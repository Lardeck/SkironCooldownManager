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
	BUFF = "buff",
	BUFF_BAR = "buffBar",
}
CDM.UPDATE_SCOPE = UPDATE_SCOPE

local VIEWER_UPDATE_MAPPING = {
	[UPDATE_SCOPE.ESSENTIAL] = {
		frameName = "EssentialCooldownViewer",
		isBuffIcon = false,
	},
	[UPDATE_SCOPE.UTILITY] = {
		frameName = "UtilityCooldownViewer",
		isBuffIcon = false,
	},
	[UPDATE_SCOPE.BUFF] = {
		frameName = "BuffIconCooldownViewer",
		isBuffIcon = true,
	},
	[UPDATE_SCOPE.BUFF_BAR] = {
		frameName = "BuffBarCooldownViewer",
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
	if self.db.profile.options.debug then
		print(addonName, ...)
	end
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
			local anchorConfig = anchorConfigList[group]
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
			local anchorConfig = buffBarsAnchorConfig[index]
			local group = ToBuffBarGroup(index)
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

local function LayoutAnchorGroup(group, visibleChildren, anchorConfig, options, changedGroups, resetSize)
	local state = GetAnchorState(group)
	local rowConfig = (anchorConfig and anchorConfig.rowConfig and #anchorConfig.rowConfig > 0) and anchorConfig.rowConfig or DEFAULT_ROW_CONFIG
	local lastRowConfig = rowConfig[#rowConfig]
	local growDir = anchorConfig and anchorConfig.grow or "CENTERED"
	local secondaryGrowDir = anchorConfig and anchorConfig.secondaryGrow or "DOWN"
	local baseSpacing = anchorConfig and anchorConfig.spacing or 0
	local point, anchor, relativePoint, xOffset, yOffset = unpack(anchorConfig and anchorConfig.anchor or DEFAULT_ANCHOR)
	local initialWidth = rowConfig[1].iconWidth or rowConfig[1].size or 47
	local initialHeight = rowConfig[1].iconHeight or rowConfig[1].size or 47
	local isCentered = growDir == "CENTER" or growDir == "CENTERED"
	local isFixed = growDir == "FIXED"
	local growsUp = secondaryGrowDir == "UP"
	local verticalPoint = growsUp and "BOTTOM" or "TOP"
	local startPoint = (isCentered or isFixed) and verticalPoint or (verticalPoint .. (growDir == "LEFT" and "RIGHT" or "LEFT"))
	local pivot = SCM:GetAnchorPivot(point, growDir)
	local parentGroup = Utils.ParseAnchorString(anchor)
	local rows = state.rows
	local layoutChildren = visibleChildren
	local childIndex = 1
	local rowIndex = 1
	local rowCount = 0
	local accumulatedY = 0
	local maxGroupWidth = 0
	local totalChildren
	local scaleData = anchorConfig and anchorConfig.advancedScale

	table.sort(visibleChildren, SortBySCMOrder)

	if isFixed then
		layoutChildren = Cache.cachedChildrenTbl[group] or visibleChildren
		table.sort(layoutChildren, SortBySCMOrder)
	end

	Cache.cachedAnchorChildren[group] = visibleChildren
	totalChildren = #layoutChildren

	while childIndex <= totalChildren do
		local currentRowConfig = rowConfig[rowIndex] or lastRowConfig
		if currentRowConfig.hardLimit then
			totalChildren = min(#visibleChildren, childIndex + currentRowConfig.limit - 1)
		end

		local rowLimit = min(totalChildren, currentRowConfig.limit or 8)
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

		local endIndex = min(childIndex + rowLimit - 1, #layoutChildren)
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
		wipe(rows[index])
		rows[index] = nil
	end

	local effectiveWidth = max(initialWidth, maxGroupWidth, 1)
	local effectiveHeight = max(initialHeight, accumulatedY - baseSpacing, 1)
	local firstRowHeight = (rows[1] and rows[1].rowIconHeight) or initialHeight
	local heightDelta = max(effectiveHeight - firstRowHeight, 0)
	local anchorOffsetY = secondaryGrowDir == "UP" and ((pivot:find("TOP") and heightDelta) or (not pivot:find("BOTTOM") and heightDelta / 2) or 0)
		or ((pivot:find("BOTTOM") and -heightDelta) or (not pivot:find("TOP") and -heightDelta / 2) or 0)
	local boundsChanged = state.effectiveWidth ~= effectiveWidth or state.effectiveHeight ~= effectiveHeight or state.anchorOffsetY ~= anchorOffsetY
	local groupAnchor = SCM:GetAnchor(group, point, anchor, relativePoint, xOffset, yOffset, growDir, initialWidth, resetSize, anchorOffsetY)

	if state.parentGroup ~= parentGroup then
		Cache.cachedAnchorLinksDirty = true
	end

	state.relativePoint = relativePoint
	state.startPoint = startPoint
	state.pivot = pivot
	state.parentGroup = parentGroup
	state.effectiveWidth = effectiveWidth
	state.effectiveHeight = effectiveHeight
	state.anchorOffsetY = anchorOffsetY

	if state.appliedWidth == nil then
		state.appliedWidth = effectiveWidth
	end
	if state.appliedHeight == nil then
		state.appliedHeight = effectiveHeight
	end
	if state.appliedAnchorOffsetY == nil then
		state.appliedAnchorOffsetY = anchorOffsetY
	end

	SCM:UpdateAnchorOffset(group, true)

	for currentRow = 1, rowCount do
		local row = rows[currentRow]
		for currentChild = row.startIndex, row.endIndex do
			local rowChild = currentChild - row.startIndex
			local child = layoutChildren[currentChild]
			local offsetX = 0

			child.SCMRowConfig = row.rowConfig
			if child.SCMLayoutLimited then
				child.SCMLayoutLimited = nil
				Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
			end

			if isCentered or isFixed then
				offsetX = (rowChild * (row.rowIconWidth + baseSpacing)) - (row.rowWidth / 2) + (row.rowIconWidth / 2)
			elseif growDir == "LEFT" then
				offsetX = -(rowChild * (row.rowIconWidth + baseSpacing))
			else
				offsetX = rowChild * (row.rowIconWidth + baseSpacing)
			end

			if child.SCMShouldBeVisible then
				SCM:UpdateManagedAnchorChild(child, groupAnchor, startPoint, offsetX, row.offsetY, row.rowIconWidth, row.rowIconHeight)
			end

			if not child.SCMBuffBar then
				SCM:SkinChild(child, child.SCMConfig)
			end
		end
	end

	if totalChildren < #visibleChildren then
		for index = totalChildren + 1, #visibleChildren do
			local child = visibleChildren[index]
			child.SCMLayoutLimited = true
			child.SCMLayoutApplied = nil
			Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
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

			SCM:UpdateUUFValues(options, effectiveWidth, rowConfig)
		end
	end

	if group == 1 then
		SCM:ApplyCustomAnchors(effectiveWidth, rowConfig)
	end

	if boundsChanged and changedGroups then
		changedGroups[group] = true
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

local function OrderCDManagerSpells_Actual(updateScope, scopedAnchorGroupsOverride)
	Cache.cachedViewerScale = 1

	wipe(Cache.cachedChildrenTbl)
	wipe(Cache.cachedCooldownFrameTbl)

	local config = SCM.currentConfig
	local isFullAllUpdate = updateScope == UPDATE_SCOPE.ALL and not scopedAnchorGroupsOverride
	local isFullBuffBarUpdate = updateScope == UPDATE_SCOPE.BUFF_BAR and not scopedAnchorGroupsOverride
	local scopedAnchorGroups = scopedAnchorGroupsOverride
	if not scopedAnchorGroups and not isFullBuffBarUpdate then
		scopedAnchorGroups = Icons.CollectScopedAnchorGroups(updateScope, config, VIEWER_UPDATE_MAPPING)
	end
	local options = SCM.db.profile.options
	local changedGroups = SCM:AcquireScopedGroupCache()
	Cache.activeScopedAnchorGroups = scopedAnchorGroups

	UpdateAnchorLinks(config)

	local viewerProcessOrder = (scopedAnchorGroups and updateScope ~= UPDATE_SCOPE.BUFF_BAR)
			and VIEWER_PROCESS_ORDER
		or VIEWER_PROCESS_ORDER_BY_SCOPE[updateScope]
		or VIEWER_PROCESS_ORDER
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
		for _, customConfig in pairs(SCM.customConfig) do
			CustomIcons.ProcessIcons(customConfig, Cache.cachedCooldownFrameTbl)
		end

		for _, customConfig in pairs(SCM.globalCustomConfig) do
			CustomIcons.ProcessIcons(customConfig, Cache.cachedCooldownFrameTbl, true)
		end
	end

	for group, visibleChildren in pairs(Cache.cachedCooldownFrameTbl) do
		LayoutAnchorGroup(group, visibleChildren, Utils.GetAnchorConfigForGroup(config, group, SCM.globalAnchorConfig, SCM.buffBarsAnchorConfig), options, changedGroups)
	end

	if not isFullBuffBarUpdate then
		for _, children in pairs(Cache.cachedChildrenTbl) do
			for _, child in ipairs(children) do
				Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
			end
		end
	end

	wipe(Cache.cachedVisitedAnchorGroups)
	if updateScope ~= UPDATE_SCOPE.BUFF_BAR then
		if config.anchorConfig then
			for group = 1, #config.anchorConfig do
				local anchorConfig = config.anchorConfig[group]
				Cache.cachedVisitedAnchorGroups[group] = true
				LayoutEmptyAnchorGroup(group, anchorConfig, scopedAnchorGroups, changedGroups, options)
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
				local anchorConfig = config.buffBarsAnchorConfig[index]
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
local hasPendingUpdate = false
local pendingUpdateScope

local function MergeUpdateScope(currentScope, newScope)
	if not currentScope then
		return newScope
	end

	if currentScope == UPDATE_SCOPE.ALL or newScope == UPDATE_SCOPE.ALL then
		return UPDATE_SCOPE.ALL
	end

	if currentScope ~= newScope then
		return UPDATE_SCOPE.ALL
	end

	return currentScope
end

local function OnOrderThrottleTick()
	isThrottled = false
	if hasPendingUpdate then
		hasPendingUpdate = false
		OrderCDManagerSpells_Actual(pendingUpdateScope or UPDATE_SCOPE.ALL)
		pendingUpdateScope = nil
	end
end

local function OrderCDManagerSpells(updateScope, applyNow)
	updateScope = updateScope or UPDATE_SCOPE.ALL
	if updateScope == UPDATE_SCOPE.BUFF or updateScope == UPDATE_SCOPE.BUFF_BAR or applyNow then
		OrderCDManagerSpells_Actual(updateScope)
		return
	end
	if isThrottled then
		pendingUpdateScope = MergeUpdateScope(pendingUpdateScope, updateScope)
		return
	end

	hasPendingUpdate = true
	isThrottled = true
	C_Timer.After(0.1, OnOrderThrottleTick)
end
CDM.OrderSpells = OrderCDManagerSpells
