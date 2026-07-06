local SCM = select(2, ...)

local dataVersion = 1
local EXPORT_TYPE_ALL = 0
local EXPORT_TYPE_CLASS = 1
local EXPORT_TYPE_GLOBAL_SETTINGS = 2
local EXPORT_TYPE_GLOBAL_ANCHORS = 3
local EXPORT_TYPE_EVERYTHING = 4
local GLOBAL_CUSTOM_CONFIG_KEYS = {
	"spellConfig",
	"itemConfig",
	"slotConfig",
	"timerConfig",
	"bloodlustConfig",
}
local PROFILE_OPTION_SECTION_KEYS = {
	resourceBar = true,
	castBar = true,
}

-- Copy/settings helpers
local function CopyValue(value)
	if type(value) == "table" then
		return CopyTable(value)
	end

	return value
end

local function BuildGeneralSettingsExport(options)
	local exportData = {}
	for key, value in pairs(options) do
		if not PROFILE_OPTION_SECTION_KEYS[key] then
			exportData[key] = CopyValue(value)
		end
	end

	return exportData
end

local function ApplyOptionsData(options, data)
	if type(data) ~= "table" then
		return
	end

	for key, value in pairs(data) do
		options[key] = CopyValue(value)
	end
end

local function ApplyResourceBarSettings(options, data)
	if type(data) ~= "table" then
		return
	end

	if data.resourceBar ~= nil then
		options.resourceBar = CopyValue(data.resourceBar)
	end
end

-- Export helpers
local function GetProfileExportData(db, exportType, classFileName, specID)
	if not classFileName and not specID then
		return {}
	end

	if exportType == EXPORT_TYPE_ALL then
		if classFileName and classFileName ~= "ALL" and specID then
			local classData = db[classFileName]
			return {
				[classFileName] = {
					[specID] = type(classData) == "table" and type(classData[specID]) == "table" and CopyValue(classData[specID]) or {},
				},
			}
		end

		local profileData = {}
		for key, value in pairs(db) do
			if key ~= "options" and key ~= "anchorConfig" and key ~= "globalAnchorConfig" and key ~= "globalCustomConfig" then
				profileData[key] = CopyValue(value)
			end
		end

		return profileData
	end

	local classData = db[classFileName]
	if type(classData) ~= "table" then
		return {}
	end

	if specID then
		return type(classData[specID]) == "table" and CopyValue(classData[specID]) or {}
	end

	return CopyValue(classData)
end

local function BuildProfileExportPayload(self, exportType, classFileName, specID, exportOptions)
	exportOptions = exportOptions or {}

	local options = self.db.profile.options
	local payload = {
		profileData = GetProfileExportData(self.db.profile, exportType, classFileName, specID),
	}

	if exportOptions.includeResourceBar then
		payload.resourceBarSettings = options.resourceBar and { resourceBar = CopyValue(options.resourceBar) } or nil
	end

	if exportOptions.includeCastBar then
		payload.castBarSettings = options.castBar and CopyValue(options.castBar) or nil
	end

	if exportOptions.includeGlobalSettings then
		payload.globalSettings = BuildGeneralSettingsExport(options)
	end

	if exportOptions.includeGlobalAnchors then
		payload.globalAnchors = {
			globalAnchorConfig = self.db.profile.globalAnchorConfig,
			globalCustomConfig = self.db.profile.globalCustomConfig,
		}
	end

	return payload
end

function SCM:ExportProfile(classFileName, specID, exportOptions)
	exportOptions = exportOptions or {}
	local hasIncludeOptions = exportOptions.includeResourceBar or exportOptions.includeCastBar or exportOptions.includeGlobalSettings or exportOptions.includeGlobalAnchors

	local exportType = specID or EXPORT_TYPE_ALL
	if classFileName == "ALL" or (specID and hasIncludeOptions) then
		exportType = EXPORT_TYPE_ALL
	elseif classFileName and not specID then
		exportType = EXPORT_TYPE_CLASS
	end

	local prefix = string.format("!SCM:%d:%d!", dataVersion, exportType)
	return prefix .. SCM.Encode(BuildProfileExportPayload(self, exportType, classFileName, specID, exportOptions))
end

function SCM:ExportGlobalSettings()
	local exportType = EXPORT_TYPE_GLOBAL_SETTINGS
	local prefix = string.format("!SCM:%d:%d!", dataVersion, exportType)
	return prefix .. SCM.Encode(BuildGeneralSettingsExport(self.db.profile.options))
end

function SCM:ExportGlobalAnchors()
	local prefix = string.format("!SCM:%d:%d!", dataVersion, EXPORT_TYPE_GLOBAL_ANCHORS)
	return prefix .. SCM.Encode({
		globalAnchorConfig = self.db.profile.globalAnchorConfig,
		globalCustomConfig = self.db.profile.globalCustomConfig,
	})
end

-- Import helpers
local function DecodeImportString(importString)
	local parameterString, dataString = importString:match("^!([^!]+)!(.+)$")
	if not parameterString or not dataString then
		return
	end

	local prefix, version, typeStr = strsplit(":", parameterString)
	local typeID = tonumber(typeStr)
	local versionID = tonumber(version)

	if prefix ~= "SCM" or versionID ~= dataVersion then
		print("Invalid Import String")
		return
	end

	local data = SCM.Decode(dataString)
	if not data then
		return
	end

	return typeID, data
end

local function MergeConfig(destDB, sourceData, defaultAnchor)
	if not destDB or not sourceData then
		return
	end

	destDB.spellConfig = sourceData.spellConfig
	destDB.itemConfig = sourceData.itemConfig
	destDB.customConfig = sourceData.customConfig or {}
	destDB.resourceBarConfig = type(sourceData.resourceBarConfig) == "table" and sourceData.resourceBarConfig or {}
	destDB.buffBarsAnchorConfig = type(sourceData.buffBarsAnchorConfig) == "table" and sourceData.buffBarsAnchorConfig or {}

	if type(sourceData.anchorConfig) == "table" and #sourceData.anchorConfig > 0 then
		destDB.anchorConfig = sourceData.anchorConfig
	elseif type(destDB.anchorConfig) ~= "table" or #destDB.anchorConfig == 0 then
		destDB.anchorConfig = defaultAnchor
	end
end

local function GetImportedGlobalAnchorData(data)
	local anchors = type(data) == "table" and data.globalAnchorConfig or nil
	if type(anchors) == "table" and #anchors > 0 then
		anchors = CopyTable(anchors)

		for index, anchorConfig in ipairs(anchors) do
			if type(anchorConfig) ~= "table" then
				anchorConfig = {}
			end

			if type(anchorConfig.anchor) ~= "table" then
				anchorConfig.anchor = { "CENTER", "UIParent", "CENTER", 0, 0 }
			end

			if type(anchorConfig.rowConfig) ~= "table" or #anchorConfig.rowConfig == 0 then
				anchorConfig.rowConfig = {
					{
						iconWidth = 40,
						iconHeight = 40,
						limit = 8,
					},
				}
			end

			anchors[index] = anchorConfig
		end
	else
		anchors = nil
	end

	local customConfig = type(data) == "table" and data.globalCustomConfig or nil
	local importedCustomConfig
	if type(customConfig) == "table" then
		for _, key in ipairs(GLOBAL_CUSTOM_CONFIG_KEYS) do
			if type(customConfig[key]) == "table" and next(customConfig[key]) then
				importedCustomConfig = importedCustomConfig or {}
				importedCustomConfig[key] = CopyTable(customConfig[key])
			end
		end
	end

	return anchors, importedCustomConfig
end

-- Public profile/import helpers
function SCM:GetFreeProfileName(profileName)
	if not profileName or strtrim(profileName) == "" then
		profileName = "New Profile"
	end

	local existingProfiles = {}
	for _, name in ipairs(self.db:GetProfiles()) do
		existingProfiles[name] = true
	end

	if not existingProfiles[profileName] then
		return profileName
	end

	local index = 1
	local baseName = profileName
	while existingProfiles[baseName .. " " .. index] do
		index = index + 1
	end

	return "New Profile " .. index
end

local function ImportSpec(db, defaultAnchor, classFileName, specID, specConfig)
	if not classFileName or type(specConfig) ~= "table" then
		return
	end

	specID = tonumber(specID) or specID
	db[classFileName] = db[classFileName] or {}
	db[classFileName][specID] = db[classFileName][specID] or CopyTable(SCM.DefaultClassConfig)
	MergeConfig(db[classFileName][specID], specConfig, defaultAnchor)
end

function SCM:ImportProfile(profileName, importString, importSettings)
	local typeID, data = DecodeImportString(importString)
	if not typeID then
		return
	end

	local hasImportSettings = type(importSettings) == "table"
	local includeResourceBar = not hasImportSettings or importSettings.includeResourceBar
	local includeCastBar = not hasImportSettings or importSettings.includeCastBar
	local includeGlobalSettings = not hasImportSettings or importSettings.includeGlobalSettings
	local includeGlobalAnchors = not hasImportSettings or importSettings.includeGlobalAnchors

	if typeID == EXPORT_TYPE_GLOBAL_SETTINGS then
		if includeGlobalSettings then
			self:ImportGlobalSettingsFromData(data)
		end
		return
	end

	if typeID == EXPORT_TYPE_GLOBAL_ANCHORS then
		if includeGlobalAnchors then
			self:ImportGlobalAnchorsFromData(data, true)
		end
		return
	end

	local importedSections
	if type(data) == "table" then
		if data.profileData or data.resourceBarSettings or data.castBarSettings or data.globalSettings or data.globalAnchors then
			importedSections = data
			data = type(data.profileData) == "table" and data.profileData or {}
		elseif typeID == EXPORT_TYPE_EVERYTHING then
			importedSections = data
			data = type(data.profileData) == "table" and data.profileData or {}
		end
	end

	if typeID == EXPORT_TYPE_EVERYTHING then
		typeID = EXPORT_TYPE_ALL
	end

	if not profileName or profileName == "" then
		profileName = SCM.db:GetCurrentProfile()
	end

	SCM.importingProfile = true
	SCM.db:SetProfile(profileName)

	local db = self.db.profile
	local options = db.options
	local defaultAnchor = self.DB.defaultAnchorConfig

	local selectedClass = hasImportSettings and (importSettings.selectedClass or "ALL") or "ALL"
	local selectedSpec = hasImportSettings and importSettings.useSpecificSpec and tonumber(importSettings.selectedSpec) or nil
	local selectedSpecKey = selectedSpec and tostring(selectedSpec)
	local importAllClasses = selectedClass == "ALL"
	local importProfileData = not hasImportSettings or importSettings.useSpecificClass

	if importProfileData then
		if typeID == EXPORT_TYPE_ALL then
			if selectedSpec then
				local classFileName = importAllClasses and select(6, GetSpecializationInfoByID(selectedSpec)) or selectedClass
				local classConfig = classFileName and data[classFileName]
				local specConfig = type(classConfig) == "table" and (classConfig[selectedSpec] or classConfig[selectedSpecKey])
				ImportSpec(db, defaultAnchor, classFileName, selectedSpec, specConfig)
			elseif not importAllClasses then
				local classConfig = data[selectedClass]
				if type(classConfig) == "table" then
					for specID, specConfig in pairs(classConfig) do
						ImportSpec(db, defaultAnchor, selectedClass, specID, specConfig)
					end
				end
			else
				for classFileName, classConfig in pairs(data) do
					if type(classConfig) == "table" then
						for specID, specConfig in pairs(classConfig) do
							ImportSpec(db, defaultAnchor, classFileName, specID, specConfig)
						end
					end
				end
			end
		elseif typeID == EXPORT_TYPE_CLASS then
			if selectedSpec then
				local classFileName = importAllClasses and select(6, GetSpecializationInfoByID(selectedSpec)) or selectedClass
				ImportSpec(db, defaultAnchor, classFileName, selectedSpec, data[selectedSpec] or data[selectedSpecKey])
			else
				for specID, specConfig in pairs(data) do
					local specIDNumber = tonumber(specID) or specID
					local classFileName = select(6, GetSpecializationInfoByID(specIDNumber))
					if importAllClasses or selectedClass == classFileName then
						ImportSpec(db, defaultAnchor, classFileName, specIDNumber, specConfig)
					end
				end
			end
		elseif typeID then
			local classFileName = select(6, GetSpecializationInfoByID(typeID))
			if (importAllClasses or selectedClass == classFileName) and (not selectedSpec or selectedSpec == typeID) then
				ImportSpec(db, defaultAnchor, classFileName, typeID, data)
			end
		end
	end

	if importedSections then
		if includeResourceBar and importedSections.resourceBarSettings then
			ApplyResourceBarSettings(options, importedSections.resourceBarSettings)
		end

		if includeCastBar and importedSections.castBarSettings then
			options.castBar = CopyValue(importedSections.castBarSettings)
		end

		if includeGlobalSettings and importedSections.globalSettings then
			ApplyOptionsData(options, importedSections.globalSettings)
		end

		if includeGlobalAnchors and importedSections.globalAnchors then
			self:ImportGlobalAnchorsFromData(importedSections.globalAnchors)
		end
	end

	self.db.profile.options = options
	SCM.db:RegisterDefaults(SCM.DefaultDB)
	SCM:UpdateDB()

	SCM.appliedOptions = nil
	SCM:ApplyOptions()

	SCM.RefreshCooldownViewerData(true)
	SCM.importingProfile = nil
end

function SCM:ImportGlobalSettings(importString)
	self:ImportProfile(nil, importString)
end

function SCM:ImportGlobalAnchors(importString)
	self:ImportProfile(nil, importString)
end

function SCM:ImportGlobalAnchorsFromData(data, refreshData)
	local previousAnchorCount = #self.db.profile.globalAnchorConfig
	local anchors, customConfig = GetImportedGlobalAnchorData(data)

	if anchors then
		self.db.profile.globalAnchorConfig = anchors
	end

	if customConfig then
		for _, key in ipairs(GLOBAL_CUSTOM_CONFIG_KEYS) do
			if customConfig[key] then
				self.db.profile.globalCustomConfig[key] = customConfig[key]
			end
		end
	end

	local currentAnchorCount = #self.db.profile.globalAnchorConfig
	for index = currentAnchorCount + 1, previousAnchorCount do
		local globalGroup = self.Utils.ToGlobalGroup(index)
		local anchorFrame = SCM:GetAnchor(globalGroup)
		if anchorFrame then
			anchorFrame:Hide()
			self.anchorFrames[globalGroup] = nil
		end
	end

	if refreshData then
		SCM.RefreshCooldownViewerData(true)
	end
end

function SCM:ImportGlobalSettingsFromData(data)
	local options = self.db.profile.options
	ApplyOptionsData(options, data)
	self.db.profile.options = options

	self.db:RegisterDefaults(SCM.DefaultDB)
	SCM.appliedOptions = nil
	SCM:UpdateDB()
	SCM:ApplyOptions()

	SCM.RefreshCooldownViewerData(true)
end
