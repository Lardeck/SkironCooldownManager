local SCM = select(2, ...)

local function OnSpellAlertManagerShowAlert(_, child)
	local options = SCM.db.profile.options
	if child.SCMConfig and child.SpellActivationAlert then
		child.SpellActivationAlert:SetFrameStrata(child:GetFrameStrata())
		child.SpellActivationAlert:SetFrameLevel(child:GetFrameLevel() + (options.glowFrameLevel or 2))
	end
	if not child.SCMConfig or not options.useCustomGlow or child.SCMActiveGlow then
		if child.SCMWidth and child.SCMHeight then
			local width = child.SCMWidth
			local height = child.SCMHeight

			local alert = child.SpellActivationAlert
			alert:SetSize(width * 1.4, height * 1.4)
		end
		return
	end

	child.SCMActiveGlow = true
	child.SpellActivationAlert:Hide()

	if child.SCMPendingCustomGlow then
		child.SCMPendingCustomGlow:Cancel()
		child.SCMPendingCustomGlow = nil
	end

	-- The size of the glow is too large when you start the glow immediately if anyone is wondering why I do that
	child.SCMPendingCustomGlow = C_Timer.NewTimer(0, function()
		child.SCMPendingCustomGlow = nil
		SCM:StartCustomGlow(child)
	end)
end

local function OnSpellAlertManagerHideAlert(_, child)
	if child.SCMConfig and child.SCMActiveGlow then
		if child.SCMPendingCustomGlow then
			child.SCMPendingCustomGlow:Cancel()
			child.SCMPendingCustomGlow = nil
		end

		child.SCMActiveGlow = nil
		SCM:StopCustomGlow(child)
	end
end

local function OnEssentialCooldownViewerLayout(viewer)
	SCM:ApplyEssentialCDManagerConfig(SCM.Icons.IsViewerLayoutDirty(viewer))
end

local function OnUtilityCooldownViewerLayout(viewer)
	SCM:ApplyUtilityCDManagerConfig(SCM.Icons.IsViewerLayoutDirty(viewer))
end

local function OnBuffCooldownViewerLayout(viewer)
	local forceLayout = SCM.Icons.IsViewerLayoutDirty(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:ApplyBuffIconCDManagerConfig(forceLayout)
end

local function OnBuffBarViewerLayout(viewer)
	local forceLayout = SCM.Icons.IsViewerLayoutDirty(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:ApplyBuffBarCDManagerConfig(forceLayout)
end

local function OnCooldownViewerSettingsRefreshLayout()
	SCM.RefreshCooldownViewerData(true)
end

function SCM.SetHooks()
	GroupLootContainer:SetClampedToScreen(true)

	hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", OnEssentialCooldownViewerLayout)
	hooksecurefunc(UtilityCooldownViewer, "RefreshLayout", OnUtilityCooldownViewerLayout)
	hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", OnBuffCooldownViewerLayout)
	hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", OnBuffBarViewerLayout)
	hooksecurefunc(CooldownViewerSettings, "RefreshLayout", OnCooldownViewerSettingsRefreshLayout)

	if ActionButtonSpellAlertManager then
		hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", OnSpellAlertManagerShowAlert)
		hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", OnSpellAlertManagerHideAlert)
	end

	hooksecurefunc(UIParent, "SetScale", function(self)
		if self == UIParent then
			SCM.RefreshCooldownViewerData(true)
		end
	end)
end
