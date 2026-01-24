local addonName, ns = ...

-- =============================================================================
-- LOCALIZED GLOBALS
-- =============================================================================
local UnitExists = UnitExists
local UnitIsFriend = UnitIsFriend
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local pairs, ipairs = pairs, ipairs
local tinsert, tremove, wipe = table.insert, table.remove, table.wipe
local floor = math.floor
local format = string.format
local rawget, rawset = rawget, rawset
local setmetatable = setmetatable
local unpack = unpack
local CreateFrame = CreateFrame
local C_NamePlate = C_NamePlate
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local C_Timer = C_Timer
local AuraUtil = AuraUtil
local sort = table.sort
local strsub = string.sub
local PixelUtil = PixelUtil

-- Ascension API (may or may not exist)
local C_Hook = C_Hook

-- =============================================================================
-- CREATE TEXTURE BORDER UTILITY (uses shared system from Nameplates.lua)
-- =============================================================================
local function CreateTextureBorder(parent, thickness)
    -- Use shared border system if available, otherwise create local
    if ns.CreateTextureBorder then
        return ns.CreateTextureBorder(parent, thickness)
    end
    
    -- Fallback (shouldn't happen if load order is correct)
    thickness = thickness or 1
    local pixelSize = PixelUtil.GetNearestPixelSize(thickness, parent:GetEffectiveScale(), 1)
    
    -- Use shared metatable if available, otherwise create minimal border
    local border = ns.BorderMethods and setmetatable({}, ns.BorderMethods) or {}
    local tex = ns.BORDER_TEX or "Interface\\Buttons\\WHITE8X8"
    
    -- Use OVERLAY layer so borders render above StatusBar fill
    border.top = parent:CreateTexture(nil, "OVERLAY")
    border.top:SetTexture(tex)
    border.top:SetPoint("TOPLEFT", parent, "TOPLEFT", -pixelSize, pixelSize)
    border.top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", pixelSize, pixelSize)
    PixelUtil.SetHeight(border.top, pixelSize, 1)
    
    border.bottom = parent:CreateTexture(nil, "OVERLAY")
    border.bottom:SetTexture(tex)
    border.bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -pixelSize, -pixelSize)
    border.bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", pixelSize, -pixelSize)
    PixelUtil.SetHeight(border.bottom, pixelSize, 1)
    
    border.left = parent:CreateTexture(nil, "OVERLAY")
    border.left:SetTexture(tex)
    border.left:SetPoint("TOPLEFT", parent, "TOPLEFT", -pixelSize, 0)
    border.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -pixelSize, 0)
    PixelUtil.SetWidth(border.left, pixelSize, 1)
    
    border.right = parent:CreateTexture(nil, "OVERLAY")
    border.right:SetTexture(tex)
    border.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", pixelSize, 0)
    border.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", pixelSize, 0)
    PixelUtil.SetWidth(border.right, pixelSize, 1)
    
    -- Only add methods if metatable not available
    if not ns.BorderMethods then
        local BORDER_ALPHA = ns.BORDER_ALPHA or 0.9
        function border:SetColor(r, g, b, a)
            a = a and math.min(a, BORDER_ALPHA) or BORDER_ALPHA
            self.top:SetVertexColor(r, g, b, a)
            self.bottom:SetVertexColor(r, g, b, a)
            self.left:SetVertexColor(r, g, b, a)
            self.right:SetVertexColor(r, g, b, a)
        end
        
        function border:Show()
            self.top:Show(); self.bottom:Show()
            self.left:Show(); self.right:Show()
        end
        
        function border:Hide()
            self.top:Hide(); self.bottom:Hide()
            self.left:Hide(); self.right:Hide()
        end
        
        function border:GetColor()
            return self.top:GetVertexColor()
        end
    end
    
    border:SetColor(0, 0, 0, ns.BORDER_ALPHA or 0.9)
    return border
end

-- =============================================================================
-- SPELL ICON CACHE
-- Lazy metatable caches icons on first access
-- =============================================================================
local IconCache = setmetatable({}, {
    __index = function(t, spellID)
        -- Only called if spellID not in cache
        local _, _, icon = GetSpellInfo(spellID)
        if icon then
            rawset(t, spellID, icon)  -- rawset bypasses __newindex
        end
        return icon
    end
})

-- Get cached icon - prefers aura data we already have
local function GetCachedIcon(spellID, iconFromAura)
    if iconFromAura then
        -- Cache from aura data (zero API calls)
        local cached = rawget(IconCache, spellID)
        if not cached then
            rawset(IconCache, spellID, iconFromAura)
        end
        return iconFromAura
    end
    -- Fallback: metatable triggers GetSpellInfo
    return IconCache[spellID]
end

-- =============================================================================
-- TIME STRING CACHE
-- Lazy metatable caches formatted time strings
-- =============================================================================
local timeCache = setmetatable({}, {
    __index = function(t, k)
        local v
        if k >= 60 then
            v = format("%dm", floor(k / 60))
        elseif k >= 1 then
            -- 1-59 seconds: whole seconds
            v = format("%d", floor(k))
        else
            -- Sub-second: one decimal place
            v = format("%.1f", k)
        end
        rawset(t, k, v)
        return v
    end
})

-- Get cached time string (rounds to appropriate precision)
local function GetCachedTimeString(seconds)
    if seconds >= 60 then
        return timeCache[floor(seconds / 60) * 60]  -- Round to minutes
    elseif seconds >= 10 then
        return timeCache[floor(seconds)]  -- Whole seconds
    elseif seconds >= 1 then
        return timeCache[floor(seconds)]  -- Whole seconds
    else
        -- Sub-second: round to 0.1s precision for cache efficiency
        local rounded = floor(seconds * 10) / 10
        return timeCache[rounded]
    end
end

-- =============================================================================
-- AURA DATA TABLE POOL
-- =============================================================================
local auraDataPool = {}
local MAX_DATA_POOL_SIZE = 100

local function AcquireAuraData()
    local data = tremove(auraDataPool)
    if not data then
        data = {}
    end
    return data
end

local function ReleaseAuraData(data)
    wipe(data)
    if #auraDataPool < MAX_DATA_POOL_SIZE then
        tinsert(auraDataPool, data)
    end
end

-- Release all aura data tables from a list back to pool
local function ReleaseAllAuraData(list)
    for i = #list, 1, -1 do
        ReleaseAuraData(list[i])
        list[i] = nil
    end
end

-- =============================================================================
-- REUSABLE COLLECTION TABLES
-- =============================================================================
local debuffCollector = {}
local buffCollector = {}

-- =============================================================================
-- BORDER COLORS
-- =============================================================================
local BORDER_COLORS = {
    Magic   = { 0.20, 0.60, 1.00 },  -- Blue (dispellable buffs on enemies)
    Curse   = { 0.60, 0.00, 1.00 },  -- Purple
    Disease = { 0.60, 0.40, 0.00 },  -- Brown
    Poison  = { 0.00, 0.60, 0.00 },  -- Green
    none    = { 0.80, 0.00, 0.00 },  -- Red (physical/no type debuffs)
}
local BUFF_COLOR_WHITE = { 1.00, 1.00, 1.00 }  -- White (non-dispellable buffs on enemies)
local BUFF_COLOR_GREEN = { 0.20, 0.80, 0.20 }  -- Green (all buffs on personal bar)

-- =============================================================================
-- TIMER COLORS
-- =============================================================================
local COLOR_RED = { 1.0, 0.2, 0.2 }
local COLOR_ORANGE = { 1.0, 0.5, 0.2 }
local COLOR_YELLOW = { 1.0, 1.0, 0.2 }
local COLOR_WHITE = { 1.0, 1.0, 1.0 }

-- =============================================================================
-- TEXT ANCHOR POSITIONS
-- INNER positioning: Text stays inside the icon bounds
-- =============================================================================
local DURATION_ANCHORS = {
    -- {textPoint, iconPoint, offsetX, offsetY}
    TOP         = { "TOP", "TOP", 0, -2 },
    TOPLEFT     = { "TOPLEFT", "TOPLEFT", 2, -2 },
    TOPRIGHT    = { "TOPRIGHT", "TOPRIGHT", -2, -2 },
    CENTER      = { "CENTER", "CENTER", 0, 0 },
    BOTTOM      = { "BOTTOM", "BOTTOM", 0, -2 },
    BOTTOMLEFT  = { "BOTTOMLEFT", "BOTTOMLEFT", 2, 2 },
    BOTTOMRIGHT = { "BOTTOMRIGHT", "BOTTOMRIGHT", -2, 2 },
}

-- Stack anchors: Same inner logic with slight offset to avoid overlap with duration
local STACK_ANCHORS = {
    TOP         = { "TOP", "TOP", 0, 3 },
    TOPLEFT     = { "TOPLEFT", "TOPLEFT", -3, 3 },
    TOPRIGHT    = { "TOPRIGHT", "TOPRIGHT", 3, 3 },
    CENTER      = { "CENTER", "CENTER", 0, 0 },
    BOTTOM      = { "BOTTOM", "BOTTOM", 0, -3 },
    BOTTOMLEFT  = { "BOTTOMLEFT", "BOTTOMLEFT", -3, -3 },
    BOTTOMRIGHT = { "BOTTOMRIGHT", "BOTTOMRIGHT", -3, -3 },
}

-- =============================================================================
-- PENDING POSITION PLATES
-- Batch plate repositioning into a single timer callback
-- =============================================================================
local pendingPositionPlates = {}
local pendingPositionTimer = nil

local function ProcessPendingPositions()
    pendingPositionTimer = nil  -- Clear timer reference
    for plate in pairs(pendingPositionPlates) do
        plate._auraPositionPending = nil
        -- Only reposition if plate still exists and has containers
        if plate and plate.debuffContainer then
            ns:UpdateAuraPositions(plate)
        end
    end
    wipe(pendingPositionPlates)  -- Clear the queue
end

-- =============================================================================
-- AURA ICON CREATION
-- Icon with square border, duration text, and stack count
-- =============================================================================
local BORDER_SIZE = 1  -- 1px thick square border

local function CreateAuraIcon(parent)
    local icon = CreateFrame("Frame", nil, parent)  -- No BackdropTemplate needed
    icon:SetSize(20, 20)
    icon:EnableMouse(false)  -- Pass through clicks
    
    -- Icon texture fills frame (border extends outside via CreateTextureBorder)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- 30% zoom
    
    -- Pixel-perfect texture border (extends outside the frame)
    icon.border = CreateTextureBorder(icon, BORDER_SIZE)
    
    -- Duration text (bottom center)
    icon.duration = icon:CreateFontString(nil, "OVERLAY")
    icon.duration:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    icon.duration:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
    icon.duration:SetTextColor(1, 1, 1)
    
    -- Stack count (top right)
    icon.count = icon:CreateFontString(nil, "OVERLAY")
    icon.count:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    icon.count:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 2, 2)
    icon.count:SetTextColor(1, 1, 1)
    
    return icon
end

-- =============================================================================
-- ICON FRAME POOL
-- =============================================================================
local MAX_POOL_SIZE = 50  -- Prevent unbounded pool growth

local AuraPool = {
    inactive = {},    -- Stack of released icons ready for reuse
}

function AuraPool:Acquire(parent)
    local icon = tremove(self.inactive)
    if not icon then
        icon = CreateAuraIcon(parent)
    end
    icon:SetParent(parent)
    return icon
end

function AuraPool:Release(icon)
    if not icon then return end
    icon:Hide()
    icon:ClearAllPoints()
    icon:SetScript("OnUpdate", nil)
    icon.spellID = nil
    icon.expires = nil
    icon.elapsed = nil
    tinsert(self.inactive, icon)
end

function AuraPool:ReleaseAll(container)
    if not container or not container.icons then return end
    for i = #container.icons, 1, -1 do
        self:Release(container.icons[i])
        container.icons[i] = nil
    end
    container.displayedCount = 0
end

-- Release auras when plate is removed (stops OnUpdate timers, returns icons to pool)
function ns:CleanupPlateAuras(myPlate)
    if myPlate.debuffContainer then
        AuraPool:ReleaseAll(myPlate.debuffContainer)
    end
    if myPlate.buffContainer then
        AuraPool:ReleaseAll(myPlate.buffContainer)
    end
end

-- Trim pool to prevent unbounded growth (called on zone change)
function AuraPool:Trim()
    local count = #self.inactive
    if count <= MAX_POOL_SIZE then return end
    -- Remove excess icons from pool (they'll be garbage collected)
    for i = count, MAX_POOL_SIZE + 1, -1 do
        tremove(self.inactive)
    end
end

-- Expose trim for external zone-change calls
ns.TrimAuraPool = function()
    AuraPool:Trim()
end

-- =============================================================================
-- BORDER COLOR HELPER
-- Handles border modes: DISABLED, COLOR_CODED/DISPELLABLE, CUSTOM
-- isPersonal: true for personal bar buffs (always green)
-- =============================================================================
local function SetBorderColor(icon, debuffType, isPurgeable, isDebuff, isPersonal)
    local borderMode = isDebuff and ns.c_debuffBorderMode or ns.c_buffBorderMode
    
    if borderMode == "DISABLED" then
        icon.border:SetColor(0, 0, 0, 0)  -- Fully transparent
    elseif borderMode == "CUSTOM" then
        local color = isDebuff and ns.c_debuffBorderColor or ns.c_buffBorderColor
        icon.border:SetColor(color[1], color[2], color[3], 1)
    else
        -- COLOR_CODED for debuffs, DISPELLABLE for buffs
        if isDebuff then
            -- Debuffs: use debuff type colors (Magic, Curse, Poison, Disease, none=red)
            local color = BORDER_COLORS[debuffType] or BORDER_COLORS.none
            icon.border:SetColor(color[1], color[2], color[3], 1)
        else
            -- Buffs: different handling for personal vs enemy
            if isPersonal then
                -- Personal bar buffs: always green
                icon.border:SetColor(unpack(BUFF_COLOR_GREEN))
            else
                -- Enemy buffs: dispellable = blue, non-dispellable = white
                if isPurgeable then
                    icon.border:SetColor(unpack(BORDER_COLORS.Magic))  -- Blue
                else
                    icon.border:SetColor(unpack(BUFF_COLOR_WHITE))     -- White
                end
            end
        end
    end
end

-- =============================================================================
-- DURATION TEXT UPDATE (Uses Time Cache)
-- =============================================================================
local function UpdateDurationText(icon)
    local timeLeft = icon.expires - GetTime()
    
    if timeLeft <= 0 then
        icon.duration:SetText("")
        return
    end
    
    -- Use cached time string
    icon.duration:SetText(GetCachedTimeString(timeLeft))
    
    -- Set color based on time remaining
    if timeLeft < 1 then
        icon.duration:SetTextColor(COLOR_RED[1], COLOR_RED[2], COLOR_RED[3])
    elseif timeLeft < 5 then
        icon.duration:SetTextColor(COLOR_ORANGE[1], COLOR_ORANGE[2], COLOR_ORANGE[3])
    elseif timeLeft < 60 then
        icon.duration:SetTextColor(COLOR_YELLOW[1], COLOR_YELLOW[2], COLOR_YELLOW[3])
    else
        icon.duration:SetTextColor(COLOR_WHITE[1], COLOR_WHITE[2], COLOR_WHITE[3])
    end
end

-- =============================================================================
-- ADAPTIVE TIMER ONUPDATE
-- Update frequency scales with urgency:
-- - Normal: 0.5s (2 FPS) - saves CPU
-- - <5 seconds: 0.1s (10 FPS) - shows countdown
-- - <1 second: 0.05s (20 FPS) - decimal precision
-- All intervals are multiplied by throttleMultiplier in Potato PC mode
-- =============================================================================
local function AuraTimerOnUpdate(icon, elapsed)
    icon.elapsed = icon.elapsed + elapsed
    
    local timeLeft = icon.expires - GetTime()
    local multiplier = ns.c_throttleMultiplier or 1
    
    -- Adaptive update interval (scaled by Potato PC mode)
    local interval
    if timeLeft <= 1 then
        interval = 0.05 * multiplier   -- 20 FPS for final second (10 FPS in Potato mode)
    elseif timeLeft <= 5 then
        interval = 0.1 * multiplier    -- 10 FPS for last 5 seconds (5 FPS in Potato mode)
    else
        interval = 0.5 * multiplier    -- 2 FPS normally (1 FPS in Potato mode)
    end
    
    if icon.elapsed < interval then return end
    icon.elapsed = 0
    
    if timeLeft <= 0 then
        -- Aura expired - will be cleaned up on next UNIT_AURA
        icon.duration:SetText("")
        icon:SetScript("OnUpdate", nil)
        return
    end
    
    UpdateDurationText(icon)
end

-- =============================================================================
-- SETTINGS CACHE
-- Called from UpdateDBCache() when settings change
-- =============================================================================
function ns:CacheAuraSettings()
    local db = TurboPlatesDB
    local auras = db and db.auras or ns.defaults.auras
    
    -- Debuffs
    ns.c_showDebuffs = auras.showDebuffs ~= false
    ns.c_maxDebuffs = auras.maxDebuffs or 6
    ns.c_debuffIconWidth = auras.debuffIconWidth or 20
    ns.c_debuffIconHeight = auras.debuffIconHeight or 20
    ns.c_debuffFontSize = auras.debuffFontSize or 10
    ns.c_debuffStackFontSize = auras.debuffStackFontSize or 10
    ns.c_debuffYOffset = auras.debuffYOffset or 0
    ns.c_debuffDurationAnchor = auras.debuffDurationAnchor or "BOTTOM"
    ns.c_debuffStackAnchor = auras.debuffStackAnchor or "TOPRIGHT"
    
    -- Buffs
    ns.c_buffFilterMode = auras.buffFilterMode or "ONLY_DISPELLABLE"
    ns.c_showBuffs = ns.c_buffFilterMode ~= "DISABLED"
    ns.c_maxBuffs = auras.maxBuffs or 4
    ns.c_buffIconWidth = auras.buffIconWidth or 18
    ns.c_buffIconHeight = auras.buffIconHeight or 18
    ns.c_buffFontSize = auras.buffFontSize or 10
    ns.c_buffStackFontSize = auras.buffStackFontSize or 10
    ns.c_buffYOffset = auras.buffYOffset or 0
    ns.c_buffGrowDirection = auras.buffGrowDirection or "CENTER"
    ns.c_buffDurationAnchor = auras.buffDurationAnchor or "BOTTOM"
    ns.c_buffStackAnchor = auras.buffStackAnchor or "TOPRIGHT"
    ns.c_buffIconSpacing = auras.buffIconSpacing or 2
    ns.c_buffMinDuration = auras.buffMinDuration or 0
    ns.c_buffMaxDuration = auras.buffMaxDuration or 300
    ns.c_buffBorderMode = auras.buffBorderMode or "COLOR_CODED"
    
    -- Duration filters (for debuffs)
    ns.c_minDuration = auras.minDuration or 0
    ns.c_maxDuration = auras.maxDuration or 300
    
    -- Layout
    ns.c_growDirection = auras.growDirection or "CENTER"
    ns.c_iconSpacing = auras.iconSpacing or 2
    ns.c_debuffSortMode = auras.debuffSortMode or "LEAST_TIME"
    ns.c_buffSortMode = auras.buffSortMode or "LEAST_TIME"
    
    -- Border modes
    ns.c_debuffBorderMode = auras.debuffBorderMode or "COLOR_CODED"
    
    -- Custom border colors
    local debuffBorderCol = auras.debuffBorderColor or { r = 0.8, g = 0, b = 0 }
    ns.c_debuffBorderColor = { debuffBorderCol.r, debuffBorderCol.g, debuffBorderCol.b }
    local buffBorderCol = auras.buffBorderColor or { r = 0.2, g = 0.8, b = 0.2 }
    ns.c_buffBorderColor = { buffBorderCol.r, buffBorderCol.g, buffBorderCol.b }
    
    -- Blacklist/Whitelist - ALWAYS reference DB tables directly for live updates
    -- Ensure tables exist in DB so references stay valid when user adds spells
    if db then
        if not db.auras then db.auras = {} end
        if not db.auras.blacklist then db.auras.blacklist = {} end
        if not db.auras.whitelist then db.auras.whitelist = {} end
        ns.AuraBlacklist = db.auras.blacklist
        ns.AuraWhitelist = db.auras.whitelist
    else
        -- No DB yet, use empty tables (will be re-cached on PLAYER_LOGIN)
        ns.AuraBlacklist = {}
        ns.AuraWhitelist = {}
    end
    
    -- Refresh all visible plates with new settings (if API available)
    -- C_NamePlate.GetNamePlates may not exist during early addon loading
    if C_NamePlate.GetNamePlates then
        for i, namePlate in ipairs(C_NamePlate.GetNamePlates() or {}) do
            local myPlate = namePlate.TurboPlate
            if myPlate and myPlate.debuffContainer then
                ns:UpdateAuraPositions(myPlate)
                -- Refresh aura display if unit exists
                if myPlate.unit and UnitExists(myPlate.unit) then
                    ns:UpdateAuras(myPlate, myPlate.unit)
                end
            end
        end
    end
end

-- =============================================================================
-- FILTER CHAIN
-- Buff Filter Modes (enemy plates only):
--   ONLY_DISPELLABLE: Only dispellable buffs (bypass duration)
--   WHITELIST_DISPELLABLE: Whitelisted + dispellable (both bypass duration)
--   ALL: All buffs, whitelisted/dispellable bypass duration, others get duration filter
-- Personal bar buffs: show ALL (only blacklist applies)
-- =============================================================================
local currentIsPersonal = false  -- Set before calling AuraUtil.ForEachAura

local function PassesFilters(spellID, duration, canStealOrPurge, auraType, debuffType)
    -- 1. BLACKLIST: Always reject first (applies to all modes, all plates)
    if rawget(ns.AuraBlacklist, spellID) then
        return false
    end
    
    -- 2. WHITELIST: Always accept (bypasses all other checks)
    local isWhitelisted = rawget(ns.AuraWhitelist, spellID)
    if isWhitelisted then return true end
    
    -- For buffs: treat Magic-type as dispellable (isStealable flag is unreliable on player targets)
    local isDispellable = canStealOrPurge or (auraType == "buff" and debuffType == "Magic")
    
    -- 3. PERSONAL BAR: Show player's own auras with duration filtering
    if currentIsPersonal then
        
        -- Debuffs: respect duration filters
        if auraType == "debuff" then
            local minDur = ns.c_minDuration
            local maxDur = ns.c_maxDuration
            local dur = duration or 0
            
            -- Permanent debuffs (no duration) filtered if any duration filter is active
            if dur == 0 and (minDur > 0 or maxDur > 0) then return false end
            
            if minDur > 0 and dur < minDur then return false end
            if maxDur > 0 and dur > maxDur then return false end
            return true
        end
        
        -- Buffs: hide permanent (no duration) unless whitelisted
        -- This filters out passive/hidden auras that clutter the display
        if not duration or duration == 0 then
            return false
        end
        
        -- Apply buff duration filter for personal bar buffs
        local minDur = ns.c_buffMinDuration
        local maxDur = ns.c_buffMaxDuration
        if minDur > 0 and duration < minDur then return false end
        if maxDur > 0 and duration > maxDur then return false end
        return true
    end
    
    -- === ENEMY PLATES ONLY BELOW THIS POINT ===
    
    -- 3. BUFF FILTERING (enemy buffs only)
    if auraType == "buff" then
        local filterMode = ns.c_buffFilterMode
        
        -- Dispellable buffs ALWAYS bypass duration check (in all modes)
        -- Whitelisted buffs ALWAYS bypass duration check (in modes that use whitelist)
        
        if filterMode == "ONLY_DISPELLABLE" then
            -- Only dispellable buffs allowed, they bypass duration
            return isDispellable
            
        elseif filterMode == "WHITELIST_DISPELLABLE" then
            -- Whitelisted or dispellable passes
            if isWhitelisted or isDispellable then return true end
            return false  -- Non-dispellable, non-whitelisted rejected
            
        else -- "ALL" (except blacklisted)
            -- Whitelisted bypasses duration check
            if isWhitelisted then return true end
            -- Dispellable bypasses duration check
            if isDispellable then return true end
            -- Non-dispellable, non-whitelisted falls through to duration check
        end
        
        -- Duration check for non-dispellable, non-whitelisted buffs only (ALL mode)
        local minDur = ns.c_buffMinDuration
        local maxDur = ns.c_buffMaxDuration
        if duration and duration > 0 then
            if minDur > 0 and duration < minDur then return false end
            if maxDur > 0 and duration > maxDur then return false end
        else
            -- Permanent aura - reject in ALL mode for non-dispellable/non-whitelisted
            return false
        end
        return true
    end
    
    -- 4. DEBUFF FILTERING (enemy debuffs = your DoTs)
    -- Whitelist bypasses all checks
    if isWhitelisted then return true end
    
    -- Duration check for debuffs
    local minDur = ns.c_minDuration
    local maxDur = ns.c_maxDuration
    if duration and duration > 0 then
        if minDur > 0 and duration < minDur then return false end
        if maxDur > 0 and duration > maxDur then return false end
    else
        -- Permanent aura - reject unless whitelisted (checked above)
        return false
    end
    
    return true
end

-- =============================================================================
-- REUSABLE CALLBACK STATE
-- =============================================================================
local currentAuraType = nil
local currentCollector = nil
local currentTime = 0

-- =============================================================================
-- CALLBACK FOR AuraUtil.ForEachAura
-- =============================================================================
local function ProcessAuraCallback(name, rank, icon, count, debuffType, duration, expires, caster, canStealOrPurge, _, spellID)
    if not name then return end
    
    -- Filter check (pass debuffType for Magic-type stealable fallback)
    if not PassesFilters(spellID, duration, canStealOrPurge, currentAuraType, debuffType) then
        return
    end
    
    -- Acquire pooled data table
    local aura = AcquireAuraData()
    aura.name = name
    aura.icon = icon
    aura.count = count or 0
    aura.debuffType = debuffType
    aura.duration = duration
    aura.expires = expires or 0
    -- For buffs: treat Magic-type as stealable (isStealable flag unreliable on player targets)
    aura.canStealOrPurge = canStealOrPurge or (currentAuraType == "buff" and debuffType == "Magic")
    aura.spellID = spellID
    aura.isDebuff = (currentAuraType == "debuff")
    aura.timeLeft = (expires and expires > 0) and (expires - currentTime) or 0
    
    tinsert(currentCollector, aura)
end

-- =============================================================================
-- SORTING COMPARATORS (Pre-defined, not created inline in sort() call)
-- =============================================================================
local function SortByTimeRemaining(a, b)
    -- Least time remaining first (shortest duration at position 1)
    -- No duration auras go last
    if a.timeLeft == 0 then return false end
    if b.timeLeft == 0 then return true end
    return a.timeLeft < b.timeLeft
end

local function SortByMostRecent(a, b)
    -- Most recently applied/refreshed first (newest at position 1)
    -- Application time = expires - duration (works correctly for refreshed auras too)
    -- No duration auras go last
    if a.duration == 0 or a.expires == 0 then return false end
    if b.duration == 0 or b.expires == 0 then return true end
    local aApplied = a.expires - a.duration
    local bApplied = b.expires - b.duration
    return aApplied > bApplied
end

-- =============================================================================
-- POSITION ICONS (Layout with grow direction)
-- LEFT = grow right, RIGHT = grow left, CENTER = grow outward
-- Icons anchor from BOTTOM edge so height grows upward
-- iconWidth is the inner icon frame width; border adds 1px outside each side
-- effectiveSpacing accounts for border overlap
-- =============================================================================
local function PositionIcons(container, count, iconWidth, spacing, growDir)
    if count == 0 then return end
    
    -- Borders extend 1px outside each icon, so adjacent borders overlap by 2px
    -- To get desired visual spacing, add 2 for the overlapping border pixels
    local outerWidth = iconWidth + (BORDER_SIZE * 2)  -- Total visual width per icon
    local effectiveSpacing = spacing  -- This is the gap between outer edges
    local step = outerWidth + effectiveSpacing  -- Distance between icon centers
    
    local totalWidth = (count * outerWidth) + ((count - 1) * effectiveSpacing)
    
    for i = 1, count do
        local icon = container.icons[i]
        if icon then
            icon:ClearAllPoints()
            
            if growDir == "CENTER" then
                -- Center-aligned horizontally, anchored at BOTTOM
                local xOffset = (i - 1) * step - (totalWidth / 2) + (outerWidth / 2)
                icon:SetPoint("BOTTOM", container, "BOTTOM", xOffset, 0)
                
            elseif growDir == "LEFT" then
                -- Anchor BOTTOMLEFT edge, grow towards RIGHT
                local xOffset = (i - 1) * step
                icon:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", xOffset, 0)
                
            elseif growDir == "RIGHT" then
                -- Anchor BOTTOMRIGHT edge, grow towards LEFT
                local xOffset = -((i - 1) * step)
                icon:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", xOffset, 0)
            end
        end
    end
end

-- =============================================================================
-- DISPLAY AURAS (Show filtered, sorted auras on container)
-- isPersonal: true if displaying on personal bar (affects buff border colors)
-- =============================================================================
local function DisplayAuras(container, auras, maxCount, iconWidth, iconHeight, spacing, growDir, fontSize, stackFontSize, durationAnchor, stackAnchor, isPersonal)
    -- Release existing icons back to pool
    AuraPool:ReleaseAll(container)
    container.icons = container.icons or {}
    
    -- Get anchor positions (duration inside, stacks outside)
    local durAnchor = DURATION_ANCHORS[durationAnchor] or DURATION_ANCHORS.BOTTOM
    local stkAnchor = STACK_ANCHORS[stackAnchor] or STACK_ANCHORS.TOPRIGHT
    
    -- Show new icons
    local count = 0
    for i = 1, #auras do
        if count >= maxCount then break end
        local aura = auras[i]
        count = count + 1
        
        local icon = AuraPool:Acquire(container)
        
        -- Size caching
        if icon._lastWidth ~= iconWidth or icon._lastHeight ~= iconHeight then
            icon:SetSize(iconWidth, iconHeight)
            icon._lastWidth = iconWidth
            icon._lastHeight = iconHeight
        end
        
        -- Set texture (using cached icon)
        icon.texture:SetTexture(GetCachedIcon(aura.spellID, aura.icon))
        
        -- Update font size only if changed
        if icon._lastDurFontSize ~= fontSize then
            icon.duration:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            icon._lastDurFontSize = fontSize
        end
        if icon._lastStackFontSize ~= stackFontSize then
            icon.count:SetFont(STANDARD_TEXT_FONT, stackFontSize, "OUTLINE")
            icon._lastStackFontSize = stackFontSize
        end
        
        -- Position duration text (cached)
        if icon._lastDurAnchor ~= durationAnchor then
            icon.duration:ClearAllPoints()
            icon.duration:SetPoint(durAnchor[1], icon, durAnchor[2], durAnchor[3], durAnchor[4])
            icon._lastDurAnchor = durationAnchor
        end
        
        -- Position stack count (cached)
        if icon._lastStkAnchor ~= stackAnchor then
            icon.count:ClearAllPoints()
            icon.count:SetPoint(stkAnchor[1], icon, stkAnchor[2], stkAnchor[3], stkAnchor[4])
            icon._lastStkAnchor = stackAnchor
        end
        
        -- Set border color by type (pass isDebuff and isPersonal for proper coloring)
        SetBorderColor(icon, aura.debuffType, aura.canStealOrPurge, aura.isDebuff, isPersonal)
        
        -- Set stack count
        if aura.count > 1 then
            icon.count:SetText(aura.count)
            icon.count:Show()
        else
            icon.count:Hide()
        end
        
        -- Set duration tracking
        icon.spellID = aura.spellID
        icon.expires = aura.expires
        icon.elapsed = 0
        
        if aura.expires > 0 then
            icon:SetScript("OnUpdate", AuraTimerOnUpdate)
            UpdateDurationText(icon)
            icon.duration:Show()
        else
            icon.duration:SetText("")
            icon.duration:Hide()
            icon:SetScript("OnUpdate", nil)
        end
        
        container.icons[count] = icon
        icon:Show()
    end
    
    -- Store actual displayed count for positioning logic
    container.displayedCount = count
    
    -- Position icons (use width for horizontal layout)
    PositionIcons(container, count, iconWidth, spacing, growDir)
end

-- =============================================================================
-- MAIN UPDATE FUNCTION
-- =============================================================================
function ns:UpdateAuras(myPlate, unit)
    -- Early exit: no unit or containers
    if not unit or not UnitExists(unit) then return end
    if not myPlate.debuffContainer then return end
    
    local isPersonal = myPlate.isPlayer
    
    -- === PERSONAL NAMEPLATE BRANCH ===
    if isPersonal then
        -- Early exit: personal bar disabled entirely
        if not ns.c_personalEnabled then
            AuraPool:ReleaseAll(myPlate.debuffContainer)
            AuraPool:ReleaseAll(myPlate.buffContainer)
            myPlate.debuffContainer:Hide()
            myPlate.buffContainer:Hide()
            return
        end
        
        local showDebuffs = ns.c_personalShowDebuffs
        local showBuffs = ns.c_personalShowBuffs
        
        -- Early exit: no auras enabled on personal bar
        if not showDebuffs and not showBuffs then
            AuraPool:ReleaseAll(myPlate.debuffContainer)
            AuraPool:ReleaseAll(myPlate.buffContainer)
            myPlate.debuffContainer:Hide()
            myPlate.buffContainer:Hide()
            return
        end
        
        -- Set flag for PassesFilters (personal = show all, only blacklist applies)
        currentIsPersonal = true
        currentTime = GetTime()
        
        -- Release previous aura data back to pool
        ReleaseAllAuraData(debuffCollector)
        ReleaseAllAuraData(buffCollector)
        
        -- Collect personal debuffs (debuffs ON the player)
        if showDebuffs then
            currentAuraType = "debuff"
            currentCollector = debuffCollector
            AuraUtil.ForEachAura(unit, "HARMFUL", 40, ProcessAuraCallback)
            myPlate.debuffContainer:Show()
        else
            AuraPool:ReleaseAll(myPlate.debuffContainer)
            myPlate.debuffContainer:Hide()
        end
        
        -- Collect personal buffs (all buffs on player)
        if showBuffs then
            currentAuraType = "buff"
            currentCollector = buffCollector
            AuraUtil.ForEachAura(unit, "HELPFUL", 40, ProcessAuraCallback)
            myPlate.buffContainer:Show()
        else
            AuraPool:ReleaseAll(myPlate.buffContainer)
            myPlate.buffContainer:Hide()
        end
        
    -- === ENEMY NAMEPLATE BRANCH ===
    else
        -- Early exit: neither debuffs nor buffs enabled for enemy plates
        if not ns.c_showDebuffs and not ns.c_showBuffs then
            return
        end
        
        -- Early exit: friendly units don't show auras
        if UnitIsFriend("player", unit) then
            AuraPool:ReleaseAll(myPlate.debuffContainer)
            AuraPool:ReleaseAll(myPlate.buffContainer)
            myPlate.debuffContainer:Hide()
            myPlate.buffContainer:Hide()
            return
        end
        
        -- Set flag for PassesFilters (enemy = use filter modes)
        currentIsPersonal = false
        currentTime = GetTime()
        
        -- Release previous aura data back to pool
        ReleaseAllAuraData(debuffCollector)
        ReleaseAllAuraData(buffCollector)
        
        -- Collect debuffs (HARMFUL|PLAYER = only your DoTs on enemy)
        if ns.c_showDebuffs then
            currentAuraType = "debuff"
            currentCollector = debuffCollector
            AuraUtil.ForEachAura(unit, "HARMFUL|PLAYER", 40, ProcessAuraCallback)
            myPlate.debuffContainer:Show()
        else
            AuraPool:ReleaseAll(myPlate.debuffContainer)
            myPlate.debuffContainer:Hide()
        end
        
        -- Collect buffs (enemy buffs, filtered by mode)
        if ns.c_showBuffs then
            currentAuraType = "buff"
            currentCollector = buffCollector
            AuraUtil.ForEachAura(unit, "HELPFUL", 40, ProcessAuraCallback)
            myPlate.buffContainer:Show()
        else
            AuraPool:ReleaseAll(myPlate.buffContainer)
            myPlate.buffContainer:Hide()
        end
    end
    
    -- === SORT AURAS (skip if empty or single aura) ===
    if #debuffCollector > 1 then
        local sortFunc = ns.c_debuffSortMode == "MOST_RECENT" and SortByMostRecent or SortByTimeRemaining
        sort(debuffCollector, sortFunc)
    end
    if #buffCollector > 1 then
        local sortFunc = ns.c_buffSortMode == "MOST_RECENT" and SortByMostRecent or SortByTimeRemaining
        sort(buffCollector, sortFunc)
    end
    
    -- === DISPLAY (only for enabled containers) ===
    if isPersonal then
        if ns.c_personalShowDebuffs then
            DisplayAuras(myPlate.debuffContainer, debuffCollector, ns.c_maxDebuffs, ns.c_debuffIconWidth, ns.c_debuffIconHeight, ns.c_iconSpacing, ns.c_growDirection, ns.c_debuffFontSize, ns.c_debuffStackFontSize, ns.c_debuffDurationAnchor, ns.c_debuffStackAnchor, true)
        else
            -- Ensure displayedCount is 0 when debuffs disabled
            myPlate.debuffContainer.displayedCount = 0
        end
        if ns.c_personalShowBuffs then
            DisplayAuras(myPlate.buffContainer, buffCollector, ns.c_maxBuffs, ns.c_buffIconWidth, ns.c_buffIconHeight, ns.c_buffIconSpacing, ns.c_buffGrowDirection, ns.c_buffFontSize, ns.c_buffStackFontSize, ns.c_buffDurationAnchor, ns.c_buffStackAnchor, true)
        end
        -- Position containers immediately after display (displayedCount now accurate)
        ns:UpdateAuraPositions(myPlate)
    else
        if ns.c_showDebuffs then
            DisplayAuras(myPlate.debuffContainer, debuffCollector, ns.c_maxDebuffs, ns.c_debuffIconWidth, ns.c_debuffIconHeight, ns.c_iconSpacing, ns.c_growDirection, ns.c_debuffFontSize, ns.c_debuffStackFontSize, ns.c_debuffDurationAnchor, ns.c_debuffStackAnchor, false)
        else
            myPlate.debuffContainer.displayedCount = 0
        end
        if ns.c_showBuffs then
            DisplayAuras(myPlate.buffContainer, buffCollector, ns.c_maxBuffs, ns.c_buffIconWidth, ns.c_buffIconHeight, ns.c_buffIconSpacing, ns.c_buffGrowDirection, ns.c_buffFontSize, ns.c_buffStackFontSize, ns.c_buffDurationAnchor, ns.c_buffStackAnchor, false)
        end
        
        -- Position containers immediately after display (displayedCount now accurate)
        ns:UpdateAuraPositions(myPlate)
        
        -- Update healer icon position when aura counts change
        if ns.UpdateHealerIconPosition and myPlate.healerIcon and myPlate.healerIcon:IsShown() then
            ns:UpdateHealerIconPosition(myPlate)
        end
    end
end

-- =============================================================================
-- CREATE AURA CONTAINERS ON PLATE
-- =============================================================================
function ns:CreateAuraContainers(myPlate)
    -- Debuff container (your DoTs)
    myPlate.debuffContainer = CreateFrame("Frame", nil, myPlate)
    myPlate.debuffContainer:SetSize(200, 30)
    myPlate.debuffContainer:EnableMouse(false)
    myPlate.debuffContainer.icons = {}
    
    -- Buff container (enemy buffs)
    myPlate.buffContainer = CreateFrame("Frame", nil, myPlate)
    myPlate.buffContainer:SetSize(200, 30)
    myPlate.buffContainer:EnableMouse(false)
    myPlate.buffContainer.icons = {}
    
    -- Release auras when plate hides
    myPlate:HookScript("OnHide", function(self)
        ns:CleanupPlateAuras(self)
    end)
    
    -- Positioning deferred to FullPlateUpdate->UpdateAuraPositions
end

-- =============================================================================
-- UPDATE AURA CONTAINER POSITIONS
-- Called when plate layout changes (not on every aura update)
-- Container visibility is managed by UpdateAuras() - this only handles positioning
-- =============================================================================
function ns:UpdateAuraPositions(myPlate)
    if not myPlate.debuffContainer then return end
    
    -- Hide aura containers for friendly units (they don't show auras)
    if myPlate.isFriendly then
        myPlate.debuffContainer:Hide()
        myPlate.buffContainer:Hide()
        return
    end
    
    -- === PERSONAL NAMEPLATE POSITIONING ===
    if myPlate.isPlayer then
        -- Skip positioning if personal bar disabled (containers hidden by UpdateAuras)
        if not ns.c_personalEnabled then return end
        if not ns.c_personalShowDebuffs and not ns.c_personalShowBuffs then return end
        
        local hpBar = myPlate.hp
        if not hpBar then return end
        
        -- Personal bar: anchor above power bar (or health bar if power disabled)
        local anchorOffset = 3  -- Base gap
        if ns.c_personalShowPower and myPlate.powerBar then
            anchorOffset = anchorOffset + (ns.c_personalPowerHeight or 8) + 2
            -- Account for additional power bar (druid mana) if visible
            if myPlate.additionalPowerBar and myPlate.additionalPowerBar:IsShown() then
                anchorOffset = anchorOffset + (ns.c_personalAdditionalPowerHeight or 6) + 1
            end
        end
        
        -- Position debuff container
        myPlate.debuffContainer:ClearAllPoints()
        local debuffY = (ns.c_personalDebuffYOffset or 0) + anchorOffset + BORDER_SIZE
        myPlate.debuffContainer:SetPoint("BOTTOM", hpBar, "TOP", 0, debuffY)
        
        -- Position buff container above debuffs
        myPlate.buffContainer:ClearAllPoints()
        local debuffIconCount = myPlate.debuffContainer.displayedCount or 0
        local buffY = (ns.c_personalBuffYOffset or 0) + anchorOffset + BORDER_SIZE
        if debuffIconCount > 0 and ns.c_personalShowDebuffs then
            buffY = buffY + (ns.c_debuffIconHeight or 20) + 4
        end
        myPlate.buffContainer:SetPoint("BOTTOM", hpBar, "TOP", 0, buffY)
        
        -- Update personal bar border based on debuff status
        if ns.UpdatePersonalBorder then
            ns:UpdatePersonalBorder()
        end
        return
    end
    
    -- Show containers (they may have been hidden by totem mode or friendly state)
    myPlate.debuffContainer:Show()
    myPlate.buffContainer:Show()
    
    -- Determine if name is enabled (for Y positioning)
    -- Use cached config setting (more reliable than IsShown() which may have timing issues)
    local nameEnabled = ns.c_nameDisplayFormat and ns.c_nameDisplayFormat ~= "disabled"
    local hpBar = myPlate.hp
    if not hpBar then return end  -- No valid anchor yet
    
    -- Calculate Y offset to clear the name if it's visible
    -- Name is 3px above hp, add name height + 3 to clear it
    local nameHeightOffset = 0
    if nameEnabled and myPlate.nameText then
        local nameHeight = myPlate.nameText:GetStringHeight()
        
        -- GetStringHeight() returns 0 on first frame before text is laid out
        -- If height is 0 or nil, schedule a deferred re-position after layout completes
        if not nameHeight or nameHeight < 1 then
            -- Only schedule once per plate to avoid spam
            if not myPlate._auraPositionPending then
                myPlate._auraPositionPending = true
                -- Add to pending plates queue (processed by single timer callback)
                pendingPositionPlates[myPlate] = true
                if not pendingPositionTimer then
                    pendingPositionTimer = C_Timer.After(0, ProcessPendingPositions)
                end
            end
            -- Use a reasonable default for now (will be corrected next frame)
            nameHeight = 12
        end
        
        nameHeightOffset = nameHeight + 3  -- 3px is the gap between hp and name
    end
    
    -- Position debuff container based on grow direction
    -- LEFT = align with left edge of healthbar, grow right
    -- RIGHT = align with right edge of healthbar, grow left
    -- CENTER = centered above healthbar (or name if visible)
    myPlate.debuffContainer:ClearAllPoints()
    local debuffGrowDir = ns.c_growDirection or "CENTER"
    -- Add BORDER_SIZE since the icon frame includes border padding
    -- Use fallback defaults (0) for YOffset in case cache isn't initialized yet
    local debuffY = (ns.c_debuffYOffset or 0) + nameHeightOffset + BORDER_SIZE
    
    if debuffGrowDir == "LEFT" then
        myPlate.debuffContainer:SetPoint("BOTTOMLEFT", hpBar, "TOPLEFT", 0, debuffY)
    elseif debuffGrowDir == "RIGHT" then
        myPlate.debuffContainer:SetPoint("BOTTOMRIGHT", hpBar, "TOPRIGHT", 0, debuffY)
    else
        myPlate.debuffContainer:SetPoint("BOTTOM", hpBar, "TOP", 0, debuffY)
    end
    
    -- Position buff container above debuffs (if visible) or at same level
    myPlate.buffContainer:ClearAllPoints()
    local debuffIconCount = myPlate.debuffContainer.displayedCount or 0
    -- Add BORDER_SIZE for buff positioning as well
    -- Use fallback defaults (0) for YOffset in case cache isn't initialized yet
    local buffY = (ns.c_buffYOffset or 0) + nameHeightOffset + BORDER_SIZE
    
    if debuffIconCount > 0 and ns.c_showDebuffs then
        -- Stack buffs above debuffs with 4px gap between rows (use height for vertical stacking)
        buffY = buffY + (ns.c_debuffIconHeight or 20) + 4
    end
    
    local buffGrowDir = ns.c_buffGrowDirection or "CENTER"
    if buffGrowDir == "LEFT" then
        myPlate.buffContainer:SetPoint("BOTTOMLEFT", hpBar, "TOPLEFT", 0, buffY)
    elseif buffGrowDir == "RIGHT" then
        myPlate.buffContainer:SetPoint("BOTTOMRIGHT", hpBar, "TOPRIGHT", 0, buffY)
    else
        myPlate.buffContainer:SetPoint("BOTTOM", hpBar, "TOP", 0, buffY)
    end
end

-- =============================================================================
-- EVENT BATCHING
-- =============================================================================
local batchUnitsToUpdate = {}  -- Reusable table for batching
local pendingPlayerAura = false  -- Flag for player aura update (personal bar)

-- Fast nameplate check (uses cached strsub)
local function IsNameplateUnit(unit)
    return unit and strsub(unit, 1, 9) == "nameplate"
end

-- =============================================================================
-- EVENT HANDLER SETUP
-- =============================================================================
local function SetupAuraEvents()
    local eventFrame = CreateFrame("Frame")
    
    -- Aura batch interval (respects Potato PC mode)
    -- Base: 0.05s (50ms), Potato: 0.1s (100ms)
    local auraBatchInterval = 0.05 * (ns.c_throttleMultiplier or 1)
    
    -- Use C_Hook batching for efficient event handling
    C_Hook:RegisterBucket(eventFrame, "UNIT_AURA", auraBatchInterval, function(events)
        -- Dedupe units (same unit may fire multiple times)
        wipe(batchUnitsToUpdate)
        pendingPlayerAura = false  -- Reset player flag
        
        -- Track player auras for personal bar display
        local trackPlayerAurasForDisplay = ns.c_personalEnabled and (ns.c_personalShowDebuffs or ns.c_personalShowBuffs)
        -- Always track player debuffs for border coloring (cheap cache update)
        local trackPlayerDebuffs = ns.c_personalEnabled and ns.c_personalBorderStyle and ns.c_personalBorderStyle ~= "none" and ns.c_personalBorderStyle ~= "black"
        
        for _, args in ipairs(events) do
            local unit = args[1]
            if unit then
                if IsNameplateUnit(unit) then
                    batchUnitsToUpdate[unit] = true
                elseif unit == "player" and (trackPlayerAurasForDisplay or trackPlayerDebuffs) then
                    pendingPlayerAura = true
                end
            end
        end
        
        -- Process each unique nameplate unit once
        for unit in pairs(batchUnitsToUpdate) do
            local nameplate = GetNamePlateForUnit(unit)
            if nameplate then
                -- Update regular auras (full plates only)
                if nameplate.myPlate then
                    ns:UpdateAuras(nameplate.myPlate, unit)
                    -- Update TurboDebuff (BigDebuffs-style priority aura)
                    if ns.UpdateTurboDebuff then
                        ns:UpdateTurboDebuff(nameplate.myPlate, unit)
                    end
                elseif nameplate._isLite then
                    -- Update TurboDebuff for lite plates
                    if ns.UpdateLiteTurboDebuff then
                        ns:UpdateLiteTurboDebuff(nameplate, unit)
                    end
                end
            end
        end
        
        -- Process player aura update (personal bar) - already checked enabled above
        if pendingPlayerAura then
            local personalPlate = ns.unitToPlate and ns.unitToPlate["player"]
            if personalPlate and personalPlate.isPlayer then
                ns:UpdateAuras(personalPlate, "player")
                -- Update TurboDebuff for personal bar
                if ns.UpdateTurboDebuff then
                    ns:UpdateTurboDebuff(personalPlate, "player")
                end
            end
            -- Update player debuff cache for border coloring (even if personal bar disabled)
            if ns.UpdatePlayerDebuffCache then
                ns:UpdatePlayerDebuffCache()
            end
        end
    end)
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================
local function Initialize()
    -- Cache aura settings
    ns:CacheAuraSettings()
    
    -- Setup event batching
    SetupAuraEvents()
end

-- Initialize when addon loads
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        Initialize()
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Trim pools and clear stale references on zone change
        AuraPool:Trim()
        wipe(pendingPositionPlates)
        pendingPositionTimer = nil
    end
end)
