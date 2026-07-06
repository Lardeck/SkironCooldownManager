local SCM = select(2, ...)
local Constants = SCM.Constants

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
