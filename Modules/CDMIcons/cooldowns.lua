local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns
local Cache = SCM.Cache
local States = SCM.States
local Constants = SCM.Constants

local function GetChildSpellID(child)
	local spellID
	if child.SCMSpellCategoryID then
		spellID = C_Spell.GetLastCategoryCooldownSource(child.SCMSpellCategoryID)
	elseif child.SCMSpellID then
		spellID = FindSpellOverrideByID(child.SCMSpellID) or child.SCMSpellID
	end

	if spellID and not issecretvalue(spellID) and Constants.CheckActiveSpell[spellID] then
		local activeSpellID = not issecretvalue(child.isActiveSpell) and child.isActiveSpell
		if activeSpellID then
			spellID = activeSpellID
		end
	end

	return spellID
end

local function IsChildOnGlobalCooldown(child)
	if child.SCMEquipSlot then
		local startTime, duration = GetInventoryItemCooldown("player", child.SCMEquipSlot)
		return startTime and startTime > 0 and duration > 0 and Cooldowns.IsGlobalCooldown(startTime, duration)
	end

	local spellID = GetChildSpellID(child)
	local cooldown = spellID and C_Spell.GetSpellCooldown(spellID)
	return cooldown and cooldown.isActive and cooldown.isOnGCD
end

local function GetChildCooldownInfo(child, includeGCD)
	if child.SCMEquipSlot then
		local now = GetTime()
		local startTime, duration = GetInventoryItemCooldown("player", child.SCMEquipSlot)
		if startTime and startTime > 0 and duration > 0 and startTime + duration > now then
			if not Cooldowns.IsGlobalCooldown(startTime, duration) then
				return "cooldown", nil, startTime, duration
			elseif includeGCD then
				return "ready", nil, startTime, duration
			end
		end

		return "ready"
	end

	if child.SCMSpellID or child.SCMSpellCategoryID then
		local cooldownData = SCM.defaultCooldownViewerConfig.cooldownIDs[child.SCMCooldownID]
		local spellID = GetChildSpellID(child)

		if spellID then
			local wasSetFromCharges = not issecretvalue(child.wasSetFromCharges) and child.wasSetFromCharges
			local wasSetFromCooldown = not issecretvalue(child.wasSetFromCooldown) and child.wasSetFromCooldown

			-- I guess just trust Blizzard :). What could go wrong
			if wasSetFromCharges then
				local spellCharges = C_Spell.GetSpellCharges(spellID)
				if spellCharges and spellCharges.isActive then
					local durationObject = C_Spell.GetSpellChargeDuration(spellID, true)
					if durationObject then
						return "recharging", durationObject
					end
				end
			elseif wasSetFromCooldown then
				local spellCooldown = C_Spell.GetSpellCooldown(spellID)
				if spellCooldown and spellCooldown.isActive and (includeGCD or not spellCooldown.isOnGCD) then
					local durationObject = C_Spell.GetSpellCooldownDuration(spellID, true)
					if durationObject then
						return spellCooldown.isOnGCD and "ready" or "cooldown", durationObject
					end
				end
			else
				local spellCooldown = C_Spell.GetSpellCooldown(spellID)
				if spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
					local durationObject = C_Spell.GetSpellCooldownDuration(spellID, true)
					if durationObject then
						return "cooldown", durationObject
					end
				end

				if cooldownData and cooldownData.charges then
					local spellCharges = C_Spell.GetSpellCharges(spellID)
					if spellCharges and spellCharges.isActive then
						local durationObject = C_Spell.GetSpellChargeDuration(spellID, true)
						if durationObject then
							return "recharging", durationObject
						end
					end
				end

				if includeGCD and spellCooldown and spellCooldown.isActive and spellCooldown.isOnGCD then
					local durationObject = C_Spell.GetSpellCooldownDuration(spellID, true)
					if durationObject then
						return "ready", durationObject
					end
				end
			end

			return "ready"
		else
			return
		end
	end
end

function Cooldowns.GetChildCooldown(child)
	if not (child.SCMEquipSlot or child.SCMSpellID or child.SCMSpellCategoryID) then
		return
	end

	local cooldownState, durationObject = GetChildCooldownInfo(child, false)
	cooldownState = cooldownState or "ready"

	if Constants.CheckCooldownFrameSpells[child.SCMSpellID] then
		return durationObject and child.Cooldown:IsVisible() and cooldownState or "ready", durationObject
	end

	return cooldownState, durationObject
end

function Cooldowns.SetNormalCooldown(self, parent)
	local options = SCM.db.profile.options
	local useAuraDisplayTime = self:GetUseAuraDisplayTime()
	local childConfig = parent.SCMConfig
	local shouldReplaceActiveSwipe = (childConfig.hideActiveSwipe or SCM.IsActiveSwipeDisabled(parent.SCMSpellID, options)) and not childConfig.forceActiveSwipe

	if useAuraDisplayTime and not shouldReplaceActiveSwipe then
		return
	end

	self.SCMSettingRegularSpellCooldown = true

	local cooldownState, durationObject, startTime, duration = GetChildCooldownInfo(parent, not options.disableGCD)
	if cooldownState then
		self:Clear()

		if durationObject then
			self:SetCooldownFromDurationObject(durationObject)
		elseif startTime then
			self:SetCooldown(startTime, duration)
		end

		States.SetCooldownState(parent, cooldownState, true)
	end

	self.SCMSettingRegularSpellCooldown = nil
end

function Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
	local config = parent.SCMConfig
	if not self:GetUseAuraDisplayTime() or config.forceActiveSwipe or not (SCM.IsActiveSwipeDisabled(parent.SCMSpellID, options) or config.hideActiveSwipe) then
		return
	end

	Cooldowns.SetNormalCooldown(self, parent)
end

local function SetRegularChildCooldown(child)
	local cooldownFrame = child.Cooldown
	if not (cooldownFrame and child.Icon) then
		return
	end

	local isActive = cooldownFrame:GetUseAuraDisplayTime()
	Cooldowns.SetNormalCooldown(cooldownFrame, child)
	States.SyncState(child, isActive, (Cooldowns.GetChildCooldown(child)))
end

local function UpdateViewerChildrenForSpellOverride(viewer, spellID, overrideSpellID, cooldownInfo)
	local children = Cache.cachedViewerChildren[viewer]
	if not children then
		children = { viewer:GetChildren() }
		Cache.cachedViewerChildren[viewer] = children
	end

	local options = SCM.db.profile.options
	for i = 1, #children do
		local child = children[i]
		local config = child.SCMConfig
		if config and not child.SCMBuffBar and child.SCMSpellID == spellID then
			States.SetOverriddenState(child, overrideSpellID and true or false)
			if cooldownInfo and not config.forceActiveSwipe and (config.hideActiveSwipe or SCM.IsActiveSwipeDisabled(child.SCMSpellID, options)) then
				SetRegularChildCooldown(child)
			end
		end
	end
end

function Cooldowns.UpdateRegularChildrenForSpellOverride(spellID, overrideSpellID, cooldownInfo)
	UpdateViewerChildrenForSpellOverride(EssentialCooldownViewer, spellID, overrideSpellID, cooldownInfo)
	UpdateViewerChildrenForSpellOverride(UtilityCooldownViewer, spellID, overrideSpellID, cooldownInfo)
end

local function OnRegularCooldownChanged(self, changeType)
	local parent = self.SCMParent or self:GetParent()
	if not (parent and parent.SCMConfig) or self.SCMSettingRegularSpellCooldown or self.SCMClearingGCD then
		return
	end

	local options = SCM.db.profile.options
	local config = parent.SCMConfig
	local useAuraDisplayTime = self:GetUseAuraDisplayTime()

	if useAuraDisplayTime then
		if not config.forceActiveSwipe and (config.hideActiveSwipe or SCM.IsActiveSwipeDisabled(parent.SCMSpellID, options)) then
			Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
		end
	elseif (options.disableGCD and IsChildOnGlobalCooldown(parent)) or (changeType == "CLEAR" and parent.SCMSpellID and Constants.FixBlizzardSpells[parent.SCMSpellID]) then
		Cooldowns.SetNormalCooldown(self, parent)
	end

	RunNextFrame(function()
		local isActive = useAuraDisplayTime
		if not issecretvalue(parent.wasSetFromAura) then
			isActive = parent.wasSetFromAura
		end

		States.SyncState(parent, isActive, (Cooldowns.GetChildCooldown(parent)))
	end)
end

function Cooldowns.SetupCooldownHooks(child, options)
	if not child.Cooldown then
		return
	end

	Cooldowns.SetupPandemicHooks(child, options)
	if child.SCMRegularCooldownHook then
		return
	end

	Cooldowns.SetupCooldownHook(child.Cooldown, function(self)
		OnRegularCooldownChanged(self, "SET")
	end)
	hooksecurefunc(child.Cooldown, "Clear", function(self)
		OnRegularCooldownChanged(self, "CLEAR")
	end)

	child.Cooldown.SCMParent = child
	child.Cooldown:HookScript("OnCooldownDone", function(self)
		OnRegularCooldownChanged(self, "DONE")
	end)
	child.SCMRegularCooldownHook = true
end
