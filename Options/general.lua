local addonName, SCM = ...
local AceGUI = LibStub("AceGUI-3.0")
local LibEditModeOverride = LibStub("LibEditModeOverride-1.0")
local LSM = LibStub("LibSharedMedia-3.0")

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
	xOffset:SetSliderValues(-30, 30, 1)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		glowTypeOptions.xOffset = value
	end)
	dynamicGlowSettingsGroup:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.33)
	yOffset:SetValue(glowTypeOptions.yOffset or 0)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-30, 30, 1)
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

local function AddCustomGlowOptions(dynamicGlowSettingsGroup)
	local options = SCM.db.profile.options
	dynamicGlowSettingsGroup:ReleaseChildren()

	local glowTypeOptions = options.glowTypeOptions[options.glowType]
	if options.glowType == "Proc" then
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
	elseif options.glowType == "Autocast" then
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
	elseif options.glowType == "Pixel" then
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
	end
end

local function SelectGlobalSettingsTab(tabWidget, group, options)
	tabWidget:ReleaseChildren()

	if group == "General" then
		local skinningSettings = AceGUI:Create("InlineGroup")
		skinningSettings:SetLayout("flow")
		skinningSettings:SetFullWidth(true)
		skinningSettings:SetTitle("Skinning")
		tabWidget:AddChild(skinningSettings)

		local enableSkinning = AceGUI:Create("CheckBox")
		enableSkinning:SetRelativeWidth(0.5)
		enableSkinning:SetLabel("Enable Skinning")
		enableSkinning:SetValue(options.enableSkinning)
		enableSkinning:SetCallback("OnValueChanged", function(_, _, value)
			options.enableSkinning = value
		end)
		skinningSettings:AddChild(enableSkinning)

		local showAnchorHighlight = AceGUI:Create("CheckBox")
		showAnchorHighlight:SetValue(options.showAnchorHighlight)
		showAnchorHighlight:SetRelativeWidth(0.5)
		showAnchorHighlight:SetLabel("Show Anchor Highlight")
		showAnchorHighlight:SetCallback("OnValueChanged", function(self, event, value)
			options.showAnchorHighlight = value
			--
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

		local hideWhileMounted = AceGUI:Create("CheckBox")
		hideWhileMounted:SetRelativeWidth(0.5)
		hideWhileMounted:SetLabel("Hide While Mounted")
		hideWhileMounted:SetValue(options.hideWhileMounted)
		hideWhileMounted:SetCallback("OnValueChanged", function(_, _, value)
			options.hideWhileMounted = value

			SCM:ApplyHideWhileMountedSettings(value)
			SCM:CreateAllCustomIcons()
		end)
		skinningSettings:AddChild(hideWhileMounted)

		local borderSettings = AceGUI:Create("InlineGroup")
		borderSettings:SetLayout("flow")
		borderSettings:SetFullWidth(true)
		borderSettings:SetTitle("Border")
		tabWidget:AddChild(borderSettings)

		local borderSize = AceGUI:Create("Slider")
		borderSize:SetRelativeWidth(0.5)
		borderSize:SetLabel("Border Size")
		borderSize:SetSliderValues(0, 5, 1)
		borderSize:SetValue(options.borderSize or 1)
		borderSize:SetCallback("OnValueChanged", function(_, _, value)
			options.borderSize = value
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

		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.33)
		chargeRelativePoint:SetLabel("Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(options.chargePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			options.chargePoint = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeRelativePoint)

		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.33)
		chargeRelativePoint:SetLabel("Relative Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(options.chargeRelativePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			options.chargeRelativePoint = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(chargeRelativePoint)

		local xOffset = AceGUI:Create("Slider")
		xOffset:SetRelativeWidth(0.33)
		xOffset:SetSliderValues(-50, 50, 0.1)
		xOffset:SetLabel("X Offset")
		xOffset:SetValue(options.chargeXOffset)
		xOffset:SetCallback("OnValueChanged", function(self, event, value)
			options.chargeXOffset = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(xOffset)

		local yOffset = AceGUI:Create("Slider")
		yOffset:SetRelativeWidth(0.33)
		yOffset:SetSliderValues(-50, 50, 0.1)
		yOffset:SetLabel("Y Offset")
		yOffset:SetValue(options.chargeYOffset)
		yOffset:SetCallback("OnValueChanged", function(self, event, value)
			options.chargeYOffset = value
			SCM:ApplyAllCDManagerConfigs()
		end)
		chargeSettings:AddChild(yOffset)

		local cooldownTextSettings = AceGUI:Create("InlineGroup")
		cooldownTextSettings:SetLayout("flow")
		cooldownTextSettings:SetFullWidth(true)
		cooldownTextSettings:SetTitle("Cooldown Text")
		tabWidget:AddChild(cooldownTextSettings)

		local enableCooldownFont = AceGUI:Create("CheckBox")
		enableCooldownFont:SetRelativeWidth(0.33)
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

		local auraSettings = AceGUI:Create("InlineGroup")
		auraSettings:SetLayout("flow")
		auraSettings:SetFullWidth(true)
		auraSettings:SetTitle("Auras")
		tabWidget:AddChild(auraSettings)

		local hideBuffsWhenInactive = AceGUI:Create("CheckBox")
		hideBuffsWhenInactive:SetRelativeWidth(0.33)
		hideBuffsWhenInactive:SetLabel("Hide Inactive Auras")
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
		auraSettings:AddChild(hideBuffsWhenInactive)

		if not LibEditModeOverride:CanEditActiveLayout() then
			AddInfoText(auraSettings, "Enable a custom edit mode profile to use this feature. Reopen the opens once you did")
		end

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
		})
		glowSettings:AddChild(glowType)

		local dynamicGlowSettingsGroup = AceGUI:Create("InlineGroup")
		dynamicGlowSettingsGroup:SetLayout("flow")
		dynamicGlowSettingsGroup:SetFullWidth(true)
		glowSettings:AddChild(dynamicGlowSettingsGroup)
		glowType:SetCallback("OnValueChanged", function(_, _, value)
			options.glowType = value
			SCM:RefreshAllGlows()
			AddCustomGlowOptions(dynamicGlowSettingsGroup)
			glowSettings:DoLayout()
			tabWidget:DoLayout()
		end)
		glowType:SetValue(options.glowType or "Pixel")
		AddCustomGlowOptions(dynamicGlowSettingsGroup)

		local pandemicGlowSettings = AceGUI:Create("InlineGroup")
		pandemicGlowSettings:SetLayout("flow")
		pandemicGlowSettings:SetFullWidth(true)
		pandemicGlowSettings:SetTitle("Pandemic Debuffs")
		tabWidget:AddChild(pandemicGlowSettings)

		local pandemicGlowOption = AceGUI:Create("Dropdown")
		pandemicGlowOption:SetList(
			{ keepPandemicGlow = "Keep", disablePandemicGlow = "Disable", replacePandemicGlow = "Replace" },
			{ "keepPandemicGlow", "disablePandemicGlow", "replacePandemicGlow" }
		)
		pandemicGlowOption:SetRelativeWidth(0.33)
		pandemicGlowOption:SetLabel("Pandemic Glow")
		pandemicGlowOption:SetValue(options.pandemicGlowOption or "keepPandemicGlow")
		pandemicGlowOption:SetCallback("OnValueChanged", function(_, _, value)
			options.pandemicGlowOption = value
		end)
		pandemicGlowSettings:AddChild(pandemicGlowOption)
	elseif group == "BuffBar" then
		local buffBarOptions = options.buffBarOptions

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
		borderSize:SetSliderValues(0, 5, 1)
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
		font:SetRelativeWidth(0.5)
		font:SetList(LSM:HashTable("font"))
		font:SetValue(buffBarOptions.font)
		font:SetCallback("OnValueChanged", function(self, event, value)
			buffBarOptions.font = value
			self:SetValue(value)
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(font)

		local fontSize = AceGUI:Create("Slider")
		fontSize:SetRelativeWidth(0.5)
		fontSize:SetLabel("Font Size")
		fontSize:SetSliderValues(1, 50, 1)
		fontSize:SetValue(buffBarOptions.fontSize)
		fontSize:SetCallback("OnValueChanged", function(self, event, value)
			buffBarOptions.fontSize = value
			SCM:SkinBuffBars()
		end)
		fontSettings:AddChild(fontSize)
	end
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
	globalSettingsTabs:SetFullHeight(true)
	globalSettingsTabs:SetLayout("flow")
	globalSettingsTabs:SetCallback("OnGroupSelected", function(self, event, group)
		SelectGlobalSettingsTab(self, group, options)
	end)
	globalSettingsTabs:SelectTab("General")
	scrollFrame:AddChild(globalSettingsTabs)
end

SCM.MainTabs.General.callback = General
