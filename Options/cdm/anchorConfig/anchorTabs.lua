local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")

function CDMOptions.GetProfileAnchorConfig(options, data, anchorIndex, isBuffBar)
	local config
	if isBuffBar then
		options.buffBarsAnchorConfig = options.buffBarsAnchorConfig or {}
		config = options.buffBarsAnchorConfig[anchorIndex]
	else
		options.anchorConfig = options.anchorConfig or {}
		config = options.anchorConfig[anchorIndex]
	end

	if not config then
		config = CopyTable(data)
	end

	if isBuffBar then
		options.buffBarsAnchorConfig[anchorIndex] = config
	else
		options.anchorConfig[anchorIndex] = config
	end

	return config
end

function CDMOptions.SelectAnchor(widget, parentWidget, anchorIndex, anchorTabsTbl, mode)
	widget:ReleaseChildren()

	SCM.activeAnchorSettings = anchorIndex
	local options = SCM.db.profile.options
	local isGlobal = mode == "global"
	local isBuffBar = mode == "buffbars"
	local isProfileConfig = false

	if options.showAnchorHighlight then
		for group, anchorFrame in pairs(SCM.anchorFrames) do
			local activeGroup = Options.GetEffectiveAnchorGroup(anchorIndex, mode)
			if group == activeGroup then
				Options.SetAnchorHighlight(anchorFrame, "active", { 0.34, 0.70, 0.91, 1 })
			else
				Options.SetAnchorHighlight(anchorFrame, "default")
			end
		end
	end

	local sourceData = (isGlobal and SCM.globalAnchorConfig[anchorIndex]) or (isBuffBar and SCM.buffBarsAnchorConfig[anchorIndex]) or SCM.anchorConfig[anchorIndex]
	if not sourceData then
		return
	end

	local data = sourceData

	if not isGlobal and sourceData.useGlobalProfileConfig then
		data = CDMOptions.GetProfileAnchorConfig(options, data, anchorIndex, isBuffBar)
		isProfileConfig = true
	end

	local anchorName = data.anchorName
	if anchorTabsTbl[anchorIndex].text ~= anchorName then
		anchorTabsTbl[anchorIndex].text = anchorName or ("Anchor " .. anchorIndex)
		widget:SetTabs(anchorTabsTbl)
	end

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	widget:AddChild(scrollFrame)

	local anchorOptions = AceGUI:Create("InlineGroup")
	anchorOptions:SetLayout("flow")
	anchorOptions:SetFullWidth(true)
	anchorOptions:SetFullHeight(true)
	anchorOptions:SetTitle("Anchor Options")
	scrollFrame:AddChild(anchorOptions)

	local buttonGroup = AceGUI:Create("SimpleGroup")
	buttonGroup:SetFullWidth(true)
	buttonGroup:SetLayout("flow")
	anchorOptions:AddChild(buttonGroup)

	local anchorButtonWidth = isGlobal and 0.33 or 0.25
	local addAnchorButton = AceGUI:Create("Button")
	addAnchorButton:SetText("Add Anchor")
	addAnchorButton:SetRelativeWidth(anchorButtonWidth)
	addAnchorButton:SetDisabled(#anchorTabsTbl >= 15)
	addAnchorButton:SetCallback("OnClick", function()
		local nextIndex = (isGlobal and SCM:AddGlobalAnchor(anchorTabsTbl)) or (isBuffBar and SCM:AddBuffBarAnchor(anchorTabsTbl)) or SCM:AddAnchor(anchorTabsTbl)
		Options.ApplyModeConfigUpdate(nextIndex, mode)
		widget:SetTabs(anchorTabsTbl)
		widget:SelectTab(nextIndex)
	end)
	buttonGroup:AddChild(addAnchorButton)

	local deleteAnchorButton = AceGUI:Create("Button")
	deleteAnchorButton:SetText("Delete Anchor")
	deleteAnchorButton:SetRelativeWidth(anchorButtonWidth)
	deleteAnchorButton:SetDisabled(((isGlobal or isBuffBar) and anchorIndex == 1) or (not isGlobal and not isBuffBar and anchorIndex <= 3))
	deleteAnchorButton:SetCallback("OnClick", function()
		if isGlobal then
			SCM:RemoveGlobalAnchor(anchorIndex, anchorTabsTbl)
		elseif isBuffBar then
			SCM:RemoveBuffBarAnchor(anchorIndex, anchorTabsTbl)
		else
			SCM:RemoveAnchor(anchorIndex, anchorTabsTbl)
		end
		widget:SetTabs(anchorTabsTbl)
		widget:SelectTab(#anchorTabsTbl)
	end)
	buttonGroup:AddChild(deleteAnchorButton)

	local renameAnchorButton = AceGUI:Create("Button")
	renameAnchorButton:SetText("Rename Anchor")
	renameAnchorButton:SetRelativeWidth(anchorButtonWidth)
	renameAnchorButton:SetDisabled(#anchorTabsTbl >= 15)
	renameAnchorButton:SetCallback("OnClick", function()
		StaticPopup_Show("SCM_RENAME_ANCHOR", nil, nil, {
			callback = function(anchorName)
				data.anchorName = anchorName
				anchorTabsTbl[anchorIndex].text = anchorName
				widget:SetTabs(anchorTabsTbl)
				widget:SelectTab(anchorIndex)
			end,
		})
	end)
	buttonGroup:AddChild(renameAnchorButton)

	if not isGlobal then
		local useGlobalProfileConfig = AceGUI:Create("CheckBox")
		useGlobalProfileConfig:SetLabel("Use Profile Config")
		useGlobalProfileConfig:SetRelativeWidth(anchorButtonWidth)
		useGlobalProfileConfig:SetValue(sourceData.useGlobalProfileConfig or false)
		useGlobalProfileConfig:SetCallback("OnValueChanged", function(_, _, value)
			sourceData.useGlobalProfileConfig = value
			if value then
				CDMOptions.GetProfileAnchorConfig(options, data, anchorIndex, isBuffBar)
			end
			Options.ApplyModeConfigUpdate(anchorIndex, mode)

			widget:SelectTab(anchorIndex)
		end)
		useGlobalProfileConfig:SetCallback("OnEnter", function(self)
			GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
			GameTooltip:SetText("Use Profile Config", nil, nil, nil, nil, true)
			GameTooltip:AddLine("This will use the anchor config for that anchor that is shared by all specs.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		useGlobalProfileConfig:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
		buttonGroup:AddChild(useGlobalProfileConfig)
	end

	local point = AceGUI:Create("Dropdown")
	point:SetRelativeWidth(isBuffBar and 0.25 or 0.33)
	point:SetLabel("Point")
	point:SetList(SCM.Constants.AnchorPoints)
	point:SetValue(data.anchor[1])
	point:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[1] = value
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(point)

	local relativeTo = AceGUI:Create("EditBox")
	relativeTo:SetRelativeWidth(isBuffBar and 0.25 or 0.33)
	relativeTo:SetLabel("Anchor Frame")
	relativeTo:SetText(data.anchor[2])
	relativeTo:SetCallback("OnEnterPressed", function(self, event, text)
		data.anchor[2] = text
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(relativeTo)
	Options.AddAnchorParentAutocomplete(anchorOptions, relativeTo, function(text) data.anchor[2] = text Options.ApplyModeConfigUpdate(anchorIndex, mode) end)

	local relativePoint = AceGUI:Create("Dropdown")
	relativePoint:SetRelativeWidth(isBuffBar and 0.25 or 0.33)
	relativePoint:SetLabel("Relative Point")
	relativePoint:SetList(SCM.Constants.AnchorPoints)
	relativePoint:SetValue(data.anchor[3])
	relativePoint:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[3] = value
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(relativePoint)

	if isBuffBar then
		local matchAnchorWidth = AceGUI:Create("CheckBox")
		matchAnchorWidth:SetLabel("Match Parent Width")
		matchAnchorWidth:SetRelativeWidth(0.25)
		matchAnchorWidth:SetValue(data.matchAnchorWidth or false)
		matchAnchorWidth:SetCallback("OnValueChanged", function(_, _, value)
			data.matchAnchorWidth = value
			Options.ApplyModeConfigUpdate(anchorIndex, mode)
			widget:SelectTab(anchorIndex)
		end)
		anchorOptions:AddChild(matchAnchorWidth)
	end

	local grow = AceGUI:Create("Dropdown")
	grow:SetRelativeWidth(0.25)
	grow:SetList(SCM.Constants.GrowthDirections)
	grow:SetLabel("Primary Growth")
	grow:SetValue(data.grow or "CENTERED")
	grow:SetCallback("OnValueChanged", function(self, event, value)
		data.grow = value
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(grow)

	local secondaryGrow = AceGUI:Create("Dropdown")
	secondaryGrow:SetRelativeWidth(0.25)
	secondaryGrow:SetList(SCM.Constants.SecondaryGrowthDirections)
	secondaryGrow:SetLabel("Secondary Growth")
	secondaryGrow:SetValue(data.secondaryGrow or "DOWN")
	secondaryGrow:SetCallback("OnValueChanged", function(self, event, value)
		data.secondaryGrow = value
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(secondaryGrow)

	local spacing = AceGUI:Create("Slider")
	spacing:SetRelativeWidth(0.25)
	spacing:SetSliderValues(-10, 50, 0.1)
	spacing:SetLabel("Spacing")
	spacing:SetValue(data.spacing or 0)
	spacing:SetCallback("OnValueChanged", function(self, event, value)
		data.spacing = value
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(spacing)

	local frameStrata = AceGUI:Create("Dropdown")
	frameStrata:SetRelativeWidth(0.25)
	frameStrata:SetList(SCM.Constants.FrameStrata, SCM.Constants.FrameStrataSorted)
	frameStrata:SetLabel("Frame Strata")
	frameStrata:SetValue(data.frameStrata or "")
	frameStrata:SetCallback("OnValueChanged", function(self, event, value)
		data.frameStrata = value ~= "" and value or nil
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(frameStrata)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetSliderValues(-1000, 1000, 0.1)
	xOffset:SetLabel("X Offset")
	xOffset:SetValue(data.anchor[4])
	xOffset:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[4] = value
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.5)
	yOffset:SetSliderValues(-1000, 1000, 0.1)
	yOffset:SetLabel("Y Offset")
	yOffset:SetValue(data.anchor[5])
	yOffset:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[5] = value
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(yOffset)

	local advancedConfigTabs = AceGUI:Create("TabGroup")
	advancedConfigTabs:SetLayout("flow")
	advancedConfigTabs:SetFullWidth(true)
	advancedConfigTabs:SetHeight(280)
	advancedConfigTabs:SetTabs({ { value = "spellConfig", text = "Spell Config" }, { value = "rowConfig", text = "Row Config" } })
	advancedConfigTabs:SetCallback("OnGroupSelected", function(self, _, configType)
		self:ReleaseChildren()

		if configType == "rowConfig" then
			CDMOptions.CreateRowConfig(self, anchorOptions, widget, parentWidget, scrollFrame, data, anchorIndex, mode, options, isProfileConfig)
		elseif configType == "spellConfig" then
			CDMOptions.CreateSpellConfig(self, anchorOptions, widget, parentWidget, scrollFrame, data, anchorIndex, mode, options, isProfileConfig)
		end
		anchorOptions:DoLayout()
	end)
	anchorOptions:AddChild(advancedConfigTabs)
	advancedConfigTabs:SelectTab("spellConfig")

	scrollFrame:DoLayout()
	--scrollFrame:FixScroll()
	--scrollFrame:SetScroll(0)
end
