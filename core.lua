local addonName, SCM = ...

SCM.CDM = {}
SCM.Options = {}
SCM.Cache = {}
SCM.Utils = {}
SCM.CustomIcons = {}
SCM.Cooldowns = {}
SCM.Icons = {}
SCM.anchorFrames = {}
SCM.itemFrames = {}
SCM.MainTabs = {}
SCM.OptionsCallbacks = {}
SCM.Skins = {}
SCM.CustomAnchors = {}
SCM.AnchorLayoutCallbacks = {}
SCM.AnchorLayoutCallbackOrder = {}
SCM.AnchorLayoutState = {}
SCM.CustomEntries = {}
SCM.Templates = {}
SCM.States = {}

function SCM.RefreshCooldownViewerData(releaseCustomIcons)
	SCM:InvalidateAnchorLinks()
	SCM:UpdateCooldownInfo(true)
	SCM:UpdateDB()

	if releaseCustomIcons then
		SCM:ResetCooldownViewerRuntimeState()
		SCM.CustomIcons.ReleaseAllIcons()
	end
	SCM:CreateAllCustomIcons()
	SCM:ApplyAllCDManagerConfigs(true)
	SCM:UpdateCastBar()
	SCM:RefreshResourceBarConfig()
end

local function OnProfileChanged(_, _, _, skipReset)
	if SCM.importingProfile then return end

	-- Hopefully players won't change profiles that much that we reach the frame limit :)
	if not skipReset then
		SCM.DB:ResetData()
	end

	SCM:InvalidateAnchorLinks()
	SCM:UpdateDB()

	SCM.appliedOptions = nil
	SCM:ApplyOptions()

	SCM.RefreshCooldownViewerData(true)

	local options = SCM.db.profile.options
	if SCM.OptionsFrame and SCM.OptionsFrame:IsShown() and options and options.showAnchorHighlight then
		for _, anchorFrame in pairs(SCM.anchorFrames) do
			anchorFrame.debugTexture:Show()
			anchorFrame.debugText:Show()
		end
	end
end

function SCM:LoadNewProfile()
	OnProfileChanged(nil, nil, nil, true)
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
	SCM.db = LibStub("AceDB-3.0"):New(addonName .. "DB", SCM.DefaultDB, true)
	SCM.LibDualSpec = LibStub("LibDualSpec-1.0")
	SCM.LibDualSpec:EnhanceDatabase(SCM.db, addonName)
	SCM:MigrateLegacyProfileOptions()
	SCM.db.RegisterCallback(SCM, "OnProfileChanged", OnProfileChanged)
	SCM.db.RegisterCallback(SCM, "OnProfileCopied", OnProfileChanged)
	SCM.db.RegisterCallback(SCM, "OnProfileReset", OnProfileChanged)

	SCM:GetAnchor(1)
	C_CVar.SetCVar("cooldownViewerEnabled", "1")

	SCM.InitializeEventFrame()
end)


if IsTestBuild() and not SetDesaturation then
	SetDesaturation = function(frame, desaturate)
		if frame.SetDesaturation then
			frame:SetDesaturation(desaturate and 1 or 0)
		end
	end
end
