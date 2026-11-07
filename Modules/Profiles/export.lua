local SCM = select(2, ...)

local Profiles = SCM.Profiles
local CopyValue = Profiles.CopyValue
local BuildGeneralSettingsExport = Profiles.BuildGeneralSettingsExport

local EXPORT_TYPE = SCM.Constants.PROFILES.EXPORT_TYPE
local ANCHOR_KEYS = SCM.Constants.PROFILES.ANCHOR_KEYS

local function GetSpecExportData(db, classFileName, specID, exportOptions)
	local classData = db[classFileName]
	local specConfig = classData and classData[specID]

	if not specConfig then
		return {}
	end

	if not exportOptions.excludeIcons then
		return CopyTable(specConfig)
	end

	local result = {}

	for key in pairs(ANCHOR_KEYS) do
		if specConfig[key] then
			result[key] = Profiles.CopyAnchors(specConfig[key], db.options[key])
		end
	end

	return result
end

local function GetClassExportData(db, classFileName, exportOptions)
	local classData = db[classFileName]

	if not classData then
		return {}
	end

	if not exportOptions.excludeIcons then
		return CopyTable(classData)
	end

	local result = {}

	for specID in pairs(classData) do
		result[specID] = GetSpecExportData(db, classFileName, specID, exportOptions)
	end

	return result
end

local function GetProfileExportData(db, exportType, classFileName, specID, exportOptions)
	if not classFileName and not specID then
		return {}
	end

	if exportType == EXPORT_TYPE.ALL then
		if classFileName and classFileName ~= "ALL" and specID then
			return {
				[classFileName] = {
					[specID] = GetSpecExportData(db, classFileName, specID, exportOptions),
				},
			}
		end

		local profileData = {}

		for key, value in pairs(db) do
			if key ~= "options" and key ~= "anchorConfig" and key ~= "globalAnchorConfig" and key ~= "globalCustomConfig" and key ~= "globalAurasAnchorConfig" then
				profileData[key] = exportOptions.excludeIcons and GetClassExportData(db, key, exportOptions) or CopyValue(value)
			end
		end

		return profileData
	end

	if specID then
		return GetSpecExportData(db, classFileName, specID, exportOptions)
	end

	return GetClassExportData(db, classFileName, exportOptions)
end

local function BuildProfileExportPayload(self, exportType, classFileName, specID, exportOptions)
	exportOptions = exportOptions or {}

	local options = self.db.profile.options
	local payload = {
		classFileName = exportType == EXPORT_TYPE.CLASS and classFileName or nil,
		profileData = GetProfileExportData(self.db.profile, exportType, classFileName, specID, exportOptions),
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
			globalAnchorConfig = CopyTable(self.db.profile.globalAnchorConfig),
		}

		if not exportOptions.excludeIcons then
			payload.globalAnchors.globalCustomConfig = CopyTable(self.db.profile.globalCustomConfig)
		end
	end

	return payload
end

function SCM:ExportProfile(classFileName, specID, exportOptions)
	exportOptions = exportOptions or {}

	local hasIncludeOptions = exportOptions.includeResourceBar or exportOptions.includeCastBar or exportOptions.includeGlobalSettings or exportOptions.includeGlobalAnchors
	local exportType = specID or EXPORT_TYPE.ALL

	if classFileName == "ALL" or (specID and hasIncludeOptions) then
		exportType = EXPORT_TYPE.ALL
	elseif classFileName and not specID then
		exportType = EXPORT_TYPE.CLASS
	end

	return Profiles.EncodeExport(exportType, BuildProfileExportPayload(self, exportType, classFileName, specID, exportOptions), exportOptions.excludeIcons)
end
