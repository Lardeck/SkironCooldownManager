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

Constants.TextOutline = {
	NONE = "None",
	OUTLINE = "Outline",
	THICKOUTLINE = "Thick Outline",
	MONOCHROME = "Monochrome",
	["OUTLINE,MONOCHROME"] = "Monochrome Outline",
}

Constants.ResourceBarGrowthDirection = {
	UP = "Up",
	DOWN = "Down",
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
	[255] = {
		resourceKind = "tipOfTheSpear",
		powerToken = "TIP_OF_THE_SPEAR",
		segmentCount = 3,
		registerUnitAura = true,
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
	{ token = "TIP_OF_THE_SPEAR", label = "Tip of the Spear" },
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
	TIP_OF_THE_SPEAR = true,
}

Constants.ResourceBarRefreshEvents = {

}

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
	[84] = true, -- Earthen (Horde)
	[85] = true, -- Earthen (Alliance)
}
