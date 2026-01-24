-- Nameplate stacking via SetClampRectInsets

local _, ns = ...

local StackingFrame = CreateFrame("Frame")
local StackingPlates = {}  -- [nameplate] = {baseX, baseY, desiredOffset, currentOffset, velocity, guid, ...}
local SortedPlates = {}    -- indexed array for deterministic iteration
local stackingEnabled = false
local stackingLastUpdate = 0
local prevPlateCount = 0   -- Track plate count changes for layout dirty detection

-- Pooled tables to reduce GC pressure
local toRemove = {}        -- reused each frame for cleanup
local entryPool = {}       -- pool of {frame, data} entries
local entryPoolIndex = 0
local prevPoolIndex = 0    -- track previous frame's pool usage for efficient clearing
local dataPool = {}        -- pool of plate data tables
local dataPoolIndex = 0

-- Acquire a data table from pool (avoids allocation during combat)
local function AcquireData()
    if dataPoolIndex > 0 then
        local d = dataPool[dataPoolIndex]
        dataPool[dataPoolIndex] = nil
        dataPoolIndex = dataPoolIndex - 1
        return d
    end
    return {}
end

-- Return a data table to the pool
local function ReleaseData(d)
    wipe(d)
    dataPoolIndex = dataPoolIndex + 1
    dataPool[dataPoolIndex] = d
end

local abs = math.abs
local floor = math.floor
local pairs = pairs
local GetTime = GetTime
local wipe = wipe
local sort = table.sort
local UnitIsFriend = UnitIsFriend
local UnitIsDead = UnitIsDead
local UnitGUID = UnitGUID
local UnitIsPet = UnitIsPet
local UnitCreatureType = UnitCreatureType
local UnitPlayerControlled = UnitPlayerControlled
local UnitIsPlayer = UnitIsPlayer
local EnumerateActiveNamePlates = C_NamePlateManager.EnumerateActiveNamePlates
local EMPTY_GUID = ""  -- Cached empty string for comparator

-- Presets
ns.StackingPresets = {
    balanced = {
        -- Dungeons/raids with 5-12 mobs: smooth but responsive
        springFrequencyRaise = 10,
        springFrequencyLower = 10,
        launchDamping = 0.8,
        xSpaceRatio = 0.8,
        ySpaceRatio = 0.8,
        originPosRatio = 0,
        upperBorder = 48,
        settleThreshold = 0.9,
        maxPlates = 60,
    },
    chill = {
        -- Open world questing with 1-5 mobs: relaxed, gentle motion
        springFrequencyRaise = 7,
        springFrequencyLower = 6,
        launchDamping = 0.6,
        xSpaceRatio = 0.75,
        ySpaceRatio = 0.8,
        originPosRatio = 0,
        upperBorder = 48,
        settleThreshold = 0.9,
        maxPlates = 60,
    },
    snappy = {
        -- M+/PvP with 10-20 mobs: fast, tight, responsive
        springFrequencyRaise = 13,
        springFrequencyLower = 11,
        launchDamping = 0.9,
        xSpaceRatio = 0.8,
        ySpaceRatio = 0.8,
        originPosRatio = 0,
        upperBorder = 48,
        settleThreshold = 1,
        maxPlates = 60,
    },
}

-- ==========================================================================
-- CONSOLIDATED TABLES (to reduce upvalue count - Lua 5.1 limit is 60)
-- ==========================================================================

-- Physics constants (refreshed from ns.c_* via RefreshStackingConfig)
local Physics = {
    springFrequencyRaise = 10,  -- ω for raising (radians/sec)
    springFrequencyLower = 10,  -- ω for lowering
    launchDamping = 0.8,        -- Min omega scale at distance
    launchDampingComplement = 0.2, -- Pre-computed: 1 - launchDamping
    settleThreshold = 0.9,      -- Snap-to-target epsilon (pixels)
    maxPlates = 60,             -- Max plates to process
}

-- State tracking (screen dimensions in UI units, NOT scaled pixels)
local State = {
    screenWidth = 1366,   -- UI units (unscaled)
    screenHeight = 768,   -- UI units (always 768 in WoW)
    uiScale = 1,
}

-- Cached config values (refreshed via ns.RefreshStackingConfig)
local Config = {
    xSpaceRatio = 0.8,
    ySpaceRatio = 0.8,
    originPosRatio = 0,           -- Base height adjust: 0=100%, -1=0%, +1=200%
    upperBorder = 48,
    stackingInterval = 0.016,     -- ~60 FPS layout updates (doubled in potato mode)
}

-- Pre-computed scaled values (updated in RefreshStackingConfig and RefreshScreenDimensions)
local Scaled = {
    clickWidth = 140,       -- Actual clickbox width for edge overlap detection
    xOverlapRatio = 0.8,    -- Sensitivity: <1 allows partial overlap, >1 more aggressive
    yspace = 24,            -- clickHeight * ySpaceRatio
    originPos = 22,
    upperBorder = 48,
    overlapThreshold = 140, -- clickWidth * xOverlapRatio (pre-computed)
    screenTopUI = 768,      -- Screen height in UI units (always 768)
    topMarginUI = 48,       -- upperBorder / uiScale
    maxScreenY = 720,       -- screenTopUI - topMarginUI
}

-- Forward declaration (defined below, called by RefreshStackingConfig)
local RefreshScreenDimensions

-- Refresh cached config values from ns.c_* (call when settings change)
-- All values come from UpdateDBCache() which handles DB → defaults fallback
function ns.RefreshStackingConfig()
    -- Physics (spring frequencies from ns.c_*)
    Physics.springFrequencyRaise = ns.c_stackingSpringFrequencyRaise or 10
    Physics.springFrequencyLower = ns.c_stackingSpringFrequencyLower or 10
    Physics.launchDamping = ns.c_stackingLaunchDamping or 0.8
    Physics.launchDampingComplement = 1 - Physics.launchDamping
    Physics.settleThreshold = ns.c_stackingSettleThreshold or 0.9
    Physics.maxPlates = ns.c_stackingMaxPlates or 60
    
    -- Config (layout settings from ns.c_*)
    Config.xSpaceRatio = ns.c_stackingXSpaceRatio or 0.8
    Config.ySpaceRatio = ns.c_stackingYSpaceRatio or 0.8
    Config.originPosRatio = ns.c_stackingOriginPosRatio or 0
    Config.upperBorder = ns.c_stackingUpperBorder or 48
    Config.stackingInterval = 0.016 * (ns.c_throttleMultiplier or 1)  -- ~60 fps layout updates
    
    -- Get clickbox dimensions (user's actual hitbox size)
    local clickWidth = ns.clickableWidth or 140
    local clickHeight = ns.clickableHeight or 30
    
    -- Compute scaled values for overlap detection
    Scaled.clickWidth = clickWidth
    Scaled.clickHeight = clickHeight
    Scaled.xOverlapRatio = Config.xSpaceRatio
    Scaled.yspace = clickHeight * Config.ySpaceRatio
    Scaled.originPos = clickHeight * (1 + Config.originPosRatio)  -- 0=100%, -1=0%, +1=200%
    Scaled.upperBorder = Config.upperBorder
    Scaled.overlapThreshold = clickWidth * Config.xSpaceRatio
    
    -- Re-compute screen-dependent values
    RefreshScreenDimensions()
end

function RefreshScreenDimensions()
    local scale = UIParent:GetEffectiveScale()
    
    -- Screen dimensions in UI units (WoW UI is always 768 tall, width varies by aspect ratio)
    -- Do NOT multiply by scale - WorldFrame and clamp insets expect UI units
    State.screenWidth = GetScreenWidth()    -- UI units (e.g., 1366 at 16:9)
    State.screenHeight = GetScreenHeight()  -- UI units (always 768)
    State.uiScale = scale
    
    -- Upper border config in pixels, convert to UI units
    local upperBorder = Scaled.upperBorder or ns.c_stackingUpperBorder or 30
    local topMarginUI = upperBorder / scale
    
    -- Screen top in UI units (768 for standard WoW)
    Scaled.screenTopUI = State.screenHeight
    Scaled.topMarginUI = topMarginUI
    Scaled.maxScreenY = State.screenHeight - topMarginUI
    
    -- Static clamp: WorldFrame is 5x height, push plates down 4x to keep in visible 1x area
    State.staticClampTop = (State.screenHeight * 4) - topMarginUI
end

-- Check if nameplate should be ignored (friendly, player, dead, pets, totems, minions/guardians)
local function ShouldIgnorePlate(nameplate)
    local unit = nameplate._unit
    if not unit then return true end
    if UnitIsUnit(unit, "player") then return true end
    if UnitIsFriend("player", unit) then return true end
    if UnitIsDead(unit) then return true end
    -- Skip all player-controlled non-player units (pets, totems, minions, guardians)
    if UnitPlayerControlled(unit) and not UnitIsPlayer(unit) then return true end
    return false
end

-- Reset plate clamping
local function ResetPlateClamping(nameplate)
    nameplate._staticClampApplied = nil
    nameplate:SetClampRectInsets(0, 0, 0, 0)
    nameplate:SetClampedToScreen(false)
end

-- Sort comparator: baseY > baseX > GUID
-- Lower baseY = processed first (anchor), higher plates stack above
-- Y bucketed by 2px to prevent micro-reorders from camera jitter
local Y_EPSILON = 2
local INV_Y_EPSILON = 1 / Y_EPSILON  -- Pre-computed for faster bucketing
local INV_DIST_THRESHOLD = 0.05      -- Pre-computed: 1/20 for omega scaling

local function PlateComparator(a, b)
    local aData, bData = a.data, b.data
    -- Guard against stale entries with released data
    if not aData or not bData then return false end
    if not aData.baseY or not bData.baseY then return false end
    
    -- bucketY is always set in DoLayoutUpdate before sort, no fallback needed
    local aY = aData.bucketY
    local bY = bData.bucketY
    if aY ~= bY then
        return aY < bY
    end
    if aData.baseX ~= bData.baseX then
        return aData.baseX < bData.baseX
    end
    return (aData.guid or EMPTY_GUID) < (bData.guid or EMPTY_GUID)
end

-- Cleanup specific plate (called from Core.lua)
function ns.CleanupStackingPlate(nameplate)
    local data = StackingPlates[nameplate]
    if data then
        ReleaseData(data)
        StackingPlates[nameplate] = nil
        nameplate:SetClampRectInsets(0, 0, 0, 0)
        nameplate:SetClampedToScreen(false)
    end
end

-- =============================================================================
-- LAYOUT UPDATE (Throttled - expensive O(n²) operations)
-- =============================================================================
-- Collects positions, sorts plates, computes desired offsets.
-- Only rebuilds/sorts/layouts when positions actually changed.

local function DoLayoutUpdate()
    -- =======================================================================
    -- COLLECT: Always gather plate positions (needed for animation baseY)
    -- =======================================================================
    -- Use clickbox height for all plates (consistent with stacking calculations)
    local clickHeight = Scaled.clickHeight or 30
    
    for nameplate in EnumerateActiveNamePlates() do
        if nameplate:IsShown() and not ShouldIgnorePlate(nameplate) then
            local _, _, _, x, y = nameplate:GetPoint(1)
            if x and y then
                local data = StackingPlates[nameplate]
                
                if not data then
                    local unit = nameplate._unit
                    
                    data = AcquireData()
                    data.baseX = x
                    data.baseY = y
                    data.height = clickHeight
                    data.guid = UnitGUID(unit)
                    data.desiredOffset = 0
                    data.currentOffset = 0
                    data.velocity = 0
                    StackingPlates[nameplate] = data
                else
                    data.baseX = x
                    data.baseY = y
                end
            end
        else
            local data = StackingPlates[nameplate]
            if data then
                ReleaseData(data)
                StackingPlates[nameplate] = nil
                ResetPlateClamping(nameplate)
            end
        end
    end
    
    -- =======================================================================
    -- CLEANUP + DIRTY CHECK + BUILD SORTED (single pass over StackingPlates)
    -- =======================================================================
    -- Combines: dead plate detection, count, dirty check, prev update, and sort build
    -- into one pairs() iteration + a separate removal loop (can't modify during pairs)
    
    local toRemoveCount = 0
    local currentCount = 0
    local layoutDirty = prevPlateCount == 0  -- First frame is always dirty
    
    entryPoolIndex = 0
    for nameplate, data in pairs(StackingPlates) do
        if not nameplate:IsShown() or not nameplate._unit then
            -- Mark for removal (can't remove during iteration)
            toRemoveCount = toRemoveCount + 1
            toRemove[toRemoveCount] = nameplate
        else
            currentCount = currentCount + 1
            
            -- Dirty check: position changed significantly (3px threshold)
            if not layoutDirty then
                if not data.prevX 
                   or abs(data.baseX - data.prevX) > 3 
                   or abs(data.baseY - data.prevY) > 3 then
                    layoutDirty = true
                end
            end
            
            -- Update prev positions and bucketY for sorting
            data.prevX = data.baseX
            data.prevY = data.baseY
            data.bucketY = floor(data.baseY * INV_Y_EPSILON)
            
            -- Build sorted array entry
            entryPoolIndex = entryPoolIndex + 1
            local entry = entryPool[entryPoolIndex]
            if not entry then
                entry = {}
                entryPool[entryPoolIndex] = entry
            end
            entry.frame = nameplate
            entry.data = data
            SortedPlates[entryPoolIndex] = entry
        end
    end
    
    -- Remove dead plates (separate loop required - can't modify during pairs)
    for i = 1, toRemoveCount do
        local nameplate = toRemove[i]
        local data = StackingPlates[nameplate]
        if data then
            ReleaseData(data)
        end
        StackingPlates[nameplate] = nil
        ResetPlateClamping(nameplate)
        toRemove[i] = nil  -- Clear for next frame (instead of wipe)
    end
    
    -- Plate count changed = dirty
    if currentCount ~= prevPlateCount then
        layoutDirty = true
        prevPlateCount = currentCount
    end
    
    -- Always clear stale SortedPlates entries before sorting (array shrunk)
    for i = entryPoolIndex + 1, prevPoolIndex do
        local entry = entryPool[i]
        if entry then
            entry.frame = nil
            entry.data = nil
        end
        SortedPlates[i] = nil
    end
    prevPoolIndex = entryPoolIndex
    
    -- Skip sort+layout if nothing changed
    if not layoutDirty then
        return
    end
    
    -- Trim pool if significantly oversized
    local poolLen = #entryPool
    if poolLen > entryPoolIndex + 20 then
        for i = entryPoolIndex + 21, poolLen do
            entryPool[i] = nil
        end
    end
    
    -- =======================================================================
    -- SORT: Deterministic ordering (baseY > baseX > GUID)
    -- =======================================================================
    if entryPoolIndex > 1 then
        sort(SortedPlates, PlateComparator)
    end
    
    -- =======================================================================
    -- LAYOUT: Compute desiredOffset (O(n²))
    -- =======================================================================
    local yspace = Scaled.yspace
    local overlapThreshold = Scaled.overlapThreshold  -- Pre-computed
    local maxScreenY = Scaled.maxScreenY              -- Pre-computed
    local maxPlates = Physics.maxPlates
    local processCount = entryPoolIndex <= maxPlates and entryPoolIndex or maxPlates
    
    for i = 1, processCount do
        local plate = SortedPlates[i].data
        local plateX = plate.baseX
        local plateY = plate.baseY
        local targetOffset = 0
        
        -- Pre-compute max offset for early exit optimization
        local maxOffset = maxScreenY - plateY
        if maxOffset < 0 then maxOffset = 0 end
        
        for j = 1, i - 1 do
            -- Early exit: already at screen ceiling, no point checking more obstacles
            if targetOffset >= maxOffset then break end
            
            local obstacle = SortedPlates[j].data
            local xdiff = abs(plateX - obstacle.baseX)
            
            if xdiff < overlapThreshold then
                local obstacleTop = obstacle.baseY + obstacle.desiredOffset + yspace
                if obstacleTop > plateY then
                    local requiredOffset = obstacleTop - plateY
                    if requiredOffset > targetOffset then
                        targetOffset = requiredOffset
                    end
                end
            end
        end
        
        -- Cap at screen top (maxOffset already computed above)
        if targetOffset > maxOffset then
            targetOffset = maxOffset
        end
        
        plate.desiredOffset = targetOffset
    end
    
    -- Overflow plates get zero offset (skip if none)
    if processCount < entryPoolIndex then
        for i = processCount + 1, entryPoolIndex do
            local entry = SortedPlates[i]
            if entry and entry.data then
                entry.data.desiredOffset = 0
            end
        end
    end
end

-- =============================================================================
-- ANIMATION UPDATE (Every frame - cheap O(n) operations)
-- =============================================================================
-- Runs spring physics and applies visual offsets.
-- Runs every frame for smooth 60fps animation regardless of layout throttle.

local function DoAnimationUpdate(dt)
    if entryPoolIndex == 0 then return end
    
    if dt > 0.05 then dt = 0.05 end  -- Clamp to prevent spring instability
    
    local omegaRaise = Physics.springFrequencyRaise
    local omegaLower = Physics.springFrequencyLower
    local launchDamping = Physics.launchDamping
    local launchDampingComplement = Physics.launchDampingComplement
    local epsilon = Physics.settleThreshold
    local maxPlates = Physics.maxPlates
    local originPos = Scaled.originPos
    local topMarginUI = Scaled.topMarginUI    -- Pre-computed
    local maxScreenY = Scaled.maxScreenY      -- Pre-computed
    local processCount = entryPoolIndex <= maxPlates and entryPoolIndex or maxPlates
    
    -- Pre-compute omega-dependent terms ONCE per frame (not per plate)
    -- These values are constant for all plates using the same omega
    local ooRaise = omegaRaise * omegaRaise
    local ooLower = omegaLower * omegaLower
    
    -- Animate processed plates
    for i = 1, processCount do
        local entry = SortedPlates[i]
        if not entry then break end
        local frame = entry.frame
        local plate = entry.data
        
        -- Skip if data was released between layout and animation (CleanupStackingPlate race)
        if plate and plate.desiredOffset and plate.currentOffset then
            local target = plate.desiredOffset
            
            -- No stacking needed: use static clamp (top-only, no bottom constraint)
            if target < 0.5 and plate.currentOffset < 0.5 and abs(plate.velocity) < 0.4 then
                -- Fast path: already settled at zero, skip everything
                if not plate.isSettled then
                    plate.currentOffset = 0
                    plate.velocity = 0
                    plate.isSettled = true
                    plate.lastBaseY = plate.baseY
                    if plate.lastClampBottom ~= 0 then
                        plate.lastClampBottom = 0
                        frame:SetClampedToScreen(true)
                        plate.isClamped = true
                        frame:SetClampRectInsets(-10, 10, topMarginUI, 0)
                    end
                elseif plate.lastBaseY ~= plate.baseY then
                    -- Settled at zero but baseY changed (mob moved)
                    plate.lastBaseY = plate.baseY
                    if plate.lastClampBottom ~= 0 then
                        plate.lastClampBottom = 0
                        frame:SetClampedToScreen(true)
                        plate.isClamped = true
                        frame:SetClampRectInsets(-10, 10, topMarginUI, 0)
                    end
                end
            else
                -- Stacking needed: run spring physics and dynamic clamp
                local pos = plate.currentOffset
                local vel = plate.velocity
                local delta = target - pos
                
                -- Check if settled (at target with no velocity)
                local settled = plate.isSettled
                if settled and abs(delta) > epsilon then
                    settled = false
                    plate.isSettled = false
                end
                
                if not settled then
                    if abs(delta) < epsilon and abs(vel) < 0.4 then
                        plate.currentOffset = target
                        plate.velocity = 0
                        plate.isSettled = true
                    else
                        -- Velocity+delta hybrid: use raise omega if moving up OR velocity still positive
                        local omega = (delta > 0 or vel > 0.4) and omegaRaise or omegaLower
                        local oo = (delta > 0 or vel > 0.4) and ooRaise or ooLower
                        
                        -- Distance-based scaling: gentle launch, normal settle
                        local dist = abs(delta)
                        local omegaScale = launchDamping + launchDampingComplement * (1 - (dist < 20 and dist * INV_DIST_THRESHOLD or 1))
                        omega = omega * omegaScale
                        oo = oo * omegaScale * omegaScale
                        
                        local f = 1 + 2 * omega * dt
                        local dt_oo = dt * oo
                        local dt2_oo = dt * dt_oo
                        local invDet = 1 / (f + dt2_oo)
                        
                        plate.currentOffset = (f * pos + dt * vel + dt2_oo * target) * invDet
                        plate.velocity = (vel + dt_oo * (target - pos)) * invDet
                    end
                    
                    -- Dynamic clamp (only when animating)
                    local renderOffset = plate.currentOffset
                    local maxOffset = maxScreenY - plate.baseY
                    if maxOffset < 0 then maxOffset = 0 end
                    if renderOffset > maxOffset then
                        renderOffset = maxOffset
                    end
                    
                    local bottomInset = -plate.baseY - renderOffset - originPos + plate.height
                    if plate.lastClampBottom ~= bottomInset then
                        plate.lastClampBottom = bottomInset
                        frame:SetClampedToScreen(true)
                        plate.isClamped = true
                        frame:SetClampRectInsets(-10, 10, topMarginUI, bottomInset)
                    end
                    plate.lastBaseY = plate.baseY
                elseif plate.lastBaseY ~= plate.baseY then
                    -- Settled but baseY changed: recalc clamp
                    plate.lastBaseY = plate.baseY
                    local renderOffset = plate.currentOffset
                    local maxOffset = maxScreenY - plate.baseY
                    if maxOffset < 0 then maxOffset = 0 end
                    if renderOffset > maxOffset then
                        renderOffset = maxOffset
                    end
                    
                    local bottomInset = -plate.baseY - renderOffset - originPos + plate.height
                    if plate.lastClampBottom ~= bottomInset then
                        plate.lastClampBottom = bottomInset
                        frame:SetClampedToScreen(true)
                        plate.isClamped = true
                        frame:SetClampRectInsets(-10, 10, topMarginUI, bottomInset)
                    end
                end
            end
        end
    end
    
    -- Overflow plates: spring toward origin (skip if none)
    if processCount >= entryPoolIndex then return end
    
    for i = processCount + 1, entryPoolIndex do
        local entry = SortedPlates[i]
        if not entry then break end
        local frame = entry.frame
        local plate = entry.data
        
        -- Skip if data was released between layout and animation (CleanupStackingPlate race)
        if plate and plate.currentOffset then
            -- Overflow plates always target 0 offset
            -- Once settled at 0 with clamping reset, skip entirely until promoted back
            if plate.isSettled then
                -- Overflow target is always 0, so if settled we're done
                -- (will wake when promoted back to processed pool with new desiredOffset)
            else
                local pos = plate.currentOffset
                local vel = plate.velocity
                local delta = -pos
                
                if abs(delta) < epsilon and abs(vel) < 0.5 then
                    plate.currentOffset = 0
                    plate.velocity = 0
                    plate.isSettled = true
                    plate.lastClampBottom = nil
                    plate.isClamped = false
                    ResetPlateClamping(frame)
                else
                    local omega = omegaLower
                    local f = 1 + 2 * omega * dt
                    local oo = ooLower
                    local dt_oo = dt * oo
                    local dt2_oo = dt * dt_oo
                    local invDet = 1 / (f + dt2_oo)
                    
                    plate.currentOffset = (f * pos + dt * vel + dt2_oo * 0) * invDet
                    plate.velocity = (vel + dt_oo * delta) * invDet
                    
                    -- Cache clamp insets for overflow plates too
                    local bottomInset = -plate.baseY - plate.currentOffset - originPos + plate.height
                    if plate.lastClampBottom ~= bottomInset then
                        plate.lastClampBottom = bottomInset
                        frame:SetClampedToScreen(true)
                        plate.isClamped = true
                        frame:SetClampRectInsets(-10, 10, topMarginUI, bottomInset)
                    end
                end
            end
        end
    end
end

-- =============================================================================
-- ONUPDATE HANDLER
-- =============================================================================
-- Layout runs throttled, animation runs every frame.

local function OnStackingUpdate(self, elapsed)
    if not ns.c_stackingEnabled then return end
    
    local now = GetTime()
    local timeSinceLastUpdate = now - stackingLastUpdate
    
    -- Layout: throttled (expensive)
    if timeSinceLastUpdate >= Config.stackingInterval then
        stackingLastUpdate = now
        DoLayoutUpdate()
    end
    
    -- Animation: every frame (cheap)
    DoAnimationUpdate(elapsed)
end

-- Reset all plates
local function ResetAllPlates()
    -- Return all data to pool before wiping
    for nameplate, data in pairs(StackingPlates) do
        ReleaseData(data)
        ResetPlateClamping(nameplate)
    end
    wipe(StackingPlates)
    wipe(SortedPlates)
    entryPoolIndex = 0
    prevPlateCount = 0
    
    -- Trim pools on zone change to prevent permanent memory retention
    if dataPoolIndex > 20 then
        for i = 21, dataPoolIndex do
            dataPool[i] = nil
        end
        dataPoolIndex = 20
    end
    if #entryPool > 20 then
        for i = 21, #entryPool do
            entryPool[i] = nil
        end
    end
    prevPoolIndex = 0
end

-- Soft reset: clear velocity but keep positions for smooth re-sort
local function SoftResetAllPlates()
    for nameplate, data in pairs(StackingPlates) do
        data.velocity = 0
    end
end

-- Event handler
local function OnEvent(self, event)
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        RefreshScreenDimensions()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA"
        or event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        ResetAllPlates()
    elseif event == "PLAYER_REGEN_ENABLED" then
        SoftResetAllPlates()
    end
end

-- Enable/disable stacking
function ns.UpdateStacking()
    local shouldEnable = ns.c_stackingEnabled
    
    if shouldEnable and not stackingEnabled then
        ns.RefreshStackingConfig()
        StackingFrame:SetScript("OnUpdate", OnStackingUpdate)
        StackingFrame:RegisterEvent("UI_SCALE_CHANGED")
        StackingFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
        StackingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        StackingFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        StackingFrame:RegisterEvent("PLAYER_DEAD")
        StackingFrame:RegisterEvent("PLAYER_ALIVE")
        StackingFrame:RegisterEvent("PLAYER_UNGHOST")
        StackingFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        StackingFrame:SetScript("OnEvent", OnEvent)
        stackingEnabled = true
        RefreshScreenDimensions()
        
        if C_CVar then
            C_CVar.Set("nameplateAllowOverlap", 1)
            C_CVar.Set("nameplateSmoothStacking", 0)
        end
    elseif not shouldEnable and stackingEnabled then
        StackingFrame:SetScript("OnUpdate", nil)
        StackingFrame:UnregisterEvent("UI_SCALE_CHANGED")
        StackingFrame:UnregisterEvent("DISPLAY_SIZE_CHANGED")
        StackingFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        StackingFrame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
        StackingFrame:UnregisterEvent("PLAYER_DEAD")
        StackingFrame:UnregisterEvent("PLAYER_ALIVE")
        StackingFrame:UnregisterEvent("PLAYER_UNGHOST")
        StackingFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        StackingFrame:SetScript("OnEvent", nil)
        ResetAllPlates()
        stackingEnabled = false
        
        -- Re-apply static clamp to existing enemy plates (tall boss fix)
        if ns.ReapplyStaticClamps then
            ns.ReapplyStaticClamps()
        end
    end
end

-- =============================================================================
-- TALL BOSS FIX (Always-on, extends WorldFrame for tall boss visibility)
-- =============================================================================
-- WorldFrame extended to 5x screen height so nameplates can exist above screen.
-- Static clamp pushes them back into visible area. When stacking is ON, its
-- dynamic clamp overrides this. When stacking is OFF, Core.lua calls
-- OnNameplateAdded to apply static clamp immediately at creation.

local TallBossFrame = CreateFrame("Frame")
local tallBossFixInitialized = false

local function ApplyWorldFrameExtension()
    RefreshScreenDimensions()
    WorldFrame:ClearAllPoints()
    WorldFrame:SetWidth(State.screenWidth)
    WorldFrame:SetHeight(State.screenHeight * 5)
    WorldFrame:SetPoint("BOTTOM")
end

-- Apply static clamp to a single nameplate (top-only, pulls tall plates into view)
-- For tall bosses: push plate down from extended WorldFrame into visible area
-- Bottom inset = 0 prevents any upward movement of plates
local function ApplyStaticClamp(nameplate)
    local topMarginUI = Scaled.topMarginUI or 30
    
    -- Cache: skip if already applied (static clamp is constant)
    if nameplate._staticClampApplied then return end
    nameplate._staticClampApplied = true
    
    nameplate:SetClampedToScreen(true)
    nameplate:SetClampRectInsets(-10, 10, topMarginUI, 0)
end

-- Re-apply static clamp to all visible enemy plates
-- Called once when stacking is disabled to restore tall boss fix
function ns.ReapplyStaticClamps()
    if not tallBossFixInitialized then return end
    for nameplate in EnumerateActiveNamePlates() do
        local unit = nameplate._unit
        if nameplate:IsShown() and unit
           and not UnitIsUnit(unit, "player")
           and not UnitIsFriend("player", unit)
           and not (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
            ApplyStaticClamp(nameplate)
        end
    end
end

-- Called from Core.lua when a nameplate is added
-- Only applies static clamp when stacking is OFF (stacking handles its own clamping)
-- Only applies to enemy nameplates (friendlies/player/pets/totems/minions don't need tall boss fix)
function ns.OnNameplateAddedForClamp(nameplate, unit)
    if not tallBossFixInitialized then return end
    if ns.c_stackingEnabled then return end  -- Stacking handles clamping
    if not unit then return end
    if UnitIsUnit(unit, "player") then return end
    if UnitIsFriend("player", unit) then return end
    -- Skip all player-controlled non-player units (pets, totems, minions, guardians)
    if UnitPlayerControlled(unit) and not UnitIsPlayer(unit) then return end
    ApplyStaticClamp(nameplate)
end

local function OnTallBossEvent(self, event)
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        ApplyWorldFrameExtension()
        -- Re-apply static clamp to all visible enemy plates with new dimensions
        if not ns.c_stackingEnabled then
            for nameplate in EnumerateActiveNamePlates() do
                local unit = nameplate._unit
                if nameplate:IsShown() and unit
                   and not UnitIsUnit(unit, "player")
                   and not UnitIsFriend("player", unit)
                   and not (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
                    nameplate._staticClampApplied = nil  -- Clear cache (topMarginUI changed)
                    ApplyStaticClamp(nameplate)
                end
            end
        end
    end
end

-- Initialize tall boss fix (called once from UpdateDBCache)
function ns.InitTallBossFix()
    if tallBossFixInitialized then return end
    tallBossFixInitialized = true
    
    -- Always extend WorldFrame
    ApplyWorldFrameExtension()
    
    -- Register for screen changes
    TallBossFrame:RegisterEvent("UI_SCALE_CHANGED")
    TallBossFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    TallBossFrame:SetScript("OnEvent", OnTallBossEvent)
    
    -- Apply static clamp to any already-visible enemy plates (in case init happens late)
    if not ns.c_stackingEnabled then
        for nameplate in EnumerateActiveNamePlates() do
            local unit = nameplate._unit
            if nameplate:IsShown() and unit
               and not UnitIsUnit(unit, "player")
               and not UnitIsFriend("player", unit)
               and not (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
                ApplyStaticClamp(nameplate)
            end
        end
    end
end

-- ==========================================================================
-- SLASH COMMAND
-- ==========================================================================

-- Get current pool stats
function ns.GetStackingStats()
    local activePlates = 0
    for _ in pairs(StackingPlates) do
        activePlates = activePlates + 1
    end
    return {
        activePlates = activePlates,
        dataPoolSize = dataPoolIndex,
        entryPoolSize = #entryPool,
    }
end

-- Slash command handler (called from Core.lua)
function ns.HandleStackingCommand(args)
    if args == "stats" then
        local stats = ns.GetStackingStats()
        print(("[TurboPlates Stacking] Active: %d, DataPool: %d, EntryPool: %d"):format(
            stats.activePlates, stats.dataPoolSize, stats.entryPoolSize
        ))
    else
        print("|cff00ff00[TurboPlates Stacking Commands]|r")
        print("  /tp stacking stats - Show pool statistics")
    end
end
