local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns
local Icons = SCM.Icons
local Cache = SCM.Cache
local Constants = SCM.Constants

local NumericRuleFormatter = C_StringUtil.CreateNumericRuleFormatter()
Cooldowns.NumericRuleFormatter = NumericRuleFormatter

function Cooldowns.ApplyNumericRuleFormatter(cooldownFrame)
	if cooldownFrame and cooldownFrame.SetCountdownFormatter and not cooldownFrame.SCMFormatter then
		cooldownFrame.SCMFormatter = true
		cooldownFrame:SetCountdownFormatter(NumericRuleFormatter)
	end
end

function Cooldowns:ApplyFormatterSettings()
	local options = SCM.db.profile.options

	NumericRuleFormatter:SetBreakpoints(options.cooldownBreakpoints)
end

local function OnBuffCooldownSet(self)
	local parent = (self.SCMConfig and self) or self:GetParent()
	if not parent or not parent.SCMConfig or (not parent.SCMCheckCooldownFrame and not parent.auraInstanceID) then
		return
	end

	if parent.auraInstanceID and (not parent.SCMAuraInstanceID or parent.auraInstanceID ~= parent.SCMAuraInstanceID) then
		parent.SCMAuraInstanceID = parent.auraInstanceID
		parent.SCMAuraDataUnit = parent.auraDataUnit or parent.SCMAuraDataunit
	end

	if not parent.SCMHidden or parent.SCMConfig.alwaysShow then
		Icons.UpdateChildDesaturation(parent, false)
		Icons.UpdateChildGlow(parent, false)

		if parent.SCMConfig.showWhileInactive then
			Icons.HideChild(parent)
			SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, nil, parent.viewerFrame and parent.viewerFrame.SCMUpdateScope)
		end
	elseif parent.SCMHidden then
		Icons.ShowChild(parent)
		Icons.UpdateChildDesaturation(parent, false)
		Icons.UpdateChildGlow(parent, false)
		SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, nil, parent.viewerFrame and parent.viewerFrame.SCMUpdateScope)
	end
end

local function OnBuffCooldownEnd(self)
	local parent = (self.SCMConfig and self) or self:GetParent()
	if not parent or not parent.SCMConfig then
		return
	end

	if parent.SCMAuraInstanceID and not parent.SCMCheckCooldownFrame then
		if not C_UnitAuras.GetAuraDataByAuraInstanceID(parent.SCMAuraDataUnit, parent.SCMAuraInstanceID) and
		C_UnitAuras.IsAuraFilteredOutByInstanceID(parent.SCMAuraDataUnit, parent.SCMAuraInstanceID, "PLAYER") then
			parent.SCMAuraInstanceID = nil
			parent.SCMAuraDataUnit = nil
		else
			return
		end
	end

	Icons.UpdateChildGlow(parent, true)

	if parent.SCMConfig.alwaysShow then
		Icons.UpdateChildDesaturation(parent, true)
		return
	end

	--local options = parent.SCMBuffOptions
	if not parent.SCMHidden or (parent.SCMHidden and parent.SCMConfig.showWhileInactive) then
		SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, nil, parent.viewerFrame and parent.viewerFrame.SCMUpdateScope)
	end
end

local function OnBuffTriggerPandemicAlert(self)
	local options = self.SCMBuffOptions or self.SCMIconOptions
	if options and options.pandemicGlowOption ~= "keepPandemicGlow" and not self.SCMPandemic then
		self.SCMPandemic = true
	end
end

local function OnBuffShowPandemicStateFrame(self)
	if not self.PandemicIcon or not self.PandemicIcon:IsVisible() then
		return
	end

	local options = self.SCMBuffOptions or self.SCMIconOptions
	if not options or options.pandemicGlowOption == "keepPandemicGlow" then
		return
	end

	self.PandemicIcon:SetAlpha(0)

	if not self.SCMGlow and options.pandemicGlowOption == "replacePandemicGlow" then
		SCM:StartCustomGlow(self)
	end
end

local function OnBuffHidePandemicStateFrame(self)
	local options = self.SCMBuffOptions or self.SCMIconOptions
	if not options then
		return
	end

	if self.SCMGlow and options.pandemicGlowOption == "replacePandemicGlow" then
		SCM:StopCustomGlow(self)
	end
end

function Cooldowns.SetupBuffIconHooks(child, options)
	local checkCooldownFrame = Constants.FakeAuras[child.SCMSpellID] or Constants.TargetAuras[child.SCMSpellID]
	if (checkCooldownFrame and child.SCMCooldownHooked) or (not checkCooldownFrame and child.SCMAuraHooked) then
		return
	end

	Icons.SetupIconHooks(child)
	child.SCMBuffOptions = options

	-- Cooldowns
	if checkCooldownFrame then
		if not child.SCMCooldownHooked then
			hooksecurefunc(child.Cooldown, "SetCooldown", OnBuffCooldownSet)
			hooksecurefunc(child.Cooldown, "Clear", OnBuffCooldownEnd)
			child.Cooldown:HookScript("OnCooldownDone", OnBuffCooldownEnd)
			child.SCMCooldownHooked = true
		end

		child.SCMCheckCooldownFrame = true
	else
		if not child.SCMAuraHooked then
			hooksecurefunc(child, "OnAuraInstanceInfoSet", OnBuffCooldownSet)
			hooksecurefunc(child, "OnAuraInstanceInfoCleared", OnBuffCooldownEnd)
			child.SCMAuraHooked = true
		end

		child.SCMCheckCooldownFrame = nil
	end

	-- Pandmic Alerts
	if not child.SCMPandemicHooked then
		hooksecurefunc(child, "TriggerPandemicAlert", OnBuffTriggerPandemicAlert)
		hooksecurefunc(child, "ShowPandemicStateFrame", OnBuffShowPandemicStateFrame)
		hooksecurefunc(child, "HidePandemicStateFrame", OnBuffHidePandemicStateFrame)
		child.SCMPandemicHooked = true
	end
end

function Cooldowns.IsChildOnCooldown(child)
	if not child or not child.Cooldown then
		return
	end

	local spellCooldownInfo = C_Spell.GetSpellCooldown(child.SCMSpellID)
	local isOnCooldown = spellCooldownInfo and spellCooldownInfo.isActive and not spellCooldownInfo.isOnGCD
	if Constants.CheckCooldownFrameSpells[child.SCMSpellID] then
		return isOnCooldown and child.Cooldown:IsVisible()
	end

	return isOnCooldown
end

function Cooldowns.SetNormalCooldown(self, parent)
	local cooldownData = SCM.defaultCooldownViewerConfig.cooldownIDs[parent.SCMCooldownID]
	self.SCMSettingRegularSpellCooldown = true

	local durationObject
	local desaturate = false

	local spellCooldown = C_Spell.GetSpellCooldown(parent.SCMSpellID)
	if spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
		desaturate = true
		durationObject = C_Spell.GetSpellCooldownDuration(parent.SCMSpellID, true)
	end

	if cooldownData.charges and not durationObject then
		local spellCharges = C_Spell.GetSpellCharges(parent.SCMSpellID)
		if spellCharges and spellCharges.isActive and not spellCharges.isOnGCD then
			durationObject = C_Spell.GetSpellChargeDuration(parent.SCMSpellID, true)
		end
	end

	if durationObject then
		parent.Icon.SCMDesaturated = desaturate
		parent.Icon:SetDesaturated(desaturate)
		self:SetCooldownFromDurationObject(durationObject)
	else
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
		self:Clear()
	end

	self.SCMSettingRegularSpellCooldown = nil
end

function Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
	if not options.disableRegularIconActiveSwipe or not parent.SCMSpellID or not self:GetUseAuraDisplayTime() or parent.SCMConfig.forceActiveSwipe then
		parent.Icon.SCMDesaturated = nil
		return
	end

	Cooldowns.SetNormalCooldown(self, parent)
end

local function SetRegularChildCooldown(child, cooldownInfo)
	local cooldownFrame = child.Cooldown
	if not (cooldownFrame and child.Icon) then
		return
	end

	Cooldowns.SetNormalCooldown(cooldownFrame, child)
end

local function OverwriteViewerChildCooldown(viewer, spellID, cooldownInfo)
	local children = Cache.cachedViewerChildren[viewer]
	if not children then
		children = { viewer:GetChildren() }
		Cache.cachedViewerChildren[viewer] = children
	end

	for i = 1, #children do
		local child = children[i]
		if child.SCMConfig and not child.SCMBuffBar and not child.SCMConfig.forceActiveSwipe and child.SCMSpellID == spellID then
			SetRegularChildCooldown(child, cooldownInfo)
		end
	end
end

function Cooldowns.OverwriteRegularChildCooldownBySpellID(spellID, overrideSpellID, cooldownInfo)
	OverwriteViewerChildCooldown(EssentialCooldownViewer, spellID, cooldownInfo)
	OverwriteViewerChildCooldown(UtilityCooldownViewer, spellID, cooldownInfo)
end

local function OnRegularCooldownChanged(self, changeType)
	local parent = self:GetParent()
	if not (parent and parent.SCMConfig) or self.SCMSettingRegularSpellCooldown or self.SCMClearingGCD then
		return
	end

	local options = SCM.db.profile.options
	local useAuraDisplayTime = self:GetUseAuraDisplayTime()
	if options.disableRegularIconActiveSwipe and not parent.SCMConfig.forceActiveSwipe and useAuraDisplayTime then
		Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
	elseif options.disableGCD or (changeType == "CLEAR" and Constants.FixBlizzardSpells[parent.SCMSpellID]) then
		Cooldowns.SetNormalCooldown(self, parent)
	elseif parent.Icon.SCMDesaturated and not useAuraDisplayTime then
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
	end

	local config = parent.SCMConfig
	if config.hideWhenNotOnCooldown then
		local shouldShow = Cooldowns.IsChildOnCooldown(parent) and true or false
		if parent.SCMShouldBeVisible ~= shouldShow then
			local viewer = parent.viewerFrame
			if viewer then
				if viewer == EssentialCooldownViewer then
					SCM:ApplyEssentialCDManagerConfig()
				elseif viewer == UtilityCooldownViewer then
					SCM:ApplyUtilityCDManagerConfig()
				end
			elseif parent.SCMGroup then
				SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, parent.SCMGlobal)
			else
				SCM:ApplyAllCDManagerConfigs()
			end
		end
	end

	Icons.UpdateChildGlow(parent, not useAuraDisplayTime)
end

function Cooldowns.SetupCooldownHooks(child)
	if child.SCMRegularCooldownHook or not child.Cooldown then
		return
	end

	hooksecurefunc(child.Cooldown, "SetCooldown", function(self)
		OnRegularCooldownChanged(self, "SET")
	end)
	hooksecurefunc(child.Cooldown, "Clear", function(self)
		OnRegularCooldownChanged(self, "CLEAR")
	end)

	child.Cooldown:HookScript("OnCooldownDone", function(self, ...)
		local parent = self:GetParent()
		parent.Icon.SCMDesaturated = nil
		OnRegularCooldownChanged(self, "DONE")
	end)
	child.SCMRegularCooldownHook = true

	hooksecurefunc(child, "TriggerPandemicAlert", OnBuffTriggerPandemicAlert)
	hooksecurefunc(child, "ShowPandemicStateFrame", OnBuffShowPandemicStateFrame)
	hooksecurefunc(child, "HidePandemicStateFrame", OnBuffHidePandemicStateFrame)
end