local SCM = select(2, ...)

local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local Cache = SCM.Cache
local Utils = SCM.Utils

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
	local cooldownID = not child.SCMCustom and child:GetCooldownID()
	local anchorData = cooldownID and anchorDataByCooldownID[cooldownID] or not cooldownID and child.SCMAnchorData
	local anchorFrame = anchorData and anchorData[2]
	if not anchorFrame or not anchorData then
		return
	end

	child.SCMAnchorFrame = anchorFrame
	anchorFrame.ClearAllPoints(child)
	anchorFrame.SetPoint(child, anchorData[1], anchorFrame, anchorData[3], anchorData[4], anchorData[5])
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

	local cooldownID = not child.SCMCustom and child:GetCooldownID()
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
					SetChildPoint(child, child.SCMAnchorFrame, child.SCMBaseStartPoint, (child.SCMBaseOffsetX or 0) + adjustmentX, (child.SCMBaseOffsetY or 0) + adjustmentY)
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
	if anchorFrame then
		anchorFrame.SetSize(child, child.SCMWidth, child.SCMHeight)
	end
end

local function OnChildSetWidth(child)
	local anchorFrame = child.SCMAnchorFrame
	if anchorFrame then
		anchorFrame.SetWidth(child, child.SCMWidth)
	end
end

local function OnChildSetHeight(child)
	local anchorFrame = child.SCMAnchorFrame
	if anchorFrame then
		anchorFrame.SetHeight(child, child.SCMHeight)
	end
end

function SCM:UpdateManagedAnchorChild(child, groupAnchor, startPoint, offsetX, offsetY, width, height)
	child.SCMWidth = width
	child.SCMHeight = height
	child.SCMBaseStartPoint = startPoint
	child.SCMBaseOffsetX = offsetX
	child.SCMBaseOffsetY = offsetY
	child.SCMLayoutApplied = true
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
	end

	if not child.SCMPointHook and not child.SCMCustom then
		child.SCMPointHook = true
		hooksecurefunc(child, "SetPoint", OnChildSetPoint)
		hooksecurefunc(child, "ClearAllPoints", OnChildSetPoint)
	end

	local adjustmentX, adjustmentY = self:GetAnchorAdjustment(child.SCMGroup, startPoint)
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

local function OnDebugTextureHide(self)
	local anchorFrame = self:GetParent()
	if anchorFrame then
		anchorFrame.SCMHighlightState = nil
		anchorFrame.isGlowActive = false
		LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
	end
end

function SCM:GetAnchor(group, point, anchor, relativePoint, xOffset, yOffset, growDir, iconSize, resetSize, anchorOffsetY)
	local anchorFrame = self.anchorFrames[group]
	if not anchorFrame then
		anchorFrame = CreateFrame("Frame", "SCM_GroupAnchor_" .. group, UIParent)
		anchorFrame:SetFrameStrata("HIGH")
		anchorFrame.debugTexture = anchorFrame:CreateTexture(nil, "BACKGROUND")
		anchorFrame:SetScale(Cache.cachedViewerScale or 1)

		anchorFrame.debugTexture:SetAllPoints()
		anchorFrame.debugTexture:SetColorTexture(8 / 255, 8 / 255, 8 / 255, 0.4)
		anchorFrame.debugTexture:SetShown(self.OptionsFrame ~= nil)

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
		anchorFrame.debugText:SetShown(self.OptionsFrame ~= nil)
		anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)

		anchorFrame.debugTexture:HookScript("OnShow", OnDebugTextureShow)
		anchorFrame.debugTexture:HookScript("OnHide", OnDebugTextureHide)

		self.anchorFrames[group] = anchorFrame
	end

	if not (point and anchor) or InCombatLockdown() then
		return anchorFrame
	end

	anchorFrame:Show()

	local target = anchor
	if type(target) == "string" then
		local selectedAnchorRef
		target, selectedAnchorRef = Utils.GetAnchorFrame(target)

		if type(selectedAnchorRef) == "string" and selectedAnchorRef:sub(1, 7) == "ANCHOR:" and target then
			anchorFrame:SetScale(target:GetScale())
		end
	end

	target = target or UIParent

	local pivot = self:GetAnchorPivot(point, growDir)

	local xOffsetMultiplier = 0
	if growDir == "LEFT" then
		xOffsetMultiplier = (point == "TOPLEFT" and 1) or ((point == "TOP" or point == "BOTTOM" or point == "CENTER") and 0.5) or 0
	elseif growDir == "RIGHT" then
		xOffsetMultiplier = (point == "TOPRIGHT" and -1) or ((point == "TOP" or point == "BOTTOM" or point == "CENTER") and -0.5) or 0
	end

	if resetSize then
		anchorFrame:SetSize(iconSize, iconSize)
	else
		anchorFrame:SetSize(max(anchorFrame:GetWidth(), iconSize), max(anchorFrame:GetHeight(), iconSize))
	end
	anchorFrame:SetScale(Cache.cachedViewerScale or 1)
	anchorFrame:ClearAllPoints()
	anchorFrame:SetPoint(pivot, target, relativePoint, xOffset + ((iconSize or 0) * xOffsetMultiplier), yOffset + (anchorOffsetY or 0))
	anchorFrame:Show()

	local shouldStartDefaultHighlight = self.OptionsFrame ~= nil
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
