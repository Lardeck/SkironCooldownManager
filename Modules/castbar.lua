local SCM = select(2, ...)
local LSM = LibStub("LibSharedMedia-3.0")
local Utils = SCM.Utils

local castBarHooksSet

-- Chained channel ticks adapted from: https://github.com/tukui-org/ElvUI/blob/63ecc16049c01a1ea6cadd991bb9ab04aecf3854/ElvUI/Game/Shared/Modules/UnitFrames/Elements/CastBar.lua#L629

local CAST_START_EVENTS = {
	UNIT_SPELLCAST_START = true,
	UNIT_SPELLCAST_DELAYED = true,
	UNIT_SPELLCAST_INTERRUPTIBLE = true,
	UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true,
	UNIT_SPELLCAST_SENT = true,
}

local CAST_STOP_EVENTS = {
	UNIT_SPELLCAST_STOP = true,
	UNIT_SPELLCAST_CHANNEL_STOP = true,
	UNIT_SPELLCAST_INTERRUPTED = true,
	UNIT_SPELLCAST_FAILED = true,
	UNIT_SPELLCAST_EMPOWER_STOP = true,
}

local ICON_SPACING = 0
local ANCHOR_PROXY_SIZE_CHANGED_EVENT = "SkironCooldownManager.AnchorProxy.SizeChanged"

local function ApplyRelativeAnchor(frame, anchors, relativeFrame)
	frame:ClearAllPoints()
	frame:SetPoint(anchors[1], relativeFrame, anchors[2], anchors[3], anchors[4])
end

local function ClearPips()
	local castBar = SCM.CastBar

	for _, band in ipairs(castBar.StageBands) do
		band:Hide()
	end
end

local function CreatePips(empoweredStages)
	local castBar = SCM.CastBar
	if type(empoweredStages) ~= "table" then
		return
	end

	ClearPips()

	local totalWidth = castBar.Status:GetWidth()
	local totalHeight = castBar.Status:GetHeight()
	local total = 0
	local options = castBar.barOptions or SCM.castBarConfig
	local stageColors = options.empoweredStageColors
	local tickOptions = options.ticks
	local tickIndex = 1

	for i, stage in ipairs(empoweredStages) do
		local band = castBar.StageBands[i]
		if not band then
			band = castBar.Status:CreateTexture(nil, "BACKGROUND")
			castBar.StageBands[i] = band
		end

		local color = stageColors[min(i, #stageColors)]
		band:ClearAllPoints()
		band:SetColorTexture(color.r, color.g, color.b, color.a)
		band:SetSize(max(totalWidth * stage, 1), totalHeight)
		band:SetPoint("LEFT", castBar.Status, "LEFT", totalWidth * total, 0)
		band:Show()

		if i < #empoweredStages then
			total = total + stage
			if tickOptions.enable then
				local tick = castBar.TickLines[tickIndex]
				if not tick then
					tick = castBar.Status:CreateTexture(nil, "OVERLAY")
					castBar.TickLines[tickIndex] = tick
				end

				local color = tickOptions.color
				tick:ClearAllPoints()
				tick:SetColorTexture(color.r, color.g, color.b, color.a)
				tick:SetSize(tickOptions.width, totalHeight)
				tick:SetPoint("CENTER", castBar.Status, "LEFT", totalWidth * total, 0)
				tick:Show()
				tickIndex = tickIndex + 1
			end
		end
	end

	for i = tickIndex, #castBar.TickLines do
		castBar.TickLines[i]:Hide()
	end
end

local function ApplyTextStyle(fs, fontPath, fontSize, fontOutline, justify, width)
	fs:SetFont(fontPath, fontSize, fontOutline)
	fs:SetJustifyH(justify)
	fs:SetWordWrap(false)
	fs:SetWidth(width)
	fs:SetShadowColor(0, 0, 0, 0)
	fs:SetShadowOffset(0, 0)
end

local function UpdateActiveAnchorFrame(castBar, options)
	local activeAnchor, activeAnchorGroup
	local anchor = options.anchors and options.anchors[2]
	if type(anchor) == "string" then
		activeAnchor, _, activeAnchorGroup = Utils.GetActiveAnchorFrame(anchor)
	else
		activeAnchor = anchor
	end

	castBar.SCMActiveAnchorFrame = activeAnchor
	castBar.SCMActiveAnchorGroup = activeAnchorGroup
	return activeAnchor
end

local function GetMatchedCastBarWidth(options, anchorFrame)
	if not options.matchParentWidth then
		return
	end

	if not anchorFrame or not anchorFrame.GetWidth then
		return
	end

	local anchorWidth = anchorFrame:GetWidth()
	return (anchorWidth and anchorWidth > 0) and anchorWidth or nil, anchorFrame
end

local function UpdateIconTexture(spellTexture)
	local castBar = SCM.CastBar
	local iconOptions = castBar.barOptions and castBar.barOptions.icon or SCM.castBarConfig.icon

	castBar.CurrentSpellTexture = spellTexture

	if iconOptions.enable and spellTexture then
		castBar.IconFrame.Icon:SetTexture(spellTexture)
		castBar.IconFrame:Show()
	else
		castBar.IconFrame.Icon:SetTexture(nil)
		castBar.IconFrame:Hide()
	end
end

local function UpdateStatusBarLook(fillColor, bgColor)
	local castBar = SCM.CastBar
	local options = castBar.barOptions or SCM.castBarConfig
	local profileOptions = SCM.db.profile.options

	local borderSize = SCM:PixelPerfect() * profileOptions.borderSize
	local texturePath = LSM:Fetch("statusbar", options.texture) or "Interface\\TargetingFrame\\UI-StatusBar"
	local borderColor = options.borderColor
	local backgroundColor = bgColor or options.bgColor
	local foregroundColor = fillColor or castBar.CurrentFillColor or options.fgColor
	local anchorFrame = UpdateActiveAnchorFrame(castBar, options)
	local matchedWidth = GetMatchedCastBarWidth(options, anchorFrame)
	local width = matchedWidth or options.width or 270

	if options.matchParentWidth and anchorFrame and not anchorFrame.SCMProxyGroup and not anchorFrame.SCMCastBarWidthHook then
		anchorFrame.SCMCastBarWidthHook = true
		anchorFrame:HookScript("OnSizeChanged", function(changedAnchor)
			local currentCastBar = SCM.CastBar
			local currentOptions = currentCastBar and (currentCastBar.barOptions or SCM.castBarConfig)
			if not (currentCastBar and currentOptions.enable and currentOptions.matchParentWidth) then
				return
			end

			if currentCastBar.SCMActiveAnchorFrame == changedAnchor then
				SCM:RefreshCastBarWidth()
			end
		end)
	end

	castBar.CurrentFillColor = foregroundColor
	castBar:SetSize(width, options.height)
	castBar:ClearAllPoints()
	castBar:SetPoint(options.anchors[1], anchorFrame or UIParent, options.anchors[3], options.anchors[4], options.anchors[5])
	castBar:SetFrameStrata(options.frameStrata or "BACKGROUND")

	castBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize })
	castBar:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

	castBar.Background:ClearAllPoints()
	castBar.Background:SetPoint("TOPLEFT", castBar, "TOPLEFT", borderSize, -borderSize)
	castBar.Background:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -borderSize, borderSize)
	castBar.Background:SetColorTexture(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)

	local iconOptions = options.icon
	local outerWidth = max(castBar:GetWidth(), 1)
	local outerHeight = max(castBar:GetHeight(), 1)
	local innerWidth = max(outerWidth - borderSize * 2, 1)
	local spacing = iconOptions.enable and min(SCM:PixelPerfect(ICON_SPACING), max(innerWidth - 1, 0)) or 0
	local iconSize = 0
	local iconZoom = min(iconOptions.zoom, 0.49)

	if iconOptions.enable then
		local configuredIconSize = iconOptions.matchBarHeight and outerHeight or SCM:PixelPerfect(max(iconOptions.size, 1))
		iconSize = min(configuredIconSize, outerHeight, max(outerWidth - borderSize - spacing - 1, 0))
	end

	castBar.Status:ClearAllPoints()
	castBar.IconFrame:ClearAllPoints()
	castBar.IconFrame.Icon:ClearAllPoints()
	castBar.IconFrame.Icon:SetPoint("TOPLEFT", castBar.IconFrame, "TOPLEFT", borderSize, -borderSize)
	castBar.IconFrame.Icon:SetPoint("BOTTOMRIGHT", castBar.IconFrame, "BOTTOMRIGHT", -borderSize, borderSize)
	castBar.IconFrame.Icon:SetTexCoord(iconZoom, 1 - iconZoom, iconZoom, 1 - iconZoom)
	castBar.IconFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = borderSize })
	castBar.IconFrame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

	if iconOptions.enable and iconSize > 0 then
		castBar.IconFrame:SetSize(iconSize, iconSize)
		if iconOptions.position == "RIGHT" then
			castBar.IconFrame:SetPoint("RIGHT", castBar, "RIGHT", -borderSize + SCM:PixelPerfect(), 0)
			castBar.Status:SetPoint("TOPLEFT", castBar, "TOPLEFT", borderSize, -borderSize)
			castBar.Status:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -(iconSize + spacing), borderSize)
		else
			castBar.IconFrame:SetPoint("LEFT", castBar, "LEFT", borderSize - SCM:PixelPerfect(), 0)
			castBar.Status:SetPoint("TOPLEFT", castBar, "TOPLEFT", iconSize + spacing, -borderSize)
			castBar.Status:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -borderSize, borderSize)
		end
	else
		castBar.Status:SetPoint("TOPLEFT", castBar, "TOPLEFT", borderSize, -borderSize)
		castBar.Status:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -borderSize, borderSize)
	end

	UpdateIconTexture(castBar.CurrentSpellTexture)
	castBar.Status:SetStatusBarTexture(texturePath)
	castBar.Status:SetStatusBarColor(foregroundColor.r or 1, foregroundColor.g or 1, foregroundColor.b or 1, foregroundColor.a or 1)

	local fontPath = LSM:Fetch("font", options.font) or STANDARD_TEXT_FONT
	local fontSize = options.fontSize
	local fontOutline = options.fontOutline or ""
	local statusWidth = castBar.Status:GetWidth()
	if not statusWidth or statusWidth <= 1 then
		statusWidth = max(outerWidth - borderSize * 2 - iconSize - spacing, 1)
	end
	local durationWidth = min(statusWidth, fontSize * 3)

	ApplyTextStyle(castBar.SpellNameText, fontPath, fontSize, fontOutline, "LEFT", max(castBar.SpellNameText:GetStringWidth(), 1))
	ApplyTextStyle(castBar.CastDurationText, fontPath, fontSize, fontOutline, "RIGHT", durationWidth)

	local spellName = options.spellName
	local castDuration = options.castDuration

	ApplyRelativeAnchor(castBar.SpellNameText, spellName.anchors, castBar.Status)
	ApplyRelativeAnchor(castBar.CastDurationText, castDuration.anchors, castBar.Status)

	castBar.SpellNameText:SetShown(spellName.enable)
	castBar.CastDurationText:SetShown(castDuration.enable)

	local sparkOptions = options.spark
	if sparkOptions.enable then
		castBar.Spark:ClearAllPoints()
		castBar.Spark:SetPoint("LEFT", castBar.Status:GetStatusBarTexture(), "RIGHT", sparkOptions.xOffset, sparkOptions.yOffset)
		castBar.Spark:SetSize(sparkOptions.width, sparkOptions.height)
		castBar.Spark:SetBlendMode(sparkOptions.blendMode)

		if sparkOptions.texture:find("\\") then
			castBar.Spark:SetTexture(sparkOptions.texture)
		else
			local texturePath = LSM:Fetch("statusbar", sparkOptions.texture)
			if texturePath then
				castBar.Spark:SetTexture(texturePath)
			end
		end

		local color = sparkOptions.color
		castBar.Spark:SetVertexColor(color.r, color.g, color.b, color.a)

		castBar.Spark:Show()
	elseif castBar.Spark:IsShown() then
		castBar.Spark:Hide()
	end

	if castBar:IsShown() and castBar.CurrentChannelTickCount then
		local tickOptions = options.ticks
		local color = tickOptions.color
		local tickWidth = tickOptions.width
		local statusWidth = castBar.Status:GetWidth()
		local statusHeight = castBar.Status:GetHeight()

		for i = 1, castBar.CurrentChannelTickCount - 1 do
			local tick = castBar.TickLines[i]
			if not tick then
				tick = castBar.Status:CreateTexture(nil, "OVERLAY")
				castBar.TickLines[i] = tick
			end

			tick:ClearAllPoints()
			tick:SetColorTexture(color.r, color.g, color.b, color.a)
			tick:SetSize(tickWidth, statusHeight)
			tick:SetPoint("CENTER", castBar.Status, "LEFT", statusWidth * i / castBar.CurrentChannelTickCount, 0)
			tick:Show()
		end

		for i = castBar.CurrentChannelTickCount, #castBar.TickLines do
			castBar.TickLines[i]:Hide()
		end
	end
end

local function HideCastBar()
	local castBar = SCM.CastBar

	ClearPips()
	for _, tick in ipairs(castBar.TickLines) do
		tick:Hide()
	end
	castBar:SetScript("OnUpdate", nil)
	castBar.Status:SetValue(0)
	castBar.SpellNameText:SetText("")
	castBar.CastDurationText:SetText("")
	castBar.CurrentFillColor = nil
	castBar.CurrentEmpoweredStages = nil
	castBar.CurrentChannelTickCount = nil
	castBar.CurrentChannelSpellID = nil
	castBar.CurrentChannelTime = nil
	castBar.CurrentChannelExtraTicks = nil
	UpdateIconTexture(nil)
	castBar:Hide()
end

local function FormatDurationText(t)
	return t < 5 and string.format("%.1f", t) or string.format("%.0f", t)
end

local function HandleCast(durationObject, castType, empoweredStages, isChannelStart)
	local castBar = SCM.CastBar
	local options = castBar.barOptions
	local spellName, _, spellTexture, notInterruptible, spellID
	local isChannel = castType == "channel"
	local fillColor

	if castType == "cast" then
		spellName, _, spellTexture, _, _, _, _, notInterruptible, spellID = UnitCastingInfo("player")
	else
		spellName, _, spellTexture, _, _, _, notInterruptible, spellID = UnitChannelInfo("player")
	end

	if notInterruptible then
		fillColor = options.interruptColor
	else
		if options.useClassColor then
			local _, class = UnitClass("player")
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
			fillColor = { r = color.r, g = color.g, b = color.b, a = options.fgColor.a }
		else
			fillColor = options.fgColor
		end
	end

	local totalDuration = durationObject:GetTotalDuration()
	if not totalDuration or totalDuration <= 0 then
		return
	end

	castBar.CurrentFillColor = fillColor
	castBar.Status:SetStatusBarColor(fillColor.r or 1, fillColor.g or 1, fillColor.b or 1, fillColor.a or 1)

	castBar.CurrentEmpoweredStages = empoweredStages
	UpdateIconTexture(spellTexture)

	if empoweredStages then
		CreatePips(empoweredStages)
	else
		ClearPips()
	end

	if isChannel and spellID and not empoweredStages then
		local channelTicks = SCM.Constants.CastBarChannelTicks
		local tickCount = channelTicks and channelTicks.ticks[spellID]

		if tickCount then
			local talent = channelTicks.talents and channelTicks.talents[spellID]
			local hasTalent = talent and IsPlayerSpell(talent.talentSpellID)

			if hasTalent then
				tickCount = talent.ticks
			end

			local aura = channelTicks.auras and channelTicks.auras[spellID]
			if aura and C_UnitAuras.GetPlayerAuraBySpellID(aura.auraSpellID) then
				tickCount = aura.ticks
			end

			local chain = channelTicks.chain and channelTicks.chain[spellID]
			if chain then
				if isChannelStart then
					local now = GetTime()
					local chained = castBar.CurrentChannelSpellID == spellID and castBar.CurrentChannelTime and now - castBar.CurrentChannelTime < chain.seconds
					castBar.CurrentChannelExtraTicks = chained and chain.extraTicks or 0
					castBar.CurrentChannelTime = now
				end

				tickCount = tickCount + (castBar.CurrentChannelExtraTicks or 0)
			else
				castBar.CurrentChannelExtraTicks = nil
				castBar.CurrentChannelTime = nil
			end
		end

		castBar.CurrentChannelSpellID = spellID

		local tickOptions = options.ticks
		if tickOptions.enable and tickCount and tickCount > 1 then
			local color = tickOptions.color
			local tickWidth = tickOptions.width
			local statusWidth = castBar.Status:GetWidth()
			local statusHeight = castBar.Status:GetHeight()

			for i = 1, tickCount - 1 do
				local tick = castBar.TickLines[i]
				if not tick then
					tick = castBar.Status:CreateTexture(nil, "OVERLAY")
					castBar.TickLines[i] = tick
				end

				tick:ClearAllPoints()
				tick:SetColorTexture(color.r, color.g, color.b, color.a)
				tick:SetSize(tickWidth, statusHeight)
				tick:SetPoint("CENTER", castBar.Status, "LEFT", statusWidth * i / tickCount, 0)
				tick:Show()
			end

			for i = tickCount, #castBar.TickLines do
				castBar.TickLines[i]:Hide()
			end
			castBar.CurrentChannelTickCount = tickCount
		else
			for _, tick in ipairs(castBar.TickLines) do
				tick:Hide()
			end
			castBar.CurrentChannelTickCount = nil
		end
	else
		if not empoweredStages then
			for _, tick in ipairs(castBar.TickLines) do
				tick:Hide()
			end
		end
		castBar.CurrentChannelTickCount = nil
		castBar.CurrentChannelSpellID = nil
		castBar.CurrentChannelTime = nil
		castBar.CurrentChannelExtraTicks = nil
	end

	local remaining = durationObject:GetRemainingDuration()
	castBar.Status:SetMinMaxValues(0, totalDuration)
	castBar.Status:SetValue(isChannel and remaining or totalDuration - remaining)

	castBar.SpellNameText:SetText(spellName or "")
	castBar.SpellNameText:SetWidth(max(castBar.SpellNameText:GetStringWidth(), 1))
	castBar.CastDurationText:SetText(FormatDurationText(remaining))

	castBar:SetScript("OnUpdate", function()
		local remaining = durationObject:GetRemainingDuration()
		castBar.Status:SetValue(isChannel and remaining or totalDuration - remaining)

		if castBar.CastDurationText:IsShown() then
			castBar.CastDurationText:SetText(FormatDurationText(remaining))
		end

		if remaining <= 0 then
			HideCastBar()
		end
	end)

	castBar:Show()
end

function SCM:RefreshCastBarWidth(delay)
	local castBar = self.CastBar
	local options = castBar and castBar.barOptions
	if not castBar or not options or not options.matchParentWidth then
		return
	end

	C_Timer.After(delay or 0.05, function()
		local currentCastBar = SCM.CastBar
		local currentOptions = currentCastBar and (currentCastBar.barOptions or SCM.castBarConfig)
		if not currentCastBar or not currentOptions or not currentOptions.matchParentWidth then
			return
		end

		local anchorFrame = UpdateActiveAnchorFrame(currentCastBar, currentOptions)
		local anchorWidth = GetMatchedCastBarWidth(currentOptions, anchorFrame)
		if anchorWidth and anchorWidth > 0 then
			UpdateStatusBarLook(currentCastBar.CurrentFillColor)
			if currentCastBar:IsShown() and currentCastBar.CurrentEmpoweredStages and currentCastBar.Status:GetStatusBarTexture() then
				CreatePips(currentCastBar.CurrentEmpoweredStages)
			end
		end
	end)
end

function SCM:RefreshCastBarLayout()
	local castBar = self.CastBar
	if not castBar then
		return
	end

	castBar.barOptions = self.castBarConfig
	UpdateStatusBarLook()

	if castBar:IsShown() and castBar.CurrentEmpoweredStages and castBar.Status:GetStatusBarTexture() then
		CreatePips(castBar.CurrentEmpoweredStages)
	end
end

function SCM:CreateCastBar()
	if self.CastBar then
		self:UpdateCastBar()
		return self.CastBar
	end

	if not castBarHooksSet then
		castBarHooksSet = true

		if EditModeManagerFrame then
			local function OnEditModeToggle()
				if not InCombatLockdown() then
					SCM:RefreshCastBarWidth()
				end
			end

			hooksecurefunc(EditModeManagerFrame, "EnterEditMode", OnEditModeToggle)
			hooksecurefunc(EditModeManagerFrame, "ExitEditMode", OnEditModeToggle)
		end
	end

	local castBar = CreateFrame("Frame", "SCM_CastBar", UIParent, "BackdropTemplate")
	castBar:SetFrameStrata("BACKGROUND")
	castBar.StageBands = {}
	castBar.TickLines = {}

	castBar.Background = castBar:CreateTexture(nil, "BACKGROUND")

	castBar.Status = CreateFrame("StatusBar", nil, castBar)
	castBar.Status:SetFrameLevel(castBar:GetFrameLevel() + 1)
	castBar.Status:SetMinMaxValues(0, 1)
	castBar.Status:SetValue(0)

	castBar.IconFrame = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
	castBar.IconFrame:SetFrameLevel(castBar:GetFrameLevel() + 2)
	castBar.IconFrame.Icon = castBar.IconFrame:CreateTexture(nil, "ARTWORK")

	castBar.SpellNameText = castBar.Status:CreateFontString(nil, "OVERLAY")
	castBar.CastDurationText = castBar.Status:CreateFontString(nil, "OVERLAY")

	castBar.Spark = castBar:CreateTexture(nil, "OVERLAY", nil, 2)

	self.CastBar = castBar
	EventRegistry:RegisterCallback(ANCHOR_PROXY_SIZE_CHANGED_EVENT, function(_, proxyGroup, proxy, _width, _height, _selectedAnchorRef, isActiveProxy)
		local currentOptions = castBar.barOptions or SCM.castBarConfig
		if not (currentOptions.enable and currentOptions.matchParentWidth and isActiveProxy) then
			return
		end

		if castBar.SCMActiveAnchorFrame == proxy or castBar.SCMActiveAnchorGroup == proxyGroup then
			castBar.SCMActiveAnchorFrame = proxy
			SCM:RefreshCastBarWidth()
		end
	end, castBar)
	self:UpdateCastBar()
	return castBar
end

function SCM:UpdateCastBar()
	local castBar = self.CastBar
	local options = SCM.castBarConfig
	if not castBar then
		return
	end

	castBar.barOptions = options
	UpdateStatusBarLook(options.fgColor)

	if options.enable then
		castBar:UnregisterAllEvents()
		HideCastBar()

		local events = {
			"UNIT_SPELLCAST_START",
			"UNIT_SPELLCAST_STOP",
			"UNIT_SPELLCAST_INTERRUPTED",
			"UNIT_SPELLCAST_INTERRUPTIBLE",
			"UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
			"UNIT_SPELLCAST_SENT",
			"UNIT_SPELLCAST_DELAYED",
			"UNIT_SPELLCAST_CHANNEL_START",
			"UNIT_SPELLCAST_CHANNEL_STOP",
			"UNIT_SPELLCAST_CHANNEL_UPDATE",
			"UNIT_SPELLCAST_EMPOWER_START",
			"UNIT_SPELLCAST_EMPOWER_STOP",
			"UNIT_SPELLCAST_EMPOWER_UPDATE",
		}
		for _, event in ipairs(events) do
			castBar:RegisterUnitEvent(event, "player")
		end

		castBar:SetScript("OnEvent", function(_, event)
			if CAST_START_EVENTS[event] then
				local durationObject = UnitCastingDuration("player")
				if not durationObject then
					return
				end

				HandleCast(durationObject, "cast")
				return
			end

			if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
				local durationObject = UnitChannelDuration("player")
				if not durationObject then
					return
				end

				HandleCast(durationObject, "channel", nil, event == "UNIT_SPELLCAST_CHANNEL_START")
				return
			end

			if event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
				local durationObject = UnitEmpoweredChannelDuration("player")
				if not durationObject then
					return
				end

				local stages = UnitEmpoweredStagePercentages("player")
				HandleCast(durationObject, "empower", stages)
				return
			end

			if CAST_STOP_EVENTS[event] then
				HideCastBar()
			end
		end)

		self:RefreshCastBarWidth(0.1)
		PlayerCastingBarFrame:UnregisterAllEvents()

		EventRegistry:RegisterCallback("SkironCooldownManager.ResourceBar.LayoutUpdated", function()
			UpdateStatusBarLook()
		end, castBar)
	else
		castBar:SetScript("OnEvent", nil)
		castBar:UnregisterAllEvents()
		HideCastBar()
	end
end
