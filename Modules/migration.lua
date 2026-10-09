local SCM = select(2, ...)

local Utils = SCM.Utils
local GetCooldownConfigKey = Utils.GetCooldownConfigKey
local ToBuffBarGroup = Utils.ToBuffBarGroup
local IsBuffBarGroup = Utils.IsBuffBarGroup
local GlobalGlowSubregion = SCM.Constants.GlobalGlowSubregion
local PROFILE_VERSION = 1

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

local function CreateAnchorConfigTables(anchorConfig, isBuffBar, isAuras)
	anchorConfig = anchorConfig or {}

	if not anchorConfig[1] then
		if isBuffBar then
			anchorConfig[1] = SCM.DB.defaultBuffBarsAnchorConfig[1]
		elseif isAuras then
			anchorConfig[1] = SCM.DB.defaultAurasAnchorConfig[1]
		end
	end

	return anchorConfig
end

function SCM:CreateCooldownBreakpoints(options)
	if not options.cooldownBreakpoints or #options.cooldownBreakpoints == 0 then
		options.cooldownBreakpoints = CopyTable(SCM.Constants.Formatter.DefaultBreakpoints)
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

local function CreateTrackedBarSpellConfig(spellConfig)
	for _, config in pairs(spellConfig) do
		if config.source and config.anchorGroup then
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

local function SetEffectRules(config, effect, rules)
	config.effectRules[effect] = {
		rules = rules,
	}
end

local function MigrateVisibilityRules(config, isAura, isCustom, isTimer, isItem)
	local hasVisibilityRules = config.effectRules.visibility ~= nil
	local shouldCreateRules = isAura or isCustom or isTimer or config.alwaysShow or config.showWhileInactive or config.hideWhenInactive or config.hideWhenNotOnCooldown

	if not hasVisibilityRules and shouldCreateRules then
		local rules
		if isTimer then
			rules = {
				{ state = "active", value = "show" },
				{ state = "inactive", value = "hide", elseIf = true },
			}
		elseif isAura then
			if config.showWhileInactive then
				rules = {
					{ state = "inactive", value = "show" },
					{ state = "active", value = "hide", elseIf = true },
				}
			elseif config.alwaysShow then
				rules = {}
			else
				rules = {
					{ state = "active", value = "show" },
					{ state = "inactive", value = "hide", elseIf = true },
				}
			end
		elseif isItem then
			if config.alwaysShow then
				rules = {
					{ state = "always", value = "show" },
				}
			elseif config.hideWhenNotOnCooldown then
				rules = {
					{ state = "cooldown", value = "show" },
					{ state = "ready", value = "hide", elseIf = true },
					{ state = "noitem", value = "hide", elseIf = true },
				}
			else
				rules = {
					{ state = "noitem", value = "hide" },
				}
			end
		elseif config.showWhileInactive then
			rules = {
				{ state = "inactive", value = "show" },
				{ state = "active", value = "hide", elseIf = true },
			}
		elseif config.alwaysShow and isCustom then
			rules = {
				{ state = "always", value = "show" },
			}
		elseif config.hideWhenNotOnCooldown then
			rules = {
				{ state = "cooldown", value = "show" },
				{ state = "ready", value = "hide", elseIf = true },
			}
		else
			rules = {
				{ state = "active", value = "show" },
				{ state = "inactive", value = "hide", elseIf = true },
			}
		end

		SetEffectRules(config, "visibility", rules)
	end

	config.hideWhenInactive = nil
	config.hideWhenNotOnCooldown = nil
	config.alwaysShow = nil
	config.showWhileInactive = nil
end

local function MigrateDesaturateRules(config, isAura, canBeActive, desaturateOnCooldown)
	local hasDesaturateRules = config.effectRules.desaturate ~= nil
	if not hasDesaturateRules then
		if isAura then
			local rules = {
				{ state = "active", enabled = false },
			}

			if config.desaturate then
				rules[2] = { state = "inactive", enabled = true }
			elseif config.alwaysShow or config.showWhileInactive then
				rules[2] = { state = "inactive", enabled = false }
			end

			SetEffectRules(config, "desaturate", rules)
		elseif desaturateOnCooldown then
			if canBeActive then
				SetEffectRules(config, "desaturate", {
					{ state = "active", enabled = false },
					{ state = "cooldown", enabled = true, elseIf = true },
				})
			else
				SetEffectRules(config, "desaturate", {
					{ state = "cooldown", enabled = true },
				})
			end
		end
	end

	config.desaturate = nil
end

local function MigrateGlowRules(config)
	local hasGlowRules = config.effectRules.glow ~= nil
	local shouldCreateRules = config.glowWhileActive or config.glowWhileInactive

	if not hasGlowRules and shouldCreateRules then
		local state = config.glowWhileActive and "active" or "inactive"
		SetEffectRules(config, "glow", {
			{ state = state, subregion = GlobalGlowSubregion },
		})
	end

	config.glowWhileActive = nil
	config.glowWhileInactive = nil
end

local function MigrateLegacyIconOptions(spellConfig, disableRegularIconActiveSwipe)
	for _, config in pairs(spellConfig) do
		local source = config.source
		local anchorGroups = config.anchorGroup
		if source and anchorGroups then
			local buffIconGroup = source[Enum.CooldownViewerCategory.TrackedBuff]
			for anchorGroup, anchorGroupConfig in pairs(anchorGroups) do
				local isAura = anchorGroup == buffIconGroup or IsBuffBarGroup(anchorGroup)
				local canBeActive = not isAura and not disableRegularIconActiveSwipe
				anchorGroupConfig.effectRules = anchorGroupConfig.effectRules or {}
				MigrateDesaturateRules(anchorGroupConfig, isAura, canBeActive, not isAura)
				MigrateVisibilityRules(anchorGroupConfig, isAura, false)
				MigrateGlowRules(anchorGroupConfig)
			end
		end
	end
end

local function MigrateLegacyCustomOptions(customConfig, disableRegularIconActiveSwipe)
	if not customConfig then
		return
	end

	for configKey, configTable in pairs(customConfig) do
		local isTimer = configKey == "timerConfig" or configKey == "bloodlustConfig"
		local isItem = configKey == "itemConfig"
		local desaturateOnCooldown = configKey == "spellConfig" or isItem or configKey == "slotConfig"
		for _, config in pairs(configTable) do
			config.effectRules = config.effectRules or {}
			MigrateDesaturateRules(config, false, isTimer, desaturateOnCooldown)
			MigrateVisibilityRules(config, false, true, isTimer and not disableRegularIconActiveSwipe, isItem)
			MigrateGlowRules(config)
		end
	end
end

local function HasAnchorConfig(anchorGroup, anchorConfig, buffBarsAnchorConfig)
	anchorGroup = tonumber(anchorGroup)
	if not anchorGroup then
		return
	end

	if IsBuffBarGroup(anchorGroup) then
		return buffBarsAnchorConfig and buffBarsAnchorConfig[anchorGroup - ToBuffBarGroup(0)]
	end

	return anchorConfig and anchorConfig[anchorGroup]
end

local function RemoveOldSpellConfigAnchors(config, anchorConfig, buffBarsAnchorConfig)
	local source = config.source
	local anchorGroups = config.anchorGroup
	if not anchorGroups then
		return
	end

	if source then
		for sourceIndex, anchorGroup in pairs(source) do
			if not HasAnchorConfig(anchorGroup, anchorConfig, buffBarsAnchorConfig) then
				source[sourceIndex] = nil
			end
		end
	end

	for anchorGroup in pairs(anchorGroups) do
		if not HasAnchorConfig(anchorGroup, anchorConfig, buffBarsAnchorConfig) then
			anchorGroups[anchorGroup] = nil
		end
	end

	return next(anchorGroups)
end

local function HasCustomAnchorConfig(config, anchorConfig)
	return HasAnchorConfig(config.anchorGroup, anchorConfig)
end

local function RemoveOldSpellConfigAnchorsFromTable(spellConfig, anchorConfig, buffBarsAnchorConfig)
	for configID, config in pairs(spellConfig) do
		if not RemoveOldSpellConfigAnchors(config, anchorConfig, buffBarsAnchorConfig) then
			spellConfig[configID] = nil
		end
	end
end

local function RemoveOldCustomConfigAnchors(customConfig, anchorConfig)
	if not customConfig then
		return
	end

	for _, configKey in ipairs({ "spellConfig", "itemConfig", "slotConfig", "timerConfig" }) do
		local configTable = customConfig[configKey]
		if configTable then
			for id, config in pairs(configTable) do
				if not HasCustomAnchorConfig(config, anchorConfig) then
					configTable[id] = nil
				end
			end
		end
	end
end

local function MigrateLegacyGlobalConfigToProfiles(self)
	local globalDB = self.db.global
	local legacyAnchorConfig = globalDB.globalAnchorConfig
	local legacyCustomConfig = globalDB.globalCustomConfig
	if not legacyAnchorConfig and not legacyCustomConfig then
		return
	end

	local profiles = self.db.profiles
	for _, profile in pairs(profiles) do
		if legacyAnchorConfig and not profile.globalAnchorConfig then
			profile.globalAnchorConfig = CopyTable(legacyAnchorConfig)
		end

		if legacyCustomConfig then
			local profileCustomConfig = profile.globalCustomConfig
			if not profileCustomConfig then
				profile.globalCustomConfig = CopyTable(legacyCustomConfig)
			else
				for key, config in pairs(legacyCustomConfig) do
					if not profileCustomConfig[key] then
						profileCustomConfig[key] = CopyTable(config)
					end
				end
			end
		end
	end

	globalDB.globalAnchorConfig = nil
	globalDB.globalCustomConfig = nil
end

local function RemoveOldAnchorConfigs(currentConfig, globalAnchorConfig, globalCustomConfig)
	RemoveOldSpellConfigAnchorsFromTable(currentConfig.spellConfig, currentConfig.anchorConfig, currentConfig.buffBarsAnchorConfig)
	RemoveOldCustomConfigAnchors(currentConfig.customConfig, currentConfig.anchorConfig)

	RemoveOldCustomConfigAnchors(globalCustomConfig, globalAnchorConfig)
end

local function GetCooldownDataForLegacySpellConfig(defaultCooldownViewerConfig, configID, config)
	local spellID = config.spellID or configID
	if not defaultCooldownViewerConfig then
		return
	end

	for sourceIndex in pairs(config.source) do
		local categoryConfig = defaultCooldownViewerConfig[sourceIndex]
		local pairIndex = SCM.Constants.SourcePairs[sourceIndex]
		local pairConfig = pairIndex and defaultCooldownViewerConfig[pairIndex]
		local data = categoryConfig and categoryConfig.spellIDs[spellID]
		if not data and pairConfig then
			data = pairConfig.spellIDs[spellID]
		end
		if data and data.cooldownID then
			return data
		end
	end

	return defaultCooldownViewerConfig.spellIDs[spellID]
end

local function MigrateLegacySpellConfigKeys(spellConfig, defaultCooldownViewerConfig)
	local legacyKeys = {}
	for configID in pairs(spellConfig) do
		if type(configID) == "number" then
			legacyKeys[#legacyKeys + 1] = configID
		end
	end

	for _, legacyID in ipairs(legacyKeys) do
		local config = spellConfig[legacyID]
		local spellID = config.spellID or legacyID
		local cooldownData = GetCooldownDataForLegacySpellConfig(defaultCooldownViewerConfig, legacyID, config)
		local cooldownID = config.cooldownID or (cooldownData and cooldownData.cooldownID)
		if cooldownID then
			local migratedID = GetCooldownConfigKey(cooldownID)
			config.spellID = spellID
			config.cooldownID = cooldownID
			spellConfig[migratedID] = config
			spellConfig[legacyID] = nil
		else
			spellConfig[legacyID] = nil
		end
	end
end

function SCM:MigrateLegacyProfileOptions()
	local legacyOptions = self.db.global.options
	if not legacyOptions then
		return
	end

	for _, profile in pairs(self.db.profiles) do
		if not profile.options then
			profile.options = CopyTable(legacyOptions)
		end
	end
end

function SCM:MigrateDB()
	local profileVersion = self.currentConfig.profileVersion

	if not profileVersion then
		MigrateLegacyGlobalConfigToProfiles(self)

		local options = self.db.profile.options
		if options.enableIconSkinning == nil then
			options.enableIconSkinning = options.enableSkinning
		end
		if options.enableBuffBarSkinning == nil then
			options.enableBuffBarSkinning = options.enableSkinning
		end

		MigrateLegacySpellConfigKeys(self.spellConfig, self.defaultCooldownViewerConfig)
		CreateTrackedBarSpellConfig(self.spellConfig)
		MigrateLegacyIconOptions(self.spellConfig, options.disableRegularIconActiveSwipe)
		MigrateLegacyCustomOptions(self.currentConfig.customConfig, options.disableRegularIconActiveSwipe)
		MigrateLegacyCustomOptions(self.db.profile.globalCustomConfig, options.disableRegularIconActiveSwipe)
		RemoveOldAnchorConfigs(self.currentConfig, self.db.profile.globalAnchorConfig, self.db.profile.globalCustomConfig)

		profileVersion = 1
	end

	if profileVersion < 2 then
	end

	self:CreateCooldownBreakpoints(self.db.profile.options)
	self.currentConfig.customConfig = CreateCustomConfigTables(self.currentConfig.customConfig)
	self.currentConfig.resourceBarConfig = self.currentConfig.resourceBarConfig or {}
	self.currentConfig.castBarConfig = self.currentConfig.castBarConfig or {}
	self.currentConfig.buffBarsAnchorConfig = CreateAnchorConfigTables(self.currentConfig.buffBarsAnchorConfig, true)
	self.currentConfig.aurasAnchorConfig = CreateAnchorConfigTables(self.currentConfig.aurasAnchorConfig, false, true)
	self.db.profile.globalCustomConfig = CreateCustomConfigTables(self.db.profile.globalCustomConfig)

	self.currentConfig.profileVersion = PROFILE_VERSION
end
