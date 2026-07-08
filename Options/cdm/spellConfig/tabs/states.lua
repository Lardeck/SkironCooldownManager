local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local Constants = SCM.Constants
local AceGUI = LibStub("AceGUI-3.0")

local REMOVE_OPTION = "remove"

local optionOrder = { "desaturate", "visibility", "glow", "border" }

local options = {
	desaturate = {
		name = "Desaturate",
		toggle = true,
		defaultEnabled = true,
	},
	visibility = {
		name = "Visibility",
		options = Constants.Visibility,
		optionsSorted = Constants.VisibilitySorted,
		defaultValue = "show",
	},
	glow = {
		name = "Show Glow",
		subregionType = "glow",
		defaultVisibility = "show",
	},
	border = {
		name = "Show Border",
		subregionType = "border",
		defaultVisibility = "show",
	},
}

local function GetUnusedStates(iconConfig)
	local states, statesSorted = {}, {}

	for _, stateValue in ipairs(Constants.StatesSorted) do
		if not iconConfig.usedStates[stateValue] then
			states[stateValue] = Constants.States[stateValue]
			tinsert(statesSorted, stateValue)
		end
	end

	return states, statesSorted
end

local function GetUsedStateTabs(iconConfig)
	local stateTabs = {}

	for _, stateValue in ipairs(iconConfig.selectedStates) do
		if iconConfig.usedStates[stateValue] then
			tinsert(stateTabs, { value = stateValue, text = Constants.States[stateValue] })
		end
	end

	return stateTabs
end

local function GetStateOptions(stateOptions, currentOption, includeRemove)
	local optionList, optionListSorted = {}, {}

	for _, optionKey in ipairs(optionOrder) do
		if optionKey == currentOption or not stateOptions[optionKey] then
			optionList[optionKey] = options[optionKey].name
			tinsert(optionListSorted, optionKey)
		end
	end

	if includeRemove then
		optionList[REMOVE_OPTION] = "Remove"
		tinsert(optionListSorted, REMOVE_OPTION)
	end

	return optionList, optionListSorted
end

local function SetDefaultOptionValues(stateOptions, optionKey)
	stateOptions[optionKey] = stateOptions[optionKey] or {}

	local option = options[optionKey]
	local optionValues = stateOptions[optionKey]
	if option.toggle then
		if optionValues.enabled == nil then
			optionValues.enabled = option.defaultEnabled
		end
	elseif option.subregionType then
		optionValues.visibility = optionValues.visibility or option.defaultVisibility
	else
		optionValues.value = optionValues.value or option.defaultValue
	end

	return optionValues
end

local function AddSelectedStateOption(stateTabs, state, stateOptions, selectedOptions, optionKey, optionIndex, subregionOptions)
	local option = options[optionKey]
	if not option then
		return
	end

	local optionDropdown = AceGUI:Create("Dropdown")
	optionDropdown:SetLabel("Option")
	optionDropdown:SetRelativeWidth(0.33)
	optionDropdown:SetList(GetStateOptions(stateOptions, optionKey, true))
	optionDropdown:SetValue(optionKey)
	optionDropdown:SetCallback("OnValueChanged", function(_, _, value)
		if value == REMOVE_OPTION then
			local removedOption = selectedOptions[optionIndex]
			if removedOption then
				tremove(selectedOptions, optionIndex)
				stateOptions[removedOption] = nil
			end
		elseif options[value] and not stateOptions[value] then
			local previousOption = selectedOptions[optionIndex]
			if previousOption ~= value then
				selectedOptions[optionIndex] = value
				stateOptions[previousOption] = nil
				SetDefaultOptionValues(stateOptions, value)
			end
		end

		stateTabs:SelectTab(state)
	end)
	stateTabs:AddChild(optionDropdown)

	local optionValues = SetDefaultOptionValues(stateOptions, optionKey)

	if option.toggle then
		local toggle = AceGUI:Create("CheckBox")
		toggle:SetRelativeWidth(0.66)
		toggle:SetLabel(option.name)
		toggle:SetValue(optionValues.enabled)
		toggle:SetCallback("OnValueChanged", function(_, _, value)
			optionValues.enabled = value
		end)
		stateTabs:AddChild(toggle)
	elseif option.subregionType then
		local subregions, subregionsSorted = {}, {}
		for index, subregionData in ipairs(subregionOptions and subregionOptions[option.subregionType] or {}) do
			subregions[index] = (Constants.Subregions[subregionData.type] or "Subregion") .. " " .. index
			tinsert(subregionsSorted, index)
		end

		local subregionDropdown = AceGUI:Create("Dropdown")
		subregionDropdown:SetLabel("Subregion")
		subregionDropdown:SetRelativeWidth(0.66)
		subregionDropdown:SetList(subregions, subregionsSorted)
		subregionDropdown:SetValue(optionValues.subregion)
		subregionDropdown:SetCallback("OnValueChanged", function(_, _, value)
			optionValues.subregion = value
		end)
		stateTabs:AddChild(subregionDropdown)
	else
		local valueDropdown = AceGUI:Create("Dropdown")
		valueDropdown:SetLabel(option.name)
		valueDropdown:SetRelativeWidth(0.66)
		valueDropdown:SetList(option.options, option.optionsSorted)
		valueDropdown:SetValue(optionValues.value)
		valueDropdown:SetCallback("OnValueChanged", function(_, _, value)
			optionValues.value = value
		end)
		stateTabs:AddChild(valueDropdown)
	end
end

local function AddStateOptions(state, stateTabs, iconConfig, stateDropdown)
	iconConfig.stateOptions[state] = iconConfig.stateOptions[state] or {}

	local stateOptions = iconConfig.stateOptions[state]
	stateOptions.selectedOptions = stateOptions.selectedOptions or {}

	local selectedOptions = stateOptions.selectedOptions
	local subregionOptions = iconConfig.subregionOptions

	for optionIndex, optionKey in ipairs(selectedOptions) do
		AddSelectedStateOption(stateTabs, state, stateOptions, selectedOptions, optionKey, optionIndex, subregionOptions)
	end

	local optionList, optionListSorted = GetStateOptions(stateOptions)
	if #optionListSorted > 0 then
		local optionDropdown = AceGUI:Create("Dropdown")
		optionDropdown:SetLabel("Add Option")
		optionDropdown:SetRelativeWidth(0.33)
		optionDropdown:SetList(optionList, optionListSorted)
		optionDropdown:SetCallback("OnValueChanged", function(_, _, value)
			if options[value] and not stateOptions[value] then
				tinsert(selectedOptions, value)
				SetDefaultOptionValues(stateOptions, value)
				stateTabs:SelectTab(state)
			end
		end)
		stateTabs:AddChild(optionDropdown)
	end

	local removeStateButton = AceGUI:Create("Button")
	removeStateButton:SetText("Remove")
	removeStateButton:SetRelativeWidth(1)
	removeStateButton:SetCallback("OnClick", function()
		iconConfig.usedStates[state] = nil
		iconConfig.stateOptions[state] = nil

		for stateIndex, stateValue in ipairs(iconConfig.selectedStates) do
			if stateValue == state then
				tremove(iconConfig.selectedStates, stateIndex)
				break
			end
		end

		stateDropdown:SetList(GetUnusedStates(iconConfig))
		local usedStateTabs = GetUsedStateTabs(iconConfig)
		stateTabs:SetTabs(usedStateTabs)

		if usedStateTabs[1] then
			stateTabs:SelectTab(usedStateTabs[1].value)
		else
			stateTabs:ReleaseChildren()
		end
	end)
	stateTabs:AddChild(removeStateButton)
end

function CDMOptions.CreateStateTabSettings(iconSettingsTabs, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
	if not isBuffBar then
		iconConfig.stateOptions = iconConfig.stateOptions or {}
		iconConfig.usedStates = iconConfig.usedStates or {}
		iconConfig.selectedStates = iconConfig.selectedStates or {}

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

		local selectedState
		local stateDropdown = AceGUI:Create("Dropdown")
		stateDropdown:SetLabel("State")
		stateDropdown:SetRelativeWidth(0.75)
		generalSettings:AddChild(stateDropdown)

		local addStateButton = AceGUI:Create("Button")
		addStateButton:SetText("Add")
		addStateButton:SetRelativeWidth(0.2)
		generalSettings:AddChild(addStateButton)

		stateDropdown:SetList(GetUnusedStates(iconConfig))
		stateDropdown:SetValue(selectedState)
		addStateButton:SetDisabled(selectedState == nil)

		stateDropdown:SetCallback("OnValueChanged", function(_, _, value)
			selectedState = value
			addStateButton:SetDisabled(value == nil)
		end)

		local stateTabs = AceGUI:Create("TabGroup")
		local usedStateTabs = GetUsedStateTabs(iconConfig)
		stateTabs:SetLayout("flow")
		stateTabs:SetFullWidth(true)
		stateTabs:SetTabs(usedStateTabs)
		stateTabs:SetCallback("OnGroupSelected", function(self, _, selectedTab)
			self:ReleaseChildren()
			if not selectedTab then
				return
			end
			AddStateOptions(selectedTab, self, iconConfig, stateDropdown)
		end)
		scrollFrame:AddChild(stateTabs)

		addStateButton:SetCallback("OnClick", function()
			if not selectedState or iconConfig.usedStates[selectedState] then
				return
			end

			iconConfig.usedStates[selectedState] = true
			iconConfig.stateOptions[selectedState] = iconConfig.stateOptions[selectedState] or {}
			tinsert(iconConfig.selectedStates, selectedState)

			stateTabs:SetTabs(GetUsedStateTabs(iconConfig))
			stateTabs:SelectTab(selectedState)
			selectedState = nil
			stateDropdown:SetValue(selectedState)
			stateDropdown:SetList(GetUnusedStates(iconConfig))
		end)

		if usedStateTabs[1] then
			stateTabs:SelectTab(usedStateTabs[1].value)
		end
	end
end
