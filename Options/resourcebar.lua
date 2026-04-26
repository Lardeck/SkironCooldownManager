local _, SCM = ...
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local Constants = SCM.Constants
local RESOURCE_BAR_POWER_TYPES = SCM.Constants.ResourceBarPowerTypes

SCM.MainTabs.ResourceBar = { value = "ResourceBar", text = "Resource Bar", order = 5, subgroups = {} }

local RESOURCE_BAR_GROW_DIRECTIONS = {
	UP = "Up",
	DOWN = "Down",
}

local RESOURCE_BAR_TABS = {
	{ value = "Layout", text = "Layout" },
	{ value = "Primary", text = "Primary" },
	{ value = "Secondary", text = "Secondary" },
}

local function RefreshResourceBars()
	SCM:RefreshResourceBarConfig()
end

local function AddLayoutSettings(parent, settings)
	local generalSettings = AceGUI:Create("InlineGroup")
	generalSettings:SetLayout("flow")
	generalSettings:SetTitle("General")
	generalSettings:SetFullWidth(true)
	parent:AddChild(generalSettings)

	local enableResourceBars = AceGUI:Create("CheckBox")
	enableResourceBars:SetRelativeWidth(0.33)
	enableResourceBars:SetLabel("Enable Resource Bars")
	enableResourceBars:SetValue(settings.enabled)
	enableResourceBars:SetCallback("OnValueChanged", function(_, _, value)
		settings.enabled = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(enableResourceBars)

	local hideWhileMounted = AceGUI:Create("CheckBox")
	hideWhileMounted:SetRelativeWidth(0.33)
	hideWhileMounted:SetLabel("Hide While Mounted")
	hideWhileMounted:SetValue(settings.hideWhileMounted)
	hideWhileMounted:SetCallback("OnValueChanged", function(_, _, value)
		settings.hideWhileMounted = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(hideWhileMounted)

	local useFrequentPowerUpdates = AceGUI:Create("CheckBox")
	useFrequentPowerUpdates:SetRelativeWidth(0.33)
	useFrequentPowerUpdates:SetLabel("Frequent Updates")
	useFrequentPowerUpdates:SetValue(settings.useFrequentPowerUpdates and true or false)
	useFrequentPowerUpdates:SetCallback("OnValueChanged", function(_, _, value)
		settings.useFrequentPowerUpdates = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(useFrequentPowerUpdates)

	local layoutSettings = AceGUI:Create("InlineGroup")
	layoutSettings:SetLayout("flow")
	layoutSettings:SetTitle("Layout")
	layoutSettings:SetFullWidth(true)
	parent:AddChild(layoutSettings)

	local barSpacing = AceGUI:Create("Slider")
	barSpacing:SetRelativeWidth(0.5)
	barSpacing:SetLabel("Spacing")
	barSpacing:SetSliderValues(-10, 20, 0.1)
	barSpacing:SetValue(settings.spacing)
	barSpacing:SetCallback("OnValueChanged", function(_, _, value)
		settings.spacing = value
		RefreshResourceBars()
	end)
	layoutSettings:AddChild(barSpacing)

	local growDirection = AceGUI:Create("Dropdown")
	growDirection:SetRelativeWidth(0.5)
	growDirection:SetLabel("Grow Direction")
	growDirection:SetList(RESOURCE_BAR_GROW_DIRECTIONS)
	growDirection:SetValue(settings.growDirection)
	growDirection:SetCallback("OnValueChanged", function(_, _, value)
		settings.growDirection = value
		RefreshResourceBars()
	end)
	layoutSettings:AddChild(growDirection)
end

local function AddPositionSettings(parent, settings)
	local positionSettings = AceGUI:Create("InlineGroup")
	positionSettings:SetLayout("flow")
	positionSettings:SetTitle("Position")
	positionSettings:SetFullWidth(true)
	parent:AddChild(positionSettings)

	local anchorPoint = AceGUI:Create("Dropdown")
	anchorPoint:SetRelativeWidth(0.33)
	anchorPoint:SetLabel("Anchor Point")
	anchorPoint:SetList(SCM.Constants.AnchorPoints)
	anchorPoint:SetValue(settings.point)
	anchorPoint:SetCallback("OnValueChanged", function(_, _, value)
		settings.point = value
		RefreshResourceBars()
	end)
	positionSettings:AddChild(anchorPoint)

	local anchorFrame = AceGUI:Create("EditBox")
	anchorFrame:SetRelativeWidth(0.33)
	anchorFrame:SetLabel("Anchor Frame")
	anchorFrame:SetText(settings.anchorFrame or "ANCHOR:1")
	anchorFrame:SetCallback("OnEnterPressed", function(self, _, text)
		settings.anchorFrame = (text and text ~= "" and text) or "ANCHOR:1"
		self:SetText(settings.anchorFrame)
		RefreshResourceBars()
	end)
	positionSettings:AddChild(anchorFrame)

	local relativePoint = AceGUI:Create("Dropdown")
	relativePoint:SetRelativeWidth(0.33)
	relativePoint:SetLabel("Relative Point")
	relativePoint:SetList(SCM.Constants.AnchorPoints)
	relativePoint:SetValue(settings.relativePoint)
	relativePoint:SetCallback("OnValueChanged", function(_, _, value)
		settings.relativePoint = value
		RefreshResourceBars()
	end)
	positionSettings:AddChild(relativePoint)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(-300, 300, 0.1)
	xOffset:SetValue(settings.xOffset)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		settings.xOffset = value
		RefreshResourceBars()
	end)
	positionSettings:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.5)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-300, 300, 0.1)
	yOffset:SetValue(settings.yOffset)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		settings.yOffset = value
		RefreshResourceBars()
	end)
	positionSettings:AddChild(yOffset)
end

local function AddPowerTypeColorSettings(parent, settings)
	local powerTypeColors = AceGUI:Create("InlineGroup")
	powerTypeColors:SetLayout("flow")
	powerTypeColors:SetTitle("Power Colors")
	powerTypeColors:SetFullWidth(true)
	parent:AddChild(powerTypeColors)

	for _, powerType in ipairs(RESOURCE_BAR_POWER_TYPES) do
		local powerTypeOverride = settings.powerTypeColorOverrides[powerType.token]
		local overrideColor = AceGUI:Create("ColorPicker")
		overrideColor:SetRelativeWidth(0.33)
		overrideColor:SetLabel(powerType.label)
		overrideColor:SetHasAlpha(false)
		overrideColor:SetColor(powerTypeOverride.color.r, powerTypeOverride.color.g, powerTypeOverride.color.b)
		overrideColor:SetCallback("OnValueChanged", function(_, _, r, g, b)
			powerTypeOverride.color = { r = r, g = g, b = b }
			RefreshResourceBars()
		end)
		powerTypeColors:AddChild(overrideColor)
	end
end

local function AddSpecialColorSettings(parent, settings)
	local specialColors = AceGUI:Create("InlineGroup")
	specialColors:SetLayout("flow")
	specialColors:SetTitle("Special Colors")
	specialColors:SetFullWidth(true)
	parent:AddChild(specialColors)

	local maelstromOverflowColor = AceGUI:Create("ColorPicker")
	maelstromOverflowColor:SetRelativeWidth(0.33)
	maelstromOverflowColor:SetLabel("Maelstrom Overflow")
	maelstromOverflowColor:SetHasAlpha(false)
	maelstromOverflowColor:SetColor(settings.maelstromOverflowColor.r, settings.maelstromOverflowColor.g, settings.maelstromOverflowColor.b)
	maelstromOverflowColor:SetCallback("OnValueChanged", function(_, _, r, g, b)
		settings.maelstromOverflowColor = { r = r, g = g, b = b }
		RefreshResourceBars()
	end)
	specialColors:AddChild(maelstromOverflowColor)
end

local function AddBarSettings(parent, title, settings, includeManaRoleSettings)
	local generalSettings = AceGUI:Create("InlineGroup")
	generalSettings:SetLayout("flow")
	generalSettings:SetTitle("General")
	generalSettings:SetFullWidth(true)
	parent:AddChild(generalSettings)

	local enableBar = AceGUI:Create("CheckBox")
	enableBar:SetRelativeWidth(0.5)
	enableBar:SetLabel("Enable Bar")
	enableBar:SetValue(settings.enabled)
	enableBar:SetCallback("OnValueChanged", function(_, _, value)
		settings.enabled = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(enableBar)

	local widthSlider
	local matchAnchorWidth = AceGUI:Create("CheckBox")
	matchAnchorWidth:SetRelativeWidth(0.5)
	matchAnchorWidth:SetLabel("Match Anchor Width")
	matchAnchorWidth:SetValue(settings.matchAnchorWidth)
	matchAnchorWidth:SetCallback("OnValueChanged", function(_, _, value)
		settings.matchAnchorWidth = value

		if widthSlider then
			widthSlider:SetDisabled(value)
		end

		RefreshResourceBars()
	end)
	generalSettings:AddChild(matchAnchorWidth)

	local barHeight = AceGUI:Create("Slider")
	barHeight:SetRelativeWidth(0.5)
	barHeight:SetLabel("Bar Height")
	barHeight:SetSliderValues(3, 40, 0.1)
	barHeight:SetValue(settings.height)
	barHeight:SetCallback("OnValueChanged", function(_, _, value)
		settings.height = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(barHeight)

	widthSlider = AceGUI:Create("Slider")
	widthSlider:SetRelativeWidth(0.5)
	widthSlider:SetLabel("Fixed Width")
	widthSlider:SetSliderValues(120, 700, 1)
	widthSlider:SetValue(settings.width)
	widthSlider:SetDisabled(settings.matchAnchorWidth)
	widthSlider:SetCallback("OnValueChanged", function(_, _, value)
		settings.width = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(widthSlider)

	local hideManaRoles = AceGUI:Create("Dropdown")
	hideManaRoles:SetRelativeWidth(0.5)
	hideManaRoles:SetLabel("Hide Mana For Roles")
	hideManaRoles:SetList(SCM.Constants.Roles)
	hideManaRoles:SetMultiselect(true)
	hideManaRoles:SetCallback("OnValueChanged", function(_, _, key, value)
		settings.hideManaRoles = settings.hideManaRoles or {}
		settings.hideManaRoles[key] = value
		RefreshResourceBars()
	end)
	settings.hideManaRoles = settings.hideManaRoles or {}
	for key, value in pairs(settings.hideManaRoles) do
		hideManaRoles:SetItemValue(key, value)
	end
	generalSettings:AddChild(hideManaRoles)

	local barSettings = AceGUI:Create("InlineGroup")
	barSettings:SetLayout("flow")
	barSettings:SetTitle("Bar")
	barSettings:SetFullWidth(true)
	parent:AddChild(barSettings)

	local texture = AceGUI:Create("LSM30_Statusbar")
	texture:SetLabel("Bar Texture")
	texture:SetRelativeWidth(0.5)
	texture:SetList(LSM:HashTable("statusbar"))
	texture:SetValue(settings.texture)
	texture:SetCallback("OnValueChanged", function(self, _, value)
		settings.texture = value
		self:SetValue(value)
		RefreshResourceBars()
	end)
	barSettings:AddChild(texture)

	local backgroundTexture = AceGUI:Create("LSM30_Statusbar")
	backgroundTexture:SetLabel("Background Texture")
	backgroundTexture:SetRelativeWidth(0.5)
	backgroundTexture:SetList(LSM:HashTable("statusbar"))
	backgroundTexture:SetValue(settings.backgroundTexture)
	backgroundTexture:SetCallback("OnValueChanged", function(self, _, value)
		settings.backgroundTexture = value
		self:SetValue(value)
		RefreshResourceBars()
	end)
	barSettings:AddChild(backgroundTexture)

	local useBackgroundTexture = AceGUI:Create("CheckBox")
	useBackgroundTexture:SetRelativeWidth(0.5)
	useBackgroundTexture:SetLabel("Show Background")
	useBackgroundTexture:SetValue(settings.useBackgroundTexture)
	useBackgroundTexture:SetCallback("OnValueChanged", function(_, _, value)
		settings.useBackgroundTexture = value
		RefreshResourceBars()
	end)
	barSettings:AddChild(useBackgroundTexture)

	local backgroundColor = AceGUI:Create("ColorPicker")
	backgroundColor:SetRelativeWidth(0.5)
	backgroundColor:SetLabel("Background Color")
	backgroundColor:SetHasAlpha(true)
	backgroundColor:SetColor(settings.backgroundColor.r, settings.backgroundColor.g, settings.backgroundColor.b, settings.backgroundColor.a)
	backgroundColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		settings.backgroundColor = { r = r, g = g, b = b, a = a }
		RefreshResourceBars()
	end)
	barSettings:AddChild(backgroundColor)

	local tickSettings = AceGUI:Create("InlineGroup")
	tickSettings:SetLayout("flow")
	tickSettings:SetTitle("Border")
	tickSettings:SetFullWidth(true)
	parent:AddChild(tickSettings)

	local showTicks = AceGUI:Create("CheckBox")
	showTicks:SetRelativeWidth(0.33)
	showTicks:SetLabel("Show Ticks")
	showTicks:SetValue(settings.showTicks)
	showTicks:SetCallback("OnValueChanged", function(_, _, value)
		settings.showTicks = value
		RefreshResourceBars()
	end)
	tickSettings:AddChild(showTicks)

	local tickColor = AceGUI:Create("ColorPicker")
	tickColor:SetRelativeWidth(0.33)
	tickColor:SetLabel("Tick Color")
	tickColor:SetHasAlpha(true)
	tickColor:SetColor(settings.tickColor.r, settings.tickColor.g, settings.tickColor.b, settings.tickColor.a)
	tickColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		settings.tickColor = { r = r, g = g, b = b, a = a }
		RefreshResourceBars()
	end)
	tickSettings:AddChild(tickColor)

	local tickWidth = AceGUI:Create("Slider")
	tickWidth:SetRelativeWidth(0.33)
	tickWidth:SetLabel("Tick Width")
	tickWidth:SetSliderValues(1, 10, 0.1)
	tickWidth:SetValue(settings.tickWidth)
	tickWidth:SetCallback("OnValueChanged", function(_, _, value)
		settings.tickWidth = value
		RefreshResourceBars()
	end)
	tickSettings:AddChild(tickWidth)

	local backdropSettings = AceGUI:Create("InlineGroup")
	backdropSettings:SetLayout("flow")
	backdropSettings:SetTitle("Border")
	backdropSettings:SetFullWidth(true)
	parent:AddChild(backdropSettings)

	local showBorder = AceGUI:Create("CheckBox")
	showBorder:SetRelativeWidth(0.33)
	showBorder:SetLabel("Show Border")
	showBorder:SetValue(settings.showBorder)
	showBorder:SetCallback("OnValueChanged", function(_, _, value)
		settings.showBorder = value
		RefreshResourceBars()
	end)
	backdropSettings:AddChild(showBorder)

	local backdropColor = AceGUI:Create("ColorPicker")
	backdropColor:SetRelativeWidth(0.33)
	backdropColor:SetLabel("Border Color")
	backdropColor:SetHasAlpha(true)
	backdropColor:SetColor(settings.backdropColor.r, settings.backdropColor.g, settings.backdropColor.b, settings.backdropColor.a)
	backdropColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		settings.backdropColor = { r = r, g = g, b = b, a = a }
		RefreshResourceBars()
	end)
	backdropSettings:AddChild(backdropColor)

	local backdropSize = AceGUI:Create("Slider")
	backdropSize:SetRelativeWidth(0.33)
	backdropSize:SetLabel("Border Size")
	backdropSize:SetSliderValues(0, 10, 0.01)
	backdropSize:SetValue(settings.backdropSize)
	backdropSize:SetCallback("OnValueChanged", function(_, _, value)
		settings.backdropSize = value
		RefreshResourceBars()
	end)
	backdropSettings:AddChild(backdropSize)

	local textSettings = AceGUI:Create("InlineGroup")
	textSettings:SetLayout("flow")
	textSettings:SetTitle("Text")
	textSettings:SetFullWidth(true)
	parent:AddChild(textSettings)

	local showValues = AceGUI:Create("CheckBox")
	showValues:SetRelativeWidth(0.33)
	showValues:SetLabel("Show Text")
	showValues:SetValue(settings.showValues)
	showValues:SetCallback("OnValueChanged", function(_, _, value)
		settings.showValues = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(showValues)

	local font = AceGUI:Create("LSM30_Font")
	font:SetLabel("Text Font")
	font:SetRelativeWidth(0.33)
	font:SetList(LSM:HashTable("font"))
	font:SetValue(settings.font)
	font:SetCallback("OnValueChanged", function(self, _, value)
		settings.font = value
		self:SetValue(value)
		RefreshResourceBars()
	end)
	textSettings:AddChild(font)

	local textOutline = AceGUI:Create("Dropdown")
	textOutline:SetRelativeWidth(0.33)
	textOutline:SetLabel("Outline")
	textOutline:SetList(Constants.TextOutline)
	textOutline:SetValue(settings.textOutline)
	textOutline:SetCallback("OnValueChanged", function(_, _, value)
		settings.textOutline = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(textOutline)

	local fontSize = AceGUI:Create("Slider")
	fontSize:SetRelativeWidth(0.33)
	fontSize:SetLabel("Font Size")
	fontSize:SetSliderValues(6, 28, 1)
	fontSize:SetValue(settings.fontSize)
	fontSize:SetCallback("OnValueChanged", function(_, _, value)
		settings.fontSize = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(fontSize)

	local textXOffset = AceGUI:Create("Slider")
	textXOffset:SetRelativeWidth(0.33)
	textXOffset:SetLabel("Text X Offset")
	textXOffset:SetSliderValues(-100, 100, 0.1)
	textXOffset:SetValue(settings.textXOffset)
	textXOffset:SetCallback("OnValueChanged", function(_, _, value)
		settings.textXOffset = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(textXOffset)

	local valueYOffset = AceGUI:Create("Slider")
	valueYOffset:SetRelativeWidth(0.33)
	valueYOffset:SetLabel("Text Y Offset")
	valueYOffset:SetSliderValues(-100, 100, 0.1)
	valueYOffset:SetValue(settings.textYOffset)
	valueYOffset:SetCallback("OnValueChanged", function(_, _, value)
		settings.textYOffset = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(valueYOffset)
end

local function SelectResourceBarTab(tabGroup, group, settings)
	tabGroup:ReleaseChildren()

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	tabGroup:AddChild(scrollFrame)

	if group == "Layout" then
		AddLayoutSettings(scrollFrame, settings)
		AddPositionSettings(scrollFrame, settings)
		AddPowerTypeColorSettings(scrollFrame, settings)
		AddSpecialColorSettings(scrollFrame, settings)
	elseif group == "Primary" then
		AddBarSettings(scrollFrame, "Primary", settings.primaryBar, true)
	elseif group == "Secondary" then
		AddBarSettings(scrollFrame, "Secondary", settings.secondaryBar)
	end
end

local function ResourceBar(self)
	local settings = SCM.db.profile.options.resourceBar

	local resourceBarFrame = AceGUI:Create("InlineGroup")
	resourceBarFrame:SetLayout("flow")
	resourceBarFrame:SetFullWidth(true)
	resourceBarFrame:SetFullHeight(true)
	self:AddChild(resourceBarFrame)

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText("|TInterface\\common\\help-i:40:40:0:0|tRight now the resource bar is still in an experimental state. Please report any bugs on github/curseforge or on discord.")
	label:SetFontObject("Game12Font")
	resourceBarFrame:AddChild(label)

	local resourceBarTabs = AceGUI:Create("TabGroup")
	resourceBarTabs:SetTabs(RESOURCE_BAR_TABS)
	resourceBarTabs:SetFullWidth(true)
	resourceBarTabs:SetFullHeight(true)
	resourceBarTabs:SetLayout("fill")
	resourceBarTabs:SetCallback("OnGroupSelected", function(widget, _, group)
		SelectResourceBarTab(widget, group, settings)
	end)
	resourceBarTabs:SelectTab("Layout")
	resourceBarFrame:AddChild(resourceBarTabs)
end

SCM.MainTabs.ResourceBar.callback = ResourceBar
