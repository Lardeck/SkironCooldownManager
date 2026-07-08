local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns
local Icons = SCM.Icons
local Cache = SCM.Cache
local Constants = SCM.Constants
local States = SCM.States

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

local function SetBuffActive(parent)
	if parent.SCMUseFixedDuration then
		parent.SCMFixedDuration = parent.SCMFixedDuration or GetTime() + parent.SCMUseFixedDuration
	end

	parent.SCMActive = true
	States.SetActiveState(parent, true)
end

local function SetBuffInactive(parent, isActiveState)
	if parent.SCMFixedDuration and GetTime() < parent.SCMFixedDuration then
		return
	elseif parent:IsShown() and parent.Cooldown and parent.Cooldown:IsVisible() and not isActiveState then
		return
	end

	parent.SCMFixedDuration = nil
	parent.SCMActive = nil
	States.SetActiveState(parent, false)
end

local function OnBuffActiveStateChanged(self)
	if not self.SCMConfig then
		return
	elseif issecretvalue(self.isActive) then
		-- print("SECRET ACTIVE STATE", self.SCMSpellID, C_Spell.GetSpellName(self.SCMSpellID))
		return
	end

	if self.isActive then
		-- print("NOT SECRET ACTIVE", self.SCMSpellID, C_Spell.GetSpellName(self.SCMSpellID))
		SetBuffActive(self)
	else
		-- print("NOT SECRET INACTIVE", self.SCMSpellID, C_Spell.GetSpellName(self.SCMSpellID))
		SetBuffInactive(self, true)
	end
end

local function OnBuffCooldownSet(self)
	local parent = (self.SCMConfig and self) or self.SCMParent or self:GetParent()
	if not parent or not parent.SCMConfig or not issecretvalue(self.isActive) or (not parent.SCMCheckCooldownFrame and not parent.auraInstanceID) then
		return
	end

	-- print("BACKUP ACTIVE", parent.SCMSpellID, C_Spell.GetSpellName(parent.SCMSpellID))
	SetBuffActive(parent)
end

local function OnBuffCooldownEnd(self)
	local parent = (self.SCMConfig and self) or self.SCMParent or self:GetParent()
	if not parent or not parent.SCMConfig or not issecretvalue(parent.isActive) then
		return
	end

	-- print("BACKUP INACTIVE", parent.SCMSpellID, C_Spell.GetSpellName(parent.SCMSpellID))

	SetBuffInactive(parent)
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

	if self.SCMPandemicStop then
		self.SCMPandemicStop:Cancel()
		self.SCMPandemicStop = nil
	end

	if not self.SCMPandemic and options.pandemicGlowOption == "replacePandemicGlow" then
		self.SCMPandemic = true

		if options.pandemicReplaceWithBorder and self.pandemicBorder then
			self.pandemicBorder:Show()
		elseif not self.SCMGlow then
			if options.pandemicReplaceWithCustomGlow then
				SCM:StartCustomGlow(self, options.pandemicCustomGlowTypeOptions[options.pandemicGlowType], options.pandemicGlowType)
			else
				SCM:StartCustomGlow(self)
			end
		end
	end
end

local function OnBuffHidePandemicStateFrame(self)
	if not self.SCMPandemic or self.SCMPandemicStop then
		return
	end

	local options = self.SCMBuffOptions or self.SCMIconOptions
	if not options or options.pandemicGlowOption ~= "replacePandemicGlow" then
		return
	end

	self.SCMPandemicStop = C_Timer.NewTimer(0.1, function()
		if options.pandemicReplaceWithBorder and self.pandemicBorder then
			self.pandemicBorder:Hide()
		else
			SCM:StopCustomGlow(self)
		end
		self.SCMPandemic = nil
	end)
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
			hooksecurefunc(child, "OnAuraInstanceInfoSet", OnBuffCooldownSet)
			hooksecurefunc(child.Cooldown, "Clear", OnBuffCooldownEnd)
			child.Cooldown:HookScript("OnCooldownDone", OnBuffCooldownEnd)
			hooksecurefunc(child, "OnActiveStateChanged", OnBuffActiveStateChanged)
			child.SCMCooldownHooked = true
		end

		child.SCMCheckCooldownFrame = true
		child.SCMUseFixedDuration = type(Constants.FakeAuras[child.SCMSpellID]) == "number" and Constants.FakeAuras[child.SCMSpellID]
	else
		if not child.SCMAuraHooked then
			hooksecurefunc(child, "OnAuraInstanceInfoSet", OnBuffCooldownSet)
			hooksecurefunc(child, "OnAuraInstanceInfoCleared", function(self)
				C_Timer.After(0, function()
					OnBuffCooldownEnd(self)
				end)
			end)

			hooksecurefunc(child, "OnActiveStateChanged", OnBuffActiveStateChanged)
			child.SCMAuraHooked = true
		end

		child.SCMCheckCooldownFrame = nil
		child.SCMUseFixedDuration = nil
	end

	-- Pandmic Alerts
	if not child.SCMPandemicHooked then
		--hooksecurefunc(child, "TriggerPandemicAlert", OnBuffTriggerPandemicAlert)
		hooksecurefunc(child, "ShowPandemicStateFrame", OnBuffShowPandemicStateFrame)
		hooksecurefunc(child, "HidePandemicStateFrame", OnBuffHidePandemicStateFrame)
		child.SCMPandemicHooked = true
	end
end

function Cooldowns.GetChildCooldown(child)
	if not child.SCMSpellID then
		return
	end

	local cooldownData = SCM.defaultCooldownViewerConfig.cooldownIDs[child.SCMCooldownID]

	local durationObject

	local spellCooldown = C_Spell.GetSpellCooldown(child.SCMSpellID)
	if spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
		durationObject = C_Spell.GetSpellCooldownDuration(child.SCMSpellID, true)
	end

	if cooldownData.charges and not durationObject then
		local spellCharges = C_Spell.GetSpellCharges(child.SCMSpellID)
		if spellCharges and spellCharges.isActive and not spellCharges.isOnGCD then
			durationObject = C_Spell.GetSpellChargeDuration(child.SCMSpellID, true)
		end
	end

	if Constants.CheckCooldownFrameSpells[child.SCMSpellID] then
		return durationObject ~= nil and child.Cooldown:IsVisible(), durationObject
	end

	return durationObject ~= nil, durationObject
end

function Cooldowns.SetNormalCooldown(self, parent)
	local cooldownData = SCM.defaultCooldownViewerConfig.cooldownIDs[parent.SCMCooldownID]
	self.SCMSettingRegularSpellCooldown = true

	local durationObject
	local desaturate = false
	local isChargeCooldown = false

	local spellID = FindSpellOverrideByID(parent.SCMSpellID)
	local spellCooldown = C_Spell.GetSpellCooldown(spellID)
	if spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
		desaturate = true
		durationObject = C_Spell.GetSpellCooldownDuration(spellID, true)
	end

	if cooldownData.charges and not durationObject then
		local spellCharges = C_Spell.GetSpellCharges(spellID)
		if spellCharges and spellCharges.isActive and not spellCharges.isOnGCD then
			isChargeCooldown = true
			durationObject = C_Spell.GetSpellChargeDuration(spellID, true)
		end
	end

	local options = SCM.db.profile.options
	if durationObject then
		self:Clear()
		parent.Icon.SCMDesaturated = desaturate
		parent.Icon:SetDesaturated(desaturate)
		if isChargeCooldown then
			self:SetDrawEdge(true)
			self:SetDrawSwipe(false)
			self:SetCooldownFromDurationObject(durationObject)
		else
			self:SetDrawEdge(false)
			self:SetDrawSwipe(true)
			self:SetCooldownFromDurationObject(durationObject)
		end
	elseif not self:GetUseAuraDisplayTime() or (options.disableRegularIconActiveSwipe and not parent.SCMConfig.forceActiveSwipe) then
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
		self:Clear()
	end

	self.SCMSettingRegularSpellCooldown = nil
end

function Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
	local config = parent.SCMConfig
	if not parent.SCMSpellID or not self:GetUseAuraDisplayTime() or config.forceActiveSwipe or not (options.disableRegularIconActiveSwipe or config.hideActiveSwipe) then
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
	local parent = self.SCMParent or self:GetParent()
	if not (parent and parent.SCMConfig) or self.SCMSettingRegularSpellCooldown or self.SCMClearingGCD then
		return
	end

	local options = SCM.db.profile.options
	local config = parent.SCMConfig
	local useAuraDisplayTime = self:GetUseAuraDisplayTime()
	if options.disableRegularIconActiveSwipe and not config.forceActiveSwipe and useAuraDisplayTime then
		Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
	elseif options.disableGCD or (changeType == "CLEAR" and Constants.FixBlizzardSpells[parent.SCMSpellID]) then
		Cooldowns.SetNormalCooldown(self, parent)
	elseif parent.Icon.SCMDesaturated and not useAuraDisplayTime then
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
	end

	if config.stateOptions then
		RunNextFrame(function()
			States.SetActiveState(parent, useAuraDisplayTime)
			States.SetCooldownState(parent, Cooldowns.GetChildCooldown(parent))
		end)
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

	child.Cooldown.SCMParent = child
	child.Cooldown:HookScript("OnCooldownDone", function(self, ...)
		local parent = self.SCMParent or self:GetParent()
		parent.Icon.SCMDesaturated = nil
		OnRegularCooldownChanged(self, "DONE")
	end)
	child.SCMRegularCooldownHook = true

	--hooksecurefunc(child, "TriggerPandemicAlert", OnBuffTriggerPandemicAlert)
	hooksecurefunc(child, "ShowPandemicStateFrame", OnBuffShowPandemicStateFrame)
	hooksecurefunc(child, "HidePandemicStateFrame", OnBuffHidePandemicStateFrame)
end
