local SCM = select(2, ...)
local LSM = LibStub("LibSharedMedia-3.0")

local originalCooldownFont
local function ApplyChargeAndApplicationStyle(child, options, fontPath)
	local rowConfig = child.SCMRowConfig or {}
	if child.ChargeCount and child.ChargeCount.Current then
		local size = rowConfig.chargeFontSize or options.chargeFontSize
		local outline = rowConfig.chargeFontOutline or options.chargeFontOutline or "OUTLINE"

		if fontPath then
			child.ChargeCount.Current:SetFont(fontPath, size, outline)
			child.ChargeCount.Current:SetWordWrap(false)
			child.ChargeCount.Current:SetNonSpaceWrap(false)
			child.ChargeCount.Current:SetMaxLines(1)

			local width = child.ChargeCount.Current:GetStringWidth()
			if not issecretvalue(width) then
				child.ChargeCount:SetWidth(width)
			end
		end

		child.ChargeCount.Current:ClearAllPoints()
		child.ChargeCount.Current:SetPoint(
			rowConfig.chargePoint or options.chargePoint,
			child.Icon,
			rowConfig.chargeRelativePoint or options.chargeRelativePoint,
			rowConfig.chargeXOffset or options.chargeXOffset,
			rowConfig.chargeYOffset or options.chargeYOffset
		)

		local chargeColour = rowConfig.chargeColour or options.chargeColour
		child.ChargeCount.Current:SetTextColor(chargeColour.r, chargeColour.g, chargeColour.b, chargeColour.a or 1)

		child.ChargeCount.Current.SCMRowConfig = rowConfig

		if child.SCMCooldownID and not child.SCMCustom then
			local cooldownData = SCM.defaultCooldownViewerConfig.cooldownIDs[child.SCMCooldownID]
			if rowConfig and cooldownData and cooldownData.charges and not child.SCMChargeCountHook then
				child.SCMChargeCountHook = true
				hooksecurefunc(child.ChargeCount.Current, "SetText", function(self, text)
					if self.SCMSetText then
						return
					end

					if self.SCMRowConfig and self.SCMRowConfig.chargeTruncateWhenZero then
						self.SCMSetText = true
						self:SetText(C_StringUtil.TruncateWhenZero(text))
						self.SCMSetText = nil
					end
				end)
			end
		end
	end

	if child.Applications and child.Applications.Applications then
		local size = rowConfig.applicationsFontSize or options.chargeFontSize
		local outline = rowConfig.applicationsFontOutline or options.chargeFontOutline or "OUTLINE"
		if fontPath then
			child.Applications.Applications:SetFont(fontPath, size, outline)
			child.Applications.Applications:SetWordWrap(false)
			child.Applications.Applications:SetNonSpaceWrap(false)
			child.Applications.Applications:SetMaxLines(1)

			local width = child.Applications.Applications:GetStringWidth()
			if not issecretvalue(width) then
				child.Applications:SetWidth(width)
			end
		end

		child.Applications.Applications:ClearAllPoints()
		child.Applications.Applications:SetPoint(
			rowConfig.applicationsPoint or options.chargePoint,
			child.Icon,
			rowConfig.applicationsRelativePoint or options.chargeRelativePoint,
			rowConfig.applicationsXOffset or options.chargeXOffset,
			rowConfig.applicationsYOffset or options.chargeYOffset
		)

		local chargeColour = rowConfig.chargeColour or options.chargeColour
		child.Applications.Applications:SetTextColor(chargeColour.r, chargeColour.g, chargeColour.b, chargeColour.a or 1)
	end
end

local function ApplyCooldownFont(cooldownFrame, options)
	options = options or SCM.db.profile.options
	local cooldownFontString = cooldownFrame.SCMCooldownFontString
	if not cooldownFontString then
		local region = cooldownFrame:GetRegions()
		if region and region.SetFont then
			cooldownFontString = region
			cooldownFrame.SCMCooldownFontString = region
		end
	end

	if options.changeCooldownFont then
		local fontPath = LSM:Fetch("font", options.cooldownFont)
		if cooldownFontString and cooldownFontString.SetFont then
			if not originalCooldownFont then
				originalCooldownFont = { cooldownFontString:GetFont() }
			end

			local parent = cooldownFrame.SCMParent or cooldownFrame:GetParent()
			if parent and parent.SCMWidth and parent.SCMHeight then
				local iconSize = min(parent.SCMWidth, parent.SCMHeight)
				local childConfig = parent.SCMConfig
				local config = parent.SCMRowConfig

				if childConfig and childConfig.cooldownOverrideGlobal then
					config = childConfig
				end

				local percentageFontSize = config and config.cooldownFontSize or options.cooldownFontSize
				local fontSize
				if percentageFontSize > 1 then
					fontSize = percentageFontSize
				else
					fontSize = max(1, floor(iconSize * percentageFontSize + 0.5))
				end

				local fontOutline = options.cooldownFontOutline or "OUTLINE"
				if config and config.cooldownFontOutline then
					fontOutline = config.cooldownFontOutline
				end

				cooldownFontString:SetFont(fontPath, fontSize, fontOutline)
				cooldownFontString:SetShadowColor(0, 0, 0, 0)
				cooldownFontString:SetShadowOffset(0, 0)

				cooldownFontString:ClearAllPoints()

				local point = "CENTER"
				local relativePoint = "CENTER"
				local xOffset = options.cooldownXOffset
				local yOffset = options.cooldownYOffset

				if config then
					point = config.cooldownTextPoint or point
					relativePoint = config.cooldownTextRelativePoint or relativePoint
					xOffset = config.cooldownTextXOffset or xOffset
					yOffset = config.cooldownTextYOffset or yOffset
				end

				cooldownFontString:SetPoint(point, parent, relativePoint, xOffset, yOffset)
			end
		end
	elseif originalCooldownFont then
		if cooldownFontString and cooldownFontString.SetFont then
			cooldownFontString:SetFont(unpack(originalCooldownFont))
		end
	end

	local parent = cooldownFrame.SCMParent or cooldownFrame:GetParent()
	if parent and parent.SCMConfig then
		cooldownFrame:SetHideCountdownNumbers(parent.SCMConfig.hideCountdownNumbers)
	end
end

local function ApplyCooldownSwipe(cooldownFrame, options)
	local parent = cooldownFrame.SCMParent or cooldownFrame:GetParent()
	if not parent then
		return
	end

	local forceActiveSwipe = parent.SCMConfig and parent.SCMConfig.forceActiveSwipe

	if parent.auraInstanceID or parent.SCMFakeAuraInstanceID or parent.SCMBuffOptions then
		if options.disableRegularIconActiveSwipe and not forceActiveSwipe then
			if options.recolorNormalSwipe then
				cooldownFrame:SetSwipeColor(unpack(options.normalSwipeColor))
			else
				cooldownFrame:SetSwipeColor(0, 0, 0, 0.7)
			end

			if parent.SCMBuffOptions then
				cooldownFrame:SetReverse(options.reverseActiveSwipe)
			end
		else
			if options.recolorActiveSwipe then
				cooldownFrame:SetSwipeColor(unpack(options.activeSwipeColor))
			end

			cooldownFrame:SetReverse(options.reverseActiveSwipe)
		end
	elseif options.recolorNormalSwipe then
		cooldownFrame:SetSwipeColor(unpack(options.normalSwipeColor))
		cooldownFrame:SetReverse(false)
	else
		cooldownFrame:SetSwipeColor(0, 0, 0, 0.7)
	end
end

local function OnSetCooldown(self)
	local options = SCM.db.profile.options

	SCM.Cooldowns.ApplyNumericRuleFormatter(self)

	ApplyCooldownSwipe(self, options)
	ApplyCooldownFont(self, options)
end

local function ApplyCooldownStyle(child, options, childConfig)
	local cooldownFrame = child.GetCooldownFrame and child:GetCooldownFrame() or child.Cooldown
	if cooldownFrame then
		if child.SCMCooldownSkinHook then
			return
		end

		child.SCMCooldownSkinHook = true
		if child.CooldownFlash then
			child.CooldownFlash:SetAlpha(0)
		end

		cooldownFrame:SetSwipeTexture("Interface\\Buttons\\WHITE8x8")
		cooldownFrame:ClearAllPoints()

		if childConfig then
			if childConfig.cooldownMoveTL then
				cooldownFrame:SetPoint("TOPLEFT", child, "TOPLEFT", childConfig.cooldownXOffsetTL, childConfig.cooldownYOffsetTL)
			else
				cooldownFrame:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
			end

			if childConfig.cooldownMoveBR then
				cooldownFrame:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", childConfig.cooldownXOffsetBR, childConfig.cooldownYOffsetBR)
			else
				cooldownFrame:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", -SCM:PixelPerfectSize(1), SCM:PixelPerfectSize(1))
			end
		else
			cooldownFrame:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
			cooldownFrame:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", -SCM:PixelPerfectSize(1), SCM:PixelPerfectSize(1))
		end

		cooldownFrame.SCMParent = child

		hooksecurefunc(cooldownFrame, "SetCooldown", OnSetCooldown)
		OnSetCooldown(cooldownFrame)
	end
end

local function ApplyZoomSettings(child, options)
	local iconZoom = options.iconZoom

	if options.keepIconSquareRatio and child.SCMWidth and child.SCMHeight then
		local baseCrop = 1 - (iconZoom * 2)
		local xCrop = baseCrop
		local yCrop = baseCrop
		local ratio = child.SCMWidth / child.SCMHeight

		if ratio > 1 then
			yCrop = xCrop / ratio
		elseif ratio < 1 then
			xCrop = yCrop * ratio
		end

		local left = (1 - xCrop) / 2
		local right = 1 - left
		local top = (1 - yCrop) / 2
		local bottom = 1 - top

		child.Icon:SetTexCoord(left, right, top, bottom)
	else
		child.Icon:SetTexCoord(iconZoom, 1 - iconZoom, iconZoom, 1 - iconZoom)
	end
end

function SCM:SkinChild(child, childConfig)
	local options = self.db.profile.options

	if C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI[1].private.skins.blizzard.cooldownManager then
		return
	end

	if not options.enableSkinning or child.SCMIconType == "empty" then
		return
	end

	local frameStrata = child.SCMAnchorFrameStrata or options.iconFrameStrata
	if frameStrata and frameStrata ~= "" then
		child:SetFrameStrata(frameStrata)
	end

	if not child.SCMSkinned or (child.SCMSkinned and self.OptionsFrame and self.OptionsFrame:IsShown()) then
		child.SCMSkinned = true

		local borderSize = options.borderSize
		local borderColor = options.borderColor
		child.customBorder = child.customBorder or CreateFrame("Frame", nil, child, "BackdropTemplate")
		child.customBorder:SetFrameLevel(child:GetFrameLevel() + 1)
		child.customBorder:ClearAllPoints()
		child.customBorder:SetAllPoints(child)
		child.customBorder:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = borderSize,
		})
		child.customBorder:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

		if borderSize == 0 then
			child.customBorder:Hide()
		else
			child.customBorder:Show()
		end

		for _, region in ipairs({ child.customBorder:GetRegions() }) do
			region:SetTexelSnappingBias(0)
			region:SetSnapToPixelGrid(false)
		end

		borderSize = options.pandemicBorderSize
		borderColor = options.pandemicBorderColor

		child.pandemicBorder = child.pandemicBorder or CreateFrame("Frame", nil, child, "BackdropTemplate")
		child.pandemicBorder:SetFrameLevel(child:GetFrameLevel() + 2)
		child.pandemicBorder:ClearAllPoints()
		child.pandemicBorder:SetAllPoints(child)
		child.pandemicBorder:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = borderSize,
		})
		child.pandemicBorder:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
		child.pandemicBorder:Hide()

		for _, region in ipairs({ child.pandemicBorder:GetRegions() }) do
			region:SetTexelSnappingBias(0)
			region:SetSnapToPixelGrid(false)
		end

		local textureRegion
		for _, region in ipairs({ child:GetRegions() }) do
			if region:IsObjectType("Texture") then
				region:SetTexelSnappingBias(0)
				region:SetSnapToPixelGrid(false)
			end

			if region.GetMaskTexture and region:GetMaskTexture(1) then
				region:RemoveMaskTexture(region:GetMaskTexture(1))
			elseif region:IsObjectType("Texture") and region.GetAtlas and region:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then
				textureRegion = region
				region:Hide()
			end
		end

		if childConfig and childConfig.customIcon and textureRegion then
			child.Icon:SetTexture(childConfig.customIcon)
			child.Icon:SetTexelSnappingBias(0)
			child.Icon:SetSnapToPixelGrid(false)
		end

		child.Icon:SetTexelSnappingBias(0)
		child.Icon:SetSnapToPixelGrid(false)

		if child.DebuffBorder then
			child.DebuffBorder:SetAlpha(0)
		end

		ApplyZoomSettings(child, options)
		ApplyChargeAndApplicationStyle(child, options, LSM:Fetch("font", options.chargeFont))
		ApplyCooldownStyle(child, options, childConfig)
	end

	for _, customSkin in ipairs(SCM.Skins) do
		pcall(customSkin, child)
	end
end

function SCM:SkinBuffBar(child, config)
	local options = SCM.db.profile.options
	config = config or child.SCMConfig

	local frameStrata = child.SCMAnchorFrameStrata or options.iconFrameStrata
	if frameStrata and frameStrata ~= "" then
		child:SetFrameStrata(frameStrata)
	end

	local buffBarOptions = options.buffBarOptions
	local borderSize = buffBarOptions.borderSize
	local borderColor = buffBarOptions.borderColor
	local backgroundColor = buffBarOptions.backgroundColor
	local foregroundColor = buffBarOptions.foregroundColor

	if config and config.customColor then
		foregroundColor = config.customColor
	end

	local iconFrame, bar

	if child.GetIconFrame then
		iconFrame = child:GetIconFrame()
	end

	if child.Bar then
		bar = child.Bar
	end

	if child.DebuffBorder then
		child.DebuffBorder:SetAlpha(0)
	end

	if bar and iconFrame then
		local statusBarTexture = bar:GetStatusBarTexture()
		if statusBarTexture then
			statusBarTexture:SetTexture(LSM:Fetch("statusbar", buffBarOptions.barTexture))
			statusBarTexture:SetTexelSnappingBias(0)
			statusBarTexture:SetSnapToPixelGrid(false)
		end

		for _, region in ipairs({ bar:GetRegions() }) do
			if region:IsObjectType("Texture") then
				region:SetTexelSnappingBias(0)
				region:SetSnapToPixelGrid(false)
				--if region:GetAtlas() == "UI-HUD-CoolDownManager-Bar-Pip" or region:GetAtlas() == "UI-HUD-CoolDownManager-Bar-BG" then
				if region:GetAtlas() == "UI-HUD-CoolDownManager-Bar-Pip" then
					region:Hide()
				end
			end
		end

		if options.buffBarContent == 2 then
			bar:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
			bar.BarBG:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
		else
			bar:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", -borderSize, 0)
			bar.BarBG:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", -borderSize, 0)
		end

		bar:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", -borderSize, 0)
		bar:SetHeight(iconFrame:GetHeight())
		bar:SetStatusBarColor(foregroundColor.r, foregroundColor.g, foregroundColor.b, foregroundColor.a)
		bar.Pip:SetAlpha(0)
		bar.BarBG:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", -borderSize, 0)
		bar.BarBG:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
		bar.BarBG:SetColorTexture(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
		bar.BarBG:SetTexelSnappingBias(0)
		bar.BarBG:SetSnapToPixelGrid(false)
		local fontOutline = buffBarOptions.fontOutline or "OUTLINE"
		bar.Name:SetFont(LSM:Fetch("font", buffBarOptions.font), buffBarOptions.fontSize, fontOutline)
		bar.Duration:SetFont(LSM:Fetch("font", buffBarOptions.font), buffBarOptions.fontSize, fontOutline)

		local nameColor = buffBarOptions.nameColor
		bar.Name:ClearPointsOffset()
		bar.Name:AdjustPointsOffset(buffBarOptions.nameXOffset, buffBarOptions.nameYOffset)
		bar.Name:SetTextColor(nameColor.r, nameColor.g, nameColor.b, nameColor.a)
		bar.Name:SetShown(not buffBarOptions.hideSpellName)

		local durationColor = buffBarOptions.durationColor
		bar.Duration:ClearPointsOffset()
		bar.Duration:AdjustPointsOffset(buffBarOptions.durationXOffset, buffBarOptions.durationYOffset)
		bar.Duration:SetTextColor(durationColor.r, durationColor.g, durationColor.b, durationColor.a)
		bar.Duration:SetShown(not buffBarOptions.hideDuration)

		bar.customBorder = bar.customBorder or CreateFrame("Frame", nil, bar, "BackdropTemplate")
		bar.customBorder:SetFrameLevel(bar:GetFrameLevel() + 1)
		bar.customBorder:SetAllPoints(bar)
		bar.customBorder:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = borderSize,
		})
		bar.customBorder:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

		if borderSize == 0 then
			bar.customBorder:Hide()
		else
			bar.customBorder:Show()
		end

		for _, region in ipairs({ bar.customBorder:GetRegions() }) do
			region:SetTexelSnappingBias(0)
			region:SetSnapToPixelGrid(false)
		end

		iconFrame.Icon:ClearAllPoints()
		iconFrame.Icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", borderSize, -borderSize)
		iconFrame.Icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -borderSize, borderSize)
		iconFrame.Icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
		iconFrame.Icon:SetTexelSnappingBias(0)
		iconFrame.Icon:SetSnapToPixelGrid(false)

		iconFrame.customBorder = iconFrame.customBorder or CreateFrame("Frame", nil, iconFrame, "BackdropTemplate")
		iconFrame.customBorder:SetFrameLevel(iconFrame:GetFrameLevel() + 1)
		iconFrame.customBorder:SetAllPoints(iconFrame)
		iconFrame.customBorder:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = borderSize,
		})
		iconFrame.customBorder:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

		if borderSize == 0 then
			iconFrame.customBorder:Hide()
		else
			iconFrame.customBorder:Show()
		end

		for _, region in ipairs({ iconFrame.customBorder:GetRegions() }) do
			region:SetTexelSnappingBias(0)
			region:SetSnapToPixelGrid(false)
		end

		for _, region in ipairs({ iconFrame:GetRegions() }) do
			if region:IsObjectType("Texture") then
				region:SetTexelSnappingBias(0)
				region:SetSnapToPixelGrid(false)
			end

			if region.GetMaskTexture and region:GetMaskTexture(1) then
				region:RemoveMaskTexture(region:GetMaskTexture(1))
			elseif region:IsObjectType("Texture") and region.GetAtlas and region:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then
				region:Hide()
			end
		end

		local rowConfig = child.SCMRowConfig or {}
		local fontPath = LSM:Fetch("font", options.chargeFont)
		if iconFrame.Applications then
			local applications = iconFrame.Applications
			applications:SetWordWrap(false)
			applications:SetNonSpaceWrap(false)
			applications:SetMaxLines(1)

			local size = rowConfig.applicationsFontSize or options.chargeFontSize
			local outline = rowConfig.applicationsFontOutline or options.chargeFontOutline or "OUTLINE"

			if fontPath then
				applications:SetFont(fontPath, size, outline)
			end

			applications:SetSize(iconFrame:GetHeight(), iconFrame:GetHeight())
			if not applications.SCMFitTextHooked then
				applications.SCMFitTextHooked = true
				hooksecurefunc(applications, "SetText", function()
					applications:SetSize(iconFrame:GetHeight(), iconFrame:GetHeight())
				end)
			end

			local point = rowConfig.applicationsPoint or options.chargePoint
			local overlay = iconFrame.SCMApplicationsOverlay
			if not overlay then
				overlay = CreateFrame("Frame", nil, iconFrame)
				overlay:SetAllPoints(iconFrame)
				iconFrame.SCMApplicationsOverlay = overlay
			end

			overlay:SetFrameLevel(iconFrame.customBorder:GetFrameLevel() + 1)
			applications:SetParent(overlay)
			applications:SetDrawLayer("OVERLAY", 7)
			applications:SetJustifyH("CENTER")
			applications:SetJustifyV("MIDDLE")
			applications:ClearAllPoints()
			applications:SetPoint(
				point,
				child.Icon,
				rowConfig.applicationsRelativePoint or options.chargeRelativePoint,
				rowConfig.applicationsXOffset or options.chargeXOffset,
				rowConfig.applicationsYOffset or options.chargeYOffset
			)
		end
	end
end

function SCM:SkinBuffBars()
	for _, child in ipairs({ BuffBarCooldownViewer:GetChildren() }) do
		self:SkinBuffBar(child)
	end
end
