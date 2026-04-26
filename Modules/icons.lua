local SCM = select(2, ...)

local Icons = SCM.Icons
local Cache = SCM.Cache
local Utils = SCM.Utils
local AddChildToGroup = Utils.AddChildToGroup
local GetSpellConfigByCooldownID = Utils.GetSpellConfigByCooldownID
local Cooldowns = SCM.Cooldowns
local TRACKED_BAR_CATEGORY = Enum.CooldownViewerCategory.TrackedBar
local delayedHideSpellIDs = {
	--[450615] = true,
}
local delayedHideSeconds = 0.03

local function OnManagedChildSetAlpha(self)
	UIParent.SetAlpha(self, self.SCMHidden and 0 or 1)
end

local function ApplyHideChildNow(child)
	child.SCMHidden = true
	UIParent.SetAlpha(child, 0)
	child:EnableMouse(false)
	child:SetScript("OnEnter", nil)
	SCM:Debug("HIDE", GetTime(), child.SCMSpellID or "unknown", child.SCMCooldownID or "unknown")

	if not child.SCMAlphaHook then
		child.SCMAlphaHook = true
		hooksecurefunc(child, "SetAlpha", OnManagedChildSetAlpha)
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
		SCM:Debug("Start Timer", child.SCMSpellID)

		child.SCMHideTimer = C_Timer.NewTimer(delayedHideSeconds, function()
			DelayedHideChildCallback(child)
		end)
		return
	end

	ApplyHideChildNow(child)
end

local function CancelChildHideTimer(child)
	if child.SCMHideTimer then
		SCM:Debug("Cancel Timer", child.SCMSpellID)
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
		SCM:Debug("SHOW", GetTime(), child.SCMSpellID or "unknown", child.SCMCooldownID or "unknown")
	end
end

function Icons.SetChildVisibilityState(child, shouldShow, applyNow)
	child.SCMShouldBeVisible = shouldShow and true or false
	if not applyNow then
		return
	end

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
		end
	end
end

local function OnShow(child)
	UIParent.SetAlpha(child, child.SCMHidden and 0 or 1)
	if child.SCMGroup and (child.SCMChanged or child.SCMBuffBar) then
		SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup)
	end
end

local function OnHide(child)
	if child.SCMGroup and (child.SCMChanged or child.SCMBuffBar) then
		SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup)
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
	if child.SCMShowHook or child == UIParent then
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

local function GetOrCacheChildren(viewer, shouldRefreshCache)
	if not Cache.cachedViewerChildren[viewer] then
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

local function ProcessBuffIcon(child, childData, options)
	Cooldowns.SetupBuffIconHooks(child, options)
	child.SCMBuffOptions = options

	--local isInactive = not child.Cooldown:IsShown() and not child.auraInstanceID
	local isInactive = not child.auraInstanceID
	local forceShow = SCM.simulateBuffs or (not SCM.isHideWhenInactiveEnabled and childData.alwaysShow)
	local shouldHide = isInactive and not forceShow

	if shouldHide then
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	Icons.SetChildVisibilityState(child, true, true)
	Icons.UpdateChildDesaturation(child, isInactive)
end

local function ProcessRegularIcon(child, childData, options)
	Icons.SetupRegularIconHooks(child)
	Icons.SetChildVisibilityState(child, not (childData.hideWhenNotOnCooldown and not Cooldowns.IsChildOnCooldown(child)), false)

	Cooldowns.OverrideRegularAuraCooldown(child.Cooldown, child, options)
end

local function ProcessBuffBar(child)
	Icons.SetupIconHooks(child)
	Icons.SetChildVisibilityState(child, true, true)
end

local function ProcessSingleChild(child, validChildren, categoryIndex, isBuffIcon, options)
	if not child.Icon then
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
		if child.SCMShouldBeVisible and child.SCMSpellID then
			print("HIDE", cooldownID, child.SCMSpellID, C_Spell.GetSpellName(child.SCMSpellID))
		end

		if activeScopedAnchorGroups and oldGroup then
			activeScopedAnchorGroups[oldGroup] = true
		end

		Utils.ResetChildSCMState(child)
		Icons.SetChildVisibilityState(child, false, true)
		return
	end

	local group = GetConfiguredGroupForCategory(childData, categoryIndex)
	local groupConfig = childData.anchorGroup and childData.anchorGroup[group]
	if not (group and groupConfig) then
		if child.SCMShouldBeVisible and child.SCMSpellID then
			print("HIDE", cooldownID, child.SCMSpellID, C_Spell.GetSpellName(child.SCMSpellID))
		end

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

	child.SCMChanged = not child.SCMConfig or child.SCMConfig ~= groupConfig
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
		if childData.hideWhileMounted then
			RegisterAttributeDriver(child, "state-visibility", "[combat]show;[mounted][stance:3]hide;show")
		else
			UnregisterAttributeDriver(child, "state-visibility")
		end
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

	child.SCMChanged = not child.SCMConfig or child.SCMConfig ~= groupConfig
	child.SCMConfig = groupConfig
	child.SCMOrder = groupConfig.order
	child.SCMCooldownID = cooldownID
	child.SCMConfigID = configID
	child.SCMGroup = group
	child.SCMBuffBar = true

	ProcessBuffBar(child)
end

function Icons.ProcessChildren(viewer, validChildren, viewerData)
	if not (viewer and viewerData) then
		return
	end

	local children = GetOrCacheChildren(viewer, viewerData.isBuffIcon or viewerData.isBuffBar)
	local categoryIndex = SCM.CooldownViewerNameToIndex[viewer:GetName()]
	local options = SCM.db.profile.options

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
