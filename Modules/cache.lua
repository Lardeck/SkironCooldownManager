local SCM = select(2, ...)

local Cache = SCM.Cache

Cache.cachedViewerScale = 1
Cache.cachedChildrenTbl = {}
Cache.cachedGroupedChildren = {}
Cache.cachedVisibleChildren = {}
Cache.cachedCooldownFrameTbl = {}
Cache.cachedChildsBySpellID = {}
Cache.cachedViewerChildren = {}
Cache.cachedActiveItemFrames = {}
Cache.cachedVisitedAnchorGroups = {}
Cache.cachedAnchorStates = {}
Cache.cachedAnchorChildren = {}
Cache.cachedAnchorLinks = {}
Cache.cachedAnchorLinksDirty = true
Cache.cachedAnchorQueue = {}
Cache.cachedAnchorOffsetVisited = {}
Cache.cachedParsedAnchorStrings = {}
Cache.cachedCustomSpellEntriesBySpellID = {}
Cache.cachedCustomItemEntriesByItemID = {}
Cache.cachedCustomSlotEntriesByItemID = {}
Cache.cachedCustomIconsByGroup = {}
Cache.customIconRequests = {}
Cache.scopedGroupTables = {}
Cache.cachedScopedAnchorGroups = {
	essential = {},
	utility = {},
	buff = {},
	buffBar = {},
}

function SCM:ClearChildrenCache()
	wipe(Cache.cachedChildrenTbl)
end

function SCM:ClearViewerChildrenCache()
	wipe(Cache.cachedViewerChildren)
end

function SCM:ResetCooldownViewerRuntimeState()
	local resetChild = self.Utils.ResetChildSCMState
	for viewerName in pairs(SCM.CooldownViewerNameToIndex) do
		local viewer = _G[viewerName]
		if viewer then
			local cachedChildren = Cache.cachedViewerChildren[viewer]
			if cachedChildren then
				for _, child in ipairs(cachedChildren) do
					resetChild(child)
				end
			end

			for _, child in ipairs({ viewer:GetChildren() }) do
				resetChild(child)
			end
		end
	end

	wipe(Cache.cachedViewerChildren)
	wipe(Cache.cachedChildsBySpellID)
	wipe(Cache.cachedChildrenTbl)
	wipe(Cache.cachedGroupedChildren)
	wipe(Cache.cachedCooldownFrameTbl)
	wipe(Cache.cachedVisitedAnchorGroups)
	wipe(Cache.cachedVisibleChildren)
	wipe(Cache.cachedAnchorChildren)

	for _, state in pairs(Cache.cachedAnchorStates) do
		state.layoutSignature = nil
		state.visibleChildCount = nil
	end
end

function SCM:InvalidateViewerChildrenCache(viewer)
	if viewer then
		Cache.cachedViewerChildren[viewer] = nil
		return
	end

	self:ClearViewerChildrenCache()
end

function SCM:InvalidatePixelPerfectCache()
	Cache.cachedPixelPerfectMultiplier = nil
end

function SCM:InvalidateAnchorLinks()
	Cache.cachedAnchorLinksDirty = true
end

function SCM:AcquireScopedGroupCache()
	local scopedGroupTables = Cache.scopedGroupTables
	local scopedGroups = scopedGroupTables[#scopedGroupTables]
	if scopedGroups then
		scopedGroupTables[#scopedGroupTables] = nil
		return scopedGroups
	end

	return {}
end

function SCM:ReleaseScopedGroupCache(scopedGroups)
	if not scopedGroups then
		return
	end

	wipe(scopedGroups)
	local scopedGroupTables = Cache.scopedGroupTables
	scopedGroupTables[#scopedGroupTables + 1] = scopedGroups
end

function SCM:GetPixelPerfectMultiplier()
	if not Cache.cachedPixelPerfectMultiplier then
		local screenHeight = select(2, GetPhysicalScreenSize())
		local scale = UIParent:GetEffectiveScale()
		if not screenHeight or screenHeight == 0 or not scale or scale == 0 then
			Cache.cachedPixelPerfectMultiplier = 1
		else
			Cache.cachedPixelPerfectMultiplier = (768 / screenHeight) / scale
		end
	end

	return Cache.cachedPixelPerfectMultiplier
end

function SCM:PixelPerfect(value)
	local pixelPerfectMultiplier = self:GetPixelPerfectMultiplier()
	if value ~= nil then
		return value * pixelPerfectMultiplier
	end

	return pixelPerfectMultiplier
end

function SCM:PixelPerfectSize(size)
	local multiplier = self:PixelPerfect()
	return floor((size / multiplier) + 0.5) * multiplier
end

