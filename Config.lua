local addonName, ns = ...

-- Get version from TOC file
local version = GetAddOnMetadata(addonName, "Version") or "1.0.0"

ns.L = {
    Title = "TurboPlates v" .. version,
    Author = "Author: surm",

    TabGeneral = "General",
    TabStyle = "Nameplate Style",
    TabFonts = "Nameplate Texts",
    TabColors = "Colors",
    TabCastbar = "Castbars",
    TabDebuffs = "Debuffs",
    TabBuffs = "Buffs",
    TabPersonal = "Personal Bar",
    TabCP = "Combo Points",
    TabTurboDebuffs = "TurboDebuffs",
    
    -- Personal Bar
    PersonalBarEnable = "Enable Personal Resource Bar",
    PersonalBarEnableDesc = "Show your own nameplate with health and power bars",
    PersonalBarWidth = "Bar Width",
    PersonalBarHeight = "Health Bar Height",
    PersonalBarShowPower = "Show Power Bar",
    PersonalBarPowerHeight = "Power Bar Height",
    PersonalBarHealthFormat = "Health Text Format",
    PersonalBarPowerFormat = "Power Text Format",
    PersonalBarUseThreatColoring = "Color by Threat",
    PersonalBarShowBuffs = "Show Buffs",
    PersonalBarShowDebuffs = "Show Debuffs",
    PersonalBarBorderStyle = "Border Style",
    PersonalBarBorderNone = "No Borders",
    PersonalBarBorderDebuff = "Color by Debuff",
    PersonalBarBorderDebuffOnly = "No Borders Unless Debuff",
    PersonalBarBorderBlack = "Default Black",
    PersonalBarYOffset = "Vertical Offset",
    PersonalBarHealthColor = "Health Bar Color",

    PersonalBarPowerColorByType = "Color Power by Type",
    PersonalBarShowAdditionalPower = "Show Mana When Shapeshifted",
    PersonalBarAdditionalPowerHeight = "Additional Power Height",
    HeroPowerOrder = "Power Bar Order",
    TabObjectives = "Quest Objectives",
    TabMisc = "Misc Options",
    TabStacking = "Plate Stacking",
    TabProfiles = "Profiles",
    
    -- Import/Export (Profiles Tab)
    ImportExportHeader = "Import / Export Settings",
    ImportExportDesc = "Export your settings to share with others, or import a settings string to apply someone else's configuration.",
    ExportSettings = "Settings",
    ExportHighlights = "Highlighted Spells",
    ExportWhitelist = "Whitelisted Auras",
    ExportBlacklist = "Blacklisted Auras",
    ExportButton = "Export Selected",
    ImportButton = "Import Selected",
    CopyButton = "Copy",
    ClearButton = "Clear",
    ExportSuccess = "Settings exported! Copy the text above.",
    ExportFailed = "Export failed: ",
    ImportSuccess = "Settings imported successfully!",
    ImportFailed = "Import failed: ",
    ImportEmpty = "Please paste a settings string first.",
    CopySuccess = "Copied to clipboard!",
    CopyEmpty = "Nothing to copy. Export first.",
    
    -- Stacking Tab
    StackingHeader = "Nameplate Stacking:",
    StackingEnable = "Enable Nameplate Stacking",
    StackingEnableDesc = "Smooth stacking algorithm that prevents nameplate overlap",
    StackingPreset = "Behavior Preset (requires /reload)",
    StackingPresetBalanced = "Balanced",
    StackingPresetChill = "Chill",
    StackingPresetSnappy = "Snappy",
    StackingPresetReloadPrompt = "Changing preset requires a UI reload. Reload now?",
    -- Spring Physics
    StackingSpringHeader = "Animation Speed:",
    StackingSpringRaise = "Rise Speed",
    StackingSpringRaiseDesc = "How fast plates move upward when stacking (higher = snappier)",
    StackingSpringLower = "Fall Speed",
    StackingSpringLowerDesc = "How fast plates move downward when unstacking (slower feels natural)",
    -- Overlap Detection
    StackingOverlapHeader = "Overlap Detection:",
    StackingXSpace = "Horizontal Overlap",
    StackingXSpaceDesc = "When plates stack: 100%=touching edges, <100%=allow overlap, >100%=stack earlier",
    StackingYSpace = "Vertical Gap",
    StackingYSpaceDesc = "Spacing between stacked plates (% of clickbox height)",
    -- Position
    StackingPositionHeader = "Position:",
    StackingOriginPos = "Base Height",
    StackingOriginPosDesc = "Base nameplate height above mob (0%=none, 100%=default, 200%=high)",
    StackingUpperBorder = "Screen Top Margin",
    StackingUpperBorderDesc = "Distance from screen top that plates cannot cross (lower = more screen use)",
    
    -- Non-Target Alpha
    NonTargetAlpha = "Non-Target Alpha",
    NonTargetAlphaDesc = "Opacity of non-targeted nameplates when you have a target (0% = invisible, 100% = fully visible)",
    
    -- Potato PC Mode
    PotatoPCMode = "Potato PC Mode",
    PotatoPCModeDesc = "Reduces CPU usage by halving update frequencies. Recommended for older or slow PCs.",
    
    -- Auras Tab
    AurasShowDebuffs = "Enable Debuff Tracking",
    AurasOwnOnly = "Own Only",
    AurasMaxDebuffs = "Max Debuffs",
    AurasDebuffWidth = "Debuff Icon Width",
    AurasDebuffHeight = "Debuff Icon Height",
    AurasDebuffFontSize = "Timer Font Size",
    AurasDebuffStackFontSize = "Stack Font Size",
    AurasBuffFilterMode = "Buff Filter",
    AurasShowBuffs = "Enable Buff Tracking",
    AurasBuffFilterOnlyDispellable = "Only Dispellable",
    AurasBuffFilterWhitelistDispellable = "Whitelist + Dispellable",
    AurasBuffFilterAll = "All (except Blacklisted)",
    AurasBuffFilterDisabled = "Disabled",
    AurasMaxBuffs = "Max Buffs",
    AurasBuffWidth = "Buff Icon Width",
    AurasBuffHeight = "Buff Icon Height",
    AurasBuffFontSize = "Timer Font Size",
    AurasBuffStackFontSize = "Stack Font Size",
    AurasBuffGrowDirection = "Buff Display Anchor",
    AurasBuffIconSpacing = "Icon Spacing",
    AurasBuffMinDuration = "Min Duration (s)",
    AurasBuffMaxDuration = "Max Duration (s)",
    AurasMinDuration = "Min Duration (s)",
    AurasMaxDuration = "Max Duration (s)",
    Unlimited = "Unlimited",
    AurasDebuffSortMode = "Debuff Sorting",
    AurasBuffSortMode = "Buff Sorting",
    AurasSortLeastTime = "Least Remaining Time",
    AurasSortMostRecent = "Most Recently Applied",
    AurasGrowDirection = "Debuff Display Anchor",
    AurasIconSpacing = "Icon Spacing",
    AurasXOffset = "Horizontal Offset",
    AurasYOffset = "Vertical Offset",
    AurasAnchorLeft = "Left",
    AurasAnchorCenter = "Center",
    AurasAnchorRight = "Right",
    AurasDebuffBorderMode = "Debuff Border",
    AurasBuffBorderMode = "Buff Border",
    AurasBorderDisabled = "Disabled",
    AurasBorderColorCoded = "Color Coded",
    AurasBorderDispellable = "Dispellable",
    AurasBorderCustom = "Custom Color",
    
    -- Text Anchor Options
    AurasDurationAnchor = "Timer Anchor",
    AurasStackAnchor = "Stack Anchor",
    AurasAnchorTop = "Top",
    AurasAnchorTopLeft = "Top Left",
    AurasAnchorTopRight = "Top Right",
    AurasAnchorBottom = "Bottom",
    AurasAnchorBottomLeft = "Bottom Left",
    AurasAnchorBottomRight = "Bottom Right",
    
    -- Aura Colors (Colors Tab)
    AuraColors = "Aura Colors:",
    DebuffBorderColor = "Debuff Border",
    BuffBorderColor = "Buff Border",
    
    -- Spell List Manager
    SpellListHeader = "Spell Filters",
    AuraBlacklist = "Aura Blacklist",
    AuraWhitelist = "Aura Whitelist",
    BlacklistManager = "Blacklisted Auras",
    WhitelistManager = "Whitelisted Auras",
    BlacklistDesc = "Spells that will never be shown",
    WhitelistDesc = "Spells that always bypass filters",
    SpellIDInput = "Spell ID",
    AddSpell = "Add",
    RemoveSpell = "Remove",
    ClearAll = "Clear All",
    Close = "Close",
    NoSpellsInList = "No spells in list",
    InvalidSpellID = "Invalid Spell ID",
    SpellAlreadyExists = "Spell already in list",
    SpellAdded = "Spell added",
    SpellRemoved = "Spell removed",
    ListCleared = "List cleared",
    
    -- General Tab (CVar Controls)
    ShowNameplatesFor = "Show Nameplates for:",
    FriendlyUnits = "Friendly Units",
    EnemyUnits = "Enemy Units",
    ShowPetsLabel = "Pets",
    ShowGuardians = "Guardians",
    ShowTotems = "Totems",
    ShowCastbar = "Enable Castbars",
    ShowCastSpark = "Show Spark",
    ShowCastTimer = "Show Timer",
    ShowMinimap = "Minimap Button",
    FriendlyNameOnly = "Name-Only Mode",
    FriendlyNameOnlyTip = "Displays friendly players as lightweight name-only plates without health bars",
    LiteHealthWhenDamaged = "Show HP When Damaged",
    LiteHealthWhenDamagedTip = "Shows a compact health bar with percentage when friendly units are below 100% health",
    FriendlyGuild = "Show Guild Names",
    ExecuteRange = "Execute Threshold (%)",

  -- Castbar Highlight Spells
    EnableHighlightGlow = "Enable Highlight Glow",
    EnableHighlightGlowTip = "Show animated glow effect on castbar when casting a spell from the Highlight Spells list",
    HighlightGlowLines = "Lines & Particles",
    HighlightGlowFrequency = "Frequency",
    HighlightGlowLength = "Length",
    HighlightGlowThickness = "Thickness",
    HighlightGlowColor = "Highlight Glow",
    HighlightSpells = "Highlight Spells",
    HighlightSpellsDesc = "Spells with custom highlight",
    NoHighlightSpells = "No spells configured",
    
    
    -- General Options Section
    GeneralOptionsHeader = "Friendly Nameplates:",
    
    -- PvP Section
    PvPHeader = "PvP:",
    ClassColoredHealth = "Class Colored Health",
    ClassColoredName = "Class Colored Name",
    ArenaNumbers = "Arena: Show Arena Numbers",
    HealerMarks = "Arena/BG: Healer Icons",
    TargetingMeIndicator = "Arena: Targeting Me Indicator",
    TargetingMeColor = "(Arena) Targeting Me",
    
    -- Quest Objectives
    ShowQuestNPCs = "Show Quest NPCs",
    ShowQuestObjectives = "Show Quest Objectives",
    QuestIconScale = "Quest Icon Scale",
    QuestIconAnchor = "Quest Icon Anchor",
    QuestIconX = "Icon X Offset",
    QuestIconY = "Icon Y Offset",

    Width = "Nameplate Width",
    HpHeight = "Healthbar Height",
    CastHeight = "Castbar Height",
    ShowCastIcon = "Show Icon",
    HealthBarBorder = "Healthbar Border",
    Scale = "Nameplate Scale",
    TargetScale = "Target Nameplate Scale",
    FriendlyScale = "Friendly Nameplate Scale",
    RaidMarkerSize = "Raid Marker Size",
    RaidMarkerAnchor = "Raid Marker Anchor",
    RaidMarkerX = "Raid Marker X",
    RaidMarkerY = "Raid Marker Y",
    Texture = "Bar Texture",
    BackgroundAlpha = "Background Alpha",
    HpColor = "Enemy Health",
    CastColor = "Normal Cast",
    NoInterruptColor = "Non-Interruptible",
    TankMode = "Tank Mode",
    TankModeDisabled = "Disabled",
    TankModeSmart = "Smart (Auto)",
    TankModeEnabled = "Always On",
    FriendlyFontSize = "Friendly Name-Only Size",
    GuildFontSize = "Friendly Guild Name Size",
    
    -- Tank Mode Colors
    TankColors = "Tank Mode Colors:",
    CastbarColors = "Castbar Colors:",
    BaseColors = "Nameplate Colors:",
    EnemyNameColor = "Enemy Name",
    TappedColor = "Tapped",
    SecureColor = "Secure",
    TransColor = "Losing",
    InsecureColor = "Lost",
    OffTankColor = "Off-Tank",
    
    -- DPS Mode Colors
    DpsColors = "DPS/Healer Colors:",
    DpsSecureColor = "Safe",
    DpsTransColor = "Warning",
    DpsAggroColor = "Aggro",
    
    -- Target/PvP Colors
    TargetPvPColors = "Target/PvP Colors:",

    Font = "Font",
    FontSize = "Nameplate Name Size",
    FontOutline = "Font Outline",
    NameDisplayFormat = "Name Display Format",
    
    -- Health Value Display
    HealthValueFormat = "Health Value Format",
    HealthValueFontSize = "Health Value Font Size",
    NameInHealthbar = "Display Name in Healthbar",
    HidePercentWhenFull = "Hide % When Full",
    HealthFormatNone = "None",
    HealthFormatCurrent = "Current",
    HealthFormatPercent = "Percent %",
    HealthFormatCurrentMax = "Current / Max",
    HealthFormatCurrentMaxPercent = "Current / Max (Percent %)",
    HealthFormatCurrentPercent = "Current (Percent %)",
    HealthFormatDeficit = "Deficit (Health Lost)",
    HealthFormatCurrentDeficit = "Current | Deficit",
    HealthFormatPercentDeficit = "Percent % | Deficit",

    TotemDisplay = "Custom Totem Display",
    TotemDisabled = "Disabled (Full Plate)",
    TotemHPName = "HP + Name",
    TotemIconOnly = "Icon Only",
    TotemIconName = "Icon + Name",
    TotemIconHP = "Icon + HP",
    TotemIconNameHP = "Icon + Name + HP",
    PetScale = "Pet Nameplate Scale",
    PetColor = "Enemy Pet",
    TargetGlow = "Target Glow",
    TargetGlowColor = "Target Glow",
    ClickableAreaHeader = "Nameplate Clickable Area Settings:",
    ClickableWidth = "Clickable Width",
    ClickableHeight = "Clickable Height",
    ShowClickbox = "Preview Clickable Area",

    -- Level Indicator
    LevelIndicator = "Level Text",
    LevelIndicatorDisabled = "Disabled",
    LevelIndicatorEnemies = "Enemies Only",
    LevelIndicatorAll = "Friendlies + Enemies",
    LevelSize = "Size",
    LevelX = "X Position",
    LevelY = "Y Position",

    -- Classification Icon
    ClassificationAnchor = "Classification Icon",
    ClassificationDisabled = "Disabled",
    ClassificationTopLeft = "Top Left",
    ClassificationTopRight = "Top Right",
    ClassificationTop = "Top",
    ClassificationBottom = "Bottom",
    ClassificationBottomLeft = "Bottom Left",
    ClassificationBottomRight = "Bottom Right",

    -- Threat Text
    ThreatTextAnchor = "Threat Text Display",
    ThreatTextDisabled = "Disabled",
    ThreatTextRightHP = "Right of Healthbar",
    ThreatTextLeftHP = "Left of Healthbar",
    ThreatTextBelowHP = "Below Healthbar",
    ThreatTextTopHP = "Top of Healthbar",
    ThreatTextLeftName = "Left of Name",
    ThreatTextRightName = "Right of Name",
    ThreatTextFontSize = "Threat Font Size",
    ThreatTextXOffset = "Threat Text X",
    ThreatTextYOffset = "Threat Text Y",

    CPHeader = "Combo Points",
    ShowComboPoints = "Enable Combo Points",
    CPOnPersonalBar = "Show on Personal Bar",
    CPStyle = "Style",
    CPStyleSquare = "Square",
    CPStyleRounded = "Rounded",
    CPSize = "Size",
    CPX = "Nameplate X",
    CPY = "Nameplate Y",
    CPPersonalX = "Personal Bar X",
    CPPersonalY = "Personal Bar Y",
    LivePreview = "Live Preview",
    LeftClick = "Left Click: ",
    Settings = "Settings",
    Reload = "Right Click: Reload UI"
}

ns.Fonts = {
    -- Default WoW Fonts
    { name = "Friz Quadrata",         path = "Interface\\AddOns\\TurboPlates\\Fonts\\FRIZQT__.TTF" },
    { name = "Arial Narrow",          path = "Interface\\AddOns\\TurboPlates\\Fonts\\ARIALN.TTF" },
    { name = "Morpheus",              path = "Fonts\\MORPHEUS.TTF" },
    { name = "Skurri",                path = "Fonts\\SKURRI.TTF" },
    -- TurboPlates Fonts
    { name = "Oswald",                path = "Interface\\AddOns\\TurboPlates\\Fonts\\Oswald-Regular.ttf" },
    { name = "Nueva Std Cond",        path = "Interface\\AddOns\\TurboPlates\\Fonts\\Nueva Std Cond.ttf" },
    { name = "ActionMan",        path = "Interface\\AddOns\\TurboPlates\\Fonts\\ActionMan.ttf" },
    { name = "Continuum Medium",        path = "Interface\\AddOns\\TurboPlates\\Fonts\\ContinuumMedium.ttf" },
    { name = "DieDieDie",        path = "Interface\\AddOns\\TurboPlates\\Fonts\\DieDieDie.ttf" },
    { name = "Expressway",        path = "Interface\\AddOns\\TurboPlates\\Fonts\\Expressway.ttf" },
    { name = "Accidental Presidency", path = "Interface\\AddOns\\TurboPlates\\Fonts\\Accidental Presidency.ttf" },
    { name = "TrashHand",             path = "Interface\\AddOns\\TurboPlates\\Fonts\\TrashHand.TTF" },
    { name = "Harry P",               path = "Interface\\AddOns\\TurboPlates\\Fonts\\HARRYP__.TTF" },
    { name = "Forced Square",         path = "Interface\\AddOns\\TurboPlates\\Fonts\\FORCED SQUARE.ttf" },
    { name = "Fira Mono",             path = "Interface\\AddOns\\TurboPlates\\Fonts\\FiraMono-Medium.ttf" },
    { name = "Fira Sans",             path = "Interface\\AddOns\\TurboPlates\\Fonts\\FiraSans-Medium.ttf" },
    { name = "Fira Sans Heavy",       path = "Interface\\AddOns\\TurboPlates\\Fonts\\FiraSans-Heavy.ttf" },
    { name = "Fira Sans Condensed",   path = "Interface\\AddOns\\TurboPlates\\Fonts\\FiraSansCondensed-Medium.ttf" },
    { name = "Fira Sans Cond Heavy",  path = "Interface\\AddOns\\TurboPlates\\Fonts\\FiraSansCondensed-Heavy.ttf" },
    { name = "PT Sans Narrow",        path = "Interface\\AddOns\\TurboPlates\\Fonts\\PTSansNarrow-Regular.ttf" },
    { name = "PT Sans Narrow Bold",   path = "Interface\\AddOns\\TurboPlates\\Fonts\\PTSansNarrow-Bold.ttf" },
    { name = "AnsyFont",              path = "Interface\\AddOns\\TurboPlates\\Fonts\\UF_FONT.TTF" },
}
ns.Outlines = { { name = "None", value = "" }, { name = "Thin", value = "OUTLINE" }, { name = "Thick", value = "THICKOUTLINE" }, { name = "Monochrome", value = "MONOCHROME" } }
ns.NameFormats = {
    { name = "Disabled", value = "disabled" },
    { name = "Full Name", value = "none" },
    { name = "Abbreviate", value = "abbreviate" },
    { name = "First Name Only", value = "first" },
    { name = "Last Name Only", value = "last" },
}
ns.TargetGlowStyles = {
    { name = "Disabled", value = "none" },
    { name = "Border Glow", value = "border" },
    { name = "Thick Outline", value = "thick" },
    { name = "Thin Outline", value = "thin" },
    { name = "Arrow (Thin)", value = "arrows_thin" },
    { name = "Arrow (Normal)", value = "arrows_normal" },
    { name = "Arrow (Double)", value = "arrows_double" },
}
ns.TargetingMeStyles = {
    { name = "Disabled", value = "disabled" },
    { name = "Glow Highlight", value = "glow" },
    { name = "Border Color", value = "border" },
    { name = "Name Color", value = "name" },
    { name = "HP Bar Color", value = "health" },
}
ns.QuestIconAnchors = {
    { name = "Left", value = "LEFT" },
    { name = "Right", value = "RIGHT" },
    { name = "Top", value = "TOP" },
}
ns.HealthFormats = {
    { name = "None", value = "none" },
    { name = "Current", value = "current" },
    { name = "Percent %", value = "percent" },
    { name = "Current / Max", value = "current-max" },
    { name = "Current / Max (Percent %)", value = "current-max-percent" },
    { name = "Current (Percent %)", value = "current-percent" },
    { name = "Deficit (Health Lost)", value = "deficit" },
    { name = "Current | Deficit", value = "current-deficit" },
    { name = "Percent % | Deficit", value = "percent-deficit" },
}
-- Power formats (same as health but with correct label)
ns.PowerFormats = {
    { name = "None", value = "none" },
    { name = "Current", value = "current" },
    { name = "Percent %", value = "percent" },
    { name = "Current / Max", value = "current-max" },
    { name = "Current / Max (Percent %)", value = "current-max-percent" },
    { name = "Current (Percent %)", value = "current-percent" },
    { name = "Deficit (Resource Lost)", value = "deficit" },
    { name = "Current | Deficit", value = "current-deficit" },
    { name = "Percent % | Deficit", value = "percent-deficit" },
}
-- Personal bar border styles
ns.PersonalBorderStyles = {
    { name = "Self-Removable Debuff Color", value = "removable" },
    { name = "Default Black", value = "black" },
    { name = "Color by Debuff", value = "debuff" },
    { name = "No Borders Unless Debuff", value = "debuff_only" },
    { name = "No Borders", value = "none" },
}
-- HERO class power bar order (shows all 3 power types)
ns.HeroPowerOrders = {
    { name = "Mana > Energy > Rage", value = 1 },
    { name = "Mana > Rage > Energy", value = 2 },
    { name = "Energy > Mana > Rage", value = 3 },
    { name = "Energy > Rage > Mana", value = 4 },
    { name = "Rage > Mana > Energy", value = 5 },
    { name = "Rage > Energy > Mana", value = 6 },
}
ns.Textures = {
    -- Built-in / Default
    { name = "Flat",            path = "Interface\\Buttons\\WHITE8X8" },
    { name = "Blizzard",        path = "Interface\\TargetingFrame\\UI-StatusBar" },
    { name = "Minimalist",      path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
    -- TurboPlates Textures
    { name = "Minimalist 2",    path = "Interface\\AddOns\\TurboPlates\\Textures\\Minimalist.tga" },
    { name = "Hyanda",          path = "Interface\\AddOns\\TurboPlates\\Textures\\bar_hyanda.tga" },
    { name = "Smooth",          path = "Interface\\AddOns\\TurboPlates\\Textures\\Smooth.tga" },
    { name = "Hyanda Reverse",  path = "Interface\\AddOns\\TurboPlates\\Textures\\bar_hyanda_reverse.blp" },
    { name = "Serenity",        path = "Interface\\AddOns\\TurboPlates\\Textures\\bar_serenity.tga" },
    { name = "Skyline",         path = "Interface\\AddOns\\TurboPlates\\Textures\\bar_skyline.tga" },
    { name = "BantoBar",        path = "Interface\\AddOns\\TurboPlates\\Textures\\BantoBar.tga" },
    { name = "D'ictum",         path = "Interface\\AddOns\\TurboPlates\\Textures\\bar4.tga" },
    { name = "Vidro",           path = "Interface\\AddOns\\TurboPlates\\Textures\\bar4_vidro.tga" },
    { name = "Melli",           path = "Interface\\AddOns\\TurboPlates\\Textures\\Melli.tga" },
    { name = "Splitbar",        path = "Interface\\AddOns\\TurboPlates\\Textures\\split_bar.tga" },
    { name = "Details 2020",    path = "Interface\\AddOns\\TurboPlates\\Textures\\texture2020.blp" },
    { name = "Details Flat",    path = "Interface\\AddOns\\TurboPlates\\Textures\\bar_flat.tga" },
    { name = "Clean",           path = "Interface\\AddOns\\TurboPlates\\Textures\\Statusbar_Clean.blp" },
    { name = "Stripes",         path = "Interface\\AddOns\\TurboPlates\\Textures\\Statusbar_Stripes.blp" },
    { name = "Stripes Thick",   path = "Interface\\AddOns\\TurboPlates\\Textures\\Statusbar_Stripes_Thick.blp" },
    { name = "Stripes Thin",    path = "Interface\\AddOns\\TurboPlates\\Textures\\Statusbar_Stripes_Thin.blp" },
    { name = "Stripe Rainbow",  path = "Interface\\AddOns\\TurboPlates\\Textures\\stripe-rainbow-bar.tga" },
    -- ElvUI Textures
    { name = "ElvUI Gloss",     path = "Interface\\AddOns\\TurboPlates\\Textures\\ElvUI_Gloss.tga" },
    { name = "ElvUI Norm",      path = "Interface\\AddOns\\TurboPlates\\Textures\\ElvUI_Norm.tga" },
}

ns.defaults = {
    width = 100,
    hpHeight = 8,
    castHeight = 6,
    scale = 1,
    targetScale = 1.2,
    friendlyScale = 1.0,
    healthBarBorder = true,  -- Show 1px border around health bar
    raidMarkerSize = 20,
    raidMarkerAnchor = "LEFT",  -- LEFT, RIGHT, or TOP
    raidMarkerX = 0,   -- X offset from anchor point
    raidMarkerY = 0,   -- Y offset from anchor point
    texture = "Clean",  -- LSM name (was path)
    backgroundAlpha = 0.6,  -- Healthbar background transparency (0-1)
    hpColor = { r = 1, g = 0.2, b = 0.2 },
    castColor = { r = 1, g = 0.8, b = 0 },
    noInterruptColor = { r = 1, g = 0.384, b = 0 },  -- rgb(255, 98, 0)
    tankMode = 0,  -- 0=Disabled, 1=Smart (auto-detect), 2=Always On
    -- Tank Mode Colors
    secureColor = { r = 1, g = 0, b = 1 },       -- Magenta - Tank has aggro (good)
    transColor = { r = 1, g = 0.8, b = 0 },      -- Orange - Losing threat (warning)
    insecureColor = { r = 1, g = 0, b = 0 },     -- Red - No aggro (bad)
    offTankColor = { r = 0.2, g = 0.7, b = 0.5 },-- Teal - Another tank has it
    -- DPS/Healer Mode Colors
    dpsSecureColor = { r = 1, g = 0, b = 1 },    -- Magenta - Safe, no threat (matches tank secure)
    dpsTransColor = { r = 1, g = 0.8, b = 0 },   -- Orange - High threat (warning)
    dpsAggroColor = { r = 1, g = 0, b = 0 },     -- Red - Have aggro (bad)
    font = "Friz Quadrata",  -- LSM name (was path)
    fontSize = 9,
    fontOutline = "OUTLINE",
    nameDisplayFormat = "none",  -- Name display format: none, abbreviate, first, last
    showCastbar = true,
    showCastIcon = true,
    showCastSpark = true,
    showCastTimer = true,
    highlightGlowEnabled = false,  -- Enable pixel glow on highlighted spells
    highlightGlowLines = 8,        -- Number of glow lines
    highlightGlowFrequency = 0.25, -- Animation speed
    highlightGlowLength = 10,      -- Line length
    highlightGlowThickness = 2,    -- Line thickness
    highlightGlowColor = { r = 1, g = 0.3, b = 0.1 },  -- Orange glow color
    friendlyNameOnly = true,  -- Checked by default
    liteHealthWhenDamaged = true,  -- Show compact HP bar when damaged
    friendlyGuild = false,
    npcTitleCache = {},  -- [npcID] = title (cached via tooltip scan)
    classColoredHealth = true,  -- Use class colors for player health bars (friendly and hostile)
    classColoredName = false,   -- Use custom hostile name color (not class colored)
    arenaNumbers = false,       -- Replace enemy names with arena numbers in arena
    healerMarks = 3,            -- 0 = disabled, 1 = enemies only, 2 = friendly only, 3 = both
    targetingMeIndicator = "disabled",  -- Arena indicator when unit targets player: disabled, glow, border, name, health
    targetingMeColor = { r = 1, g = 0.2, b = 0.2 },  -- Red color for targeting me indicator
    executeRange = 0,           -- 0 = disabled, otherwise show marker at this % health
    friendlyFontSize = 10,
    guildFontSize = 9,
    healthValueFormat = "percent",  -- Health value display format
    healthValueFontSize = 8,     -- Health value font size
    nameInHealthbar = false,     -- Show name inside healthbar (left) with health value (right)
    hidePercentWhenFull = false,  -- Hide percent display when at full health (disabled by default)
    totemDisplay = "icon_name",   -- Totem display mode: disabled, hp_name, icon_only, icon_name, icon_hp, icon_name_hp
    petScale = 0.7,
    petColor = { r = 0.5, g = 0.5, b = 0.5 },
    targetGlow = "border",  -- Target glow style: none, border, thick, thin
    targetGlowColor = { r = 0, g = 1, b = 1 },  -- Neon cyan
    tappedColor = { r = 0.5, g = 0.5, b = 0.5 },  -- Grey for tapped units
    -- Quest objective icons
    showQuestNPCs = true,       -- Show quest pickup/turnin icons
    showQuestObjectives = true, -- Show quest kill/collect objective icons
    questIconScale = 100,       -- Icon scale percentage (100% = 1.2x base)
    questIconAnchor = "LEFT",   -- LEFT, RIGHT, or TOP
    questIconX = 0,             -- Icon X Offset
    questIconY = 0,             -- Icon Y Offset
    hostileNameColor = { r = 1, g = 1, b = 1 },  -- White by default
    showComboPoints = false,  -- Enable combo points display
    cpOnPersonalBar = false,  -- Show combo points on personal bar instead of target nameplate
    cpStyle = 1,  -- Combo point style (placeholder for future styles)
    cpSize = 12,
    cpX = 0,
    cpY = 0,  -- 0 is now the new default (previously -4 offset is baked in)
    cpPersonalX = 0,  -- X offset for personal bar combo points
    cpPersonalY = 0,  -- Y offset for personal bar combo points
    minimap = { hide = false, pos = 45 },
    potatoMode = false,  -- Halves all update frequencies to reduce CPU usage
    nonTargetAlpha = 0.6,   -- Manual alpha for non-targeted nameplates (0-1)
    -- Level indicator
    levelMode = "all",  -- disabled, enemies, all
    -- Classification icon
    classificationAnchor = "TOPLEFT",  -- disabled, TOPLEFT, TOPRIGHT, TOP, BOTTOM, BOTTOMLEFT, BOTTOMRIGHT
    
    -- Threat text display
    threatTextAnchor = "disabled",  -- disabled, right_hp, left_hp, below_hp, top_hp, left_name, right_name
    threatTextFontSize = 10,
    threatTextOffsetX = 2,
    threatTextOffsetY = 0,
    
    -- === PERSONAL RESOURCE BAR ===
    personal = {
        enabled = false,  -- Disabled by default (also controls CVar)
        width = 110,
        height = 12,
        showPowerBar = true,
        powerHeight = 8,
        healthFormat = "percent",  -- Uses same format as healthValueFormat
        powerFormat = "percent",
        healthColor = { r = 0.612, g = 1, b = 0 },  -- Lime green
        powerColorByType = true,  -- Use class power colors (mana=blue, rage=red, etc.)
        useThreatColoring = false,  -- Use threat colors from nameplate system when applicable
        showAdditionalPower = true,  -- Show mana bar when druid is shapeshifted
        additionalPowerHeight = 6,  -- Height of additional mana bar
        heroPowerOrder = 1,  -- HERO class power bar order (1=Mana>Energy>Rage)
        showBuffs = true,
        showDebuffs = true,
        buffXOffset = 0,
        buffYOffset = 0,
        debuffXOffset = 0,
        debuffYOffset = 0,
        yOffset = 0,
        borderStyle = "removable",  -- removable, black, debuff, debuff_only, none
    },
    
    -- === AURA TRACKING ===
    auras = {
        -- Debuffs (Your DoTs on enemies) - HARMFUL|PLAYER filter
        showDebuffs = true,
        maxDebuffs = 6,
        debuffIconWidth = 20,
        debuffIconHeight = 16,
        debuffFontSize = 12,
        debuffStackFontSize = 11,
        debuffXOffset = 0,
        debuffYOffset = 0,
        debuffBorderMode = "COLOR_CODED",  -- DISABLED, COLOR_CODED, CUSTOM
        debuffDurationAnchor = "BOTTOM",  -- TOP, TOPLEFT, TOPRIGHT, CENTER, BOTTOM, BOTTOMLEFT, BOTTOMRIGHT
        debuffStackAnchor = "TOPLEFT",   -- TOP, TOPLEFT, TOPRIGHT, CENTER, BOTTOM, BOTTOMLEFT, BOTTOMRIGHT
        
        -- Buffs (Enemy buffs you can purge/steal)
        showBuffs = true,
        buffFilterMode = "ONLY_DISPELLABLE",  -- ONLY_DISPELLABLE, WHITELIST_DISPELLABLE, ALL
        maxBuffs = 4,
        buffIconWidth = 18,
        buffIconHeight = 18,
        buffFontSize = 10,
        buffStackFontSize = 10,
        buffXOffset = 0,
        buffYOffset = 0,
        buffGrowDirection = "CENTER",  -- CENTER, LEFT, RIGHT
        buffDurationAnchor = "CENTER",  -- TOP, TOPLEFT, TOPRIGHT, CENTER, BOTTOM, BOTTOMLEFT, BOTTOMRIGHT
        buffStackAnchor = "TOPRIGHT",   -- TOP, TOPLEFT, TOPRIGHT, CENTER, BOTTOM, BOTTOMLEFT, BOTTOMRIGHT
        buffIconSpacing = 2,
        buffMinDuration = 0,
        buffMaxDuration = 600,
        buffBorderMode = "COLOR_CODED",  -- DISABLED, COLOR_CODED, CUSTOM
        
        -- Duration filters (for debuffs)
        minDuration = 0,       -- 0 = no minimum
        maxDuration = 0,       -- 0 = no maximum (unlimited)
        
        -- Layout
        growDirection = "CENTER",  -- CENTER, LEFT, RIGHT
        iconSpacing = 2,
        
        -- Sorting (LEAST_TIME or MOST_RECENT)
        debuffSortMode = "LEAST_TIME",
        buffSortMode = "MOST_RECENT",
        
        -- Custom border colors
        debuffBorderColor = { r = 0.8, g = 0, b = 0 },  -- Red
        buffBorderColor = { r = 0.2, g = 0.8, b = 0.2 },  -- Green
        
        -- Blacklist/Whitelist (spellID tables)
        blacklist = {},
        whitelist = {},
    },
    
    -- === NAMEPLATE STACKING ===
    stacking = {
        enabled = false,          -- Custom stacking disabled by default
        preset = "balanced",      -- Behavior preset: balanced, chill, snappy
        -- Spring physics (preset defaults, slider-adjustable)
        springFrequencyRaise = 10,
        springFrequencyLower = 10,
        launchDamping = 0.8,
        settleThreshold = 0.9,
        -- Layout settings (preset defaults, slider-adjustable)
        xSpaceRatio = 0.8,
        ySpaceRatio = 0.8,
        originPosRatio = 0,
        upperBorder = 48,
        -- Limits
        maxPlates = 60,
    },
    
    -- === TURBO DEBUFFS (BigDebuffs-style priority aura) ===
    turboDebuffs = {
        enabled = false,  -- Disabled by default (niche feature)
        showFriendly = false,  -- Show on friendly nameplates
        
        -- Full plates settings
        size = 32,
        anchor = "RIGHT",
        xOffset = 0,
        yOffset = 0,
        timerSize = 22,
        
        -- Name-only plates settings
        nameOnlyAnchor = "RIGHT",
        nameOnlySize = 24,
        nameOnlyTimerSize = 16,
        nameOnlyXOffset = 0,
        nameOnlyYOffset = 0,
        
        -- Category toggles
        immunities = true,
        cc = true,
        silence = true,
        interrupts = true,
        roots = true,
        disarm = true,
        buffs_defensive = true,
        buffs_offensive = true,
        buffs_other = true,
        snare = true,
        
        -- Category priorities
        priority = {
            immunities = 80,
            cc = 70,
            silence = 60,
            roots = 55,
            disarm = 50,
            buffs_defensive = 45,
            buffs_offensive = 40,
            buffs_other = 35,
            snare = 30,
            interrupts = 25,
        },
    },
}

-- Deep copy helper for table values
local function DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

function ns:LoadVariables()
    if not TurboPlatesDB then TurboPlatesDB = {} end
    
    for k, v in pairs(ns.defaults) do
        if TurboPlatesDB[k] == nil then
            TurboPlatesDB[k] = DeepCopy(v)
        elseif type(v) == "table" and type(TurboPlatesDB[k]) == "table" then
            for subKey, subVal in pairs(v) do
                if TurboPlatesDB[k][subKey] == nil then
                    TurboPlatesDB[k][subKey] = DeepCopy(subVal)
                end
            end
        end
    end
    
    -- Migrate font from path to LSM name
    if TurboPlatesDB.font and TurboPlatesDB.font:find("\\") then
        for _, f in ipairs(ns.Fonts) do
            if f.path == TurboPlatesDB.font then
                TurboPlatesDB.font = f.name
                break
            end
        end
        -- Fallback if path not found in list
        if TurboPlatesDB.font:find("\\") then
            TurboPlatesDB.font = "Friz Quadrata"
        end
    end
    
    -- Migrate texture from path to LSM name
    if TurboPlatesDB.texture and TurboPlatesDB.texture:find("\\") then
        for _, t in ipairs(ns.Textures) do
            if t.path == TurboPlatesDB.texture then
                TurboPlatesDB.texture = t.name
                break
            end
        end
        -- Fallback if path not found in list
        if TurboPlatesDB.texture:find("\\") then
            TurboPlatesDB.texture = "Clean"
        end
    end
    
    -- Validate texture (now LSM name)
    if not TurboPlatesDB.texture or TurboPlatesDB.texture == "" then
        TurboPlatesDB.texture = ns.defaults.texture
    end
    
    -- Validate color tables
    if type(TurboPlatesDB.hpColor) ~= "table" or not TurboPlatesDB.hpColor.r then
        TurboPlatesDB.hpColor = DeepCopy(ns.defaults.hpColor)
    end
    if type(TurboPlatesDB.castColor) ~= "table" or not TurboPlatesDB.castColor.r then
        TurboPlatesDB.castColor = DeepCopy(ns.defaults.castColor)
    end
    if type(TurboPlatesDB.noInterruptColor) ~= "table" or not TurboPlatesDB.noInterruptColor.r then
        TurboPlatesDB.noInterruptColor = DeepCopy(ns.defaults.noInterruptColor)
    end
    if type(TurboPlatesDB.petColor) ~= "table" or not TurboPlatesDB.petColor.r then
        TurboPlatesDB.petColor = DeepCopy(ns.defaults.petColor)
    end
    if type(TurboPlatesDB.targetGlowColor) ~= "table" or not TurboPlatesDB.targetGlowColor.r then
        TurboPlatesDB.targetGlowColor = DeepCopy(ns.defaults.targetGlowColor)
    end
    if type(TurboPlatesDB.tappedColor) ~= "table" or not TurboPlatesDB.tappedColor.r then
        TurboPlatesDB.tappedColor = DeepCopy(ns.defaults.tappedColor)
    end
    if type(TurboPlatesDB.hostileNameColor) ~= "table" or not TurboPlatesDB.hostileNameColor.r then
        TurboPlatesDB.hostileNameColor = DeepCopy(ns.defaults.hostileNameColor)
    end
    if type(TurboPlatesDB.secureColor) ~= "table" or not TurboPlatesDB.secureColor.r then
        TurboPlatesDB.secureColor = DeepCopy(ns.defaults.secureColor)
    end
    if type(TurboPlatesDB.transColor) ~= "table" or not TurboPlatesDB.transColor.r then
        TurboPlatesDB.transColor = DeepCopy(ns.defaults.transColor)
    end
    if type(TurboPlatesDB.insecureColor) ~= "table" or not TurboPlatesDB.insecureColor.r then
        TurboPlatesDB.insecureColor = DeepCopy(ns.defaults.insecureColor)
    end
    if type(TurboPlatesDB.offTankColor) ~= "table" or not TurboPlatesDB.offTankColor.r then
        TurboPlatesDB.offTankColor = DeepCopy(ns.defaults.offTankColor)
    end
    if type(TurboPlatesDB.dpsSecureColor) ~= "table" or not TurboPlatesDB.dpsSecureColor.r then
        TurboPlatesDB.dpsSecureColor = DeepCopy(ns.defaults.dpsSecureColor)
    end
    if type(TurboPlatesDB.dpsTransColor) ~= "table" or not TurboPlatesDB.dpsTransColor.r then
        TurboPlatesDB.dpsTransColor = DeepCopy(ns.defaults.dpsTransColor)
    end
    if type(TurboPlatesDB.dpsAggroColor) ~= "table" or not TurboPlatesDB.dpsAggroColor.r then
        TurboPlatesDB.dpsAggroColor = DeepCopy(ns.defaults.dpsAggroColor)
    end
    if type(TurboPlatesDB.minimap) ~= "table" then
        TurboPlatesDB.minimap = DeepCopy(ns.defaults.minimap)
    end
    if type(TurboPlatesDB.targetingMeColor) ~= "table" or not TurboPlatesDB.targetingMeColor.r then
        TurboPlatesDB.targetingMeColor = DeepCopy(ns.defaults.targetingMeColor)
    end
    if type(TurboPlatesDB.highlightGlowColor) ~= "table" or not TurboPlatesDB.highlightGlowColor.r then
        TurboPlatesDB.highlightGlowColor = DeepCopy(ns.defaults.highlightGlowColor)
    end
    
    -- Update cached db reference
    if ns.UpdateDBCache then 
        ns:UpdateDBCache()
    end
end
