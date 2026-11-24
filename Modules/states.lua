local SCM = select(2, ...)

local States = SCM.States
local Icons = SCM.Icons
local ToGlobalGroup = SCM.Utils.ToGlobalGroup
local UpdateChildDesaturation = Icons.UpdateChildDesaturation

local GLOBAL_GLOW_SUBREGION = SCM.Constants.GENERAL.GLOBAL_GLOW_SUBREGION
local DEFAULT_BORDER_COLOR = { r = 1, g = 1, b = 1, a = 1 }

local trackedUsabilitySpells = {}

function States.HasEffectRules(config, effectKey)
	local effectConfig = config and config.effectRules and config.effectRules[effectKey]
	local rules = effectConfig and effectConfig.rules
	return rules and rules[1] ~= nil or false
end

function States.PruneEffectRules(config, effectKey)
	local effectRules = config and config.effectRules
	if not effectRules then
		return
	end

	if effectKey then
		local effectConfig = effectRules[effectKey]
		local rules = effectConfig and effectConfig.rules
		if effectConfig and (not rules or not rules[1]) then
			effectRules[effectKey] = nil
		end
	end

	if not next(effectRules) then
		config.effectRules = nil
	end
end

local function DoesRuleMatchState(ruleState, state)
	if not ruleState then
		return false
	end

	if ruleState == "always" or ruleState == state.CooldownState then
		return true
	end

	if ruleState == "active" then
		return state.Active and true or false
	end

	if ruleState == "inactive" then
		return state.Active == false
	end

	if ruleState == "overridden" then
		return state.Overridden and true or false
	end

	if ruleState == "usableSpell" then
		return state.TrackedSpell and state.TrackedSpell.usable and true or false
	end

	return false
end

local function GetFirstMatchedRule(rules, state, skipActiveFalse)
	for index = 1, #rules do
		local rule = rules[index]
		local ruleState = rule.state
		if DoesRuleMatchState(ruleState, state) and not (skipActiveFalse and ruleState == "active" and rule.enabled == false) then
			return rule
		end
	end
end

local function GetNextMatchedRule(rules, index, state)
	local ruleCount = #rules

	while index <= ruleCount do
		local rule = rules[index]
		index = index + 1

		if DoesRuleMatchState(rule.state, state) then
			while index <= ruleCount and rules[index].elseIf do
				index = index + 1
			end

			return rule, index
		end
	end
end

local function GetOrCreateState(child)
	local state = child.SCMState
	if not state then
		state = { Visibility = true }
		child.SCMState = state
	end

	return state
end

local function HasUsableSpellRule(effectRules)
	if not effectRules then
		return false
	end

	for _, effect in pairs(effectRules) do
		local rules = effect.rules
		if rules then
			for index = 1, #rules do
				if rules[index].state == "usableSpell" then
					return true
				end
			end
		end
	end

	return false
end

function States.StopStateGlows(child)
	local state = child and child.SCMState
	local activeStateGlows = state and state.ActiveStateGlows
	if not activeStateGlows then
		return
	end

	for key, activeStateGlow in pairs(activeStateGlows) do
		SCM:StopCustomGlow(activeStateGlow.frame, key, activeStateGlow.glowType)
		activeStateGlows[key] = nil
	end

	state.ActiveStateGlows = nil
end

local function GetGlowOptions(config, subregion)
	if subregion == GLOBAL_GLOW_SUBREGION then
		local options = SCM.db.profile.options
		local glowType = options.glowType
		local glowTypeOptions = glowType and options.glowTypeOptions and options.glowTypeOptions[glowType]
		return glowType, glowTypeOptions
	end

	local subregionOptions = config.subregionOptions and config.subregionOptions.glow
	local glowOptions = subregionOptions and subregionOptions[subregion]
	local glowType = glowOptions and glowOptions.glowType
	local glowTypeOptions = glowType and glowOptions.glowTypeOptions and glowOptions.glowTypeOptions[glowType]
	return glowType, glowTypeOptions
end

local function ApplyGlowRules(child, state, config, effectConfig, refreshGlowOptions)
	local rules = effectConfig and effectConfig.rules
	local activeStateGlows = state.ActiveStateGlows
	if not rules or not rules[1] then
		if activeStateGlows then
			States.StopStateGlows(child)
		end
		return
	end

	state.GlowRefreshID = (state.GlowRefreshID or 0) + 1
	local refreshID = state.GlowRefreshID

	local rule, index = GetNextMatchedRule(rules, 1, state)
	while rule do
		local glowType, glowTypeOptions = GetGlowOptions(config, rule.subregion)
		local glowFrame = child
		if rule.subregionTargetType == "custom" then
			glowFrame = _G[rule.subregionTargetCustom]
		end

		if glowTypeOptions and glowFrame then
			local key = "SCMStateGlow_" .. tostring(rule.state) .. "_" .. tostring(rule.subregion)
			activeStateGlows = activeStateGlows or {}
			state.ActiveStateGlows = activeStateGlows

			local activeStateGlow = activeStateGlows[key]
			if refreshGlowOptions or not activeStateGlow or activeStateGlow.glowType ~= glowType or activeStateGlow.frame ~= glowFrame then
				if activeStateGlow then
					SCM:StopCustomGlow(activeStateGlow.frame, key, activeStateGlow.glowType)
				end

				if glowType == "Button" then
					for activeKey, currentStateGlow in pairs(activeStateGlows) do
						if activeKey ~= key and currentStateGlow.glowType == "Button" and currentStateGlow.frame == glowFrame then
							SCM:StopCustomGlow(currentStateGlow.frame, activeKey, currentStateGlow.glowType)
							activeStateGlows[activeKey] = nil
						end
					end
				end

				SCM:StartCustomGlow(child, glowTypeOptions, glowType, key, true, true, glowFrame)
				activeStateGlow = {
					glowType = glowType,
					frame = glowFrame,
				}
				activeStateGlows[key] = activeStateGlow
			end

			activeStateGlow.RefreshID = refreshID
		end

		rule, index = GetNextMatchedRule(rules, index, state)
	end

	if not activeStateGlows then
		return
	end

	for key, activeStateGlow in pairs(activeStateGlows) do
		if activeStateGlow.RefreshID ~= refreshID then
			SCM:StopCustomGlow(activeStateGlow.frame, key, activeStateGlow.glowType)
			activeStateGlows[key] = nil
		end
	end

	if not next(activeStateGlows) then
		state.ActiveStateGlows = nil
	end
end

local function HideAllStateBorders(child)
	local state = child and child.SCMState
	local activeBorders = state and state.ActiveStateBorders
	if not activeBorders then
		return
	end

	local borders = child.SCMStateBorders
	for key in pairs(activeBorders) do
		local border = borders and borders[key]
		if border then
			border:Hide()
			border.SCMStateBorderShown = false
		end
		activeBorders[key] = nil
	end

	state.ActiveStateBorders = nil
end
States.HideAllStateBorders = HideAllStateBorders

local function ShowStateBorder(child, state, targetFrame, key, borderOptions, refreshID)
	local borders = child.SCMStateBorders
	if not borders then
		borders = {}
		child.SCMStateBorders = borders
	end

	local border = borders[key]
	if not border then
		border = CreateFrame("Frame", nil, targetFrame, "BackdropTemplate")
		border:SetFrameLevel(targetFrame:GetFrameLevel() + 3)
		border:SetAllPoints(targetFrame)
		borders[key] = border
	elseif border:GetParent() ~= targetFrame then
		border:SetParent(targetFrame)
		border:SetFrameLevel(targetFrame:GetFrameLevel() + 3)
		border:ClearAllPoints()
		border:SetAllPoints(targetFrame)
	end

	local options = SCM.db.profile.options
	local borderSize = borderOptions.borderSize or options.borderSize or 1
	local borderColor = borderOptions.borderColor or options.borderColor or DEFAULT_BORDER_COLOR
	local r, g, b, a = borderColor.r or 1, borderColor.g or 1, borderColor.b or 1, borderColor.a or 1

	if borderSize == 0 then
		if border.SCMStateBorderShown ~= false then
			border:Hide()
			border.SCMStateBorderShown = false
		end
	else
		if border.SCMStateBorderSize ~= borderSize then
			border:SetBackdrop({
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				edgeSize = borderSize,
			})
			border.SCMStateBorderSize = borderSize

			local regions = { border:GetRegions() }
			for index = 1, #regions do
				local region = regions[index]
				region:SetTexelSnappingBias(0)
				region:SetSnapToPixelGrid(false)
			end
		end

		border:SetBackdropBorderColor(r, g, b, a)

		if not border.SCMStateBorderShown then
			border:Show()
			border.SCMStateBorderShown = true
		end
	end

	local activeBorders = state.ActiveStateBorders
	if not activeBorders then
		activeBorders = {}
		state.ActiveStateBorders = activeBorders
	end

	activeBorders[key] = refreshID
end

local function ApplyBorderRules(child, state, config, effectConfig)
	local rules = effectConfig and effectConfig.rules
	local activeBorders = state.ActiveStateBorders
	if not rules or not rules[1] then
		if activeBorders then
			HideAllStateBorders(child)
		end
		return
	end

	local subregionOptions = config.subregionOptions and config.subregionOptions.border
	if not subregionOptions or not subregionOptions[1] then
		if activeBorders then
			HideAllStateBorders(child)
		end
		return
	end

	state.BorderRefreshID = (state.BorderRefreshID or 0) + 1
	local refreshID = state.BorderRefreshID

	local rule, index = GetNextMatchedRule(rules, 1, state)
	while rule do
		local borderOptions = subregionOptions[rule.subregion]
		local targetFrame = child
		if rule.subregionTargetType == "custom" then
			targetFrame = _G[rule.subregionTargetCustom]
		end

		if borderOptions and targetFrame then
			local key = "SCMStateBorder_" .. tostring(rule.state) .. "_" .. tostring(rule.subregion)
			ShowStateBorder(child, state, targetFrame, key, borderOptions, refreshID)
		end

		rule, index = GetNextMatchedRule(rules, index, state)
	end

	activeBorders = state.ActiveStateBorders
	if not activeBorders then
		return
	end

	local borders = child.SCMStateBorders
	for key in pairs(activeBorders) do
		if activeBorders[key] ~= refreshID then
			local border = borders and borders[key]
			if border then
				border:Hide()
				border.SCMStateBorderShown = false
			end
			activeBorders[key] = nil
		end
	end

	if not next(activeBorders) then
		state.ActiveStateBorders = nil
	end
end

local function ApplyCooldownRules(child, state, effectConfig)
	if not child.Cooldown then
		return
	end

	local rules = effectConfig and effectConfig.rules
	local rule = rules and rules[1] and GetFirstMatchedRule(rules, state)
	state.CooldownRule = rule
	if rule then
		SCM.ApplyCooldownRule(child.Cooldown, rule)
		return
	end

	SCM.ResetCooldownRule(child.Cooldown, child, state.CooldownState)
end

local function ApplyVisibilityRules(state, effectRules)
	local visibilityRules = effectRules and effectRules.visibility and effectRules.visibility.rules
	local visibilityRule = visibilityRules and visibilityRules[1] and GetFirstMatchedRule(visibilityRules, state)
	local shouldShow = not visibilityRule or visibilityRule.value ~= "hide"
	local visibilityChanged = state.Visibility ~= shouldShow
	state.Visibility = shouldShow
	return visibilityChanged
end

local function ApplyDesaturateRules(child, state, config, effectRules)
	local desaturateRules = effectRules and effectRules.desaturate and effectRules.desaturate.rules
	local shouldDesaturate
	if desaturateRules and desaturateRules[1] then
		local skipActiveFalse = SCM.IsActiveSwipeDisabled(child, SCM.db.profile.options) and not config.forceActiveSwipe and not child.SCMBuffOptions and not child.SCMBuffBar
		local rule = GetFirstMatchedRule(desaturateRules, state, skipActiveFalse)
		if rule and rule.enabled ~= nil then
			shouldDesaturate = rule.enabled and true or false
		end
	end

	if shouldDesaturate ~= nil then
		if state.Desaturate ~= shouldDesaturate then
			state.Desaturate = shouldDesaturate
			UpdateChildDesaturation(child, shouldDesaturate, true)
		end
	elseif state.Desaturate ~= nil then
		state.Desaturate = nil
		UpdateChildDesaturation(child, false)
	end
end

local function EvaluateEffects(child, state, config, refreshGlowOptions)
	local effectRules = config.effectRules
	local visibilityChanged = ApplyVisibilityRules(state, effectRules)

	ApplyDesaturateRules(child, state, config, effectRules)

	if effectRules and effectRules.glow then
		ApplyGlowRules(child, state, config, effectRules.glow, refreshGlowOptions)
	elseif state.ActiveStateGlows then
		States.StopStateGlows(child)
	end

	if effectRules and effectRules.border then
		ApplyBorderRules(child, state, config, effectRules.border)
	elseif state.ActiveStateBorders then
		HideAllStateBorders(child)
	end

	state.Initialized = true
	return visibilityChanged
end

local function TriggerLayoutRefresh(child)
	SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, child.SCMGlobal, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
end

function States.UntrackSpellUsability(child)
	local state = child and child.SCMState
	if not state then
		return
	end

	local spell = state.TrackedSpell
	state.UsabilitySpellID = nil
	if not spell then
		return
	end

	state.TrackedSpell = nil
	spell.children[child] = nil
	if not next(spell.children) then
		trackedUsabilitySpells[spell.id] = nil
	end
end

local function GetSpellUsable(spellID)
	local usable = C_Spell.IsSpellUsable(spellID)
	if issecretvalue(usable) then
		return nil
	end

	return usable and true or false
end

function States.SyncSpellUsability(child, spellID, refreshOptions)
	local config = child and child.SCMConfig
	if not config then
		return false
	end

	local state = child.SCMState
	if not spellID then
		if not state then
			return false
		end

		local hadTrackedSpell = state.TrackedSpell ~= nil
		States.UntrackSpellUsability(child)
		return hadTrackedSpell
	end

	if not refreshOptions and state and state.UsabilitySpellID == spellID then
		return false
	end

	local shouldTrack = HasUsableSpellRule(config.effectRules)
	local previousSpell = state and state.TrackedSpell

	if previousSpell and (not shouldTrack or previousSpell.id ~= spellID) then
		States.UntrackSpellUsability(child)
	end

	if shouldTrack then
		state = GetOrCreateState(child)
		if not state.TrackedSpell then
			local spell = trackedUsabilitySpells[spellID]
			if not spell then
				spell = {
					id = spellID,
					children = {},
					usable = GetSpellUsable(spellID) or false,
				}
				trackedUsabilitySpells[spellID] = spell
			end

			spell.children[child] = true
			state.TrackedSpell = spell
		end

		state.UsabilitySpellID = spellID
	elseif state then
		state.UsabilitySpellID = spellID
	end

	return previousSpell ~= (state and state.TrackedSpell)
end

function States.Reset(child)
	if not child then
		return
	end

	States.StopStateGlows(child)
	HideAllStateBorders(child)
	States.UntrackSpellUsability(child)

	local state = child.SCMState
	if state and state.Desaturate ~= nil then
		UpdateChildDesaturation(child, false)
	end

	child.SCMState = nil
end

function States.RestoreVisualEffects(child)
	local config = child and child.SCMConfig
	local state = child and child.SCMState
	if not (config and state and state.Initialized) then
		return
	end

	local effectRules = config.effectRules
	if not effectRules then
		return
	end

	if effectRules.glow and not state.ActiveStateGlows then
		ApplyGlowRules(child, state, config, effectRules.glow)
	end

	if effectRules.border and not state.ActiveStateBorders then
		ApplyBorderRules(child, state, config, effectRules.border)
	end
end

local function ApplyStateMutations(state, isActive, cooldownState, isOverridden)
	local activeChanged = isActive ~= nil and state.Active ~= isActive
	local cooldownChanged = cooldownState ~= nil and state.CooldownState ~= cooldownState
	local overriddenChanged = isOverridden ~= nil and state.Overridden ~= isOverridden

	if activeChanged then
		state.Active = isActive
	end

	if cooldownChanged then
		state.CooldownState = cooldownState
	end

	if overriddenChanged then
		state.Overridden = isOverridden
	end

	return activeChanged, cooldownChanged, overriddenChanged
end

local function UpdateState(child, isActive, cooldownState, isOverridden, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	local config = child and child.SCMConfig
	if not config then
		return
	end

	local state = GetOrCreateState(child)
	local effectRules = config.effectRules
	local activeChanged, cooldownChanged, overriddenChanged = ApplyStateMutations(state, isActive, cooldownState, isOverridden)

	local cooldownEffect = effectRules and effectRules.cooldown
	if cooldownState ~= nil or (cooldownEffect and (activeChanged or overriddenChanged or refreshOptions)) or (refreshOptions and state.CooldownRule) then
		ApplyCooldownRules(child, state, cooldownEffect)
	end

	if not (refreshOptions or refreshGlowOptions or activeChanged or cooldownChanged or overriddenChanged or not state.Initialized) then
		return
	end

	if not effectRules and state.Visibility and state.Desaturate == nil and not state.ActiveStateGlows and not state.ActiveStateBorders then
		state.Initialized = true
		return
	end

	local visibilityChanged = EvaluateEffects(child, state, config, refreshGlowOptions)
	if visibilityChanged and not skipLayoutRefresh then
		TriggerLayoutRefresh(child)
	end
end

function States.SyncState(child, isActive, cooldownState, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	UpdateState(child, isActive, cooldownState, nil, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
end

function States.SetCooldownState(child, cooldownState, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	UpdateState(child, nil, cooldownState, nil, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
end

function States.SetActiveState(child, isActive, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	UpdateState(child, isActive, nil, nil, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
end

function States.SetOverriddenState(child, isOverridden, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	UpdateState(child, nil, nil, isOverridden, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
end

local function RefreshChildForSpellUsability(child)
	local config = child.SCMConfig
	local state = child.SCMState
	if not (config and state) then
		return false
	end

	local cooldownEffect = config.effectRules and config.effectRules.cooldown
	if cooldownEffect then
		ApplyCooldownRules(child, state, cooldownEffect)
	end

	return EvaluateEffects(child, state, config)
end

local function UpdateTrackedSpellChildren(spell, scopedGroups)
	for child in pairs(spell.children) do
		if RefreshChildForSpellUsability(child) and child.SCMGroup then
			scopedGroups = scopedGroups or SCM:AcquireScopedGroupCache()
			local group = child.SCMGlobal and ToGlobalGroup(child.SCMGroup) or child.SCMGroup
			scopedGroups[group] = true
		end
	end

	return scopedGroups
end

function States.UpdateSpellUsability()
	if not next(trackedUsabilitySpells) then
		return
	end

	local scopedGroups
	for spellID, spell in pairs(trackedUsabilitySpells) do
		local usable = GetSpellUsable(spellID)
		if usable ~= nil and spell.usable ~= usable then
			spell.usable = usable
			scopedGroups = UpdateTrackedSpellChildren(spell, scopedGroups)
		end
	end

	if scopedGroups then
		SCM.CDM.OrderSpells(SCM.CDM.UPDATE_SCOPE.ALL, scopedGroups)
		SCM:ReleaseScopedGroupCache(scopedGroups)
	end
end
