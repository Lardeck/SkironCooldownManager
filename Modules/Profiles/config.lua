local SCM = select(2, ...)

local Profiles = SCM.Profiles

local EXPORT_TYPE = SCM.Constants.PROFILES.EXPORT_TYPE
local CUSTOM_CONFIG_KEYS = SCM.Constants.PROFILES.CUSTOM_CONFIG_KEYS
local SPEC_CONFIG_KEYS = SCM.Constants.PROFILES.SPEC_CONFIG_KEYS
local ANCHOR_KEYS = SCM.Constants.PROFILES.ANCHOR_KEYS

function Profiles.GetDefaultAnchors(classFileName, specID, key)
	local classConfig = SCM.DB.classes[classFileName]
	local anchors = classConfig and classConfig[key] and classConfig[key][specID]

	return anchors or (key == "anchorConfig" and SCM.DB.defaultAnchorConfig or SCM.DB.defaultBuffBarsAnchorConfig)
end

function Profiles.ApplyCustomConfig(destination, source)
	if not next(source) then
		wipe(destination)
		return
	end

	for _, key in ipairs(CUSTOM_CONFIG_KEYS) do
		if source[key] then
			destination[key] = CopyTable(source[key])
		end
	end
end

function Profiles.HasSpecConfig(data, excludeIcons)
	if excludeIcons then
		return data.anchorConfig or data.buffBarsAnchorConfig
	end

	for _, key in ipairs(SPEC_CONFIG_KEYS) do
		if data[key] then
			return true
		end
	end
end

function Profiles.ApplySpecConfig(destination, source, classFileName, specID, excludeIcons, sharedSettings)
	local preserveAnchors = excludeIcons or not source.spellConfig or not source.customConfig

	for _, key in ipairs(SPEC_CONFIG_KEYS) do
		local section = source[key]
		local isAnchor = ANCHOR_KEYS[key]

		if section and (not excludeIcons or isAnchor) then
			if isAnchor and preserveAnchors then
				local sharedAnchors = sharedSettings and sharedSettings[key]
				local anchors = Profiles.CopyAnchors(section, sharedAnchors)

				destination[key] = destination[key] or CopyTable(Profiles.GetDefaultAnchors(classFileName, specID, key))
				Profiles.ApplyAnchors(destination[key], anchors)
			elseif key == "customConfig" then
				destination.customConfig = destination.customConfig or {}
				Profiles.ApplyCustomConfig(destination.customConfig, section)
			else
				destination[key] = section
			end
		end
	end

	if source.spellConfig and not excludeIcons then
		destination.profileVersion = source.profileVersion
	end
end

local function ImportSpec(db, classFileName, specID, specConfig, excludeIcons, sharedSettings)
	if not classFileName or not specConfig or not Profiles.HasSpecConfig(specConfig, excludeIcons) then
		return
	end

	specID = tonumber(specID) or specID
	db[classFileName] = db[classFileName] or {}
	db[classFileName][specID] = db[classFileName][specID] or {}

	Profiles.ApplySpecConfig(db[classFileName][specID], specConfig, classFileName, specID, excludeIcons, sharedSettings)
end

function Profiles.ImportProfileData(db, typeID, payload, importSettings)
	local data = payload.profileData

	if not data or not next(data) then
		return
	end

	local excludeIcons = (importSettings and importSettings.excludeIcons) or payload.excludeIcons
	local sharedSettings = payload.globalSettings

	local selectedClass = importSettings and importSettings.selectedClass or "ALL"
	local selectedSpec = importSettings and importSettings.useSpecificSpec and tonumber(importSettings.selectedSpec) or nil
	local selectedSpecKey = selectedSpec and tostring(selectedSpec)
	local importAllClasses = selectedClass == "ALL"
	local importProfileData = not importSettings or importSettings.useSpecificClass

	if importProfileData then
		if typeID == EXPORT_TYPE.ALL then
			if selectedSpec then
				local classFileName = importAllClasses and select(6, GetSpecializationInfoByID(selectedSpec)) or selectedClass
				local classConfig = classFileName and data[classFileName]
				local specConfig = classConfig and (classConfig[selectedSpec] or classConfig[selectedSpecKey])

				ImportSpec(db, classFileName, selectedSpec, specConfig, excludeIcons, sharedSettings)
			elseif not importAllClasses then
				local classConfig = data[selectedClass]

				if classConfig then
					for specID, specConfig in pairs(classConfig) do
						ImportSpec(db, selectedClass, specID, specConfig, excludeIcons, sharedSettings)
					end
				end
			else
				for classFileName, classConfig in pairs(data) do
					if classConfig then
						for specID, specConfig in pairs(classConfig) do
							ImportSpec(db, classFileName, specID, specConfig, excludeIcons, sharedSettings)
						end
					end
				end
			end
		elseif typeID == EXPORT_TYPE.CLASS then
			if selectedSpec then
				local classFileName = importAllClasses and (payload.classFileName or select(6, GetSpecializationInfoByID(selectedSpec))) or selectedClass

				ImportSpec(db, classFileName, selectedSpec, data[selectedSpec] or data[selectedSpecKey], excludeIcons, sharedSettings)
			else
				for specID, specConfig in pairs(data) do
					local specIDNumber = tonumber(specID) or specID
					local classFileName = payload.classFileName
						or (SCM.isForever and (importAllClasses and SCM.Utils.GetClass() or selectedClass))
						or select(6, GetSpecializationInfoByID(specIDNumber))

					if importAllClasses or selectedClass == classFileName then
						ImportSpec(db, classFileName, specIDNumber, specConfig, excludeIcons, sharedSettings)
					end
				end
			end
		elseif typeID then
			local classFileName = select(6, GetSpecializationInfoByID(typeID))

			if (importAllClasses or selectedClass == classFileName) and (not selectedSpec or selectedSpec == typeID) then
				ImportSpec(db, classFileName, typeID, data, excludeIcons, sharedSettings)
			end
		end
	end
end
