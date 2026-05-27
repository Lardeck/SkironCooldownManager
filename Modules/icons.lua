local SCM = select(2, ...)

local Icons = SCM.Icons
local Cache = SCM.Cache
local Utils = SCM.Utils
local Constants = SCM.Constants
local AddChildToGroup = Utils.AddChildToGroup
local GetSpellConfigByCooldownID = Utils.GetSpellConfigByCooldownID
local Cooldowns = SCM.Cooldowns
local TRACKED_BAR_CATEGORY = Enum.CooldownViewerCategory.TrackedBar
local delayedHideSpellIDs = {
	--[450615] = true,
}
local delayedHideSeconds = 0.03

local function OnSetAlpha(self)
	UIParent.SetAlpha(self, self.SCMHidden and 0 or 1)
end

local function ApplyHideChildNow(child)
	child.SCMHidden = true
	UIParent.SetAlpha(child, 0)
	child:EnableMouse(false)
	child.SCMOnEnter = child.SCMOnEnter or child:GetScript("OnEnter")
	child:SetScript("OnEnter", nil)

	if not child.SCMAlphaHook then
		child.SCMAlphaHook = true
		hooksecurefunc(child, "SetAlpha", OnSetAlpha)
	end
end

local function DelayedHideChildCallback(child)
	child.SCMHideTimer = nil
	if child.viewerFrame and not child.SCMHidden then
		ApplyHideChildNow(child)
	end
end

function Icons.HideChild(child)
	if not child.viewerFrame or child.SCMHidden then
		return
	end

	if delayedHideSpellIDs[child.SCMSpellID] then
		if child.SCMHideTimer then
			return
		end

		child.SCMHideTimer = C_Timer.NewTimer(delayedHideSeconds, function()
			DelayedHideChildCallback(child)
		end)
		return
	end

	ApplyHideChildNow(child)
end

local function CancelChildHideTimer(child)
	if child.SCMHideTimer then
		child.SCMHideTimer:Cancel()
		child.SCMHideTimer = nil
	end
end

function Icons.ShowChild(child)
	CancelChildHideTimer(child)

	if child.SCMLayoutLimited then
		return
	end

	if child.viewerFrame and child.SCMHidden then
		child.SCMHidden = false
		UIParent.SetAlpha(child, 1)
		child:EnableMouse(true)

		if SCM.showTooltips then
			child:SetScript("OnEnter", child.SCMOnEnter)
		end
	end
end

function Icons.SetChildVisibilityState(child, shouldShow, applyNow)
	child.SCMShouldBeVisible = shouldShow and true or false
	if not applyNow then
		return
	end

	child.SCMAppliedVisibility = child.SCMShouldBeVisible and not child.SCMLayoutLimited
	child.SCMAppliedLayoutLimited = child.SCMLayoutLimited and true or false

	if child.viewerFrame then
		if shouldShow and not child.SCMLayoutLimited then
			Icons.ShowChild(child)
		else
			Icons.HideChild(child)
		end
		return
	end

	if child.SCMCustom and not child:GetAttribute("statehidden") then
		child:SetShown(shouldShow and not child.SCMLayoutLimited)
	end
end

function Icons.UpdateChildDesaturation(child, shouldDesaturate)
	if child.Icon and child.SCMConfig and child.SCMSpellID then
		if child.SCMConfig.desaturate then
			child.Icon.SCMDesaturated = shouldDesaturate
			child.Icon:SetDesaturated(shouldDesaturate)
		else
			child.Icon.SCMDesaturated = false
			child.Icon:SetDesaturated(false)
		end
	end
end

function Icons.UpdateChildGlow(child, isInactive)
	if child.SCMConfig then
		if child.SCMConfig.glowWhileActive then
			if not isInactive then
				SCM:StartCustomGlow(child)
				return
			end

			if child.SCMGlow then
				SCM:StopCustomGlow(child)
			end
		elseif child.SCMConfig.glowWhileInactive then
			if isInactive then
				SCM:StartCustomGlow(child)
				return
			end

			if child.SCMGlow then
				SCM:StopCustomGlow(child)
			end
		end
	end
end

local function OnShow(child)
	UIParent.SetAlpha(child, child.SCMHidden and 0 or 1)
	if child.SCMGroup and (child.SCMChanged or child.SCMBuffBar) then
		if child.SCMBuffBar then
			if Constants.FakeAuras[child.SCMSpellID] then
				child.SCMFakeAuraInstanceID = true
			elseif child.auraInstanceID then
				child.SCMAuraInstanceID = child.SCMAuraInstanceID or child.auraInstanceID
				child.SCMAuraDataUnit = child.SCMAuraDataUnit or child.auraDataUnit
			end
		end

		SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, child.SCMGlobal, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
	end
end

local function OnHide(child)
	if child.SCMGroup and (child.SCMChanged or child.SCMBuffBar) then
		if child.SCMBuffBar then
			if child.SCMFakeAuraInstanceID and child.SCMFixedDuration and GetTime() < child.SCMFixedDuration then
				return
			elseif child.SCMAuraInstanceID and not child.SCMFakeAuraInstanceID 
			and C_UnitAuras.GetAuraDataByAuraInstanceID(child.SCMAuraDataUnit, child.SCMAuraInstanceID)
			and C_UnitAuras.IsAuraFilteredOutByInstanceID(child.SCMAuraDataUnit, child.SCMAuraInstanceID, "PLAYER") then
				return
			end

			child.SCMAuraInstanceID = nil
			child.SCMAuraDataUnit = nil
			child.SCMFakeAuraInstanceID = nil
		end

		SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, child.SCMGlobal, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
	end
end

local function OnSetDesaturated(iconTexture)
	local parent = iconTexture:GetParent()
	if not parent.SCMCustom and not iconTexture.SCMSkipUpdate and iconTexture.SCMDesaturated then
		iconTexture.SCMSkipUpdate = true
		iconTexture:SetDesaturated(iconTexture.SCMDesaturated)
		iconTexture.SCMSkipUpdate = nil
	end
end

function Icons.SetupIconHooks(child)
	if child.SCMShowHook then
		return
	end
	child.SCMShowHook = true

	child:HookScript("OnShow", OnShow)
	child:HookScript("OnHide", OnHide)

	if child.Icon and child.Icon.SetDesaturated then
		hooksecurefunc(child.Icon, "SetDesaturated", OnSetDesaturated)
	end
end

function Icons.SetupRegularIconHooks(child)
	if child.SCMRegularCooldownHook then
		return
	end

	Icons.SetupIconHooks(child)
	Cooldowns.SetupCooldownHooks(child)
end

function Icons.SetupBuffBarHooks(child)
	if child.SCMShowHook then
		return
	end
	child.SCMShowHook = true

	if Constants.FakeAuras[child.SCMSpellID] then
		child:HookScript("OnShow", OnShow)
		child:HookScript("OnHide", OnHide)

		if type(Constants.FakeAuras[child.SCMSpellID]) == "number" then
			child.SCMFixedDuration = GetTime() + Constants.FakeAuras[child.SCMSpellID]
		end
		-- DevTool:AddData(child)
	else
		child:HookScript("OnShow", OnShow)
		hooksecurefunc(child, "OnAuraInstanceInfoCleared", OnHide)
	end
end

local function GetOrCacheChildren(viewer)
	if not Cache.cachedViewerChildren[viewer] or (viewer:GetNumChildren() ~= #Cache.cachedViewerChildren[viewer]) then
		Cache.cachedViewerChildren[viewer] = { viewer:GetChildren() }
	end

	return Cache.cachedViewerChildren[viewer]
end

local function GetConfiguredGroupForCategory(childData, categoryIndex)
	if not (childData and childData.source and categoryIndex ~= nil) then
		return
	end

	if categoryIndex == Enum.CooldownViewerCategory.TrackedBuff or categoryIndex == Enum.CooldownViewerCategory.TrackedBar then
		return childData.source[categoryIndex]
	end

	local pairedCategory = Utils.GetPairedSource(categoryIndex)
	return childData.source[categoryIndex] or (pairedCategory and childData.source[pairedCategory])
end

function Icons.CollectScopedAnchorGroups(updateScope, config, viewerUpdateMapping)
	if updateScope == "all" then
		return
	end

	local viewerData = viewerUpdateMapping[updateScope]
	local targetGroups = viewerData and Cache.cachedScopedAnchorGroups[updateScope]
	if not targetGroups then
		return
	end

	wipe(targetGroups)

	local viewer = _G[viewerData.frameName]
	local spellConfig = config and config.spellConfig
	local defaultConfig = SCM.defaultCooldownViewerConfig
	if not (viewer and spellConfig and defaultConfig) then
		return targetGroups
	end

	local categoryIndex = SCM.CooldownViewerNameToIndex[viewer:GetName()]
	if not categoryIndex then
		return targetGroups
	end

	for _, child in ipairs(GetOrCacheChildren(viewer, viewerData.isBuffIcon or viewerData.isBuffBar)) do
		if child.GetCooldownID then
			local cooldownID = child:GetCooldownID()
			local _, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)
			local group = GetConfiguredGroupForCategory(childData, categoryIndex)
			if group then
				targetGroups[group] = true
			end
		end
	end

	return targetGroups
end

function Icons.ExpandScopedAnchorGroups(viewer, viewerData, scopedAnchorGroups)
	if not (viewerData and scopedAnchorGroups) or viewerData.isBuffBar then
		return
	end

	local children = GetOrCacheChildren(viewer, viewerData.isBuffIcon)
	local categoryIndex = SCM.CooldownViewerNameToIndex[viewer:GetName()]
	local defaultCooldownIDs = SCM.defaultCooldownViewerConfig.cooldownIDs
	if not defaultCooldownIDs then
		return
	end

	for _, child in ipairs(children) do
		if child.Icon and child.GetCooldownID then
			local oldCooldownID = child.SCMCooldownID
			local oldGroup = child.SCMGroup
			local cooldownID = child:GetCooldownID()
			local _, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)

			if not (cooldownID and childData) then
				if oldGroup then
					Cache.cachedAnchorStates[oldGroup].layoutSignature = nil
					scopedAnchorGroups[oldGroup] = true
				end
			else
				local group = GetConfiguredGroupForCategory(childData, categoryIndex)
				local groupConfig = childData.anchorGroup[group]
				if not (group and groupConfig) then
					if oldGroup then
						Cache.cachedAnchorStates[oldGroup].layoutSignature = nil
						scopedAnchorGroups[oldGroup] = true
					end
				elseif oldCooldownID ~= cooldownID or oldGroup ~= group then
					if oldGroup then
						Cache.cachedAnchorStates[oldGroup].layoutSignature = nil
						scopedAnchorGroups[oldGroup] = true
					end
					Cache.cachedAnchorStates[group].layoutSignature = nil
					scopedAnchorGroups[group] = true
				end
			end
		end
	end
end

local function ProcessBuffIcon(child, childData, options)
	Cooldowns.SetupBuffIconHooks(child, options)
	child.SCMBuffOptions = options

	local isInactive
	if child.SCMCheckCooldownFrame then
		isInactive = not child.Cooldown:IsVisible()
	else
		isInactive = not child.auraInstanceID or not child.auraDataUnit
	end

	local forceShow = SCM.simulateBuffs or (not SCM.isHideWhenInactiveEnabled and childData.alwaysShow)
	local shouldHide = (childData.showWhileInactive and not isInactive) or (isInactive and not (forceShow or childData.showWhileInactive))

	if shouldHide then
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	Icons.SetChildVisibilityState(child, true, true)
	Icons.UpdateChildDesaturation(child, isInactive)
	Icons.UpdateChildGlow(child, isInactive)
end

local function ProcessRegularIcon(child, childData, options)
	Icons.SetupRegularIconHooks(child)

	local shouldShow = not (childData.hideWhenNotOnCooldown and not Cooldowns.IsChildOnCooldown(child))
	local applyNow = shouldShow and child.SCMHidden and not child.SCMLayoutLimited
	Icons.SetChildVisibilityState(child, shouldShow, applyNow)
	child.SCMIconOptions = options

	Cooldowns.OverrideRegularAuraCooldown(child.Cooldown, child, options)
end

local function ProcessBuffBar(child, childData, options)
	Icons.SetupBuffBarHooks(child)

	local isInactive = not child.auraInstanceID and not child.SCMFakeAuraInstanceID
	local forceShow = SCM.simulateBuffs or (not SCM.isHideWhenInactiveEnabled and childData.alwaysShow)
	local shouldHide = isInactive and not forceShow

	if shouldHide then
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	Icons.SetChildVisibilityState(child, true, true)
end

local function ProcessSingleChild(child, validChildren, categoryIndex, isBuffIcon, options)
	if not child.Icon then
		return
	end

	local activeScopedAnchorGroups = Cache.activeScopedAnchorGroups
	local cooldownID = child:GetCooldownID()
	local categoryConfig = categoryIndex and SCM.defaultCooldownViewerConfig[categoryIndex]
	local info = categoryConfig and (categoryConfig[cooldownID] or SCM.defaultCooldownViewerConfig.cooldownIDs[cooldownID])
	local spellID = info and (info.overrideSpellID or info.spellID)
	if info and info.linkedSpellIDs and #info.linkedSpellIDs == 1 then
		child.SCMLinkedSpellID = info.linkedSpellIDs[1]
	end

	child.SCMSpellID = spellID

	local configID, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)
	if not (cooldownID and spellID and childData) then
		Utils.ResetChildSCMState(child)
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	local group = GetConfiguredGroupForCategory(childData, categoryIndex)
	local groupConfig = childData.anchorGroup and childData.anchorGroup[group]
	if not (group and groupConfig) then
		Utils.ResetChildSCMState(child)
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	if activeScopedAnchorGroups and not activeScopedAnchorGroups[group] then
		return
	end

	AddChildToGroup(validChildren, group, child)

	child.SCMChanged = (not child.SCMConfig or child.SCMConfig ~= groupConfig) or (not child.SCMCooldownID or child.SCMCooldownID ~= cooldownID)
	child.SCMConfig = groupConfig
	child.SCMOrder = groupConfig.order
	child.SCMCooldownID = cooldownID
	child.SCMConfigID = configID
	child.SCMGroup = group

	if isBuffIcon then
		ProcessBuffIcon(child, groupConfig, options)
	else
		ProcessRegularIcon(child, groupConfig, options)
	end

	if not InCombatLockdown() then
		RegisterAttributeDriver(child, "state-visibility", SCM:GetVisibilityConditions(SCM.db.profile.options))
	end
end

local function ProcessSingleBuffBarChild(child, validChildren, categoryIndex, options)
	if not child.GetCooldownID then
		return
	end

	local oldCooldownID = child.SCMCooldownID
	local oldGroup = child.SCMGroup
	local activeScopedAnchorGroups = Cache.activeScopedAnchorGroups
	local cooldownID = child:GetCooldownID()
	local categoryConfig = categoryIndex and SCM.defaultCooldownViewerConfig[categoryIndex]
	local info = categoryConfig and (categoryConfig[cooldownID] or SCM.defaultCooldownViewerConfig.cooldownIDs[cooldownID])
	local spellID = info and (info.overrideSpellID or info.spellID)
	if info and info.linkedSpellIDs and #info.linkedSpellIDs == 1 then
		child.SCMLinkedSpellID = info.linkedSpellIDs[1]
	end

	child.SCMSpellID = spellID

	local configID, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)
	if not (cooldownID and spellID and childData) then
		if activeScopedAnchorGroups and oldGroup then
			activeScopedAnchorGroups[oldGroup] = true
		end

		Utils.ResetChildSCMState(child)
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	local group = childData.source[TRACKED_BAR_CATEGORY]
	local groupConfig = childData.anchorGroup and childData.anchorGroup[group]
	if not (group and groupConfig) then
		if activeScopedAnchorGroups and oldGroup then
			activeScopedAnchorGroups[oldGroup] = true
		end

		Utils.ResetChildSCMState(child)
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	if activeScopedAnchorGroups and (oldCooldownID ~= cooldownID or oldGroup ~= group) then
		if oldGroup then
			activeScopedAnchorGroups[oldGroup] = true
		end
		activeScopedAnchorGroups[group] = true
	end

	AddChildToGroup(validChildren, group, child)

	child.SCMChanged = (not child.SCMConfig or child.SCMConfig ~= groupConfig) or (not child.SCMCooldownID or child.SCMCooldownID ~= cooldownID)
	child.SCMConfig = groupConfig
	child.SCMOrder = groupConfig.order
	child.SCMCooldownID = cooldownID
	child.SCMConfigID = configID
	child.SCMGroup = group
	child.SCMBuffBar = true

	ProcessBuffBar(child, groupConfig, options)
end

function Icons.ProcessChildren(viewer, validChildren, viewerData)
	if not (viewer and viewerData) then
		return
	end

	local children = GetOrCacheChildren(viewer)
	local categoryIndex = SCM.CooldownViewerNameToIndex[viewer:GetName()]
	local options = SCM.db.profile.options
	viewer.SCMUpdateScope = viewerData.updateScope

	if viewerData.isBuffBar then
		for _, child in ipairs(children) do
			ProcessSingleBuffBarChild(child, validChildren, categoryIndex, options)
		end
		return
	end

	local isBuffIcon = viewerData.isBuffIcon
	for _, child in ipairs(children) do
		ProcessSingleChild(child, validChildren, categoryIndex, isBuffIcon, options)
	end
end
