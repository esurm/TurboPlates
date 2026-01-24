local addonName, ns = ...
local L = ns.L

local btn = CreateFrame("Button", "TurboPlatesMinimapBtn", Minimap)
btn:SetFrameStrata("MEDIUM")
btn:SetSize(31, 31)
btn:SetFrameLevel(8)
btn:RegisterForClicks("AnyUp")
btn:RegisterForDrag("LeftButton")
btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local overlay = btn:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

local icon = btn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetAtlas("renown-rocket")
icon:SetPoint("CENTER", 0, 1)

local function UpdatePosition()
    if not TurboPlatesDB then return end
    if type(TurboPlatesDB.minimap) ~= "table" then
        TurboPlatesDB.minimap = { hide = false, pos = 45 }
    end
    
    local db = TurboPlatesDB.minimap
    if db.hide then btn:Hide() else btn:Show() end
    
    local angle = math.rad(db.pos or 45)
    local x, y = math.cos(angle), math.sin(angle)
    btn:SetPoint("CENTER", Minimap, "CENTER", x * 80, y * 80)
end

btn:SetMovable(true)
btn:SetScript("OnDragStart", function(self)
    local throttle = 0
    self:SetScript("OnUpdate", function(self, elapsed)
        throttle = throttle + elapsed
        if throttle < 0.016 then return end  -- ~60 FPS limit (prevents cursor lag)
        throttle = 0
        
        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local cx, cy = Minimap:GetCenter()
        x, y = x / scale, y / scale
        local angle = math.atan2(y - cy, x - cx)
        
        if not TurboPlatesDB then TurboPlatesDB = {} end
        if type(TurboPlatesDB.minimap) ~= "table" then TurboPlatesDB.minimap = {hide=false,pos=45} end
        
        TurboPlatesDB.minimap.pos = math.deg(angle)
        UpdatePosition()
    end)
end)
btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

btn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        ReloadUI()
    else
        if ns.ToggleGUI then ns:ToggleGUI() end
    end
end)

btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("TurboPlates")
    local l = (L.LeftClick or "L: ") .. (L.Settings or "Settings")
    local r = (L.Reload or "R: Reload")
    GameTooltip:AddLine(l, 1, 1, 1)
    GameTooltip:AddLine(r, 1, 1, 1)
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() UpdatePosition() end)

ns.UpdateMinimapButton = UpdatePosition
