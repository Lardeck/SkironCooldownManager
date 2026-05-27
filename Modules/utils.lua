local SCM = select(2, ...)

local Utils = SCM.Utils
local Cache = SCM.Cache
local COOLDOWN_CONFIG_KEY_PREFIX = "cooldown:"
local GLOBAL_GROUP_OFFSET = 100
local GLOBAL_BUFF_BAR_OFFSET = 200
local FIRST_GLOBAL_GROUP = GLOBAL_GROUP_OFFSET + 1
local FIRST_BUFF_BAR_GROUP = GLOBAL_BUFF_BAR_OFFSET + 1
local CHILD_SCM_RESET_FIELDS = {
	"SCMConfig",
	"SCMRowConfig",
	"SCMConfigID",
	"SCMCooldownID",
	"SCMSpellID",
	"SCMLinkedSpellID",
	"SCMAuraInstanceID",
	"SCMOrder",
	"SCMGroup",
	"SCMGlobal",
	"SCMBuffBar",
	"SCMBuffOptions",
	"SCMIconOptions",
	"SCMCheckCooldownFrame",
	"SCMChanged",
	"SCMCustom",
	"SCMIconType",
	"SCMIconTexture",
	"SCMFakeAuraInstanceID",
	"SCMGlowWhileActive",
	"SCMPandemic",
	"SCMRowConfig",
	"SCMShouldBeVisible",
	"SCMGlow",
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

function Utils.ApplyCraftQuality(craftQuality, itemID)
	local qualityAtlas = Utils.GetCustomItemCraftQualityAtlas(itemID)
	if not qualityAtlas then
		return
	end

	craftQuality:ClearAllPoints()
	craftQuality:SetPoint("TOPLEFT", craftQuality:GetParent().Icon, "TOPLEFT", -10, 10)
	craftQuality:SetSize(34, 34)
	craftQuality:SetAtlas(qualityAtlas, false)
	craftQuality:SetTexelSnappingBias(0)
	craftQuality:SetSnapToPixelGrid(false)
	craftQuality:Show()
	return true
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

	if child.SCMGlow then
		SCM:StopCustomGlow(child)
	end

	if child.Icon then
		child.Icon.SCMDesaturated = nil
	end

	for index = 1, #CHILD_SCM_RESET_FIELDS do
		child[CHILD_SCM_RESET_FIELDS[index]] = nil
	end
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

function Utils.ParseAnchorString(anchorString)
	if type(anchorString) ~= "string" then
		return
	end

	local parsedAnchorStrings = Cache.cachedParsedAnchorStrings
	local cachedAnchorGroup = parsedAnchorStrings[anchorString]
	if cachedAnchorGroup then
		return cachedAnchorGroup
	end

	local anchorGroup
	if anchorString:sub(1, 7) ~= "ANCHOR:" then
		return
	end

	local anchorType, anchorID = anchorString:match("^ANCHOR:([%a]+):(%d+)$")
	if anchorType and anchorID then
		anchorID = tonumber(anchorID)
		if not anchorID or anchorID <= 0 then
			return
		end

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

	anchorID = anchorString:match("^ANCHOR:(%d+)$")
	anchorID = anchorID and tonumber(anchorID) or nil
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
		for currentFrame in anchorFrames:gmatch("[^,]+") do
			currentFrame = strtrim(currentFrame)
			local anchorFrame = currentFrame ~= "" and GetSingleAnchorFrame(currentFrame)
			if anchorFrame and (currentFrame:sub(1, 7) == "ANCHOR:" or anchorFrame:IsVisible()) then
				return anchorFrame, currentFrame
			end
		end

		return
	end

	return GetSingleAnchorFrame(anchorFrames), anchorFrames
end

function Utils.GetActiveAnchorFrame(anchorFrames)
	local anchorFrame, selectedAnchorRef = Utils.GetAnchorFrame(anchorFrames)
	if type(selectedAnchorRef) ~= "string" or selectedAnchorRef:sub(1, 7) ~= "ANCHOR:" then
		return anchorFrame, selectedAnchorRef
	end

	local anchorGroup = Utils.ParseAnchorString(selectedAnchorRef)
	local state = anchorGroup and Cache.cachedAnchorStates[anchorGroup]
	local proxy = state and state.currentProxyActive and state.currentProxyFrame
	if proxy and proxy:IsShown() then
		return proxy, selectedAnchorRef, anchorGroup
	end

	return anchorFrame, selectedAnchorRef, anchorGroup
end

function Utils.GetPairedSource(sourceIndex)
	if sourceIndex == Enum.CooldownViewerCategory.TrackedBuff or sourceIndex == Enum.CooldownViewerCategory.TrackedBar then
		return
	end

	return SCM.Constants.SourcePairs[sourceIndex]
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

	if isBuffBar then
		local anchorConfig = config and config.buffBarsAnchorConfig and config.buffBarsAnchorConfig[anchorIndex]
		local profileAnchorConfig = options and options.buffBarsAnchorConfig
		if anchorConfig and anchorConfig.useGlobalProfileConfig and profileAnchorConfig and profileAnchorConfig[anchorIndex] then
			return profileAnchorConfig[anchorIndex]
		end

		return anchorConfig
	end

	local anchorConfig = config and config.anchorConfig and config.anchorConfig[anchorIndex]
	if anchorConfig then
		local profileAnchorConfig = options and options.anchorConfig
		if anchorConfig.useGlobalProfileConfig and profileAnchorConfig and profileAnchorConfig[anchorIndex] then
			return profileAnchorConfig[anchorIndex]
		end

		return anchorConfig
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

function Utils.SortBySCMOrder(a, b)
	return (a.SCMOrder or 0) < (b.SCMOrder or 0)
end

function Utils.AddChildToGroup(validChildren, group, child, isGlobal)
	if isGlobal then
		group = Utils.ToGlobalGroup(group)
		child.SCMGlobal = true
	end

	local groupChildren = GetOrCreateTableEntry(validChildren, group)
	groupChildren[#groupChildren + 1] = child
	return group
end

function Utils.GetIconType(config)
	if not config or not (type(config) == "table") then return end
	return config.iconType or (config.spellID and "spell") or "item"
end

function Utils.GetClass()
	return UnitClassBase("player")
end

function Utils.GetSpec()
	return GetSpecializationInfo(GetSpecialization())
end

local classFileNameToID = {}

--- Returns a table of { [classFile] = displayString } for all classes.
--- Populates the shared classFileNameToID lookup as a side effect.
--- Pass addAll=true to include an "ALL" = "ALL" entry (for export/import filters).
function Utils.GetClassList(addAll)
	local classes = {}

	if addAll then
		classes["ALL"] = "ALL"
	end

	for classIndex = 1, GetNumClasses() do
		local className, classFile, classID = GetClassInfo(classIndex)
		if className and classFile and classID then
			local classColor = GetClassColorObj(classFile)
			local classAtlas = GetClassAtlas(classFile)
			classes[classFile] = classAtlas and ("|A:%s:0:0|a %s"):format(classAtlas, classColor:WrapTextInColorCode(className)) or classColor:WrapTextInColorCode(className)
			classFileNameToID[classFile] = classID
		end
	end

	return classes
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
