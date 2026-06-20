local SCM = select(2, ...)

local Utils = SCM.Utils
local OriginalElvUIAnchors = {}

local function GetAnchorLayoutCallbackSettings()
	local profileOptions = SCM.db and SCM.db.profile and SCM.db.profile.options
	if not profileOptions then
		return
	end

	profileOptions.anchorLayoutCallbacks = profileOptions.anchorLayoutCallbacks or {}
	return profileOptions.anchorLayoutCallbacks
end

local function NormalizeAnchorLayoutGroups(groups)
	if groups == nil then
		return
	end

	if type(groups) == "number" then
		return { [groups] = true }
	end

	if type(groups) ~= "table" then
		return
	end

	local normalizedGroups = {}
	for key, value in pairs(groups) do
		if type(key) == "number" and value then
			normalizedGroups[key] = true
		elseif type(value) == "number" then
			normalizedGroups[value] = true
		end
	end

	if next(normalizedGroups) then
		return normalizedGroups
	end
end

local function CopyAnchorLayoutRoles(roles)
	if type(roles) ~= "table" then
		return
	end

	local copiedRoles = {}
	for role, enabled in pairs(roles) do
		copiedRoles[role] = enabled and true or false
	end
	return copiedRoles
end

local function GetAnchorLayoutCallbackConfig(addOnName, callbackEntry)
	local settings = GetAnchorLayoutCallbackSettings()
	if not settings then
		return
	end

	local config = settings[addOnName]
	if type(config) ~= "table" then
		config = { enabled = config }
		settings[addOnName] = config
	end

	if config.enabled == nil then
		config.enabled = callbackEntry.defaultEnabled
	end
	if callbackEntry.roles and type(config.roles) ~= "table" then
		config.roles = CopyAnchorLayoutRoles(callbackEntry.roles)
	end

	return config
end

local function RemoveAnchorLayoutCallbackOrder(addOnName)
	for index = #SCM.AnchorLayoutCallbackOrder, 1, -1 do
		if SCM.AnchorLayoutCallbackOrder[index] == addOnName then
			tremove(SCM.AnchorLayoutCallbackOrder, index)
		end
	end
end

function SCM:RegisterAnchorLayoutCallback(addOnName, callback, callbackOptions, override)
	if type(addOnName) ~= "string" or addOnName == "" or type(callback) ~= "function" then
		return false
	end

	local callbacks = self.AnchorLayoutCallbacks
	if callbacks[addOnName] and not override then
		return false
	end

	callbackOptions = type(callbackOptions) == "table" and callbackOptions or {}

	if not callbacks[addOnName] then
		tinsert(self.AnchorLayoutCallbackOrder, addOnName)
	end

	callbacks[addOnName] = {
		activeGroups = {},
		callback = callback,
		defaultEnabled = callbackOptions.defaultEnabled ~= false,
		displayName = callbackOptions.displayName or addOnName,
		groups = NormalizeAnchorLayoutGroups(callbackOptions.groups or callbackOptions.group),
		roles = CopyAnchorLayoutRoles(callbackOptions.roles),
	}

	GetAnchorLayoutCallbackConfig(addOnName, callbacks[addOnName])

	for group, state in pairs(self.AnchorLayoutState) do
		self:NotifyAnchorLayoutCallback(addOnName, callbacks[addOnName], group, state)
	end

	return true
end

function SCM:UnregisterAnchorLayoutCallback(addOnName)
	local callbacks = self.AnchorLayoutCallbacks
	local callbackEntry = callbacks[addOnName]
	if not callbackEntry then
		return false
	end

	for group, state in pairs(self.AnchorLayoutState) do
		self:NotifyAnchorLayoutCallback(addOnName, callbackEntry, group, state, false)
	end

	callbacks[addOnName] = nil
	RemoveAnchorLayoutCallbackOrder(addOnName)
	return true
end

function SCM:GetAnchorLayoutCallbacks()
	return self.AnchorLayoutCallbacks, self.AnchorLayoutCallbackOrder
end

function SCM:IsAnchorLayoutCallbackEnabled(addOnName)
	local callbackEntry = self.AnchorLayoutCallbacks[addOnName]
	if not callbackEntry then
		return false
	end

	local config = GetAnchorLayoutCallbackConfig(addOnName, callbackEntry)
	if not config then
		return callbackEntry.defaultEnabled
	end

	return config.enabled and true or false
end

function SCM:GetAnchorLayoutCallbackRoles(addOnName)
	local callbackEntry = self.AnchorLayoutCallbacks[addOnName]
	if not (callbackEntry and callbackEntry.roles) then
		return
	end

	local config = GetAnchorLayoutCallbackConfig(addOnName, callbackEntry)
	return config and config.roles or callbackEntry.roles
end

function SCM:IsAnchorLayoutCallbackRoleEnabled(addOnName)
	local callbackEntry = self.AnchorLayoutCallbacks[addOnName]
	if not callbackEntry then
		return false
	end
	if not callbackEntry.roles then
		return true
	end

	local roles = self:GetAnchorLayoutCallbackRoles(addOnName)
	local currentRole = select(5, Utils.GetSpec())
	return roles and roles[currentRole] == true or false
end

function SCM:SetAnchorLayoutCallbackEnabled(addOnName, enabled)
	local callbackEntry = self.AnchorLayoutCallbacks[addOnName]
	if not callbackEntry then
		return false
	end

	local config = GetAnchorLayoutCallbackConfig(addOnName, callbackEntry)
	if config then
		config.enabled = enabled and true or false
	end

	if not enabled then
		for group, state in pairs(self.AnchorLayoutState) do
			self:NotifyAnchorLayoutCallback(addOnName, callbackEntry, group, state, false)
		end
	else
		for group, state in pairs(self.AnchorLayoutState) do
			self:NotifyAnchorLayoutCallback(addOnName, callbackEntry, group, state)
		end
	end

	return true
end

function SCM:SetAnchorLayoutCallbackRoleEnabled(addOnName, role, enabled)
	local callbackEntry = self.AnchorLayoutCallbacks[addOnName]
	if not (callbackEntry and callbackEntry.roles) then
		return false
	end

	local config = GetAnchorLayoutCallbackConfig(addOnName, callbackEntry)
	if not config then
		return false
	end

	config.roles[role] = enabled and true or false
	for group, state in pairs(self.AnchorLayoutState) do
		self:NotifyAnchorLayoutCallback(addOnName, callbackEntry, group, state)
	end

	return true
end

function SCM:NotifyAnchorLayoutCallback(addOnName, callbackEntry, group, state, enabled)
	if not callbackEntry or not state then
		return
	end

	if enabled == nil then
		enabled = self:IsAnchorLayoutCallbackEnabled(addOnName) and self:IsAnchorLayoutCallbackRoleEnabled(addOnName)
	end

	local groups = callbackEntry.groups
	if enabled and groups and not groups[group] then
		return
	end

	local activeGroups = callbackEntry.activeGroups
	if not enabled and not activeGroups[group] then
		return
	end

	local ok, err = pcall(
		callbackEntry.callback,
		group,
		state.anchorFrame,
		state.effectiveWidth,
		state.effectiveHeight,
		state.rowConfig,
		state.options,
		enabled
	)

	activeGroups[group] = enabled and ok or nil
	callbackEntry.lastError = not ok and err or nil

	if not ok then
		self:Debug("Anchor layout callback failed", addOnName, err)
	end
end

function SCM:NotifyAnchorLayoutCallbacks(group, anchorFrame, effectiveWidth, effectiveHeight, rowConfig, options)
	local state = self.AnchorLayoutState[group]
	if not state then
		state = {}
		self.AnchorLayoutState[group] = state
	end

	state.anchorFrame = anchorFrame
	state.effectiveWidth = effectiveWidth
	state.effectiveHeight = effectiveHeight
	state.rowConfig = rowConfig
	state.options = options

	for _, addOnName in ipairs(self.AnchorLayoutCallbackOrder) do
		self:NotifyAnchorLayoutCallback(addOnName, self.AnchorLayoutCallbacks[addOnName], group, state)
	end
end

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

function SCM:UpdateUUFValues(options, maxGroupWidth, rowConfig)
	local offset = min((maxGroupWidth - 150), 0)
	local mainAnchor = SCM:GetAnchor(1)
	local height = floor((rowConfig[1].iconHeight or rowConfig[1].size) + 0.5) + options.anchorsHeightOffset

	if UUF_Player then
		if options.anchorUUF and options.anchorUUFRoles[(select(5, Utils.GetSpec()))] then
			if not UUF_Player.SCMOriginalAnchor then
				UUF_Player.SCMOriginalAnchor = { UUF_Player:GetPoint() }
				UUF_Player.SCMOriginalWidth = UUF_Player:GetWidth()
				UUF_Player.SCMOriginalHeight = UUF_Player:GetHeight()
			end
			UUF_Player:ClearAllPoints()

			mainAnchor.SetPoint(UUF_Player, "TOPRIGHT", mainAnchor, "TOPLEFT", offset - options.temporaryPadding, options.anchorsYOffset)

			UUF_Player.SCMOffset = offset - options.temporaryPadding
			UUF_Player.SCMYOffset = options.anchorsYOffset
			UUF_Player.SCMHeight = height
			UUF_Player.SCMAnchor = mainAnchor
			UUF_Player.SCMCustomAnchor = true

			if options.adjustHeight then
				UUF_Player:SetHeight(height)
				UUF_Player_HealthBar:SetHeight(height - 2)
				UUF_Player_HealthBackground:SetHeight(height - 2)

				if UUF_Player.HealthPrediction then
					if UUF_Player.HealthPrediction.healAbsorb then
						UUF_Player.HealthPrediction.healAbsorb:SetHeight(height - 2)
					end

					if UUF_Player.HealthPrediction.damageAbsorb then
						UUF_Player.HealthPrediction.damageAbsorb:SetHeight(height - 2)
					end
				end
			end

			if not UUF_Player.SCMHook then
				UUF_Player.SCMHook = true
				hooksecurefunc(UUF_Player, "SetPoint", function(self)
					if self.SCMAnchor and options.anchorUUF and options.anchorUUFRoles and options.anchorUUFRoles[(select(5, Utils.GetSpec()))] then
						self.SCMAnchor.SetPoint(self, "TOPRIGHT", self.SCMAnchor, "TOPLEFT", self.SCMOffset, self.SCMYOffset)
						if options.adjustHeight then
							self.SCMAnchor.SetHeight(self, self.SCMHeight)
							self.SCMAnchor.SetHeight(UUF_Player_HealthBar, self.SCMHeight - 2)
							self.SCMAnchor.SetHeight(UUF_Player_HealthBackground, self.SCMHeight - 2)

							if self.HealthPrediction then
								if self.HealthPrediction.healAbsorb then
									self.SCMAnchor.SetHeight(self.HealthPrediction.healAbsorb, self.SCMHeight - 2)
								end

								if self.HealthPrediction.damageAbsorb then
									self.SCMAnchor.SetHeight(self.HealthPrediction.damageAbsorb, self.SCMHeight - 2)
								end
							end
						end
					end
				end)

				hooksecurefunc(UUF_Player, "SetSize", function(self)
					if self.SCMAnchor and options.anchorUUF and options.anchorUUFRoles and options.anchorUUFRoles[(select(5, Utils.GetSpec()))] and options.adjustHeight then
						self.SCMAnchor.SetHeight(self, self.SCMHeight)
						self.SCMAnchor.SetHeight(UUF_Player_HealthBar, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Player_HealthBackground, self.SCMHeight - 2)

						if self.HealthPrediction then
							if self.HealthPrediction.healAbsorb then
								self.SCMAnchor.SetHeight(self.HealthPrediction.healAbsorb, self.SCMHeight - 2)
							end

							if self.HealthPrediction.damageAbsorb then
								self.SCMAnchor.SetHeight(self.HealthPrediction.damageAbsorb, self.SCMHeight - 2)
							end
						end
					end
				end)
			end
		elseif UUF_Player.SCMCustomAnchor then
			UUF_Player:ClearAllPoints()
			UUF_Player.SCMAnchor.SetPoint(UUF_Player, unpack(UUF_Player.SCMOriginalAnchor))
			UUF_Player.SCMAnchor.SetHeight(UUF_Player, UUF_Player.SCMOriginalHeight)
			UUF_Player.SCMAnchor.SetHeight(UUF_Player_HealthBar, UUF_Player.SCMOriginalHeight - 2)
			UUF_Player.SCMAnchor.SetHeight(UUF_Player_HealthBackground, UUF_Player.SCMOriginalHeight - 2)

			if UUF_Player.HealthPrediction then
				if UUF_Player.HealthPrediction.healAbsorb then
					UUF_Player.SCMAnchor.SetHeight(UUF_Player.HealthPrediction.healAbsorb, UUF_Player.SCMOriginalHeight - 2)
				end

				if UUF_Player.HealthPrediction.damageAbsorb then
					UUF_Player.SCMAnchor.SetHeight(UUF_Player.HealthPrediction.damageAbsorb, UUF_Player.SCMOriginalHeight - 2)
				end
			end

			UUF_Player.SCMCustomAnchor = nil
			UUF_Player.SCMOffset = nil
			UUF_Player.SCMHeight = nil
			UUF_Player.SCMAnchor = nil
			UUF_Player.SCMOriginalHeight = nil
			UUF_Player.SCMOriginalAnchor = nil
		end
	end

	if UUF_Target then
		if options.anchorUUF and options.anchorUUFRoles and options.anchorUUFRoles[(select(5, Utils.GetSpec()))] then
			if not UUF_Target.SCMOriginalAnchor then
				UUF_Target.SCMOriginalAnchor = { UUF_Target:GetPoint() }
				UUF_Target.SCMOriginalWidth = UUF_Target:GetWidth()
				UUF_Target.SCMOriginalHeight = UUF_Target:GetHeight()
			end

			UUF_Target:ClearAllPoints()
			mainAnchor.SetPoint(UUF_Target, "TOPLEFT", mainAnchor, "TOPRIGHT", -offset + options.temporaryPadding, options.anchorsYOffset)

			UUF_Target.SCMOffset = -offset + options.temporaryPadding
			UUF_Target.SCMYOffset = options.anchorsYOffset
			UUF_Target.SCMHeight = height
			UUF_Target.SCMAnchor = mainAnchor
			UUF_Target.SCMCustomAnchor = true

			if options.adjustHeight then
				UUF_Target:SetHeight(height)
				UUF_Target_HealthBar:SetHeight(height - 2)
				UUF_Target_HealthBackground:SetHeight(height - 2)
			end

			if not UUF_Target.SCMHook then
				UUF_Target.SCMHook = true
				hooksecurefunc(UUF_Target, "SetPoint", function(self)
					if self.SCMAnchor and options.anchorUUF and options.anchorUUFRoles and options.anchorUUFRoles[(select(5, Utils.GetSpec()))] then
						self.SCMAnchor.SetPoint(self, "TOPLEFT", self.SCMAnchor, "TOPRIGHT", self.SCMOffset, self.SCMYOffset)

						if options.adjustHeight then
							self.SCMAnchor.SetHeight(self, self.SCMHeight)
							self.SCMAnchor.SetHeight(UUF_Target_HealthBar, self.SCMHeight - 2)
							self.SCMAnchor.SetHeight(UUF_Target_HealthBackground, self.SCMHeight - 2)
						end
					end
				end)

				hooksecurefunc(UUF_Target, "SetSize", function(self)
					if self.SCMAnchor and options.anchorUUF and options.anchorUUFRoles and options.anchorUUFRoles[(select(5, Utils.GetSpec()))] and options.adjustHeight then
						self.SCMAnchor.SetHeight(self, self.SCMHeight)
						self.SCMAnchor.SetHeight(UUF_Target_HealthBar, self.SCMHeight - 2)
						self.SCMAnchor.SetHeight(UUF_Target_HealthBackground, self.SCMHeight - 2)
					end
				end)
			end
		elseif UUF_Target.SCMCustomAnchor then
			UUF_Target:ClearAllPoints()
			UUF_Target.SCMAnchor.SetPoint(UUF_Target, unpack(UUF_Target.SCMOriginalAnchor))

			if options.adjustHeight then
				UUF_Target.SCMAnchor.SetHeight(UUF_Target, UUF_Target.SCMOriginalHeight)
				UUF_Target.SCMAnchor.SetHeight(UUF_Target_HealthBar, UUF_Target.SCMOriginalHeight - 2)
				UUF_Target.SCMAnchor.SetHeight(UUF_Target_HealthBackground, UUF_Target.SCMOriginalHeight - 2)
			end

			UUF_Target.SCMCustomAnchor = nil
			UUF_Target.SCMOffset = nil
			UUF_Target.SCMHeight = nil
			UUF_Target.SCMAnchor = nil
			UUF_Target.SCMOriginalHeight = nil
			UUF_Target.SCMOriginalAnchor = nil
		end
	end

	if ElvUI then
		local E = ElvUI[1]
		if options.anchorElvUI then
			if E.db.movers then
				SCM.db.profile.options.elvUIAnchors["ElvUF_PlayerMover"] = SCM.db.profile.options.elvUIAnchors["ElvUF_PlayerMover"] or E.db.movers.ElvUF_PlayerMover
				E.db.movers.ElvUF_PlayerMover = string.format("TOPRIGHT,%s,TOPLEFT,%d,%d", mainAnchor:GetName(), -offset - options.temporaryPadding, options.anchorsYOffset)
				E:SetMoverPoints("ElvUF_PlayerMover")

				SCM.db.profile.options.elvUIAnchors["ElvUF_TargetMover"] = SCM.db.profile.options.elvUIAnchors["ElvUF_TargetMover"] or E.db.movers.ElvUF_TargetMover
				E.db.movers.ElvUF_TargetMover = string.format("TOPLEFT,%s,TOPRIGHT,%d,%d", mainAnchor:GetName(), offset + options.temporaryPadding, options.anchorsYOffset)
				E:SetMoverPoints("ElvUF_TargetMover")
			end

			if options.adjustHeight then
				E.db.unitframe.units.player.height = height
				E.db.unitframe.units.target.height = height
			end

			local UF = E:GetModule("UnitFrames")
			UF:Update_AllFrames()
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
