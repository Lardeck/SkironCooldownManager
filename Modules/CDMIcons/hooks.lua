local SCM = select(2, ...)

local Icons = SCM.Icons
local Constants = SCM.Constants
local Cooldowns = SCM.Cooldowns

local function OnShow(child)
	UIParent.SetAlpha(child, child.SCMHidden and 0 or 1)
	if child.SCMGroup and (child.SCMChanged or child.SCMBuffBar) then
		if child.SCMBuffBar and child.SCMSpellID and (not SCM.OptionsFrame or not SCM.OptionsFrame:IsShown()) then
			if Constants.FakeAuras[child.SCMSpellID] then
				child.SCMFakeAuraInstanceID = true
			end

			if child.SCMFakeAuraInstanceID and child.SCMUseFixedDuration then
				child.SCMFixedDuration = GetTime() + Constants.FakeAuras[child.SCMSpellID]
			end
		end

		SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, child.SCMGlobal, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
	end
end

local function OnHide(child)
	SCM:ClearChildPressOverlay(child)

	local shouldRefresh = child.SCMGroup and (child.SCMChanged or child.SCMBuffBar)
	if shouldRefresh then
		if child.SCMBuffBar then
			if child.SCMFakeAuraInstanceID and child.SCMFixedDuration and GetTime() < child.SCMFixedDuration then
				shouldRefresh = false
			elseif child:IsShown() and child.Cooldown and child.Cooldown:IsVisible() then
				shouldRefresh = false
			else
				child.SCMFixedDuration = nil
				child.SCMFakeAuraInstanceID = nil
			end
		end

		if shouldRefresh then
			SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, child.SCMGlobal, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
		end
	end

	SCM.StopChildGlows(child)
end

local function OnSetDesaturated(iconTexture)
	local parent = iconTexture:GetParent()
	if parent and not parent.SCMConfig then
		parent = parent:GetParent()
	end

	local icon = parent and parent.SCMConfig and parent.Icon
	if icon and not parent.SCMCustom and not icon.SCMSkipUpdate and icon.SCMDesaturated ~= nil then
		icon.SCMSkipUpdate = true
		iconTexture:SetDesaturated(icon.SCMDesaturated)
		icon.SCMSkipUpdate = nil
	end
end

local function SetupDesaturationHooks(child)
	local icon = child.Icon
	if not icon or icon.SCMDesaturationHook then
		return
	end

	local texture = icon.Icon or icon
	hooksecurefunc(texture, "SetDesaturated", OnSetDesaturated)
	hooksecurefunc(texture, "SetDesaturation", OnSetDesaturated)
	icon.SCMDesaturationHook = true
end

function Icons.SetupIconHooks(child)
	SetupDesaturationHooks(child)
	if child.SCMShowHook then
		return
	end
	child.SCMShowHook = true

	child:HookScript("OnShow", OnShow)
	child:HookScript("OnHide", OnHide)
end

function Icons.SetupRegularIconHooks(child, options)
	Icons.SetupIconHooks(child)
	Cooldowns.SetupCooldownHooks(child, options)
end

local function SetBuffBarActiveState(child)
	local isActive = child.isActive
	if not issecretvalue(isActive) then
		if isActive then
			OnShow(child)
		else
			OnHide(child)
		end
	end
end

function Icons.SetupBuffBarHooks(child)
	SetupDesaturationHooks(child)
	if child.SCMSpellID and Constants.FakeAuras[child.SCMSpellID] then
		child.SCMUseFixedDuration = type(Constants.FakeAuras[child.SCMSpellID]) == "number" and Constants.FakeAuras[child.SCMSpellID]
	else
		child.SCMFakeAuraInstanceID = nil
		child.SCMUseFixedDuration = nil
	end

	if not child.SCMShowHook then
		child.SCMShowHook = true
		hooksecurefunc(child, "OnActiveStateChanged", SetBuffBarActiveState)
		child:HookScript("OnShow", OnShow)
		child:HookScript("OnHide", OnHide)
	end
end
