local addonName, ns = ...
local L = ns.L

-- Cache frequently used globals
local C_CVar = C_CVar
local C_NamePlateManager = C_NamePlateManager
local C_NamePlate = C_NamePlate
local CreateFrame = CreateFrame
local UnitClass = UnitClass
local pairs = pairs
local floor = math.floor
local max = math.max
local min = math.min
local PixelUtil = PixelUtil

-- Media paths
local mediaPath = "Interface\\AddOns\\TurboPlates\\Textures\\"
local bdTex = "Interface\\Buttons\\WHITE8X8"
local glowTex = mediaPath.."glowTex.blp"
local bgTex = mediaPath.."bgTex.blp"

-- GUI font (immune to system font overrides from other addons)
local GUI_FONT = "Interface\\AddOns\\TurboPlates\\Fonts\\FRIZQT__.ttf"

-- Alpha bias to prevent 1px border dropout in 3.3.5 client
local BORDER_ALPHA = 0.9

-- Create pixel-perfect texture-based border (replaces SetBackdrop for solid borders)
local function CreateTextureBorder(parent, thickness)
    thickness = thickness or 1
    -- Options GUI frames are UIParent children - use actual parent scale
    local scale = parent:GetEffectiveScale()
    local pixelSize = PixelUtil.GetNearestPixelSize(thickness, scale, 1)
    
    local border = {}
    local tex = "Interface\\Buttons\\WHITE8X8"
    
    -- Use OVERLAY layer so borders render above StatusBar fill
    -- Anchor borders INSIDE the frame edges to avoid sub-pixel issues
    border.top = parent:CreateTexture(nil, "OVERLAY")
    border.top:SetTexture(tex)
    border.top:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    PixelUtil.SetHeight(border.top, pixelSize, 1)
    
    border.bottom = parent:CreateTexture(nil, "OVERLAY")
    border.bottom:SetTexture(tex)
    border.bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    PixelUtil.SetHeight(border.bottom, pixelSize, 1)
    
    border.left = parent:CreateTexture(nil, "OVERLAY")
    border.left:SetTexture(tex)
    border.left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -pixelSize)
    border.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, pixelSize)
    PixelUtil.SetWidth(border.left, pixelSize, 1)
    
    border.right = parent:CreateTexture(nil, "OVERLAY")
    border.right:SetTexture(tex)
    border.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -pixelSize)
    border.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, pixelSize)
    PixelUtil.SetWidth(border.right, pixelSize, 1)
    
    function border:SetColor(r, g, b, a)
        -- Clamp alpha to BORDER_ALPHA max to maintain anti-dropout behavior
        a = a and math.min(a, BORDER_ALPHA) or BORDER_ALPHA
        self.top:SetVertexColor(r, g, b, a)
        self.bottom:SetVertexColor(r, g, b, a)
        self.left:SetVertexColor(r, g, b, a)
        self.right:SetVertexColor(r, g, b, a)
    end
    
    function border:Show()
        self.top:Show()
        self.bottom:Show()
        self.left:Show()
        self.right:Show()
    end
    
    function border:Hide()
        self.top:Hide()
        self.bottom:Hide()
        self.left:Hide()
        self.right:Hide()
    end
    
    function border:GetColor()
        return self.top:GetVertexColor()
    end
    
    border:SetColor(0, 0, 0, BORDER_ALPHA)
    return border
end

-- Class color
local _, class = UnitClass("player")
local classColor = RAID_CLASS_COLORS[class] or {r=1, g=1, b=1}
local cr, cg, cb = classColor.r, classColor.g, classColor.b

-- GUI state
local guiFrame, guiTab, guiPage = nil, {}, {}
local reopenAfterCombat = false

-- Forward declare ShowGUI for combat handler
local ShowGUI

-- Combat lockdown handler - auto-close during combat
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat: close options if open
        if guiFrame and guiFrame:IsVisible() then
            reopenAfterCombat = true
            guiFrame:Hide()
            print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Options closed due to combat.")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat: reopen if it was open before or user tried to open during combat
        if reopenAfterCombat then
            reopenAfterCombat = false
            -- Use C_Timer.After to ensure combat state is fully cleared
            C_Timer.After(0, function()
                if not InCombatLockdown() then
                    ShowGUI()
                end
            end)
        end
    end
end)

StaticPopupDialogs["TURBOPLATES_RESET"] = {
    text = "Reset all TurboPlates settings to defaults?\n\nThis will reload your UI.\n(Spell lists will be preserved)",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        -- Preserve spell lists before reset
        local savedBlacklist = TurboPlatesDB and TurboPlatesDB.auras and TurboPlatesDB.auras.blacklist
        local savedWhitelist = TurboPlatesDB and TurboPlatesDB.auras and TurboPlatesDB.auras.whitelist
        local savedHighlightSpells = TurboPlatesDB and TurboPlatesDB.highlightSpells
        
        -- Reset settings
        TurboPlatesDB = nil
        
        -- Restore spell lists if they existed
        if savedBlacklist or savedWhitelist or savedHighlightSpells then
            TurboPlatesDB = {}
            if savedBlacklist or savedWhitelist then
                TurboPlatesDB.auras = {}
                if savedBlacklist then TurboPlatesDB.auras.blacklist = savedBlacklist end
                if savedWhitelist then TurboPlatesDB.auras.whitelist = savedWhitelist end
            end
            if savedHighlightSpells then TurboPlatesDB.highlightSpells = savedHighlightSpells end
        end
        
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function UpdateAll()
    if ns.UpdateDBCache then ns:UpdateDBCache() end
    if ns.UpdateAllPlates then ns:UpdateAllPlates() end
    if ns.UpdateMinimapButton then ns:UpdateMinimapButton() end
    if ns.UpdatePreview then ns.UpdatePreview() end
end

-- Throttled version for sliders (30ms delay)
local updatePending = false
local function UpdateAllThrottled()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.03, function()
        updatePending = false
        UpdateAll()
    end)
end

-- Dark backdrop style
local defaultBackdrop = {
    bgFile = bdTex,
    edgeFile = bdTex,
    edgeSize = 1,
    insets = {left = 1, right = 1, top = 1, bottom = 1}
}

local function CreateBD(frame, a)
    -- Background texture
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture(0, 0, 0, a or 0.6)
    frame.__bg = bg
    
    -- Pixel-perfect 1px border
    frame.__border = CreateTextureBorder(frame, 1)
end

local function CreateSD(frame, size)
    if frame.__shadow then return end
    local sd = CreateFrame("Frame", nil, frame)
    sd:SetBackdrop({edgeFile = glowTex, edgeSize = size or 4})
    sd:SetBackdropBorderColor(0, 0, 0, 0.4)
    sd:SetPoint("TOPLEFT", frame, -4, 4)
    sd:SetPoint("BOTTOMRIGHT", frame, 4, -4)
    sd:SetFrameLevel(0)
    frame.__shadow = sd
end

-- Subtle background texture with faint diagonal lines for depth
local function CreateTex(frame)
    if frame.__bgTex then return end
    local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    tex:SetAllPoints()
    tex:SetTexture(bgTex, true, true)  -- Enable tiling
    tex:SetHorizTile(true)
    tex:SetVertTile(true)
    tex:SetBlendMode("ADD")
    tex:SetAlpha(0.08)  -- Extremely subtle - barely visible lines for depth
    frame.__bgTex = tex
    return tex
end

-- Create inner gradient for depth effect
local function CreateInnerGradient(frame)
    if frame.__innerGrad then return end
    local tex = frame:CreateTexture(nil, "BORDER")
    tex:SetAllPoints()
    tex:SetTexture(bdTex)
    tex:SetGradientAlpha("VERTICAL", 0.05, 0.05, 0.05, 0.3, 0.15, 0.15, 0.15, 0.1)
    frame.__innerGrad = tex
    return tex
end

local function CreateFS(parent, size, text, color, anchor, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(GUI_FONT, size, "OUTLINE")
    fs:SetText(text or "")
    if color == "class" then
        fs:SetTextColor(cr, cg, cb)
    elseif color == "system" then
        fs:SetTextColor(1, 0.8, 0)
    else
        fs:SetTextColor(1, 1, 1)
    end
    if anchor then fs:SetPoint(anchor, x or 0, y or 0) end
    return fs
end

-- Create gradient background
local function CreateGradient(frame)
    local tex = frame:CreateTexture(nil, "BORDER")
    tex:SetAllPoints()
    tex:SetTexture(bdTex)
    tex:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.5, 0.3, 0.3, 0.3, 0.3)
    return tex
end

-- Button helpers
local function Button_OnEnter(self)
    if self.__gradient then
        self.__gradient:SetGradientAlpha("VERTICAL", cr*0.3, cg*0.3, cb*0.3, 0.5, cr*0.5, cg*0.5, cb*0.5, 0.3)
    end
    if self.__border then
        self.__border:SetColor(cr, cg, cb, 1)
    end
end
local function Button_OnLeave(self)
    if self.__gradient then
        self.__gradient:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.5, 0.3, 0.3, 0.3, 0.3)
    end
    if self.__border then
        self.__border:SetColor(0, 0, 0, 1)
    end
end
local function Button_OnMouseDown(self)
    if self.__gradient then
        self.__gradient:SetGradientAlpha("VERTICAL", 0.2, 0.2, 0.2, 0.5, 0, 0, 0, 0.5)
    end
    if self.text then
        self.text:SetPoint("CENTER", 1, -1)
    end
end
local function Button_OnMouseUp(self)
    if self.text then
        self.text:SetPoint("CENTER", 0, 0)
    end
    -- Restore hover state if still hovering
    if self:IsMouseOver() then
        Button_OnEnter(self)
    else
        Button_OnLeave(self)
    end
end

local function CreateButton(parent, width, height, text)
    local bu = CreateFrame("Button", nil, parent)
    bu:SetSize(width, height)
    
    -- Gradient background for 3D button look
    bu.__gradient = bu:CreateTexture(nil, "BACKGROUND")
    bu.__gradient:SetAllPoints()
    bu.__gradient:SetTexture(bdTex)
    bu.__gradient:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.5, 0.3, 0.3, 0.3, 0.3)
    
    -- Border
    bu.__border = CreateTextureBorder(bu, 1)
    
    bu.text = CreateFS(bu, 13, text, nil, "CENTER")
    
    bu:HookScript("OnEnter", Button_OnEnter)
    bu:HookScript("OnLeave", Button_OnLeave)
    bu:HookScript("OnMouseDown", Button_OnMouseDown)
    bu:HookScript("OnMouseUp", Button_OnMouseUp)
    
    -- Hook SetFrameLevel to also update __bg frame level
    local oldSetFrameLevel = bu.SetFrameLevel
    bu.SetFrameLevel = function(self, level)
        oldSetFrameLevel(self, level)
        if self.__bg then
            self.__bg:SetFrameLevel(level)
        end
    end
    
    return bu
end

-- =============================================================================
-- SPELL LIST MANAGER (Blacklist/Whitelist Panel)
-- =============================================================================
local spellListPanels = {}  -- Store created panels to toggle visibility

local function CreateSpellListPanel(parentFrame, listType)
    -- listType = "blacklist" or "whitelist"
    local panelName = "TurboPlatesSpellList_" .. listType
    local otherType = listType == "blacklist" and "whitelist" or "blacklist"
    
    -- If panel already exists, just toggle it
    if spellListPanels[listType] then
        if spellListPanels[listType]:IsShown() then
            spellListPanels[listType]:Hide()
        else
            -- Hide other panel first
            if spellListPanels[otherType] and spellListPanels[otherType]:IsShown() then
                spellListPanels[otherType]:Hide()
            end
            spellListPanels[listType]:Show()
        end
        return spellListPanels[listType]
    end
    
    -- Hide other panel if it exists (for first-time creation)
    if spellListPanels[otherType] and spellListPanels[otherType]:IsShown() then
        spellListPanels[otherType]:Hide()
    end
    
    -- Create the panel (slides out to the right of main GUI)
    -- Match main GUI styling exactly
    local panel = CreateFrame("Frame", panelName, guiFrame, "BackdropTemplate")
    panel:SetSize(280, 500)
    panel:SetPoint("TOPLEFT", guiFrame, "TOPRIGHT", 3, 0)
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(guiFrame:GetFrameLevel() + 10)
    CreateBD(panel, 0.5)  -- Same alpha as main GUI
    CreateSD(panel, 4)
    CreateTex(panel)
    CreateInnerGradient(panel)  -- Glass depth effect like main GUI
    
    -- Title
    local title = listType == "blacklist" and L.BlacklistManager or L.WhitelistManager
    local titleFS = CreateFS(panel, 14, title, "system", "TOPLEFT", 15, -15)
    
    -- Description
    local desc = listType == "blacklist" and L.BlacklistDesc or L.WhitelistDesc
    local descFS = CreateFS(panel, 11, desc, nil, "TOPLEFT", 15, -35)
    descFS:SetTextColor(0.7, 0.7, 0.7)
    
    -- Input editbox for Spell ID
    local inputBox = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
    inputBox:SetSize(150, 24)
    inputBox:SetPoint("TOPLEFT", 15, -60)
    inputBox:SetFont(GUI_FONT, 12, "")
    inputBox:SetAutoFocus(false)
    inputBox:SetNumeric(true)
    inputBox:SetMaxLetters(10)
    CreateBD(inputBox, 0.3)
    inputBox.__border:SetColor(0.3, 0.3, 0.3, 1)
    inputBox:SetTextInsets(8, 8, 0, 0)
    
    -- Placeholder text
    local placeholder = inputBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetText("Spell ID")
    placeholder:SetTextColor(0.5, 0.5, 0.5)
    inputBox:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    inputBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then placeholder:Show() end
    end)
    
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    inputBox:SetScript("OnEnterPressed", function(self)
        -- Trigger add button
        self:ClearFocus()
    end)
    
    -- Add button
    local addBtn = CreateButton(panel, 70, 24, L.AddSpell)
    addBtn:SetPoint("LEFT", inputBox, "RIGHT", 10, 0)
    addBtn:SetFrameLevel(panel:GetFrameLevel() + 50)  -- Match main GUI button level
    
    -- Spell preview (icon + name)
    local previewFrame = CreateFrame("Frame", nil, panel)
    previewFrame:SetSize(250, 30)
    previewFrame:SetPoint("TOPLEFT", 15, -92)
    
    local previewIcon = previewFrame:CreateTexture(nil, "ARTWORK")
    previewIcon:SetSize(24, 24)
    previewIcon:SetPoint("LEFT", 0, 0)
    previewIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    previewFrame.icon = previewIcon
    
    local previewIconBorder = CreateFrame("Frame", nil, previewFrame, "BackdropTemplate")
    previewIconBorder:SetSize(26, 26)
    previewIconBorder:SetPoint("CENTER", previewIcon, "CENTER")
    CreateBD(previewIconBorder, 0)
    previewFrame.iconBorder = previewIconBorder
    
    local previewName = CreateFS(previewFrame, 12, "", nil, "LEFT", 32, 0)
    previewFrame.name = previewName
    previewFrame:Hide()
    
    -- Update preview when typing
    inputBox:SetScript("OnTextChanged", function(self)
        local spellID = tonumber(self:GetText())
        if spellID and spellID > 0 then
            local name, _, icon = GetSpellInfo(spellID)
            if name and icon then
                previewIcon:SetTexture(icon)
                previewName:SetText(name)
                previewFrame:Show()
                return
            end
        end
        previewFrame:Hide()
    end)
    
    -- Scrollable list area (leave room for bottom buttons)
    local listBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    listBg:SetSize(250, 323)
    listBg:SetPoint("TOPLEFT", 15, -127)
    CreateBD(listBg, 0.25)
    
    -- Custom scroll frame (no default template - we'll make our own scrollbar)
    local scrollFrame = CreateFrame("ScrollFrame", nil, listBg)
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -5, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(240, 1)  -- Height will be set dynamically
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Custom scrollbar (only visible when needed)
    local scrollBar = CreateFrame("Frame", nil, listBg)
    scrollBar:SetSize(8, 311)
    scrollBar:SetPoint("TOPRIGHT", -2, -6)
    scrollBar:Hide()  -- Hidden by default
    
    local scrollThumb = CreateFrame("Button", nil, scrollBar)
    scrollThumb:SetSize(8, 40)
    scrollThumb:SetPoint("TOP", 0, 0)
    local thumbTex = scrollThumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetTexture(bdTex)
    thumbTex:SetVertexColor(cr, cg, cb, 0.6)
    scrollThumb.tex = thumbTex
    
    scrollThumb:SetScript("OnEnter", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.9) end)
    scrollThumb:SetScript("OnLeave", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.6) end)
    
    -- Scrollbar dragging (OnUpdate only active while dragging)
    local function ScrollThumbOnUpdate(self)
        local _, cursorY = GetCursorPosition()
        local scale = scrollBar:GetEffectiveScale()
        cursorY = cursorY / scale
        local barTop = scrollBar:GetTop()
        local barHeight = scrollBar:GetHeight() - self:GetHeight()
        local offset = barTop - cursorY - self:GetHeight() / 2
        offset = max(0, min(barHeight, offset))
        local scrollMax = scrollFrame:GetVerticalScrollRange()
        scrollFrame:SetVerticalScroll(scrollMax * (offset / barHeight))
    end
    scrollThumb:SetScript("OnMouseDown", function(self)
        self:SetScript("OnUpdate", ScrollThumbOnUpdate)
    end)
    scrollThumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    
    -- Mouse wheel scrolling
    listBg:EnableMouseWheel(true)
    listBg:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        local newScroll = current - (delta * 30)
        newScroll = max(0, min(maxScroll, newScroll))
        scrollFrame:SetVerticalScroll(newScroll)
    end)
    
    -- Update scrollbar position when scrolling
    local function UpdateScrollBar()
        local scrollMax = scrollFrame:GetVerticalScrollRange()
        if scrollMax > 0 then
            scrollBar:Show()
            -- Adjust scroll child width when scrollbar is visible
            scrollChild:SetWidth(232)
            -- Adjust scrollframe
            scrollFrame:SetPoint("BOTTOMRIGHT", -14, 5)
            -- Update thumb position
            local scrollCurrent = scrollFrame:GetVerticalScroll()
            local barHeight = scrollBar:GetHeight() - scrollThumb:GetHeight()
            local thumbOffset = (scrollCurrent / scrollMax) * barHeight
            scrollThumb:SetPoint("TOP", 0, -thumbOffset)
        else
            scrollBar:Hide()
            scrollChild:SetWidth(245)
            scrollFrame:SetPoint("BOTTOMRIGHT", -3, 5)
        end
    end
    
    scrollFrame:SetScript("OnScrollRangeChanged", UpdateScrollBar)
    scrollFrame:SetScript("OnVerticalScroll", UpdateScrollBar)
    
    panel.scrollChild = scrollChild
    panel.bars = {}  -- Store spell bars
    
    -- Function to refresh the spell list
    local function RefreshSpellList()
        -- Hide all existing bars
        for _, bar in pairs(panel.bars) do
            bar:Hide()
        end
        
        -- Get the appropriate list
        local list = TurboPlatesDB.auras and TurboPlatesDB.auras[listType] or {}
        
        local index = 0
        for spellID, _ in pairs(list) do
            index = index + 1
            local bar = panel.bars[index]
            
            if not bar then
                -- Create new bar
                bar = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                PixelUtil.SetSize(bar, 230, 28)
                CreateBD(bar, 0.2)
                
                -- Icon with border frame
                local iconFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
                PixelUtil.SetSize(iconFrame, 22, 22)
                iconFrame:SetPoint("LEFT", 3, 0)
                CreateBD(iconFrame, 0)
                
                local icon = iconFrame:CreateTexture(nil, "ARTWORK")
                local inset = PixelUtil.GetNearestPixelSize(1, iconFrame:GetEffectiveScale(), 1)
                icon:SetPoint("TOPLEFT", inset, -inset)
                icon:SetPoint("BOTTOMRIGHT", -inset, inset)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                bar.icon = icon
                
                -- Name
                local nameFS = CreateFS(bar, 11, "", nil, "LEFT", 30, 0)
                nameFS:SetWidth(145)
                nameFS:SetJustifyH("LEFT")
                bar.nameFS = nameFS
                
                -- Spell ID text
                local idFS = CreateFS(bar, 10, "", nil, "RIGHT", -30, 0)
                idFS:SetTextColor(0.5, 0.5, 0.5)
                bar.idFS = idFS
                
                -- Remove button
                local removeBtn = CreateFrame("Button", nil, bar)
                removeBtn:SetSize(16, 16)
                removeBtn:SetPoint("RIGHT", -5, 0)
                removeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
                removeBtn:GetNormalTexture():SetVertexColor(0.8, 0.2, 0.2)
                removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
                removeBtn:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3)
                bar.removeBtn = removeBtn
                
                -- Tooltip on icon hover
                bar:SetScript("OnEnter", function(self)
                    if self.spellID then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetSpellByID(self.spellID)
                        GameTooltip:Show()
                    end
                end)
                bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
                
                panel.bars[index] = bar
            end
            
            -- Populate bar data
            local name, _, icon = GetSpellInfo(spellID)
            bar.spellID = spellID
            bar.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            bar.nameFS:SetText(name or "Unknown")
            bar.idFS:SetText(tostring(spellID))
            bar:ClearAllPoints()
            -- Calculate pixel-perfect offset
            local scale = scrollChild:GetEffectiveScale()
            local spacing = PixelUtil.GetNearestPixelSize(30, scale, 1)
            local yOffset = -(index - 1) * spacing
            bar:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
            bar:Show()
            
            -- Remove button click handler
            bar.removeBtn:SetScript("OnClick", function()
                PlaySound(856)
                local removedName = GetSpellInfo(spellID)
                if TurboPlatesDB.auras and TurboPlatesDB.auras[listType] then
                    TurboPlatesDB.auras[listType][spellID] = nil
                end
                -- Refresh cached settings
                if ns.CacheAuraSettings then ns:CacheAuraSettings() end
                RefreshSpellList()
                local listDisplayName = listType == "whitelist" and "Whitelist" or "Blacklist"
                if removedName then
                    print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Removed from " .. listDisplayName .. " - " .. removedName)
                end
            end)
        end
        
        -- Update scroll child height
        scrollChild:SetHeight(math.max(1, index * 30))
        
        -- Show "no spells" message if empty
        if index == 0 then
            if not panel.emptyText then
                panel.emptyText = CreateFS(scrollChild, 12, L.NoSpellsInList, nil, "TOP", 0, -20)
                panel.emptyText:SetTextColor(0.5, 0.5, 0.5)
            end
            panel.emptyText:Show()
        elseif panel.emptyText then
            panel.emptyText:Hide()
        end
    end
    
    panel.RefreshSpellList = RefreshSpellList
    
    -- Add button click handler
    addBtn:SetScript("OnClick", function()
        PlaySound(856)
        local spellID = tonumber(inputBox:GetText())
        if not spellID or spellID <= 0 then
            print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: " .. L.InvalidSpellID)
            return
        end
        
        local name = GetSpellInfo(spellID)
        if not name then
            print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: " .. L.InvalidSpellID)
            return
        end
        
        -- Ensure auras table exists
        if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
        if not TurboPlatesDB.auras[listType] then TurboPlatesDB.auras[listType] = {} end
        
        -- Check if already exists
        if TurboPlatesDB.auras[listType][spellID] then
            local listDisplayName = listType == "whitelist" and "Whitelist" or "Blacklist"
            print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Spell already in " .. listDisplayName)
            return
        end
        
        -- Add to list
        TurboPlatesDB.auras[listType][spellID] = true
        
        -- Refresh cached settings
        if ns.CacheAuraSettings then ns:CacheAuraSettings() end
        
        -- Clear input and refresh list
        inputBox:SetText("")
        previewFrame:Hide()
        RefreshSpellList()
        local listDisplayName = listType == "whitelist" and "Whitelist" or "Blacklist"
        print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Added to " .. listDisplayName .. " - " .. name)
    end)
    
    -- Also trigger add on Enter key
    inputBox:HookScript("OnEnterPressed", function()
        addBtn:Click()
    end)
    
    -- Bottom buttons (same style as main GUI Reset/Close buttons)
    local clearBtn = CreateButton(panel, 120, 26, L.ClearAll)
    clearBtn:SetPoint("BOTTOMLEFT", 15, 15)
    clearBtn:SetFrameLevel(panel:GetFrameLevel() + 50)  -- Match main GUI button level
    clearBtn:SetScript("OnClick", function()
        PlaySound(856)
        StaticPopupDialogs["TURBOPLATES_CLEAR_SPELLLIST"] = {
            text = "Clear all spells from " .. (listType == "blacklist" and "Blacklist" or "Whitelist") .. "?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                if TurboPlatesDB.auras then
                    TurboPlatesDB.auras[listType] = {}
                end
                if ns.CacheAuraSettings then ns:CacheAuraSettings() end
                RefreshSpellList()
                print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: " .. L.ListCleared)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("TURBOPLATES_CLEAR_SPELLLIST")
    end)
    
    local closeBtn = CreateButton(panel, 120, 26, L.Close or "Close")
    closeBtn:SetPoint("BOTTOMRIGHT", -15, 15)
    closeBtn:SetFrameLevel(panel:GetFrameLevel() + 50)  -- Match main GUI button level
    closeBtn:SetScript("OnClick", function() PlaySound(856); panel:Hide() end)
    
    -- Hide when main GUI hides
    guiFrame:HookScript("OnHide", function() panel:Hide() end)
    
    -- Refresh list on show
    panel:SetScript("OnShow", RefreshSpellList)
    
    -- Store panel reference
    spellListPanels[listType] = panel
    
    -- Initial refresh
    RefreshSpellList()
    
    return panel
end

-- Helper function to open spell list panel (called from buttons on Debuffs/Buffs tabs)
local function OpenSpellListPanel(listType)
    CreateSpellListPanel(guiFrame, listType)
end

-- Checkbox
local function CreateCheckBox(parent, var, label, x, y, callback)
    local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    chk:SetSize(16, 16)
    chk:SetPoint("TOPLEFT", x, y)
    chk:SetNormalTexture("")
    chk:SetPushedTexture("")
    
    local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
    bg:SetAllPoints()
    bg:SetFrameLevel(chk:GetFrameLevel() - 1)
    CreateBD(bg, 0.3)
    CreateGradient(bg)
    chk.bg = bg
    
    chk:SetHighlightTexture(bdTex)
    local hl = chk:GetHighlightTexture()
    hl:SetAllPoints(bg)
    hl:SetVertexColor(cr, cg, cb, 0.25)
    
    local check = chk:CreateTexture(nil, "OVERLAY")
    check:SetSize(20, 20)
    check:SetPoint("CENTER")
    check:SetAtlas("questlog-icon-checkmark-yellow-2x")
    check:SetVertexColor(1, 0.82, 0)
    chk:SetCheckedTexture(check)
    
    chk.label = CreateFS(chk, 13, label, nil, "LEFT", 24, 0)
    chk:SetHitRectInsets(0, -chk.label:GetStringWidth()-10, 0, 0)
    
    if var then
        chk:SetChecked(TurboPlatesDB[var])
        chk:SetScript("OnClick", function(self)
            TurboPlatesDB[var] = self:GetChecked() and true or false
            UpdateAll()
            if callback then callback(self) end
        end)
        chk:SetScript("OnShow", function(self) self:SetChecked(TurboPlatesDB[var]) end)
    end
    return chk
end

-- CVar Checkbox (reads/writes game CVars instead of addon saved variables)
-- Stores reference in ns.cvarCheckboxes for external sync
local function CreateCVarCheckBox(parent, cvar, label, x, y, callback)
    local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    chk:SetSize(16, 16)
    chk:SetPoint("TOPLEFT", x, y)
    chk:SetNormalTexture("")
    chk:SetPushedTexture("")
    
    local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
    bg:SetAllPoints()
    bg:SetFrameLevel(chk:GetFrameLevel() - 1)
    CreateBD(bg, 0.3)
    CreateGradient(bg)
    chk.bg = bg
    
    chk:SetHighlightTexture(bdTex)
    local hl = chk:GetHighlightTexture()
    hl:SetAllPoints(bg)
    hl:SetVertexColor(cr, cg, cb, 0.25)
    
    local check = chk:CreateTexture(nil, "OVERLAY")
    check:SetSize(20, 20)
    check:SetPoint("CENTER")
    check:SetAtlas("questlog-icon-checkmark-yellow-2x")
    check:SetVertexColor(1, 0.8, 0)
    chk:SetCheckedTexture(check)
    
    chk.label = CreateFS(chk, 13, label, nil, "LEFT", 24, 0)
    chk:SetHitRectInsets(0, -chk.label:GetStringWidth()-10, 0, 0)
    
    local function GetCVarBool(name)
        local val = GetCVar(name)
        return val and (val == "1" or val == 1)
    end
    
    -- Store the cvar name for syncing
    chk.cvar = cvar
    chk.GetCVarBool = GetCVarBool
    
    chk:SetChecked(GetCVarBool(cvar))
    chk:SetScript("OnClick", function(self)
        local newVal = self:GetChecked() and "1" or "0"
        SetCVar(cvar, newVal)
        if callback then callback(self) end
    end)
    chk:SetScript("OnShow", function(self)
        self:SetChecked(GetCVarBool(cvar))
    end)
    
    -- Register this checkbox for CVar sync
    if not ns.cvarCheckboxes then ns.cvarCheckboxes = {} end
    ns.cvarCheckboxes[cvar] = chk
    
    return chk
end

-- Shared slider counter
local sliderCount = 0

-- Direct nameplate resize function (bypasses slow attribute chain)
-- Called from CVar sliders when user changes clickable area size
local function ApplyNameplateSizes(width, height)
    -- Update CVars
    C_CVar.Set("nameplateWidth", width)
    C_CVar.Set("nameplateHeight", height)
    -- Update namespace cache (used by Core.lua and other modules)
    ns.clickableWidth = width
    ns.clickableHeight = height
    -- Directly resize all active nameplates (skip attribute-based resizing)
    if C_NamePlateManager.EnumerateActiveNamePlates then
        for np in C_NamePlateManager.EnumerateActiveNamePlates() do
            if np then
                np:SetSize(width, height)
                -- Also resize UnitFrame if it exists (some addons attach to this)
                if np.UnitFrame then
                    np.UnitFrame:SetSize(width, height)
                end
            end
        end
    end
    -- Refresh stacking config so collision zones adapt to new clickbox
    if ns.RefreshStackingConfig then
        ns.RefreshStackingConfig()
    end
end

-- CVar Slider (for nameplateWidth/nameplateHeight - stores in CVars, not TurboPlatesDB)
local function CreateCVarSlider(parent, cvar, label, minVal, maxVal, x, y, callback, suffix)
    sliderCount = sliderCount + 1
    suffix = suffix or ""  -- Optional suffix (e.g., "px")
    
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(220, 50)
    frame:SetPoint("TOPLEFT", x, y)
    
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(GUI_FONT, 12, "")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)
    title:SetTextColor(1, 0.8, 0)
    
    local sliderBg = CreateFrame("Frame", nil, frame)
    sliderBg:SetSize(220, 8)
    sliderBg:SetPoint("TOPLEFT", 0, -18)
    
    -- Background texture
    local sliderBgTex = sliderBg:CreateTexture(nil, "BACKGROUND")
    sliderBgTex:SetAllPoints()
    sliderBgTex:SetTexture(0.1, 0.1, 0.1, 1)
    
    -- Pixel-perfect border
    sliderBg.border = CreateTextureBorder(sliderBg, 1)
    sliderBg.border:SetColor(0.3, 0.3, 0.3, 1)
    
    local slider = CreateFrame("Slider", "TurboPlatesSlider"..sliderCount, sliderBg)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(220, 16)
    slider:SetPoint("CENTER", sliderBg, "CENTER", 0, 0)
    slider:SetThumbTexture(bdTex)
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(12, 12)
    thumb:SetVertexColor(cr, cg, cb)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    
    local low = frame:CreateFontString(nil, "OVERLAY")
    low:SetFont(GUI_FONT, 10, "")
    low:SetPoint("TOPLEFT", sliderBg, "BOTTOMLEFT", 0, -2)
    low:SetText(minVal .. suffix)
    low:SetTextColor(0.6, 0.6, 0.6)
    
    local high = frame:CreateFontString(nil, "OVERLAY")
    high:SetFont(GUI_FONT, 10, "")
    high:SetPoint("TOPRIGHT", sliderBg, "BOTTOMRIGHT", 0, -2)
    high:SetText(maxVal .. suffix)
    high:SetTextColor(0.6, 0.6, 0.6)
    
    local valueText = frame:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(GUI_FONT, 12, "")
    valueText:SetPoint("TOP", sliderBg, "BOTTOM", 0, -2)
    
    -- Use namespace cache (initialized at PLAYER_LOGIN in Core.lua)
    local val = (cvar == "nameplateWidth") and ns.clickableWidth or ns.clickableHeight
    slider:SetValue(val)
    valueText:SetText(tostring(floor(val)) .. suffix)
    
    slider:SetScript("OnValueChanged", function(self, v)
        v = floor(v + 0.5)
        valueText:SetText(tostring(v) .. suffix)
        -- Use namespace cache for the "other" dimension (no CVar lookup)
        local width, height
        if cvar == "nameplateWidth" then
            width = v
            height = ns.clickableHeight
        else
            width = ns.clickableWidth
            height = v
        end
        -- Direct resize (fast path, no attribute overhead)
        ApplyNameplateSizes(width, height)
        if ns.UpdatePreview then ns.UpdatePreview() end
        if callback then callback(self, v) end
    end)
    
    slider:SetScript("OnMouseWheel", function(self, delta)
        local newVal = self:GetValue() + delta
        newVal = max(minVal, min(maxVal, newVal))
        self:SetValue(newVal)
    end)
    
    slider:SetScript("OnShow", function(self)
        -- Sync from namespace cache when panel opens
        local v = (cvar == "nameplateWidth") and ns.clickableWidth or ns.clickableHeight
        self:SetValue(v)
        valueText:SetText(tostring(floor(v)) .. suffix)
    end)
    
    frame.slider = slider
    return frame
end

-- Alpha CVar slider (stores in DB and applies CVar)
local function CreateAlphaCVarSlider(parent, dbVar, cvar, label, x, y, tooltipText)
    sliderCount = sliderCount + 1
    
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(220, 50)
    frame:SetPoint("TOPLEFT", x, y)
    
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(GUI_FONT, 12, "")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)
    title:SetTextColor(1, 0.8, 0)
    
    local sliderBg = CreateFrame("Frame", nil, frame)
    sliderBg:SetSize(220, 8)
    sliderBg:SetPoint("TOPLEFT", 0, -18)
    
    local sliderBgTex = sliderBg:CreateTexture(nil, "BACKGROUND")
    sliderBgTex:SetAllPoints()
    sliderBgTex:SetTexture(0.1, 0.1, 0.1, 1)
    
    sliderBg.border = CreateTextureBorder(sliderBg, 1)
    sliderBg.border:SetColor(0.3, 0.3, 0.3, 1)
    
    local slider = CreateFrame("Slider", "TurboPlatesSlider"..sliderCount, sliderBg)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(220, 16)
    slider:SetPoint("CENTER", sliderBg, "CENTER", 0, 0)
    slider:SetThumbTexture(bdTex)
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(12, 12)
    thumb:SetVertexColor(cr, cg, cb)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(0.1)
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    
    local low = frame:CreateFontString(nil, "OVERLAY")
    low:SetFont(GUI_FONT, 10, "")
    low:SetPoint("TOPLEFT", sliderBg, "BOTTOMLEFT", 0, -2)
    low:SetText("0%")
    low:SetTextColor(0.6, 0.6, 0.6)
    
    local high = frame:CreateFontString(nil, "OVERLAY")
    high:SetFont(GUI_FONT, 10, "")
    high:SetPoint("TOPRIGHT", sliderBg, "BOTTOMRIGHT", 0, -2)
    high:SetText("100%")
    high:SetTextColor(0.6, 0.6, 0.6)
    
    local valueText = frame:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(GUI_FONT, 12, "")
    valueText:SetPoint("TOP", sliderBg, "BOTTOM", 0, -2)
    
    local function FormatValue(v)
        return tostring(floor(v * 100 + 0.5)) .. "%"
    end
    
    local val = TurboPlatesDB[dbVar]
    if val == nil then val = ns.defaults[dbVar] or 0.6 end
    slider:SetValue(val)
    valueText:SetText(FormatValue(val))
    
    slider:SetScript("OnValueChanged", function(self, v)
        v = floor(v * 10 + 0.5) / 10  -- Round to 0.1 steps
        TurboPlatesDB[dbVar] = v
        valueText:SetText(FormatValue(v))
        -- Update cache and refresh all nameplate alphas
        if ns.UpdateDBCache then ns:UpdateDBCache() end
        if ns.UpdateNameplateAlphas then ns.UpdateNameplateAlphas() end
    end)
    
    slider:SetScript("OnMouseWheel", function(self, delta)
        local newVal = self:GetValue() + (delta * 0.1)
        newVal = max(0, min(1, newVal))
        self:SetValue(newVal)
    end)
    
    slider:SetScript("OnShow", function(self)
        local v = TurboPlatesDB[dbVar]
        if v == nil then v = ns.defaults[dbVar] or 0.6 end
        self:SetValue(v)
        valueText:SetText(FormatValue(v))
    end)
    
    if tooltipText then
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.8, 0)
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    frame.slider = slider
    return frame
end

-- Dark themed slider
local function CreateSlider(parent, var, label, minVal, maxVal, x, y, isFloat, callback, suffix, displayMultiplier)
    sliderCount = sliderCount + 1
    suffix = suffix or ""  -- Optional suffix (e.g., "%")
    displayMultiplier = displayMultiplier or 1  -- Optional multiplier for display (e.g., 100 to show 0.5 as 50)
    
    -- Container frame - total height ~50px
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(220, 50)
    frame:SetPoint("TOPLEFT", x, y)
    
    -- Label above
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(GUI_FONT, 12, "")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)
    title:SetTextColor(1, 0.8, 0)
    
    -- Slider background (texture-based border for pixel-perfect rendering)
    local sliderBg = CreateFrame("Frame", nil, frame)
    sliderBg:SetSize(220, 8)
    sliderBg:SetPoint("TOPLEFT", 0, -18)
    
    -- Background texture
    local sliderBgTex = sliderBg:CreateTexture(nil, "BACKGROUND")
    sliderBgTex:SetAllPoints()
    sliderBgTex:SetTexture(bdTex)
    sliderBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
    
    -- Pixel-perfect border
    sliderBg.__border = CreateTextureBorder(sliderBg, 1)
    sliderBg.__border:SetColor(0.3, 0.3, 0.3, 1)
    
    -- Slider bar
    local slider = CreateFrame("Slider", "TurboPlatesSlider"..sliderCount, sliderBg)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(220, 16)
    slider:SetPoint("CENTER", sliderBg, "CENTER", 0, 0)
    slider:SetThumbTexture(bdTex)
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(12, 12)
    thumb:SetVertexColor(cr, cg, cb)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(isFloat and 0.1 or 1)
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    
    -- Low/High labels (with display multiplier)
    local low = frame:CreateFontString(nil, "OVERLAY")
    low:SetFont(GUI_FONT, 10, "")
    low:SetPoint("TOPLEFT", sliderBg, "BOTTOMLEFT", 0, -2)
    low:SetText(tostring(math.floor(minVal * displayMultiplier + 0.5)) .. suffix)
    low:SetTextColor(0.6, 0.6, 0.6)
    
    local high = frame:CreateFontString(nil, "OVERLAY")
    high:SetFont(GUI_FONT, 10, "")
    high:SetPoint("TOPRIGHT", sliderBg, "BOTTOMRIGHT", 0, -2)
    high:SetText(tostring(math.floor(maxVal * displayMultiplier + 0.5)) .. suffix)
    high:SetTextColor(0.6, 0.6, 0.6)
    
    -- Value in center
    local valueText = frame:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(GUI_FONT, 12, "")
    valueText:SetPoint("TOP", sliderBg, "BOTTOM", 0, -2)
    
    -- Helper to format value with suffix and display multiplier
    local function FormatValue(v)
        local displayVal = v * displayMultiplier
        if displayMultiplier ~= 1 then
            -- When using multiplier, show as integer
            return tostring(math.floor(displayVal + 0.5)) .. suffix
        else
            return (isFloat and string.format("%.1f", displayVal) or tostring(displayVal)) .. suffix
        end
    end
    
    -- Initialize
    local val = TurboPlatesDB[var]
    if val == nil then val = ns.defaults[var] or minVal end
    slider:SetValue(val)
    valueText:SetText(FormatValue(val))
    
    slider:SetScript("OnValueChanged", function(self, v)
        if isFloat then v = math.floor(v * 10 + 0.5) / 10 else v = math.floor(v + 0.5) end
        TurboPlatesDB[var] = v
        valueText:SetText(FormatValue(v))
        UpdateAllThrottled()
        if callback then callback(self, v) end
    end)
    
    slider:SetScript("OnMouseWheel", function(self, delta)
        local step = isFloat and 0.1 or 1
        local newVal = self:GetValue() + (delta * step)
        newVal = math.max(minVal, math.min(maxVal, newVal))
        self:SetValue(newVal)
    end)
    
    slider:SetScript("OnShow", function(self)
        local v = TurboPlatesDB[var]
        if v == nil then v = ns.defaults[var] or minVal end
        self:SetValue(v)
        valueText:SetText(FormatValue(v))
    end)
    
    frame.slider = slider
    return frame
end

-- Color Swatch
local function CreateColorSwatch(parent, var, label, x, y, callback)
    local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatch:SetSize(18, 18)
    swatch:SetPoint("TOPLEFT", x, y)
    CreateBD(swatch, 1)
    
    local tex = swatch:CreateTexture(nil, "OVERLAY")
    tex:SetPoint("TOPLEFT", 0, 0)
    tex:SetPoint("BOTTOMRIGHT", 0, 0)
    tex:SetTexture(bdTex)
    swatch.tex = tex
    
    if label then
        swatch.label = CreateFS(swatch, 12, label, nil, "LEFT", 24, 0)
    end
    
    local function RefreshColor()
        local c = TurboPlatesDB[var]
        if not c or not c.r then c = ns.defaults[var] or {r=1,g=1,b=1} end
        tex:SetVertexColor(c.r, c.g, c.b)
    end
    
    swatch:SetScript("OnClick", function()
        local c = TurboPlatesDB[var]
        if not c or not c.r then c = ns.defaults[var] or {r=1,g=1,b=1} end
        local prevR, prevG, prevB = c.r, c.g, c.b
        
        ColorPickerFrame.func = nil
        ColorPickerFrame.cancelFunc = nil
        ColorPickerFrame:Hide()
        ColorPickerFrame:SetColorRGB(prevR, prevG, prevB)
        ColorPickerFrame.previousValues = {r = prevR, g = prevG, b = prevB}
        
        local currentVar = var
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            TurboPlatesDB[currentVar] = {r = r, g = g, b = b}
            tex:SetVertexColor(r, g, b)
            UpdateAll()
            if callback then callback() end
        end
        ColorPickerFrame.cancelFunc = function()
            TurboPlatesDB[currentVar] = {r = prevR, g = prevG, b = prevB}
            tex:SetVertexColor(prevR, prevG, prevB)
            UpdateAll()
            if callback then callback() end
        end
        ColorPickerFrame:Show()
    end)
    swatch:SetScript("OnShow", RefreshColor)
    RefreshColor()
    return swatch
end

-- Scrollable dropdown for long lists (textures/fonts)
local scrollDropdownCount = 0
local function CreateScrollableDropdown(parent, var, label, options, x, y, callback, maxHeight)
    scrollDropdownCount = scrollDropdownCount + 1
    maxHeight = maxHeight or 200
    
    -- Container
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(220, 50)
    frame:SetPoint("TOPLEFT", x, y)
    
    -- Label above
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(GUI_FONT, 12, "")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)
    title:SetTextColor(1, 0.8, 0)
    
    -- Main button (dark background)
    local btn = CreateFrame("Button", "TurboPlatesScrollDD"..scrollDropdownCount, frame, "BackdropTemplate")
    btn:SetSize(220, 22)
    btn:SetPoint("TOPLEFT", 0, -18)
    CreateBD(btn, 0.6)
    btn.__border:SetColor(1, 1, 1, 0.2)
    
    -- Selected text
    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(GUI_FONT, 12, "")
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -22, 0)
    text:SetJustifyH("LEFT")
    btn.text = text
    
    -- Arrow
    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetTexture(mediaPath.."arrow.tga")
    arrow:SetRotation(math.rad(180))
    btn.arrow = arrow
    
    -- Dropdown list container (fixed height with scroll)
    local listName = "TurboPlatesScrollDDList"..scrollDropdownCount
    local list = CreateFrame("Frame", listName, UIParent, "BackdropTemplate")
    list:SetFrameStrata("TOOLTIP")
    list:SetFrameLevel(200)
    list:SetClampedToScreen(true)
    
    local numOpts = #options
    local itemHeight = 20
    local totalHeight = numOpts * itemHeight + 6
    local listHeight = min(totalHeight, maxHeight)
    list:SetSize(220, listHeight)
    
    -- Solid dark background
    local listBgTex = list:CreateTexture(nil, "BACKGROUND")
    listBgTex:SetAllPoints()
    listBgTex:SetTexture(bdTex)
    listBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
    
    -- Border
    list.__border = CreateTextureBorder(list, 1)
    list.__border:SetColor(0.3, 0.3, 0.3, 1)
    list:Hide()
    btn.list = list
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, list)
    scrollFrame:SetPoint("TOPLEFT", 3, -3)
    scrollFrame:SetPoint("BOTTOMRIGHT", -3, 3)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(214, totalHeight - 6)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Custom scrollbar (only when needed)
    local needsScroll = totalHeight > maxHeight
    local scrollBar, scrollThumb
    
    if needsScroll then
        scrollFrame:SetPoint("BOTTOMRIGHT", -12, 3)
        scrollChild:SetWidth(202)
        
        scrollBar = CreateFrame("Frame", nil, list)
        scrollBar:SetSize(8, listHeight - 8)
        scrollBar:SetPoint("TOPRIGHT", -2, -4)
        
        scrollThumb = CreateFrame("Button", nil, scrollBar)
        local thumbHeight = max(20, (maxHeight / totalHeight) * (listHeight - 8))
        scrollThumb:SetSize(8, thumbHeight)
        scrollThumb:SetPoint("TOP", 0, 0)
        local thumbTex = scrollThumb:CreateTexture(nil, "OVERLAY")
        thumbTex:SetAllPoints()
        thumbTex:SetTexture(bdTex)
        thumbTex:SetVertexColor(cr, cg, cb, 0.6)
        scrollThumb.tex = thumbTex
        
        scrollThumb:SetScript("OnEnter", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.9) end)
        scrollThumb:SetScript("OnLeave", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.6) end)
        
        -- Drag scrollbar
        local function ScrollThumbOnUpdate(self)
            local _, cursorY = GetCursorPosition()
            local scale = scrollBar:GetEffectiveScale()
            cursorY = cursorY / scale
            local barTop = scrollBar:GetTop()
            local barHeight = scrollBar:GetHeight() - self:GetHeight()
            local offset = barTop - cursorY - self:GetHeight() / 2
            offset = max(0, min(barHeight, offset))
            local scrollMax = scrollFrame:GetVerticalScrollRange()
            scrollFrame:SetVerticalScroll(scrollMax * (offset / barHeight))
        end
        scrollThumb:SetScript("OnMouseDown", function(self) self:SetScript("OnUpdate", ScrollThumbOnUpdate) end)
        scrollThumb:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
        
        -- Update thumb position on scroll
        local function UpdateScrollBar()
            local scrollMax = scrollFrame:GetVerticalScrollRange()
            if scrollMax > 0 then
                local scrollCurrent = scrollFrame:GetVerticalScroll()
                local barHeight = scrollBar:GetHeight() - scrollThumb:GetHeight()
                local thumbOffset = (scrollCurrent / scrollMax) * barHeight
                scrollThumb:SetPoint("TOP", 0, -thumbOffset)
            end
        end
        scrollFrame:SetScript("OnVerticalScroll", UpdateScrollBar)
    end
    
    -- Mouse wheel
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        local newScroll = current - (delta * 40)
        newScroll = max(0, min(maxScroll, newScroll))
        scrollFrame:SetVerticalScroll(newScroll)
    end)
    
    -- Create option buttons
    for i, opt in ipairs(options) do
        local optBtn = CreateFrame("Button", nil, scrollChild)
        optBtn:SetSize(scrollChild:GetWidth() - 2, 18)
        optBtn:SetPoint("TOPLEFT", 1, -(i - 1) * itemHeight)
        
        local optText = optBtn:CreateFontString(nil, "OVERLAY")
        optText:SetFont(GUI_FONT, 12, "")
        optText:SetPoint("LEFT", 6, 0)
        optText:SetPoint("RIGHT", -4, 0)
        optText:SetJustifyH("LEFT")
        optText:SetText(opt.name)
        optBtn.text = optText
        optBtn.value = opt.path or opt.value
        optBtn.name = opt.name
        
        local optBg = optBtn:CreateTexture(nil, "BACKGROUND")
        optBg:SetAllPoints()
        optBg:SetTexture(bdTex)
        optBg:SetVertexColor(1, 1, 1, 0)
        optBtn.bg = optBg
        
        optBtn:SetScript("OnEnter", function(self) self.bg:SetVertexColor(cr, cg, cb, 0.3) end)
        optBtn:SetScript("OnLeave", function(self) self.bg:SetVertexColor(1, 1, 1, 0) end)
        optBtn:SetScript("OnClick", function(self)
            TurboPlatesDB[var] = self.value
            text:SetText(self.name)
            list:Hide()
            arrow:SetRotation(math.rad(180))
            UpdateAll()
            if callback then callback(self.value) end
        end)
    end
    
    -- Toggle list
    btn:SetScript("OnClick", function(self)
        if list:IsShown() then
            list:Hide()
            arrow:SetRotation(math.rad(180))
        else
            list:ClearAllPoints()
            list:SetPoint("TOP", self, "BOTTOM", 0, -2)
            list:Show()
            arrow:SetRotation(math.rad(0))
            scrollFrame:SetVerticalScroll(0)
            if scrollThumb then scrollThumb:SetPoint("TOP", 0, 0) end
        end
    end)
    
    btn:SetScript("OnHide", function() list:Hide() end)
    btn:SetScript("OnEnter", function(self) self.__border:SetColor(cr, cg, cb, 0.5) end)
    btn:SetScript("OnLeave", function(self) self.__border:SetColor(1, 1, 1, 0.2) end)
    
    -- Initialize value
    local function Refresh()
        local current = TurboPlatesDB[var]
        if current == nil then current = ns.defaults[var] end
        for _, opt in ipairs(options) do
            if (opt.path or opt.value) == current then
                text:SetText(opt.name)
                return
            end
        end
        if options[1] then text:SetText(options[1].name) end
    end
    
    btn:SetScript("OnShow", function() Refresh(); list:Hide() end)
    Refresh()
    
    frame.btn = btn
    return frame
end

-- Dark themed dropdown
local dropdownCount = 0
local function CreateDropdown(parent, var, label, options, x, y, callback)
    dropdownCount = dropdownCount + 1
    
    -- Container - total height ~50px
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(220, 50)
    frame:SetPoint("TOPLEFT", x, y)
    
    -- Label above
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(GUI_FONT, 12, "")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)
    title:SetTextColor(1, 0.8, 0)
    
    -- Main button (dark background)
    local btn = CreateFrame("Button", "TurboPlatesDD"..dropdownCount, frame, "BackdropTemplate")
    btn:SetSize(220, 22)
    btn:SetPoint("TOPLEFT", 0, -18)
    CreateBD(btn, 0.6)
    btn.__border:SetColor(1, 1, 1, 0.2)
    
    -- Selected text
    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(GUI_FONT, 12, "")
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -22, 0)
    text:SetJustifyH("LEFT")
    btn.text = text
    
    -- Arrow (downward chevron)
    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetTexture(mediaPath.."arrow.tga")
    arrow:SetRotation(math.rad(180))  -- Rotate to point down
    btn.arrow = arrow
    
    -- Dropdown list (parented to UIParent for proper z-ordering)
    local listName = "TurboPlatesDDList"..dropdownCount
    local list = CreateFrame("Frame", listName, UIParent)
    list:SetFrameStrata("TOOLTIP")
    list:SetFrameLevel(200)
    list:SetClampedToScreen(true)
    
    -- Solid dark background (texture-based)
    local listBgTex = list:CreateTexture(nil, "BACKGROUND")
    listBgTex:SetAllPoints()
    listBgTex:SetTexture(bdTex)
    listBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
    
    -- Pixel-perfect border
    list.__border = CreateTextureBorder(list, 1)
    list.__border:SetColor(0.3, 0.3, 0.3, 1)
    list:Hide()
    btn.list = list
    
    -- Create option buttons
    local numOpts = #options
    list:SetSize(220, numOpts * 20 + 6)
    
    for i, opt in ipairs(options) do
        local optBtn = CreateFrame("Button", nil, list)
        optBtn:SetSize(214, 18)
        optBtn:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 20)
        
        local optText = optBtn:CreateFontString(nil, "OVERLAY")
        optText:SetFont(GUI_FONT, 12, "")
        optText:SetPoint("LEFT", 6, 0)
        optText:SetText(opt.name)
        optBtn.text = optText
        optBtn.value = opt.path or opt.value
        optBtn.name = opt.name
        
        local optBg = optBtn:CreateTexture(nil, "BACKGROUND")
        optBg:SetAllPoints()
        optBg:SetTexture(bdTex)
        optBg:SetVertexColor(1, 1, 1, 0)
        optBtn.bg = optBg
        
        optBtn:SetScript("OnEnter", function(self)
            self.bg:SetVertexColor(cr, cg, cb, 0.3)
        end)
        optBtn:SetScript("OnLeave", function(self)
            self.bg:SetVertexColor(1, 1, 1, 0)
        end)
        optBtn:SetScript("OnClick", function(self)
            TurboPlatesDB[var] = self.value
            text:SetText(self.name)
            list:Hide()
            arrow:SetRotation(math.rad(180))  -- Point down when closed
            UpdateAll()
            if callback then callback(self.value) end
        end)
    end
    
    -- Toggle list - position it below the button
    btn:SetScript("OnClick", function(self)
        if list:IsShown() then
            list:Hide()
            arrow:SetRotation(math.rad(180))  -- Point down when closed
        else
            -- Position list below button
            list:ClearAllPoints()
            local x, y = self:GetCenter()
            local bw = self:GetWidth()
            local bh = self:GetHeight()
            list:SetPoint("TOP", self, "BOTTOM", 0, -2)
            list:Show()
            arrow:SetRotation(math.rad(0))  -- Point up when opened
        end
    end)
    
    -- Hide list when button is hidden
    btn:SetScript("OnHide", function() list:Hide() end)
    
    btn:SetScript("OnEnter", function(self) self.__border:SetColor(cr, cg, cb, 0.5) end)
    btn:SetScript("OnLeave", function(self) self.__border:SetColor(1, 1, 1, 0.2) end)
    
    -- Initialize value
    local function Refresh()
        local current = TurboPlatesDB[var]
        if current == nil then current = ns.defaults[var] end
        for _, opt in ipairs(options) do
            if (opt.path or opt.value) == current then
                text:SetText(opt.name)
                return
            end
        end
        -- Default to first option if not found
        if options[1] then text:SetText(options[1].name) end
    end
    
    btn:SetScript("OnShow", function() Refresh(); list:Hide() end)
    Refresh()
    
    frame.btn = btn
    return frame
end

-- Tab system
local tabNames = {L.TabGeneral, L.TabStyle, L.TabFonts, L.TabColors, L.TabCastbar, L.TabDebuffs, L.TabBuffs, L.TabPersonal, L.TabCP, L.TabObjectives, L.TabStacking, L.TabTurboDebuffs, L.TabMisc, L.TabProfiles or "Profiles"}

local function SelectTab(index)
    for i, tab in pairs(guiTab) do
        if i == index then
            tab.__bg:SetTexture(cr, cg, cb, 0.3)
            tab.checked = true
            guiPage[i]:Show()
        else
            tab.__bg:SetTexture(0, 0, 0, 0.3)
            tab.checked = false
            guiPage[i]:Hide()
        end
    end
end

local function CreateTab(parent, index, name)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetPoint("TOPLEFT", 15, -28.75 * (index - 1) - 50)
    tab:SetSize(120, 26)
    CreateBD(tab, 0.3)
    CreateFS(tab, 12, name, "system", "LEFT", 10, 0)
    tab.index = index
    
    tab:SetScript("OnClick", function(self) 
        PlaySound(856) -- SOUNDKIT.GS_TITLE_OPTION_OK
        SelectTab(self.index)
    end)
    tab:SetScript("OnEnter", function(self)
        if self.checked then return end
        self.__bg:SetTexture(cr, cg, cb, 0.15)
    end)
    tab:SetScript("OnLeave", function(self)
        if self.checked then return end
        self.__bg:SetTexture(0, 0, 0, 0.3)
    end)
    return tab
end

-- Preview frame (positioned ABOVE the panel, outside)
local previewFrame = nil
local function CreatePreview(parent)
    local p = CreateFrame("Frame", "TurboPlatesPreview", UIParent, "BackdropTemplate")
    p:SetSize(320, 100)
    p:SetPoint("BOTTOM", parent, "TOP", 0, 20)
    p:SetFrameStrata("HIGH")
    p:SetFrameLevel(100)
    CreateBD(p, 0.8)
    CreateSD(p)
    p:Hide()  -- Start hidden, toggle checkbox controls visibility
    previewFrame = p
    
    -- Get default sizes from ns.defaults
    local d = ns.defaults or {width = 110, hpHeight = 12, castHeight = 12}
    local defWidth = d.width or 110
    local defHpHeight = d.hpHeight or 12
    local defCastHeight = d.castHeight or 12
    
    local plate = CreateFrame("Frame", nil, p)
    plate:SetSize(defWidth + 40, defHpHeight + defCastHeight + 30)
    plate:SetPoint("CENTER", 0, -20)
    
    -- Health bar with initial size
    local hp = CreateFrame("StatusBar", nil, plate)
    hp:SetSize(defWidth, defHpHeight)
    hp:SetPoint("CENTER", plate, "CENTER", 0, 5)  -- Centered in plate, offset up slightly for castbar room
    hp:SetStatusBarTexture(bdTex)
    hp:SetStatusBarColor(0.8, 0.2, 0.2)
    hp:SetMinMaxValues(0, 100)
    hp:SetValue(75)
    
    local hpBg = hp:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints()
    hpBg:SetTexture(bdTex)
    hpBg:SetVertexColor(0, 0, 0, 0.8)
    hp.bg = hpBg  -- Store reference for background alpha updates
    
    -- Pixel-perfect texture border
    hp.border = CreateTextureBorder(hp, 1)
    
    -- Target glow frame (border style - matches Nameplates.lua targetGlow)
    local targetGlow = CreateFrame("Frame", nil, hp, "BackdropTemplate")
    targetGlow:SetPoint("TOPLEFT", hp, "TOPLEFT", -5, 5)
    targetGlow:SetPoint("BOTTOMRIGHT", hp, "BOTTOMRIGHT", 5, -5)
    targetGlow:SetBackdrop({ edgeFile = "Interface\\AddOns\\TurboPlates\\Textures\\GlowTex.tga", edgeSize = 5 })
    targetGlow:SetBackdropBorderColor(1, 1, 1, 0.9)
    targetGlow:SetFrameLevel(hp:GetFrameLevel() - 1)
    targetGlow:EnableMouse(false)
    targetGlow:Hide()
    plate.targetGlow = targetGlow
    
    -- Target arrows (left and right)
    local targetArrows = {}
    targetArrows.left = hp:CreateTexture(nil, "OVERLAY")
    targetArrows.left:SetTexCoord(1, 0, 0, 1)  -- Flip horizontally for left arrow
    targetArrows.left:Hide()
    targetArrows.right = hp:CreateTexture(nil, "OVERLAY")
    targetArrows.right:Hide()
    plate.targetArrows = targetArrows
    
    -- Castbar with initial size
    local cb = CreateFrame("StatusBar", nil, plate)
    cb:SetSize(defWidth - defCastHeight - 2, defCastHeight)
    cb:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -2)
    cb:SetStatusBarTexture(bdTex)
    cb:SetStatusBarColor(0.3, 0.6, 1)
    cb:SetMinMaxValues(0, 100)
    cb:SetValue(50)
    
    local cbBg = cb:CreateTexture(nil, "BACKGROUND")
    cbBg:SetAllPoints()
    cbBg:SetTexture(bdTex)
    cbBg:SetVertexColor(0, 0, 0, 0.8)
    
    -- Pixel-perfect texture border for castbar preview
    cb.border = CreateTextureBorder(cb, 1)
    
    -- Castbar spark (for preview)
    local cbSpark = cb:CreateTexture(nil, "OVERLAY")
    cbSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    cbSpark:SetBlendMode("ADD")
    cbSpark:SetSize(16, defCastHeight * 2)
    cbSpark:SetVertexColor(1, 1, 0.8)
    cbSpark:Hide()
    
    -- Name text
    local nameText = hp:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(GUI_FONT, 10, "OUTLINE")
    nameText:SetPoint("BOTTOM", hp, "TOP", 0, 3)
    nameText:SetText("Dummy")
    
    -- Level text (shown right of name when enabled)
    local levelText = hp:CreateFontString(nil, "OVERLAY")
    levelText:SetFont(GUI_FONT, 10, "OUTLINE")
    levelText:SetPoint("LEFT", nameText, "RIGHT", 2, 0)
    levelText:SetText("60")
    levelText:SetTextColor(1, 1, 0)  -- Yellow (same level as player)
    levelText:Hide()
    
    -- Castbar text
    local cbTime = cb:CreateFontString(nil, "OVERLAY")
    cbTime:SetFont(GUI_FONT, 8, "OUTLINE")
    cbTime:SetPoint("RIGHT", cb, -4, 0)
    cbTime:SetText("1.5")
    
    local cbName = cb:CreateFontString(nil, "OVERLAY")
    cbName:SetFont(GUI_FONT, 8, "OUTLINE")
    cbName:SetPoint("LEFT", cb, 4, 0)
    cbName:SetText("Casting...")
    
    -- Castbar icon
    local cbIcon = plate:CreateTexture(nil, "OVERLAY")
    cbIcon:SetSize(defCastHeight, defCastHeight)
    cbIcon:SetPoint("RIGHT", cb, "LEFT", -2, 0)
    cbIcon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
    cbIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    local cbIconBorder = CreateFrame("Frame", nil, plate)
    cbIconBorder:SetAllPoints(cbIcon)
    cbIconBorder.border = CreateTextureBorder(cbIconBorder, 1)
    
    -- Raid icon
    local raidIcon = plate:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(16, 16)
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    SetRaidTargetIconTexture(raidIcon, 8)
    raidIcon:SetPoint("RIGHT", hp, "LEFT", -4, 0)
    
    -- Clickbox debug visualization (shows nameplate clickable area)
    local clickboxDebug = plate:CreateTexture(nil, "BACKGROUND", nil, -8)
    clickboxDebug:SetTexture("Interface\\Buttons\\WHITE8X8")
    clickboxDebug:SetVertexColor(1, 1, 1, 0.3)
    clickboxDebug:SetPoint("CENTER", plate, "CENTER", 0, 0)
    clickboxDebug:Hide()  -- Hidden by default, shown when CVar is set
    
    -- Execute range indicator (vertical line on healthbar)
    local execIndicator = hp:CreateTexture(nil, "OVERLAY")
    execIndicator:SetTexture(bdTex)
    execIndicator:SetVertexColor(1, 1, 1, 0.8)
    execIndicator:SetWidth(2)
    execIndicator:Hide()
    
    -- Health value text (centered on health bar)
    local healthText = hp:CreateFontString(nil, "OVERLAY")
    healthText:SetFont(GUI_FONT, 10, "OUTLINE")
    healthText:SetPoint("CENTER", hp, "CENTER", 0, 0)
    healthText:SetText("75 - 100 (75%)")
    healthText:SetTextColor(1, 1, 1)
    healthText:Hide()  -- Hidden by default
    
    -- Combo points (only shown for Druid, Rogue, HERO)
    local cpColors = {
        [1] = {r = 1.0, g = 0.0, b = 0.0},
        [2] = {r = 1.0, g = 0.5, b = 0.0},
        [3] = {r = 1.0, g = 1.0, b = 0.0},
        [4] = {r = 0.5, g = 1.0, b = 0.0},
        [5] = {r = 0.0, g = 1.0, b = 0.0},
    }
    local MAX_CP = 5
    local cpBars = {}
    local cpContainer = CreateFrame("Frame", nil, plate)
    cpContainer:SetSize(100, 4)
    cpContainer:SetPoint("BOTTOM", hp, "TOP", 0, -1)
    
    for i = 1, MAX_CP do
        -- Simple texture for each combo point (no borders)
        local bar = cpContainer:CreateTexture(nil, "ARTWORK")
        bar:SetTexture(bdTex)
        
        local color = cpColors[i]
        bar:SetVertexColor(color.r, color.g, color.b)
        
        cpBars[i] = bar
    end
    
    -- Check if player should see combo points
    local function ShouldShowComboPoints()
        local _, playerClass = UnitClass("player")
        return playerClass == "DRUID" or playerClass == "ROGUE" or playerClass == "HERO"
    end
    
    -- =============================================================================
    -- AURA PREVIEW (Debuffs/Buffs)
    -- =============================================================================
    local PREVIEW_BORDER_SIZE = 1  -- Must match BORDER_SIZE in Auras.lua
    
    -- Border colors for debuffs (also used for buff dispellable logic)
    local DEBUFF_BORDER_COLORS = {
        Magic   = { 0.20, 0.60, 1.00 },  -- Blue (also dispellable buffs)
        Curse   = { 0.60, 0.00, 1.00 },
        Disease = { 0.60, 0.40, 0.00 },
        Poison  = { 0.00, 0.60, 0.00 },
        none    = { 0.80, 0.00, 0.00 },  -- Red (also non-dispellable buffs)
    }
    
    -- Sample debuffs for preview (icon, debuffType, duration, stacks)
    local sampleDebuffs = {
        { icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", debuffType = "Magic", duration = "12", stacks = 0 },
        { icon = "Interface\\Icons\\Spell_Fire_Immolation", debuffType = "none", duration = "8", stacks = 0 },
        { icon = "Interface\\Icons\\Ability_Rogue_Rupture", debuffType = "none", duration = "4", stacks = 5 },
    }
    
    -- Sample buffs for preview (purgeable shows dispellable color)
    local sampleBuffs = {
        { icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", purgeable = true, duration = "15", stacks = 0 },
        { icon = "Interface\\Icons\\Spell_Nature_Regeneration", purgeable = false, duration = "30", stacks = 0 },
    }
    
    -- Helper to create a preview aura icon (matches Auras.lua CreateAuraIcon)
    local function CreatePreviewAuraIcon(parent)
        local icon = CreateFrame("Frame", nil, parent)
        icon:SetSize(20, 20)
        
        -- Icon texture fills frame (border extends outside via CreateTextureBorder)
        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints()
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- 30% zoom
        
        -- Square border using texture (extends outside the frame)
        icon.border = CreateTextureBorder(icon, PREVIEW_BORDER_SIZE)
        
        icon.duration = icon:CreateFontString(nil, "OVERLAY")
        icon.duration:SetFont(GUI_FONT, 10, "OUTLINE")
        icon.duration:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
        icon.duration:SetTextColor(1, 1, 0.2)
        
        icon.count = icon:CreateFontString(nil, "OVERLAY")
        icon.count:SetFont(GUI_FONT, 10, "OUTLINE")
        icon.count:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 2, 2)
        icon.count:SetTextColor(1, 1, 1)
        
        return icon
    end
    
    -- Debuff container
    local debuffContainer = CreateFrame("Frame", nil, plate)
    debuffContainer:SetSize(200, 30)
    debuffContainer.icons = {}
    for i = 1, 6 do
        debuffContainer.icons[i] = CreatePreviewAuraIcon(debuffContainer)
    end
    
    -- Buff container
    local buffContainer = CreateFrame("Frame", nil, plate)
    buffContainer:SetSize(200, 30)
    buffContainer.icons = {}
    for i = 1, 4 do
        buffContainer.icons[i] = CreatePreviewAuraIcon(buffContainer)
    end
    
    -- =============================================================================
    -- TURBODEBUFFS PREVIEW (BigDebuffs-style single priority aura)
    -- =============================================================================
    local tdFrame = CreateFrame("Frame", nil, plate)
    tdFrame:SetSize(32, 32)
    tdFrame:SetFrameLevel(plate:GetFrameLevel() + 10)
    
    tdFrame.icon = tdFrame:CreateTexture(nil, "ARTWORK")
    tdFrame.icon:SetAllPoints()
    tdFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    tdFrame.icon:SetTexture("Interface\\Icons\\Spell_Frost_FreezingBreath")  -- Sample CC icon
    
    tdFrame.border = CreateTextureBorder(tdFrame, 1)
    
    tdFrame.timer = tdFrame:CreateFontString(nil, "OVERLAY")
    tdFrame.timer:SetFont(GUI_FONT, 12, "OUTLINE")
    tdFrame.timer:SetPoint("CENTER", 0, 0)
    tdFrame.timer:SetText("5")
    tdFrame.timer:SetTextColor(1, 1, 1)
    
    tdFrame:Hide()  -- Hidden by default
    plate.turboDebuffPreview = tdFrame
    
    -- Store references for UpdatePreview
    plate.debuffContainer = debuffContainer
    plate.buffContainer = buffContainer
    plate.nameText = nameText
    plate.levelText = levelText
    plate.hp = hp
    
    local castTimer = 0
    plate:SetScript("OnUpdate", function(self, elapsed)
        if not guiFrame or not guiFrame:IsShown() then return end
        castTimer = castTimer + elapsed
        if castTimer > 1.5 then castTimer = 0 end
        local progress = castTimer / 1.5
        cb:SetValue(progress * 100)
        -- Update timer text
        local db = TurboPlatesDB
        if db and (db.showCastTimer == nil or db.showCastTimer == true) then
            cbTime:SetText(string.format("%.1f", 1.5 - castTimer))
            cbTime:Show()
        else
            cbTime:Hide()
        end
        -- Update spark position
        if db and (db.showCastSpark == nil or db.showCastSpark == true) and cb:IsShown() then
            local cbWidth = cb:GetWidth()
            cbSpark:ClearAllPoints()
            cbSpark:SetPoint("CENTER", cb, "LEFT", cbWidth * progress, 0)
            cbSpark:Show()
        else
            cbSpark:Hide()
        end
    end)
    
    ns.UpdatePreview = function()
        if not guiFrame or not guiFrame:IsShown() then return end
        local db = TurboPlatesDB
        if not db then return end
        local d = ns.defaults
        
        hp:SetSize(db.width or d.width, db.hpHeight or d.hpHeight)
        cb:SetSize(db.width or d.width, db.castHeight or d.castHeight)
        hp:SetStatusBarTexture(db.texture or d.texture)
        cb:SetStatusBarTexture(db.texture or d.texture)
        
        -- Update background alpha
        if hp.bg then
            local bgAlpha = db.backgroundAlpha or d.backgroundAlpha or 0.8
            hp.bg:SetVertexColor(0, 0, 0, bgAlpha)
        end
        
        -- Toggle healthbar border visibility in preview
        if hp.border then
            if db.healthBarBorder ~= false then
                hp.border:Show()
            else
                hp.border:Hide()
            end
        end
        
        -- Update target glow/arrow preview
        local glowStyle = db.targetGlow or d.targetGlow or "none"
        local arrowStyle = db.targetArrow or d.targetArrow or "none"
        local glowColor = db.targetGlowColor or d.targetGlowColor or { r = 1, g = 1, b = 1 }
        
        -- Hide all glow elements first
        if plate.targetGlow then plate.targetGlow:Hide() end
        if plate.targetArrows then
            plate.targetArrows.left:Hide()
            plate.targetArrows.right:Hide()
        end
        if plate.thickOutline then 
            plate.thickOutline:Hide()
            -- Hide both cached borders
            if plate.thickOutline.borders then
                if plate.thickOutline.borders.thick then plate.thickOutline.borders.thick:Hide() end
                if plate.thickOutline.borders.thin then plate.thickOutline.borders.thin:Hide() end
            end
        end
        
        -- Arrow styles
        local arrowTextures = {
            arrows_thin = "Interface\\AddOns\\TurboPlates\\Textures\\arrow_thin_right_64.tga",
            arrows_normal = "Interface\\AddOns\\TurboPlates\\Textures\\arrow_single_right_64.tga",
            arrows_double = "Interface\\AddOns\\TurboPlates\\Textures\\arrow_double_right_64.tga",
        }
        
        -- Show arrows if enabled
        if arrowTextures[arrowStyle] and plate.targetArrows then
            local arrows = plate.targetArrows
            local texPath = arrowTextures[arrowStyle]
            arrows.left:SetTexture(texPath)
            arrows.right:SetTexture(texPath)
            
            -- Size scales with HP bar height
            local hpHeight = db.hpHeight or d.hpHeight or 8
            local arrowHeight = hpHeight * 1.3
            local arrowWidth = arrowHeight * 1
            
            arrows.left:SetSize(arrowWidth, arrowHeight)
            arrows.right:SetSize(arrowWidth, arrowHeight)
            
            arrows.left:ClearAllPoints()
            arrows.right:ClearAllPoints()
            arrows.right:SetPoint("LEFT", hp, "RIGHT", -3, 0)
            arrows.left:SetPoint("RIGHT", hp, "LEFT", 3, 0)
            
            arrows.left:SetVertexColor(glowColor.r, glowColor.g, glowColor.b, 0.9)
            arrows.right:SetVertexColor(glowColor.r, glowColor.g, glowColor.b, 0.9)
            
            arrows.left:Show()
            arrows.right:Show()
        end
        
        -- Show glow/border if enabled (independent of arrows)
        if glowStyle == "thick" or glowStyle == "thin" then
            -- Thick/Thin outline: solid colored border around healthbar
            if not plate.thickOutline then
                local outline = CreateFrame("Frame", nil, hp)
                outline:SetFrameLevel(hp:GetFrameLevel() + 2)
                outline:EnableMouse(false)
                outline.borders = {}  -- Cache for thick/thin borders
                plate.thickOutline = outline
            end
            
            local outline = plate.thickOutline
            local borderKey = glowStyle  -- "thick" or "thin" as cache key
            
            -- Use cached border or create new one
            if not outline.borders[borderKey] then
                local thickness = (glowStyle == "thick") and 3 or 1.5
                outline.borders[borderKey] = CreateTextureBorder(hp, thickness)
            end
            
            -- Hide the other thickness if shown
            local otherKey = (borderKey == "thick") and "thin" or "thick"
            if outline.borders[otherKey] then
                outline.borders[otherKey]:Hide()
            end
            
            local border = outline.borders[borderKey]
            border:SetColor(glowColor.r, glowColor.g, glowColor.b, 1)
            border:Show()
            outline:Show()
        elseif glowStyle == "border" then
            -- Border style: glow surrounding the healthbar
            if plate.targetGlow then
                local glow = plate.targetGlow
                glow:ClearAllPoints()
                glow:SetPoint("TOPLEFT", hp, "TOPLEFT", -5, 5)
                glow:SetPoint("BOTTOMRIGHT", hp, "BOTTOMRIGHT", 5, -5)
                glow:SetBackdrop({ edgeFile = "Interface\\AddOns\\TurboPlates\\Textures\\GlowTex.tga", edgeSize = 5 })
                glow:SetBackdropBorderColor(glowColor.r, glowColor.g, glowColor.b, 0.9)
                glow:Show()
            end
        end
        
        local hpC = db.hpColor or d.hpColor
        local castC = db.castColor or d.castColor
        hp:SetStatusBarColor(hpC.r, hpC.g, hpC.b)
        cb:SetStatusBarColor(castC.r, castC.g, castC.b)
        
        local f = db.font or d.font
        local fs = db.fontSize or d.fontSize
        local fo = db.fontOutline or d.fontOutline
        nameText:SetFont(f, fs, fo)
        cbTime:SetFont(f, 8, "OUTLINE")
        cbName:SetFont(f, 8, "OUTLINE")
        
        -- Apply name positioning based on nameInHealthbar setting
        local nameInHealthbar = db.nameInHealthbar or false
        nameText:ClearAllPoints()
        if nameInHealthbar then
            nameText:SetPoint("LEFT", hp, "LEFT", 4, 0)
            nameText:SetJustifyH("LEFT")
            local hpWidth = db.width or d.width
            nameText:SetWidth(hpWidth * 0.6)
        else
            nameText:SetPoint("BOTTOM", hp, "TOP", 0, 3)
            nameText:SetJustifyH("CENTER")
            nameText:SetWidth(0)
        end
        nameText:SetText("Dummy")
        
        -- Show/hide name based on nameDisplayFormat
        local nameFormat = db.nameDisplayFormat or d.nameDisplayFormat or "none"
        if nameFormat == "disabled" then
            nameText:Hide()
        else
            nameText:Show()
        end
        
        -- Apply hostile name color
        local nameColor = db.hostileNameColor or d.hostileNameColor or {r = 1, g = 1, b = 1}
        nameText:SetTextColor(nameColor.r, nameColor.g, nameColor.b)
        
        -- Level indicator preview
        local levelMode = db.levelMode or d.levelMode or "disabled"
        if levelMode ~= "disabled" and plate.levelText then
            plate.levelText:SetFont(f, fs, fo)
            plate.levelText:ClearAllPoints()
            if nameInHealthbar then
                -- Anchor to right of healthbar when name is inside
                plate.levelText:SetPoint("LEFT", hp, "RIGHT", 2, 0)
            else
                plate.levelText:SetPoint("LEFT", nameText, "RIGHT", 2, 0)
            end
            plate.levelText:SetText("58")  -- Sample level (below player)
            -- Use orange color (lower level than player)
            plate.levelText:SetTextColor(1.0, 0.5, 0.0)
            plate.levelText:Show()
        elseif plate.levelText then
            plate.levelText:Hide()
        end
        
        -- Health value text
        local healthFormat = db.healthValueFormat or d.healthValueFormat or "none"
        local healthFontSize = db.healthValueFontSize or d.healthValueFontSize or 10
        healthText:SetFont(f, healthFontSize, fo)
        
        -- Position health text based on nameInHealthbar setting
        healthText:ClearAllPoints()
        if nameInHealthbar then
            healthText:SetPoint("RIGHT", hp, "RIGHT", -4, 0)
            healthText:SetJustifyH("RIGHT")
        else
            healthText:SetPoint("CENTER", hp, "CENTER", 0, 0)
            healthText:SetJustifyH("CENTER")
        end
        
        -- Helper function to truncate values (always enabled)
        local function TruncateValue(value)
            if value >= 1000000 then
                return string.format("%.2fm", value / 1000000)
            elseif value >= 1000 then
                return string.format("%.1fk", value / 1000)
            else
                return string.format("%d", value)
            end
        end
        
        if healthFormat ~= "none" then
            local current, max = 75, 100
            local percent = (current / max) * 100
            local deficit = max - current
            local atFullHealth = (current == max)
            local text = ""
            
            if healthFormat == "current" then
                text = TruncateValue(current)
            elseif healthFormat == "percent" then
                -- Only show percent if not at full health
                if not atFullHealth then
                    text = string.format("%.0f%%", percent)
                end
            elseif healthFormat == "current-max" then
                text = TruncateValue(current) .. " / " .. TruncateValue(max)
            elseif healthFormat == "current-max-percent" then
                if atFullHealth then
                    text = TruncateValue(current) .. " / " .. TruncateValue(max)
                else
                    text = TruncateValue(current) .. " / " .. TruncateValue(max) .. " (" .. string.format("%.0f%%", percent) .. ")"
                end
            elseif healthFormat == "current-percent" then
                if atFullHealth then
                    text = TruncateValue(current)
                else
                    text = TruncateValue(current) .. " (" .. string.format("%.0f%%", percent) .. ")"
                end
            elseif healthFormat == "deficit" then
                -- Only show if not at full health
                if not atFullHealth then
                    text = "-" .. TruncateValue(deficit)
                end
            elseif healthFormat == "current-deficit" then
                if atFullHealth then
                    text = TruncateValue(current)
                else
                    text = TruncateValue(current) .. " | -" .. TruncateValue(deficit)
                end
            elseif healthFormat == "percent-deficit" then
                -- Only show if not at full health
                if not atFullHealth then
                    text = string.format("%.0f%%", percent) .. " | -" .. TruncateValue(deficit)
                end
            end
            
            if text ~= "" then
                healthText:SetText(text)
                healthText:Show()
            else
                healthText:Hide()
            end
        else
            healthText:Hide()
        end
        
        -- Execute indicator
        local execRange = db.executeRange or d.executeRange or 0
        if execRange > 0 and execRange <= 100 then
            local width = db.width or d.width
            local height = db.hpHeight or d.hpHeight
            local xPos = (execRange / 100) * width
            execIndicator:SetHeight(height)
            execIndicator:ClearAllPoints()
            execIndicator:SetPoint("LEFT", hp, "LEFT", xPos, 0)
            execIndicator:Show()
        else
            execIndicator:Hide()
        end
        
        raidIcon:SetSize(db.raidMarkerSize or d.raidMarkerSize, db.raidMarkerSize or d.raidMarkerSize)
        raidIcon:ClearAllPoints()
        local anchor = db.raidMarkerAnchor or d.raidMarkerAnchor or "CENTER"
        local offsetX = db.raidMarkerX or d.raidMarkerX or 0
        local offsetY = db.raidMarkerY or d.raidMarkerY or 0
        if anchor == "LEFT" then
            raidIcon:SetPoint("RIGHT", hp, "LEFT", offsetX - 2, offsetY)
        elseif anchor == "RIGHT" then
            raidIcon:SetPoint("LEFT", hp, "RIGHT", offsetX + 2, offsetY)
        elseif anchor == "TOP" then
            raidIcon:SetPoint("BOTTOM", nameText, "TOP", offsetX, offsetY + 2)
        else  -- CENTER
            raidIcon:SetPoint("CENTER", hp, "CENTER", offsetX, offsetY)
        end
        
        if db.showCastbar then
            cb:Show()
            local iconSize = db.castHeight or d.castHeight
            local showIcon = db.showCastIcon ~= false
            local showSpark = db.showCastSpark == nil or db.showCastSpark == true
            local castW = showIcon and ((db.width or d.width) - iconSize - 2) or (db.width or d.width)
            cb:SetWidth(castW)
            cb:ClearAllPoints()
            if showIcon then
                cb:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -2)
                cbIcon:SetSize(iconSize, iconSize)
                cbIcon:ClearAllPoints()
                cbIcon:SetPoint("RIGHT", cb, "LEFT", -2, 0)
                cbIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                cbIcon:Show()
                cbIconBorder:ClearAllPoints()
                cbIconBorder:SetAllPoints(cbIcon)
                cbIconBorder:Show()
            else
                cb:SetPoint("TOP", hp, "BOTTOM", 0, -2)
                cbIcon:Hide()
                cbIconBorder:Hide()
            end
            -- Update spark size based on castbar height
            cbSpark:SetSize(16, iconSize * 2)
            if showSpark then
                cbSpark:Show()
            else
                cbSpark:Hide()
            end
            cbTime:ClearAllPoints()
            cbTime:SetPoint("RIGHT", cb, -4, 0)
            cbName:ClearAllPoints()
            cbName:SetPoint("LEFT", cb, 4, 0)
            cbName:SetPoint("RIGHT", cbTime, "LEFT", -5, 0)
            cbName:SetText("Casting...")
        else
            cb:Hide()
            cbIcon:Hide()
            cbIconBorder:Hide()
            cbSpark:Hide()
        end
        plate:SetScale(db.scale or d.scale)
        
        -- Combo points - show for Druid, Rogue, HERO (if enabled)
        if ShouldShowComboPoints() and db.showComboPoints ~= false then
            local cpSize = db.cpSize or d.cpSize or 14
            local cpHeight = 4
            local spacing = 1  -- 1px gap between bars
            local totalWidth = (cpSize * MAX_CP) + (spacing * (MAX_CP - 1))
            local cpX = db.cpX or d.cpX or 0
            local cpY = db.cpY or d.cpY or 0
            
            cpContainer:SetSize(totalWidth, cpHeight)
            cpContainer:ClearAllPoints()
            cpContainer:SetPoint("BOTTOM", hp, "TOP", cpX, -1 + cpY)
            cpContainer:Show()
            
            for i = 1, MAX_CP do
                cpBars[i]:ClearAllPoints()
                cpBars[i]:SetSize(cpSize, cpHeight)
                if i == 1 then
                    cpBars[i]:SetPoint("LEFT", cpContainer, "LEFT", 0, 0)
                else
                    cpBars[i]:SetPoint("LEFT", cpBars[i-1], "RIGHT", spacing, 0)
                end
                cpBars[i]:Show()
            end
        else
            cpContainer:Hide()
        end
        
        -- Clickbox debug visualization (shows clickable area)
        local showClickbox = C_CVar.GetBool("DrawNameplateClickBox")
        if showClickbox then
            -- Use namespace cache (initialized at PLAYER_LOGIN, updated by sliders)
            clickboxDebug:SetSize(ns.clickableWidth, ns.clickableHeight)
            clickboxDebug:Show()
        else
            clickboxDebug:Hide()
        end
        
        -- =============================================================================
        -- AURA PREVIEW UPDATE
        -- =============================================================================
        local auras = db.auras or d.auras
        local showDebuffs = auras.showDebuffs ~= false
        local buffFilterMode = auras.buffFilterMode or "ONLY_DISPELLABLE"
        local showBuffs = buffFilterMode ~= "DISABLED"
        local debuffWidth = auras.debuffIconWidth or 20
        local debuffHeight = auras.debuffIconHeight or 20
        local buffWidth = auras.buffIconWidth or 18
        local buffHeight = auras.buffIconHeight or 18
        local maxDebuffs = auras.maxDebuffs or 6
        local maxBuffs = auras.maxBuffs or 4
        local debuffGrowDir = auras.growDirection or "CENTER"
        local buffGrowDir = auras.buffGrowDirection or "CENTER"
        local debuffIconSpacing = auras.iconSpacing or 2
        local buffIconSpacing = auras.buffIconSpacing or 2
        local debuffXOffset = auras.debuffXOffset or 0
        local debuffYOffset = auras.debuffYOffset or 0
        local buffXOffset = auras.buffXOffset or 0
        local buffYOffset = auras.buffYOffset or 0
        
        -- Border mode settings
        local debuffBorderMode = auras.debuffBorderMode or "COLOR_CODED"
        local buffBorderMode = auras.buffBorderMode or "COLOR_CODED"
        local debuffBorderColor = auras.debuffBorderColor or d.auras.debuffBorderColor
        local buffBorderColor = auras.buffBorderColor or d.auras.buffBorderColor
        
        -- Font size settings
        local debuffFontSize = auras.debuffFontSize or 10
        local buffFontSize = auras.buffFontSize or 10
        
        -- Text anchor settings
        local debuffDurationAnchor = auras.debuffDurationAnchor or "BOTTOM"
        local debuffStackAnchor = auras.debuffStackAnchor or "TOPRIGHT"
        local buffDurationAnchor = auras.buffDurationAnchor or "BOTTOM"
        local buffStackAnchor = auras.buffStackAnchor or "TOPRIGHT"
        
        -- Stack font size settings (separate from duration)
        local debuffStackFontSize = auras.debuffStackFontSize or 10
        local buffStackFontSize = auras.buffStackFontSize or 10
        
        -- Text anchor lookup tables (same as Auras.lua)
        -- INNER positioning: Text stays inside the icon bounds
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
        
        -- Determine anchor: name if visible, otherwise healthbar
        local nameFormat = db.nameDisplayFormat or d.nameDisplayFormat or "none"
        local anchor = (nameFormat ~= "disabled") and nameText or hp
        
        -- Helper to position icons based on grow direction
        local function PositionPreviewIcons(container, count, iconWidth, iconHeight, samples, borderColors, isBuff, growDir, iconSpacing, borderMode, customBorderColor, fontSize, stackFontSize, durationAnchor, stackAnchor)
            for i = 1, #container.icons do
                container.icons[i]:Hide()
            end
            
            if count == 0 then return end
            
            -- Get anchor positions (duration inside, stacks outside)
            local durAnchor = DURATION_ANCHORS[durationAnchor] or DURATION_ANCHORS.BOTTOM
            local stkAnchor = STACK_ANCHORS[stackAnchor] or STACK_ANCHORS.TOPRIGHT
            
            local totalWidth = (count * iconWidth) + ((count - 1) * iconSpacing)
            
            for i = 1, count do
                local icon = container.icons[i]
                local sample = samples[((i - 1) % #samples) + 1]
                
                icon:SetSize(iconWidth, iconHeight)
                icon.texture:SetTexture(sample.icon)
                
                -- Set border color based on border mode (matches Auras.lua SetBorderColor)
                if borderMode == "DISABLED" then
                    icon.border:SetColor(0, 0, 0, 0)  -- Fully transparent
                elseif borderMode == "CUSTOM" and customBorderColor then
                    icon.border:SetColor(customBorderColor.r or 1, customBorderColor.g or 1, customBorderColor.b or 1, 1)
                else
                    -- COLOR_CODED for debuffs, DISPELLABLE for buffs
                    if isBuff then
                        -- Buffs: dispellable = Magic blue, non-dispellable = red
                        if sample.purgeable then
                            icon.border:SetColor(unpack(DEBUFF_BORDER_COLORS.Magic))  -- Blue
                        else
                            icon.border:SetColor(unpack(DEBUFF_BORDER_COLORS.none))   -- Red
                        end
                    else
                        -- Debuffs: use debuff type colors
                        local color = borderColors[sample.debuffType] or borderColors.none
                        icon.border:SetColor(unpack(color))
                    end
                end
                
                -- Apply font sizes (separate for duration and stacks)
                local fs = fontSize or 10
                local sfs = stackFontSize or 10
                icon.duration:SetFont(GUI_FONT, fs, "OUTLINE")
                icon.count:SetFont(GUI_FONT, sfs, "OUTLINE")
                
                -- Position duration text based on anchor setting (textPoint, iconPoint, offsetX, offsetY)
                icon.duration:ClearAllPoints()
                icon.duration:SetPoint(durAnchor[1], icon, durAnchor[2], durAnchor[3], durAnchor[4])
                
                -- Position stack count based on anchor setting
                icon.count:ClearAllPoints()
                icon.count:SetPoint(stkAnchor[1], icon, stkAnchor[2], stkAnchor[3], stkAnchor[4])
                
                -- Duration text
                icon.duration:SetText(sample.duration)
                
                -- Stack count
                if sample.stacks > 1 then
                    icon.count:SetText(sample.stacks)
                    icon.count:Show()
                else
                    icon.count:Hide()
                end
                
                -- Position based on grow direction
                -- LEFT = grow right, RIGHT = grow left, CENTER = grow outward
                -- Icons anchor from BOTTOM edge so height grows upward
                icon:ClearAllPoints()
                if growDir == "CENTER" then
                    local xOffset = (i - 1) * (iconWidth + iconSpacing) - (totalWidth / 2) + (iconWidth / 2)
                    icon:SetPoint("BOTTOM", container, "BOTTOM", xOffset, 0)
                elseif growDir == "LEFT" then
                    local xOffset = (i - 1) * (iconWidth + iconSpacing)
                    icon:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", xOffset, 0)
                elseif growDir == "RIGHT" then
                    local xOffset = -((i - 1) * (iconWidth + iconSpacing))
                    icon:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", xOffset, 0)
                end
                
                icon:Show()
            end
        end
        
        -- Calculate Y offset to clear the name if it's visible
        -- Name is positioned 3px above hp, so add name height + 3 to clear it
        local nameHeightOffset = 0
        if nameFormat ~= "disabled" then
            local nameHeight = nameText:GetStringHeight() or 12
            nameHeightOffset = nameHeight + 3  -- 3px is the gap between hp and name
        end
        
        -- Position debuff container based on grow direction
        -- Always anchor to hp for consistent X alignment, adjust Y for name height
        debuffContainer:ClearAllPoints()
        -- Add PREVIEW_BORDER_SIZE since the icon frame includes border padding
        local debuffY = debuffYOffset + nameHeightOffset + PREVIEW_BORDER_SIZE
        if debuffGrowDir == "LEFT" then
            debuffContainer:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", debuffXOffset, debuffY)
        elseif debuffGrowDir == "RIGHT" then
            debuffContainer:SetPoint("BOTTOMRIGHT", hp, "TOPRIGHT", debuffXOffset, debuffY)
        else
            debuffContainer:SetPoint("BOTTOM", hp, "TOP", debuffXOffset, debuffY)
        end
        
        -- Determine actual debuff count for preview (for stacking calculation)
        local actualDebuffCount = showDebuffs and math.min(#sampleDebuffs, maxDebuffs) or 0
        
        -- Position buff container based on grow direction (stacks above debuffs if visible)
        buffContainer:ClearAllPoints()
        -- Add PREVIEW_BORDER_SIZE for buff positioning as well
        local buffY = buffYOffset + nameHeightOffset + PREVIEW_BORDER_SIZE
        if actualDebuffCount > 0 then
            buffY = buffY + debuffHeight + 4
        end
        if buffGrowDir == "LEFT" then
            buffContainer:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", buffXOffset, buffY)
        elseif buffGrowDir == "RIGHT" then
            buffContainer:SetPoint("BOTTOMRIGHT", hp, "TOPRIGHT", buffXOffset, buffY)
        else
            buffContainer:SetPoint("BOTTOM", hp, "TOP", buffXOffset, buffY)
        end
        
        -- Show/hide and populate containers
        if showDebuffs then
            debuffContainer:Show()
            PositionPreviewIcons(debuffContainer, actualDebuffCount, debuffWidth, debuffHeight, sampleDebuffs, DEBUFF_BORDER_COLORS, false, debuffGrowDir, debuffIconSpacing, debuffBorderMode, debuffBorderColor, debuffFontSize, debuffStackFontSize, debuffDurationAnchor, debuffStackAnchor)
        else
            debuffContainer:Hide()
        end
        
        if showBuffs then
            buffContainer:Show()
            local buffCount = math.min(#sampleBuffs, maxBuffs)
            PositionPreviewIcons(buffContainer, buffCount, buffWidth, buffHeight, sampleBuffs, nil, true, buffGrowDir, buffIconSpacing, buffBorderMode, buffBorderColor, buffFontSize, buffStackFontSize, buffDurationAnchor, buffStackAnchor)
        else
            buffContainer:Hide()
        end
        
        -- =============================================================================
        -- TURBODEBUFFS PREVIEW UPDATE
        -- =============================================================================
        local td = db.turboDebuffs or d.turboDebuffs or {}
        local tdDefaults = d.turboDebuffs or {}
        local tdEnabled = td.enabled == true
        
        if tdEnabled and plate.turboDebuffPreview then
            local tdFrame = plate.turboDebuffPreview
            local tdSize = td.size or tdDefaults.size or 32
            local tdAnchor = td.anchor or tdDefaults.anchor or "LEFT"
            local tdXOff = td.xOffset or tdDefaults.xOffset or 0
            local tdYOff = td.yOffset or tdDefaults.yOffset or 0
            local tdTimerSize = td.timerSize or tdDefaults.timerSize or 14
            
            tdFrame:SetSize(tdSize, tdSize)
            tdFrame.timer:SetFont(f, tdTimerSize, "OUTLINE")
            
            tdFrame:ClearAllPoints()
            if tdAnchor == "LEFT" then
                tdFrame:SetPoint("RIGHT", hp, "LEFT", -4 + tdXOff, tdYOff)
            elseif tdAnchor == "RIGHT" then
                tdFrame:SetPoint("LEFT", hp, "RIGHT", 4 + tdXOff, tdYOff)
            elseif tdAnchor == "TOP" then
                tdFrame:SetPoint("BOTTOM", hp, "TOP", tdXOff, 4 + tdYOff)
            elseif tdAnchor == "BOTTOM" then
                tdFrame:SetPoint("TOP", hp, "BOTTOM", tdXOff, -4 + tdYOff)
            else
                tdFrame:SetPoint("RIGHT", hp, "LEFT", -4 + tdXOff, tdYOff)
            end
            
            tdFrame:Show()
        elseif plate.turboDebuffPreview then
            plate.turboDebuffPreview:Hide()
        end
    end
    return p
end

-- Show GUI (internal function, no toggle, no combat check)
-- Used by combat handler to reopen after combat
ShowGUI = function()
    if guiFrame then
        guiFrame:Show()
        -- Only show preview if toggle is checked
        if previewFrame and guiFrame.previewToggle and guiFrame.previewToggle:GetChecked() then
            previewFrame:Show()
            ns.UpdatePreview()
        end
    else
        -- Frame doesn't exist yet, need to create it via ToggleGUI
        ns:ToggleGUI()
    end
end

-- Main GUI creation
function ns:ToggleGUI()
    -- Combat lockdown check
    if InCombatLockdown() then
        print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Options will open after combat ends.")
        reopenAfterCombat = true
        return
    end
    
    if guiFrame then
        if guiFrame:IsShown() then
            guiFrame:Hide()
            if previewFrame then previewFrame:Hide() end
        else
            ShowGUI()
        end
        return
    end
    
    if not TurboPlatesDB then TurboPlatesDB = {} end
    
    -- Main frame (670x500)
    guiFrame = CreateFrame("Frame", "TurboPlatesGUI", UIParent, "BackdropTemplate")
    guiFrame:SetSize(670, 500)
    guiFrame:SetPoint("CENTER")
    guiFrame:SetFrameStrata("HIGH")
    guiFrame:SetFrameLevel(10)
    guiFrame:EnableMouse(true)
    guiFrame:SetMovable(true)
    guiFrame:RegisterForDrag("LeftButton")
    guiFrame:SetScript("OnDragStart", guiFrame.StartMoving)
    guiFrame:SetScript("OnDragStop", guiFrame.StopMovingOrSizing)
    guiFrame:SetScript("OnHide", function() if previewFrame then previewFrame:Hide() end end)
    guiFrame:SetScript("OnShow", function()
        -- Only show preview if the toggle exists and is checked
        if previewFrame and guiFrame.previewToggle and guiFrame.previewToggle:GetChecked() then
            previewFrame:Show()
        end
    end)
    CreateBD(guiFrame, 0.5)  -- Slightly translucent background
    CreateSD(guiFrame)
    CreateTex(guiFrame)  -- Subtle striped texture (very low alpha)
    CreateInnerGradient(guiFrame)  -- Glass depth effect
    tinsert(UISpecialFrames, "TurboPlatesGUI")
    
    -- Title (gradient colored like .toc)
    local version = GetAddOnMetadata(addonName, "Version") or "1.0.0"
    local coloredTitle = "|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r"
    CreateFS(guiFrame, 16, coloredTitle, nil, "TOP", 0, -10)
    CreateFS(guiFrame, 12, "v"..version, nil, "TOP", 0, -28)
    
    -- Aura Whitelist button (top right)
    local auraWhitelist = CreateButton(guiFrame, 100, 22, L.AuraWhitelist)
    auraWhitelist:SetPoint("TOPRIGHT", -20, -10)
    auraWhitelist:SetFrameLevel(guiFrame:GetFrameLevel() + 50)
    auraWhitelist:SetScript("OnClick", function() PlaySound(856); OpenSpellListPanel("whitelist") end)
    
    -- Aura Blacklist button (top right, next to whitelist)
    local auraBlacklist = CreateButton(guiFrame, 100, 22, L.AuraBlacklist)
    auraBlacklist:SetPoint("RIGHT", auraWhitelist, "LEFT", -10, 0)
    auraBlacklist:SetFrameLevel(guiFrame:GetFrameLevel() + 50)
    auraBlacklist:SetScript("OnClick", function() PlaySound(856); OpenSpellListPanel("blacklist") end)
    
    -- Close button (bottom right)
    local close = CreateButton(guiFrame, 80, 22, "Close")
    close:SetPoint("BOTTOMRIGHT", -20, 15)
    close:SetFrameLevel(guiFrame:GetFrameLevel() + 50)
    close:SetScript("OnClick", function() PlaySound(856); guiFrame:Hide() end)
    
    -- Reset button (bottom right, next to close)
    local reset = CreateButton(guiFrame, 80, 22, "Reset")
    reset:SetPoint("RIGHT", close, "LEFT", -10, 0)
    reset:SetFrameLevel(guiFrame:GetFrameLevel() + 50)
    reset:SetScript("OnClick", function() PlaySound(856); StaticPopup_Show("TURBOPLATES_RESET") end)
    
    -- Create preview first (above the tab content area)
    CreatePreview(guiFrame)
    
    -- Live Preview toggle checkbox (top left)
    local previewToggle = CreateFrame("CheckButton", nil, guiFrame, "BackdropTemplate")
    previewToggle:SetSize(16, 16)
    previewToggle:SetPoint("TOPLEFT", 15, -10)
    previewToggle:SetNormalTexture("")
    previewToggle:SetPushedTexture("")
    
    local ptBg = CreateFrame("Frame", nil, previewToggle, "BackdropTemplate")
    ptBg:SetAllPoints()
    ptBg:SetFrameLevel(previewToggle:GetFrameLevel())
    CreateBD(ptBg, 0.3)
    CreateGradient(ptBg)
    
    previewToggle:SetHighlightTexture(bdTex)
    local ptHl = previewToggle:GetHighlightTexture()
    ptHl:SetAllPoints(ptBg)
    ptHl:SetVertexColor(cr, cg, cb, 0.25)
    
    local ptCheck = previewToggle:CreateTexture(nil, "OVERLAY")
    ptCheck:SetSize(26, 26)
    ptCheck:SetPoint("CENTER")
    ptCheck:SetAtlas("questlog-icon-checkmark-yellow-2x")
    ptCheck:SetSize(20, 20)
    ptCheck:SetVertexColor(1, 0.8, 0)
    previewToggle:SetCheckedTexture(ptCheck)
    
    local ptLabel = CreateFS(previewToggle, 13, L.LivePreview, nil, "LEFT", 24, 0)
    previewToggle:SetHitRectInsets(0, -ptLabel:GetStringWidth()-10, 0, 0)
    
    -- Default to unchecked (hide preview)
    previewToggle:SetChecked(false)
    previewToggle:SetScript("OnClick", function(self)
        if self:GetChecked() then
            if previewFrame then previewFrame:Show() end
            ns.UpdatePreview()
        else
            if previewFrame then previewFrame:Hide() end
        end
    end)
    guiFrame.previewToggle = previewToggle  -- Store reference for OnShow
    
    -- Minimap button toggle checkbox (bottom left, mirrors live preview position)
    local mmToggle = CreateFrame("CheckButton", nil, guiFrame, "BackdropTemplate")
    mmToggle:SetSize(16, 16)
    mmToggle:SetPoint("BOTTOMLEFT", 15, 15)
    mmToggle:SetNormalTexture("")
    mmToggle:SetPushedTexture("")
    
    local mmBg = CreateFrame("Frame", nil, mmToggle, "BackdropTemplate")
    mmBg:SetAllPoints()
    mmBg:SetFrameLevel(mmToggle:GetFrameLevel())
    CreateBD(mmBg, 0.3)
    CreateGradient(mmBg)
    
    mmToggle:SetHighlightTexture(bdTex)
    local mmHl = mmToggle:GetHighlightTexture()
    mmHl:SetAllPoints(mmBg)
    mmHl:SetVertexColor(cr, cg, cb, 0.25)
    
    local mmCheck = mmToggle:CreateTexture(nil, "OVERLAY")
    mmCheck:SetSize(20, 20)
    mmCheck:SetPoint("CENTER")
    mmCheck:SetAtlas("questlog-icon-checkmark-yellow-2x")
    mmCheck:SetVertexColor(1, 0.8, 0)
    mmToggle:SetCheckedTexture(mmCheck)
    
    local mmLabel = CreateFS(mmToggle, 13, L.ShowMinimap, nil, "LEFT", 24, 0)
    mmToggle:SetHitRectInsets(0, -mmLabel:GetStringWidth()-10, 0, 0)
    mmToggle:SetScript("OnClick", function(self)
        if type(TurboPlatesDB.minimap) ~= "table" then TurboPlatesDB.minimap = {hide = false, pos = 45} end
        TurboPlatesDB.minimap.hide = not self:GetChecked()
        if ns.UpdateMinimapButton then ns:UpdateMinimapButton() end
    end)
    mmToggle:SetScript("OnShow", function(self)
        if type(TurboPlatesDB.minimap) ~= "table" then TurboPlatesDB.minimap = {hide = false, pos = 45} end
        self:SetChecked(not TurboPlatesDB.minimap.hide)
    end)
    -- Initialize checked state immediately (in case OnShow doesn't fire)
    if type(TurboPlatesDB.minimap) ~= "table" then TurboPlatesDB.minimap = {hide = false, pos = 45} end
    mmToggle:SetChecked(not TurboPlatesDB.minimap.hide)
    
    -- Create tabs on left
    for i, name in ipairs(tabNames) do
        guiTab[i] = CreateTab(guiFrame, i, name)
        
        -- Create simple frame for each tab page (no scrollbar)
        guiPage[i] = CreateFrame("Frame", nil, guiFrame, "BackdropTemplate")
        guiPage[i]:SetPoint("TOPLEFT", 150, -50)
        guiPage[i]:SetPoint("BOTTOMRIGHT", -20, 50)
        guiPage[i]:Hide()
        CreateBD(guiPage[i], 0.3)
        
        -- For compatibility, child points to the page itself
        guiPage[i].child = guiPage[i]
    end
    
    -- TAB 1: General (CVar Controls + Core Settings)
    local p1 = guiPage[1]
    local y = -10
    
    -- Section header
    CreateFS(p1, 13, L.ShowNameplatesFor, "system", "TOPLEFT", 20, y)
    
    -- Friendly Units parent checkbox first
    local friendlyUnits = CreateCVarCheckBox(p1, "nameplateShowFriends", L.FriendlyUnits, 20, y - 25)
    
    -- Friendly children - enable parent when any child is checked
    local friendlyPets = CreateCVarCheckBox(p1, "nameplateShowFriendlyPets", L.ShowPetsLabel, 40, y - 55, function(self)
        if self:GetChecked() and not friendlyUnits:GetChecked() then
            friendlyUnits:SetChecked(true)
            SetCVar("nameplateShowFriends", "1")
        end
    end)
    local friendlyGuardians = CreateCVarCheckBox(p1, "nameplateShowFriendlyGuardians", L.ShowGuardians, 40, y - 85, function(self)
        if self:GetChecked() and not friendlyUnits:GetChecked() then
            friendlyUnits:SetChecked(true)
            SetCVar("nameplateShowFriends", "1")
        end
    end)
    local friendlyTotems = CreateCVarCheckBox(p1, "nameplateShowFriendlyTotems", L.ShowTotems, 40, y - 115, function(self)
        if self:GetChecked() and not friendlyUnits:GetChecked() then
            friendlyUnits:SetChecked(true)
            SetCVar("nameplateShowFriends", "1")
        end
    end)
    
    -- Helper to update friendly children visual state
    local function UpdateFriendlyChildrenState()
        local enabled = friendlyUnits:GetChecked()
        if enabled then
            friendlyPets:Enable()
            friendlyPets:SetAlpha(1)
            friendlyPets.label:SetTextColor(1, 1, 1)
            friendlyGuardians:Enable()
            friendlyGuardians:SetAlpha(1)
            friendlyGuardians.label:SetTextColor(1, 1, 1)
            friendlyTotems:Enable()
            friendlyTotems:SetAlpha(1)
            friendlyTotems.label:SetTextColor(1, 1, 1)
        else
            friendlyPets:Disable()
            friendlyPets:SetAlpha(0.5)
            friendlyPets.label:SetTextColor(0.5, 0.5, 0.5)
            friendlyGuardians:Disable()
            friendlyGuardians:SetAlpha(0.5)
            friendlyGuardians.label:SetTextColor(0.5, 0.5, 0.5)
            friendlyTotems:Disable()
            friendlyTotems:SetAlpha(0.5)
            friendlyTotems.label:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    
    -- Hook parent to grey out children when disabled (keep checkmarks)
    friendlyUnits:HookScript("OnClick", UpdateFriendlyChildrenState)
    friendlyUnits:HookScript("OnShow", UpdateFriendlyChildrenState)
    
    -- Enemy Units parent checkbox first
    local enemyUnits = CreateCVarCheckBox(p1, "nameplateShowEnemies", L.EnemyUnits, 260, y - 25)
    
    -- Enemy children - enable parent when any child is checked
    local enemyPets = CreateCVarCheckBox(p1, "nameplateShowEnemyPets", L.ShowPetsLabel, 280, y - 55, function(self)
        if self:GetChecked() and not enemyUnits:GetChecked() then
            enemyUnits:SetChecked(true)
            SetCVar("nameplateShowEnemies", "1")
        end
    end)
    local enemyGuardians = CreateCVarCheckBox(p1, "nameplateShowEnemyGuardians", L.ShowGuardians, 280, y - 85, function(self)
        if self:GetChecked() and not enemyUnits:GetChecked() then
            enemyUnits:SetChecked(true)
            SetCVar("nameplateShowEnemies", "1")
        end
    end)
    local enemyTotems = CreateCVarCheckBox(p1, "nameplateShowEnemyTotems", L.ShowTotems, 280, y - 115, function(self)
        if self:GetChecked() and not enemyUnits:GetChecked() then
            enemyUnits:SetChecked(true)
            SetCVar("nameplateShowEnemies", "1")
        end
    end)
    
    -- Helper to update enemy children visual state
    local function UpdateEnemyChildrenState()
        local enabled = enemyUnits:GetChecked()
        if enabled then
            enemyPets:Enable()
            enemyPets:SetAlpha(1)
            enemyPets.label:SetTextColor(1, 1, 1)
            enemyGuardians:Enable()
            enemyGuardians:SetAlpha(1)
            enemyGuardians.label:SetTextColor(1, 1, 1)
            enemyTotems:Enable()
            enemyTotems:SetAlpha(1)
            enemyTotems.label:SetTextColor(1, 1, 1)
        else
            enemyPets:Disable()
            enemyPets:SetAlpha(0.5)
            enemyPets.label:SetTextColor(0.5, 0.5, 0.5)
            enemyGuardians:Disable()
            enemyGuardians:SetAlpha(0.5)
            enemyGuardians.label:SetTextColor(0.5, 0.5, 0.5)
            enemyTotems:Disable()
            enemyTotems:SetAlpha(0.5)
            enemyTotems.label:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    
    -- Hook parent to grey out children when disabled (keep checkmarks)
    enemyUnits:HookScript("OnClick", UpdateEnemyChildrenState)
    enemyUnits:HookScript("OnShow", UpdateEnemyChildrenState)
    
    -- General Options section header
    CreateFS(p1, 13, L.GeneralOptionsHeader, "system", "TOPLEFT", 20, y - 155)
    
    -- Additional settings
    local friendlyNameOnlyCB = CreateCheckBox(p1, "friendlyNameOnly", L.FriendlyNameOnly, 20, y - 175)
    friendlyNameOnlyCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.FriendlyNameOnly, 1, 1, 1)
        GameTooltip:AddLine(L.FriendlyNameOnlyTip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    friendlyNameOnlyCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Show Guild checkbox (dependent on Name Only) - indented as child
    local friendlyGuildCB = CreateCheckBox(p1, "friendlyGuild", L.FriendlyGuild, 40, y - 205)
    
    -- Show HP when damaged checkbox (dependent on Name Only) - indented as child
    local liteHealthCB = CreateCheckBox(p1, "liteHealthWhenDamaged", L.LiteHealthWhenDamaged, 40, y - 235)
    liteHealthCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.LiteHealthWhenDamaged, 1, 1, 1)
        GameTooltip:AddLine(L.LiteHealthWhenDamagedTip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    liteHealthCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Helper to update dependent checkboxes state based on name-only
    local function UpdateNameOnlyDependents()
        local enabled = TurboPlatesDB.friendlyNameOnly
        if enabled then
            friendlyGuildCB:Enable()
            friendlyGuildCB:SetAlpha(1)
            friendlyGuildCB.label:SetTextColor(1, 1, 1)
            liteHealthCB:Enable()
            liteHealthCB:SetAlpha(1)
            liteHealthCB.label:SetTextColor(1, 1, 1)
        else
            friendlyGuildCB:Disable()
            friendlyGuildCB:SetAlpha(0.5)
            friendlyGuildCB.label:SetTextColor(0.5, 0.5, 0.5)
            liteHealthCB:Disable()
            liteHealthCB:SetAlpha(0.5)
            liteHealthCB.label:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    
    -- Hook name-only checkbox to update dependent checkboxes
    friendlyNameOnlyCB:HookScript("OnClick", UpdateNameOnlyDependents)
    friendlyNameOnlyCB:HookScript("OnShow", UpdateNameOnlyDependents)
    
    -- Tank Mode dropdown
    local tankOpts = {{name = L.TankModeDisabled, value = 0}, {name = L.TankModeSmart, value = 1}, {name = L.TankModeEnabled, value = 2}}
    CreateDropdown(p1, "tankMode", L.TankMode, tankOpts, 20, y - 265)
    
    -- Execute Range slider (below Tank Mode)
    CreateSlider(p1, "executeRange", L.ExecuteRange, 0, 100, 20, y - 320, false, nil, "%")
    
    -- PvP section header
    CreateFS(p1, 13, L.PvPHeader, "system", "TOPLEFT", 260, y - 155)
    
    -- PvP settings (right column)
    CreateCheckBox(p1, "classColoredHealth", L.ClassColoredHealth, 260, y - 175)
    CreateCheckBox(p1, "classColoredName", L.ClassColoredName, 260, y - 205)
    CreateCheckBox(p1, "arenaNumbers", L.ArenaNumbers, 260, y - 235)
    CreateDropdown(p1, "targetingMeIndicator", L.TargetingMeIndicator, ns.TargetingMeStyles, 260, y - 265)
    
    -- Healer marks dropdown (CLEU-based healer detection)
    local healerMarksOpts = {
        {name = "Disabled", value = 0},
        {name = "Enemies Only", value = 1},
        {name = "Friendly Only", value = 2},
        {name = "Both", value = 3},
    }
    CreateDropdown(p1, "healerMarks", L.HealerMarks, healerMarksOpts, 260, y - 320)
    
    -- TAB 2: Style (Sizes & Textures)
    local p2 = guiPage[2]
    y = -10
    
    -- Row 1: Bar Texture (left) & Healthbar Border checkbox (right)
    CreateScrollableDropdown(p2, "texture", L.Texture, ns.GetLSMTextures(), 20, y, nil, 200)
    CreateCheckBox(p2, "healthBarBorder", L.HealthBarBorder, 260, y - 18)
    
    -- Row 2: Background Alpha (left) & Non-Target Alpha (right)
    CreateSlider(p2, "backgroundAlpha", L.BackgroundAlpha, 0, 1, 20, y - 55, true, nil, "%", 100)
    CreateAlphaCVarSlider(p2, "nonTargetAlpha", nil, L.NonTargetAlpha, 260, y - 55, L.NonTargetAlphaDesc)
    
    -- Row 3: Width & Height sliders
    CreateSlider(p2, "width", L.Width, 50, 250, 20, y - 110, false, nil, "px")
    CreateSlider(p2, "hpHeight", L.HpHeight, 5, 50, 260, y - 110, false, nil, "px")
    
    -- Row 4: Scale & Target Scale sliders (display as percentage)
    CreateSlider(p2, "scale", L.Scale, 0.5, 2.5, 20, y - 165, true, nil, "%", 100)
    CreateSlider(p2, "targetScale", L.TargetScale, 0.5, 2.5, 260, y - 165, true, nil, "%", 100)
    
    -- Row 5: Friendly Scale & Pet Scale (display as percentage)
    CreateSlider(p2, "friendlyScale", L.FriendlyScale, 0.5, 2.5, 20, y - 220, true, nil, "%", 100)
    CreateSlider(p2, "petScale", L.PetScale, 0.3, 1.5, 260, y - 220, true, nil, "%", 100)
    
    -- Row 6: Raid Marker Anchor & Raid Marker Size
    local anchorOpts = {{name = "Left", value = "LEFT"}, {name = "Right", value = "RIGHT"}, {name = "Top (Above Name)", value = "TOP"}}
    CreateDropdown(p2, "raidMarkerAnchor", L.RaidMarkerAnchor, anchorOpts, 20, y - 275)
    
    -- Row 7: Raid Marker Size & Raid Marker Y
    CreateSlider(p2, "raidMarkerSize", L.RaidMarkerSize, 10, 40, 260, y - 275, false, nil, "px")
    CreateSlider(p2, "raidMarkerY", L.RaidMarkerY, -50, 50, 20, y - 330, false, nil, "px")
    
    -- Row 8: Raid Marker X
    CreateSlider(p2, "raidMarkerX", L.RaidMarkerX, -50, 50, 260, y - 330, false, nil, "px")
    
    -- TAB 3: Fonts
    local p3 = guiPage[3]
    y = -10
    
    -- Row 1: Font dropdowns
    CreateScrollableDropdown(p3, "font", L.Font, ns.GetLSMFonts(), 20, y, nil, 200)
    CreateDropdown(p3, "fontOutline", L.FontOutline, ns.Outlines, 260, y)
    
    -- Row 2: Font size slider and name display format
    CreateSlider(p3, "fontSize", L.FontSize, 8, 24, 20, y - 50, false, nil, "pt")
    CreateDropdown(p3, "nameDisplayFormat", L.NameDisplayFormat, ns.NameFormats, 260, y - 50)
    
    -- Row 3: Friendly & Guild font sizes
    CreateSlider(p3, "friendlyFontSize", L.FriendlyFontSize, 8, 24, 20, y - 105, false, nil, "pt")
    CreateSlider(p3, "guildFontSize", L.GuildFontSize, 8, 24, 260, y - 105 , false, nil, "pt")
    
    -- Row 4: Health Value Format dropdown and font size
    CreateDropdown(p3, "healthValueFormat", L.HealthValueFormat, ns.HealthFormats, 20, y - 155)
    CreateSlider(p3, "healthValueFontSize", L.HealthValueFontSize, 6, 18, 260, y - 155, false, nil, "pt")
    
    -- Row 5: Name in healthbar checkbox and Hide % When Full checkbox
    CreateCheckBox(p3, "nameInHealthbar", L.NameInHealthbar, 20, y - 205)
    CreateCheckBox(p3, "hidePercentWhenFull", L.HidePercentWhenFull, 260, y - 205)
    
    -- Level Indicator dropdown
    local levelModeOpts = {
        {name = L.LevelIndicatorDisabled, value = "disabled"},
        {name = L.LevelIndicatorEnemies, value = "enemies"},
        {name = L.LevelIndicatorAll, value = "all"},
    }
    CreateDropdown(p3, "levelMode", L.LevelIndicator, levelModeOpts, 20, y - 235)
    
    -- Classification Icon dropdown (anchor position)
    local classificationAnchorOpts = {
        {name = L.ClassificationDisabled, value = "disabled"},
        {name = L.ClassificationTopLeft, value = "TOPLEFT"},
        {name = L.ClassificationTopRight, value = "TOPRIGHT"},
        {name = L.ClassificationTop, value = "TOP"},
        {name = L.ClassificationBottom, value = "BOTTOM"},
        {name = L.ClassificationBottomLeft, value = "BOTTOMLEFT"},
        {name = L.ClassificationBottomRight, value = "BOTTOMRIGHT"},
    }
    CreateDropdown(p3, "classificationAnchor", L.ClassificationAnchor, classificationAnchorOpts, 260, y - 235)
    
    -- Threat Text Display dropdown
    local threatTextAnchorOpts = {
        {name = L.ThreatTextDisabled, value = "disabled"},
        {name = L.ThreatTextRightHP, value = "right_hp"},
        {name = L.ThreatTextLeftHP, value = "left_hp"},
        {name = L.ThreatTextBelowHP, value = "below_hp"},
        {name = L.ThreatTextTopHP, value = "top_hp"},
        {name = L.ThreatTextLeftName, value = "left_name"},
        {name = L.ThreatTextRightName, value = "right_name"},
    }
    CreateDropdown(p3, "threatTextAnchor", L.ThreatTextAnchor, threatTextAnchorOpts, 20, y - 290)
    CreateSlider(p3, "threatTextFontSize", L.ThreatTextFontSize, 6, 18, 260, y - 290, false, nil, "pt")
    
    -- Threat Text offset sliders
    CreateSlider(p3, "threatTextOffsetX", L.ThreatTextXOffset, -20, 20, 20, y - 340, false, nil, "px")
    CreateSlider(p3, "threatTextOffsetY", L.ThreatTextYOffset, -20, 20, 260, y - 340, false, nil, "px")
    
    -- TAB 4: Colors
    local p4 = guiPage[4]
    y = -10
    
    -- Base healthbar colors section
    CreateFS(p4, 12, L.BaseColors, "system", "TOPLEFT", 20, y)
    CreateColorSwatch(p4, "hpColor", L.HpColor, 20, y - 25)
    CreateColorSwatch(p4, "hostileNameColor", L.EnemyNameColor, 150, y - 25)
    CreateColorSwatch(p4, "petColor", L.PetColor, 280, y - 25)
    CreateColorSwatch(p4, "tappedColor", L.TappedColor, 410, y - 25)
    
    -- Castbar colors section
    CreateFS(p4, 12, L.CastbarColors, "system", "TOPLEFT", 20, y - 70)
    CreateColorSwatch(p4, "castColor", L.CastColor, 20, y - 95)
    CreateColorSwatch(p4, "noInterruptColor", L.NoInterruptColor, 150, y - 95)
    CreateColorSwatch(p4, "highlightGlowColor", L.HighlightGlowColor, 280, y - 95)
    
    -- Tank colors section
    CreateFS(p4, 12, L.TankColors, "system", "TOPLEFT", 20, y - 140)
    CreateColorSwatch(p4, "secureColor", L.SecureColor, 20, y - 165)
    CreateColorSwatch(p4, "transColor", L.TransColor, 150, y - 165)
    CreateColorSwatch(p4, "insecureColor", L.InsecureColor, 280, y - 165)
    CreateColorSwatch(p4, "offTankColor", L.OffTankColor, 410, y - 165)
    
    -- DPS colors section
    CreateFS(p4, 12, L.DpsColors, "system", "TOPLEFT", 20, y - 205)
    CreateColorSwatch(p4, "dpsSecureColor", L.DpsSecureColor, 20, y - 230)
    CreateColorSwatch(p4, "dpsTransColor", L.DpsTransColor, 150, y - 230)
    CreateColorSwatch(p4, "dpsAggroColor", L.DpsAggroColor, 280, y - 230)
    
    -- Target/PvP colors section
    CreateFS(p4, 12, L.TargetPvPColors or "Target/PvP Colors:", "system", "TOPLEFT", 20, y - 275)
    CreateColorSwatch(p4, "targetGlowColor", L.TargetGlowColor, 20, y - 300)
    CreateColorSwatch(p4, "targetingMeColor", L.TargetingMeColor, 150, y - 300)
    
    -- Aura Border colors section (note: uses auras table, needs special handling)
    CreateFS(p4, 12, L.AuraColors or "Aura Border Colors:", "system", "TOPLEFT", 20, y - 340)
    
    -- Debuff border color swatch (reads/writes from TurboPlatesDB.auras.debuffBorderColor)
    local debuffBorderSwatch = CreateFrame("Button", nil, p4, "BackdropTemplate")
    debuffBorderSwatch:SetSize(18, 18)
    debuffBorderSwatch:SetPoint("TOPLEFT", 20, y - 365)
    CreateBD(debuffBorderSwatch, 1)
    local debuffTex = debuffBorderSwatch:CreateTexture(nil, "OVERLAY")
    debuffTex:SetPoint("TOPLEFT", 0, 0)
    debuffTex:SetPoint("BOTTOMRIGHT", 0, 0)
    debuffTex:SetTexture(bdTex)
    debuffBorderSwatch.tex = debuffTex
    debuffBorderSwatch.label = CreateFS(debuffBorderSwatch, 12, L.DebuffBorderColor or "Debuff Border", nil, "LEFT", 24, 0)
    
    local function RefreshDebuffBorderColor()
        local c = TurboPlatesDB.auras and TurboPlatesDB.auras.debuffBorderColor
        if not c or not c.r then c = ns.defaults.auras and ns.defaults.auras.debuffBorderColor or {r=1,g=0.2,b=0.2} end
        debuffTex:SetVertexColor(c.r, c.g, c.b)
    end
    
    debuffBorderSwatch:SetScript("OnClick", function()
        local c = TurboPlatesDB.auras and TurboPlatesDB.auras.debuffBorderColor
        if not c or not c.r then c = ns.defaults.auras and ns.defaults.auras.debuffBorderColor or {r=1,g=0.2,b=0.2} end
        local prevR, prevG, prevB = c.r, c.g, c.b
        
        ColorPickerFrame.func = nil
        ColorPickerFrame.cancelFunc = nil
        ColorPickerFrame:Hide()
        ColorPickerFrame:SetColorRGB(prevR, prevG, prevB)
        ColorPickerFrame.previousValues = {r = prevR, g = prevG, b = prevB}
        
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras.debuffBorderColor = {r = r, g = g, b = b}
            debuffTex:SetVertexColor(r, g, b)
            if ns.CacheAuraSettings then ns:CacheAuraSettings() end
            UpdateAll()
        end
        ColorPickerFrame.cancelFunc = function()
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras.debuffBorderColor = {r = prevR, g = prevG, b = prevB}
            debuffTex:SetVertexColor(prevR, prevG, prevB)
            if ns.CacheAuraSettings then ns:CacheAuraSettings() end
            UpdateAll()
        end
        ColorPickerFrame:Show()
    end)
    debuffBorderSwatch:SetScript("OnShow", RefreshDebuffBorderColor)
    RefreshDebuffBorderColor()
    
    -- Buff border color swatch (reads/writes from TurboPlatesDB.auras.buffBorderColor)
    local buffBorderSwatch = CreateFrame("Button", nil, p4, "BackdropTemplate")
    buffBorderSwatch:SetSize(18, 18)
    buffBorderSwatch:SetPoint("TOPLEFT", 150, y - 365)
    CreateBD(buffBorderSwatch, 1)
    local buffTex = buffBorderSwatch:CreateTexture(nil, "OVERLAY")
    buffTex:SetPoint("TOPLEFT", 0, 0)
    buffTex:SetPoint("BOTTOMRIGHT", 0, 0)
    buffTex:SetTexture(bdTex)
    buffBorderSwatch.tex = buffTex
    buffBorderSwatch.label = CreateFS(buffBorderSwatch, 12, L.BuffBorderColor or "Buff Border", nil, "LEFT", 24, 0)
    
    local function RefreshBuffBorderColor()
        local c = TurboPlatesDB.auras and TurboPlatesDB.auras.buffBorderColor
        if not c or not c.r then c = ns.defaults.auras and ns.defaults.auras.buffBorderColor or {r=0.2,g=0.8,b=0.2} end
        buffTex:SetVertexColor(c.r, c.g, c.b)
    end
    
    buffBorderSwatch:SetScript("OnClick", function()
        local c = TurboPlatesDB.auras and TurboPlatesDB.auras.buffBorderColor
        if not c or not c.r then c = ns.defaults.auras and ns.defaults.auras.buffBorderColor or {r=0.2,g=0.8,b=0.2} end
        local prevR, prevG, prevB = c.r, c.g, c.b
        
        ColorPickerFrame.func = nil
        ColorPickerFrame.cancelFunc = nil
        ColorPickerFrame:Hide()
        ColorPickerFrame:SetColorRGB(prevR, prevG, prevB)
        ColorPickerFrame.previousValues = {r = prevR, g = prevG, b = prevB}
        
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras.buffBorderColor = {r = r, g = g, b = b}
            buffTex:SetVertexColor(r, g, b)
            if ns.CacheAuraSettings then ns:CacheAuraSettings() end
            UpdateAll()
        end
        ColorPickerFrame.cancelFunc = function()
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras.buffBorderColor = {r = prevR, g = prevG, b = prevB}
            buffTex:SetVertexColor(prevR, prevG, prevB)
            if ns.CacheAuraSettings then ns:CacheAuraSettings() end
            UpdateAll()
        end
        ColorPickerFrame:Show()
    end)
    buffBorderSwatch:SetScript("OnShow", RefreshBuffBorderColor)
    RefreshBuffBorderColor()

    -- TAB 5: Castbar
    local p5 = guiPage[5]
    y = -10
    
    -- Left column: checkboxes and slider
    CreateCheckBox(p5, "showCastbar", L.ShowCastbar, 20, y)
    CreateCheckBox(p5, "showCastIcon", L.ShowCastIcon, 20, y - 30)
    CreateCheckBox(p5, "showCastSpark", L.ShowCastSpark, 20, y - 60)
    CreateCheckBox(p5, "showCastTimer", L.ShowCastTimer, 20, y - 90)
    CreateSlider(p5, "castHeight", L.CastHeight, 5, 50, 20, y - 120, false, nil, "px")
    
    -- Highlight Glow checkbox with tooltip
    local hlGlowCB = CreateCheckBox(p5, "highlightGlowEnabled", L.EnableHighlightGlow, 20, y - 180)
    hlGlowCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.EnableHighlightGlow, 1, 1, 1)
        GameTooltip:AddLine(L.EnableHighlightGlowTip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    hlGlowCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Highlight Glow sliders
    CreateSlider(p5, "highlightGlowLines", L.HighlightGlowLines, 1, 16, 20, y - 210, false, nil, "")
    CreateSlider(p5, "highlightGlowFrequency", L.HighlightGlowFrequency, -2, 2, 20, y - 255, true, nil, "")
    CreateSlider(p5, "highlightGlowLength", L.HighlightGlowLength, 1, 30, 20, y - 300, false, nil, "px")
    CreateSlider(p5, "highlightGlowThickness", L.HighlightGlowThickness, 1, 10, 20, y - 345, false, nil, "px")
    
    -- Right column: Highlighted Spells List
    local hlHeader = CreateFS(p5, 13, L.HighlightSpells, "system", "TOPLEFT", 260, y)
    
    -- Input editbox for Spell ID
    local hlInputBox = CreateFrame("EditBox", nil, p5, "BackdropTemplate")
    hlInputBox:SetSize(130, 22)
    hlInputBox:SetPoint("TOPLEFT", 260, y - 22)
    hlInputBox:SetFont(GUI_FONT, 11, "")
    hlInputBox:SetAutoFocus(false)
    hlInputBox:SetNumeric(true)
    hlInputBox:SetMaxLetters(10)
    CreateBD(hlInputBox, 0.3)
    hlInputBox.__border:SetColor(0.3, 0.3, 0.3, 1)
    hlInputBox:SetTextInsets(6, 6, 0, 0)
    hlInputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    hlInputBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    
    -- Placeholder text
    local hlPlaceholder = hlInputBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hlPlaceholder:SetPoint("LEFT", 6, 0)
    hlPlaceholder:SetText("Spell ID")
    hlPlaceholder:SetTextColor(0.5, 0.5, 0.5)
    hlInputBox:SetScript("OnEditFocusGained", function() hlPlaceholder:Hide() end)
    hlInputBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then hlPlaceholder:Show() end
    end)
    
    -- Add button
    local hlAddBtn = CreateButton(p5, 60, 22, L.AddSpell)
    hlAddBtn:SetPoint("LEFT", hlInputBox, "RIGHT", 5, 0)
    hlAddBtn:SetFrameLevel(p5:GetFrameLevel() + 50)
    
    -- Spell preview
    local hlPreview = CreateFrame("Frame", nil, p5)
    hlPreview:SetSize(200, 24)
    hlPreview:SetPoint("TOPLEFT", 260, y - 48)
    
    local hlPreviewIcon = hlPreview:CreateTexture(nil, "ARTWORK")
    hlPreviewIcon:SetSize(20, 20)
    hlPreviewIcon:SetPoint("LEFT", 0, 0)
    hlPreviewIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    local hlPreviewIconBorder = CreateFrame("Frame", nil, hlPreview, "BackdropTemplate")
    hlPreviewIconBorder:SetSize(22, 22)
    hlPreviewIconBorder:SetPoint("CENTER", hlPreviewIcon, "CENTER")
    CreateBD(hlPreviewIconBorder, 0)
    
    local hlPreviewName = CreateFS(hlPreview, 11, "", nil, "LEFT", 26, 0)
    hlPreview:Hide()
    
    hlInputBox:SetScript("OnTextChanged", function(self)
        local spellID = tonumber(self:GetText())
        if spellID and spellID > 0 then
            local name, _, icon = GetSpellInfo(spellID)
            if name and icon then
                hlPreviewIcon:SetTexture(icon)
                hlPreviewName:SetText(name)
                hlPreview:Show()
                return
            end
        end
        hlPreview:Hide()
    end)
    
    -- Scrollable list area
    local hlListBg = CreateFrame("Frame", nil, p5, "BackdropTemplate")
    hlListBg:SetSize(200, 310)
    hlListBg:SetPoint("TOPLEFT", 260, y - 75)
    CreateBD(hlListBg, 0.25)
    
    local hlScrollFrame = CreateFrame("ScrollFrame", nil, hlListBg)
    hlScrollFrame:SetPoint("TOPLEFT", 4, -4)
    hlScrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)
    
    local hlScrollChild = CreateFrame("Frame", nil, hlScrollFrame)
    hlScrollChild:SetSize(190, 1)
    hlScrollFrame:SetScrollChild(hlScrollChild)
    
    -- Custom scrollbar
    local hlScrollBar = CreateFrame("Frame", nil, hlListBg)
    hlScrollBar:SetSize(8, 300)
    hlScrollBar:SetPoint("TOPRIGHT", -2, -5)
    hlScrollBar:Hide()
    
    local hlScrollThumb = CreateFrame("Button", nil, hlScrollBar)
    hlScrollThumb:SetSize(8, 40)
    hlScrollThumb:SetPoint("TOP", 0, 0)
    local hlThumbTex = hlScrollThumb:CreateTexture(nil, "OVERLAY")
    hlThumbTex:SetAllPoints()
    hlThumbTex:SetTexture(bdTex)
    hlThumbTex:SetVertexColor(cr, cg, cb, 0.6)
    hlScrollThumb.tex = hlThumbTex
    
    hlScrollThumb:SetScript("OnEnter", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.9) end)
    hlScrollThumb:SetScript("OnLeave", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.6) end)
    
    local function HlScrollThumbOnUpdate(self)
        local _, cursorY = GetCursorPosition()
        local scale = hlScrollBar:GetEffectiveScale()
        cursorY = cursorY / scale
        local barTop = hlScrollBar:GetTop()
        local barHeight = hlScrollBar:GetHeight() - self:GetHeight()
        local offset = barTop - cursorY - self:GetHeight() / 2
        offset = max(0, min(barHeight, offset))
        local scrollMax = hlScrollFrame:GetVerticalScrollRange()
        hlScrollFrame:SetVerticalScroll(scrollMax * (offset / barHeight))
    end
    hlScrollThumb:SetScript("OnMouseDown", function(self)
        self:SetScript("OnUpdate", HlScrollThumbOnUpdate)
    end)
    hlScrollThumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    
    hlListBg:EnableMouseWheel(true)
    hlListBg:SetScript("OnMouseWheel", function(self, delta)
        local current = hlScrollFrame:GetVerticalScroll()
        local maxScroll = hlScrollFrame:GetVerticalScrollRange()
        local newScroll = current - (delta * 25)
        newScroll = max(0, min(maxScroll, newScroll))
        hlScrollFrame:SetVerticalScroll(newScroll)
    end)
    
    local function UpdateHlScrollBar()
        local scrollMax = hlScrollFrame:GetVerticalScrollRange()
        if scrollMax > 0 then
            hlScrollBar:Show()
            hlScrollChild:SetWidth(182)
            hlScrollFrame:SetPoint("BOTTOMRIGHT", -14, 4)
            local scrollCurrent = hlScrollFrame:GetVerticalScroll()
            local barHeight = hlScrollBar:GetHeight() - hlScrollThumb:GetHeight()
            local thumbOffset = (scrollCurrent / scrollMax) * barHeight
            hlScrollThumb:SetPoint("TOP", 0, -thumbOffset)
        else
            hlScrollBar:Hide()
            hlScrollChild:SetWidth(190)
            hlScrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)
        end
    end
    
    hlScrollFrame:SetScript("OnScrollRangeChanged", UpdateHlScrollBar)
    hlScrollFrame:SetScript("OnVerticalScroll", UpdateHlScrollBar)
    
    local hlBars = {}
    local hlEmptyText
    
    local function RefreshHighlightList()
        for _, bar in pairs(hlBars) do bar:Hide() end
        
        local list = TurboPlatesDB.highlightSpells or {}
        local index = 0
        
        for spellID in pairs(list) do
            index = index + 1
            local bar = hlBars[index]
            
            if not bar then
                bar = CreateFrame("Frame", nil, hlScrollChild, "BackdropTemplate")
                bar:SetHeight(24)
                bar:SetPoint("LEFT", 0, 0)
                bar:SetPoint("RIGHT", 0, 0)
                CreateBD(bar, 0.2)
                
                -- Icon with border frame
                local iconFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
                PixelUtil.SetSize(iconFrame, 18, 18)
                iconFrame:SetPoint("LEFT", 3, 0)
                CreateBD(iconFrame, 0)
                
                local icon = iconFrame:CreateTexture(nil, "ARTWORK")
                local inset = PixelUtil.GetNearestPixelSize(1, iconFrame:GetEffectiveScale(), 1)
                icon:SetPoint("TOPLEFT", inset, -inset)
                icon:SetPoint("BOTTOMRIGHT", -inset, inset)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                bar.icon = icon
                
                local nameFS = CreateFS(bar, 10, "", nil, "LEFT", 26, 0)
                nameFS:SetWidth(110)
                nameFS:SetJustifyH("LEFT")
                bar.nameFS = nameFS
                
                local idFS = CreateFS(bar, 9, "", nil, "RIGHT", -24, 0)
                idFS:SetTextColor(0.5, 0.5, 0.5)
                bar.idFS = idFS
                
                local removeBtn = CreateFrame("Button", nil, bar)
                removeBtn:SetSize(14, 14)
                removeBtn:SetPoint("RIGHT", -4, 0)
                removeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
                removeBtn:GetNormalTexture():SetVertexColor(0.8, 0.2, 0.2)
                removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
                removeBtn:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3)
                bar.removeBtn = removeBtn
                
                bar:SetScript("OnEnter", function(self)
                    if self.spellID then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetSpellByID(self.spellID)
                        GameTooltip:Show()
                    end
                end)
                bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
                
                hlBars[index] = bar
            end
            
            local name, _, icon = GetSpellInfo(spellID)
            bar.spellID = spellID
            bar.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            bar.nameFS:SetText(name or "Unknown")
            bar.idFS:SetText(tostring(spellID))
            bar:ClearAllPoints()
            -- Calculate pixel-perfect offset
            local scale = hlScrollChild:GetEffectiveScale()
            local spacing = PixelUtil.GetNearestPixelSize(25, scale, 1)
            local yOffset = -(index - 1) * spacing
            bar:SetPoint("TOPLEFT", hlScrollChild, "TOPLEFT", 0, yOffset)
            bar:SetPoint("TOPRIGHT", hlScrollChild, "TOPRIGHT", 0, yOffset)
            bar:Show()
            
            bar.removeBtn:SetScript("OnClick", function()
                PlaySound(856)
                local removedName = GetSpellInfo(spellID)
                if TurboPlatesDB.highlightSpells then
                    TurboPlatesDB.highlightSpells[spellID] = nil
                    ns.c_highlightSpells = TurboPlatesDB.highlightSpells
                    -- Rebuild name cache
                    ns.c_highlightSpellNames = {}
                    for sid in pairs(ns.c_highlightSpells) do
                        local sname = GetSpellInfo(sid)
                        if sname then ns.c_highlightSpellNames[sname] = true end
                    end
                end
                RefreshHighlightList()
                if removedName then
                    print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Removed from Highlight List - " .. removedName)
                end
            end)
        end
        
        hlScrollChild:SetHeight(math.max(1, index * 25))
        
        if index == 0 then
            if not hlEmptyText then
                hlEmptyText = CreateFS(hlScrollChild, 11, L.NoHighlightSpells, nil, "TOP", 0, -15)
                hlEmptyText:SetTextColor(0.5, 0.5, 0.5)
            end
            hlEmptyText:Show()
        elseif hlEmptyText then
            hlEmptyText:Hide()
        end
    end
    
    hlAddBtn:SetScript("OnClick", function()
        PlaySound(856)
        local spellID = tonumber(hlInputBox:GetText())
        if not spellID or spellID <= 0 then
            print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: " .. L.InvalidSpellID)
            return
        end
        
        local name = GetSpellInfo(spellID)
        if not name then
            print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: " .. L.InvalidSpellID)
            return
        end
        
        if not TurboPlatesDB.highlightSpells then TurboPlatesDB.highlightSpells = {} end
        if TurboPlatesDB.highlightSpells[spellID] then
            print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Spell already in Highlight List")
            return
        end
        
        TurboPlatesDB.highlightSpells[spellID] = true
        ns.c_highlightSpells = TurboPlatesDB.highlightSpells
        -- Update name cache
        if not ns.c_highlightSpellNames then ns.c_highlightSpellNames = {} end
        ns.c_highlightSpellNames[name] = true
        
        hlInputBox:SetText("")
        hlPreview:Hide()
        RefreshHighlightList()
        print("|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r: Added to Highlight List - " .. name)
    end)
    
    hlInputBox:HookScript("OnEnterPressed", function() hlAddBtn:Click() end)
    p5:HookScript("OnShow", RefreshHighlightList)
    
    -- AURA HELPER FUNCTIONS (used by both Debuffs and Buffs tabs)
    -- Note: p6 is needed for CreateAuraCheckBox parent initialization
    local p6 = guiPage[6]
    y = -10
    
    -- Helper function for nested auras settings (checkbox)
    local function CreateAuraCheckBox(parent, var, label, x, y, callback)
        local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
        chk:SetSize(16, 16)
        chk:SetPoint("TOPLEFT", x, y)
        chk:SetNormalTexture("")
        chk:SetPushedTexture("")
        
        local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetFrameLevel(chk:GetFrameLevel())
        CreateBD(bg, 0.3)
        CreateGradient(bg)
        chk.bg = bg
        
        chk:SetHighlightTexture(bdTex)
        local hl = chk:GetHighlightTexture()
        hl:SetAllPoints(bg)
        hl:SetVertexColor(cr, cg, cb, 0.25)
        
        local check = chk:CreateTexture(nil, "OVERLAY")
        check:SetSize(20, 20)
        check:SetPoint("CENTER")
        check:SetAtlas("questlog-icon-checkmark-yellow-2x")
        check:SetVertexColor(1, 0.82, 0)
        chk:SetCheckedTexture(check)
        
        chk.label = CreateFS(chk, 13, label, nil, "LEFT", 24, 0)
        chk:SetHitRectInsets(0, -chk.label:GetStringWidth()-10, 0, 0)
        
        local function GetVal()
            return TurboPlatesDB.auras and TurboPlatesDB.auras[var]
        end
        local function SetVal(v)
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras[var] = v
        end
        
        chk:SetChecked(GetVal())
        chk:SetScript("OnClick", function(self)
            SetVal(self:GetChecked() and true or false)
            if ns.CacheAuraSettings then ns:CacheAuraSettings() end
            UpdateAll()
            if callback then callback(self) end
        end)
        chk:SetScript("OnShow", function(self) self:SetChecked(GetVal()) end)
        return chk
    end
    
    -- Helper function for nested auras settings (slider)
    -- zeroText: if set, display this text when value is 0 (e.g., "Unlimited" for max duration)
    local auraSliderCount = 0
    local function CreateAuraSlider(parent, var, label, minVal, maxVal, x, y, isFloat, callback, suffix, zeroText)
        auraSliderCount = auraSliderCount + 1
        suffix = suffix or ""
        
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(220, 50)
        frame:SetPoint("TOPLEFT", x, y)
        
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(GUI_FONT, 12, "")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(label)
        title:SetTextColor(1, 0.8, 0)
        
        local sliderBg = CreateFrame("Frame", nil, frame)
        sliderBg:SetSize(220, 8)
        sliderBg:SetPoint("TOPLEFT", 0, -18)
        
        local sliderBgTex = sliderBg:CreateTexture(nil, "BACKGROUND")
        sliderBgTex:SetAllPoints()
        sliderBgTex:SetTexture(bdTex)
        sliderBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        sliderBg.__border = CreateTextureBorder(sliderBg, 1)
        sliderBg.__border:SetColor(0.3, 0.3, 0.3, 1)
        
        local slider = CreateFrame("Slider", "TurboPlatesAuraSlider"..auraSliderCount, sliderBg)
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(220, 16)
        slider:SetPoint("CENTER", sliderBg, "CENTER", 0, 0)
        slider:SetThumbTexture(bdTex)
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(12, 12)
        thumb:SetVertexColor(cr, cg, cb)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(isFloat and 0.1 or 1)
        slider:EnableMouse(true)
        slider:EnableMouseWheel(true)
        
        local low = frame:CreateFontString(nil, "OVERLAY")
        low:SetFont(GUI_FONT, 10, "")
        low:SetPoint("TOPLEFT", sliderBg, "BOTTOMLEFT", 0, -2)
        low:SetText(zeroText or (tostring(minVal) .. suffix))
        low:SetTextColor(0.6, 0.6, 0.6)
        
        local high = frame:CreateFontString(nil, "OVERLAY")
        high:SetFont(GUI_FONT, 10, "")
        high:SetPoint("TOPRIGHT", sliderBg, "BOTTOMRIGHT", 0, -2)
        high:SetText(tostring(maxVal) .. suffix)
        high:SetTextColor(0.6, 0.6, 0.6)
        
        local valueText = frame:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(GUI_FONT, 12, "")
        valueText:SetPoint("TOP", sliderBg, "BOTTOM", 0, -2)
        
        local function GetVal()
            local v = TurboPlatesDB.auras and TurboPlatesDB.auras[var]
            if v == nil then v = ns.defaults.auras and ns.defaults.auras[var] or minVal end
            return v
        end
        local function SetVal(v)
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras[var] = v
        end
        local function FormatValue(v)
            if zeroText and v == 0 then return zeroText end
            if isFloat then return string.format("%.1f", v) .. suffix
            else return tostring(math.floor(v + 0.5)) .. suffix end
        end
        
        slider:SetValue(GetVal())
        valueText:SetText(FormatValue(GetVal()))
        
        slider:SetScript("OnValueChanged", function(self, v)
            if isFloat then v = math.floor(v * 10 + 0.5) / 10 else v = math.floor(v + 0.5) end
            SetVal(v)
            valueText:SetText(FormatValue(v))
            if ns.CacheAuraSettings then ns:CacheAuraSettings() end
            UpdateAll()
            if callback then callback(self, v) end
        end)
        slider:SetScript("OnMouseWheel", function(self, delta)
            local step = isFloat and 0.1 or 1
            local newVal = self:GetValue() + (delta * step)
            newVal = math.max(minVal, math.min(maxVal, newVal))
            self:SetValue(newVal)
        end)
        slider:SetScript("OnShow", function(self)
            local v = GetVal()
            self:SetValue(v)
            valueText:SetText(FormatValue(v))
        end)
        
        frame.slider = slider
        return frame
    end
    
    -- Helper function for nested auras settings (dropdown)
    local auraDropdownCount = 0
    local function CreateAuraDropdown(parent, var, label, options, x, y, callback)
        auraDropdownCount = auraDropdownCount + 1
        
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(220, 50)
        frame:SetPoint("TOPLEFT", x, y)
        
        -- Only create title if label is provided
        local btnYOffset = 0
        if label and label ~= "" then
            local title = frame:CreateFontString(nil, "OVERLAY")
            title:SetFont(GUI_FONT, 12, "")
            title:SetPoint("TOPLEFT", 0, 0)
            title:SetText(label)
            title:SetTextColor(1, 0.8, 0)
            btnYOffset = -18
        end
        
        local btn = CreateFrame("Button", "TurboPlatesAuraDD"..auraDropdownCount, frame, "BackdropTemplate")
        btn:SetSize(220, 22)
        btn:SetPoint("TOPLEFT", 0, btnYOffset)
        CreateBD(btn, 0.6)
        btn.__border:SetColor(1, 1, 1, 0.2)
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(GUI_FONT, 12, "")
        text:SetPoint("LEFT", 8, 0)
        text:SetPoint("RIGHT", -22, 0)
        text:SetJustifyH("LEFT")
        btn.text = text
        
        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(14, 14)
        arrow:SetPoint("RIGHT", -5, 0)
        arrow:SetTexture(mediaPath.."arrow.tga")
        arrow:SetRotation(math.rad(180))
        btn.arrow = arrow
        
        local listName = "TurboPlatesAuraDDList"..auraDropdownCount
        local list = CreateFrame("Frame", listName, UIParent)
        list:SetFrameStrata("TOOLTIP")
        list:SetFrameLevel(200)
        list:SetClampedToScreen(true)
        
        local listBgTex = list:CreateTexture(nil, "BACKGROUND")
        listBgTex:SetAllPoints()
        listBgTex:SetTexture(bdTex)
        listBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        list.__border = CreateTextureBorder(list, 1)
        list.__border:SetColor(0.3, 0.3, 0.3, 1)
        list:Hide()
        btn.list = list
        
        local numOpts = #options
        list:SetSize(220, numOpts * 20 + 6)
        
        local function GetVal()
            return TurboPlatesDB.auras and TurboPlatesDB.auras[var]
        end
        local function SetVal(v)
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras[var] = v
        end
        
        for i, opt in ipairs(options) do
            local optBtn = CreateFrame("Button", nil, list)
            optBtn:SetSize(214, 18)
            optBtn:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 20)
            
            local optText = optBtn:CreateFontString(nil, "OVERLAY")
            optText:SetFont(GUI_FONT, 12, "")
            optText:SetPoint("LEFT", 6, 0)
            optText:SetText(opt.name)
            optBtn.text = optText
            optBtn.value = opt.value
            optBtn.name = opt.name
            
            local optBg = optBtn:CreateTexture(nil, "BACKGROUND")
            optBg:SetAllPoints()
            optBg:SetTexture(bdTex)
            optBg:SetVertexColor(1, 1, 1, 0)
            optBtn.bg = optBg
            
            optBtn:SetScript("OnEnter", function(self) self.bg:SetVertexColor(cr, cg, cb, 0.3) end)
            optBtn:SetScript("OnLeave", function(self) self.bg:SetVertexColor(1, 1, 1, 0) end)
            optBtn:SetScript("OnClick", function(self)
                SetVal(self.value)
                text:SetText(self.name)
                list:Hide()
                arrow:SetRotation(math.rad(180))
                if ns.CacheAuraSettings then ns:CacheAuraSettings() end
                UpdateAll()
                if callback then callback(self.value) end
            end)
        end
        
        btn:SetScript("OnClick", function(self)
            if list:IsShown() then
                list:Hide()
                arrow:SetRotation(math.rad(180))
            else
                list:ClearAllPoints()
                list:SetPoint("TOP", self, "BOTTOM", 0, -2)
                list:Show()
                arrow:SetRotation(math.rad(0))
            end
        end)
        btn:SetScript("OnHide", function() list:Hide() end)
        btn:SetScript("OnEnter", function(self) self.__border:SetColor(cr, cg, cb, 0.5) end)
        btn:SetScript("OnLeave", function(self) self.__border:SetColor(1, 1, 1, 0.2) end)
        
        local function Refresh()
            local current = GetVal()
            if current == nil then current = ns.defaults.auras and ns.defaults.auras[var] end
            for _, opt in ipairs(options) do
                if opt.value == current then
                    text:SetText(opt.name)
                    return
                end
            end
            if options[1] then text:SetText(options[1].name) end
        end
        
        btn:SetScript("OnShow", function() Refresh(); list:Hide() end)
        Refresh()
        
        frame.btn = btn
        return frame
    end
    
    -- Helper function for nested auras settings (color swatch)
    local function CreateAuraColorSwatch(parent, var, label, x, y, callback)
        local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
        swatch:SetSize(18, 18)
        swatch:SetPoint("TOPLEFT", x, y)
        CreateBD(swatch, 1)
        
        local tex = swatch:CreateTexture(nil, "OVERLAY")
        tex:SetPoint("TOPLEFT", 0, 0)
        tex:SetPoint("BOTTOMRIGHT", 0, 0)
        tex:SetTexture(bdTex)
        swatch.tex = tex
        
        if label then
            swatch.label = CreateFS(swatch, 12, label, nil, "LEFT", 24, 0)
        end
        
        local function GetVal()
            return TurboPlatesDB.auras and TurboPlatesDB.auras[var]
        end
        local function SetVal(c)
            if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
            TurboPlatesDB.auras[var] = c
        end
        
        local function RefreshColor()
            local c = GetVal()
            if not c or not c.r then c = ns.defaults.auras and ns.defaults.auras[var] or {r=1,g=1,b=1} end
            tex:SetVertexColor(c.r, c.g, c.b)
        end
        
        swatch:SetScript("OnClick", function()
            local c = GetVal()
            if not c or not c.r then c = ns.defaults.auras and ns.defaults.auras[var] or {r=1,g=1,b=1} end
            local prevR, prevG, prevB = c.r, c.g, c.b
            
            ColorPickerFrame.func = nil
            ColorPickerFrame.cancelFunc = nil
            ColorPickerFrame:Hide()
            ColorPickerFrame:SetColorRGB(prevR, prevG, prevB)
            ColorPickerFrame.previousValues = {r = prevR, g = prevG, b = prevB}
            
            ColorPickerFrame.func = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                SetVal({r = r, g = g, b = b})
                tex:SetVertexColor(r, g, b)
                if ns.CacheAuraSettings then ns:CacheAuraSettings() end
                UpdateAll()
                if callback then callback() end
            end
            ColorPickerFrame.cancelFunc = function()
                SetVal({r = prevR, g = prevG, b = prevB})
                tex:SetVertexColor(prevR, prevG, prevB)
                if ns.CacheAuraSettings then ns:CacheAuraSettings() end
                UpdateAll()
                if callback then callback() end
            end
            ColorPickerFrame:Show()
        end)
        swatch:SetScript("OnShow", RefreshColor)
        RefreshColor()
        return swatch
    end
    
    -- Anchor options for debuff display
    local anchorOptions = {
        { name = L.AurasAnchorLeft, value = "LEFT" },
        { name = L.AurasAnchorCenter, value = "CENTER" },
        { name = L.AurasAnchorRight, value = "RIGHT" },
    }
    
    -- Text anchor options (for duration and stack count positioning)
    local textAnchorOptions = {
        { name = L.AurasAnchorTop, value = "TOP" },
        { name = L.AurasAnchorTopLeft, value = "TOPLEFT" },
        { name = L.AurasAnchorTopRight, value = "TOPRIGHT" },
        { name = L.AurasAnchorCenter, value = "CENTER" },
        { name = L.AurasAnchorBottom, value = "BOTTOM" },
        { name = L.AurasAnchorBottomLeft, value = "BOTTOMLEFT" },
        { name = L.AurasAnchorBottomRight, value = "BOTTOMRIGHT" },
    }
    
    -- TAB 6: Debuffs (Your DoTs on enemies)
    local p6 = guiPage[6]
    y = -10
    
    -- Enable checkbox + Own Only (disabled, always checked)
    CreateAuraCheckBox(p6, "showDebuffs", L.AurasShowDebuffs, 20, y)
    
    -- Own Only checkbox (always checked, greyed out) - styled to match other checkboxes
    local ownOnlyCB = CreateFrame("CheckButton", nil, p6, "BackdropTemplate")
    ownOnlyCB:SetSize(16, 16)
    ownOnlyCB:SetPoint("TOPLEFT", 260, y)
    ownOnlyCB:SetNormalTexture("")
    ownOnlyCB:SetPushedTexture("")
    
    local ownOnlyBg = CreateFrame("Frame", nil, ownOnlyCB, "BackdropTemplate")
    ownOnlyBg:SetAllPoints()
    ownOnlyBg:SetFrameLevel(ownOnlyCB:GetFrameLevel())
    CreateBD(ownOnlyBg, 0.3)
    CreateGradient(ownOnlyBg)
    
    local ownOnlyCheck = ownOnlyCB:CreateTexture(nil, "OVERLAY")
    ownOnlyCheck:SetSize(20, 20)
    ownOnlyCheck:SetPoint("CENTER")
    ownOnlyCheck:SetAtlas("questlog-icon-checkmark-yellow-2x")
    ownOnlyCheck:SetVertexColor(1, 0.82, 0, 0.5)  -- Dimmed gold
    ownOnlyCB:SetCheckedTexture(ownOnlyCheck)
    ownOnlyCB:SetChecked(true)
    ownOnlyCB:Disable()
    ownOnlyCB:SetAlpha(0.5)
    
    local ownOnlyLabel = CreateFS(ownOnlyCB, 13, L.AurasOwnOnly, nil, "LEFT", 24, 0)
    ownOnlyLabel:SetTextColor(0.5, 0.5, 0.5)  -- Grey text
    
    -- Row 1: Max Debuffs, Icon Width
    y = y - 40
    CreateAuraSlider(p6, "maxDebuffs", L.AurasMaxDebuffs, 1, 12, 20, y, false, nil, "")
    CreateAuraSlider(p6, "debuffIconWidth", L.AurasDebuffWidth, 10, 50, 260, y, false, nil, "px")
    
    -- Row 2: Display Anchor, Icon Height
    y = y - 43
    CreateAuraDropdown(p6, "growDirection", L.AurasGrowDirection, anchorOptions, 20, y)
    CreateAuraSlider(p6, "debuffIconHeight", L.AurasDebuffHeight, 10, 50, 260, y, false, nil, "px")
    
    -- Row 3: Horizontal Offset, Vertical Offset
    y = y - 43
    CreateAuraSlider(p6, "debuffXOffset", L.AurasXOffset, -200, 200, 20, y, false, nil, "px")
    CreateAuraSlider(p6, "debuffYOffset", L.AurasYOffset, -200, 200, 260, y, false, nil, "px")
    
    -- Row 4: Icon Spacing
    y = y - 43
    CreateAuraSlider(p6, "iconSpacing", L.AurasIconSpacing, 0, 10, 20, y, false, nil, "px")
    
    -- Row 4: Timer Font Size, Stack Font Size
    y = y - 43
    CreateAuraSlider(p6, "debuffFontSize", L.AurasDebuffFontSize, 6, 16, 20, y, false, nil, "px")
    CreateAuraSlider(p6, "debuffStackFontSize", L.AurasDebuffStackFontSize, 6, 16, 260, y, false, nil, "px")
    
    -- Row 5: Timer Anchor, Stack Anchor
    y = y - 43
    CreateAuraDropdown(p6, "debuffDurationAnchor", L.AurasDurationAnchor, textAnchorOptions, 20, y)
    CreateAuraDropdown(p6, "debuffStackAnchor", L.AurasStackAnchor, textAnchorOptions, 260, y)
    
    -- Row 6: Min Duration, Max Duration
    y = y - 43
    CreateAuraSlider(p6, "minDuration", L.AurasMinDuration, 0, 30, 20, y, false, nil, "s")
    CreateAuraSlider(p6, "maxDuration", L.AurasMaxDuration, 0, 600, 260, y, false, nil, "s", L.Unlimited or "Unlimited")
    
    -- Row 7: Debuff Sorting dropdown, Border Mode dropdown
    y = y - 43
    local sortOptions = {
        { name = L.AurasSortLeastTime, value = "LEAST_TIME" },
        { name = L.AurasSortMostRecent, value = "MOST_RECENT" },
    }
    CreateAuraDropdown(p6, "debuffSortMode", L.AurasDebuffSortMode, sortOptions, 20, y)
    
    local borderOptions = {
        { name = L.AurasBorderDisabled, value = "DISABLED" },
        { name = L.AurasBorderColorCoded, value = "COLOR_CODED" },
        { name = L.AurasBorderCustom, value = "CUSTOM" },
    }
    CreateAuraDropdown(p6, "debuffBorderMode", L.AurasDebuffBorderMode, borderOptions, 260, y)
    
    -- TAB 7: Buffs (Enemy buffs you can purge/steal)
    local p7 = guiPage[7]
    y = -10
    
    -- Row 0: Enable checkbox + Filter mode dropdown
    CreateAuraCheckBox(p7, "showBuffs", L.AurasShowBuffs, 20, y)
    
    local buffFilterOptions = {
        { name = L.AurasBuffFilterOnlyDispellable, value = "ONLY_DISPELLABLE" },
        { name = L.AurasBuffFilterWhitelistDispellable, value = "WHITELIST_DISPELLABLE" },
        { name = L.AurasBuffFilterAll, value = "ALL" },
    }
    CreateAuraDropdown(p7, "buffFilterMode", "", buffFilterOptions, 260, y)
    
    -- Row 1: Max Buffs, Icon Width
    y = y - 40
    CreateAuraSlider(p7, "maxBuffs", L.AurasMaxBuffs, 1, 12, 20, y, false, nil, "")
    CreateAuraSlider(p7, "buffIconWidth", L.AurasBuffWidth, 10, 50, 260, y, false, nil, "px")
    
    -- Row 2: Buff Display Anchor, Icon Height
    y = y - 43
    CreateAuraDropdown(p7, "buffGrowDirection", L.AurasBuffGrowDirection, anchorOptions, 20, y)
    CreateAuraSlider(p7, "buffIconHeight", L.AurasBuffHeight, 10, 50, 260, y, false, nil, "px")
    
    -- Row 3: Horizontal Offset, Vertical Offset
    y = y - 43
    CreateAuraSlider(p7, "buffXOffset", L.AurasXOffset, -200, 200, 20, y, false, nil, "px")
    CreateAuraSlider(p7, "buffYOffset", L.AurasYOffset, -200, 200, 260, y, false, nil, "px")
    
    -- Row 4: Icon Spacing
    y = y - 43
    CreateAuraSlider(p7, "buffIconSpacing", L.AurasBuffIconSpacing, 0, 10, 20, y, false, nil, "px")
    
    -- Row 4: Timer Font Size, Stack Font Size
    y = y - 43
    CreateAuraSlider(p7, "buffFontSize", L.AurasBuffFontSize, 6, 16, 20, y, false, nil, "px")
    CreateAuraSlider(p7, "buffStackFontSize", L.AurasBuffStackFontSize, 6, 16, 260, y, false, nil, "px")
    
    -- Row 5: Timer Anchor, Stack Anchor
    y = y - 43
    CreateAuraDropdown(p7, "buffDurationAnchor", L.AurasDurationAnchor, textAnchorOptions, 20, y)
    CreateAuraDropdown(p7, "buffStackAnchor", L.AurasStackAnchor, textAnchorOptions, 260, y)
    
    -- Row 6: Min Duration, Max Duration
    y = y - 43
    CreateAuraSlider(p7, "buffMinDuration", L.AurasBuffMinDuration, 0, 30, 20, y, false, nil, "s")
    CreateAuraSlider(p7, "buffMaxDuration", L.AurasBuffMaxDuration, 0, 600, 260, y, false, nil, "s", L.Unlimited or "Unlimited")
    
    -- Row 7: Buff Sorting dropdown, Border Mode
    y = y - 43
    local buffSortOptions = {
        { name = L.AurasSortLeastTime, value = "LEAST_TIME" },
        { name = L.AurasSortMostRecent, value = "MOST_RECENT" },
    }
    CreateAuraDropdown(p7, "buffSortMode", L.AurasBuffSortMode, buffSortOptions, 20, y)
    
    local buffBorderOptions = {
        { name = L.AurasBorderDisabled, value = "DISABLED" },
        { name = L.AurasBorderDispellable, value = "COLOR_CODED" },
        { name = L.AurasBorderCustom, value = "CUSTOM" },
    }
    CreateAuraDropdown(p7, "buffBorderMode", L.AurasBuffBorderMode, buffBorderOptions, 260, y)
    
    -- ==========================================================================
    -- TAB 8: Personal Bar (Player's own nameplate)
    -- ==========================================================================
    local p8 = guiPage[8]
    y = -10
    
    -- Ensure personal table exists in DB
    local function EnsurePersonalDB()
        if not TurboPlatesDB.personal then TurboPlatesDB.personal = {} end
        return TurboPlatesDB.personal
    end
    
    -- Helper to create checkbox for nested personal.* settings (matches main CreateCheckBox styling)
    local function CreatePersonalCheckBox(parent, key, label, x, y, callback)
        local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
        chk:SetSize(16, 16)
        chk:SetPoint("TOPLEFT", x, y)
        chk:SetNormalTexture("")
        chk:SetPushedTexture("")
        
        local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetFrameLevel(chk:GetFrameLevel())
        CreateBD(bg, 0.3)
        CreateGradient(bg)
        chk.bg = bg
        
        chk:SetHighlightTexture(bdTex)
        local hl = chk:GetHighlightTexture()
        hl:SetAllPoints(bg)
        hl:SetVertexColor(cr, cg, cb, 0.25)
        
        local check = chk:CreateTexture(nil, "OVERLAY")
        check:SetSize(20, 20)
        check:SetPoint("CENTER")
        check:SetAtlas("questlog-icon-checkmark-yellow-2x")
        check:SetVertexColor(1, 0.82, 0)
        chk:SetCheckedTexture(check)
        
        chk.label = CreateFS(chk, 13, label, nil, "LEFT", 24, 0)
        chk:SetHitRectInsets(0, -chk.label:GetStringWidth()-10, 0, 0)
        
        local function GetVal()
            local personal = EnsurePersonalDB()
            local val = personal[key]
            if val == nil then return ns.defaults.personal[key] end
            return val
        end
        
        chk:SetChecked(GetVal())
        chk:SetScript("OnClick", function(self)
            local personal = EnsurePersonalDB()
            personal[key] = self:GetChecked() and true or false
            UpdateAll()
            if callback then callback(self) end
        end)
        chk:SetScript("OnShow", function(self) self:SetChecked(GetVal()) end)
        return chk
    end
    
    -- Helper to create slider for nested personal.* settings (matches main CreateSlider styling)
    local function CreatePersonalSlider(parent, key, label, minVal, maxVal, x, y, suffix)
        sliderCount = sliderCount + 1
        suffix = suffix or ""
        
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(220, 50)
        frame:SetPoint("TOPLEFT", x, y)
        
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(GUI_FONT, 12, "")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(label)
        title:SetTextColor(1, 0.8, 0)
        
        local sliderBg = CreateFrame("Frame", nil, frame)
        sliderBg:SetSize(220, 8)
        sliderBg:SetPoint("TOPLEFT", 0, -18)
        
        local sliderBgTex = sliderBg:CreateTexture(nil, "BACKGROUND")
        sliderBgTex:SetAllPoints()
        sliderBgTex:SetTexture(bdTex)
        sliderBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        sliderBg.__border = CreateTextureBorder(sliderBg, 1)
        sliderBg.__border:SetColor(0.3, 0.3, 0.3, 1)
        
        local slider = CreateFrame("Slider", "TurboPlatesSlider"..sliderCount, sliderBg)
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(220, 16)
        slider:SetPoint("CENTER", sliderBg, "CENTER", 0, 0)
        slider:SetThumbTexture(bdTex)
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(12, 12)
        thumb:SetVertexColor(cr, cg, cb)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(1)
        slider:EnableMouse(true)
        slider:EnableMouseWheel(true)
        
        local low = frame:CreateFontString(nil, "OVERLAY")
        low:SetFont(GUI_FONT, 10, "")
        low:SetPoint("TOPLEFT", sliderBg, "BOTTOMLEFT", 0, -2)
        low:SetText(minVal .. suffix)
        low:SetTextColor(0.6, 0.6, 0.6)
        
        local high = frame:CreateFontString(nil, "OVERLAY")
        high:SetFont(GUI_FONT, 10, "")
        high:SetPoint("TOPRIGHT", sliderBg, "BOTTOMRIGHT", 0, -2)
        high:SetText(maxVal .. suffix)
        high:SetTextColor(0.6, 0.6, 0.6)
        
        local valueText = frame:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(GUI_FONT, 12, "")
        valueText:SetPoint("TOP", sliderBg, "BOTTOM", 0, -2)
        
        local function GetVal()
            local personal = EnsurePersonalDB()
            local val = personal[key]
            if val == nil then return ns.defaults.personal[key] or minVal end
            return val
        end
        
        slider:SetValue(GetVal())
        valueText:SetText(tostring(math.floor(GetVal())) .. suffix)
        
        slider:SetScript("OnValueChanged", function(self, v)
            v = math.floor(v + 0.5)
            local personal = EnsurePersonalDB()
            personal[key] = v
            valueText:SetText(tostring(v) .. suffix)
            UpdateAll()
        end)
        
        slider:SetScript("OnMouseWheel", function(self, delta)
            local newVal = self:GetValue() + delta
            newVal = math.max(minVal, math.min(maxVal, newVal))
            self:SetValue(newVal)
        end)
        
        slider:SetScript("OnShow", function(self)
            local v = GetVal()
            self:SetValue(v)
            valueText:SetText(tostring(math.floor(v)) .. suffix)
        end)
        
        frame.slider = slider
        return frame
    end
    
    -- Helper to create dropdown for nested personal.* settings (matches main CreateDropdown styling)
    local function CreatePersonalDropdown(parent, key, label, options, x, y)
        dropdownCount = dropdownCount + 1
        
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(220, 50)
        frame:SetPoint("TOPLEFT", x, y)
        
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(GUI_FONT, 12, "")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(label)
        title:SetTextColor(1, 0.8, 0)
        
        local btn = CreateFrame("Button", "TurboPlatesPersonalDD"..dropdownCount, frame, "BackdropTemplate")
        btn:SetSize(220, 22)
        btn:SetPoint("TOPLEFT", 0, -18)
        CreateBD(btn, 0.6)
        btn.__border:SetColor(1, 1, 1, 0.2)
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(GUI_FONT, 12, "")
        text:SetPoint("LEFT", 8, 0)
        text:SetPoint("RIGHT", -22, 0)
        text:SetJustifyH("LEFT")
        btn.text = text
        
        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(14, 14)
        arrow:SetPoint("RIGHT", -5, 0)
        arrow:SetTexture(mediaPath.."arrow.tga")
        arrow:SetRotation(math.rad(180))
        btn.arrow = arrow
        
        local listName = "TurboPlatesPersonalDDList"..dropdownCount
        local list = CreateFrame("Frame", listName, UIParent)
        list:SetFrameStrata("TOOLTIP")
        list:SetFrameLevel(200)
        list:SetClampedToScreen(true)
        
        local listBgTex = list:CreateTexture(nil, "BACKGROUND")
        listBgTex:SetAllPoints()
        listBgTex:SetTexture(bdTex)
        listBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        list.__border = CreateTextureBorder(list, 1)
        list.__border:SetColor(0.3, 0.3, 0.3, 1)
        list:Hide()
        btn.list = list
        
        local numOpts = #options
        list:SetSize(220, numOpts * 20 + 6)
        
        local function GetVal()
            local personal = EnsurePersonalDB()
            local val = personal[key]
            if val == nil then return ns.defaults.personal[key] end
            return val
        end
        
        local function GetDisplayName(val)
            for _, opt in ipairs(options) do
                if opt.value == val then return opt.name end
            end
            return options[1] and options[1].name or ""
        end
        
        for i, opt in ipairs(options) do
            local optBtn = CreateFrame("Button", nil, list)
            optBtn:SetSize(214, 18)
            optBtn:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 20)
            
            local optText = optBtn:CreateFontString(nil, "OVERLAY")
            optText:SetFont(GUI_FONT, 12, "")
            optText:SetPoint("LEFT", 6, 0)
            optText:SetText(opt.name)
            optBtn.text = optText
            optBtn.value = opt.value
            optBtn.name = opt.name
            
            local optBg = optBtn:CreateTexture(nil, "BACKGROUND")
            optBg:SetAllPoints()
            optBg:SetTexture(bdTex)
            optBg:SetVertexColor(1, 1, 1, 0)
            optBtn.bg = optBg
            
            optBtn:SetScript("OnEnter", function(self) self.bg:SetVertexColor(cr, cg, cb, 0.3) end)
            optBtn:SetScript("OnLeave", function(self) self.bg:SetVertexColor(1, 1, 1, 0) end)
            optBtn:SetScript("OnClick", function(self)
                local personal = EnsurePersonalDB()
                personal[key] = self.value
                text:SetText(self.name)
                list:Hide()
                UpdateAll()
            end)
        end
        
        btn:SetScript("OnClick", function(self)
            if list:IsShown() then
                list:Hide()
                arrow:SetRotation(math.rad(180))
            else
                list:ClearAllPoints()
                list:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
                list:Show()
                arrow:SetRotation(math.rad(0))
            end
        end)
        
        btn:SetScript("OnHide", function() list:Hide() end)
        
        btn:SetScript("OnShow", function(self)
            text:SetText(GetDisplayName(GetVal()))
            list:Hide()
        end)
        
        btn:SetScript("OnEnter", function(self) self.__border:SetColor(cr, cg, cb, 0.5) end)
        btn:SetScript("OnLeave", function(self) self.__border:SetColor(1, 1, 1, 0.2) end)
        
        -- Initialize display
        text:SetText(GetDisplayName(GetVal()))
        
        frame.btn = btn
        frame.list = list
        return frame
    end
    
    -- Checkbox for Personal Bar Enable - syncs with nameplateShowPersonal CVar
    -- Keeps Interface settings and TurboPlates config in sync
    local function CreatePersonalEnableCheckBox(parent, x, y)
        local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
        chk:SetSize(16, 16)
        chk:SetPoint("TOPLEFT", x, y)
        chk:SetNormalTexture("")
        chk:SetPushedTexture("")
        
        local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetFrameLevel(chk:GetFrameLevel())
        CreateBD(bg, 0.3)
        CreateGradient(bg)
        chk.bg = bg
        
        chk:SetHighlightTexture(bdTex)
        local hl = chk:GetHighlightTexture()
        hl:SetAllPoints(bg)
        hl:SetVertexColor(cr, cg, cb, 0.25)
        
        local check = chk:CreateTexture(nil, "OVERLAY")
        check:SetSize(20, 20)
        check:SetPoint("CENTER")
        check:SetAtlas("questlog-icon-checkmark-yellow-2x")
        check:SetVertexColor(1, 0.82, 0)
        chk:SetCheckedTexture(check)
        
        chk.label = CreateFS(chk, 13, L.PersonalBarEnable, nil, "LEFT", 24, 0)
        chk:SetHitRectInsets(0, -chk.label:GetStringWidth()-10, 0, 0)
        
        -- Store CVar name for syncing (like CreateCVarCheckBox)
        chk.cvar = "nameplateShowPersonal"
        
        local function GetCVarBool(name)
            local val = GetCVar(name)
            return val and (val == "1" or val == 1)
        end
        chk.GetCVarBool = GetCVarBool
        
        chk:SetChecked(GetCVarBool("nameplateShowPersonal"))
        chk:SetScript("OnClick", function(self)
            local enabled = self:GetChecked()
            -- Update CVar (this controls whether the nameplate appears)
            SetCVar("nameplateShowPersonal", enabled and "1" or "0")
            -- Also save to our DB for consistency
            local personal = EnsurePersonalDB()
            personal.enabled = enabled and true or false
            UpdateAll()
            -- Refresh personal combo points when re-enabling personal bar
            if enabled and ns.UpdatePersonalComboPoints then
                ns:UpdatePersonalComboPoints()
            end
        end)
        chk:SetScript("OnShow", function(self)
            self:SetChecked(GetCVarBool("nameplateShowPersonal"))
        end)
        
        -- Register for CVar sync (like CreateCVarCheckBox does)
        if not ns.cvarCheckboxes then ns.cvarCheckboxes = {} end
        ns.cvarCheckboxes["nameplateShowPersonal"] = chk
        
        -- Also register a callback to sync DB when CVar changes externally
        ns.personalEnableCheckbox = chk
        
        -- Tooltip
        chk:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.PersonalBarEnable, 1, 0.8, 0)
            GameTooltip:AddLine(L.PersonalBarEnableDesc, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        chk:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        return chk
    end
    
    -- Row 1: Enable checkbox (CVar-synced) - Show Power bar checkbox
    CreatePersonalEnableCheckBox(p8, 20, y)
    CreatePersonalCheckBox(p8, "showPowerBar", L.PersonalBarShowPower, 260, y)
    
    -- Row 2: Width slider - Health Bar height slider
    y = y - 30
    CreatePersonalSlider(p8, "width", L.PersonalBarWidth or "Bar Width", 60, 200, 20, y, "")
    CreatePersonalSlider(p8, "height", L.PersonalBarHeight, 4, 30, 260, y, "")
    
    -- Row 3: Power Bar height slider - Additional Power height slider OR HERO Power Order dropdown
    y = y - 50
    CreatePersonalSlider(p8, "powerHeight", L.PersonalBarPowerHeight, 2, 20, 20, y, "")
    
    -- HERO class gets a dropdown for power bar order, others get additional power height slider
    local _, playerClass = UnitClass("player")
    if playerClass == "HERO" then
        CreatePersonalDropdown(p8, "heroPowerOrder", L.HeroPowerOrder or "Power Bar Order", ns.HeroPowerOrders, 260, y)
    else
        CreatePersonalSlider(p8, "additionalPowerHeight", L.PersonalBarAdditionalPowerHeight or "Additional Power Height", 2, 12, 260, y, "")
    end
    
    -- Row 4: Health Text Format dropdown - Power Text Format dropdown
    y = y - 50
    CreatePersonalDropdown(p8, "healthFormat", L.PersonalBarHealthFormat, ns.HealthFormats, 20, y)
    CreatePersonalDropdown(p8, "powerFormat", L.PersonalBarPowerFormat, ns.PowerFormats, 260, y)
    
    -- Row 5: Border Style dropdown - Vertical Offset slider
    y = y - 50
    CreatePersonalDropdown(p8, "borderStyle", L.PersonalBarBorderStyle or "Border Style", ns.PersonalBorderStyles, 20, y)
    CreatePersonalSlider(p8, "yOffset", L.PersonalBarYOffset, -250, 250, 260, y, "")
    
    -- Row 6: Health Bar color swatch - Threat Coloring checkbox
    y = y - 50
    do
        local swatch = CreateFrame("Button", nil, p8, "BackdropTemplate")
        swatch:SetSize(18, 18)
        swatch:SetPoint("TOPLEFT", 20, y)
        CreateBD(swatch, 1)
        
        local tex = swatch:CreateTexture(nil, "OVERLAY")
        tex:SetPoint("TOPLEFT", 0, 0)
        tex:SetPoint("BOTTOMRIGHT", 0, 0)
        tex:SetTexture(bdTex)
        swatch.tex = tex
        
        swatch.label = CreateFS(swatch, 12, L.PersonalBarHealthColor or "Health Bar Color", nil, "LEFT", 24, 0)
        
        local function RefreshColor()
            local personal = EnsurePersonalDB()
            local c = personal.healthColor
            if not c or not c.r then c = ns.defaults.personal.healthColor end
            tex:SetVertexColor(c.r, c.g, c.b)
        end
        
        swatch:SetScript("OnClick", function()
            local personal = EnsurePersonalDB()
            local c = personal.healthColor
            if not c or not c.r then c = ns.defaults.personal.healthColor end
            local prevR, prevG, prevB = c.r, c.g, c.b
            
            ColorPickerFrame.func = nil
            ColorPickerFrame.cancelFunc = nil
            ColorPickerFrame:Hide()
            ColorPickerFrame:SetColorRGB(prevR, prevG, prevB)
            ColorPickerFrame.previousValues = {r = prevR, g = prevG, b = prevB}
            
            ColorPickerFrame.func = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local personal = EnsurePersonalDB()
                personal.healthColor = {r = r, g = g, b = b}
                tex:SetVertexColor(r, g, b)
                UpdateAll()
            end
            ColorPickerFrame.cancelFunc = function()
                local personal = EnsurePersonalDB()
                personal.healthColor = {r = prevR, g = prevG, b = prevB}
                tex:SetVertexColor(prevR, prevG, prevB)
                UpdateAll()
            end
            ColorPickerFrame:Show()
        end)
        swatch:SetScript("OnShow", RefreshColor)
        RefreshColor()
    end
    CreatePersonalCheckBox(p8, "useClassColor", L.PersonalBarUseClassColor or "Color by Class", 260, y)
    
    -- Row 7: Show Buffs checkbox - Show Debuffs checkbox
    y = y - 30
    CreatePersonalCheckBox(p8, "showBuffs", L.PersonalBarShowBuffs, 20, y)
    CreatePersonalCheckBox(p8, "showDebuffs", L.PersonalBarShowDebuffs, 260, y)
    
    -- Row 8: Buffs X Position - Buffs Y Position
    y = y - 30
    CreatePersonalSlider(p8, "buffXOffset", L.PersonalBarBuffXOffset or "Buffs X Position", -200, 200, 20, y, "px")
    CreatePersonalSlider(p8, "buffYOffset", L.PersonalBarBuffYOffset or "Buffs Y Position", -200, 200, 260, y, "px")
    
    -- Row 9: Debuffs X Position - Debuffs Y Position
    y = y - 50
    CreatePersonalSlider(p8, "debuffXOffset", L.PersonalBarDebuffXOffset or "Debuffs X Position", -200, 200, 20, y, "px")
    CreatePersonalSlider(p8, "debuffYOffset", L.PersonalBarDebuffYOffset or "Debuffs Y Position", -200, 200, 260, y, "px")
    
    -- ==========================================================================
    -- TAB 9: CP (Combo Points)
    -- ==========================================================================
    local p9 = guiPage[9]
    y = -10
    
    local cpEnableCB = CreateCheckBox(p9, "showComboPoints", L.ShowComboPoints, 20, y, function()
        -- Clean up all combo points when disabling
        if ns.CleanupPersonalComboPoints then ns:CleanupPersonalComboPoints() end
        if ns.CleanupTargetComboPoints then ns:CleanupTargetComboPoints() end
        UpdateAll()
        -- Refresh personal combo points if enabling
        if ns.UpdatePersonalComboPoints then ns:UpdatePersonalComboPoints() end
    end)
    
    -- "Show on Personal Bar" checkbox (dependent on showComboPoints)
    local cpPersonalCB = CreateCheckBox(p9, "cpOnPersonalBar", L.CPOnPersonalBar, 260, y, function()
        -- Clean up both locations (switching modes)
        if ns.CleanupPersonalComboPoints then ns:CleanupPersonalComboPoints() end
        if ns.CleanupTargetComboPoints then ns:CleanupTargetComboPoints() end
        -- Then refresh all plates to show/hide combo points appropriately
        UpdateAll()
        -- Refresh personal combo points if switching to personal mode
        if ns.UpdatePersonalComboPoints then ns:UpdatePersonalComboPoints() end
    end)
    
    -- Grey out personal bar checkbox when combo points disabled
    local function UpdateCPPersonalState()
        local enabled = TurboPlatesDB.showComboPoints
        if enabled then
            cpPersonalCB:SetAlpha(1)
            cpPersonalCB:Enable()
        else
            cpPersonalCB:SetAlpha(0.5)
            cpPersonalCB:Disable()
        end
    end
    UpdateCPPersonalState()
    cpEnableCB:HookScript("OnClick", UpdateCPPersonalState)
    
    local cpOpts = {
        {name = L.CPStyleSquare, value = 1},
        {name = L.CPStyleRounded, value = 2}
    }
    CreateDropdown(p9, "cpStyle", L.CPStyle, cpOpts, 20, y - 40)
    CreateSlider(p9, "cpSize", L.CPSize, 4, 20, 260, y - 40, false, nil, "px")
    
    -- Nameplate position sliders
    CreateSlider(p9, "cpX", L.CPX, -50, 50, 20, y - 105, false, nil, "px")
    CreateSlider(p9, "cpY", L.CPY, -20, 20, 260, y - 105, false, nil, "px")
    
    -- Personal bar position sliders
    CreateSlider(p9, "cpPersonalX", L.CPPersonalX, -50, 50, 20, y - 170, false, nil, "px")
    CreateSlider(p9, "cpPersonalY", L.CPPersonalY, -20, 20, 260, y - 170, false, nil, "px")
    
    -- TAB 10: Objectives (Quest Icons)
    local p10 = guiPage[10]
    y = -10
    
    -- Checkboxes for quest icon types
    CreateCheckBox(p10, "showQuestNPCs", L.ShowQuestNPCs, 20, y)
    CreateCheckBox(p10, "showQuestObjectives", L.ShowQuestObjectives, 20, y - 30)
    
    -- Scale slider (50% to 200%, where 100% = 1.2x base scale)
    CreateSlider(p10, "questIconScale", L.QuestIconScale, 50, 200, 20, y - 80, false, nil, "%")
    
    -- Anchor dropdown
    CreateDropdown(p10, "questIconAnchor", L.QuestIconAnchor, ns.QuestIconAnchors, 260, y - 80)
    
    -- X/Y position sliders
    CreateSlider(p10, "questIconX", L.QuestIconX, -50, 50, 20, y - 145, false, nil, "px")
    CreateSlider(p10, "questIconY", L.QuestIconY, -50, 50, 260, y - 145, false, nil, "px")
    
    -- ==========================================================================
    -- TAB 11: Stacking (Custom nameplate stacking algorithm)
    -- ==========================================================================
    local p11 = guiPage[11]
    y = -10
    
    -- Ensure stacking table exists in DB
    local function EnsureStackingDB()
        if not TurboPlatesDB.stacking then TurboPlatesDB.stacking = {} end
        return TurboPlatesDB.stacking
    end
    
    -- Helper to create checkbox for nested stacking.* settings
    local function CreateStackingCheckBox(parent, key, label, x, y, callback)
        local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
        chk:SetSize(16, 16)
        chk:SetPoint("TOPLEFT", x, y)
        chk:SetNormalTexture("")
        chk:SetPushedTexture("")
        
        local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetFrameLevel(chk:GetFrameLevel() - 1)
        CreateBD(bg, 0.3)
        CreateGradient(bg)
        chk.bg = bg
        
        chk:SetHighlightTexture(bdTex)
        local hl = chk:GetHighlightTexture()
        hl:SetAllPoints(bg)
        hl:SetVertexColor(cr, cg, cb, 0.25)
        
        local check = chk:CreateTexture(nil, "OVERLAY")
        check:SetSize(20, 20)
        check:SetPoint("CENTER")
        check:SetAtlas("questlog-icon-checkmark-yellow-2x")
        check:SetVertexColor(1, 0.82, 0)
        chk:SetCheckedTexture(check)
        
        chk.label = CreateFS(chk, 13, label, nil, "LEFT", 24, 0)
        chk:SetHitRectInsets(0, -chk.label:GetStringWidth()-10, 0, 0)
        
        local function GetVal()
            local stacking = EnsureStackingDB()
            local val = stacking[key]
            if val == nil then return ns.defaults.stacking[key] end
            return val
        end
        
        chk:SetChecked(GetVal())
        chk:SetScript("OnClick", function(self)
            local stacking = EnsureStackingDB()
            stacking[key] = self:GetChecked() and true or false
            UpdateAll()
            if callback then callback(self) end
        end)
        chk:SetScript("OnShow", function(self) self:SetChecked(GetVal()) end)
        return chk
    end
    
    -- Helper to create slider for nested stacking.* settings with float support
    -- displayMultiplier: multiply stored value for display (e.g., 100 shows 0.65 as 65%)
    -- displayOffset: add to displayed value after multiplying (e.g., 100 shows 0 as 100%)
    local function CreateStackingSlider(parent, key, label, minVal, maxVal, x, y, isFloat, suffix, step, displayMultiplier, displayOffset)
        sliderCount = sliderCount + 1
        suffix = suffix or ""
        step = step or (isFloat and 0.01 or 1)
        displayMultiplier = displayMultiplier or 1
        displayOffset = displayOffset or 0
        
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(220, 50)
        frame:SetPoint("TOPLEFT", x, y)
        
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(GUI_FONT, 12, "")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(label)
        title:SetTextColor(1, 0.8, 0)
        
        local sliderBg = CreateFrame("Frame", nil, frame)
        sliderBg:SetSize(220, 8)
        sliderBg:SetPoint("TOPLEFT", 0, -18)
        
        local sliderBgTex = sliderBg:CreateTexture(nil, "BACKGROUND")
        sliderBgTex:SetAllPoints()
        sliderBgTex:SetTexture(bdTex)
        sliderBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        sliderBg.__border = CreateTextureBorder(sliderBg, 1)
        sliderBg.__border:SetColor(0.3, 0.3, 0.3, 1)
        
        local slider = CreateFrame("Slider", "TurboPlatesSlider"..sliderCount, sliderBg)
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(220, 16)
        slider:SetPoint("CENTER", sliderBg, "CENTER", 0, 0)
        slider:SetThumbTexture(bdTex)
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(12, 12)
        thumb:SetVertexColor(cr, cg, cb)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:EnableMouse(true)
        slider:EnableMouseWheel(true)
        
        local low = frame:CreateFontString(nil, "OVERLAY")
        low:SetFont(GUI_FONT, 10, "")
        low:SetPoint("TOPLEFT", sliderBg, "BOTTOMLEFT", 0, -2)
        local lowDisplay = minVal * displayMultiplier + displayOffset
        low:SetText((displayMultiplier > 1 and tostring(math.floor(lowDisplay)) or (isFloat and string.format("%.2f", minVal) or tostring(minVal))) .. suffix)
        low:SetTextColor(0.6, 0.6, 0.6)
        
        local high = frame:CreateFontString(nil, "OVERLAY")
        high:SetFont(GUI_FONT, 10, "")
        high:SetPoint("TOPRIGHT", sliderBg, "BOTTOMRIGHT", 0, -2)
        local highDisplay = maxVal * displayMultiplier + displayOffset
        high:SetText((displayMultiplier > 1 and tostring(math.floor(highDisplay)) or (isFloat and string.format("%.2f", maxVal) or tostring(maxVal))) .. suffix)
        high:SetTextColor(0.6, 0.6, 0.6)
        
        local valueText = frame:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(GUI_FONT, 12, "")
        valueText:SetPoint("TOP", sliderBg, "BOTTOM", 0, -2)
        
        local function GetVal()
            local stacking = EnsureStackingDB()
            local val = stacking[key]
            if val == nil then return ns.defaults.stacking[key] or minVal end
            return val
        end
        
        local function FormatValue(v)
            local displayVal = v * displayMultiplier + displayOffset
            if displayMultiplier > 1 or displayOffset ~= 0 then
                return tostring(math.floor(displayVal + 0.5)) .. suffix
            elseif isFloat then
                return string.format("%.2f", v) .. suffix
            else
                return tostring(math.floor(v + 0.5)) .. suffix
            end
        end
        
        slider:SetValue(GetVal())
        valueText:SetText(FormatValue(GetVal()))
        
        slider:SetScript("OnValueChanged", function(self, v)
            if isFloat then
                v = math.floor(v * 100 + 0.5) / 100
            else
                v = math.floor(v + 0.5)
            end
            local stacking = EnsureStackingDB()
            stacking[key] = v
            valueText:SetText(FormatValue(v))
            UpdateAll()
        end)
        
        slider:SetScript("OnMouseWheel", function(self, delta)
            local newVal = self:GetValue() + (delta * step)
            newVal = math.max(minVal, math.min(maxVal, newVal))
            self:SetValue(newVal)
        end)
        
        slider:SetScript("OnShow", function(self)
            local v = GetVal()
            self:SetValue(v)
            valueText:SetText(FormatValue(v))
        end)
        
        frame.slider = slider
        return frame
    end
    
    -- Row 1: Enable stacking
    local enableCheck = CreateStackingCheckBox(p11, "enabled", L.StackingEnable, 20, y, function()
        if ns.UpdateDBCache then ns:UpdateDBCache() end
        if ns.UpdateStacking then ns.UpdateStacking() end
    end)
    enableCheck.tooltipText = L.StackingEnableDesc
    
    -- Preset dropdown (uses existing CreateDropdown pattern but for nested stacking.preset)
    local presetOpts = {
        {name = L.StackingPresetBalanced or "Balanced", value = "balanced"},
        {name = L.StackingPresetChill or "Chill", value = "chill"},
        {name = L.StackingPresetSnappy or "Snappy", value = "snappy"},
    }
    
    -- Create preset dropdown manually to handle nested stacking.preset
    dropdownCount = dropdownCount + 1
    local presetFrame = CreateFrame("Frame", nil, p11)
    presetFrame:SetSize(180, 50)
    presetFrame:SetPoint("TOPLEFT", 260, y)
    
    local presetTitle = presetFrame:CreateFontString(nil, "OVERLAY")
    presetTitle:SetFont(GUI_FONT, 12, "")
    presetTitle:SetPoint("TOPLEFT", 0, 0)
    presetTitle:SetText(L.StackingPreset or "Behavior Preset")
    presetTitle:SetTextColor(1, 0.8, 0)
    
    local presetBtn = CreateFrame("Button", "TurboPlatesPresetDD", presetFrame, "BackdropTemplate")
    presetBtn:SetSize(180, 22)
    presetBtn:SetPoint("TOPLEFT", 0, -18)
    CreateBD(presetBtn, 0.6)
    presetBtn.__border:SetColor(1, 1, 1, 0.2)
    
    local presetText = presetBtn:CreateFontString(nil, "OVERLAY")
    presetText:SetFont(GUI_FONT, 12, "")
    presetText:SetPoint("LEFT", 8, 0)
    presetText:SetPoint("RIGHT", -22, 0)
    presetText:SetJustifyH("LEFT")
    presetBtn.text = presetText
    
    local presetArrow = presetBtn:CreateTexture(nil, "OVERLAY")
    presetArrow:SetSize(14, 14)
    presetArrow:SetPoint("RIGHT", -5, 0)
    presetArrow:SetTexture(mediaPath.."arrow.tga")
    presetArrow:SetRotation(math.rad(180))
    
    local presetList = CreateFrame("Frame", "TurboPlatesPresetDDList", UIParent)
    presetList:SetFrameStrata("TOOLTIP")
    presetList:SetFrameLevel(200)
    presetList:SetClampedToScreen(true)
    presetList:SetSize(180, #presetOpts * 20 + 6)
    
    local presetListBg = presetList:CreateTexture(nil, "BACKGROUND")
    presetListBg:SetAllPoints()
    presetListBg:SetTexture(bdTex)
    presetListBg:SetVertexColor(0.1, 0.1, 0.1, 1)
    presetList.__border = CreateTextureBorder(presetList, 1)
    presetList.__border:SetColor(0.3, 0.3, 0.3, 1)
    presetList:Hide()
    
    -- Function to apply preset and prompt reload
    local function ApplyPreset(presetKey, optName)
        local stacking = EnsureStackingDB()
        local oldPreset = stacking.preset or "balanced"
        
        if oldPreset ~= presetKey then
            -- Get preset values and apply all to DB
            local presetValues = ns.StackingPresets and ns.StackingPresets[presetKey]
            if presetValues then
                stacking.preset = presetKey
                -- Physics (spring frequencies)
                stacking.springFrequencyRaise = presetValues.springFrequencyRaise
                stacking.springFrequencyLower = presetValues.springFrequencyLower
                stacking.launchDamping = presetValues.launchDamping
                stacking.settleThreshold = presetValues.settleThreshold
                -- Layout settings
                stacking.xSpaceRatio = presetValues.xSpaceRatio
                stacking.ySpaceRatio = presetValues.ySpaceRatio
                stacking.originPosRatio = presetValues.originPosRatio
                stacking.upperBorder = presetValues.upperBorder
                -- Limits
                stacking.maxPlates = presetValues.maxPlates
            else
                stacking.preset = presetKey
            end
            
            presetText:SetText(optName)
            presetList:Hide()
            presetArrow:SetRotation(math.rad(180))
            
            -- Refresh sliders to show new preset values
            for _, child in pairs({p11:GetChildren()}) do
                if child.slider then
                    local onShow = child.slider:GetScript("OnShow")
                    if onShow then onShow(child.slider) end
                end
            end
            
            -- Prompt for reload since motion constants are local
            StaticPopupDialogs["TURBOPLATES_PRESET_RELOAD"] = {
                text = L.StackingPresetReloadPrompt or "Changing preset requires a UI reload. Reload now?",
                button1 = ACCEPT,
                button2 = CANCEL,
                OnAccept = function() ReloadUI() end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("TURBOPLATES_PRESET_RELOAD")
        else
            presetList:Hide()
            presetArrow:SetRotation(math.rad(180))
        end
    end
    
    for i, opt in ipairs(presetOpts) do
        local optBtn = CreateFrame("Button", nil, presetList)
        optBtn:SetSize(174, 18)
        optBtn:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 20)
        
        local optText = optBtn:CreateFontString(nil, "OVERLAY")
        optText:SetFont(GUI_FONT, 12, "")
        optText:SetPoint("LEFT", 6, 0)
        optText:SetText(opt.name)
        
        local optBg = optBtn:CreateTexture(nil, "BACKGROUND")
        optBg:SetAllPoints()
        optBg:SetTexture(bdTex)
        optBg:SetVertexColor(1, 1, 1, 0)
        optBtn.bg = optBg
        
        optBtn:SetScript("OnEnter", function(self) self.bg:SetVertexColor(cr, cg, cb, 0.3) end)
        optBtn:SetScript("OnLeave", function(self) self.bg:SetVertexColor(1, 1, 1, 0) end)
        optBtn:SetScript("OnClick", function() ApplyPreset(opt.value, opt.name) end)
    end
    
    presetBtn:SetScript("OnClick", function()
        if presetList:IsShown() then
            presetList:Hide()
            presetArrow:SetRotation(math.rad(180))
        else
            presetList:ClearAllPoints()
            presetList:SetPoint("TOP", presetBtn, "BOTTOM", 0, -2)
            presetList:Show()
            presetArrow:SetRotation(math.rad(0))
        end
    end)
    
    presetBtn:SetScript("OnHide", function() presetList:Hide() end)
    presetBtn:SetScript("OnEnter", function(self) self.__border:SetColor(cr, cg, cb, 0.5) end)
    presetBtn:SetScript("OnLeave", function(self) self.__border:SetColor(1, 1, 1, 0.2) end)
    
    local function RefreshPreset()
        local stacking = EnsureStackingDB()
        local current = stacking.preset or "balanced"
        for _, opt in ipairs(presetOpts) do
            if opt.value == current then
                presetText:SetText(opt.name)
                return
            end
        end
        presetText:SetText(presetOpts[1].name)
    end
    
    presetBtn:SetScript("OnShow", function() RefreshPreset(); presetList:Hide() end)
    RefreshPreset()
    
    -- Row 2: Spring Physics (animation speed)
    local springRaiseSlider = CreateStackingSlider(p11, "springFrequencyRaise", L.StackingSpringRaise, 3, 12, 20, y - 50, true, "", 0.5)
    springRaiseSlider:EnableMouse(true)
    springRaiseSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.StackingSpringRaise, 1, 0.8, 0)
        GameTooltip:AddLine(L.StackingSpringRaiseDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    springRaiseSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    local springLowerSlider = CreateStackingSlider(p11, "springFrequencyLower", L.StackingSpringLower, 2, 10, 260, y - 50, true, "", 0.5)
    springLowerSlider:EnableMouse(true)
    springLowerSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.StackingSpringLower, 1, 0.8, 0)
        GameTooltip:AddLine(L.StackingSpringLowerDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    springLowerSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Row 3: Overlap Detection (when plates stack)
    local xSpaceSlider = CreateStackingSlider(p11, "xSpaceRatio", L.StackingXSpace, 0.70, 1.30, 20, y - 110, true, "%", 0.05, 100)
    xSpaceSlider:EnableMouse(true)
    xSpaceSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.StackingXSpace, 1, 0.8, 0)
        GameTooltip:AddLine(L.StackingXSpaceDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    xSpaceSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    local ySpaceSlider = CreateStackingSlider(p11, "ySpaceRatio", L.StackingYSpace, 0.50, 1.20, 260, y - 110, true, "%", 0.05, 100)
    ySpaceSlider:EnableMouse(true)
    ySpaceSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.StackingYSpace, 1, 0.8, 0)
        GameTooltip:AddLine(L.StackingYSpaceDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ySpaceSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Row 4: Position settings
    local originSlider = CreateStackingSlider(p11, "originPosRatio", L.StackingOriginPos, -1, 1, 20, y - 170, true, "%", 0.1, 100, 100)
    originSlider:EnableMouse(true)
    originSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.StackingOriginPos, 1, 0.8, 0)
        GameTooltip:AddLine(L.StackingOriginPosDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    originSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    local topMarginSlider = CreateStackingSlider(p11, "upperBorder", L.StackingUpperBorder, 0, 100, 260, y - 170, false, "px", 5)
    topMarginSlider:EnableMouse(true)
    topMarginSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.StackingUpperBorder, 1, 0.8, 0)
        GameTooltip:AddLine(L.StackingUpperBorderDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    topMarginSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Info note about clickable area dependency
    local stackingNote = p11:CreateFontString(nil, "OVERLAY")
    stackingNote:SetFont(GUI_FONT, 11, "")
    stackingNote:SetPoint("TOPLEFT", 20, y - 230)
    stackingNote:SetText(L.StackingClickboxNote or "NB! Stacking offsets are based on Clickable Nameplate Size values (under Misc tab)")
    stackingNote:SetTextColor(0.7, 0.7, 0.7)
    
    -- ==========================================================================
    -- TAB 12: TurboDebuffs (BigDebuffs-style priority aura)
    -- ==========================================================================
    local p12 = guiPage[12]
    y = -10
    
    -- Ensure turboDebuffs table exists in DB
    local function EnsureTurboDebuffsDB()
        if not TurboPlatesDB.turboDebuffs then TurboPlatesDB.turboDebuffs = {} end
        return TurboPlatesDB.turboDebuffs
    end
    
    -- Helper to create checkbox for nested turboDebuffs.* settings
    local function CreateTDCheckBox(parent, key, label, x, y, callback)
        local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
        chk:SetSize(16, 16)
        chk:SetPoint("TOPLEFT", x, y)
        chk:SetNormalTexture("")
        chk:SetPushedTexture("")
        
        local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetFrameLevel(chk:GetFrameLevel())
        CreateBD(bg, 0.3)
        CreateGradient(bg)
        chk.bg = bg
        
        chk:SetHighlightTexture(bdTex)
        local hl = chk:GetHighlightTexture()
        hl:SetAllPoints(bg)
        hl:SetVertexColor(cr, cg, cb, 0.25)
        
        local check = chk:CreateTexture(nil, "OVERLAY")
        check:SetSize(20, 20)
        check:SetPoint("CENTER")
        check:SetAtlas("questlog-icon-checkmark-yellow-2x")
        check:SetVertexColor(1, 0.82, 0)
        chk:SetCheckedTexture(check)
        
        chk.label = CreateFS(chk, 13, label, nil, "LEFT", 24, 0)
        chk:SetHitRectInsets(0, -chk.label:GetStringWidth()-10, 0, 0)
        
        local function GetVal()
            local td = EnsureTurboDebuffsDB()
            local val = td[key]
            if val == nil then return ns.defaults.turboDebuffs[key] end
            return val
        end
        
        chk:SetChecked(GetVal())
        chk:SetScript("OnClick", function(self)
            local td = EnsureTurboDebuffsDB()
            td[key] = self:GetChecked() and true or false
            if ns.CacheTurboDebuffsSettings then ns:CacheTurboDebuffsSettings() end
            UpdateAll()
            if callback then callback(self) end
        end)
        chk:SetScript("OnShow", function(self) self:SetChecked(GetVal()) end)
        return chk
    end
    
    -- Helper to create slider for nested turboDebuffs.* settings
    local function CreateTDSlider(parent, key, label, minVal, maxVal, x, y, isFloat, suffix, step)
        sliderCount = sliderCount + 1
        suffix = suffix or ""
        step = step or (isFloat and 0.1 or 1)
        
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(220, 50)
        frame:SetPoint("TOPLEFT", x, y)
        
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(GUI_FONT, 12, "")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(label)
        title:SetTextColor(1, 0.8, 0)
        
        local sliderBg = CreateFrame("Frame", nil, frame)
        sliderBg:SetSize(220, 8)
        sliderBg:SetPoint("TOPLEFT", 0, -18)
        
        local sliderBgTex = sliderBg:CreateTexture(nil, "BACKGROUND")
        sliderBgTex:SetAllPoints()
        sliderBgTex:SetTexture(bdTex)
        sliderBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        sliderBg.__border = CreateTextureBorder(sliderBg, 1)
        sliderBg.__border:SetColor(0.3, 0.3, 0.3, 1)
        
        local slider = CreateFrame("Slider", "TurboPlatesSlider"..sliderCount, sliderBg)
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(220, 16)
        slider:SetPoint("CENTER", sliderBg, "CENTER", 0, 0)
        slider:SetThumbTexture(bdTex)
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(12, 12)
        thumb:SetVertexColor(cr, cg, cb)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:EnableMouse(true)
        slider:EnableMouseWheel(true)
        
        local low = frame:CreateFontString(nil, "OVERLAY")
        low:SetFont(GUI_FONT, 10, "")
        low:SetPoint("TOPLEFT", sliderBg, "BOTTOMLEFT", 0, -2)
        low:SetText(tostring(minVal) .. suffix)
        low:SetTextColor(0.6, 0.6, 0.6)
        
        local high = frame:CreateFontString(nil, "OVERLAY")
        high:SetFont(GUI_FONT, 10, "")
        high:SetPoint("TOPRIGHT", sliderBg, "BOTTOMRIGHT", 0, -2)
        high:SetText(tostring(maxVal) .. suffix)
        high:SetTextColor(0.6, 0.6, 0.6)
        
        local valueText = frame:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(GUI_FONT, 12, "")
        valueText:SetPoint("TOP", sliderBg, "BOTTOM", 0, -2)
        
        local function FormatValue(v)
            if isFloat then
                return string.format("%.1f", v) .. suffix
            else
                return tostring(math.floor(v + 0.5)) .. suffix
            end
        end
        
        local function GetVal()
            local td = EnsureTurboDebuffsDB()
            local val = td[key]
            if val == nil then return ns.defaults.turboDebuffs[key] or minVal end
            return val
        end
        
        slider:SetValue(GetVal())
        valueText:SetText(FormatValue(GetVal()))
        
        slider:SetScript("OnValueChanged", function(self, v)
            if isFloat then
                v = math.floor(v * 10 + 0.5) / 10
            else
                v = math.floor(v + 0.5)
            end
            local td = EnsureTurboDebuffsDB()
            td[key] = v
            valueText:SetText(FormatValue(v))
            if ns.CacheTurboDebuffsSettings then ns:CacheTurboDebuffsSettings() end
            UpdateAll()
        end)
        
        slider:SetScript("OnMouseWheel", function(self, delta)
            local newVal = self:GetValue() + (delta * step)
            newVal = max(minVal, min(maxVal, newVal))
            self:SetValue(newVal)
        end)
        
        slider:SetScript("OnShow", function(self)
            local v = GetVal()
            self:SetValue(v)
            valueText:SetText(FormatValue(v))
        end)
        
        frame.slider = slider
        return frame
    end
    
    -- Helper to create dropdown for nested turboDebuffs.* settings
    local function CreateTDDropdown(parent, key, label, options, x, y)
        dropdownCount = dropdownCount + 1
        
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(220, 50)
        frame:SetPoint("TOPLEFT", x, y)
        
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(GUI_FONT, 12, "")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(label)
        title:SetTextColor(1, 0.8, 0)
        
        local btn = CreateFrame("Button", "TurboPlatesTDDD"..dropdownCount, frame, "BackdropTemplate")
        btn:SetSize(220, 22)
        btn:SetPoint("TOPLEFT", 0, -18)
        CreateBD(btn, 0.6)
        btn.__border:SetColor(1, 1, 1, 0.2)
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(GUI_FONT, 12, "")
        text:SetPoint("LEFT", 8, 0)
        text:SetPoint("RIGHT", -22, 0)
        text:SetJustifyH("LEFT")
        btn.text = text
        
        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(14, 14)
        arrow:SetPoint("RIGHT", -5, 0)
        arrow:SetTexture(mediaPath.."arrow.tga")
        arrow:SetRotation(math.rad(180))
        
        local listName = "TurboPlatesTDDDList"..dropdownCount
        local list = CreateFrame("Frame", listName, UIParent)
        list:SetFrameStrata("TOOLTIP")
        list:SetFrameLevel(200)
        list:SetClampedToScreen(true)
        
        local listBgTex = list:CreateTexture(nil, "BACKGROUND")
        listBgTex:SetAllPoints()
        listBgTex:SetTexture(bdTex)
        listBgTex:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        list.__border = CreateTextureBorder(list, 1)
        list.__border:SetColor(0.3, 0.3, 0.3, 1)
        list:Hide()
        btn.list = list
        
        local numOpts = #options
        list:SetSize(220, numOpts * 20 + 6)
        
        for i, opt in ipairs(options) do
            local optBtn = CreateFrame("Button", nil, list)
            optBtn:SetSize(214, 18)
            optBtn:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 20)
            
            local optText = optBtn:CreateFontString(nil, "OVERLAY")
            optText:SetFont(GUI_FONT, 12, "")
            optText:SetPoint("LEFT", 6, 0)
            optText:SetText(opt.name)
            optText:SetTextColor(0.9, 0.9, 0.9)
            
            optBtn:SetScript("OnEnter", function(self)
                optText:SetTextColor(1, 0.8, 0)
            end)
            optBtn:SetScript("OnLeave", function(self)
                optText:SetTextColor(0.9, 0.9, 0.9)
            end)
            optBtn:SetScript("OnClick", function(self)
                local td = EnsureTurboDebuffsDB()
                td[key] = opt.value
                text:SetText(opt.name)
                list:Hide()
                if ns.CacheTurboDebuffsSettings then ns:CacheTurboDebuffsSettings() end
                UpdateAll()
            end)
        end
        
        btn:SetScript("OnClick", function(self)
            if list:IsShown() then
                list:Hide()
            else
                list:ClearAllPoints()
                list:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
                list:Show()
            end
        end)
        
        local function Refresh()
            local td = EnsureTurboDebuffsDB()
            local currentVal = td[key]
            if currentVal == nil then currentVal = ns.defaults.turboDebuffs[key] end
            for _, opt in ipairs(options) do
                if opt.value == currentVal then
                    text:SetText(opt.name)
                    return
                end
            end
            if options[1] then text:SetText(options[1].name) end
        end
        
        btn:SetScript("OnShow", function() Refresh(); list:Hide() end)
        Refresh()
        
        frame.btn = btn
        return frame
    end
    
    -- Main enable checkbox
    local enableCB = CreateTDCheckBox(p12, "enabled", "Enable TurboDebuffs", 20, y)
    enableCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Enable TurboDebuffs", 1, 1, 1)
        GameTooltip:AddLine("Performance optimized custom 'BigDebuffs' integration, built from scratch for Ascension. Respects Aura Blacklist entries.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    enableCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Show for Friendlies checkbox (aligned with Name-Only column)
    local friendlyCB = CreateTDCheckBox(p12, "showFriendly", "Show for Friendlies", 260, y)
    
    -- Grey out friendly checkbox when TurboDebuffs disabled
    local function UpdateFriendlyState()
        local td = TurboPlatesDB and TurboPlatesDB.turboDebuffs or {}
        local enabled = td.enabled ~= false
        if enabled then
            friendlyCB.label:SetTextColor(1, 1, 1)
            friendlyCB:Enable()
        else
            friendlyCB.label:SetTextColor(0.5, 0.5, 0.5)
            friendlyCB:Disable()
        end
    end
    enableCB:HookScript("OnClick", UpdateFriendlyState)
    UpdateFriendlyState()
    
    -- Column headers
    local fullHeader = p12:CreateFontString(nil, "OVERLAY")
    fullHeader:SetFont(GUI_FONT, 12, "")
    fullHeader:SetPoint("TOPLEFT", 20, y - 30)
    fullHeader:SetText("Normal Nameplates:")
    fullHeader:SetTextColor(1, 0.8, 0)
    
    local nameOnlyHeader = p12:CreateFontString(nil, "OVERLAY")
    nameOnlyHeader:SetFont(GUI_FONT, 12, "")
    nameOnlyHeader:SetPoint("TOPLEFT", 260, y - 30)
    nameOnlyHeader:SetText("Friendly Name-Only Plates:")
    nameOnlyHeader:SetTextColor(1, 0.8, 0)
    
    -- Anchor dropdown options
    local anchorOpts = {
        {name = "Left", value = "LEFT"},
        {name = "Right", value = "RIGHT"},
        {name = "Top", value = "TOP"},
        {name = "Bottom", value = "BOTTOM"},
    }
    
    -- Row 1: Icon Position dropdowns
    CreateTDDropdown(p12, "anchor", "Icon Position", anchorOpts, 20, y - 48)
    CreateTDDropdown(p12, "nameOnlyAnchor", "Icon Position", anchorOpts, 260, y - 48)
    
    -- Row 2: Icon Size sliders
    CreateTDSlider(p12, "size", "Icon Size", 16, 64, 20, y - 93, false, "px")
    CreateTDSlider(p12, "nameOnlySize", "Icon Size", 12, 48, 260, y - 93, false, "px")
    
    -- Row 3: Timer Font Size sliders
    CreateTDSlider(p12, "timerSize", "Timer Font Size", 8, 24, 20, y - 138, false, "px")
    CreateTDSlider(p12, "nameOnlyTimerSize", "Timer Font Size", 6, 18, 260, y - 138, false, "px")
    
    -- Row 4: X Offset sliders
    CreateTDSlider(p12, "xOffset", "X Offset", -50, 50, 20, y - 183, false, "px")
    CreateTDSlider(p12, "nameOnlyXOffset", "X Offset", -50, 50, 260, y - 183, false, "px")
    
    -- Row 5: Y Offset sliders
    CreateTDSlider(p12, "yOffset", "Y Offset", -50, 50, 20, y - 228, false, "px")
    CreateTDSlider(p12, "nameOnlyYOffset", "Y Offset", -50, 50, 260, y - 228, false, "px")
    
    -- Section: Category Toggles
    local categoryHeader = p12:CreateFontString(nil, "OVERLAY")
    categoryHeader:SetFont(GUI_FONT, 12, "")
    categoryHeader:SetPoint("TOPLEFT", 20, y - 273)
    categoryHeader:SetText("Show Categories:")
    categoryHeader:SetTextColor(1, 0.8, 0)
    
    -- Category checkboxes (3 columns)
    local catY = y - 292
    CreateTDCheckBox(p12, "immunities", "Immunities", 20, catY)
    CreateTDCheckBox(p12, "cc", "Crowd Control", 180, catY)
    CreateTDCheckBox(p12, "silence", "Silences", 340, catY)
    
    catY = catY - 23
    CreateTDCheckBox(p12, "interrupts", "Interrupts", 20, catY)
    CreateTDCheckBox(p12, "roots", "Roots", 180, catY)
    CreateTDCheckBox(p12, "disarm", "Disarms", 340, catY)
    
    catY = catY - 23
    CreateTDCheckBox(p12, "buffs_defensive", "Defensive Buffs", 20, catY)
    CreateTDCheckBox(p12, "buffs_offensive", "Offensive Buffs", 180, catY)
    CreateTDCheckBox(p12, "buffs_other", "Other Buffs", 340, catY)
    
    catY = catY - 23
    CreateTDCheckBox(p12, "snare", "Snares", 20, catY)
    
    -- TAB 13: Misc
    local p13 = guiPage[13]
    y = -10
    
    -- Row 1: Totem Display (left) & Performance header + Potato PC Mode (right)
    local totemOpts = {
        {name = L.TotemDisabled, value = "disabled"},
        {name = L.TotemHPName, value = "hp_name"},
        {name = L.TotemIconOnly, value = "icon_only"},
        {name = L.TotemIconName, value = "icon_name"},
        {name = L.TotemIconHP, value = "icon_hp"},
        {name = L.TotemIconNameHP, value = "icon_name_hp"},
    }
    CreateDropdown(p13, "totemDisplay", L.TotemDisplay, totemOpts, 20, y)
    
    -- Performance header (right side)
    local perfHeader = p13:CreateFontString(nil, "OVERLAY")
    perfHeader:SetFont(GUI_FONT, 12, "")
    perfHeader:SetPoint("TOPLEFT", 260, y)
    perfHeader:SetText(L.PerformanceHeader or "Performance:")
    perfHeader:SetTextColor(1, 0.8, 0)
    
    -- Potato PC Mode checkbox (below Performance header)
    local potatoCheck = CreateCheckBox(p13, "potatoMode", L.PotatoPCMode, 260, y - 18)
    potatoCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.PotatoPCMode, 1, 0.8, 0)
        GameTooltip:AddLine(L.PotatoPCModeDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    potatoCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    potatoCheck:SetScript("OnClick", function(self)
        TurboPlatesDB.potatoMode = self:GetChecked()
        if ns.UpdateDBCache then ns:UpdateDBCache() end
        -- Show reload prompt since aura batching interval is set at load time
        StaticPopup_Show("TURBOPLATES_RELOAD_UI")
    end)
    
    -- Row 2: Target Glow (left) & Target Arrow (right)
    y = y - 50
    CreateDropdown(p13, "targetGlow", L.TargetGlow, ns.TargetGlowStyles, 20, y)
    CreateDropdown(p13, "targetArrow", L.TargetArrow, ns.TargetArrowStyles, 260, y)
    
    -- Section: Nameplate Clickable Area
    y = y - 50
    local clickHeader = p13:CreateFontString(nil, "OVERLAY")
    clickHeader:SetFont(GUI_FONT, 12, "")
    clickHeader:SetPoint("TOPLEFT", 20, y)
    clickHeader:SetText(L.ClickableAreaHeader or "Nameplate Clickable Area:")
    clickHeader:SetTextColor(1, 0.8, 0)
    
    -- Show Clickbox toggle - uses Blizzard's native DrawNameplateClickBox CVar
    -- Requires reload to apply, syncs with external CVar changes via CVAR_UPDATE
    local showClickbox = CreateCVarCheckBox(p13, "DrawNameplateClickBox", L.ShowClickbox, 260, y + 3, function(self)
        StaticPopup_Show("TURBOPLATES_RELOAD_UI")
    end)
    
    -- Clickable Width & Height sliders (below header)
    y = y - 35
    CreateCVarSlider(p13, "nameplateWidth", L.ClickableWidth, 40, 200, 20, y, nil, "px")
    CreateCVarSlider(p13, "nameplateHeight", L.ClickableHeight, 18, 60, 260, y, nil, "px")
    
    -- TAB 14: Profiles (Import/Export)
    local p14 = guiPage[14]
    y = -10
    
    -- Header
    local header = CreateFS(p14, 14, L.ImportExportHeader or "Import / Export Settings", "system", "TOPLEFT", 20, y)
    header:SetTextColor(1, 0.8, 0)
    
    -- Description
    local desc = p14:CreateFontString(nil, "OVERLAY")
    desc:SetFont(GUI_FONT, 11, "")
    desc:SetPoint("TOPLEFT", 20, y - 25)
    desc:SetWidth(460)
    desc:SetJustifyH("LEFT")
    desc:SetText(L.ImportExportDesc or "Export your settings to share with others, or import a settings string to apply someone else's configuration.")
    desc:SetTextColor(0.8, 0.8, 0.8)
    
    -- Category checkboxes (stored in ns for access by buttons)
    ns.exportOptions = { settings = true, highlights = true, whitelist = true, blacklist = true }
    
    local checkboxY = y - 58
    
    local function CreateExportCheckbox(parent, xPos, label, key)
        local chk = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
        chk:SetSize(16, 16)
        chk:SetPoint("TOPLEFT", xPos, checkboxY)
        chk:SetNormalTexture("")
        chk:SetPushedTexture("")
        
        local bg = CreateFrame("Frame", nil, chk, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetFrameLevel(chk:GetFrameLevel() - 1)
        CreateBD(bg, 0.3)
        CreateGradient(bg)
        chk.bg = bg
        
        chk:SetHighlightTexture(bdTex)
        local hl = chk:GetHighlightTexture()
        hl:SetAllPoints(bg)
        hl:SetVertexColor(cr, cg, cb, 0.25)
        
        local check = chk:CreateTexture(nil, "OVERLAY")
        check:SetSize(20, 20)
        check:SetPoint("CENTER")
        check:SetAtlas("questlog-icon-checkmark-yellow-2x")
        check:SetVertexColor(1, 0.82, 0)
        chk:SetCheckedTexture(check)
        
        chk.label = CreateFS(chk, 11, label, nil, "LEFT", 22, 0)
        chk:SetHitRectInsets(0, -chk.label:GetStringWidth() - 6, 0, 0)
        
        chk:SetChecked(true)
        chk:SetScript("OnClick", function(self)
            PlaySound(856)
            ns.exportOptions[key] = self:GetChecked() and true or false
        end)
        
        return chk
    end
    
    local cbSettings = CreateExportCheckbox(p14, 20, L.ExportSettings or "Settings", "settings")
    local cbHighlights = CreateExportCheckbox(p14, 100, L.ExportHighlights or "Highlights", "highlights")
    local cbWhitelist = CreateExportCheckbox(p14, 230, L.ExportWhitelist or "Whitelist", "whitelist")
    local cbBlacklist = CreateExportCheckbox(p14, 360, L.ExportBlacklist or "Blacklist", "blacklist")
    
    -- Scrollable text area (matches spell list panel style)
    local textBg = CreateFrame("Frame", nil, p14, "BackdropTemplate")
    textBg:SetPoint("TOPLEFT", 20, y - 90)
    textBg:SetSize(460, 230)
    CreateBD(textBg, 0.25)
    
    -- Custom scroll frame (no default template)
    local scrollFrame14 = CreateFrame("ScrollFrame", nil, textBg)
    scrollFrame14:SetPoint("TOPLEFT", 5, -5)
    scrollFrame14:SetPoint("BOTTOMRIGHT", -5, 5)
    
    local editBox = CreateFrame("EditBox", "TurboPlatesImportExportBox", scrollFrame14)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(438)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Scroll to cursor when it moves (required for paste to work in scrollframe)
    editBox:SetScript("OnCursorChanged", function(self, _, cursorY, _, cursorHeight)
        cursorY = -cursorY
        local offset = scrollFrame14:GetVerticalScroll()
        local frameHeight = scrollFrame14:GetHeight()
        if cursorY < offset then
            scrollFrame14:SetVerticalScroll(cursorY)
        elseif cursorY + cursorHeight > offset + frameHeight then
            scrollFrame14:SetVerticalScroll(cursorY + cursorHeight - frameHeight)
        end
    end)
    
    -- Update scroll range when text changes
    editBox:SetScript("OnTextChanged", function(self)
        scrollFrame14:UpdateScrollChildRect()
    end)
    
    scrollFrame14:SetScrollChild(editBox)
    
    -- Custom scrollbar (only visible when needed)
    local scrollBar14 = CreateFrame("Frame", nil, textBg)
    scrollBar14:SetSize(8, 218)
    scrollBar14:SetPoint("TOPRIGHT", -2, -6)
    scrollBar14:Hide()
    
    local scrollThumb14 = CreateFrame("Button", nil, scrollBar14)
    scrollThumb14:SetSize(8, 40)
    scrollThumb14:SetPoint("TOP", 0, 0)
    local thumbTex14 = scrollThumb14:CreateTexture(nil, "OVERLAY")
    thumbTex14:SetAllPoints()
    thumbTex14:SetTexture(bdTex)
    thumbTex14:SetVertexColor(cr, cg, cb, 0.6)
    scrollThumb14.tex = thumbTex14
    
    scrollThumb14:SetScript("OnEnter", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.9) end)
    scrollThumb14:SetScript("OnLeave", function(self) self.tex:SetVertexColor(cr, cg, cb, 0.6) end)
    
    -- Scrollbar dragging
    local function ScrollThumb14OnUpdate(self)
        local _, cursorY = GetCursorPosition()
        local scale = scrollBar14:GetEffectiveScale()
        cursorY = cursorY / scale
        local barTop = scrollBar14:GetTop()
        local barHeight = scrollBar14:GetHeight() - self:GetHeight()
        local offset = barTop - cursorY - self:GetHeight() / 2
        offset = max(0, min(barHeight, offset))
        local scrollMax = scrollFrame14:GetVerticalScrollRange()
        scrollFrame14:SetVerticalScroll(scrollMax * (offset / barHeight))
    end
    scrollThumb14:SetScript("OnMouseDown", function(self)
        self:SetScript("OnUpdate", ScrollThumb14OnUpdate)
    end)
    scrollThumb14:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    
    -- Mouse wheel scrolling
    textBg:EnableMouseWheel(true)
    textBg:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame14:GetVerticalScroll()
        local maxScroll = scrollFrame14:GetVerticalScrollRange()
        local newScroll = current - (delta * 30)
        newScroll = max(0, min(maxScroll, newScroll))
        scrollFrame14:SetVerticalScroll(newScroll)
    end)
    
    -- Click on scroll frame to focus editbox
    scrollFrame14:EnableMouse(true)
    scrollFrame14:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    
    -- Update scrollbar position when scrolling
    local function UpdateScrollBar14()
        local scrollMax = scrollFrame14:GetVerticalScrollRange()
        if scrollMax > 0 then
            scrollBar14:Show()
            editBox:SetWidth(426)
            scrollFrame14:SetPoint("BOTTOMRIGHT", -14, 5)
            local scrollCurrent = scrollFrame14:GetVerticalScroll()
            local barHeight = scrollBar14:GetHeight() - scrollThumb14:GetHeight()
            local thumbOffset = (scrollCurrent / scrollMax) * barHeight
            scrollThumb14:SetPoint("TOP", 0, -thumbOffset)
        else
            scrollBar14:Hide()
            editBox:SetWidth(438)
            scrollFrame14:SetPoint("BOTTOMRIGHT", -5, 5)
        end
    end
    
    scrollFrame14:SetScript("OnScrollRangeChanged", UpdateScrollBar14)
    scrollFrame14:SetScript("OnVerticalScroll", UpdateScrollBar14)
    
    -- Status text
    local statusText = p14:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(GUI_FONT, 11, "")
    statusText:SetPoint("TOPLEFT", 20, y - 325)
    statusText:SetWidth(460)
    statusText:SetJustifyH("LEFT")
    statusText:SetText("")
    
    -- Buttons (matching main GUI style) - Order: Export, Import, Copy, Clear
    local exportBtn = CreateButton(p14, 130, 26, L.ExportButton or "Export Selected")
    exportBtn:SetPoint("TOPLEFT", 20, y - 350)
    exportBtn:SetScript("OnClick", function()
        PlaySound(856)
        local str, err = ns:ExportSettings(ns.exportOptions)
        if str then
            editBox:SetText(str)
            editBox:HighlightText()
            editBox:SetFocus()
            statusText:SetText("|cff00ff00" .. (L.ExportSuccess or "Settings exported! Copy the text above.") .. "|r")
        else
            statusText:SetText("|cffff0000" .. (L.ExportFailed or "Export failed: ") .. (err or "unknown error") .. "|r")
        end
    end)
    
    local importBtn = CreateButton(p14, 130, 26, L.ImportButton or "Import Selected")
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    importBtn:SetScript("OnClick", function()
        PlaySound(856)
        local text = editBox:GetText()
        if not text or text == "" then
            statusText:SetText("|cffff0000" .. (L.ImportEmpty or "Please paste a settings string first.") .. "|r")
            return
        end
        
        local success, msg = ns:ImportSettings(text, ns.exportOptions)
        if success then
            statusText:SetText("|cff00ff00" .. msg .. "|r")
            StaticPopup_Show("TURBOPLATES_IMPORT_RELOAD")
        else
            statusText:SetText("|cffff0000" .. (L.ImportFailed or "Import failed: ") .. msg .. "|r")
        end
    end)
    
    local clearBtn = CreateButton(p14, 60, 26, L.ClearButton or "Clear")
    clearBtn:SetPoint("TOPRIGHT", -20, y - 350)
    clearBtn:SetScript("OnClick", function()
        PlaySound(856)
        editBox:SetText("")
        statusText:SetText("")
        editBox:ClearFocus()
    end)
    
    local copyBtn = CreateButton(p14, 60, 26, L.CopyButton or "Copy")
    copyBtn:SetPoint("RIGHT", clearBtn, "LEFT", -8, 0)
    copyBtn:SetScript("OnClick", function()
        PlaySound(856)
        local text = editBox:GetText()
        if text and text ~= "" then
            Internal_CopyToClipboard(text)
            statusText:SetText("|cff00ff00" .. (L.CopySuccess or "Copied to clipboard!") .. "|r")
        else
            statusText:SetText("|cffff0000" .. (L.CopyEmpty or "Nothing to copy. Export first.") .. "|r")
        end
    end)
    
    SelectTab(1)
    ns.UpdatePreview()
end

-- Reload UI popup for settings that require it
StaticPopupDialogs["TURBOPLATES_RELOAD_UI"] = {
    text = "This setting requires a UI reload to take full effect. Reload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Import settings reload popup
StaticPopupDialogs["TURBOPLATES_IMPORT_RELOAD"] = {
    text = "Settings imported successfully!\n\nReload now to apply changes?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateLauncher()
    local panel = CreateFrame("Frame", nil, UIParent)
    panel.name = "TurboPlates"
    InterfaceOptions_AddCategory(panel)
    local t = panel:CreateFontString(nil, "ARTWORK")
    t:SetFont(GUI_FONT, 14, "")
    t:SetPoint("TOPLEFT", 16, -16)
    local version = GetAddOnMetadata(addonName, "Version") or "1.0.0"
    t:SetText("TurboPlates v" .. version)
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(200, 30)
    btn:SetPoint("CENTER")
    btn:SetText("Open Settings")
    btn:SetScript("OnClick", function()
        InterfaceOptionsFrame:Hide()
        ns:ToggleGUI()
    end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("CVAR_UPDATE")
loader:SetScript("OnEvent", function(self, event, cvar, value)
    if event == "PLAYER_LOGIN" then
        CreateLauncher()
    elseif event == "CVAR_UPDATE" then
        -- Sync CVar checkboxes when CVars change externally (keybind, console, Interface settings)
        if ns.cvarCheckboxes and cvar then
            local chk = ns.cvarCheckboxes[cvar]
            if chk and chk:IsVisible() then
                local val = GetCVar(cvar)
                chk:SetChecked(val and (val == "1" or val == 1))
            end
            
            -- Special handling for nameplateShowPersonal: also sync to saved DB
            -- Interface settings changes should persist in TurboPlates config
            if cvar == "nameplateShowPersonal" then
                local val = GetCVar(cvar)
                local enabled = val and (val == "1" or val == 1)
                if TurboPlatesDB and TurboPlatesDB.personal then
                    TurboPlatesDB.personal.enabled = enabled
                end
                -- Update cache and re-register/unregister events
                if ns.UpdateDBCache then
                    ns:UpdateDBCache()
                end
            end
        end
    end
end)
