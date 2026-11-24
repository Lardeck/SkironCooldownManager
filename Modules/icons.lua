local SCM = select(2, ...)

local Cache = SCM.Cache
local Icons = SCM.Icons

local function OnSetAlpha(self)
	UIParent.SetAlpha(self, self.SCMHidden and 0 or 1)
end
function Icons.HideChild(child)
	SCM.StopChildGlows(child)
	SCM.States.HideAllStateBorders(child)
	SCM:ClearChildPressOverlay(child)

	if child.SCMSpellID and not child.SCMBuffOptions and not child.SCMBuffBar then
		Cache.cachedChildsBySpellID[child.SCMSpellID] = nil
	end

	if child.SCMHidden then
		return
	elseif not child.viewerFrame then
		child.SCMHidden = true
		UIParent.SetAlpha(child, 0)
		return
	end

	SCM:PositionHiddenManagedChild(child)
	child.SCMHidden = true
	UIParent.SetAlpha(child, 0)
	child:EnableMouse(false)
	child:SetMouseClickEnabled(false)
	child:SetMouseMotionEnabled(false)
	if not child.SCMAlphaHook then
		child.SCMAlphaHook = true
		hooksecurefunc(child, "SetAlpha", OnSetAlpha)
	end
end

local function CancelChildHideTimer(child)
	if child.SCMHideTimer then
		child.SCMHideTimer:Cancel()
		child.SCMHideTimer = nil
	end
end

function Icons.ShowChild(child)
	CancelChildHideTimer(child)

	if child.SCMLayoutLimited then
		return
	end

	if child.SCMSpellID and not child.SCMBuffOptions and not child.SCMBuffBar then
		Cache.cachedChildsBySpellID[child.SCMSpellID] = child
	end

	if child.viewerFrame and child.SCMHidden then
		child.SCMHidden = false
		UIParent.SetAlpha(child, 1)
		child:SetMouseClickEnabled(false)

		if SCM.showTooltips then
			child:EnableMouse(true)
			child:SetMouseMotionEnabled(true)
		else
			child:EnableMouse(false)
		end

		SCM.States.RestoreVisualEffects(child)
	end
end

function Icons.SetChildVisibilityState(child, shouldShow, applyNow)
	child.SCMShouldBeVisible = shouldShow and true or false
	if not applyNow then
		return
	end

	child.SCMAppliedVisibility = child.SCMShouldBeVisible and not child.SCMLayoutLimited
	child.SCMAppliedLayoutLimited = child.SCMLayoutLimited and true or false

	if child.viewerFrame then
		if shouldShow and not child.SCMLayoutLimited then
			Icons.ShowChild(child)
		else
			Icons.HideChild(child)
		end
		return
	end

	if not child.SCMShouldBeVisible or child.SCMLayoutLimited then
		SCM.StopChildGlows(child)
		SCM.States.HideAllStateBorders(child)
	end

	if child.SCMCustom and not child:GetAttribute("statehidden") then
		local shouldBeShown = child.SCMShouldBeVisible and not child.SCMLayoutLimited
		if child:IsShown() == shouldBeShown then
			return
		end

		child.SCMSkipShowValidation = shouldBeShown and true or nil
		child:SetShown(shouldBeShown)
		child.SCMSkipShowValidation = nil

		if shouldBeShown then
			SCM.States.RestoreVisualEffects(child)
		end
	end
end

function Icons.UpdateChildDesaturation(child, shouldDesaturate, forceDesaturation)
	if child.Icon and child.SCMConfig then
		if forceDesaturation then
			child.Icon.SCMDesaturated = shouldDesaturate
		else
			child.Icon.SCMDesaturated = nil
		end

		if child.Icon.Icon then
			child.Icon.Icon:SetDesaturated(shouldDesaturate)
		else
			child.Icon:SetDesaturated(shouldDesaturate)
		end
	end
end
