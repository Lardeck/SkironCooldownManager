local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM

local Utils = SCM.Utils
local GetCooldownConfigKey = Utils.GetCooldownConfigKey

local colorKnown = "ffffff"
local colorUnknown = "808080"
local colorDisabled = "ff0000"

local customButtonConfigs = {
	{
		text = "Spell",
		popupKey = "SCM_CUSTOM_SPELL_ID",
		popupTitle = "Enter Spell ID",
		iconType = "spell",
	},
	{
		text = "Item",
		popupKey = "SCM_CUSTOM_ITEM_ID",
		popupTitle = "Enter Item ID",
		iconType = "item",
	},
	{
		text = "Slot",
		popupKey = "SCM_SPEC_SLOT_ID",
		popupTitle = "Enter Slot ID",
		iconType = "slot",
	},
	{
		text = "Timer",
		popupKey = "SCM_TIMER_SPELL_ID",
		popupTitle = "Enter Spell ID",
		iconType = "timer",
		tooltip = function(tooltip, elementDescription)
			GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription))
			GameTooltip_AddInstructionLine(tooltip, "Timers can only be created based on successful casts.")
		end,
	},
	{
		text = "Empty",
		iconType = "empty",
	},
}

local presetButtonConfigs = {
	["TIMERS"] = {
		{
			text = "|T136012:16:16|t Bloodlust",
			configID = 2825,
			iconType = "bloodlust",
			config = {
				duration = 40,
			},
		},
		{
			text = "|T7548911:16:16|t Light's Potential",
			configID = 1236616,
			iconType = "timer",
			config = {
				duration = 30,
			},
		},
		{
			text = "|T7548916:16:16|t Potion of Recklessness",
			configID = 1236994,
			iconType = "timer",
			config = {
				duration = 30,
			},
		},
		{
			text = "|T133876:16:16|t Algeth'ar Puzzle Box",
			configID = 383781,
			iconType = "timer",
			config = {
				duration = 20,
			},
		},
		{
			text = "|T7636709:16:16|t Light Company Guidon",
			configID = 1259633,
			iconType = "timer",
			config = {
				duration = 15,
			},
		},
		{
			text = "|T7636706:16:16|t Vaelgor's Final Stare",
			configID = 1260459,
			iconType = "timer",
			config = {
				duration = 15,
			},
		},
		{
			text = "|T2103819:16:16|t Emberwing Feather",
			configID = 1250508,
			iconType = "timer",
			config = {
				duration = 10,
			},
		},
	},
	["ITEMS"] = {
		{
			text = "|T7548909:16:16|t Silvermoon Health Potion",
			configID = 241304,
			iconType = "item",
			config = {
				customItems = {
					[1] = 241305,
				},
			},
		},
		{
			text = "|T538745:16:16|t Healthstone",
			configID = 5512,
			iconType = "item",
			config = {
				customItems = {
					[1] = 224464,
				},
			},
		},
		{
			text = "|T7548911:16:16|t Light's Potential",
			configID = 245898,
			iconType = "item",
			config = {
				customItems = {
					[1] = 245897,
					[2] = 241308,
					[3] = 241309,
				},
			},
		},
		{
			text = "|T7548916:16:16|t Potion of Recklessness",
			configID = 245902,
			iconType = "item",
			config = {
				customItems = {
					[1] = 245903,
					[2] = 241288,
					[3] = 241289,
				},
			},
		},
	},
	["RACIALS"] = {
		{
			text = "|T136225:16:16|t Stoneform",
			configID = 20594,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [3] = true },
			},
		},
		{
			text = "|T132089:16:16|t Shadowmeld",
			configID = 58984,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [4] = true },
			},
		},
		{
			text = "|T135726:16:16|t Blood Fury",
			configID = 20572,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [2] = true },
			},
		},
		{
			text = "|T135727:16:16|t Berserking",
			configID = 26297,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [8] = true },
			},
		},
		{
			text = "|T2021574:16:16|t Ancestral Call",
			configID = 274738,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [36] = true },
			},
		},
		{
			text = "|T1724004:16:16|t Spatial Rift",
			configID = 256948,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [29] = true },
			},
		},
		{
			text = "|T1786406:16:16|t Fireblood",
			configID = 265221,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [34] = true },
			},
		},
		{
			text = "|T132368:16:16|t War Stomp",
			configID = 20549,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [6] = true },
			},
		},
		{
			text = "|T4622488:16:16|t Wing Buffet",
			configID = 357214,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [52] = true, [70] = true },
			},
		},
		{
			text = "|T1723987:16:16|t Bull Rush",
			configID = 255654,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [28] = true },
			},
		},
		{
			text = "|T132309:16:16|t Escape Artist",
			configID = 20589,
			iconType = "spell",
			config = {
				useLoadRace = true,
				loadRaces = { [7] = true },
			},
		},
	},
}

local function GetSpellIDForCooldownInfo(cooldownInfo)
	if cooldownInfo then
		return cooldownInfo.linkedSpellID or cooldownInfo.overrideTooltipSpellID or cooldownInfo.overrideSpellID or cooldownInfo.spellID
	end
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

local function BuildIconData(configID, iconType)
	if iconType == "spell" or iconType == "timer" or iconType == "bloodlust" then
		local texture = C_Spell.GetSpellTexture(configID)
		if not texture then
			return
		end

		return {
			texture = texture,
			spellID = configID,
		}
	elseif iconType == "item" then
		local texture = C_Item.GetItemIconByID(configID)
		if not texture then
			return
		end

		return {
			texture = texture,
			spellID = 0,
			itemID = configID,
		}
	elseif iconType == "slot" then
		if configID < 1 or configID > 19 then
			return
		end

		return {
			texture = GetInventoryItemTexture("player", configID) or 134400,
			spellID = 0,
			slotID = configID,
		}
	elseif iconType == "empty" then
		return {
			texture = 134400,
		}
	end
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

local function CreateCustomIconButton(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfig)
	local button = rootDescription:CreateButton(buttonConfig.text, function()
		local function AddCustomIcon(configID)
			local iconData

			if buttonConfig.buildIconData then
				iconData = buttonConfig.buildIconData(configID)
			else
				iconData = BuildIconData(configID, buttonConfig.iconType)
			end

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

			if buttonConfig.config then
				local customConfig = SCM:GetConfigTableByID(uniqueID, buttonConfig.iconType, isGlobal)
				for key, value in pairs(buttonConfig.config) do
					customConfig[key] = value
				end
			end

			SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
		end

		if buttonConfig.popupKey then
			ShowNumericInputPopup(buttonConfig.popupKey, buttonConfig.popupTitle, AddCustomIcon)
		elseif buttonConfig.configID then
			AddCustomIcon(buttonConfig.configID)
		elseif buttonConfig.iconType == "empty" then
			AddCustomIcon("")
		end
	end)

	if buttonConfig.tooltip then
		button:SetTooltip(buttonConfig.tooltip)
	end
end

local function CreateCustomIconButtons(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfigs, text)
	local customButton = rootDescription:CreateButton(text)

	for _, buttonConfig in ipairs(buttonConfigs) do
		CreateCustomIconButton(customButton, scrollFrame, anchorIndex, isGlobal, buttonConfig)
	end

	return customButton
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

local function ProcessAndCreateButtons(parentButton, items, isBuffIcon, scrollFrame, anchorIndex, mode)
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
			local button = parentButton:CreateButton(string.format("|T%d:0|t |cff%s%s (%d)|r", C_Spell.GetSpellTexture(info.spellID), activeColor, C_Spell.GetSpellName(info.spellID), info.spellID), function(info)
				if not CDMOptions.IsSpellInData(info.cooldownID, info.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, info.configID, info.cooldownID) then
					local dataIndex = scrollFrame:AddSpellBySpellID(info)
					SCM:AddSpellToConfig(anchorIndex, dataIndex, info, data, item.targetCategory, isBuffIcon)
					Options.ApplyModeConfigUpdate(anchorIndex, mode)
				end
				return MenuResponse.Open
			end, info)
			button:SetTooltip(function(tooltip, elementDescription)
				tooltip:SetSpellByID(info.spellID)
			end)
		end
	end
end

local function CreateIconButtons(rootDescription, scrollFrame, anchorIndex, mode, buttonName, targetCategory, isBuffIcon, predicate, ...)
	local dataProvider = CooldownViewerSettings:GetDataProvider()
	local cooldownInfoByID = dataProvider and dataProvider.displayData.cooldownInfoByID

	local button = rootDescription:CreateButton(buttonName)

	local items = {}
	for _, categoryID in ipairs({ ... }) do
		local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(categoryID, true)
		for _, cooldownID in ipairs(cooldownIDs) do
			local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
			local data = cooldownInfoByID[cooldownID]

			if info and data and (not predicate or predicate(categoryID, data)) then
				local spellID = GetSpellIDForCooldownInfo(info)
				local configID = GetCooldownConfigKey(cooldownID)
				info.spellID = spellID

				if configID and not CDMOptions.IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
					table.insert(items, { info = info, data = data, cooldownID = cooldownID, targetCategory = targetCategory })
				end
			end
		end
	end

	button:SetGridMode(MenuConstants.VerticalGridDirection, floor(#items / 15) + 1)
	ProcessAndCreateButtons(button, items, isBuffIcon, scrollFrame, anchorIndex, mode)
end

local function CreateBuffBarIconButtons(rootDescription, scrollFrame, anchorIndex, mode)
	local dataProvider = CooldownViewerSettings:GetDataProvider()
	local cooldownInfoByID = dataProvider and dataProvider.displayData.cooldownInfoByID

	if cooldownInfoByID then
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

				if configID and not CDMOptions.IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
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

				if configID and not CDMOptions.IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
					table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 3 })
				end
			end
		end

		buffButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#buffItems / 15) + 1)

		ProcessAndCreateButtons(buffButton, buffItems, false, scrollFrame, anchorIndex, mode)
	end
end

local function CreateCopyButtons(rootDescription, scrollFrame, anchorIndex, mode)
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

						if configID and not CDMOptions.IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
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

					Options.ApplyModeConfigUpdate(anchorIndex, mode)
				end)
			end
		end
	end
end

local function CreateExternalCustomEntries(rootDescription, scrollFrame, anchorIndex)
	for _, customEntry in pairs(SCM.CustomEntries) do
		customEntry(rootDescription, scrollFrame, anchorIndex)
	end
end

function CDMOptions.CreateAddSpellDropdown(owner, rootDescription, scrollFrame, anchorIndex, mode)
	rootDescription:CreateTitle("Add Icon")

	if mode == "global" then
		CreateCustomIconButtons(rootDescription, scrollFrame, anchorIndex, true, customButtonConfigs, "Custom")

		local presetButton = CreateCustomIconButtons(rootDescription, scrollFrame, anchorIndex, true, presetButtonConfigs, "Presets")
		CreateCustomIconButtons(presetButton, scrollFrame, anchorIndex, true, presetButtonConfigs["TIMERS"], "|T237538:16:16|t Timers")
		CreateCustomIconButtons(presetButton, scrollFrame, anchorIndex, true, presetButtonConfigs["ITEMS"], "|T134856:16:16|t Items")
		CreateCustomIconButtons(presetButton, scrollFrame, anchorIndex, true, presetButtonConfigs["RACIALS"], "|T135727:16:16|t Racials")
		return
	end

	if mode == "buffbars" then
		CreateBuffBarIconButtons(rootDescription, scrollFrame, anchorIndex, mode)
		return
	end

	CreateIconButtons(rootDescription, scrollFrame, anchorIndex, mode, "Essential", Enum.CooldownViewerCategory.Essential, false, nil, 0)
	CreateIconButtons(rootDescription, scrollFrame, anchorIndex, mode, "Utility", Enum.CooldownViewerCategory.Utility, false, nil, 1)
	CreateIconButtons(rootDescription, scrollFrame, anchorIndex, mode, "Buff", Enum.CooldownViewerCategory.TrackedBuff, true, function(categoryID, data)
		return categoryID == 2 or (categoryID == 3 and (type(data.category) == "number" and data.category <= 3))
	end, 2, 3)

	rootDescription:CreateDivider()

	CreateCustomIconButtons(rootDescription, scrollFrame, anchorIndex, false, customButtonConfigs, "Custom")

	local presetButton = CreateCustomIconButtons(rootDescription, scrollFrame, anchorIndex, false, presetButtonConfigs, "Presets")
	CreateCustomIconButtons(presetButton, scrollFrame, anchorIndex, false, presetButtonConfigs["TIMERS"], "|T237538:16:16|t Timers")
	CreateCustomIconButtons(presetButton, scrollFrame, anchorIndex, false, presetButtonConfigs["ITEMS"], "|T134856:16:16|t Items")
	
	CreateCopyButtons(rootDescription, scrollFrame, anchorIndex, mode)
	CreateExternalCustomEntries(rootDescription, scrollFrame, anchorIndex)
end
