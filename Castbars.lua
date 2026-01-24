local addonName, ns = ...

-- TurboPlates Castbar System

-------------------------------------------------------------------------------
-- CACHED GLOBALS
-------------------------------------------------------------------------------
local format = string.format
local floor = math.floor
local GetTime = GetTime
local CreateFrame = CreateFrame
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitIsFriend = UnitIsFriend
local UnitCreatureType = UnitCreatureType
local sub = string.sub
local PixelUtil = PixelUtil

local addon = ns

-- LibCustomGlow reference
local LCG = LibStub("LibCustomGlow-1.0", true)

-- Reusable color table to avoid garbage creation
local highlightColorTable = {1, 0.3, 0.1, 1}

-- Create pixel-perfect texture-based border (uses shared system from Nameplates.lua)
local function CreateTextureBorder(parent, thickness)
    -- Use shared border system if available
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
    end
    
    border:SetColor(0, 0, 0, ns.BORDER_ALPHA or 0.9)
    return border
end

-- Time cache for formatted strings
local timeCache = setmetatable({}, {
    __index = function(t, k)
        -- k is already floored tenths (e.g., 35 = 3.5 seconds)
        local v = format("%.1f", k / 10)
        t[k] = v
        return v
    end
})

local function GetCachedTime(seconds)
    -- Floor to tenths and use cache
    local tenths = floor(seconds * 10 + 0.5)  -- Round to nearest tenth
    if tenths < 0 then tenths = 0 end
    if tenths > 999 then tenths = 999 end  -- Cap at 99.9 seconds
    return timeCache[tenths]
end

-------------------------------------------------------------------------------
-- CASTBAR STATE MANAGEMENT
-------------------------------------------------------------------------------

-- Cached setting accessors
local function GetShowCastbar() return addon.c_showCastbar end
local function GetShowCastIcon() return addon.c_showCastIcon end
local function GetShowCastSpark() return addon.c_showCastSpark end
local function GetShowCastTimer() return addon.c_showCastTimer end
local function GetCastColor() return addon.c_castColor_r or 1, addon.c_castColor_g or 0.8, addon.c_castColor_b or 0 end
local function GetNoInterruptColor() return addon.c_noInterruptColor_r or 0.6, addon.c_noInterruptColor_g or 0.6, addon.c_noInterruptColor_b or 0.6 end
local function GetHighlightGlowEnabled() return addon.c_highlightGlowEnabled end
local function GetHighlightGlowColor()
    return addon.c_highlightGlowColor_r or 1, addon.c_highlightGlowColor_g or 0.3, addon.c_highlightGlowColor_b or 0.1
end
local function IsHighlightSpell(spellName)
    local names = addon.c_highlightSpellNames
    return names and names[spellName] or false
end

-- Stop any active glow on castbar's glow frame
local function StopCastbarGlow(castbar)
    if not LCG then return end
    local glowFrame = castbar.glowFrame
    if not glowFrame then return end
    LCG.PixelGlow_Stop(glowFrame, "highlight")
    glowFrame:Hide()
end

-- Start glow on castbar's dedicated glow frame
local function StartCastbarGlow(castbar)
    if not LCG then return end
    local glowFrame = castbar.glowFrame
    if not glowFrame then return end
    
    local r, g, b = GetHighlightGlowColor()
    highlightColorTable[1], highlightColorTable[2], highlightColorTable[3] = r, g, b
    
    -- Calculate total area including icon if visible
    local cbWidth = castbar:GetWidth()
    local cbHeight = castbar:GetHeight()
    local totalWidth = cbWidth
    local iconOffset = 0
    
    -- If icon is visible, expand glow to cover it
    if castbar.icon and castbar.icon:IsShown() then
        local iconSize = castbar.icon:GetWidth()
        totalWidth = cbWidth + iconSize + 2  -- +2 for gap
        iconOffset = (iconSize + 2) / 2  -- Center the expanded area
    end
    
    -- Position glow frame to cover castbar + icon
    glowFrame:ClearAllPoints()
    glowFrame:SetSize(totalWidth, cbHeight)
    glowFrame:SetPoint("CENTER", castbar, "CENTER", -iconOffset, 0)
    glowFrame:Show()
    
    -- Get glow settings from cache
    local lines = addon.c_highlightGlowLines or 8
    local frequency = addon.c_highlightGlowFrequency or 0.25
    local length = addon.c_highlightGlowLength or 10
    local thickness = addon.c_highlightGlowThickness or 2
    
    -- Outward offset so glow expands outside the border
    local outwardOffset = 2
    
    LCG.PixelGlow_Start(glowFrame, highlightColorTable, lines, frequency, length, thickness, outwardOffset, outwardOffset, false, "highlight", 8)
end

-- Reset castbar state
local function ResetCastbar(castbar)
    castbar.casting = nil
    castbar.channeling = nil
    castbar.notInterruptible = nil
    castbar.castID = nil
    castbar.spellName = nil
    castbar.holdTime = 0
end

-- Hide castbar and icon completely
local function HideCastbar(castbar)
    ResetCastbar(castbar)
    castbar:Hide()
    if castbar.icon then castbar.icon:Hide() end
    if castbar.iconBorder then castbar.iconBorder:Hide() end
    if castbar.spark then castbar.spark:Hide() end
    
    -- Stop any active glow and hide container
    StopCastbarGlow(castbar)
    if castbar.glowFrame then
        castbar.glowFrame:Hide()
    end
    castbar.isHighlighted = nil
end

-- OnUpdate handler for smooth progress bar animation
local function CastbarOnUpdate(self, elapsed)
    if self.casting then
        self.duration = self.duration + elapsed
        if self.duration >= self.max then
            HideCastbar(self)
            return
        end
        self:SetValue(self.duration)
        if GetShowCastTimer() then
            self.timeText:SetText(GetCachedTime(self.max - self.duration))
        else
            self.timeText:SetText("")
        end
        -- Update spark position
        if self.spark and GetShowCastSpark() then
            local progress = self.duration / self.max
            local width = self:GetWidth()
            self.spark:SetPoint("CENTER", self, "LEFT", width * progress, 0)
            self.spark:Show()
        elseif self.spark then
            self.spark:Hide()
        end
    elseif self.channeling then
        self.duration = self.duration - elapsed
        if self.duration <= 0 then
            HideCastbar(self)
            return
        end
        self:SetValue(self.duration)
        if GetShowCastTimer() then
            self.timeText:SetText(GetCachedTime(self.duration))
        else
            self.timeText:SetText("")
        end
        -- Update spark position for channeling
        if self.spark and GetShowCastSpark() then
            local progress = self.duration / self.max
            local width = self:GetWidth()
            self.spark:SetPoint("CENTER", self, "LEFT", width * progress, 0)
            self.spark:Show()
        elseif self.spark then
            self.spark:Hide()
        end
    elseif self.holdTime > 0 then
        self.holdTime = self.holdTime - elapsed
        if self.spark then self.spark:Hide() end
    else
        HideCastbar(self)
    end
end

-- Start a cast (handles both cast and channel start)
local function CastStart(castbar, unit)
    if not unit then return end
    if not GetShowCastbar() then 
        HideCastbar(castbar)
        return 
    end
    
    -- Never show castbar for player's personal nameplate
    if UnitIsUnit(unit, "player") then
        HideCastbar(castbar)
        return
    end
    
    -- Try casting first
    -- WoW 3.3.5 UnitCastingInfo returns: name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible
    local name, _, _, texture, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
    local isCasting = true
    
    if not name then
        -- Try channel
        -- WoW 3.3.5 UnitChannelInfo returns: name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible
        name, _, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        isCasting = false
    end
    
    if not name then
        HideCastbar(castbar)
        return
    end
    
    -- Safety check for missing time values (some special casts may not have them)
    if not startTime or not endTime then
        HideCastbar(castbar)
        return
    end
    
    endTime = endTime / 1000
    startTime = startTime / 1000
    
    -- Validate times are reasonable
    if endTime <= startTime then
        HideCastbar(castbar)
        return
    end
    
    castbar.max = endTime - startTime
    castbar.startTime = startTime
    castbar.casting = isCasting or nil
    castbar.channeling = (not isCasting) or nil
    castbar.notInterruptible = notInterruptible
    castbar.holdTime = 0
    castbar.castID = castID
    castbar.spellName = name
    
    if isCasting then
        castbar.duration = GetTime() - startTime
    else
        castbar.duration = endTime - GetTime()
    end
    
    castbar:SetMinMaxValues(0, castbar.max)
    castbar:SetValue(castbar.duration)
    
    castbar.spellText:SetText(name)
    if castbar.icon then
        castbar.icon:SetTexture(texture)
    end
    
    -- Set color based on interruptibility
    if notInterruptible then
        castbar:SetStatusBarColor(GetNoInterruptColor())
    else
        castbar:SetStatusBarColor(GetCastColor())
    end
    
    -- Show icon if enabled (position relative to castbar)
    if GetShowCastIcon() and castbar.icon then
        local iconSize = addon.c_castHeight or 12
        PixelUtil.SetSize(castbar.icon, iconSize, iconSize, 1, 1)
        castbar.icon:ClearAllPoints()
        PixelUtil.SetPoint(castbar.icon, "RIGHT", castbar, "LEFT", -2, 0, 1, 1)
        castbar.icon:Show()
        if castbar.iconBorder then
            castbar.iconBorder:ClearAllPoints()
            castbar.iconBorder:SetAllPoints(castbar.icon)
            castbar.iconBorder:Show()
        end
    else
        if castbar.icon then castbar.icon:Hide() end
        if castbar.iconBorder then castbar.iconBorder:Hide() end
    end

    -- Skip highlights for friendly units and totems
    local skipHighlight = UnitIsFriend("player", unit) or UnitCreatureType(unit) == "Totem"

    -- Check for highlight spell only if glow is enabled
    local glowEnabled = GetHighlightGlowEnabled()
    
    if glowEnabled and not skipHighlight then
        local isHighlight = IsHighlightSpell(name)
        castbar.isHighlighted = isHighlight
        
        if isHighlight then
            -- Apply glow effect
            StartCastbarGlow(castbar)
        else
            StopCastbarGlow(castbar)
        end
    else
        -- Glow disabled, ensure any previous glow is stopped
        castbar.isHighlighted = nil
        StopCastbarGlow(castbar)
    end
    
    castbar:Show()
end



-- Handle cast update (delayed/pushed back)
local function CastUpdate(castbar, unit, event)
    if not castbar:IsShown() then return end
    
    local name, startTime, endTime, _
    if event == "UNIT_SPELLCAST_DELAYED" then
        name, _, _, _, startTime, endTime = UnitCastingInfo(unit)
    else
        name, _, _, _, startTime, endTime = UnitChannelInfo(unit)
    end
    
    if not name then return end
    
    endTime = endTime / 1000
    startTime = startTime / 1000
    
    if castbar.casting then
        castbar.duration = GetTime() - startTime
    else
        castbar.duration = endTime - GetTime()
    end
    
    castbar.max = endTime - startTime
    castbar.startTime = startTime
    
    castbar:SetMinMaxValues(0, castbar.max)
    castbar:SetValue(castbar.duration)
end

-- Handle cast stop
local function CastStop(castbar, unit, castID)
    if not castbar:IsShown() then return end
    
    -- Verify castID for casts (not channels)
    if castbar.castID and castbar.castID ~= castID then return end
    
    HideCastbar(castbar)
end

-- Handle cast fail/interrupt
local function CastFail(castbar, unit, castID, event)
    if not castbar:IsShown() then return end
    if castbar.castID and castbar.castID ~= castID then return end
    
    castbar:SetValue(castbar.max)
    castbar:SetStatusBarColor(1.0, 0.0, 0.0)
    castbar.spellText:SetText(event == "UNIT_SPELLCAST_FAILED" and FAILED or INTERRUPTED)
    
    castbar.casting = nil
    castbar.channeling = nil
    castbar.holdTime = 0.5  -- Brief hold to show failed state
end

-- Handle interruptible state change
local function CastInterruptible(castbar, unit, notInterruptible)
    if not castbar:IsShown() then return end
    
    castbar.notInterruptible = notInterruptible
    
    -- Use helper functions for cached colors
    if notInterruptible then
        castbar:SetStatusBarColor(GetNoInterruptColor())
    else
        castbar:SetStatusBarColor(GetCastColor())
    end
end

function ns:CreateCastbar(myPlate)
    local cb = CreateFrame("StatusBar", nil, myPlate)
    cb:SetStatusBarTexture(ns.c_texture or ns.GetTexture(ns.defaults.texture))
    cb:SetStatusBarColor(1, 0.8, 0)
    cb:EnableMouse(false)  -- Pass through clicks
    cb:Hide()

    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(cb)
    bg:SetTexture(0, 0, 0, 0.75)

    -- Pixel-perfect texture border for castbar
    cb.border = CreateTextureBorder(cb, 1)
    
    -- Dedicated glow frame - parented to myPlate so it can cover castbar + icon area
    local glowFrame = CreateFrame("Frame", nil, myPlate)
    glowFrame:SetFrameLevel(cb:GetFrameLevel() + 5)
    glowFrame:Hide()  -- Start hidden, shown only when glow is active
    cb.glowFrame = glowFrame

    -- Icon parented to castbar for consistent pixel alignment
    local icon = cb:CreateTexture(nil, "OVERLAY")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:Hide()
    cb.icon = icon
    
    -- Pixel-perfect texture border for icon
    local iconBorder = CreateFrame("Frame", nil, cb)
    iconBorder:EnableMouse(false)
    iconBorder.border = CreateTextureBorder(iconBorder, 1)
    iconBorder:Hide()
    cb.iconBorder = iconBorder

    local fontPath = ns.c_font or ns.GetFont(ns.defaults.font)
    local timeText = cb:CreateFontString(nil, "OVERLAY")
    timeText:SetFont(fontPath, 8, "OUTLINE")
    timeText:SetPoint("RIGHT", cb, "RIGHT", -4, 0)

    local spellText = cb:CreateFontString(nil, "OVERLAY")
    spellText:SetFont(fontPath, 8, "OUTLINE")
    spellText:SetPoint("LEFT", cb, "LEFT", 4, 0)
    spellText:SetPoint("RIGHT", timeText, "LEFT", -5, 0)
    spellText:SetJustifyH("LEFT")
    spellText:SetWordWrap(false)
    
    -- Spark (bright edge indicator at cast progress)
    local spark = cb:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("ADD")
    spark:SetSize(16, cb:GetHeight() * 2)
    spark:SetVertexColor(1, 1, 0.8)
    spark:Hide()
    cb.spark = spark

    myPlate.castbar = cb
    cb.timeText = timeText
    cb.spellText = spellText
    cb.myPlate = myPlate

    -- Initialize state
    ResetCastbar(cb)
    cb.duration = 0
    cb.max = 1
    
    -- Set OnUpdate (always set, but only runs when visible due to how WoW works)
    cb:SetScript("OnUpdate", CastbarOnUpdate)
    
    return cb
end

-------------------------------------------------------------------------------
-- GLOBAL EVENT FRAME
-- ONE event frame handles ALL nameplates - much more efficient than per-castbar registration
-------------------------------------------------------------------------------
local castbarEventFrame = CreateFrame("Frame")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
castbarEventFrame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

-- Cache unit prefix check ("nameplate" is 9 characters)
local NAMEPLATE_PREFIX = "nameplate"

castbarEventFrame:SetScript("OnEvent", function(self, event, unit, _, _, castID)
    -- Skip non-nameplate units
    if not unit then return end
    
    -- Always use addon.unitToPlate directly (not a stale cached reference)
    local unitToPlate = addon.unitToPlate
    if not unitToPlate then return end
    
    -- Check if this is a nameplate unit (must start with "nameplate")
    if sub(unit, 1, 9) ~= NAMEPLATE_PREFIX then return end
    
    -- Get plate for this unit
    local myPlate = unitToPlate[unit]
    if not myPlate or not myPlate.castbar then return end
    
    local castbar = myPlate.castbar
    
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        CastStart(castbar, unit)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        CastStop(castbar, unit, castID)
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        CastFail(castbar, unit, castID, event)
    elseif event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        CastUpdate(castbar, unit, event)
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        CastInterruptible(castbar, unit, false)
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        CastInterruptible(castbar, unit, true)
    end
end)

-------------------------------------------------------------------------------
-- PUBLIC API (called from Core.lua and Nameplates.lua)
-------------------------------------------------------------------------------

-- Check for existing cast when nameplate is added
function ns:CheckExistingCast(unit)
    if not unit then return end
    if not GetShowCastbar() then return end
    
    local plates = self.unitToPlate
    if not plates then return end
    
    local myPlate = plates[unit]
    if not myPlate or not myPlate.castbar then return end
    
    CastStart(myPlate.castbar, unit)
end

-- Clean up castbar when nameplate is removed
function ns:CleanupCastbar(unit)
    local plates = self.unitToPlate
    if not plates then return end
    
    local myPlate = plates[unit]
    if myPlate and myPlate.castbar then
        HideCastbar(myPlate.castbar)
    end
end
