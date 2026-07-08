local SCM = select(2, ...)
local States = SCM.States
local Icons = SCM.Icons

function States.GetState(child)
	if not child.SCMState then
		child.SCMState = {
			Visibility = true,
		}
	end

	return child.SCMState
end

local function IsStateActive(state, stateKey)
	if stateKey == "ready" then
		return state.Cooldown == false
	elseif stateKey == "cooldown" then
		return state.Cooldown
	elseif stateKey == "active" then
		return state.Active
	elseif stateKey == "inactive" then
		return state.Active == false
	end
end

local function GetPriorityStateOptions(config, state)
	local selectedStates = config and config.selectedStates
	local stateOptions = config and config.stateOptions
	if not (selectedStates and stateOptions) then
		return
	end

	for _, stateKey in ipairs(selectedStates) do
		if IsStateActive(state, stateKey) and stateOptions[stateKey] then
			return stateKey, stateOptions[stateKey]
		end
	end
end

local function ApplyVisibilityOptions(child, state, options)
	local shouldShow = true
	if options and options.visibility then
		shouldShow = options.visibility.value == "show"
	end

	state.Visibility = shouldShow
	if child.SCMShouldBeVisible ~= shouldShow then
		Icons.SetChildVisibilityState(child, shouldShow, true)
		state.UpdateRequired = true
	end
end

local function ApplyDesaturateOptions(child, state, options)
	if options and options.desaturate ~= nil then
		local shouldDesaturate = options.desaturate.enabled
		if state.Desaturate == shouldDesaturate then
			return
		end

		state.Desaturate = shouldDesaturate
		Icons.UpdateChildDesaturation(child, shouldDesaturate, true)
		return
	end

	if state.Desaturate ~= nil then
		state.Desaturate = nil
		Icons.UpdateChildDesaturation(child, false)
	end
end

local function ApplyGlowOptions(child, state, config, options)
	local glowOptions, glowType, glowTypeOptions
	if options and options.glow then
		local subregionOptions = config and config.subregionOptions
		glowOptions = subregionOptions and subregionOptions.glow and subregionOptions.glow[options.glow.subregion]
		glowType = glowOptions and glowOptions.glowType
		glowTypeOptions = glowType and glowOptions.glowTypeOptions and glowOptions.glowTypeOptions[glowType]
	end

	if glowOptions and glowTypeOptions then
		local key = "SCMSubregion" .. glowOptions.typeIndex
		local isSameGlow = state.Glow == key
			and state.GlowType == glowType
			and state.GlowTypeOptions == glowTypeOptions
			and child.SCMGlow == glowType
			and child.SCMGlowKey == key

		if isSameGlow then
			return
		end

		SCM:StartCustomGlow(child, glowTypeOptions, glowType, key, true)
		state.Glow = key
		state.GlowType = glowType
		state.GlowTypeOptions = glowTypeOptions
		return
	end

	if state.Glow then
		SCM:StopCustomGlow(child)
		state.Glow = nil
		state.GlowType = nil
		state.GlowTypeOptions = nil
	end
end

local function ApplyStateOptions(child)
	local state = States.GetState(child)
	local config = child.SCMConfig
	local stateKey, options = GetPriorityStateOptions(config, state)

	state.UpdateRequired = false
	state.ActiveState = stateKey

	ApplyVisibilityOptions(child, state, options)
	ApplyDesaturateOptions(child, state, options)
	ApplyGlowOptions(child, state, config, options)

	if state.UpdateRequired then
		SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, nil, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
	end
end

function States.SetCooldownState(child, isOnCooldown)
	local state = States.GetState(child)
	if state.Cooldown == isOnCooldown then
		return
	end

	state.Cooldown = isOnCooldown
	ApplyStateOptions(child)
end

function States.SetActiveState(child, isActive)
	local state = States.GetState(child)
	if state.Active == isActive then
		return
	end

	state.Active = isActive
	ApplyStateOptions(child)
end
