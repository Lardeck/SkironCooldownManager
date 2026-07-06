local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")

local function AddTimerOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	if buttonData.isCustom and (buttonData.iconType == "spell" or buttonData.iconType == "timer") then
		local timerOptions = AceGUI:Create("InlineGroup")
		timerOptions:SetLayout("flow")
		timerOptions:SetFullWidth(true)
		timerOptions:SetTitle("Timer")
		iconSettingsTabs:AddChild(timerOptions)

		local castTimer = AceGUI:Create("Slider")
		castTimer:SetRelativeWidth(0.5)
		castTimer:SetSliderValues(0, 60, 0.1)
		castTimer:SetLabel("Timer Duration")
		castTimer:SetValue(buttonConfig.duration or 0)
		castTimer:SetCallback("OnValueChanged", function(_, _, value)
			buttonConfig.duration = value > 0 and value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)

		timerOptions:AddChild(castTimer)
	end
end

local function AddIconOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	local options = SCM.db.profile.options

	if not buttonData.isCustom and buttonData.iconType == "spell" then
		local glowOptions = AceGUI:Create("InlineGroup")
		glowOptions:SetLayout("flow")
		glowOptions:SetFullWidth(true)
		glowOptions:SetTitle("Glow")
		iconSettingsTabs:AddChild(glowOptions)

		local useCustomGlowColor = AceGUI:Create("CheckBox")
		useCustomGlowColor:SetLabel("Use Custom Glow Color")
		useCustomGlowColor:SetRelativeWidth(0.5)
		useCustomGlowColor:SetValue(buttonConfig.useCustomGlowColor)
		useCustomGlowColor:SetDisabled(not options.useCustomGlow)
		SCM.Utils.SetDisabledTooltip(useCustomGlowColor, "Enable 'Use Custom Glow' in Global Settings > Glow first.")
		useCustomGlowColor:SetCallback("OnValueChanged", function(self, event, value)
			buttonConfig.useCustomGlowColor = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)
		glowOptions:AddChild(useCustomGlowColor)

		local customGlowColor = AceGUI:Create("ColorPicker")
		customGlowColor:SetRelativeWidth(0.33)
		customGlowColor:SetLabel("Glow Color")
		customGlowColor:SetHasAlpha(true)
		customGlowColor:SetDisabled(not options.useCustomGlow)
		if buttonConfig.customGlowColor then
			customGlowColor:SetColor(unpack(buttonConfig.customGlowColor))
		end
		customGlowColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
			buttonConfig.customGlowColor = { r, g, b, a }
		end)
		glowOptions:AddChild(customGlowColor)
	end

	AddTimerOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
end

local function AddBuffBarOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	-- local options = SCM.db.profile.options

	local customColor = AceGUI:Create("ColorPicker")
	customColor:SetRelativeWidth(0.5)
	customColor:SetLabel("Custom Color")
	customColor:SetHasAlpha(true)
	if buttonConfig.customColor then
		customColor:SetColor(buttonConfig.customColor.r, buttonConfig.customColor.g, buttonConfig.customColor.b, buttonConfig.customColor.a)
	end
	customColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		buttonConfig.customColor = { r = r, g = g, b = b, a = a }
		SCM:SkinBuffBars()
	end)
	iconSettingsTabs:AddChild(customColor)
end

function CDMOptions.CreateGeneralTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	if not isBuffBar then
		AddIconOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	else
		AddBuffBarOptions(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	end
end
