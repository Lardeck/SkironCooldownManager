local SCM = select(2, ...)

local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local Cache = SCM.Cache
local Utils = SCM.Utils

local ANCHOR_PROXY_SIZE_CHANGED_EVENT = "SkironCooldownManager.AnchorProxy.SizeChanged"

local PIVOT_MAP = {
	LEFT = {
		TOP = "TOPRIGHT",
		TOPLEFT = "TOPRIGHT",
		BOTTOM = "BOTTOMRIGHT",
		BOTTOMLEFT = "BOTTOMRIGHT",
		LEFT = "RIGHT",
	},
	RIGHT = {
		TOP = "TOPLEFT",
		TOPRIGHT = "TOPLEFT",
		BOTTOM = "BOTTOMLEFT",
		BOTTOMRIGHT = "BOTTOMLEFT",
		RIGHT = "LEFT",
	},
}

local POINT_OFFSETS = {
	TOPLEFT = { -0.5, 0.5 },
	TOP = { 0, 0.5 },
	TOPRIGHT = { 0.5, 0.5 },
	LEFT = { -0.5, 0 },
	CENTER = { 0, 0 },
	RIGHT = { 0.5, 0 },
	BOTTOMLEFT = { -0.5, -0.5 },
	BOTTOM = { 0, -0.5 },
	BOTTOMRIGHT = { 0.5, -0.5 },
}

local anchorDataByCooldownID = {}

local function GetAnchorState(group)
	local state = Cache.cachedAnchorStates[group]
	if not state then
		state = { rows = {} }
		Cache.cachedAnchorStates[group] = state
	end

	return state
end

local function OnChildSetPoint(child)
	if child.SCMSetPoint then
		return
	end

	local cooldownID = not child.SCMCustom and (child:GetCooldownID() or child.SCMCooldownID)
	local anchorData = cooldownID and anchorDataByCooldownID[cooldownID] or not cooldownID and child.SCMAnchorData
	local anchorFrame = anchorData and anchorData[2]
	if not anchorFrame or not anchorData then
		return
	end

	child.SCMAnchorFrame = anchorFrame
	anchorFrame.ClearAllPoints(child)

	child.SCMSetPoint = true
	child:SetPoint(anchorData[1], anchorFrame, anchorData[3], anchorData[4], anchorData[5])
	child.SCMSetPoint = nil
end

local function SetChildSetPointHook(child)
	if child.SCMPointHook or child.SCMCustom then
		return
	end

	child.SCMPointHook = true
	hooksecurefunc(child, "SetPoint", OnChildSetPoint)
	hooksecurefunc(child, "ClearAllPoints", OnChildSetPoint)
end

function SCM:GetAnchorPivot(point, growDir)
	return (PIVOT_MAP[growDir] and PIVOT_MAP[growDir][point]) or point
end

local function GetPointShift(state, point)
	if not state then
		return 0, 0
	end

	local pointOffset = POINT_OFFSETS[point] or POINT_OFFSETS.CENTER
	local effectiveWidth = state.effectiveWidth or 0
	local effectiveHeight = state.effectiveHeight or 0
	local appliedWidth = state.appliedWidth or effectiveWidth
	local appliedHeight = state.appliedHeight or effectiveHeight
	return (effectiveWidth - appliedWidth) * pointOffset[1], (effectiveHeight - appliedHeight) * pointOffset[2]
end

local function SetChildPoint(child, groupAnchor, startPoint, offsetX, offsetY)
	child.SCMAnchorFrame = groupAnchor

	local cooldownID = not child.SCMCustom and (child:GetCooldownID() or child.SCMCooldownID)
	local anchorData = cooldownID and anchorDataByCooldownID[cooldownID] or not cooldownID and child.SCMAnchorData
	if not anchorData then
		anchorData = {}
		if cooldownID then
			anchorDataByCooldownID[cooldownID] = anchorData
		else
			child.SCMAnchorData = anchorData
		end
	end

	local anchorChanged = anchorData[1] ~= startPoint or anchorData[2] ~= groupAnchor or anchorData[3] ~= startPoint or anchorData[4] ~= offsetX or anchorData[5] ~= offsetY
	if anchorChanged then
		anchorData[1] = startPoint
		anchorData[2] = groupAnchor
		anchorData[3] = startPoint
		anchorData[4] = offsetX
		anchorData[5] = offsetY
	end

	if anchorChanged or cooldownID then
		OnChildSetPoint(child)
	end
end

function SCM:PositionHiddenManagedChild(child)
	SetChildSetPointHook(child)
	SetChildPoint(child, UIParent, "BOTTOM", 0, -100)
end

local function RemoveProxy(state)
	state.currentProxyRequired = nil
	state.currentProxyActive = nil

	local proxy = state.currentProxyFrame
	if proxy and not (InCombatLockdown() and proxy:IsProtected()) then
		proxy:Hide()
	end
end

local function OnProxySizeChanged(proxy, width, height)
	local group = proxy.SCMProxyGroup
	if not group then
		return
	end

	local state = Cache.cachedAnchorStates[group]
	local selectedAnchorFrame = state and state.selectedAnchorFrame
	local isActiveProxy = state and state.currentProxyActive and state.currentProxyFrame == proxy or false
	SCM.Callbacks:Fire(ANCHOR_PROXY_SIZE_CHANGED_EVENT, group, proxy, width, height, selectedAnchorFrame, isActiveProxy)
end

local function GetProxy(group)
	local state = GetAnchorState(group)
	local proxy = state.currentProxyFrame

	if not proxy and not InCombatLockdown() then
		proxy = CreateFrame("Frame", "SCM_GroupAnchorProxy_" .. group, UIParent)
		proxy:Hide()
		proxy.SCMProxyGroup = group
		proxy:HookScript("OnSizeChanged", OnProxySizeChanged)
		state.currentProxyFrame = proxy
	end

	return proxy, state
end

local function GetAnchorPointOffsets(point, growDir, iconWidth, xOffset, yOffset, anchorOffsetY)
	local xOffsetMultiplier = 0
	if growDir == "LEFT" then
		xOffsetMultiplier = (point == "TOPLEFT" and 1) or ((point == "TOP" or point == "BOTTOM" or point == "CENTER") and 0.5) or 0
	elseif growDir == "RIGHT" then
		xOffsetMultiplier = (point == "TOPRIGHT" and -1) or ((point == "TOP" or point == "BOTTOM" or point == "CENTER") and -0.5) or 0
	end

	return xOffset + (iconWidth or 0) * xOffsetMultiplier, yOffset + anchorOffsetY
end

local function GetAnchorOffset(group, visited)
	local state = Cache.cachedAnchorStates[group]
	if not state then
		return 0, 0
	end

	local anchorOffsetY = (state.anchorOffsetY or 0) - (state.appliedAnchorOffsetY or state.anchorOffsetY or 0)

	if not InCombatLockdown() then
		return 0, 0
	end

	if visited[group] then
		return state.transformX or 0, state.transformY or 0
	end

	if state.currentProxyActive then
		local anchorFrame = SCM.anchorFrames[group]
		local proxy = state.currentProxyFrame
		local anchorX, anchorY
		local proxyX, proxyY
		if anchorFrame then
			anchorX, anchorY = anchorFrame:GetCenter()
		end
		if proxy then
			proxyX, proxyY = proxy:GetCenter()
		end
		if anchorX and anchorY and proxyX and proxyY then
			return proxyX - anchorX, proxyY - anchorY
		end
	end

	if not state.parentGroup then
		local pivotShiftX, pivotShiftY = GetPointShift(state, state.pivot)
		return -pivotShiftX, anchorOffsetY - pivotShiftY
	end

	visited[group] = true
	local parentX, parentY = GetAnchorOffset(state.parentGroup, visited)
	visited[group] = nil

	local parentShiftX, parentShiftY = GetPointShift(Cache.cachedAnchorStates[state.parentGroup], state.relativePoint)
	local pivotShiftX, pivotShiftY = GetPointShift(state, state.pivot)
	return parentX + parentShiftX - pivotShiftX, parentY + parentShiftY - pivotShiftY + anchorOffsetY
end

function SCM:UpdateAnchorOffset(group, skipChildren)
	local state = GetAnchorState(group)
	local visited = Cache.cachedAnchorOffsetVisited
	wipe(visited)
	local transformX, transformY = GetAnchorOffset(group, visited)
	local changed = state.transformX ~= transformX or state.transformY ~= transformY
	state.transformX = transformX
	state.transformY = transformY

	if changed and not skipChildren and state.startPoint then
		local adjustmentX, adjustmentY = self:GetAnchorAdjustment(group, state.startPoint)
		local children = Cache.cachedAnchorChildren[group]
		if children then
			for index = 1, #children do
				local child = children[index]
				if child and child.SCMGroup == group and child.SCMLayoutApplied then
					if child.SCMProxyAnchor then
						SetChildPoint(child, child.SCMAnchorFrame, child.SCMBaseStartPoint, child.SCMBaseOffsetX or 0, child.SCMBaseOffsetY or 0)
					else
						SetChildPoint(child, child.SCMAnchorFrame, child.SCMBaseStartPoint, (child.SCMBaseOffsetX or 0) + adjustmentX, (child.SCMBaseOffsetY or 0) + adjustmentY)
					end
				end
			end
		end
	end

	return changed, transformX, transformY
end

function SCM:GetAnchorAdjustment(group, point)
	if not InCombatLockdown() then
		return 0, 0
	end

	local state = Cache.cachedAnchorStates[group]
	if not state then
		return 0, 0
	end

	local pointShiftX, pointShiftY = GetPointShift(state, point)
	return (state.transformX or 0) + pointShiftX, (state.transformY or 0) + pointShiftY
end

local function OnChildSetSize(child)
	local anchorFrame = child.SCMAnchorFrame
	if anchorFrame and child.SCMHeight and child.SCMWidth then
		anchorFrame.SetSize(child, child.SCMWidth, child.SCMHeight)
	end
end

local function OnChildSetWidth(child)
	local anchorFrame = child.SCMAnchorFrame
	if anchorFrame and child.SCMWidth then
		anchorFrame.SetWidth(child, child.SCMWidth)
	end
end

local function OnChildSetHeight(child)
	local anchorFrame = child.SCMAnchorFrame
	if anchorFrame and child.SCMHeight then
		anchorFrame.SetHeight(child, child.SCMHeight)
	end
end

local function OnChildSetScale(child)
	local anchorFrame = child.SCMAnchorFrame
	if anchorFrame then
		anchorFrame.SetScale(child, Cache.cachedViewerScale or 1)
	end
end

function SCM:UpdateManagedAnchorChild(child, groupAnchor, startPoint, offsetX, offsetY, width, height, useProxyAnchor)
	child.SCMWidth = width
	child.SCMHeight = height
	child.SCMBaseStartPoint = startPoint
	child.SCMBaseOffsetX = offsetX
	child.SCMBaseOffsetY = offsetY
	child.SCMLayoutApplied = true
	child.SCMProxyAnchor = useProxyAnchor and true or nil
	child:SetScale(Cache.cachedViewerScale or 1)

	if child.SCMBuffBar then
		child:SetWidth(width)
		child:SetHeight(height)

		if child.Icon then
			child.Icon:SetSize(height, height)
		end

		if child.Bar and child.Bar.Pip then
			child.Bar.Pip:SetHeight(height * 1.4)
		end
	else
		child:SetSize(width, height)
	end

	if not child.SCMSizeHook and not child.SCMCustom then
		child.SCMSizeHook = true
		hooksecurefunc(child, "SetSize", OnChildSetSize)
		hooksecurefunc(child, "SetWidth", OnChildSetWidth)
		hooksecurefunc(child, "SetHeight", OnChildSetHeight)
		hooksecurefunc(child, "SetScale", OnChildSetScale)
	end

	SetChildSetPointHook(child)

	local adjustmentX, adjustmentY = 0, 0
	if not useProxyAnchor then
		adjustmentX, adjustmentY = self:GetAnchorAdjustment(child.SCMGroup, startPoint)
	end
	SetChildPoint(child, groupAnchor, startPoint, offsetX + adjustmentX, offsetY + adjustmentY)
end

local function OnDebugTextureShow(self)
	local anchorFrame = self:GetParent()
	if not anchorFrame then
		return
	end

	anchorFrame.SCMHighlightState = "default"
	anchorFrame.isGlowActive = false
	anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)
	LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
	LibCustomGlow.PixelGlow_Start(anchorFrame, nil, nil, nil, nil, nil, nil, nil, nil, "SCM")
end

local function StopAnchorHighlight(anchorFrame)
	anchorFrame.SCMHighlightState = nil
	anchorFrame.isGlowActive = false
	LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
end

local function OnDebugTextureHide(self)
	local anchorFrame = self:GetParent()
	if anchorFrame then
		StopAnchorHighlight(anchorFrame)
	end
end

function SCM:HideAnchorHighlight(anchorFrame)
	anchorFrame.debugTexture:Hide()
	anchorFrame.debugText:Hide()
	StopAnchorHighlight(anchorFrame)
end

local function SetGroupAnchorPoint(anchorFrame, group, point, target, relativePoint, xOffset, yOffset)
	anchorFrame:ClearAllPoints()
	local success = pcall(anchorFrame.SetPoint, anchorFrame, point, target, relativePoint, xOffset, yOffset)
	if not success then
		anchorFrame:SetPoint(point, UIParent, "CENTER", xOffset, yOffset)
		if anchorFrame.SCMInvalidAnchorTarget ~= target then
			SCM:Print("|cffff4040Invalid anchor for group " .. group .. ": " .. (target:GetName() or "unnamed frame") .. ". Using screen center.|r")
		end
	end
	anchorFrame.SCMInvalidAnchorTarget = not success and target or nil
end

local function OnGroupAnchorVisibilityChanged(anchorFrame, selectedAnchorFrame)
	local group = anchorFrame.SCMAnchorGroup
	local state = GetAnchorState(group)

	state.selectedAnchorFrame = selectedAnchorFrame
	state.layoutSignature = nil
	state.currentProxyRequired = InCombatLockdown() or nil

	SCM:ApplyAnchorGroupCDManagerConfig(group)
end

function SCM:GetManagedAnchorChildAnchor(group, groupAnchor, point, anchor, relativePoint, xOffset, yOffset, growDir, offsetWidth, frameWidth, frameHeight, anchorOffsetY)
	local state = Cache.cachedAnchorStates[group]
	if not state then
		return groupAnchor, false
	end

	if not (groupAnchor and groupAnchor:IsProtected()) then
		RemoveProxy(state)
		return groupAnchor, false
	end

	if not InCombatLockdown() then
		RemoveProxy(state)
		return groupAnchor, false
	end

	local proxy = state.currentProxyFrame
	if not proxy then
		return groupAnchor, false
	end

	local target = anchor
	if type(target) == "string" then
		target = Utils.GetActiveAnchorFrame(target)
	end
	target = target or UIParent

	proxy:SetFrameStrata((groupAnchor and groupAnchor:GetFrameStrata()) or "HIGH")
	proxy:SetScale((groupAnchor and groupAnchor:GetScale()) or Cache.cachedViewerScale or 1)

	state.currentProxyRequired = nil
	state.currentProxyActive = true

	proxy:SetSize(max(frameWidth, 1), max(frameHeight, 1))
	SetGroupAnchorPoint(proxy, group, self:GetAnchorPivot(point, growDir), target, relativePoint, GetAnchorPointOffsets(point, growDir, offsetWidth, xOffset, yOffset, anchorOffsetY))
	proxy:Show()

	return proxy, true
end

function SCM:GetAnchor(group, point, anchor, relativePoint, xOffset, yOffset, growDir, offsetWidth, frameWidth, frameHeight, anchorOffsetY)
	local anchorFrame = self.anchorFrames[group]
	if not anchorFrame then
		anchorFrame = CreateFrame("Frame", "SCM_GroupAnchor_" .. group, UIParent)
		anchorFrame.SCMAnchorGroup = group
		anchorFrame:SetFrameStrata("HIGH")
		anchorFrame:SetFrameLevel(1000)
		anchorFrame.debugTexture = anchorFrame:CreateTexture(nil, "BACKGROUND")
		anchorFrame:SetScale(Cache.cachedViewerScale or 1)

		anchorFrame.debugTexture:SetAllPoints()
		anchorFrame.debugTexture:SetColorTexture(8 / 255, 8 / 255, 8 / 255, 0.4)
		anchorFrame.debugTexture:SetTexelSnappingBias(0)
		anchorFrame.debugTexture:SetSnapToPixelGrid(false)
		local showAnchorHighlight = self.OptionsFrame and self.OptionsFrame:IsShown() and self.db.profile.options.showAnchorHighlight
		anchorFrame.debugTexture:SetShown(showAnchorHighlight)

		anchorFrame.debugText = anchorFrame:CreateFontString(nil, "OVERLAY", "Permok_Expressway_Large")
		anchorFrame.debugText:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
		if group > 100 and group < 200 then
			anchorFrame.debugText:SetText("G" .. group - 100)
		elseif group > 200 then
			anchorFrame.debugText:SetText("B" .. group - 200)
		else
			anchorFrame.debugText:SetText(group)
		end
		anchorFrame.debugText:SetFontHeight(35)
		anchorFrame.debugText:SetShown(showAnchorHighlight)
		anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)

		anchorFrame.debugTexture:HookScript("OnShow", OnDebugTextureShow)
		anchorFrame.debugTexture:HookScript("OnHide", OnDebugTextureHide)

		self.anchorFrames[group] = anchorFrame
	end

	if not (point and anchor) or (InCombatLockdown() and anchorFrame:IsProtected()) then
		return anchorFrame
	end

	local state = GetAnchorState(group)
	local target, selectedAnchorFrame = Utils.GetAnchorFrame(anchor)
	local usesVisibilitySelection = type(anchor) == "string" and anchor:find(",", 1, true)

	Utils.RegisterAnchorVisibility(anchorFrame, anchor, OnGroupAnchorVisibilityChanged)
	state.selectedAnchorFrame = usesVisibilitySelection and selectedAnchorFrame or nil

	if anchorFrame:IsProtected() or usesVisibilitySelection then
		GetProxy(group)
	end

	target = target or UIParent

	local pivot = self:GetAnchorPivot(point, growDir)
	local appliedXOffset, appliedYOffset = GetAnchorPointOffsets(point, growDir, offsetWidth, xOffset, yOffset, anchorOffsetY)

	anchorFrame:SetSize(frameWidth, frameHeight)
	anchorFrame:SetScale(Cache.cachedViewerScale or 1)
	SetGroupAnchorPoint(anchorFrame, group, pivot, target, relativePoint, appliedXOffset, appliedYOffset)
	anchorFrame:Show()
	RemoveProxy(state)

	local shouldStartDefaultHighlight = self.OptionsFrame
		and self.OptionsFrame:IsShown()
		and not anchorFrame.isGlowActive
		and anchorFrame.SCMHighlightState ~= "default"
		and self.db.profile.options.showAnchorHighlight

	if shouldStartDefaultHighlight then
		anchorFrame.SCMHighlightState = "default"
		anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)
		LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
		LibCustomGlow.PixelGlow_Start(anchorFrame, nil, nil, nil, nil, nil, nil, nil, nil, "SCM")
	end

	return anchorFrame
end

function SCM:ResetAnchors()
	if InCombatLockdown() then
		return
	end

	for _, anchorFrame in pairs(self.anchorFrames) do
		Utils.UnregisterAnchorVisibility(anchorFrame)
		anchorFrame:ClearAllPoints()
	end
end

function SCM:InitializeAllAnchorFrames()
	local config = self.currentConfig
	if not config then
		return
	end

	local anchorConfig = config.anchorConfig
	if anchorConfig then
		for group = 1, #anchorConfig do
			self:GetAnchor(group)
		end
	end
	local aurasAnchorConfig = config.aurasAnchorConfig
	if aurasAnchorConfig then
		for group in pairs(aurasAnchorConfig) do
			self:GetAnchor(group)
		end
	end

	local globalAnchorConfig = self.globalAnchorConfig
	if globalAnchorConfig then
		for index = 1, #globalAnchorConfig do
			self:GetAnchor(Utils.ToGlobalGroup(index))
		end
	end
	local globalAurasAnchorConfig = self.globalAurasAnchorConfig
	if globalAurasAnchorConfig then
		for index in pairs(globalAurasAnchorConfig) do
			self:GetAnchor(Utils.ToGlobalGroup(index))
		end
	end

	local buffBarsAnchorConfig = config.buffBarsAnchorConfig
	if buffBarsAnchorConfig then
		for index = 1, #buffBarsAnchorConfig do
			self:GetAnchor(Utils.ToBuffBarGroup(index))
		end
	end
end
