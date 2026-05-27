local SCM = select(2, ...)
SCM.Constants = {}

BACKDROP_SCM_PIXEL = {
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 2,
}

SCM.CooldownViewerNameToIndex = {
	["EssentialCooldownViewer"] = Enum.CooldownViewerCategory.Essential,
	--["UtilityCooldownViewer"] = Enum.CooldownViewerCategory.Utility,
	["UtilityCooldownViewer"] = Enum.CooldownViewerCategory.Essential,
	["BuffIconCooldownViewer"] = Enum.CooldownViewerCategory.TrackedBuff,
	["BuffBarCooldownViewer"] = Enum.CooldownViewerCategory.TrackedBar,
}

local Constants = SCM.Constants
Constants.AnchorPoints = {
	TOPLEFT = "TOPLEFT",
	TOP = "TOP",
	TOPRIGHT = "TOPRIGHT",
	LEFT = "LEFT",
	CENTER = "CENTER",
	RIGHT = "RIGHT",
	BOTTOMLEFT = "BOTTOMLEFT",
	BOTTOM = "BOTTOM",
	BOTTOMRIGHT = "BOTTOMRIGHT",
}

Constants.GrowthDirections = {
	CENTERED = "Centered Horizontal",
	LEFT = "Left",
	RIGHT = "Right",
	FIXED = "Fixed",
}

Constants.SecondaryGrowthDirections = {
	DOWN = "Down",
	UP = "Up",
}

Constants.FrameStrata = {
	[""] = "Default",
	BACKGROUND = "Background",
	LOW = "Low",
	MEDIUM = "Medium",
	HIGH = "High",
	DIALOG = "Dialog",
	FULLSCREEN = "Fullscreen",
	FULLSCREEN_DIALOG = "Fullscreen Dialog",
	-- TOOLTIP = "Tooltip",
}

Constants.FrameStrataSorted = {
	"",
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"FULLSCREEN",
	"FULLSCREEN_DIALOG",
	-- "TOOLTIP",
}

Constants.TextOutline = {
	[""] = "None",
	OUTLINE = "Outline",
	THICKOUTLINE = "Thick Outline",
	MONOCHROME = "Monochrome",
	["OUTLINE,MONOCHROME"] = "Monochrome Outline",
	SLUG = "Slug",
	["OUTLINE SLUG"] = "Outline Slug",
}

Constants.TextOutlineSorted = {
	"",
	"OUTLINE",
	"SLUG",
	"MONOCHROME",
	"OUTLINE,MONOCHROME",
	"OUTLINE SLUG",
	"THICKOUTLINE",
}

Constants.BlendMode = {
	["DISABLE"] = "DISABLE",
	["BLEND"] = "BLEND",
	["ADD"] = "ADD",
	["MOD"] = "MOD",
}

Constants.BlendModeSorted = {
	"DISABLE",
	"BLEND",
	"ADD",
	"MOD"
}

Constants.BuffBarContent = {
	[Enum.CooldownViewerBarContent.IconAndName] = "Bar + Icon",
	[Enum.CooldownViewerBarContent.NameOnly] = "Bar Only"
}

Constants.ResourceBarGrowthDirection = {
	UP = "Up",
	DOWN = "Down",
}

Constants.CooldownTimer = {}

Constants.CooldownTimer.DisplayStyle = {
	{
		decimalSeconds = "Decimal Seconds (1.1)",
		seconds = "Seconds (10s)",
		secondsOnly = "Seconds (10)",
		clock = "Clock (1:10)",
		minutes = "Minutes (2m)",
		hours = "Hours (1h)",
		days = "Days (1d)",
	},
	{
		"decimalSeconds",
		"seconds",
		"secondsOnly",
		"clock",
		"minutes",
		"hours",
		"days",
	},
}

Constants.CooldownTimer.DisplayStyleSettings = {
	decimalSeconds = {
		step = 0.1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%.1f",
	},
	seconds = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%ds",
	},
	secondsOnly = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d",
	},
	clock = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d:%02d",
	},
	minutes = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dm",
	},
	hours = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dh",
	},
	days = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dd",
	},
}

Constants.CooldownTimer.DefaultBreakpoints = {
	{
		threshold = 0,
		displayStyle = "secondsOnly",
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d",
	},
	{
		threshold = 60,
		displayStyle = "clock",
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d:%02d",
		components = {
			{ div = 60 },
			{ mod = 60 },
		},
	},
	{
		threshold = 120,
		displayStyle = "minutes",
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dm",
		components = {
			{ div = 60 },
		},
	},
}

Constants.SourcePairs = {
	[0] = 1,
	[1] = 0,
	[2] = 3,
	[3] = 2,
}

Constants.SpecIDs = {
	-- DK
	250,
	251,
	252,
	-- DH
	577,
	581,
	1480,
	-- Druid
	102,
	103,
	104,
	105,
	-- Evoker
	1467,
	1468,
	1473,
	-- Hunter
	253,
	254,
	255,
	-- Mage
	62,
	63,
	64,
	-- Monk
	268,
	269,
	270,
	-- Paladin
	65,
	66,
	70,
	-- Priest
	256,
	257,
	258,
	-- Rogue
	259,
	260,
	261,
	-- Shaman
	262,
	263,
	264,
	-- Warlock
	265,
	266,
	267,
	-- Warrior
	71,
	72,
	73,
}

Constants.ClassSecondaryPower = {
	["DEATHKNIGHT"] = {
		resourceKind = "runes",
		powerToken = "RUNES",
	},
	["DRUID"] = {
		powerType = Enum.PowerType.ComboPoints,
		powerToken = "COMBO_POINTS",
		showWhenPrimaryPowerType = Enum.PowerType.Energy,
	},
	["EVOKER"] = {
		powerType = Enum.PowerType.Essence,
		powerToken = "ESSENCE",
	},
	["PALADIN"] = {
		powerType = Enum.PowerType.HolyPower,
		powerToken = "HOLY_POWER",
	},
	["ROGUE"] = {
		powerType = Enum.PowerType.ComboPoints,
		powerToken = "COMBO_POINTS",
	},
	["WARLOCK"] = {
		powerType = Enum.PowerType.SoulShards,
		powerToken = "SOUL_SHARDS",
	},
}

Constants.SpecSecondaryPower = {
	[62] = {
		powerType = Enum.PowerType.ArcaneCharges,
		powerToken = "ARCANE_CHARGES",
	},
	[63] = {
		resourceKind = "spellCharges",
		spellID = 108853,
		powerToken = "SPELL_CHARGES_FIRE_BLAST",
		segmentCount = 2,
		segmentCountTalentSpellID = 205029,
		talentSegmentCount = 3,
	},
	[64] = {
		resourceKind = "icicles",
		powerToken = "ICICLES",
		segmentCount = 5,
		registerUnitAura = true,
	},
	[255] = {
		resourceKind = "tipOfTheSpear",
		powerToken = "TIP_OF_THE_SPEAR",
		segmentCount = 3,
		registerUnitAura = true,
	},
	[257] = {
		resourceKind = "spellCharges",
		spellID = 2050,
		powerToken = "SPELL_CHARGES_SERENITY",
		segmentCount = 2,
	},
	[263] = {
		resourceKind = "maelstromWeapon",
		powerToken = "MAELSTROM_WEAPON",
		segmentCount = 5,
		registerUnitAura = true,
	},
	[267] = {
		resourceKind = "destructionSoulShards",
		powerType = Enum.PowerType.SoulShards,
		powerToken = "SOUL_SHARDS",
		segmentCount = 5,
	},
	[268] = {
		resourceKind = "stagger",
		powerToken = "STAGGER",
	},
	[269] = {
		powerType = Enum.PowerType.Chi,
		powerToken = "CHI",
	},
	[581] = {
		resourceKind = "vengeanceSoulFragments",
		powerToken = "SOUL_FRAGMENTS_VENGEANCE",
		spellID = 228477,
		segmentCount = 6,
	},
	[1480] = {
		resourceKind = "soulFragments",
		powerToken = "SOUL_FRAGMENTS",
		registerUnitAura = true,
	},
}

Constants.ClassManaSecondaryPower = {
	["DRUID"] = {
		[Enum.PowerType.LunarPower] = {
			powerType = Enum.PowerType.Mana,
			powerToken = "MANA",
		},
	},
	["PRIEST"] = {
		[Enum.PowerType.Insanity] = {
			powerType = Enum.PowerType.Mana,
			powerToken = "MANA",
		},
	},
	["SHAMAN"] = {
		[Enum.PowerType.Maelstrom] = {
			powerType = Enum.PowerType.Mana,
			powerToken = "MANA",
		},
	},
}

Constants.ChargedComboPointColor = {
	r = 0.25,
	g = 0.70,
	b = 1.00,
	filledAlpha = 0.45,
	emptyAlpha = 0.22,
}

Constants.FallbackPowerColorByToken = {
	ESSENCE = { r = 0.32, g = 0.84, b = 0.90 },
	MAELSTROM_WEAPON = { r = 0.00, g = 0.50, b = 1.00 },
	SOUL_FRAGMENTS = { r = 0.35, g = 0.25, b = 0.73 },
	SOUL_FRAGMENTS_VENGEANCE = { r = 0.35, g = 0.25, b = 0.73 },
	SPELL_CHARGES_FIRE_BLAST = { r = 1.00, g = 0.34, b = 0.12 },
	STAGGER = { r = 0.52, g = 1.00, b = 0.52 },
}

Constants.ResourceBarPowerTypes = {
	{ token = "MANA", label = "Mana" },
	{ token = "RAGE", label = "Rage" },
	{ token = "FOCUS", label = "Focus" },
	{ token = "ENERGY", label = "Energy" },
	{ token = "COMBO_POINTS", label = "Combo Points" },
	{ token = "RUNES", label = "Runes" },
	{ token = "RUNIC_POWER", label = "Runic Power" },
	{ token = "SOUL_SHARDS", label = "Soul Shards" },
	{ token = "LUNAR_POWER", label = "Astral Power" },
	{ token = "HOLY_POWER", label = "Holy Power" },
	{ token = "MAELSTROM", label = "Maelstrom" },
	{ token = "CHI", label = "Chi" },
	{ token = "INSANITY", label = "Insanity" },
	{ token = "ARCANE_CHARGES", label = "Arcane Charges" },
	{ token = "FURY", label = "Fury" },
	{ token = "PAIN", label = "Pain" },
	{ token = "ESSENCE", label = "Essence" },
	{ token = "STAGGER", label = "Stagger" },
	{ token = "MAELSTROM_WEAPON", label = "Maelstrom Weapon" },
	{ token = "SOUL_FRAGMENTS", label = "Soul Fragments (Devourer)" },
	{ token = "SOUL_FRAGMENTS_VENGEANCE", label = "Soul Fragments (Vengeance)" },
	{ token = "TIP_OF_THE_SPEAR", label = "Tip of the Spear" },
	{ token = "ICICLES", label = "Icicles" },
	{ token = "SPELL_CHARGES_FIRE_BLAST", label = "Fire Blast Charges" },
	{ token = "SPELL_CHARGES_SERENITY", label = "Serenity Charges" },
}

Constants.DruidPrimaryPowerTypes = {
	none = "None",
	[Enum.PowerType.Mana] = "Mana",
	[Enum.PowerType.Energy] = "Energy",
	[Enum.PowerType.Rage] = "Rage",
	[Enum.PowerType.LunarPower] = "Lunar",
}

Constants.DruidSecondaryPowerTypes = {
	none = "None",
	[Enum.PowerType.Mana] = "Mana",
	[Enum.PowerType.ComboPoints] = "Combo Points",
}

Constants.DruidSecondaryResourceByPowerType = {
	[Enum.PowerType.Mana] = {
		powerType = Enum.PowerType.Mana,
		powerToken = "MANA",
	},
	[Enum.PowerType.ComboPoints] = {
		powerType = Enum.PowerType.ComboPoints,
		powerToken = "COMBO_POINTS",
	},
}

Constants.SegmentTicksByPowerToken = {
	ARCANE_CHARGES = true,
	CHI = true,
	COMBO_POINTS = true,
	ESSENCE = true,
	HOLY_POWER = true,
	MAELSTROM_WEAPON = true,
	RUNES = true,
	SOUL_SHARDS = true,
	SOUL_FRAGMENTS_VENGEANCE = true,
	SPELL_CHARGES_FIRE_BLAST = true,
	SPELL_CHARGES_SERENITY = true,
	TIP_OF_THE_SPEAR = true,
}

-- Tick counts adapted from ElvUI's channel tick list: https://github.com/tukui-org/ElvUI/blob/63ecc16049c01a1ea6cadd991bb9ab04aecf3854/ElvUI/Game/Mainline/Filters/Filters.lua#L185
Constants.CastBarChannelTicks = {
	ticks = {
		[755] = 5,
		[740] = 4,
		[5143] = 4,
		[15407] = 6,
		[48045] = 6,
		[64843] = 4,
		[64902] = 5,
		[113656] = 4,
		[12051] = 6,
		[120360] = 15,
		[198013] = 10,
		[198590] = 4,
		[205021] = 5,
		[206931] = 3,
		[212084] = 10,
		[234153] = 5,
		[257044] = 7,
		[291944] = 6,
		[356995] = 3,
		[47757] = 3,
		[47758] = 3,
		[373129] = 3,
		[400171] = 3,
	},
	talents = {
		[356995] = { talentSpellID = 1219723, ticks = 4 },
	},
	auras = {
		[47757] = { auraSpellID = 373183, ticks = 6 },
		[47758] = { auraSpellID = 373183, ticks = 6 },
	},
	chain = {
		[356995] = { extraTicks = 1, seconds = 3 },
	},
}

Constants.ResourceBarRefreshEvents = {}

Constants.Roles = {
	HEALER = "Healer",
	DAMAGER = "DPS",
	TANK = "Tank",
}

Constants.Races = {
	[1] = true, -- Human
	[2] = true, -- Orc
	[3] = true, -- Dwarf
	[4] = true, -- Night Elf
	[5] = true, -- Undead
	[6] = true, -- Tauren
	[7] = true, -- Gnome
	[8] = true, -- Troll
	[9] = true, -- Goblin
	[10] = true, -- Blood Elf
	[11] = true, -- Draenei
	[22] = true, -- Worgen
	[25] = true, -- Pandaren (Alliance)
	[26] = true, -- Pandaren (Horde)
	[27] = true, -- Nightborne
	[28] = true, -- Highmountain Tauren
	[29] = true, -- Void Elf
	[30] = true, -- Lightforged Draenei
	[31] = true, -- Zandalari Troll
	[32] = true, -- Kul Tiran
	[34] = true, -- Dark Iron Dwarf
	[35] = true, -- Vulpera
	[36] = true, -- Mag'har Orc
	[37] = true, -- Mechagnome
	[52] = true, -- Dracthyr (Alliance)
	[70] = true, -- Dracthyr (Horde)
	[84] = 85, -- Earthen (Horde)
	[85] = 84, -- Earthen (Alliance)
	[86] = 91, -- Haranir
	[91] = 86, -- Haranir
}

Constants.FakeAuras = {
	-- WARLOCK
	[265187] = 15, -- Summon Tyrant 15
	[1288950] = 23, -- Grimoire: Fel Ravager
	[104316] = 12, -- Call Dreadstalkers
	[1276672] = 12, -- Summon Doomguard (not even Blizzard shows that)

	-- PALADIN
	[26573] = true, -- Consecration 12

	-- PRIEST
	-- [373276] = 24, -- Idol of Yogg-Saron
	[451234] = true, -- Voidwrath 6
	[34433] = true, -- Shadowfiend 6

	-- SHAMAN
	[5394] = true, -- Healing Stream Totem 15
	[108280] = true, -- Healing Tide Totem 10
	[98008] = true, -- Spirit Link Totem 6
	[192077] = true, -- Wind Rush Totem 7
	[355580] = true, -- Static Field Totem 6
	[192058] = true, -- Capacitor Totem 2
	[2484] = true, -- Earthbind Totem 20
	[8143] = true, -- Tremor Totem 10
	[383013] = true, -- Poison Cleansing Totem 6
	[204336] = true, -- Grounding Totem 3
	[204331] = true, -- Counterstrike Totem 15
	[460697] = true, -- Totem of Wrath 15
	[51485] = true, -- Earthgrab Totem 20
	[198103] = true, -- Earth Elemental 30
	--[444995] = 25, -- Surging Totem

	-- MONK
	[322118] = true, -- Invoke Yu'lon, the Jade Serpent 12
}

Constants.TargetAuras = {
	[1160] = true,
}

-- Blizzard randomly clears those cooldowns and I have to fix it. Fun :)
Constants.FixBlizzardSpells = {
	[202137] = true, -- Sigil of Silence
	[204596] = true, -- Sigil of Flame
	[207684] = true, -- Sigil or Misery
	[325153] = true, -- Exploding Keg
}

-- C_Spell.GetSpellCooldown returns a very short cooldown but Blizzard never sets the cooldown which breaks hideWhileNotReady
Constants.CheckCooldownFrameSpells = {
	[190925] = true, -- Harpoon
}