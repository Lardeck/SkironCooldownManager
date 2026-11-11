local addonName, SCM = ...

local AceGUI = LibStub("AceGUI-3.0")
local LibEditModeOverride = LibStub("LibEditModeOverride-1.0")
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local LibWindow = LibStub("LibWindow-1.1")
local Options = SCM.Options
local Utils = SCM.Utils
local ToGlobalGroup = Utils.ToGlobalGroup
local ToBuffBarGroup = Utils.ToBuffBarGroup
local UPDATE_SCOPE = SCM.CDM.UPDATE_SCOPE
local activeSwipeConfig = SCM.Defaults.ActiveSwipeCooldownIDs
local activeSwipeSpells = activeSwipeConfig.version == select(4, GetBuildInfo()) and SCM.DefaultDB.profile.options.debuffs

StaticPopupDialogs["SCM_FORCE_RELOAD_POPUP"] = {
	text = "%s",
	button1 = RELOADUI,
	button2 = CANCEL,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(_, data)
		if data.callback then
			data.callback(data.data)
		else
			data.options[data.key] = data.value
		end
		C_UI.Reload()
	end,
	OnCancel = function(_, data)
		if data.checkbox and data.key then
			data.checkbox:SetValue(data.options[data.key])
		end
	end,
}

SCM.Tooltip = CreateFrame("GameTooltip", "SCM_GameTooltip", UIParent, "GameTooltipTemplate")

function SCM.ShowReloadPopup(data)
	StaticPopup_Show("SCM_FORCE_RELOAD_POPUP", "This requires a UI reload. Reload now?", nil, data)
end

function SCM.IsActiveSwipeDisabled(child, options)
	if options.disableRegularIconActiveSwipe then
		return true
	end

	if options.limitActiveSwipeToSelectedSpell then
		local spellID = activeSwipeSpells and activeSwipeSpells[child.SCMSpellID] and child.SCMSpellID
		if not spellID and activeSwipeSpells and not child.SCMCustom then
			spellID = activeSwipeConfig.cooldownIDs[child.SCMCooldownID]
		end
		local selectedSpell = spellID and options.debuffs[spellID]
		return not selectedSpell or not selectedSpell.enabled
	end
end

function Options.GetEffectiveAnchorGroup(anchorIndex, mode)
	if mode == "global" then
		return ToGlobalGroup(anchorIndex)
	end

	if mode == "buffbars" then
		return ToBuffBarGroup(anchorIndex)
	end

	return anchorIndex
end

function Options.ApplyModeConfigUpdate(anchorIndex, mode, refreshOptions, refreshGlowOptions)
	if mode == "global" then
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, true, nil, refreshOptions, refreshGlowOptions)
	elseif mode == "buffbars" then
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, false, UPDATE_SCOPE.BUFF_BAR, refreshOptions, refreshGlowOptions)
	else
		SCM:ApplyAllCDManagerConfigs(true, refreshOptions, refreshGlowOptions)
	end
end

function Options.IsCircularAnchor(anchorFrame, text)
	return Utils.IsAnchorDependentOn(Utils.GetAnchorFrame(text), anchorFrame)
end

function Options.SetAnchorHighlight(anchorFrame, state, color)
	local isActive = state == "active"
	if anchorFrame.SCMHighlightState == state and anchorFrame.isGlowActive == isActive then
		return
	end

	anchorFrame.SCMHighlightState = state
	anchorFrame.isGlowActive = isActive
	LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
	LibCustomGlow.PixelGlow_Start(anchorFrame, color, nil, nil, nil, nil, nil, nil, nil, "SCM")

	if anchorFrame.debugText then
		if state == "active" then
			anchorFrame.debugText:SetTextColor(0.34, 0.70, 0.91, 1)
		else
			anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)
		end
	end
end

function SCM:AddTab(tab)
	if not self.MainTabs[tab.value] and tab.callback then
		self.MainTabs[tab.value] = tab
	end

	if self.OptionsFrame and self.OptionsFrame:IsShown() then
		self.OptionsFrame:DoLayout()
	end
end

function SCM:GetHideWhenInactive()
	if LibEditModeOverride:IsReady() then
		LibEditModeOverride:LoadLayouts()
		return LibEditModeOverride:GetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive)
	end
end

function SCM:GetShowTooltip()
	if LibEditModeOverride:IsReady() then
		LibEditModeOverride:LoadLayouts()
		return LibEditModeOverride:GetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.ShowTooltips)
	end
end

local function SetViewerHideWhenInactive(viewer, value)
	if not LibEditModeOverride:IsReady() then
		return false
	end

	LibEditModeOverride:LoadLayouts()

	if not LibEditModeOverride:CanEditActiveLayout() then
		return false
	end

	local targetSetting = value and 0 or 1
	local currentSetting = LibEditModeOverride:GetFrameSetting(viewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive)
	if currentSetting ~= targetSetting then
		LibEditModeOverride:SetFrameSetting(viewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive, targetSetting)
		LibEditModeOverride:SaveOnly()
		LibEditModeOverride:ApplyChanges()
	end

	return true
end

function SCM:SetHideWhenInactive(value)
	if SetViewerHideWhenInactive(BuffIconCooldownViewer, value) then
		self.isHideWhenInactiveEnabled = not value
	end
end

function SCM:SetBuffBarHideWhenInactive(value)
	if SetViewerHideWhenInactive(BuffBarCooldownViewer, value) then
		self.isHideWhenInactiveBarsEnabled = not value
	end
end

function SCM:SetBuffBarContent(value)
	if not LibEditModeOverride:IsReady() then
		return
	end

	LibEditModeOverride:LoadLayouts()
	if LibEditModeOverride:CanEditActiveLayout() then
		local currentSetting = LibEditModeOverride:GetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.BarContent)
		if value ~= currentSetting then
			LibEditModeOverride:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.BarContent, value)
			LibEditModeOverride:SaveOnly()
			LibEditModeOverride:ApplyChanges()
		end
	end
end

function SCM:GetVisibilityConditions(options)
	if options.useCustomVisibilityCondition then
		local currentCondition = SecureCmdOptionParse(options.customVisibilityCondition)
		if currentCondition == "show" or currentCondition == "hide" then
			return options.customVisibilityCondition
		else
			return "show"
		end
	else
		local visibility = {}
		if options.hideWhileMounted then
			tinsert(visibility, "[mounted][stance:3]hide")
		end

		if options.hideWhileDead then
			tinsert(visibility, "[@player,dead]hide")
		end

		if options.hideWhileInVehicle then
			tinsert(visibility, "[@player,unithasvehicleui]hide")
		end

		if options.hideWhileResting then
			tinsert(visibility, "[resting]hide")
		end

		if options.hideOutOfCombat then
			tinsert(visibility, "[nocombat]hide")
		end

		if #visibility > 0 then
			return "[combat]show;" .. table.concat(visibility, ";") .. ";show"
		else
			return "show"
		end
	end
end

function SCM:ApplyAttributeDriver()
	if not InCombatLockdown() then
		local conditionals = SCM:GetVisibilityConditions(self.db.profile.options)
		RegisterAttributeDriver(EssentialCooldownViewer, "state-visibility", conditionals)
		RegisterAttributeDriver(UtilityCooldownViewer, "state-visibility", conditionals)
		RegisterAttributeDriver(BuffIconCooldownViewer, "state-visibility", conditionals)

		self:ApplyResourceBarAttributeDriver()
	end
end

function SCM:ApplyOptions()
	self:ApplyPressOverlayOptions()

	self:SetCursorEnabled(self.db.profile.options.enableCursor)

	if InCombatLockdown() or self.appliedOptions or not LibEditModeOverride:IsReady() then
		return
	end
	self.appliedOptions = true

	local options = self.db.profile.options
	self:SetHideWhenInactive(options.hideBuffsWhenInactive)
	self:SetBuffBarHideWhenInactive(options.disableBuffBarHideWhenInactive)
	self:SetBuffBarContent(options.buffBarContent)
	self:ApplyAttributeDriver()
	self.Cooldowns.Formatter:SetBreakpoints(options.cooldownBreakpoints)
end

local function OpenOptions()
	if InCombatLockdown() then
		SCM:Print("Can't open the options while in combat.")
		return
	end

	SCM.isOptionsOpen = true
	SCM.simulateBuffs = true

	if SCM.isForever then
		SCM:RefreshSwingTimerConfig()
	end

	local options = SCM.db.profile.options

	SCM:StopAllGlows()
	SCM:ApplyAllCDManagerConfigs()

	local frame = AceGUI:Create("SCMFrame")
	frame:SetTitle(addonName .. " - " .. C_AddOns.GetAddOnMetadata(addonName, "Version"))
	frame:SetLayout("flow")
	SCM.OptionsFrame = frame
	LibWindow.RegisterConfig(frame.frame, options.optionsWindow)
	LibWindow.SetScale(frame.frame, options.menuScale)
	local titleContainer = frame.frame.TitleContainer
	if not titleContainer.SCMPositionSaveHook then
		titleContainer.SCMPositionSaveHook = true
		titleContainer:HookScript("OnMouseUp", function(self)
			if SCM.db.profile.options.savePosition then
				LibWindow.SavePosition(self:GetParent())
			end
		end)
	end

	if options.savePosition then
		LibWindow.RestorePosition(frame.frame)
	end

	frame:SetHeight(1000)
	frame:SetWidth(850)

	local tabsTbl = {}
	for _, tab in pairs(SCM.MainTabs) do
		tinsert(tabsTbl, tab)
	end
	table.sort(tabsTbl, function(a, b)
		return a.order < b.order
	end)

	local tabs = AceGUI:Create("TabGroup")
	tabs:SetTabs(tabsTbl)
	tabs:SetWidth(frame.frame:GetWidth() - 30)
	tabs:SetFullHeight(true)
	tabs:SetLayout("fill")
	tabs:SetCallback("OnGroupSelected", function(self, event, group)
		self:ReleaseChildren()

		local options = SCM.db.profile.options
		if options.showAnchorHighlight then
			for _, anchorFrame in pairs(SCM.anchorFrames) do
				anchorFrame.debugTexture:Show()
				anchorFrame.debugText:Show()

				if group ~= "CDM" then
					anchorFrame.isGlowActive = false
					anchorFrame.SCMHighlightState = "default"
					LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
					LibCustomGlow.PixelGlow_Start(anchorFrame, nil, nil, nil, nil, nil, nil, nil, nil, "SCM")
					anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)
				end
			end
		else
			for _, anchorFrame in pairs(SCM.anchorFrames) do
				SCM:HideAnchorHighlight(anchorFrame)
			end
		end

		if SCM.MainTabs[group] then
			SCM.MainTabs[group].callback(self, frame, group)
		end
	end)
	tabs:SelectTab("General")
	frame:AddChild(tabs)

	if SCM.SkinOptionsFrame then -- Only exists if ElvUI[1] is loaded
		SCM:SkinOptionsFrame(frame, tabs)
	end
	frame:SetCallback("OnClose", function()
		SCM.OptionsFrame = nil
		SCM.isOptionsOpen = nil
		SCM.simulateBuffs = nil
		for _, anchorFrame in pairs(SCM.anchorFrames) do
			SCM:HideAnchorHighlight(anchorFrame)
		end
		SCM.RefreshCooldownViewerData(true)
		SCM.CheckForDisabledCooldowns()
		RunNextFrame(function()
			SCM:RestoreBlizzardGlows()
		end)

		if options.savePosition then
			LibWindow.SavePosition(frame.frame)
		end

		if not AceGUI:IsReleasing(frame) then
			frame:Release()
		end
	end)

	if SCM.db.profile.options.showAnchorHighlight then
		for _, anchorFrame in pairs(SCM.anchorFrames) do
			anchorFrame.debugTexture:Show()
			anchorFrame.debugText:Show()
		end
	end

	tabs.border:ClearBackdrop()
end

local function IsDisabled(categoryID)
	return categoryID < 0
		or categoryID == Enum.CooldownViewerCategory.SpecAgnosticEssential
		or categoryID == Enum.CooldownViewerCategory.EquipSlotEssential
		or categoryID == Enum.CooldownViewerCategory.SpecAgnosticTracked
		or categoryID == Enum.CooldownViewerCategory.EquipSlotTracked
end

local function IsCooldownSpell(categoryID)
	return categoryID == Enum.CooldownViewerCategory.Essential
		or categoryID == Enum.CooldownViewerCategory.Utility
		or categoryID == Enum.CooldownViewerCategory.SpecAgnosticEssential
		or categoryID == Enum.CooldownViewerCategory.EquipSlotEssential
end

local function IsCooldownBuff(categoryID)
	return categoryID == Enum.CooldownViewerCategory.TrackedBuff
		or categoryID == Enum.CooldownViewerCategory.TrackedBar
		or categoryID == Enum.CooldownViewerCategory.SpecAgnosticTracked
		or categoryID == Enum.CooldownViewerCategory.EquipSlotTracked
end

local function IsInWrongCategory(categoryID, anchorGroup)
	return (anchorGroup >= 200 and categoryID ~= Enum.CooldownViewerCategory.TrackedBar) or (anchorGroup < 100 and categoryID ~= Enum.CooldownViewerCategory.TrackedBuff)
end

local function FixCooldownCategories(data)
	local dataProvider = CooldownViewerSettings:GetDataProvider()

	for cooldownID, categoryID in pairs(data) do
		dataProvider:SetCooldownToCategory(cooldownID, categoryID)
	end

	CooldownViewerSettings:SaveCurrentLayout()
end

function SCM.GetDisabledCooldowns()
	local dataProvider = CooldownViewerSettings:GetDataProvider()
	local cooldownInfoByID = dataProvider and dataProvider.displayData and dataProvider.displayData.cooldownInfoByID

	local disabledCooldowns = {}
	for _, config in pairs(SCM.spellConfig) do
		local _, anchorGroup = next(config.source)
		local data = cooldownInfoByID and cooldownInfoByID[config.cooldownID]
		local cooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(config.cooldownID)
		if anchorGroup and data and cooldownInfo then
			local categoryID = cooldownInfo.category
			local isCooldownSpell = IsCooldownSpell(categoryID)
			local isCooldownBuff = IsCooldownBuff(categoryID)

			if IsDisabled(data.category) or (isCooldownBuff and IsInWrongCategory(data.category, anchorGroup)) then
				local targetCategoryID
				if isCooldownSpell then
					targetCategoryID = Enum.CooldownViewerCategory.Essential
				elseif isCooldownBuff then
					if anchorGroup > 200 then
						targetCategoryID = Enum.CooldownViewerCategory.TrackedBar
					else
						targetCategoryID = Enum.CooldownViewerCategory.TrackedBuff
					end
				end

				if targetCategoryID then
					disabledCooldowns[config.cooldownID] = targetCategoryID
				end
			end
		end
	end

	return disabledCooldowns
end

function SCM.CheckForDisabledCooldowns()
	if not SCM.options.checkForDisabledIcons or InCombatLockdown() then
		return
	end
	local disabledCooldowns = SCM.GetDisabledCooldowns()

	if next(disabledCooldowns) then
		StaticPopup_Show(
			"SCM_FORCE_RELOAD_POPUP",
			"|cFF4080FFSkiron|r|cFFFFFFFFCooldownManager|r detected disabled icons in Blizzards CooldownViewer. Do you want to reload to fix this automatically?",
			nil,
			{
				callback = FixCooldownCategories,
				data = disabledCooldowns,
			}
		)
	end
end

function SCM.ForceEnableDisabledCooldowns()
	local disabledCooldowns = SCM.GetDisabledCooldowns()
	FixCooldownCategories(disabledCooldowns)
end

SLASH_SCM1 = "/scm"
local function HandleMessage(msg, editBox)
	if msg == "debug" then
		local options = SCM.db.profile.options
		options.debug = not options.debug
	else
		SCM:ToggleOptions()
	end
end
SlashCmdList["SCM"] = HandleMessage

function SCM:ToggleOptions()
	if not SCM.OptionsFrame or not SCM.OptionsFrame:IsShown() then
		OpenOptions()
	else
		SCM.OptionsFrame:Release()
		SCM.OptionsFrame = nil
	end
end
