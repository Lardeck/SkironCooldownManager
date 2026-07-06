local SCM = select(2, ...)
local LibCustomGlow = LibStub("LibCustomGlow-1.0")

local activeGlows = {}

function SCM:StartCustomGlow(child, glowTypeOptions, glowType)
	if not child then
		return
	end

	local options = self.db.profile.options
	if child.SCMGlow and options.glowType == child.SCMGlow then
		return
	end

	if child.SCMGlow and (options.glowType ~= child.SCMGlow or (self.OptionsFrame and self.OptionsFrame:IsVisible())) then
		self:StopCustomGlow(child)
	end

	local childConfig = child.SCMConfig
	if not childConfig then
		return
	end

	local glowType = glowType or options.glowType
	local glowTypeOptions = glowTypeOptions or options.glowTypeOptions[glowType]
	local color = childConfig.useCustomGlowColor and childConfig.customGlowColor or glowTypeOptions.glowColor
	child.SCMGlow = glowType

	if glowType == "Proc" then
		LibCustomGlow.ProcGlow_Start(child, { key = "SCM", frameLevel = 1, color = color, startAnim = glowTypeOptions.startAnim, xOffset = glowTypeOptions.xOffset, yOffset = glowTypeOptions.yOffset })
	elseif glowType == "Autocast" then
		-- color,N,frequency,scale,xOffset,yOffset,key,frameLevel
		LibCustomGlow.AutoCastGlow_Start(child, color, glowTypeOptions.numParticles, glowTypeOptions.frequency, glowTypeOptions.scale, glowTypeOptions.xOffset, glowTypeOptions.yOffset, "SCM", 1)
	elseif glowType == "Pixel" then
		-- N,frequency,length,th,xOffset,yOffset,border
		LibCustomGlow.PixelGlow_Start(
			child,
			color,
			glowTypeOptions.numLines,
			glowTypeOptions.frequency,
			glowTypeOptions.length,
			glowTypeOptions.thickness,
			glowTypeOptions.xOffset,
			glowTypeOptions.yOffset,
			glowTypeOptions.border,
			"SCM",
			1
		)

		-- Why do I have to do this?
		local glowFrame = child["_PixelGlowSCM"]
		if glowFrame then
			glowFrame:ClearAllPoints()
			glowFrame:SetPoint("TOPLEFT", child, "TOPLEFT", -glowTypeOptions.xOffset, glowTypeOptions.yOffset)
			glowFrame:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", glowTypeOptions.xOffset, -glowTypeOptions.yOffset)

			for _, texture in pairs(glowFrame.textures) do
				texture:SetTexelSnappingBias(0)
				texture:SetSnapToPixelGrid(false)

				if glowTypeOptions.border then
					texture:SetBlendMode("ADD")
				end
			end

			for _, mask in pairs(glowFrame.masks) do
				mask:SetTexelSnappingBias(0)
				mask:SetSnapToPixelGrid(false)
			end
		end
	elseif glowType == "Button" then
		LibCustomGlow.ButtonGlow_Start(child, color, glowTypeOptions.frequency)
	end

	activeGlows[child] = true
end

function SCM:StopCustomGlow(child)
	if child.SCMGlow == "Proc" then
		LibCustomGlow.ProcGlow_Stop(child, "SCM")
	elseif child.SCMGlow == "Autocast" then
		LibCustomGlow.AutoCastGlow_Stop(child, "SCM")
	elseif child.SCMGlow == "Pixel" then
		LibCustomGlow.PixelGlow_Stop(child, "SCM")
	elseif child.SCMGlow == "Button" then
		LibCustomGlow.ButtonGlow_Stop(child)
	end

	child.SCMGlow = nil
	activeGlows[child] = nil
end

function SCM:StopAllGlows()
	for child in pairs(activeGlows) do
		self:StopCustomGlow(child)
	end
end

function SCM:RefreshAllGlows()
	for child in pairs(activeGlows) do
		self:StartCustomGlow(child)
	end
end

local function RestoreSpellAlertGlow(self, child, options)
	if not (child and child.SCMActiveGlow and child.SpellActivationAlert) then
		return
	end

	if options.useCustomGlow and child.SCMConfig then
		child.SpellActivationAlert:Hide()
		self:StartCustomGlow(child)
		return
	end

	--child.SpellActivationAlert:Show()
end

function SCM:RestoreBlizzardGlows()
	local options = self.db.profile.options
	for _, viewerName in ipairs({ "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer" }) do
		local viewer = _G[viewerName]
		if viewer then
			for _, child in ipairs({ viewer:GetChildren() }) do
				RestoreSpellAlertGlow(self, child, options)
			end
		end
	end
end
