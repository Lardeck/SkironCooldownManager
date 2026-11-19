local SCM = select(2, ...)
SCM.Constants = {}

local CONSTANTS = SCM.Constants

BACKDROP_SCM_PIXEL = {
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 2,
}

CONSTANTS.GENERAL = {
	ANCHOR_POINTS = {
		TOPLEFT = "TOPLEFT",
		TOP = "TOP",
		TOPRIGHT = "TOPRIGHT",
		LEFT = "LEFT",
		CENTER = "CENTER",
		RIGHT = "RIGHT",
		BOTTOMLEFT = "BOTTOMLEFT",
		BOTTOM = "BOTTOM",
		BOTTOMRIGHT = "BOTTOMRIGHT",
	},

	GROWTH_DIRECTIONS = {
		CENTERED = "Centered Horizontal",
		LEFT = "Left",
		RIGHT = "Right",
		FIXED = "Fixed",
	},

	SECONDARY_GROWTH_DIRECTIONS = {
		DOWN = "Down",
		UP = "Up",
	},

	FRAME_STRATA = {
		BACKGROUND = "Background",
		LOW = "Low",
		MEDIUM = "Medium",
		HIGH = "High",
		DIALOG = "Dialog",
		FULLSCREEN = "Fullscreen",
		FULLSCREEN_DIALOG = "Fullscreen Dialog",
		-- TOOLTIP = "Tooltip",
	},

	FRAME_STRATA_SORTED = {
		"BACKGROUND",
		"LOW",
		"MEDIUM",
		"HIGH",
		"DIALOG",
		"FULLSCREEN",
		"FULLSCREEN_DIALOG",
		-- "TOOLTIP",
	},

	TEXT_OUTLINE = {
		[""] = "None",
		OUTLINE = "Outline",
		THICKOUTLINE = "Thick Outline",
		MONOCHROME = "Monochrome",
		["OUTLINE,MONOCHROME"] = "Monochrome Outline",
		SLUG = "Slug",
		["OUTLINE SLUG"] = "Outline Slug",
	},

	TEXT_OUTLINE_SORTED = {
		"",
		"OUTLINE",
		"SLUG",
		"MONOCHROME",
		"OUTLINE,MONOCHROME",
		"OUTLINE SLUG",
		"THICKOUTLINE",
	},

	BLEND_MODE = {
		["DISABLE"] = "DISABLE",
		["BLEND"] = "BLEND",
		["ADD"] = "ADD",
		["MOD"] = "MOD",
	},

	BLEND_MODE_SORTED = {
		"DISABLE",
		"BLEND",
		"ADD",
		"MOD",
	},

	STATES = {
		["always"] = "Always",
		["active"] = "Active",
		["inactive"] = "Inactive",
		["overridden"] = "Overridden",
		["ready"] = "Ready",
		["cooldown"] = "On Cooldown",
		["noitem"] = "No Item",
		["recharging"] = "Recharging",
		["usableSpell"] = "Usable (Spell)",
	},

	STATES_SORTED = {
		["buffBar"] = {
			"always",
			"active",
			"inactive",
		},
		["spell"] = {
			"always",
			"ready",
			"cooldown",
			"active",
			"inactive",
			"overridden",
			"recharging",
			"usableSpell",
		},
		["buffIcon"] = {
			"always",
			"ready",
			"cooldown",
			"active",
			"inactive",
			"recharging",
		},
		["timer"] = {
			"always",
			"active",
			"inactive",
		},
		["item"] = {
			"always",
			"ready",
			"cooldown",
			"noitem",
		},
		["slot"] = {
			"always",
			"ready",
			"cooldown",
		},
		["custom"] = {
			"always",
			"ready",
			"cooldown",
			"usableSpell",
		},
		-- "nocharges",
		-- "maxcharges",
		-- "recharging",
		-- "ongcd",
		-- "mounted",
	},

	VISIBILITY = {
		["show"] = "Show",
		["hide"] = "Hide",
	},

	VISIBILITY_SORTED = {
		"show",
		"hide",
	},

	GLOBAL_GLOW_SUBREGION = "global",

	SUBREGIONS = {
		["glow"] = "Glow",
		["border"] = "Border",
		--["text"] = "Text"
	},

	SUBREGIONS_SORTED = {
		"glow",
		"border",
	},

	SUBREGION_TARGETS = {
		["self"] = "Self",
		["custom"] = "Custom"
	},

	SUBREGION_TARGETS_SORTED = {
		"self",
		"custom"
	},

	GLOW_TYPES = {
		["Pixel"] = "Pixel",
		["Autocast"] = "Autocast",
		["Proc"] = "Proc",
		["Button"] = "Button",
	},

	GLOW_TYPES_SORTED = {
		"Pixel",
		"Proc",
		"Autocast",
		"Button",
		"Button",
	},

	RESOURCE_BAR_GROWTH_DIRECTION = {
		UP = "Up",
		DOWN = "Down",
	},

	SATED_DEBUFFS = {
		[57723] = true,
		[57724] = true,
		[80354] = true,
		[95809] = true,
		[160455] = true,
		[264689] = true,
		[390435] = true,
	},

	SCM_ANCHORS = {
		["SkironCooldownManager"] = {
			["Cursor"] = "SCM_Cursor",
			["Cast Bar"] = "SCM_CastBar",
			["Primary Resource Bar"] = "SCM_PrimaryResourceBar",
			["Secondary Resource Bar"] = "SCM_SecondaryResourceBar",
			["Anchor"] = "ANCHOR:#",
			["Global Anchor"] = "ANCHOR:G:#",
			["Buff Bar Anchor"] = "ANCHOR:BB:#"
		},
	},
}

