local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

-- Register TurboPlates bundled fonts with LSM
for _, fontEntry in ipairs(ns.Fonts) do
    LSM:Register("font", fontEntry.name, fontEntry.path)
end

-- Register TurboPlates bundled textures with LSM
for _, texEntry in ipairs(ns.Textures) do
    LSM:Register("statusbar", texEntry.name, texEntry.path)
end

-- Get list of all available fonts from LSM
function ns.GetLSMFonts()
    local list = LSM:List("font")
    local options = {}
    for i, name in ipairs(list) do
        options[i] = { name = name, value = name }
    end
    return options
end

-- Get list of all available textures from LSM
function ns.GetLSMTextures()
    local list = LSM:List("statusbar")
    local options = {}
    for i, name in ipairs(list) do
        options[i] = { name = name, value = name }
    end
    return options
end

-- Fetch font path by LSM name
function ns.GetFont(name)
    return LSM:Fetch("font", name) or LSM:Fetch("font", "Friz Quadrata TT")
end

-- Fetch texture path by LSM name
function ns.GetTexture(name)
    return LSM:Fetch("statusbar", name) or LSM:Fetch("statusbar", "Blizzard")
end

-- Store LSM reference for addon use
ns.LSM = LSM
