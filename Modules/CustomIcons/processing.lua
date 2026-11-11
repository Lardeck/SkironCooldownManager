local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local LoadConditions = SCM.LoadConditions
local Cooldowns = SCM.Cooldowns
local CDM = SCM.CDM
local Cache = SCM.Cache
local Icons = SCM.Icons
local States = SCM.States

function CustomIcons.IsCustomIconActive(config, iconType, isOnCooldown)
	if iconType == "timer" or iconType == "bloodlust" then
		return isOnCooldown and true or false
	end

	if iconType == "slot" then
		return CustomIcons.GetSlotSpellID(config)
	end

	return iconType == "spell" or iconType == "empty"
end

local function ProcessCustomIcon(id, config, validChildren, refreshOptions, refreshGlowOptions)
	local anchorGroup = config.anchorGroup or 1
	local customFrames = CustomIcons.GetCustomIconFrames(config)
	if not customFrames then
		return
	end

	local frame = customFrames[id]
	if frame and CustomIcons.ShouldCreateCustomIcon(config) and LoadConditions.ShouldLoad(config) then
		frame:SetFrameLevel(frame:GetFrameLevel() + (SCM.db.profile.options.craftQualityFrameLevel or 3))
		local iconType = frame.SCMIconType
		if iconType == "empty" then
			States.SyncState(frame, true, "ready", true, refreshOptions, refreshGlowOptions)
			Icons.SetChildVisibilityState(frame, SCM.isOptionsOpen or frame.SCMState.Visibility, true)
			CDM.AddChildToScopedGroup(Cache.cachedChildrenTbl, anchorGroup, frame, frame.SCMGlobal)
			CDM.AddChildToScopedGroup(validChildren, anchorGroup, frame, frame.SCMGlobal)
			return
		end

		local iconTexture = CustomIcons.GetCustomIconTexture(config, iconType, frame) or frame.SCMIconTexture
		if not iconTexture and SCM.isOptionsOpen then
			iconTexture = 134400
		end

		if iconTexture then
			if frame.SCMIconTexture ~= iconTexture then
				frame.SCMIconTexture = iconTexture
				frame.Icon:SetTexture(iconTexture)
				frame.Icon:SetTexelSnappingBias(0)
				frame.Icon:SetSnapToPixelGrid(false)
				CustomIcons.UpdateCustomIconCraftQuality(frame, iconType, config)
			end
			local hasCount = CustomIcons.SetCustomIconCountText(frame, iconType, config)
			local isOnCooldown, isChargeCooldown = Cooldowns.UpdateCustomIconCooldown(frame, iconType, config)
			local isActive = CustomIcons.IsCustomIconActive(config, iconType, isOnCooldown)
			local cooldownState = Cooldowns.GetCustomIconCooldownState(iconType, hasCount, isOnCooldown, isChargeCooldown)
			States.SyncState(frame, isActive, cooldownState, true, refreshOptions, refreshGlowOptions)

			local shouldShow = SCM.isOptionsOpen or frame.SCMState.Visibility

			Icons.SetChildVisibilityState(frame, shouldShow, true)
			CDM.AddChildToScopedGroup(Cache.cachedChildrenTbl, anchorGroup, frame, frame.SCMGlobal)

			if shouldShow then
				if iconType == "spell" then
					C_Spell.EnableSpellRangeCheck(config.spellID, config.showOutOfRange or false)

					CustomIcons.UpdateCustomIconCharges(frame, config.spellID)
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

local function ProcessCustomIconEntries(entries, validChildren, refreshOptions, refreshGlowOptions)
	if not entries then
		return
	end

	for i = 1, #entries, 2 do
		ProcessCustomIcon(entries[i], entries[i + 1], validChildren, refreshOptions, refreshGlowOptions)
	end
end

function CustomIcons.ProcessGroupIcons(group, validChildren, refreshOptions, refreshGlowOptions)
	if group then
		ProcessCustomIconEntries(Cache.cachedCustomIconsByGroup[group], validChildren, refreshOptions, refreshGlowOptions)
		return
	end

	for _, entries in pairs(Cache.cachedCustomIconsByGroup) do
		ProcessCustomIconEntries(entries, validChildren, refreshOptions, refreshGlowOptions)
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
