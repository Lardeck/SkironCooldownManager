local addonName, SCM = ...
local eventFrame = CreateFrame("Frame")

SCM.CDM = {}
SCM.Cache = {}
SCM.Utils = {}
SCM.CustomIcons = {}
SCM.Cooldowns = {}
SCM.Icons = {}
SCM.anchorFrames = {}
SCM.itemFrames = {}
SCM.MainTabs = {}
SCM.OptionsCallbacks = {}
SCM.Skins = {}
SCM.CustomAnchors = {}
SCM.CustomEntries = {}
SCM.Templates = {}

local function OnEssentialCooldownViewerLayout(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:InvalidateViewerChildrenCache(UtilityCooldownViewer)
	SCM:ApplyEssentialCDManagerConfig()
end

local function OnUtilityCooldownViewerLayout(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:InvalidateViewerChildrenCache(EssentialCooldownViewer)
	SCM:ApplyUtilityCDManagerConfig()
end

local function OnBuffCooldownViewerLayout(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:ApplyBuffIconCDManagerConfig()
end

local function OnBuffBarViewerLayout(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:ApplyBuffBarCDManagerConfig()
end

local function OnCooldownViewerSettingsRefreshLayout(self)
	SCM:ClearChildrenCache()
	SCM:UpdateCooldownInfo(true, self:GetDataProvider())
	SCM:UpdateDB()
	SCM:ApplyAllCDManagerConfigs()
end

local pendingCustomGlowChildren = {}
local function OnSpellAlertManagerShowAlert(_, child)
	local options = SCM.db.profile.options
	if not child.SCMConfig or not options.useCustomGlow or child.SCMActiveGlow then
		if child.SCMWidth and child.SCMHeight then
			local width = child.SCMWidth
			local height = child.SCMHeight

			local alert = child.SpellActivationAlert
			alert:SetSize(width * 1.4, height * 1.4)

			if alert.ProcStartFlipbook then
				alert.ProcStartFlipbook:SetSize((width / 42) * 150, (height / 42) * 150)
			end
		end
		return
	end

	child.SCMActiveGlow = true
	child.SpellActivationAlert:Hide()

	-- The size of the glow is too large when you start the glow immediately if anyone is wondering why I do that
	pendingCustomGlowChildren[child] = C_Timer.NewTimer(0, function()
		SCM:StartCustomGlow(child)
	end)
end

local function OnSpellAlertManagerHideAlert(_, child)
	if child.SCMConfig and child.SCMActiveGlow then
		if pendingCustomGlowChildren[child] then
			pendingCustomGlowChildren[child]:Cancel()
			pendingCustomGlowChildren[child] = nil
		end

		child.SCMActiveGlow = nil
		SCM:StopCustomGlow(child)
	end
end

local function RefreshCooldownViewerData(releaseCustomIcons)
	SCM:InvalidateAnchorLinks()
	SCM:ClearViewerChildrenCache()
	SCM:UpdateCooldownInfo(true, CooldownViewerSettings:GetDataProvider())
	SCM:UpdateDB()

	if releaseCustomIcons then
		SCM.CustomIcons.ReleaseAllIcons()
	end
	SCM:CreateAllCustomIcons()
	SCM:ApplyAllCDManagerConfigs()
	SCM:UpdateCastBar()
	SCM:RefreshResourceBarConfig()
end
SCM.RefreshCooldownViewerData = RefreshCooldownViewerData

function SCM:SetHooks()
	hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", OnEssentialCooldownViewerLayout)
	hooksecurefunc(UtilityCooldownViewer, "RefreshLayout", OnUtilityCooldownViewerLayout)
	hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", OnBuffCooldownViewerLayout)
	hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", OnBuffBarViewerLayout)
	hooksecurefunc(CooldownViewerSettings, "RefreshLayout", OnCooldownViewerSettingsRefreshLayout)

	if ActionButtonSpellAlertManager then
		hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", OnSpellAlertManagerShowAlert)
		hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", OnSpellAlertManagerHideAlert)
	end

	hooksecurefunc(UIParent, "SetScale", function()
		RefreshCooldownViewerData(true)
	end)
end

function SCM:PLAYER_ENTERING_WORLD(isInitialLogin, isReload)
	if isInitialLogin or isReload then
		SCM:UpdateCooldownInfo(true, CooldownViewerSettings:GetDataProvider())
		SCM:UpdateDB()

		SCM:CreateAllCustomIcons()
		SCM:ApplyAllCDManagerConfigs()
		SCM:SetHooks()
		SCM:InitializeResourceBars()
		SCM:CreateCastBar()
	elseif self.isInInstance ~= IsInInstance() then
		RefreshCooldownViewerData()
	end

	self.isInInstance = IsInInstance()
end

function SCM:BAG_UPDATE_DELAYED()
	SCM.CustomIcons.UpdateItemCountText()
end

function SCM:UNIT_SPELLCAST_SUCCEEDED(_, _, spellID)
	SCM:ApplySuccessfulCastBySpellID(spellID)
end

function SCM:SPELL_UPDATE_COOLDOWN(spellID)
	local predicate = function(config)
		return config.spellID == spellID or config.iconType == "item"
	end

	SCM.CustomIcons.UpdateItemCountText(spellID)
	SCM:ApplyAnchorGroupByIconTypes(false, predicate, "spell", "item", "slot")
	SCM:UpdateCustomIconsGCD()
end

function SCM:SPELL_UPDATE_CHARGES()
	SCM:ApplyAnchorGroupByIconTypes(false, nil, "spell")
end

function SCM:PLAYER_EQUIPMENT_CHANGED()
	SCM:CreateAllCustomIcons()
	SCM:ApplyAllCDManagerConfigs()
end

function SCM:PLAYER_EQUIPED_SPELLS_CHANGED()
	C_Timer.After(0.1, function()
		SCM:CreateAllCustomIcons("slot")
		SCM:ApplyAllCDManagerConfigs()
	end)
	
	eventFrame:UnregisterEvent("PLAYER_EQUIPED_SPELLS_CHANGED")
end

function SCM:PLAYER_REGEN_ENABLED()
	if not self.appliedOptions then
		self:ApplyOptions()
	end

	SCM:ApplyAllCDManagerConfigs()
end

function SCM:PLAYER_REGEN_DISABLED() end

function SCM:EDIT_MODE_LAYOUTS_UPDATED()
	SCM:ApplyOptions()
end

local function RefreshLayoutAfterScaleChange()
	SCM:ApplyAllCDManagerConfigs()
end

function SCM:TRAIT_CONFIG_UPDATED()
	C_Timer.After(0.5, function()
		RefreshCooldownViewerData()
		SCM:RefreshResourceBarConfig()
	end)
end

function SCM:ACTIVE_PLAYER_SPECIALIZATION_CHANGED()
	C_Timer.After(0.5, function()
		RefreshCooldownViewerData(true)
		SCM:RefreshResourceBarConfig()
	end)
end

function SCM:UI_SCALE_CHANGED()
	RefreshLayoutAfterScaleChange()
end

function SCM:DISPLAY_SIZE_CHANGED()
	RefreshLayoutAfterScaleChange()
end

function SCM:CVAR_UPDATE(cvarName)
	if cvarName == "uiScale" then
		RefreshLayoutAfterScaleChange()
	end
end

function SCM:SPELL_DATA_LOAD_RESULT(spellID, success)
	if success then
		SCM.CustomIcons.CreateSpellIcon(spellID)
	end
end

function SCM:ITEM_DATA_LOAD_RESULT(itemID, success)
	if success then
		SCM.CustomIcons.CreateItemIcon(itemID)
	end
end

local function OnProfileChanged(_, _, _, skipReset)
	-- Hopefully players won't change profiles that much that we reach the frame limit :)
	if not skipReset then
		SCM.DB:ResetData()
	end

	SCM:InvalidateAnchorLinks()

	RefreshCooldownViewerData(true)

	local options = SCM.db.profile.options
	if SCM.OptionsFrame and SCM.OptionsFrame:IsShown() and options and options.showAnchorHighlight then
		for _, anchorFrame in pairs(SCM.anchorFrames) do
			anchorFrame.debugTexture:Show()
			anchorFrame.debugText:Show()
		end
	end
end

function SCM:LoadNewProfile()
	OnProfileChanged(nil, nil, nil, true)
end

local function OnEventFrameEvent(_, event, ...)
	if SCM[event] then
		SCM[event](SCM, ...)
	end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
	SCM.db = LibStub("AceDB-3.0"):New(addonName .. "DB", SCM.DefaultDB, true)
	SCM.LibDualSpec = LibStub("LibDualSpec-1.0")
	SCM.LibDualSpec:EnhanceDatabase(SCM.db, addonName)
	SCM:MigrateLegacyProfileOptions()
	SCM.db.RegisterCallback(SCM, "OnProfileChanged", OnProfileChanged)
	SCM.db.RegisterCallback(SCM, "OnProfileCopied", OnProfileChanged)
	SCM.db.RegisterCallback(SCM, "OnProfileReset", OnProfileChanged)

	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	eventFrame:RegisterEvent("PLAYER_EQUIPED_SPELLS_CHANGED")
	eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
	eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
	eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
	eventFrame:RegisterEvent("UI_SCALE_CHANGED")
	eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
	eventFrame:RegisterEvent("CVAR_UPDATE")
	eventFrame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
	eventFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
	eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	eventFrame:SetScript("OnEvent", OnEventFrameEvent)

	SCM:GetAnchor(1)
	C_CVar.SetCVar("cooldownViewerEnabled", "1")
end)

function SCM:GetConfigTable(iconType, isGlobal)
	if iconType == "spell" then
		return isGlobal and self.globalCustomConfig.spellConfig or self.customConfig.spellConfig
	end

	if iconType == "slot" then
		return isGlobal and self.globalCustomConfig.slotConfig or self.customConfig.slotConfig
	end

	if iconType == "timer" then
		return isGlobal and self.globalCustomConfig.timerConfig or self.customConfig.timerConfig
	end

	return isGlobal and self.globalCustomConfig.itemConfig or self.customConfig.itemConfig
end

function SCM:GetConfigTableByID(configID, iconType, isGlobal)
	local configTable = self:GetConfigTable(iconType, isGlobal)
	return configTable and configTable[configID]
end
