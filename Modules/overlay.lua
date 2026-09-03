local SCM = select(2, ...)
local Cache = SCM.Cache
local LibActionButton = LibStub("LibActionButton-1.0-ElvUI", true) or LibStub("LibActionButton-1.0", true)

local blizzardActionButtonHooksSet
local ellesmereUIActionButtonHooksSet
local elvUIActionButtonHooksSet

local function SetPressOverlay(action, shown)
	local actionType, actionID, actionSubType = GetActionInfo(action)

	local spellID
	if actionType == "spell" or actionSubType == "spell" then
		spellID = FindSpellOverrideByID(actionID) or actionID
	elseif actionType == "macro" then
		spellID = GetMacroSpell(actionID)
	end

	if spellID then
		local child = Cache.cachedChildsBySpellID[spellID]
		if child and child.SCMPressOverlay then
			child.SCMPressOverlay:SetShown(shown)
		end
	end
end

local function OnLABActionButtonPostClick(button, _, down)
	if not SCM.options.pressOverlay or button._state_type ~= "action" then
		return
	end

	SetPressOverlay(button._state_action, down)
end

local function HookLABActionButton(button)
	if button.SCMPressOverlayHooked then
		return
	end

	button.SCMPressOverlayHooked = true
	button:HookScript("PostClick", OnLABActionButtonPostClick)
end

local function OnLABActionButtonCreated(_, button)
	HookLABActionButton(button)
end

local function SetLABActionButtonHooks()
	if elvUIActionButtonHooksSet then
		return
	end

	elvUIActionButtonHooksSet = true

	if LibActionButton then
		LibActionButton.RegisterCallback(SCM, "OnButtonCreated", OnLABActionButtonCreated)
		for button in pairs(LibActionButton.buttonRegistry) do
			HookLABActionButton(button)
		end
	end
end

local function SetBlizzardActionButtonHooks()
	if blizzardActionButtonHooksSet then
		return
	end

	blizzardActionButtonHooksSet = true

	hooksecurefunc("ActionButtonDown", function(id)
		if not SCM.options.pressOverlay then
			return
		end

		local actionButton = GetActionButtonForID(id)
		if actionButton then
			SetPressOverlay(actionButton.action, true)
		end
	end)

	hooksecurefunc("ActionButtonUp", function(id)
		if not SCM.options.pressOverlay then
			return
		end
		local actionButton = GetActionButtonForID(id)
		if actionButton then
			SetPressOverlay(actionButton.action, false)
		end
	end)

	hooksecurefunc("MultiActionButtonDown", function(barName, id)
		if not SCM.options.pressOverlay then
			return
		end

		local bar = _G[barName]
		if bar then
			SetPressOverlay(bar.actionButtons[id].action, true)
		end
	end)

	hooksecurefunc("MultiActionButtonUp", function(barName, id)
		if not SCM.options.pressOverlay then
			return
		end

		local bar = _G[barName]
		if bar then
			SetPressOverlay(bar.actionButtons[id].action, false)
		end
	end)
end

local function OnEllesmereUIActionButtonPress(button, down)
	if not SCM.options.pressOverlay then
		return
	end

	local action = button:GetAttribute("action") or button.action
	if action then
		SetPressOverlay(action, down)
	end
end

local function SetEllesmereUIActionButtonHooks()
	if ellesmereUIActionButtonHooksSet then
		return
	end

	ellesmereUIActionButtonHooksSet = true
	if _EUI_OnActionButtonPress then
		hooksecurefunc("_EUI_OnActionButtonPress", OnEllesmereUIActionButtonPress)
	end
end

function SCM:InitializePressOverlay()
	if not SCM.options.pressOverlay then
		return
	end

	SetLABActionButtonHooks()
	SetBlizzardActionButtonHooks()

	if C_AddOns.IsAddOnLoaded("EllesmereUIActionBars") then
		SetEllesmereUIActionButtonHooks()
	end
end
