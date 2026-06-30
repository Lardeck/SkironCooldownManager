local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")

local function AddIconColorOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig,
								   anchorIndex, mode, isGlobal, isBuffBar)
	local options = SCM.db.profile.options

	if buttonData.isCustom or buttonFrame.data.isBuffIcon then
		local notsureyetOptions = AceGUI:Create("InlineGroup")
		notsureyetOptions:SetLayout("flow")
		notsureyetOptions:SetFullWidth(true)
		notsureyetOptions:SetTitle("Not sure yet")
		iconSettingsTabs:AddChild(notsureyetOptions)

		if buttonFrame.data.isBuffIcon then
			local desaturate = AceGUI:Create("CheckBox")
			desaturate:SetLabel("Desaturate While Inactive")
			desaturate:SetRelativeWidth(0.5)
			desaturate:SetValue(buttonConfig.desaturate)
			desaturate:SetDisabled(not buttonConfig.alwaysShow and not buttonConfig.showWhileInactive)
			SCM.Utils.SetDisabledTooltip(desaturate, "Enable 'Show Always' first.")
			desaturate:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.desaturate = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			notsureyetOptions:AddChild(desaturate)
		elseif buttonData.isCustom and buttonData.iconType ~= "timer" then
			if buttonData.iconType == "spell" then
				local showNotUsable = AceGUI:Create("CheckBox")
				showNotUsable:SetLabel("Show Not Usable")
				showNotUsable:SetRelativeWidth(0.5)
				showNotUsable:SetValue(buttonConfig.showNotUsable)
				showNotUsable:SetCallback("OnValueChanged", function(self, event, value)
					buttonConfig.showNotUsable = value or nil
					CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
				end)
				notsureyetOptions:AddChild(showNotUsable)

				local showOutOfRange = AceGUI:Create("CheckBox")
				showOutOfRange:SetLabel("Show Out Of Range")
				showOutOfRange:SetRelativeWidth(0.5)
				showOutOfRange:SetValue(buttonConfig.showOutOfRange)
				showOutOfRange:SetCallback("OnValueChanged", function(self, event, value)
					buttonConfig.showOutOfRange = value
					C_Spell.EnableSpellRangeCheck(buttonData.spellID, value)
					CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
				end)
				notsureyetOptions:AddChild(showOutOfRange)
			end
		end
	end
end

local function AddIconTextOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig,
								  anchorIndex, mode, isGlobal, isBuffBar)
	if buttonData.isCustom and (buttonData.iconType == "item" or buttonData.iconType == "spell") then
		local textOptions = AceGUI:Create("InlineGroup")
		textOptions:SetLayout("flow")
		textOptions:SetFullWidth(true)
		textOptions:SetTitle("Text")
		iconSettingsTabs:AddChild(textOptions)

		if buttonData.iconType == "item" then
			local showCraftQuality = AceGUI:Create("CheckBox")
			showCraftQuality:SetLabel("Show Craft Quality")
			showCraftQuality:SetRelativeWidth(0.5)
			showCraftQuality:SetValue(buttonConfig.showCraftQuality)
			showCraftQuality:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.showCraftQuality = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			textOptions:AddChild(showCraftQuality)

			local hideStackInCombat -- Define local earlier so that hideStackText toggle can disable it later

			local hideStackText = AceGUI:Create("CheckBox")
			hideStackText:SetLabel("Hide Count")
			hideStackText:SetRelativeWidth(0.5)
			hideStackText:SetValue(buttonConfig.hideStackText)
			hideStackText:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.hideStackText = value or nil
				hideStackInCombat:SetDisabled(value)
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			textOptions:AddChild(hideStackText)

			-- hideStackInCombat toggle
			hideStackInCombat = AceGUI:Create("CheckBox")
			hideStackInCombat:SetLabel("Hide Count In Combat")
			hideStackInCombat:SetRelativeWidth(0.5)
			hideStackInCombat:SetValue(buttonConfig.hideStackInCombat)
			hideStackInCombat:SetDisabled(buttonConfig.hideStackText)
			hideStackInCombat:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.hideStackInCombat = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			textOptions:AddChild(hideStackInCombat)
		elseif buttonData.iconType == "spell" then
			local forceShowCharges = AceGUI:Create("CheckBox")
			forceShowCharges:SetLabel("Force Show Charges")
			forceShowCharges:SetRelativeWidth(0.5)
			forceShowCharges:SetValue(buttonConfig.forceShowCharges)
			forceShowCharges:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.forceShowCharges = value
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			textOptions:AddChild(forceShowCharges)
		end
	end
end

function CDMOptions.CreateDisplayTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData,
											 iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
	AddIconColorOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex,
		mode, isGlobal, isBuffBar)
	AddIconTextOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex,
		mode, isGlobal, isBuffBar)
end
