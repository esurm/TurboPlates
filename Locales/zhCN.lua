--[[
TurboPlates - Simplified Chinese Locale (zhCN)
Complete Chinese localization for TurboPlates.
Uses zhCN/zhTW clients by default, or any client when Chinese is selected.
Loaded from TOC after Locales\enUS.lua.
]]

local addonName, ns = ...
local L = ns:NewLocale("zhCN")

local function ApplyChineseFont()
    ns.GUI_FONT = ns.CJK_FONT_PATH or "Interface\\AddOns\\TurboPlates\\Fonts\\NotoSansSC-Regular.ttf"
end

-- ============================================================================
-- Core ns.L Table Translation
-- ============================================================================

L.Author = "作者: surm"
L.Language = "语言"
L.LanguageEnglish = "English"
L.LanguageChinese = "简体中文"
L.LanguageFrench = "Français"
L.LanguageSpanish = "Español"
L.LanguageGerman = "Deutsch"
L.LanguageReloadPrompt = "更改语言需要重载界面。立即重载？"

L.TabGeneral = "常规"
L.TabStyle = "样式"
L.TabFonts = "文本"
L.TabColors = "颜色"
L.TabCastbar = "施法条"
L.TabDebuffs = "减益"
L.TabBuffs = "增益"
L.TabPersonal = "个人条"
L.TabCP = "连击点"
L.TabTurboDebuffs = "光环增强"
L.TabObjectives = "怪物标识"
L.TabMisc = "选项"
L.TabStacking = "堆叠"
L.TabProfiles = "配置"

-- Personal Bar
L.PersonalBarEnable = "启用个人资源条"
L.PersonalBarEnableDesc = "显示自己的姓名版，包含生命值和能量条"
L.PersonalBarWidth = "血条宽度"
L.PersonalBarHeight = "生命值条高度"
L.PersonalBarShowPower = "显示能量条"
L.PersonalBarPowerHeight = "能量条高度"
L.PersonalBarHealthFormat = "生命值文本格式"
L.PersonalBarPowerFormat = "能量文本格式"
L.PersonalBarUseClassColor = "按职业着色"
L.PersonalBarShowBuffs = "显示增益效果"
L.PersonalBarShowDebuffs = "显示减益效果"
L.PersonalBarBorderStyle = "边框样式"
L.PersonalBarBorderNone = "无边框"
L.PersonalBarBorderDebuff = "按减益效果着色"
L.PersonalBarBorderDebuffOnly = "仅减益效果时显示边框"
L.PersonalBarBorderBlack = "默认黑色"
L.PersonalBarYOffset = "垂直偏移"
L.PersonalBarBuffXOffset = "增益图标X位置"
L.PersonalBarBuffYOffset = "增益图标Y位置"
L.PersonalBarDebuffXOffset = "减益图标X位置"
L.PersonalBarDebuffYOffset = "减益图标Y位置"
L.PersonalBarHealthColor = "生命值条颜色"
L.PersonalBarPowerColorByType = "按类型着色能量"
L.PersonalBarShowAdditionalPower = "变形时显示法力条"
L.PersonalBarAdditionalPowerHeight = "额外能量条高度"
L.HeroPowerOrder = "能量条顺序"

-- Import/Export
L.ImportExportHeader = "导入/导出设置"
L.ImportExportDesc = "导出你的设置与他人分享，或导入设置字符串应用他人的配置。"
L.ExportSettings = "设置"
L.ExportHighlights = "高亮法术"
L.ExportWhitelist = "白名单光环"
L.ExportBlacklist = "黑名单光环"
L.ExportButton = "导出选中项"
L.ImportButton = "导入选中项"
L.CopyButton = "复制"
L.Reset = "重置"
L.ClearButton = "清除"
L.ExportSuccess = "设置已导出！请复制上方文本。"
L.ExportFailed = "导出失败："
L.ImportSuccess = "设置已成功导入！"
L.ImportFailed = "导入失败："
L.ImportEmpty = "请先粘贴设置字符串。"
L.CopySuccess = "已复制到剪贴板！"
L.CopyEmpty = "没有可复制的内容。请先导出。"
L.Close = "关闭"

-- Stacking
L.StackingHeader = "姓名版堆叠："
L.StackingEnable = "启用姓名版堆叠"
L.StackingEnableDesc = "防止姓名版重叠的平滑堆叠算法"
L.StackingPreset = "行为预设（需要 /reload）"
L.StackingPresetBalanced = "均衡"
L.StackingPresetChill = "平缓"
L.StackingPresetSnappy = "灵敏"
L.StackingPresetReloadPrompt = "更改预设需要重新加载界面。立即重载？"
L.StackingClickboxNote = "提示：堆叠偏移基于杂项页中的可点击姓名版尺寸。"
L.StackingSpringHeader = "动画速度："
L.StackingSpringRaise = "上升速度"
L.StackingSpringRaiseDesc = "姓名版向上堆叠时的移动速度（越高越灵敏）"
L.StackingSpringLower = "下降速度"
L.StackingSpringLowerDesc = "姓名版取消堆叠时的下降速度（较慢更自然）"
L.StackingOverlapHeader = "重叠检测："
L.StackingXSpace = "水平重叠"
L.StackingXSpaceDesc = "堆叠时：100%=边缘接触，<100%=允许重叠，>100%=提前堆叠"
L.StackingYSpace = "垂直间距"
L.StackingYSpaceDesc = "堆叠姓名版之间的间距（点击框高度的百分比）"
L.StackingPositionHeader = "位置："
L.StackingOriginPos = "基础高度"
L.StackingOriginPosDesc = "姓名版在怪物上方的基准高度（0%=无，100%=默认，200%=高）"
L.StackingUpperBorder = "屏幕顶部边距"
L.StackingUpperBorderDesc = "姓名版不能超过的屏幕顶部距离（越低=屏幕利用率越高）"

L.NonTargetAlpha = "非目标透明度"
L.NonTargetAlphaDesc = "拥有目标时，非目标姓名版的透明度（0%=不可见，100%=完全可见）"
L.PerformanceHeader = "性能："
L.PotatoPCMode = "土豆电脑模式"
L.PotatoPCModeDesc = "降低更新频率以减少CPU占用。建议老旧或慢速电脑使用。"

-- Auras
L.AurasShowDebuffs = "启用减益效果追踪"
L.AurasOwnOnly = "仅自己的"
L.AurasMaxDebuffs = "最大减益数量"
L.AurasDebuffWidth = "减益图标宽度"
L.AurasDebuffHeight = "减益图标高度"
L.AurasDebuffFontSize = "计时器字号"
L.AurasDebuffStackFontSize = "堆叠数字号"
L.AurasBuffFilterMode = "增益过滤"
L.AurasShowBuffs = "启用增益效果追踪"
L.AurasBuffFilterOnlyDispellable = "仅可驱散的"
L.AurasBuffFilterWhitelistDispellable = "白名单 + 可驱散"
L.AurasBuffFilterWhitelistOnly = "仅白名单"
L.AurasBuffFilterAll = "全部（黑名单除外）"
L.AurasBuffFilterDisabled = "禁用"
L.AurasMaxBuffs = "最大增益数量"
L.AurasBuffWidth = "增益图标宽度"
L.AurasBuffHeight = "增益图标高度"
L.AurasBuffFontSize = "计时器字号"
L.AurasBuffStackFontSize = "堆叠数字号"
L.AurasBuffGrowDirection = "增益显示方向"
L.AurasBuffIconSpacing = "图标间距"
L.AurasBuffMinDuration = "最小持续时间（秒）"
L.AurasBuffMaxDuration = "最大持续时间（秒）"
L.AurasMinDuration = "最小持续时间（秒）"
L.AurasMaxDuration = "最大持续时间（秒）"
L.Unlimited = "无限制"
L.AurasDebuffSortMode = "减益排序"
L.AurasBuffSortMode = "增益排序"
L.AurasSortLeastTime = "剩余时间最少"
L.AurasSortMostRecent = "最近施加"
L.AurasGrowDirection = "减益显示方向"
L.AurasIconSpacing = "图标间距"
L.AurasXOffset = "水平偏移"
L.AurasYOffset = "垂直偏移"
L.AurasAnchorLeft = "左侧"
L.AurasAnchorCenter = "居中"
L.AurasAnchorRight = "右侧"
L.AurasDebuffBorderMode = "减益边框"
L.AurasBuffBorderMode = "增益边框"
L.AurasBorderDisabled = "禁用"
L.AurasBorderColorCoded = "按类型着色"
L.AurasBorderDispellable = "可驱散"
L.AurasBorderCustom = "自定义颜色"

L.AurasDurationAnchor = "计时器锚点"
L.AurasStackAnchor = "堆叠数字点"
L.AurasAnchorTop = "上方"
L.AurasAnchorTopLeft = "左上"
L.AurasAnchorTopRight = "右上"
L.AurasAnchorBottom = "下方"
L.AurasAnchorBottomLeft = "左下"
L.AurasAnchorBottomRight = "右下"

L.AuraColors = "光环颜色："
L.DebuffBorderColor = "减益边框"
L.BuffBorderColor = "增益边框"

-- Spell List Manager
L.SpellListHeader = "法术过滤器"
L.AuraBlacklist = "光环黑名单"
L.AuraWhitelist = "光环白名单"
L.BlacklistManager = "黑名单光环"
L.WhitelistManager = "白名单光环"
L.BlacklistDesc = "永不显示的法术"
L.WhitelistDesc = "始终绕过过滤器的法术"
L.SpellIDInput = "法术ID"
L.AddSpell = "添加"
L.RemoveSpell = "移除"
L.ClearAll = "全部清除"
L.NoSpellsInList = "列表中没有法术"
L.InvalidSpellID = "无效的法术ID"
L.SpellAlreadyExists = "法术已在列表中"
L.SpellAdded = "已添加法术"
L.SpellRemoved = "已移除法术"
L.ListCleared = "列表已清空"
L.CustomAuraNameplateColor = "根据光环自定义姓名版颜色（优先级列表）"
L.CustomAuraNameplateColorDesc = "首个匹配的增益/减益规则将覆盖姓名版生命值条的颜色。"
L.AuraColorSpellID = "法术ID"
L.AuraColorOwnOnly = "仅自己的"
L.AuraColorAddRule = "添加规则"
L.AuraColorNoRules = "没有光环颜色规则"

-- General Tab
L.ShowNameplatesFor = "显示姓名版："
L.FriendlyUnits = "友方单位"
L.EnemyUnits = "敌方单位"
L.ShowPetsLabel = "宠物"
L.ShowGuardians = "守护者"
L.ShowTotems = "图腾"
L.ShowCastbar = "启用施法条"
L.ShowCastSpark = "显示火花"
L.ShowCastTimer = "显示计时器"
L.ShowMinimap = "小地图按钮"
L.FriendlyNameOnly = "仅名称模式"
L.FriendlyNameOnlyTip = "将友方玩家显示为轻量级仅名称姓名版，不显示血条"
L.LiteHealthWhenDamaged = "受伤时显示血条"
L.LiteHealthWhenDamagedTip = "当友方单位生命值低于100%时，显示紧凑型百分比血条"
L.FriendlyGuild = "显示公会名称"
L.ExecuteRange = "斩杀阈值（%）"

L.EnableHighlightGlow = "启用高亮发光"
L.EnableHighlightGlowTip = "施放高亮列表中的法术时，在施法条上显示动画发光效果"
L.HighlightGlowLines = "线条和粒子"
L.HighlightGlowFrequency = "频率"
L.HighlightGlowLength = "长度"
L.HighlightGlowThickness = "厚度"
L.HighlightGlowColor = "高亮发光颜色"
L.HighlightSpells = "高亮法术"
L.HighlightSpellsDesc = "具有自定义高亮的法术"
L.NoHighlightSpells = "未配置高亮法术"
L.GeneralOptionsHeader = "友方姓名版："

-- PvP
L.PvPHeader = "PvP："
L.ClassColoredHealth = "按职业着色血条"
L.ClassColoredName = "按职业着色名称"
L.ArenaNumbers = "竞技场：显示竞技场编号"
L.HealerMarks = "竞技场/战场：治疗者图标"
L.HealerMarksDisabled = "禁用"
L.HealerMarksEnemiesOnly = "仅敌方"
L.HealerMarksFriendlyOnly = "仅友方"
L.HealerMarksBoth = "双方"
L.TargetingMeIndicator = "目标指向我"
L.TargetingMeColor = "目标指向我"

-- Quest
L.ShowQuestNPCs = "显示任务NPC"
L.ShowQuestObjectives = "显示任务目标"
L.QuestIconScale = "任务图标缩放"
L.QuestIconAnchor = "任务图标锚点"
L.QuestIconX = "图标X偏移"
L.QuestIconY = "图标Y偏移"
L.EliteBossIndicator = "精英/首领标识"
L.EliteBossIconAnchor = "精英/首领位置"
L.EliteBossIconX = "精英/首领X偏移"
L.EliteBossIconY = "精英/首领Y偏移"
L.EliteBossIconSize = "精英/首领大小"

L.Width = "姓名版宽度"
L.HpHeight = "血条高度"
L.CastHeight = "施法条高度"
L.ShowCastIcon = "显示图标"
L.HealthBarBorder = "血条边框"
L.Scale = "姓名版缩放"
L.TargetScale = "目标姓名版缩放"
L.FriendlyScale = "友方姓名版缩放"
L.RaidMarkerSize = "团队标记大小"
L.RaidMarkerAnchor = "团队标记锚点"
L.RaidMarkerAnchorLeft = "左侧"
L.RaidMarkerAnchorRight = "右侧"
L.RaidMarkerAnchorTop = "上方（名称上方）"
L.RaidMarkerX = "团队标记X"
L.RaidMarkerY = "团队标记Y"
L.Texture = "条纹理"
L.BackgroundAlpha = "背景透明度"
L.HpColor = "敌方血条"
L.CastColor = "普通施法"
L.NoInterruptColor = "不可打断"
L.TankMode = "坦克模式"
L.TankModeDisabled = "禁用"
L.TankModeSmart = "智能（自动）"
L.TankModeEnabled = "始终开启"
L.FriendlyFontSize = "友方仅名称字号"
L.GuildFontSize = "友方公会名称字号"

-- Tank Colors
L.TankColors = "坦克模式颜色："
L.CastbarColors = "施法条颜色："
L.BaseColors = "姓名版颜色："
L.EnemyNameColor = "敌方名称"
L.TappedColor = "已标记"
L.SecureColor = "稳固"
L.TransColor = "失去中"
L.InsecureColor = "已丢失"
L.OffTankColor = "副坦克"

L.DpsColors = "DPS/治疗颜色："
L.DpsSecureColor = "安全"
L.DpsTransColor = "警告"
L.DpsAggroColor = "仇恨"
L.TargetPvPColors = "目标/PvP颜色："

-- Font
L.Font = "字体"
L.FontSize = "姓名版名称字号"
L.NameTextYOffset = "名称垂直偏移"
L.FontOutline = "字体描边"
L.NameDisplayFormat = "名称显示格式"

L.HealthValueFormat = "生命值格式"
L.HealthValueFontSize = "生命值字号"
L.NameInHealthbar = "在血条内显示名称"
L.HidePercentWhenFull = "满血时隐藏百分比"
L.HealthFormatNone = "无"
L.HealthFormatCurrent = "当前值"
L.HealthFormatPercent = "百分比%"
L.HealthFormatCurrentMax = "当前值/最大值"
L.HealthFormatCurrentMaxPercent = "当前值/最大值（百分比%）"
L.HealthFormatCurrentPercent = "当前值（百分比%）"
L.HealthFormatDeficit = "损失值（丢失生命）"
L.HealthFormatCurrentDeficit = "当前值|损失值"
L.HealthFormatPercentDeficit = "百分比%|损失值"

L.TotemDisplay = "自定义图腾显示"
L.TotemDisabled = "禁用（完整姓名版）"
L.TotemHPName = "血量+名称"
L.TotemIconOnly = "仅图标"
L.TotemIconName = "图标+名称"
L.TotemIconHP = "图标+血量"
L.TotemIconNameHP = "图标+名称+血量"

L.PetScale = "宠物姓名版缩放"
L.PetColor = "敌方宠物"
L.TargetGlow = "目标发光"
L.TargetArrow = "目标箭头"
L.TargetGlowColor = "目标发光颜色"
L.MouseoverGlowColor = "鼠标悬停高亮"
L.ClickableAreaHeader = "姓名版点击区域设置："
L.ClickableWidth = "点击宽度"
L.ClickableHeight = "点击高度"
L.ShowClickbox = "预览点击区域"

L.LevelIndicator = "等级文本"
L.LevelIndicatorDisabled = "禁用"
L.LevelIndicatorEnemies = "仅敌方"
L.LevelIndicatorAll = "友方+敌方"
L.LevelSize = "大小"
L.LevelX = "X位置"
L.LevelY = "Y位置"

L.ClassificationAnchor = "分类图标"
L.ClassificationDisabled = "禁用"
L.ClassificationTopLeft = "左上"
L.ClassificationTopRight = "右上"
L.ClassificationTop = "上方"
L.ClassificationBottom = "下方"
L.ClassificationBottomLeft = "左下"
L.ClassificationBottomRight = "右下"

L.ThreatTextAnchor = "仇恨文本显示"
L.ThreatTextDisabled = "禁用"
L.ThreatTextRightHP = "血条右侧"
L.ThreatTextLeftHP = "血条左侧"
L.ThreatTextBelowHP = "血条下方"
L.ThreatTextTopHP = "血条上方"
L.ThreatTextLeftName = "名称左侧"
L.ThreatTextRightName = "名称右侧"
L.ThreatTextFontSize = "仇恨字号"
L.ThreatTextXOffset = "仇恨文本X"
L.ThreatTextYOffset = "仇恨文本Y"

-- Combo Points
L.CPHeader = "连击点"
L.ShowComboPoints = "启用连击点"
L.CPOnPersonalBar = "在个人条上显示"
L.CPStyle = "样式"
L.CPStyleSquare = "方形"
L.CPStyleRounded = "圆角"
L.CPSize = "大小"
L.CPX = "姓名版X"
L.CPY = "姓名版Y"
L.CPPersonalX = "个人条X"
L.CPPersonalY = "个人条Y"
L.LivePreview = "实时预览"
L.LeftClick = "左键："
L.Settings = "设置"
L.Reload = "右键：重载界面"

-- ============================================================================
-- Hardcoded string translations
-- ============================================================================

L.BoostedBy = "已加载 |cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r v%s - /tp 打开配置"
L.OptionsClosedCombat = "|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r：战斗中已关闭选项。"
L.OptionsWillOpen = "|cff4fa3ffT|cff5fb6f7u|cff6fcaefr|cff7fdee7b|cff8ff2d8o|cff9ff6b0P|cfffff68fl|cffffd36da|cffffb24at|cffff9138e|cffff3300s|r：战斗结束后将打开选项。"
L.ConflictText = "|cff4fa3ffTurboPlates|r 检测到不兼容的姓名版插件：|cffff6666%s|r\n\n同一时间只能启用一个姓名版插件。"
L.DisableIt = "禁用该插件"
L.DisableTP = "禁用 TurboPlates"
L.ResetText = "将所有 TurboPlates 设置重置为默认值？\n\n这将重载你的界面。\n（法术列表将被保留）"
L.ResetYes = "是"
L.ResetNo = "否"
L.ReloadRequired = "此设置需要重载界面才能完全生效。立即重载？"
L.ReloadNow = "立即重载"
L.Later = "稍后再说"
L.ImportReload = "设置已成功导入！\n\n立即重载以应用更改？"
L.WhitelistName = "白名单"
L.BlacklistName = "黑名单"
L.RemovedFrom = "已从 %s 中移除 - %s"
L.AddedTo = "已添加至 %s - %s"
L.SpellAlreadyIn = "法术已在 %s 中"
L.ClearSpellList = "清除 %s 中的所有法术？"
L.RemovedFromHL = "已从高亮列表中移除 - %s"
L.AddedToHL = "已添加至高亮列表 - %s"
L.SpellAlreadyInHL = "法术已在高亮列表中"
L.EnableTurboDebuffs = "启用光环增强"
L.TurboDebuffsDesc = "针对 Ascension 从零构建的高性能自定义 'BigDebuffs' 集成。遵守光环黑名单条目。"
L.TDShowForFriendlies = "在友方上显示"
L.TDNormalNameplates = "普通姓名版："
L.TDFriendlyNameOnly = "友方仅名称姓名版："
L.TDIconPosition = "图标位置"
L.TDIconSize = "图标大小"
L.TDTimerFontSize = "计时器字号"
L.TDXOffset = "X偏移"
L.TDYOffset = "Y偏移"
L.TDShowCategories = "显示分类："
L.TDImmunities = "免疫"
L.TDCrowdControl = "控制"
L.TDSilences = "沉默"
L.TDInterrupts = "打断"
L.TDRoots = "定身"
L.TDDisarms = "缴械"
L.TDDefensiveBuffs = "防御增益"
L.TDOffensiveBuffs = "攻击增益"
L.TDOtherBuffs = "其他增益"
L.TDSnares = "减速"
L.TDLeft = "左侧"
L.TDRight = "右侧"
L.TDTop = "上方"
L.TDBottom = "下方"
L.StackingStats = "[TurboPlates 堆叠] 活跃：%d，数据池：%d，条目池：%d"
L.StackingCommands = "[TurboPlates 堆叠命令]"
L.StackingStatsCmd = "  /tp stacking stats - 显示池统计信息"
L.ExportNoSettings = "没有要导出的设置"
L.ExportNoCategory = "未选择类别"
L.ExportNoData = "没有要导出的数据"
L.ExportSerialFailed = "序列化失败"
L.ExportCompressFailed = "压缩失败"
L.ExportEncodeFailed = "编码失败"
L.ImportEmptyStr = "导入字符串为空"
L.ImportInvalidPrefix = "格式无效（缺少 TurboPlates 前缀）"
L.ImportDecodeFailed = "解码失败 - 无效的字符串"
L.ImportDecompressFailed = "解压失败 - 数据损坏"
L.ImportDeserializeFailed = "反序列化失败 - 无效数据"
L.ImportValidationFailed = "验证失败 - 格式错误的设置"
L.ImportNoMatch = "字符串中未找到匹配的数据"
L.ImportSuccessStr = "已导入：%s"
L.LabelSettings = "设置"
L.LabelHighlights = "法术高亮"
L.LabelWhitelist2 = "白名单"
L.LabelBlacklist2 = "黑名单"
L.LabelDeleted = "已删除"
L.Yes = "是"
L.No = "否"

-- ============================================================================
-- Dropdown Name Translations (override English from Config.lua)
-- ============================================================================

ns:RegisterLocalePostApply("zhCN", function()
    ApplyChineseFont()

-- Outlines
for _, v in ipairs(ns.Outlines) do
    if v.value == "" then v.name = "无"
    elseif v.value == "OUTLINE" then v.name = "细描边"
    elseif v.value == "THICKOUTLINE" then v.name = "粗描边"
    elseif v.value == "MONOCHROME" then v.name = "单色"
    end
end

-- Name Formats
for _, v in ipairs(ns.NameFormats) do
    if v.value == "disabled" then v.name = "禁用"
    elseif v.value == "none" then v.name = "全名"
    elseif v.value == "abbreviate" then v.name = "缩写"
    elseif v.value == "first" then v.name = "仅名"
    elseif v.value == "last" then v.name = "仅姓"
    end
end

-- Target Glow Styles
for _, v in ipairs(ns.TargetGlowStyles) do
    if v.value == "none" then v.name = "禁用"
    elseif v.value == "border" then v.name = "边框发光"
    elseif v.value == "thick" then v.name = "粗轮廓"
    elseif v.value == "thin" then v.name = "细轮廓"
    end
end

-- Target Arrow Styles
for _, v in ipairs(ns.TargetArrowStyles) do
    if v.value == "none" then v.name = "禁用"
    elseif v.value == "arrows_thin" then v.name = "箭头（细）"
    elseif v.value == "arrows_normal" then v.name = "箭头（普通）"
    elseif v.value == "arrows_double" then v.name = "箭头（双）"
    end
end

-- Targeting Me Styles
for _, v in ipairs(ns.TargetingMeStyles) do
    if v.value == "disabled" then v.name = "禁用"
    elseif v.value == "glow" then v.name = "发光高亮"
    elseif v.value == "border" then v.name = "边框颜色"
    elseif v.value == "name" then v.name = "名称颜色"
    elseif v.value == "health" then v.name = "血条颜色"
    end
end

-- Quest Icon Anchors
for _, v in ipairs(ns.QuestIconAnchors) do
    if v.value == "LEFT" then v.name = "左侧"
    elseif v.value == "RIGHT" then v.name = "右侧"
    elseif v.value == "TOP" then v.name = "上方"
    end
end

-- Elite/Boss Icon Anchors
for _, v in ipairs(ns.EliteBossIconAnchors) do
    if v.value == "TOPLEFT" then v.name = "左上"
    elseif v.value == "TOP" then v.name = "上方"
    elseif v.value == "TOPRIGHT" then v.name = "右上"
    elseif v.value == "LEFT" then v.name = "左侧"
    elseif v.value == "RIGHT" then v.name = "右侧"
    elseif v.value == "BOTTOMLEFT" then v.name = "左下"
    elseif v.value == "BOTTOM" then v.name = "下方"
    elseif v.value == "BOTTOMRIGHT" then v.name = "右下"
    end
end

-- Elite/Boss Indicator Styles
for _, v in ipairs(ns.EliteBossIndicatorStyles) do
    if v.value == "none" then v.name = "禁用"
    elseif v.value == "default" then v.name = "默认"
    elseif v.value == "colored_skulls" then v.name = "彩色骷髅"
    elseif v.value == "elvui_dragons" then v.name = "ElvUI 龙形边饰"
    elseif v.value == "sre_classic" then v.name = "SRE - 经典"
    elseif v.value == "sre_modern" then v.name = "SRE - 现代"
    elseif v.value == "sre_tiny" then v.name = "SRE - 迷你"
    end
end

-- Health Formats
for _, v in ipairs(ns.HealthFormats) do
    if v.value == "none" then v.name = "无"
    elseif v.value == "current" then v.name = "当前值"
    elseif v.value == "percent" then v.name = "百分比%"
    elseif v.value == "current-max" then v.name = "当前值/最大值"
    elseif v.value == "current-max-percent" then v.name = "当前值/最大值（百分比%）"
    elseif v.value == "current-percent" then v.name = "当前值（百分比%）"
    elseif v.value == "deficit" then v.name = "损失值"
    elseif v.value == "current-deficit" then v.name = "当前值|损失值"
    elseif v.value == "percent-deficit" then v.name = "百分比%|损失值"
    end
end

-- Power Formats
for _, v in ipairs(ns.PowerFormats) do
    if v.value == "none" then v.name = "无"
    elseif v.value == "current" then v.name = "当前值"
    elseif v.value == "percent" then v.name = "百分比%"
    elseif v.value == "current-max" then v.name = "当前值/最大值"
    elseif v.value == "current-max-percent" then v.name = "当前值/最大值（百分比%）"
    elseif v.value == "current-percent" then v.name = "当前值（百分比%）"
    elseif v.value == "deficit" then v.name = "损失值"
    elseif v.value == "current-deficit" then v.name = "当前值|损失值"
    elseif v.value == "percent-deficit" then v.name = "百分比%|损失值"
    end
end

-- Personal Border Styles
for _, v in ipairs(ns.PersonalBorderStyles) do
    if v.value == "removable" then v.name = "可移除减益颜色"
    elseif v.value == "black" then v.name = "默认黑色"
    elseif v.value == "debuff" then v.name = "按减益着色"
    elseif v.value == "debuff_only" then v.name = "仅减益时显示边框"
    elseif v.value == "none" then v.name = "无边框"
    end
end

-- Hero Power Orders
for _, v in ipairs(ns.HeroPowerOrders) do
    if v.value == 1 then v.name = "法力 > 能量 > 怒气"
    elseif v.value == 2 then v.name = "法力 > 怒气 > 能量"
    elseif v.value == 3 then v.name = "能量 > 法力 > 怒气"
    elseif v.value == 4 then v.name = "能量 > 怒气 > 法力"
    elseif v.value == 5 then v.name = "怒气 > 法力 > 能量"
    elseif v.value == 6 then v.name = "怒气 > 能量 > 法力"
    end
end
end)
