local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local Utils = SCM.Utils
local AceGUI = LibStub("AceGUI-3.0")

local stateTypeTree = {
	{ value = "visibility", text = "Visibility" },
	{ value = "desaturate", text = "Desaturate" },
	{ value = "glow", text = "Glow" },
	{ value = "border", text = "Border" },
	{ value = "cooldown", text = "Cooldown" },
}

local buffBarTabs = {
	{ value = "general", text = "General" },
	{ value = "subregion", text = "Subregions (Alpha)" },
	{
		value = "state",
		text = "States (Alpha)",
		children = {
			{ value = "visibility", text = "Visibility" },
			{ value = "glow", text = "Glow" },
			{ value = "border", text = "Border" },
		},
	},
}

local iconTypeTabs = {
	all = {
		{ value = "general", text = "General" },
		{ value = "subregion", text = "Subregions (Alpha)" },
		{ value = "state", text = "States (Alpha)", children = stateTypeTree },
		{ value = "cooldown", text = "Cooldown" },
		{ value = "load", text = "Load Conditions" },
	},
	spell = {
		{ value = "display", text = "Display" },
	},
	item = {
		{ value = "display", text = "Display" },
		{ value = "items", text = "Items" },
	},
	timer = {},
	bloodlust = {
		{ value = "display", text = "Display" },
		{ value = "state", text = "States (Alpha)", children = stateTypeTree },
		{ value = "load", text = "Load Conditions" },
	},
	slot = {
		{ value = "filter", text = "Filter" },
	},
}
for iconType, options in pairs(iconTypeTabs) do
	if iconType ~= "all" and iconType ~= "bloodlust" then
		for i = #iconTypeTabs.all, 1, -1 do
			tinsert(options, 1, iconTypeTabs.all[i])
		end
	end
end

function CDMOptions.CreateSpellConfigTabs(parentScrollFrame, iconSettings, buttonFrame, anchorIndex, mode, isGlobal, isBuffBar)
	local buttonData = buttonFrame.data
	local iconConfig

	if buttonData.isCustom then
		iconConfig = SCM:GetConfigTableByID(buttonData.id, buttonData.iconType, isGlobal, isBuffBar)
	else
		iconConfig = SCM:GetSpellConfigForGroup(buttonData.id, isBuffBar and Utils.ToBuffBarGroup(anchorIndex) or anchorIndex)
	end

	if not iconConfig then
		CDMOptions.ShowIconSettingsMessage(iconSettings, parentScrollFrame, "|TInterface\\common\\help-i:40:40:0:0|tThis icon could not be resolved for the current anchor.")
		return
	end

	buttonFrame:SetBackdropBorderColor(0, 1, 0, 1)

	if iconConfig then
		local selectedIconText = AceGUI:Create("Heading")
		selectedIconText:SetRelativeWidth(1)
		iconSettings:AddChild(selectedIconText)

		if buttonData.iconType == "bloodlust" then
			selectedIconText:SetText("Bloodlust")
		elseif buttonData.spellID and buttonData.spellID > 0 then
			selectedIconText:SetText(string.format("|T%d:0|t%s (%d)", buttonData.texture, C_Spell.GetSpellName(buttonData.spellID), buttonData.spellID))
		elseif buttonData.itemID then
			selectedIconText:SetText(string.format("|T%d:0|t%s (%d)", buttonData.texture, C_Item.GetItemNameByID(buttonData.itemID), buttonData.itemID))
		elseif buttonData.slotID then
			selectedIconText:SetText("Slot ID " .. buttonData.slotID)
		end

		local iconSettingsTabs = AceGUI:Create("TreeGroup")
		iconSettingsTabs:SetLayout("flow")
		iconSettingsTabs:SetFullWidth(true)
		iconSettingsTabs:SetHeight(410)
		iconSettingsTabs:SetAutoAdjustHeight(false)
		iconSettingsTabs:SetTree(isBuffBar and buffBarTabs or iconTypeTabs[buttonData.iconType])
		iconSettingsTabs:SetCallback("OnGroupSelected", function(self, _, group)
			self:ReleaseChildren()
			local stateType = group:match("%c([^%c]+)$")

			if group == "general" then
				CDMOptions.CreateGeneralTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "cooldown" then
				CDMOptions.CreateCooldownTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "display" then
				CDMOptions.CreateDisplayTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "load" then
				CDMOptions.CreateLoadTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "state" then
				self:SelectByPath("state", "visibility")
				return
			elseif stateType then
				CDMOptions.ShowIconSettingsMessage(self, iconSettingsTabs, "|TInterface\\common\\help-i:40:40:0:0|tThese options are subject to change.")
				CDMOptions.CreateStateTabSettings(self, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar, stateType)
			elseif group == "subregion" then
				CDMOptions.ShowIconSettingsMessage(self, iconSettingsTabs, "|TInterface\\common\\help-i:40:40:0:0|tThese options are subject to change.")
				CDMOptions.CreateSubregionTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "items" then
				CDMOptions.CreateItemsTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "filter" then
				CDMOptions.CreateFilterTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			end

			iconSettings:DoLayout()
			parentScrollFrame:DoLayout()
		end)

		if buttonData.iconType == "bloodlust" then
			iconSettingsTabs:SelectByValue("glow")
		else
			iconSettingsTabs:SelectByValue("general")
		end
		iconSettings:AddChild(iconSettingsTabs)

		iconSettings:DoLayout()
		parentScrollFrame:DoLayout()

		return buttonFrame
	end
end
