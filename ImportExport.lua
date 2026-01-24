local _, ns = ...

local EXPORT_PREFIX = "!TP1!"
local LibDeflate = LibStub("LibDeflate")
local AceSerializer = LibStub("AceSerializer-3.0")

-- Deep copy helper for settings
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- Validate imported settings structure
-- Ensures nested tables exist and have correct types, fills missing fields from defaults
local function ValidateSettings(settings)
    if type(settings) ~= "table" then return false end
    
    -- List of nested table keys that must be tables
    local nestedTables = { "personal", "auras", "stacking", "turboDebuffs" }
    
    for _, key in ipairs(nestedTables) do
        if settings[key] ~= nil and type(settings[key]) ~= "table" then
            -- Invalid type - replace with defaults
            settings[key] = ns.defaults[key] and DeepCopy(ns.defaults[key]) or nil
        elseif settings[key] and ns.defaults[key] then
            -- Fill missing subkeys from defaults
            for subKey, subVal in pairs(ns.defaults[key]) do
                if settings[key][subKey] == nil then
                    settings[key][subKey] = DeepCopy(subVal)
                end
            end
        end
    end
    
    -- Color tables that must have r/g/b fields
    local colorKeys = {
        "hpColor", "castColor", "noInterruptColor", "petColor",
        "targetGlowColor", "tappedColor", "hostileNameColor",
        "secureColor", "transColor", "insecureColor", "offTankColor",
        "dpsSecureColor", "dpsTransColor", "dpsAggroColor",
        "highlightGlowColor", "targetingMeColor"
    }
    
    for _, key in ipairs(colorKeys) do
        if settings[key] ~= nil then
            if type(settings[key]) ~= "table" or settings[key].r == nil then
                -- Invalid color - replace with default
                settings[key] = ns.defaults[key] and DeepCopy(ns.defaults[key]) or nil
            end
        end
    end
    
    -- Minimap settings table
    if settings.minimap ~= nil and type(settings.minimap) ~= "table" then
        settings.minimap = ns.defaults.minimap and DeepCopy(ns.defaults.minimap) or { hide = false, pos = 45 }
    end
    
    -- Nested color tables (inside personal, auras, etc.)
    if settings.personal and type(settings.personal) == "table" then
        if settings.personal.healthColor and (type(settings.personal.healthColor) ~= "table" or settings.personal.healthColor.r == nil) then
            settings.personal.healthColor = ns.defaults.personal and DeepCopy(ns.defaults.personal.healthColor) or nil
        end
    end
    
    if settings.auras and type(settings.auras) == "table" then
        if settings.auras.debuffBorderColor and (type(settings.auras.debuffBorderColor) ~= "table" or settings.auras.debuffBorderColor.r == nil) then
            settings.auras.debuffBorderColor = ns.defaults.auras and DeepCopy(ns.defaults.auras.debuffBorderColor) or nil
        end
        if settings.auras.buffBorderColor and (type(settings.auras.buffBorderColor) ~= "table" or settings.auras.buffBorderColor.r == nil) then
            settings.auras.buffBorderColor = ns.defaults.auras and DeepCopy(ns.defaults.auras.buffBorderColor) or nil
        end
        -- Ensure blacklist/whitelist are tables
        if settings.auras.blacklist ~= nil and type(settings.auras.blacklist) ~= "table" then
            settings.auras.blacklist = {}
        end
        if settings.auras.whitelist ~= nil and type(settings.auras.whitelist) ~= "table" then
            settings.auras.whitelist = {}
        end
    end
    
    -- TurboDebuffs priority table
    if settings.turboDebuffs and type(settings.turboDebuffs) == "table" then
        if settings.turboDebuffs.priority ~= nil and type(settings.turboDebuffs.priority) ~= "table" then
            settings.turboDebuffs.priority = ns.defaults.turboDebuffs and DeepCopy(ns.defaults.turboDebuffs.priority) or nil
        end
    end
    
    return true
end

-- Export current settings to encoded string
-- options: { settings = bool, highlights = bool, whitelist = bool, blacklist = bool }
function ns:ExportSettings(options)
    if not TurboPlatesDB then
        return nil, "No settings to export"
    end
    
    -- Default: export everything
    options = options or { settings = true, highlights = true, whitelist = true, blacklist = true }
    
    -- Check if anything is selected
    if not options.settings and not options.highlights and not options.whitelist and not options.blacklist then
        return nil, "No categories selected"
    end
    
    local exportData = {}
    
    -- Settings: everything except highlightSpells and auras.whitelist/blacklist
    if options.settings then
        for k, v in pairs(TurboPlatesDB) do
            if k ~= "highlightSpells" then
                if k == "auras" and type(v) == "table" then
                    -- Copy auras table without whitelist/blacklist
                    exportData.auras = {}
                    for ak, av in pairs(v) do
                        if ak ~= "whitelist" and ak ~= "blacklist" then
                            exportData.auras[ak] = DeepCopy(av)
                        end
                    end
                else
                    exportData[k] = DeepCopy(v)
                end
            end
        end
    end
    
    -- Spell Highlights
    if options.highlights and TurboPlatesDB.highlightSpells then
        exportData.highlightSpells = DeepCopy(TurboPlatesDB.highlightSpells)
    end
    
    -- Aura Whitelist
    if options.whitelist and TurboPlatesDB.auras and TurboPlatesDB.auras.whitelist then
        if not exportData.auras then exportData.auras = {} end
        exportData.auras.whitelist = DeepCopy(TurboPlatesDB.auras.whitelist)
    end
    
    -- Aura Blacklist
    if options.blacklist and TurboPlatesDB.auras and TurboPlatesDB.auras.blacklist then
        if not exportData.auras then exportData.auras = {} end
        exportData.auras.blacklist = DeepCopy(TurboPlatesDB.auras.blacklist)
    end
    
    -- Check if we have anything to export
    if not next(exportData) then
        return nil, "No data to export"
    end
    
    local serialized = AceSerializer:Serialize(exportData)
    if not serialized then
        return nil, "Serialization failed"
    end
    
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    if not compressed then
        return nil, "Compression failed"
    end
    
    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return nil, "Encoding failed"
    end
    
    return EXPORT_PREFIX .. encoded
end

-- Import settings from encoded string
-- options: { settings = bool, highlights = bool, whitelist = bool, blacklist = bool }
function ns:ImportSettings(importString, options)
    if not importString or importString == "" then
        return false, "Empty import string"
    end
    
    -- Default: import everything
    options = options or { settings = true, highlights = true, whitelist = true, blacklist = true }
    
    -- Check if anything is selected
    if not options.settings and not options.highlights and not options.whitelist and not options.blacklist then
        return false, "No categories selected"
    end
    
    -- Trim whitespace
    importString = importString:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Validate prefix
    if not importString:find("^" .. EXPORT_PREFIX:gsub("!", "%%!")) then
        return false, "Invalid format (missing TurboPlates prefix)"
    end
    
    -- Strip prefix
    local data = importString:sub(#EXPORT_PREFIX + 1)
    
    local decoded = LibDeflate:DecodeForPrint(data)
    if not decoded then
        return false, "Decode failed - invalid string"
    end
    
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return false, "Decompression failed - corrupted data"
    end
    
    local success, settings = AceSerializer:Deserialize(decompressed)
    if not success or type(settings) ~= "table" then
        return false, "Deserialize failed - invalid data"
    end
    
    -- Validate and repair settings structure (only if importing settings)
    if options.settings then
        if not ValidateSettings(settings) then
            return false, "Validation failed - malformed settings"
        end
    end
    
    -- Apply imported data based on selected categories
    local imported = {}
    
    -- Settings: everything except highlightSpells and auras.whitelist/blacklist
    if options.settings then
        for k, v in pairs(settings) do
            if k ~= "highlightSpells" then
                if k == "auras" and type(v) == "table" then
                    -- Merge auras but preserve whitelist/blacklist unless selected
                    if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
                    for ak, av in pairs(v) do
                        if ak ~= "whitelist" and ak ~= "blacklist" then
                            TurboPlatesDB.auras[ak] = av
                        end
                    end
                else
                    TurboPlatesDB[k] = v
                end
            end
        end
        table.insert(imported, "Settings")
    end
    
    -- Spell Highlights
    if options.highlights and settings.highlightSpells then
        TurboPlatesDB.highlightSpells = settings.highlightSpells
        table.insert(imported, "Spell Highlights")
    end
    
    -- Aura Whitelist
    if options.whitelist and settings.auras and settings.auras.whitelist then
        if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
        TurboPlatesDB.auras.whitelist = settings.auras.whitelist
        table.insert(imported, "Whitelist")
    end
    
    -- Aura Blacklist
    if options.blacklist and settings.auras and settings.auras.blacklist then
        if not TurboPlatesDB.auras then TurboPlatesDB.auras = {} end
        TurboPlatesDB.auras.blacklist = settings.auras.blacklist
        table.insert(imported, "Blacklist")
    end
    
    if #imported == 0 then
        return false, "No matching data found in string"
    end
    
    return true, "Imported: " .. table.concat(imported, ", ")
end
