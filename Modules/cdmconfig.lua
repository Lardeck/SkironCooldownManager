local SCM = select(2, ...)

local Utils = SCM.Utils

local function GetSpellAnchorGroupConfig(spellConfig, group)
	return spellConfig and spellConfig.anchorGroup and spellConfig.anchorGroup[group]
end

local function SetOverrideConfigMetatables(overrideConfig, profileConfig, defaultConfig)
	if not defaultConfig then
		defaultConfig = {}
	end

	for key, value in pairs(overrideConfig) do
		local profileValue = profileConfig[key]
		if type(value) == "table" and type(profileValue) == "table" then
			SetOverrideConfigMetatables(value, profileValue, defaultConfig[key])
		end
	end

	if type(defaultConfig[1]) == "table" then
		for index, defaultValue in ipairs(defaultConfig) do
			if rawget(overrideConfig, index) == nil then
				local profileValue = profileConfig[index]
				if type(profileValue) == "table" then
					overrideConfig[index] = SetOverrideConfigMetatables({}, profileValue, defaultValue)
				end
			end
		end
	end

	return setmetatable(overrideConfig, {
		__index = function(self, key)
			local value = profileConfig[key]
			if type(value) == "table" then
				value = SetOverrideConfigMetatables({}, value, defaultConfig[key])
				rawset(self, key, value)
			end

			return value
		end,
	})
end

function SCM:UpdateCastAndResourceBarConfigs()
	local options = self.db.profile.options
	local defaultOptions = SCM.DefaultDB.profile.options

	if self.resourceBarOverride.active then
		self.resourceBarConfig = SetOverrideConfigMetatables(self.resourceBarOverride, options.resourceBar, defaultOptions.resourceBar)
	else
		self.resourceBarConfig = options.resourceBar
	end

	local resourceBarConfig = self.resourceBarConfig
	self:UpdateResourceBarSparkTexture(resourceBarConfig.primaryBar.spark)
	self:UpdateResourceBarSparkTexture(resourceBarConfig.secondaryBar.spark)
	if self.isForever then
		self:UpdateResourceBarSparkTexture(resourceBarConfig.primaryBar.manaTickSpark)
		self:UpdateResourceBarSparkTexture(resourceBarConfig.secondaryBar.manaTickSpark)
	end

	if self.castBarOverride.active then
		self.castBarConfig = SetOverrideConfigMetatables(self.castBarOverride, options.castBar, defaultOptions.castBar)
	else
		self.castBarConfig = options.castBar
	end

	if self.CastBar then
		self.CastBar.barOptions = self.castBarConfig
	end
end

function SCM:UpdateDB()
	local firstGlobalGroup = SCM.Utils.ToGlobalGroup(1)
	local firstBuffBarGroup = SCM.Utils.ToBuffBarGroup(1)
	local class = Utils.GetClass()

	local specID, role, _
	if SCM.isForever then
		specID = 1
		role = select(5, Utils.GetSpec())
	else
		specID, _, _, _, role = Utils.GetSpec()
	end

	local _, _, raceID = UnitRace("player")

	local currentConfig = self.DB:LoadData()

	local specAnchorConfig = self.DB.defaultAnchorConfig
	local specBuffBarsAnchorConfig = self.DB.defaultBuffBarsAnchorConfig
	local specAurasAnchorConfig = self.DB.defaultAurasAnchorConfig
	local specSpellConfig = {}
	local specCustomConfig = {}
	local resourceBarOverride = {}
	local castBarOverride = {}

	if currentConfig then
		specAnchorConfig = currentConfig.anchorConfig[specID] or specAnchorConfig
		specBuffBarsAnchorConfig = (currentConfig.buffBarsAnchorConfig and currentConfig.buffBarsAnchorConfig[specID]) or specBuffBarsAnchorConfig
		specAurasAnchorConfig = (currentConfig.aurasAnchorConfig and currentConfig.aurasAnchorConfig[specID]) or specAurasAnchorConfig
		specSpellConfig = currentConfig.spellConfig[specID] or specSpellConfig
		specCustomConfig = (currentConfig.customConfig and currentConfig.customConfig[specID]) or specCustomConfig
		resourceBarOverride = (currentConfig.resourceBarConfig and currentConfig.resourceBarConfig[specID]) or resourceBarOverride
		castBarOverride = (currentConfig.castBarConfig and currentConfig.castBarConfig[specID]) or castBarOverride
	end

	self.db.profile[class] = self.db.profile[class] or {}
	self.db.profile[class][specID] = self.db.profile[class][specID] or {}

	local currentConfig = self.db.profile[class][specID]
	currentConfig.anchorConfig = currentConfig.anchorConfig or CopyTable(specAnchorConfig)
	currentConfig.buffBarsAnchorConfig = currentConfig.buffBarsAnchorConfig or CopyTable(specBuffBarsAnchorConfig)
	currentConfig.aurasAnchorConfig = currentConfig.aurasAnchorConfig or CopyTable(specAurasAnchorConfig)
	currentConfig.spellConfig = currentConfig.spellConfig or CopyTable(specSpellConfig)
	currentConfig.customConfig = currentConfig.customConfig or CopyTable(specCustomConfig)
	currentConfig.resourceBarConfig = currentConfig.resourceBarConfig or CopyTable(resourceBarOverride)
	currentConfig.castBarConfig = currentConfig.castBarConfig or CopyTable(castBarOverride)

	self.currentConfig = currentConfig
	self.anchorConfig = currentConfig.anchorConfig
	self.buffBarsAnchorConfig = currentConfig.buffBarsAnchorConfig
	self.aurasAnchorConfig = currentConfig.aurasAnchorConfig
	self.spellConfig = currentConfig.spellConfig

	self:MigrateDB()

	self.globalAnchorConfig = self.db.profile.globalAnchorConfig
	self.globalCustomConfig = self.db.profile.globalCustomConfig
	self.globalAurasAnchorConfig = self.db.profile.globalAurasAnchorConfig

	self.customConfig = currentConfig.customConfig

	self.resourceBarOverride = currentConfig.resourceBarConfig
	self.castBarOverride = currentConfig.castBarConfig
	self:UpdateCastAndResourceBarConfigs()

	if SCM.isForever then
		self.swingTimerConfig = self.db.profile.options.swingTimer
	end

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
