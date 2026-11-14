local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local Cache = SCM.Cache
local Utils = SCM.Utils
local GetIconType = Utils.GetIconType
local ToGlobalGroup = Utils.ToGlobalGroup
local BloodlustTimerEntries = CustomIcons.BloodlustTimerEntries
local CustomIconAlwaysVisibilityConfigs = CustomIcons.AlwaysVisibilityConfigs

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
	if not requestedItemIDs[itemID] and not C_Item.IsItemDataCachedByID(itemID) then
		requestedItemIDs[itemID] = true
		SCM:RegisterEvent("ITEM_DATA_LOAD_RESULT")
		C_Item.RequestLoadItemDataByID(itemID)
	end
end

local function CacheCustomIconEntry(id, config, isGlobal, slotItemID)
	local iconType = GetIconType(config)
	if (iconType == "spell" or iconType == "timer" or iconType == "bloodlust") and config.spellID then
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
		if not requestedSpellIDs[config.spellID] and not C_Spell.IsSpellDataCached(config.spellID) then
			requestedSpellIDs[config.spellID] = true
			SCM:RegisterEvent("SPELL_DATA_LOAD_RESULT")
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

function CustomIcons.RebuildCustomIconLoadCache()
	local customIconRequests = Cache.customIconRequests
	customIconRequests.requestedSpellIDs = customIconRequests.requestedSpellIDs or {}
	customIconRequests.requestedItemIDs = customIconRequests.requestedItemIDs or {}
	local requestedSpellIDs = customIconRequests.requestedSpellIDs
	local requestedItemIDs = customIconRequests.requestedItemIDs

	wipe(Cache.cachedCustomSpellEntriesBySpellID)
	wipe(Cache.cachedCustomItemEntriesByItemID)
	wipe(Cache.cachedCustomSlotEntriesByItemID)
	wipe(BloodlustTimerEntries)
	wipe(CustomIconAlwaysVisibilityConfigs)
	for _, entries in pairs(Cache.cachedCustomIconsByGroup) do
		wipe(entries)
	end

	local function CacheCustomConfig(customConfig, isGlobal)
		if not customConfig then
			return
		end

		for id, config in pairs(customConfig) do
			if CustomIcons.HasAlwaysVisibilityRule(config) then
				CustomIconAlwaysVisibilityConfigs[config] = true
			end
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
			if GetIconType(config) == "bloodlust" then
				BloodlustTimerEntries[#BloodlustTimerEntries + 1] = id
			end
		end
	end

	for _, customConfig in pairs(SCM.customConfig) do
		CacheCustomConfig(customConfig, false)
	end

	for _, customConfig in pairs(SCM.globalCustomConfig) do
		CacheCustomConfig(customConfig, true)
	end

	CustomIcons.UpdateBloodlustTimerEvent()
end
