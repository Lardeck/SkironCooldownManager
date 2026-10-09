local SCM = select(2, ...)
local Constants = SCM.Constants

Constants.Formatter = {}

Constants.Formatter.DisplayStyle = {
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

Constants.Formatter.DisplayStyleSettings = {
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

Constants.Formatter.DefaultBreakpoints = {
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

Constants.ItemCategories = {
	[4] = true, -- Item - Combat Cons. (Potion)
	[11] = true, -- Item - Food
	[24] = true, -- Item - Combat Cons. (Aggressive)
	[27] = true, -- Item - Scroll
	[28] = true, -- Item - Quick Buff
	[29] = true, -- Item - Debuff
	[30] = true, -- Item - Healing
	[59] = true, -- Item - Drink
	[79] = true, -- Item - Potion (Non-Combat)
	[94] = true, -- Item - Summoning
	[100] = true, -- Item - Mana Gem
	[102] = true, -- Item - Long Buff
	[103] = true, -- Item - Epic
	[150] = true, -- Item - Bandage
	[791] = true, -- Item - Salt Shaker
	[951] = true, -- PVP Battlefield Item - LONG (30 mins)
	[991] = true, -- Item - SnowMaster
	[1031] = true, -- Item - Half Hour
	[1051] = true, -- Item - Jumper Cables
	[1071] = true, -- Item - Hatch Jubling
	[1139] = true, -- Item - Quest (10 minutes)
	[1140] = true, -- Item - Quest (1 min)
	[1141] = true, -- Item - Burst Trinket
	[1143] = true, -- Item - Target Dummy
	[1146] = true, -- Item - Enchanting Rod
	[1153] = true, -- Item - Combat Cons. (Non-Aggressive)
	[1157] = true, -- Item - Quest (10 sec)
	[1160] = true, -- Item - Priest Epic Staff
	[1183] = true, -- Item - Netherwing Whelp
	[1190] = true, -- Item - PVP Health Increase
	[1193] = true, -- Item - Repair Bot
	[1203] = true, -- Item - Speed
	[1213] = true, -- Item - Tracking
	[1216] = true, -- Item - Engineering Enchant
	[1229] = true, -- Item - Scroll of Recall
	[1232] = true, -- Item - Darkmoon Tarot Cards
	[1361] = true, -- Scenario - Item - Damage
	[1362] = true, -- Scenario - Item - Stun
	[1364] = true, -- Scenario - Item - Heal
	[1416] = true, -- Item - The Pigskin
	[1430] = true, -- Item - Combat Cons. (Landshark)
	[1444] = true, -- Item - Push Loot
	[1473] = true, -- Item - Portable Mailbox - Engineering
	[1476] = true, -- Item - On Use - Helm Visual
	[1711] = true, -- Item - Healthstone
	[1836] = true, -- Item - PvP - Defensive Trinket
	[1909] = true, -- 9.0 Covenant - Phial of Serenity
	[2295] = true, -- 11.0 Professions - Engineering - Pausing Pylon
	[2347] = true, -- 11.1 - Cantrip - 2H Mace - Slot Machine Arm - Shared CD
	[2495] = true, -- 12.0 Raid - Darkwell - Boss 01 - Belo'ren - Accessory - Trinket - Shared Trasnform
	[2566] = true, -- Item - Demonic Healthstone
}
