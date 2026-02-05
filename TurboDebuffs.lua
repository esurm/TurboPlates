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
-- SPELL DATABASE (from BigDebuffs)
-- Categories: immunities, cc, silence, interrupts, roots, disarm,
--             buffs_defensive, buffs_offensive, buffs_other, snare
-- =============================================================================
local Spells = {
    -- Death Knight
    [48707] = { type = "immunities" },  -- Anti-Magic Shell
    [49203] = { type = "cc" },          -- Hungering Cold
    [51209] = { parent = 49203 },
    [47476] = { type = "silence" },     -- Strangulate
    [47528] = { type = "interrupts", duration = 4 },  -- Mind Freeze
    [49039] = { type = "buffs_defensive" },  -- Lichborne
    [48792] = { type = "buffs_defensive" },  -- Icebound Fortitude
    [50461] = { type = "buffs_defensive" },  -- Anti-Magic Zone
    [49028] = { type = "buffs_offensive" },  -- Dancing Rune Weapon
    [45524] = { type = "snare" },       -- Chains of Ice
    [55666] = { type = "snare" },       -- Desecration
    [68766] = { parent = 55666 },
    [55741] = { parent = 55666 },
    [58617] = { type = "snare" },       -- Glyph of Heart Strike
    [50436] = { type = "snare" },       -- Icy Clutch (Chilblains)
    -- Death Knight Pet
    [47481] = { type = "cc" },          -- Gnaw (Ghoul)
    [47484] = { type = "buffs_defensive" },  -- Huddle (Ghoul)
    
    -- Druid
    [33786] = { type = "cc" },          -- Cyclone
    [49802] = { type = "cc" },          -- Maim
    [22570] = { parent = 49802 },
    [8983] = { type = "cc" },           -- Bash
    [5211] = { parent = 8983 },
    [6798] = { parent = 8983 },
    [18658] = { type = "cc" },          -- Hibernate
    [2637] = { parent = 18658 },
    [18657] = { parent = 18658 },
    [49803] = { type = "cc" },          -- Pounce
    [9005] = { parent = 49803 },
    [9823] = { parent = 49803 },
    [9827] = { parent = 49803 },
    [27006] = { parent = 49803 },
    [16979] = { type = "interrupts", duration = 4 },  -- Feral Charge (Interrupt)
    [45334] = { type = "roots" },       -- Feral Charge (Immobilize)
    [53308] = { type = "roots" },       -- Entangling Roots
    [339] = { parent = 53308 },
    [1062] = { parent = 53308 },
    [5195] = { parent = 53308 },
    [5196] = { parent = 53308 },
    [9852] = { parent = 53308 },
    [9853] = { parent = 53308 },
    [26989] = { parent = 53308 },
    [53313] = { parent = 53308 },       -- From Nature's Grasp
    [17116] = { type = "buffs_defensive" },  -- Nature's Swiftness
    [61336] = { type = "buffs_defensive" },  -- Survival Instincts
    [22812] = { type = "buffs_defensive" },  -- Barkskin
    [29166] = { type = "buffs_offensive" },  -- Innervate
    [54833] = { parent = 29166 },       -- Glyph Innervate
    [50334] = { type = "buffs_offensive" },  -- Berserk
    [69369] = { type = "buffs_offensive" },  -- Predator's Swiftness
    [53201] = { type = "buffs_offensive" },  -- Starfall
    [48505] = { parent = 53201 },
    [53199] = { parent = 53201 },
    [53200] = { parent = 53201 },
    [53312] = { type = "buffs_other" }, -- Nature's Grasp
    [33357] = { type = "buffs_other" }, -- Dash
    [768] = { type = "buffs_other" },   -- Cat Form
    [9634] = { type = "buffs_other" },  -- Dire Bear Form
    [783] = { type = "buffs_other" },   -- Travel Form
    [24858] = { type = "buffs_other" }, -- Moonkin Form
    [33891] = {},                       -- Tree of Life (A52) - blocked
    [34123] = {},                       -- Tree of Life aura (A52) - blocked
    [113891] = { type = "buffs_other" }, -- Tree of Life form (Bronzebeard)
    [1134123] = {},                     -- Tree of Life aura (Bronzebeard) - blocked
    [58179] = { type = "snare" },       -- Infected Wounds
    [58181] = { parent = 58179 },
    [61391] = { type = "snare" },       -- Typhoon
    [61390] = { parent = 61391 },
    [61388] = { parent = 61391 },
    [61387] = { parent = 61391 },
    [53227] = { parent = 61391 },
    [50259] = { type = "snare" },       -- Dazed (Feral Charge cat)
    [50411] = { parent = 50259 },
    
    -- Hunter
    [34471] = { type = "immunities" },  -- The Beast Within
    [34692] = { parent = 34471 },
    [19263] = { type = "immunities" },  -- Deterrence
    [24394] = { type = "cc" },          -- Intimidation (Stun)
    [49012] = { type = "cc" },          -- Wyvern Sting
    [19386] = { parent = 49012 },
    [24132] = { parent = 49012 },
    [24133] = { parent = 49012 },
    [27068] = { parent = 49012 },
    [49011] = { parent = 49012 },
    [19503] = { type = "cc" },          -- Scatter Shot
    [14309] = { type = "cc" },          -- Freezing Trap
    [3355] = { parent = 14309 },
    [14308] = { parent = 14309 },
    [60210] = { type = "cc" },          -- Freezing Arrow Effect
    [14327] = { type = "cc" },          -- Scare Beast
    [1513] = { parent = 14327 },
    [14326] = { parent = 14327 },
    [34490] = { type = "silence" },     -- Silencing Shot
    [48999] = { type = "roots" },       -- Counterattack
    [19306] = { parent = 48999 },
    [20909] = { parent = 48999 },
    [20910] = { parent = 48999 },
    [27067] = { parent = 48999 },
    [48998] = { parent = 48999 },
    [19185] = { type = "roots" },       -- Entrapment
    [64803] = { parent = 19185 },
    [19388] = { parent = 19185 },
    [19184] = { parent = 19185 },
    [19387] = { parent = 19185 },
    [64804] = { parent = 19185 },
    [53359] = { type = "disarm" },      -- Chimera Shot - Scorpid
    [5384] = { type = "buffs_defensive" },   -- Feign Death
    [54216] = { type = "buffs_defensive" },  -- Master's Call
    [62305] = { parent = 54216 },
    [3034] = { type = "buffs_other" },  -- Viper Sting
    [5118] = { type = "buffs_other" },  -- Aspect of the Cheetah
    [13159] = { parent = 5118 },        -- Aspect of the Pack
    [35101] = { type = "snare" },       -- Concussive Barrage
    [5116] = { type = "snare" },        -- Concussive Shot
    [13810] = { type = "snare" },       -- Frost Trap Aura
    [61394] = { type = "snare" },       -- Glyph of Freezing Trap
    [2974] = { type = "snare" },        -- Wing Clip
    [15571] = { parent = 50259 },       -- Dazed (from Hunter)
    [30981] = { type = "snare" },       -- Crippling Poison (Serpent Sting)
    
    -- Hunter Pets
    [19574] = { type = "immunities" },  -- Bestial Wrath (Pet)
    [53562] = { type = "cc" },          -- Ravage (Pet)
    [50518] = { parent = 53562 },
    [50519] = { type = "cc" },          -- Sonic Blast (Bat)
    [53568] = { parent = 50519 },
    [53564] = { parent = 50519 },
    [53565] = { parent = 50519 },
    [53566] = { parent = 50519 },
    [53567] = { parent = 50519 },
    [26090] = { type = "interrupts", duration = 2 },  -- Pummel (Pet)
    [53548] = { type = "roots" },       -- Pin (Pet)
    [50245] = { parent = 53548 },
    [53544] = { parent = 53548 },
    [53545] = { parent = 53548 },
    [53546] = { parent = 53548 },
    [53547] = { parent = 53548 },
    [4167] = { type = "roots" },        -- Web (Pet)
    [54706] = { type = "roots" },       -- Venom Web Spray (Silithid)
    [55509] = { parent = 54706 },
    [55505] = { parent = 54706 },
    [55506] = { parent = 54706 },
    [55507] = { parent = 54706 },
    [55508] = { parent = 54706 },
    [53148] = { type = "roots" },       -- Charge (Immobilize)
    [53543] = { type = "disarm" },      -- Snatch (Pet Disarm)
    [50541] = { parent = 53543 },
    [53537] = { parent = 53543 },
    [53538] = { parent = 53543 },
    [53540] = { parent = 53543 },
    [53542] = { parent = 53543 },
    [53480] = { type = "buffs_defensive" },  -- Roar of Sacrifice
    [53476] = { type = "buffs_defensive" },  -- Intervene (Pet)
    [1742] = { type = "buffs_defensive" },   -- Cower (Pet)
    [26064] = { type = "buffs_defensive" },  -- Shell Shield (Pet)
    [54644] = { type = "snare" },       -- Froststorm Breath (Chimera)
    [50271] = { type = "snare" },       -- Tendon Rip (Hyena)
    [53575] = { parent = 50271 },
    
    -- Mage
    [45438] = { type = "immunities" },  -- Ice Block
    [118] = { type = "cc" },            -- Polymorph
    [12824] = { parent = 118 },
    [12825] = { parent = 118 },
    [12826] = { parent = 118 },
    [61780] = { parent = 118 },
    [71319] = { parent = 118 },
    [61025] = { parent = 118 },
    [28271] = { parent = 118 },
    [28272] = { parent = 118 },
    [61305] = { parent = 118 },
    [61721] = { parent = 118 },
    [42950] = { type = "cc" },          -- Dragon's Breath
    [31661] = { parent = 42950 },
    [33041] = { parent = 42950 },
    [33042] = { parent = 42950 },
    [33043] = { parent = 42950 },
    [42949] = { parent = 42950 },
    [44572] = { type = "cc" },          -- Deep Freeze
    [12355] = { type = "cc" },          -- Impact
    [55021] = { type = "silence" },     -- Improved Counterspell
    [18469] = { parent = 55021 },
    [2139] = { type = "interrupts", duration = 8 },  -- Counterspell
    [12494] = { type = "roots" },       -- Frostbite
    [11071] = { parent = 12494 },
    [122] = { type = "roots" },         -- Frost Nova
    [42917] = { parent = 122 },
    [865] = { parent = 122 },
    [6131] = { parent = 122 },
    [10230] = { parent = 122 },
    [27088] = { parent = 122 },
    [55080] = { type = "roots" },       -- Shattered Barrier
    [64346] = { type = "disarm" },      -- Fiery Payback
    [54748] = { type = "buffs_defensive" },  -- Burning Determination
    [12472] = { type = "buffs_offensive" },  -- Icy Veins
    [12042] = { type = "buffs_offensive" },  -- Arcane Power
    [12043] = { type = "buffs_offensive" },  -- Presence of Mind
    [12051] = { type = "buffs_offensive" },  -- Evocation
    [44544] = { type = "buffs_offensive" },  -- Fingers of Frost
    [66] = { type = "buffs_offensive" },     -- Invisibility
    [32612] = { parent = 66 },
    [43039] = { type = "buffs_other" }, -- Ice Barrier
    [11426] = { parent = 43039 },
    [13031] = { parent = 43039 },
    [13032] = { parent = 43039 },
    [13033] = { parent = 43039 },
    [27134] = { parent = 43039 },
    [33405] = { parent = 43039 },
    [43038] = { parent = 43039 },
    [43020] = { type = "buffs_other" }, -- Mana Shield
    [1463] = { parent = 43020 },
    [8494] = { parent = 43020 },
    [8495] = { parent = 43020 },
    [10191] = { parent = 43020 },
    [10192] = { parent = 43020 },
    [10193] = { parent = 43020 },
    [27131] = { parent = 43020 },
    [43019] = { parent = 43020 },
    [43012] = { type = "buffs_other" }, -- Frost Ward
    [6143] = { parent = 43012 },
    [8461] = { parent = 43012 },
    [8462] = { parent = 43012 },
    [10177] = { parent = 43012 },
    [28609] = { parent = 43012 },
    [32796] = { parent = 43012 },
    [43010] = { type = "buffs_other" }, -- Fire Ward
    [543] = { parent = 43010 },
    [8457] = { parent = 43010 },
    [8458] = { parent = 43010 },
    [10223] = { parent = 43010 },
    [10225] = { parent = 43010 },
    [27128] = { parent = 43010 },
    [11113] = { type = "snare" },       -- Blast Wave
    [42945] = { parent = 11113 },
    [71151] = { parent = 11113 },
    [6136] = { type = "snare" },        -- Chilled
    [120] = { type = "snare" },         -- Cone of Cold
    [65023] = { parent = 120 },
    [42930] = { parent = 120 },
    [42931] = { parent = 120 },
    [27087] = { parent = 120 },
    [10161] = { parent = 120 },
    [10160] = { parent = 120 },
    [10159] = { parent = 120 },
    [8492] = { parent = 120 },
    [116] = { type = "snare" },         -- Frostbolt
    [47610] = { type = "snare" },       -- Frostfire Bolt
    [31589] = { type = "snare" },       -- Slow
    [20005] = { type = "snare" },       -- Chilled (talent)
    [7321] = { parent = 20005 },
    -- Mage Pet
    [33395] = { type = "roots" },       -- Freeze (Water Elemental)
    
    -- Paladin
    [642] = { type = "immunities" },    -- Divine Shield
    [19753] = { type = "immunities" },  -- Divine Intervention
    [10278] = { type = "immunities" },  -- Hand of Protection
    [5599] = { parent = 10278 },
    [1022] = { parent = 10278 },
    [20066] = { type = "cc" },          -- Repentance
    [10308] = { type = "cc" },          -- Hammer of Justice
    [853] = { parent = 10308 },
    [5588] = { parent = 10308 },
    [5589] = { parent = 10308 },
    [10326] = { type = "cc" },          -- Turn Evil
    [48817] = { type = "cc" },          -- Holy Wrath
    [2812] = { parent = 48817 },
    [10318] = { parent = 48817 },
    [27139] = { parent = 48817 },
    [48816] = { parent = 48817 },
    [20170] = { type = "cc" },          -- Seal of Justice Stun
    [63529] = { type = "silence" },     -- Silenced - Shield of the Templar
    [31821] = { type = "buffs_defensive" },  -- Aura Mastery
    [54428] = { type = "buffs_defensive" },  -- Divine Plea
    [53563] = { type = "buffs_defensive" },  -- Beacon of Light
    [498] = { type = "buffs_defensive" },    -- Divine Protection
    [6940] = { type = "buffs_defensive" },   -- Hand of Sacrifice
    [1044] = { type = "buffs_defensive" },   -- Hand of Freedom
    [64205] = { type = "buffs_defensive" },  -- Divine Sacrifice
    [53659] = { type = "buffs_defensive" },  -- Sacred Cleansing
    [31884] = { type = "buffs_offensive" },  -- Avenging Wrath
    [58597] = { type = "buffs_other" }, -- Sacred Shield Proc
    [59578] = { type = "buffs_other" }, -- The Art of War
    [20184] = { type = "snare" },       -- Judgement of Justice
    [48827] = { type = "snare" },       -- Avenger's Shield
    
    -- Priest
    [64044] = { type = "cc" },          -- Psychic Horror (Horrify)
    [10890] = { type = "cc" },          -- Psychic Scream
    [8122] = { parent = 10890 },
    [8124] = { parent = 10890 },
    [10888] = { parent = 10890 },
    [605] = { type = "cc" },            -- Mind Control
    [10955] = { type = "cc" },          -- Shackle Undead
    [9484] = { parent = 10955 },
    [9485] = { parent = 10955 },
    [15487] = { type = "silence" },     -- Silence
    [64058] = { type = "disarm" },      -- Psychic Horror (Disarm)
    [47585] = { type = "buffs_defensive" },  -- Dispersion
    [20711] = { type = "buffs_defensive" },  -- Spirit of Redemption
    [47788] = { type = "buffs_defensive" },  -- Guardian Spirit
    [33206] = { type = "buffs_defensive" },  -- Pain Suppression
    [10060] = { type = "buffs_offensive" },  -- Power Infusion
    [6346] = { type = "buffs_other" },  -- Fear Ward
    [48066] = { type = "buffs_other" }, -- Power Word: Shield
    [17] = { parent = 48066 },
    [592] = { parent = 48066 },
    [600] = { parent = 48066 },
    [3747] = { parent = 48066 },
    [6065] = { parent = 48066 },
    [6066] = { parent = 48066 },
    [10898] = { parent = 48066 },
    [10899] = { parent = 48066 },
    [10900] = { parent = 48066 },
    [10901] = { parent = 48066 },
    [25217] = { parent = 48066 },
    [25218] = { parent = 48066 },
    [48065] = { parent = 48066 },
    [48156] = { type = "snare" },       -- Mind Flay
    
    -- Rogue
    [51690] = { type = "immunities" },  -- Killing Spree
    [31224] = { type = "immunities" },  -- Cloak of Shadows
    [1776] = { type = "cc" },           -- Gouge
    [2094] = { type = "cc" },           -- Blind
    [8643] = { type = "cc" },           -- Kidney Shot
    [408] = { parent = 8643 },
    [51724] = { type = "cc" },          -- Sap
    [6770] = { parent = 51724 },
    [2070] = { parent = 51724 },
    [11297] = { parent = 51724 },
    [1833] = { type = "cc" },           -- Cheap Shot
    [1330] = { type = "silence" },      -- Garrote - Silence
    [18425] = { type = "silence" },     -- Silence (Improved Kick)
    [1766] = { type = "interrupts", duration = 5 },  -- Kick
    [51722] = { type = "disarm" },      -- Dismantle
    [26669] = { type = "buffs_defensive" },  -- Evasion
    [5277] = { parent = 26669 },
    [51713] = { type = "buffs_offensive" },  -- Shadow Dance
    [11305] = { type = "buffs_other" }, -- Sprint
    [51693] = { type = "snare" },       -- Ambush proc
    [31125] = { type = "snare" },       -- Blade Twisting
    [51585] = { parent = 31125 },
    [3409] = { parent = 30981 },        -- Crippling Poison
    [26679] = { type = "snare" },       -- Deadly Throw
    
    -- Shaman
    [8178] = { type = "immunities" },   -- Grounding Totem Effect
    [58861] = { parent = 8983 },        -- Bash (Spirit Wolf)
    [51514] = { type = "cc" },          -- Hex
    [39796] = { type = "cc" },          -- Stoneclaw Stun
    [57994] = { type = "interrupts", duration = 2 },  -- Wind Shear
    [63685] = { type = "roots" },       -- Freeze (Enhancement)
    [64695] = { type = "roots" },       -- Earthgrab (Elemental)
    [30823] = { type = "buffs_defensive" },  -- Shamanistic Rage
    [16188] = { parent = 17116 },       -- Nature's Swiftness
    [16166] = { type = "buffs_offensive" },  -- Elemental Mastery
    [2825] = { type = "buffs_offensive" },   -- Bloodlust
    [32182] = { type = "buffs_offensive" },  -- Heroism
    [58875] = { type = "buffs_other" }, -- Spirit Walk
    [55277] = { type = "buffs_other" }, -- Stoneclaw Totem (Absorb)
    [3600] = { type = "snare" },        -- Earthbind
    [8056] = { type = "snare" },        -- Frost Shock
    [49235] = { parent = 8056 },
    [49236] = { parent = 8056 },
    [25464] = { parent = 8056 },
    [10473] = { parent = 8056 },
    [10472] = { parent = 8056 },
    [8058] = { parent = 8056 },
    [8034] = { type = "snare" },        -- Frostbrand Attack
    [58799] = { parent = 8034 },
    [58798] = { parent = 8034 },
    [58797] = { parent = 8034 },
    [25501] = { parent = 8034 },
    [16353] = { parent = 8034 },
    [16352] = { parent = 8034 },
    [10458] = { parent = 8034 },
    [8037] = { parent = 8034 },
    
    -- Warlock
    [60995] = { type = "cc" },          -- Demon Charge (Metamorphosis)
    [47847] = { type = "cc" },          -- Shadowfury
    [30283] = { parent = 47847 },
    [30413] = { parent = 47847 },
    [30414] = { parent = 47847 },
    [47846] = { parent = 47847 },
    [18647] = { type = "cc" },          -- Banish
    [710] = { parent = 18647 },
    [47860] = { type = "cc" },          -- Death Coil
    [6789] = { parent = 47860 },
    [17925] = { parent = 47860 },
    [17926] = { parent = 47860 },
    [27223] = { parent = 47860 },
    [47859] = { parent = 47860 },
    [6358] = { type = "cc" },           -- Seduction
    [6215] = { type = "cc" },           -- Fear
    [5782] = { parent = 6215 },
    [6213] = { parent = 6215 },
    [17928] = { type = "cc" },          -- Howl of Terror
    [5484] = { parent = 17928 },
    [47995] = { type = "cc" },          -- Intercept (Felguard)
    [25274] = { parent = 47995 },
    [30153] = { parent = 47995 },
    [30195] = { parent = 47995 },
    [30197] = { parent = 47995 },
    [22703] = { type = "cc" },          -- Infernal stun
    [32752] = { type = "cc" },          -- Summoning Disorientation
    [31117] = { type = "silence" },     -- Unstable Affliction (Silence)
    [24259] = { type = "silence" },     -- Spell Lock (Silence)
    [19647] = { type = "interrupts", duration = 6 },  -- Spell Lock (Interrupt)
    [19244] = { parent = 19647, duration = 5 },
    [18708] = { type = "buffs_defensive" },  -- Fel Domination
    [47241] = { type = "buffs_offensive" },  -- Metamorphosis
    [11719] = { type = "buffs_offensive" },  -- Curse of Tongues
    [1714] = { parent = 11719 },
    [47986] = { type = "buffs_other" }, -- Sacrifice
    [18118] = { type = "snare" },       -- Aftermath
    [18223] = { type = "snare" },       -- Curse of Exhaustion
    [63311] = { type = "snare" },       -- Shadowflame
    [60947] = { type = "snare" },       -- Nightmare
    [60946] = { parent = 60947 },
    
    -- Warrior
    [46924] = { type = "immunities" },  -- Bladestorm
    [23920] = { type = "immunities" },  -- Spell Reflection
    [59725] = { parent = 23920 },
    [12809] = { type = "cc" },          -- Concussion Blow
    [12798] = { type = "cc" },          -- Revenge Stun
    [46968] = { type = "cc" },          -- Shockwave
    [5246] = { type = "cc" },           -- Intimidating Shout (Non-Target)
    [20511] = { parent = 5246 },        -- Intimidating Shout (Target)
    [7922] = { type = "cc" },           -- Charge
    [20253] = { parent = 47995 },       -- Intercept
    [18498] = { type = "silence" },     -- Silenced - Gag Order
    [6552] = { type = "interrupts", duration = 4 },  -- Pummel
    [72] = { type = "interrupts", duration = 6 },    -- Shield Bash
    [58373] = { type = "roots" },       -- Glyph of Hamstring
    [23694] = { type = "roots" },       -- Improved Hamstring
    [676] = { type = "disarm" },        -- Disarm
    [12975] = { type = "buffs_defensive" },  -- Last Stand
    [55694] = { type = "buffs_defensive" },  -- Enraged Regeneration
    [871] = { type = "buffs_defensive" },    -- Shield Wall
    [3411] = { type = "buffs_defensive" },   -- Intervene
    [2565] = { type = "buffs_defensive" },   -- Shield Block
    [20230] = { type = "buffs_defensive" },  -- Retaliation
    [18499] = { type = "buffs_defensive" },  -- Berserker Rage
    [1719] = { type = "buffs_offensive" },   -- Recklessness
    [2457] = { type = "buffs_other" },  -- Battle Stance
    [2458] = { type = "buffs_other" },  -- Berserker Stance
    [71] = { type = "buffs_other" },    -- Defensive Stance
    [1715] = { type = "snare" },        -- Hamstring
    [12323] = { type = "snare" },       -- Piercing Howl
    
    -- Misc / Racials / Engineering
    [6615] = { type = "immunities" },   -- Free Action Potion
    [24364] = { type = "immunities" },  -- Living Free Action
    [20549] = { type = "cc" },          -- War Stomp
    [13181] = { type = "cc" },          -- Gnomish Mind Control Cap
    [13327] = { type = "cc" },          -- Reckless Charge
    [71988] = { type = "cc" },          -- Vile Fumes
    [30217] = { type = "cc" },          -- Adamantite Grenade
    [67890] = { parent = 30217 },
    [67769] = { type = "cc" },          -- Cobalt Frag Bomb
    [30216] = { type = "cc" },          -- Fel Iron Bomb
    [50396] = { type = "cc" },          -- Psychosis (PvE)
    [20685] = { type = "cc" },          -- Storm Hammer (PvE)
    [19821] = { type = "silence" },     -- Arcane Bomb
    [28730] = { type = "silence" },     -- Arcane Torrent (Mana)
    [25046] = { parent = 28730 },       -- Arcane Torrent (Energy)
    [50613] = { parent = 28730 },       -- Arcane Torrent (Runic Power)
    [39965] = { type = "roots" },       -- Frost Grenade
    [55536] = { type = "roots" },       -- Frostweave Net
    [13099] = { type = "roots" },       -- Net-o-Matic
    [14030] = { type = "roots" },       -- Hooked Net
    [43183] = { type = "buffs_other" }, -- Drink (Arena/Lvl 80 Water)
    [57073] = { parent = 43183 },       -- Mage Water
    [71586] = { type = "buffs_other" }, -- Hardened Skin
    [29703] = { parent = 50259 },       -- Dazed
    
    -- Ascension Custom Spells
    [2304523] = { type = "silence" },
    [2304507] = { type = "roots" },
    [2304504] = { type = "roots" },
    [1590930] = { type = "cc" },
    [1398188] = { type = "cc" },
    [1133071] = { type = "cc" },
    [1180050] = { type = "cc" },
    [1398183] = { type = "cc" },
    [1398198] = { type = "cc" },
    [1398221] = { type = "cc" },
    [1398158] = { type = "buffs_defensive" },
    [1143163] = { type = "buffs_defensive" },
    [1398157] = { type = "buffs_defensive" },
    [1398189] = { type = "buffs_defensive" },
    [1180520] = { type = "buffs_defensive" },
    [1318221] = { type = "buffs_defensive" },
    [1182049] = { type = "buffs_defensive" },
    [1398160] = { type = "buffs_defensive" },
    [1398195] = { type = "buffs_defensive" },
    [1398197] = { type = "buffs_defensive" },
    [1398215] = { type = "buffs_offensive" },
    [1180100] = { type = "buffs_offensive" },
    [1180002] = { type = "buffs_offensive" },
    [1398218] = { type = "buffs_offensive" },
    [1398159] = { type = "buffs_offensive" },
    [1180009] = { type = "buffs_offensive" },
    [991022] = { type = "buffs_other" },
    [1186380] = { type = "buffs_defensive" },
}

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
    frame.timer:SetFont(font, timerSize, "OUTLINE")
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
            frame.timer:SetFont(font, timerSize, "OUTLINE")
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
            frame.timer:SetFont(font, timerSize, "OUTLINE")
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
