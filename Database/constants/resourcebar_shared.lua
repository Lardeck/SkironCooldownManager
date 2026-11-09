local SCM = select(2, ...)

SCM.Constants.RESOURCE_BAR = {
	CLASS_SECONDARY_POWER = {
		["DRUID"] = {
			powerType = Enum.PowerType.ComboPoints,
			powerToken = "COMBO_POINTS",
			showWhenPrimaryPowerType = Enum.PowerType.Energy,
			registerUnitAuraSpecs = {
				[103] = true,
			},
		},
		["ROGUE"] = {
			powerType = Enum.PowerType.ComboPoints,
			powerToken = "COMBO_POINTS",
		},
	},

	POWER_TYPES = {
		{ token = "MANA", label = "Mana" },
		{ token = "RAGE", label = "Rage" },
		{ token = "FOCUS", label = "Focus", client = WOW_PROJECT_MAINLINE },
		{ token = "ENERGY", label = "Energy" },
		{ token = "COMBO_POINTS", label = "Combo Points" },
		{ token = "RUNES", label = "Runes", client = WOW_PROJECT_MAINLINE },
		{ token = "RUNIC_POWER", label = "Runic Power", client = WOW_PROJECT_MAINLINE },
		{ token = "SOUL_SHARDS", label = "Soul Shards", client = WOW_PROJECT_MAINLINE },
		{ token = "LUNAR_POWER", label = "Astral Power", client = WOW_PROJECT_MAINLINE },
		{ token = "HOLY_POWER", label = "Holy Power", client = WOW_PROJECT_MAINLINE },
		{ token = "MAELSTROM", label = "Maelstrom", client = WOW_PROJECT_MAINLINE },
		{ token = "CHI", label = "Chi", client = WOW_PROJECT_MAINLINE },
		{ token = "INSANITY", label = "Insanity", client = WOW_PROJECT_MAINLINE },
		{ token = "ARCANE_CHARGES", label = "Arcane Charges", client = WOW_PROJECT_MAINLINE },
		{ token = "FURY", label = "Fury", client = WOW_PROJECT_MAINLINE },
		{ token = "PAIN", label = "Pain", client = WOW_PROJECT_MAINLINE },
		{ token = "ESSENCE", label = "Essence", client = WOW_PROJECT_MAINLINE },
		{ token = "STAGGER", label = "Stagger", client = WOW_PROJECT_MAINLINE },
		{ token = "MAELSTROM_WEAPON", label = "Maelstrom Weapon", client = WOW_PROJECT_MAINLINE },
		{ token = "SOUL_FRAGMENTS", label = "Soul Fragments (Devourer)", client = WOW_PROJECT_MAINLINE },
		{ token = "SOUL_FRAGMENTS_VENGEANCE", label = "Soul Fragments (Vengeance)", client = WOW_PROJECT_MAINLINE },
		{ token = "TIP_OF_THE_SPEAR", label = "Tip of the Spear", client = WOW_PROJECT_MAINLINE },
		{ token = "ICICLES", label = "Icicles", client = WOW_PROJECT_MAINLINE },
		{ token = "SPELL_CHARGES_FIRE_BLAST", label = "Fire Blast Charges", client = WOW_PROJECT_MAINLINE },
		{ token = "SPELL_CHARGES_SERENITY", label = "Serenity Charges", client = WOW_PROJECT_MAINLINE },
	},

	DRUID_PRIMARY_POWER_TYPES = {
		none = "None",
		[Enum.PowerType.Mana] = "Mana",
		[Enum.PowerType.Energy] = "Energy",
		[Enum.PowerType.Rage] = "Rage",
	},

	DRUID_SECONDARY_POWER_TYPES = {
		none = "None",
		[Enum.PowerType.Mana] = "Mana",
		[Enum.PowerType.ComboPoints] = "Combo Points",
	},

	DRUID_SECONDARY_RESOURCE_BY_POWER_TYPE = {
		[Enum.PowerType.Mana] = {
			powerType = Enum.PowerType.Mana,
			powerToken = "MANA",
		},
		[Enum.PowerType.ComboPoints] = {
			powerType = Enum.PowerType.ComboPoints,
			powerToken = "COMBO_POINTS",
		},
	},

	SEGMENT_TICKS_BY_POWER_TOKEN = {
		COMBO_POINTS = true,
	},

	MANA_VALUE_ORDER = {
		[1] = "Raw - Percent",
		[2] = "Percent - Raw",
	}
}
