local SCM = select(2, ...)
local LSM = LibStub("LibSharedMedia-3.0")
local Utils = SCM.Utils

SCMSwingTimerMixin = CreateFromMixins(SwingTimerMixin)
SCMSwingTimerMixin.SetIsInEditMode = nil
SCMSwingTimerMixin.OnUpdate = nil

local SWING_TIMER_EVENTS = {
	"PLAYER_IN_COMBAT_CHANGED",
	"PLAYER_TARGET_CHANGED",
	"WEAPON_SLOT_CHANGED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_SWING_RANGE_UPDATE",
	"PLAYER_REGEN_ENABLED",
}

function SCMSwingTimerMixin:OnLoad()
	self.durationFormatter = SCM.Formatter.CreateFormatter(SCM.DefaultSwingTimerBreakpoints)
	self.durationObject = C_DurationUtil.CreateDuration()
	self.durationTextBinding = C_DurationUtil.CreateDurationTextBinding()
	self.durationTextBinding:SetDuration(self.durationObject)
	self.durationTextBinding:SetFontString(self.StatusBar.Duration)
	self.durationFormatter:SetDurationTextBinding(self.durationTextBinding)
	self.durationTextBinding:SetExpiredText("")
	self.durationTextBinding:SetZeroDurationText("")
	self.expirationSignals = C_Timer.NewTimedSignalMap(function()
		self:ClearSwingTimer()
	end)

	FrameUtil.RegisterFrameForEvents(self, SWING_TIMER_EVENTS)
	self:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")

	self:ClearSwingTimer()
end

function SCMSwingTimerMixin:Init(swingType, typeText, barOptions)
	self.swingType = swingType
	self.typeText = typeText
	self.barOptions = barOptions
	self:UpdateWeaponState()
	self:InitializeBarPresentation()

	for _, texture in ipairs({ self.Border:GetRegions() }) do
		texture:SetTexelSnappingBias(0)
		texture:SetSnapToPixelGrid(false)
	end

	SCM.RegisterCallback(self, "SkironCooldownManager.AnchorProxy.SizeChanged", function(_, proxyGroup, _, _, _, _, isActiveProxy)
		if isActiveProxy and self.SCMActiveAnchorGroup == proxyGroup then
			self:UpdateLayout()
		end
	end)
end

function SCMSwingTimerMixin:GetStatusBarPip()
	return self.StatusBar.Spark
end

function SCMSwingTimerMixin:GetTypeLabel()
	return self.StatusBar.Name
end

function SCMSwingTimerMixin:GetTimeLabel()
	return self.StatusBar.Duration
end

function SCMSwingTimerMixin:GetConfig()
	if self.swingType == Enum.PlayerSwingType.OffHand then
		return SCM.swingTimerConfig.OffHand
	elseif self.swingType == Enum.PlayerSwingType.Ranged then
		return SCM.swingTimerConfig.Ranged
	end
	return SCM.swingTimerConfig.MainHand
end

function SCMSwingTimerMixin:UpdateWeaponState()
	if self.swingType == Enum.PlayerSwingType.MainHand then
		self.hasAppropriateWeapon = true
		return
	end

	local attackSpeed = self:GetEquippedSwingDuration()
	if issecretvalue(attackSpeed) then
		return
	end

	self.hasAppropriateWeapon = attackSpeed and attackSpeed > 0 or false
end

function SCMSwingTimerMixin:HasAppropriateWeapon()
	return self.hasAppropriateWeapon
end

function SCMSwingTimerMixin:OnEvent(event, ...)
	if event == "PLAYER_SWING" then
		local duration, swingType = ...
		if self.swingType == swingType and self:ShouldHandleSwing() then
			self:ResetSwingTimer(duration)
		end
	elseif event == "PLAYER_SWING_RANGE_UPDATE" then
		local swingType, isInRange, checksRange = ...
		if self.swingType == swingType and self:ShouldHandleSwing() then
			self:SetOutOfRange(checksRange and not isInRange)
		end
	elseif event == "PLAYER_IN_COMBAT_CHANGED" then
		if self:ShouldHandleSwing() then
			self:UpdateShownState()
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		if self:ShouldHandleSwing() then
			self:UpdateRangeState()
		end
	elseif event == "WEAPON_SLOT_CHANGED" then
		self:UpdateWeaponState()
		self:ApplyConfig(self:GetConfig())
		self:ResetSwingTimerForEquippedWeapon()
	elseif event == "PLAYER_ENTERING_WORLD" or event == "UNIT_ATTACK_SPEED" or event == "PLAYER_REGEN_ENABLED" then
		self:UpdateWeaponState()
		self:ApplyConfig(self:GetConfig())
	end
end

function SCMSwingTimerMixin:OnAttributeChanged(name)
	if name == "statehidden" and self.barOptions then
		self:UpdateShownState()
	end
end

function SCMSwingTimerMixin:OnHide()
	if self:HasSwingTimer() then
		self:ClearSwingTimer()
	end
end

function SCMSwingTimerMixin:HasSwingTimer()
	return not self.durationObject:IsZero()
end

function SCMSwingTimerMixin:IsLoaded()
	return self.barOptions and self.barOptions.enabled
end

function SCMSwingTimerMixin:ShouldDisplaySwing()
	return self:IsLoaded()
end

function SCMSwingTimerMixin:ShouldCheckRange()
	return self:ShouldHandleSwing()
end

function SCMSwingTimerMixin:IsOutOfRange()
	return self.isOutOfRange
end

function SCMSwingTimerMixin:ShouldClearSwing()
	return self:HasSwingTimer() and not self:ShouldHandleSwing()
end

function SCMSwingTimerMixin:ShouldBeShown()
	if not self:ShouldHandleSwing() or self:GetAttribute("statehidden") then
		return false
	end

	return not self.barOptions.hideWhileInactive or self:HasSwingTimer()
end

function SCMSwingTimerMixin:UpdateSparkVisibility()
	local options = self.barOptions
	self.StatusBar.Spark:SetShown(options.spark.enable and self:HasSwingTimer())
end

function SCMSwingTimerMixin:ResetSwingTimer(duration)
	if issecretvalue(duration) or not duration or duration <= 0 or self:GetAttribute("statehidden") then
		return
	end

	self.durationObject:SetTimeFromStart(GetTime(), duration)
	self.StatusBar:SetTimerDuration(self.durationObject, self.interpolation, Enum.StatusBarTimerDirection.ElapsedTime)

	self.durationTextBinding:Enable()
	self.durationTextBinding:UpdateFontString()
	self.expirationSignals:SignalAt(self.swingType, self.durationObject:GetEndTime())

	self:UpdateSparkVisibility()
	if self.barOptions.hideWhileInactive then
		self:UpdateShownState()
	end
end

function SCMSwingTimerMixin:ClearSwingTimer()
	self.expirationSignals:CancelAllSignals()
	self.durationTextBinding:Disable()
	self.durationObject:Reset()
	self.durationTextBinding:UpdateFontString()

	self.StatusBar:SetValue(0)
	self.StatusBar.Spark:Hide()

	if self.barOptions and self.barOptions.hideWhileInactive then
		self:UpdateShownState()
	end
end

function SCMSwingTimerMixin:UpdateSwingEventRegistration()
	if self:ShouldHandleSwing() then
		if not self:IsEventRegistered("PLAYER_SWING") then
			self:RegisterEvent("PLAYER_SWING")
		end
	elseif self:IsEventRegistered("PLAYER_SWING") then
		self:UnregisterEvent("PLAYER_SWING")
	end
end

function SCMSwingTimerMixin:UpdateFrameState()
	SwingTimerMixin.UpdateFrameState(self)
	self:UpdateSwingEventRegistration()
	SCM:RefreshSwingTimerHeights()
end

function SCMSwingTimerMixin:UpdateShownStateAndRegistration()
	self:UpdateFrameState()
end

function SCMSwingTimerMixin:ApplyHeight(height)
	if InCombatLockdown() and self:IsProtected() then
		self.needsRefresh = true
		return
	end

	if self:GetHeight() ~= height then
		self:SetHeight(height)
	end
end

function SCMSwingTimerMixin:HookAnchorWidthRefresh(anchor)
	if not anchor or anchor.SCMProxyGroup or anchor.SCMSwingTimerWidthHook then
		return
	end

	anchor.SCMSwingTimerWidthHook = true
	anchor:HookScript("OnSizeChanged", function(changedAnchor)
		for _, timer in pairs(SCM.SwingTimers) do
			if timer.barOptions.matchAnchorWidth and timer.SCMActiveAnchorFrame == changedAnchor then
				timer:UpdateLayout()
			end
		end
	end)
end

function SCMSwingTimerMixin:UpdateLayout()
	if not self:ShouldHandleSwing() then
		return
	end

	if InCombatLockdown() and self:IsProtected() then
		self.needsRefresh = true
		return
	end

	local options = self.barOptions
	local anchor, _, anchorGroup = Utils.GetActiveAnchorFrame(options.anchorFrame)
	self.SCMActiveAnchorFrame = anchor
	self.SCMActiveAnchorGroup = anchorGroup

	local width = options.width
	if options.matchAnchorWidth and anchor then
		width = anchor:GetWidth()
		self:HookAnchorWidthRefresh(anchor)
	end
	width = math.max(options.minWidth, width)

	self:SetWidth(width)

	self:ClearAllPoints()
	self:SetPoint(options.point, anchor or UIParent, options.relativePoint, options.xOffset, options.yOffset)

	local duration = self.StatusBar.Duration
	duration:ClearAllPoints()
	duration:SetPoint("RIGHT", self.StatusBar, "RIGHT", options.durationTextXOffset, options.durationTextYOffset)

	local name = self.StatusBar.Name
	name:ClearAllPoints()
	name:SetPoint("LEFT", self.StatusBar, "LEFT", options.nameTextXOffset, options.nameTextYOffset)
	name:SetPoint("RIGHT", self.StatusBar, "RIGHT", options.nameTextXOffset, options.nameTextYOffset)
end

function SCMSwingTimerMixin:ApplyBorder()
	local options = self.barOptions
	local border = self.Border
	if not options.showBorder or options.backdropSize <= 0 then
		border:Hide()
		return
	end

	self.borderBackdrop = self.borderBackdrop or CopyTable(BACKDROP_SCM_PIXEL)
	self.borderBackdrop.edgeSize = options.backdropSize
	border:SetBackdrop(self.borderBackdrop)
	local color = options.backdropColor
	border:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
	border:Show()
end

function SCMSwingTimerMixin:ApplySpark()
	local options = self.barOptions
	local spark = self.StatusBar.Spark
	local sparkOptions = options.spark

	local texturePath = "Interface\\Buttons\\WHITE8x8"
	if sparkOptions.useCustomTexture and sparkOptions.texture ~= "" then
		local texture = sparkOptions.texture
		if texture:find("\\", 1, true) or texture:find("/", 1, true) then
			texturePath = texture
		else
			texturePath = LSM:Fetch("statusbar", texture)
		end
	end

	spark:SetTexture(texturePath)
	spark:SetSize(sparkOptions.width, sparkOptions.height)
	spark:SetBlendMode(sparkOptions.blendMode)

	local color = sparkOptions.color
	spark:SetVertexColor(color.r, color.g, color.b, color.a)
	spark:ClearAllPoints()
	spark:SetPoint("RIGHT", self.StatusBar:GetStatusBarTexture(), "RIGHT", sparkOptions.xOffset, sparkOptions.yOffset)

	self:UpdateSparkVisibility()
end

function SCMSwingTimerMixin:ApplyAppearance()
	local options = self.barOptions

	self:SetFrameStrata(options.frameStrata)
	self:SetFrameLevel(options.frameLevel)

	self.interpolation = options.useSmoothPowerUpdates and Enum.StatusBarInterpolation.ExponentialEaseOut or Enum.StatusBarInterpolation.Immediate

	self.StatusBar:SetStatusBarTexture(LSM:Fetch("statusbar", options.texture))
	
	local foregroundColor = options.foregroundColor
	self.StatusBar:SetStatusBarColor(foregroundColor.r, foregroundColor.g, foregroundColor.b, foregroundColor.a)

	local background = self.Background
	local backgroundColor = options.backgroundColor
	background:SetTexture(LSM:Fetch("statusbar", options.backgroundTexture))
	background:SetVertexColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)

	self:ApplyBorder()

	local fontPath = LSM:Fetch("font", options.font)
	local outline = options.textOutline == "NONE" and "" or options.textOutline
	self.StatusBar.Name:SetFont(fontPath, options.nameFontSize, outline)
	self.StatusBar.Duration:SetFont(fontPath, options.durationFontSize, outline)
	self.StatusBar.Name:SetShown(options.showValues and options.showNameText)
	self.StatusBar.Duration:SetShown(options.showValues and options.showDurationText)

	self:ApplySpark()

	if self:HasSwingTimer() then
		self.StatusBar:SetTimerDuration(self.durationObject, self.interpolation, Enum.StatusBarTimerDirection.ElapsedTime)
	end
end

function SCMSwingTimerMixin:ApplyVisibility()
	local options = self.barOptions

	if InCombatLockdown() then
		self.needsRefresh = true
		return
	end

	local condition = SCM:GetVisibilityConditions(options)
	RegisterAttributeDriver(self, "state-visibility", condition)
	if condition == "show" then
		UnregisterAttributeDriver(self, "state-visibility")
	end
end

function SCMSwingTimerMixin:ApplyConfig(options)
	if InCombatLockdown() and self:IsProtected() then
		self.needsRefresh = true
		return
	end

	self.needsRefresh = nil
	self.barOptions = options

	if not self:ShouldHandleSwing() then
		if self:IsEventRegistered("PLAYER_SWING") then
			self:UpdateFrameState()
		end
		return
	end

	self:ApplyAppearance()
	self:UpdateLayout()
	self:ApplyVisibility()
	self:UpdateFrameState()
	self:ApplyRangePresentation()
end

function SCM:RefreshSwingTimerHeights()
	local eligibleCount = 0
	for _, timer in pairs(self.SwingTimers) do
		if timer.barOptions.heightMode == "combined" and timer:ShouldHandleSwing() then
			eligibleCount = eligibleCount + 1
		end
	end

	local combinedHeight = self.swingTimerConfig.combinedHeight / math.max(1, eligibleCount)
	for _, timer in pairs(self.SwingTimers) do
		if timer:ShouldHandleSwing() then
			local height = timer.barOptions.height
			if timer.barOptions.heightMode == "combined" then
				height = combinedHeight
			end
			timer:ApplyHeight(height)
		end
	end
end

function SCMSwingTimerMixin:ApplyFormatterSettings(options)
	self.durationFormatter.showIdleDuration = options.showIdleDuration
	self.durationFormatter:SetBreakpoints(options.durationBreakpoints)
end

function SCM:RefreshSwingTimerConfig()
	for swingType, timer in pairs(self.SwingTimers) do
		local options = self.swingTimerConfig[swingType]
		timer:ApplyFormatterSettings(options)
		timer:ApplyConfig(options)
	end
end
