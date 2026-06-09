local addonName, ns = ...

-- TurboDebuffs: BigDebuffs-style single priority aura display for nameplates
-- Ported from BigDebuffs by Jordon with Ascension fixes

local GetTime = GetTime
local UnitGUID = UnitGUID
local GetSpellInfo = GetSpellInfo
local CreateFrame = CreateFrame
local ceil = math.ceil
local floor = math.floor
local pairs = pairs
local type = type
local format = string.format
local AuraUtil = AuraUtil
local rawset = rawset
local rawget = rawget
local UnitIsUnit = UnitIsUnit
local UnitCreatureType = UnitCreatureType
local UnitIsFriend = UnitIsFriend

-- Cached blacklist reference (set after initialization)
local AuraBlacklist

-- Timer colors (match Auras.lua)
local COLOR_RED = { 1.0, 0.2, 0.2 }
local COLOR_ORANGE = { 1.0, 0.5, 0.2 }
local COLOR_YELLOW = { 1.0, 1.0, 0.2 }
local COLOR_WHITE = { 1.0, 1.0, 1.0 }

-- Cached timer strings (avoids garbage from string concatenation)
local cachedMinutes = setmetatable({}, { __index = function(t, k)
    local v = k .. "m"
    rawset(t, k, v)
    return v
end })
local cachedHours = setmetatable({}, { __index = function(t, k)
    local v = k .. "h"
    rawset(t, k, v)
    return v
end })
local cachedDecimals = setmetatable({}, { __index = function(t, k)
    local v = format("%.1f", k / 10)
    rawset(t, k, v)
    return v
end })

-- =============================================================================
-- SPELL DATABASE (from BigDebuffs) -- now in ServerData.lua
-- =============================================================================
local Spells = ns.ServerData.Active.TurboDebuffs

-- Expose for external access if needed
ns.TurboDebuffsSpells = Spells

-- =============================================================================
-- ASCENSION FIX: Name-based spell lookup
-- Handles Ascension servers using different spell IDs for same spells
-- =============================================================================
local SpellsByName = {}

-- Pre-resolved parent names (avoids GetSpellInfo in hot path)
local ParentNames = {}

local function BuildSpellNameTable()
    for spellId, spellData in pairs(Spells) do
        if type(spellId) == "number" then
            local spellName = GetSpellInfo(spellId)
            if spellName then
                if not SpellsByName[spellName] then
                    SpellsByName[spellName] = {}
                end
                for k, v in pairs(spellData) do
                    SpellsByName[spellName][k] = v
                end
                SpellsByName[spellName].originalId = spellId
            end
            -- Pre-resolve parent names
            if spellData.parent then
                local parentName = GetSpellInfo(spellData.parent)
                if parentName then
                    ParentNames[spellData.parent] = parentName
                end
            end
        end
    end
    -- Cache blacklist reference after init
    AuraBlacklist = ns.AuraBlacklist
end

-- =============================================================================
-- PRIORITY SYSTEM
-- =============================================================================

-- Get priority for a spell based on its category
local function GetAuraPriority(name, id)
    local spellData = Spells[id]
    
    -- Ascension fix: fallback to name lookup
    if not spellData and name then
        spellData = SpellsByName[name]
        if spellData and spellData.originalId then
            id = spellData.originalId
        end
    end
    
    if not spellData then return nil end
    
    -- Resolve parent spell
    if spellData.parent then
        local parentData = Spells[spellData.parent]
        if not parentData then
            local parentName = ParentNames[spellData.parent]
            if parentName then
                parentData = SpellsByName[parentName]
            end
        end
        if parentData then
            id = spellData.parent
            spellData = parentData
        end
    end
    
    local spellType = spellData.type
    if not spellType then return nil end
    
    -- Check if category is enabled
    local cfg = ns.c_turboDebuffs or {}
    if cfg[spellType] == false then return nil end
    
    -- Return category priority
    local priorities = cfg.priority or {}
    return priorities[spellType] or 0
end

-- =============================================================================
-- AURA SCANNING (using AuraUtil.ForEachAura for efficiency)
-- Returns winning aura: icon, expires, duration, priority, auraType, spellId
-- =============================================================================

-- Module-local state for callback (avoids allocations)
local scanTime = 0
local scanBest = {
    icon = nil,
    expires = 0,
    duration = 0,
    priority = 0,
    timeLeft = 0,
    auraType = nil,
    spellId = nil,
}
local scanMindControlled = false

-- Reset scan state before each unit scan
local function ResetScanState()
    scanTime = GetTime()
    scanBest.icon = nil
    scanBest.expires = 0
    scanBest.duration = 0
    scanBest.priority = 0
    scanBest.timeLeft = 0
    scanBest.auraType = nil
    scanBest.spellId = nil
    scanMindControlled = false
end

-- Callback for AuraUtil.ForEachAura - checks each aura against spell database
local function TurboDebuffAuraCallback(name, rank, icon, count, debuffType, duration, expires, caster, canStealOrPurge, nameplateShowPersonal, spellId)
    if not name or not spellId then return end
    
    -- Mind Control check - hide TurboDebuff entirely if found
    if spellId == 605 then
        scanMindControlled = true
        return
    end
    
    -- Blacklist check (uses upvalued reference)
    if AuraBlacklist and rawget(AuraBlacklist, spellId) then return end
    
    -- Fast reject: not in our spell database
    local spellData = Spells[spellId]
    if not spellData and name then
        spellData = SpellsByName[name]
    end
    if not spellData then return end
    
    -- Get priority (handles parent resolution, category enable check)
    local p = GetAuraPriority(name, spellId)
    if not p then return end
    
    -- Calculate time remaining
    local timeLeft = (expires and expires > 0) and (expires - scanTime) or 0
    
    -- Reject expired auras (non-permanent with no time left)
    if expires and expires > 0 and timeLeft <= 0 then return end
    
    -- Compare: higher priority wins, tiebreaker = more time remaining
    if p > scanBest.priority or (p == scanBest.priority and timeLeft > scanBest.timeLeft) then
        scanBest.priority = p
        scanBest.icon = icon
        scanBest.expires = expires or 0
        scanBest.duration = duration or 0
        scanBest.timeLeft = timeLeft
        scanBest.spellId = spellId
        
        -- Resolve aura type (with parent lookup using pre-resolved names)
        local data = spellData
        if data.parent then
            local parentName = ParentNames[data.parent]
            local parentData = Spells[data.parent] or (parentName and SpellsByName[parentName])
            if parentData then data = parentData end
        end
        scanBest.auraType = data.type
    end
end

-- Scan unit auras using ForEachAura (2 API calls vs 80 UnitDebuff/UnitBuff loops)
local function ScanUnitAuras(unit)
    ResetScanState()
    
    -- Scan debuffs (HARMFUL)
    AuraUtil.ForEachAura(unit, "HARMFUL", 40, TurboDebuffAuraCallback)
    
    -- Early exit if mind controlled
    if scanMindControlled then return nil end
    
    -- Scan buffs (HELPFUL)
    AuraUtil.ForEachAura(unit, "HELPFUL", 40, TurboDebuffAuraCallback)
    
    -- Early exit if mind controlled (found during buff scan)
    if scanMindControlled then return nil end
    
    -- Return best candidate
    if scanBest.icon then
        return scanBest.icon, scanBest.expires, scanBest.duration, scanBest.priority, scanBest.auraType, scanBest.spellId
    end
    return nil
end

-- =============================================================================
-- FRAME CREATION AND DISPLAY
-- =============================================================================

local PixelUtil = PixelUtil
local BORDER_TEX = "Interface\\Buttons\\WHITE8X8"
local BORDER_ALPHA = 0.9

-- Create pixel-perfect 1px border using PixelUtil
-- Uses shared ns.CreateTextureBorder if available, otherwise creates manually
local function CreateIconBorder(frame)
    -- Use shared border function if available (defined in Nameplates.lua)
    if ns.CreateTextureBorder then
        local border = ns.CreateTextureBorder(frame, 1)
        border:SetColor(0, 0, 0, BORDER_ALPHA)
        return border
    end
    
    -- Fallback: manual creation with PixelUtil
    local pixelSize = PixelUtil.GetNearestPixelSize(1, frame:GetEffectiveScale(), 1)
    local border = ns.BorderMethods and setmetatable({}, ns.BorderMethods) or {}
    
    border.top = frame:CreateTexture(nil, "OVERLAY")
    border.top:SetTexture(BORDER_TEX)
    border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", -pixelSize, pixelSize)
    border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", pixelSize, pixelSize)
    PixelUtil.SetHeight(border.top, pixelSize, 1)
    
    border.bottom = frame:CreateTexture(nil, "OVERLAY")
    border.bottom:SetTexture(BORDER_TEX)
    border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -pixelSize, -pixelSize)
    border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", pixelSize, -pixelSize)
    PixelUtil.SetHeight(border.bottom, pixelSize, 1)
    
    border.left = frame:CreateTexture(nil, "OVERLAY")
    border.left:SetTexture(BORDER_TEX)
    border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", -pixelSize, 0)
    border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -pixelSize, 0)
    PixelUtil.SetWidth(border.left, pixelSize, 1)
    
    border.right = frame:CreateTexture(nil, "OVERLAY")
    border.right:SetTexture(BORDER_TEX)
    border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", pixelSize, 0)
    border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", pixelSize, 0)
    PixelUtil.SetWidth(border.right, pixelSize, 1)
    
    -- Add methods if metatable not available
    if not ns.BorderMethods then
        function border:SetColor(r, g, b, a)
            a = a and math.min(a, BORDER_ALPHA) or BORDER_ALPHA
            self.top:SetVertexColor(r, g, b, a)
            self.bottom:SetVertexColor(r, g, b, a)
            self.left:SetVertexColor(r, g, b, a)
            self.right:SetVertexColor(r, g, b, a)
        end
    end
    
    border:SetColor(0, 0, 0, BORDER_ALPHA)
    return border
end

-- Create TurboDebuff frame for a nameplate
local function CreateTurboDebuffFrame(myPlate)
    local cfg = ns.c_turboDebuffs or {}
    local size = cfg.size or 32
    
    local frame = CreateFrame("Frame", nil, myPlate)
    PixelUtil.SetSize(frame, size, size, 1, 1)
    frame:SetFrameLevel(myPlate:GetFrameLevel() + 10)
    frame.cachedSize = size
    
    -- Icon texture
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Pixel-perfect border
    frame.border = CreateIconBorder(frame)
    
    -- Timer text (fake-centered via LEFT+RIGHT span to avoid sub-pixel jitter)
    frame.timer = frame:CreateFontString(nil, "OVERLAY")
    frame.timer:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.timer:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    local font = ns.c_font or "Fonts\\FRIZQT__.TTF"
    local timerSize = cfg.timerSize or (size / 2.5)
    ns:SetFontSafe(frame.timer, font, timerSize, "OUTLINE")
    frame.timer:SetTextColor(1, 1, 1)
    frame.timer:SetJustifyH("CENTER")
    frame.timer:SetJustifyV("MIDDLE")
    
    -- State
    frame.timeEnd = 0
    frame.lastTimerText = nil
    frame.cachedAnchor = nil
    frame.cachedXOff = nil
    frame.cachedYOff = nil
    frame.cachedAnchorFrame = nil
    
    -- OnUpdate for timer display with color coding
    frame:SetScript("OnUpdate", function(self, elapsed)
        local remain = self.timeEnd - GetTime()
        if remain > 0 then
            local text
            if remain <= 3 then
                text = cachedDecimals[floor(remain * 10)]
            elseif remain <= 60 then
                text = ceil(remain)
            elseif remain <= 3600 then
                text = cachedMinutes[ceil(remain / 60)]
            else
                text = cachedHours[ceil(remain / 3600)]
            end
            if text ~= self.lastTimerText then
                self.timer:SetText(text)
                self.lastTimerText = text
            end
            -- Color based on time remaining
            if remain < 1 then
                self.timer:SetTextColor(COLOR_RED[1], COLOR_RED[2], COLOR_RED[3])
            elseif remain < 3 then
                self.timer:SetTextColor(COLOR_ORANGE[1], COLOR_ORANGE[2], COLOR_ORANGE[3])
            elseif remain < 60 then
                self.timer:SetTextColor(COLOR_YELLOW[1], COLOR_YELLOW[2], COLOR_YELLOW[3])
            else
                self.timer:SetTextColor(COLOR_WHITE[1], COLOR_WHITE[2], COLOR_WHITE[3])
            end
        elseif self.lastTimerText then
            -- Aura expired - hide frame (safety net for delayed UNIT_AURA)
            self.timer:SetText("")
            self.lastTimerText = nil
            self:Hide()
        end
    end)
    
    frame:Hide()
    return frame
end

-- Update TurboDebuff display for a plate
local function UpdateTurboDebuff(myPlate, unit)
    if not myPlate or not unit then return end
    
    local cfg = ns.c_turboDebuffs or {}
    if not cfg.enabled then
        if myPlate.turboDebuff then myPlate.turboDebuff:Hide() end
        return
    end
    
    -- Always hide on player's own nameplate and totems
    if UnitIsUnit("player", unit) or UnitCreatureType(unit) == "Totem" then
        if myPlate.turboDebuff then myPlate.turboDebuff:Hide() end
        return
    end
    
    -- Hide for friendlies if disabled
    if not cfg.showFriendly and UnitIsFriend("player", unit) then
        if myPlate.turboDebuff then myPlate.turboDebuff:Hide() end
        return
    end
    
    -- Create frame if needed
    if not myPlate.turboDebuff then
        myPlate.turboDebuff = CreateTurboDebuffFrame(myPlate)
    end
    
    local frame = myPlate.turboDebuff
    
    -- Scan for winning aura
    local icon, expires, duration, priority, auraType, spellId = ScanUnitAuras(unit)
    
    if icon then
        -- Full plates always use full plate settings
        -- (Lite plates are handled separately by UpdateLiteTurboDebuff)
        local size = cfg.size or 32
        local anchor = cfg.anchor or "LEFT"
        local xOff = cfg.xOffset or 0
        local yOff = cfg.yOffset or 0
        local timerSize = cfg.timerSize or (size / 2.5)
        
        -- Update size (cached to avoid redundant PixelUtil calls)
        if frame.cachedSize ~= size then
            PixelUtil.SetSize(frame, size, size, 1, 1)
            frame.cachedSize = size
        end
        
        -- Update timer font size (cached to avoid redundant calls)
        local font = ns.c_font or "Fonts\\FRIZQT__.TTF"
        if frame.cachedFont ~= font or frame.cachedFontSize ~= timerSize then
            ns:SetFontSafe(frame.timer, font, timerSize, "OUTLINE")
            frame.cachedFont = font
            frame.cachedFontSize = timerSize
        end
        
        -- Position anchored to healthBar (cached to avoid redundant repositioning)
        local anchorFrame = myPlate.hp or myPlate
        if frame.cachedAnchor ~= anchor or frame.cachedXOff ~= xOff or frame.cachedYOff ~= yOff or frame.cachedAnchorFrame ~= anchorFrame then
            frame:ClearAllPoints()
            if anchor == "LEFT" then
                frame:SetPoint("RIGHT", anchorFrame, "LEFT", -4 + xOff, yOff)
            elseif anchor == "RIGHT" then
                frame:SetPoint("LEFT", anchorFrame, "RIGHT", 4 + xOff, yOff)
            elseif anchor == "TOP" then
                frame:SetPoint("BOTTOM", anchorFrame, "TOP", xOff, 4 + yOff)
            elseif anchor == "BOTTOM" then
                frame:SetPoint("TOP", anchorFrame, "BOTTOM", xOff, -4 + yOff)
            else
                frame:SetPoint("LEFT", anchorFrame, "LEFT", -size - 4 + xOff, yOff)
            end
            frame.cachedAnchor = anchor
            frame.cachedXOff = xOff
            frame.cachedYOff = yOff
            frame.cachedAnchorFrame = anchorFrame
        end
        
        -- Update icon (cached to avoid redundant SetTexture calls)
        if frame.cachedSpellId ~= spellId then
            frame.icon:SetTexture(icon)
            frame.cachedSpellId = spellId
        end
        
        -- Update timer
        if duration and duration > 0.2 then
            frame.timeEnd = expires
        else
            -- Permanent aura
            frame.timeEnd = 0
            frame.timer:SetText("")
            frame.lastTimerText = nil
        end
        
        frame:Show()
    else
        -- Clear timer state before hiding
        frame.timer:SetText("")
        frame.lastTimerText = nil
        frame.cachedSpellId = nil
        frame:Hide()
    end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================
ns.TurboDebuffs = {
    Spells = Spells,
    SpellsByName = SpellsByName,
    GetAuraPriority = GetAuraPriority,
    ScanUnitAuras = ScanUnitAuras,
    UpdateTurboDebuff = UpdateTurboDebuff,
    CreateTurboDebuffFrame = CreateTurboDebuffFrame,
}

-- Called on UNIT_AURA for nameplate units (full plates)
function ns:UpdateTurboDebuff(myPlate, unit)
    UpdateTurboDebuff(myPlate, unit)
end

-- Called when full plate is hidden
function ns:HideTurboDebuff(myPlate)
    if myPlate and myPlate.turboDebuff then
        myPlate.turboDebuff.timer:SetText("")
        myPlate.turboDebuff.lastTimerText = nil
        myPlate.turboDebuff.expirationTime = nil
        myPlate.turboDebuff.spellID = nil
        myPlate.turboDebuff.duration = nil
        myPlate.turboDebuff.cachedSpellId = nil
        myPlate.turboDebuff:Hide()
    end
end

-- Update TurboDebuff for lite plates (friendly name-only)
-- Uses liteContainer and liteNameText as anchor
local function UpdateLiteTurboDebuff(nameplate, unit)
    if not nameplate or not unit then return end
    
    local cfg = ns.c_turboDebuffs or {}
    if not cfg.enabled then
        if nameplate.liteTurboDebuff then nameplate.liteTurboDebuff:Hide() end
        return
    end
    
    -- Lite plates are always friendly
    if not cfg.showFriendly then
        if nameplate.liteTurboDebuff then nameplate.liteTurboDebuff:Hide() end
        return
    end
    
    local container = nameplate.liteContainer
    if not container then return end
    
    -- Create frame if needed (parented to liteContainer)
    if not nameplate.liteTurboDebuff then
        nameplate.liteTurboDebuff = CreateTurboDebuffFrame(container)
    end
    
    local frame = nameplate.liteTurboDebuff
    
    -- Scan for winning aura
    local icon, expires, duration, priority, auraType, spellId = ScanUnitAuras(unit)
    
    if icon then
        -- Use name-only settings
        local size = cfg.nameOnlySize or 24
        local anchor = cfg.nameOnlyAnchor or "LEFT"
        local xOff = cfg.nameOnlyXOffset or 0
        local yOff = cfg.nameOnlyYOffset or 0
        local timerSize = cfg.nameOnlyTimerSize or (size / 2.5)
        
        -- Update size (cached)
        if frame.cachedSize ~= size then
            PixelUtil.SetSize(frame, size, size, 1, 1)
            frame.cachedSize = size
        end
        
        -- Update timer font size (cached)
        local font = ns.c_font or "Fonts\\FRIZQT__.TTF"
        if frame.cachedFont ~= font or frame.cachedFontSize ~= timerSize then
            ns:SetFontSafe(frame.timer, font, timerSize, "OUTLINE")
            frame.cachedFont = font
            frame.cachedFontSize = timerSize
        end
        
        -- Position - anchor to liteNameText (cached)
        local anchorFrame = container.liteNameText or container
        if frame.cachedAnchor ~= anchor or frame.cachedXOff ~= xOff or frame.cachedYOff ~= yOff or frame.cachedAnchorFrame ~= anchorFrame then
            frame:ClearAllPoints()
            if anchor == "LEFT" then
                frame:SetPoint("RIGHT", anchorFrame, "LEFT", -4 + xOff, yOff)
            elseif anchor == "RIGHT" then
                frame:SetPoint("LEFT", anchorFrame, "RIGHT", 4 + xOff, yOff)
            elseif anchor == "TOP" then
                frame:SetPoint("BOTTOM", anchorFrame, "TOP", xOff, 4 + yOff)
            elseif anchor == "BOTTOM" then
                frame:SetPoint("TOP", anchorFrame, "BOTTOM", xOff, -4 + yOff)
            else
                frame:SetPoint("LEFT", anchorFrame, "LEFT", -size - 4 + xOff, yOff)
            end
            frame.cachedAnchor = anchor
            frame.cachedXOff = xOff
            frame.cachedYOff = yOff
            frame.cachedAnchorFrame = anchorFrame
        end
        
        -- Update icon (cached to avoid redundant SetTexture calls)
        if frame.cachedSpellId ~= spellId then
            frame.icon:SetTexture(icon)
            frame.cachedSpellId = spellId
        end
        
        -- Update timer
        if duration and duration > 0.2 then
            frame.timeEnd = expires
        else
            -- Permanent aura
            frame.timeEnd = 0
            frame.timer:SetText("")
            frame.lastTimerText = nil
        end
        
        frame:Show()
    else
        frame.timer:SetText("")
        frame.lastTimerText = nil
        frame.cachedSpellId = nil
        frame:Hide()
    end
end

-- Called for lite plates
function ns:UpdateLiteTurboDebuff(nameplate, unit)
    UpdateLiteTurboDebuff(nameplate, unit)
end

-- Called when lite plate is hidden
function ns:HideLiteTurboDebuff(nameplate)
    if nameplate and nameplate.liteTurboDebuff then
        nameplate.liteTurboDebuff.timer:SetText("")
        nameplate.liteTurboDebuff.lastTimerText = nil
        nameplate.liteTurboDebuff.expirationTime = nil
        nameplate.liteTurboDebuff.spellID = nil
        nameplate.liteTurboDebuff.duration = nil
        nameplate.liteTurboDebuff.cachedSpellId = nil
        nameplate.liteTurboDebuff:Hide()
    end
end

-- Initialize at PLAYER_LOGIN
function ns:InitTurboDebuffs()
    BuildSpellNameTable()
end

-- Cache settings
function ns:CacheTurboDebuffsSettings()
    local td = TurboPlatesDB and TurboPlatesDB.turboDebuffs or ns.defaults.turboDebuffs or {}
    local defaults = ns.defaults.turboDebuffs or {}
    
    ns.c_turboDebuffs = {
        enabled = td.enabled == true,  -- Disabled by default
        showFriendly = td.showFriendly == true,
        
        -- Full plates
        size = td.size or defaults.size or 32,
        anchor = td.anchor or defaults.anchor or "LEFT",
        xOffset = td.xOffset or defaults.xOffset or 0,
        yOffset = td.yOffset or defaults.yOffset or 0,
        timerSize = td.timerSize or defaults.timerSize or 14,
        
        -- Name-only plates
        nameOnlyAnchor = td.nameOnlyAnchor or defaults.nameOnlyAnchor or "LEFT",
        nameOnlySize = td.nameOnlySize or defaults.nameOnlySize or 24,
        nameOnlyTimerSize = td.nameOnlyTimerSize or defaults.nameOnlyTimerSize or 10,
        nameOnlyXOffset = td.nameOnlyXOffset or defaults.nameOnlyXOffset or 0,
        nameOnlyYOffset = td.nameOnlyYOffset or defaults.nameOnlyYOffset or 0,
        
        -- Category enables
        immunities = td.immunities ~= false,
        cc = td.cc ~= false,
        silence = td.silence ~= false,
        interrupts = td.interrupts ~= false,
        roots = td.roots ~= false,
        disarm = td.disarm ~= false,
        buffs_defensive = td.buffs_defensive == true,  -- Off by default
        buffs_offensive = td.buffs_offensive == true,  -- Off by default
        buffs_other = td.buffs_other == true,          -- Off by default
        snare = td.snare == true,                      -- Off by default
        
        -- Priorities
        priority = td.priority or defaults.priority or {
            immunities = 80,
            cc = 70,
            silence = 60,
            interrupts = 55,
            roots = 50,
            disarm = 45,
            buffs_defensive = 40,
            buffs_offensive = 35,
            buffs_other = 30,
            snare = 25,
        },
    }
end
