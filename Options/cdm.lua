local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local Utils = SCM.Utils
local CustomIcons = SCM.CustomIcons
local Constants = SCM.Constants
local ToGlobalGroup = Utils.ToGlobalGroup
local ToBuffBarGroup = Utils.ToBuffBarGroup
local GetCooldownConfigKey = Utils.GetCooldownConfigKey
local UPDATE_SCOPE = SCM.CDM.UPDATE_SCOPE

local colorKnown = "ffffff"
local colorUnknown = "808080"
local colorDisabled = "ff0000"

SCM.MainTabs.CDM = { value = "CDM", text = "Cooldown Manager", order = 2, subgroups = {} }

StaticPopupDialogs["SCM_CONFIRM_COPY_ANCHORS"] = {
	text = "Copy anchor configuration from |cFFFFFFFF%s|r?\n\nThis will overwrite the current anchor layout for |cFFFFFFFF%s|r.",
	button1 = "Copy",
	button2 = "Cancel",
	OnAccept = function(self, data)
		if data and data.callback then
			data.callback()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local iconTypeTabs = {
	all = {
		{ value = "general", text = "General" },
		{ value = "glow", text = "Glow" },
		{ value = "load", text = "Load Conditions" },
	},
	spell = {},
	item = {
		{ value = "items", text = "Items" },
	},
	timer = {},
	slot = {
		{ value = "filter", text = "Filter" },
	},
}
for iconType, options in pairs(iconTypeTabs) do
	if iconType ~= "all" then
		for i = #iconTypeTabs.all, 1, -1 do
			tinsert(options, 1, iconTypeTabs.all[i])
		end
	end
end

local function GetDefaultLoadRaceNames()
	local dualFactionRaces = {}
	local loadedRaces = {}
	local raceIDs = {}

	local sortedIDs = {}
	for raceID in pairs(SCM.Constants.Races) do
		sortedIDs[#sortedIDs + 1] = raceID
	end
	table.sort(sortedIDs)

	for i = 1, #sortedIDs do
		local raceID = sortedIDs[i]
		local raceInfo = C_CreatureInfo.GetRaceInfo(raceID)

		if raceInfo and not dualFactionRaces[raceInfo.raceName] then
			dualFactionRaces[raceInfo.raceName] = true
			loadedRaces[raceID] = raceInfo.raceName
			tinsert(raceIDs, raceID)
		end
	end

	table.sort(raceIDs, function(raceIDA, raceIDB)
		return loadedRaces[raceIDA] < loadedRaces[raceIDB]
	end)

	return loadedRaces, raceIDs
end

local function SortByIndex(a, b)
	return a.dataIndex < b.dataIndex
end

local function ShowNumericInputPopup(key, title, callback)
	StaticPopupDialogs[key] = StaticPopupDialogs[key]
		or {
			text = title,
			button1 = ACCEPT,
			button2 = CANCEL,
			hasEditBox = true,
			timeout = 0,
			whileDead = true,
			preferredIndex = 3,
			OnAccept = function(self)
				local id = tonumber(self.EditBox:GetText() or "")
				local acceptCallback = self.data
				if id and id > 0 and type(acceptCallback) == "function" then
					acceptCallback(id)
				end
			end,
			hideOnEscape = true,
			EditBoxOnEnterPressed = function(self)
				if self:GetParent():GetButton1():IsEnabled() then
					self:GetParent():GetButton1():Click()
				end
			end,
		}
	StaticPopup_Show(key, nil, nil, callback)
end

local function BuildSpellIconData(spellID)
	local texture = C_Spell.GetSpellTexture(spellID)
	if not texture then
		return
	end

	return {
		texture = texture,
		spellID = spellID,
	}
end

local function BuildItemIconData(itemID)
	local texture = C_Item.GetItemIconByID(itemID)
	if not texture then
		return
	end

	return {
		texture = texture,
		spellID = 0,
		itemID = itemID,
	}
end

local function BuildSlotIconData(slotID)
	if slotID < 1 or slotID > 19 then
		return
	end

	return {
		texture = GetInventoryItemTexture("player", slotID) or 134400,
		spellID = 0,
		slotID = slotID,
	}
end

local function BuildEmptyIconData()
	return {
		texture = 134400,
	}
end

local customButtonConfigs = {
	{
		text = "Spell",
		popupKey = "SCM_CUSTOM_SPELL_ID",
		popupTitle = "Enter Spell ID",
		iconType = "spell",
		buildIconData = BuildSpellIconData,
	},
	{
		text = "Item",
		popupKey = "SCM_CUSTOM_ITEM_ID",
		popupTitle = "Enter Item ID",
		iconType = "item",
		buildIconData = BuildItemIconData,
	},
	{
		text = "Slot",
		popupKey = "SCM_SPEC_SLOT_ID",
		popupTitle = "Enter Slot ID",
		iconType = "slot",
		buildIconData = BuildSlotIconData,
	},
	{
		text = "Timer",
		popupKey = "SCM_TIMER_SPELL_ID",
		popupTitle = "Enter Spell ID",
		iconType = "timer",
		buildIconData = BuildSpellIconData,
		tooltip = function(tooltip, elementDescription)
			GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription))
			GameTooltip_AddInstructionLine(tooltip, "Timers can only be created based on successful casts.")
		end,
	},
	{
		text = "Empty",
		iconType = "empty",
		buildIconData = BuildEmptyIconData,
	},
}

local function CreateCustomIconButton(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfig)
	local button = rootDescription:CreateButton(buttonConfig.text, function()
		local function AddCustomIcon(configID)
			local iconData = buttonConfig.buildIconData(configID)
			if not iconData then
				return
			end

			iconData.iconType = buttonConfig.iconType
			iconData.isCustom = true

			local uniqueID = SCM:GetUniqueID(configID, buttonConfig.iconType, isGlobal)
			iconData.id = uniqueID
			local order, insertedData = scrollFrame:AddCustomIcon(iconData)

			uniqueID = SCM:AddCustomIcon(anchorIndex, buttonConfig.iconType, configID, order, uniqueID, isGlobal)
			if not uniqueID then
				scrollFrame:RemoveButton(insertedData)
				return
			end

			insertedData.id = uniqueID

			SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
		end

		if buttonConfig.popupKey then
			ShowNumericInputPopup(buttonConfig.popupKey, buttonConfig.popupTitle, AddCustomIcon)
		elseif buttonConfig.iconType == "empty" then
			AddCustomIcon("")
		end
	end)

	if buttonConfig.tooltip then
		button:SetTooltip(buttonConfig.tooltip)
	end
end

local function CreateCustomIconButtons(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfigs)
	for _, buttonConfig in ipairs(buttonConfigs) do
		CreateCustomIconButton(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfig)
	end
end

local function GetEffectiveAnchorGroup(anchorIndex, mode)
	if mode == "global" then
		return ToGlobalGroup(anchorIndex)
	end

	if mode == "buffbars" then
		return ToBuffBarGroup(anchorIndex)
	end

	return anchorIndex
end

local function SetAnchorHighlight(anchorFrame, state, color)
	local isActive = state == "active"
	if anchorFrame.SCMHighlightState == state and anchorFrame.isGlowActive == isActive then
		return
	end

	anchorFrame.SCMHighlightState = state
	anchorFrame.isGlowActive = isActive
	LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
	LibCustomGlow.PixelGlow_Start(anchorFrame, color, nil, nil, nil, nil, nil, nil, nil, "SCM")

	if anchorFrame.debugText then
		if state == "active" then
			anchorFrame.debugText:SetTextColor(0.34, 0.70, 0.91, 1)
		else
			anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)
		end
	end
end

local function ApplyModeConfigUpdate(anchorIndex, mode)
	if mode == "global" then
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, true)
	elseif mode == "buffbars" then
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, false, UPDATE_SCOPE.BUFF_BAR)
	else
		SCM:ApplyAllCDManagerConfigs(true)
	end
end

local function GetSpellIDForCooldownInfo(cooldownInfo)
	if cooldownInfo then
		return cooldownInfo.linkedSpellID or cooldownInfo.overrideTooltipSpellID or cooldownInfo.overrideSpellID or cooldownInfo.spellID
	end
end

local function BuildScrollSpellData(data, configID)
	return {
		spellID = data.spellID,
		linkedSpellIDs = data.linkedSpellIDs,
		isKnown = data.isKnown,
		category = data.category,
		cooldownID = data.cooldownID,
		configID = configID,
	}
end

local function DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID)
	return scrollFrame.dataProvider:FindByPredicate(function(data)
		if data.isCustom or data.isAddButton then
			return false
		end

		if data.id == configID then
			return true
		end

		if cooldownID and data.cooldownID == cooldownID then
			return true
		end
	end)
end

local function GetDisplayDataForSpellConfig(defaultCooldownViewerConfig, sourceIndex, configID, config)
	local data = defaultCooldownViewerConfig[sourceIndex]
	if not data then
		return
	end

	local pairData = defaultCooldownViewerConfig[SCM.Constants.SourcePairs[sourceIndex]]
	local cooldownID = config.cooldownID or tonumber(tostring(configID):match("(%d+)$"))

	if cooldownID then
		return data.cooldownIDs[cooldownID] or (pairData and pairData.cooldownIDs[cooldownID])
	end
end

local function CreateAddSpellDropdown(owner, rootDescription, scrollFrame, anchorIndex, mode)
	rootDescription:CreateTitle("Add Icon")

	local dataProvider = CooldownViewerSettings:GetDataProvider()
	local cooldownInfoByID = dataProvider and dataProvider.displayData.cooldownInfoByID

	if mode == "global" then
		local customButton = rootDescription:CreateButton("Custom")
		CreateCustomIconButtons(customButton, scrollFrame, anchorIndex, true, customButtonConfigs)
		return
	end

	local function GetSortRank(info, data)
		if type(data.category) == "number" and data.category < 0 then
			return 4
		end
		if info.isKnown then
			return 1
		end

		return data.category
	end

	local function SortSpells(a, b)
		local rankA = GetSortRank(a.info, a.data)
		local rankB = GetSortRank(b.info, b.data)

		if rankA ~= rankB then
			return rankA < rankB
		end

		local nameA = C_Spell.GetSpellName(a.info.spellID)
		local nameB = C_Spell.GetSpellName(b.info.spellID)

		if nameA and nameB then
			return nameA < nameB
		end
	end

	local function ProcessAndCreateButtons(parentButton, items, isBuffIcon)
		table.sort(items, SortSpells)

		for _, item in ipairs(items) do
			local data = item.data
			local cooldownID = item.cooldownID
			local info = item.info
			local configID = GetCooldownConfigKey(cooldownID)
			if configID then
				info.cooldownID = item.cooldownID
				info.configID = configID
				info.isDisabled = type(data.category) == "number" and data.category < 0
				info.category = data.category

				local activeColor = (type(data.category) == "number" and data.category < 0 and colorDisabled) or (info.isKnown and colorKnown) or colorUnknown
				parentButton:CreateButton(string.format("|T%d:0|t |cff%s%s (%d)|r", C_Spell.GetSpellTexture(info.spellID), activeColor, C_Spell.GetSpellName(info.spellID), info.spellID), function(info)
					if not SCM:IsSpellInData(info.cooldownID, info.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, info.configID, info.cooldownID) then
						local dataIndex = scrollFrame:AddSpellBySpellID(info)
						SCM:AddSpellToConfig(anchorIndex, dataIndex, info, data, item.targetCategory, isBuffIcon)
						ApplyModeConfigUpdate(anchorIndex, mode)
					end
					return MenuResponse.Open
				end, info)
			end
		end
	end

	if mode == "buffbars" then
		local buffButton = rootDescription:CreateButton("Buff Bars")
		local buffItems = {}

		local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(2, true)
		for _, cooldownID in ipairs(cooldownIDs) do
			local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
			local data = cooldownInfoByID[cooldownID]

			if info and data and type(data.category) == "number" and (data.category == 3 or data.category < 0) then
				local spellID = GetSpellIDForCooldownInfo(info)
				local configID = GetCooldownConfigKey(cooldownID)
				info.spellID = spellID

				if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
					table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 3 })
				end
			end
		end

		cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(3, true)
		for _, cooldownID in ipairs(cooldownIDs) do
			local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
			local data = cooldownInfoByID[cooldownID]

			if info and data and type(data.category) == "number" and (data.category == 3 or data.category < 0) then
				local spellID = GetSpellIDForCooldownInfo(info)
				local configID = GetCooldownConfigKey(cooldownID)
				info.spellID = spellID

				if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
					table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 3 })
				end
			end
		end

		buffButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#buffItems / 15) + 1)

		ProcessAndCreateButtons(buffButton, buffItems, false)

		return
	end

	local essentialButton = rootDescription:CreateButton("Essential")
	local utilityButton = rootDescription:CreateButton("Utility")
	local buffButton = rootDescription:CreateButton("Buff")

	local essentialItems = {}
	local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(0, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(essentialItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 0 })
			end
		end
	end

	essentialButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#essentialItems / 15) + 1)
	ProcessAndCreateButtons(essentialButton, essentialItems)

	local utilityItems = {}
	cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(1, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(utilityItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 1 })
			end
		end
	end

	utilityButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#utilityItems / 15) + 1)

	ProcessAndCreateButtons(utilityButton, utilityItems)

	local buffItems = {}

	cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(2, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = Enum.CooldownViewerCategory.TrackedBuff })
			end
		end
	end

	cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(3, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data and type(data.category) == "number" and data.category <= 3 then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = Enum.CooldownViewerCategory.TrackedBuff })
			end
		end
	end

	buffButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#buffItems / 15) + 1)

	ProcessAndCreateButtons(buffButton, buffItems, true)

	rootDescription:CreateDivider()

	local customButton = rootDescription:CreateButton("Custom")
	CreateCustomIconButtons(customButton, scrollFrame, anchorIndex, false, customButtonConfigs)

	if CreateCategoryObjectLookup and CooldownViewerSettingsDataProvider_GetCategories then
		local copyFromButton = rootDescription:CreateButton("Copy From")
		local lookup = CreateCategoryObjectLookup()

		for _, sourceCategory in ipairs(CooldownViewerSettingsDataProvider_GetCategories()) do
			local category = sourceCategory >= 0 and sourceCategory < 3 and lookup[sourceCategory]

			if category then
				copyFromButton:CreateButton(category.title, function()
					local dataProvider = CooldownViewerSettings:GetDataProvider()
					local displayData = dataProvider and dataProvider.displayData
					if not displayData then
						return
					end

					for _, cooldownID in ipairs(displayData.orderedCooldownIDs) do
						local data = displayData.cooldownInfoByID[cooldownID]
						local configID = data and data.category == sourceCategory and GetCooldownConfigKey(cooldownID)

						if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
							local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
							if info then
								info.spellID = GetSpellIDForCooldownInfo(info)
								info.cooldownID = cooldownID
								info.configID = configID
								info.isDisabled = false
								info.category = data.category

								local dataIndex = scrollFrame:AddSpellBySpellID(info)
								SCM:AddSpellToConfig(anchorIndex, dataIndex, info, data, sourceCategory)
							end
						end
					end

					ApplyModeConfigUpdate(anchorIndex, mode)
				end)
			end
		end
	end

	for _, customEntry in pairs(SCM.CustomEntries) do
		customEntry(rootDescription, scrollFrame, anchorIndex)
	end
end

local function SelectAdvancedRowSettings(self, tabGroup, rowConfig, rowIndex, anchorIndex, mode, options, data)
	self:ReleaseChildren()

	if tabGroup == "general" then
		local keepAspectRatio = AceGUI:Create("CheckBox")
		keepAspectRatio:SetLabel("Lock Aspect Ratio")
		keepAspectRatio:SetRelativeWidth(0.5)
		keepAspectRatio:SetValue(rowConfig.keepAspectRatio)
		keepAspectRatio:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.keepAspectRatio = value
		end)
		keepAspectRatio:SetCallback("OnEnter", function()
			GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
			GameTooltip:SetText("Lock Aspect Ratio", nil, nil, nil, nil, true)
			GameTooltip:AddLine("This will lock both Icon Width & Icon Height to be the same value.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		keepAspectRatio:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
		self:AddChild(keepAspectRatio)

		local hardLimit = AceGUI:Create("CheckBox")
		hardLimit:SetLabel("Hard Limit")
		hardLimit:SetRelativeWidth(0.5)
		hardLimit:SetValue(rowConfig.hardLimit)
		hardLimit:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.hardLimit = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		hardLimit:SetCallback("OnEnter", function()
			GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
			GameTooltip:SetText("Hard Limit", nil, nil, nil, nil, true)
			GameTooltip:AddLine("This option will ensure that only the set number of icons are displayed.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		hardLimit:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
		self:AddChild(hardLimit)

		if rowIndex == 1 then
			local fixedWidth
			local useFixedWidth = AceGUI:Create("CheckBox")
			useFixedWidth:SetLabel("Use Fixed Width")
			useFixedWidth:SetRelativeWidth(0.5)
			useFixedWidth:SetValue(rowConfig.useFixedWidth)
			useFixedWidth:SetDisabled(data.matchAnchorWidth)
			useFixedWidth:SetCallback("OnValueChanged", function(_, _, value)
				rowConfig.useFixedWidth = value
				ApplyModeConfigUpdate(anchorIndex, mode)

				if fixedWidth then
					rowConfig.fixedWidth = rowConfig.fixedWidth or 200
					fixedWidth:SetDisabled(not value)
				end
			end)
			useFixedWidth:SetCallback("OnEnter", function()
				GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
				GameTooltip:SetText("Use Fixed Width", nil, nil, nil, nil, true)
				GameTooltip:AddLine("This will make the row use a fixed width instead of calculating it based on the number of icons.", 1, 1, 1, true)
				GameTooltip:Show()
			end)
			useFixedWidth:SetCallback("OnLeave", function()
				GameTooltip:Hide()
			end)
			self:AddChild(useFixedWidth)

			fixedWidth = AceGUI:Create("Slider")
			fixedWidth:SetRelativeWidth(0.5)
			fixedWidth:SetSliderValues(100, 1000, 0.1)
			fixedWidth:SetLabel("Fixed Width")
			fixedWidth:SetValue(rowConfig.fixedWidth or 200)
			fixedWidth:SetDisabled(not rowConfig.useFixedWidth)
			fixedWidth:SetCallback("OnValueChanged", function(_, _, value)
				rowConfig.fixedWidth = value
				ApplyModeConfigUpdate(anchorIndex, mode)
			end)
			self:AddChild(fixedWidth)
		end
	elseif tabGroup == "charges" then
		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.5)
		chargeRelativePoint:SetLabel("Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(rowConfig.chargePoint or options.chargePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.chargePoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(chargeRelativePoint)

		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.5)
		chargeRelativePoint:SetLabel("Relative Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(rowConfig.chargeRelativePoint or options.chargeRelativePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.chargeRelativePoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(chargeRelativePoint)

		local xOffset = AceGUI:Create("Slider")
		xOffset:SetRelativeWidth(0.25)
		xOffset:SetSliderValues(-50, 50, 0.1)
		xOffset:SetLabel("X Offset")
		xOffset:SetValue(rowConfig.chargeXOffset or options.chargeXOffset)
		xOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.chargeXOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(xOffset)

		local yOffset = AceGUI:Create("Slider")
		yOffset:SetRelativeWidth(0.25)
		yOffset:SetSliderValues(-50, 50, 0.1)
		yOffset:SetLabel("Y Offset")
		yOffset:SetValue(rowConfig.chargeYOffset or options.chargeYOffset)
		yOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.chargeYOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(yOffset)

		local chargeFontSize = AceGUI:Create("Slider")
		chargeFontSize:SetRelativeWidth(0.25)
		chargeFontSize:SetLabel("Font Size")
		chargeFontSize:SetSliderValues(1, 50, 1)
		chargeFontSize:SetValue(rowConfig.chargeFontSize or options.chargeFontSize)
		chargeFontSize:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.chargeFontSize = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(chargeFontSize)

		local truncateWhenZero = AceGUI:Create("CheckBox")
		truncateWhenZero:SetLabel("Truncate When Zero")
		truncateWhenZero:SetRelativeWidth(0.25)
		truncateWhenZero:SetValue(rowConfig.chargeTruncateWhenZero)
		truncateWhenZero:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.chargeTruncateWhenZero = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(truncateWhenZero)
	elseif tabGroup == "applications" then
		local applicationsPoint = AceGUI:Create("Dropdown")
		applicationsPoint:SetRelativeWidth(0.5)
		applicationsPoint:SetLabel("Point")
		applicationsPoint:SetList(SCM.Constants.AnchorPoints)
		applicationsPoint:SetValue(rowConfig.applicationsPoint or options.chargePoint)
		applicationsPoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.applicationsPoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(applicationsPoint)

		local applicationsRelativePoint = AceGUI:Create("Dropdown")
		applicationsRelativePoint:SetRelativeWidth(0.5)
		applicationsRelativePoint:SetLabel("Relative Point")
		applicationsRelativePoint:SetList(SCM.Constants.AnchorPoints)
		applicationsRelativePoint:SetValue(rowConfig.applicationsRelativePoint or options.chargeRelativePoint)
		applicationsRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.applicationsRelativePoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(applicationsRelativePoint)

		local xOffset = AceGUI:Create("Slider")
		xOffset:SetRelativeWidth(0.33)
		xOffset:SetSliderValues(-50, 50, 0.1)
		xOffset:SetLabel("X Offset")
		xOffset:SetValue(rowConfig.applicationsXOffset or options.chargeXOffset)
		xOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.applicationsXOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(xOffset)

		local yOffset = AceGUI:Create("Slider")
		yOffset:SetRelativeWidth(0.33)
		yOffset:SetSliderValues(-50, 50, 0.1)
		yOffset:SetLabel("Y Offset")
		yOffset:SetValue(rowConfig.applicationsYOffset or options.chargeYOffset)
		yOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.applicationsYOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(yOffset)

		local fontSize = AceGUI:Create("Slider")
		fontSize:SetRelativeWidth(0.33)
		fontSize:SetLabel("Font Size")
		fontSize:SetSliderValues(1, 50, 1)
		fontSize:SetValue(rowConfig.applicationsFontSize or options.chargeFontSize)
		fontSize:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.applicationsFontSize = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(fontSize)
	elseif tabGroup == "cooldowns" then
		local fontSize = AceGUI:Create("Slider")
		fontSize:SetRelativeWidth(0.5)
		fontSize:SetSliderValues(1, 50, 1)
		fontSize:SetLabel("Font Size")
		fontSize:SetValue(rowConfig.cooldownFontSize or ((options.cooldownFontSize or 0.6) * (rowConfig.iconWidth or rowConfig.size)))
		fontSize:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.cooldownFontSize = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(fontSize)
	end
end

local function SelectRow(widget, rowWidget, parentWidget, scrollFrame, data, anchorIndex, rowIndex, rowTabsTbl, mode, options, isProfileConfig)
	widget:ReleaseChildren()

	local isGlobal = mode == "global"
	local isBuffBar = mode == "buffbars"
	local useDataRowConfig = isGlobal or isBuffBar or isProfileConfig

	if not data.rowConfig[rowIndex] then
		return
	end

	local rowConfig = data.rowConfig[rowIndex]
	local widthLabel = isBuffBar and "Bar Width" or "Icon Width"
	local heightLabel = isBuffBar and "Bar Height" or "Icon Height"
	local iconWidth = AceGUI:Create("Slider")
	iconWidth:SetRelativeWidth(0.33)
	iconWidth:SetSliderValues(10, isBuffBar and 500 or 200, 0.1)
	iconWidth:SetLabel(widthLabel)
	iconWidth:SetDisabled(data.matchAnchorWidth)
	iconWidth:SetValue(rowConfig.iconWidth or rowConfig.size)

	widget:AddChild(iconWidth)

	local iconHeight = AceGUI:Create("Slider")
	iconHeight:SetRelativeWidth(0.33)
	iconHeight:SetSliderValues(10, 200, 0.1)
	iconHeight:SetLabel(heightLabel)
	iconHeight:SetValue(rowConfig.iconHeight or rowConfig.size)
	iconHeight:SetCallback("OnValueChanged", function(self, event, value)
		if rowConfig.keepAspectRatio then
			local newWidth
			if (rowConfig.iconHeight or rowConfig.size) == (rowConfig.iconWidth or rowConfig.size) then
				newWidth = value
			else
				local ratio = (rowConfig.iconWidth or rowConfig.size) / (rowConfig.iconHeight or rowConfig.size)
				newWidth = ceil((ratio * value) * 10) / 10
			end

			rowConfig.iconWidth = newWidth
			iconWidth:SetValue(rowConfig.iconWidth)
		end

		rowConfig.iconHeight = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	iconWidth:SetCallback("OnValueChanged", function(self, event, value)
		if rowConfig.keepAspectRatio then
			local newHeight
			if (rowConfig.iconHeight or rowConfig.size) == (rowConfig.iconWidth or rowConfig.size) then
				newHeight = value
			else
				local ratio = (rowConfig.iconHeight or rowConfig.size) / (rowConfig.iconWidth or rowConfig.size)
				newHeight = ceil((ratio * value) * 10) / 10
			end

			rowConfig.iconHeight = newHeight
			iconHeight:SetValue(rowConfig.iconHeight)
		end
		rowConfig.iconWidth = value

		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	widget:AddChild(iconHeight)

	local limit = AceGUI:Create("Slider")
	limit:SetRelativeWidth(0.33)
	limit:SetSliderValues(1, 20, 1)
	limit:SetLabel("Limit")
	limit:SetValue(rowConfig.limit)
	limit:SetCallback("OnValueChanged", function(self, event, value)
		rowConfig.limit = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	widget:AddChild(limit)

	local advancedRowSettings = AceGUI:Create("TabGroup")
	local advancedTabs = isBuffBar and { { value = "general", text = "General" }, { value = "applications", text = "Stacks (Alpha)" } }
		or { { value = "general", text = "General" }, { value = "charges", text = "Charges" }, { value = "applications", text = "Stacks" }, { value = "cooldowns", text = "Cooldowns" } }
	advancedRowSettings:SetAutoAdjustHeight(false)
	advancedRowSettings:SetHeight(150)
	advancedRowSettings:SetFullWidth(true)
	advancedRowSettings:SetLayout("flow")
	advancedRowSettings:SetTabs(advancedTabs)
	advancedRowSettings:SetCallback("OnGroupSelected", function(self, event, tabGroup)
		SelectAdvancedRowSettings(self, tabGroup, rowConfig, rowIndex, anchorIndex, mode, options, data)
	end)
	advancedRowSettings:SelectTab("general")
	widget:AddChild(advancedRowSettings)

	local buttonGroup = AceGUI:Create("SimpleGroup")
	buttonGroup:SetFullWidth(true)
	buttonGroup:SetLayout("flow")
	widget:AddChild(buttonGroup)

	local addRowButton = AceGUI:Create("Button")
	addRowButton:SetText("Add Row")
	addRowButton:SetRelativeWidth(0.5)
	addRowButton:SetDisabled(#rowTabsTbl >= 9)
	addRowButton:SetCallback("OnClick", function()
		local nextIndex = (useDataRowConfig and (#data.rowConfig + 1)) or SCM:AddRow(anchorIndex)
		if isGlobal then
			data.rowConfig[nextIndex] = { iconHeight = 40, iconWidth = 40, limit = 8 }
		elseif isBuffBar then
			data.rowConfig[nextIndex] = { iconHeight = 40, iconWidth = 150, limit = 8 }
		elseif isProfileConfig then
			data.rowConfig[nextIndex] = { iconHeight = 40, iconWidth = 40, limit = 8 }
		end

		tinsert(rowTabsTbl, { value = nextIndex, text = "Row " .. nextIndex })
		table.sort(rowTabsTbl, function(a, b)
			return a.value < b.value
		end)
		widget:SetTabs(rowTabsTbl)
		widget:SelectTab(nextIndex)
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	buttonGroup:AddChild(addRowButton)

	local deleteRowButton = AceGUI:Create("Button")
	deleteRowButton:SetText("Delete Row")
	deleteRowButton:SetRelativeWidth(0.5)
	deleteRowButton:SetDisabled(rowIndex == 1)
	deleteRowButton:SetCallback("OnClick", function()
		if useDataRowConfig then
			tremove(data.rowConfig, rowIndex)
		else
			SCM:RemoveRow(anchorIndex, rowIndex)
		end

		local removedIndex
		for i, tab in ipairs(rowTabsTbl) do
			if tab.value == rowIndex then
				removedIndex = i
				tremove(rowTabsTbl, i)
				break
			end
		end

		for i = removedIndex, #rowTabsTbl do
			rowTabsTbl[i].value = i
			rowTabsTbl[i].text = "Row " .. i
		end

		widget:SetTabs(rowTabsTbl)
		widget:SelectTab(#rowTabsTbl)
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	buttonGroup:AddChild(deleteRowButton)
end

local function AddStateOptions(stateType, iconSettingsTabs, iconSettings, scrollFrame, value, options, buttonConfig)
	buttonConfig.stateOptions = buttonConfig.stateOptions or {}
	buttonConfig.stateOptions[value] = buttonConfig.stateOptions[value] or {}

	SCM.Templates.AddGlowOptions(iconSettingsTabs, buttonConfig.stateOptions[value], iconSettings, scrollFrame)
end

local function CreateStateDropdown(iconSettingsTabs, iconSettings, scrollFrame, options, buttonConfig)
	local stateType = AceGUI:Create("Dropdown")
	stateType:SetRelativeWidth(0.5)
	stateType:SetLabel("State Type")
	stateType:SetList({
		["ready"] = "Ready",
		["cooldown"] = "On Cooldown",
		["active"] = "Active",
	})
	iconSettingsTabs:AddChild(stateType)

	stateType:SetCallback("OnValueChanged", function(_, _, value)
		AddStateOptions(stateType, iconSettingsTabs, iconSettings, scrollFrame, value, options, buttonConfig)
		iconSettingsTabs:DoLayout()
	end)
	stateType:SetValue("ready")
end

local function SelectAnchor(widget, parentWidget, anchorIndex, anchorTabsTbl, mode)
	widget:ReleaseChildren()

	SCM.activeAnchorSettings = anchorIndex
	local options = SCM.db.profile.options
	local isGlobal = mode == "global"
	local isBuffBar = mode == "buffbars"
	local currentAnchorIndex = GetEffectiveAnchorGroup(anchorIndex, mode)
	local isProfileConfig = false

	if options.showAnchorHighlight then
		for group, anchorFrame in pairs(SCM.anchorFrames) do
			local activeGroup = GetEffectiveAnchorGroup(anchorIndex, mode)
			if group == activeGroup then
				SetAnchorHighlight(anchorFrame, "active", { 0.34, 0.70, 0.91, 1 })
			else
				SetAnchorHighlight(anchorFrame, "default")
			end
		end
	end

	local sourceData = (isGlobal and SCM.globalAnchorConfig[anchorIndex]) or (isBuffBar and SCM.buffBarsAnchorConfig[anchorIndex]) or SCM.anchorConfig[anchorIndex]
	if not sourceData then
		return
	end

	local data = sourceData
	local function GetProfileAnchorConfig()
		local config
		if isBuffBar then
			options.buffBarsAnchorConfig = options.buffBarsAnchorConfig or {}
			config = options.buffBarsAnchorConfig[anchorIndex]
		else
			options.anchorConfig = options.anchorConfig or {}
			config = options.anchorConfig[anchorIndex]
		end

		if not config then
			config = CopyTable(data)
		end

		if isBuffBar then
			options.buffBarsAnchorConfig[anchorIndex] = config
		else
			options.anchorConfig[anchorIndex] = config
		end

		return config
	end

	if not isGlobal and sourceData.useGlobalProfileConfig then
		data = GetProfileAnchorConfig()
		isProfileConfig = true
	end

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	widget:AddChild(scrollFrame)

	local anchorOptions = AceGUI:Create("InlineGroup")
	anchorOptions:SetLayout("flow")
	anchorOptions:SetFullWidth(true)
	anchorOptions:SetHeight(250)
	anchorOptions:SetTitle("Anchor Options")
	scrollFrame:AddChild(anchorOptions)

	local buttonGroup = AceGUI:Create("SimpleGroup")
	buttonGroup:SetFullWidth(true)
	buttonGroup:SetLayout("flow")
	anchorOptions:AddChild(buttonGroup)

	local anchorButtonWidth = isGlobal and 0.5 or 0.33
	local addAnchorButton = AceGUI:Create("Button")
	addAnchorButton:SetText("Add Anchor")
	addAnchorButton:SetRelativeWidth(anchorButtonWidth)
	addAnchorButton:SetDisabled(#anchorTabsTbl >= 15)
	addAnchorButton:SetCallback("OnClick", function()
		local nextIndex = (isGlobal and SCM:AddGlobalAnchor(anchorTabsTbl)) or (isBuffBar and SCM:AddBuffBarAnchor(anchorTabsTbl)) or SCM:AddAnchor(anchorTabsTbl)
		ApplyModeConfigUpdate(nextIndex, mode)
		widget:SetTabs(anchorTabsTbl)
		widget:SelectTab(nextIndex)
	end)
	buttonGroup:AddChild(addAnchorButton)

	local deleteAnchorButton = AceGUI:Create("Button")
	deleteAnchorButton:SetText("Delete Anchor")
	deleteAnchorButton:SetRelativeWidth(anchorButtonWidth)
	deleteAnchorButton:SetDisabled(((isGlobal or isBuffBar) and anchorIndex == 1) or (not isGlobal and not isBuffBar and anchorIndex <= 3))
	deleteAnchorButton:SetCallback("OnClick", function()
		if isGlobal then
			SCM:RemoveGlobalAnchor(anchorIndex, anchorTabsTbl)
		elseif isBuffBar then
			SCM:RemoveBuffBarAnchor(anchorIndex, anchorTabsTbl)
		else
			SCM:RemoveAnchor(anchorIndex, anchorTabsTbl)
		end
		widget:SetTabs(anchorTabsTbl)
		widget:SelectTab(#anchorTabsTbl)
	end)
	buttonGroup:AddChild(deleteAnchorButton)

	if not isGlobal then
		local useGlobalProfileConfig = AceGUI:Create("CheckBox")
		useGlobalProfileConfig:SetLabel("Use Profile Config (EXPERIMENTAL)")
		useGlobalProfileConfig:SetRelativeWidth(0.33)
		useGlobalProfileConfig:SetValue(sourceData.useGlobalProfileConfig or false)
		useGlobalProfileConfig:SetCallback("OnValueChanged", function(_, _, value)
			sourceData.useGlobalProfileConfig = value
			if value then
				GetProfileAnchorConfig()
			end
			ApplyModeConfigUpdate(anchorIndex, mode)
			widget:SelectTab(anchorIndex)
		end)
		useGlobalProfileConfig:SetCallback("OnEnter", function(self)
			GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
			GameTooltip:SetText("Use Profile Config", nil, nil, nil, nil, true)
			GameTooltip:AddLine("This will use the anchor config for that anchor that is shared by all specs.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		useGlobalProfileConfig:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
		buttonGroup:AddChild(useGlobalProfileConfig)
	end

	local point = AceGUI:Create("Dropdown")
	point:SetRelativeWidth(isBuffBar and 0.25 or 0.33)
	point:SetLabel("Point")
	point:SetList(SCM.Constants.AnchorPoints)
	point:SetValue(data.anchor[1])
	point:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[1] = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(point)

	local relativeTo = AceGUI:Create("EditBox")
	relativeTo:SetRelativeWidth(isBuffBar and 0.25 or 0.33)
	relativeTo:SetLabel("Anchor Frame")
	relativeTo:SetText(data.anchor[2])
	relativeTo:SetCallback("OnEnterPressed", function(self, event, text)
		data.anchor[2] = text
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(relativeTo)

	local relativePoint = AceGUI:Create("Dropdown")
	relativePoint:SetRelativeWidth(isBuffBar and 0.25 or 0.33)
	relativePoint:SetLabel("Relative Point")
	relativePoint:SetList(SCM.Constants.AnchorPoints)
	relativePoint:SetValue(data.anchor[3])
	relativePoint:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[3] = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(relativePoint)

	if isBuffBar then
		local matchAnchorWidth = AceGUI:Create("CheckBox")
		matchAnchorWidth:SetLabel("Match Parent Width")
		matchAnchorWidth:SetRelativeWidth(0.25)
		matchAnchorWidth:SetValue(data.matchAnchorWidth or false)
		matchAnchorWidth:SetCallback("OnValueChanged", function(_, _, value)
			data.matchAnchorWidth = value
			ApplyModeConfigUpdate(anchorIndex, mode)
			widget:SelectTab(anchorIndex)
		end)
		anchorOptions:AddChild(matchAnchorWidth)
	end

	local grow = AceGUI:Create("Dropdown")
	grow:SetRelativeWidth(0.25)
	grow:SetList(SCM.Constants.GrowthDirections)
	grow:SetLabel("Primary Growth")
	grow:SetValue(data.grow or "CENTERED")
	grow:SetCallback("OnValueChanged", function(self, event, value)
		data.grow = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(grow)

	local secondaryGrow = AceGUI:Create("Dropdown")
	secondaryGrow:SetRelativeWidth(0.25)
	secondaryGrow:SetList(SCM.Constants.SecondaryGrowthDirections)
	secondaryGrow:SetLabel("Secondary Growth")
	secondaryGrow:SetValue(data.secondaryGrow or "DOWN")
	secondaryGrow:SetCallback("OnValueChanged", function(self, event, value)
		data.secondaryGrow = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(secondaryGrow)

	local spacing = AceGUI:Create("Slider")
	spacing:SetRelativeWidth(0.25)
	spacing:SetSliderValues(-10, 50, 0.1)
	spacing:SetLabel("Spacing")
	spacing:SetValue(data.spacing or 0)
	spacing:SetCallback("OnValueChanged", function(self, event, value)
		data.spacing = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(spacing)

	local frameStrata = AceGUI:Create("Dropdown")
	frameStrata:SetRelativeWidth(0.25)
	frameStrata:SetList(SCM.Constants.FrameStrata, SCM.Constants.FrameStrataSorted)
	frameStrata:SetLabel("Frame Strata")
	frameStrata:SetValue(data.frameStrata or "")
	frameStrata:SetCallback("OnValueChanged", function(self, event, value)
		data.frameStrata = value ~= "" and value or nil
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(frameStrata)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetSliderValues(-1000, 1000, 0.1)
	xOffset:SetLabel("X Offset")
	xOffset:SetValue(data.anchor[4])
	xOffset:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[4] = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.5)
	yOffset:SetSliderValues(-1000, 1000, 0.1)
	yOffset:SetLabel("Y Offset")
	yOffset:SetValue(data.anchor[5])
	yOffset:SetCallback("OnValueChanged", function(self, event, value)
		data.anchor[5] = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	anchorOptions:AddChild(yOffset)

	local rowTabsTbl = {}
	for i, row in ipairs(data.rowConfig) do
		tinsert(rowTabsTbl, { value = i, text = "Row " .. i })
	end

	local rowTabs = AceGUI:Create("TabGroup")
	rowTabs:SetLayout("flow")
	rowTabs:SetAutoAdjustHeight(false)
	rowTabs:SetFullWidth(true)
	rowTabs:SetHeight(280)
	rowTabs:SetTabs(rowTabsTbl)
	rowTabs:SetCallback("OnGroupSelected", function(self, event, rowIndex)
		SelectRow(self, widget, parentWidget, scrollFrame, data, anchorIndex, rowIndex, rowTabsTbl, mode, options, isProfileConfig)
	end)
	rowTabs:SelectTab(1)
	anchorOptions:AddChild(rowTabs)

	local top = AceGUI:Create("InlineGroup")
	top:SetLayout("flow")
	top:SetFullWidth(true)
	top:SetHeight(120)
	top:SetTitle("Spell Config")
	scrollFrame:AddChild(top)

	top:PauseLayout()
	local horizontalScrollFrame = AceGUI:Create("SCMHorizontalScrollFrame")
	horizontalScrollFrame:SetHeight(86)
	horizontalScrollFrame:SetFullWidth(true)
	horizontalScrollFrame.scrollbar:ClearAllPoints()
	horizontalScrollFrame.scrollbar:SetPoint("BOTTOMLEFT", horizontalScrollFrame.frame, "BOTTOMLEFT")
	horizontalScrollFrame.scrollbar:SetPoint("BOTTOMRIGHT", horizontalScrollFrame.frame, "BOTTOMRIGHT")
	horizontalScrollFrame.scrollBox:ClearAllPoints()
	horizontalScrollFrame.scrollBox:SetPoint("TOPLEFT", horizontalScrollFrame.frame, "TOPLEFT")
	horizontalScrollFrame.scrollBox:SetPoint("BOTTOMRIGHT", horizontalScrollFrame.scrollbar, "TOPRIGHT", 0, 2)

	horizontalScrollFrame:SetSortComparator(SortByIndex)

	local spells = {}
	if not isGlobal and SCM.spellConfig then
		local defaultCooldownViewerConfig = SCM.defaultCooldownViewerConfig

		for configID, info in pairs(SCM.spellConfig) do
			if info.anchorGroup[currentAnchorIndex] then
				for sourceIndex, spellAnchorIndex in pairs(info.source) do
					if currentAnchorIndex == spellAnchorIndex then
						local data = GetDisplayDataForSpellConfig(defaultCooldownViewerConfig, sourceIndex, configID, info)
						if data then
							tinsert(spells, { configID = configID, info = info, data = data, isBuffIcon = sourceIndex >= 2 })
							break
						end
					end
				end
			end
		end
	end

	local function AddCustomCollection(customConfig)
		for _, config in pairs(customConfig) do
			if config.anchorGroup == anchorIndex then
				local iconType = config.iconType or (config.spellID and "spell") or "item"
				local texture
				if iconType == "spell" or iconType == "timer" then
					texture = config.spellID and C_Spell.GetSpellTexture(config.spellID)
				elseif iconType == "slot" then
					texture = config.slotID and GetInventoryItemTexture("player", config.slotID) or 134400
				elseif iconType == "item" then
					texture = config.itemID and C_Item.GetItemIconByID(config.itemID)
				end

				if texture or SCM.isOptionsOpen then
					tinsert(spells, {
						order = config.order,
						texture = texture or 134400,
						spellID = config.spellID or 0,
						itemID = config.itemID,
						slotID = config.slotID,
						iconType = iconType,
						id = config.id,
						isCustom = true,
					})
				end
			end
		end
	end

	if isGlobal then
		for _, customConfig in pairs(SCM.globalCustomConfig) do
			AddCustomCollection(customConfig)
		end
	elseif isBuffBar then
	else
		for _, customConfig in pairs(SCM.customConfig) do
			AddCustomCollection(customConfig)
		end
	end

	table.sort(spells, function(a, b)
		return (a.order or a.info.anchorGroup[currentAnchorIndex].order) < (b.order or b.info.anchorGroup[currentAnchorIndex].order)
	end)

	for _, spellInfo in ipairs(spells) do
		if spellInfo.isCustom then
			horizontalScrollFrame:AddCustomIcon(spellInfo)
		else
			horizontalScrollFrame:AddSpellBySpellID(BuildScrollSpellData(spellInfo.data, spellInfo.configID), spellInfo.info.anchorGroup[currentAnchorIndex].order, spellInfo.isBuffIcon)
		end
	end

	horizontalScrollFrame:AddAddButton()

	local iconSettings = AceGUI:Create("InlineGroup")
	iconSettings:SetLayout("flow")
	iconSettings:SetFullWidth(true)
	iconSettings:SetHeight(120)
	iconSettings:SetTitle("")
	scrollFrame:AddChild(iconSettings)

	local function ShowIconSettingsMessage(message)
		iconSettings:SetTitle("")

		local label = AceGUI:Create("Label")
		label:SetRelativeWidth(1.0)
		label:SetHeight(24)
		label:SetJustifyH("CENTER")
		label:SetJustifyV("MIDDLE")
		label:SetText(message)
		label:SetFontObject("Game12Font")
		iconSettings:AddChild(label)

		iconSettings:DoLayout()
		scrollFrame:DoLayout()
	end

	ShowIconSettingsMessage("|TInterface\\common\\help-i:40:40:0:0|tClick on an icon above to show spell specific options.")

	local lastButtonFrame
	horizontalScrollFrame:SetCallback("OnGroupSelected", function(scrollFrameWidget, event, buttonFrame, button)
		iconSettings:ReleaseChildren()

		if lastButtonFrame then
			lastButtonFrame:SetBackdropBorderColor(BLACK_FONT_COLOR:GetRGBA())
		end

		if button == "LeftButton" then
			if buttonFrame.data.isAddButton then
				local menu = MenuUtil.CreateContextMenu(nil, function(owner, rootDescription)
					CreateAddSpellDropdown(owner, rootDescription, horizontalScrollFrame, anchorIndex, mode)
				end)
			else
				if not lastButtonFrame or lastButtonFrame ~= buttonFrame then
					local buttonData = buttonFrame.data
					local buttonConfig = buttonData.isCustom and SCM:GetConfigTableByID(buttonData.id, buttonData.iconType, isGlobal) or SCM:GetSpellConfigForGroup(buttonData.id, currentAnchorIndex)
					if not buttonConfig then
						lastButtonFrame = nil
						ShowIconSettingsMessage("|TInterface\\common\\help-i:40:40:0:0|tThis icon could not be resolved for the current anchor.")
						return
					end

					buttonFrame:SetBackdropBorderColor(0, 1, 0, 1)

					if buttonConfig then
						local function ApplyIconConfigUpdate()
							if buttonFrame.data.isCustom then
								SCM:CreateAllCustomIcons(buttonData.iconType)
								SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
								return
							end
							ApplyModeConfigUpdate(anchorIndex, mode)
						end

						local iconSettingsTabs = AceGUI:Create("TabGroup")
						iconSettingsTabs:SetLayout("flow")
						iconSettingsTabs:SetFullWidth(true)
						iconSettingsTabs:SetTabs(isBuffBar and { { value = "general", text = "General" } } or iconTypeTabs[buttonData.iconType])
						iconSettingsTabs:SetCallback("OnGroupSelected", function(self, event, group)
							iconSettingsTabs:ReleaseChildren()

							if group == "general" then
								if buttonData.spellID and buttonData.spellID > 0 then
									iconSettings:SetTitle(C_Spell.GetSpellName(buttonData.spellID))
								elseif buttonData.itemID then
									iconSettings:SetTitle(C_Item.GetItemNameByID(buttonData.itemID))
								elseif buttonData.slotID then
									iconSettings:SetTitle("Slot ID " .. buttonData.slotID)
								end

								if not isBuffBar then
									local desaturate, alwaysShow, showWhileInactive
									if buttonFrame.data.isBuffIcon or buttonData.isCustom then
										alwaysShow = AceGUI:Create("CheckBox")
										alwaysShow:SetLabel("Show Always")
										alwaysShow:SetRelativeWidth(0.5)
										alwaysShow:SetValue(buttonConfig.alwaysShow)
										alwaysShow:SetDisabled((not buttonData.isCustom and not options.hideBuffsWhenInactive) or buttonConfig.showWhileInactive)
										SCM.Utils.SetDisabledTooltip(
											alwaysShow,
											"Enable \"Disable 'Hide Inactive Auras'\" in Global Settings > General > Auras first or disable 'Show While Inactive'."
										)
										iconSettingsTabs:AddChild(alwaysShow)
										alwaysShow:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.alwaysShow = value
											ApplyIconConfigUpdate()

											if desaturate then
												desaturate:SetDisabled(not value)
											end

											if showWhileInactive then
												showWhileInactive:SetDisabled(value)
											end
										end)
									end

									if buttonFrame.data.isBuffIcon then
										showWhileInactive = AceGUI:Create("CheckBox")
										showWhileInactive:SetLabel("Show While Inactive")
										showWhileInactive:SetRelativeWidth(0.5)
										showWhileInactive:SetValue(buttonConfig.showWhileInactive)
										showWhileInactive:SetDisabled(not options.hideBuffsWhenInactive or buttonConfig.alwaysShow)
										SCM.Utils.SetDisabledTooltip(showWhileInactive, "Enable \"Disable 'Hide Inactive Auras'\" in Global Settings > General > Auras first or disable 'Show Always'.")
										iconSettingsTabs:AddChild(showWhileInactive)
										showWhileInactive:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.showWhileInactive = value
											ApplyIconConfigUpdate()

											if desaturate then
												desaturate:SetDisabled(not value)
											end

											if alwaysShow then
												alwaysShow:SetDisabled(value)
											end
										end)

										local hideWhileMounted = AceGUI:Create("CheckBox")
										hideWhileMounted:SetRelativeWidth(0.5)
										hideWhileMounted:SetValue(buttonConfig.hideWhileMounted)
										hideWhileMounted:SetLabel("Hilde While Mounted")
										hideWhileMounted:SetDisabled(not options.hideWhileMounted)
										hideWhileMounted:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.hideWhileMounted = value or nil
											ApplyIconConfigUpdate()
										end)
										iconSettingsTabs:AddChild(hideWhileMounted)

										desaturate = AceGUI:Create("CheckBox")
										desaturate:SetLabel("Desaturate While Inactive")
										desaturate:SetRelativeWidth(0.5)
										desaturate:SetValue(buttonConfig.desaturate)
										desaturate:SetDisabled(not buttonConfig.alwaysShow and not buttonConfig.showWhileInactive)
										SCM.Utils.SetDisabledTooltip(desaturate, "Enable 'Show Always' first.")
										desaturate:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.desaturate = value or nil
											ApplyIconConfigUpdate()
										end)
										iconSettingsTabs:AddChild(desaturate)
									elseif buttonData.iconType ~= "timer" then
										local hideWhileReady = AceGUI:Create("CheckBox")
										hideWhileReady:SetLabel("Hide While Ready")
										hideWhileReady:SetRelativeWidth(0.5)
										hideWhileReady:SetValue(buttonConfig.hideWhenNotOnCooldown)
										hideWhileReady:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.hideWhenNotOnCooldown = value or nil
											ApplyIconConfigUpdate()
										end)
										iconSettingsTabs:AddChild(hideWhileReady)

										if buttonData.isCustom then
											local showGCD = AceGUI:Create("CheckBox")
											showGCD:SetLabel("Show GCD")
											showGCD:SetRelativeWidth(0.5)
											showGCD:SetValue(buttonConfig.showGCD)
											showGCD:SetCallback("OnValueChanged", function(self, event, value)
												buttonConfig.showGCD = value or nil
												ApplyIconConfigUpdate()
											end)
											iconSettingsTabs:AddChild(showGCD)

											if buttonData.iconType == "item" then
												local showCraftQuality = AceGUI:Create("CheckBox")
												showCraftQuality:SetLabel("Show Craft Quality")
												showCraftQuality:SetRelativeWidth(0.5)
												showCraftQuality:SetValue(buttonConfig.showCraftQuality)
												showCraftQuality:SetCallback("OnValueChanged", function(self, event, value)
													buttonConfig.showCraftQuality = value or nil
													ApplyIconConfigUpdate()
												end)
												iconSettingsTabs:AddChild(showCraftQuality)

												local hideStackText = AceGUI:Create("CheckBox")
												hideStackText:SetLabel("Hide Count")
												hideStackText:SetRelativeWidth(0.5)
												hideStackText:SetValue(buttonConfig.hideStackText)
												hideStackText:SetCallback("OnValueChanged", function(self, event, value)
													buttonConfig.hideStackText = value or nil
													ApplyIconConfigUpdate()
												end)
												iconSettingsTabs:AddChild(hideStackText)
											elseif buttonData.iconType == "spell" then
												local showNotUsable = AceGUI:Create("CheckBox")
												showNotUsable:SetLabel("Show Not Usable")
												showNotUsable:SetRelativeWidth(0.5)
												showNotUsable:SetValue(buttonConfig.showNotUsable)
												showNotUsable:SetCallback("OnValueChanged", function(self, event, value)
													buttonConfig.showNotUsable = value or nil
													ApplyIconConfigUpdate()
												end)
												iconSettingsTabs:AddChild(showNotUsable)

												local showOutOfRange = AceGUI:Create("CheckBox")
												showOutOfRange:SetLabel("Show Out Of Range")
												showOutOfRange:SetRelativeWidth(0.5)
												showOutOfRange:SetValue(buttonConfig.showOutOfRange)
												showOutOfRange:SetCallback("OnValueChanged", function(self, event, value)
													buttonConfig.showOutOfRange = value
													C_Spell.EnableSpellRangeCheck(buttonData.spellID, value)
													ApplyIconConfigUpdate()
												end)
												iconSettingsTabs:AddChild(showOutOfRange)

												local forceShowCharges = AceGUI:Create("CheckBox")
												forceShowCharges:SetLabel("Force Show Charges")
												forceShowCharges:SetRelativeWidth(0.5)
												forceShowCharges:SetValue(buttonConfig.forceShowCharges)
												forceShowCharges:SetCallback("OnValueChanged", function(self, event, value)
													buttonConfig.forceShowCharges = value
													ApplyIconConfigUpdate()
												end)
												iconSettingsTabs:AddChild(forceShowCharges)
											end
										else
											local forceActiveSwipe = AceGUI:Create("CheckBox")
											forceActiveSwipe:SetLabel("Force Active Swipe")
											forceActiveSwipe:SetRelativeWidth(0.5)
											forceActiveSwipe:SetValue(buttonConfig.forceActiveSwipe)
											forceActiveSwipe:SetCallback("OnValueChanged", function(self, event, value)
												buttonConfig.forceActiveSwipe = value or nil
												ApplyIconConfigUpdate()
											end)
											iconSettingsTabs:AddChild(forceActiveSwipe)
										end
									end

									if buttonData.isCustom and (buttonData.iconType == "spell" or buttonData.iconType == "timer") then
										local castTimer = AceGUI:Create("Slider")
										castTimer:SetRelativeWidth(0.5)
										castTimer:SetSliderValues(0, 60, 0.1)
										castTimer:SetLabel("Timer Duration")
										castTimer:SetValue(buttonConfig.duration or 0)
										castTimer:SetCallback("OnValueChanged", function(_, _, value)
											buttonConfig.duration = value > 0 and value or nil
											ApplyIconConfigUpdate()
										end)

										iconSettingsTabs:AddChild(castTimer)
									end
								else
									local customColor = AceGUI:Create("ColorPicker")
									customColor:SetRelativeWidth(0.5)
									customColor:SetLabel("Custom Color")
									customColor:SetHasAlpha(true)
									if buttonConfig.customColor then
										customColor:SetColor(buttonConfig.customColor.r, buttonConfig.customColor.g, buttonConfig.customColor.b, buttonConfig.customColor.a)
									end
									customColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
										buttonConfig.customColor = { r = r, g = g, b = b, a = a }
										SCM:SkinBuffBars()
									end)
									iconSettingsTabs:AddChild(customColor)
								end
							elseif group == "load" then
								if buttonData.isCustom then
									if isGlobal then
										local useLoadClass = AceGUI:Create("CheckBox")
										useLoadClass:SetLabel("Class")
										useLoadClass:SetRelativeWidth(0.5)
										useLoadClass:SetValue(buttonConfig.useLoadClass)
										iconSettingsTabs:AddChild(useLoadClass)

										local loadClass = AceGUI:Create("Dropdown")
										loadClass:SetRelativeWidth(0.5)
										loadClass:SetLabel("Classes")
										loadClass:SetList(SCM.Utils.GetClassList(false))
										loadClass:SetMultiselect(true)
										loadClass:SetDisabled(not buttonConfig.useLoadClass)
										loadClass:SetCallback("OnValueChanged", function(_, _, key, value)
											buttonConfig.loadClasses = buttonConfig.loadClasses or GetDefaultCustomIconLoadClasses()
											buttonConfig.loadClasses[key] = value
											ApplyIconConfigUpdate()
										end)

										if not buttonConfig.loadClasses then
											buttonConfig.loadClasses = GetDefaultCustomIconLoadClasses()
										end

										for key, value in pairs(buttonConfig.loadClasses) do
											loadClass:SetItemValue(key, value)
										end

										useLoadClass:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.useLoadClass = value or nil
											loadClass:SetDisabled(not value)
											ApplyIconConfigUpdate()
										end)

										iconSettingsTabs:AddChild(loadClass)

										local useLoadRole = AceGUI:Create("CheckBox")
										useLoadRole:SetLabel("Role")
										useLoadRole:SetRelativeWidth(0.5)
										useLoadRole:SetValue(buttonConfig.useLoadRole)
										iconSettingsTabs:AddChild(useLoadRole)

										local loadRole = AceGUI:Create("Dropdown")
										loadRole:SetRelativeWidth(0.5)
										loadRole:SetLabel("Roles")
										loadRole:SetList(SCM.Constants.Roles)
										loadRole:SetMultiselect(true)
										loadRole:SetDisabled(not buttonConfig.useLoadRole)
										loadRole:SetCallback("OnValueChanged", function(_, _, key, value)
											buttonConfig.loadRoles = buttonConfig.loadRoles or {}
											buttonConfig.loadRoles[key] = value
											ApplyIconConfigUpdate()
										end)

										if not buttonConfig.loadRoles then
											buttonConfig.loadRoles = { ["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false }
										end

										for key, value in pairs(buttonConfig.loadRoles) do
											loadRole:SetItemValue(key, value)
										end

										useLoadRole:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.useLoadRole = value or nil
											loadRole:SetDisabled(not value)
											ApplyIconConfigUpdate()
										end)

										iconSettingsTabs:AddChild(loadRole)

										local useLoadRace = AceGUI:Create("CheckBox")
										useLoadRace:SetLabel("Race")
										useLoadRace:SetRelativeWidth(0.5)
										useLoadRace:SetValue(buttonConfig.useLoadRace)
										iconSettingsTabs:AddChild(useLoadRace)

										local loadRaces = AceGUI:Create("Dropdown")
										loadRaces:SetRelativeWidth(0.5)
										loadRaces:SetLabel("Races")
										loadRaces:SetList(GetDefaultLoadRaceNames())
										loadRaces:SetMultiselect(true)
										loadRaces:SetDisabled(not buttonConfig.useLoadRace)
										loadRaces:SetCallback("OnValueChanged", function(_, _, key, value)
											buttonConfig.loadRaces = buttonConfig.loadRaces or CustomIcons.GetDefaultLoadRaces()
											buttonConfig.loadRaces[key] = value

											if type(Constants.Races[key]) == "number" then
												buttonConfig.loadRaces[Constants.Races[key]] = value
											end

											ApplyIconConfigUpdate()
										end)

										if not buttonConfig.loadRaces then
											buttonConfig.loadRaces = CustomIcons.GetDefaultLoadRaces()
										end

										for key, value in pairs(buttonConfig.loadRaces) do
											loadRaces:SetItemValue(key, value)
										end

										useLoadRace:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.useLoadRace = value or nil
											loadRaces:SetDisabled(not value)
											ApplyIconConfigUpdate()
										end)

										iconSettingsTabs:AddChild(loadRaces)

										local useSpellKnown = AceGUI:Create("CheckBox")
										useSpellKnown:SetLabel("Spell Known")
										useSpellKnown:SetRelativeWidth(0.5)
										useSpellKnown:SetValue(buttonConfig.useSpellKnown)
										iconSettingsTabs:AddChild(useSpellKnown)

										local loadSpellKnown = AceGUI:Create("EditBox")
										loadSpellKnown:SetRelativeWidth(0.5)
										loadSpellKnown:SetLabel("SpellID")
										loadSpellKnown:SetText(buttonConfig.spellKnownSpellID and tostring(buttonConfig.spellKnownSpellID) or "")
										loadSpellKnown:SetDisabled(not buttonConfig.useSpellKnown)
										loadSpellKnown:SetCallback("OnEnterPressed", function(_, _, value)
											buttonConfig.spellKnownSpellID = tonumber(value)
											ApplyIconConfigUpdate()
										end)

										useSpellKnown:SetCallback("OnValueChanged", function(self, event, value)
											buttonConfig.useSpellKnown = value
											loadSpellKnown:SetDisabled(not value)
											ApplyIconConfigUpdate()
										end)

										iconSettingsTabs:AddChild(loadSpellKnown)

										iconSettings:DoLayout()
										scrollFrame:DoLayout()
										return
									end
								end

								local label = AceGUI:Create("Label")
								label:SetRelativeWidth(1.0)
								label:SetHeight(24)
								label:SetJustifyH("CENTER")
								label:SetJustifyV("MIDDLE")
								label:SetText("|TInterface\\common\\help-i:40:40:0:0|tLoad conditions are only available for global custom icons (for now).")
								label:SetFontObject("Game12Font")
								iconSettingsTabs:AddChild(label)
							elseif group == "glow" then
								if not buttonData.isCustom and buttonData.iconType == "spell" then
									local useCustomGlowColor = AceGUI:Create("CheckBox")
									useCustomGlowColor:SetLabel("Use Custom Glow Color")
									useCustomGlowColor:SetRelativeWidth(0.5)
									useCustomGlowColor:SetValue(buttonConfig.useCustomGlowColor)
									useCustomGlowColor:SetDisabled(not options.useCustomGlow)
									SCM.Utils.SetDisabledTooltip(useCustomGlowColor, "Enable 'Use Custom Glow' in Global Settings > Glow first.")
									useCustomGlowColor:SetCallback("OnValueChanged", function(self, event, value)
										buttonConfig.useCustomGlowColor = value or nil
										ApplyIconConfigUpdate()
									end)
									iconSettingsTabs:AddChild(useCustomGlowColor)

									local customGlowColor = AceGUI:Create("ColorPicker")
									customGlowColor:SetRelativeWidth(0.33)
									customGlowColor:SetLabel("Glow Color")
									customGlowColor:SetHasAlpha(true)
									customGlowColor:SetDisabled(not options.useCustomGlow)
									if buttonConfig.customGlowColor then
										customGlowColor:SetColor(unpack(buttonConfig.customGlowColor))
									end
									customGlowColor:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
										buttonConfig.customGlowColor = { r, g, b, a }
									end)
									iconSettingsTabs:AddChild(customGlowColor)
								end

								if buttonData.iconType == "spell" or buttonData.iconType == "timer" then
									local glowWhileActive = AceGUI:Create("CheckBox")
									glowWhileActive:SetLabel("Glow While Active")
									glowWhileActive:SetRelativeWidth(0.5)
									glowWhileActive:SetValue(buttonConfig.glowWhileActive)
									glowWhileActive:SetDisabled(not options.useCustomGlow)
									SCM.Utils.SetDisabledTooltip(glowWhileActive, "Enable 'Use Custom Glow' in Global Settings > Glow first.")
									glowWhileActive:SetCallback("OnValueChanged", function(self, event, value)
										buttonConfig.glowWhileActive = value or nil
										ApplyIconConfigUpdate()
									end)
									iconSettingsTabs:AddChild(glowWhileActive)

									local glowWhileInactive = AceGUI:Create("CheckBox")
									glowWhileInactive:SetLabel("Glow While Inactive")
									glowWhileInactive:SetRelativeWidth(0.5)
									glowWhileInactive:SetValue(buttonConfig.glowWhileInactive)
									glowWhileInactive:SetDisabled(not options.useCustomGlow)
									SCM.Utils.SetDisabledTooltip(glowWhileInactive, "Enable 'Use Custom Glow' in Global Settings > Glow first.")
									glowWhileInactive:SetCallback("OnValueChanged", function(self, event, value)
										buttonConfig.glowWhileInactive = value or nil
										ApplyIconConfigUpdate()
									end)
									iconSettingsTabs:AddChild(glowWhileInactive)
								end
							elseif group == "state" then
								CreateStateDropdown(self, iconSettings, scrollFrame, options, buttonConfig)
							elseif group == "items" then
								buttonConfig.customItems = buttonConfig.customItems or {}

								local listContainer = AceGUI:Create("SimpleGroup")
								listContainer:SetLayout("flow")
								listContainer:SetFullWidth(true)

								local pendingItemLoads = {}
								local RefreshList

								local function GetCustomItemDisplay(itemID)
									local itemName = C_Item.GetItemNameByID(itemID)
									local itemTexture = C_Item.GetItemIconByID(itemID)
									local isLoaded = itemName ~= nil and itemTexture ~= nil
									local qualityAtlas = Utils.GetCustomItemCraftQualityAtlas(itemID)
									local qualityIcon = qualityAtlas and ("|A:%s:45:45|a"):format(qualityAtlas) or ""
									itemTexture = itemTexture or 134400
									return ("|T%s:30:30:5:0:30:30:3:27:3:27|t%s%s"):format(itemTexture, qualityIcon, itemName or ("Item ID " .. itemID)), isLoaded
								end

								local function RequestCustomItemLoad(itemID)
									if pendingItemLoads[itemID] then
										return
									end

									pendingItemLoads[itemID] = true
									local item = Item:CreateFromItemID(itemID)
									item:ContinueOnItemLoad(function()
										pendingItemLoads[itemID] = nil
										if listContainer.frame and listContainer.frame:IsShown() then
											RefreshList()
										end
									end)
								end

								RefreshList = function()
									listContainer:ReleaseChildren()

									for i, itemID in ipairs(buttonConfig.customItems) do
										itemID = tonumber(itemID)
										if itemID then
											buttonConfig.customItems[i] = itemID

											local row = AceGUI:Create("SimpleGroup")
											row:SetLayout("flow")
											row:SetFullWidth(true)
											listContainer:AddChild(row)

											local label = AceGUI:Create("Label")
											local text, isLoaded = GetCustomItemDisplay(itemID)
											label:SetText(text)
											label:SetRelativeWidth(0.8)
											label:SetFontObject(GameFontHighlight)
											label:SetHeight(38)
											label:SetJustifyV("MIDDLE")
											row:AddChild(label)

											if not isLoaded then
												RequestCustomItemLoad(itemID)
											end

											local removeBtn = AceGUI:Create("Button")
											removeBtn:SetText("Delete")
											removeBtn:SetRelativeWidth(0.15)
											removeBtn:SetCallback("OnClick", function()
												table.remove(buttonConfig.customItems, i)
												RefreshList()
												ApplyIconConfigUpdate()
											end)
											row:AddChild(removeBtn)
										end
									end

									listContainer:DoLayout()
									iconSettingsTabs:DoLayout()
									scrollFrame:DoLayout()
								end

								local addItemButton = AceGUI:Create("EditBox")
								addItemButton:SetRelativeWidth(0.8)
								addItemButton:SetLabel("Add Fallback Item IDs")
								addItemButton:SetCallback("OnEnterPressed", function(self, _, value)
									local itemID = value and tonumber(value)
									if itemID and itemID > 0 then
										table.insert(buttonConfig.customItems, itemID)
										self:SetText("")
										RefreshList()
										ApplyIconConfigUpdate()
									end
								end)
								iconSettingsTabs:AddChild(addItemButton)
								iconSettingsTabs:AddChild(listContainer)

								RefreshList()
							elseif group == "filter" then
								buttonConfig.filterItems = buttonConfig.filterItems or {}
								buttonConfig.filterItemsArray = buttonConfig.filterItemsArray or {}

								local listContainer = AceGUI:Create("SimpleGroup")
								listContainer:SetLayout("flow")
								listContainer:SetFullWidth(true)

								local pendingItemLoads = {}
								local RefreshList

								local function GetCustomItemDisplay(itemID)
									local itemName = C_Item.GetItemNameByID(itemID)
									local itemTexture = C_Item.GetItemIconByID(itemID)
									local isLoaded = itemName ~= nil and itemTexture ~= nil
									itemTexture = itemTexture or 134400
									return ("|T%s:30:30:5:0:30:30:3:27:3:27|t  %s"):format(itemTexture, itemName or ("Item ID " .. itemID)), isLoaded
								end

								local function RequestCustomItemLoad(itemID)
									if pendingItemLoads[itemID] then
										return
									end

									pendingItemLoads[itemID] = true
									local item = Item:CreateFromItemID(itemID)
									item:ContinueOnItemLoad(function()
										pendingItemLoads[itemID] = nil
										if listContainer.frame and listContainer.frame:IsShown() then
											RefreshList()
										end
									end)
								end

								RefreshList = function()
									listContainer:ReleaseChildren()

									for i, itemID in ipairs(buttonConfig.filterItemsArray) do
										itemID = tonumber(itemID)
										if itemID then
											local row = AceGUI:Create("SimpleGroup")
											row:SetLayout("flow")
											row:SetFullWidth(true)
											listContainer:AddChild(row)

											local label = AceGUI:Create("Label")
											local text, isLoaded = GetCustomItemDisplay(itemID)
											label:SetText(text)
											label:SetRelativeWidth(0.8)
											label:SetFontObject(GameFontHighlight)
											label:SetHeight(38)
											label:SetJustifyV("MIDDLE")
											row:AddChild(label)

											if not isLoaded then
												RequestCustomItemLoad(itemID)
											end

											local removeBtn = AceGUI:Create("Button")
											removeBtn:SetText("Delete")
											removeBtn:SetRelativeWidth(0.15)
											removeBtn:SetCallback("OnClick", function()
												buttonConfig.filterItems[itemID] = nil
												table.remove(buttonConfig.filterItemsArray, i)
												RefreshList()
												ApplyIconConfigUpdate()
											end)
											row:AddChild(removeBtn)
										end
									end

									listContainer:DoLayout()
									iconSettingsTabs:DoLayout()
									scrollFrame:DoLayout()
								end

								local addItemButton = AceGUI:Create("EditBox")
								addItemButton:SetRelativeWidth(0.8)
								addItemButton:SetLabel("Add Filter Item IDs")
								addItemButton:SetCallback("OnEnterPressed", function(self, _, value)
									local itemID = value and tonumber(value)
									if itemID and itemID > 0 and not buttonConfig.filterItems[itemID] then
										buttonConfig.filterItems[itemID] = value
										tinsert(buttonConfig.filterItemsArray, itemID)

										self:SetText("")
										RefreshList()
										ApplyIconConfigUpdate()
									end
								end)
								iconSettingsTabs:AddChild(addItemButton)
								iconSettingsTabs:AddChild(listContainer)

								RefreshList()
							end

							iconSettings:DoLayout()
							scrollFrame:DoLayout()
						end)
						iconSettingsTabs:SelectTab("general")
						iconSettings:AddChild(iconSettingsTabs)
						lastButtonFrame = buttonFrame

						iconSettings:DoLayout()
						scrollFrame:DoLayout()
					end
				else
					lastButtonFrame:SetBackdropBorderColor(BLACK_FONT_COLOR:GetRGBA())
					lastButtonFrame = nil

					ShowIconSettingsMessage("|TInterface\\common\\help-i:40:40:0:0|tClick on an icon to show spell specific options.")
				end
			end
		elseif button == "RightButton" and not buttonFrame.data.isAddButton then
			local menu = MenuUtil.CreateContextMenu(nil, function(owner, rootDescription)
				rootDescription:CreateButton("Remove", function()
					if buttonFrame.data.isCustom then
						SCM:RemoveCustomIcon(buttonFrame.data.id, isGlobal, buttonFrame.data.iconType)
					else
						SCM:RemoveSpellFromConfig(currentAnchorIndex, buttonFrame.data)
					end
					horizontalScrollFrame:RemoveButton(buttonFrame.data)
					if buttonFrame.data.isCustom then
						SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
						return
					end
					ApplyModeConfigUpdate(anchorIndex, mode)
				end)
			end)
		end
	end)

	horizontalScrollFrame:SetCallback("OnRelease", function()
		if lastButtonFrame then
			lastButtonFrame:SetBackdropBorderColor(BLACK_FONT_COLOR:GetRGBA())
		end
	end)

	horizontalScrollFrame:SetCallback("OnDragStop", function(self, event, collection)
		for i, entry in ipairs(collection) do
			if entry.isCustom and entry.id then
				local customConfig = SCM:GetConfigTableByID(entry.id, entry.iconType, isGlobal)
				if customConfig and customConfig.anchorGroup == anchorIndex then
					customConfig.order = i

					local customFrames = SCM.CustomIcons.GetCustomIconFrames(customConfig)
					if customFrames and customFrames[entry.id] then
						customFrames[entry.id].SCMOrder = i
					end
				end
			elseif entry.spellID and entry.spellID > 0 then
				local spellConfig = entry.id and SCM.spellConfig[entry.id]
				if spellConfig and spellConfig.anchorGroup[currentAnchorIndex] then
					spellConfig.anchorGroup[currentAnchorIndex].order = i
				end
			end
		end
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)

	top:AddChild(horizontalScrollFrame)
	top:ResumeLayout()
	top:DoLayout()

	scrollFrame:DoLayout()
	--scrollFrame:FixScroll()
	--scrollFrame:SetScroll(0)

	RunNextFrame(function()
		horizontalScrollFrame.scrollbar:ScrollToEnd()
		horizontalScrollFrame.scrollbar:ScrollToBegin()
	end)
end

local function CreateAnchorTabGroup(parent, frame, mode)
	parent:ReleaseChildren()

	local isGlobal = mode == "global"
	local isBuffBar = mode == "buffbars"

	local anchorTabs = AceGUI:Create("TabGroup")
	anchorTabs:SetLayout("fill")
	anchorTabs:SetFullWidth(true)
	anchorTabs:SetFullHeight(true)
	anchorTabs.frame:SetPoint("TOPLEFT", parent.frame, "TOPLEFT", 0, -30)
	anchorTabs.frame:SetPoint("BOTTOMRIGHT", parent.frame, "BOTTOMRIGHT", 0, -5)
	anchorTabs.frame:SetParent(parent.frame)
	anchorTabs.frame:Show()

	local sourceConfig = (isGlobal and SCM.globalAnchorConfig) or (isBuffBar and SCM.buffBarsAnchorConfig) or SCM.anchorConfig
	local anchorTabsTbl = {}
	for i in ipairs(sourceConfig) do
		tinsert(anchorTabsTbl, { value = i, text = "Anchor " .. i })
	end

	anchorTabs:SetTabs(anchorTabsTbl)
	anchorTabs:SetCallback("OnGroupSelected", function(self, event, anchorIndex)
		SelectAnchor(self, parent, anchorIndex, anchorTabsTbl, mode)
	end)
	parent:AddChild(anchorTabs)
	anchorTabs:SelectTab(1)
end

local function GetCopyClassList()
	return SCM.Utils.GetClassList(false)
end

local function GetCopySpecList(classFileName)
	return SCM.Utils.GetSpecList(classFileName)
end

local function CreateCopyAnchorTab(widget, frame, modeTabs)
	widget:ReleaseChildren()

	local currentClass = SCM.currentClass
	local currentSpecID = SCM.currentSpecID
	-- Use the live player API so we don't depend on copyClassFileNameToID being pre-populated.
	local _, currentSpecName = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
	local targetSpecDisplay = currentSpecName or tostring(currentSpecID)

	-- Populate the class list (also seeds the classFileNameToID lookup used by GetCopySpecList).
	local classList = GetCopyClassList()

	local outerGroup = AceGUI:Create("SimpleGroup")
	outerGroup:SetFullWidth(true)
	outerGroup:SetLayout("flow")
	widget:AddChild(outerGroup)

	local targetLabel = AceGUI:Create("Label")
	targetLabel:SetFullWidth(true)
	targetLabel:SetText("|cFFAAAAAACopy Anchors To |r " .. (classList[currentClass] or currentClass) .. " - " .. targetSpecDisplay)
	targetLabel:SetJustifyH("CENTER")
	targetLabel:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
	outerGroup:AddChild(targetLabel)

	local infoLabel = AceGUI:Create("Label")
	infoLabel:SetFullWidth(true)
	infoLabel:SetText("This will only copy across anchors and their layout, spells / icons are not copied.")
	infoLabel:SetJustifyH("CENTER")
	infoLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	outerGroup:AddChild(infoLabel)

	local copyFromGroup = AceGUI:Create("InlineGroup")
	copyFromGroup:SetFullWidth(true)
	copyFromGroup:SetTitle("Copy From")
	copyFromGroup:SetLayout("flow")
	outerGroup:AddChild(copyFromGroup)

	local selectedClass = nil
	local selectedSpecID = nil
	local selectedSpecDisplay = nil

	local copyBtn

	local function RefreshCopyButton()
		if not copyBtn then
			return
		end
		local isSelf = selectedClass == currentClass and selectedSpecID == currentSpecID
		local isValid = selectedClass ~= nil and selectedSpecID ~= nil and not isSelf
		copyBtn:SetDisabled(not isValid)
		if isSelf then
			copyBtn:SetText("Cannot Copy to the Same Specialization")
		else
			copyBtn:SetText("Copy Anchors")
		end
	end

	local specDropdown = AceGUI:Create("Dropdown")
	specDropdown:SetRelativeWidth(0.5)
	specDropdown:SetLabel("Specialization")
	specDropdown:SetList({})
	specDropdown:SetDisabled(true)
	specDropdown.text:SetJustifyH("LEFT")

	local classDropdown = AceGUI:Create("Dropdown")
	classDropdown:SetRelativeWidth(0.5)
	classDropdown:SetLabel("Class")
	classDropdown:SetList(classList)
	classDropdown.text:SetJustifyH("LEFT")
	classDropdown:SetCallback("OnValueChanged", function(_, _, value)
		selectedClass = value
		selectedSpecID = nil
		selectedSpecDisplay = nil
		local specList = GetCopySpecList(value)
		specDropdown:SetList(specList)
		specDropdown:SetValue(nil)
		specDropdown:SetDisabled(false)
		specDropdown.text:SetJustifyH("LEFT")
		RefreshCopyButton()
	end)
	copyFromGroup:AddChild(classDropdown)

	specDropdown:SetCallback("OnValueChanged", function(_, _, value)
		selectedSpecID = value
		local specList = GetCopySpecList(selectedClass)
		selectedSpecDisplay = specList[value]
		RefreshCopyButton()
	end)
	copyFromGroup:AddChild(specDropdown)

	copyBtn = AceGUI:Create("Button")
	copyBtn:SetText("Copy Anchors")
	copyBtn:SetFullWidth(true)
	copyBtn:SetDisabled(true)
	copyBtn:SetCallback("OnClick", function()
		StaticPopup_Show("SCM_CONFIRM_COPY_ANCHORS", selectedSpecDisplay or tostring(selectedSpecID), targetSpecDisplay, {
			callback = function()
				SCM:CopyAnchorConfig(selectedClass, selectedSpecID)
				modeTabs:SelectTab("spec")
			end,
		})
	end)
	copyFromGroup:AddChild(copyBtn)
end

local function CDM(self, frame, group)
	local modeTabs = AceGUI:Create("TabGroup")
	modeTabs:SetLayout("fill")
	modeTabs:SetFullWidth(true)
	modeTabs:SetFullHeight(true)

	local tabs = {
		{ value = "spec", text = "|cFFFFFFFFSpecialization|r: Icons" },
		{ value = "buffbars", text = "|cFFFFFFFFSpecialization|r: Bars" },
		{ value = "global", text = "|cFFFFFFFFGlobal|r: Icons" },
		{ value = "copy", text = "|cFFFFFFFFCopy|r Anchors" },
	}

	modeTabs:SetTabs(tabs)
	modeTabs:SetCallback("OnGroupSelected", function(widget, event, mode)
		if mode == "copy" then
			CreateCopyAnchorTab(widget, frame, modeTabs)
		else
			CreateAnchorTabGroup(widget, frame, mode)
		end
	end)
	modeTabs:SelectTab("spec")
	self:AddChild(modeTabs)

	self.typeTab = modeTabs
end

SCM.MainTabs.CDM.callback = CDM
