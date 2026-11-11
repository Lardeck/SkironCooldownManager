local SCM = select(2, ...)
local Options = SCM.Options

Options.CDM = {}
local CDMOptions = Options.CDM

local AceGUI = LibStub("AceGUI-3.0")
local Utils = SCM.Utils

SCM.MainTabs.CDM = { value = "CDM", text = "Cooldown Manager", order = 2, subgroups = {} }

local function GetSpellAnchorGroupConfig(order, sourceIndex)
	if
		sourceIndex ~= Enum.CooldownViewerCategory.TrackedBuff
		and sourceIndex ~= Enum.CooldownViewerCategory.TrackedBar
		and sourceIndex ~= Enum.CooldownViewerCategory.SpecAgnosticTracked
		and sourceIndex ~= Enum.CooldownViewerCategory.EquipSlotTracked
	then
		return {
			order = order,
			useSpellKnown = false,
			effectRules = {
				desaturate = {
					rules = {
						{
							state = "active",
							enabled = false,
						},
						{
							state = "cooldown",
							enabled = true,
							elseIf = true,
						},
					},
				},
			},
		}
	end

	return {
		order = order,
		useSpellKnown = false,
		effectRules = {
			visibility = {
				rules = {
					{
						state = "active",
						value = "show",
					},
					{
						state = "inactive",
						value = "hide",
					},
				},
			},
			desaturate = {
				rules = {
					{
						state = "active",
						enabled = false,
					},
				},
			},
		},
	}
end

function SCM:AddSpellToConfig(anchorGroup, order, info, displayData, sourceIndex)
	local spellID = displayData.spellID
	if displayData.linkedSpellIDs and #displayData.linkedSpellIDs == 1 then
		spellID = displayData.linkedSpellIDs[1]
	end

	local effectiveAnchorGroup = anchorGroup
	if sourceIndex == Enum.CooldownViewerCategory.TrackedBar then
		effectiveAnchorGroup = Utils.NormalizeBuffBarGroup(anchorGroup)
		if not effectiveAnchorGroup then
			return
		end
	end

	local cooldownID = displayData.cooldownID or info.cooldownID
	local configID = Utils.GetCooldownConfigKey(cooldownID)
	if not configID then
		return
	end

	if not self.spellConfig[configID] then
		self.spellConfig[configID] = {
			spellID = spellID,
			cooldownID = cooldownID,
			source = {
				[sourceIndex] = effectiveAnchorGroup,
			},
			anchorGroup = {
				[effectiveAnchorGroup] = GetSpellAnchorGroupConfig(order, sourceIndex),
			},
		}
	else
		self.spellConfig[configID].spellID = spellID
		self.spellConfig[configID].cooldownID = cooldownID or self.spellConfig[configID].cooldownID
		self.spellConfig[configID].source[sourceIndex] = effectiveAnchorGroup
		self.spellConfig[configID].anchorGroup[effectiveAnchorGroup] = GetSpellAnchorGroupConfig(order, sourceIndex)
	end
end

function SCM:RemoveSpellFromConfig(anchorIndex, data)
	local configID = data.id or Utils.GetCooldownConfigKey(data.cooldownID)
	local spellConfig = configID and self.spellConfig[configID]
	if spellConfig then
		for category, anchorGroup in pairs(spellConfig.source) do
			if anchorGroup == anchorIndex then
				spellConfig.source[category] = nil
			end
		end

		spellConfig.anchorGroup[anchorIndex] = nil

		if not next(spellConfig.anchorGroup) then
			self.spellConfig[configID] = nil
		end
	end
end

function CDMOptions.IsSpellInData(cooldownID, source)
	local configID = Utils.GetCooldownConfigKey(cooldownID)
	local spellConfig = configID and SCM.spellConfig[configID]
	local pairedSource = Utils.GetPairedSource(source)
	return spellConfig and (spellConfig.source[source] or (pairedSource and spellConfig.source[pairedSource]))
end

function CDMOptions.ShowIconSettingsMessage(parentWidget, scrollFrame, message)
	--parentWidget:SetTitle("")

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText(message)
	label:SetFontObject("Game12Font")
	parentWidget:AddChild(label)

	parentWidget:DoLayout()
	scrollFrame:DoLayout()
end

function CDMOptions.GetItemIconData(info, category, activeColor, trinketIndex)
	local texture, buttonName

	if info.equipSlot and (info.equipSlot == 13 or info.equipSlot == 14) then
		texture = GetInventoryItemTexture("player", info.equipSlot)
		local trinketName = "Trinket " .. ((info.equipSlot == 13 and 1) or 2)
		if category == Enum.CooldownViewerCategory.EquipSlotTracked then
			trinketName = trinketName .. " - Aura " .. trinketIndex
			if info.spellID then
				texture = C_Spell.GetSpellTexture(info.spellID)
			end
		end

		buttonName = string.format("|T%d:0|t |cff%s%s|r", texture, activeColor, trinketName)
	elseif info.spellCategoryID then
		local itemName
		if info.spellCategoryID == 4 then
			texture = "Interface/ICONS/INV_POTION_114"
			itemName = "Combat Potion"
			info.tooltipTitle = COOLDOWN_VIEWER_TOOLTIP_POTION_COMBAT_TITLE
			info.tooltipDescription = COOLDOWN_VIEWER_TOOLTIP_POTION_COMBAT_DESCRIPTION

			if category == 6 then
				itemName = itemName .. " Aura"
			end
		elseif info.spellCategoryID == 30 then
			texture = "Interface/ICONS/INV_POTION_54"
			itemName = "Health Potion"
			info.tooltipTitle = COOLDOWN_VIEWER_TOOLTIP_POTION_HEALTH_TITLE
			info.tooltipDescription = COOLDOWN_VIEWER_TOOLTIP_POTION_HEALTH_DESCRIPTION
		elseif info.spellCategoryID == 1711 then
			texture = "Interface/ICONS/Warlock_ Healthstone"
			itemName = "Healthstone"
			info.tooltipItemID = 5512
		elseif info.spellCategoryID == 2566 then
			texture = "Interface/ICONS/Warlock_ Bloodstone"
			itemName = "Bloodstone"
			info.tooltipItemID = 224464
		end

		buttonName = string.format("|T%s:0|t |cff%s%s|r", texture, activeColor, itemName)
	end

	return buttonName, texture
end

function CDMOptions.GetItemIconDataFromData(data, category)
	local texture

	if data.equipSlot and (data.equipSlot == 13 or data.equipSlot == 14) then
		texture = GetInventoryItemTexture("player", data.equipSlot)
		if category == Enum.CooldownViewerCategory.EquipSlotTracked then
			if data.spellID or #data.linkedSpellIDs > 0 then
				texture = C_Spell.GetSpellTexture(data.spellID or data.linkedSpellIDs[1])
			end
		end
	elseif data.spellCategoryID then
		if data.spellCategoryID == 4 then
			texture = "Interface/ICONS/INV_POTION_114"
		elseif data.spellCategoryID == 30 then
			texture = "Interface/ICONS/INV_POTION_54"
		elseif data.spellCategoryID == 1711 then
			texture = "Interface/ICONS/Warlock_ Healthstone"
		elseif data.spellCategoryID == 2566 then
			texture = "Interface/ICONS/Warlock_ Bloodstone"
		end
	end

	return texture
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
		{ value = "auras", text = "|cFFFFFFFFSpecialization|r: Auras (SoonTM)" },
		{ value = "globalauras", text = "|cFFFFFFFFGlobal|r: Auras (SoonTM)" },
	}

	modeTabs:SetTabs(tabs)
	modeTabs:SetCallback("OnGroupSelected", function(widget, event, mode)
		if mode == "copy" then
			CDMOptions.CreateCopyAnchorTab(widget, frame, modeTabs)
		elseif mode ~= "auras" and mode ~= "globalauras" then
			CDMOptions.CreateAnchorTabGroup(widget, frame, mode)
		end
	end)
	self:AddChild(modeTabs)
	modeTabs:SelectTab("spec")

	self.typeTab = modeTabs
end

SCM.MainTabs.CDM.callback = CDM
