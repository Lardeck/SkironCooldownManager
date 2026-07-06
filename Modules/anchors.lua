local SCM = select(2, ...)
local Utils = SCM.Utils

local lastXOffset, lastYOffset, lastHeight, lastPadding

local function OnResourceBarWidthChanged(self)
	UIParent.SetWidth(self, self.SCMWidth)
end

function SCM:UpdateResourceBarWidth(maxGroupWidth)
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

function SCM:UpdateUFValues(options, maxGroupWidth, rowConfig)
	if ElvUI then
		local E = ElvUI[1]

		local xOffset = min((maxGroupWidth - 150), 0)
		local yOffset = options.anchorsYOffset
		local padding = options.temporaryPadding

		local mainAnchor = SCM:GetAnchor(1)
		local height = floor((rowConfig[1].iconHeight or rowConfig[1].size) + 0.5) + options.anchorsHeightOffset
		if options.anchorElvUI and options.anchorElvUIRoles[(select(5, Utils.GetSpec()))] then
			local changed = false
			if E.db.movers then
				SCM.db.profile.options.elvUIAnchors["ElvUF_PlayerMover"] = SCM.db.profile.options.elvUIAnchors["ElvUF_PlayerMover"] or E.db.movers.ElvUF_PlayerMover
				E.db.movers.ElvUF_PlayerMover = string.format("TOPRIGHT,%s,TOPLEFT,%d,%d", mainAnchor:GetName(), -xOffset - padding, yOffset)
				E:SetMoverPoints("ElvUF_PlayerMover")

				SCM.db.profile.options.elvUIAnchors["ElvUF_TargetMover"] = SCM.db.profile.options.elvUIAnchors["ElvUF_TargetMover"] or E.db.movers.ElvUF_TargetMover
				E.db.movers.ElvUF_TargetMover = string.format("TOPLEFT,%s,TOPRIGHT,%d,%d", mainAnchor:GetName(), xOffset + padding, yOffset)
				E:SetMoverPoints("ElvUF_TargetMover")

				changed = changed or lastXOffset ~= xOffset or lastPadding ~= padding or lastYOffset ~= yOffset

				lastPadding = padding
				lastXOffset = xOffset
				lastYOffset = yOffset
			end

			if options.adjustHeight then
				E.db.unitframe.units.player.height = height
				E.db.unitframe.units.target.height = height

				changed = changed or lastHeight ~= height
				lastHeight = height
			end

			if changed then
				local UF = E:GetModule("UnitFrames")
				UF:Update_AllFrames()
			end
		else
			local changed = false
			if SCM.db.profile.options.elvUIAnchors["ElvUF_PlayerMover"] then
				changed = true
				E.db.movers.ElvUF_PlayerMover = SCM.db.profile.options.elvUIAnchors["ElvUF_PlayerMover"]
				E:SetMoverPoints("ElvUF_PlayerMover")
			end

			if SCM.db.profile.options.elvUIAnchors["ElvUF_TargetMover"] then
				changed = true
				E.db.movers.ElvUF_TargetMover = SCM.db.profile.options.elvUIAnchors["ElvUF_TargetMover"]
				E:SetMoverPoints("ElvUF_TargetMover")
			end

			if changed then
				local UF = E:GetModule("UnitFrames")
				UF:Update_AllFrames()
				wipe(SCM.db.profile.options.elvUIAnchors)
			end
		end
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
			sourceBuffBarsAnchorConfig = self.DB.defaultBuffBarsAnchorConfig
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
