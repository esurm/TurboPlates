local addonName, ns = ...

-- =============================================================================
-- ServerData: Centralized spell/ID database per server profile
-- Shared   = works on any WotLK 3.3.5a server
-- Bronzebeard = IDs specific to Bronzebeard server (11xxxxx format, Ascension customs)
-- CoA      = IDs specific to Conquest of Azeroth (starts empty, fill as discovered)
-- Active   = composed at Init() = Shared + detected server's data
-- =============================================================================

local ServerData = {
    Active = {
        TurboDebuffs  = {},
        TotemIDs      = {},
        TankAuras     = {},
        VigilanceID   = nil,
    },
}

-- =============================================================================
-- SHARED: Standard WotLK spell IDs + any cross-server custom IDs
-- =============================================================================
ServerData.Shared = {
    TurboDebuffs = {
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
    },

    -- Standard WoW totem IDs (work on any 3.3.5a server)
    TotemIDs = {
        -- Fire Totems
        [2894] = true,   -- Fire Elemental Totem
        [8190] = true, [10585] = true, [10586] = true, [10587] = true,  -- Magma Totem
        [3599] = true, [6363] = true, [6364] = true, [6365] = true, [10437] = true, [10438] = true,  -- Searing Totem
        [8184] = true, [10537] = true, [10538] = true,  -- Fire Resistance Totem
        [8227] = true, [8249] = true, [10526] = true, [16387] = true,  -- Flametongue Totem
        -- Earth Totems
        [2484] = true,  -- Earthbind Totem
        [5730] = true, [6390] = true, [6391] = true, [6392] = true, [10427] = true, [10428] = true,  -- Stoneclaw Totem
        [2062] = true,  -- Earth Elemental Totem
        [8071] = true, [8154] = true, [8155] = true, [10406] = true, [10407] = true, [10408] = true,  -- Stoneskin Totem
        [8075] = true, [8160] = true, [8161] = true, [10442] = true, [25361] = true,  -- Strength of Earth Totem
        [8143] = true,  -- Tremor Totem
        -- Water Totems
        [8170] = true,  -- Cleansing Totem
        [5394] = true, [6375] = true, [6377] = true, [10462] = true, [10463] = true,  -- Healing Stream Totem
        [5675] = true, [10495] = true, [10496] = true, [10497] = true,  -- Mana Spring Totem
        [8181] = true, [10478] = true, [10479] = true,  -- Frost Resistance Totem
        [10595] = true, [10600] = true, [10601] = true,  -- Nature Resistance Totem
        -- Air Totems
        [3738] = true,  -- Wrath of Air Totem
        [8177] = true,  -- Grounding Totem
        -- Other Totems
        [30706] = true, [57720] = true,  -- Totem of Wrath (shared standard ranks)
        [16190] = true,  -- Mana Tide Totem (shared standard)
    },

    -- Shared tank auras (none currently - all are server-specific)
    TankAuras = {},

    -- Shared vigilance (none currently)
    VigilanceID = nil,
}

-- =============================================================================
-- BRONZEBEARD: Server-specific IDs (11xxxxx format, Ascension custom spells)
-- =============================================================================
ServerData.Bronzebeard = {
    TurboDebuffs = {
        -- Tree of Life (Bronzebeard custom IDs)
        [113891] = { type = "buffs_other" },  -- Tree of Life form
        [1134123] = {},                       -- Tree of Life aura - blocked

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
    },

    TotemIDs = {
        -- Fire Totems (11xxxxx Bronzebeard format)
        [1102894] = true,  -- Fire Elemental Totem
        [1108190] = true, [1110585] = true, [1110586] = true, [1110587] = true,  -- Magma Totem
        [1103599] = true, [1106363] = true, [1106364] = true, [1106365] = true, [1110437] = true, [1110438] = true,  -- Searing Totem
        [1108184] = true, [1110537] = true, [1110538] = true,  -- Fire Resistance Totem
        [1108227] = true, [1108249] = true, [1110526] = true, [1116387] = true,  -- Flametongue Totem
        -- Earth Totems
        [1102484] = true,  -- Earthbind Totem
        [1105730] = true, [1106390] = true, [1106391] = true, [1106392] = true, [1110427] = true, [110428] = true,  -- Stoneclaw Totem
        [1102062] = true,  -- Earth Elemental Totem
        [1108071] = true, [1108154] = true, [1108155] = true, [1110406] = true, [1110407] = true, [1110408] = true,  -- Stoneskin Totem
        [1108075] = true, [1108160] = true, [1108161] = true, [1110442] = true, [1125361] = true,  -- Strength of Earth Totem
        [1108143] = true,  -- Tremor Totem
        -- Water Totems
        [1108170] = true,  -- Cleansing Totem
        [1105394] = true, [1106375] = true, [1106377] = true, [1110462] = true, [1110463] = true,  -- Healing Stream Totem
        [1105675] = true, [1110495] = true, [1110496] = true, [1110497] = true,  -- Mana Spring Totem
        [1108181] = true, [1110478] = true, [1110479] = true,  -- Frost Resistance Totem
        [1110595] = true, [1110600] = true, [1110601] = true,  -- Nature Resistance Totem
        -- Air Totems
        [1103738] = true,  -- Wrath of Air Totem
        [1108177] = true,  -- Grounding Totem
        -- Other Totems
        [1130706] = true, [1157720] = true,  -- Totem of Wrath (Bronzebeard)
        [1116190] = true,  -- Mana Tide Totem (Bronzebeard)
        [2304590] = true,  -- Capacitor Totem (Ascension custom)
    },

    TankAuras = {
        [1182001] = true,  -- Shaman tank buff
        [1109634] = true,  -- Druid Bear Form
        [1125780] = true,  -- Paladin Righteous Fury
    },

    VigilanceID = 1150720,
}

-- =============================================================================
-- COA: Conquest of Azeroth IDs (starts empty, fill as discovered)
-- =============================================================================
ServerData.CoA = {
    TurboDebuffs  = {},
    TotemIDs      = {},
    TankAuras     = {},
    VigilanceID   = nil,
}

-- =============================================================================
-- INIT: Detect server and compose Active tables
-- =============================================================================
function ServerData:Init()
    -- Detect which server we're on
    ns.CoA:Detect()

    local server = ns.CoA.active and self.CoA or self.Bronzebeard

    -- Compose Active.TurboDebuffs = Shared + server-specific
    wipe(self.Active.TurboDebuffs)
    for k, v in pairs(self.Shared.TurboDebuffs) do
        self.Active.TurboDebuffs[k] = v
    end
    for k, v in pairs(server.TurboDebuffs) do
        self.Active.TurboDebuffs[k] = v
    end

    -- Compose Active.TotemIDs = Shared + server-specific
    wipe(self.Active.TotemIDs)
    for k, v in pairs(self.Shared.TotemIDs) do
        self.Active.TotemIDs[k] = v
    end
    for k, v in pairs(server.TotemIDs) do
        self.Active.TotemIDs[k] = v
    end

    -- Compose Active.TankAuras = Shared + server-specific
    wipe(self.Active.TankAuras)
    for k, v in pairs(self.Shared.TankAuras) do
        self.Active.TankAuras[k] = v
    end
    for k, v in pairs(server.TankAuras) do
        self.Active.TankAuras[k] = v
    end

    -- VigilanceID: server wins if set, otherwise shared
    self.Active.VigilanceID = server.VigilanceID or self.Shared.VigilanceID
end

ns.ServerData = ServerData
