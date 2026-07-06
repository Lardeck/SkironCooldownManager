local SCM = select(2, ...)
local Constants = SCM.Constants

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
