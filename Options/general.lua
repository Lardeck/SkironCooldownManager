local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local LibEditModeOverride = LibStub("LibEditModeOverride-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LibWindow = LibStub("LibWindow-1.1")

SCM.MainTabs.General = { value = "General", text = "Global Settings", order = 1, subgroups = {} }

local function AddInfoText(widget, text)
	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText(string.format("|TInterface\\common\\help-i:40:40:0:0|t%s.", text))
	label:SetFontObject("Game12Font")
	widget:AddChild(label)
end

local function AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.33)
	xOffset:SetValue(glowTypeOptions.xOffset or 0)
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(-30, 30, 0.1)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		glowTypeOptions.xOffset = value
	end)
	dynamicGlowSettingsGroup:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.33)
	yOffset:SetValue(glowTypeOptions.yOffset or 0)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-30, 30, 0.1)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		glowTypeOptions.yOffset = value
	end)
	dynamicGlowSettingsGroup:AddChild(yOffset)
end

local function AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)
	local glowColor = AceGUI:Create("ColorPicker")
	glowColor:SetRelativeWidth(0.33)
	glowColor:SetLabel("Glow Color")
	glowColor:SetHasAlpha(true)
	glowColor:SetColor(unpack(glowTypeOptions.glowColor))
	glowColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		glowTypeOptions.glowColor = { r, g, b, a }
	end)
	dynamicGlowSettingsGroup:AddChild(glowColor)
end

local function AddCustomGlowOptions(dynamicGlowSettingsGroup, glowTypeOptions, glowType)
	dynamicGlowSettingsGroup:ReleaseChildren()

	if glowType == "Proc" then
		local startAnim = AceGUI:Create("CheckBox")
		startAnim:SetRelativeWidth(0.33)
		startAnim:SetValue(glowTypeOptions.startAnim)
		startAnim:SetLabel("Start Animation")
		startAnim:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.startAnim = value
		end)
		dynamicGlowSettingsGroup:AddChild(startAnim)

		AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)
	elseif glowType == "Autocast" then
		--color,numParticles,frequency,scale,xOffset,yOffset

		local numParticles = AceGUI:Create("Slider")
		numParticles:SetRelativeWidth(0.33)
		numParticles:SetValue(glowTypeOptions.numParticles or 4)
		numParticles:SetLabel("Particles")
		numParticles:SetSliderValues(1, 30, 1)
		numParticles:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.numParticles = value
		end)
		dynamicGlowSettingsGroup:AddChild(numParticles)

		local frequency = AceGUI:Create("Slider")
		frequency:SetRelativeWidth(0.33)
		frequency:SetValue(glowTypeOptions.frequency or 0.125)
		frequency:SetLabel("Frequency")
		frequency:SetSliderValues(-3, 3, 0.05)
		frequency:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.frequency = value
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
		end)
		dynamicGlowSettingsGroup:AddChild(scale)

		AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)
	elseif glowType == "Pixel" then
		--color,numLines,frequency,length,thickness,xOffset,yOffset,border

		local numLines = AceGUI:Create("Slider")
		numLines:SetRelativeWidth(0.33)
		numLines:SetValue(glowTypeOptions.numLines or 8)
		numLines:SetLabel("Lines")
		numLines:SetSliderValues(1, 30, 1)
		numLines:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.numLines = value
		end)
		dynamicGlowSettingsGroup:AddChild(numLines)

		local frequency = AceGUI:Create("Slider")
		frequency:SetRelativeWidth(0.33)
		frequency:SetValue(glowTypeOptions.frequency or 0.25)
		frequency:SetLabel("Frequency")
		frequency:SetSliderValues(-3, 3, 0.05)
		frequency:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.frequency = value
		end)
		dynamicGlowSettingsGroup:AddChild(frequency)

		local length = AceGUI:Create("Slider")
		length:SetRelativeWidth(0.33)
		length:SetValue(glowTypeOptions.length or 2)
		length:SetLabel("Length")
		length:SetSliderValues(1, 15, 0.05)
		length:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.length = value
		end)
		dynamicGlowSettingsGroup:AddChild(length)

		local thickness = AceGUI:Create("Slider")
		thickness:SetRelativeWidth(0.33)
		thickness:SetValue(glowTypeOptions.thickness or 2)
		thickness:SetLabel("Thickness")
		thickness:SetSliderValues(1, 15, 0.05)
		thickness:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.thickness = value
		end)
		dynamicGlowSettingsGroup:AddChild(thickness)

		AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)

		local border = AceGUI:Create("CheckBox")
		border:SetRelativeWidth(0.33)
		border:SetValue(glowTypeOptions.border)
		border:SetLabel("Border")
		border:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.border = value
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
		end)
		dynamicGlowSettingsGroup:AddChild(frequency)

		AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)
	end
end

local function GetCooldownBreakpointComponents(displayStyle, minValue)
	if displayStyle == "clock" then
		if minValue >= 86400 then
			return {
				{ div = 86400 },
				{ div = 3600, mod = 24 },
			}
		elseif minValue >= 3600 then
			return {
				{ div = 3600 },
				{ div = 60, mod = 60 },
			}
		else
			return {
				{ div = 60 },
				{ mod = 60 },
			}
		end
	elseif displayStyle == "minutes" then
		return {
			{ div = 60 },
		}
	elseif displayStyle == "hours" then
		return {
			{ div = 3600 },
		}
	elseif displayStyle == "days" then
		return {
			{ div = 86400 },
		}
	end
end

local function SelectGlobalSettingsTab(tabWidget, scrollFrame, group, options)
	tabWidget:ReleaseChildren()

	if group == "General" then
		local skinningSettings = AceGUI:Create("InlineGroup")
		skinningSettings:SetLayout("flow")
		skinningSettings:SetFullWidth(true)
		skinningSettings:SetTitle("General")
		tabWidget:AddChild(skinningSettings)

		local enableSkinning = AceGUI:Create("CheckBox")
		enableSkinning:SetRelativeWidth(0.33)
		enableSkinning:SetLabel("Enable Skinning")
		enableSkinning:SetValue(options.enableSkinning)
		enableSkinning:SetCallback("OnValueChanged", function(_, _, value)
			options.enableSkinning = value
		end)
		skinningSettings:AddChild(enableSkinning)

		local showAnchorHighlight = AceGUI:Create("CheckBox")
		showAnchorHighlight:SetValue(options.showAnchorHighlight)
		showAnchorHighlight:SetRelativeWidth(0.33)
		showAnchorHighlight:SetLabel("Show Anchor Highlight")
		showAnchorHighlight:SetCallback("OnValueChanged", function(self, event, value)
			options.showAnchorHighlight = value
			if value and SCM.OptionsFrame then
				for _, anchorFrame in pairs(SCM.anchorFrames) do
					anchorFrame.debugTexture:Show()
					anchorFrame.debugText:Show()
				end
			else
				for _, anchorFrame in pairs(SCM.anchorFrames) do
					anchorFrame.debugTexture:Hide()
					anchorFrame.debugText:Hide()
				end
			end
		end)
		skinningSettings:AddChild(showAnchorHighlight)

		local savePosition = AceGUI:Create("CheckBox")
		savePosition:SetRelativeWidth(0.33)
		savePosition:SetLabel("Save Option Window Position")
		savePosition:SetValue(options.savePosition)
		savePosition:SetCallback("OnValueChanged", function(_, _, value)
			options.savePosition = value
		end)
		skinningSettings:AddChild(savePosition)

		local menuScale = AceGUI:Create("Slider")
		menuScale:SetRelativeWidth(0.5)
		menuScale:SetLabel("Options Scale")
		menuScale:SetSliderValues(0.5, 2, 0.1)
		menuScale:SetValue(options.menuScale)
		menuScale:SetCallback("OnMouseUp", function(_, _, value)
			options.menuScale = value
			LibWindow.SetScale(SCM.OptionsFrame.frame, value)
		end)
		skinningSettings:AddChild(menuScale)

		local resetPosition = AceGUI:Create("Button")
		resetPosition:SetRelativeWidth(0.5)
		resetPosition:SetText("Reset Position")
		resetPosition:SetCallback("OnClick", function()
			options.optionsWindow.x = 0
			options.optionsWindow.y = 0
			options.optionsWindow.point = "CENTER"
			LibWindow.RestorePosition(SCM.OptionsFrame.frame)
		end)
		skinningSettings:AddChild(resetPosition)

		local visibilitySettings = AceGUI:Create("InlineGroup")
		visibilitySettings:SetLayout("flow")
		visibilitySettings:SetFullWidth(true)
		visibilitySettings:SetTitle("Visibility")
		tabWidget:AddChild(visibilitySettings)

		local hideWhileMounted = AceGUI:Create("CheckBox")
		hideWhileMounted:SetRelativeWidth(0.33)
		hideWhileMounted:SetLabel("Hide While Mounted")
		hideWhileMounted:SetValue(options.hideWhileMounted)
		hideWhileMounted:SetDisabled(options.useCustomVisibilityCondition)
		hideWhileMounted:SetCallback("OnValueChanged", function(_, _, value)
			options.hideWhileMounted = value

			SCM:ApplyAttributeDriver(value)
			SCM:CreateAllCustomIcons()
		end)
		visibilitySettings:AddChild(hideWhileMounted)

		local hideWhileDead = AceGUI:Create("CheckBox")
		hideWhileDead:SetRelativeWidth(0.33)
		hideWhileDead:SetLabel("Hide While Dead")
		hideWhileDead:SetValue(options.hideWhileDead)
		hideWhileDead:SetDisabled(options.useCustomVisibilityCondition)
		hideWhileDead:SetCallback("OnValueChanged", function(_, _, value)
			options.hideWhileDead = value

			SCM:ApplyAttributeDriver()
			SCM:CreateAllCustomIcons()
		end)
		visibilitySettings:AddChild(hideWhileDead)

		local hideWhileInVehicle = AceGUI:Create("CheckBox")
		hideWhileInVehicle:SetRelativeWidth(0.33)
		hideWhileInVehicle:SetLabel("Hide While In Vehicle")
		hideWhileInVehicle:SetValue(options.hideWhileInVehicle)
		hideWhileInVehicle:SetDisabled(options.useCustomVisibilityCondition)
		hideWhileInVehicle:SetCallback("OnValueChanged", function(_, _, value)
			options.hideWhileInVehicle = value

			SCM:ApplyAttributeDriver()
			SCM:CreateAllCustomIcons()
		end)
		visibilitySettings:AddChild(hideWhileInVehicle)

		local hideWhileResting = AceGUI:Create("CheckBox")
		hideWhileResting:SetRelativeWidth(0.33)
		hideWhileResting:SetLabel("Hide While Resting")
		hideWhileResting:SetValue(options.hideWhileResting)
		hideWhileResting:SetDisabled(options.useCustomVisibilityCondition)
		hideWhileResting:SetCallback("OnValueChanged", function(_, _, value)
			options.hideWhileResting = value

			SCM:ApplyAttributeDriver()
			SCM:CreateAllCustomIcons()
		end)
		visibilitySettings:AddChild(hideWhileResting)

		local hideOutOfCombat = AceGUI:Create("CheckBox")
		hideOutOfCombat:SetRelativeWidth(0.33)
		hideOutOfCombat:SetLabel("Hide Outside Of Combat")
		hideOutOfCombat:SetValue(options.hideOutOfCombat)
		hideOutOfCombat:SetDisabled(options.useCustomVisibilityCondition)
		hideOutOfCombat:SetCallback("OnValueChanged", function(_, _, value)
			options.hideOutOfCombat = value

			SCM:ApplyAttributeDriver()
			SCM:CreateAllCustomIcons()
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
		useCustomVisibilityCondition:SetValue(options.useCustomVisibilityCondition)

		customVisibilitySettings:AddChild(useCustomVisibilityCondition)

		local customVisibilityCondition = AceGUI:Create("EditBox")
		customVisibilityCondition:SetRelativeWidth(0.5)
		customVisibilityCondition:SetLabel("Condition")
		customVisibilityCondition:SetText(options.customVisibilityCondition)
		customVisibilityCondition:SetDisabled(not options.useCustomVisibilityCondition)
		customVisibilityCondition:SetCallback("OnEnterPressed", function(_, _, value)
			options.customVisibilityCondition = value

			SCM:ApplyAttributeDriver()
			SCM:CreateAllCustomIcons()
		end)
		customVisibilitySettings:AddChild(customVisibilityCondition)

		useCustomVisibilityCondition:SetCallback("OnValueChanged", function(_, _, value)
			options.useCustomVisibilityCondition = value

			customVisibilityCondition:SetDisabled(not value)
			hideWhileMounted:SetDisabled(value)
			hideWhileDead:SetDisabled(value)
			hideWhileInVehicle:SetDisabled(value)
			hideWhileResting:SetDisabled(value)
			hideOutOfCombat:SetDisabled(value)
			SCM:ApplyAttributeDriver()
			SCM:CreateAllCustomIcons()
		end)
		local auraSettings = AceGUI:Create("InlineGroup")
		auraSettings:SetLayout("flow")
		auraSettings:SetFullWidth(true)
		auraSettings:SetTitle("Auras")
		tabWidget:AddChild(auraSettings)

		local hideBuffsWhenInactive = AceGUI:Create("CheckBox")
		hideBuffsWhenInactive:SetRelativeWidth(0.33)
		hideBuffsWhenInactive:SetLabel('Disable "Hide When Inactive"')
		hideBuffsWhenInactive:SetValue(options.hideBuffsWhenInactive)
		hideBuffsWhenInactive:SetDisabled(not LibEditModeOverride:CanEditActiveLayout())
		SCM.Utils.SetDisabledTooltip(hideBuffsWhenInactive, "Enable a custom edit mode profile first, then reopen options.")
		hideBuffsWhenInactive:SetCallback("OnValueChanged", function(self, _, value)
			if InCombatLockdown() then
				return
			end

			options.hideBuffsWhenInactive = value

			SCM:SetHideWhenInactive(value)
			SCM.RefreshCooldownViewerData(true)
		end)
		hideBuffsWhenInactive:SetCallback("OnEnter", function(self)
			GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
			GameTooltip:AddLine(
				'This will disable the checkbox "Hide When Inactive" in the Blizzard CDM settings. SCM will still hide all buffs that are not tracked but this allows you to show buffs at all times.',
				1,
				1,
				1,
				true
			)
			GameTooltip:Show()
		end)
		hideBuffsWhenInactive:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
		auraSettings:AddChild(hideBuffsWhenInactive)

		if not LibEditModeOverride:CanEditActiveLayout() then
			AddInfoText(auraSettings, "Enable a custom edit mode profile to use this feature. Reopen the opens once you did")
		end

		local disableGCD = AceGUI:Create("CheckBox")
		disableGCD:SetRelativeWidth(0.5)
		disableGCD:SetLabel("Disable GCD (Experimental)")
		disableGCD:SetValue(options.disableGCD)
		disableGCD:SetCallback("OnValueChanged", function(_, _, value)
			options.disableGCD = value
		end)
		auraSettings:AddChild(disableGCD)

		local normalSwipeSettings = AceGUI:Create("InlineGroup")
		normalSwipeSettings:SetLayout("flow")
		normalSwipeSettings:SetFullWidth(true)
		normalSwipeSettings:SetTitle("Cooldown Swipe")
		auraSettings:AddChild(normalSwipeSettings)

		local recolorNormalSwipe = AceGUI:Create("CheckBox")
		recolorNormalSwipe:SetRelativeWidth(0.5)
		recolorNormalSwipe:SetLabel("Recolor Swipe")
		recolorNormalSwipe:SetValue(options.recolorNormalSwipe)
		recolorNormalSwipe:SetCallback("OnValueChanged", function(_, _, value)
			options.recolorNormalSwipe = value
		end)
		normalSwipeSettings:AddChild(recolorNormalSwipe)

		local normalSwipeColor = AceGUI:Create("ColorPicker")
		normalSwipeColor:SetRelativeWidth(0.5)
		normalSwipeColor:SetLabel("Swipe Color")
		normalSwipeColor:SetHasAlpha(true)
		normalSwipeColor:SetColor(unpack(options.normalSwipeColor))
		normalSwipeColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			options.normalSwipeColor = { r, g, b, a }
		end)
		normalSwipeSettings:AddChild(normalSwipeColor)

		local activeSwipeSettings = AceGUI:Create("InlineGroup")
		activeSwipeSettings:SetLayout("flow")
		activeSwipeSettings:SetFullWidth(true)
		activeSwipeSettings:SetTitle("Active Swipe")
		auraSettings:AddChild(activeSwipeSettings)

		local recolorActiveSwipe = AceGUI:Create("CheckBox")
		recolorActiveSwipe:SetRelativeWidth(0.5)
		recolorActiveSwipe:SetLabel("Recolor Swipe")
		recolorActiveSwipe:SetValue(options.recolorActiveSwipe)
		recolorActiveSwipe:SetCallback("OnValueChanged", function(_, _, value)
			options.recolorActiveSwipe = value
		end)
		activeSwipeSettings:AddChild(recolorActiveSwipe)

		local activeSwipeColor = AceGUI:Create("ColorPicker")
		activeSwipeColor:SetRelativeWidth(0.5)
		activeSwipeColor:SetLabel("Swipe Color")
		activeSwipeColor:SetHasAlpha(true)
		activeSwipeColor:SetColor(unpack(options.activeSwipeColor))
		activeSwipeColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			options.activeSwipeColor = { r, g, b, a }
		end)
		activeSwipeSettings:AddChild(activeSwipeColor)

		local reverseActiveSwipe = AceGUI:Create("CheckBox")
		reverseActiveSwipe:SetRelativeWidth(0.5)
		reverseActiveSwipe:SetLabel("Reverse Active Swipe")
		reverseActiveSwipe:SetValue(options.reverseActiveSwipe)
		reverseActiveSwipe:SetCallback("OnValueChanged", function(_, _, value)
			options.reverseActiveSwipe = value
		end)
		activeSwipeSettings:AddChild(reverseActiveSwipe)

		local disableRegularIconActiveSwipe = AceGUI:Create("CheckBox")
		disableRegularIconActiveSwipe:SetRelativeWidth(0.5)
		disableRegularIconActiveSwipe:SetLabel("Disable On Regular Icons")
		disableRegularIconActiveSwipe:SetValue(options.disableRegularIconActiveSwipe)
		disableRegularIconActiveSwipe:SetCallback("OnValueChanged", function(_, _, value)
			options.disableRegularIconActiveSwipe = value
		end)
		activeSwipeSettings:AddChild(disableRegularIconActiveSwipe)
	elseif group == "Icons" then
		local iconSettings = AceGUI:Create("InlineGroup")
		iconSettings:SetLayout("flow")
		iconSettings:SetFullWidth(true)
		iconSettings:SetTitle("Icon")
		tabWidget:AddChild(iconSettings)

		local iconZoom = AceGUI:Create("Slider")
		iconZoom:SetRelativeWidth(0.25)
		iconZoom:SetValue(options.iconZoom or 1)
		iconZoom:SetLabel("Zoom")
		iconZoom:SetSliderValues(-0.1, 0.4, 0.01)
		iconZoom:SetIsPercent(true)
		iconZoom:SetCallback("OnValueChanged", function(self, event, value)
			options.iconZoom = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		iconSettings:AddChild(iconZoom)

		local iconFrameStrata = AceGUI:Create("Dropdown")
		iconFrameStrata:SetRelativeWidth(0.25)
		iconFrameStrata:SetLabel("Frame Strata")
		iconFrameStrata:SetList(SCM.Constants.FrameStrata, SCM.Constants.FrameStrataSorted)
		iconFrameStrata:SetValue(options.iconFrameStrata or "")
		iconFrameStrata:SetCallback("OnValueChanged", function(_, _, value)
			options.iconFrameStrata = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		iconSettings:AddChild(iconFrameStrata)

		local keepIconSquareRatio = AceGUI:Create("CheckBox")
		keepIconSquareRatio:SetRelativeWidth(0.25)
		keepIconSquareRatio:SetLabel("Keep Icon Square Ratio")
		keepIconSquareRatio:SetValue(options.keepIconSquareRatio)
		keepIconSquareRatio:SetCallback("OnValueChanged", function(_, _, value)
			options.keepIconSquareRatio = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		iconSettings:AddChild(keepIconSquareRatio)

		local borderSettings = AceGUI:Create("InlineGroup")
		borderSettings:SetLayout("flow")
		borderSettings:SetFullWidth(true)
		borderSettings:SetTitle("Border")
		tabWidget:AddChild(borderSettings)

		local borderSize = AceGUI:Create("Slider")
		borderSize:SetRelativeWidth(0.5)
		borderSize:SetLabel("Border Size")
		borderSize:SetSliderValues(0, 5, 0.1)
		borderSize:SetValue(options.borderSize or 1)
		borderSize:SetCallback("OnValueChanged", function(_, _, value)
			options.borderSize = value
			SCM:CreateCastBar()
			SCM:ApplyAllCDManagerConfigs()
		end)
		borderSettings:AddChild(borderSize)

		local borderColor = AceGUI:Create("ColorPicker")
		borderColor:SetRelativeWidth(0.5)
		borderColor:SetLabel("Border Color")
		borderColor:SetHasAlpha(true)

		local color = options.borderColor or { r = 0, g = 0, b = 0, a = 1 }
		borderColor:SetColor(color.r, color.g, color.b, color.a)
		borderColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			options.borderColor = { r = r, g = g, b = b, a = a }
			SCM:ApplyAllCDManagerConfigs()
		end)
		borderSettings:AddChild(borderColor)

		local chargeSettings = AceGUI:Create("InlineGroup")
		chargeSettings:SetLayout("flow")
		chargeSettings:SetFullWidth(true)
		chargeSettings:SetTitle("Charge/Application")
		tabWidget:AddChild(chargeSettings)

		local chargeFont = AceGUI:Create("LSM30_Font")
		chargeFont:SetLabel("Font")
		chargeFont:SetRelativeWidth(0.33)
		chargeFont:SetList(LSM:HashTable("font"))
		chargeFont:SetValue(options.chargeFont)
		chargeFont:SetCallback("OnValueChanged", function(self, event, value)
			if value ~= options.chargeFont then
				options.chargeFont = value
				self:SetValue(value)
				SCM:ApplyAllCDManagerConfigs()
			end
		end)
		chargeSettings:AddChild(chargeFont)

		local chargeFontSize = AceGUI:Create("Slider")
		chargeFontSize:SetRelativeWidth(0.33)
		chargeFontSize:SetLabel("Font Size")
		chargeFontSize:SetSliderValues(1, 50, 1)
		chargeFontSize:SetValue(options.chargeFontSize)
		chargeFontSize:SetCallback("OnValueChanged", function(self, event, value)
			options.chargeFontSize = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeFontSize)

		local chargeFontOutline = AceGUI:Create("Dropdown")
		chargeFontOutline:SetRelativeWidth(0.33)
		chargeFontOutline:SetLabel("Outline")
		chargeFontOutline:SetList(SCM.Constants.TextOutline, SCM.Constants.TextOutlineSorted)
		chargeFontOutline:SetValue(options.chargeFontOutline or "OUTLINE")
		chargeFontOutline:SetCallback("OnValueChanged", function(_, _, value)
			options.chargeFontOutline = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeFontOutline)

		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.25)
		chargeRelativePoint:SetLabel("Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(options.chargePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			options.chargePoint = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeRelativePoint)

		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.25)
		chargeRelativePoint:SetLabel("Relative Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(options.chargeRelativePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			options.chargeRelativePoint = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeRelativePoint)

		local xOffset = AceGUI:Create("Slider")
		xOffset:SetRelativeWidth(0.25)
		xOffset:SetSliderValues(-50, 50, 0.1)
		xOffset:SetLabel("X Offset")
		xOffset:SetValue(options.chargeXOffset)
		xOffset:SetCallback("OnValueChanged", function(self, event, value)
			options.chargeXOffset = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(xOffset)

		local yOffset = AceGUI:Create("Slider")
		yOffset:SetRelativeWidth(0.25)
		yOffset:SetSliderValues(-50, 50, 0.1)
		yOffset:SetLabel("Y Offset")
		yOffset:SetValue(options.chargeYOffset)
		yOffset:SetCallback("OnValueChanged", function(self, event, value)
			options.chargeYOffset = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(yOffset)

		local chargeFrameLevel = AceGUI:Create("Slider")
		chargeFrameLevel:SetRelativeWidth(0.5)
		chargeFrameLevel:SetLabel("Frame Level")
		chargeFrameLevel:SetSliderValues(0, 10, 1)
		chargeFrameLevel:SetValue(options.chargeFrameLevel or 1)
		chargeFrameLevel:SetCallback("OnValueChanged", function(_, _, value)
			options.chargeFrameLevel = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeFrameLevel)

		local chargeColour = AceGUI:Create("ColorPicker")
		chargeColour:SetLabel("Colour")
		chargeColour:SetRelativeWidth(0.5)
		chargeColour:SetColor(options.chargeColour.r, options.chargeColour.g, options.chargeColour.b, options.chargeColour.a or 1)
		chargeColour:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			options.chargeColour = { r = r, g = g, b = b, a = a }
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeColour)

		local cooldownTextSettings = AceGUI:Create("InlineGroup")
		cooldownTextSettings:SetLayout("flow")
		cooldownTextSettings:SetFullWidth(true)
		cooldownTextSettings:SetTitle("Cooldown Font")
		tabWidget:AddChild(cooldownTextSettings)

		local enableCooldownFont = AceGUI:Create("CheckBox")
		enableCooldownFont:SetRelativeWidth(1)
		enableCooldownFont:SetLabel("Custom Cooldown Font")
		enableCooldownFont:SetValue(options.changeCooldownFont)
		enableCooldownFont:SetCallback("OnValueChanged", function(_, _, value)
			options.changeCooldownFont = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownTextSettings:AddChild(enableCooldownFont)

		local cooldownFont = AceGUI:Create("LSM30_Font")
		cooldownFont:SetLabel("Font")
		cooldownFont:SetRelativeWidth(0.33)
		cooldownFont:SetList(LSM:HashTable("font"))
		cooldownFont:SetValue(options.cooldownFont)
		cooldownFont:SetCallback("OnValueChanged", function(self, event, value)
			options.cooldownFont = value
			self:SetValue(value)
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownTextSettings:AddChild(cooldownFont)

		local cooldownFontSize = AceGUI:Create("Slider")
		local cooldownFontSizeValue = options.cooldownFontSize or 0.6
		if cooldownFontSizeValue > 1 then
			cooldownFontSizeValue = cooldownFontSizeValue / 40
			options.cooldownFontSize = cooldownFontSizeValue
		end

		cooldownFontSize:SetRelativeWidth(0.33)
		cooldownFontSize:SetLabel("Font Size")
		cooldownFontSize:SetSliderValues(0.1, 1, 0.01)
		cooldownFontSize:SetIsPercent(true)
		cooldownFontSize:SetValue(cooldownFontSizeValue)
		cooldownFontSize:SetCallback("OnValueChanged", function(self, event, value)
			options.cooldownFontSize = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownTextSettings:AddChild(cooldownFontSize)

		local cooldownFontOutline = AceGUI:Create("Dropdown")
		cooldownFontOutline:SetRelativeWidth(0.33)
		cooldownFontOutline:SetLabel("Outline")
		cooldownFontOutline:SetList(SCM.Constants.TextOutline, SCM.Constants.TextOutlineSorted)
		cooldownFontOutline:SetValue(options.cooldownFontOutline or "OUTLINE")
		cooldownFontOutline:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownFontOutline = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownTextSettings:AddChild(cooldownFontOutline)

		local cooldownXOffset = AceGUI:Create("Slider")
		cooldownXOffset:SetRelativeWidth(0.33)
		cooldownXOffset:SetValue(options.cooldownXOffset)
		cooldownXOffset:SetLabel("X Offset")
		cooldownXOffset:SetSliderValues(-30, 30, 0.1)
		cooldownXOffset:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownXOffset = value
		end)
		cooldownTextSettings:AddChild(cooldownXOffset)

		local cooldownYOffset = AceGUI:Create("Slider")
		cooldownYOffset:SetRelativeWidth(0.33)
		cooldownYOffset:SetValue(options.cooldownYOffset)
		cooldownYOffset:SetLabel("Y Offset")
		cooldownYOffset:SetSliderValues(-30, 30, 0.1)
		cooldownYOffset:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownYOffset = value
		end)
		cooldownTextSettings:AddChild(cooldownYOffset)

		local cooldownFrameLevel = AceGUI:Create("Slider")
		cooldownFrameLevel:SetRelativeWidth(0.33)
		cooldownFrameLevel:SetLabel("Frame Level")
		cooldownFrameLevel:SetSliderValues(0, 10, 1)
		cooldownFrameLevel:SetValue(options.cooldownFrameLevel or 1)
		cooldownFrameLevel:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownFrameLevel = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownTextSettings:AddChild(cooldownFrameLevel)

		local cooldownPositionSettings = AceGUI:Create("InlineGroup")
		cooldownPositionSettings:SetLayout("flow")
		cooldownPositionSettings:SetFullWidth(true)
		cooldownPositionSettings:SetTitle("Cooldown Frame Position")
		tabWidget:AddChild(cooldownPositionSettings)

		local cooldownMoveTL = AceGUI:Create("CheckBox")
		cooldownMoveTL:SetRelativeWidth(0.33)
		cooldownMoveTL:SetValue(options.cooldownMoveTL)
		cooldownMoveTL:SetLabel("Offset TOPLEFT")
		cooldownPositionSettings:AddChild(cooldownMoveTL)

		local cooldownXOffsetTL = AceGUI:Create("Slider")
		cooldownXOffsetTL:SetRelativeWidth(0.33)
		cooldownXOffsetTL:SetSliderValues(-50, 50, 0.1)
		cooldownXOffsetTL:SetLabel("X Offset TOPLEFT")
		cooldownXOffsetTL:SetValue(options.cooldownXOffsetTL or 0)
		cooldownXOffsetTL:SetDisabled(not options.cooldownMoveTL)
		cooldownXOffsetTL:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownXOffsetTL = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownPositionSettings:AddChild(cooldownXOffsetTL)

		local cooldownYOffsetTL = AceGUI:Create("Slider")
		cooldownYOffsetTL:SetRelativeWidth(0.33)
		cooldownYOffsetTL:SetSliderValues(-50, 50, 0.1)
		cooldownYOffsetTL:SetLabel("Y Offset TOPLEFT")
		cooldownYOffsetTL:SetValue(options.cooldownYOffsetTL or 0)
		cooldownYOffsetTL:SetDisabled(not options.cooldownMoveTL)
		cooldownYOffsetTL:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownYOffsetTL = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownPositionSettings:AddChild(cooldownYOffsetTL)

		cooldownMoveTL:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownMoveTL = value
			cooldownXOffsetTL:SetDisabled(not value)
			cooldownYOffsetTL:SetDisabled(not value)
			SCM:ApplyAllCDManagerConfigs()
		end)

		local cooldownMoveBR = AceGUI:Create("CheckBox")
		cooldownMoveBR:SetRelativeWidth(0.33)
		cooldownMoveBR:SetValue(options.cooldownMoveBR)
		cooldownMoveBR:SetLabel("Offset BOTTOMRIGHT")
		cooldownPositionSettings:AddChild(cooldownMoveBR)

		local cooldownXOffsetBR = AceGUI:Create("Slider")
		cooldownXOffsetBR:SetRelativeWidth(0.33)
		cooldownXOffsetBR:SetSliderValues(-50, 50, 0.1)
		cooldownXOffsetBR:SetLabel("X Offset BOTTOMRIGHT")
		cooldownXOffsetBR:SetValue(options.cooldownXOffsetBR or -SCM:PixelPerfectSize(1))
		cooldownXOffsetBR:SetDisabled(not options.cooldownMoveBR)
		cooldownXOffsetBR:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownXOffsetBR = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownPositionSettings:AddChild(cooldownXOffsetBR)

		local cooldownYOffsetBR = AceGUI:Create("Slider")
		cooldownYOffsetBR:SetRelativeWidth(0.33)
		cooldownYOffsetBR:SetSliderValues(-50, 50, 0.1)
		cooldownYOffsetBR:SetLabel("Y Offset BOTTOMRIGHT")
		cooldownYOffsetBR:SetValue(options.cooldownYOffsetBR or SCM:PixelPerfectSize(1))
		cooldownYOffsetBR:SetDisabled(not options.cooldownMoveBR)
		cooldownYOffsetBR:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownYOffsetBR = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		cooldownPositionSettings:AddChild(cooldownYOffsetBR)

		cooldownMoveBR:SetCallback("OnValueChanged", function(_, _, value)
			options.cooldownMoveBR = value
			cooldownXOffsetBR:SetDisabled(not value)
			cooldownYOffsetBR:SetDisabled(not value)
			SCM:ApplyAllCDManagerConfigs()
		end)

		local cooldownTimerSettings = AceGUI:Create("InlineGroup")
		cooldownTimerSettings:SetLayout("flow")
		cooldownTimerSettings:SetFullWidth(true)
		cooldownTimerSettings:SetTitle("Cooldown Timer")
		tabWidget:AddChild(cooldownTimerSettings)

		local Constants = SCM.Constants.CooldownTimer
		local breakpoints = options.cooldownBreakpoints
		local breakpointTabsTbl = {}
		for i = 1, #breakpoints do
			breakpointTabsTbl[i] = { value = i, text = "Breakpoint " .. i }
		end

		local breakpointTabs = AceGUI:Create("TabGroup")
		breakpointTabs:SetLayout("flow")
		breakpointTabs:SetFullWidth(true)
		breakpointTabs:SetTabs(breakpointTabsTbl)
		breakpointTabs:SetCallback("OnGroupSelected", function(self, event, breakpointIndex)
			self:ReleaseChildren()

			breakpoints = options.cooldownBreakpoints
			local selectedBreakpoint = breakpoints[breakpointIndex]

			local breakpointButtonGroup = AceGUI:Create("SimpleGroup")
			breakpointButtonGroup:SetFullWidth(true)
			breakpointButtonGroup:SetLayout("flow")
			self:AddChild(breakpointButtonGroup)

			local addBreakpointButton = AceGUI:Create("Button")
			addBreakpointButton:SetText("Add Breakpoint")
			addBreakpointButton:SetRelativeWidth(0.5)
			addBreakpointButton:SetCallback("OnClick", function()
				local breakpoint = CopyTable(Constants.DisplayStyleSettings.seconds)
				breakpoint.threshold = 5
				breakpoint.displayStyle = "seconds"
				breakpoint.components = GetCooldownBreakpointComponents(breakpoint.displayStyle, breakpoint.threshold)
				breakpoints[#breakpoints + 1] = breakpoint
				breakpointIndex = #breakpoints
				SCM.Cooldowns:ApplyFormatterSettings()

				breakpointTabsTbl = {}
				for i = 1, #breakpoints do
					breakpointTabsTbl[i] = { value = i, text = "Breakpoint " .. i }
				end
				self:SetTabs(breakpointTabsTbl)
				self:SelectTab(breakpointIndex)
			end)
			breakpointButtonGroup:AddChild(addBreakpointButton)

			local removeBreakpointButton = AceGUI:Create("Button")
			removeBreakpointButton:SetText("Remove Breakpoint")
			removeBreakpointButton:SetRelativeWidth(0.5)
			removeBreakpointButton:SetDisabled(#breakpoints <= 1)
			removeBreakpointButton:SetCallback("OnClick", function()
				tremove(breakpoints, breakpointIndex)

				if breakpointIndex > #breakpoints then
					breakpointIndex = #breakpoints
				end
				SCM.Cooldowns:ApplyFormatterSettings()

				breakpointTabsTbl = {}
				for i = 1, #breakpoints do
					breakpointTabsTbl[i] = { value = i, text = "Breakpoint " .. i }
				end
				self:SetTabs(breakpointTabsTbl)
				self:SelectTab(breakpointIndex)
			end)
			breakpointButtonGroup:AddChild(removeBreakpointButton)

			local minValueInput = AceGUI:Create("EditBox")
			minValueInput:SetRelativeWidth(0.33)
			minValueInput:SetLabel("Min Value (in seconds)")
			minValueInput:SetText(tostring(selectedBreakpoint.threshold or 0))
			minValueInput:SetCallback("OnEnterPressed", function(input, _, text)
				local value = tonumber(text)
				if not value then
					input:SetText(tostring(selectedBreakpoint.threshold or 0))
					return
				end

				local displayStyle = selectedBreakpoint.displayStyle
				local styleSettings = Constants.DisplayStyleSettings[displayStyle]
				selectedBreakpoint.threshold = value
				selectedBreakpoint.step = styleSettings.step
				selectedBreakpoint.rounding = styleSettings.rounding
				selectedBreakpoint.format = styleSettings.format
				selectedBreakpoint.components = GetCooldownBreakpointComponents(displayStyle, value)

				SCM.Cooldowns:ApplyFormatterSettings()
			end)
			self:AddChild(minValueInput)

			local displayStyle = selectedBreakpoint.displayStyle

			local breakpointDisplayStyle = AceGUI:Create("Dropdown")
			breakpointDisplayStyle:SetRelativeWidth(0.33)
			breakpointDisplayStyle:SetLabel("Display Style")
			breakpointDisplayStyle:SetList(Constants.DisplayStyle[1], Constants.DisplayStyle[2])
			breakpointDisplayStyle:SetValue(displayStyle)
			breakpointDisplayStyle:SetCallback("OnValueChanged", function(_, _, value)
				local styleSettings = Constants.DisplayStyleSettings[value]

				selectedBreakpoint.displayStyle = value
				selectedBreakpoint.step = styleSettings.step
				selectedBreakpoint.rounding = styleSettings.rounding

				if selectedBreakpoint.color then
					selectedBreakpoint.format = CreateColor(unpack(selectedBreakpoint.color)):WrapTextInColorCode(C_StringUtil.StripHyperlinks(styleSettings.format))
				else
					selectedBreakpoint.format = styleSettings.format
				end
				selectedBreakpoint.components = GetCooldownBreakpointComponents(value, selectedBreakpoint.threshold or 0)

				SCM.Cooldowns:ApplyFormatterSettings()
			end)
			self:AddChild(breakpointDisplayStyle)

			local breakpointColor = AceGUI:Create("ColorPicker")
			breakpointColor:SetRelativeWidth(0.33)
			breakpointColor:SetLabel("Color")
			breakpointColor:SetColor(unpack(selectedBreakpoint.color or { 1, 1, 1, 1 }))
			breakpointColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
				selectedBreakpoint.color = { r, g, b, a }
				selectedBreakpoint.format = CreateColor(r, g, b, a):WrapTextInColorCode(C_StringUtil.StripHyperlinks(selectedBreakpoint.format))

				SCM.Cooldowns:ApplyFormatterSettings()
			end)
			self:AddChild(breakpointColor)
		end)
		breakpointTabs:SelectTab(1)
		cooldownTimerSettings:AddChild(breakpointTabs)

		local cooldownTimerTestEditBox = AceGUI:Create("EditBox")
		cooldownTimerTestEditBox:SetRelativeWidth(0.5)
		cooldownTimerTestEditBox:SetText("")
		cooldownTimerTestEditBox:SetLabel("Enter Test Duration")
		cooldownTimerSettings:AddChild(cooldownTimerTestEditBox)

		local cooldownTimerTestResult = AceGUI:Create("Label")
		cooldownTimerTestResult:SetRelativeWidth(0.5)
		cooldownTimerTestResult:SetText("Output: (No Input)")
		cooldownTimerSettings:AddChild(cooldownTimerTestResult)

		cooldownTimerTestEditBox:SetCallback("OnEnterPressed", function(_, _, value)
			if tonumber(value) then
				cooldownTimerTestResult:SetText(string.format("Output: %s", SCM.Cooldowns.NumericRuleFormatter:FormatNumber(tonumber(value))))
			else
				cooldownTimerTestResult:SetText("Output: (Invalid Input)")
			end
		end)
	elseif group == "Glow" then
		local glowSettings = AceGUI:Create("InlineGroup")
		glowSettings:SetLayout("flow")
		glowSettings:SetFullWidth(true)
		glowSettings:SetTitle("Custom Glow")
		tabWidget:AddChild(glowSettings)

		local useCustomGlow = AceGUI:Create("CheckBox")
		useCustomGlow:SetRelativeWidth(0.5)
		useCustomGlow:SetLabel("Use Custom Glow")
		useCustomGlow:SetValue(options.useCustomGlow)
		useCustomGlow:SetCallback("OnValueChanged", function(_, _, value)
			options.useCustomGlow = value
		end)
		glowSettings:AddChild(useCustomGlow)

		local glowType = AceGUI:Create("Dropdown")
		glowType:SetRelativeWidth(0.5)
		glowType:SetLabel("Custom Glow Type")
		glowType:SetList({
			["Pixel"] = "Pixel Glow",
			["Autocast"] = "Autocast Glow",
			["Proc"] = "Proc Glow",
			["Button"] = "Button",
		})
		glowSettings:AddChild(glowType)

		local dynamicGlowSettingsGroup = AceGUI:Create("InlineGroup")
		dynamicGlowSettingsGroup:SetLayout("flow")
		dynamicGlowSettingsGroup:SetFullWidth(true)
		glowSettings:AddChild(dynamicGlowSettingsGroup)
		glowType:SetCallback("OnValueChanged", function(_, _, value)
			options.glowType = value
			SCM:RefreshAllGlows()
			AddCustomGlowOptions(dynamicGlowSettingsGroup, options.glowTypeOptions[value], value)
			glowSettings:DoLayout()
			tabWidget:DoLayout()
		end)
		glowType:SetValue(options.glowType or "Pixel")
		AddCustomGlowOptions(dynamicGlowSettingsGroup, options.glowTypeOptions[options.glowType], options.glowType)

		local pandemicGlowSettings = AceGUI:Create("InlineGroup")
		pandemicGlowSettings:SetLayout("flow")
		pandemicGlowSettings:SetFullWidth(true)
		pandemicGlowSettings:SetTitle("Pandemic Glow")
		tabWidget:AddChild(pandemicGlowSettings)

		local pandemicGlowOption = AceGUI:Create("Dropdown")
		pandemicGlowOption:SetList(
			{ keepPandemicGlow = "Keep", disablePandemicGlow = "Disable", replacePandemicGlow = "Replace" },
			{ "keepPandemicGlow", "disablePandemicGlow", "replacePandemicGlow" }
		)
		pandemicGlowOption:SetRelativeWidth(1)
		pandemicGlowOption:SetLabel("Pandemic Glow")
		pandemicGlowOption:SetValue(options.pandemicGlowOption or "keepPandemicGlow")
		pandemicGlowOption:SetCallback("OnValueChanged", function(_, _, value)
			options.pandemicGlowOption = value
		end)
		pandemicGlowSettings:AddChild(pandemicGlowOption)

		local pandemicGlowBorderSettings = AceGUI:Create("InlineGroup")
		pandemicGlowBorderSettings:SetLayout("flow")
		pandemicGlowBorderSettings:SetFullWidth(true)
		pandemicGlowBorderSettings:SetTitle("Border")
		pandemicGlowSettings:AddChild(pandemicGlowBorderSettings)

		local replaceWithBorder = AceGUI:Create("CheckBox")
		replaceWithBorder:SetRelativeWidth(0.33)
		replaceWithBorder:SetLabel("Replace With Border")
		replaceWithBorder:SetValue(options.pandemicReplaceWithBorder)
		replaceWithBorder:SetDisabled(options.pandemicReplaceWithCustomGlow)
		pandemicGlowBorderSettings:AddChild(replaceWithBorder)

		local borderSize = AceGUI:Create("Slider")
		borderSize:SetRelativeWidth(0.33)
		borderSize:SetLabel("Border Size")
		borderSize:SetSliderValues(0, 10, 0.1)
		borderSize:SetValue(options.pandemicBorderSize or 1)
		borderSize:SetCallback("OnValueChanged", function(_, _, value)
			options.pandemicBorderSize = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		pandemicGlowBorderSettings:AddChild(borderSize)

		local borderColor = AceGUI:Create("ColorPicker")
		borderColor:SetRelativeWidth(0.33)
		borderColor:SetLabel("Border Color")
		borderColor:SetHasAlpha(true)

		local color = options.pandemicBorderColor or { r = 0, g = 0, b = 0, a = 0 }
		borderColor:SetColor(color.r, color.g, color.b, color.a)
		borderColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			options.pandemicBorderColor = { r = r, g = g, b = b, a = a }
			SCM:ApplyAllCDManagerConfigs()
		end)
		pandemicGlowBorderSettings:AddChild(borderColor)

		local pandemicGlowGlowSettings = AceGUI:Create("InlineGroup")
		pandemicGlowGlowSettings:SetLayout("flow")
		pandemicGlowGlowSettings:SetFullWidth(true)
		pandemicGlowGlowSettings:SetTitle("Custom Glow")
		pandemicGlowSettings:AddChild(pandemicGlowGlowSettings)

		local replaceWithCustomGlow = AceGUI:Create("CheckBox")
		replaceWithCustomGlow:SetRelativeWidth(0.5)
		replaceWithCustomGlow:SetLabel("Replace With Custom Glow")
		replaceWithCustomGlow:SetDisabled(options.pandemicReplaceWithBorder)
		replaceWithCustomGlow:SetValue(options.pandemicReplaceWithCustomGlow)

		pandemicGlowGlowSettings:AddChild(replaceWithCustomGlow)

		local pandemicGlowType = AceGUI:Create("Dropdown")
		pandemicGlowType:SetRelativeWidth(0.5)
		pandemicGlowType:SetLabel("Custom Glow Type")
		pandemicGlowType:SetList({
			["Pixel"] = "Pixel Glow",
			["Autocast"] = "Autocast Glow",
			["Proc"] = "Proc Glow",
			["Button"] = "Button",
		})
		pandemicGlowGlowSettings:AddChild(pandemicGlowType)

		local dynamicGlowSettingsGroup = AceGUI:Create("InlineGroup")
		dynamicGlowSettingsGroup:SetLayout("flow")
		dynamicGlowSettingsGroup:SetFullWidth(true)
		pandemicGlowGlowSettings:AddChild(dynamicGlowSettingsGroup)
		pandemicGlowType:SetCallback("OnValueChanged", function(_, _, value)
			options.pandemicGlowType = value
			AddCustomGlowOptions(dynamicGlowSettingsGroup, options.pandemicCustomGlowTypeOptions[value], value)
			pandemicGlowGlowSettings:DoLayout()
			tabWidget:DoLayout()
		end)
		pandemicGlowType:SetValue(options.pandemicGlowType or "Pixel")
		AddCustomGlowOptions(dynamicGlowSettingsGroup, options.pandemicCustomGlowTypeOptions[options.pandemicGlowType], options.pandemicGlowType)

		replaceWithBorder:SetCallback("OnValueChanged", function(_, _, value)
			options.pandemicReplaceWithBorder = value
			SCM:ApplyAllCDManagerConfigs()

			replaceWithCustomGlow:SetDisabled(value)
		end)

		replaceWithCustomGlow:SetCallback("OnValueChanged", function(_, _, value)
			options.pandemicReplaceWithCustomGlow = value

			replaceWithBorder:SetDisabled(value)
		end)
	elseif group == "Keybinds" then
		local kb = options.keybinds

		local mainGroup = AceGUI:Create("InlineGroup")
		mainGroup:SetLayout("flow")
		mainGroup:SetFullWidth(true)
		mainGroup:SetTitle("Keybinds")
		tabWidget:AddChild(mainGroup)

		local enabled = AceGUI:Create("CheckBox")
		enabled:SetRelativeWidth(1.0)
		enabled:SetLabel("Show keybinds on cooldown icons")
		enabled:SetValue(kb.enabled)
		enabled:SetCallback("OnValueChanged", function(_, _, value)
			kb.enabled = value
			SCM.Keybinds.OnSettingChanged()
		end)
		mainGroup:AddChild(enabled)

		local posGroup = AceGUI:Create("InlineGroup")
		posGroup:SetLayout("flow")
		posGroup:SetFullWidth(true)
		posGroup:SetTitle("Position")
		tabWidget:AddChild(posGroup)

		local anchorPoints = {
			TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right",
			LEFT = "Left", CENTER = "Center", RIGHT = "Right",
			BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right",
		}
		local anchorOrder = {
			"TOPLEFT","TOP","TOPRIGHT","LEFT","CENTER","RIGHT","BOTTOMLEFT","BOTTOM","BOTTOMRIGHT",
		}

		local anchor = AceGUI:Create("Dropdown")
		anchor:SetRelativeWidth(0.33)
		anchor:SetLabel("Anchor")
		anchor:SetList(anchorPoints, anchorOrder)
		anchor:SetValue(kb.anchor)
		anchor:SetCallback("OnValueChanged", function(_, _, value)
			kb.anchor = value
			if SCM.Keybinds then SCM.Keybinds.RefreshAllFrames() end
		end)
		posGroup:AddChild(anchor)

		local xOffset = AceGUI:Create("Slider")
		xOffset:SetRelativeWidth(0.33)
		xOffset:SetLabel("X Offset")
		xOffset:SetSliderValues(-30, 30, 0.5)
		xOffset:SetValue(kb.offsetX)
		xOffset:SetCallback("OnValueChanged", function(_, _, value)
			kb.offsetX = value
			if SCM.Keybinds then SCM.Keybinds.RefreshAllFrames() end
		end)
		posGroup:AddChild(xOffset)

		local yOffset = AceGUI:Create("Slider")
		yOffset:SetRelativeWidth(0.33)
		yOffset:SetLabel("Y Offset")
		yOffset:SetSliderValues(-30, 30, 0.5)
		yOffset:SetValue(kb.offsetY)
		yOffset:SetCallback("OnValueChanged", function(_, _, value)
			kb.offsetY = value
			if SCM.Keybinds then SCM.Keybinds.RefreshAllFrames() end
		end)
		posGroup:AddChild(yOffset)

		local fontGroup = AceGUI:Create("InlineGroup")
		fontGroup:SetLayout("flow")
		fontGroup:SetFullWidth(true)
		fontGroup:SetTitle("Text")
		tabWidget:AddChild(fontGroup)

		local font = AceGUI:Create("LSM30_Font")
		font:SetLabel("Font")
		font:SetRelativeWidth(0.33)
		font:SetList(LSM:HashTable("font"))
		font:SetValue(kb.fontName)
		font:SetCallback("OnValueChanged", function(self, _, value)
			kb.fontName = value
			self:SetValue(value)
			if SCM.Keybinds then SCM.Keybinds.RefreshAllFrames() end
		end)
		fontGroup:AddChild(font)

		local fontSize = AceGUI:Create("Slider")
		fontSize:SetRelativeWidth(0.33)
		fontSize:SetLabel("Font Size")
		fontSize:SetSliderValues(6, 24, 1)
		fontSize:SetValue(kb.fontSize)
		fontSize:SetCallback("OnValueChanged", function(_, _, value)
			kb.fontSize = value
			if SCM.Keybinds then SCM.Keybinds.RefreshAllFrames() end
		end)
		fontGroup:AddChild(fontSize)

		local fontFlags = AceGUI:Create("Dropdown")
		fontFlags:SetRelativeWidth(0.33)
		fontFlags:SetLabel("Outline")
		fontFlags:SetList({ [""] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick" })
		fontFlags:SetValue(kb.fontFlags)
		fontFlags:SetCallback("OnValueChanged", function(_, _, value)
			kb.fontFlags = value
			if SCM.Keybinds then SCM.Keybinds.RefreshAllFrames() end
		end)
		fontGroup:AddChild(fontFlags)

		local color = AceGUI:Create("ColorPicker")
		color:SetRelativeWidth(0.33)
		color:SetLabel("Color")
		color:SetHasAlpha(true)
		color:SetColor(kb.color[1], kb.color[2], kb.color[3], kb.color[4])
		color:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			kb.color = { r, g, b, a }
			if SCM.Keybinds then SCM.Keybinds.RefreshAllFrames() end
		end)
		fontGroup:AddChild(color)

	elseif group == "BuffBar" then
		local buffBarOptions = options.buffBarOptions

		local generalSettings = AceGUI:Create("InlineGroup")
		generalSettings:SetLayout("flow")
		generalSettings:SetFullWidth(true)
		generalSettings:SetTitle("General")
		tabWidget:AddChild(generalSettings)

		local buffBarContent = AceGUI:Create("Dropdown")
		buffBarContent:SetList(SCM.Constants.BuffBarContent)
		buffBarContent:SetRelativeWidth(0.5)
		buffBarContent:SetLabel("Bar Type")
		buffBarContent:SetValue(options.buffBarContent)
		buffBarContent:SetCallback("OnValueChanged", function(_, _, value)
			options.buffBarContent = value

			SCM:SetBuffBarContent(value)
			SCM:SkinBuffBars()
		end)
		generalSettings:AddChild(buffBarContent)

		local textureSettings = AceGUI:Create("InlineGroup")
		textureSettings:SetLayout("flow")
		textureSettings:SetFullWidth(true)
		textureSettings:SetTitle("Texture")
		tabWidget:AddChild(textureSettings)

		local barTexture = AceGUI:Create("LSM30_Statusbar")
		barTexture:SetLabel("Foreground Texture")
		barTexture:SetRelativeWidth(0.33)
		barTexture:SetList(LSM:HashTable("statusbar"))
		barTexture:SetValue(buffBarOptions.barTexture)
		barTexture:SetCallback("OnValueChanged", function(self, event, value)
			buffBarOptions.barTexture = value
			self:SetValue(value)
			SCM:SkinBuffBars()
		end)
		textureSettings:AddChild(barTexture)

		local backgroundColor = AceGUI:Create("ColorPicker")
		backgroundColor:SetRelativeWidth(0.33)
		backgroundColor:SetLabel("Background Color")
		backgroundColor:SetHasAlpha(true)

		local color = buffBarOptions.backgroundColor or { r = 0, g = 0, b = 0, a = 1 }
		backgroundColor:SetColor(color.r, color.g, color.b, color.a)
		backgroundColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			buffBarOptions.backgroundColor = { r = r, g = g, b = b, a = a }
			SCM:SkinBuffBars()
		end)
		textureSettings:AddChild(backgroundColor)

		local foregroundColor = AceGUI:Create("ColorPicker")
		foregroundColor:SetRelativeWidth(0.33)
		foregroundColor:SetLabel("Foreground Color")
		foregroundColor:SetHasAlpha(true)

		local fgColor = buffBarOptions.foregroundColor or { r = 1, g = 1, b = 1, a = 1 }
		foregroundColor:SetColor(fgColor.r, fgColor.g, fgColor.b, fgColor.a)
		foregroundColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			buffBarOptions.foregroundColor = { r = r, g = g, b = b, a = a }
			SCM:SkinBuffBars()
		end)
		textureSettings:AddChild(foregroundColor)

		local borderSettings = AceGUI:Create("InlineGroup")
		borderSettings:SetLayout("flow")
		borderSettings:SetFullWidth(true)
		borderSettings:SetTitle("Border")
		tabWidget:AddChild(borderSettings)

		local borderSize = AceGUI:Create("Slider")
		borderSize:SetRelativeWidth(0.5)
		borderSize:SetLabel("Border Size")
		borderSize:SetSliderValues(0, 5, 0.1)
		borderSize:SetValue(buffBarOptions.borderSize or 1)
		borderSize:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.borderSize = value
			SCM:SkinBuffBars()
		end)
		borderSettings:AddChild(borderSize)

		local borderColor = AceGUI:Create("ColorPicker")
		borderColor:SetRelativeWidth(0.5)
		borderColor:SetLabel("Border Color")
		borderColor:SetHasAlpha(true)

		local color = buffBarOptions.borderColor or { r = 0, g = 0, b = 0, a = 1 }
		borderColor:SetColor(color.r, color.g, color.b, color.a)
		borderColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			buffBarOptions.borderColor = { r = r, g = g, b = b, a = a }
			SCM:SkinBuffBars()
		end)
		borderSettings:AddChild(borderColor)

		local fontSettings = AceGUI:Create("InlineGroup")
		fontSettings:SetLayout("flow")
		fontSettings:SetFullWidth(true)
		fontSettings:SetTitle("Text")
		tabWidget:AddChild(fontSettings)

		local font = AceGUI:Create("LSM30_Font")
		font:SetLabel("Font")
		font:SetRelativeWidth(0.33)
		font:SetList(LSM:HashTable("font"))
		font:SetValue(buffBarOptions.font)
		font:SetCallback("OnValueChanged", function(self, event, value)
			buffBarOptions.font = value
			self:SetValue(value)
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(font)

		local fontSize = AceGUI:Create("Slider")
		fontSize:SetRelativeWidth(0.33)
		fontSize:SetLabel("Font Size")
		fontSize:SetSliderValues(1, 50, 1)
		fontSize:SetValue(buffBarOptions.fontSize)
		fontSize:SetCallback("OnValueChanged", function(self, event, value)
			buffBarOptions.fontSize = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(fontSize)

		local fontOutline = AceGUI:Create("Dropdown")
		fontOutline:SetRelativeWidth(0.33)
		fontOutline:SetLabel("Outline")
		fontOutline:SetList(SCM.Constants.TextOutline, SCM.Constants.TextOutlineSorted)
		fontOutline:SetValue(buffBarOptions.fontOutline or "OUTLINE")
		fontOutline:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.fontOutline = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(fontOutline)

		local hideSpellName = AceGUI:Create("CheckBox")
		hideSpellName:SetRelativeWidth(0.25)
		hideSpellName:SetLabel("Hide Text")
		hideSpellName:SetValue(buffBarOptions.hideSpellName)
		hideSpellName:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.hideSpellName = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(hideSpellName)

		local nameColor = AceGUI:Create("ColorPicker")
		nameColor:SetRelativeWidth(0.25)
		nameColor:SetLabel("Name Color")
		nameColor:SetHasAlpha(true)

		local color = buffBarOptions.nameColor
		nameColor:SetColor(color.r, color.g, color.b, color.a)
		nameColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			buffBarOptions.nameColor = { r = r, g = g, b = b, a = a }
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(nameColor)

		local nameXOffset = AceGUI:Create("Slider")
		nameXOffset:SetRelativeWidth(0.25)
		nameXOffset:SetValue(buffBarOptions.nameXOffset or 0)
		nameXOffset:SetLabel("Name X Offset")
		nameXOffset:SetSliderValues(-100, 100, 0.1)
		nameXOffset:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.nameXOffset = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(nameXOffset)

		local nameYOffset = AceGUI:Create("Slider")
		nameYOffset:SetRelativeWidth(0.25)
		nameYOffset:SetValue(buffBarOptions.nameYOffset or 0)
		nameYOffset:SetLabel("Name Y Offset")
		nameYOffset:SetSliderValues(-100, 100, 0.1)
		nameYOffset:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.nameYOffset = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(nameYOffset)

		local hideDuration = AceGUI:Create("CheckBox")
		hideDuration:SetRelativeWidth(0.25)
		hideDuration:SetLabel("Hide Duration")
		hideDuration:SetValue(buffBarOptions.hideDuration)
		hideDuration:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.hideDuration = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(hideDuration)

		local durationColor = AceGUI:Create("ColorPicker")
		durationColor:SetRelativeWidth(0.25)
		durationColor:SetLabel("Duration Color")
		durationColor:SetHasAlpha(true)

		local color = buffBarOptions.durationColor
		durationColor:SetColor(color.r, color.g, color.b, color.a)
		durationColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			buffBarOptions.durationColor = { r = r, g = g, b = b, a = a }
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(durationColor)

		local durationXOffset = AceGUI:Create("Slider")
		durationXOffset:SetRelativeWidth(0.25)
		durationXOffset:SetValue(buffBarOptions.durationXOffset or 0)
		durationXOffset:SetLabel("Duration X Offset")
		durationXOffset:SetSliderValues(-100, 100, 0.1)
		durationXOffset:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.durationXOffset = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(durationXOffset)

		local durationYOffset = AceGUI:Create("Slider")
		durationYOffset:SetRelativeWidth(0.25)
		durationYOffset:SetValue(buffBarOptions.durationYOffset or 0)
		durationYOffset:SetLabel("Duration Y Offset")
		durationYOffset:SetSliderValues(-100, 100, 0.1)
		durationYOffset:SetCallback("OnValueChanged", function(_, _, value)
			buffBarOptions.durationYOffset = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(durationYOffset)
	end

	scrollFrame:DoLayout()
	tabWidget:DoLayout()
end

local function General(self, frame, group)
	LibEditModeOverride:LoadLayouts()

	local options = SCM.db.profile.options

	local generalFrame = AceGUI:Create("InlineGroup")
	generalFrame:SetLayout("fill")
	generalFrame:SetFullWidth(true)
	generalFrame:SetFullHeight(true)
	self:AddChild(generalFrame)

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	generalFrame:AddChild(scrollFrame)

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(12)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText("|TInterface\\common\\help-i:24:24:0:0|t|cFF4080FFSkiron|r|cFFFFFFFFCooldownManager|r will overwrite most Blizzard Settings.")
	label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	scrollFrame:AddChild(label)

	local globalSettingsTabs = AceGUI:Create("TabGroup")
	globalSettingsTabs:SetTabs(SCM.Defaults.GlobalSettingsTabs)
	globalSettingsTabs:SetFullWidth(true)
	--globalSettingsTabs:SetFullHeight(true)
	globalSettingsTabs:SetLayout("flow")
	globalSettingsTabs:SetCallback("OnGroupSelected", function(self, event, group)
		SelectGlobalSettingsTab(self, scrollFrame, group, options)
	end)
	globalSettingsTabs:SelectTab("General")
	scrollFrame:AddChild(globalSettingsTabs)
end

SCM.MainTabs.General.callback = General
