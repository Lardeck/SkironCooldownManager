local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local CDM = SCM.CDM
local Cache = SCM.Cache
local Icons = SCM.Icons
local GetIconType = SCM.Utils.GetIconType
local ResetChildSCMState = SCM.Utils.ResetChildSCMState

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
	frame.spellID = nil
	frame.itemID = nil
	frame.slotID = nil
	frame.lastCastStartTime = nil
	frame.UpdateCooldown = nil
	frame.UpdateCharges = nil
	frame.height = nil

	frame:EnableMouse(false)
	frame:SetAlpha(1)
	frame:Hide()
	frame:ClearAllPoints()
	frame.Icon:SetDesaturated(false)
	frame.Icon:SetTexture(nil)
	frame.CraftQuality:Hide()
	frame.CraftQuality:SetTexture(nil)
	frame.Cooldown:Clear()
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
		parent.Icon:SetDesaturation(0)
	end

	if parent.UpdateCooldown then
		parent.isOnGCD = nil
		parent.UpdateCooldown(parent, parent.SCMIconType, parent.SCMConfig)
	end

	if parent.UpdateCharges then
		parent.UpdateCharges(parent, parent.spellID)
	end

	if parent and parent.SCMGroup then
		SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, parent.SCMGlobal)
	end
end

local function OnCustomIconShow(self)
	if not ShouldShowCustomIcon(self.SCMConfig, self.SCMIconType, nil, nil, self) and not self:GetAttribute("statehidden") then
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

local function SetCustomIconCountText(frame, iconType, config)
	frame.ChargeCount.Current:SetText("")
	frame.ChargeCount.Current:Hide()

	if iconType == "spell" or iconType == "slot" or iconType == "timer" then
		return
	end

	local itemID = config.itemID
	if not itemID then
		return
	end

	local count = C_Item.GetItemCount(itemID, false, true)
	if not count or count <= 0 then
		frame.ChargeCount.Current:SetText(0)
		frame.ChargeCount.Current:Show()
		frame.Icon:SetVertexColor(0.4, 0.4, 0.4)
		return
	end

	frame.ChargeCount.Current:SetText(count)
	frame.ChargeCount.Current:Show()

	if not frame.isOnCooldown then
		frame.Icon:SetVertexColor(1, 1, 1)
		frame.Icon:SetDesaturated(false)
	end

	return true
end

local function GetCustomItemCraftQualityInfo(itemID)
	if not itemID then
		return
	end

	local qualityInfo = C_TradeSkillUI.GetItemCraftedQualityInfo(itemID)
	if qualityInfo then
		return qualityInfo
	end

	return C_TradeSkillUI.GetItemReagentQualityInfo(itemID)
end

local function ApplyCraftQuality(craftQuality, itemID)
	local qualityInfo = GetCustomItemCraftQualityInfo(itemID)
	if not (qualityInfo and qualityInfo.iconInventory) then
		return
	end

	craftQuality:SetAtlas(qualityInfo.iconInventory, true)
	craftQuality:Show()
	return true
end

local function UpdateCustomIconCraftQuality(frame, iconType, config)
	local craftQuality = frame.CraftQuality
	craftQuality:Hide()
	craftQuality:SetTexture(nil)

	if iconType ~= "item" or not config.showCraftQuality or not config.itemID then
		return
	end

	if ApplyCraftQuality(craftQuality, config.itemID) then
		return
	end

	local item = Item:CreateFromItemID(config.itemID)
	if not item or item:IsItemEmpty() then
		return
	end

	item:ContinueOnItemLoad(function()
		if frame.SCMReleased or frame.SCMConfig ~= config or frame.SCMIconType ~= iconType then
			return
		end

		ApplyCraftQuality(craftQuality, config.itemID)
	end)
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

local function UpdateCustomIconCooldown(frame, iconType, config)
	local now = GetTime()
	local customTimerStart, customTimerDuration = GetActiveCustomTimer(frame, iconType, config, now)
	if customTimerStart then
		frame.Cooldown:SetCooldown(customTimerStart, customTimerDuration)
		frame.Icon:SetDesaturated(false)
		UpdateCustomIconGlow(frame, true)
		return true
	end

	if iconType == "spell" then
		local spellCooldown = C_Spell.GetSpellCooldown(config.spellID)
		if config.showGCD and spellCooldown.isOnGCD then
			frame.GCDCooldown:SetCooldown(spellCooldown.startTime, spellCooldown.duration)
		end

		local durationObject = C_Spell.GetSpellChargeDuration(config.spellID)
		if durationObject then
			frame.Cooldown:SetCooldownFromDurationObject(durationObject)

			if not spellCooldown.isOnGCD then
				local spellDurationObject = C_Spell.GetSpellCooldownDuration(config.spellID)
				local desaturation = spellDurationObject:EvaluateRemainingDuration(desaturationCurve)
				local alpha = spellDurationObject:EvaluateRemainingDuration(alphaCurve)
				frame.Icon:SetDesaturation(desaturation)
				frame.Cooldown:SetEdgeColor(1, 1, 1, desaturation)
				frame.Cooldown:SetSwipeColor(0, 0, 0, alpha)
				--frame.Cooldown:SetReverse(frame.Icon:IsDesaturated())
			end
		else
			durationObject = C_Spell.GetSpellCooldownDuration(config.spellID)
			frame.Cooldown:SetCooldownFromDurationObject(durationObject)
			if not spellCooldown or not spellCooldown.isOnGCD then
				frame.Icon:SetDesaturation(C_CurveUtil.EvaluateColorValueFromBoolean(durationObject:IsZero(), 0, 1))
			end
		end

		local isOnCooldown = frame.Cooldown:IsShown()
		UpdateCustomIconGlow(frame, false)
		return isOnCooldown
	end

	if iconType == "item" then
		local startTime, duration, _, modRate = C_Item.GetItemCooldown(config.itemID)
		if duration and duration > 0 and (startTime + duration) - GetTime() >= 0.1 then
			if modRate then
				frame.Cooldown:SetCooldown(startTime, duration, modRate)
			else
				frame.Cooldown:SetCooldown(startTime, duration)
			end
			frame.Icon:SetVertexColor(1, 1, 1)
			frame.Icon:SetDesaturated(true)
			frame.isOnCooldown = true
			UpdateCustomIconGlow(frame, false)
			return true
		elseif C_Item.GetItemCount(config.itemID) == 0 then
			frame.isOnCooldown = false
			frame.Cooldown:Clear()
			frame.Icon:SetVertexColor(0.4, 0.4, 0.4)
			UpdateCustomIconGlow(frame, false)
			return
		end
	end

	if iconType == "slot" and config.slotID then
		local startTime, duration = GetInventoryItemCooldown("player", config.slotID)
		if startTime and startTime > 0 and (startTime + duration) - GetTime() >= 0.1 then
			frame.Cooldown:SetCooldown(startTime, duration)
			frame.Icon:SetDesaturated(true)
			UpdateCustomIconGlow(frame, false)
			return true
		end
	end

	frame.Cooldown:Clear()
	frame.Icon:SetVertexColor(1, 1, 1)
	frame.Icon:SetDesaturated(false)
	UpdateCustomIconGlow(frame, false)
end

local function UpdateCustomIconCharges(frame, spellID)
	if not spellID then
		return
	end

	local chargeInfo = C_Spell.GetSpellCharges(spellID)
	if not chargeInfo then
		frame.ChargeCount.Current:Hide()
		return
	end

	frame.ChargeCount.Current:SetText(C_Spell.GetSpellDisplayCount(spellID))
	frame.ChargeCount.Current:Show()
end

local function DoesItemOrSpellExists(config)
	local iconType = GetIconType(config)
	if iconType == "spell" or iconType == "timer" then
		return config.spellID and C_Spell.DoesSpellExist(config.spellID)
	end

	if iconType == "item" then
		return config.itemID and C_Item.DoesItemExistByID(config.itemID)
	end

	if iconType == "slot" then
		if config.slotID then
			local itemID = GetInventoryItemID("player", config.slotID)
			if itemID then
				return C_Item.DoesItemExistByID(itemID) and C_Item.GetItemSpell(itemID)
			end
		end
	end
end

local function GetItemOrSlotSpellID(config)
	local iconType = GetIconType(config)
	if iconType == "item" then
		return config.itemID and C_Item.DoesItemExistByID(config.itemID) and select(2, C_Item.GetItemSpell(config.itemID))
	end

	if iconType == "slot" then
		if config.slotID then
			local itemID = GetInventoryItemID("player", config.slotID)
			if itemID then
				return C_Item.DoesItemExistByID(itemID) and select(2, C_Item.GetItemSpell(itemID))
			end
		end
	end
end

local function GetDefaultLoadClasses()
	local loadClasses = {}
	for classIndex = 1, GetNumClasses() do
		local classFile = select(2, GetClassInfo(classIndex))
		if classFile then
			loadClasses[classFile] = true
		end
	end
	return loadClasses
end

local function MatchesLoadFilter(loadFilter, value)
	if loadFilter then
		if not next(loadFilter) then
			return true
		end

		return loadFilter[value]
	end

	return true
end

local function ShouldLoadCustomIcon(config)
	if config.alwaysShow then return true end

	if not MatchesLoadFilter(config.loadRoles, SCM.currentRole) then return false end
	if not MatchesLoadFilter(config.loadClasses, SCM.currentClass) then return false end
	if not MatchesLoadFilter(config.loadRaces, SCM.currentRace) then return false end

	return true
end

local function ResolveCustomIconTexture(config, iconType)
	if (iconType == "spell" or iconType == "timer") and config.spellID then
		return C_Spell.GetSpellTexture(config.spellID)
	end

	if iconType == "item" and config.itemID then
		return C_Item.GetItemIconByID(config.itemID)
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

	if config.slotID or config.itemID then
		frame.SCMSpellID = GetItemOrSlotSpellID(config) or nil
		config.spellID = frame.SCMSpellID
	else
		frame.SCMSpellID = config.spellID
	end
end

local function UpdateCustomIconFrameState(frame, config)
	local iconType = frame.SCMIconType
	local iconTexture = ResolveCustomIconTexture(config, iconType)
	if not iconTexture then
		iconTexture = 134400
	end

	frame.SCMIconTexture = iconTexture
	frame.Icon:SetTexture(iconTexture)
	frame.UpdateCooldown = UpdateCustomIconCooldown
	frame.UpdateCharges = nil
	UpdateCustomIconCraftQuality(frame, iconType, config)

	if iconType == "spell" then
		local chargeInfo = C_Spell.GetSpellCharges(config.spellID)
		UpdateCustomIconCharges(frame, config.spellID)

		if chargeInfo then
			frame.UpdateCharges = UpdateCustomIconCharges
		end
	else
		frame.ChargeCount.Current:SetText("")
		frame.ChargeCount.Current:Hide()
	end
end

local function ApplyGlobalSettings(frame)
	local options = SCM.db.profile.options

	if not InCombatLockdown() then
		if options.hideWhileMounted then
			RegisterAttributeDriver(frame, "state-visibility", "[combat]show;[mounted][stance:3]hide;show")
		else
			UnregisterAttributeDriver(frame, "state-visibility")
		end
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

	if iconType == "item" and config.itemID then
		local entries = Cache.cachedCustomItemEntriesByItemID[config.itemID]
		if not entries then
			entries = {}
			Cache.cachedCustomItemEntriesByItemID[config.itemID] = entries
		end

		tinsert(entries, {
			id = id,
			config = config,
			isGlobal = isGlobal and true or nil,
		})
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

	local itemID
	if iconType == "item" then
		itemID = config.itemID
	elseif iconType == "slot" then
		itemID = slotItemID
	end

	if itemID and not requestedItemIDs[itemID] then
		requestedItemIDs[itemID] = true
		C_Item.RequestLoadItemDataByID(itemID)
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

	local function CacheCustomConfig(customConfig, isGlobal)
		if not customConfig then
			return
		end

		for id, config in pairs(customConfig) do
			local slotItemID = config.slotID and GetInventoryItemID("player", config.slotID) or nil
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
			return
		end

		if DoesItemOrSpellExists(config) and ShouldLoadCustomIcon(config) then
			local frame = AcquireCustomIconFrame(customFrames, id)
			ConfigureCustomIconFrame(frame, id, config, 1, config.anchorGroup or 1, isGlobal)
			UpdateCustomIconFrameState(frame, config)
			ApplyGlobalSettings(frame)
			Icons.SetChildVisibilityState(frame, false, true)
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

function CustomIcons.ProcessIcons(customConfig, validChildren, isGlobal)
	for id, config in pairs(customConfig) do
		local anchorGroup = config.anchorGroup or 1
		local customFrames = CustomIcons.GetCustomIconFrames(config)
		if customFrames then
			if customFrames[id] and DoesItemOrSpellExists(config) and ShouldLoadCustomIcon(config) then
				if CDM.IsScopedAnchorGroupAllowed(anchorGroup, isGlobal) then
					local frame = customFrames[id]
					local iconType = frame.SCMIconType
					local iconTexture = ResolveCustomIconTexture(config, iconType)
					if not iconTexture and SCM.isOptionsOpen then
						iconTexture = 134400
					end

					if iconTexture then
						if frame.SCMIconTexture ~= iconTexture then
							frame.SCMIconTexture = iconTexture
							frame.Icon:SetTexture(iconTexture)
							UpdateCustomIconCraftQuality(frame, iconType, config)
						end
						local hasCount = SetCustomIconCountText(frame, iconType, config)
						local isOnCooldown = UpdateCustomIconCooldown(frame, iconType, config)
						local shouldShow = ShouldShowCustomIcon(config, iconType, hasCount, isOnCooldown)

						Icons.SetChildVisibilityState(frame, shouldShow, true)

						if shouldShow then
							if iconType == "spell" then
								UpdateCustomIconCharges(frame, config.spellID)
							end

							CDM.AddChildToScopedGroup(validChildren, anchorGroup, frame, isGlobal)
						end
					else
						Icons.SetChildVisibilityState(frame, false, true)
					end
				end
			elseif customFrames[id] then
				Icons.SetChildVisibilityState(customFrames[id], false, true)
			end
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

local function UpdateCountTextForConfigTable(customConfig, spellID)
	for id, config in pairs(customConfig) do
		if not spellID or config.spellID == spellID then
			local frame = CustomItemFrames[id]
			if frame and not frame.SCMReleased then
				SetCustomIconCountText(frame, frame.SCMIconType, config)
			end
		end
	end
end

function CustomIcons.UpdateItemCountText(spellID)
	local customConfig = SCM.customConfig
	if customConfig then
		UpdateCountTextForConfigTable(customConfig.itemConfig, spellID)
	end

	local globalCustomConfig = SCM.globalCustomConfig
	if globalCustomConfig then
		UpdateCountTextForConfigTable(globalCustomConfig.itemConfig, spellID)
	end
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
		loadClasses = GetDefaultLoadClasses(),
		loadRaces = SCM.Constants.Races,
		loadRoles = { ["TANK"] = true, ["HEALER"] = true, ["DAMAGER"] = true },
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
