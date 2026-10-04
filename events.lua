local addonName, SCM = ...
local eventFrame
local registeredEvents = {}

local SCMLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "data source",
	text = addonName,
	icon = "Interface/AddOns/SkironCooldownManager/Media/Logo.png",
	OnClick = function(_, button)
		if button == "LeftButton" then
			SCM:ToggleOptions()
		end
	end,
})

function SCM:RegisterEvent(event)
	if not registeredEvents[event] then
		registeredEvents[event] = true
		eventFrame:RegisterEvent(event)
	end
end

function SCM:UnregisterEvent(event)
	if registeredEvents[event] then
		registeredEvents[event] = nil
		eventFrame:UnregisterEvent(event)
	end
end

function SCM:PLAYER_ENTERING_WORLD(isInitialLogin, isReload)
	if isInitialLogin or isReload then
		SCM.build = select(4, GetBuildInfo())
		SCM.isForever = SCM.build >= 16000 and SCM.build < 20000
		SCM.options = SCM.db.profile.options

		SCM.PrepareCooldownViewerData()
		SCM:InitializeAllAnchorFrames()
		SCM:ApplyOptions()

		SCM:SetHooks()
		SCM.RefreshCooldownViewerLayout()

		eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
		eventFrame:RegisterEvent("SPELL_UPDATE_USES")
		eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
		eventFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
		eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
		eventFrame:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED")
		eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
		eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
		eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
		eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
		eventFrame:RegisterEvent("UI_SCALE_CHANGED")
		eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
		eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
		eventFrame:RegisterEvent("CVAR_UPDATE")
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

		SCM.initialized = true
		SCM.InCombatLockdown = InCombatLockdown()
		SCM.Callbacks:Fire("SCM_Ready")
		SCM.CheckForDisabledCooldowns()

		LibStub("LibDBIcon-1.0"):Register(addonName, SCMLDB, SCM.options.minimapButton)
	elseif self.isInInstance ~= IsInInstance() then
		SCM.RefreshCooldownViewerData(false, true)
	end

	self.isInInstance = IsInInstance()
	self.refreshEquipmentSlotIcons = true
end

function SCM:BAG_UPDATE_DELAYED()
	if SCM.CustomIcons.UpdateItemCountText() then
		SCM:ApplyAnchorGroupByIconType("item")
	end

	if self.refreshEquipmentSlotIcons and not self.InCombatLockdown then
		self.refreshEquipmentSlotIcons = nil
		C_Timer.After(0, function()
			SCM.CustomIcons.CreateIcons(SCM.customConfig.slotConfig, false, "slot")
			SCM.CustomIcons.CreateIcons(SCM.globalCustomConfig.slotConfig, true, "slot")
			SCM:ApplyAnchorGroupByIconType("slot")
		end)
	end
end

function SCM:ITEM_DATA_LOAD_RESULT(itemID, success)
	local requestedItemIDs = SCM.Cache.customIconRequests.requestedItemIDs
	if not requestedItemIDs or not requestedItemIDs[itemID] then
		return
	end
	requestedItemIDs[itemID] = nil
	if not next(requestedItemIDs) then
		SCM:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
	end

	if success then
		SCM.CustomIcons.CreateItemIcon(itemID)
	end
end

function SCM:ACTIONBAR_SLOT_CHANGED(actionSlot)
	local actionType, itemID = GetActionInfo(actionSlot)
	if actionType ~= "item" or not itemID then
		return
	end

	SCM.CustomIcons.UpdateItemCountForItemID(itemID)
end

function SCM:UNIT_SPELLCAST_SUCCEEDED(_, _, spellID)
	SCM:ApplySuccessfulCastBySpellID(spellID)
end

local isSpellCooldownUpdateThrottled = false
local pendingSpellCooldownIDs = {}

local function OnSpellCooldownUpdateThrottleTick()
	isSpellCooldownUpdateThrottled = false

	SCM:UpdateCustomCooldowns(pendingSpellCooldownIDs)
	wipe(pendingSpellCooldownIDs)
end

local function QueueCooldownUpdate()
	if isSpellCooldownUpdateThrottled then
		return
	end

	isSpellCooldownUpdateThrottled = true
	C_Timer.After(0.1, OnSpellCooldownUpdateThrottleTick)
end

function SCM:SPELL_UPDATE_COOLDOWN(spellID)
	if spellID then
		pendingSpellCooldownIDs[spellID] = true
	end
	QueueCooldownUpdate()
end

function SCM:SPELL_UPDATE_USABLE()
	SCM.CustomIcons.UpdateSpellUsability()
end

function SCM:SPELL_RANGE_CHECK_UPDATE(spellID, isInRange, checksRange)
	SCM.CustomIcons.UpdateSpellRange(spellID, isInRange, checksRange)
end

function SCM:SPELL_UPDATE_CHARGES()
	SCM:ApplyAnchorGroupByIconTypes(false, nil, "spell")
end

function SCM:SPELL_UPDATE_USES(spellID, baseSpellID)
	SCM.CustomIcons.UpdateSpellUses(spellID, baseSpellID)
end

function SCM:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellID, ...)
	SCM.CustomIcons.UpdateSpellGlow(spellID, "SHOW")
end

function SCM:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellID)
	SCM.CustomIcons.UpdateSpellGlow(spellID, "HIDE")
end

function SCM:PLAYER_EQUIPMENT_CHANGED()
	if self.initialized and self.InCombatLockdown then
		self.refreshEquipmentSlotIcons = true
		return
	end

	self.refreshEquipmentSlotIcons = nil
	SCM:CreateAllCustomIcons("slot")
	SCM:ApplyAnchorGroupByIconType("slot")
end

function SCM:PLAYER_EQUIPED_SPELLS_CHANGED()
	C_Timer.After(1, function()
		SCM:CreateAllCustomIcons("slot")
		SCM:ApplyAnchorGroupByIconType("slot")
	end)

	eventFrame:UnregisterEvent("PLAYER_EQUIPED_SPELLS_CHANGED")
end

function SCM:PLAYER_REGEN_DISABLED()
	self.InCombatLockdown = true
end
function SCM:PLAYER_REGEN_ENABLED()
	self.InCombatLockdown = nil

	if not self.appliedOptions then
		self:ApplyOptions()
		SCM.RefreshCooldownViewerData()
		return
	end

	if self.refreshEquipmentSlotIcons then
		self:PLAYER_EQUIPMENT_CHANGED()
	end
	QueueCooldownUpdate()

	if self.SCMRefreshMatchedBuffBarWidths then
		self.SCMRefreshMatchedBuffBarWidths = nil
		self:ApplyBuffBarCDManagerConfig()
	end
end

function SCM:EDIT_MODE_LAYOUTS_UPDATED()
	if not self.appliedOptions then
		self:ApplyOptions()
	end
	SCM.RefreshCooldownViewerData(false, true)
end

function SCM:TRAIT_CONFIG_UPDATED()
	C_Timer.After(0.5, function()
		SCM.RefreshCooldownViewerData(true)
	end)
end

function SCM:ACTIVE_PLAYER_SPECIALIZATION_CHANGED()
	SCM:ResetCooldownViewerRuntimeState()
	SCM:ResetResourceBar()

	C_Timer.After(0.5, function()
		SCM:ResetAnchors()
		SCM:ResetCastBar()
		SCM.RefreshCooldownViewerData(true)
	end)
end

local function RefreshPixelPerfectLayout()
	SCM:InvalidatePixelPerfectCache()
	SCM:ApplyAllCDManagerConfigs()
end

function SCM:UI_SCALE_CHANGED()
	RefreshPixelPerfectLayout()
end

function SCM:DISPLAY_SIZE_CHANGED()
	RefreshPixelPerfectLayout()
end

function SCM:CVAR_UPDATE(cvarName)
	if cvarName == "uiScale" then
		RefreshPixelPerfectLayout()
	end
end

function SCM:COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED(baseSpellID, overrideSpellID)
	local cooldown = C_Spell.GetSpellCooldown(baseSpellID)
	if not (cooldown and cooldown.isActive) then
		cooldown = nil
	end

	SCM.Cooldowns.UpdateRegularChildrenForSpellOverride(baseSpellID, overrideSpellID, cooldown)
end

function SCM:SPELL_DATA_LOAD_RESULT(spellID, success)
	local requestedSpellIDs = SCM.Cache.customIconRequests.requestedSpellIDs
	if not requestedSpellIDs or not requestedSpellIDs[spellID] then
		return
	end
	requestedSpellIDs[spellID] = nil
	if not next(requestedSpellIDs) then
		SCM:UnregisterEvent("SPELL_DATA_LOAD_RESULT")
	end

	if success then
		SCM.CustomIcons.CreateSpellIcon(spellID)
	end
end

function SCM.InitializeEventFrame()
	eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:SetScript("OnEvent", function(_, event, ...)
		if SCM[event] then
			SCM[event](SCM, ...)
		end
	end)
end
