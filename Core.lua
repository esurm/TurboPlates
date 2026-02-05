local addonName, ns = ...

-- TurboPlates Core
-- Nameplate handling via C_NamePlateManager, EventRegistry, C_NamePlate

-- Incompatible addons list
local IncompatibleAddOns = {
    "Ascension_NamePlates",
    "Kui_Nameplates",
    "TidyPlates_ThreatPlates",
    "PlateBuffs",
}

-- StaticPopup for addon conflicts
StaticPopupDialogs["TURBOPLATES_ADDON_CONFLICT"] = {
    text = "|cff4fa3ffTurboPlates|r has detected an incompatible nameplate addon: |cffff6666%s|r\n\nOnly one nameplate addon can be active at a time.",
    button1 = "Disable It",
    button2 = "Disable TurboPlates",
    OnAccept = function(self, data)
        if data == "Ascension_NamePlates" then
            -- Ascension_NamePlates is controlled by CVar, not addon disable
            C_CVar.Set("useNewNameplates", false)
            ReloadUI()
        elseif data == "ElvUI_NamePlates" then
            -- ElvUI nameplates: disable via E.private setting
            if ElvUI and ElvUI[1] and ElvUI[1].private and ElvUI[1].private.nameplates then
                ElvUI[1].private.nameplates.enable = false
            end
            ReloadUI()
        else
            DisableAddOn(data)
            ReloadUI()
        end
    end,
    OnCancel = function()
        DisableAddOn("TurboPlates")
        ReloadUI()
    end,
    timeout = 0,
    showAlert = 1,
    whileDead = 1,
    hideOnEscape = false,
}

-- Cache frequently used globals
local UnitExists = UnitExists
local UnitName = UnitName
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local UnitIsPet = UnitIsPet
local UnitPlayerControlled = UnitPlayerControlled
local UnitCreatureType = UnitCreatureType
local UnitGUID = UnitGUID
local GetTime = GetTime
local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local GetGuildInfo = GetGuildInfo
local GetCVarBool = GetCVarBool
local IsInGroup = IsInGroup
local GetNumGroupMembers = GetNumGroupMembers
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame
local wipe = wipe
local pairs = pairs
local tinsert = tinsert
local strlower = string.lower
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local C_NamePlateManager = C_NamePlateManager
local C_NamePlate = C_NamePlate
local C_CVar = C_CVar
local IsInRaid = IsInRaid
local WorldFrame = WorldFrame
local UIParent = UIParent
local RunNextFrame = RunNextFrame
local EventRegistry = EventRegistry
local GetAddOnMetadata = GetAddOnMetadata

-- CURSOR FLICKER FIX: Override ApplyFPSIncrease to avoid Hide/Show cycle
-- Use ClearAllPoints() -> SetPoint() instead of Hide() -> SetPoint() -> Show()
do
    local abs = math.abs
    local floor = math.floor
    local GetTime = GetTime
    
    local function UpdateAlphaAndLevel(nameplate, parent)
        -- Note: 'nameplate' here is actually myPlate (our TurboPlates frame), not the base frame
        -- 'parent' is the Blizzard base nameplate frame
        -- Alpha override: Always control alpha for non-personal nameplates
        -- This prevents the game engine from dimming plates (CVars don't exist in this client)
        local a
        local isPersonal = nameplate.isPlayer
        if not isPersonal then
            -- Manual alpha control for all non-personal nameplates
            if ns.currentTargetGUID and ns.c_nonTargetAlpha and ns.c_nonTargetAlpha < 1 then
                -- Only dim when: has target AND setting is less than 100%
                -- Use cached GUID to avoid garbage from UnitGUID() calls
                local isTarget = nameplate.cachedGUID == ns.currentTargetGUID
                a = isTarget and 1.0 or ns.c_nonTargetAlpha
            else
                -- No target OR setting is 100%: all nameplates at full alpha
                a = 1.0
            end
        else
            -- Personal bar: inherit from parent
            a = parent:GetAlpha()
        end
        
        if a ~= nameplate:GetAlpha() then
            nameplate:SetAlpha(a)
        end
        local level = parent:GetFrameLevel()
        if level ~= nameplate:GetFrameLevel() then
            nameplate:SetFrameLevel(level)
        end
    end
    
    local function SmoothMoveNameplate(nameplate, x, y)
        -- Skip if position unchanged
        if nameplate.x == x and nameplate.y == y then
            return
        end
        
        -- Skip ClearAllPoints - just update the existing point
        -- Engine handles re-anchoring without full invalidation
        nameplate:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", x, y)
        nameplate.x, nameplate.y = x, y
    end
    
    local function OnSizeChangedHandler(self, newX, newY)
        SmoothMoveNameplate(self.nameplate, newX, newY)
        
        -- Defer alpha/level updates until plate stops moving to reduce shimmer
        if C_NamePlateManager.IsNamePlateMoving(self.parent) then
            return
        end
        UpdateAlphaAndLevel(self.nameplate, self.parent)
    end
    
    local function DeferredAlphaUpdate(movementCallback)
        UpdateAlphaAndLevel(movementCallback.nameplate, movementCallback.parent)
    end
    
    -- Batched alpha update system
    local pendingAlphaUpdates = {}
    local pendingAlphaTimer = nil
    
    local function ProcessPendingAlphaUpdates()
        pendingAlphaTimer = nil
        local frame = next(pendingAlphaUpdates)
        while frame do
            local nextFrame = next(pendingAlphaUpdates, frame)
            if frame.nameplate and frame.parent then
                UpdateAlphaAndLevel(frame.nameplate, frame.parent)
            end
            pendingAlphaUpdates[frame] = nil
            frame = nextFrame
        end
    end
    
    local function OnEventHandler(self)
        pendingAlphaUpdates[self] = true
        if not pendingAlphaTimer then
            pendingAlphaTimer = true
            RunNextFrame(ProcessPendingAlphaUpdates)
        end
    end
    
    local function InitializeMovementCallback(movementCallback)
        local nameplate = movementCallback.nameplate
        nameplate:SetParent(WorldFrame)
        nameplate:ClearAllPoints()
        
        -- Initial position
        local x, y = movementCallback:GetSize()
        nameplate:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", x, y)
        nameplate.x, nameplate.y = x, y
        
        -- OnSizeChanged updates position and syncs alpha/level
        movementCallback:SetScript("OnSizeChanged", OnSizeChangedHandler)
        
        -- PLAYER_TARGET_CHANGED: Sync alpha immediately when target changes
        movementCallback:RegisterEvent("PLAYER_TARGET_CHANGED")
        movementCallback:SetScript("OnEvent", OnEventHandler)
    end
    
    C_NamePlateManager.ApplyFPSIncrease = function(nameplate)
        local nameplateFrame = nameplate:GetParent()
        if C_CVar.GetBool("highPrecisionNameplates") then
            nameplate:SetPoint("BOTTOM", nameplateFrame, "BOTTOM", 0, 0)
            return
        end
        if nameplate.movementCallback then return end
        
        -- Sync visibility when Blizzard plate hides (fixes orphaned plates)
        -- Use hooksecurefunc instead of HookScript to avoid taint during combat
        hooksecurefunc(nameplateFrame, "Hide", function()
            nameplate:Hide()
        end)
        hooksecurefunc(nameplateFrame, "Show", function()
            nameplate:Show()
        end)
        
        local movementCallback = CreateFrame("Frame", nil, nameplate)
        movementCallback:EnableMouse(false)
        nameplate.movementCallback = movementCallback
        
        movementCallback.nameplate = nameplate
        movementCallback.parent = nameplateFrame
        movementCallback:SetPoint("BOTTOMLEFT", WorldFrame)
        movementCallback:SetPoint("TOPRIGHT", nameplateFrame, "CENTER")
        
        -- Defer initialization to next frame (using pre-defined function, not inline closure)
        local callback = movementCallback
        RunNextFrame(function() InitializeMovementCallback(callback) end)
    end
end

-- Cache C_NamePlateManager functions (ApplyFPSIncrease is now our override)
local ApplyFPSIncrease = C_NamePlateManager.ApplyFPSIncrease
local DisableBlizzPlate = C_NamePlateManager.DisableBlizzPlate
local EnumerateActiveNamePlates = C_NamePlateManager.EnumerateActiveNamePlates
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

local Core = CreateFrame("Frame")
Core:RegisterEvent("PLAYER_LOGIN")
Core:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Combat ends - finish deferred DisableBlizzPlate calls
Core:RegisterEvent("PLAYER_LEVEL_UP")  -- Refresh level text when player levels up


ns.Core = Core
ns.unitToPlate = {}     -- [unit] = myPlate (used for fast unit->plate lookups)
ns.GuildDisplayCache = {} -- [guildName] = "<GuildName>" (cached formatted strings)
ns.deferredDisable = {} -- Nameplates that need DisableBlizzPlate called after combat

local npcTitleTooltip
local npcTitleQueue = {}        -- [npcID] = unit
local npcTitleQueueGUID = {}    -- [npcID] = guid
local npcTitleQueueOrder = {}   -- [i] = npcID (FIFO)
local npcTitleQueueIndex = 1
local npcTitleQueueTimer

local function GetNPCIDForUnit(unit)
    local guid = unit and UnitGUID(unit)
    if not guid then return nil end

    if GetCreatureIDFromGUID then
        local id = GetCreatureIDFromGUID(guid)
        if id and id > 0 then
            return id
        end
    end

    if type(guid) == "string" and #guid >= 12 then
        local id = tonumber(guid:sub(6, 12), 16)
        if id and id > 0 then
            return id
        end
    end
end

local function EnsureNPCTitleTooltip()
    if npcTitleTooltip then
        return npcTitleTooltip
    end
    npcTitleTooltip = CreateFrame("GameTooltip", "TurboPlatesNPCTitleScanTooltip", UIParent, "GameTooltipTemplate")
    npcTitleTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    return npcTitleTooltip
end

local function ScanNPCTitle(unit)
    local tip = EnsureNPCTitleTooltip()
    tip:ClearLines()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:SetUnit(unit)

    local lineIndex = 2
    if GetCVarBool and GetCVarBool("colorblindMode") then
        lineIndex = 3
    end

    local line = _G["TurboPlatesNPCTitleScanTooltipTextLeft" .. lineIndex]
    local text = line and line:GetText() or nil
    tip:Hide()

    if not text or text == "" then
        return nil
    end

    local levelToken = LEVEL and strlower(LEVEL) or "level"
    if strlower(text):find(levelToken, 1, true) then
        return nil
    end

    return text
end

local function ProcessNPCTitleQueue()
    npcTitleQueueTimer = nil

    if InCombatLockdown() then
        return
    end

    local cache = ns.c_npcTitleCache
    if not cache then
        return
    end

    local maxIndex = #npcTitleQueueOrder
    if npcTitleQueueIndex > maxIndex then
        wipe(npcTitleQueueOrder)
        npcTitleQueueIndex = 1
        return
    end

    local scansThisTick = 0
    while scansThisTick < 2 and npcTitleQueueIndex <= maxIndex do
        local npcID = npcTitleQueueOrder[npcTitleQueueIndex]
        npcTitleQueueIndex = npcTitleQueueIndex + 1
        if npcID then
            local unit = npcTitleQueue[npcID]
            local guid = npcTitleQueueGUID[npcID]
            npcTitleQueue[npcID] = nil
            npcTitleQueueGUID[npcID] = nil

            if unit and guid and not cache[npcID] and UnitExists(unit) and UnitGUID(unit) == guid and (not UnitIsPlayer(unit)) and (not UnitPlayerControlled(unit)) then
                local title = ScanNPCTitle(unit)
                if title and title ~= "" then
                    cache[npcID] = title
                end
            end
        end
        scansThisTick = scansThisTick + 1
    end

    if npcTitleQueueIndex <= #npcTitleQueueOrder then
        npcTitleQueueTimer = true
        C_Timer.After(0.05, ProcessNPCTitleQueue)
    else
        wipe(npcTitleQueueOrder)
        npcTitleQueueIndex = 1
    end
end

local function QueueNPCTitleScan(npcID, unit)
    if not npcID or npcID == 0 then
        return
    end
    local cache = ns.c_npcTitleCache
    if cache and cache[npcID] then
        return
    end
    if npcTitleQueue[npcID] then
        return
    end

    npcTitleQueue[npcID] = unit
    npcTitleQueueGUID[npcID] = UnitGUID(unit)
    tinsert(npcTitleQueueOrder, npcID)

    if not npcTitleQueueTimer and not InCombatLockdown() then
        npcTitleQueueTimer = true
        C_Timer.After(0.05, ProcessNPCTitleQueue)
    end
end

local ARENA_UNITS = {"arena1", "arena2", "arena3", "arena4", "arena5"}

-- Helper to get formatted guild display string (cached to avoid string concatenation)
local function GetGuildDisplayString(guildName)
    local cached = ns.GuildDisplayCache[guildName]
    if not cached then
        cached = "<" .. guildName .. ">"
        ns.GuildDisplayCache[guildName] = cached
    end
    return cached
end

-- Cached clickable area dimensions (set at PLAYER_LOGIN, updated by GUI sliders)
ns.clickableWidth = 140   -- Default, will be set from CVar at login
ns.clickableHeight = 30   -- Default, will be set from CVar at login

-- Hidden parent for Blizzard elements (used during combat to avoid SetAttribute taint)
local turboHiddenParent = CreateFrame("Frame", "TurboPlatesHiddenParent", UIParent)
turboHiddenParent:Hide()

-- Manually hide Blizzard nameplate elements WITHOUT calling SetAttribute
-- Safe during combat since secure attributes aren't touched
local function HideBlizzardElements(nameplate)
    if nameplate._turboBlizzHidden then return end
    
    -- Capture all regions into table FIRST, then iterate
    -- Re-calling GetRegions() each iteration causes index shift when reparenting
    local blizzElements = {nameplate:GetRegions()}
    local healthBar, castBar = nameplate:GetChildren()
    if healthBar then tinsert(blizzElements, healthBar) end
    if castBar then tinsert(blizzElements, castBar) end
    
    for _, child in ipairs(blizzElements) do
        if child then
            child:SetParent(turboHiddenParent)
            child:SetAlpha(0)
            child:Hide()
            if child.SetTexture then
                child:SetTexture()
            elseif child.SetStatusBarTexture then
                child:SetStatusBarTexture(nil)
            end
        end
    end
    
    nameplate._turboBlizzHidden = true
end

-- Safe wrapper for DisableBlizzPlate (taint-safe during combat)
local function SafeDisableBlizzPlate(unit, nameplate)
    if not nameplate then
        nameplate = GetNamePlateForUnit(unit)
    end
    if not nameplate then return end
    
    -- If already properly disabled via API (attribute set), nothing to do
    if nameplate:GetAttribute("disabled-blizz-plate") then return end
    
    if InCombatLockdown() then
        -- During combat: manually hide elements (no SetAttribute = no taint)
        HideBlizzardElements(nameplate)
        -- Remember to call full API after combat to set the attribute
        ns.deferredDisable[nameplate] = unit
    else
        -- Out of combat: use full API which sets the secure attribute
        DisableBlizzPlate(unit)
    end
end

-- Note: Cached settings are stored in ns.c_* (set by Nameplates.lua:UpdateDBCache)
-- Core.lua uses ns.c_font, ns.c_friendlyFontSize, ns.c_guildFontSize, ns.c_fontOutline, ns.c_raidMarkerSize

Core:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ns:LoadVariables()  -- Also calls UpdateDBCache() at the end (sets ns.c_* cache)
        
        -- Force disable problematic Ascension nameplate CVars that conflict with TurboPlates
        -- These cause visual glitches and performance issues with custom nameplate addons
        if C_CVar then
            C_CVar.Set("nameplateSmoothStacking", false)  -- Smooth Stacking Nameplates
            C_CVar.Set("highPrecisionNameplates", false)  -- High-Precision Nameplates
            -- Note: ShowClassColorInNameplate is handled by our own classColoredHealth setting
            -- Note: DrawNameplateClickBox is user-controllable via options, not forced here
            
            -- Custom stacking requires nameplateAllowOverlap to be enabled
            if ns.c_stackingEnabled then
                C_CVar.Set("nameplateAllowOverlap", 1)
            end
            -- Note: Alpha CVars (nameplateNotSelectedAlpha, nameplateMinAlpha) don't exist
            -- in Ascension client. Alpha is handled manually in UpdateAlphaAndLevel().
        end
        
        -- Enable nameplate resizing so Clickable Width/Height sliders work
        if C_NamePlateManager and C_NamePlateManager.SetEnableResizeNamePlates then
            C_NamePlateManager.SetEnableResizeNamePlates(true)
        end
        
        -- Initialize clickable area cache from CVars (avoids per-plate CVar lookups)
        ns.clickableWidth = C_CVar.GetNumber("nameplateWidth") or 110
        ns.clickableHeight = C_CVar.GetNumber("nameplateHeight") or 30
        
        -- Initialize tall boss fix (extends WorldFrame for tall boss nameplates)
        if ns.InitTallBossFix then
            ns.InitTallBossFix()
        end
        
        -- Initialize custom stacking system
        if ns.UpdateStacking then
            ns.UpdateStacking()
        end
        
        -- Initialize TurboDebuffs (BigDebuffs-style priority aura)
        if ns.InitTurboDebuffs then
            ns:InitTurboDebuffs()
        end
        
        -- Apply non-target alpha to any existing nameplates (delayed to ensure all are created)
        C_Timer.After(0.1, function()
            if ns.UpdateNameplateAlphas then
                ns.UpdateNameplateAlphas()
            end
        end)
        
        -- Delayed quest icon refresh (API may not be ready immediately at login)
        -- Similar to Plater's 4.1s delay for QuestLogUpdated
        C_Timer.After(3, function()
            if ns.UpdateAllQuestIcons then
                ns.UpdateAllQuestIcons()
            end
        end)
        
        -- Check for incompatible nameplate addons
        -- Special case: Ascension_NamePlates is controlled by CVar, not addon list
        if C_CVar.GetBool("useNewNameplates") then
            StaticPopup_Show("TURBOPLATES_ADDON_CONFLICT", "Ascension_NamePlates", "Ascension_NamePlates", "Ascension_NamePlates")
        -- Check ElvUI nameplates module (E.private.nameplates.enable)
        elseif ElvUI and ElvUI[1] and ElvUI[1].private and ElvUI[1].private.nameplates and ElvUI[1].private.nameplates.enable then
            StaticPopup_Show("TURBOPLATES_ADDON_CONFLICT", "ElvUI NamePlates", "ElvUI NamePlates", "ElvUI_NamePlates")
        else
            -- Check other incompatible addons
            for _, addon in ipairs(IncompatibleAddOns) do
                if addon ~= "Ascension_NamePlates" then
                    local name, _, _, enabled = GetAddOnInfo(addon)
                    if enabled then
                        StaticPopup_Show("TURBOPLATES_ADDON_CONFLICT", addon, addon, addon)
                        break
                    end
                end
            end
        end
        
        local version = GetAddOnMetadata(addonName, "Version") or "1.0.0"
        print("Boosted by |cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r v" .. version .. " - /tp for config")
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended - finish any deferred DisableBlizzPlate calls
        -- Now safe to call SetAttribute without causing taint
        for nameplate, unit in pairs(ns.deferredDisable) do
            if nameplate and unit then
                -- The attribute wasn't set during combat, set it now
                if not nameplate:GetAttribute("disabled-blizz-plate") then
                    nameplate:SetAttribute("disabled-blizz-plate", true)
                end
            end
        end
        wipe(ns.deferredDisable)

        -- Resume NPC title scans (cached titles remain visible in combat)
        if not npcTitleQueueTimer and npcTitleQueueOrder[1] and not InCombatLockdown() then
            npcTitleQueueTimer = true
            C_Timer.After(0.05, ProcessNPCTitleQueue)
        end
    elseif event == "PLAYER_LEVEL_UP" then
        -- Player leveled up - update cached level and refresh all nameplate level text
        local newLevel = ...
        ns.c_playerLevel = newLevel or UnitLevel("player")
        
        -- Refresh all visible nameplates to update level display
        for unit, myPlate in pairs(ns.unitToPlate) do
            if myPlate and myPlate.levelText then
                myPlate.levelText._lastLevel = nil  -- Force refresh
                if ns.UpdateLevelText then
                    ns.UpdateLevelText(unit)
                end
            end
        end
    end
end)

-- Create lite container elements on a frame
-- Does NOT call DisableBlizzPlate - that's handled separately at nameplate level
local function SetupLiteContainer(container, nameplate)
    local defaultFont = "Fonts\\FRIZQT__.TTF"
    
    container:EnableMouse(false)
    
    local txt = container:CreateFontString(nil, "OVERLAY")
    txt:SetFont(defaultFont, 12, "OUTLINE")
    txt:SetPoint("CENTER", container, "CENTER", 0, 0)
    txt:SetJustifyV("MIDDLE")
    container.liteNameText = txt
    
    local guild = container:CreateFontString(nil, "OVERLAY")
    guild:SetFont(defaultFont, 10, "OUTLINE")
    guild:SetPoint("TOP", txt, "BOTTOM", 0, -1)
    guild:SetTextColor(0.8, 0.8, 0.8)
    guild:Hide()
    container.liteGuildText = guild
    
    local icon = container:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    icon:Hide()
    container.liteRaidIcon = icon
    
    -- Level text for lite plates (anchored right of name)
    local levelText = container:CreateFontString(nil, "OVERLAY")
    levelText:SetFont(defaultFont, 12, "OUTLINE")
    levelText:SetPoint("LEFT", txt, "RIGHT", PixelUtil.GetNearestPixelSize(2, 1), 0)
    levelText:SetJustifyH("LEFT")
    levelText:SetJustifyV("MIDDLE")
    levelText:Hide()
    container.liteLevelText = levelText
    
    -- Lite health bar (shown when damaged) - size scales with friendlyFontSize
    local friendlySize = ns.c_friendlyFontSize or 12
    local hpWidth = math.floor(friendlySize * 5)   -- Width proportional to font size
    local hpHeight = math.floor(friendlySize * 0.5) -- Height proportional to font size
    local liteHP = CreateFrame("StatusBar", nil, container)
    PixelUtil.SetSize(liteHP, hpWidth, hpHeight, 1, 1)
    PixelUtil.SetPoint(liteHP, "TOP", txt, "BOTTOM", 0, -2, 1, 1)
    liteHP:SetStatusBarTexture(ns.c_texture or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    liteHP:SetStatusBarColor(0, 1, 0)
    liteHP:Hide()
    container.liteHealthBar = liteHP
    
    -- Lite health bar background
    local liteHPBG = liteHP:CreateTexture(nil, "BACKGROUND")
    liteHPBG:SetAllPoints()
    liteHPBG:SetColorTexture(0, 0, 0, 0.7)
    
    -- Lite health text - scales with friendlyFontSize
    local liteHPText = liteHP:CreateFontString(nil, "OVERLAY")
    local fontSize = math.max(7, math.floor(friendlySize * 0.75))
    liteHPText:SetFont(ns.c_font or defaultFont, fontSize, "OUTLINE")
    liteHPText:SetPoint("CENTER", liteHP, "CENTER", 0, 0)
    liteHPText:SetTextColor(1, 1, 1)
    container.liteHealthText = liteHPText
    
    container:SetParent(nameplate)
    container:SetAllPoints()
    container:SetFrameLevel(nameplate:GetFrameLevel() + 1)
end

-- Event-driven nameplate handling via EventRegistry
-- Uses SafeDisableBlizzPlate to hide elements during combat without SetAttribute
local function OnNamePlateAdded(_, unit, nameplate)
    if not nameplate and unit then
        nameplate = GetNamePlateForUnit(unit)
    end
    if not nameplate then return end
    
    -- Apply static clamp for tall boss fix (when stacking is OFF)
    if ns.OnNameplateAddedForClamp then
        ns.OnNameplateAddedForClamp(nameplate, unit)
    end
    
    -- TAINT FIX: Check if this nameplate has EVER been initialized by TurboPlates
    -- If NEITHER liteContainer NOR myPlate exists, this is a brand new nameplate frame
    -- Use SafeDisableBlizzPlate which won't taint during combat
    local needsInit = not nameplate.liteContainer and not nameplate.myPlate
    if needsInit then
        SafeDisableBlizzPlate(unit, nameplate)
    end
    
    local isFriendly = UnitIsFriend("player", unit)
    
    -- Never use lite plate for player's own personal nameplate
    local isPersonalPlate = UnitIsUnit(unit, "player")
    
    -- Check if unit is a pet or totem (for including in friendly name-only mode)
    local isPetOrTotem = false
    local isTotem = false
    if not UnitIsPlayer(unit) then
        isTotem = UnitCreatureType(unit) == "Totem"
        isPetOrTotem = UnitIsPet(unit) or isTotem
    end
    
    -- Check if Gladdy is handling this totem - skip our processing entirely
    if isTotem and nameplate.gladdyTotemFrame and nameplate.gladdyTotemFrame.active then
        -- Gladdy is handling this totem - hide our elements and return
        if nameplate.myPlate then nameplate.myPlate:Hide() end
        if nameplate.liteContainer then nameplate.liteContainer:Hide() end
        return
    end
    
    -- ULTRA-LIGHTWEIGHT: Friendly name-only uses a single FontString, no myPlate frame
    -- NEVER apply to personal nameplate - it always needs full plate treatment
    local useLitePlate = isFriendly and ns.c_friendlyNameOnly and not isPersonalPlate
    if isPetOrTotem and isFriendly and ns.c_friendlyNameOnly then
        useLitePlate = true
    end
    
    if useLitePlate then
        -- Hide full plate if it exists from previous non-friendly use
        if nameplate.myPlate then
            nameplate.myPlate:Hide()
        end
        -- Clear unit lookup since lite plates don't use unitToPlate
        ns.unitToPlate[unit] = nil
        
        -- Create lite container if it doesn't exist
        local container = nameplate.liteContainer
        if not container then
            container = CreateFrame("Frame", nil, nameplate)
            SetupLiteContainer(container, nameplate)
            nameplate.liteContainer = container
        end
        
        -- References for convenience
        local txt = container.liteNameText
        local guild = container.liteGuildText
        local icon = container.liteRaidIcon
        
        nameplate.liteNameText = txt
        nameplate.liteGuildText = guild
        nameplate.liteRaidIcon = icon
        
        -- Font caching - only call SetFont if settings changed
        if txt._lastFont ~= ns.c_font or txt._lastSize ~= ns.c_friendlyFontSize or txt._lastOutline ~= ns.c_fontOutline then
            txt:SetFont(ns.c_font, ns.c_friendlyFontSize, ns.c_fontOutline)
            txt._lastFont = ns.c_font
            txt._lastSize = ns.c_friendlyFontSize
            txt._lastOutline = ns.c_fontOutline
        end
        
        if guild._lastFont ~= ns.c_font or guild._lastSize ~= ns.c_guildFontSize or guild._lastOutline ~= ns.c_fontOutline then
            guild:SetFont(ns.c_font, ns.c_guildFontSize, ns.c_fontOutline)
            guild._lastFont = ns.c_font
            guild._lastSize = ns.c_guildFontSize
            guild._lastOutline = ns.c_fontOutline
        end
        
        -- Cache unit data on nameplate to avoid re-querying
        local name = nameplate._cachedName
        local isPlayer = nameplate._cachedIsPlayer
        local cachedClass = nameplate._cachedClass
        
        -- Only query if not cached or unit changed
        if not name then
            name = UnitName(unit) or ""
            nameplate._cachedName = name
            isPlayer = UnitIsPlayer(unit)
            nameplate._cachedIsPlayer = isPlayer
            if isPlayer then
                local _, class = UnitClass(unit)
                cachedClass = class
                nameplate._cachedClass = class
            end
        end
        
        local displayName = ns.FormatName and ns:FormatName(name) or name
        txt:SetText(displayName)
        
        -- Class color for players (use cached class)
        if isPlayer and cachedClass then
            local classColor = RAID_CLASS_COLORS[cachedClass]
            if classColor then
                txt:SetTextColor(classColor.r, classColor.g, classColor.b)
            else
                txt:SetTextColor(0, 1, 0)
            end
        else
            txt:SetTextColor(0, 1, 0)
        end
        
        txt:Show()
        
        -- Guild text for players (if enabled) - use cached guild
        local showSubtitle = false
        if isPlayer and ns.c_friendlyGuild then
            local guildName = nameplate._cachedGuild
            if guildName == nil then  -- nil means not yet queried
                guildName = GetGuildInfo(unit)
                nameplate._cachedGuild = guildName or false  -- false = queried but no guild
            end
            if guildName and guildName ~= false then
                guild:SetText(GetGuildDisplayString(guildName))
                guild:Show()
                showSubtitle = true
            else
                guild:Hide()
            end
        elseif (not isPlayer) and (not UnitPlayerControlled(unit)) then
            local npcID = nameplate._cachedNPCID
            if npcID == nil then
                npcID = GetNPCIDForUnit(unit) or false
                nameplate._cachedNPCID = npcID
            end

            if npcID and npcID ~= false then
                local title = ns.c_npcTitleCache and ns.c_npcTitleCache[npcID]
                if title and title ~= "" then
                    guild:SetText("<" .. title .. ">")
                    guild:Show()
                    showSubtitle = true
                else
                    guild:Hide()
                    QueueNPCTitleScan(npcID, unit)
                end
            else
                guild:Hide()
            end
        else
            guild:Hide()
        end
        
        -- Reposition name text based on guild visibility
        -- When guild is shown, push name up so guild appears at the original center position
        if showSubtitle then
            local guildHeight = ns.c_guildFontSize + 1  -- font size + 1px gap
            if txt._guildOffset ~= guildHeight then
                txt:ClearAllPoints()
                txt:SetPoint("CENTER", container, "CENTER", 0, guildHeight / 2)
                txt._guildOffset = guildHeight
            end
        elseif txt._guildOffset then
            txt:ClearAllPoints()
            txt:SetPoint("CENTER", container, "CENTER", 0, 0)
            txt._guildOffset = nil
        end

        -- Reposition lite health bar based on guild visibility
        if container.liteHealthBar then
            local anchorKey = showSubtitle and "subtitle" or "name"
            if container.liteHealthBar._lastAnchorKey ~= anchorKey then
                container.liteHealthBar:ClearAllPoints()
                PixelUtil.SetPoint(container.liteHealthBar, "TOP", showSubtitle and guild or txt, "BOTTOM", 0, -2, 1, 1)
                container.liteHealthBar._lastAnchorKey = anchorKey
            end
        end
        
        -- Update lite raid icon (initialize cache values for UpdateAllPlates)
        local raidIndex = GetRaidTargetIndex(unit)
        if raidIndex then
            icon:SetSize(ns.c_raidMarkerSize, ns.c_raidMarkerSize)
            icon._lastSize = ns.c_raidMarkerSize
            icon:ClearAllPoints()
            icon:SetPoint("BOTTOM", txt, "TOP", 0, 2)
            icon._litePositioned = true
            SetRaidTargetIconTexture(icon, raidIndex)
            icon:Show()
        else
            icon:Hide()
        end
        
        -- Update lite level text (only if mode is "all" since lite plates are friendly)
        local levelText = container.liteLevelText
        if levelText then
            if ns.c_levelMode == "all" then
                local level = UnitLevel(unit)
                -- Skip if same level as player
                if level > 0 and level == ns.c_playerLevel then
                    levelText:Hide()
                else
                    -- Font caching for level text
                    if levelText._lastFont ~= ns.c_font or levelText._lastSize ~= ns.c_friendlyFontSize or levelText._lastOutline ~= ns.c_fontOutline then
                        levelText:SetFont(ns.c_font, ns.c_friendlyFontSize, ns.c_fontOutline)
                        levelText._lastFont = ns.c_font
                        levelText._lastSize = ns.c_friendlyFontSize
                        levelText._lastOutline = ns.c_fontOutline
                    end
                    if not levelText._positioned then
                        levelText:ClearAllPoints()
                        levelText:SetPoint("LEFT", txt, "RIGHT", PixelUtil.GetNearestPixelSize(2, 1), 0)
                        levelText._positioned = true
                    end
                    
                    local color
                    if level <= 0 then
                        color = GetQuestDifficultyColor(999)
                        levelText:SetText("??")
                    else
                        color = GetQuestDifficultyColor(level)
                        levelText:SetText(level)
                    end
                    levelText:SetTextColor(color.r, color.g, color.b)
                    levelText:Show()
                end
            else
                levelText:Hide()
            end
        end
        
        -- Update lite quest icon
        if ns.UpdateLiteQuestIcon then
            ns.UpdateLiteQuestIcon(nameplate, unit)
        end
        
        -- Update TurboDebuff for lite plates
        if ns.UpdateLiteTurboDebuff then
            ns:UpdateLiteTurboDebuff(nameplate, unit)
        end
        
        -- Update healer icon for lite plates
        if ns.UpdateLiteHealerIcon then
            ns:UpdateLiteHealerIcon(container, unit)
        end
        
        -- Update lite health bar when damaged
        if ns.c_liteHealthWhenDamaged and container.liteHealthBar then
            ns:UpdateLiteHealthBar(container, unit)
        elseif container.liteHealthBar then
            container.liteHealthBar:Hide()
        end
        
        container:Show()
        nameplate._isLite = true
        return
    end
    
    -- Non-lite path: hide lite container if exists, including lite quest icon
    if nameplate.liteContainer then
        nameplate.liteContainer:Hide()
        -- Hide lite healer icon
        if nameplate.liteContainer.liteHealerIcon then
            nameplate.liteContainer.liteHealerIcon:Hide()
        end
    end
    if nameplate.liteQuestIcon then
        nameplate.liteQuestIcon:Hide()
    end
    -- Hide lite TurboDebuff when switching to full plate
    if ns.HideLiteTurboDebuff then
        ns:HideLiteTurboDebuff(nameplate)
    end
    nameplate._isLite = false
    
    -- Create full plate frame (once, reused) - DisableBlizzPlate already called above if needed
    if not nameplate.myPlate then
        if ns.CreatePlateFrame then
            ns:CreatePlateFrame(nameplate, unit)
            if nameplate.myPlate then
                ApplyFPSIncrease(nameplate.myPlate)
            end
        end
    end
    
    -- Update and show
    if nameplate.myPlate then
        nameplate.myPlate.unit = unit
        nameplate.myPlate.cachedGUID = UnitGUID(unit)
        
        -- Hide personal bar elements BEFORE showing to prevent one-frame flash
        if nameplate.myPlate.powerBar then
            nameplate.myPlate.powerBar:Hide()
        end
        if nameplate.myPlate.additionalPowerBar then
            nameplate.myPlate.additionalPowerBar:Hide()
        end
        
        nameplate.myPlate:Show()
        ns.unitToPlate[unit] = nameplate.myPlate
        
        if ns.FullPlateUpdate then
            ns:FullPlateUpdate(nameplate.myPlate, unit)
        end
        
        -- Initial TurboDebuff update (don't wait for UNIT_AURA batch)
        if ns.UpdateTurboDebuff then
            ns:UpdateTurboDebuff(nameplate.myPlate, unit)
        end
        
        if ns.CheckExistingCast then
            ns:CheckExistingCast(unit)
        end
        
        -- Validate target plate in case this newly added plate is the target
        -- (handles case where target's plate appears after target was selected)
        if ns.ValidateTargetPlate then
            ns.ValidateTargetPlate()
        end
    end
end

-- Hide frames when nameplate removed (frames are reused)
local function OnNamePlateRemoved(_, unit, nameplate)
    if not nameplate and unit then
        nameplate = GetNamePlateForUnit(unit)
    end
    if unit then
        -- Clean up castbar BEFORE clearing unit mapping (so lookup works)
        if ns.CleanupCastbar then
            ns:CleanupCastbar(unit)
        end
        -- Clear quest retry state for this unit
        if ns.ClearQuestRetryState then
            ns.ClearQuestRetryState(unit)
        end
        ns.unitToPlate[unit] = nil
        -- Clear personal plate reference if this was the player's nameplate
        if UnitIsUnit(unit, "player") and ns.ClearPersonalPlateRef then
            ns:ClearPersonalPlateRef()
        end
    end
    if nameplate then
        -- Clear cached unit data (so next unit gets fresh data)
        nameplate._cachedName = nil
        nameplate._cachedIsPlayer = nil
        nameplate._cachedClass = nil
        nameplate._cachedGuild = nil
        nameplate._cachedNPCID = nil
        
        if nameplate.liteContainer then
            nameplate.liteContainer:Hide()
            -- Hide lite healer icon
            if nameplate.liteContainer.liteHealerIcon then
                nameplate.liteContainer.liteHealerIcon:Hide()
            end
        end
        -- Hide lite TurboDebuff
        if ns.HideLiteTurboDebuff then
            ns:HideLiteTurboDebuff(nameplate)
        end
        if nameplate.myPlate then
            -- Clear stale plate reference before recycling (keep GUID - target still exists)
            if nameplate.myPlate == ns.currentTargetPlate then
                ns.currentTargetPlate = nil
                -- Don't clear ns.currentTargetGUID - the target unit still exists,
                -- just its plate went out of view. ValidateTargetPlate will reapply
                -- effects when the plate comes back.
            end
            -- Reset scale and glow to prevent leftover effects on recycled plates
            -- TAINT FIX: Defer to next frame to break secure callback chain
            -- (pet nameplates removed during combat can propagate taint otherwise)
            local plate = nameplate.myPlate
            RunNextFrame(function()
                if plate then
                    plate:SetScale(ns.c_scale or 1)
                    plate._lastScale = nil
                    if ns.ClearTargetGlow then
                        ns.ClearTargetGlow(plate)
                    end
                end
            end)
            -- Clear targeting me indicator (prevent stale visuals on recycled plates)
            if nameplate.myPlate.isTargetingMe or nameplate.myPlate._targetingMeActive then
                nameplate.myPlate.isTargetingMe = nil
                nameplate.myPlate._targetingMeActive = nil
                if nameplate.myPlate.targetingMeGlow then
                    nameplate.myPlate.targetingMeGlow:Hide()
                end
                -- Reset border to default black
                if nameplate.myPlate.hp and nameplate.myPlate.hp.border then
                    nameplate.myPlate.hp.border:SetColor(0, 0, 0, ns.BORDER_ALPHA or 0.6)
                end
            end
            -- Release auras to pool (stops OnUpdate timers on hidden frames)
            if ns.CleanupPlateAuras then
                ns:CleanupPlateAuras(nameplate.myPlate)
            end
            -- Hide TurboDebuff
            if ns.HideTurboDebuff then
                ns:HideTurboDebuff(nameplate.myPlate)
            end
            -- Hide healer icon
            if nameplate.myPlate.healerIcon then
                nameplate.myPlate.healerIcon:Hide()
            end
            -- Hide threat text and clear cached values
            if nameplate.myPlate.threatText then
                nameplate.myPlate.threatText:Hide()
                nameplate.myPlate.threatText._lastPct = nil
                nameplate.myPlate.threatText._lastLeadText = nil
                nameplate.myPlate.threatText._lastLeadValue = nil
            end
            -- Clean up castbar (glow cleanup handled by CleanupCastbar above)
            if nameplate.myPlate.castbar then
                nameplate.myPlate.castbar:Hide()
                nameplate.myPlate.castbar.isHighlighted = nil
                -- Hide glow frame container
                if nameplate.myPlate.castbar.glowFrame then
                    nameplate.myPlate.castbar.glowFrame:Hide()
                end
            end
            -- Hide combo points on recycled plate
            if nameplate.myPlate.cps then
                for i = 1, #nameplate.myPlate.cps do
                    nameplate.myPlate.cps[i]:Hide()
                end
            end
            -- Clear arena number from name text (prevent stale arena numbers on recycled plates)
            if nameplate.myPlate.nameText then
                nameplate.myPlate.nameText:SetText("")
            end
            nameplate.myPlate:Hide()
            -- Reset personal plate state (prevents flash of power bar on recycled plates)
            nameplate.myPlate.isPlayer = false
            if nameplate.myPlate.powerBar then
                nameplate.myPlate.powerBar:Hide()
            end
            if nameplate.myPlate.additionalPowerBar then
                nameplate.myPlate.additionalPowerBar:Hide()
            end
            -- Hide HERO power bars (prevents them showing on recycled plates)
            if nameplate.myPlate.heroPowerBars then
                for i = 1, 3 do
                    if nameplate.myPlate.heroPowerBars[i] then
                        nameplate.myPlate.heroPowerBars[i]:Hide()
                    end
                end
            end
            -- Clear initialized flag so plate gets re-initialized for next unit
            nameplate.myPlate._initialized = false
            nameplate.myPlate._lastUnit = nil
            -- Clear absorb cache and hide absorb/heal textures to prevent visual artifacts
            nameplate.myPlate._lastAbsorb = nil
            nameplate.myPlate._lastAbsorbHealth = nil
            if nameplate.myPlate.hp then
                if nameplate.myPlate.hp.absorbBar then nameplate.myPlate.hp.absorbBar:Hide() end
                if nameplate.myPlate.hp.absorbOverlay then nameplate.myPlate.hp.absorbOverlay:Hide() end
                if nameplate.myPlate.hp.overAbsorbGlow then nameplate.myPlate.hp.overAbsorbGlow:Hide() end
                if nameplate.myPlate.hp.healBar then nameplate.myPlate.hp.healBar:Hide() end
            end
        end
        -- Clean up stacking data for removed plate
        if ns.CleanupStackingPlate then
            ns.CleanupStackingPlate(nameplate)
        end
    end
end

-- Note: Lite plate cache is now handled by Nameplates.lua:UpdateDBCache (ns.c_*)

-- Update lite health bar (shared between OnNamePlateAdded and UNIT_HEALTH updates)
function ns:UpdateLiteHealthBar(container, unit)
    if not container or not container.liteHealthBar then return end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    if health < maxHealth and maxHealth > 0 then
        local liteHP = container.liteHealthBar
        liteHP:SetMinMaxValues(0, maxHealth)
        liteHP:SetValue(health)
        -- Update text using health value format setting
        if ns.FormatHealthValue then
            container.liteHealthText:SetText(ns.FormatHealthValue(health, maxHealth))
        else
            container.liteHealthText:SetText("")
        end
        -- Update color based on health percent (green to red gradient)
        local pct = math.floor((health / maxHealth) * 100)
        local r, g = 1, 1
        if pct < 50 then
            r, g = 1, pct / 50
        else
            r = (100 - pct) / 50
        end
        liteHP:SetStatusBarColor(r, g, 0)
        liteHP:Show()
    else
        container.liteHealthBar:Hide()
    end
end

function ns:UpdateAllPlates()
    
    for nameplate in EnumerateActiveNamePlates() do
        local unit = nameplate._unit
        if unit and UnitExists(unit) then
            local isFriendly = UnitIsFriend("player", unit)
            
            -- Never use lite plate for player's own personal nameplate
            local isPersonalPlate = UnitIsUnit(unit, "player")
            
            local isPetOrTotem = false
            if not UnitIsPlayer(unit) then
                isPetOrTotem = UnitIsPet(unit) or (UnitCreatureType(unit) == "Totem")
            end
            
            -- NEVER apply lite plate to personal nameplate
            local useLitePlate = isFriendly and ns.c_friendlyNameOnly and not isPersonalPlate
            if isPetOrTotem and isFriendly and ns.c_friendlyNameOnly then
                useLitePlate = true
            end
            
            if useLitePlate then
                if nameplate.myPlate then 
                    nameplate.myPlate:Hide()
                    -- Clear unitToPlate mapping when switching to lite mode
                    ns.unitToPlate[unit] = nil
                end
                nameplate._isLite = true
                
                local container = nameplate.liteContainer
                if not container then
                    container = CreateFrame("Frame", nil, nameplate)
                    SetupLiteContainer(container, nameplate)
                    nameplate.liteContainer = container
                end
                
                local txt = container.liteNameText
                local guild = container.liteGuildText
                local icon = container.liteRaidIcon
                
                nameplate.liteNameText = txt
                nameplate.liteGuildText = guild
                nameplate.liteRaidIcon = icon
                
                -- Lite name font caching
                if txt._lastFont ~= ns.c_font or txt._lastSize ~= ns.c_friendlyFontSize or txt._lastOutline ~= ns.c_fontOutline then
                    txt:SetFont(ns.c_font, ns.c_friendlyFontSize, ns.c_fontOutline)
                    txt._lastFont = ns.c_font
                    txt._lastSize = ns.c_friendlyFontSize
                    txt._lastOutline = ns.c_fontOutline
                end
                -- Lite guild font caching
                if guild._lastFont ~= ns.c_font or guild._lastSize ~= ns.c_guildFontSize or guild._lastOutline ~= ns.c_fontOutline then
                    guild:SetFont(ns.c_font, ns.c_guildFontSize, ns.c_fontOutline)
                    guild._lastFont = ns.c_font
                    guild._lastSize = ns.c_guildFontSize
                    guild._lastOutline = ns.c_fontOutline
                end

                -- Lite damaged-HP refresh (size/texture/font) - scales with friendlyFontSize
                if container.liteHealthBar then
                    local friendlySize = ns.c_friendlyFontSize or 12
                    local hpWidth = math.floor(friendlySize * 5)
                    local hpHeight = math.floor(friendlySize * 0.5)
                    if container.liteHealthBar._lastW ~= hpWidth or container.liteHealthBar._lastH ~= hpHeight then
                        PixelUtil.SetSize(container.liteHealthBar, hpWidth, hpHeight, 1, 1)
                        container.liteHealthBar._lastW = hpWidth
                        container.liteHealthBar._lastH = hpHeight
                    end

                    local texture = ns.c_texture or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
                    if container.liteHealthBar._lastTexture ~= texture and container.liteHealthBar.SetStatusBarTexture then
                        container.liteHealthBar:SetStatusBarTexture(texture)
                        container.liteHealthBar._lastTexture = texture
                    end
                end
                if container.liteHealthText then
                    local defaultFont = "Fonts\\FRIZQT__.TTF"
                    local font = ns.c_font or defaultFont
                    local fontSize = math.max(7, math.floor((ns.c_friendlyFontSize or 12) * 0.75))
                    local outline = ns.c_fontOutline or "OUTLINE"
                    if container.liteHealthText._lastFont ~= font or container.liteHealthText._lastSize ~= fontSize or container.liteHealthText._lastOutline ~= outline then
                        container.liteHealthText:SetFont(font, fontSize, outline)
                        container.liteHealthText._lastFont = font
                        container.liteHealthText._lastSize = fontSize
                        container.liteHealthText._lastOutline = outline
                    end
                end
                
                local name = UnitName(unit) or ""
                local displayName = ns.FormatName and ns:FormatName(name) or name
                txt:SetText(displayName)
                
                local isPlayer = UnitIsPlayer(unit)
                local class
                if isPlayer then
                    _, class = UnitClass(unit)
                end
                local classColor = isPlayer and class and RAID_CLASS_COLORS[class]
                if classColor then
                    txt:SetTextColor(classColor.r, classColor.g, classColor.b)
                else
                    txt:SetTextColor(0, 1, 0)
                end
                
                txt:Show()

                local showSubtitle = false
                if isPlayer and ns.c_friendlyGuild then
                    local guildName = GetGuildInfo(unit)
                    if guildName then
                        guild:SetText(GetGuildDisplayString(guildName))
                        guild:Show()
                        showSubtitle = true
                    else
                        guild:Hide()
                    end
                elseif (not isPlayer) and (not UnitPlayerControlled(unit)) then
                    local npcID = nameplate._cachedNPCID
                    if npcID == nil then
                        npcID = GetNPCIDForUnit(unit) or false
                        nameplate._cachedNPCID = npcID
                    end

                    if npcID and npcID ~= false then
                        local title = ns.c_npcTitleCache and ns.c_npcTitleCache[npcID]
                        if title and title ~= "" then
                            guild:SetText("<" .. title .. ">")
                            guild:Show()
                            showSubtitle = true
                        else
                            guild:Hide()
                            QueueNPCTitleScan(npcID, unit)
                        end
                    else
                        guild:Hide()
                    end
                else
                    guild:Hide()
                end
                
                -- Reposition name text based on guild visibility
                if showSubtitle then
                    local guildHeight = ns.c_guildFontSize + 1
                    if txt._guildOffset ~= guildHeight then
                        txt:ClearAllPoints()
                        txt:SetPoint("CENTER", container, "CENTER", 0, guildHeight / 2)
                        txt._guildOffset = guildHeight
                    end
                elseif txt._guildOffset then
                    txt:ClearAllPoints()
                    txt:SetPoint("CENTER", container, "CENTER", 0, 0)
                    txt._guildOffset = nil
                end

                -- Reposition lite health bar based on guild visibility
                if container.liteHealthBar then
                    local anchorKey = showSubtitle and "subtitle" or "name"
                    if container.liteHealthBar._lastAnchorKey ~= anchorKey then
                        container.liteHealthBar:ClearAllPoints()
                        PixelUtil.SetPoint(container.liteHealthBar, "TOP", showSubtitle and guild or txt, "BOTTOM", 0, -2, 1, 1)
                        container.liteHealthBar._lastAnchorKey = anchorKey
                    end
                end
                
                local raidIndex = GetRaidTargetIndex(unit)
                if raidIndex then
                    -- Size caching
                    if icon._lastSize ~= ns.c_raidMarkerSize then
                        icon:SetSize(ns.c_raidMarkerSize, ns.c_raidMarkerSize)
                        icon._lastSize = ns.c_raidMarkerSize
                    end
                    -- Position caching
                    if not icon._litePositioned then
                        icon:ClearAllPoints()
                        icon:SetPoint("BOTTOM", txt, "TOP", 0, 2)
                        icon._litePositioned = true
                    end
                    SetRaidTargetIconTexture(icon, raidIndex)
                    icon:Show()
                else
                    icon:Hide()
                end
                
                -- Update lite level text (only if mode is "all" since lite plates are friendly)
                local levelText = container.liteLevelText
                if levelText then
                    if ns.c_levelMode == "all" then
                        local level = UnitLevel(unit)
                        -- Skip if same level as player
                        if level > 0 and level == ns.c_playerLevel then
                            levelText:Hide()
                        else
                            -- Font caching
                            if levelText._lastFont ~= ns.c_font or levelText._lastSize ~= ns.c_friendlyFontSize or levelText._lastOutline ~= ns.c_fontOutline then
                                levelText:SetFont(ns.c_font, ns.c_friendlyFontSize, ns.c_fontOutline)
                                levelText._lastFont = ns.c_font
                                levelText._lastSize = ns.c_friendlyFontSize
                                levelText._lastOutline = ns.c_fontOutline
                            end
                            -- Position caching
                            if not levelText._positioned then
                                levelText:ClearAllPoints()
                                levelText:SetPoint("LEFT", txt, "RIGHT", PixelUtil.GetNearestPixelSize(2, 1), 0)
                                levelText._positioned = true
                            end
                            
                            local color
                            if level <= 0 then
                                color = GetQuestDifficultyColor(999)
                                levelText:SetText("??")
                            else
                                color = GetQuestDifficultyColor(level)
                                levelText:SetText(level)
                            end
                            levelText:SetTextColor(color.r, color.g, color.b)
                            levelText:Show()
                        end
                    else
                        levelText:Hide()
                    end
                end
                
                -- Update lite quest icon
                if ns.UpdateLiteQuestIcon then
                    ns.UpdateLiteQuestIcon(nameplate, unit)
                end
                
                -- Update TurboDebuff for lite plates
                if ns.UpdateLiteTurboDebuff then
                    ns:UpdateLiteTurboDebuff(nameplate, unit)
                end
                
                -- Update lite health bar when damaged
                if ns.c_liteHealthWhenDamaged and container.liteHealthBar then
                    local health = UnitHealth(unit)
                    local maxHealth = UnitHealthMax(unit)
                    if health < maxHealth and maxHealth > 0 then
                        local liteHP = container.liteHealthBar
                        liteHP:SetMinMaxValues(0, maxHealth)
                        liteHP:SetValue(health)
                        local pct = math.floor((health / maxHealth) * 100)
                        container.liteHealthText:SetText(pct .. "%")
                        local r, g = 1, 1
                        if pct < 50 then
                            r, g = 1, pct / 50
                        else
                            r = (100 - pct) / 50
                        end
                        liteHP:SetStatusBarColor(r, g, 0)
                        liteHP:Show()
                    else
                        container.liteHealthBar:Hide()
                    end
                elseif container.liteHealthBar then
                    container.liteHealthBar:Hide()
                end
                
                container:Show()
            else
                if nameplate.liteContainer then
                    nameplate.liteContainer:Hide()
                end
                if nameplate.liteQuestIcon then
                    nameplate.liteQuestIcon:Hide()
                end
                -- Hide lite TurboDebuff when switching to full plate
                if ns.HideLiteTurboDebuff then
                    ns:HideLiteTurboDebuff(nameplate)
                end
                nameplate._isLite = false
                
                -- Create full plate if it doesn't exist (switching from lite to full mode)
                if not nameplate.myPlate and ns.CreatePlateFrame then
                    ns:CreatePlateFrame(nameplate, unit)
                    if nameplate.myPlate then
                        ApplyFPSIncrease(nameplate.myPlate)
                    end
                end
                
                if nameplate.myPlate then
                    nameplate.myPlate.unit = unit
                    nameplate.myPlate.cachedGUID = UnitGUID(unit)
                    nameplate.myPlate:Show()
                    ns.unitToPlate[unit] = nameplate.myPlate
                    if ns.UpdatePlateStyle then ns:UpdatePlateStyle(nameplate.myPlate) end
                    -- Only do FullPlateUpdate if plate hasn't been initialized for this unit
                    -- Settings changes only need UpdatePlateStyle, not full unit data refresh
                    if not nameplate.myPlate._initialized or nameplate.myPlate._lastUnit ~= unit then
                        if ns.FullPlateUpdate then ns:FullPlateUpdate(nameplate.myPlate, unit) end
                        nameplate.myPlate._initialized = true
                        nameplate.myPlate._lastUnit = unit
                    end
                    
                    -- Refresh TurboDebuff on settings change (applies new size/anchor immediately)
                    if ns.UpdateTurboDebuff then
                        ns:UpdateTurboDebuff(nameplate.myPlate, unit)
                    end
                end
            end
        end
    end
    if ns.UpdatePreview then ns:UpdatePreview() end
end

function ns:GetNamePlateUnit(nameplate)
    return nameplate._unit
end

-- RefreshPlateForUnit: Re-evaluates plate type when faction changes
-- Called from UNIT_FACTION handler - when NPC becomes hostile/friendly, plate type may need to swap
function ns:RefreshPlateForUnit(unit)
    local nameplate = GetNamePlateForUnit(unit)
    if nameplate then
        -- Re-run the full plate setup logic (determines lite vs full plate)
        OnNamePlateAdded(nil, unit, nameplate)
    end
end

EventRegistry:RegisterCallback("NamePlateManager.UnitAdded", OnNamePlateAdded)
EventRegistry:RegisterCallback("NamePlateManager.UnitRemoved", OnNamePlateRemoved)

-- Fallback: traditional event for cases where EventRegistry callback doesn't fire
-- (race condition with ActiveNamePlateUnits or C-level hide not triggering OnHide hook)
local nameplateEventFallback = CreateFrame("Frame")
nameplateEventFallback:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
nameplateEventFallback:SetScript("OnEvent", function(_, _, unit)
    local nameplate = GetNamePlateForUnit(unit)
    if nameplate then
        OnNamePlateRemoved(nil, unit, nameplate)
    end
end)

SLASH_TURBOPLATES1 = "/tp"
SLASH_TURBOPLATES2 = "/turboplates"
SlashCmdList["TURBOPLATES"] = function(msg)
    if msg and msg ~= "" then
        local cmd, args = msg:match("^(%S+)%s*(.*)$")
        cmd = cmd and cmd:lower()
        
        if cmd == "stacking" then
            if ns.HandleStackingCommand then
                ns.HandleStackingCommand(args)
            end
            return
        end
    end
    
    if ns.ToggleGUI then ns:ToggleGUI() end
end
