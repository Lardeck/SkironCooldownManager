local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local Utils = SCM.Utils
local AceGUI = LibStub("AceGUI-3.0")

local iconTypeTabs = {
	all = {
		{ value = "general", text = "General" },
		{ value = "display", text = "Display" },
		{ value = "cooldown", text = "Cooldown" },
		{ value = "subregion", text = "Subregions (NYI)" },
		{ value = "state", text = "States (NYI)" },
		{ value = "load", text = "Load Conditions" },
	},
	spell = {},
	item = {
		{ value = "items", text = "Items" },
	},
	timer = {},
	bloodlust = { { value = "glow", text = "Glow" } },
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

	-- if buttonData.iconType == "bloodlust" then
	-- 	iconSettings:SetTitle("Bloodlust")
	-- elseif buttonData.spellID and buttonData.spellID > 0 then
	-- 	iconSettings:SetTitle(C_Spell.GetSpellName(buttonData.spellID))
	-- elseif buttonData.itemID then
	-- 	iconSettings:SetTitle(C_Item.GetItemNameByID(buttonData.itemID))
	-- elseif buttonData.slotID then
	-- 	iconSettings:SetTitle("Slot ID " .. buttonData.slotID)
	-- end

	if iconConfig then
		local maxHeight

		local iconSettingsTabs = AceGUI:Create("TreeGroup")
		iconSettingsTabs:SetLayout("flow")
		iconSettingsTabs:SetFullWidth(true)
		iconSettingsTabs:SetHeight(410)
		iconSettingsTabs:SetAutoAdjustHeight(false)
		iconSettingsTabs:SetTree(isBuffBar and { { value = "general", text = "General" } } or iconTypeTabs[buttonData.iconType])
		iconSettingsTabs:SetCallback("OnGroupSelected", function(self, _, group)
			self:ReleaseChildren()

			if group == "general" then
				CDMOptions.CreateGeneralTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "cooldown" then
				CDMOptions.CreateCooldownTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "visibility" then
				CDMOptions.CreateVisibilityTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "display" then
				CDMOptions.CreateDisplayTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "load" then
				CDMOptions.CreateLoadTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "glow" then
				CDMOptions.CreateGlowTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "state" then
				CDMOptions.CreateStateTabSettings(self, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "subregion" then
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
