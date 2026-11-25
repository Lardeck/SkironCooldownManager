local SCM = select(2, ...)

local Utils = SCM.Utils
local Cache = SCM.Cache

local GLOBAL_GROUP_OFFSET = 100
local GLOBAL_BUFF_BAR_OFFSET = 200
local FIRST_GLOBAL_GROUP = GLOBAL_GROUP_OFFSET + 1
local FIRST_BUFF_BAR_GROUP = GLOBAL_BUFF_BAR_OFFSET + 1

local pendingAnchorVisibilityRegistrations = {}
local anchorVisibilityRefreshQueued
local visitedAnchorDependencies = {}

local function DependsOnAnchor(target, anchorFrame)
	if not target or visitedAnchorDependencies[target] then
		return false
	end

	if target == anchorFrame then
		return true
	end

	visitedAnchorDependencies[target] = true
	for index = 1, target:GetNumPoints() do
		if DependsOnAnchor(select(2, target:GetPoint(index)), anchorFrame) then
			return true
		end
	end

	return DependsOnAnchor(target:GetParent(), anchorFrame)
end

function Utils.IsAnchorDependentOn(target, anchorFrame)
	wipe(visitedAnchorDependencies)
	return DependsOnAnchor(target, anchorFrame)
end

function Utils.ToGlobalGroup(index)
	return GLOBAL_GROUP_OFFSET + (index or 1)
end

function Utils.ToBuffBarGroup(index)
	return GLOBAL_BUFF_BAR_OFFSET + (index or 1)
end

function Utils.IsGlobalGroup(group)
	return type(group) == "number" and group >= FIRST_GLOBAL_GROUP and group < FIRST_BUFF_BAR_GROUP
end

function Utils.IsBuffBarGroup(group)
	return type(group) == "number" and group >= FIRST_BUFF_BAR_GROUP
end

function Utils.ParseAnchorString(anchorString)
	if type(anchorString) ~= "string" then
		return
	end

	local parsedAnchorStrings = Cache.cachedParsedAnchorStrings
	local cachedAnchorGroup = parsedAnchorStrings[anchorString]

	if cachedAnchorGroup then
		return cachedAnchorGroup
	end

	if anchorString:sub(1, 7) ~= "ANCHOR:" then
		return
	end

	local anchorType, anchorID = anchorString:match("^ANCHOR:([%a]+):(%d+)$")

	if anchorType and anchorID then
		anchorID = tonumber(anchorID)

		if not anchorID or anchorID <= 0 then
			return
		end

		local anchorGroup
		anchorType = string.upper(anchorType)

		if anchorType == "I" then
			anchorGroup = anchorID
		elseif anchorType == "G" then
			anchorGroup = Utils.ToGlobalGroup(anchorID)
		elseif anchorType == "BB" then
			anchorGroup = Utils.ToBuffBarGroup(anchorID)
		end

		parsedAnchorStrings[anchorString] = anchorGroup

		return anchorGroup
	end

	anchorID = tonumber(anchorString:match("^ANCHOR:(%d+)$"))

	if not anchorID or anchorID <= 0 or anchorID == GLOBAL_GROUP_OFFSET or anchorID == GLOBAL_BUFF_BAR_OFFSET then
		return
	end

	parsedAnchorStrings[anchorString] = anchorID

	return anchorID
end

local function GetSingleAnchorFrame(anchorFrame)
	if anchorFrame:sub(1, 7) ~= "ANCHOR:" then
		return _G[anchorFrame] or SCM[anchorFrame]
	end

	local anchorGroup = Utils.ParseAnchorString(anchorFrame)

	if anchorGroup then
		return SCM:GetAnchor(anchorGroup)
	end
end

function Utils.GetAnchorFrame(anchorFrames)
	if type(anchorFrames) == "table" then
		return anchorFrames, anchorFrames
	end

	if type(anchorFrames) ~= "string" or anchorFrames == "" or anchorFrames == "NONE" then
		return
	end

	if anchorFrames:find(",", 1, true) then
		local fallbackFrame, fallbackRef

		for frameName in anchorFrames:gmatch("[^,]+") do
			local currentFrame = strtrim(frameName)
			local anchorFrame = currentFrame ~= "" and GetSingleAnchorFrame(currentFrame)

			if anchorFrame then
				if currentFrame:sub(1, 7) == "ANCHOR:" or anchorFrame:IsVisible() then
					return anchorFrame, currentFrame
				end

				fallbackFrame, fallbackRef = anchorFrame, currentFrame
			end
		end

		return fallbackFrame, fallbackRef
	end

	return GetSingleAnchorFrame(anchorFrames), anchorFrames
end

function Utils.GetActiveAnchorFrame(anchorFrames)
	local anchorFrame, selectedAnchorFrame = Utils.GetAnchorFrame(anchorFrames)

	if type(selectedAnchorFrame) ~= "string" or selectedAnchorFrame:sub(1, 7) ~= "ANCHOR:" then
		return anchorFrame, selectedAnchorFrame
	end

	local anchorGroup = Utils.ParseAnchorString(selectedAnchorFrame)
	local state = anchorGroup and Cache.cachedAnchorStates[anchorGroup]
	local proxy = state and state.currentProxyActive and state.currentProxyFrame

	if proxy and proxy:IsShown() then
		return proxy, selectedAnchorFrame, anchorGroup
	end

	return anchorFrame, selectedAnchorFrame, anchorGroup
end

local function RefreshAnchorVisibilitySelection(owner)
	local registration = owner.SCMAnchorVisibility
	if not registration then
		return
	end

	local selectedFrame, selectedRef = Utils.GetAnchorFrame(registration.anchor)

	if registration.selectedFrame ~= selectedFrame or registration.selectedRef ~= selectedRef then
		registration.selectedFrame = selectedFrame
		registration.selectedRef = selectedRef

		registration.callback(owner, selectedRef)
	end
end

local function OnAnchorVisibilityChanged(frame)
	for owner in pairs(frame.SCMAnchorVisibilityObservers) do
		SCM:RequestLayoutUpdate(owner, RefreshAnchorVisibilitySelection)
	end
end

local function WatchAnchorCandidates(owner, registration)
	registration.hasMissingFrames = nil

	for frameName in registration.anchor:gmatch("[^,]+") do
		local anchorName = strtrim(frameName)
		local target = anchorName ~= "" and GetSingleAnchorFrame(anchorName)

		if anchorName ~= "" and anchorName ~= "NONE" and not target then
			registration.hasMissingFrames = true
		end

		while target and target ~= UIParent do
			if target ~= owner and target.HookScript and not registration.frames[target] then
				registration.frames[target] = true

				if not target.SCMAnchorVisibilityObservers then
					target.SCMAnchorVisibilityObservers = {}
					target:HookScript("OnShow", OnAnchorVisibilityChanged)
					target:HookScript("OnHide", OnAnchorVisibilityChanged)
				end

				target.SCMAnchorVisibilityObservers[owner] = registration
			end

			local parent = target:GetParent()

			if parent == target then
				break
			end

			target = parent
		end
	end
end

local function RefreshPendingAnchorVisibilityRegistrations()
	anchorVisibilityRefreshQueued = nil

	for owner, registration in pairs(pendingAnchorVisibilityRegistrations) do
		pendingAnchorVisibilityRegistrations[owner] = nil

		WatchAnchorCandidates(owner, registration)
		SCM:RequestLayoutUpdate(owner, RefreshAnchorVisibilitySelection)
	end
end

function Utils.UnregisterAnchorVisibility(frame)
	local registration = frame.SCMAnchorVisibility

	if not registration then
		return
	end

	for target in pairs(registration.frames) do
		target.SCMAnchorVisibilityObservers[frame] = nil
	end

	frame.SCMAnchorVisibility = nil
	pendingAnchorVisibilityRegistrations[frame] = nil
end

-- Call beside anchor resolution; callbacks receive the owner and selected reference when selection changes.
function Utils.RegisterAnchorVisibility(frame, anchor, callback)
	local registration = frame.SCMAnchorVisibility

	if registration and registration.anchor == anchor then
		return
	end

	Utils.UnregisterAnchorVisibility(frame)

	if type(anchor) ~= "string" or not anchor:find(",", 1, true) then
		return
	end

	local selectedFrame, selectedRef = Utils.GetAnchorFrame(anchor)

	registration = {
		anchor = anchor,
		callback = callback,
		selectedFrame = selectedFrame,
		selectedRef = selectedRef,
		frames = {},
	}

	frame.SCMAnchorVisibility = registration

	WatchAnchorCandidates(frame, registration)

	-- Other addon frames may be created later in the same initialization pass.
	if registration.hasMissingFrames then
		pendingAnchorVisibilityRegistrations[frame] = registration

		if not anchorVisibilityRefreshQueued then
			anchorVisibilityRefreshQueued = true

			RunNextFrame(RefreshPendingAnchorVisibilityRegistrations)
		end
	end
end

function Utils.NormalizeBuffBarGroup(group)
	group = tonumber(group)

	if not group or group <= 0 or group == GLOBAL_GROUP_OFFSET or group == GLOBAL_BUFF_BAR_OFFSET then
		return
	end

	if group >= FIRST_BUFF_BAR_GROUP then
		return group
	end

	if group >= FIRST_GLOBAL_GROUP then
		return Utils.ToBuffBarGroup(group - GLOBAL_GROUP_OFFSET)
	end

	return Utils.ToBuffBarGroup(group)
end

function Utils.GetAnchorConfigForGroup(config, anchorIndex, isGlobal, isBuffBar)
	local options = SCM.db and SCM.db.profile and SCM.db.profile.options

	if isGlobal then
		local globalAnchorConfig = (config and config.globalAnchorConfig) or SCM.globalAnchorConfig

		return globalAnchorConfig and globalAnchorConfig[anchorIndex]
	end

	local configKey = isBuffBar and "buffBarsAnchorConfig" or "anchorConfig"
	local anchorConfig = config and config[configKey] and config[configKey][anchorIndex]
	local profileAnchorConfig = options and options[configKey]

	if anchorConfig and anchorConfig.useGlobalProfileConfig and profileAnchorConfig and profileAnchorConfig[anchorIndex] then
		return profileAnchorConfig[anchorIndex]
	end

	return anchorConfig
end

function Utils.EnsureProfileAnchorConfig(options, configKey, anchorIndex, anchorConfig)
	local profileAnchors = GetOrCreateTableEntry(options, configKey)
	if not profileAnchors[anchorIndex] then
		local sharedAnchor = CopyTable(anchorConfig)
		sharedAnchor.useGlobalProfileConfig = nil
		profileAnchors[anchorIndex] = sharedAnchor
	end
end

function Utils.GetAnchorConfigForLayoutGroup(config, group)
	if Utils.IsGlobalGroup(group) then
		return Utils.GetAnchorConfigForGroup(config, group - GLOBAL_GROUP_OFFSET, true)
	end

	if Utils.IsBuffBarGroup(group) then
		return Utils.GetAnchorConfigForGroup(config, group - GLOBAL_BUFF_BAR_OFFSET, nil, true)
	end

	return Utils.GetAnchorConfigForGroup(config, group)
end
