local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local LoadConditions = SCM.LoadConditions
local Cooldowns = SCM.Cooldowns
local Icons = SCM.Icons
local States = SCM.States
local Utils = SCM.Utils
local ToGlobalGroup = Utils.ToGlobalGroup
local CustomItemFrames = CustomIcons.ItemFrames
local CustomSpellFrames = CustomIcons.SpellFrames

function Cooldowns.OnCustomIconCooldownDone(self)
	local parent = self.SCMParent or self:GetParent()
	if not parent or parent.SCMReleased or not parent.SCMConfig then
		return
	end

	if parent.SCMIconType == "item" or parent.SCMIconType == "slot" then
		local wasVisible = parent.SCMShouldBeVisible
		Cooldowns.UpdateItemCooldownState(parent)
		if parent.SCMShouldBeVisible ~= wasVisible then
			SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, parent.SCMGlobal)
		end
		return
	end

	if parent.Icon and not (parent.SCMConfig.effectRules and parent.SCMConfig.effectRules.desaturate) then
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
	end

	if parent.UpdateCooldown then
		parent.isOnGCD = nil
		parent.UpdateCooldown(parent, parent.SCMIconType, parent.SCMConfig)
	end

	if parent.UpdateCharges then
		parent.UpdateCharges(parent, parent.spellID)
	end

	if parent and parent.SCMGroup then
		SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, parent.SCMGlobal)
	end
end

local function UpdateCustomIconGCD(frame, config, isOnCooldown)
	if not isOnCooldown and not frame.Cooldown:IsShown() and config.showGCD then
		local globalCooldown = C_Spell.GetSpellCooldown(61304)
		if globalCooldown and globalCooldown.isActive then
			if frame.SCMGCDStartTime ~= globalCooldown.startTime or frame.SCMGCDDuration ~= globalCooldown.duration then
				frame.SCMGCDStartTime = globalCooldown.startTime
				frame.SCMGCDDuration = globalCooldown.duration
				frame.GCDCooldown:Show()
				frame.GCDCooldown:SetReverse(false)
				frame.GCDCooldown:SetCooldown(globalCooldown.startTime, globalCooldown.duration)
			end
			return
		end
	end
	if frame.GCDCooldown:IsShown() then
		frame.GCDCooldown:Hide()
	end
	frame.SCMGCDStartTime = nil
	frame.SCMGCDDuration = nil
end

function Cooldowns.UpdateCustomIconCooldown(frame, iconType, config)
	local now = GetTime()
	local customTimerStart, customTimerDuration = CustomIcons.GetActiveCustomTimer(frame, iconType, config, now)
	if customTimerStart then
		frame.Cooldown:SetCooldown(customTimerStart, customTimerDuration)
		frame.Cooldown:SetReverse(true)
		if not (config.effectRules and config.effectRules.desaturate) then
			frame.Icon:SetDesaturated(false)
		end
		UpdateCustomIconGCD(frame, config, true)
		return true
	end

	if iconType == "spell" then
		local isOnCooldown = false
		local isChargeCooldown = false
		local spellCooldown = C_Spell.GetSpellCooldown(config.spellID)
		if spellCooldown.isActive and not spellCooldown.isOnGCD then
			local durationObject = C_Spell.GetSpellCooldownDuration(config.spellID, true)
			frame.Cooldown:Clear()
			frame.Cooldown:SetCooldownFromDurationObject(durationObject)
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon:SetDesaturated(true)
				frame.Icon:SetDesaturation(C_CurveUtil.EvaluateColorValueFromBoolean(durationObject:IsZero(), 0, 1))
			end
			isOnCooldown = true
		end

		spellCooldown = C_Spell.GetSpellCharges(config.spellID)

		if not isOnCooldown and spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
			frame.Cooldown:Clear()
			frame.Cooldown:SetCooldownFromDurationObject(C_Spell.GetSpellChargeDuration(config.spellID, true))
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon:SetDesaturated(false)
			end
			isOnCooldown = true
			isChargeCooldown = true
		end

		if not isOnCooldown then
			frame.Cooldown:Clear()
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon.SCMDesaturated = nil
				frame.Icon:SetDesaturated(false)
			end
		end

		UpdateCustomIconGCD(frame, config, isOnCooldown)

		return isOnCooldown, isChargeCooldown
	end

	if iconType == "item" or iconType == "slot" then
		local startTime, duration, modRate
		if iconType == "slot" then
			startTime, duration = GetInventoryItemCooldown("player", config.slotID)
		else
			local enabled
			startTime, duration, enabled, modRate = C_Item.GetItemCooldown(frame.SCMItemID)
		end

		local expirationTime = startTime and duration > 0 and startTime + duration / (modRate or 1) or 0
		local isOnCooldown = expirationTime > now
		if isOnCooldown and iconType == "slot" and Cooldowns.IsGlobalCooldown(startTime, duration) then
			isOnCooldown = false
		end
		if not isOnCooldown then
			expirationTime = 0
		end

		if frame.SCMCooldownExpirationTime ~= expirationTime then
			frame.isOnCooldown = isOnCooldown
			frame.SCMCooldownExpirationTime = expirationTime
			local isPendingItemCooldown = isOnCooldown and iconType == "item" and duration < 0.1
			if isOnCooldown and not isPendingItemCooldown then
				frame.Cooldown:SetCooldown(startTime, duration, modRate or 1)
			else
				frame.Cooldown:Clear()
			end
			if isPendingItemCooldown then
				frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_USABLE_COLOR:GetRGBA())
			else
				local color = iconType == "item" and frame.SCMItemCount == 0 and 0.4 or 1
				frame.Icon:SetVertexColor(color, color, color)
			end
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon:SetDesaturated(isOnCooldown and not isPendingItemCooldown)
			end
		end
		UpdateCustomIconGCD(frame, config, isOnCooldown)
		return isOnCooldown
	end

	frame.isOnCooldown = false
	frame.Cooldown:Clear()
	frame.Icon:SetVertexColor(1, 1, 1)
	if not (config.effectRules and config.effectRules.desaturate) then
		frame.Icon:SetDesaturated(false)
	end
	UpdateCustomIconGCD(frame, config, iconType == "timer")
end

function Cooldowns.GetCustomIconCooldownState(iconType, hasCount, isOnCooldown, isChargeCooldown)
	if iconType == "item" and not hasCount then
		return "noitem"
	end

	if isChargeCooldown then
		return "recharging"
	end

	return isOnCooldown and "cooldown" or "ready"
end

function Cooldowns.UpdateItemCooldownState(frame)
	local config = frame.SCMConfig
	if not LoadConditions.ShouldLoad(config) then
		return
	end

	local iconType = frame.SCMIconType
	if iconType == "item" and not frame.SCMItemCount then
		frame.SCMItemCount = C_Item.GetItemCount(frame.SCMItemID, false, true)
	end
	local isOnCooldown = Cooldowns.UpdateCustomIconCooldown(frame, iconType, config)
	local hasCount = iconType ~= "item" or frame.SCMItemCount > 0
	local cooldownState = Cooldowns.GetCustomIconCooldownState(iconType, hasCount, isOnCooldown)
	local state = frame.SCMState
	if not state or state.CooldownState ~= cooldownState then
		States.SetCooldownState(frame, cooldownState, true)
	end

	local shouldShow = SCM.isOptionsOpen or frame.SCMState.Visibility
	if frame.SCMShouldBeVisible ~= shouldShow then
		Icons.SetChildVisibilityState(frame, shouldShow, true)
	end
end

function Cooldowns.UpdateItemCooldowns(scopedGroups)
	for _, frame in pairs(CustomItemFrames) do
		if frame.SCMIconType == "item" or frame.SCMIconType == "slot" then
			local wasVisible = frame.SCMShouldBeVisible
			Cooldowns.UpdateItemCooldownState(frame)
			if frame.SCMShouldBeVisible ~= wasVisible then
				local group = frame.SCMGlobal and ToGlobalGroup(frame.SCMGroup) or frame.SCMGroup
				scopedGroups[group] = true
			end
		end
	end
end

function Cooldowns.UpdateSpellGCD(scopedGroups)
	for _, frame in pairs(CustomSpellFrames) do
		local config = frame.SCMConfig
		local group = frame.SCMGlobal and ToGlobalGroup(frame.SCMGroup) or frame.SCMGroup
		-- Scoped icons are refreshed by the layout pass.
		if config.showGCD and not scopedGroups[group] then
			Cooldowns.UpdateCustomIconCooldown(frame, frame.SCMIconType, config)
		end
	end
end
