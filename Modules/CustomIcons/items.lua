local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local Cooldowns = SCM.Cooldowns
local Cache = SCM.Cache
local Icons = SCM.Icons
local States = SCM.States
local Utils = SCM.Utils
local CustomItemFrames = CustomIcons.ItemFrames

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

function CustomIcons.SetCustomItemID(frame, config)
	local itemID = GetCustomItemID(config)
	if frame.SCMItemID ~= itemID then
		frame.SCMItemCount = nil
	end
	frame.SCMItemID = itemID
	frame.SCMSpellID = select(2, C_Item.GetItemSpell(itemID))
	config.spellID = frame.SCMSpellID
	return itemID
end

function CustomIcons.SetCustomIconCountText(frame, iconType, config)
	if iconType == "slot" or iconType == "timer" or iconType == "bloodlust" then
		frame.ChargeCount.Current:SetText("")
		frame.ChargeCount.Current:Hide()
		return
	elseif iconType == "spell" then
		return
	end

	local itemID = frame.SCMItemID

	local count = C_Item.GetItemCount(itemID, false, true)
	frame.SCMItemCount = count
	if not config.hideStackText then
		frame.ChargeCount.Current:SetText(count)
		frame.ChargeCount.Current:Show()
	else
		frame.ChargeCount.Current:SetText("")
	end

	if count == 0 then
		frame.Icon:SetVertexColor(0.4, 0.4, 0.4)
		return
	end

	if not frame.isOnCooldown then
		frame.Icon:SetVertexColor(1, 1, 1)
		if not States.HasEffectRules(config, "desaturate") then
			frame.Icon:SetDesaturated(false)
		end
	end

	return true
end


function CustomIcons.UpdateCustomIconCraftQuality(frame, iconType, config)
	local craftQuality = frame.CraftQuality
	local texture = craftQuality.Texture
	texture:SetTexture(nil)
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)
	craftQuality:Hide()

	if iconType ~= "item" or not config.showCraftQuality then
		return
	end

	local itemID = frame.SCMItemID
	local qualityAtlas = Utils.GetCustomItemCraftQualityAtlas(itemID)
	if not qualityAtlas then
		return
	end

	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", frame.Icon, "TOPLEFT", -10, 10)
	texture:SetSize(34, 34)
	texture:SetAtlas(qualityAtlas, false)
	craftQuality:Show()
end

function CustomIcons.UpdateItemCountForItemID(itemID)
	local entriesByItemID = Cache.cachedCustomItemEntriesByItemID[itemID]

	if not entriesByItemID then
		return
	end

	for i = 1, #entriesByItemID do
		local entry = entriesByItemID[i]
		local frame = CustomItemFrames[entry.id]
		if frame and not frame.SCMReleased then
			CustomIcons.SetCustomIconCountText(frame, frame.SCMIconType, entry.config)
		end
	end
end

function CustomIcons.GetSlotSpellID(config)
	if config.slotID then
		local itemID = GetInventoryItemID("player", config.slotID)
		if itemID then
			return C_Item.DoesItemExistByID(itemID) and select(2, C_Item.GetItemSpell(itemID))
		end
	end
end

local function UpdateCountTextForConfigTable(customConfig)
	if not customConfig then
		return
	end

	local visibilityChanged = false

	for id, config in pairs(customConfig) do
		local frame = CustomItemFrames[id]
		if frame and not frame.SCMReleased then
			local iconType = frame.SCMIconType
			if iconType ~= "empty" then
				local previousItemID = frame.SCMItemID
				local itemID = CustomIcons.SetCustomItemID(frame, config)
				if itemID ~= previousItemID then
					CustomIcons.UpdateCustomIconFrameState(frame, config)
				end

				local hasCount = CustomIcons.SetCustomIconCountText(frame, iconType, config)
				local isOnCooldown, isChargeCooldown = Cooldowns.UpdateCustomIconCooldown(frame, iconType, config)
				local wasVisible = frame.SCMShouldBeVisible
				local isActive = CustomIcons.IsCustomIconActive(config, iconType, isOnCooldown)
				local cooldownState = Cooldowns.GetCustomIconCooldownState(iconType, hasCount, isOnCooldown, isChargeCooldown)
				States.SyncState(frame, isActive, cooldownState, true)

				local shouldShow = SCM.isOptionsOpen or frame.SCMState.Visibility

				Icons.SetChildVisibilityState(frame, shouldShow, true)

				if wasVisible ~= shouldShow then
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
