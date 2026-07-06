local SCM = select(2, ...)
local Constants = SCM.Constants

SCM.CooldownViewerNameToIndex = {
	["EssentialCooldownViewer"] = Enum.CooldownViewerCategory.Essential,
	--["UtilityCooldownViewer"] = Enum.CooldownViewerCategory.Utility,
	["UtilityCooldownViewer"] = Enum.CooldownViewerCategory.Essential,
	["BuffIconCooldownViewer"] = Enum.CooldownViewerCategory.TrackedBuff,
	["BuffBarCooldownViewer"] = Enum.CooldownViewerCategory.TrackedBar,
}

Constants.SourcePairs = {
	[0] = 1,
	[1] = 0,
	[2] = 3,
	[3] = 2,
}

Constants.BuffBarContent = {
	[Enum.CooldownViewerBarContent.IconAndName] = "Bar + Icon",
	[Enum.CooldownViewerBarContent.NameOnly] = "Bar Only",
}

Constants.FakeAuras = {
	-- WARLOCK
	[265187] = 15, -- Summon Tyrant 15
	[1288950] = 20, -- Grimoire: Fel Ravager
	[1288945] = 20, -- Grimoire: Imp Lord
	[104316] = 12, -- Call Dreadstalkers
	[1251781] = 15, -- Summon Vilefiend
	[1276672] = 12, -- Summon Doomguard (not even Blizzard shows that)
	[1122] = true, -- Summon Infernal
	[205180] = 25, -- Summon Darkglare

	-- PALADIN
	[26573] = true, -- Consecration 12

	-- PRIEST
	-- [373276] = 24, -- Idol of Yogg-Saron
	[451234] = true, -- Voidwrath 6
	[34433] = true, -- Shadowfiend 6
	[1280137] = true, -- Mindbender 12
	[450193] = true, -- Entropic Rift
	[449880] = true, -- Void Heart

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
	[325197] = true, -- Invoke Chi-ji, the Red Crane 12
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
