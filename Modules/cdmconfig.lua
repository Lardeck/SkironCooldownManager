local SCM = select(2, ...)

local Utils = SCM.Utils

local function GetSpellAnchorGroupConfig(spellConfig, group)
	return spellConfig and spellConfig.anchorGroup and spellConfig.anchorGroup[group]
end

local function CreateCustomConfigTables(customConfig)
	customConfig = customConfig or {}
	customConfig.spellConfig = GetOrCreateTableEntry(customConfig, "spellConfig")
	customConfig.itemConfig = GetOrCreateTableEntry(customConfig, "itemConfig")
	customConfig.slotConfig = GetOrCreateTableEntry(customConfig, "slotConfig")
	customConfig.timerConfig = GetOrCreateTableEntry(customConfig, "timerConfig")
	customConfig.bloodlustConfig = GetOrCreateTableEntry(customConfig, "bloodlustConfig")

	local allowedKeys = SCM.DefaultDB.profile.globalCustomConfig
	for key in pairs(customConfig) do
		if not allowedKeys[key] then
			customConfig[key] = nil
		end
	end

	return customConfig
end

local function CreateAnchorConfigTables(customConfig)
	customConfig = customConfig or {}

	if not customConfig[1] then
		customConfig[1] = {
			anchor = { "CENTER", "UIParent", "CENTER", 0, 0 },
			rowConfig = {
				[1] = {
					iconWidth = 150,
					iconHeight = 40,
					limit = 8,
				},
			},
		}
	end

	return customConfig
end

local function CreateTrackedBarSpellConfig(spellConfig)
	if type(spellConfig) ~= "table" then
		return
	end

	for _, config in pairs(spellConfig) do
		if type(config) == "table" and type(config.source) == "table" and type(config.anchorGroup) == "table" then
			local trackedBarGroup = config.source[Enum.CooldownViewerCategory.TrackedBar]
			local normalizedTrackedBarGroup = Utils.NormalizeBuffBarGroup(trackedBarGroup)
			local legacyGroup = normalizedTrackedBarGroup and (normalizedTrackedBarGroup - 200)
			local groupConfig = (trackedBarGroup and config.anchorGroup[trackedBarGroup]) or (legacyGroup and config.anchorGroup[legacyGroup])

			if trackedBarGroup ~= normalizedTrackedBarGroup then
				config.source[Enum.CooldownViewerCategory.TrackedBar] = normalizedTrackedBarGroup
			end

			if normalizedTrackedBarGroup and groupConfig then
				config.anchorGroup[normalizedTrackedBarGroup] = groupConfig
			end

			if trackedBarGroup and trackedBarGroup ~= normalizedTrackedBarGroup then
				config.anchorGroup[trackedBarGroup] = nil
			end

			if legacyGroup and legacyGroup ~= normalizedTrackedBarGroup then
				config.anchorGroup[legacyGroup] = nil
			end
		end
	end
end

local function CreateSpecFallbackConfig(config, specConfig, isActive, setSpecConfig)
	config = config or {}
	setSpecConfig = setSpecConfig or nop

	isActive = isActive or function()
		return specConfig and specConfig.active
	end

	local function SaveSpecConfig()
		specConfig = specConfig or {}
		setSpecConfig(specConfig)
		setSpecConfig = nop
		return specConfig
	end

	local function CreateChildConfig(key)
		local function SaveChildConfig(childConfig)
			SaveSpecConfig()[key] = childConfig
		end

		return CreateSpecFallbackConfig(config[key], specConfig and specConfig[key], isActive, SaveChildConfig)
	end

	local metatable = {
		__index = function(_, key)
			if key == "active" then
				return isActive()
			end

			if not isActive() then
				return config[key]
			end

			local value = specConfig and specConfig[key]
			if value == nil then
				value = config[key]
			end

			if type(value) == "table" then
				return CreateChildConfig(key)
			end

			return value
		end,
		__newindex = function(_, key, value)
			if key == "active" then
				SaveSpecConfig()[key] = value
			elseif isActive() then
				if IsShiftKeyDown() then
					if specConfig then
						specConfig[key] = nil
					end
				else
					SaveSpecConfig()[key] = value
				end
			else
				config[key] = value
			end
		end,
	}

	return setmetatable({}, metatable)
end

local function CreateCooldownBreakpoints(options)
	if not options.cooldownBreakpoints or #options.cooldownBreakpoints == 0 then
		options.cooldownBreakpoints = CopyTable(SCM.Constants.CooldownTimer.DefaultBreakpoints)
	else
		for _, breakpoint in ipairs(options.cooldownBreakpoints) do
			if not breakpoint.threshold then
				breakpoint.threshold = 0
			end

			if not breakpoint.step then
				breakpoint.step = 1
			end

			if breakpoint.components then
				local components = breakpoint.components
				local nextIndex = 1
				for i = 1, 10 do
					local component = components[i]
					if component then
						if i ~= nextIndex then
							components[nextIndex] = component
							components[i] = nil
						end

						nextIndex = nextIndex + 1
					end
				end
			end
		end
	end
end

function SCM:UpdateDB()
	self:MigrateLegacyGlobalConfigToProfiles()

	local options = self.db.profile.options

	CreateCooldownBreakpoints(options)

	local firstGlobalGroup = SCM.Utils.ToGlobalGroup(1)
	local firstBuffBarGroup = SCM.Utils.ToBuffBarGroup(1)
	local class = Utils.GetClass()
	local specID, _, _, _, role = Utils.GetSpec()
	local _, _, raceID = UnitRace("player")

	local currentConfig = self.DB:LoadData()
	local specAnchorConfig = currentConfig and currentConfig.anchorConfig[specID]
	local specBuffBarsAnchorConfig = currentConfig and currentConfig.buffBarsAnchorConfig and currentConfig.buffBarsAnchorConfig[specID]
	local specSpellConfig = currentConfig and currentConfig.spellConfig[specID]
	local specCustomConfig = currentConfig and currentConfig.customConfig and currentConfig.customConfig[specID]
	local specResourceBarConfig = currentConfig and currentConfig.resourceBarConfig and currentConfig.resourceBarConfig[specID]
	local specCastBarConfig = currentConfig and currentConfig.castBarConfig and currentConfig.castBarConfig[specID]

	self.db.profile[class] = self.db.profile[class] or {}
	self.db.profile[class][specID] = self.db.profile[class][specID]
		or {
			anchorConfig = CopyTable(specAnchorConfig or self.DB.defaultAnchorConfig),
			buffBarsAnchorConfig = CopyTable(specBuffBarsAnchorConfig or self.DB.defaultBuffBarsAnchorConfig),
			spellConfig = specSpellConfig or {},
			customConfig = specCustomConfig or {},
			resourceBarConfig = specResourceBarConfig or {},
			castBarConfig = specCastBarConfig or {},
		}

	self.currentConfig = self.db.profile[class][specID]
	self.anchorConfig = self.currentConfig.anchorConfig
	self.spellConfig = self.currentConfig.spellConfig
	self:MigrateLegacySpellConfigKeys(self.spellConfig, self.defaultCooldownViewerConfig)
	CreateTrackedBarSpellConfig(self.spellConfig)
	self.itemConfig = self.currentConfig.itemConfig

	self.currentConfig.customConfig = self.currentConfig.customConfig or {}
	self.customConfig = CreateCustomConfigTables(self.currentConfig.customConfig)

	self.currentConfig.resourceBarConfig = self.currentConfig.resourceBarConfig or {}
	self.specResourceBarConfig = self.currentConfig.resourceBarConfig
	self.resourceBarConfig = CreateSpecFallbackConfig(options.resourceBar, self.currentConfig.resourceBarConfig)

	self.currentConfig.castBarConfig = self.currentConfig.castBarConfig or {}
	self.specCastBarConfig = self.currentConfig.castBarConfig
	self.castBarConfig = CreateSpecFallbackConfig(options.castBar, self.currentConfig.castBarConfig)
	if self.CastBar then
		self.CastBar.barOptions = self.castBarConfig
	end

	self.currentConfig.buffBarsAnchorConfig = self.currentConfig.buffBarsAnchorConfig or {}
	self.buffBarsAnchorConfig = CreateAnchorConfigTables(self.currentConfig.buffBarsAnchorConfig)

	self.globalAnchorConfig = self.db.profile.globalAnchorConfig
	self.globalCustomConfig = CreateCustomConfigTables(self.db.profile.globalCustomConfig)
	self:RemoveOldAnchorConfigs(self.currentConfig, self.globalAnchorConfig, self.globalCustomConfig)

	self.isHideWhenInactiveEnabled = self:GetHideWhenInactive() == 1
	self.showTooltips = self:GetShowTooltip() == 1
	self.currentClass = class
	self.currentSpecID = specID
	self.currentRole = role
	self.currentRace = raceID

	for group, anchorFrame in pairs(self.anchorFrames) do
		if group < firstGlobalGroup and not self.anchorConfig[group] then
			anchorFrame:Hide()
		elseif Utils.IsGlobalGroup(group) and not self.globalAnchorConfig[group - 100] then
			anchorFrame:Hide()
		elseif group >= firstBuffBarGroup and not self.buffBarsAnchorConfig[group - 200] then
			anchorFrame:Hide()
		end
	end
end

function SCM:GetSpellConfigForGroup(configID, group)
	return GetSpellAnchorGroupConfig(self.spellConfig and self.spellConfig[configID], group)
end
