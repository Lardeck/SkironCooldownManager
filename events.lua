local SCM = select(2, ...)
local eventFrame

function SCM:PLAYER_ENTERING_WORLD(isInitialLogin, isReload)
	if isInitialLogin or isReload then
		SCM:UpdateCooldownInfo(true)
		SCM:UpdateDB()
		SCM:ApplyOptions()

		SCM:CreateAllCustomIcons()
		SCM:ApplyAllCDManagerConfigs()
		SCM:SetHooks()
		SCM:InitializeResourceBars()
		SCM:CreateCastBar()

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
		eventFrame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
		eventFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	elseif self.isInInstance ~= IsInInstance() then
		SCM.RefreshCooldownViewerData()
	end

	self.isInInstance = IsInInstance()
end

function SCM:BAG_UPDATE_DELAYED()
	if SCM.CustomIcons.UpdateItemCountText() then
		SCM:ApplyAnchorGroupByIconType("item")
	end

	if not self.initEquipment then
		self.initEquipment = true
		C_Timer.After(1, function()
			SCM:CreateAllCustomIcons("slot")
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

local function PendingSpellCooldownPredicate(config)
	return pendingSpellCooldownIDs[config.spellID]
end

local function OnSpellCooldownUpdateThrottleTick()
	if not next(pendingSpellCooldownIDs) then
		isSpellCooldownUpdateThrottled = false
		return
	end

	isSpellCooldownUpdateThrottled = true
	C_Timer.After(0.1, OnSpellCooldownUpdateThrottleTick)
	SCM:ApplyAnchorGroupByIconTypes(false, PendingSpellCooldownPredicate, "spell", "item", "slot")
	SCM:UpdateCustomIconsGCD()
	wipe(pendingSpellCooldownIDs)
end

function SCM:SPELL_UPDATE_COOLDOWN(spellID)
	if not spellID then
		return
	end

	if isSpellCooldownUpdateThrottled then
		pendingSpellCooldownIDs[spellID] = true
		return
	end

	local predicate = function(config)
		return config.spellID == spellID
	end

	isSpellCooldownUpdateThrottled = true
	C_Timer.After(0.1, OnSpellCooldownUpdateThrottleTick)
	SCM:ApplyAnchorGroupByIconTypes(false, predicate, "spell", "item", "slot")
	SCM:UpdateCustomIconsGCD()
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

function SCM:PLAYER_REGEN_DISABLED() end
function SCM:PLAYER_REGEN_ENABLED()
	SCM.RefreshCooldownViewerData()
end

function SCM:EDIT_MODE_LAYOUTS_UPDATED()
	SCM:UpdateDB()
	SCM:ApplyOptions()
end

local function RefreshPixelPerfectLayout()
	SCM:InvalidatePixelPerfectCache()
	SCM:ApplyAllCDManagerConfigs()
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
		SCM.RefreshCooldownViewerData(true)
	end)
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
	local options = SCM.db.profile.options
	local cooldown = C_Spell.GetSpellCooldown(baseSpellID)
	if cooldown and cooldown.isActive and options.disableRegularIconActiveSwipe then
		SCM.Cooldowns.OverwriteRegularChildCooldownBySpellID(baseSpellID, overrideSpellID, cooldown)
	end
end

function SCM:SPELL_DATA_LOAD_RESULT(spellID, success)
	local requestedSpellIDs = SCM.Cache.customIconRequests.requestedSpellIDs
	if not requestedSpellIDs or not requestedSpellIDs[spellID] then
		return
	end
	requestedSpellIDs[spellID] = nil

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
