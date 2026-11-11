local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local LoadConditions = SCM.LoadConditions
local Cooldowns = SCM.Cooldowns
local Cache = SCM.Cache
local Icons = SCM.Icons
local Utils = SCM.Utils
local GetIconType = Utils.GetIconType
local ResetChildSCMState = Utils.ResetChildSCMState
local CustomItemFrames = CustomIcons.ItemFrames
local CustomSpellFrames = CustomIcons.SpellFrames

local CustomIconFramePool

function CustomIcons.GetCustomIconFrames(config)
	local iconType = GetIconType(config)
	if not iconType then
		return
	end

	if iconType == "spell" or iconType == "timer" or iconType == "bloodlust" then
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
	frame.SCMItemCount = nil
	frame.slotID = nil
	frame.lastCastStartTime = nil
	frame.UpdateCooldown = nil
	frame.UpdateCharges = nil
	frame.height = nil
	frame.isOnCooldown = nil
	frame.isOnGCD = nil
	frame.spellOutOfRange = nil
	frame.SCMCooldownExpirationTime = nil
	frame.SCMGCDStartTime = nil
	frame.SCMGCDDuration = nil

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
	local craftQuality = frame.CraftQuality
	craftQuality.Texture:SetTexture(nil)
	craftQuality.Texture:SetTexelSnappingBias(0)
	craftQuality.Texture:SetSnapToPixelGrid(false)
	craftQuality:Hide()
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

local function OnCustomIconShow(self)
	if self:GetAttribute("statehidden") or self.SCMSkipShowValidation then
		return
	end

	if self.SCMShouldBeVisible and not self.SCMLayoutApplied then
		self.SCMAppliedVisibility = false
		self:Hide()
		return
	end

	if self.SCMIconType ~= "empty" and not self.SCMShouldBeVisible then
		self.SCMAppliedVisibility = false
		self:Hide()
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
		frame.Cooldown:SetScript("OnCooldownDone", Cooldowns.OnCustomIconCooldownDone)
		frame.GCDCooldown:SetScript("OnCooldownDone", Cooldowns.OnCustomIconCooldownDone)
		frame.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
		frame.Icon:SetTexelSnappingBias(0)
		frame.Icon:SetSnapToPixelGrid(false)
		frame.CraftQuality:SetFrameLevel(frame:GetFrameLevel() + 3)
		frame.CraftQuality.Texture:SetTexelSnappingBias(0)
		frame.CraftQuality.Texture:SetSnapToPixelGrid(false)
		frame.OutOfRange:SetTexelSnappingBias(0)
		frame.OutOfRange:SetSnapToPixelGrid(false)
		frame:HookScript("OnShow", OnCustomIconShow)
		frame:HookScript("OnHide", SCM.StopChildGlows)
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

function CustomIcons.GetCustomIconTexture(config, iconType, frame)
	if (iconType == "spell" or iconType == "timer" or iconType == "bloodlust") and config.spellID then
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

local function ConfigureCustomIconFrame(frame, id, config, anchorGroup, isGlobal)
	frame:SetScale(Cache.cachedViewerScale or 1)

	frame.SCMConfig = config
	frame.SCMOrder = config.order
	frame.SCMCooldownID = id
	frame.SCMIconType = GetIconType(config)
	frame.SCMGroup = anchorGroup
	frame.SCMGlobal = isGlobal and true or nil
	frame.SCMCustom = true

	if frame.SCMIconType == "item" then
		CustomIcons.SetCustomItemID(frame, config)
	elseif config.slotID then
		frame.SCMSpellID = CustomIcons.GetSlotSpellID(config) or nil
		config.spellID = frame.SCMSpellID
	else
		frame.SCMSpellID = config.spellID
	end
end

function CustomIcons.UpdateCustomIconFrameState(frame, config)
	local iconType = frame.SCMIconType
	if iconType == "empty" then
		return
	end

	if iconType == "item" or iconType == "slot" then
		frame.isOnCooldown = nil
		frame.SCMCooldownExpirationTime = nil
	end

	local iconTexture = CustomIcons.GetCustomIconTexture(config, iconType, frame)
	if not iconTexture then
		iconTexture = 134400
	end

	frame.SCMIconTexture = iconTexture
	frame.Icon:SetTexture(iconTexture)
	frame.Icon:SetTexelSnappingBias(0)
	frame.Icon:SetSnapToPixelGrid(false)
	frame.UpdateCooldown = Cooldowns.UpdateCustomIconCooldown
	frame.UpdateCharges = nil
	CustomIcons.UpdateCustomIconCraftQuality(frame, iconType, config)

	if iconType == "spell" then
		local chargeInfo = C_Spell.GetSpellCharges(config.spellID)
		CustomIcons.UpdateCustomIconCharges(frame, config.spellID)

		if chargeInfo or frame.SCMConfig.forceShowCharges then
			frame.UpdateCharges = CustomIcons.UpdateCustomIconCharges
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

local function CreateCustomIcon(id, config, isGlobal, skipExisting)
	local customFrames = CustomIcons.GetCustomIconFrames(config)
	if customFrames then
		if skipExisting and customFrames[id] and not customFrames[id].SCMReleased then
			local frame = customFrames[id]
			if frame.SCMIconType == "item" then
				frame.SCMSpellID = select(2, C_Item.GetItemSpell(frame.SCMItemID))
				config.spellID = frame.SCMSpellID
				CustomIcons.UpdateCustomIconFrameState(frame, config)
			end
			return
		end

		if CustomIcons.ShouldCreateCustomIcon(config) and LoadConditions.ShouldLoad(config) then
			local frame = AcquireCustomIconFrame(customFrames, id)
			ConfigureCustomIconFrame(frame, id, config, config.anchorGroup or 1, isGlobal)
			CustomIcons.UpdateCustomIconFrameState(frame, config)
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
