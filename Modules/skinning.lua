local SCM = select(2, ...)
local LSM = LibStub("LibSharedMedia-3.0")

local originalCooldownFont
local function GetCooldownFontScale(options)
	local cooldownFontScale = options.cooldownFontSize or 0.6
	if cooldownFontScale > 1 then
		cooldownFontScale = cooldownFontScale / 40
		options.cooldownFontSize = cooldownFontScale
	end

	return cooldownFontScale
end

local function ApplyChargeAndApplicationStyle(child, options, fontPath)
	local rowConfig = child.SCMRowConfig or {}
	if child.ChargeCount and child.ChargeCount.Current then
		local size = rowConfig.chargeFontSize or options.chargeFontSize

		if fontPath then
			child.ChargeCount.Current:SetFont(fontPath, size, "OUTLINE")
		end

		if child.SCMCustom then
			child.ChargeCount:SetWidth(child.ChargeCount.Current:GetWidth())
			child.ChargeCount:SetHeight(child.ChargeCount.Current:GetStringHeight() - 10)
		end

		child.ChargeCount.Current:ClearAllPoints()
		child.ChargeCount.Current:SetPoint(
			rowConfig.chargePoint or options.chargePoint,
			child.Icon,
			rowConfig.chargeRelativePoint or options.chargeRelativePoint,
			rowConfig.chargeXOffset or options.chargeXOffset,
			rowConfig.chargeYOffset or options.chargeYOffset
		)
	end

	if child.Applications and child.Applications.Applications then
		local size = rowConfig.applicationsFontSize or options.chargeFontSize
		if fontPath then
			child.Applications.Applications:SetFont(fontPath, size, "OUTLINE")
		end

		child.Applications.Applications:ClearAllPoints()
		child.Applications.Applications:SetPoint(
			rowConfig.applicationsPoint or options.chargePoint,
			child.Icon,
			rowConfig.applicationsRelativePoint or options.chargeRelativePoint,
			rowConfig.applicationsXOffset or options.chargeXOffset,
			rowConfig.applicationsYOffset or options.chargeYOffset
		)
	end
end

local function ApplyCooldownFont(cooldownFrame, options)
	options = options or SCM.db.profile.options

	if options.changeCooldownFont then
		local fontPath = LSM:Fetch("font", options.cooldownFont)
		local cooldownFontString = cooldownFrame:GetRegions()
		if cooldownFontString and cooldownFontString.SetFont then
			if not originalCooldownFont then
				originalCooldownFont = { cooldownFontString:GetFont() }
			end

			local parent = cooldownFrame:GetParent()
			if parent.SCMWidth and parent.SCMHeight then
				local width, height = parent.SCMWidth, parent.SCMHeight
				local iconSize = min(width, height)
				local fontSize = max(1, floor(iconSize * GetCooldownFontScale(options) + 0.5))
				cooldownFontString:SetFont(fontPath, fontSize, "OUTLINE")
				cooldownFontString:SetShadowColor(0, 0, 0, 0)
				cooldownFontString:SetShadowOffset(0, 0)
			end
		end
	elseif originalCooldownFont then
		local cooldownFontString = cooldownFrame:GetRegions()
		if cooldownFontString and cooldownFontString.SetFont then
			cooldownFontString:SetFont(unpack(originalCooldownFont))
		end
	end
end

local function ApplyCooldownStyle(child, options)
	local cooldownFrame = child.GetCooldownFrame and child:GetCooldownFrame() or child.Cooldown
	if cooldownFrame then
		if child.SCMCooldownSkinHook then
			return
		end

		child.SCMCooldownSkinHook = true
		if child.CooldownFlash then
			child.CooldownFlash:SetAlpha(0)
		end

		cooldownFrame:ClearAllPoints()
		cooldownFrame:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -0)
		cooldownFrame:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", -0, 0)
		cooldownFrame:SetSwipeTexture("Interface\\Buttons\\WHITE8x8")

		hooksecurefunc(cooldownFrame, "SetCooldown", function(self)
			local parent = self:GetParent()
			RunNextFrame(function()
				if options.recolorActiveSwipe and parent.auraInstanceID then
					if not options.disableRegularIconActiveSwipe or (parent.SCMConfig and parent.SCMConfig.forceActiveSwipe) or parent.SCMBuffOptions then
						self:SetSwipeColor(unpack(options.activeSwipeColor))
						self:SetReverse(options.reverseActiveSwipe)
					elseif options.recolorNormalSwipe then
						self:SetSwipeColor(unpack(options.normalSwipeColor))
						self:SetReverse(false)
					else
						self:SetSwipeColor(0, 0, 0, 0.7)
					end
				elseif options.recolorNormalSwipe then
					self:SetSwipeColor(unpack(options.normalSwipeColor))
					self:SetReverse(false)
				else
					self:SetSwipeColor(0, 0, 0, 0.7)
				end
			end)
			ApplyCooldownFont(self, options)
		end)

		-- hooksecurefunc(cooldownFrame, "Clear", function(self)
		-- 	if options.recolorActiveSwipe then
		-- 		self:SetSwipeColor(0, 0, 0, 0.7)
		-- 	end
		-- end)

		ApplyCooldownFont(cooldownFrame, options)
	end
end

function SCM:SkinChild(child, childConfig)
	if C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI[1].private.skins.blizzard.cooldownManager then
		return
	end

	local options = self.db.profile.options
	if not options.enableSkinning then
		return
	end

	local borderSize = SCM:PixelPerfect() * options.borderSize
	local borderColor = options.borderColor

	if child.SCMSkinned and self.OptionsFrame ~= nil and self.OptionsFrame:IsShown() then
		if borderSize == 0 then
			child.customBorder:Hide()
		else
			child.customBorder:SetBackdrop({
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				edgeSize = borderSize,
			})
			child.customBorder:Show()

			child.customBorder:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
		end

		child.Icon:ClearAllPoints()
		child.Icon:SetPoint("TOPLEFT", child, "TOPLEFT", borderSize, -borderSize)
		child.Icon:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", -borderSize, borderSize)
		child.Icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)

		local fontPath = LSM:Fetch("font", options.chargeFont)
		ApplyChargeAndApplicationStyle(child, options, fontPath)
		ApplyCooldownStyle(child, options)
	elseif not child.SCMSkinned then
		child.SCMSkinned = true

		child.Icon:ClearAllPoints()
		child.Icon:SetPoint("TOPLEFT", child, "TOPLEFT", borderSize, -borderSize)
		child.Icon:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", -borderSize, borderSize)
		child.Icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)

		child.customBorder = CreateFrame("Frame", nil, child, "BackdropTemplate")
		child.customBorder:SetFrameLevel(child:GetFrameLevel() + 1)
		child.customBorder:SetAllPoints(child)
		child.customBorder:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = borderSize,
		})
		child.customBorder:SetBackdropBorderColor(0, 0, 0, 1)

		if borderSize == 0 then
			child.customBorder:Hide()
		else
			child.customBorder:Show()
		end

		local textureRegion
		for _, region in ipairs({ child:GetRegions() }) do
			if region.GetMaskTexture and region:GetMaskTexture(1) then
				region:RemoveMaskTexture(region:GetMaskTexture(1))
			elseif region:IsObjectType("Texture") and region.GetAtlas and region:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then
				textureRegion = region
				region:Hide()
			end
		end

		if childConfig and childConfig.customIcon and textureRegion then
			child.Icon:SetTexture(childConfig.customIcon)

			if not child.SCMIconTextureHook then
				child.SCMIconTextureHook = true
				hooksecurefunc(child.Icon, "SetTexture", function(self)
					local config = self:GetParent().SCMConfig
					if config and config.customIcon then
						textureRegion.SetTexture(self, config.customIcon)
					end
				end)
			end
		end

		if child.DebuffBorder then
			child.DebuffBorder:SetAlpha(0)
		end

		local fontPath = LSM:Fetch("font", options.chargeFont)
		ApplyChargeAndApplicationStyle(child, options, fontPath)
		ApplyCooldownStyle(child, options)
	end

	for _, customSkin in ipairs(SCM.Skins) do
		pcall(customSkin, child)
	end
end

function SCM:SkinBuffBars()
	local options = SCM.db.profile.options.buffBarOptions
	local borderSize = SCM:PixelPerfect() * options.borderSize
	local borderColor = options.borderColor
	local backgroundColor = options.backgroundColor
	local foregroundColor = options.foregroundColor

	local iconFrame, bar
	for _, child in ipairs({ BuffBarCooldownViewer:GetChildren() }) do
		if child.GetIconFrame then
			iconFrame = child:GetIconFrame()
		end

		if child.Bar then
			bar = child.Bar
		end

		if bar and iconFrame then
			local statusBarTexture = bar:GetStatusBarTexture()
			if statusBarTexture then
				statusBarTexture:SetTexture(LSM:Fetch("statusbar", options.barTexture))
			end

			for _, region in ipairs({ bar:GetRegions() }) do
				if region:IsObjectType("Texture") then
					--if region:GetAtlas() == "UI-HUD-CoolDownManager-Bar-Pip" or region:GetAtlas() == "UI-HUD-CoolDownManager-Bar-BG" then
					if region:GetAtlas() == "UI-HUD-CoolDownManager-Bar-Pip" then
						region:Hide()
					end
				end
			end

			bar:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", -borderSize, 0)
			bar:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", -borderSize, 0)
			bar:SetHeight(iconFrame:GetHeight())
			bar:SetStatusBarColor(foregroundColor.r, foregroundColor.g, foregroundColor.b, foregroundColor.a)
			bar.Pip:SetAlpha(0)
			bar.BarBG:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", -borderSize, 0)
			bar.BarBG:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", -borderSize, 0)
			bar.BarBG:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
			bar.BarBG:SetColorTexture(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
			bar.Name:SetFont(LSM:Fetch("font", options.font), options.fontSize, "OUTLINE")
			bar.Duration:SetFont(LSM:Fetch("font", options.font), options.fontSize, "OUTLINE")

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

			iconFrame.Icon:ClearAllPoints()
			iconFrame.Icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", borderSize, -borderSize)
			iconFrame.Icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -borderSize, borderSize)
			iconFrame.Icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)

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

			for _, region in ipairs({ iconFrame:GetRegions() }) do
				if region.GetMaskTexture and region:GetMaskTexture(1) then
					region:RemoveMaskTexture(region:GetMaskTexture(1))
				elseif region:IsObjectType("Texture") and region.GetAtlas and region:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then
					region:Hide()
				end
			end
		end
	end
end
