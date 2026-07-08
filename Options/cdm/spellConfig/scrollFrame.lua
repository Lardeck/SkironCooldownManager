local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")

local function SortByIndex(a, b)
	return a.dataIndex < b.dataIndex
end

local function SortByOrder(a, b)
	return a.order < b.order
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

local function AddCDMIcons(spells, currentAnchorIndex)
	local spellConfig = SCM.spellConfig
	if not spellConfig then
		return
	end

	local defaultCooldownViewerConfig = SCM.defaultCooldownViewerConfig

	for configID, config in pairs(spellConfig) do
		local anchorConfig = config.anchorGroup[currentAnchorIndex]
		if anchorConfig then
			for sourceIndex, sourceAnchorIndex in pairs(config.source) do
				if sourceAnchorIndex == currentAnchorIndex then
					local data = GetDisplayDataForSpellConfig(defaultCooldownViewerConfig, sourceIndex, configID, config)
					if data then
						spells[#spells + 1] = {
							order = anchorConfig.order,
							spellID = data.spellID,
							linkedSpellIDs = data.linkedSpellIDs,
							isKnown = data.isKnown,
							category = data.category,
							cooldownID = data.cooldownID,
							configID = configID,
							isBuffIcon = sourceIndex >= 2,
						}
						break
					end
				end
			end
		end
	end
end

local function AddCustomIcons(spells, customConfig, anchorIndex)
	for _, config in pairs(customConfig) do
		if config.anchorGroup == anchorIndex then
			local iconType = config.iconType or (config.spellID and "spell") or "item"
			local texture

			if iconType == "spell" or iconType == "timer" or iconType == "bloodlust" then
				texture = config.spellID and C_Spell.GetSpellTexture(config.spellID)
			elseif iconType == "slot" then
				texture = config.slotID and GetInventoryItemTexture("player", config.slotID) or 134400
			elseif iconType == "item" then
				texture = config.itemID and C_Item.GetItemIconByID(config.itemID)
			end

			if texture or SCM.isOptionsOpen then
				spells[#spells + 1] = {
					order = config.order,
					texture = texture or 134400,
					spellID = config.spellID or 0,
					itemID = config.itemID,
					slotID = config.slotID,
					iconType = iconType,
					id = config.id,
					isCustom = true,
				}
			end
		end
	end
end

local function GetSpellsForAnchor(anchorIndex, currentAnchorIndex, isGlobal, isBuffBar)
	local spells = {}
	if not isGlobal then
		AddCDMIcons(spells, currentAnchorIndex)
	end

	if isGlobal then
		for _, customConfig in pairs(SCM.globalCustomConfig) do
			AddCustomIcons(spells, customConfig, anchorIndex)
		end
	elseif not isBuffBar then
		for _, customConfig in pairs(SCM.customConfig) do
			AddCustomIcons(spells, customConfig, anchorIndex)
		end
	end

	table.sort(spells, SortByOrder)
	return spells
end

function CDMOptions.CreateSpellConfigScrollFrame(anchorIndex, mode, spellConfigTab, anchorOptions, parentScrollFrame)
	local currentAnchorIndex = Options.GetEffectiveAnchorGroup(anchorIndex, mode)
	local isGlobal = mode == "global"
	local isBuffBar = mode == "buffbars"

	local scrollFrame = AceGUI:Create("SCMHorizontalScrollFrame")
	scrollFrame:SetHeight(86)
	scrollFrame:SetFullWidth(true)

	scrollFrame:SetSortComparator(SortByIndex)

	local spells = GetSpellsForAnchor(anchorIndex, currentAnchorIndex, isGlobal, isBuffBar)

	for _, spellInfo in ipairs(spells) do
		if spellInfo.isCustom then
			scrollFrame:AddCustomIcon(spellInfo)
		else
			scrollFrame:AddSpellBySpellID(spellInfo, spellInfo.order, spellInfo.isBuffIcon)
		end
	end

	scrollFrame:AddAddButton()

	local iconSettings = AceGUI:Create("SimpleGroup")
	iconSettings:SetLayout("flow")
	iconSettings:SetFullWidth(true)
	iconSettings:SetFullHeight(true)
	--iconSettings:SetTitle("")

	local lastButtonFrame
	scrollFrame:SetCallback("OnGroupSelected", function(_, _, buttonFrame, button)
		iconSettings:ReleaseChildren()

		if lastButtonFrame then
			lastButtonFrame:SetBackdropBorderColor(BLACK_FONT_COLOR:GetRGBA())
		end

		if button == "LeftButton" then
			if buttonFrame.data.isAddButton then
				local menu = MenuUtil.CreateContextMenu(nil, function(owner, rootDescription)
					CDMOptions.CreateAddSpellDropdown(owner, rootDescription, scrollFrame, anchorIndex, mode)
				end)
			else
				if not lastButtonFrame or lastButtonFrame ~= buttonFrame then
					lastButtonFrame = CDMOptions.CreateSpellConfigTabs(parentScrollFrame, iconSettings, buttonFrame, anchorIndex, mode, isGlobal, isBuffBar)
				else
					lastButtonFrame:SetBackdropBorderColor(BLACK_FONT_COLOR:GetRGBA())
					lastButtonFrame = nil

					CDMOptions.ShowIconSettingsMessage(iconSettings, spellConfigTab, "|TInterface\\common\\help-i:40:40:0:0|tClick on an icon to show spell specific options.")
				end
			end

			spellConfigTab:DoLayout()
			anchorOptions:DoLayout()
		elseif button == "RightButton" and not buttonFrame.data.isAddButton then
			local menu = MenuUtil.CreateContextMenu(nil, function(owner, rootDescription)
				rootDescription:CreateButton("Remove", function()
					if buttonFrame.data.isCustom then
						SCM:RemoveCustomIcon(buttonFrame.data.id, isGlobal, buttonFrame.data.iconType)
					else
						SCM:RemoveSpellFromConfig(currentAnchorIndex, buttonFrame.data)
					end
					scrollFrame:RemoveButton(buttonFrame.data)
					if buttonFrame.data.isCustom then
						SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
						return
					end
					Options.ApplyModeConfigUpdate(anchorIndex, mode)
				end)
			end)
		end
	end)

	scrollFrame:SetCallback("OnRelease", function()
		if lastButtonFrame then
			lastButtonFrame:SetBackdropBorderColor(BLACK_FONT_COLOR:GetRGBA())
		end
	end)

	scrollFrame:SetCallback("OnDragStop", function(self, event, collection)
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
		Options.ApplyModeConfigUpdate(anchorIndex, mode)
	end)

	spellConfigTab:AddChild(scrollFrame)
	spellConfigTab:AddChild(iconSettings)

	CDMOptions.ShowIconSettingsMessage(iconSettings, spellConfigTab, "|TInterface\\common\\help-i:40:40:0:0|tClick on an icon above to show spell specific options.")

	RunNextFrame(function()
		scrollFrame.scrollbar:ScrollToEnd()
		scrollFrame.scrollbar:ScrollToBegin()
	end)
end
