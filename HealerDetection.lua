local addonName, ns = ...

-- =============================================================================
-- HEALER DETECTION MODULE
-- Detects healers via combat log by tracking healer-only talent spells.
-- Registry persists until zone change, displays only in arena/battleground.
-- =============================================================================

local UnitGUID = UnitGUID
local UnitIsFriend = UnitIsFriend
local UnitIsUnit = UnitIsUnit
local IsInInstance = IsInInstance
local GetTime = GetTime
local wipe = table.wipe
local pairs = pairs
local unpack = unpack
local bit_band = bit.band
local CreateFrame = CreateFrame
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local C_NamePlate = C_NamePlate
local PixelUtil = PixelUtil

-- =============================================================================
-- HEALER-ONLY SPELLS (Talent-based spells that require heal spec investment)
-- =============================================================================
local HEALER_SPELLS = {
    -- PRIEST Discipline
    ["Penance"]             = "PRIEST",
    ["Pain Suppression"]    = "PRIEST",
    ["Power Infusion"]      = "PRIEST",

    -- PRIEST Holy
    ["Circle of Healing"]   = "PRIEST",
    ["Guardian Spirit"]     = "PRIEST",
    ["Lightwell"]           = "PRIEST",

    -- DRUID Restoration
    ["Swiftmend"]           = "DRUID",
    ["Wild Growth"]         = "DRUID",
    ["Tree of Life"]        = "DRUID",
    ["Nature's Swiftness"]  = "DRUID",

    -- SHAMAN Restoration
    ["Riptide"]             = "SHAMAN",
    ["Cleanse Spirit"]      = "SHAMAN",
    ["Mana Tide Totem"]     = "SHAMAN",
    ["Earth Shield"]        = "SHAMAN",

    -- PALADIN Holy
    ["Holy Shock"]          = "PALADIN",
    ["Beacon of Light"]     = "PALADIN",
    ["Divine Favor"]        = "PALADIN",
    ["Divine Illumination"] = "PALADIN",
}

-- =============================================================================
-- HEALER REGISTRY
-- =============================================================================
-- healerRegistry[guid] = { name = "Name", class = "PRIEST", isFriend = true/false }
local healerRegistry = {}

-- =============================================================================
-- ICON TEXTURE COORDINATES (256x256 atlas, 64px icons)
-- =============================================================================
local HEALER_TEXTURE = "Interface\\AddOns\\TurboPlates\\Artwork\\healers_icons.tga"

local function getIconCoords(x, y)
    local b = 1/256
    return { b * x * 64, b * (x * 64 + 64), b * y * 64, b * (y * 64 + 64) }
end

local ICONS_COORDS = {
    [true] = {  -- Friendly (green icons)
        [false]     = getIconCoords(0, 0),  -- Generic healer
        ["DRUID"]   = getIconCoords(1, 0),
        ["PALADIN"] = getIconCoords(3, 0),
        ["PRIEST"]  = getIconCoords(0, 1),
        ["SHAMAN"]  = getIconCoords(1, 1),
    },
    [false] = {  -- Enemy (red icons)
        [false]     = getIconCoords(2, 1),  -- Generic healer
        ["DRUID"]   = getIconCoords(3, 1),
        ["PALADIN"] = getIconCoords(1, 2),
        ["PRIEST"]  = getIconCoords(2, 2),
        ["SHAMAN"]  = getIconCoords(3, 2),
    },
}

-- =============================================================================
-- ZONE STATE
-- =============================================================================
local inPvPZone = false

local function UpdatePvPZone()
    local inInstance, instanceType = IsInInstance()
    local wasInPvP = inPvPZone
    
    inPvPZone = inInstance and (instanceType == "arena" or instanceType == "pvp")
    
    -- Wipe registry when leaving PvP zone
    if wasInPvP and not inPvPZone then
        wipe(healerRegistry)
    end
end

function ns:IsInPvPZone()
    return inPvPZone
end

-- =============================================================================
-- HEALER REGISTRY API
-- =============================================================================
function ns:IsHealer(guid)
    return healerRegistry[guid] ~= nil
end

function ns:GetHealerInfo(guid)
    return healerRegistry[guid]
end

function ns:GetHealerRegistry()
    return healerRegistry
end

-- =============================================================================
-- COMBAT LOG EVENT HANDLER
-- =============================================================================
-- Source flags for classification
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY or 0x00000010
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE or 0x00000001

-- Events that can trigger healer detection
local HEALER_DETECT_EVENTS = {
    ["SPELL_HEAL"] = true,
    ["SPELL_PERIODIC_HEAL"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_AURA_APPLIED"] = true,
}

local function OnCombatLogEvent(...)
    if not inPvPZone then return end
    
    -- Ascension uses modern CLEU format via CombatLogGetCurrentEventInfo
    -- time, token, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
    -- destGUID, destName, destFlags, destRaidFlags, spellID, spellName, ...
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, spellID, spellName = CombatLogGetCurrentEventInfo(...)
    
    -- Only care about heal/cast events that could indicate a healer
    if not event or not HEALER_DETECT_EVENTS[event] then
        return
    end
    
    -- Check if spell is a healer-only spell
    local healerClass = HEALER_SPELLS[spellName]
    if not healerClass then return end
    
    -- Must be from a player
    if not sourceFlags or bit_band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == 0 then
        return
    end
    
    -- Skip self
    if bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
        return
    end
    
    -- Already registered
    if healerRegistry[sourceGUID] then return end
    
    -- Determine if friendly
    local isFriend = bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0
    
    -- Register healer
    healerRegistry[sourceGUID] = {
        name = sourceName,
        class = healerClass,
        isFriend = isFriend,
    }
    
    -- Refresh any visible nameplate for this healer
    ns:RefreshHealerPlates(sourceGUID)
end

-- Refresh all plates that match a GUID (both full and lite plates)
function ns:RefreshHealerPlates(guid)
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate then
            local plateGUID = UnitGUID(unit)
            if plateGUID == guid then
                -- Full plate
                if nameplate.myPlate then
                    ns:UpdateHealerIcon(nameplate.myPlate, unit)
                end
                -- Lite plate
                if nameplate.liteContainer and nameplate.liteContainer:IsShown() then
                    ns:UpdateLiteHealerIcon(nameplate.liteContainer, unit)
                end
            end
        end
    end
end

-- =============================================================================
-- HEALER ICON CREATION
-- =============================================================================
local HEALER_ICON_SIZE = 24

function ns:EnsureHealerIcon(myPlate)
    if myPlate.healerIcon then return end
    
    local icon = myPlate:CreateTexture(nil, "OVERLAY", nil, 7)
    icon:SetTexture(HEALER_TEXTURE)
    PixelUtil.SetSize(icon, HEALER_ICON_SIZE, HEALER_ICON_SIZE, 1, 1)
    icon:Hide()
    myPlate.healerIcon = icon
end

-- Lite plate version (simpler, anchors above name text)
function ns:EnsureLiteHealerIcon(container)
    if container.liteHealerIcon then return end
    
    local icon = container:CreateTexture(nil, "OVERLAY", nil, 7)
    icon:SetTexture(HEALER_TEXTURE)
    PixelUtil.SetSize(icon, HEALER_ICON_SIZE, HEALER_ICON_SIZE, 1, 1)
    icon:Hide()
    container.liteHealerIcon = icon
end

-- =============================================================================
-- HEALER ICON POSITIONING
-- Dynamic anchor above aura containers
-- =============================================================================
function ns:UpdateHealerIconPosition(myPlate)
    if not myPlate.healerIcon then return end
    
    local icon = myPlate.healerIcon
    icon:ClearAllPoints()
    
    -- Calculate base Y offset from healthbar top
    local yOffset = 3  -- Base gap above HP
    
    -- Account for name text if visible
    if myPlate.nameText and myPlate.nameText:IsShown() then
        local nameHeight = myPlate.nameText:GetStringHeight()
        if nameHeight and nameHeight > 0 then
            yOffset = yOffset + nameHeight + 3
        else
            yOffset = yOffset + 12 + 3  -- Default estimate
        end
    end
    
    -- Account for debuff container if visible and has icons
    if myPlate.debuffContainer and myPlate.debuffContainer:IsShown() then
        local debuffCount = myPlate.debuffContainer.displayedCount or 0
        if debuffCount > 0 then
            local debuffHeight = ns.c_debuffIconHeight or 20
            yOffset = yOffset + debuffHeight + 4
        end
    end
    
    -- Account for buff container if visible and has icons
    if myPlate.buffContainer and myPlate.buffContainer:IsShown() then
        local buffCount = myPlate.buffContainer.displayedCount or 0
        if buffCount > 0 then
            local buffHeight = ns.c_buffIconHeight or 20
            yOffset = yOffset + buffHeight + 4
        end
    end
    
    -- Anchor above all elements
    local anchorFrame = myPlate.hp or myPlate
    PixelUtil.SetPoint(icon, "BOTTOM", anchorFrame, "TOP", 0, yOffset, 1, 1)
end

-- =============================================================================
-- HEALER ICON UPDATE
-- =============================================================================
function ns:UpdateHealerIcon(myPlate, unit)
    if not myPlate then return end
    
    -- Ensure icon exists
    ns:EnsureHealerIcon(myPlate)
    local icon = myPlate.healerIcon
    
    -- Early return: skip self
    if UnitIsUnit(unit, "player") then
        icon:Hide()
        return
    end
    
    -- Early return: not in PvP zone
    if not inPvPZone then
        icon:Hide()
        return
    end
    
    -- Early return: setting disabled
    local setting = ns.c_healerMarks or 0
    if setting == 0 then
        icon:Hide()
        return
    end
    
    -- Check if unit is a known healer
    local guid = UnitGUID(unit)
    local healer = healerRegistry[guid]
    
    if not healer then
        icon:Hide()
        return
    end
    
    -- Filter by setting (1=Enemies, 2=Friendly, 3=Both)
    local isFriend = healer.isFriend
    if setting == 1 and isFriend then
        icon:Hide()
        return
    elseif setting == 2 and not isFriend then
        icon:Hide()
        return
    end
    
    -- Set texture coords based on class and friend status
    local coords = ICONS_COORDS[isFriend][healer.class] or ICONS_COORDS[isFriend][false]
    icon:SetTexCoord(unpack(coords))
    
    -- Position and show
    ns:UpdateHealerIconPosition(myPlate)
    icon:Show()
end

-- =============================================================================
-- LITE PLATE HEALER ICON UPDATE
-- For friendly name-only plates
-- =============================================================================
function ns:UpdateLiteHealerIcon(container, unit)
    if not container then return end
    
    -- Ensure icon exists
    ns:EnsureLiteHealerIcon(container)
    local icon = container.liteHealerIcon
    
    -- Early return: not in PvP zone
    if not inPvPZone then
        icon:Hide()
        return
    end
    
    -- Early return: setting disabled or enemies-only
    local setting = ns.c_healerMarks or 0
    if setting == 0 or setting == 1 then  -- 0=disabled, 1=enemies only
        icon:Hide()
        return
    end
    
    -- Check if unit is a known healer
    local guid = UnitGUID(unit)
    local healer = healerRegistry[guid]
    
    if not healer then
        icon:Hide()
        return
    end
    
    -- Lite plates are friendly, so check if healer is friendly
    if not healer.isFriend then
        icon:Hide()
        return
    end
    
    -- Set texture coords (friendly icons)
    local coords = ICONS_COORDS[true][healer.class] or ICONS_COORDS[true][false]
    icon:SetTexCoord(unpack(coords))
    
    -- Position above name text (or raid icon if visible)
    icon:ClearAllPoints()
    local nameText = container.liteNameText
    local raidIcon = container.liteRaidIcon
    
    if raidIcon and raidIcon:IsShown() then
        PixelUtil.SetPoint(icon, "BOTTOM", raidIcon, "TOP", 0, 2, 1, 1)
    elseif nameText then
        PixelUtil.SetPoint(icon, "BOTTOM", nameText, "TOP", 0, 2, 1, 1)
    else
        PixelUtil.SetPoint(icon, "CENTER", container, "CENTER", 0, 20, 1, 1)
    end
    
    icon:Show()
end

-- =============================================================================
-- EVENT FRAME
-- =============================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        UpdatePvPZone()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEvent(...)
    end
end)

-- Initial zone check
UpdatePvPZone()
