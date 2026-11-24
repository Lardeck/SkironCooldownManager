local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local CONSTANTS = SCM.Constants.GENERAL
local AceGUI = LibStub("AceGUI-3.0")

local function GetFormattedTitle(subregionData)
	local color, type
	if subregionData.type == "glow" then
		color = { 0.95, 0.95, 0.32, 1 }
		type = CONSTANTS.GLOW_TYPES[subregionData.glowType or "Pixel"]
		local glowTypeOptions = subregionData.glowTypeOptions
		if glowTypeOptions and subregionData.glowType and glowTypeOptions[subregionData.glowType] then
			color = glowTypeOptions[subregionData.glowType].glowColor or color
		end
	else
		color = { 1, 1, 1, 1 }
	end

	return string.format("|c%s%s %s %d|r", CreateColor(unpack(color)):GenerateHexColor(), type or "", CONSTANTS.SUBREGIONS[subregionData.type] or subregionData.type, subregionData.typeIndex)
end

local function BuildSubregionTabs(iconConfig)
	local subregionTabs = {}

	for _, subregionData in ipairs(iconConfig.subregions) do
		tinsert(subregionTabs, { value = subregionData.globalIndex, text = GetFormattedTitle(subregionData) })
	end

	return subregionTabs
end

local function AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.33)
	xOffset:SetValue(glowTypeOptions.xOffset or 0)
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(-30, 30, 0.1)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		glowTypeOptions.xOffset = value
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
	end)
	dynamicGlowSettingsGroup:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.33)
	yOffset:SetValue(glowTypeOptions.yOffset or 0)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-30, 30, 0.1)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		glowTypeOptions.yOffset = value
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
	end)
	dynamicGlowSettingsGroup:AddChild(yOffset)
end

local function AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	local glowColor = AceGUI:Create("ColorPicker")
	glowColor:SetRelativeWidth(0.33)
	glowColor:SetLabel("Glow Color")
	glowColor:SetHasAlpha(true)
	glowTypeOptions.glowColor = glowTypeOptions.glowColor or { 0.95, 0.95, 0.32, 1 }
	glowColor:SetColor(unpack(glowTypeOptions.glowColor))
	glowColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		glowTypeOptions.glowColor = { r, g, b, a }
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
	end)
	dynamicGlowSettingsGroup:AddChild(glowColor)
end

local function AddCustomGlowOptions(dynamicGlowSettingsGroup, glowTypeOptions, glowType, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	dynamicGlowSettingsGroup:ReleaseChildren()

	if glowType == "Proc" then
		local startAnim = AceGUI:Create("CheckBox")
		startAnim:SetRelativeWidth(0.33)
		startAnim:SetValue(glowTypeOptions.startAnim)
		startAnim:SetLabel("Start Animation")
		startAnim:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.startAnim = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(startAnim)

		AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	elseif glowType == "Autocast" then
		--color,numParticles,frequency,scale,xOffset,yOffset

		local numParticles = AceGUI:Create("Slider")
		numParticles:SetRelativeWidth(0.33)
		numParticles:SetValue(glowTypeOptions.numParticles or 4)
		numParticles:SetLabel("Particles")
		numParticles:SetSliderValues(1, 30, 1)
		numParticles:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.numParticles = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(numParticles)

		local frequency = AceGUI:Create("Slider")
		frequency:SetRelativeWidth(0.33)
		frequency:SetValue(glowTypeOptions.frequency or 0.125)
		frequency:SetLabel("Frequency")
		frequency:SetSliderValues(-3, 3, 0.05)
		frequency:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.frequency = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(frequency)

		local scale = AceGUI:Create("Slider")
		scale:SetRelativeWidth(0.33)
		scale:SetValue(glowTypeOptions.scale or 1)
		scale:SetLabel("Scale")
		scale:SetSliderValues(0.01, 5, 0.1)
		scale:SetIsPercent(true)
		scale:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.scale = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(scale)

		AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	elseif glowType == "Pixel" then
		--color,numLines,frequency,length,thickness,xOffset,yOffset,border

		local numLines = AceGUI:Create("Slider")
		numLines:SetRelativeWidth(0.33)
		numLines:SetValue(glowTypeOptions.numLines or 8)
		numLines:SetLabel("Lines")
		numLines:SetSliderValues(1, 30, 1)
		numLines:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.numLines = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(numLines)

		local frequency = AceGUI:Create("Slider")
		frequency:SetRelativeWidth(0.33)
		frequency:SetValue(glowTypeOptions.frequency or 0.25)
		frequency:SetLabel("Frequency")
		frequency:SetSliderValues(-3, 3, 0.05)
		frequency:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.frequency = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(frequency)

		local length = AceGUI:Create("Slider")
		length:SetRelativeWidth(0.33)
		length:SetValue(glowTypeOptions.length or 2)
		length:SetLabel("Length")
		length:SetSliderValues(1, 15, 0.05)
		length:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.length = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(length)

		local thickness = AceGUI:Create("Slider")
		thickness:SetRelativeWidth(0.33)
		thickness:SetValue(glowTypeOptions.thickness or 2)
		thickness:SetLabel("Thickness")
		thickness:SetSliderValues(1, 15, 0.05)
		thickness:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.thickness = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(thickness)

		AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)

		local border = AceGUI:Create("CheckBox")
		border:SetRelativeWidth(0.33)
		border:SetValue(glowTypeOptions.border)
		border:SetLabel("Border")
		border:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.border = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(border)
	elseif glowType == "Button" then
		local frequency = AceGUI:Create("Slider")
		frequency:SetRelativeWidth(0.33)
		frequency:SetValue(glowTypeOptions.frequency or 0.125)
		frequency:SetLabel("Frequency")
		frequency:SetSliderValues(-3, 3, 0.05)
		frequency:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.frequency = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
		end)
		dynamicGlowSettingsGroup:AddChild(frequency)

		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end
end

local function RemoveSubregionRules(iconConfig, subregionType, removedIndex)
	local effectConfig = iconConfig.effectRules and iconConfig.effectRules[subregionType]
	local rules = effectConfig and effectConfig.rules
	if not rules then
		return
	end

	for ruleIndex = #rules, 1, -1 do
		local rule = rules[ruleIndex]
		if rule.subregion == removedIndex then
			tremove(rules, ruleIndex)
		elseif type(rule.subregion) == "number" and rule.subregion > removedIndex then
			rule.subregion = rule.subregion - 1
		end
	end

	if rules[1] then
		rules[1].elseIf = nil
	end

	SCM.States.PruneEffectRules(iconConfig, subregionType)
end

local function AddSubregionOptions(subregionData, subregionTabs, iconConfig, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	if subregionData.type == "glow" then
		subregionData.glowType = subregionData.glowType or "Pixel"
		subregionData.glowTypeOptions = subregionData.glowTypeOptions or {}
		subregionData.glowTypeOptions[subregionData.glowType] = subregionData.glowTypeOptions[subregionData.glowType] or {}

		local glowType = AceGUI:Create("Dropdown")
		glowType:SetRelativeWidth(1)
		glowType:SetLabel("Glow Type")
		glowType:SetList(CONSTANTS.GLOW_TYPES, CONSTANTS.GLOW_TYPES_SORTED)
		subregionTabs:AddChild(glowType)

		local dynamicGlowSettingsGroup = AceGUI:Create("SimpleGroup")
		dynamicGlowSettingsGroup:SetLayout("flow")
		dynamicGlowSettingsGroup:SetFullWidth(true)
		subregionTabs:AddChild(dynamicGlowSettingsGroup)

		glowType:SetCallback("OnValueChanged", function(_, _, value)
			subregionData.glowType = value
			subregionData.glowTypeOptions[value] = subregionData.glowTypeOptions[value] or {}

			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true, true)
			subregionTabs:SetTabs(BuildSubregionTabs(iconConfig))
			subregionTabs:SelectTab(subregionData.globalIndex)
		end)
		glowType:SetValue(subregionData.glowType)
		AddCustomGlowOptions(dynamicGlowSettingsGroup, subregionData.glowTypeOptions[subregionData.glowType], subregionData.glowType, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	elseif subregionData.type == "border" then
		local borderSize = AceGUI:Create("Slider")
		borderSize:SetRelativeWidth(0.5)
		borderSize:SetLabel("Border Size")
		borderSize:SetSliderValues(0, 5, 0.1)
		borderSize:SetValue(subregionData.borderSize or 1)
		borderSize:SetCallback("OnValueChanged", function(_, _, value)
			subregionData.borderSize = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true)
		end)
		subregionTabs:AddChild(borderSize)

		local borderColor = AceGUI:Create("ColorPicker")
		borderColor:SetRelativeWidth(0.5)
		borderColor:SetLabel("Border Color")
		borderColor:SetHasAlpha(true)

		subregionData.borderColor = subregionData.borderColor or {r = 0, g = 0, b = 0, a = 1}
		local color = subregionData.borderColor
		borderColor:SetColor(color.r, color.g, color.b, color.a)
		borderColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			subregionData.borderColor = { r = r, g = g, b = b, a = a }
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true)
		end)
		subregionTabs:AddChild(borderColor)
	elseif subregionData.type == "text" then
	end

	local removeSubregionButton = AceGUI:Create("Button")
	removeSubregionButton:SetFullWidth(true)
	removeSubregionButton:SetText("Remove")
	removeSubregionButton:SetCallback("OnClick", function()
		local removedIndex = subregionData.globalIndex
		local removedType = subregionData.type

		tremove(iconConfig.subregions, removedIndex)
		tremove(iconConfig.subregionOptions[removedType], subregionData.typeIndex)
		RemoveSubregionRules(iconConfig, removedType, subregionData.typeIndex)

		for index, subregionData in ipairs(iconConfig.subregions) do
			subregionData.globalIndex = index
		end

		for index, subregionData in ipairs(iconConfig.subregionOptions[removedType]) do
			subregionData.typeIndex = index
		end

		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true)

		local tabs = BuildSubregionTabs(iconConfig)
		local selectedTab = tabs[removedIndex] or tabs[removedIndex - 1]
		subregionTabs:SetTabs(tabs)

		if selectedTab then
			subregionTabs:SelectTab(selectedTab.value)
		else
			subregionTabs:ReleaseChildren()
		end
	end)
	subregionTabs:AddChild(removeSubregionButton)
end

function CDMOptions.CreateSubregionTabSettings(iconSettingsTabs, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
	iconConfig.subregions = iconConfig.subregions or {}
	iconConfig.subregionOptions = iconConfig.subregionOptions or {}

	local rootGroup = AceGUI:Create("SimpleGroup")
	rootGroup:SetLayout("fill")
	rootGroup:SetFullWidth(true)
	rootGroup:SetFullHeight(true)
	iconSettingsTabs:AddChild(rootGroup)

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true)
	rootGroup:AddChild(scrollFrame)

	local generalSettings = AceGUI:Create("InlineGroup")
	generalSettings:SetLayout("flow")
	generalSettings:SetFullWidth(true)
	scrollFrame:AddChild(generalSettings)

	local selectedSubregion
	local subregionDropdown = AceGUI:Create("Dropdown")
	subregionDropdown:SetLabel("Subregion")
	subregionDropdown:SetRelativeWidth(0.75)
	generalSettings:AddChild(subregionDropdown)

	local addSubregionButton = AceGUI:Create("Button")
	addSubregionButton:SetText("Add")
	addSubregionButton:SetRelativeWidth(0.2)
	generalSettings:AddChild(addSubregionButton)

	subregionDropdown:SetList(CONSTANTS.SUBREGIONS, CONSTANTS.SUBREGIONS_SORTED)
	subregionDropdown:SetValue(selectedSubregion)
	addSubregionButton:SetDisabled(selectedSubregion == nil)

	subregionDropdown:SetCallback("OnValueChanged", function(_, _, value)
		selectedSubregion = value
		addSubregionButton:SetDisabled(value == nil)
	end)

	local subregionTabs = AceGUI:Create("TabGroup")
	local tabs = BuildSubregionTabs(iconConfig)
	subregionTabs:SetLayout("flow")
	subregionTabs:SetFullWidth(true)
	subregionTabs:SetTabs(tabs)
	subregionTabs:SetCallback("OnGroupSelected", function(self, _, selectedTab)
		self:ReleaseChildren()
		if not selectedTab or not iconConfig.subregions[selectedTab] then
			return
		end
		AddSubregionOptions(iconConfig.subregions[selectedTab], self, iconConfig, buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)
	scrollFrame:AddChild(subregionTabs)

	addSubregionButton:SetCallback("OnClick", function()
		if not selectedSubregion then
			return
		end
		iconConfig.subregionOptions[selectedSubregion] = iconConfig.subregionOptions[selectedSubregion] or {}

		local subregionData = {
			type = selectedSubregion,
		}

		if selectedSubregion == "glow" then
			subregionData.glowTypeOptions = {}
		end

		tinsert(iconConfig.subregionOptions[selectedSubregion], subregionData)
		tinsert(iconConfig.subregions, subregionData)

		subregionData.globalIndex = #iconConfig.subregions
		subregionData.typeIndex = #iconConfig.subregionOptions[selectedSubregion]
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true)

		subregionTabs:SetTabs(BuildSubregionTabs(iconConfig))
		subregionTabs:SelectTab(subregionData.globalIndex)
		selectedSubregion = nil
		subregionDropdown:SetValue(selectedSubregion)
	end)

	if tabs[1] then
		subregionTabs:SelectTab(tabs[1].value)
	end
end
