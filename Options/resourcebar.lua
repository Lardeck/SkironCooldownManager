local SCM = select(2, ...)
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

local function RefreshResourceBars(refreshTicks)
	SCM:RefreshResourceBarConfig(refreshTicks, true)
end

local function AddLayoutSettings(parent, settings)
	local generalSettings = AceGUI:Create("InlineGroup")
	generalSettings:SetLayout("flow")
	generalSettings:SetTitle("General")
	generalSettings:SetFullWidth(true)
	parent:AddChild(generalSettings)

	local enableResourceBars = AceGUI:Create("CheckBox")
	enableResourceBars:SetRelativeWidth(0.5)
	enableResourceBars:SetLabel("Enable Resource Bars")
	enableResourceBars:SetValue(settings.enabled)
	enableResourceBars:SetCallback("OnValueChanged", function(_, _, value)
		settings.enabled = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(enableResourceBars)

	local useFrequentPowerUpdates = AceGUI:Create("CheckBox")
	useFrequentPowerUpdates:SetRelativeWidth(0.5)
	useFrequentPowerUpdates:SetLabel("Frequent Updates")
	useFrequentPowerUpdates:SetValue(settings.useFrequentPowerUpdates and true or false)
	useFrequentPowerUpdates:SetCallback("OnValueChanged", function(_, _, value)
		settings.useFrequentPowerUpdates = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(useFrequentPowerUpdates)

	local visibilitySettings = AceGUI:Create("InlineGroup")
	visibilitySettings:SetLayout("flow")
	visibilitySettings:SetTitle("Visibility")
	visibilitySettings:SetFullWidth(true)
	parent:AddChild(visibilitySettings)

	local hideWhileMounted = AceGUI:Create("CheckBox")
	hideWhileMounted:SetRelativeWidth(0.33)
	hideWhileMounted:SetLabel("Hide While Mounted")
	hideWhileMounted:SetValue(settings.hideWhileMounted)
	hideWhileMounted:SetDisabled(settings.useCustomVisibilityCondition)
	hideWhileMounted:SetCallback("OnValueChanged", function(_, _, value)
		settings.hideWhileMounted = value
		RefreshResourceBars()
	end)
	visibilitySettings:AddChild(hideWhileMounted)

	local hideWhileDead = AceGUI:Create("CheckBox")
	hideWhileDead:SetRelativeWidth(0.33)
	hideWhileDead:SetLabel("Hide While Dead")
	hideWhileDead:SetValue(settings.hideWhileDead)
	hideWhileDead:SetDisabled(settings.useCustomVisibilityCondition)
	hideWhileDead:SetCallback("OnValueChanged", function(_, _, value)
		settings.hideWhileDead = value
		RefreshResourceBars()
	end)
	visibilitySettings:AddChild(hideWhileDead)

	local hideWhileInVehicle = AceGUI:Create("CheckBox")
	hideWhileInVehicle:SetRelativeWidth(0.33)
	hideWhileInVehicle:SetLabel("Hide While In Vehicle")
	hideWhileInVehicle:SetValue(settings.hideWhileInVehicle)
	hideWhileInVehicle:SetDisabled(settings.useCustomVisibilityCondition)
	hideWhileInVehicle:SetCallback("OnValueChanged", function(_, _, value)
		settings.hideWhileInVehicle = value
		RefreshResourceBars()
	end)
	visibilitySettings:AddChild(hideWhileInVehicle)

	local hideWhileResting = AceGUI:Create("CheckBox")
	hideWhileResting:SetRelativeWidth(0.33)
	hideWhileResting:SetLabel("Hide While Resting")
	hideWhileResting:SetValue(settings.hideWhileResting)
	hideWhileResting:SetDisabled(settings.useCustomVisibilityCondition)
	hideWhileResting:SetCallback("OnValueChanged", function(_, _, value)
		settings.hideWhileResting = value
		RefreshResourceBars()
	end)
	visibilitySettings:AddChild(hideWhileResting)

	local hideOutOfCombat = AceGUI:Create("CheckBox")
	hideOutOfCombat:SetRelativeWidth(0.33)
	hideOutOfCombat:SetLabel("Hide Outside Of Combat")
	hideOutOfCombat:SetValue(settings.hideOutOfCombat)
	hideOutOfCombat:SetDisabled(settings.useCustomVisibilityCondition)
	hideOutOfCombat:SetCallback("OnValueChanged", function(_, _, value)
		settings.hideOutOfCombat = value
		RefreshResourceBars()
	end)
	visibilitySettings:AddChild(hideOutOfCombat)

	local customVisibilitySettings = AceGUI:Create("InlineGroup")
	customVisibilitySettings:SetLayout("flow")
	customVisibilitySettings:SetFullWidth(true)
	customVisibilitySettings:SetTitle("Custom")
	visibilitySettings:AddChild(customVisibilitySettings)

	local useCustomVisibilityCondition = AceGUI:Create("CheckBox")
	useCustomVisibilityCondition:SetRelativeWidth(0.5)
	useCustomVisibilityCondition:SetLabel("Use Custom Condition")
	useCustomVisibilityCondition:SetValue(settings.useCustomVisibilityCondition)

	customVisibilitySettings:AddChild(useCustomVisibilityCondition)

	local customVisibilityCondition = AceGUI:Create("EditBox")
	customVisibilityCondition:SetRelativeWidth(0.5)
	customVisibilityCondition:SetLabel("Condition")
	customVisibilityCondition:SetText(settings.customVisibilityCondition)
	customVisibilityCondition:SetDisabled(not settings.useCustomVisibilityCondition)
	customVisibilityCondition:SetCallback("OnEnterPressed", function(_, _, value)
		settings.customVisibilityCondition = value

		SCM:ApplyAttributeDriver()
		SCM:CreateAllCustomIcons()
	end)
	customVisibilitySettings:AddChild(customVisibilityCondition)

	useCustomVisibilityCondition:SetCallback("OnValueChanged", function(_, _, value)
		settings.useCustomVisibilityCondition = value

		customVisibilityCondition:SetDisabled(not value)
		hideWhileMounted:SetDisabled(value)
		hideWhileDead:SetDisabled(value)
		hideWhileInVehicle:SetDisabled(value)
		hideWhileResting:SetDisabled(value)
		hideOutOfCombat:SetDisabled(value)
		SCM:ApplyAttributeDriver()
		SCM:CreateAllCustomIcons()
	end)

	local layoutSettings = AceGUI:Create("InlineGroup")
	layoutSettings:SetLayout("flow")
	layoutSettings:SetTitle("Layout")
	layoutSettings:SetFullWidth(true)
	parent:AddChild(layoutSettings)

	local barMinWidth = AceGUI:Create("Slider")
	barMinWidth:SetRelativeWidth(0.5)
	barMinWidth:SetLabel("Min Width")
	barMinWidth:SetSliderValues(50, 500, 0.1)
	barMinWidth:SetValue(settings.minWidth)
	barMinWidth:SetCallback("OnValueChanged", function(_, _, value)
		settings.minWidth = value
		RefreshResourceBars()
	end)
	layoutSettings:AddChild(barMinWidth)

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

	local frameStrata = AceGUI:Create("Dropdown")
	frameStrata:SetRelativeWidth(0.5)
	frameStrata:SetList(SCM.Constants.FrameStrata, SCM.Constants.FrameStrataSorted)
	frameStrata:SetLabel("Frame Strata")
	frameStrata:SetValue(settings.frameStrata or "")
	frameStrata:SetCallback("OnValueChanged", function(self, event, value)
		settings.frameStrata = value ~= "" and value or nil
		RefreshResourceBars()
	end)
	layoutSettings:AddChild(frameStrata)
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

	local staggerColors = settings.staggerColors
	for _, staggerColorInfo in ipairs({
		{ "light", "Light Stagger" },
		{ "moderate", "Moderate Stagger" },
		{ "heavy", "Heavy Stagger" },
	}) do
		local key = staggerColorInfo[1]
		local color = staggerColors[key]

		local colorPicker = AceGUI:Create("ColorPicker")
		colorPicker:SetRelativeWidth(0.33)
		colorPicker:SetLabel(staggerColorInfo[2])
		colorPicker:SetHasAlpha(false)
		colorPicker:SetColor(color.r, color.g, color.b)
		colorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b)
			staggerColors[key] = { r = r, g = g, b = b }
			RefreshResourceBars()
		end)
		powerTypeColors:AddChild(colorPicker)
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

	local defaultRuneColor = settings.powerTypeColorOverrides.RUNES.color
	local runeRechargeColorValue = settings.runeRechargeColor or defaultRuneColor
	local runeRechargeColor = AceGUI:Create("ColorPicker")
	runeRechargeColor:SetRelativeWidth(0.33)
	runeRechargeColor:SetLabel("Recharging Runes")
	runeRechargeColor:SetHasAlpha(false)
	runeRechargeColor:SetColor(runeRechargeColorValue.r, runeRechargeColorValue.g, runeRechargeColorValue.b)
	runeRechargeColor:SetCallback("OnValueChanged", function(_, _, r, g, b)
		settings.runeRechargeColor = { r = r, g = g, b = b }
		RefreshResourceBars()
	end)
	specialColors:AddChild(runeRechargeColor)
end

local function AddBarSettings(parent, title, settings, includeManaRoleSettings, globalSettings)
	local isSpecConfigActive = SCM.resourceBarConfig.active

	local generalSettings = AceGUI:Create("InlineGroup")
	generalSettings:SetLayout("flow")
	generalSettings:SetTitle("General")
	generalSettings:SetFullWidth(true)
	parent:AddChild(generalSettings)

	local enableBar = AceGUI:Create("CheckBox")
	enableBar:SetRelativeWidth(0.25)
	enableBar:SetLabel("Enable Bar")
	enableBar:SetValue(settings.enabled)
	enableBar:SetCallback("OnValueChanged", function(_, _, value)
		settings.enabled = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(enableBar)

	local widthSlider
	local matchAnchorWidth = AceGUI:Create("CheckBox")
	matchAnchorWidth:SetRelativeWidth(0.25)
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

	local textOnly = AceGUI:Create("CheckBox")
	textOnly:SetRelativeWidth(0.25)
	textOnly:SetLabel("Text Only")
	textOnly:SetValue(settings.textOnly)
	textOnly:SetCallback("OnValueChanged", function(_, _, value)
		settings.textOnly = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(textOnly)

	local useSmoothPowerUpdates = AceGUI:Create("CheckBox")
	useSmoothPowerUpdates:SetRelativeWidth(0.25)
	useSmoothPowerUpdates:SetLabel("Smooth Updates")
	useSmoothPowerUpdates:SetValue(settings.useSmoothPowerUpdates and true or false)
	useSmoothPowerUpdates:SetCallback("OnValueChanged", function(_, _, value)
		settings.useSmoothPowerUpdates = value
		RefreshResourceBars()
	end)
	generalSettings:AddChild(useSmoothPowerUpdates)

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

	if title == "Primary" or title == "Secondary" then
		local barHeightAlternative = AceGUI:Create("Slider")
		barHeightAlternative:SetRelativeWidth(0.5)
		barHeightAlternative:SetLabel(title == "Primary" and "Bar Height (with Secondary)" or "Bar Height (with Primary)")
		barHeightAlternative:SetSliderValues(3, 40, 0.1)
		barHeightAlternative:SetValue(settings.heightAlternative)
		barHeightAlternative:SetCallback("OnValueChanged", function(_, _, value)
			settings.heightAlternative = value
			RefreshResourceBars()
		end)
		generalSettings:AddChild(barHeightAlternative)
	end

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

	if not isSpecConfigActive then
		local hideManaRoleSettings = settings.hideManaRoles
		local hideManaRoles = AceGUI:Create("Dropdown")
		hideManaRoles:SetRelativeWidth(0.5)
		hideManaRoles:SetLabel("Hide Mana For Roles")
		hideManaRoles:SetList(SCM.Constants.Roles)
		hideManaRoles:SetMultiselect(true)
		hideManaRoles:SetCallback("OnValueChanged", function(_, _, key, value)
			settings.hideManaRoles[key] = value
			RefreshResourceBars()
		end)
		for key in pairs(SCM.Constants.Roles) do
			hideManaRoles:SetItemValue(key, hideManaRoleSettings[key])
		end
		generalSettings:AddChild(hideManaRoles)
	else
		local forceMana = AceGUI:Create("CheckBox")
		forceMana:SetRelativeWidth(0.5)
		forceMana:SetLabel("Show Mana (if possible)")
		forceMana:SetValue(settings.forceMana)
		forceMana:SetCallback("OnValueChanged", function(_, _, value)
			settings.forceMana = value
			RefreshResourceBars()
		end)
		generalSettings:AddChild(forceMana)

		if UnitClassBase("player") == "DRUID" then
			local powerTypeList = title == "Primary" and Constants.DruidPrimaryPowerTypes or Constants.DruidSecondaryPowerTypes
			local druidFormPowerTypesBySpec = settings.druidFormPowerTypes

			local druidSettings = AceGUI:Create("InlineGroup")
			druidSettings:SetFullWidth(true)
			druidSettings:SetTitle("Druid")
			druidSettings:SetLayout("flow")
			parent:AddChild(druidSettings)

			local specID = SCM.currentSpecID
			local druidFormPowerTypes = druidFormPowerTypesBySpec[specID]
			local function AddDruidFormDropdown(parentGroup, druidFormPowerTypes, formID, label)
				local formDropdown = AceGUI:Create("Dropdown")
				formDropdown:SetRelativeWidth(0.33)
				formDropdown:SetLabel(label)
				formDropdown:SetList(powerTypeList)
				formDropdown:SetValue(druidFormPowerTypes[formID])
				formDropdown:SetCallback("OnValueChanged", function(_, _, value)
					druidFormPowerTypes[formID] = value
					RefreshResourceBars()
				end)
				parentGroup:AddChild(formDropdown)
			end

			AddDruidFormDropdown(druidSettings, druidFormPowerTypes, 0, "Human Form")
			AddDruidFormDropdown(druidSettings, druidFormPowerTypes, 1, "Bear Form")
			AddDruidFormDropdown(druidSettings, druidFormPowerTypes, 2, "Cat Form")
			AddDruidFormDropdown(druidSettings, druidFormPowerTypes, 3, "Travel Form")
			AddDruidFormDropdown(druidSettings, druidFormPowerTypes, 4, "Moonkin Form")
		end
	end

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
		RefreshResourceBars(true)
	end)
	tickSettings:AddChild(showTicks)

	local tickColor = AceGUI:Create("ColorPicker")
	tickColor:SetRelativeWidth(0.33)
	tickColor:SetLabel("Tick Color")
	tickColor:SetHasAlpha(true)
	tickColor:SetColor(settings.tickColor.r, settings.tickColor.g, settings.tickColor.b, settings.tickColor.a)
	tickColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		settings.tickColor = { r = r, g = g, b = b, a = a }
		RefreshResourceBars(true)
	end)
	tickSettings:AddChild(tickColor)

	local tickWidth = AceGUI:Create("Slider")
	tickWidth:SetRelativeWidth(0.33)
	tickWidth:SetLabel("Tick Width")
	tickWidth:SetSliderValues(1, 10, 0.1)
	tickWidth:SetValue(settings.tickWidth)
	tickWidth:SetCallback("OnValueChanged", function(_, _, value)
		settings.tickWidth = value
		RefreshResourceBars(true)
	end)
	tickSettings:AddChild(tickWidth)

	local sparkOptions = settings.spark
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
		RefreshResourceBars()
	end)
	sparkGroup:AddChild(sparkEnable)

	local sparkColor = AceGUI:Create("ColorPicker")
	sparkColor:SetRelativeWidth(0.33)
	sparkColor:SetLabel("Spark Color")
	sparkColor:SetHasAlpha(true)
	sparkColor:SetColor(sparkOptions.color.r, sparkOptions.color.g, sparkOptions.color.b, sparkOptions.color.a)
	sparkColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		sparkOptions.color = { r = r, g = g, b = b, a = a }
		RefreshResourceBars()
	end)
	sparkGroup:AddChild(sparkColor)

	local blendMode = AceGUI:Create("Dropdown")
	blendMode:SetRelativeWidth(0.33)
	blendMode:SetList(SCM.Constants.BlendMode, SCM.Constants.BlendModeSorted)
	blendMode:SetLabel("Blend Mode")
	blendMode:SetValue(sparkOptions.blendMode)
	blendMode:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.blendMode = value
		RefreshResourceBars()
	end)
	sparkGroup:AddChild(blendMode)

	local sparkWidth = AceGUI:Create("Slider")
	sparkWidth:SetRelativeWidth(0.25)
	sparkWidth:SetLabel("Spark Width")
	sparkWidth:SetSliderValues(1, 50, 0.1)
	sparkWidth:SetValue(sparkOptions.width)
	sparkWidth:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.width = value
		RefreshResourceBars()
	end)
	sparkGroup:AddChild(sparkWidth)

	local sparkHeight = AceGUI:Create("Slider")
	sparkHeight:SetRelativeWidth(0.25)
	sparkHeight:SetLabel("Spark Height")
	sparkHeight:SetSliderValues(1, 80, 0.1)
	sparkHeight:SetValue(sparkOptions.height)
	sparkHeight:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.height = value
		RefreshResourceBars()
	end)
	sparkGroup:AddChild(sparkHeight)

	local sparkXOffset = AceGUI:Create("Slider")
	sparkXOffset:SetRelativeWidth(0.25)
	sparkXOffset:SetLabel("Spark X-Offset")
	sparkXOffset:SetSliderValues(-20, 20, 0.1)
	sparkXOffset:SetValue(sparkOptions.xOffset)
	sparkXOffset:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.xOffset = value
		RefreshResourceBars()
	end)
	sparkGroup:AddChild(sparkXOffset)

	local sparkYOffset = AceGUI:Create("Slider")
	sparkYOffset:SetRelativeWidth(0.25)
	sparkYOffset:SetLabel("Spark Y-Offset")
	sparkYOffset:SetSliderValues(-20, 20, 0.1)
	sparkYOffset:SetValue(sparkOptions.yOffset)
	sparkYOffset:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.yOffset = value
		RefreshResourceBars()
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
		RefreshResourceBars()
	end)

	useCustomTexture:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.useCustomTexture = value
		customTexture:SetDisabled(not value)
		RefreshResourceBars()
	end)
	sparkGroup:AddChild(customTexture)

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
	showValues:SetRelativeWidth(0.25)
	showValues:SetLabel("Show Text")
	showValues:SetValue(settings.showValues)
	showValues:SetCallback("OnValueChanged", function(_, _, value)
		settings.showValues = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(showValues)

	local showValues = AceGUI:Create("CheckBox")
	showValues:SetRelativeWidth(0.25)
	showValues:SetLabel("Show Percent Sign")
	showValues:SetValue(settings.showPercentageSign)
	showValues:SetCallback("OnValueChanged", function(_, _, value)
		settings.showPercentageSign = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(showValues)

	local font = AceGUI:Create("LSM30_Font")
	font:SetLabel("Text Font")
	font:SetRelativeWidth(0.25)
	font:SetList(LSM:HashTable("font"))
	font:SetValue(settings.font)
	font:SetCallback("OnValueChanged", function(self, _, value)
		settings.font = value
		self:SetValue(value)
		RefreshResourceBars()
	end)
	textSettings:AddChild(font)

	local textOutline = AceGUI:Create("Dropdown")
	textOutline:SetRelativeWidth(0.25)
	textOutline:SetLabel("Outline")
	textOutline:SetList(Constants.TextOutline, Constants.TextOutlineSorted)
	textOutline:SetValue(settings.textOutline)
	textOutline:SetCallback("OnValueChanged", function(_, _, value)
		settings.textOutline = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(textOutline)

	local fontSize = AceGUI:Create("Slider")
	fontSize:SetRelativeWidth(0.33)
	fontSize:SetLabel("Font Size")
	fontSize:SetSliderValues(6, 100, 1)
	fontSize:SetValue(settings.fontSize)
	fontSize:SetCallback("OnValueChanged", function(_, _, value)
		settings.fontSize = value
		RefreshResourceBars()
	end)
	textSettings:AddChild(fontSize)

	local textXOffset = AceGUI:Create("Slider")
	textXOffset:SetRelativeWidth(0.33)
	textXOffset:SetLabel("Text X Offset")
	textXOffset:SetSliderValues(-300, 300, 0.1)
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

	if title == "Secondary" then
		local miscSettings = AceGUI:Create("InlineGroup")
		miscSettings:SetLayout("flow")
		miscSettings:SetTitle("Miscellaneous")
		miscSettings:SetFullWidth(true)
		parent:AddChild(miscSettings)

		local disableMaelstromOverflow = AceGUI:Create("CheckBox")
		disableMaelstromOverflow:SetRelativeWidth(0.5)
		disableMaelstromOverflow:SetLabel("Disable Maelstrom Overflow")
		disableMaelstromOverflow:SetValue(settings.disableMaelstromOverflow)
		disableMaelstromOverflow:SetCallback("OnValueChanged", function(_, _, value)
			settings.disableMaelstromOverflow = value
			RefreshResourceBars()
		end)
		miscSettings:AddChild(disableMaelstromOverflow)

		local staggerDisplayAsPercent = AceGUI:Create("CheckBox")
		staggerDisplayAsPercent:SetRelativeWidth(0.33)
		staggerDisplayAsPercent:SetLabel("Stagger Text As Percent")
		staggerDisplayAsPercent:SetValue(globalSettings.staggerDisplayAsPercent)
		staggerDisplayAsPercent:SetCallback("OnValueChanged", function(_, _, value)
			globalSettings.staggerDisplayAsPercent = value
			RefreshResourceBars()
		end)
		miscSettings:AddChild(staggerDisplayAsPercent)
	end

	parent:DoLayout()
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
		AddBarSettings(scrollFrame, "Primary", settings.primaryBar, true, settings)
	elseif group == "Secondary" then
		AddBarSettings(scrollFrame, "Secondary", settings.secondaryBar, nil, settings)
	end
end

local function ResourceBar(self)
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

	local statusGroup = AceGUI:Create("InlineGroup")
	statusGroup:SetFullWidth(true)
	statusGroup:SetLayout("flow")
	resourceBarFrame:AddChild(statusGroup)

	local currentStatus = AceGUI:Create("Label")
	currentStatus:SetRelativeWidth(0.33)
	currentStatus:SetJustifyH("LEFT")
	currentStatus:SetJustifyV("MIDDLE")
	currentStatus:SetFontObject("Game15Font")
	statusGroup:AddChild(currentStatus)

	if SCM.resourceBarConfig.active then
		currentStatus:SetText(string.format("Status: |cffea00ffSpecialization|r (%s)", (select(2, SCM.Utils.GetSpec()))))
	else
		currentStatus:SetText("Status: |cfffcf803Profile|r")
	end

	local modifyCurrentSpecialization = AceGUI:Create("CheckBox")
	modifyCurrentSpecialization:SetRelativeWidth(0.33)
	modifyCurrentSpecialization:SetLabel("Use Specialization Config")
	modifyCurrentSpecialization:SetValue(SCM.resourceBarConfig.active)
	statusGroup:AddChild(modifyCurrentSpecialization)

	local resetCurrentSpecialization = AceGUI:Create("Button")
	resetCurrentSpecialization:SetText("Clear Spec Config")
	resetCurrentSpecialization:SetRelativeWidth(0.33)
	resetCurrentSpecialization:SetDisabled(not SCM.resourceBarConfig.active)
	resetCurrentSpecialization:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
		GameTooltip:SetText("Clear Spec Config", nil, nil, nil, nil, true)
		GameTooltip:AddLine("This will clear the spec config and fall back to the normal resource bar options.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	resetCurrentSpecialization:SetCallback("OnLeave", function()
		GameTooltip:Hide()
	end)
	statusGroup:AddChild(resetCurrentSpecialization)

	local currentTab = "Layout"
	local resourceBarTabs = AceGUI:Create("TabGroup")
	resourceBarTabs:SetTabs(RESOURCE_BAR_TABS)
	resourceBarTabs:SetFullWidth(true)
	resourceBarTabs:SetFullHeight(true)
	resourceBarTabs:SetLayout("fill")
	resourceBarTabs:SetCallback("OnGroupSelected", function(widget, _, group)
		currentTab = group
		SelectResourceBarTab(widget, group, SCM.resourceBarConfig)
	end)
	resourceBarTabs:SelectTab("Layout")
	resourceBarFrame:AddChild(resourceBarTabs)

	resetCurrentSpecialization:SetCallback("OnClick", function()
		local specResourceBarConfig = SCM.specResourceBarConfig
		local isActive = specResourceBarConfig.active

		wipe(specResourceBarConfig)
		specResourceBarConfig.active = isActive

		resourceBarTabs:SelectTab(currentTab)
		RefreshResourceBars()
	end)

	modifyCurrentSpecialization:SetCallback("OnValueChanged", function(_, _, value)
		SCM.resourceBarConfig.active = value

		if value then
			currentStatus:SetText(string.format("Status: |cffea00ffSpecialization|r (%s)", (select(2, SCM.Utils.GetSpec()))))
		else
			currentStatus:SetText("Status: |cfffcf803Profile|r")
		end

		resourceBarTabs:SelectTab(currentTab)
		resetCurrentSpecialization:SetDisabled(not value)
		RefreshResourceBars()
	end)
end

SCM.MainTabs.ResourceBar.callback = ResourceBar
