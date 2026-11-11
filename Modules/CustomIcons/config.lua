local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local LoadConditions = SCM.LoadConditions

function SCM:CreateAllCustomIcons(iconType)
	CustomIcons.RebuildCustomIconLoadCache()

	for _, customConfig in pairs(self.customConfig) do
		CustomIcons.CreateIcons(customConfig, false, iconType)
	end

	for _, customConfig in pairs(self.globalCustomConfig) do
		CustomIcons.CreateIcons(customConfig, true, iconType)
	end
end

function SCM:AddCustomIcon(anchorGroup, iconType, configID, order, uniqueID, isGlobal)
	local configTable = SCM:GetConfigTable(iconType, isGlobal)
	if not configTable then
		return
	end

	local configKey = iconType == "item" and "itemID" or iconType == "slot" and "slotID" or "spellID"
	for _, entry in pairs(configTable) do
		if entry.anchorGroup == anchorGroup and entry[configKey] == configID then
			return
		end
	end

	uniqueID = uniqueID or SCM:GetUniqueID(configID, iconType, isGlobal)

	if not order then
		order = 1
		for _, entry in pairs(configTable) do
			if entry.anchorGroup == anchorGroup and (entry.order or 0) >= order then
				order = (entry.order or 0) + 1
			end
		end
	end

	local visibilityRules
	if iconType == "item" then
		visibilityRules = {
			{ state = "noitem", value = "hide" },
		}
	elseif iconType == "timer" or iconType == "bloodlust" then
		visibilityRules = {
			{ state = "active", value = "show" },
			{ state = "inactive", value = "hide" },
		}
	end

	local desaturateRules
	if iconType == "timer" or iconType == "bloodlust" then
		desaturateRules = {
			{ state = "active", enabled = false },
			{ state = "inactive", enabled = true },
		}
	else
		desaturateRules = {
			{ state = "cooldown", enabled = true },
		}
	end

	configTable[uniqueID] = {
		id = uniqueID,
		iconType = iconType,
		spellID = (iconType == "spell" or iconType == "timer" or iconType == "bloodlust") and configID or nil,
		itemID = iconType == "item" and configID or nil,
		slotID = iconType == "slot" and configID or nil,
		anchorGroup = anchorGroup,
		order = order,
		useLoadClass = false,
		loadClasses = LoadConditions.GetDefaultLoadClasses(),
		useLoadRace = false,
		loadRaces = LoadConditions.GetDefaultLoadRaces(),
		useLoadRole = false,
		loadRoles = { ["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false },
		useSpellKnown = false,
		effectRules = {
			visibility = {
				rules = visibilityRules,
			},
			desaturate = {
				rules = desaturateRules,
			},
		},
	}

	self:CreateAllCustomIcons(iconType)

	return uniqueID
end

function SCM:RemoveCustomIcon(id, isGlobal, iconType)
	local configTable = SCM:GetConfigTable(iconType, isGlobal)
	if configTable and configTable[id] then
		local config = configTable[id]
		configTable[id] = nil

		CustomIcons.ReleaseIcon(id, config)
		self:CreateAllCustomIcons(iconType)
	end
end
