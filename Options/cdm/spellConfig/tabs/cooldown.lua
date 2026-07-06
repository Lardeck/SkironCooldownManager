local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

function CDMOptions.CreateCooldownTabSettings(iconSettingsTabs, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
	if not isBuffBar then
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
		generalSettings:SetTitle("General")
		scrollFrame:AddChild(generalSettings)

		if buttonData.isCustom then
			local showGCD = AceGUI:Create("CheckBox")
			showGCD:SetLabel("Show GCD")
			showGCD:SetRelativeWidth(0.5)
			showGCD:SetValue(iconConfig.showGCD)
			showGCD:SetCallback("OnValueChanged", function(self, event, value)
				iconConfig.showGCD = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			generalSettings:AddChild(showGCD)
		else
			local forceActiveSwipe = AceGUI:Create("CheckBox")
			forceActiveSwipe:SetLabel("Force Active Swipe")
			forceActiveSwipe:SetRelativeWidth(0.5)
			forceActiveSwipe:SetValue(iconConfig.forceActiveSwipe)
			forceActiveSwipe:SetCallback("OnValueChanged", function(_, _, value)
				iconConfig.forceActiveSwipe = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			generalSettings:AddChild(forceActiveSwipe)

			local hideActiveSwipe = AceGUI:Create("CheckBox")
			hideActiveSwipe:SetLabel("Hide Active Swipe")
			hideActiveSwipe:SetRelativeWidth(0.5)
			hideActiveSwipe:SetValue(iconConfig.hideActiveSwipe)
			hideActiveSwipe:SetCallback("OnValueChanged", function(_, _, value)
				iconConfig.hideActiveSwipe = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			generalSettings:AddChild(hideActiveSwipe)
		end

		local textSettings = AceGUI:Create("InlineGroup")
		textSettings:SetLayout("flow")
		textSettings:SetFullWidth(true)
		textSettings:SetTitle("Text")
		scrollFrame:AddChild(textSettings)

		local hideCountdownNumbers = AceGUI:Create("CheckBox")
		hideCountdownNumbers:SetRelativeWidth(0.5)
		hideCountdownNumbers:SetValue(iconConfig.hideCountdownNumbers)
		hideCountdownNumbers:SetLabel("Hide Timer Text")
		hideCountdownNumbers:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.hideCountdownNumbers = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)
		textSettings:AddChild(hideCountdownNumbers)

		local cooldownOverrideGlobal = AceGUI:Create("CheckBox")
		cooldownOverrideGlobal:SetRelativeWidth(0.5)
		cooldownOverrideGlobal:SetValue(iconConfig.cooldownOverrideGlobal)
		cooldownOverrideGlobal:SetLabel("Override Global")
		textSettings:AddChild(cooldownOverrideGlobal)

		local cooldownFont = AceGUI:Create("LSM30_Font")
		cooldownFont:SetLabel("Font")
		cooldownFont:SetRelativeWidth(0.33)
		cooldownFont:SetList(LSM:HashTable("font"))
		cooldownFont:SetValue(iconConfig.cooldownFont)
		cooldownFont:SetDisabled(not iconConfig.cooldownOverrideGlobal)
		cooldownFont:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.cooldownFont = value
			self:SetValue(value)
			SCM:ApplyAllCDManagerConfigs()
		end)
		textSettings:AddChild(cooldownFont)

		local cooldownFontSize = AceGUI:Create("Slider")
		cooldownFontSize:SetRelativeWidth(0.33)
		cooldownFontSize:SetLabel("Font Size")
		cooldownFontSize:SetSliderValues(0.1, 1, 0.01)
		cooldownFontSize:SetIsPercent(true)
		cooldownFontSize:SetValue(iconConfig.cooldownFontSize or 0.6)
		cooldownFontSize:SetDisabled(not iconConfig.cooldownOverrideGlobal)
		cooldownFontSize:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.cooldownFontSize = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		textSettings:AddChild(cooldownFontSize)

		local cooldownFontOutline = AceGUI:Create("Dropdown")
		cooldownFontOutline:SetRelativeWidth(0.33)
		cooldownFontOutline:SetLabel("Outline")
		cooldownFontOutline:SetList(SCM.Constants.TextOutline, SCM.Constants.TextOutlineSorted)
		cooldownFontOutline:SetValue(iconConfig.cooldownFontOutline or "OUTLINE")
		cooldownFontOutline:SetDisabled(not iconConfig.cooldownOverrideGlobal)
		cooldownFontOutline:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownFontOutline = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		textSettings:AddChild(cooldownFontOutline)

		local cooldownTextPoint = AceGUI:Create("Dropdown")
		cooldownTextPoint:SetRelativeWidth(0.5)
		cooldownTextPoint:SetLabel("Point")
		cooldownTextPoint:SetList(SCM.Constants.AnchorPoints)
		cooldownTextPoint:SetDisabled(not iconConfig.cooldownOverrideGlobal)
		cooldownTextPoint:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownTextPoint = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		if iconConfig.cooldownTextPoint then
			cooldownTextPoint:SetValue(iconConfig.cooldownTextPoint)
		end
		textSettings:AddChild(cooldownTextPoint)

		local cooldownTextRelativePoint = AceGUI:Create("Dropdown")
		cooldownTextRelativePoint:SetRelativeWidth(0.5)
		cooldownTextRelativePoint:SetLabel("Relative Point")
		cooldownTextRelativePoint:SetList(SCM.Constants.AnchorPoints)
		cooldownTextRelativePoint:SetValue(iconConfig.cooldownTextRelativePoint)
		cooldownTextRelativePoint:SetDisabled(not iconConfig.cooldownOverrideGlobal)
		cooldownTextRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownTextRelativePoint = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		textSettings:AddChild(cooldownTextRelativePoint)

		local cooldownXOffsetText = AceGUI:Create("Slider")
		cooldownXOffsetText:SetRelativeWidth(0.5)
		cooldownXOffsetText:SetSliderValues(-50, 50, 0.1)
		cooldownXOffsetText:SetLabel("X Offset")
		cooldownXOffsetText:SetValue(iconConfig.cooldownTextYOffset or 0)
		cooldownXOffsetText:SetDisabled(not iconConfig.cooldownOverrideGlobal)
		cooldownXOffsetText:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownTextXOffset = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		textSettings:AddChild(cooldownXOffsetText)

		local cooldownYOffsetText = AceGUI:Create("Slider")
		cooldownYOffsetText:SetRelativeWidth(0.5)
		cooldownYOffsetText:SetSliderValues(-50, 50, 0.1)
		cooldownYOffsetText:SetLabel("Y Offset")
		cooldownYOffsetText:SetValue(iconConfig.cooldownTextYOffset or 0)
		cooldownYOffsetText:SetDisabled(not iconConfig.cooldownOverrideGlobal)
		cooldownYOffsetText:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownTextYOffset = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		textSettings:AddChild(cooldownYOffsetText)

		cooldownOverrideGlobal:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.cooldownOverrideGlobal = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)

			cooldownFont:SetDisabled(not value)
			cooldownFontSize:SetDisabled(not value)
			cooldownFontOutline:SetDisabled(not value)
			cooldownTextPoint:SetDisabled(not value)
			cooldownTextRelativePoint:SetDisabled(not value)
			cooldownXOffsetText:SetDisabled(not value)
			cooldownYOffsetText:SetDisabled(not value)
		end)

		local positionSettings = AceGUI:Create("InlineGroup")
		positionSettings:SetLayout("flow")
		positionSettings:SetFullWidth(true)
		positionSettings:SetTitle("Position")
		scrollFrame:AddChild(positionSettings)

		local cooldownMoveTL = AceGUI:Create("CheckBox")
		cooldownMoveTL:SetRelativeWidth(0.33)
		cooldownMoveTL:SetValue(iconConfig.cooldownMoveTL)
		cooldownMoveTL:SetLabel("Offset TOPLEFT")
		positionSettings:AddChild(cooldownMoveTL)

		local cooldownXOffsetTL = AceGUI:Create("Slider")
		cooldownXOffsetTL:SetRelativeWidth(0.33)
		cooldownXOffsetTL:SetSliderValues(-50, 50, 0.1)
		cooldownXOffsetTL:SetLabel("X Offset TOPLEFT")
		cooldownXOffsetTL:SetValue(iconConfig.cooldownXOffsetTL or 0)
		cooldownXOffsetTL:SetDisabled(not iconConfig.cooldownMoveTL)
		cooldownXOffsetTL:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownXOffsetTL = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		positionSettings:AddChild(cooldownXOffsetTL)

		local cooldownYOffsetTL = AceGUI:Create("Slider")
		cooldownYOffsetTL:SetRelativeWidth(0.33)
		cooldownYOffsetTL:SetSliderValues(-50, 50, 0.1)
		cooldownYOffsetTL:SetLabel("Y Offset TOPLEFT")
		cooldownYOffsetTL:SetValue(iconConfig.cooldownYOffsetTL or 0)
		cooldownYOffsetTL:SetDisabled(not iconConfig.cooldownMoveTL)
		cooldownYOffsetTL:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownYOffsetTL = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		positionSettings:AddChild(cooldownYOffsetTL)

		cooldownMoveTL:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.cooldownMoveTL = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)

			cooldownXOffsetTL:SetDisabled(not value)
			cooldownYOffsetTL:SetDisabled(not value)
		end)

		local cooldownMoveBR = AceGUI:Create("CheckBox")
		cooldownMoveBR:SetRelativeWidth(0.33)
		cooldownMoveBR:SetValue(iconConfig.cooldownMoveBR)
		cooldownMoveBR:SetLabel("Offset BOTTOMRIGHT")
		positionSettings:AddChild(cooldownMoveBR)

		local cooldownXOffsetBR = AceGUI:Create("Slider")
		cooldownXOffsetBR:SetRelativeWidth(0.33)
		cooldownXOffsetBR:SetSliderValues(-50, 50, 0.1)
		cooldownXOffsetBR:SetLabel("X Offset BOTTOMRIGHT")
		cooldownXOffsetBR:SetValue(iconConfig.cooldownXOffsetBR or -SCM:PixelPerfectSize(1))
		cooldownXOffsetBR:SetDisabled(not iconConfig.cooldownMoveBR)
		cooldownXOffsetBR:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownXOffsetBR = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		positionSettings:AddChild(cooldownXOffsetBR)

		local cooldownYOffsetBR = AceGUI:Create("Slider")
		cooldownYOffsetBR:SetRelativeWidth(0.33)
		cooldownYOffsetBR:SetSliderValues(-50, 50, 0.1)
		cooldownYOffsetBR:SetLabel("Y Offset BOTTOMRIGHT")
		cooldownYOffsetBR:SetValue(iconConfig.cooldownYOffsetBR or SCM:PixelPerfectSize(1))
		cooldownYOffsetBR:SetDisabled(not iconConfig.cooldownMoveBR)
		cooldownYOffsetBR:SetCallback("OnValueChanged", function(_, _, value)
			iconConfig.cooldownYOffsetBR = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		positionSettings:AddChild(cooldownYOffsetBR)

		cooldownMoveBR:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.cooldownMoveBR = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)

			cooldownXOffsetBR:SetDisabled(not value)
			cooldownYOffsetBR:SetDisabled(not value)
		end)
		scrollFrame:DoLayout()
	end
end
