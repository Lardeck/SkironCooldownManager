local SCM = select(2, ...)

local OriginalUUFAnchors = {}
local OriginalElvUIAnchors = {}

local function OnResourceBarWidthChanged(self)
	UIParent.SetWidth(self, self.SCMWidth)
end

function SCM:UpdateResourceBarWidth(maxGroupWidth)
	maxGroupWidth = self:PixelPerfect(maxGroupWidth)
	for _, resourceBarName in ipairs(SCM.db.profile.options.resourceBars) do
		local resourceBar = _G[resourceBarName]
		if resourceBar and resourceBar:IsShown() then
			resourceBar.SCMWidth = max(200, maxGroupWidth)
			resourceBar:SetWidth(max(200, maxGroupWidth))

			if not resourceBar.SCMHook then
				resourceBar.SCMHook = true
				hooksecurefunc(resourceBar, "SetWidth", OnResourceBarWidthChanged)
				hooksecurefunc(resourceBar, "SetSize", OnResourceBarWidthChanged)
			end
		end
	end
end

function SCM:UpdateUUFValues(options, maxGroupWidth, rowConfig)
	local offset = min((maxGroupWidth - 150), 0)
	local mainAnchor = SCM:GetAnchor(1)

	if UUF_Player then
		if options.anchorUUF and options.anchorUUFRoles[(select(5, GetSpecializationInfo(GetSpecialization())))] then
			if not UUF_Player.SCMOriginalAnchor then
				UUF_Player.SCMOriginalAnchor = { UUF_Player:GetPoint() }
				UUF_Player.SCMOriginalWidth = UUF_Player:GetWidth()
				UUF_Player.SCMOriginalHeight = UUF_Player:GetHeight()
			end
			UUF_Player:ClearAllPoints()

			mainAnchor.SetPoint(UUF_Player, "TOPRIGHT", mainAnchor, "TOPLEFT", offset, 0)

			local height = rowConfig[1].iconHeight or rowConfig[1].size
			UUF_Player.SCMOffset = offset
			UUF_Player.SCMHeight = height
			UUF_Player.SCMAnchor = mainAnchor
			UUF_Player.SCMCustomAnchor = true

			UUF_Player:SetHeight(height)
			UUF_Player_HealthBar:SetHeight(height - 2)
			UUF_Player_HealthBackground:SetHeight(height - 2)
			UUF_Player_HealAbsorbBar:SetHeight(height - 2)

			if not UUF_Player.SCMHook then
				UUF_Player.SCMHook = true
				hooksecurefunc(UUF_Player, "SetPoint", function(self)
					if options.anchorUUF and options.anchorUUFRoles[(select(5, GetSpecializationInfo(GetSpecialization())))] then
						self.SCMAnchor.SetPoint(self, "TOPRIGHT", self.SCMAnchor, "TOPLEFT", self.SCMOffset, 0)
						self.SCMAnchor.SetHeight(self, self.SCMHeight)
						self.SCMAnchor.SetHeight(UUF_Player_HealthBar, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Player_HealthBackground, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Player_HealAbsorbBar, self.SCMHeight - 2)
					end
				end)

				hooksecurefunc(UUF_Player, "SetSize", function(self)
					if options.anchorUUF and options.anchorUUFRoles[(select(5, GetSpecializationInfo(GetSpecialization())))] then
						self.SCMAnchor.SetHeight(self, self.SCMHeight)
						self.SCMAnchor.SetHeight(UUF_Player_HealthBar, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Player_HealthBackground, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Player_HealAbsorbBar, self.SCMHeight - 2)
					end
				end)
			end
		elseif UUF_Player.SCMCustomAnchor then
			UUF_Player:ClearAllPoints()
			UUF_Player.SCMAnchor.SetPoint(UUF_Player, unpack(UUF_Player.SCMOriginalAnchor))
			UUF_Player.SCMAnchor.SetHeight(UUF_Player, UUF_Player.SCMOriginalHeight)
			UUF_Player.SCMAnchor.SetHeight(UUF_Player_HealthBar, UUF_Player.SCMOriginalHeight - 2)
			UUF_Player.SCMAnchor.SetHeight(UUF_Player_HealthBackground, UUF_Player.SCMOriginalHeight - 2)
			UUF_Player.SCMAnchor.SetHeight(UUF_Player_HealAbsorbBar, UUF_Player.SCMOriginalHeight - 2)

			UUF_Player.SCMCustomAnchor = nil
			UUF_Player.SCMOffset = nil
			UUF_Player.SCMHeight = nil
			UUF_Player.SCMAnchor = nil
			UUF_Player.SCMOriginalHeight = nil
			UUF_Player.SCMOriginalAnchor = nil
		end
	end

	if UUF_Target then
		if options.anchorUUF and options.anchorUUFRoles[(select(5, GetSpecializationInfo(GetSpecialization())))] then
			if not UUF_Target.SCMOriginalAnchor then
				UUF_Target.SCMOriginalAnchor = { UUF_Target:GetPoint() }
				UUF_Target.SCMOriginalWidth = UUF_Target:GetWidth()
				UUF_Target.SCMOriginalHeight = UUF_Target:GetHeight()
			end

			UUF_Target:ClearAllPoints()
			mainAnchor.SetPoint(UUF_Target, "TOPLEFT", mainAnchor, "TOPRIGHT", -offset, 0)

			local height = rowConfig[1].iconHeight or rowConfig[1].size
			UUF_Target.SCMOffset = -offset
			UUF_Target.SCMHeight = height
			UUF_Target.SCMAnchor = mainAnchor
			UUF_Target.SCMCustomAnchor = true

			UUF_Target:SetHeight(height)
			UUF_Target_HealthBar:SetHeight(height - 2)
			UUF_Target_HealthBackground:SetHeight(height - 2)

			if not UUF_Target.SCMHook then
				UUF_Target.SCMHook = true
				hooksecurefunc(UUF_Target, "SetPoint", function(self)
					if options.anchorUUF and options.anchorUUFRoles[(select(5, GetSpecializationInfo(GetSpecialization())))] then
						self.SCMAnchor.SetPoint(self, "TOPLEFT", self.SCMAnchor, "TOPRIGHT", self.SCMOffset, 0)
						self.SCMAnchor.SetHeight(self, self.SCMHeight)
						self.SCMAnchor.SetHeight(UUF_Target_HealthBar, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Target_HealthBackground, self.SCMHeight - 2)
					end
				end)

				hooksecurefunc(UUF_Target, "SetSize", function(self)
					if options.anchorUUF and options.anchorUUFRoles[(select(5, GetSpecializationInfo(GetSpecialization())))] then
						self.SCMAnchor.SetHeight(self, self.SCMHeight)
						self.SCMAnchor.SetHeight(UUF_Target_HealthBar, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Target_HealthBackground, self.SCMHeight - 2)
					end
				end)
			end
		elseif UUF_Target.SCMCustomAnchor then
			UUF_Target:ClearAllPoints()
			UUF_Target.SCMAnchor.SetPoint(UUF_Target, unpack(UUF_Target.SCMOriginalAnchor))
			UUF_Target.SCMAnchor.SetHeight(UUF_Target, UUF_Target.SCMOriginalHeight)
			UUF_Target.SCMAnchor.SetHeight(UUF_Target_HealthBar, UUF_Target.SCMOriginalHeight - 2)
			UUF_Target.SCMAnchor.SetHeight(UUF_Target_HealthBackground, UUF_Target.SCMOriginalHeight - 2)

			UUF_Target.SCMCustomAnchor = nil
			UUF_Target.SCMOffset = nil
			UUF_Target.SCMHeight = nil
			UUF_Target.SCMAnchor = nil
			UUF_Target.SCMOriginalHeight = nil
			UUF_Target.SCMOriginalAnchor = nil
		end
	end

	if ElvUI and not next(OriginalElvUIAnchors) and options.anchorElvUI then
		local E = ElvUI[1]
		if E.db.movers then
			OriginalElvUIAnchors["ElvUF_PlayerMover"] = OriginalElvUIAnchors["ElvUF_PlayerMover"] or E.db.movers.ElvUF_PlayerMover
			E.db.movers.ElvUF_PlayerMover = string.format("TOPRIGHT,%s,TOPLEFT,%d,%d", mainAnchor:GetName(), -offset, 0)
			E:SetMoverPoints("ElvUF_PlayerMover")

			OriginalElvUIAnchors["ElvUF_TargetMover"] = OriginalElvUIAnchors["ElvUF_TargetMover"] or E.db.movers.ElvUF_TargetMover
			E.db.movers.ElvUF_TargetMover = string.format("TOPLEFT,%s,TOPRIGHT,%d,%d", mainAnchor:GetName(), offset, 0)
			E:SetMoverPoints("ElvUF_TargetMover")
		end

		E.db.unitframe.units.player.height = rowConfig[1].size
		E.db.unitframe.units.target.height = rowConfig[1].size

		local UF = E:GetModule('UnitFrames')
		UF:Update_AllFrames()
	end
end

function SCM:ApplyCustomAnchors(maxGroupWidth, rowConfig)
	local inLockdown = InCombatLockdown()

	for frame, options in pairs(self.CustomAnchors) do
		frame = type(frame) == "string" and _G[frame] or frame
		if frame and type(frame) == "table" and options.anchorIndex and options.xOffset and options.yOffset and (not frame:IsProtected() or not inLockdown) then
			if not frame.SCMHook then
				frame.SCMHook = true
				frame.OriginalClearAllPoints = frame.ClearAllPoints
				frame.OriginalSetPoint = frame.SetPoint
				frame.ClearAllPoints = nop
				frame.SetPoint = nop

				if options.setWidth then
					frame.OriginalSetWidth = frame.SetWidth
					frame.SetWidth = nop
				end
			end

			frame:OriginalClearAllPoints()
			local point = options.point
			local anchorRef = options.anchorFrame
			local relativePoint = options.relativePoint
			local xOffset = options.xOffset
			local yOffset = options.yOffset

			if point and anchorRef and relativePoint then
				local setPoint = frame.OriginalSetPoint
				local anchorRefType = type(anchorRef)
				local isAnchorList = anchorRefType == "table"

				if isAnchorList then
					for i = 1, #anchorRef do
						local ref = anchorRef[i]
						local anchor
						local anchorIndex = tonumber(ref)
						if anchorIndex then
							anchor = SCM:GetAnchor(anchorIndex)
						else
							local refType = type(ref)
							if refType == "string" then
								anchor = SCM.Utils.GetAnchorFrame(ref)
							elseif refType == "table" then
								anchor = ref
							end
						end

						if anchor and anchor:IsVisible() then
							setPoint(frame, point, anchor, relativePoint, xOffset, yOffset)
							break
						end
					end
				else
					local anchor
					local anchorIndex = tonumber(anchorRef)
					if anchorIndex then
						anchor = SCM:GetAnchor(anchorIndex)
					elseif anchorRefType == "string" then
						anchor = SCM.Utils.GetAnchorFrame(anchorRef)
					elseif anchorRefType == "table" then
						anchor = anchorRef
					end

					if anchor and anchor:IsVisible() then
						setPoint(frame, point, anchor, relativePoint, xOffset, yOffset)
						break
					end
				end
			else
				frame:OriginalSetPoint("BOTTOM", SCM:GetAnchor(options.anchorIndex), "TOP", options.xOffset, options.yOffset)
			end

			if options.setWidth then
				frame:OriginalSetWidth(max(200, maxGroupWidth - (options.widthOffset or 0)))
			end
		end
	end
end

--- Copies anchorConfig and buffBarsAnchorConfig from a source class/spec into the
--- current logged-in spec, then live-applies the result.
---@param sourceClass string  Uppercase class file name, e.g. "WARRIOR"
---@param sourceSpecID number  Spec ID integer, e.g. 71
function SCM:CopyAnchorConfig(sourceClass, sourceSpecID)
	local targetClass = self.currentClass
	local targetSpecID = self.currentSpecID

	-- Resolve source anchor data.  Prefer already-saved profile data; fall back to
	-- the registered class defaults, then the global default anchor config.
	local sourceProfile = self.db.profile[sourceClass] and self.db.profile[sourceClass][sourceSpecID]
	local sourceAnchorConfig
	local sourceBuffBarsAnchorConfig

	if sourceProfile then
		sourceAnchorConfig = sourceProfile.anchorConfig
		sourceBuffBarsAnchorConfig = sourceProfile.buffBarsAnchorConfig
	else
		-- Source spec has never been opened; try the class registration data.
		local classData = self.DB.classes[sourceClass]
		if classData then
			sourceAnchorConfig = classData.anchorConfig and classData.anchorConfig[sourceSpecID]
			sourceBuffBarsAnchorConfig = classData.buffBarsAnchorConfig and classData.buffBarsAnchorConfig[sourceSpecID]
		end
		-- Final fallback: global defaults.
		if not sourceAnchorConfig then
			sourceAnchorConfig = self.DB.defaultAnchorConfig
		end
		if not sourceBuffBarsAnchorConfig then
			sourceBuffBarsAnchorConfig = {}
		end
	end

	-- Ensure the target entry exists before writing into it.
	self.db.profile[targetClass] = self.db.profile[targetClass] or {}
	self.db.profile[targetClass][targetSpecID] = self.db.profile[targetClass][targetSpecID] or CopyTable(self.DefaultClassConfig)

	local targetProfile = self.db.profile[targetClass][targetSpecID]
	targetProfile.anchorConfig = CopyTable(sourceAnchorConfig)
	targetProfile.buffBarsAnchorConfig = CopyTable(sourceBuffBarsAnchorConfig)

	-- Re-load live references and refresh all anchor frames.
	self:UpdateDB()
	self:ApplyAllCDManagerConfigs()
end
