local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local Constants = SCM.Constants
local Options = SCM.Options

SCM.MainTabs.SwingTimer = { value = "SwingTimer", text = "Swing Timer", order = 7, subgroups = {} }

local SWING_TIMER_TABS = {
	{ value = "MainHand", text = "Main Hand" },
	{ value = "OffHand", text = "Off Hand" },
	{ value = "Ranged", text = "Ranged" },
}

local SWING_TIMER_SETTINGS_TABS = {
	{ value = "Border", text = "Border" },
	{ value = "Text", text = "Text" },
	{ value = "NumberFormat", text = "Number Format" },
	{ value = "Spark", text = "Spark" },
	{ value = "Visibility", text = "Visibility" },
}

local function RefreshSwingTimer(refreshTicks)
	SCM:RefreshSwingTimerConfig(refreshTicks, true)
end

local function AddVisibilitySettings(parent, config)
	local visibilitySettings = AceGUI:Create("InlineGroup")
	visibilitySettings:SetLayout("flow")
	visibilitySettings:SetTitle("Visibility")
	visibilitySettings:SetFullWidth(true)
	parent:AddChild(visibilitySettings)

	local hideWhileMounted = AceGUI:Create("CheckBox")
	hideWhileMounted:SetRelativeWidth(0.33)
	hideWhileMounted:SetLabel("Hide While Mounted")
	hideWhileMounted:SetValue(config.hideWhileMounted)
	hideWhileMounted:SetDisabled(config.useCustomVisibilityCondition)
	hideWhileMounted:SetCallback("OnValueChanged", function(_, _, value)
		config.hideWhileMounted = value
		RefreshSwingTimer()
	end)
	visibilitySettings:AddChild(hideWhileMounted)

	local hideWhileDead = AceGUI:Create("CheckBox")
	hideWhileDead:SetRelativeWidth(0.33)
	hideWhileDead:SetLabel("Hide While Dead")
	hideWhileDead:SetValue(config.hideWhileDead)
	hideWhileDead:SetDisabled(config.useCustomVisibilityCondition)
	hideWhileDead:SetCallback("OnValueChanged", function(_, _, value)
		config.hideWhileDead = value
		RefreshSwingTimer()
	end)
	visibilitySettings:AddChild(hideWhileDead)

	local hideWhileInVehicle = AceGUI:Create("CheckBox")
	hideWhileInVehicle:SetRelativeWidth(0.33)
	hideWhileInVehicle:SetLabel("Hide While In Vehicle")
	hideWhileInVehicle:SetValue(config.hideWhileInVehicle)
	hideWhileInVehicle:SetDisabled(config.useCustomVisibilityCondition)
	hideWhileInVehicle:SetCallback("OnValueChanged", function(_, _, value)
		config.hideWhileInVehicle = value
		RefreshSwingTimer()
	end)
	visibilitySettings:AddChild(hideWhileInVehicle)

	local hideWhileResting = AceGUI:Create("CheckBox")
	hideWhileResting:SetRelativeWidth(0.33)
	hideWhileResting:SetLabel("Hide While Resting")
	hideWhileResting:SetValue(config.hideWhileResting)
	hideWhileResting:SetDisabled(config.useCustomVisibilityCondition)
	hideWhileResting:SetCallback("OnValueChanged", function(_, _, value)
		config.hideWhileResting = value
		RefreshSwingTimer()
	end)
	visibilitySettings:AddChild(hideWhileResting)

	local hideOutOfCombat = AceGUI:Create("CheckBox")
	hideOutOfCombat:SetRelativeWidth(0.33)
	hideOutOfCombat:SetLabel("Hide Outside Of Combat")
	hideOutOfCombat:SetValue(config.hideOutOfCombat)
	hideOutOfCombat:SetDisabled(config.useCustomVisibilityCondition)
	hideOutOfCombat:SetCallback("OnValueChanged", function(_, _, value)
		config.hideOutOfCombat = value
		RefreshSwingTimer()
	end)
	visibilitySettings:AddChild(hideOutOfCombat)

	local hideWhileInactive = AceGUI:Create("CheckBox")
	hideWhileInactive:SetRelativeWidth(0.33)
	hideWhileInactive:SetLabel("Hide While Inactive")
	hideWhileInactive:SetValue(config.hideWhileInactive)
	hideWhileInactive:SetCallback("OnValueChanged", function(_, _, value)
		config.hideWhileInactive = value
		RefreshSwingTimer()
	end)
	visibilitySettings:AddChild(hideWhileInactive)

	local customVisibilitySettings = AceGUI:Create("InlineGroup")
	customVisibilitySettings:SetLayout("flow")
	customVisibilitySettings:SetFullWidth(true)
	customVisibilitySettings:SetTitle("Custom")
	visibilitySettings:AddChild(customVisibilitySettings)

	local useCustomVisibilityCondition = AceGUI:Create("CheckBox")
	useCustomVisibilityCondition:SetRelativeWidth(0.5)
	useCustomVisibilityCondition:SetLabel("Use Custom Condition")
	useCustomVisibilityCondition:SetValue(config.useCustomVisibilityCondition)

	customVisibilitySettings:AddChild(useCustomVisibilityCondition)

	local customVisibilityCondition = AceGUI:Create("EditBox")
	customVisibilityCondition:SetRelativeWidth(0.5)
	customVisibilityCondition:SetLabel("Condition")
	customVisibilityCondition:SetText(config.customVisibilityCondition)
	customVisibilityCondition:SetDisabled(not config.useCustomVisibilityCondition)
	customVisibilityCondition:SetCallback("OnEnterPressed", function(_, _, value)
		config.customVisibilityCondition = value
		RefreshSwingTimer()
	end)
	customVisibilitySettings:AddChild(customVisibilityCondition)

	useCustomVisibilityCondition:SetCallback("OnValueChanged", function(_, _, value)
		config.useCustomVisibilityCondition = value

		customVisibilityCondition:SetDisabled(not value)
		hideWhileMounted:SetDisabled(value)
		hideWhileDead:SetDisabled(value)
		hideWhileInVehicle:SetDisabled(value)
		hideWhileResting:SetDisabled(value)
		hideOutOfCombat:SetDisabled(value)
		RefreshSwingTimer()
	end)
end

local function AddPositionSettings(parent, swingType, config)
	local positionSettings = AceGUI:Create("InlineGroup")
	positionSettings:SetLayout("flow")
	positionSettings:SetTitle("Position")
	positionSettings:SetFullWidth(true)
	parent:AddChild(positionSettings)

	local anchorPoint = AceGUI:Create("Dropdown")
	anchorPoint:SetRelativeWidth(0.33)
	anchorPoint:SetLabel("Anchor Point")
	anchorPoint:SetList(SCM.Constants.AnchorPoints)
	anchorPoint:SetValue(config.point)
	anchorPoint:SetCallback("OnValueChanged", function(_, _, value)
		config.point = value
		RefreshSwingTimer()
	end)
	positionSettings:AddChild(anchorPoint)

	local anchorFrame = AceGUI:Create("EditBox")
	anchorFrame:SetRelativeWidth(0.33)
	anchorFrame:SetLabel("Anchor Frame")
	anchorFrame:SetText(config.anchorFrame or "ANCHOR:1")
	local function SetAnchor(text)
		text = text ~= "" and text or "ANCHOR:1"
		local timer = SCM.SwingTimers and SCM.SwingTimers[swingType]
		if Options.IsCircularAnchor(timer, text) then
			anchorFrame:SetText(config.anchorFrame or "ANCHOR:1")
			SCM:Print("|cffff4040Anchor unchanged: that choice would create a circular dependency.|r")
			return
		end
		config.anchorFrame = text
		anchorFrame:SetText(text)
		RefreshSwingTimer()
	end
	anchorFrame:SetCallback("OnEnterPressed", function(_, _, text)
		SetAnchor(text)
	end)
	positionSettings:AddChild(anchorFrame)
	Options.AddAnchorParentAutocomplete(positionSettings, anchorFrame, SetAnchor)

	local relativePoint = AceGUI:Create("Dropdown")
	relativePoint:SetRelativeWidth(0.33)
	relativePoint:SetLabel("Relative Point")
	relativePoint:SetList(SCM.Constants.AnchorPoints)
	relativePoint:SetValue(config.relativePoint)
	relativePoint:SetCallback("OnValueChanged", function(_, _, value)
		config.relativePoint = value
		RefreshSwingTimer()
	end)
	positionSettings:AddChild(relativePoint)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(-300, 300, 0.1)
	xOffset:SetValue(config.xOffset)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		config.xOffset = value
		RefreshSwingTimer()
	end)
	positionSettings:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.5)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-300, 300, 0.1)
	yOffset:SetValue(config.yOffset)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		config.yOffset = value
		RefreshSwingTimer()
	end)
	positionSettings:AddChild(yOffset)
end

local function AddGeneralSettings(parent, config)
	local generalSettings = AceGUI:Create("InlineGroup")
	generalSettings:SetLayout("flow")
	generalSettings:SetTitle("General")
	generalSettings:SetFullWidth(true)
	parent:AddChild(generalSettings)

	local enableBar = AceGUI:Create("CheckBox")
	enableBar:SetRelativeWidth(0.5)
	enableBar:SetLabel("Enable Bar")
	enableBar:SetValue(config.enabled)
	enableBar:SetCallback("OnValueChanged", function(_, _, value)
		config.enabled = value
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(enableBar)

	local useSmoothPowerUpdates = AceGUI:Create("CheckBox")
	useSmoothPowerUpdates:SetRelativeWidth(0.5)
	useSmoothPowerUpdates:SetLabel("Smooth Updates")
	useSmoothPowerUpdates:SetValue(config.useSmoothPowerUpdates and true or false)
	useSmoothPowerUpdates:SetCallback("OnValueChanged", function(_, _, value)
		config.useSmoothPowerUpdates = value
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(useSmoothPowerUpdates)

	local frameStrata = AceGUI:Create("Dropdown")
	frameStrata:SetRelativeWidth(0.5)
	frameStrata:SetList(SCM.Constants.FrameStrata, SCM.Constants.FrameStrataSorted)
	frameStrata:SetLabel("Frame Strata")
	frameStrata:SetValue(config.frameStrata or "BACKGROUND")
	frameStrata:SetCallback("OnValueChanged", function(_, _, value)
		config.frameStrata = value ~= "" and value or nil
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(frameStrata)

	local frameLevel = AceGUI:Create("Slider")
	frameLevel:SetRelativeWidth(0.5)
	frameLevel:SetLabel("Frame Level")
	frameLevel:SetSliderValues(0, 10, 1)
	frameLevel:SetValue(config.frameLevel or 1)
	frameLevel:SetCallback("OnValueChanged", function(_, _, value)
		config.frameLevel = value
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(frameLevel)

	local texture = AceGUI:Create("LSM30_Statusbar")
	texture:SetLabel("Bar Texture")
	texture:SetRelativeWidth(0.5)
	texture:SetList(LSM:HashTable("statusbar"))
	texture:SetValue(config.texture)
	texture:SetCallback("OnValueChanged", function(self, _, value)
		config.texture = value
		self:SetValue(value)
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(texture)

	local backgroundTexture = AceGUI:Create("LSM30_Statusbar")
	backgroundTexture:SetLabel("Background Texture")
	backgroundTexture:SetRelativeWidth(0.5)
	backgroundTexture:SetList(LSM:HashTable("statusbar"))
	backgroundTexture:SetValue(config.backgroundTexture)
	backgroundTexture:SetCallback("OnValueChanged", function(self, _, value)
		config.backgroundTexture = value
		self:SetValue(value)
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(backgroundTexture)

	local foregroundColor = AceGUI:Create("ColorPicker")
	foregroundColor:SetRelativeWidth(0.5)
	foregroundColor:SetLabel("Bar Color")
	foregroundColor:SetHasAlpha(true)
	foregroundColor:SetColor(config.foregroundColor.r, config.foregroundColor.g, config.foregroundColor.b, config.foregroundColor.a)
	foregroundColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		config.foregroundColor = { r = r, g = g, b = b, a = a }
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(foregroundColor)

	local backgroundColor = AceGUI:Create("ColorPicker")
	backgroundColor:SetRelativeWidth(0.5)
	backgroundColor:SetLabel("Background Color")
	backgroundColor:SetHasAlpha(true)
	backgroundColor:SetColor(config.backgroundColor.r, config.backgroundColor.g, config.backgroundColor.b, config.backgroundColor.a)
	backgroundColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		config.backgroundColor = { r = r, g = g, b = b, a = a }
		RefreshSwingTimer()
	end)
	generalSettings:AddChild(backgroundColor)
end

local function AddWidthSettings(parent, config)
	local widthSettings = AceGUI:Create("InlineGroup")
	widthSettings:SetLayout("flow")
	widthSettings:SetTitle("Width")
	widthSettings:SetFullWidth(true)
	parent:AddChild(widthSettings)

	local matchAnchorWidth = AceGUI:Create("CheckBox")
	matchAnchorWidth:SetRelativeWidth(0.33)
	matchAnchorWidth:SetLabel("Match Anchor Width")
	matchAnchorWidth:SetValue(config.matchAnchorWidth)
	widthSettings:AddChild(matchAnchorWidth)

	local minWidth = AceGUI:Create("Slider")
	minWidth:SetRelativeWidth(0.33)
	minWidth:SetLabel("Min Width")
	minWidth:SetSliderValues(50, 700, 0.1)
	minWidth:SetValue(config.minWidth)
	minWidth:SetCallback("OnValueChanged", function(_, _, value)
		config.minWidth = value
		RefreshSwingTimer()
	end)
	widthSettings:AddChild(minWidth)

	local widthSlider = AceGUI:Create("Slider")
	widthSlider:SetRelativeWidth(0.33)
	widthSlider:SetLabel("Fixed Width")
	widthSlider:SetSliderValues(120, 700, 1)
	widthSlider:SetValue(config.width)
	widthSlider:SetDisabled(config.matchAnchorWidth)
	widthSlider:SetCallback("OnValueChanged", function(_, _, value)
		config.width = value
		RefreshSwingTimer()
	end)
	widthSettings:AddChild(widthSlider)

	matchAnchorWidth:SetCallback("OnValueChanged", function(_, _, value)
		config.matchAnchorWidth = value
		widthSlider:SetDisabled(value)
		RefreshSwingTimer()
	end)
end

local function AddHeightSettings(parent, config)
	local heightSettings = AceGUI:Create("InlineGroup")
	heightSettings:SetLayout("flow")
	heightSettings:SetTitle("Height")
	heightSettings:SetFullWidth(true)
	parent:AddChild(heightSettings)

	local heightMode = AceGUI:Create("Dropdown")
	heightMode:SetRelativeWidth(0.33)
	heightMode:SetLabel("Height Mode")
	heightMode:SetList({ single = "Single", combined = "Combined" }, { "single", "combined" })
	heightMode:SetValue(config.heightMode)
	heightSettings:AddChild(heightMode)

	local singleHeight = AceGUI:Create("Slider")
	singleHeight:SetRelativeWidth(0.33)
	singleHeight:SetLabel("Single Height")
	singleHeight:SetSliderValues(3, 40, 0.1)
	singleHeight:SetValue(config.height)
	singleHeight:SetDisabled(config.heightMode == "combined")
	singleHeight:SetCallback("OnValueChanged", function(_, _, value)
		config.height = value
		RefreshSwingTimer()
	end)
	heightSettings:AddChild(singleHeight)

	local combinedHeight = AceGUI:Create("Slider")
	combinedHeight:SetRelativeWidth(0.33)
	combinedHeight:SetLabel("Combined Height (Shared)")
	combinedHeight:SetSliderValues(9, 120, 0.1)
	combinedHeight:SetValue(SCM.swingTimerConfig.combinedHeight)
	combinedHeight:SetDisabled(config.heightMode ~= "combined")
	combinedHeight:SetCallback("OnValueChanged", function(_, _, value)
		SCM.swingTimerConfig.combinedHeight = value
		RefreshSwingTimer()
	end)
	heightSettings:AddChild(combinedHeight)

	heightMode:SetCallback("OnValueChanged", function(_, _, value)
		config.heightMode = value
		singleHeight:SetDisabled(value == "combined")
		combinedHeight:SetDisabled(value ~= "combined")
		RefreshSwingTimer()
	end)
end

local function AddSparkSettings(parent, config)
	local sparkOptions = config.spark
	local sparkGroup = AceGUI:Create("InlineGroup")
	sparkGroup:SetTitle("Spark")
	sparkGroup:SetFullWidth(true)
	sparkGroup:SetLayout("flow")
	parent:AddChild(sparkGroup)

	local sparkEnable = AceGUI:Create("CheckBox")
	sparkEnable:SetRelativeWidth(0.33)
	sparkEnable:SetLabel("Show Spark")
	sparkEnable:SetValue(sparkOptions.enable)
	sparkEnable:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.enable = value
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(sparkEnable)

	local sparkColor = AceGUI:Create("ColorPicker")
	sparkColor:SetRelativeWidth(0.33)
	sparkColor:SetLabel("Spark Color")
	sparkColor:SetHasAlpha(true)
	sparkColor:SetColor(sparkOptions.color.r, sparkOptions.color.g, sparkOptions.color.b, sparkOptions.color.a)
	sparkColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		sparkOptions.color = { r = r, g = g, b = b, a = a }
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(sparkColor)

	local blendMode = AceGUI:Create("Dropdown")
	blendMode:SetRelativeWidth(0.33)
	blendMode:SetList(SCM.Constants.BlendMode, SCM.Constants.BlendModeSorted)
	blendMode:SetLabel("Blend Mode")
	blendMode:SetValue(sparkOptions.blendMode)
	blendMode:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.blendMode = value
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(blendMode)

	local sparkWidth = AceGUI:Create("Slider")
	sparkWidth:SetRelativeWidth(0.25)
	sparkWidth:SetLabel("Spark Width")
	sparkWidth:SetSliderValues(1, 50, 0.1)
	sparkWidth:SetValue(sparkOptions.width)
	sparkWidth:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.width = value
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(sparkWidth)

	local sparkHeight = AceGUI:Create("Slider")
	sparkHeight:SetRelativeWidth(0.25)
	sparkHeight:SetLabel("Spark Height")
	sparkHeight:SetSliderValues(1, 80, 0.1)
	sparkHeight:SetValue(sparkOptions.height)
	sparkHeight:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.height = value
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(sparkHeight)

	local sparkXOffset = AceGUI:Create("Slider")
	sparkXOffset:SetRelativeWidth(0.25)
	sparkXOffset:SetLabel("Spark X-Offset")
	sparkXOffset:SetSliderValues(-20, 20, 0.1)
	sparkXOffset:SetValue(sparkOptions.xOffset)
	sparkXOffset:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.xOffset = value
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(sparkXOffset)

	local sparkYOffset = AceGUI:Create("Slider")
	sparkYOffset:SetRelativeWidth(0.25)
	sparkYOffset:SetLabel("Spark Y-Offset")
	sparkYOffset:SetSliderValues(-20, 20, 0.1)
	sparkYOffset:SetValue(sparkOptions.yOffset)
	sparkYOffset:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.yOffset = value
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(sparkYOffset)

	local useCustomTexture = AceGUI:Create("CheckBox")
	useCustomTexture:SetRelativeWidth(0.33)
	useCustomTexture:SetLabel("Use Custom Texture")
	useCustomTexture:SetValue(sparkOptions.useCustomTexture)
	sparkGroup:AddChild(useCustomTexture)

	local customTexture = AceGUI:Create("EditBox")
	customTexture:SetRelativeWidth(0.66)
	customTexture:SetLabel("Custom Texture")
	customTexture:SetText(sparkOptions.texture or "")
	customTexture:SetDisabled(not sparkOptions.useCustomTexture)
	customTexture:SetCallback("OnEnter", function(widget)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
		GameTooltip:SetText("Custom Texture", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Supports LibSharedMedia names and interface paths.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	customTexture:SetCallback("OnLeave", function()
		GameTooltip:Hide()
	end)
	customTexture:SetCallback("OnEnterPressed", function(widget, _, text)
		sparkOptions.texture = text
		widget:SetText(sparkOptions.texture)
		RefreshSwingTimer()
	end)

	useCustomTexture:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.useCustomTexture = value
		customTexture:SetDisabled(not value)
		RefreshSwingTimer()
	end)
	sparkGroup:AddChild(customTexture)
end

local function AddTickSettings(parent, config)
	-- local tickSettings = AceGUI:Create("InlineGroup")
	-- tickSettings:SetLayout("flow")
	-- tickSettings:SetTitle("Border")
	-- tickSettings:SetFullWidth(true)
	-- parent:AddChild(tickSettings)
end

local function AddBorderSettings(parent, config)
	local backdropSettings = AceGUI:Create("InlineGroup")
	backdropSettings:SetLayout("flow")
	backdropSettings:SetTitle("Border")
	backdropSettings:SetFullWidth(true)
	parent:AddChild(backdropSettings)

	local showBorder = AceGUI:Create("CheckBox")
	showBorder:SetRelativeWidth(0.33)
	showBorder:SetLabel("Show Border")
	showBorder:SetValue(config.showBorder)
	showBorder:SetCallback("OnValueChanged", function(_, _, value)
		config.showBorder = value
		RefreshSwingTimer()
	end)
	backdropSettings:AddChild(showBorder)

	local backdropColor = AceGUI:Create("ColorPicker")
	backdropColor:SetRelativeWidth(0.33)
	backdropColor:SetLabel("Border Color")
	backdropColor:SetHasAlpha(true)
	backdropColor:SetColor(config.backdropColor.r, config.backdropColor.g, config.backdropColor.b, config.backdropColor.a)
	backdropColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		config.backdropColor = { r = r, g = g, b = b, a = a }
		RefreshSwingTimer()
	end)
	backdropSettings:AddChild(backdropColor)

	local backdropSize = AceGUI:Create("Slider")
	backdropSize:SetRelativeWidth(0.33)
	backdropSize:SetLabel("Border Size")
	backdropSize:SetSliderValues(0, 10, 0.01)
	backdropSize:SetValue(config.backdropSize)
	backdropSize:SetCallback("OnValueChanged", function(_, _, value)
		config.backdropSize = value
		RefreshSwingTimer()
	end)
	backdropSettings:AddChild(backdropSize)
end

local function AddTextSettings(parent, config)
	local textSettings = AceGUI:Create("InlineGroup")
	textSettings:SetLayout("flow")
	textSettings:SetTitle("Text")
	textSettings:SetFullWidth(true)
	parent:AddChild(textSettings)

	local showText = AceGUI:Create("CheckBox")
	showText:SetFullWidth(true)
	showText:SetLabel("Show Text")
	showText:SetValue(config.showValues)
	showText:SetCallback("OnValueChanged", function(_, _, value)
		config.showValues = value
		RefreshSwingTimer()
	end)
	textSettings:AddChild(showText)

	local font = AceGUI:Create("LSM30_Font")
	font:SetLabel("Text Font")
	font:SetRelativeWidth(0.5)
	font:SetList(LSM:HashTable("font"))
	font:SetValue(config.font)
	font:SetCallback("OnValueChanged", function(self, _, value)
		config.font = value
		self:SetValue(value)
		RefreshSwingTimer()
	end)
	textSettings:AddChild(font)

	local textOutline = AceGUI:Create("Dropdown")
	textOutline:SetRelativeWidth(0.5)
	textOutline:SetLabel("Outline")
	textOutline:SetList(Constants.TextOutline, Constants.TextOutlineSorted)
	textOutline:SetValue(config.textOutline)
	textOutline:SetCallback("OnValueChanged", function(_, _, value)
		config.textOutline = value
		RefreshSwingTimer()
	end)
	textSettings:AddChild(textOutline)

	local nameSettings = AceGUI:Create("InlineGroup")
	nameSettings:SetLayout("flow")
	nameSettings:SetTitle("Name")
	nameSettings:SetFullWidth(true)
	textSettings:AddChild(nameSettings)

	local showName = AceGUI:Create("CheckBox")
	showName:SetFullWidth(true)
	showName:SetLabel("Show Name")
	showName:SetValue(config.showNameText)
	showName:SetCallback("OnValueChanged", function(_, _, value)
		config.showNameText = value
		RefreshSwingTimer()
	end)
	nameSettings:AddChild(showName)

	local nameFontSize = AceGUI:Create("Slider")
	nameFontSize:SetRelativeWidth(0.33)
	nameFontSize:SetLabel("Font Size")
	nameFontSize:SetSliderValues(6, 100, 1)
	nameFontSize:SetValue(config.nameFontSize)
	nameFontSize:SetCallback("OnValueChanged", function(_, _, value)
		config.nameFontSize = value
		RefreshSwingTimer()
	end)
	nameSettings:AddChild(nameFontSize)

	local nameTextXOffset = AceGUI:Create("Slider")
	nameTextXOffset:SetRelativeWidth(0.33)
	nameTextXOffset:SetLabel("X Offset")
	nameTextXOffset:SetSliderValues(-300, 300, 0.1)
	nameTextXOffset:SetValue(config.nameTextXOffset)
	nameTextXOffset:SetCallback("OnValueChanged", function(_, _, value)
		config.nameTextXOffset = value
		RefreshSwingTimer()
	end)
	nameSettings:AddChild(nameTextXOffset)

	local nameTextYOffset = AceGUI:Create("Slider")
	nameTextYOffset:SetRelativeWidth(0.33)
	nameTextYOffset:SetLabel("Y Offset")
	nameTextYOffset:SetSliderValues(-100, 100, 0.1)
	nameTextYOffset:SetValue(config.nameTextYOffset)
	nameTextYOffset:SetCallback("OnValueChanged", function(_, _, value)
		config.nameTextYOffset = value
		RefreshSwingTimer()
	end)
	nameSettings:AddChild(nameTextYOffset)

	local durationSettings = AceGUI:Create("InlineGroup")
	durationSettings:SetLayout("flow")
	durationSettings:SetTitle("Duration")
	durationSettings:SetFullWidth(true)
	textSettings:AddChild(durationSettings)

	local showDuration = AceGUI:Create("CheckBox")
	showDuration:SetFullWidth(true)
	showDuration:SetLabel("Show Duration")
	showDuration:SetValue(config.showDurationText)
	showDuration:SetCallback("OnValueChanged", function(_, _, value)
		config.showDurationText = value
		RefreshSwingTimer()
	end)
	durationSettings:AddChild(showDuration)

	local durationFontSize = AceGUI:Create("Slider")
	durationFontSize:SetRelativeWidth(0.33)
	durationFontSize:SetLabel("Font Size")
	durationFontSize:SetSliderValues(6, 100, 1)
	durationFontSize:SetValue(config.durationFontSize)
	durationFontSize:SetCallback("OnValueChanged", function(_, _, value)
		config.durationFontSize = value
		RefreshSwingTimer()
	end)
	durationSettings:AddChild(durationFontSize)

	local durationTextXOffset = AceGUI:Create("Slider")
	durationTextXOffset:SetRelativeWidth(0.33)
	durationTextXOffset:SetLabel("X Offset")
	durationTextXOffset:SetSliderValues(-300, 300, 0.1)
	durationTextXOffset:SetValue(config.durationTextXOffset)
	durationTextXOffset:SetCallback("OnValueChanged", function(_, _, value)
		config.durationTextXOffset = value
		RefreshSwingTimer()
	end)
	durationSettings:AddChild(durationTextXOffset)

	local durationTextYOffset = AceGUI:Create("Slider")
	durationTextYOffset:SetRelativeWidth(0.33)
	durationTextYOffset:SetLabel("Y Offset")
	durationTextYOffset:SetSliderValues(-100, 100, 0.1)
	durationTextYOffset:SetValue(config.durationTextYOffset)
	durationTextYOffset:SetCallback("OnValueChanged", function(_, _, value)
		config.durationTextYOffset = value
		RefreshSwingTimer()
	end)
	durationSettings:AddChild(durationTextYOffset)
end

local function AddNumberFormatSettings(parent, swingType, config)
	local formatterSettings = AceGUI:Create("InlineGroup")
	formatterSettings:SetLayout("flow")
	formatterSettings:SetTitle("Number Format")
	formatterSettings:SetFullWidth(true)
	parent:AddChild(formatterSettings)

	local formatter = SCM.SwingTimers[swingType].durationFormatter
	SCM.Templates.AddFormatterOptions(formatterSettings, formatter, {
		showPrecisionAndRounding = true,
		hasAlpha = true,
	})

	local showIdleDuration = AceGUI:Create("CheckBox")
	showIdleDuration:SetFullWidth(true)
	showIdleDuration:SetLabel("Show Zero When Idle")
	showIdleDuration:SetValue(config.showIdleDuration)
	showIdleDuration:SetCallback("OnValueChanged", function(_, _, value)
		config.showIdleDuration = value
		RefreshSwingTimer()
	end)
	formatterSettings:AddChild(showIdleDuration)
end

local function SelectSwingTimerTab(tabGroup, swingType)
	local config = SCM.swingTimerConfig
	tabGroup:ReleaseChildren()

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	tabGroup:AddChild(scrollFrame)

	local swingTypeConfig = config[swingType]

	AddGeneralSettings(scrollFrame, swingTypeConfig)
	AddWidthSettings(scrollFrame, swingTypeConfig)
	AddHeightSettings(scrollFrame, swingTypeConfig)
	AddPositionSettings(scrollFrame, swingType, swingTypeConfig)

	local settingsTabs = AceGUI:Create("TabGroup")
	settingsTabs:SetTabs(SWING_TIMER_SETTINGS_TABS)
	settingsTabs:SetFullWidth(true)
	settingsTabs:SetLayout("flow")
	settingsTabs:SetCallback("OnGroupSelected", function(widget, _, group)
		widget:ReleaseChildren()
		if group == "Border" then
			AddBorderSettings(widget, swingTypeConfig)
		elseif group == "Text" then
			AddTextSettings(widget, swingTypeConfig)
		elseif group == "NumberFormat" then
			AddNumberFormatSettings(widget, swingType, swingTypeConfig)
		elseif group == "Spark" then
			AddSparkSettings(widget, swingTypeConfig)
		elseif group == "Visibility" then
			AddVisibilitySettings(widget, swingTypeConfig)
		end
		scrollFrame:DoLayout()
	end)
	scrollFrame:AddChild(settingsTabs)
	settingsTabs:SelectTab("Border")
end

local function SwingTimer(self)
	local swingTimerFrame = AceGUI:Create("InlineGroup")
	swingTimerFrame:SetLayout("flow")
	swingTimerFrame:SetFullWidth(true)
	swingTimerFrame:SetFullHeight(true)
	self:AddChild(swingTimerFrame)

	local swingTimerTabs = AceGUI:Create("TabGroup")
	swingTimerTabs:SetTabs(SWING_TIMER_TABS)
	swingTimerTabs:SetFullWidth(true)
	swingTimerTabs:SetFullHeight(true)
	swingTimerTabs:SetLayout("fill")
	swingTimerTabs:SetCallback("OnGroupSelected", function(widget, _, group)
		SelectSwingTimerTab(widget, group)
	end)
	swingTimerTabs:SelectTab("MainHand")
	swingTimerFrame:AddChild(swingTimerTabs)
end

SCM.MainTabs.SwingTimer.callback = SwingTimer
