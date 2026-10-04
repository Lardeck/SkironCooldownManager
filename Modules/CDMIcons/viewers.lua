local SCM = select(2, ...)

local Cache = SCM.Cache
local Icons = SCM.Icons
local Utils = SCM.Utils
local GetSpellConfigByCooldownID = Utils.GetSpellConfigByCooldownID

function Icons.GetOrCacheChildren(viewer)
	if not Cache.cachedViewerChildren[viewer] or (viewer:GetNumChildren() ~= #Cache.cachedViewerChildren[viewer]) then
		Cache.cachedViewerChildren[viewer] = { viewer:GetChildren() }
	end

	return Cache.cachedViewerChildren[viewer]
end

--TODO: Yep, this requires a rework
function Icons.GetConfiguredGroupForCategory(childData, categoryIndex)
	if not (childData and childData.source and categoryIndex) then
		return
	end

	if categoryIndex == Enum.CooldownViewerCategory.Essential or categoryIndex == Enum.CooldownViewerCategory.Utility then
		if childData.source[Enum.CooldownViewerCategory.EquipSlotEssential] then
			return childData.source[Enum.CooldownViewerCategory.EquipSlotEssential]
		elseif childData.source[Enum.CooldownViewerCategory.SpecAgnosticEssential] then
			return childData.source[Enum.CooldownViewerCategory.SpecAgnosticEssential]
		end
	end

	if categoryIndex == Enum.CooldownViewerCategory.TrackedBuff or categoryIndex == Enum.CooldownViewerCategory.TrackedBar then
		return childData.source[Enum.CooldownViewerCategory.EquipSlotTracked] or childData.source[Enum.CooldownViewerCategory.SpecAgnosticTracked] or childData.source[categoryIndex]
	end

	local pairedCategory = Utils.GetPairedSource(categoryIndex)
	return childData.source[categoryIndex] or (pairedCategory and childData.source[pairedCategory])
end

function Icons.IsViewerLayoutDirty(viewer)
	local children = Cache.cachedViewerChildren[viewer]
	if not children or viewer:GetNumChildren() ~= #children then
		return true
	end

	local categoryIndex = SCM.CooldownViewerNameToIndex[viewer:GetName()]
	for _, child in ipairs(children) do
		if child.GetCooldownID then
			local cooldownID = child:GetCooldownID()
			if cooldownID ~= child.SCMCooldownID then
				if child.SCMCooldownID then
					return true
				end

				local _, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)
				local group = Icons.GetConfiguredGroupForCategory(childData, categoryIndex)
				if group and childData.anchorGroup and childData.anchorGroup[group] then
					return true
				end
			end
		end
	end
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

	for _, child in ipairs(Icons.GetOrCacheChildren(viewer)) do
		if child.GetCooldownID then
			local cooldownID = child:GetCooldownID()
			local _, childData = GetSpellConfigByCooldownID(SCM.spellConfig, cooldownID)
			local group = Icons.GetConfiguredGroupForCategory(childData, categoryIndex)
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

	local children = Icons.GetOrCacheChildren(viewer)
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
				local group = Icons.GetConfiguredGroupForCategory(childData, categoryIndex)
				local groupConfig = childData.anchorGroup[group]
				if not (group and groupConfig) then
					if oldGroup then
						Cache.cachedAnchorStates[oldGroup].layoutSignature = nil
						scopedAnchorGroups[oldGroup] = true
					end
				elseif oldCooldownID ~= cooldownID or oldGroup ~= group then
					if child.Icon.SCMDesaturated ~= nil then
						Icons.UpdateChildDesaturation(child, false)
					end
					child.SCMCooldownID = nil
					child.SCMState = nil

					if oldGroup then
						Cache.cachedAnchorStates[oldGroup].layoutSignature = nil
						scopedAnchorGroups[oldGroup] = true
					end
					local state = Cache.cachedAnchorStates[group]
					if state then
						state.layoutSignature = nil
					end
					scopedAnchorGroups[group] = true
				end
			end
		end
	end
end
