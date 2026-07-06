local SCM = select(2, ...)
local Constants = SCM.Constants

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
	[25] = 26, -- Pandaren (Alliance)
	[26] = 25, -- Pandaren (Horde)
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
	[52] = 70, -- Dracthyr (Alliance)
	[70] = 52, -- Dracthyr (Horde)
	[84] = 85, -- Earthen (Horde)
	[85] = 84, -- Earthen (Alliance)
	[86] = 91, -- Haranir
	[91] = 86, -- Haranir
}
