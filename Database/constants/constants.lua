local SCM = select(2, ...)
SCM.Constants = {}

local Constants = SCM.Constants

BACKDROP_SCM_PIXEL = {
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 2,
}

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
	"MOD",
}

Constants.States = {
	["active"] = "Active",
	["inactive"] = "Inactive",
	["ready"] = "Ready",
	["cooldown"] = "On Cooldown",
	["nocharges"] = "No Charges",
	["maxcharges"] = "Max Charges",
	["recharging"] = "Recharging",
	["ongcd"] = "On GCD",
	["mounted"] = "Mounted"
}

Constants.StatesSorted = {
	"ready",
	"cooldown",
	"active",
	"inactive",
	"nocharges",
	"maxcharges",
	"recharging",
	"ongcd",
	"mounted",
}

Constants.Visibility = {
	["show"] = "Show",
	["hide"] = "Hide",
}

Constants.VisibilitySorted = {
	"show",
	"hide",
}

Constants.Subregions = {
	["glow"] = "Glow",
	["border"] = "Border",
	--["text"] = "Text"
}

Constants.SubregionsSorted = {
	"glow",
	"border",
}

Constants.GlowTypes = {
	["Pixel"] = "Pixel",
	["Autocast"] = "Autocast",
	["Proc"] = "Proc",
	["Button"] = "Button",
}

Constants.GlowTypesSorted = {
	"Pixel",
	"Proc",
	"Autocast",
	"Button"
}

Constants.ResourceBarGrowthDirection = {
	UP = "Up",
	DOWN = "Down",
}

Constants.SatedDebuffs = {
	[57723] = true,
	[57724] = true,
	[80354] = true,
	[95809] = true,
	[160455] = true,
	[264689] = true,
	[390435] = true,
}
