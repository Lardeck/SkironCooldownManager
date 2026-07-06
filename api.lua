local SCM = select(2, ...)
SCMAPI = {}

function SCMAPI.AddTab(tab)
	SCM:AddTab(tab)
end

function SCMAPI.RegisterClassConfig(classFileName, config)
	if classFileName and config then
		SCM.DB:RegisterClassConfig(classFileName, config)
	end
end

-- importSettings can contain:
--   useSpecificClass: import class/spec profile data.
--   useSpecificSpec: limit class/spec profile data to selectedSpec.
--   selectedClass: uppercase class file name or "ALL".
--   selectedSpec: specialization ID used when useSpecificSpec is true.
--   includeResourceBar: import resource bar settings.
--   includeCastBar: import cast bar settings.
--   includeGlobalSettings: import global settings.
--   includeGlobalAnchors: import global anchors.
function SCMAPI.ImportProfile(profileName, importString, importSettings)
	SCM:ImportProfile(profileName, importString, importSettings)
end

function SCMAPI.ImportGlobalSettings(importString)
	SCM:ImportGlobalSettings(importString)
end

function SCMAPI.ImportGlobalAnchors(importString)
	SCM:ImportGlobalAnchors(importString)
end

function SCMAPI.AddCustomIcon(anchorGroup, iconType, configID, order, uniqueID, isGlobal)
	local uniqueID = SCM:AddCustomIcon(anchorGroup, iconType, configID, order, uniqueID, isGlobal)
	if not uniqueID then
		return
	end

	SCM:ApplyAnchorGroupCDManagerConfig(anchorGroup, isGlobal)
	return uniqueID, SCM:GetConfigTableByID(uniqueID, iconType, isGlobal)
end

function SCMAPI.RegisterAndLoadConfig(profileName, classFileName, config, specID)
	SCM.DB:RegisterAndLoadConfig(profileName, classFileName, config, specID)
end

function SCMAPI.RegisterCustomSkin(skinFunction)
	tinsert(SCM.Skins, skinFunction)
end

function SCMAPI.ReloadSkins()
	SCM:ApplyAllCDManagerConfigs()
end

function SCMAPI.RegisterCustomAnchor(frame, options, override)
	if frame and (not SCM.CustomAnchors[frame] or override) then
		SCM.CustomAnchors[frame] = options
	end
end

function SCMAPI.RegisterCustomEntry(customEntry)
	tinsert(SCM.CustomEntries, customEntry)
end

function SCMAPI.SetPrimaryResourceBarColorOverride(r, g, b)
	return SCM:SetPrimaryResourceBarColorOverride(r, g, b)
end

function SCMAPI.ClearPrimaryResourceBarColorOverride()
	return SCM:ClearPrimaryResourceBarColorOverride()
end

function SCMAPI.SetPrimaryResourceBarTextOverride(text)
	return SCM:SetPrimaryResourceBarTextOverride(text)
end

function SCMAPI.ClearPrimaryResourceBarTextOverride()
	return SCM:ClearPrimaryResourceBarTextOverride()
end

function SCMAPI.FetchAnchors()
	return SCM.anchorFrames
end
