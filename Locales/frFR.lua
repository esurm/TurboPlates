--[[
TurboPlates - French Locale (frFR)
Uses frFR clients by default, or any client when French is selected.
Loaded from TOC after Locales\zhCN.lua.
]]

local _, ns = ...
local L = ns:NewLocale("frFR")

local T = {
    Author = "Auteur : surm",
    Language = "Langue",
    LanguageEnglish = "English",
    LanguageChinese = "Chinois simplifié",
    LanguageFrench = "Français",
    LanguageSpanish = "Español",
    LanguageGerman = "Deutsch",
    LanguageReloadPrompt = "Langue: /reload. Recharger ?",

    TabGeneral = "Général",
    TabStyle = "Style",
    TabFonts = "Textes",
    TabColors = "Couleurs",
    TabCastbar = "Sorts",
    TabDebuffs = "Debuffs",
    TabBuffs = "Buffs",
    TabPersonal = "Perso",
    TabCP = "Combo",
    TabTurboDebuffs = "TurboDebuffs",
    TabObjectives = "Mobs",
    TabMisc = "Options",
    TabStacking = "Empilement",
    TabProfiles = "Profils",

    PersonalBarEnable = "Barre perso.",
    PersonalBarEnableDesc = "Affiche vos PV/ressource.",
    PersonalBarWidth = "Largeur de la barre",
    PersonalBarHeight = "Hauteur de santé",
    PersonalBarShowPower = "Ressource",
    PersonalBarPowerHeight = "Hauteur ressource",
    PersonalBarHealthFormat = "Format PV",
    PersonalBarPowerFormat = "Format ressource",
    PersonalBarUseClassColor = "Couleur classe",
    PersonalBarShowBuffs = "Afficher les améliorations",
    PersonalBarShowDebuffs = "Afficher les affaiblissements",
    PersonalBarBorderStyle = "Style de bordure",
    PersonalBarBorderNone = "Sans bordure",
    PersonalBarBorderDebuff = "Couleur par affaiblissement",
    PersonalBarBorderDebuffOnly = "Seulement debuff",
    PersonalBarBorderBlack = "Noir par défaut",
    PersonalBarYOffset = "Décalage vertical",
    PersonalBarBuffXOffset = "Position X des améliorations",
    PersonalBarBuffYOffset = "Position Y des améliorations",
    PersonalBarDebuffXOffset = "Debuffs X",
    PersonalBarDebuffYOffset = "Debuffs Y",
    PersonalBarHealthColor = "Couleur de la barre de santé",
    PersonalBarPowerColorByType = "Couleur ressource",
    PersonalBarShowAdditionalPower = "Mana en forme",
    PersonalBarAdditionalPowerHeight = "Hauteur ressource 2",
    HeroPowerOrder = "Ordre des ressources",

    ImportExportHeader = "Import / Export",
    ImportExportDesc = "Exporter ou importer les réglages.",
    ExportSettings = "Réglages",
    ExportHighlights = "Sorts glow",
    ExportWhitelist = "Auras whitelist",
    ExportBlacklist = "Auras blacklist",
    ExportButton = "Exporter la sélection",
    ImportButton = "Importer la sélection",
    CopyButton = "Copier",
    Reset = "Réinitialiser",
    ClearButton = "Effacer",
    ExportSuccess = "Export prêt. Copiez ci-dessus.",
    ExportFailed = "Échec de l'export : ",
    ImportSuccess = "Import réussi !",
    ImportFailed = "Échec de l'import : ",
    ImportEmpty = "Collez le texte à importer.",
    CopySuccess = "Copié !",
    CopyEmpty = "Exportez avant.",
    Close = "Fermer",

    StackingHeader = "Empilement des barres :",
    StackingEnable = "Empilement",
    StackingEnableDesc = "Évite le chevauchement.",
    StackingPreset = "Profil (/reload)",
    StackingPresetBalanced = "Équilibré",
    StackingPresetChill = "Doux",
    StackingPresetSnappy = "Réactif",
    StackingPresetReloadPrompt = "Profil: /reload. Recharger ?",
    StackingClickboxNote = "Utilise la taille cliquable.",
    StackingSpringHeader = "Vitesse d'animation :",
    StackingSpringRaise = "Vitesse de montée",
    StackingSpringRaiseDesc = "Vitesse de montée",
    StackingSpringLower = "Vitesse de descente",
    StackingSpringLowerDesc = "Vitesse de descente",
    StackingOverlapHeader = "Chevauchement:",
    StackingXSpace = "Chevauchement horizontal",
    StackingXSpaceDesc = "100%=contact, <100%=serré, >100%=tôt",
    StackingYSpace = "Écart vertical",
    StackingYSpaceDesc = "Espacement vertical",
    StackingPositionHeader = "Position :",
    StackingOriginPos = "Hauteur de base",
    StackingOriginPosDesc = "Hauteur mob (100%=déf.)",
    StackingUpperBorder = "Marge haute de l'écran",
    StackingUpperBorderDesc = "Marge haute écran",

    NonTargetAlpha = "Alpha autres",
    NonTargetAlphaDesc = "Opacité des autres cibles",
    PerformanceHeader = "Performances :",
    PotatoPCMode = "Mode PC peu puissant",
    PotatoPCModeDesc = "Moins de CPU, mises à jour lentes.",

    AurasShowDebuffs = "Debuffs actifs",
    AurasOwnOnly = "Seulement les miens",
    AurasMaxDebuffs = "Max affaiblissements",
    AurasDebuffWidth = "Largeur debuff",
    AurasDebuffHeight = "Hauteur debuff",
    AurasDebuffFontSize = "Taille timer",
    AurasDebuffStackFontSize = "Taille des charges",
    AurasBuffFilterMode = "Filtre des améliorations",
    AurasShowBuffs = "Buffs actifs",
    AurasBuffFilterOnlyDispellable = "Seulement dissipables",
    AurasBuffFilterWhitelistDispellable = "Whitelist+dissipable",
    AurasBuffFilterWhitelistOnly = "Liste blanche seulement",
    AurasBuffFilterAll = "Tout sauf blacklist",
    AurasBuffFilterDisabled = "Désactivé",
    AurasMaxBuffs = "Max améliorations",
    AurasBuffWidth = "Largeur buff",
    AurasBuffHeight = "Hauteur buff",
    AurasBuffFontSize = "Taille timer",
    AurasBuffStackFontSize = "Taille des charges",
    AurasBuffGrowDirection = "Ancrage des améliorations",
    AurasBuffIconSpacing = "Espacement des icônes",
    AurasBuffMinDuration = "Durée min. (s)",
    AurasBuffMaxDuration = "Durée max. (s)",
    AurasMinDuration = "Durée min. (s)",
    AurasMaxDuration = "Durée max. (s)",
    Unlimited = "Illimité",
    AurasDebuffSortMode = "Tri des affaiblissements",
    AurasBuffSortMode = "Tri des améliorations",
    AurasSortLeastTime = "Temps restant le plus faible",
    AurasSortMostRecent = "Application la plus récente",
    AurasGrowDirection = "Ancrage des affaiblissements",
    AurasIconSpacing = "Espacement des icônes",
    AurasXOffset = "Décalage X",
    AurasYOffset = "Décalage Y",
    AurasAnchorLeft = "Gauche",
    AurasAnchorCenter = "Centre",
    AurasAnchorRight = "Droite",
    AurasDebuffBorderMode = "Bordure d'affaiblissement",
    AurasBuffBorderMode = "Bordure d'amélioration",
    AurasBorderDisabled = "Désactivé",
    AurasBorderColorCoded = "Couleur par type",
    AurasBorderDispellable = "Dissipable",
    AurasBorderCustom = "Couleur personnalisée",
    AurasDurationAnchor = "Ancrage du minuteur",
    AurasStackAnchor = "Ancrage des charges",
    AurasAnchorTop = "Haut",
    AurasAnchorTopLeft = "Haut gauche",
    AurasAnchorTopRight = "Haut droite",
    AurasAnchorBottom = "Bas",
    AurasAnchorBottomLeft = "Bas gauche",
    AurasAnchorBottomRight = "Bas droite",
    AuraColors = "Couleurs des auras :",
    DebuffBorderColor = "Bordure d'affaiblissement",
    BuffBorderColor = "Bordure d'amélioration",

    SpellListHeader = "Filtres de sorts",
    AuraBlacklist = "Liste noire des auras",
    AuraWhitelist = "Liste blanche des auras",
    BlacklistManager = "Auras en liste noire",
    WhitelistManager = "Auras en liste blanche",
    BlacklistDesc = "Ne jamais afficher",
    WhitelistDesc = "Toujours afficher",
    SpellIDInput = "ID du sort",
    AddSpell = "Ajouter",
    RemoveSpell = "Retirer",
    ClearAll = "Tout effacer",
    NoSpellsInList = "Aucun sort dans la liste",
    InvalidSpellID = "ID de sort invalide",
    SpellAlreadyExists = "Sort déjà dans la liste",
    SpellAdded = "Sort ajouté",
    SpellRemoved = "Sort retiré",
    ListCleared = "Liste effacée",
    CustomAuraNameplateColor = "Couleur par aura",
    CustomAuraNameplateColorDesc = "Une aura trouvée colore les PV.",
    AuraColorSpellID = "ID du sort",
    AuraColorOwnOnly = "Seulement les miens",
    AuraColorAddRule = "Ajouter une règle",
    AuraColorNoRules = "Aucune règle",

    ShowNameplatesFor = "Barres pour :",
    FriendlyUnits = "Unités alliées",
    EnemyUnits = "Unités ennemies",
    ShowPetsLabel = "Familiers",
    ShowGuardians = "Gardiens",
    ShowTotems = "Totems",
    ShowCastbar = "Barres de sort",
    ShowCastSpark = "Afficher l'étincelle",
    ShowCastTimer = "Afficher le minuteur",
    ShowMinimap = "Bouton de minicarte",
    FriendlyNameOnly = "Mode nom seul",
    FriendlyNameOnlyTip = "Alliés affichés nom seul.",
    LiteHealthWhenDamaged = "Afficher les PV si blessé",
    LiteHealthWhenDamagedTip = "Petite barre PV sous 100%",
    FriendlyGuild = "Afficher les noms de guilde",
    ExecuteRange = "Seuil d'exécution (%)",

    EnableHighlightGlow = "Glow cast",
    EnableHighlightGlowTip = "Glow pour sorts listés",
    HighlightGlowLines = "Lignes/particules",
    HighlightGlowFrequency = "Fréquence",
    HighlightGlowLength = "Longueur",
    HighlightGlowThickness = "Épaisseur",
    HighlightGlowColor = "Lueur de surbrillance",
    HighlightSpells = "Sorts en surbrillance",
    HighlightSpellsDesc = "Sorts avec glow",
    NoHighlightSpells = "Aucun sort configuré",
    GeneralOptionsHeader = "Barres alliées :",

    PvPHeader = "JcJ :",
    ClassColoredHealth = "Santé colorée par classe",
    ClassColoredName = "Nom coloré par classe",
    ArenaNumbers = "Numéros arène",
    HealerMarks = "Icônes soigneurs",
    HealerMarksDisabled = "Désactivé",
    HealerMarksEnemiesOnly = "Ennemis seulement",
    HealerMarksFriendlyOnly = "Alliés seulement",
    HealerMarksBoth = "Les deux",
    TargetingMeIndicator = "Me cible",
    TargetingMeColor = "Me cible",

    ShowQuestNPCs = "Afficher les PNJ de quête",
    ShowQuestObjectives = "Objectifs quête",
    QuestIconScale = "Taille des icônes de quête",
    QuestIconAnchor = "Ancrage des icônes de quête",
    QuestIconX = "Décalage X de l'icône",
    QuestIconY = "Décalage Y de l'icône",
    EliteBossIndicator = "Indicateur élite/boss",
    EliteBossIconAnchor = "Ancrage élite/boss",
    EliteBossIconX = "Décalage X élite/boss",
    EliteBossIconY = "Décalage Y élite/boss",
    EliteBossIconSize = "Taille élite/boss",

    Width = "Largeur plaque",
    HpHeight = "Hauteur de santé",
    CastHeight = "Hauteur d'incantation",
    ShowCastIcon = "Afficher l'icône",
    HealthBarBorder = "Bordure de santé",
    Scale = "Échelle",
    TargetScale = "Échelle de la cible",
    FriendlyScale = "Échelle des alliés",
    RaidMarkerSize = "Taille marque",
    RaidMarkerAnchor = "Ancrage des marqueurs de raid",
    RaidMarkerAnchorLeft = "Gauche",
    RaidMarkerAnchorRight = "Droite",
    RaidMarkerAnchorTop = "Haut (au-dessus du nom)",
    RaidMarkerX = "Marqueur de raid X",
    RaidMarkerY = "Marqueur de raid Y",
    Texture = "Texture de barre",
    BackgroundAlpha = "Alpha du fond",
    HpColor = "Santé ennemie",
    CastColor = "Incantation normale",
    NoInterruptColor = "Non interruptible",
    TankMode = "Mode tank",
    TankModeDisabled = "Désactivé",
    TankModeSmart = "Intelligent (auto)",
    TankModeEnabled = "Toujours actif",
    FriendlyFontSize = "Taille du nom seul allié",
    GuildFontSize = "Nom guilde",

    TankColors = "Couleurs du mode tank :",
    CastbarColors = "Couleurs des incantations :",
    BaseColors = "Couleurs des barres :",
    EnemyNameColor = "Nom ennemi",
    TappedColor = "Déjà engagé",
    SecureColor = "Sécurisé",
    TransColor = "En perte",
    InsecureColor = "Perdu",
    OffTankColor = "Off-tank",
    DpsColors = "DPS/Soigneurs:",
    DpsSecureColor = "Sûr",
    DpsTransColor = "Alerte",
    DpsAggroColor = "Aggro",
    TargetPvPColors = "Couleurs cible/JcJ :",

    Font = "Police",
    FontSize = "Taille du nom",
    NameTextYOffset = "Décalage Y du nom",
    FontOutline = "Contour de police",
    NameDisplayFormat = "Format d'affichage du nom",
    HealthValueFormat = "Format de la santé",
    HealthValueFontSize = "Taille du texte de santé",
    NameInHealthbar = "Nom dans barre PV",
    HidePercentWhenFull = "Masquer le % à pleine santé",
    HealthFormatNone = "Aucun",
    HealthFormatCurrent = "Actuel",
    HealthFormatPercent = "Pourcentage %",
    HealthFormatCurrentMax = "Actuel / Max",
    HealthFormatCurrentMaxPercent = "Actuel / Max (pourcentage %)",
    HealthFormatCurrentPercent = "Actuel (pourcentage %)",
    HealthFormatDeficit = "Déficit (santé perdue)",
    HealthFormatCurrentDeficit = "Actuel | Déficit",
    HealthFormatPercentDeficit = "Pourcentage % | Déficit",

    TotemDisplay = "Affichage totem",
    TotemDisabled = "Off (plaque complète)",
    TotemHPName = "PV + nom",
    TotemIconOnly = "Icône seule",
    TotemIconName = "Icône + nom",
    TotemIconHP = "Icône + PV",
    TotemIconNameHP = "Icône + nom + PV",
    PetScale = "Échelle des familiers",
    PetColor = "Familier ennemi",
    TargetGlow = "Lueur de cible",
    TargetArrow = "Flèche de cible",
    TargetGlowColor = "Lueur de cible",
    MouseoverGlowColor = "Lueur au survol",
    ClickableAreaHeader = "Zone cliquable:",
    ClickableWidth = "Largeur cliquable",
    ClickableHeight = "Hauteur cliquable",
    ShowClickbox = "Voir clickbox",

    LevelIndicator = "Texte du niveau",
    LevelIndicatorDisabled = "Désactivé",
    LevelIndicatorEnemies = "Ennemis seulement",
    LevelIndicatorAll = "Alliés + ennemis",
    LevelSize = "Taille",
    LevelX = "Position X",
    LevelY = "Position Y",
    ClassificationAnchor = "Icône de classification",
    ClassificationDisabled = "Désactivé",
    ClassificationTopLeft = "Haut gauche",
    ClassificationTopRight = "Haut droite",
    ClassificationTop = "Haut",
    ClassificationBottom = "Bas",
    ClassificationBottomLeft = "Bas gauche",
    ClassificationBottomRight = "Bas droite",

    ThreatTextAnchor = "Affichage du texte de menace",
    ThreatTextDisabled = "Désactivé",
    ThreatTextRightHP = "À droite de la santé",
    ThreatTextLeftHP = "À gauche de la santé",
    ThreatTextBelowHP = "Sous la santé",
    ThreatTextTopHP = "Au-dessus de la santé",
    ThreatTextLeftName = "À gauche du nom",
    ThreatTextRightName = "À droite du nom",
    ThreatTextFontSize = "Taille du texte de menace",
    ThreatTextXOffset = "Menace X",
    ThreatTextYOffset = "Menace Y",

    CPHeader = "Points de combo",
    ShowComboPoints = "Activer les points de combo",
    CPOnPersonalBar = "Sur barre perso.",
    CPStyle = "Style",
    CPStyleSquare = "Carré",
    CPStyleRounded = "Arrondi",
    CPSize = "Taille",
    CPX = "Barre X",
    CPY = "Barre Y",
    CPPersonalX = "Barre personnelle X",
    CPPersonalY = "Barre personnelle Y",
    LivePreview = "Aperçu en direct",
    LeftClick = "Clic gauche : ",
    Settings = "Réglages",
    Reload = "Clic droit : /reload",

    BoostedBy = "|cff4fa3ffTurboPlates|r v%s chargé - /tp",
    OptionsClosedCombat = "|cff4fa3ffTurboPlates|r : options fermées.",
    OptionsWillOpen = "|cff4fa3ffTurboPlates|r : ouvre après combat.",
    ConflictText = "|cff4fa3ffTurboPlates|r : addon incompatible : |cffff6666%s|r\n\nGardez un seul addon de plaques actif.",
    DisableIt = "Le désactiver",
    DisableTP = "Désactiver TurboPlates",
    ResetText = "Réinitialiser TurboPlates ?\n\nUI rechargée.\n(Listes de sorts gardées)",
    ResetYes = "Oui",
    ResetNo = "Non",
    ReloadRequired = "/reload requis. Recharger ?",
    ReloadNow = "Recharger",
    Later = "Plus tard",
    ImportReload = "Import terminé.\n\nRecharger ?",
    WhitelistName = "Liste blanche",
    BlacklistName = "Liste noire",
    RemovedFrom = "Retiré de %s - %s",
    AddedTo = "Ajouté à %s - %s",
    SpellAlreadyIn = "Déjà dans %s",
    ClearSpellList = "Vider %s ?",
    RemovedFromHL = "Retiré glow - %s",
    AddedToHL = "Ajouté glow - %s",
    SpellAlreadyInHL = "Déjà dans Glow",
    EnableTurboDebuffs = "TurboDebuffs",
    TurboDebuffsDesc = "BigDebuffs avec aura blacklist.",
    TDShowForFriendlies = "Alliés",
    TDNormalNameplates = "Plaques normales:",
    TDFriendlyNameOnly = "Nom seul:",
    TDIconPosition = "Position de l'icône",
    TDIconSize = "Taille de l'icône",
    TDTimerFontSize = "Taille du minuteur",
    TDXOffset = "Décalage X",
    TDYOffset = "Décalage Y",
    TDShowCategories = "Catégories affichées :",
    TDImmunities = "Immunités",
    TDCrowdControl = "Contrôles",
    TDSilences = "Silences",
    TDInterrupts = "Interruptions",
    TDRoots = "Immobilisations",
    TDDisarms = "Désarmements",
    TDDefensiveBuffs = "Améliorations défensives",
    TDOffensiveBuffs = "Améliorations offensives",
    TDOtherBuffs = "Autres améliorations",
    TDSnares = "Ralentissements",
    TDLeft = "Gauche",
    TDRight = "Droite",
    TDTop = "Haut",
    TDBottom = "Bas",
    StackingStats = "[TP Empilement] Actifs:%d Données:%d Entrées:%d",
    StackingCommands = "[Commandes TP]",
    StackingStatsCmd = "  /tp stacking stats",
    ExportNoSettings = "Aucun réglage à exporter",
    ExportNoCategory = "Aucune catégorie sélectionnée",
    ExportNoData = "Aucune donnée à exporter",
    ExportSerialFailed = "Sérialisation échouée",
    ExportCompressFailed = "Compression échouée",
    ExportEncodeFailed = "Échec de l'encodage",
    ImportEmptyStr = "Chaîne d'import vide",
    ImportInvalidPrefix = "Préfixe TP manquant",
    ImportDecodeFailed = "Décodage échoué",
    ImportDecompressFailed = "Décompression échouée",
    ImportDeserializeFailed = "Lecture échouée",
    ImportValidationFailed = "Validation échouée",
    ImportNoMatch = "Aucune donnée",
    ImportSuccessStr = "Importé : %s",
    LabelSettings = "Réglages",
    LabelHighlights = "Sorts en surbrillance",
    LabelWhitelist2 = "Liste blanche",
    LabelBlacklist2 = "Liste noire",
    LabelDeleted = "Supprimé",
    Yes = "Oui",
    No = "Non",
}

for k, v in pairs(T) do
    L[k] = v
end

ns:RegisterLocalePostApply("frFR", function()
for _, v in ipairs(ns.Outlines) do
    if v.value == "" then v.name = "Aucun"
    elseif v.value == "OUTLINE" then v.name = "Fin"
    elseif v.value == "THICKOUTLINE" then v.name = "Épais"
    elseif v.value == "MONOCHROME" then v.name = "Monochrome"
    end
end

for _, v in ipairs(ns.NameFormats) do
    if v.value == "disabled" then v.name = "Désactivé"
    elseif v.value == "none" then v.name = "Nom complet"
    elseif v.value == "abbreviate" then v.name = "Abréger"
    elseif v.value == "first" then v.name = "Prénom seulement"
    elseif v.value == "last" then v.name = "Nom seulement"
    end
end

for _, v in ipairs(ns.TargetGlowStyles) do
    if v.value == "none" then v.name = "Désactivé"
    elseif v.value == "border" then v.name = "Lueur de bordure"
    elseif v.value == "thick" then v.name = "Contour épais"
    elseif v.value == "thin" then v.name = "Contour fin"
    end
end

for _, v in ipairs(ns.TargetArrowStyles) do
    if v.value == "none" then v.name = "Désactivé"
    elseif v.value == "arrows_thin" then v.name = "Flèche (fine)"
    elseif v.value == "arrows_normal" then v.name = "Flèche (normale)"
    elseif v.value == "arrows_double" then v.name = "Flèche (double)"
    end
end

for _, v in ipairs(ns.TargetingMeStyles) do
    if v.value == "disabled" then v.name = "Désactivé"
    elseif v.value == "glow" then v.name = "Lueur de surbrillance"
    elseif v.value == "border" then v.name = "Couleur de bordure"
    elseif v.value == "name" then v.name = "Couleur du nom"
    elseif v.value == "health" then v.name = "Couleur de santé"
    end
end

for _, v in ipairs(ns.QuestIconAnchors) do
    if v.value == "LEFT" then v.name = "Gauche"
    elseif v.value == "RIGHT" then v.name = "Droite"
    elseif v.value == "TOP" then v.name = "Haut"
    end
end

for _, v in ipairs(ns.EliteBossIconAnchors) do
    if v.value == "TOPLEFT" then v.name = "Haut gauche"
    elseif v.value == "TOP" then v.name = "Haut"
    elseif v.value == "TOPRIGHT" then v.name = "Haut droite"
    elseif v.value == "LEFT" then v.name = "Gauche"
    elseif v.value == "RIGHT" then v.name = "Droite"
    elseif v.value == "BOTTOMLEFT" then v.name = "Bas gauche"
    elseif v.value == "BOTTOM" then v.name = "Bas"
    elseif v.value == "BOTTOMRIGHT" then v.name = "Bas droite"
    end
end

for _, v in ipairs(ns.EliteBossIndicatorStyles) do
    if v.value == "none" then v.name = "Désactivé"
    elseif v.value == "default" then v.name = "Défaut"
    elseif v.value == "colored_skulls" then v.name = "Crânes colorés"
    elseif v.value == "elvui_dragons" then v.name = "Dragons ElvUI"
    elseif v.value == "sre_classic" then v.name = "SRE - classique"
    elseif v.value == "sre_modern" then v.name = "SRE - moderne"
    elseif v.value == "sre_tiny" then v.name = "SRE - mini"
    end
end

local function ApplyFormatNames(list)
    for _, v in ipairs(list) do
        if v.value == "none" then v.name = "Aucun"
        elseif v.value == "current" then v.name = "Actuel"
        elseif v.value == "percent" then v.name = "Pourcentage %"
        elseif v.value == "current-max" then v.name = "Actuel / Max"
        elseif v.value == "current-max-percent" then v.name = "Actuel / Max (pourcentage %)"
        elseif v.value == "current-percent" then v.name = "Actuel (pourcentage %)"
        elseif v.value == "deficit" then v.name = "Déficit"
        elseif v.value == "current-deficit" then v.name = "Actuel | Déficit"
        elseif v.value == "percent-deficit" then v.name = "Pourcentage % | Déficit"
        end
    end
end
ApplyFormatNames(ns.HealthFormats)
ApplyFormatNames(ns.PowerFormats)

for _, v in ipairs(ns.PersonalBorderStyles) do
    if v.value == "removable" then v.name = "Couleur d'affaiblissement dissipable"
    elseif v.value == "black" then v.name = "Noir par défaut"
    elseif v.value == "debuff" then v.name = "Couleur par affaiblissement"
    elseif v.value == "debuff_only" then v.name = "Bordure seulement avec affaiblissement"
    elseif v.value == "none" then v.name = "Sans bordure"
    end
end

for _, v in ipairs(ns.HeroPowerOrders) do
    if v.value == 1 then v.name = "Mana > Énergie > Rage"
    elseif v.value == 2 then v.name = "Mana > Rage > Énergie"
    elseif v.value == 3 then v.name = "Énergie > Mana > Rage"
    elseif v.value == 4 then v.name = "Énergie > Rage > Mana"
    elseif v.value == 5 then v.name = "Rage > Mana > Énergie"
    elseif v.value == 6 then v.name = "Rage > Énergie > Mana"
    end
end
end)
