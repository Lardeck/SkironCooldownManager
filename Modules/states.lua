local SCM = select(2, ...)
local States = SCM.States
local Icons = SCM.Icons
local UpdateChildDesaturation = Icons.UpdateChildDesaturation
local GLOBAL_GLOW_SUBREGION = SCM.Constants.GENERAL.GLOBAL_GLOW_SUBREGION
local EMPTY_EFFECT_RULES = {}
local trackedUsabilitySpells = {}

local function GetNextMatchedRule(rules, index, state, skipActiveFalse)
	local ruleCount = #rules

	while index <= ruleCount do
		local rule = rules[index]
		local ruleState = rule.state
		index = index + 1

		if
			ruleState
			and (ruleState == "always" or ruleState == state.CooldownState or (ruleState == "active" and state.Active) or (ruleState == "inactive" and state.Active == false) or (ruleState == "overridden" and state.Overridden) or (ruleState == "usableSpell" and state.TrackedSpell and state.TrackedSpell.usable))
			and not (skipActiveFalse and ruleState == "active" and rule.enabled == false)
		then
			while index <= ruleCount and rules[index].elseIf do
				index = index + 1
			end

			return rule, index
		end
	end
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
	local rules = effectConfig.rules
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
end

local function HideAllStateBorders(child)
	local activeBorders = child.SCMActiveStateBorders
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
	child.SCMActiveStateBorders = nil
end
States.HideAllStateBorders = HideAllStateBorders

local function ShowStateBorder(child, targetFrame, key, borderOptions, refreshID)
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
	local borderColor = borderOptions.borderColor or options.borderColor or { r = 1, g = 1, b = 1, a = 1 }
	local r, g, b, a = borderColor.r or 1, borderColor.g or 1, borderColor.b or 1, borderColor.a or 1

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

	local shouldShow = borderSize ~= 0
	if not shouldShow and border.SCMStateBorderShown ~= false then
		border:Hide()
		border.SCMStateBorderShown = false
	elseif shouldShow and not border.SCMStateBorderShown then
		border:Show()
		border.SCMStateBorderShown = true
	end

	local activeBorders = child.SCMActiveStateBorders
	if not activeBorders then
		activeBorders = {}
		child.SCMActiveStateBorders = activeBorders
	end
	activeBorders[key] = refreshID
end

local function ApplyBorderRules(child, state, config, effectConfig)
	local rules = effectConfig.rules
	local activeBorders = child.SCMActiveStateBorders
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
			ShowStateBorder(child, targetFrame, key, borderOptions, refreshID)
		end
		rule, index = GetNextMatchedRule(rules, index, state)
	end

	activeBorders = child.SCMActiveStateBorders
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
end

local function ApplyCooldownRules(child, state, effectConfig)
	local rules = effectConfig and effectConfig.rules
	local rule = rules and rules[1] and GetNextMatchedRule(rules, 1, state)
	if not child.Cooldown then
		return
	end

	state.CooldownRule = rule
	if rule then
		SCM.ApplyCooldownRule(child.Cooldown, rule)
		return
	end

	local options = SCM.db.profile.options
	local hideActiveSwipe = (SCM.IsActiveSwipeDisabled(child, options) or child.SCMConfig.hideActiveSwipe) and not child.SCMConfig.forceActiveSwipe
	local showActiveSwipe = child.Cooldown:GetUseAuraDisplayTime() and not hideActiveSwipe
	local isRecharging = state.CooldownState == "recharging" and not showActiveSwipe
	child.Cooldown:SetDrawEdge(isRecharging)
	child.Cooldown:SetDrawSwipe(not isRecharging or (child.SCMCustom and true or false))
	child.Cooldown:SetEdgeColor(1, 0.7, 0, 1)
	if child.SCMCustom then
		child.Cooldown:SetReverse(state.CooldownState == "cooldown" and child.lastCastStartTime and true or false)
	else
		child.Cooldown:SetReverse(false)
	end
	if isRecharging and child.SCMCustom then
		child.Cooldown:SetSwipeColor(0, 0, 0, 0)
	else
		SCM.ApplyCooldownSwipe(child.Cooldown, options)
	end
end

local function ApplyStateOptions(child, skipLayoutRefresh, state, refreshGlowOptions)
	local config = child.SCMConfig
	local effectRules = config.effectRules or EMPTY_EFFECT_RULES

	local visibilityRules = effectRules.visibility and effectRules.visibility.rules
	local visibilityRule = visibilityRules and visibilityRules[1] and GetNextMatchedRule(visibilityRules, 1, state)
	local shouldShow = not visibilityRule or visibilityRule.value ~= "hide"
	state.UpdateRequired = state.Visibility ~= shouldShow
	state.Visibility = shouldShow

	local desaturateRules = effectRules.desaturate and effectRules.desaturate.rules
	local shouldDesaturate
	if desaturateRules and desaturateRules[1] then
		local skipActiveFalse = SCM.IsActiveSwipeDisabled(child, SCM.db.profile.options) and not config.forceActiveSwipe and not child.SCMBuffOptions and not child.SCMBuffBar
		local rule = GetNextMatchedRule(desaturateRules, 1, state, skipActiveFalse)

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

	if effectRules.glow then
		ApplyGlowRules(child, state, config, effectRules.glow, refreshGlowOptions)
	elseif state.ActiveStateGlows then
		States.StopStateGlows(child)
	end

	if effectRules.border then
		ApplyBorderRules(child, state, config, effectRules.border)
	elseif child.SCMActiveStateBorders then
		HideAllStateBorders(child)
	end
	if not state.UpdateRequired or skipLayoutRefresh then
		return
	end

	SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, nil, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
end

local function HasUsableSpellRule(effectRules)
	for _, effect in pairs(effectRules) do
		if effect.rules then
			for _, rule in ipairs(effect.rules) do
				if rule.state == "usableSpell" then
					return true
				end
			end
		end
	end
end

function States.UntrackSpellUsability(child)
	local state = child.SCMState
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

local function UpdateState(child, isActive, cooldownState, isOverridden, skipLayoutRefresh, refreshOptions, refreshGlowOptions, spellID)
	local config = child and child.SCMConfig
	if not config then
		return false
	end

	local effectRules = config.effectRules
	local state = child.SCMState
	if not state then
		state = { Visibility = true }
		child.SCMState = state
	end

	if spellID ~= nil and (refreshOptions or state.UsabilitySpellID ~= spellID) then
		local shouldTrack = spellID and effectRules and HasUsableSpellRule(effectRules)
		local previousSpell = state.TrackedSpell
		if previousSpell and (not shouldTrack or previousSpell.id ~= spellID) then
			States.UntrackSpellUsability(child)
		end

		if shouldTrack and not state.TrackedSpell then
			local spell = trackedUsabilitySpells[spellID]
			if not spell then
				spell = { id = spellID, children = {}, usable = C_Spell.IsSpellUsable(spellID) }
				trackedUsabilitySpells[spellID] = spell
			end
			spell.children[child] = true
			state.TrackedSpell = spell
		end
		state.UsabilitySpellID = spellID
		refreshOptions = refreshOptions or previousSpell ~= state.TrackedSpell
	end

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

	local cooldownEffect = effectRules and effectRules.cooldown
	if cooldownState ~= nil or (cooldownEffect and (activeChanged or overriddenChanged or refreshOptions)) or (refreshOptions and state.CooldownRule) then
		ApplyCooldownRules(child, state, cooldownEffect)
	end

	if not (refreshOptions or activeChanged or cooldownChanged or overriddenChanged) then
		return false
	end

	if not effectRules and state.Visibility and state.Desaturate == nil and not state.ActiveStateGlows and not child.SCMActiveStateBorders then
		return true
	end

	ApplyStateOptions(child, skipLayoutRefresh, state, refreshGlowOptions)
	return true
end

function States.SyncState(child, isActive, cooldownState, skipLayoutRefresh, refreshOptions, refreshGlowOptions, spellID)
	return UpdateState(child, isActive, cooldownState, nil, skipLayoutRefresh, refreshOptions, refreshGlowOptions, spellID)
end

function States.SetCooldownState(child, cooldownState, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	return UpdateState(child, nil, cooldownState, nil, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
end

function States.SetActiveState(child, isActive, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	return UpdateState(child, isActive, nil, nil, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
end

function States.SetOverriddenState(child, isOverridden, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
	return UpdateState(child, nil, nil, isOverridden, skipLayoutRefresh, refreshOptions, refreshGlowOptions)
end

function States.UpdateSpellUsability()
	local scopedGroups
	for spellID, spell in pairs(trackedUsabilitySpells) do
		local usable = C_Spell.IsSpellUsable(spellID)
		if spell.usable ~= usable then
			spell.usable = usable
			for child in pairs(spell.children) do
				States.SyncState(child, nil, nil, true, true)
				if child.SCMState.UpdateRequired then
					scopedGroups = scopedGroups or SCM:AcquireScopedGroupCache()
					scopedGroups[child.SCMGlobal and SCM.Utils.ToGlobalGroup(child.SCMGroup) or child.SCMGroup] = true
				end
			end
		end
	end

	if scopedGroups then
		SCM.CDM.OrderSpells(SCM.CDM.UPDATE_SCOPE.ALL, scopedGroups)
		SCM:ReleaseScopedGroupCache(scopedGroups)
	end
end
