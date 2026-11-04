local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns
local Cache = SCM.Cache
local Icons = SCM.Icons
local States = SCM.States
local Utils = SCM.Utils
local AddChildToGroup = Utils.AddChildToGroup
local GetSpellConfigByCooldownID = Utils.GetSpellConfigByCooldownID
local TRACKED_BAR_CATEGORY = Enum.CooldownViewerCategory.TrackedBar

local function ProcessBuffIcon(child, options, refreshOptions, refreshGlowOptions)
	Cooldowns.SetupBuffIconHooks(child, options)
	child.SCMBuffOptions = options

	local isInactive
	if not issecretvalue(child.isActive) then
		isInactive = not child.isActive
	elseif child.SCMCheckCooldownFrame then
		isInactive = not child.Cooldown:IsVisible() and not child.SCMFixedDuration
	else
		isInactive = not child.auraInstanceID or not child.auraDataUnit
	end

	States.SetActiveState(child, not isInactive, true, refreshOptions, refreshGlowOptions)

	local canShowInactive = not SCM.isHideWhenInactiveEnabled
	local stateVisible = child.SCMState.Visibility
	local shouldShow = SCM.simulateBuffs or ((not isInactive or canShowInactive) and stateVisible)
	local wasVisible = child.SCMShouldBeVisible

	child.SCMChanged = child.SCMChanged or wasVisible ~= shouldShow
	Icons.SetChildVisibilityState(child, shouldShow, true)
end

local function ProcessRegularIcon(child, options, refreshOptions, refreshGlowOptions)
	Icons.SetupRegularIconHooks(child, options)
	local isActive = (child.Cooldown and child.Cooldown:GetUseAuraDisplayTime()) or false
	Cooldowns.OverrideRegularAuraCooldown(child.Cooldown, child, options)

	States.SyncState(child, isActive, Cooldowns.GetChildCooldown(child), true, refreshOptions, refreshGlowOptions)

	local shouldShow = child.SCMState.Visibility
	child.SCMChanged = child.SCMChanged or child.SCMShouldBeVisible ~= shouldShow
	Icons.SetChildVisibilityState(child, shouldShow, true)
	child.SCMIconOptions = options
end

local function ProcessBuffBar(child, options, refreshOptions, refreshGlowOptions)
	Icons.SetupBuffBarHooks(child)
	Cooldowns.SetupPandemicHooks(child, options)
	child.SCMBuffBarOptions = options

	local isInactive
	if not issecretvalue(child.isActive) then
		isInactive = not child.isActive
	else
		isInactive = not child.auraInstanceID and not child.SCMFakeAuraInstanceID
	end

	States.SetActiveState(child, not isInactive, true, refreshOptions, refreshGlowOptions)

	local forceShow = options.disableBuffBarHideWhenInactive
	local stateVisible = child.SCMState.Visibility
	local shouldShow = SCM.simulateBuffs or ((not isInactive or forceShow) and stateVisible)
	local wasVisible = child.SCMShouldBeVisible

	child.SCMChanged = child.SCMChanged or wasVisible ~= shouldShow
	Icons.SetChildVisibilityState(child, shouldShow, true)
end

local function ProcessSingleChild(child, validChildren, categoryIndex, isBuffIcon, options, refreshOptions, refreshGlowOptions)
	if not child.Icon then
		return
	end

	local activeScopedAnchorGroups = Cache.activeScopedAnchorGroups
	local cooldownID = child:GetCooldownID() or child.SCMCooldownID
	local defaultConfig = SCM.defaultCooldownViewerConfig
	local categoryConfig = categoryIndex and defaultConfig and SCM.defaultCooldownViewerConfig[categoryIndex]
	local info = categoryConfig and (categoryConfig[cooldownID] or SCM.defaultCooldownViewerConfig.cooldownIDs[cooldownID])
	local spellID = info and (info.overrideTooltipSpellID or info.overrideSpellID or info.spellID)

	if info and info.linkedSpellIDs and #info.linkedSpellIDs == 1 then
		child.SCMLinkedSpellID = info.linkedSpellIDs[1]
	end

	local configID, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)
	if not (cooldownID and info and childData) then
		if child.SCMConfig then
			Utils.ResetChildSCMState(child)
		end

		if not child.SCMHidden then
			Icons.SetChildVisibilityState(child, false, true)
		end
		return
	end

	child.SCMSpellID = spellID

	local group = Icons.GetConfiguredGroupForCategory(childData, categoryIndex)
	local groupConfig = childData.anchorGroup and childData.anchorGroup[group]
	if not group or not groupConfig then
		if child.SCMConfig then
			Utils.ResetChildSCMState(child)
		end

		if not child.SCMHidden then
			Icons.SetChildVisibilityState(child, false, true)
		end
		return
	end

	AddChildToGroup(validChildren, group, child)

	refreshOptions = refreshOptions or child.SCMConfig ~= groupConfig or child.SCMCooldownID ~= cooldownID
	child.SCMChanged = child.SCMChanged or (not child.SCMConfig or child.SCMConfig ~= groupConfig) or (not child.SCMCooldownID or child.SCMCooldownID ~= cooldownID)
	child.SCMConfig = groupConfig
	child.SCMOrder = groupConfig.order
	child.SCMCooldownID = cooldownID
	child.SCMConfigID = configID
	child.SCMGroup = group
	child.SCMSpellCategoryID = info.spellCategoryID
	child.SCMEquipSlot = info.equipSlot

	if activeScopedAnchorGroups and not activeScopedAnchorGroups[group] and (child.SCMBuffOptions or child.SCMIconOptions) then
		return
	end

	if isBuffIcon then
		ProcessBuffIcon(child, options, refreshOptions, refreshGlowOptions)
	else
		ProcessRegularIcon(child, options, refreshOptions, refreshGlowOptions)
	end

	if not InCombatLockdown() then
		RegisterAttributeDriver(child, "state-visibility", SCM:GetVisibilityConditions(SCM.db.profile.options))
	end
end

local function ProcessSingleBuffBarChild(child, validChildren, categoryIndex, options, refreshOptions, refreshGlowOptions)
	if not child.GetCooldownID then
		return
	end

	local activeScopedAnchorGroups = Cache.activeScopedAnchorGroups
	local cooldownID = child:GetCooldownID() or child.SCMCooldownID
	local defaultConfig = SCM.defaultCooldownViewerConfig
	local categoryConfig = categoryIndex and defaultConfig and SCM.defaultCooldownViewerConfig[categoryIndex]
	local info = categoryConfig and (categoryConfig[cooldownID] or SCM.defaultCooldownViewerConfig.cooldownIDs[cooldownID])
	local spellID = info and (info.overrideSpellID or info.spellID)
	if info and info.linkedSpellIDs and #info.linkedSpellIDs == 1 then
		child.SCMLinkedSpellID = info.linkedSpellIDs[1]
	end

	child.SCMSpellID = spellID

	local configID, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)
	if not (cooldownID and spellID and childData) then
		if child.SCMConfig then
			Utils.ResetChildSCMState(child)
		end
		if not child.SCMHidden then
			Icons.SetChildVisibilityState(child, false, true)
		end
		return
	end

	local group = childData.source[TRACKED_BAR_CATEGORY]
	local groupConfig = childData.anchorGroup and childData.anchorGroup[group]
	if not (group and groupConfig) then
		if child.SCMConfig then
			Utils.ResetChildSCMState(child)
		end
		if not child.SCMHidden then
			Icons.SetChildVisibilityState(child, false, true)
		end
		return
	end

	AddChildToGroup(validChildren, group, child)

	refreshOptions = refreshOptions or child.SCMConfig ~= groupConfig or child.SCMCooldownID ~= cooldownID
	child.SCMChanged = child.SCMChanged or (not child.SCMConfig or child.SCMConfig ~= groupConfig) or (not child.SCMCooldownID or child.SCMCooldownID ~= cooldownID)
	child.SCMConfig = groupConfig
	child.SCMOrder = groupConfig.order
	child.SCMCooldownID = cooldownID
	child.SCMConfigID = configID
	child.SCMGroup = group
	child.SCMBuffBar = true

	if activeScopedAnchorGroups and not activeScopedAnchorGroups[group] then
		return
	end

	ProcessBuffBar(child, options, refreshOptions, refreshGlowOptions)
end

function Icons.ProcessChildren(viewer, validChildren, viewerData, refreshOptions, refreshGlowOptions)
	if not (viewer and viewerData) then
		return
	end

	local children = Icons.GetOrCacheChildren(viewer)
	local categoryIndex = SCM.Constants.CDM.COOLDOWN_VIEWER_NAME_TO_INDEX[viewer:GetName()]
	local options = SCM.db.profile.options
	viewer.SCMUpdateScope = viewerData.updateScope

	if viewerData.isBuffBar then
		for _, child in ipairs(children) do
			ProcessSingleBuffBarChild(child, validChildren, categoryIndex, options, refreshOptions, refreshGlowOptions)
		end
		return
	end

	local isBuffIcon = viewerData.isBuffIcon
	for _, child in ipairs(children) do
		ProcessSingleChild(child, validChildren, categoryIndex, isBuffIcon, options, refreshOptions, refreshGlowOptions)
	end
end
