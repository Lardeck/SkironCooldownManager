local SCM = select(2, ...)

local Utils = SCM.Utils

local function GetSpellAnchorGroupConfig(spellConfig, group)
	return spellConfig and spellConfig.anchorGroup and spellConfig.anchorGroup[group]
end

local function SetSpecConfigMetatables(specConfig, profileConfig, defaultConfig)
	if not defaultConfig then
		defaultConfig = {}
	end

	for key, value in pairs(specConfig) do
		local profileValue = profileConfig[key]
		if type(value) == "table" and type(profileValue) == "table" then
			SetSpecConfigMetatables(value, profileValue, defaultConfig[key])
		end
	end

	if type(defaultConfig[1]) == "table" then
		for index, defaultValue in ipairs(defaultConfig) do
			if rawget(specConfig, index) == nil then
				local profileValue = profileConfig[index]
				if type(profileValue) == "table" then
					specConfig[index] = SetSpecConfigMetatables({}, profileValue, defaultValue)
				end
			end
		end
	end

	return setmetatable(specConfig, {
		__index = function(self, key)
			local value = profileConfig[key]
			if type(value) == "table" then
				value = SetSpecConfigMetatables({}, value, defaultConfig[key])
				rawset(self, key, value)
			end

			return value
		end,
	})
end

function SCM:UpdateCastAndResourceBarConfigs(checkSpec)
	local options = self.db.profile.options
	local defaultOptions = SCM.DefaultDB.profile.options

	if checkSpec and self.specResourceBarConfig.active then
		self.resourceBarConfig = SetSpecConfigMetatables(self.specResourceBarConfig, options.resourceBar, defaultOptions.resourceBar)
	else
		self.resourceBarConfig = options.resourceBar
	end

	if checkSpec and self.specCastBarConfig.active then
		self.castBarConfig = SetSpecConfigMetatables(self.specCastBarConfig, options.castBar, defaultOptions.castBar)
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
	local specResourceBarConfig = {}
	local specCastBarConfig = {}

	if currentConfig then
		specAnchorConfig = currentConfig.anchorConfig[specID] or specAnchorConfig
		specBuffBarsAnchorConfig = (currentConfig.buffBarsAnchorConfig and currentConfig.buffBarsAnchorConfig[specID]) or specBuffBarsAnchorConfig
		specAurasAnchorConfig = (currentConfig.aurasAnchorConfig and currentConfig.aurasAnchorConfig[specID]) or specAurasAnchorConfig
		specSpellConfig = currentConfig.spellConfig[specID] or specSpellConfig
		specCustomConfig = (currentConfig.customConfig and currentConfig.customConfig[specID]) or specCustomConfig
		specResourceBarConfig = (currentConfig.resourceBarConfig and currentConfig.resourceBarConfig[specID]) or specResourceBarConfig
		specCastBarConfig = (currentConfig.castBarConfig and currentConfig.castBarConfig[specID]) or specCastBarConfig
	end

	self.db.profile[class] = self.db.profile[class] or {}
	self.db.profile[class][specID] = self.db.profile[class][specID] or {}

	local currentConfig = self.db.profile[class][specID]
	currentConfig.anchorConfig = currentConfig.anchorConfig or CopyTable(specAnchorConfig)
	currentConfig.buffBarsAnchorConfig = currentConfig.buffBarsAnchorConfig or CopyTable(specBuffBarsAnchorConfig)
	currentConfig.aurasAnchorConfig = currentConfig.aurasAnchorConfig or CopyTable(specAurasAnchorConfig)
	currentConfig.spellConfig = currentConfig.spellConfig or CopyTable(specSpellConfig)
	currentConfig.customConfig = currentConfig.customConfig or CopyTable(specCustomConfig)
	currentConfig.resourceBarConfig = currentConfig.resourceBarConfig or CopyTable(specResourceBarConfig)
	currentConfig.castBarConfig = currentConfig.castBarConfig or CopyTable(specCastBarConfig)

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

	if not SCM.isForever then
		self.specResourceBarConfig = currentConfig.resourceBarConfig
		self.specCastBarConfig = currentConfig.castBarConfig
		self:UpdateCastAndResourceBarConfigs(true)
	else
		self.swingTimerConfig = self.db.profile.options.swingTimer
		self:UpdateCastAndResourceBarConfigs(false)
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
