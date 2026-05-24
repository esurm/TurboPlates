--[[
TurboPlates - German Locale (deDE)
Uses deDE clients by default, or any client when German is selected.
Loaded from TOC after Locales\esES.lua.
]]

local _, ns = ...
local L = ns:NewLocale("deDE")

local T = {
    Author = "Autor: surm",
    Language = "Sprache",
    LanguageEnglish = "English",
    LanguageChinese = "Chinesisch",
    LanguageFrench = "Français",
    LanguageSpanish = "Español",
    LanguageGerman = "Deutsch",
    LanguageReloadPrompt = "Sprache braucht /reload. Laden?",

    TabGeneral = "Allgemein",
    TabStyle = "Stil",
    TabFonts = "Texte",
    TabColors = "Farben",
    TabCastbar = "Zauber",
    TabDebuffs = "Debuffs",
    TabBuffs = "Buffs",
    TabPersonal = "Persönlich",
    TabCP = "Combo",
    TabTurboDebuffs = "TurboDebuffs",
    TabObjectives = "Mob-Icons",
    TabMisc = "Optionen",
    TabStacking = "Stapelung",
    TabProfiles = "Profile",

    PersonalBarEnable = "Pers. Leiste an",
    PersonalBarEnableDesc = "Zeigt eigene HP/Ressource",
    PersonalBarWidth = "Leistenbreite",
    PersonalBarHeight = "HP-Höhe",
    PersonalBarShowPower = "Ressource",
    PersonalBarPowerHeight = "Ressourcenhöhe",
    PersonalBarHealthFormat = "HP-Format",
    PersonalBarPowerFormat = "Ressourcenformat",
    PersonalBarUseClassColor = "Klassenfarbe",
    PersonalBarShowBuffs = "Buffs anzeigen",
    PersonalBarShowDebuffs = "Debuffs anzeigen",
    PersonalBarBorderStyle = "Rahmenstil",
    PersonalBarBorderNone = "Keine Rahmen",
    PersonalBarBorderDebuff = "Farbe nach Debuff",
    PersonalBarBorderDebuffOnly = "Nur bei Debuff",
    PersonalBarBorderBlack = "Standard-Schwarz",
    PersonalBarYOffset = "Vertikaler Versatz",
    PersonalBarBuffXOffset = "Buffs X",
    PersonalBarBuffYOffset = "Buffs Y",
    PersonalBarDebuffXOffset = "Debuffs X",
    PersonalBarDebuffYOffset = "Debuffs Y",
    PersonalBarHealthColor = "HP-Farbe",
    PersonalBarPowerColorByType = "Ressourcenfarbe",
    PersonalBarShowAdditionalPower = "Extra-Mana",
    PersonalBarAdditionalPowerHeight = "Extra-Ressource",
    HeroPowerOrder = "Ressourcenfolge",

    ImportExportHeader = "Import / Export",
    ImportExportDesc = "Einstellungen exportieren/importieren.",
    ExportSettings = "Einstellungen",
    ExportHighlights = "Glow-Zauber",
    ExportWhitelist = "Whitelist-Auren",
    ExportBlacklist = "Blacklist-Auren",
    ExportButton = "Exportieren",
    ImportButton = "Importieren",
    CopyButton = "Kopieren",
    Reset = "Zurücksetzen",
    ClearButton = "Leeren",
    ExportSuccess = "Export fertig. Oben kopieren.",
    ExportFailed = "Export fehlgeschlagen: ",
    ImportSuccess = "Import erfolgreich!",
    ImportFailed = "Import fehlgeschlagen: ",
    ImportEmpty = "Import-Text einfügen.",
    CopySuccess = "Kopiert!",
    CopyEmpty = "Erst exportieren.",
    Close = "Schließen",

    StackingHeader = "Stapelung:",
    StackingEnable = "Stapelung an",
    StackingEnableDesc = "Verhindert Überlappung",
    StackingPreset = "Profil (/reload)",
    StackingPresetBalanced = "Ausgewogen",
    StackingPresetChill = "Ruhig",
    StackingPresetSnappy = "Direkt",
    StackingPresetReloadPrompt = "Profil braucht /reload. Laden?",
    StackingClickboxNote = "Nutzt Klickbox-Größe.",
    StackingSpringHeader = "Animation:",
    StackingSpringRaise = "Steigen",
    StackingSpringRaiseDesc = "Tempo nach oben",
    StackingSpringLower = "Fallen",
    StackingSpringLowerDesc = "Tempo nach unten",
    StackingOverlapHeader = "Overlap:",
    StackingXSpace = "Horizontal",
    StackingXSpaceDesc = "100%=Kontakt, <100%=enger, >100%=früher",
    StackingYSpace = "Vertikal",
    StackingYSpaceDesc = "Vertikaler Abstand",
    StackingPositionHeader = "Position:",
    StackingOriginPos = "Basis-Höhe",
    StackingOriginPosDesc = "Höhe über Mob (100%=Std.)",
    StackingUpperBorder = "Oberer Rand",
    StackingUpperBorderDesc = "Abstand zum oberen Rand",

    NonTargetAlpha = "Andere Alpha",
    NonTargetAlphaDesc = "Deckkraft anderer Ziele",
    PerformanceHeader = "Leistung:",
    PotatoPCMode = "Low-PC-Modus",
    PotatoPCModeDesc = "Weniger CPU, langsamere Updates.",

    AurasShowDebuffs = "Debuffs aktivieren",
    AurasOwnOnly = "Nur eigene",
    AurasMaxDebuffs = "Max. Debuffs",
    AurasDebuffWidth = "Debuff-Breite",
    AurasDebuffHeight = "Debuff-Höhe",
    AurasDebuffFontSize = "Timergröße",
    AurasDebuffStackFontSize = "Stapelgröße",
    AurasBuffFilterMode = "Buff-Filter",
    AurasShowBuffs = "Buffs aktivieren",
    AurasBuffFilterOnlyDispellable = "Nur bannbar",
    AurasBuffFilterWhitelistDispellable = "Whitelist+bannbar",
    AurasBuffFilterWhitelistOnly = "Nur Whitelist",
    AurasBuffFilterAll = "Alles außer Blacklist",
    AurasBuffFilterDisabled = "Deaktiviert",
    AurasMaxBuffs = "Max. Buffs",
    AurasBuffWidth = "Buff-Breite",
    AurasBuffHeight = "Buff-Höhe",
    AurasBuffFontSize = "Timergröße",
    AurasBuffStackFontSize = "Stapelgröße",
    AurasBuffGrowDirection = "Buff-Anker",
    AurasBuffIconSpacing = "Iconabstand",
    AurasBuffMinDuration = "Min. Dauer (s)",
    AurasBuffMaxDuration = "Max. Dauer (s)",
    AurasMinDuration = "Min. Dauer (s)",
    AurasMaxDuration = "Max. Dauer (s)",
    Unlimited = "Unbegrenzt",
    AurasDebuffSortMode = "Debuff-Sortierung",
    AurasBuffSortMode = "Buff-Sortierung",
    AurasSortLeastTime = "Kürzeste Restzeit",
    AurasSortMostRecent = "Neueste zuerst",
    AurasGrowDirection = "Debuff-Anker",
    AurasIconSpacing = "Iconabstand",
    AurasXOffset = "X-Versatz",
    AurasYOffset = "Y-Versatz",
    AurasAnchorLeft = "Links",
    AurasAnchorCenter = "Mitte",
    AurasAnchorRight = "Rechts",
    AurasDebuffBorderMode = "Debuff-Rahmen",
    AurasBuffBorderMode = "Buff-Rahmen",
    AurasBorderDisabled = "Deaktiviert",
    AurasBorderColorCoded = "Nach Typ",
    AurasBorderDispellable = "Bannbar",
    AurasBorderCustom = "Eigene Farbe",
    AurasDurationAnchor = "Timeranker",
    AurasStackAnchor = "Stapelanker",
    AurasAnchorTop = "Oben",
    AurasAnchorTopLeft = "Oben links",
    AurasAnchorTopRight = "Oben rechts",
    AurasAnchorBottom = "Unten",
    AurasAnchorBottomLeft = "Unten links",
    AurasAnchorBottomRight = "Unten rechts",
    AuraColors = "Aurenfarben:",
    DebuffBorderColor = "Debuff-Rahmen",
    BuffBorderColor = "Buff-Rahmen",

    SpellListHeader = "Zauberfilter",
    AuraBlacklist = "Auren-Blacklist",
    AuraWhitelist = "Auren-Whitelist",
    BlacklistManager = "Aura-Blacklist",
    WhitelistManager = "Aura-Whitelist",
    BlacklistDesc = "Nie anzeigen",
    WhitelistDesc = "Immer anzeigen",
    SpellIDInput = "Zauber-ID",
    AddSpell = "Hinzu",
    RemoveSpell = "Entf.",
    ClearAll = "Alles leeren",
    NoSpellsInList = "Liste leer",
    InvalidSpellID = "Ungültige ID",
    SpellAlreadyExists = "Schon in Liste",
    SpellAdded = "Zauber hinzu",
    SpellRemoved = "Zauber entfernt",
    ListCleared = "Liste geleert",
    CustomAuraNameplateColor = "Aura-Farbe",
    CustomAuraNameplateColorDesc = "Passende Aura färbt HP.",
    AuraColorSpellID = "Zauber-ID",
    AuraColorOwnOnly = "Nur eigene",
    AuraColorAddRule = "Regel hinzu",
    AuraColorNoRules = "Keine Farbregeln",

    ShowNameplatesFor = "Plaketten für:",
    FriendlyUnits = "Verbündete",
    EnemyUnits = "Feinde",
    ShowPetsLabel = "Begleiter",
    ShowGuardians = "Wächter",
    ShowTotems = "Totems",
    ShowCastbar = "Zauberleisten",
    ShowCastSpark = "Funken anzeigen",
    ShowCastTimer = "Timer anzeigen",
    ShowMinimap = "Minikarten-Button",
    FriendlyNameOnly = "Nur Namen",
    FriendlyNameOnlyTip = "Verbündete nur als Namen.",
    LiteHealthWhenDamaged = "LP bei Schaden",
    LiteHealthWhenDamagedTip = "Kleine HP-Leiste unter 100%",
    FriendlyGuild = "Gilde anzeigen",
    ExecuteRange = "Execute (%)",

    EnableHighlightGlow = "Cast-Glow",
    EnableHighlightGlowTip = "Glow für gelistete Zauber",
    HighlightGlowLines = "Linien/Partikel",
    HighlightGlowFrequency = "Frequenz",
    HighlightGlowLength = "Länge",
    HighlightGlowThickness = "Dicke",
    HighlightGlowColor = "Glow-Farbe",
    HighlightSpells = "Glow-Zauber",
    HighlightSpellsDesc = "Zauber mit Glow",
    NoHighlightSpells = "Keine Zauber",
    GeneralOptionsHeader = "Verbündete:",

    PvPHeader = "PvP:",
    ClassColoredHealth = "HP nach Klasse",
    ClassColoredName = "Name nach Klasse",
    ArenaNumbers = "Arena-Nummern",
    HealerMarks = "Heiler-Icons",
    HealerMarksDisabled = "Deaktiviert",
    HealerMarksEnemiesOnly = "Nur Feinde",
    HealerMarksFriendlyOnly = "Nur Verbündete",
    HealerMarksBoth = "Beide",
    TargetingMeIndicator = "Zielt auf mich",
    TargetingMeColor = "Zielt auf mich",

    ShowQuestNPCs = "Quest-NSCs anzeigen",
    ShowQuestObjectives = "Questziele",
    QuestIconScale = "Questicon-Skal.",
    QuestIconAnchor = "Questicon-Anker",
    QuestIconX = "Symbol-X-Versatz",
    QuestIconY = "Symbol-Y-Versatz",
    EliteBossIndicator = "Elite/Boss-Icon",
    EliteBossIconAnchor = "Elite/Boss-Anker",
    EliteBossIconX = "Elite/Boss X",
    EliteBossIconY = "Elite/Boss Y",
    EliteBossIconSize = "Elite/Boss-Größe",

    Width = "Plakettenbreite",
    HpHeight = "HP-Höhe",
    CastHeight = "Zauberhöhe",
    ShowCastIcon = "Symbol anzeigen",
    HealthBarBorder = "HP-Rahmen",
    Scale = "Skalierung",
    TargetScale = "Ziel-Skalierung",
    FriendlyScale = "Verb.-Skalierung",
    RaidMarkerSize = "Raidmark-Skal.",
    RaidMarkerAnchor = "Raidmark-Anker",
    RaidMarkerAnchorLeft = "Links",
    RaidMarkerAnchorRight = "Rechts",
    RaidMarkerAnchorTop = "Oben (über Name)",
    RaidMarkerX = "Raidmark X",
    RaidMarkerY = "Raidmark Y",
    Texture = "Leistentextur",
    BackgroundAlpha = "BG-Alpha",
    HpColor = "Feind-HP",
    CastColor = "Normaler Zauber",
    NoInterruptColor = "Nicht kickbar",
    TankMode = "Tankmodus",
    TankModeDisabled = "Deaktiviert",
    TankModeSmart = "Smart (auto)",
    TankModeEnabled = "Immer an",
    FriendlyFontSize = "Verb.-Namen",
    GuildFontSize = "Gildenname",

    TankColors = "Tank-Farben:",
    CastbarColors = "Zauberfarben:",
    BaseColors = "Plakettenfarben:",
    EnemyNameColor = "Feindname",
    TappedColor = "Markiert",
    SecureColor = "Sicher",
    TransColor = "Wechselt",
    InsecureColor = "Verloren",
    OffTankColor = "Off-Tank",
    DpsColors = "DPS/Heiler:",
    DpsSecureColor = "Sicher",
    DpsTransColor = "Warnung",
    DpsAggroColor = "Aggro",
    TargetPvPColors = "Ziel/PvP:",

    Font = "Schriftart",
    FontSize = "Namensgröße",
    NameTextYOffset = "Name Y",
    FontOutline = "Kontur",
    NameDisplayFormat = "Namensformat",
    HealthValueFormat = "HP-Format",
    HealthValueFontSize = "HP-Textgröße",
    NameInHealthbar = "Name in HP-Leiste",
    HidePercentWhenFull = "100% ausblenden",
    HealthFormatNone = "Keine",
    HealthFormatCurrent = "Aktuell",
    HealthFormatPercent = "Prozent %",
    HealthFormatCurrentMax = "Aktuell / Max",
    HealthFormatCurrentMaxPercent = "Aktuell/Max (%)",
    HealthFormatCurrentPercent = "Aktuell (%)",
    HealthFormatDeficit = "Defizit",
    HealthFormatCurrentDeficit = "Aktuell | Defizit",
    HealthFormatPercentDeficit = "% | Defizit",

    TotemDisplay = "Totem-Anzeige",
    TotemDisabled = "Aus (volle Platte)",
    TotemHPName = "LP + Name",
    TotemIconOnly = "Nur Symbol",
    TotemIconName = "Symbol + Name",
    TotemIconHP = "Symbol + LP",
    TotemIconNameHP = "Symbol + Name + LP",
    PetScale = "Begleiter-Skal.",
    PetColor = "Feind-Begleiter",
    TargetGlow = "Zielleuchten",
    TargetArrow = "Zielpfeil",
    TargetGlowColor = "Zielleuchten",
    MouseoverGlowColor = "Mouseover-Glow",
    ClickableAreaHeader = "Klickfläche:",
    ClickableWidth = "Klickbreite",
    ClickableHeight = "Klickhöhe",
    ShowClickbox = "Klickbox anzeigen",

    LevelIndicator = "Leveltext",
    LevelIndicatorDisabled = "Deaktiviert",
    LevelIndicatorEnemies = "Nur Feinde",
    LevelIndicatorAll = "Verb. + Feinde",
    LevelSize = "Größe",
    LevelX = "X-Position",
    LevelY = "Y-Position",
    ClassificationAnchor = "Klassifikation",
    ClassificationDisabled = "Deaktiviert",
    ClassificationTopLeft = "Oben links",
    ClassificationTopRight = "Oben rechts",
    ClassificationTop = "Oben",
    ClassificationBottom = "Unten",
    ClassificationBottomLeft = "Unten links",
    ClassificationBottomRight = "Unten rechts",

    ThreatTextAnchor = "Aggro-Text",
    ThreatTextDisabled = "Deaktiviert",
    ThreatTextRightHP = "Rechts der HP",
    ThreatTextLeftHP = "Links der HP",
    ThreatTextBelowHP = "Unter HP",
    ThreatTextTopHP = "Über HP",
    ThreatTextLeftName = "Links vom Namen",
    ThreatTextRightName = "Rechts vom Namen",
    ThreatTextFontSize = "Aggro-Textgröße",
    ThreatTextXOffset = "Aggro-Text X",
    ThreatTextYOffset = "Aggro-Text Y",

    CPHeader = "Combopunkte",
    ShowComboPoints = "Combopunkte",
    CPOnPersonalBar = "Auf pers. Leiste",
    CPStyle = "Stil",
    CPStyleSquare = "Quadratisch",
    CPStyleRounded = "Abgerundet",
    CPSize = "Größe",
    CPX = "Plakette X",
    CPY = "Plakette Y",
    CPPersonalX = "Pers. Leiste X",
    CPPersonalY = "Pers. Leiste Y",
    LivePreview = "Live-Vorschau",
    LeftClick = "Linksklick: ",
    Settings = "Einstellungen",
    Reload = "Rechtsklick: /reload",

    BoostedBy = "|cff4fa3ffTurboPlates|r v%s geladen - /tp",
    OptionsClosedCombat = "|cff4fa3ffTurboPlates|r: Optionen im Kampf zu.",
    OptionsWillOpen = "|cff4fa3ffTurboPlates|r: Öffnet nach Kampf.",
    ConflictText = "|cff4fa3ffTurboPlates|r: Inkompatibles Addon: |cffff6666%s|r\n\nNur ein Plaketten-Addon aktiv lassen.",
    DisableIt = "Deaktivieren",
    DisableTP = "TP deaktivieren",
    ResetText = "TurboPlates zurücksetzen?\n\nUI lädt neu.\n(Zauberlisten bleiben)",
    ResetYes = "Ja",
    ResetNo = "Nein",
    ReloadRequired = "/reload nötig. Neu laden?",
    ReloadNow = "Neu laden",
    Later = "Später",
    ImportReload = "Import fertig.\n\nNeu laden?",
    WhitelistName = "Whitelist",
    BlacklistName = "Blacklist",
    RemovedFrom = "Aus %s - %s",
    AddedTo = "Zu %s - %s",
    SpellAlreadyIn = "Schon in %s",
    ClearSpellList = "%s leeren?",
    RemovedFromHL = "Aus Glow - %s",
    AddedToHL = "Zu Glow - %s",
    SpellAlreadyInHL = "Schon in Glow-Liste",
    EnableTurboDebuffs = "TurboDebuffs an",
    TurboDebuffsDesc = "BigDebuffs mit Aura-Blacklist.",
    TDShowForFriendlies = "Verbündete",
    TDNormalNameplates = "Normale:",
    TDFriendlyNameOnly = "Nur-Namen:",
    TDIconPosition = "Iconposition",
    TDIconSize = "Icongröße",
    TDTimerFontSize = "Timergröße",
    TDXOffset = "X-Versatz",
    TDYOffset = "Y-Versatz",
    TDShowCategories = "Kategorien:",
    TDImmunities = "Immun",
    TDCrowdControl = "CC",
    TDSilences = "Silence",
    TDInterrupts = "Kick",
    TDRoots = "Root",
    TDDisarms = "Disarm",
    TDDefensiveBuffs = "Defensiv",
    TDOffensiveBuffs = "Offensiv",
    TDOtherBuffs = "Andere",
    TDSnares = "Snare",
    TDLeft = "Links",
    TDRight = "Rechts",
    TDTop = "Oben",
    TDBottom = "Unten",
    StackingStats = "[TP Stapelung] Aktiv:%d Daten:%d Einträge:%d",
    StackingCommands = "[TP Stapelung]",
    StackingStatsCmd = "  /tp stacking stats",
    ExportNoSettings = "Keine Einstellungen",
    ExportNoCategory = "Keine Kategorie",
    ExportNoData = "Keine Daten",
    ExportSerialFailed = "Serialisieren fehlgeschlagen",
    ExportCompressFailed = "Packen fehlgeschlagen",
    ExportEncodeFailed = "Kodierung fehlgeschlagen",
    ImportEmptyStr = "Leerer Import",
    ImportInvalidPrefix = "TP-Präfix fehlt",
    ImportDecodeFailed = "Dekodieren fehlgeschlagen",
    ImportDecompressFailed = "Entpacken fehlgeschlagen",
    ImportDeserializeFailed = "Lesen fehlgeschlagen",
    ImportValidationFailed = "Prüfung fehlgeschlagen",
    ImportNoMatch = "Nichts Passendes",
    ImportSuccessStr = "Importiert: %s",
    LabelSettings = "Einstellungen",
    LabelHighlights = "Glow-Zauber",
    LabelWhitelist2 = "Whitelist",
    LabelBlacklist2 = "Blacklist",
    LabelDeleted = "Gelöscht",
    Yes = "Ja",
    No = "Nein",
}

for k, v in pairs(T) do
    L[k] = v
end

ns:RegisterLocalePostApply("deDE", function()
for _, v in ipairs(ns.Outlines) do
    if v.value == "" then v.name = "Keine"
    elseif v.value == "OUTLINE" then v.name = "Dünn"
    elseif v.value == "THICKOUTLINE" then v.name = "Dick"
    elseif v.value == "MONOCHROME" then v.name = "Monochrom"
    end
end

for _, v in ipairs(ns.NameFormats) do
    if v.value == "disabled" then v.name = "Deaktiviert"
    elseif v.value == "none" then v.name = "Voller Name"
    elseif v.value == "abbreviate" then v.name = "Abkürzen"
    elseif v.value == "first" then v.name = "Nur Vorname"
    elseif v.value == "last" then v.name = "Nur Nachname"
    end
end

for _, v in ipairs(ns.TargetGlowStyles) do
    if v.value == "none" then v.name = "Deaktiviert"
    elseif v.value == "border" then v.name = "Rahmenleuchten"
    elseif v.value == "thick" then v.name = "Dicke Kontur"
    elseif v.value == "thin" then v.name = "Dünne Kontur"
    end
end

for _, v in ipairs(ns.TargetArrowStyles) do
    if v.value == "none" then v.name = "Deaktiviert"
    elseif v.value == "arrows_thin" then v.name = "Pfeil (dünn)"
    elseif v.value == "arrows_normal" then v.name = "Pfeil (normal)"
    elseif v.value == "arrows_double" then v.name = "Pfeil (doppelt)"
    end
end

for _, v in ipairs(ns.TargetingMeStyles) do
    if v.value == "disabled" then v.name = "Deaktiviert"
    elseif v.value == "glow" then v.name = "Glow"
    elseif v.value == "border" then v.name = "Rahmenfarbe"
    elseif v.value == "name" then v.name = "Namensfarbe"
    elseif v.value == "health" then v.name = "HP-Farbe"
    end
end

for _, v in ipairs(ns.QuestIconAnchors) do
    if v.value == "LEFT" then v.name = "Links"
    elseif v.value == "RIGHT" then v.name = "Rechts"
    elseif v.value == "TOP" then v.name = "Oben"
    end
end

for _, v in ipairs(ns.EliteBossIconAnchors) do
    if v.value == "TOPLEFT" then v.name = "Oben links"
    elseif v.value == "TOP" then v.name = "Oben"
    elseif v.value == "TOPRIGHT" then v.name = "Oben rechts"
    elseif v.value == "LEFT" then v.name = "Links"
    elseif v.value == "RIGHT" then v.name = "Rechts"
    elseif v.value == "BOTTOMLEFT" then v.name = "Unten links"
    elseif v.value == "BOTTOM" then v.name = "Unten"
    elseif v.value == "BOTTOMRIGHT" then v.name = "Unten rechts"
    end
end

for _, v in ipairs(ns.EliteBossIndicatorStyles) do
    if v.value == "none" then v.name = "Deaktiviert"
    elseif v.value == "default" then v.name = "Standard"
    elseif v.value == "colored_skulls" then v.name = "Farbige Schädel"
    elseif v.value == "elvui_dragons" then v.name = "ElvUI-Drachen"
    elseif v.value == "sre_classic" then v.name = "SRE - klassisch"
    elseif v.value == "sre_modern" then v.name = "SRE - modern"
    elseif v.value == "sre_tiny" then v.name = "SRE - winzig"
    end
end

local function ApplyFormatNames(list)
    for _, v in ipairs(list) do
        if v.value == "none" then v.name = "Keine"
        elseif v.value == "current" then v.name = "Aktuell"
        elseif v.value == "percent" then v.name = "Prozent %"
        elseif v.value == "current-max" then v.name = "Aktuell / Max"
        elseif v.value == "current-max-percent" then v.name = "Aktuell/Max (%)"
        elseif v.value == "current-percent" then v.name = "Aktuell (%)"
        elseif v.value == "deficit" then v.name = "Defizit"
        elseif v.value == "current-deficit" then v.name = "Aktuell | Defizit"
        elseif v.value == "percent-deficit" then v.name = "% | Defizit"
        end
    end
end
ApplyFormatNames(ns.HealthFormats)
ApplyFormatNames(ns.PowerFormats)

for _, v in ipairs(ns.PersonalBorderStyles) do
    if v.value == "removable" then v.name = "Bannbar"
    elseif v.value == "black" then v.name = "Schwarz"
    elseif v.value == "debuff" then v.name = "Debuff-Farbe"
    elseif v.value == "debuff_only" then v.name = "Nur Debuff"
    elseif v.value == "none" then v.name = "Keine Rahmen"
    end
end

for _, v in ipairs(ns.HeroPowerOrders) do
    if v.value == 1 then v.name = "Mana > Energie > Wut"
    elseif v.value == 2 then v.name = "Mana > Wut > Energie"
    elseif v.value == 3 then v.name = "Energie > Mana > Wut"
    elseif v.value == 4 then v.name = "Energie > Wut > Mana"
    elseif v.value == 5 then v.name = "Wut > Mana > Energie"
    elseif v.value == 6 then v.name = "Wut > Energie > Mana"
    end
end
end)
