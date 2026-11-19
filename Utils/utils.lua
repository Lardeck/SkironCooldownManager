local SCM = select(2, ...)

local Utils = SCM.Utils
local Cache = SCM.Cache

local GetSpecialization = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo

local COOLDOWN_CONFIG_KEY_PREFIX = "cooldown:"
local CHILD_SCM_RESET_FIELDS = {
	"SCMConfig",
	"SCMRowConfig",
	"SCMSkinned",
	"SCMConfigID",
	"SCMCooldownID",
	"SCMSpellID",
	"SCMLinkedSpellID",
	"SCMAuraInstanceID",
	"SCMFakeAuraInstanceID",
	"SCMUseFixedDuration",
	"SCMOrder",
	"SCMGroup",
	"SCMGlobal",
	"SCMBuffBar",
	"SCMBuffOptions",
	"SCMIconOptions",
	"SCMChanged",
	"SCMCustom",
	"SCMIconType",
	"SCMIconTexture",
	"SCMPandemic",
	"SCMPandemicStop",
	"SCMShouldBeVisible",
	"SCMGlow",
	"SCMGlowKey",
	"SCMPendingCustomGlow",
	"SCMActiveStateBorders",
	"SCMActiveGlow",
	"SCMAnchorFrame",
	"SCMAnchorFrameStrata",
	"SCMAnchorData",
	"SCMWidth",
	"SCMHeight",
	"SCMBaseStartPoint",
	"SCMBaseOffsetX",
	"SCMBaseOffsetY",
	"SCMLayoutLimited",
	"SCMMissingCooldownLimited",
	"SCMLayoutApplied",
	"SCMAppliedVisibility",
	"SCMAppliedLayoutLimited",
	"SCMProxyAnchor",
	"SCMState",
}

local function CreateDisabledTooltipOverlay(widget)
	if not widget or not widget.frame then
		return
	end

	local frame = widget.frame
	local overlay = frame.SCMDisabledTooltipOverlay
	if not overlay then
		overlay = CreateFrame("Frame", nil, frame)
		overlay:SetAllPoints(frame)
		overlay:EnableMouse(true)
		overlay:Hide()
		overlay:SetScript("OnEnter", function(self)
			local ownerWidget = self.ownerWidget
			if not ownerWidget or not ownerWidget.disabled then
				return
			end

			local tooltip = ownerWidget._scmDisabledTooltip
			if type(tooltip) == "function" then
				tooltip = tooltip(ownerWidget)
			end

			if not tooltip or tooltip == "" then
				return
			end

			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(tooltip, 1, 0.82, 0, 1, true)
			GameTooltip:Show()
		end)
		overlay:SetScript("OnLeave", function(self)
			if GameTooltip:IsOwned(self) then
				GameTooltip:Hide()
			end
		end)
		overlay:SetScript("OnHide", function(self)
			if GameTooltip:IsOwned(self) then
				GameTooltip:Hide()
			end
		end)
		frame.SCMDisabledTooltipOverlay = overlay
	end

	overlay.ownerWidget = widget
	return overlay
end

function Utils.GetCustomItemCraftQualityAtlas(itemID)
	local qualityInfo = C_TradeSkillUI.GetItemCraftedQualityInfo(itemID) or C_TradeSkillUI.GetItemReagentQualityInfo(itemID)
	return qualityInfo and (qualityInfo.iconSmall or qualityInfo.iconChat or qualityInfo.iconInventory)
end

function Utils.RefreshDisabledTooltip(widget)
	local overlay = CreateDisabledTooltipOverlay(widget)
	if not overlay then
		return
	end

	local tooltip = widget._scmDisabledTooltip
	if widget.disabled and tooltip and tooltip ~= "" then
		overlay:Show()
		return
	end

	overlay:Hide()
	if GameTooltip:IsOwned(overlay) then
		GameTooltip:Hide()
	end
end

function Utils.SetDisabledTooltip(widget, tooltip)
	if not widget or not widget.frame then
		return
	end

	if not widget._scmDisabledTooltipHooked then
		widget._scmDisabledTooltipHooked = true

		local originalOnAcquire = widget.OnAcquire
		widget.OnAcquire = function(self, ...)
			if originalOnAcquire then
				originalOnAcquire(self, ...)
			end

			self._scmDisabledTooltip = nil
			if self.frame and self.frame.SCMDisabledTooltipOverlay then
				self.frame.SCMDisabledTooltipOverlay:Hide()
			end
		end

		local originalSetDisabled = widget.SetDisabled
		widget.SetDisabled = function(self, disabled)
			originalSetDisabled(self, disabled)
			Utils.RefreshDisabledTooltip(self)
		end
	end

	widget._scmDisabledTooltip = tooltip
	Utils.RefreshDisabledTooltip(widget)
end

function Utils.ResetChildSCMState(child)
	if not child then
		return
	end

	if child.SCMHideTimer then
		child.SCMHideTimer:Cancel()
		child.SCMHideTimer = nil
	end

	SCM.StopChildGlows(child)
	SCM:ClearChildPressOverlay(child)
	SCM.States.UntrackSpellUsability(child)

	if child.SCMActiveStateBorders then
		SCM.States.HideAllStateBorders(child)
	end

	if child.Icon then
		child.Icon.SCMDesaturated = nil
	end

	if child.ChargeCount and child.ChargeCount.Current then
		child.ChargeCount.Current.SCMRowConfig = nil
	end

	for index = 1, #CHILD_SCM_RESET_FIELDS do
		child[CHILD_SCM_RESET_FIELDS[index]] = nil
	end
end

function Utils.GetCooldownConfigKey(cooldownID)
	if not cooldownID then
		return
	end

	return COOLDOWN_CONFIG_KEY_PREFIX .. tostring(cooldownID)
end

function Utils.GetSpellConfigByCooldownID(spellConfig, cooldownID)
	if not cooldownID then
		return
	end

	local configID = COOLDOWN_CONFIG_KEY_PREFIX .. tostring(cooldownID)
	return configID, configID and spellConfig and spellConfig[configID]
end

function Utils.GetPairedSource(sourceIndex)
	if sourceIndex == Enum.CooldownViewerCategory.TrackedBuff or sourceIndex == Enum.CooldownViewerCategory.TrackedBar then
		return
	end

	return SCM.Constants.CDM.SOURCE_PAIRS[sourceIndex]
end

function Utils.SortBySCMOrder(a, b)
	return (a.SCMOrder or 0) < (b.SCMOrder or 0)
end

function Utils.AddChildToGroup(validChildren, group, child, isGlobal)
	if isGlobal then
		group = Utils.ToGlobalGroup(group)
		child.SCMGlobal = true
	end

	local groupChildren = validChildren[group]
	if not groupChildren then
		if validChildren == Cache.cachedChildrenTbl then
			groupChildren = GetOrCreateTableEntry(Cache.cachedGroupedChildren, group)
			wipe(groupChildren)
		elseif validChildren == Cache.cachedCooldownFrameTbl then
			groupChildren = GetOrCreateTableEntry(Cache.cachedVisibleChildren, group)
			wipe(groupChildren)
		else
			groupChildren = {}
		end
		validChildren[group] = groupChildren
	end

	groupChildren[#groupChildren + 1] = child
	return group
end

function Utils.GetIconType(config)
	if not config or not (type(config) == "table") then
		return
	end
	return config.iconType or (config.spellID and "spell") or "item"
end

function Utils.GetClass()
	return UnitClassBase("player")
end

local fixedRaceAtlasNames = {
	highmountaintauren = "highmountain",
	lightforgeddraenei = "lightforged",
	zandalaritroll = "zandalari",
	earthendwarf = "earthen",
	scourge = "undead",
}

function Utils.GetRaceAtlas(raceName, gender)
	if fixedRaceAtlasNames[raceName] then
		raceName = fixedRaceAtlasNames[raceName]
	end

	return ("raceicon128-%s-%s"):format(raceName, gender)
end

function Utils.GetSpec()
	if GetSpecialization then
		return GetSpecializationInfo(GetSpecialization())
	end
end

local classFileNameToID = {}

--- Returns a table of { [classFile] = displayString } and a localized, alphabetically sorted array of classFile values.
--- Populates the shared classFileNameToID lookup as a side effect.
--- Pass addAll=true to include an "ALL" = "ALL" entry (for export/import filters).
function Utils.GetClassList(addAll)
	local classes = {}
	local classNames = {}
	local sortedClasses = {}

	if addAll then
		classes["ALL"] = "ALL"
	end

	for classIndex = 1, (SCM.isForever and 11 or GetNumClasses()) do
		local className, classFile, classID = GetClassInfo(classIndex)
		if classFile then
		local classColor = GetClassColorObj(classFile)
			local classAtlas = GetClassAtlas(classFile)
			classes[classFile] = classAtlas and ("|A:%s:0:0|a %s"):format(classAtlas, classColor:WrapTextInColorCode(className)) or classColor:WrapTextInColorCode(className)
			classFileNameToID[classFile] = classID
			classNames[classFile] = className
			sortedClasses[#sortedClasses + 1] = classFile
		end
	end

	table.sort(sortedClasses, function(firstClass, secondClass)
		return classNames[firstClass] < classNames[secondClass]
	end)
	if addAll then
		table.insert(sortedClasses, 1, "ALL")
	end

	return classes, sortedClasses
end

--- Returns a table of { [specID] = displayString } for all specs of the given class.
--- Utils.GetClassList must have been called at least once to populate the classID lookup.
function Utils.GetSpecList(classFileName)
	local specs = {}
	if classFileName and classFileNameToID[classFileName] then
		local classID = classFileNameToID[classFileName]
		for specIndex = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
			local id, name, _, icon = GetSpecializationInfoForClassID(classID, specIndex)
			if id and name and icon then
				specs[id] = ("|T%s:14:14:0:0|t %s"):format(icon, name)
			end
		end
	end
	return specs
end
