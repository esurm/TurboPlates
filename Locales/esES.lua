--[[
TurboPlates - Spanish Locale (esES)
Uses esES/esMX clients by default, or any client when Spanish is selected.
Loaded from TOC after Locales\frFR.lua.
]]

local _, ns = ...
local L = ns:NewLocale("esES")

local T = {
    Author = "Autor: surm",
    Language = "Idioma",
    LanguageEnglish = "English",
    LanguageChinese = "Chino simplificado",
    LanguageFrench = "Français",
    LanguageSpanish = "Español",
    LanguageGerman = "Deutsch",
    LanguageReloadPrompt = "Idioma: /reload. ¿Recargar?",

    TabGeneral = "General",
    TabStyle = "Estilo",
    TabFonts = "Textos",
    TabColors = "Colores",
    TabCastbar = "Casteos",
    TabDebuffs = "Debuffs",
    TabBuffs = "Buffs",
    TabPersonal = "Personal",
    TabCP = "Combo",
    TabTurboDebuffs = "TurboDebuffs",
    TabObjectives = "Mobs",
    TabMisc = "Opciones",
    TabStacking = "Apilado",
    TabProfiles = "Perfiles",

    PersonalBarEnable = "Barra personal",
    PersonalBarEnableDesc = "Muestra tu vida/recurso.",
    PersonalBarWidth = "Ancho barra",
    PersonalBarHeight = "Alto vida",
    PersonalBarShowPower = "Recurso",
    PersonalBarPowerHeight = "Altura recurso",
    PersonalBarHealthFormat = "Formato vida",
    PersonalBarPowerFormat = "Formato recurso",
    PersonalBarUseClassColor = "Color de clase",
    PersonalBarShowBuffs = "Buffs",
    PersonalBarShowDebuffs = "Debuffs",
    PersonalBarBorderStyle = "Borde",
    PersonalBarBorderNone = "Sin bordes",
    PersonalBarBorderDebuff = "Color por perjuicio",
    PersonalBarBorderDebuffOnly = "Solo con debuff",
    PersonalBarBorderBlack = "Negro predeterminado",
    PersonalBarYOffset = "Desplazamiento vertical",
    PersonalBarBuffXOffset = "Buffs X",
    PersonalBarBuffYOffset = "Buffs Y",
    PersonalBarDebuffXOffset = "Debuffs X",
    PersonalBarDebuffYOffset = "Debuffs Y",
    PersonalBarHealthColor = "Color vida",
    PersonalBarPowerColorByType = "Color recurso",
    PersonalBarShowAdditionalPower = "Mana en forma",
    PersonalBarAdditionalPowerHeight = "Altura recurso 2",
    HeroPowerOrder = "Orden de recursos",

    ImportExportHeader = "Importar / exportar ajustes",
    ImportExportDesc = "Exporta o importa ajustes.",
    ExportSettings = "Ajustes",
    ExportHighlights = "Hechizos glow",
    ExportWhitelist = "Auras whitelist",
    ExportBlacklist = "Auras blacklist",
    ExportButton = "Exportar",
    ImportButton = "Importar",
    CopyButton = "Copiar",
    Reset = "Reset",
    ClearButton = "Limpiar",
    ExportSuccess = "Exportado. Copia arriba.",
    ExportFailed = "Error al exportar: ",
    ImportSuccess = "¡Importado!",
    ImportFailed = "Error al importar: ",
    ImportEmpty = "Pega el texto de import.",
    CopySuccess = "¡Copiado!",
    CopyEmpty = "Exporta primero.",
    Close = "Cerrar",

    StackingHeader = "Apilado de placas:",
    StackingEnable = "Apilado",
    StackingEnableDesc = "Evita superposición.",
    StackingPreset = "Perfil (/reload)",
    StackingPresetBalanced = "Equilibrado",
    StackingPresetChill = "Relajado",
    StackingPresetSnappy = "Ágil",
    StackingPresetReloadPrompt = "Perfil: /reload. ¿Recargar?",
    StackingClickboxNote = "Usa tamaño clicable.",
    StackingSpringHeader = "Animación:",
    StackingSpringRaise = "Subida",
    StackingSpringRaiseDesc = "Velocidad de subida",
    StackingSpringLower = "Bajada",
    StackingSpringLowerDesc = "Velocidad de bajada",
    StackingOverlapHeader = "Solape:",
    StackingXSpace = "Horizontal",
    StackingXSpaceDesc = "100%=contacto, <100%=más, >100%=antes",
    StackingYSpace = "Vertical",
    StackingYSpaceDesc = "Espacio vertical",
    StackingPositionHeader = "Posición:",
    StackingOriginPos = "Altura base",
    StackingOriginPosDesc = "Altura sobre mob (100%=pred.)",
    StackingUpperBorder = "Margen sup.",
    StackingUpperBorderDesc = "Margen superior",

    NonTargetAlpha = "Alpha otros",
    NonTargetAlphaDesc = "Opacidad de otros objetivos",
    PerformanceHeader = "Rendimiento:",
    PotatoPCMode = "Low-PC",
    PotatoPCModeDesc = "Menos CPU, actualiza más lento.",

    AurasShowDebuffs = "Debuffs activos",
    AurasOwnOnly = "Solo propios",
    AurasMaxDebuffs = "Máx. perjuicios",
    AurasDebuffWidth = "Ancho debuff",
    AurasDebuffHeight = "Alto debuff",
    AurasDebuffFontSize = "Tamaño timer",
    AurasDebuffStackFontSize = "Tamaño stacks",
    AurasBuffFilterMode = "Filtro buffs",
    AurasShowBuffs = "Buffs activos",
    AurasBuffFilterOnlyDispellable = "Solo disipables",
    AurasBuffFilterWhitelistDispellable = "Whitelist+disipable",
    AurasBuffFilterWhitelistOnly = "Solo lista blanca",
    AurasBuffFilterAll = "Todo salvo blacklist",
    AurasBuffFilterDisabled = "Desactivado",
    AurasMaxBuffs = "Máx. beneficios",
    AurasBuffWidth = "Ancho buff",
    AurasBuffHeight = "Alto buff",
    AurasBuffFontSize = "Tamaño timer",
    AurasBuffStackFontSize = "Tamaño stacks",
    AurasBuffGrowDirection = "Ancla buffs",
    AurasBuffIconSpacing = "Espacio iconos",
    AurasBuffMinDuration = "Dur. mín. (s)",
    AurasBuffMaxDuration = "Dur. máx. (s)",
    AurasMinDuration = "Dur. mín. (s)",
    AurasMaxDuration = "Dur. máx. (s)",
    Unlimited = "Ilimitado",
    AurasDebuffSortMode = "Orden debuffs",
    AurasBuffSortMode = "Orden buffs",
    AurasSortLeastTime = "Menor tiempo",
    AurasSortMostRecent = "Más reciente",
    AurasGrowDirection = "Ancla debuffs",
    AurasIconSpacing = "Espacio iconos",
    AurasXOffset = "Offset X",
    AurasYOffset = "Offset Y",
    AurasAnchorLeft = "Izquierda",
    AurasAnchorCenter = "Centro",
    AurasAnchorRight = "Derecha",
    AurasDebuffBorderMode = "Borde debuff",
    AurasBuffBorderMode = "Borde buff",
    AurasBorderDisabled = "Desactivado",
    AurasBorderColorCoded = "Color por tipo",
    AurasBorderDispellable = "Disipable",
    AurasBorderCustom = "Color propio",
    AurasDurationAnchor = "Ancla timer",
    AurasStackAnchor = "Ancla stacks",
    AurasAnchorTop = "Arriba",
    AurasAnchorTopLeft = "Arriba izquierda",
    AurasAnchorTopRight = "Arriba derecha",
    AurasAnchorBottom = "Abajo",
    AurasAnchorBottomLeft = "Abajo izquierda",
    AurasAnchorBottomRight = "Abajo derecha",
    AuraColors = "Colores de auras:",
    DebuffBorderColor = "Borde de perjuicio",
    BuffBorderColor = "Borde de beneficio",

    SpellListHeader = "Filtros",
    AuraBlacklist = "Blacklist",
    AuraWhitelist = "Whitelist",
    BlacklistManager = "Blacklist",
    WhitelistManager = "Whitelist",
    BlacklistDesc = "Nunca mostrar",
    WhitelistDesc = "Siempre mostrar",
    SpellIDInput = "ID de hechizo",
    AddSpell = "Añadir",
    RemoveSpell = "Quitar",
    ClearAll = "Limpiar todo",
    NoSpellsInList = "Lista vacía",
    InvalidSpellID = "ID no válido",
    SpellAlreadyExists = "Hechizo ya listado",
    SpellAdded = "Hechizo añadido",
    SpellRemoved = "Hechizo quitado",
    ListCleared = "Lista vaciada",
    CustomAuraNameplateColor = "Color por aura",
    CustomAuraNameplateColorDesc = "Aura coincidente colorea vida.",
    AuraColorSpellID = "ID de hechizo",
    AuraColorOwnOnly = "Solo propios",
    AuraColorAddRule = "Añadir regla",
    AuraColorNoRules = "Sin reglas de aura",

    ShowNameplatesFor = "Placas para:",
    FriendlyUnits = "Aliados",
    EnemyUnits = "Enemigos",
    ShowPetsLabel = "Mascotas",
    ShowGuardians = "Guardianes",
    ShowTotems = "Tótems",
    ShowCastbar = "Casteos",
    ShowCastSpark = "Destello",
    ShowCastTimer = "Timer",
    ShowMinimap = "Minimapa",
    FriendlyNameOnly = "Solo nombre",
    FriendlyNameOnlyTip = "Aliados solo con nombre.",
    LiteHealthWhenDamaged = "Vida con daño",
    LiteHealthWhenDamagedTip = "Barra pequeña bajo 100%",
    FriendlyGuild = "Hermandad",
    ExecuteRange = "Ejecución (%)",

    EnableHighlightGlow = "Glow cast",
    EnableHighlightGlowTip = "Glow para hechizos listados",
    HighlightGlowLines = "Líneas/partículas",
    HighlightGlowFrequency = "Frecuencia",
    HighlightGlowLength = "Longitud",
    HighlightGlowThickness = "Grosor",
    HighlightGlowColor = "Color glow",
    HighlightSpells = "Hechizos glow",
    HighlightSpellsDesc = "Hechizos con glow",
    NoHighlightSpells = "Sin hechizos",
    GeneralOptionsHeader = "Aliados:",

    PvPHeader = "JcJ:",
    ClassColoredHealth = "Vida por clase",
    ClassColoredName = "Nombre por clase",
    ArenaNumbers = "Números arena",
    HealerMarks = "Sanadores",
    HealerMarksDisabled = "Desactivado",
    HealerMarksEnemiesOnly = "Solo enemigos",
    HealerMarksFriendlyOnly = "Solo aliados",
    HealerMarksBoth = "Ambos",
    TargetingMeIndicator = "Me apunta",
    TargetingMeColor = "Me apunta",

    ShowQuestNPCs = "PNJs misión",
    ShowQuestObjectives = "Objetivos misión",
    QuestIconScale = "Escala icono",
    QuestIconAnchor = "Ancla icono",
    QuestIconX = "Icono X",
    QuestIconY = "Icono Y",
    EliteBossIndicator = "Élite/jefe",
    EliteBossIconAnchor = "Ancla élite",
    EliteBossIconX = "Élite/jefe X",
    EliteBossIconY = "Élite/jefe Y",
    EliteBossIconSize = "Tamaño élite/jefe",

    Width = "Ancho placa",
    HpHeight = "Alto vida",
    CastHeight = "Alto casteo",
    ShowCastIcon = "Mostrar icono",
    HealthBarBorder = "Borde vida",
    Scale = "Escala",
    TargetScale = "Escala objetivo",
    FriendlyScale = "Escala aliados",
    RaidMarkerSize = "Tamaño marca",
    RaidMarkerAnchor = "Ancla marca",
    RaidMarkerAnchorLeft = "Izquierda",
    RaidMarkerAnchorRight = "Derecha",
    RaidMarkerAnchorTop = "Arriba (sobre el nombre)",
    RaidMarkerX = "Marcador de banda X",
    RaidMarkerY = "Marcador de banda Y",
    Texture = "Textura de barra",
    BackgroundAlpha = "Alpha fondo",
    HpColor = "Salud enemiga",
    CastColor = "Casteo normal",
    NoInterruptColor = "No interrumpible",
    TankMode = "Tanque",
    TankModeDisabled = "Desactivado",
    TankModeSmart = "Inteligente (auto)",
    TankModeEnabled = "Siempre activo",
    FriendlyFontSize = "Nombre aliado",
    GuildFontSize = "Tamaño de hermandad aliada",

    TankColors = "Tanque:",
    CastbarColors = "Casteo:",
    BaseColors = "Placas:",
    EnemyNameColor = "Nombre enemigo",
    TappedColor = "Reclamado",
    SecureColor = "Seguro",
    TransColor = "Perdiendo",
    InsecureColor = "Perdido",
    OffTankColor = "Tanque secundario",
    DpsColors = "DPS/Sanadores:",
    DpsSecureColor = "Seguro",
    DpsTransColor = "Alerta",
    DpsAggroColor = "Agro",
    TargetPvPColors = "Objetivo/JcJ:",

    Font = "Fuente",
    FontSize = "Tamaño nombre",
    NameTextYOffset = "Nombre Y",
    FontOutline = "Contorno",
    NameDisplayFormat = "Formato nombre",
    HealthValueFormat = "Formato vida",
    HealthValueFontSize = "Texto vida",
    NameInHealthbar = "Nombre en vida",
    HidePercentWhenFull = "Ocultar al 100%",
    HealthFormatNone = "Ninguno",
    HealthFormatCurrent = "Actual",
    HealthFormatPercent = "Porcentaje %",
    HealthFormatCurrentMax = "Actual / Máx.",
    HealthFormatCurrentMaxPercent = "Actual/Máx (%)",
    HealthFormatCurrentPercent = "Actual (%)",
    HealthFormatDeficit = "Déficit",
    HealthFormatCurrentDeficit = "Actual | Déficit",
    HealthFormatPercentDeficit = "% | Déficit",

    TotemDisplay = "Vista de tótems",
    TotemDisabled = "Off (placa completa)",
    TotemHPName = "Salud + nombre",
    TotemIconOnly = "Solo icono",
    TotemIconName = "Icono + nombre",
    TotemIconHP = "Icono + salud",
    TotemIconNameHP = "Icono + nombre + salud",
    PetScale = "Escala de mascotas",
    PetColor = "Mascota enemiga",
    TargetGlow = "Brillo de objetivo",
    TargetArrow = "Flecha de objetivo",
    TargetGlowColor = "Brillo de objetivo",
    MouseoverGlowColor = "Brillo al pasar el ratón",
    ClickableAreaHeader = "Ajustes del área clicable:",
    ClickableWidth = "Anchura clicable",
    ClickableHeight = "Altura clicable",
    ShowClickbox = "Previsualizar área clicable",

    LevelIndicator = "Texto de nivel",
    LevelIndicatorDisabled = "Desactivado",
    LevelIndicatorEnemies = "Solo enemigos",
    LevelIndicatorAll = "Aliados + enemigos",
    LevelSize = "Tamaño",
    LevelX = "Posición X",
    LevelY = "Posición Y",
    ClassificationAnchor = "Icono de clasificación",
    ClassificationDisabled = "Desactivado",
    ClassificationTopLeft = "Arriba izquierda",
    ClassificationTopRight = "Arriba derecha",
    ClassificationTop = "Arriba",
    ClassificationBottom = "Abajo",
    ClassificationBottomLeft = "Abajo izquierda",
    ClassificationBottomRight = "Abajo derecha",

    ThreatTextAnchor = "Texto de amenaza",
    ThreatTextDisabled = "Desactivado",
    ThreatTextRightHP = "Derecha de salud",
    ThreatTextLeftHP = "Izquierda de salud",
    ThreatTextBelowHP = "Debajo de salud",
    ThreatTextTopHP = "Encima de salud",
    ThreatTextLeftName = "Izquierda del nombre",
    ThreatTextRightName = "Derecha del nombre",
    ThreatTextFontSize = "Tamaño amenaza",
    ThreatTextXOffset = "Amenaza X",
    ThreatTextYOffset = "Amenaza Y",

    CPHeader = "Puntos de combo",
    ShowComboPoints = "Combopuntos",
    CPOnPersonalBar = "En barra pers.",
    CPStyle = "Estilo",
    CPStyleSquare = "Cuadrado",
    CPStyleRounded = "Redondeado",
    CPSize = "Tamaño",
    CPX = "Placa X",
    CPY = "Placa Y",
    CPPersonalX = "Barra personal X",
    CPPersonalY = "Barra personal Y",
    LivePreview = "Vista previa",
    LeftClick = "Clic izquierdo: ",
    Settings = "Ajustes",
    Reload = "Clic derecho: /reload",

    BoostedBy = "|cff4fa3ffTurboPlates|r v%s cargado - /tp",
    OptionsClosedCombat = "|cff4fa3ffTurboPlates|r: opciones cerradas.",
    OptionsWillOpen = "|cff4fa3ffTurboPlates|r: abre tras combate.",
    ConflictText = "|cff4fa3ffTurboPlates|r: addon incompatible: |cffff6666%s|r\n\nDeja activo solo un addon de placas.",
    DisableIt = "Desactivarlo",
    DisableTP = "Desactivar TurboPlates",
    ResetText = "¿Restablecer TurboPlates?\n\nLa UI se recargará.\n(Listas de hechizos se conservan)",
    ResetYes = "Sí",
    ResetNo = "No",
    ReloadRequired = "/reload. ¿Recargar?",
    ReloadNow = "Recargar",
    Later = "Más tarde",
    ImportReload = "Importado.\n\n¿Recargar?",
    WhitelistName = "Lista blanca",
    BlacklistName = "Lista negra",
    RemovedFrom = "Quitado de %s - %s",
    AddedTo = "Añadido a %s - %s",
    SpellAlreadyIn = "Ya está en %s",
    ClearSpellList = "¿Vaciar %s?",
    RemovedFromHL = "Quitado glow - %s",
    AddedToHL = "Añadido glow - %s",
    SpellAlreadyInHL = "Ya en glow",
    EnableTurboDebuffs = "TurboDebuffs",
    TurboDebuffsDesc = "BigDebuffs con blacklist de auras.",
    TDShowForFriendlies = "Aliados",
    TDNormalNameplates = "Placas normales:",
    TDFriendlyNameOnly = "Solo nombre:",
    TDIconPosition = "Posición",
    TDIconSize = "Tamaño icono",
    TDTimerFontSize = "Tamaño timer",
    TDXOffset = "Desplazamiento X",
    TDYOffset = "Desplazamiento Y",
    TDShowCategories = "Categorías:",
    TDImmunities = "Inmunidad",
    TDCrowdControl = "Control",
    TDSilences = "Silencios",
    TDInterrupts = "Cortes",
    TDRoots = "Roots",
    TDDisarms = "Desarmes",
    TDDefensiveBuffs = "Defensivos",
    TDOffensiveBuffs = "Ofensivos",
    TDOtherBuffs = "Otros buffs",
    TDSnares = "Snares",
    TDLeft = "Izquierda",
    TDRight = "Derecha",
    TDTop = "Arriba",
    TDBottom = "Abajo",
    StackingStats = "[TP Apilado] Activas:%d Datos:%d Entradas:%d",
    StackingCommands = "[Comandos TP]",
    StackingStatsCmd = "  /tp stacking stats",
    ExportNoSettings = "Sin ajustes",
    ExportNoCategory = "Sin categoría",
    ExportNoData = "No hay datos para exportar",
    ExportSerialFailed = "Serialización falló",
    ExportCompressFailed = "Compresión falló",
    ExportEncodeFailed = "Falló la codificación",
    ImportEmptyStr = "Import vacío",
    ImportInvalidPrefix = "Falta prefijo TP",
    ImportDecodeFailed = "Decodificación falló",
    ImportDecompressFailed = "Descompresión falló",
    ImportDeserializeFailed = "Lectura falló",
    ImportValidationFailed = "Validación falló",
    ImportNoMatch = "Sin datos válidos",
    ImportSuccessStr = "Importado: %s",
    LabelSettings = "Ajustes",
    LabelHighlights = "Glow",
    LabelWhitelist2 = "Whitelist",
    LabelBlacklist2 = "Blacklist",
    LabelDeleted = "Eliminado",
    Yes = "Sí",
    No = "No",
}

for k, v in pairs(T) do
    L[k] = v
end

ns:RegisterLocalePostApply("esES", function()
for _, v in ipairs(ns.Outlines) do
    if v.value == "" then v.name = "Ninguno"
    elseif v.value == "OUTLINE" then v.name = "Fino"
    elseif v.value == "THICKOUTLINE" then v.name = "Grueso"
    elseif v.value == "MONOCHROME" then v.name = "Monocromo"
    end
end

for _, v in ipairs(ns.NameFormats) do
    if v.value == "disabled" then v.name = "Desactivado"
    elseif v.value == "none" then v.name = "Nombre completo"
    elseif v.value == "abbreviate" then v.name = "Abreviar"
    elseif v.value == "first" then v.name = "Solo nombre"
    elseif v.value == "last" then v.name = "Solo apellido"
    end
end

for _, v in ipairs(ns.TargetGlowStyles) do
    if v.value == "none" then v.name = "Desactivado"
    elseif v.value == "border" then v.name = "Brillo de borde"
    elseif v.value == "thick" then v.name = "Contorno grueso"
    elseif v.value == "thin" then v.name = "Contorno fino"
    end
end

for _, v in ipairs(ns.TargetArrowStyles) do
    if v.value == "none" then v.name = "Desactivado"
    elseif v.value == "arrows_thin" then v.name = "Flecha (fina)"
    elseif v.value == "arrows_normal" then v.name = "Flecha (normal)"
    elseif v.value == "arrows_double" then v.name = "Flecha (doble)"
    end
end

for _, v in ipairs(ns.TargetingMeStyles) do
    if v.value == "disabled" then v.name = "Desactivado"
    elseif v.value == "glow" then v.name = "Brillo resaltado"
    elseif v.value == "border" then v.name = "Color de borde"
    elseif v.value == "name" then v.name = "Color de nombre"
    elseif v.value == "health" then v.name = "Color de salud"
    end
end

for _, v in ipairs(ns.QuestIconAnchors) do
    if v.value == "LEFT" then v.name = "Izquierda"
    elseif v.value == "RIGHT" then v.name = "Derecha"
    elseif v.value == "TOP" then v.name = "Arriba"
    end
end

for _, v in ipairs(ns.EliteBossIconAnchors) do
    if v.value == "TOPLEFT" then v.name = "Arriba izquierda"
    elseif v.value == "TOP" then v.name = "Arriba"
    elseif v.value == "TOPRIGHT" then v.name = "Arriba derecha"
    elseif v.value == "LEFT" then v.name = "Izquierda"
    elseif v.value == "RIGHT" then v.name = "Derecha"
    elseif v.value == "BOTTOMLEFT" then v.name = "Abajo izquierda"
    elseif v.value == "BOTTOM" then v.name = "Abajo"
    elseif v.value == "BOTTOMRIGHT" then v.name = "Abajo derecha"
    end
end

for _, v in ipairs(ns.EliteBossIndicatorStyles) do
    if v.value == "none" then v.name = "Desactivado"
    elseif v.value == "default" then v.name = "Predeterminado"
    elseif v.value == "colored_skulls" then v.name = "Calaveras de color"
    elseif v.value == "elvui_dragons" then v.name = "Dragones ElvUI"
    elseif v.value == "sre_classic" then v.name = "SRE - clásico"
    elseif v.value == "sre_modern" then v.name = "SRE - moderno"
    elseif v.value == "sre_tiny" then v.name = "SRE - mini"
    end
end

local function ApplyFormatNames(list)
    for _, v in ipairs(list) do
        if v.value == "none" then v.name = "Ninguno"
        elseif v.value == "current" then v.name = "Actual"
        elseif v.value == "percent" then v.name = "Porcentaje %"
        elseif v.value == "current-max" then v.name = "Actual / Máx."
        elseif v.value == "current-max-percent" then v.name = "Actual / Máx. (porcentaje %)"
        elseif v.value == "current-percent" then v.name = "Actual (porcentaje %)"
        elseif v.value == "deficit" then v.name = "Déficit"
        elseif v.value == "current-deficit" then v.name = "Actual | Déficit"
        elseif v.value == "percent-deficit" then v.name = "Porcentaje % | Déficit"
        end
    end
end
ApplyFormatNames(ns.HealthFormats)
ApplyFormatNames(ns.PowerFormats)

for _, v in ipairs(ns.PersonalBorderStyles) do
    if v.value == "removable" then v.name = "Color de perjuicio disipable"
    elseif v.value == "black" then v.name = "Negro predeterminado"
    elseif v.value == "debuff" then v.name = "Color por perjuicio"
    elseif v.value == "debuff_only" then v.name = "Borde solo con perjuicio"
    elseif v.value == "none" then v.name = "Sin bordes"
    end
end

for _, v in ipairs(ns.HeroPowerOrders) do
    if v.value == 1 then v.name = "Maná > Energía > Ira"
    elseif v.value == 2 then v.name = "Maná > Ira > Energía"
    elseif v.value == 3 then v.name = "Energía > Maná > Ira"
    elseif v.value == 4 then v.name = "Energía > Ira > Maná"
    elseif v.value == 5 then v.name = "Ira > Maná > Energía"
    elseif v.value == 6 then v.name = "Ira > Energía > Maná"
    end
end
end)
