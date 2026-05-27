local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local CDM = SCM.CDM
local Cache = SCM.Cache
local Icons = SCM.Icons
local Utils = SCM.Utils
local GetIconType = Utils.GetIconType
local ResetChildSCMState = Utils.ResetChildSCMState
local ToGlobalGroup = Utils.ToGlobalGroup

local CustomItemFrames = {}
local CustomSpellFrames = {}
local CustomIconFramePool
local ShouldShowCustomIcon

function CustomIcons.GetCustomIconFrames(config)
	local iconType = GetIconType(config)
	if not iconType then
		return
	end

	if iconType == "spell" or iconType == "timer" then
		return CustomSpellFrames
	end

	return CustomItemFrames
end

local function ResetCustomIconFrame(_, frame)
	local customFrames = frame.SCMFrameRegistry
	local frameID = frame.SCMFrameID
	ResetChildSCMState(frame)

	if customFrames and frameID and customFrames[frameID] == frame then
		customFrames[frameID] = nil
	end

	frame.SCMReleased = true
	frame.SCMFrameRegistry = nil
	frame.SCMFrameID = nil
	frame.SCMSkinned = nil
	frame.spellID = nil
	frame.SCMItemID = nil
	frame.slotID = nil
	frame.lastCastStartTime = nil
	frame.UpdateCooldown = nil
	frame.UpdateCharges = nil
	frame.height = nil
	frame.isOnCooldown = nil
	frame.isOnGCD = nil
	frame.spellOutOfRange = nil
	frame.SCMCooldownStartTime = nil
	frame.SCMCooldownDuration = nil

	frame:EnableMouse(false)
	frame:SetAlpha(1)
	frame:Hide()
	frame:ClearAllPoints()
	frame.OutOfRange:Hide()
	frame.Icon:SetVertexColor(1, 1, 1, 1)
	frame.Icon:SetDesaturated(false)
	frame.Icon:SetTexture(nil)
	frame.Icon:SetTexelSnappingBias(0)
	frame.Icon:SetSnapToPixelGrid(false)
	frame.CraftQuality:Hide()
	frame.CraftQuality:SetTexture(nil)
	frame.CraftQuality:SetTexelSnappingBias(0)
	frame.CraftQuality:SetSnapToPixelGrid(false)
	frame.Cooldown:Clear()
	frame.Cooldown:SetReverse(false)
	frame.GCDCooldown:Clear()
	frame.GCDCooldown:Hide()
	frame.GCDCooldown:SetReverse(true)
	frame.ChargeCount.Current:SetText("")
	frame.ChargeCount.Current:Hide()
end

local function GetCustomIconFramePool()
	if not CustomIconFramePool then
		CustomIconFramePool = CreateFramePool("Frame", UIParent, "SCMItemIconTemplate", ResetCustomIconFrame)
	end

	return CustomIconFramePool
end

local function OnIconCooldownDone(self)
	local parent = self:GetParent()
	if not parent or parent.SCMReleased or not parent.SCMConfig then
		return
	end

	if parent.Icon then
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
	end

	if parent.UpdateCooldown then
		parent.isOnGCD = nil
		parent.UpdateCooldown(parent, parent.SCMIconType, parent.SCMConfig)
	end

	if parent.UpdateCharges then
		parent.UpdateCharges(parent, parent.spellID)
	end

	if parent and parent.SCMGroup then
		SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, parent.SCMGlobal, CDM.UPDATE_SCOPE.ESSENTIAL_UTILITY)
	end
end

local function OnCustomIconShow(self)
	if self:GetAttribute("statehidden") then
		return
	end

	if self.SCMShouldBeVisible and not self.SCMLayoutApplied then
		self.SCMAppliedVisibility = false
		self:Hide()
		return
	end

	if self.SCMIconType == "empty" then
		return
	end

	if not ShouldShowCustomIcon(self.SCMConfig, self.SCMIconType, nil, nil, self) then
		Icons.SetChildVisibilityState(self, false, true)
	end
end

local function AcquireCustomIconFrame(customFrames, id)
	local frame = customFrames[id]
	if frame and not frame.SCMReleased then
		return frame
	end

	frame = GetCustomIconFramePool():Acquire()
	frame.SCMReleased = nil
	frame.SCMFrameRegistry = customFrames
	frame.SCMFrameID = id
	frame.SCMShouldBeVisible = true
	customFrames[id] = frame

	if not frame.SCMCustomIconInitialized then
		frame.Cooldown:SetScript("OnCooldownDone", OnIconCooldownDone)
		frame.GCDCooldown:SetScript("OnCooldownDone", OnIconCooldownDone)
		frame.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
		frame.Icon:SetTexelSnappingBias(0)
		frame.Icon:SetSnapToPixelGrid(false)
		frame.CraftQuality:SetTexelSnappingBias(0)
		frame.CraftQuality:SetSnapToPixelGrid(false)
		frame.OutOfRange:SetTexelSnappingBias(0)
		frame.OutOfRange:SetSnapToPixelGrid(false)
		frame:HookScript("OnShow", OnCustomIconShow)
		frame.SCMCustomIconInitialized = true
	end

	return frame
end

local function ReleaseCustomIconFrame(frame)
	if not frame or frame.SCMReleased then
		return
	end

	Icons.SetChildVisibilityState(frame, false, true)
	GetCustomIconFramePool():Release(frame)
end

local function GetCustomItemID(config)
	local itemID = config.itemID
	if C_Item.GetItemCount(itemID, false, true) > 0 then
		return itemID
	end

	local customItems = config.customItems
	if customItems then
		for i = 1, #customItems do
			local customItemID = customItems[i]
			if C_Item.GetItemCount(customItemID, false, true) > 0 then
				return customItemID
			end
		end
	end

	return itemID
end

local function SetCustomItemID(frame, config)
	local itemID = GetCustomItemID(config)
	frame.SCMItemID = itemID
	frame.SCMSpellID = select(2, C_Item.GetItemSpell(itemID))
	config.spellID = frame.SCMSpellID
	return itemID
end

local function CacheCustomItemEntry(itemID, id, config, isGlobal)
	local entries = Cache.cachedCustomItemEntriesByItemID[itemID]
	if not entries then
		entries = {}
		Cache.cachedCustomItemEntriesByItemID[itemID] = entries
	end

	tinsert(entries, {
		id = id,
		config = config,
		isGlobal = isGlobal and true or nil,
	})
end

local function RequestCustomItemDataLoad(itemID, requestedItemIDs)
	if not requestedItemIDs[itemID] then
		requestedItemIDs[itemID] = true
		C_Item.RequestLoadItemDataByID(itemID)
	end
end

local function SetCustomIconCountText(frame, iconType, config)
	if iconType == "spell" or iconType == "slot" or iconType == "timer" then
		frame.ChargeCount.Current:SetText("")
		frame.ChargeCount.Current:Hide()
		return
	end

	local itemID = frame.SCMItemID

	local count = C_Item.GetItemCount(itemID, false, true)
	if not config.hideStackText then
		frame.ChargeCount.Current:SetText(count)
		frame.ChargeCount.Current:Show()
	else
		frame.ChargeCount.Current:SetText("")
	end

	if count <= 0 then
		frame.Icon:SetVertexColor(0.4, 0.4, 0.4)
		return
	end

	if not frame.isOnCooldown then
		frame.Icon:SetVertexColor(1, 1, 1)
		frame.Icon:SetDesaturated(false)
	end

	return true
end

local function UpdateCustomIconCraftQuality(frame, iconType, config)
	local craftQuality = frame.CraftQuality
	craftQuality:Hide()
	craftQuality:SetTexture(nil)
	craftQuality:SetTexelSnappingBias(0)
	craftQuality:SetSnapToPixelGrid(false)

	if iconType ~= "item" or not config.showCraftQuality then
		return
	end

	local itemID = frame.SCMItemID

	Utils.ApplyCraftQuality(craftQuality, itemID)
end

local desaturationCurve = C_CurveUtil.CreateCurve()
desaturationCurve:SetType(Enum.LuaCurveType.Step)
desaturationCurve:AddPoint(0, 0)
desaturationCurve:AddPoint(0.001, 1)

local alphaCurve = C_CurveUtil.CreateCurve()
alphaCurve:SetType(Enum.LuaCurveType.Step)
alphaCurve:AddPoint(0, 0)
alphaCurve:AddPoint(0.001, 0.7)

local function UpdateCustomIconGlow(frame, isActive)
	if not frame or not frame.SCMConfig then
		return
	end

	if frame.SCMConfig.glowWhileActive and isActive then
		if not frame.SCMGlowWhileActive then
			frame.SCMGlowWhileActive = true
			SCM:StartCustomGlow(frame)
		end
	elseif frame.SCMConfig.glowWhileInactive and not isActive then
		if not frame.SCMGlowWhileActive then
			frame.SCMGlowWhileActive = true
			SCM:StartCustomGlow(frame)
		end
	elseif frame.SCMGlowWhileActive then
		frame.SCMGlowWhileActive = nil
		SCM:StopCustomGlow(frame)
	end
end

local function GetActiveCustomTimer(frame, iconType, config, now)
	local duration
	if iconType == "spell" or iconType == "timer" then
		duration = config.duration
	end

	if not duration or duration <= 0 then
		return
	end

	local startTime = frame.lastCastStartTime
	if not startTime then
		return
	end

	if startTime + duration > now then
		return startTime, duration
	end

	frame.lastCastStartTime = nil
end

local function UpdateCustomIconGCD(frame, config, isOnCooldown)
	if isOnCooldown or frame.Cooldown:IsShown() or not config.showGCD then
		frame.GCDCooldown:Hide()
		return
	end

	local globalCooldown = C_Spell.GetSpellCooldown(61304)
	if globalCooldown and globalCooldown.isActive then
		frame.GCDCooldown:Show()
		frame.GCDCooldown:SetReverse(false)
		frame.GCDCooldown:SetCooldown(globalCooldown.startTime, globalCooldown.duration)
	else
		frame.GCDCooldown:Hide()
	end
end

local function UpdateCustomIconCooldown(frame, iconType, config)
	local now = GetTime()
	local customTimerStart, customTimerDuration = GetActiveCustomTimer(frame, iconType, config, now)
	if customTimerStart then
		frame.Cooldown:SetCooldown(customTimerStart, customTimerDuration)
		frame.Cooldown:SetReverse(true)
		frame.Icon:SetDesaturated(false)
		UpdateCustomIconGCD(frame, config, true)
		UpdateCustomIconGlow(frame, true)
		return true
	end

	if iconType == "spell" then
		local isOnCooldown = false
		local spellCooldown = C_Spell.GetSpellCooldown(config.spellID)
		if spellCooldown.isActive and not spellCooldown.isOnGCD then
			local durationObject = C_Spell.GetSpellCooldownDuration(config.spellID, true)

			frame.Icon:SetDesaturated(true)
			frame.Cooldown:SetDrawEdge(false)
			frame.Cooldown:SetSwipeColor(0, 0, 0, 0.7)
			frame.Cooldown:SetCooldownFromDurationObject(durationObject)
			frame.Icon:SetDesaturation(C_CurveUtil.EvaluateColorValueFromBoolean(durationObject:IsZero(), 0, 1))
			isOnCooldown = true
		end

		spellCooldown = C_Spell.GetSpellCharges(config.spellID)

		if not isOnCooldown and spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
			frame.Cooldown:SetCooldownFromDurationObject(C_Spell.GetSpellChargeDuration(config.spellID, true))
			frame.Icon:SetDesaturated(false)
			frame.Cooldown:SetDrawEdge(true)
			frame.Cooldown:SetSwipeColor(0, 0, 0, 0)
			isOnCooldown = true
		end

		if not isOnCooldown then
			frame.Cooldown:Clear()
			frame.Icon.SCMDesaturated = nil
			frame.Icon:SetDesaturated(false)
		end

		if not isOnCooldown and (not spellCooldown or not spellCooldown.isActive or spellCooldown.isOnGCD) and config.showGCD then
			local globalCooldown = C_Spell.GetSpellCooldown(61304)

			if globalCooldown.isActive then
				frame.GCDCooldown:Show()
				frame.GCDCooldown:SetReverse(false)
				frame.GCDCooldown:SetCooldown(globalCooldown.startTime, globalCooldown.duration)
			end
		else
			frame.GCDCooldown:Hide()
		end

		UpdateCustomIconGlow(frame, false)
		return isOnCooldown
	end

	if iconType == "item" then
		local itemID = frame.SCMItemID
		--local count = C_Item.GetItemCount(itemID, false, true)
		local startTime, duration, _, modRate = C_Item.GetItemCooldown(itemID)

		if duration > 0 and (startTime + duration) - GetTime() >= 0 then
			if not frame.isOnCooldown or frame.SCMCooldownStartTime ~= startTime or frame.SCMCooldownDuration ~= duration then
				if duration < 0.1 then
					frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_USABLE_COLOR:GetRGBA())
					frame.Icon:SetDesaturated(false)
				else
					if modRate then
						frame.Cooldown:SetCooldown(startTime, duration, modRate)
					else
						frame.Cooldown:SetCooldown(startTime, duration)
					end

					frame.Icon:SetVertexColor(1, 1, 1)
					frame.Icon:SetDesaturated(true)
				end
				frame.isOnCooldown = true
				frame.SCMCooldownStartTime = startTime
				frame.SCMCooldownDuration = duration
				UpdateCustomIconGCD(frame, config, true)
				UpdateCustomIconGlow(frame, false)
			end

			return true
		elseif duration == 0 and frame.isOnCooldown then
			frame.isOnCooldown = false
			frame.SCMCooldownStartTime = nil
			frame.SCMCooldownDuration = nil
			frame.Cooldown:Clear()
			frame.Icon:SetVertexColor(1, 1, 1)
			frame.Icon:SetDesaturated(false)
			UpdateCustomIconGCD(frame, config, true)
			UpdateCustomIconGlow(frame, false)
		end
		return
	end

	if iconType == "slot" and config.slotID then
		local startTime, duration = GetInventoryItemCooldown("player", config.slotID)
		if startTime and startTime > 0 and (startTime + duration) - GetTime() >= 0.1 then
			frame.Cooldown:SetCooldown(startTime, duration)

			local globalCooldown = C_Spell.GetSpellCooldown(61304)
			frame.Icon:SetDesaturated(not (duration == globalCooldown.duration))

			UpdateCustomIconGCD(frame, config, true)
			UpdateCustomIconGlow(frame, false)
			return true
		end
	end

	frame.Cooldown:Clear()
	frame.Icon:SetVertexColor(1, 1, 1)
	frame.Icon:SetDesaturated(false)
	UpdateCustomIconGCD(frame, config, iconType == "timer")
	UpdateCustomIconGlow(frame, false)
end

local function UpdateCustomIconCharges(frame, spellID)
	if not spellID then
		return
	end

	local chargeInfo = C_Spell.GetSpellCharges(spellID)
	if not chargeInfo and not frame.SCMConfig.forceShowCharges then
		frame.ChargeCount.Current:Hide()
		return
	end

	local success, charges = pcall(C_StringUtil.TruncateWhenZero, chargeInfo and C_Spell.GetSpellDisplayCount(spellID) or C_Spell.GetSpellCastCount(spellID))
	if success then
		frame.ChargeCount.Current:SetText(charges)
		frame.ChargeCount.Current:Show()
	else
		frame.ChargeCount.Current:Hide()
	end
end

local function UpdateSpellUsesForEntries(entries)
	if not entries then
		return
	end

	for i = 1, #entries do
		local entry = entries[i]
		local frame = CustomSpellFrames[entry.id]
		local updateCharges = frame and not frame.SCMReleased and frame.UpdateCharges
		if updateCharges then
			updateCharges(frame, entry.config.spellID)
		end
	end
end

function CustomIcons.UpdateSpellUses(spellID, baseSpellID)
	local entriesBySpellID = Cache.cachedCustomSpellEntriesBySpellID

	UpdateSpellUsesForEntries(entriesBySpellID[spellID])

	if baseSpellID and baseSpellID ~= spellID then
		UpdateSpellUsesForEntries(entriesBySpellID[baseSpellID])
	end
end

function CustomIcons.UpdateSpellGlow(spellID, event)
	local entriesBySpellID = Cache.cachedCustomSpellEntriesBySpellID[spellID]

	if not entriesBySpellID then
		for baseSpellID, entries in pairs(Cache.cachedCustomSpellEntriesBySpellID) do
			if C_Spell.GetOverrideSpell(baseSpellID) == spellID then
				entriesBySpellID = entries
			end
		end

		if not entriesBySpellID then
			return
		end
	end

	for i = 1, #entriesBySpellID do
		local entry = entriesBySpellID[i]
		local frame = CustomSpellFrames[entry.id]
		if frame and not frame.SCMReleased then
			if event == "SHOW" then
				SCM:StartCustomGlow(frame)
			else
				SCM:StopCustomGlow(frame)
			end
		end
	end
end

local function DoesItemOrSpellExists(config)
	local iconType = GetIconType(config)
	if iconType == "empty" then
		return true
	end

	if iconType == "spell" or iconType == "timer" then
		return config.spellID and C_Spell.DoesSpellExist(config.spellID)
	end

	if iconType == "item" then
		return config.itemID and C_Item.DoesItemExistByID(config.itemID)
	end

	if iconType == "slot" then
		if config.alwaysShow then
			return true
		elseif config.slotID then
			local itemID = GetInventoryItemID("player", config.slotID)
			if itemID and (not config.filterItems or not config.filterItems[itemID]) then
				return C_Item.DoesItemExistByID(itemID) and C_Item.GetItemSpell(itemID)
			end
		end
	end
end

local function GetSlotSpellID(config)
	if config.slotID then
		local itemID = GetInventoryItemID("player", config.slotID)
		if itemID then
			return C_Item.DoesItemExistByID(itemID) and select(2, C_Item.GetItemSpell(itemID))
		end
	end
end

function CustomIcons.GetDefaultLoadClasses()
	local loadClasses = {}
	for classFile in pairs(SCM.Utils.GetClassList(false)) do
		loadClasses[classFile] = false
	end
	return loadClasses
end

function CustomIcons.GetDefaultLoadRaces()
	local loadRaces = {}
	for raceID in pairs(SCM.Constants.Races) do
		loadRaces[raceID] = false
	end
	return loadRaces
end

local function MatchesLoadFilter(loadFilter, value)
	if loadFilter then
		if not next(loadFilter) then
			return false
		end

		return loadFilter[value]
	end

	return true
end

local function ShouldLoadCustomIcon(config)
	if config.useLoadRole and not MatchesLoadFilter(config.loadRoles, SCM.currentRole) then
		return false
	end

	if config.useLoadClass and not MatchesLoadFilter(config.loadClasses, SCM.currentClass) then
		return false
	end

	if config.useLoadRace and not MatchesLoadFilter(config.loadRaces, SCM.currentRace) then
		return false
	end

	if config.useSpellKnown and (not config.spellKnownSpellID or type(config.spellKnownSpellID) ~= "number" or not C_SpellBook.IsSpellKnown(config.spellKnownSpellID)) then
		return false
	end

	return true
end

local function GetCustomIconTexture(config, iconType, frame)
	if (iconType == "spell" or iconType == "timer") and config.spellID then
		return C_Spell.GetSpellTexture(config.spellID)
	end

	if iconType == "item" then
		return C_Item.GetItemIconByID(frame.SCMItemID)
	end

	if iconType == "slot" and config.slotID then
		local itemID = GetInventoryItemID("player", config.slotID)
		if itemID then
			return C_Item.GetItemIconByID(itemID)
		end
		return GetInventoryItemTexture("player", config.slotID)
	end
end

function ShouldShowCustomIcon(config, iconType, hasCount, isOnCooldown, frame)
	if not config then
		return
	end

	if SCM.isOptionsOpen or config.alwaysShow then
		return true
	end

	hasCount = hasCount == nil and frame and SetCustomIconCountText(frame, iconType, config) or hasCount
	isOnCooldown = isOnCooldown == nil and frame and UpdateCustomIconCooldown(frame, iconType, config) or isOnCooldown

	if iconType == "timer" then
		return isOnCooldown and true or false
	end

	local canShowIcon = iconType == "spell" or iconType == "slot" or hasCount
	return canShowIcon and (not config.hideWhenNotOnCooldown or isOnCooldown)
end

local function ConfigureCustomIconFrame(frame, id, config, viewerScale, anchorGroup, isGlobal)
	frame:SetScale(viewerScale)

	frame.SCMConfig = config
	frame.SCMOrder = config.order
	frame.SCMCooldownID = id
	frame.SCMIconType = GetIconType(config)
	frame.SCMGroup = anchorGroup
	frame.SCMGlobal = isGlobal and true or nil
	frame.SCMCustom = true

	if frame.SCMIconType == "item" then
		SetCustomItemID(frame, config)
	elseif config.slotID then
		frame.SCMSpellID = GetSlotSpellID(config) or nil
		config.spellID = frame.SCMSpellID
	else
		frame.SCMSpellID = config.spellID
	end
end

local function UpdateCustomIconFrameState(frame, config)
	local iconType = frame.SCMIconType
	if iconType == "empty" then
		return
	end

	local iconTexture = GetCustomIconTexture(config, iconType, frame)
	if not iconTexture then
		iconTexture = 134400
	end

	frame.SCMIconTexture = iconTexture
	frame.Icon:SetTexture(iconTexture)
	frame.Icon:SetTexelSnappingBias(0)
	frame.Icon:SetSnapToPixelGrid(false)
	frame.UpdateCooldown = UpdateCustomIconCooldown
	frame.UpdateCharges = nil
	UpdateCustomIconCraftQuality(frame, iconType, config)

	if iconType == "spell" then
		local chargeInfo = C_Spell.GetSpellCharges(config.spellID)
		UpdateCustomIconCharges(frame, config.spellID)

		if chargeInfo or frame.SCMConfig.forceShowCharges then
			frame.UpdateCharges = UpdateCustomIconCharges
		end
	elseif iconType ~= "item" then
		frame.ChargeCount.Current:SetText("")
		frame.ChargeCount.Current:Hide()
	end
end

local function ApplyGlobalSettings(frame)
	if not InCombatLockdown() then
		RegisterAttributeDriver(frame, "state-visibility", SCM:GetVisibilityConditions(SCM.db.profile.options))
	end
end

function CustomIcons.HideIcons()
	for _, customFrame in pairs(CustomItemFrames) do
		Icons.SetChildVisibilityState(customFrame, false, true)
	end

	for _, customFrame in pairs(CustomSpellFrames) do
		Icons.SetChildVisibilityState(customFrame, false, true)
	end
end

function CustomIcons.ReleaseIcon(id, config)
	local customFrames = CustomIcons.GetCustomIconFrames(config)
	if customFrames and customFrames[id] then
		ReleaseCustomIconFrame(customFrames[id])
	end
end

function CustomIcons.ReleaseAllIcons()
	for _, customFrame in pairs(CustomItemFrames) do
		ReleaseCustomIconFrame(customFrame)
	end

	for _, customFrame in pairs(CustomSpellFrames) do
		ReleaseCustomIconFrame(customFrame)
	end
end

local function CacheCustomIconEntry(id, config, isGlobal, slotItemID)
	local iconType = GetIconType(config)
	if (iconType == "spell" or iconType == "timer") and config.spellID then
		local entries = Cache.cachedCustomSpellEntriesBySpellID[config.spellID]
		if not entries then
			entries = {}
			Cache.cachedCustomSpellEntriesBySpellID[config.spellID] = entries
		end

		tinsert(entries, {
			id = id,
			config = config,
			isGlobal = isGlobal and true or nil,
		})
		return
	end

	if iconType == "item" then
		local primaryItemID = config.itemID
		CacheCustomItemEntry(primaryItemID, id, config, isGlobal)

		local customItems = config.customItems
		if customItems then
			for i = 1, #customItems do
				local itemID = customItems[i]
				if itemID ~= primaryItemID then
					CacheCustomItemEntry(itemID, id, config, isGlobal)
				end
			end
		end

		return
	end

	if iconType == "slot" and config.slotID then
		if not slotItemID then
			return
		end

		local entries = Cache.cachedCustomSlotEntriesByItemID[slotItemID]
		if not entries then
			entries = {}
			Cache.cachedCustomSlotEntriesByItemID[slotItemID] = entries
		end

		tinsert(entries, {
			id = id,
			config = config,
			isGlobal = isGlobal and true or nil,
		})
	end
end

local function RequestCustomIconDataLoad(config, requestedSpellIDs, requestedItemIDs, slotItemID)
	local iconType = GetIconType(config)
	if (iconType == "spell" or iconType == "timer") and config.spellID then
		if not requestedSpellIDs[config.spellID] then
			requestedSpellIDs[config.spellID] = true
			C_Spell.RequestLoadSpellData(config.spellID)
		end
		return
	end

	if iconType == "item" then
		local primaryItemID = config.itemID
		RequestCustomItemDataLoad(primaryItemID, requestedItemIDs)

		local customItems = config.customItems
		if customItems then
			for i = 1, #customItems do
				local itemID = customItems[i]
				if itemID ~= primaryItemID then
					RequestCustomItemDataLoad(itemID, requestedItemIDs)
				end
			end
		end
		return
	end

	if iconType == "slot" and slotItemID then
		RequestCustomItemDataLoad(slotItemID, requestedItemIDs)
	end
end

local function RebuildCustomIconLoadCache()
	local customIconRequests = Cache.customIconRequests
	customIconRequests.requestedSpellIDs = customIconRequests.requestedSpellIDs or {}
	customIconRequests.requestedItemIDs = customIconRequests.requestedItemIDs or {}
	local requestedSpellIDs = customIconRequests.requestedSpellIDs
	local requestedItemIDs = customIconRequests.requestedItemIDs
	wipe(requestedSpellIDs)
	wipe(requestedItemIDs)

	wipe(Cache.cachedCustomSpellEntriesBySpellID)
	wipe(Cache.cachedCustomItemEntriesByItemID)
	wipe(Cache.cachedCustomSlotEntriesByItemID)
	for _, entries in pairs(Cache.cachedCustomIconsByGroup) do
		wipe(entries)
	end

	local function CacheCustomConfig(customConfig, isGlobal)
		if not customConfig then
			return
		end

		for id, config in pairs(customConfig) do
			local slotItemID = config.slotID and GetInventoryItemID("player", config.slotID) or nil
			local group = isGlobal and ToGlobalGroup(config.anchorGroup or 1) or (config.anchorGroup or 1)
			local groupEntries = Cache.cachedCustomIconsByGroup[group]
			if not groupEntries then
				groupEntries = {}
				Cache.cachedCustomIconsByGroup[group] = groupEntries
			end
			groupEntries[#groupEntries + 1] = id
			groupEntries[#groupEntries + 1] = config
			CacheCustomIconEntry(id, config, isGlobal, slotItemID)
			RequestCustomIconDataLoad(config, requestedSpellIDs, requestedItemIDs, slotItemID)
		end
	end

	for _, customConfig in pairs(SCM.customConfig) do
		CacheCustomConfig(customConfig, false)
	end

	for _, customConfig in pairs(SCM.globalCustomConfig) do
		CacheCustomConfig(customConfig, true)
	end
end

local function CreateCustomIcon(id, config, isGlobal, skipExisting)
	local customFrames = CustomIcons.GetCustomIconFrames(config)
	if customFrames then
		if skipExisting and customFrames[id] and not customFrames[id].SCMReleased then
			local frame = customFrames[id]
			if frame.SCMIconType == "item" then
				frame.SCMSpellID = select(2, C_Item.GetItemSpell(frame.SCMItemID))
				config.spellID = frame.SCMSpellID
				UpdateCustomIconFrameState(frame, config)
			end
			return
		end

		if DoesItemOrSpellExists(config) and ShouldLoadCustomIcon(config) then
			local frame = AcquireCustomIconFrame(customFrames, id)
			ConfigureCustomIconFrame(frame, id, config, 1, config.anchorGroup or 1, isGlobal)
			UpdateCustomIconFrameState(frame, config)
			ApplyGlobalSettings(frame)
			Icons.SetChildVisibilityState(frame, frame.SCMIconType == "empty", true)
		elseif customFrames[id] then
			ReleaseCustomIconFrame(customFrames[id])
		end
	end
end

function CustomIcons.CreateSpellIcon(spellID)
	local entries = Cache.cachedCustomSpellEntriesBySpellID[spellID]
	if not entries then
		return
	end

	for _, entry in ipairs(entries) do
		if entry.config then
			CreateCustomIcon(entry.id, entry.config, entry.isGlobal, true)
		end
	end
end

function CustomIcons.CreateItemIcon(itemID)
	local entries = Cache.cachedCustomItemEntriesByItemID[itemID]
	if entries then
		for _, entry in ipairs(entries) do
			if entry.config then
				CreateCustomIcon(entry.id, entry.config, entry.isGlobal, true)
			end
		end
	end

	entries = Cache.cachedCustomSlotEntriesByItemID[itemID]
	if not entries then
		return
	end

	for _, entry in ipairs(entries) do
		local config = entry.config
		if config and config.slotID and GetInventoryItemID("player", config.slotID) == itemID then
			CreateCustomIcon(entry.id, config, entry.isGlobal, true)
		end
	end
end

function CustomIcons.CreateIcons(customConfig, isGlobal, iconType)
	for id, config in pairs(customConfig) do
		if not iconType or GetIconType(config) == iconType then
			CreateCustomIcon(id, config, isGlobal)
		end
	end
end

local function ProcessCustomIcon(id, config, validChildren)
	local anchorGroup = config.anchorGroup or 1
	local customFrames = CustomIcons.GetCustomIconFrames(config)
	if not customFrames then
		return
	end

	if customFrames[id] and DoesItemOrSpellExists(config) and ShouldLoadCustomIcon(config) then
		local frame = customFrames[id]
		local iconType = frame.SCMIconType
		if iconType == "empty" then
			Icons.SetChildVisibilityState(frame, true, true)
			CDM.AddChildToScopedGroup(Cache.cachedChildrenTbl, anchorGroup, frame, frame.SCMGlobal)
			CDM.AddChildToScopedGroup(validChildren, anchorGroup, frame, frame.SCMGlobal)
			return
		end

		local iconTexture = GetCustomIconTexture(config, iconType, frame)
		if not iconTexture and SCM.isOptionsOpen then
			iconTexture = 134400
		end

		if iconTexture then
			if frame.SCMIconTexture ~= iconTexture then
				frame.SCMIconTexture = iconTexture
				frame.Icon:SetTexture(iconTexture)
				frame.Icon:SetTexelSnappingBias(0)
				frame.Icon:SetSnapToPixelGrid(false)
				UpdateCustomIconCraftQuality(frame, iconType, config)
			end
			local hasCount = SetCustomIconCountText(frame, iconType, config)
			local isOnCooldown = UpdateCustomIconCooldown(frame, iconType, config)
			local shouldShow = ShouldShowCustomIcon(config, iconType, hasCount, isOnCooldown)

			Icons.SetChildVisibilityState(frame, shouldShow, true)
			CDM.AddChildToScopedGroup(Cache.cachedChildrenTbl, anchorGroup, frame, frame.SCMGlobal)

			if shouldShow then
				if iconType == "spell" then
					C_Spell.EnableSpellRangeCheck(config.spellID, config.showOutOfRange or false)

					UpdateCustomIconCharges(frame, config.spellID)
				end

				CDM.AddChildToScopedGroup(validChildren, anchorGroup, frame, frame.SCMGlobal)
			end
		else
			Icons.SetChildVisibilityState(customFrames[id], false, true)
		end
	elseif customFrames[id] then
		Icons.SetChildVisibilityState(customFrames[id], false, true)
	end
end

local function ProcessCustomIconEntries(entries, validChildren)
	if not entries then
		return
	end

	for i = 1, #entries, 2 do
		ProcessCustomIcon(entries[i], entries[i + 1], validChildren)
	end
end

function CustomIcons.ProcessGroupIcons(group, validChildren)
	if group then
		ProcessCustomIconEntries(Cache.cachedCustomIconsByGroup[group], validChildren)
		return
	end

	for _, entries in pairs(Cache.cachedCustomIconsByGroup) do
		ProcessCustomIconEntries(entries, validChildren)
	end
end

function CustomIcons.ProcessIcons(customConfig, validChildren, isGlobal)
	for id, config in pairs(customConfig) do
		local anchorGroup = config.anchorGroup or 1
		if CDM.IsScopedAnchorGroupAllowed(anchorGroup, isGlobal) then
			ProcessCustomIcon(id, config, validChildren)
		end
	end
end

function CustomIcons.UpdateIcons(customConfig, key)
	for id, config in pairs(customConfig) do
		if config[key] then
			local customFrames = CustomIcons.GetCustomIconFrames(config)
			if customFrames then
				if customFrames[id] then
					local frame = customFrames[id]
					local iconType = frame.SCMIconType
					UpdateCustomIconCooldown(frame, iconType, config)
				end
			end
		end
	end
end

local function UpdateSpellUsabilityForConfig(configTable)
	if not configTable then
		return
	end

	for id, config in pairs(configTable) do
		local spellID = config.spellID
		local frame = spellID and CustomSpellFrames[id]
		if frame and not frame.SCMReleased then
			if frame.spellOutOfRange then
				frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_IN_RANGE_COLOR:GetRGBA())
			elseif not config.showNotUsable or C_Spell.IsSpellUsable(spellID) then
				frame.Icon:SetVertexColor(1, 1, 1, 1)
			else
				frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_USABLE_COLOR:GetRGBA())
			end
		end
	end
end

function CustomIcons.UpdateSpellUsability()
	UpdateSpellUsabilityForConfig(SCM.customConfig.spellConfig)
	UpdateSpellUsabilityForConfig(SCM.globalCustomConfig.spellConfig)
end

function CustomIcons.UpdateSpellsKnown()
	CustomIcons.CreateIcons(SCM.customConfig.spellConfig)
	CustomIcons.CreateIcons(SCM.globalCustomConfig.spellConfig, true)
	CustomIcons.ProcessIcons(SCM.customConfig.spellConfig, Cache.cachedCooldownFrameTbl)
	CustomIcons.ProcessIcons(SCM.globalCustomConfig.spellConfig, Cache.cachedCooldownFrameTbl, true)
end

function CustomIcons.UpdateSpellRange(spellID, isInRange, checksRange)
	local entries = Cache.cachedCustomSpellEntriesBySpellID[spellID]
	if not entries then
		return
	end

	local showOutOfRange = checksRange == true and isInRange == false
	for _, entry in ipairs(entries) do
		local frame = CustomSpellFrames[entry.id]
		if frame and not frame.SCMReleased and not (frame.spellOutOfRange == showOutOfRange) then
			local config = entry.config
			if config and config.showOutOfRange then
				frame.spellOutOfRange = showOutOfRange
				frame.OutOfRange:SetShown(showOutOfRange)

				if showOutOfRange then
					frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_IN_RANGE_COLOR:GetRGBA())
				elseif not config.showNotUsable or C_Spell.IsSpellUsable(spellID) then
					frame.Icon:SetVertexColor(1, 1, 1, 1)
				else
					frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_USABLE_COLOR:GetRGBA())
				end
			else
				frame.spellOutOfRange = nil
			end
		end
	end
end

local function UpdateCountTextForConfigTable(customConfig)
	local visibilityChanged = false

	for id, config in pairs(customConfig) do
		local frame = CustomItemFrames[id]
		if frame and not frame.SCMReleased then
			local iconType = frame.SCMIconType
			if iconType ~= "empty" then
				local previousItemID = frame.SCMItemID
				local itemID = SetCustomItemID(frame, config)
				if itemID ~= previousItemID then
					UpdateCustomIconFrameState(frame, config)
				end

				local hasCount = SetCustomIconCountText(frame, iconType, config)
				local isOnCooldown = UpdateCustomIconCooldown(frame, iconType, config)
				local shouldShow = ShouldShowCustomIcon(config, iconType, hasCount, isOnCooldown) and true or false

				if frame.SCMShouldBeVisible ~= shouldShow then
					Icons.SetChildVisibilityState(frame, shouldShow, true)
					visibilityChanged = true
				end
			end
		end
	end

	return visibilityChanged
end

function CustomIcons.UpdateItemCountText()
	local visibilityChanged = false
	local customConfig = SCM.customConfig
	if customConfig and UpdateCountTextForConfigTable(customConfig.itemConfig) then
		visibilityChanged = true
	end

	local globalCustomConfig = SCM.globalCustomConfig
	if globalCustomConfig and UpdateCountTextForConfigTable(globalCustomConfig.itemConfig) then
		visibilityChanged = true
	end

	return visibilityChanged
end

function SCM:CreateAllCustomIcons(iconType)
	RebuildCustomIconLoadCache()

	for _, customConfig in pairs(self.customConfig) do
		CustomIcons.CreateIcons(customConfig, false, iconType)
	end

	for _, customConfig in pairs(self.globalCustomConfig) do
		CustomIcons.CreateIcons(customConfig, true, iconType)
	end
end

function SCM:UpdateCustomIconsGCD()
	for _, config in pairs(self.customConfig) do
		CustomIcons.UpdateIcons(config, "showGCD")
	end

	for _, config in pairs(self.globalCustomConfig) do
		CustomIcons.UpdateIcons(config, "showGCD")
	end
end

function SCM:AddCustomIcon(anchorGroup, iconType, configID, order, uniqueID, isGlobal)
	local configTable = SCM:GetConfigTable(iconType, isGlobal)
	if not configTable then
		return
	end

	local configKey = iconType == "item" and "itemID" or iconType == "slot" and "slotID" or "spellID"
	for _, entry in pairs(configTable) do
		if entry.anchorGroup == anchorGroup and entry[configKey] == configID then
			return
		end
	end

	uniqueID = uniqueID or SCM:GetUniqueID(configID, iconType, isGlobal)

	if not order then
		order = 1
		for _, entry in pairs(configTable) do
			if entry.anchorGroup == anchorGroup and (entry.order or 0) >= order then
				order = (entry.order or 0) + 1
			end
		end
	end

	configTable[uniqueID] = {
		id = uniqueID,
		iconType = iconType,
		spellID = (iconType == "spell" or iconType == "timer") and configID or nil,
		itemID = iconType == "item" and configID or nil,
		slotID = iconType == "slot" and configID or nil,
		anchorGroup = anchorGroup,
		order = order,
		useLoadClass = false,
		loadClasses = CustomIcons.GetDefaultLoadClasses(),
		useLoadRace = false,
		loadRaces = CustomIcons.GetDefaultLoadRaces(),
		useLoadRole = false,
		loadRoles = { ["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false },
	}

	self:CreateAllCustomIcons(iconType)

	return uniqueID
end

function SCM:RemoveCustomIcon(id, isGlobal, iconType)
	local configTable = SCM:GetConfigTable(iconType, isGlobal)
	if configTable and configTable[id] then
		local config = configTable[id]
		configTable[id] = nil

		CustomIcons.ReleaseIcon(id, config)
		self:CreateAllCustomIcons(iconType)
	end
end
