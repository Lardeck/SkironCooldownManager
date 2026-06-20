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

function SCMAPI.ImportProfile(profileName, importString)
	SCM:ImportProfile(profileName, importString)
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

-- callback(group, anchorFrame, effectiveWidth, effectiveHeight, rowConfig, options, enabled)
-- callbackOptions: { displayName = string, defaultEnabled = boolean, group = number, groups = table, roles = table }
function SCMAPI.RegisterAnchorLayoutCallback(addOnName, callback, callbackOptions, override)
	if type(callbackOptions) == "boolean" then
		override = callbackOptions
		callbackOptions = nil
	end

	return SCM:RegisterAnchorLayoutCallback(addOnName, callback, callbackOptions, override)
end

function SCMAPI.UnregisterAnchorLayoutCallback(addOnName)
	return SCM:UnregisterAnchorLayoutCallback(addOnName)
end

function SCMAPI.IsAnchorLayoutCallbackEnabled(addOnName)
	return SCM:IsAnchorLayoutCallbackEnabled(addOnName)
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
