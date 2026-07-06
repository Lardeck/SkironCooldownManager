local addonName, SCM = ...

local Cache = SCM.Cache
local Utils = SCM.Utils
local ToGlobalGroup = Utils.ToGlobalGroup
local ToBuffBarGroup = Utils.ToBuffBarGroup
local SortBySCMOrder = Utils.SortBySCMOrder
local AddChildToGroup = Utils.AddChildToGroup
local CustomIcons = SCM.CustomIcons

local Icons = SCM.Icons
local Utils = SCM.Utils
local CDM = SCM.CDM

local UPDATE_SCOPE = {
	ALL = "all",
	ESSENTIAL = "essential",
	UTILITY = "utility",
	ESSENTIAL_UTILITY = "essentialUtility",
	BUFF = "buff",
	BUFF_BAR = "buffBar",
}
CDM.UPDATE_SCOPE = UPDATE_SCOPE

local VIEWER_UPDATE_MAPPING = {
	[UPDATE_SCOPE.ESSENTIAL] = {
		frameName = "EssentialCooldownViewer",
		updateScope = UPDATE_SCOPE.ESSENTIAL,
		isBuffIcon = false,
	},
	[UPDATE_SCOPE.UTILITY] = {
		frameName = "UtilityCooldownViewer",
		updateScope = UPDATE_SCOPE.UTILITY,
		isBuffIcon = false,
	},
	[UPDATE_SCOPE.BUFF] = {
		frameName = "BuffIconCooldownViewer",
		updateScope = UPDATE_SCOPE.BUFF,
		isBuffIcon = true,
	},
	[UPDATE_SCOPE.BUFF_BAR] = {
		frameName = "BuffBarCooldownViewer",
		updateScope = UPDATE_SCOPE.BUFF_BAR,
		isBuffBar = true,
	},
}

local VIEWER_PROCESS_ORDER = {
	VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.ESSENTIAL],
	VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.UTILITY],
	VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.BUFF],
	VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.BUFF_BAR],
}

local VIEWER_PROCESS_ORDER_BY_SCOPE = {
	[UPDATE_SCOPE.ALL] = VIEWER_PROCESS_ORDER,
	[UPDATE_SCOPE.ESSENTIAL] = { VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.ESSENTIAL] },
	[UPDATE_SCOPE.UTILITY] = { VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.UTILITY] },
	[UPDATE_SCOPE.BUFF] = { VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.BUFF] },
	[UPDATE_SCOPE.BUFF_BAR] = { VIEWER_UPDATE_MAPPING[UPDATE_SCOPE.BUFF_BAR] },
}

local DEFAULT_ROW_CONFIG = { { limit = 8, iconWidth = 47, iconHeight = 47 } }
local DEFAULT_ANCHOR = { "CENTER", UIParent, "CENTER", 0, 0 }

function SCM:Debug(...)
	local options = self.db.profile.options
	if not options.debug then
		return
	end

	local debugGroup = tonumber(options.debugGroup)
	if debugGroup and debugGroup > 0 then
		local matchedGroup = false
		local numArgs = select("#", ...)
		for index = 1, numArgs - 1 do
			if (select(index, ...)) == "group" and tonumber((select(index + 1, ...))) == debugGroup then
				matchedGroup = true
				break
			end
		end

		if not matchedGroup then
			return
		end
	end

	print(addonName, ...)
end

local function IsScopedGroup(scopedAnchorGroups, group)
	return not scopedAnchorGroups or scopedAnchorGroups[group]
end

local function IsScopedAnchorGroupAllowed(group, isGlobal)
	local effectiveGroup = isGlobal and ToGlobalGroup(group) or group
	return IsScopedGroup(Cache.activeScopedAnchorGroups, effectiveGroup)
end
CDM.IsScopedAnchorGroupAllowed = IsScopedAnchorGroupAllowed

local function AddChildToScopedGroup(validChildren, group, child, isGlobal)
	if IsScopedAnchorGroupAllowed(group, isGlobal) then
		AddChildToGroup(validChildren, group, child, isGlobal)
	end
end
CDM.AddChildToScopedGroup = AddChildToScopedGroup

local function CollectScopedAnchorGroups(updateScope, config)
	if updateScope ~= UPDATE_SCOPE.ESSENTIAL_UTILITY then
		return Icons.CollectScopedAnchorGroups(updateScope, config, VIEWER_UPDATE_MAPPING)
	end

	local targetGroups = Icons.CollectScopedAnchorGroups(UPDATE_SCOPE.ESSENTIAL, config, VIEWER_UPDATE_MAPPING)

	for group in pairs(Icons.CollectScopedAnchorGroups(UPDATE_SCOPE.UTILITY, config, VIEWER_UPDATE_MAPPING)) do
		targetGroups[group] = true
	end

	return targetGroups
end

local function GetAnchorState(group)
	local state = Cache.cachedAnchorStates[group]
	if not state then
		state = { rows = {} }
		Cache.cachedAnchorStates[group] = state
	end

	return state
end

local function UpdateAnchorLinks(config)
	local anchorLinks = Cache.cachedAnchorLinks
	if not Cache.cachedAnchorLinksDirty then
		return anchorLinks
	end

	for _, linkedGroups in pairs(anchorLinks) do
		wipe(linkedGroups)
	end

	for _, state in pairs(Cache.cachedAnchorStates) do
		state.parentGroup = nil
	end

	local anchorConfigList = config and config.anchorConfig
	if anchorConfigList then
		for group = 1, #anchorConfigList do
			local anchorConfig = Utils.GetAnchorConfigForGroup(config, group)
			local parentGroup = Utils.ParseAnchorString(anchorConfig and anchorConfig.anchor and anchorConfig.anchor[2])
			local state = GetAnchorState(group)
			state.parentGroup = parentGroup
			if parentGroup then
				local linkedGroups = anchorLinks[parentGroup]
				if not linkedGroups then
					linkedGroups = {}
					anchorLinks[parentGroup] = linkedGroups
				end
				linkedGroups[group] = true
			end
		end
	end

	local globalAnchorConfig = SCM.globalAnchorConfig
	if globalAnchorConfig then
		for index = 1, #globalAnchorConfig do
			local anchorConfig = globalAnchorConfig[index]
			local group = ToGlobalGroup(index)
			local parentGroup = Utils.ParseAnchorString(anchorConfig and anchorConfig.anchor and anchorConfig.anchor[2])
			local state = GetAnchorState(group)
			state.parentGroup = parentGroup
			if parentGroup then
				local linkedGroups = anchorLinks[parentGroup]
				if not linkedGroups then
					linkedGroups = {}
					anchorLinks[parentGroup] = linkedGroups
				end
				linkedGroups[group] = true
			end
		end
	end

	local buffBarsAnchorConfig = config and config.buffBarsAnchorConfig
	if buffBarsAnchorConfig then
		for index = 1, #buffBarsAnchorConfig do
			local group = ToBuffBarGroup(index)
			local anchorConfig = Utils.GetAnchorConfigForGroup(config, index, nil, true)
			local parentGroup = Utils.ParseAnchorString(anchorConfig and anchorConfig.anchor and anchorConfig.anchor[2])
			local state = GetAnchorState(group)
			state.parentGroup = parentGroup
			if parentGroup then
				local linkedGroups = anchorLinks[parentGroup]
				if not linkedGroups then
					linkedGroups = {}
					anchorLinks[parentGroup] = linkedGroups
				end
				linkedGroups[group] = true
			end
		end
	end

	Cache.cachedAnchorLinksDirty = false
	return anchorLinks
end

local function GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
	local duplicateChild = child.SCMLayoutNextDuplicate
	if duplicateChild and (duplicateChild == masterChild or duplicateChild:GetCooldownID() ~= masterCooldownID) then
		child.SCMLayoutNextDuplicate = nil
		return
	end

	return duplicateChild
end

local function LayoutManagedAnchorChild(child, row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)
	child.SCMRowConfig = row.rowConfig
	child.SCMAnchorFrameStrata = anchorConfig and anchorConfig.frameStrata or nil

	if child.SCMLayoutLimited then
		child.SCMLayoutLimited = nil
		Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
	end

	if child.SCMShouldBeVisible then
		SCM:UpdateManagedAnchorChild(child, childAnchor, startPoint, offsetX, row.offsetY, row.rowIconWidth, row.rowIconHeight, useProxyAnchor)
	end

	if not child.SCMBuffBar then
		SCM:SkinChild(child, child.SCMConfig)
	else
		SCM:SkinBuffBar(child, child.SCMConfig)
	end
	child.SCMChanged = false
end

local function CollapseDuplicateChildren(layoutChildren, layoutChildCount)
	local uniqueChildren = Cache.cachedLayoutChildren
	local seenCooldownIDs = Cache.cachedLayoutCooldownIDs
	local hasDuplicateChildren = false
	local totalChildren = 0

	if not uniqueChildren then
		uniqueChildren = {}
		Cache.cachedLayoutChildren = uniqueChildren
	else
		wipe(uniqueChildren)
	end
	if not seenCooldownIDs then
		seenCooldownIDs = {}
		Cache.cachedLayoutCooldownIDs = seenCooldownIDs
	else
		wipe(seenCooldownIDs)
	end

	for index = 1, layoutChildCount do
		local child = layoutChildren[index]
		local cooldownID = child.SCMCooldownID
		child.SCMLayoutNextDuplicate = nil

		if cooldownID then
			local masterChild = seenCooldownIDs[cooldownID]
			if masterChild then
				hasDuplicateChildren = true
				if masterChild ~= child then
					child.SCMLayoutNextDuplicate = masterChild.SCMLayoutNextDuplicate
					masterChild.SCMLayoutNextDuplicate = child
				end
			else
				seenCooldownIDs[cooldownID] = child
				totalChildren = totalChildren + 1
				uniqueChildren[totalChildren] = child
			end
		else
			totalChildren = totalChildren + 1
			uniqueChildren[totalChildren] = child
		end
	end

	wipe(seenCooldownIDs)
	if hasDuplicateChildren then
		return uniqueChildren, totalChildren
	end

	wipe(uniqueChildren)
	return layoutChildren, layoutChildCount
end

local function LayoutAnchorGroup(group, visibleChildren, anchorConfig, options, changedGroups, resetSize, allowLayoutSkip)
	Cache.cachedVisitedAnchorGroups[group] = true

	local state = GetAnchorState(group)
	local rowConfig = anchorConfig.rowConfig or DEFAULT_ROW_CONFIG
	local lastRowConfig = rowConfig[#rowConfig]
	local growDir = anchorConfig.grow or "CENTERED"
	local secondaryGrowDir = anchorConfig.secondaryGrow or "DOWN"
	local baseSpacing = anchorConfig.spacing or 0
	local point, anchor, relativePoint, xOffset, yOffset = unpack(anchorConfig and anchorConfig.anchor or DEFAULT_ANCHOR)
	local initialWidth = (rowConfig[1].useFixedWidth and rowConfig[1].fixedWidth) or rowConfig[1].iconWidth or rowConfig[1].size or 47
	local initialHeight = rowConfig[1].iconHeight or rowConfig[1].size or 47
	local isCentered = growDir == "CENTER" or growDir == "CENTERED"
	local isFixed = growDir == "FIXED"
	local lockGroupSize = group == 1 and SCM.anchorFrames[1] and SCM.anchorFrames[1]:IsProtected() and InCombatLockdown()
	local growsUp = secondaryGrowDir == "UP"
	local verticalPoint = growsUp and "BOTTOM" or "TOP"
	local startPoint = (isCentered or isFixed) and verticalPoint or (verticalPoint .. (growDir == "LEFT" and "RIGHT" or "LEFT"))
	local pivot = SCM:GetAnchorPivot(point, growDir)
	local parentGroup = Utils.ParseAnchorString(anchor)
	local matchedAnchorWidth
	if anchorConfig.matchAnchorWidth and Utils.IsBuffBarGroup(group) then
		local anchorFrame = Utils.GetAnchorFrame(anchor)
		if anchorFrame then
			matchedAnchorWidth = max(anchorFrame:GetWidth(), 1)
		end
	end
	local rows = state.rows
	local layoutChildren = visibleChildren
	local childIndex = 1
	local rowIndex = 1
	local rowCount = 0
	local accumulatedY = 0
	local maxGroupWidth = 0
	local totalChildren
	-- Doesn't exist yet as an option but it will at some point
	local scaleData = anchorConfig and anchorConfig.advancedScale
	local configuredChildren = Cache.cachedChildrenTbl[group]
	local layoutChildCount
	local visibleChildCount = #visibleChildren
	local configuredChildCount = configuredChildren and #configuredChildren or 0
	local layoutSignature = visibleChildCount
	local hasChangedChild = false

	table.sort(visibleChildren, SortBySCMOrder)
	for index = 1, visibleChildCount do
		local child = visibleChildren[index]
		hasChangedChild = hasChangedChild or child.SCMChanged
		local cooldownID = child.SCMCooldownID
		local cooldownSignature = tonumber(cooldownID) or 0
		if cooldownSignature == 0 and cooldownID then
			cooldownID = tostring(cooldownID)
			for byteIndex = 1, #cooldownID do
				cooldownSignature = cooldownSignature + (cooldownID:byte(byteIndex) * byteIndex)
			end
		end
		layoutSignature = layoutSignature + (cooldownSignature * index) + ((child.SCMOrder or 0) * 17)
	end

	if isFixed then
		layoutChildren = configuredChildren or visibleChildren
		table.sort(layoutChildren, SortBySCMOrder)
	end

	Cache.cachedAnchorChildren[group] = visibleChildren
	state.visibleChildCount = visibleChildCount

	layoutChildCount = #layoutChildren
	layoutSignature = layoutSignature + (configuredChildCount * 31) + (layoutChildCount * 131) + (lockGroupSize and 8191 or 0)

	if allowLayoutSkip and not hasChangedChild and not resetSize and not SCM.isOptionsOpen and state.layoutSignature == layoutSignature then
		return
	end

	state.layoutSignature = layoutSignature

	layoutChildren, layoutChildCount = CollapseDuplicateChildren(layoutChildren, layoutChildCount)
	totalChildren = layoutChildCount
	local hardLimitChildCount = lockGroupSize and layoutChildCount or visibleChildCount

	while childIndex <= totalChildren do
		local currentRowConfig = rowConfig[rowIndex] or lastRowConfig
		local rowLimit = max(currentRowConfig.limit or 8, 1)
		if currentRowConfig.hardLimit then
			totalChildren = min(hardLimitChildCount, layoutChildCount, childIndex + rowLimit - 1)
		end

		local rowIconWidth = currentRowConfig.iconWidth or currentRowConfig.size or 47
		local rowIconHeight = currentRowConfig.iconHeight or currentRowConfig.size or 47

		if scaleData then
			local targetViewer = Cache.cachedCooldownFrameTbl[scaleData.viewer]
			local targetGroup = targetViewer and targetViewer[scaleData.anchorGroup]
			if targetGroup and #targetGroup <= scaleData.numChildren then
				rowIconWidth = scaleData.iconWidth or scaleData.size or rowIconWidth
				rowIconHeight = scaleData.iconHeight or scaleData.size or rowIconHeight
			end
		end

		if matchedAnchorWidth then
			rowIconWidth = matchedAnchorWidth
		end

		local endIndex = min(childIndex + rowLimit - 1, totalChildren)
		local numInRow = endIndex - childIndex + 1
		local rowWidth = (numInRow * rowIconWidth) + ((numInRow - 1) * baseSpacing)
		local fixedWidth = (currentRowConfig.useFixedWidth and currentRowConfig.fixedWidth) or rowWidth
		local row = rows[rowCount + 1]

		if fixedWidth > maxGroupWidth then
			maxGroupWidth = fixedWidth
		end

		if not row then
			row = {}
			rows[rowCount + 1] = row
		end

		rowCount = rowCount + 1
		row.startIndex = childIndex
		row.endIndex = endIndex
		row.rowConfig = currentRowConfig
		row.rowIconWidth = rowIconWidth
		row.rowIconHeight = rowIconHeight
		row.rowWidth = rowWidth
		row.offsetY = growsUp and accumulatedY or -accumulatedY

		accumulatedY = accumulatedY + rowIconHeight + baseSpacing
		childIndex = endIndex + 1
		rowIndex = rowIndex + 1
	end

	for index = rowCount + 1, #rows do
		rows[index] = nil
	end

	local firstRow = rows[1]
	local firstRowWidth = (firstRow and firstRow.rowIconWidth) or initialWidth
	local firstRowHeight = (firstRow and firstRow.rowIconHeight) or initialHeight
	local effectiveWidth = max(firstRowWidth, maxGroupWidth, 1)
	if matchedAnchorWidth then
		effectiveWidth = matchedAnchorWidth
	end
	local effectiveHeight = max(firstRowHeight, accumulatedY - baseSpacing, 1)
	local heightDelta = max(effectiveHeight - firstRowHeight, 0)
	local anchorOffsetY = secondaryGrowDir == "UP" and ((pivot:find("TOP") and heightDelta) or (not pivot:find("BOTTOM") and heightDelta / 2) or 0)
		or ((pivot:find("BOTTOM") and -heightDelta) or (not pivot:find("TOP") and -heightDelta / 2) or 0)
	local boundsChanged = state.effectiveWidth ~= effectiveWidth or state.effectiveHeight ~= effectiveHeight or state.anchorOffsetY ~= anchorOffsetY
	local parentChanged = state.parentGroup ~= parentGroup

	state.relativePoint = relativePoint
	state.startPoint = startPoint
	state.pivot = pivot
	state.parentGroup = parentGroup
	state.effectiveWidth = effectiveWidth
	state.effectiveHeight = effectiveHeight
	state.anchorOffsetY = anchorOffsetY

	local groupAnchor = SCM:GetAnchor(group, point, anchor, relativePoint, xOffset, yOffset, growDir, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY)

	if parentChanged then
		Cache.cachedAnchorLinksDirty = true
	end

	if state.appliedWidth == nil then
		state.appliedWidth = effectiveWidth
	end
	if state.appliedHeight == nil then
		state.appliedHeight = effectiveHeight
	end
	if state.appliedAnchorOffsetY == nil then
		state.appliedAnchorOffsetY = anchorOffsetY
	end

	local childAnchor, useProxyAnchor =
		SCM:GetManagedAnchorChildAnchor(group, groupAnchor, point, anchor, relativePoint, xOffset, yOffset, growDir, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY, lockGroupSize)
	local anchorOffsetChanged = SCM:UpdateAnchorOffset(group, true)
	if useProxyAnchor and changedGroups and anchorOffsetChanged then
		changedGroups[group] = true
	end

	for currentRow = 1, rowCount do
		local row = rows[currentRow]
		for currentChild = row.startIndex, row.endIndex do
			local rowChild = currentChild - row.startIndex
			local child = layoutChildren[currentChild]
			local offsetX = 0

			if isCentered or isFixed then
				offsetX = (rowChild * (row.rowIconWidth + baseSpacing)) - (row.rowWidth / 2) + (row.rowIconWidth / 2)
			elseif growDir == "LEFT" then
				offsetX = -(rowChild * (row.rowIconWidth + baseSpacing))
			else
				offsetX = rowChild * (row.rowIconWidth + baseSpacing)
			end

			LayoutManagedAnchorChild(child, row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)

			if child.SCMLayoutNextDuplicate then
				local masterChild = child
				local masterCooldownID = child.SCMCooldownID
				local duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
				while duplicateChild do
					child = duplicateChild
					LayoutManagedAnchorChild(child, row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)

					duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
				end
			end
		end
	end

	if totalChildren < layoutChildCount then
		for index = totalChildren + 1, layoutChildCount do
			local child = layoutChildren[index]
			if child.SCMShouldBeVisible then
				child.SCMLayoutLimited = true
				child.SCMLayoutApplied = nil
				Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
			end

			if child.SCMLayoutNextDuplicate then
				local masterChild = child
				local masterCooldownID = child.SCMCooldownID
				local duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
				while duplicateChild do
					child = duplicateChild
					if child.SCMShouldBeVisible then
						child.SCMLayoutLimited = true
						child.SCMLayoutApplied = nil
						Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
					end

					duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
				end
			end
		end
	end

	if not InCombatLockdown() and groupAnchor then
		groupAnchor:SetSize(effectiveWidth, effectiveHeight)
		state.appliedWidth = effectiveWidth
		state.appliedHeight = effectiveHeight
		state.appliedAnchorOffsetY = anchorOffsetY

		if group == 1 then
			if options.adjustResourceWidth and C_AddOns.IsAddOnLoaded("SenseiClassResourceBar") then
				if SCRB and SCRB.registerCustomFrame then
					SCRB.registerCustomFrame(SCM:GetAnchor(1))
				else
					SCM:UpdateResourceBarWidth(effectiveWidth)
				end
			end

			SCM:UpdateUFValues(options, effectiveWidth, rowConfig)
		end
	end

	if group == 1 then
		SCM:ApplyCustomAnchors(effectiveWidth, rowConfig)
	end

	if boundsChanged and changedGroups then
		changedGroups[group] = true
	end

	if layoutChildren == Cache.cachedLayoutChildren then
		wipe(layoutChildren)
	end
end

local function LayoutEmptyAnchorGroup(group, anchorConfig, scopedAnchorGroups, changedGroups, options)
	if not IsScopedGroup(scopedAnchorGroups, group) or Cache.cachedCooldownFrameTbl[group] then
		return
	end

	local emptyChildren = Cache.cachedAnchorChildren[group]
	if not emptyChildren then
		emptyChildren = {}
		Cache.cachedAnchorChildren[group] = emptyChildren
	else
		wipe(emptyChildren)
	end

	LayoutAnchorGroup(group, emptyChildren, anchorConfig, options, changedGroups, true)
end

local function UpdateAnchorChain(changedGroups, config)
	if not InCombatLockdown() or not next(changedGroups) then
		return
	end

	local anchorLinks = UpdateAnchorLinks(config)
	local visitedGroups = SCM:AcquireScopedGroupCache()
	local queue = Cache.cachedAnchorQueue
	local queueIndex = 1

	wipe(queue)

	for group in pairs(changedGroups) do
		local linkedGroups = anchorLinks[group]
		if linkedGroups then
			for linkedGroup in pairs(linkedGroups) do
				queue[#queue + 1] = linkedGroup
			end
		end
	end

	while queueIndex <= #queue do
		local group = queue[queueIndex]
		queueIndex = queueIndex + 1

		if not visitedGroups[group] then
			visitedGroups[group] = true
			if SCM:UpdateAnchorOffset(group) then
				local linkedGroups = anchorLinks[group]
				if linkedGroups then
					for linkedGroup in pairs(linkedGroups) do
						queue[#queue + 1] = linkedGroup
					end
				end
			end
		end
	end

	wipe(queue)
	SCM:ReleaseScopedGroupCache(visitedGroups)
end

local function MergeUpdateScope(currentScope, newScope)
	if not currentScope or currentScope == newScope then
		return newScope
	end

	if currentScope == UPDATE_SCOPE.ALL or newScope == UPDATE_SCOPE.ALL then
		return UPDATE_SCOPE.ALL
	end

	local currentIsEssentialUtility = currentScope == UPDATE_SCOPE.ESSENTIAL or currentScope == UPDATE_SCOPE.UTILITY or currentScope == UPDATE_SCOPE.ESSENTIAL_UTILITY
	local newIsEssentialUtility = newScope == UPDATE_SCOPE.ESSENTIAL or newScope == UPDATE_SCOPE.UTILITY or newScope == UPDATE_SCOPE.ESSENTIAL_UTILITY
	if currentIsEssentialUtility and newIsEssentialUtility then
		return UPDATE_SCOPE.ESSENTIAL_UTILITY
	end

	return UPDATE_SCOPE.ALL
end

local function OrderCDManagerSpells_Actual(updateScope, scopedAnchorGroupsOverride)
	Cache.cachedViewerScale = 1

	wipe(Cache.cachedChildrenTbl)
	wipe(Cache.cachedCooldownFrameTbl)

	local config = SCM.currentConfig
	local isFullAllUpdate = updateScope == UPDATE_SCOPE.ALL and not scopedAnchorGroupsOverride
	local isFullBuffBarUpdate = updateScope == UPDATE_SCOPE.BUFF_BAR and not scopedAnchorGroupsOverride
	local scopedAnchorGroups = scopedAnchorGroupsOverride
	if not scopedAnchorGroups and not isFullBuffBarUpdate then
		scopedAnchorGroups = CollectScopedAnchorGroups(updateScope, config)
	end
	local options = SCM.db.profile.options
	local changedGroups = SCM:AcquireScopedGroupCache()
	Cache.activeScopedAnchorGroups = scopedAnchorGroups

	UpdateAnchorLinks(config)

	local viewerProcessOrder = (scopedAnchorGroups and updateScope ~= UPDATE_SCOPE.BUFF_BAR) and VIEWER_PROCESS_ORDER or VIEWER_PROCESS_ORDER_BY_SCOPE[updateScope] or VIEWER_PROCESS_ORDER
	if scopedAnchorGroups and updateScope ~= UPDATE_SCOPE.BUFF_BAR then
		for i = 1, #viewerProcessOrder do
			local viewerData = viewerProcessOrder[i]
			Icons.ExpandScopedAnchorGroups(_G[viewerData.frameName], viewerData, scopedAnchorGroups)
		end
	end

	for i = 1, #viewerProcessOrder do
		local viewerData = viewerProcessOrder[i]
		Icons.ProcessChildren(_G[viewerData.frameName], Cache.cachedChildrenTbl, viewerData)
	end

	for group, children in pairs(Cache.cachedChildrenTbl) do
		if IsScopedGroup(scopedAnchorGroups, group) then
			local visibleChildren = GetOrCreateTableEntry(Cache.cachedVisibleChildren, group)
			wipe(visibleChildren)
			for _, child in ipairs(children) do
				if child.SCMShouldBeVisible then
					visibleChildren[#visibleChildren + 1] = child
				end
			end

			Cache.cachedCooldownFrameTbl[group] = visibleChildren
		end
	end

	if updateScope ~= UPDATE_SCOPE.BUFF_BAR then
		if scopedAnchorGroups then
			for group in pairs(scopedAnchorGroups) do
				CustomIcons.ProcessGroupIcons(group, Cache.cachedCooldownFrameTbl)
			end
		else
			CustomIcons.ProcessGroupIcons(nil, Cache.cachedCooldownFrameTbl)
		end
	end

	local allowLayoutSkip = scopedAnchorGroups and updateScope ~= UPDATE_SCOPE.BUFF_BAR
	wipe(Cache.cachedVisitedAnchorGroups)
	for group, visibleChildren in pairs(Cache.cachedCooldownFrameTbl) do
		LayoutAnchorGroup(group, visibleChildren, Utils.GetAnchorConfigForLayoutGroup(config, group), options, changedGroups, nil, allowLayoutSkip)
	end

	if not isFullBuffBarUpdate then
		for _, children in pairs(Cache.cachedChildrenTbl) do
			for _, child in ipairs(children) do
				local appliedVisibility = child.SCMShouldBeVisible and not child.SCMLayoutLimited
				local appliedLayoutLimited = child.SCMLayoutLimited and true or false
				if child.SCMAppliedVisibility ~= appliedVisibility or child.SCMAppliedLayoutLimited ~= appliedLayoutLimited then
					Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
				end
			end
		end
	end

	if updateScope ~= UPDATE_SCOPE.BUFF_BAR then
		if config.anchorConfig then
			for group = 1, #config.anchorConfig do
				if not Cache.cachedVisitedAnchorGroups[group] then
					local anchorConfig = Utils.GetAnchorConfigForGroup(config, group)
					Cache.cachedVisitedAnchorGroups[group] = true
					LayoutEmptyAnchorGroup(group, anchorConfig, scopedAnchorGroups, changedGroups, options)
				end
			end
		end

		if SCM.globalAnchorConfig then
			for index = 1, #SCM.globalAnchorConfig do
				local anchorConfig = SCM.globalAnchorConfig[index]
				local group = ToGlobalGroup(index)
				if not Cache.cachedVisitedAnchorGroups[group] then
					Cache.cachedVisitedAnchorGroups[group] = true
					LayoutEmptyAnchorGroup(group, anchorConfig, scopedAnchorGroups, changedGroups, options)
				end
			end
		end
	end

	if updateScope == UPDATE_SCOPE.ALL or updateScope == UPDATE_SCOPE.BUFF_BAR then
		if config.buffBarsAnchorConfig then
			for index = 1, #config.buffBarsAnchorConfig do
				local anchorConfig = Utils.GetAnchorConfigForGroup(config, index, nil, true)
				local group = ToBuffBarGroup(index)
				if not Cache.cachedVisitedAnchorGroups[group] then
					Cache.cachedVisitedAnchorGroups[group] = true
					LayoutEmptyAnchorGroup(group, anchorConfig, scopedAnchorGroups, changedGroups, options)
				end
			end
		end
	end

	if isFullAllUpdate or isFullBuffBarUpdate then
		SCM:SkinBuffBars()
	end

	UpdateAnchorChain(changedGroups, config)

	SCM:ReleaseScopedGroupCache(changedGroups)
	Cache.activeScopedAnchorGroups = nil
end
CDM.OrderSpellsActual = OrderCDManagerSpells_Actual

local isThrottled = false
local pendingUpdateScope

local function OnOrderThrottleTick()
	isThrottled = false
	if pendingUpdateScope then
		local updateScope = pendingUpdateScope
		pendingUpdateScope = nil
		OrderCDManagerSpells_Actual(updateScope)
	end
end

local function OrderCDManagerSpells(updateScope, applyNow)
	updateScope = updateScope or UPDATE_SCOPE.ALL

	if updateScope == UPDATE_SCOPE.BUFF or updateScope == UPDATE_SCOPE.BUFF_BAR or applyNow then
		if applyNow or updateScope == UPDATE_SCOPE.ALL then
			pendingUpdateScope = nil
		end
		OrderCDManagerSpells_Actual(updateScope)
		return
	end
	if isThrottled then
		pendingUpdateScope = MergeUpdateScope(pendingUpdateScope, updateScope)
		return
	end

	pendingUpdateScope = updateScope
	isThrottled = true
	C_Timer.After(0.1, OnOrderThrottleTick)
end
CDM.OrderSpells = OrderCDManagerSpells
