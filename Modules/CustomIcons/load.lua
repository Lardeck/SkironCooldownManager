local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local Utils = SCM.Utils
local GetIconType = Utils.GetIconType
local CustomIconAlwaysVisibilityConfigs = CustomIcons.AlwaysVisibilityConfigs

function CustomIcons.HasAlwaysVisibilityRule(config)
	local visibilityRules = config.effectRules and config.effectRules.visibility
	local rules = visibilityRules and visibilityRules.rules
	if not rules then
		return
	end

	for i = 1, #rules do
		if rules[i].state == "always" then
			return true
		end
	end
end

function CustomIcons.ShouldCreateCustomIcon(config)
	local iconType = GetIconType(config)
	if iconType == "empty" then
		return true
	end

	local hasAlwaysVisibility = CustomIconAlwaysVisibilityConfigs[config]

	if iconType == "spell" or iconType == "timer" or iconType == "bloodlust" then
		return config.spellID and (hasAlwaysVisibility or C_Spell.DoesSpellExist(config.spellID))
	end

	if iconType == "item" then
		return config.itemID and (hasAlwaysVisibility or C_Item.DoesItemExistByID(config.itemID))
	end

	if iconType == "slot" and config.slotID then
		local itemID = GetInventoryItemID("player", config.slotID)
		return itemID and (not config.filterItems or not config.filterItems[itemID]) and C_Item.DoesItemExistByID(itemID) and (hasAlwaysVisibility or C_Item.GetItemSpell(itemID))
	end
end
