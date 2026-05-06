local SCM = select(2, ...)
local LSM = LibStub("LibSharedMedia-3.0")

local Utils = SCM.Utils
local RESOURCE_BAR_FRAME_NAME = "SCM_ResourceBarContainer"
local MOUNTED_VISIBILITY_CONDITION = "[combat]show;[mounted][stance:3]hide;show"

local UNIT_POWER_SPELL_IDS = Constants.UnitPowerSpellIDs
local SPELL_ID_VOID_METAMORPHOSIS = UNIT_POWER_SPELL_IDS.VOID_METAMORPHOSIS_SPELL_ID or 1217607
local SPELL_ID_DARK_HEART = UNIT_POWER_SPELL_IDS.DARK_HEART_SPELL_ID or 1225789
local SPELL_ID_SILENCE_THE_WHISPERS = UNIT_POWER_SPELL_IDS.SILENCE_THE_WHISPERS_SPELL_ID or 1227702
local SPELL_ID_MAELSTROM_WEAPON = UNIT_POWER_SPELL_IDS.MAELSTROM_WEAPON or 344179
local SPELL_ID_TIP_OF_THE_SPEAR = 260286

local SCMConstants = SCM.Constants
local CHARGED_COMBO_POINT_COLOR = SCMConstants.ChargedComboPointColor
local DEFAULT_RESOURCE_BAR_ANCHOR = "ANCHOR:1"
local RESOURCE_BAR_RECONFIGURE_EVENTS = {
	PLAYER_ENTERING_WORLD = true,
	PLAYER_GAINS_VEHICLE_DATA = true,
	PLAYER_LOSES_VEHICLE_DATA = true,
	UNIT_DISPLAYPOWER = true,
	UPDATE_SHAPESHIFT_FORM = true,
	UNIT_MAXPOWER = true,
}

local function GetPowerColorByInfo(powerToken, powerType)
	local colorInfo = GetPowerBarColor(powerType)
	if colorInfo then
		return colorInfo
	end

	return SCMConstants.FallbackPowerColorByToken[powerToken]
end

local function GetPowerColor(powerToken, powerType, altR, altG, altB)
	local barOptions = SCM.db.profile.options.resourceBar
	local colorOverrides = barOptions and barOptions.powerTypeColorOverrides
	local powerTypeColorOverride = powerToken and colorOverrides and colorOverrides[powerToken]

	if powerTypeColorOverride then
		local color = powerTypeColorOverride.color
		return color.r, color.g, color.b
	end

	local colorInfo = GetPowerColorByInfo(powerToken, powerType)
	if colorInfo and colorInfo.r and colorInfo.g and colorInfo.b then
		return colorInfo.r, colorInfo.g, colorInfo.b
	end

	if altR and altG and altB then
		return altR, altG, altB
	end

	return 0.25, 0.55, 1.00
end

local function ShouldHideManaForCurrentRole(barOptions)
	local role = select(5, Utils.GetSpec())
	return barOptions.hideManaRoles[role]
end

local function UpdateResourceBarBackdropInfo(barOptions)
	if not barOptions.showBorder then
		return
	end

	local backdropSize = barOptions.backdropSize
	if not backdropSize or backdropSize <= 0 then
		return
	end

	local backdropInfo = CopyTable(BACKDROP_SCM_PIXEL)
	backdropInfo.edgeSize = backdropSize
	return backdropInfo
end

local function CalculateResourceBarInset(region)
	if region.barOptions and not region.barOptions.showBorder then
		return 0
	end

	local backdropSize = (region.barOptions and region.barOptions.backdropSize) or 0
	if backdropSize <= 0 then
		return 0
	end

	return backdropSize * 0.5
end

local function UpdateResourceBarBorder(bar, barOptions)
	if not bar or not bar.BorderFrame then
		return
	end

	local borderFrame = bar.BorderFrame
	borderFrame:SetFrameLevel(bar:GetFrameLevel() + 1)

	local backdropInfo = UpdateResourceBarBackdropInfo(barOptions)
	if not backdropInfo then
		borderFrame:SetBackdrop(nil)
		borderFrame:Hide()
		return
	end

	borderFrame:SetBackdrop(backdropInfo)
	borderFrame:ApplyBackdrop()

	local color = barOptions.backdropColor or {}
	local alpha = color.a == nil and 1 or color.a
	borderFrame:SetBackdropBorderColor(color.r or 0, color.g or 0, color.b or 0, alpha)
	borderFrame:Show()
end

local function SetRegionPoint(region, bar)
	local inset = CalculateResourceBarInset(bar)
	region:ClearAllPoints()
	region:SetPoint("TOPLEFT", bar, "TOPLEFT", inset, -inset)
	region:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -inset, inset)
	return inset
end

local function UpdateResourceBarBackgroundTexture(bar, barOptions)
	local backgroundTexture = bar.Background
	local backgroundTextureName = barOptions.useBackgroundTexture and (barOptions.backgroundTexture or barOptions.texture)
	if not backgroundTextureName then
		backgroundTexture:Hide()
		return
	end

	local backgroundColor = barOptions.backgroundColor
	backgroundTexture:SetVertexColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)

	backgroundTexture:SetTexture(LSM:Fetch("statusbar", backgroundTextureName))
	SetRegionPoint(backgroundTexture, bar)
	backgroundTexture:Show()
end

local function GetRuneValues()
	local fillValue = 0
	local readyRuneCount = 0
	local maxRuneCount = 0
	local runeChargeSegments = {}
	local currentTime = GetTime()

	for runeIndex = 1, 6 do
		local cooldownStartTime, cooldownDuration, runeReady = GetRuneCooldown(runeIndex)
		if runeReady ~= nil then
			maxRuneCount = maxRuneCount + 1
			if runeReady then
				fillValue = fillValue + 1
				readyRuneCount = readyRuneCount + 1
				runeChargeSegments[maxRuneCount] = {
					progress = 1,
					remaining = 0,
					index = runeIndex,
				}
			elseif cooldownStartTime and cooldownDuration and cooldownDuration > 0 then
				local elapsedSinceRechargeStart = currentTime - cooldownStartTime
				local chargeProgress = Clamp(elapsedSinceRechargeStart / cooldownDuration, 0, 1)

				local remaining = cooldownDuration - elapsedSinceRechargeStart
				if remaining < 0 then
					remaining = 0
				end

				runeChargeSegments[maxRuneCount] = {
					progress = chargeProgress,
					remaining = remaining,
					index = runeIndex,
				}
				fillValue = fillValue + chargeProgress
			else
				runeChargeSegments[maxRuneCount] = {
					progress = 0,
					remaining = math.huge,
					index = runeIndex,
				}
			end
		end
	end

	return fillValue, maxRuneCount, readyRuneCount, runeChargeSegments
end

local function GetSoulFragmentValues()
	local currentValue = 0
	local maxValue = 0

	if C_UnitAuras.GetPlayerAuraBySpellID(SPELL_ID_VOID_METAMORPHOSIS) then
		local auraData = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_ID_SILENCE_THE_WHISPERS)
		currentValue = auraData and auraData.applications or 0
		maxValue = GetCollapsingStarCost() or 0
	else
		local auraData = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_ID_DARK_HEART)
		currentValue = auraData and auraData.applications or 0
	end

	if maxValue <= 0 then
		maxValue = C_Spell.GetSpellMaxCumulativeAuraApplications(SPELL_ID_DARK_HEART) or 0
	end

	return currentValue, maxValue
end

local function GetEssenceValue()
	local currentValue = UnitPower("player", Enum.PowerType.Essence) or 0
	local maxValue = UnitPowerMax("player", Enum.PowerType.Essence) or 0
	local fillValue = currentValue

	if currentValue < maxValue then
		local partialValue = UnitPartialPower("player", Enum.PowerType.Essence) or 0
		local partialProgress = Clamp(partialValue / 1000, 0, 1)

		fillValue = fillValue + partialProgress
	end

	return fillValue, maxValue, currentValue
end

local function GetTipOfTheSpearValue()
	local currentValue = 0
	local maxValue = 3

	local auraData = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_ID_TIP_OF_THE_SPEAR)
	if auraData then
		currentValue = auraData.applications or 0
	end

	return currentValue, maxValue
end

local function GetMaelstromWeaponValue()
	local currentValue = 0
	local maxValue = 10

	local auraData = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_ID_MAELSTROM_WEAPON)
	if auraData then
		currentValue = auraData.applications or 0
	end

	return currentValue, maxValue
end

local function GetCurrentPowerValue(resourceKind, powerType)
	if resourceKind == "runes" then
		return GetRuneValues()
	end

	if powerType == Enum.PowerType.Essence then
		return GetEssenceValue()
	end

	if resourceKind == "stagger" then
		local currentValue = UnitStagger("player") or 0
		local maxValue = UnitHealthMax("player") or 0
		return currentValue, maxValue
	end

	if resourceKind == "maelstromWeapon" then
		return GetMaelstromWeaponValue()
	end

	if resourceKind == "soulFragments" then
		local currentValue, maxValue = GetSoulFragmentValues()
		return currentValue, maxValue
	end

	if resourceKind == "destructionSoulShards" then
		local currentRawValue = UnitPower("player", Enum.PowerType.SoulShards, true)
		local maxRawValue = UnitPowerMax("player", Enum.PowerType.SoulShards, true)
		local currentValue = currentRawValue / 10
		local maxValue = maxRawValue / 10
		return currentValue, maxValue
	end

	if resourceKind == "tipOfTheSpear" then
		return GetTipOfTheSpearValue()
	end

	local currentValue = UnitPower("player", powerType)
	local maxValue = UnitPowerMax("player", powerType)
	return currentValue, maxValue
end

local function UpdateStaggerBarColor(bar, currentValue, maxValue)
	local staggerPercent = maxValue > 0 and currentValue / maxValue or 0
	if staggerPercent >= 0.60 then
		bar:SetStatusBarColor(1.00, 0.42, 0.42)
	elseif staggerPercent >= 0.30 then
		bar:SetStatusBarColor(1.00, 0.98, 0.72)
	else
		bar:SetStatusBarColor(0.52, 1.00, 0.52)
	end
end

local function HideRegions(regionList)
	if not regionList then
		return
	end

	for _, region in ipairs(regionList) do
		region:Hide()
	end
end

local function GetNumSegments(bar, maxValue)
	local segmentCount = bar.segmentCount or maxValue
	if not segmentCount or segmentCount <= 0 then
		return
	end

	return max(1, segmentCount)
end

local function UpdateBarTextPosition(bar, barOptions)
	local text = bar.Text.Value
	if not text then
		return
	end

	local anchorRegion = bar.Text or bar
	text:ClearAllPoints()
	text:SetPoint("CENTER", anchorRegion, "CENTER", barOptions.textXOffset, barOptions.textYOffset)
end

local function ResetResourceBar(bar)
	bar.resourceKind = nil
	bar.powerType = nil
	bar.powerToken = nil
	bar.segmentCount = nil
	bar.SCMRegisterUnitAura = nil
	bar.Text.Value:SetText("")

	HideRegions(bar.SegmentTicks)
	HideRegions(bar.SegmentFillBars)
	HideRegions(bar.RuneSegmentBars)

	bar.SCMSegmentedDisplay = nil
	bar.SCMConfiguredSegmentCount = nil

	bar:GetStatusBarTexture():SetAlpha(1)

	bar:Hide()
end

local function ConfigureBarForResource(bar, resource, altR, altG, altB)
	local resourceKind = resource.resourceKind or "power"
	local powerType = resource.powerType
	local powerToken = resource.powerToken
	local registerUnitAura = resource.registerUnitAura
	local segmentCount = resource.segmentCount

	if bar.SCMUseSegmentedSecondaryDisplay and powerType == Enum.PowerType.Mana then
		segmentCount = nil
	elseif resourceKind == "maelstromWeapon" and bar.barOptions and bar.barOptions.disableMaelstromOverflow then
		segmentCount = 10
	end

	local resourceChanged = bar.resourceKind ~= resourceKind
		or bar.powerType ~= powerType
		or bar.powerToken ~= powerToken
		or bar.SCMRegisterUnitAura ~= registerUnitAura
		or bar.SCMConfiguredSegmentCount ~= segmentCount

	bar.resourceKind = resourceKind
	bar.powerType = powerType
	bar.powerToken = powerToken
	bar.segmentCount = segmentCount
	bar.SCMConfiguredSegmentCount = segmentCount
	bar.SCMRegisterUnitAura = registerUnitAura

	local overrideColor = bar.SCMIsPrimaryResourceBar and SCM.primaryResourceBarColorOverride
	local r, g, b
	if overrideColor then
		r, g, b = overrideColor.r, overrideColor.g, overrideColor.b
	else
		r, g, b = GetPowerColor(bar.powerToken, bar.powerType, altR, altG, altB)
	end
	bar:SetStatusBarColor(r, g, b)
	bar:Show()

	return resourceChanged
end

local function CreateTicks(bar, tickCount, tickColor)
	bar.SegmentTicks = bar.SegmentTicks or {}

	for tickIndex = #bar.SegmentTicks + 1, tickCount do
		local tick = bar.SegmentTicks[tickIndex] or bar:CreateTexture(nil, "OVERLAY")
		tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a)
		bar.SegmentTicks[tickIndex] = tick
	end

	return bar.SegmentTicks
end

local function UpdateTicks(bar, maxValue)
	local barOptions = bar.barOptions
	local segmentCount = GetNumSegments(bar, maxValue)
	local hasConfiguredSegments = bar.segmentCount and bar.segmentCount > 1
	local hasPowerTokenSegments = bar.powerToken and SCMConstants.SegmentTicksByPowerToken[bar.powerToken]
	local hasSegmentTicks = hasConfiguredSegments or hasPowerTokenSegments

	if not barOptions or not barOptions.showTicks or not hasSegmentTicks or type(segmentCount) ~= "number" or segmentCount <= 1 then
		HideRegions(bar.SegmentTicks)
		return
	end

	local tickWidth = barOptions.tickWidth
	if not tickWidth or tickWidth <= 0 then
		HideRegions(bar.SegmentTicks)
		return
	end

	local tickCount = segmentCount - 1
	local tickColor = barOptions.tickColor
	local tickTextures = CreateTicks(bar, tickCount, tickColor)
	local barHeight = bar:GetHeight()
	local offset = bar:GetWidth() / segmentCount

	for tickIndex = 1, tickCount do
		local tick = tickTextures[tickIndex]
		tick:ClearAllPoints()
		tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a)
		tick:SetPoint("LEFT", tickIndex * offset, 0)
		tick:SetWidth(tickWidth)
		tick:SetHeight(barHeight)
		tick:Show()
	end

	for tickIndex = tickCount + 1, #tickTextures do
		tickTextures[tickIndex]:Hide()
	end
end

local function RefreshBarTicks(bar, maxValue)
	if not bar.powerToken or not bar:IsShown() then
		return
	end

	if maxValue == nil then
		local _, currentMaxValue = GetCurrentPowerValue(bar.resourceKind, bar.powerType)
		maxValue = currentMaxValue
	end

	UpdateTicks(bar, maxValue)
end

local function GetChargedSegmentMap(bar, segmentCount, currentValue)
	local isRogueComboPointResource = bar.powerType == Enum.PowerType.ComboPoints and Utils.GetClass() == "ROGUE"
	if isRogueComboPointResource then
		local chargedComboPoints = GetUnitChargedPowerPoints("player")
		if not chargedComboPoints or #chargedComboPoints == 0 then
			return
		end

		local chargedSegmentMap = {}
		for _, pointIndex in ipairs(chargedComboPoints) do
			chargedSegmentMap[pointIndex] = true
		end

		return chargedSegmentMap
	end

	local isMaelstromWeaponResource = bar.resourceKind == "maelstromWeapon"
	local hasNumericSegmentValues = type(segmentCount) == "number" and type(currentValue) == "number"
	if not isMaelstromWeaponResource or not hasNumericSegmentValues then
		return
	end

	local overflowCount = floor(currentValue - segmentCount)
	if overflowCount <= 0 then
		return
	end
	if overflowCount > segmentCount then
		overflowCount = segmentCount
	end

	local chargedSegmentMap = {}
	for segmentIndex = 1, overflowCount do
		chargedSegmentMap[segmentIndex] = true
	end

	return chargedSegmentMap
end

local function HasSegments(bar, segmentCount)
	local hasSegments = type(segmentCount) == "number" and segmentCount > 1
	if not bar.SCMUseSegmentedSecondaryDisplay or not hasSegments then
		return
	end

	local hasConfiguredSegments = bar.segmentCount and bar.segmentCount > 1
	if hasConfiguredSegments then
		return true
	end

	return bar.powerToken and SCMConstants.SegmentTicksByPowerToken[bar.powerToken]
end

local function CreateSegments(bar, segmentCount)
	bar.SegmentFillBars = bar.SegmentFillBars or {}
	local texturePath = bar.SCMTexturePath or LSM:Fetch("statusbar", bar.barOptions.texture)

	for segmentIndex = #bar.SegmentFillBars + 1, segmentCount do
		local segmentBar = bar.SegmentFillBars[segmentIndex] or CreateFrame("StatusBar", nil, bar)
		segmentBar:SetMinMaxValues(0, 1)
		segmentBar:SetStatusBarTexture(texturePath)
		segmentBar:SetFrameLevel(2)
		bar.SegmentFillBars[segmentIndex] = segmentBar
	end

	return bar.SegmentFillBars
end

local function GetProgressValues(bar, segmentCount, currentValue, resourceSegmentValues)
	local segmentProgressValues = {}

	if bar.resourceKind == "runes" then
		local orderedRuneSegments = {}
		for runeIndex = 1, segmentCount do
			orderedRuneSegments[runeIndex] = resourceSegmentValues[runeIndex] or {
				progress = 0,
				remaining = math.huge,
				index = runeIndex,
			}
		end

		table.sort(orderedRuneSegments, function(leftRune, rightRune)
			if leftRune.remaining == rightRune.remaining then
				return leftRune.index < rightRune.index
			end

			return leftRune.remaining < rightRune.remaining
		end)

		for segmentIndex = 1, segmentCount do
			local runeSegment = orderedRuneSegments[segmentIndex]
			segmentProgressValues[segmentIndex] = (runeSegment and runeSegment.progress) or 0
		end

		return segmentProgressValues
	end

	if bar.powerType == Enum.PowerType.Essence then
		for segmentIndex = 1, segmentCount do
			segmentProgressValues[segmentIndex] = Clamp(currentValue - (segmentIndex - 1), 0, 1)
		end

		return segmentProgressValues
	end

	for segmentIndex = 1, segmentCount do
		segmentProgressValues[segmentIndex] = (currentValue >= segmentIndex and 1 or 0)
	end

	return segmentProgressValues
end

local function UpdateSegments(bar, maxValue, currentValue, resourceSegmentValues)
	local segmentCount = GetNumSegments(bar, maxValue)
	if not HasSegments(bar, segmentCount) then
		bar.SCMSegmentedDisplay = nil
		HideRegions(bar.SegmentFillBars)
		HideRegions(bar.RuneSegmentBars)
		bar:GetStatusBarTexture():SetAlpha(1)
		return
	end

	bar.SCMSegmentedDisplay = true
	bar.segmentCount = segmentCount
	bar:GetStatusBarTexture():SetAlpha(0)
	HideRegions(bar.RuneSegmentBars)

	local barOptions = bar.barOptions
	local segmentBars = CreateSegments(bar, segmentCount)
	local texturePath = bar.SCMTexturePath or LSM:Fetch("statusbar", barOptions.texture)
	local r, g, b = GetPowerColor(bar.powerToken, bar.powerType)
	local overflowR, overflowG, overflowB = CHARGED_COMBO_POINT_COLOR.r, CHARGED_COMBO_POINT_COLOR.g, CHARGED_COMBO_POINT_COLOR.b

	if bar.resourceKind == "maelstromWeapon" then
		local overflowColor = SCM.db.profile.options.resourceBar.maelstromOverflowColor
		if overflowColor and overflowColor.r and overflowColor.g and overflowColor.b then
			overflowR, overflowG, overflowB = overflowColor.r, overflowColor.g, overflowColor.b
		end
	end

	local chargedSegments = GetChargedSegmentMap(bar, segmentCount, currentValue)
	local segmentProgressValues = GetProgressValues(bar, segmentCount, currentValue, resourceSegmentValues)
	local segmentWidth = bar:GetWidth() / segmentCount
	local segmentHeight = bar:GetHeight()
	local borderSize = 0
	if barOptions.showBorder then
		borderSize = (barOptions.backdropSize or 0) * 2
	end

	for segmentIndex = 1, segmentCount do
		local segmentBar = segmentBars[segmentIndex]
		segmentBar:ClearAllPoints()
		segmentBar:SetStatusBarTexture(texturePath)
		segmentBar:SetPoint("LEFT", (segmentIndex - 1) * segmentWidth, 0)
		segmentBar:SetWidth(segmentWidth)
		segmentBar:SetHeight(segmentHeight - borderSize)

		local segmentR, segmentG, segmentB = r, g, b
		if chargedSegments and chargedSegments[segmentIndex] then
			if bar.resourceKind == "maelstromWeapon" then
				segmentR, segmentG, segmentB = overflowR, overflowG, overflowB
			else
				segmentR, segmentG, segmentB = CHARGED_COMBO_POINT_COLOR.r, CHARGED_COMBO_POINT_COLOR.g, CHARGED_COMBO_POINT_COLOR.b
			end
		end

		segmentBar:SetStatusBarColor(segmentR, segmentG, segmentB)
		segmentBar:SetValue(segmentProgressValues[segmentIndex] or 0)
		segmentBar:Show()
	end

	for segmentIndex = segmentCount + 1, #segmentBars do
		segmentBars[segmentIndex]:Hide()
	end
end

local function ApplyBarAppearance(bar, barOptions)
	if not bar then
		return
	end

	bar.barOptions = barOptions

	local texturePath = LSM:Fetch("statusbar", barOptions.texture)
	bar.SCMTexturePath = texturePath
	bar:SetStatusBarTexture(texturePath)

	if bar.SegmentFillBars then
		for _, segmentBar in ipairs(bar.SegmentFillBars) do
			segmentBar:SetStatusBarTexture(texturePath)
		end
	end

	local statusBarTexture = bar:GetStatusBarTexture()
	SetRegionPoint(statusBarTexture, bar)
	UpdateResourceBarBackgroundTexture(bar, barOptions)

	local text = bar.Text
	local fontPath = LSM:Fetch("font", barOptions.font)
	local fontFlags = barOptions.textOutline

	if not fontFlags or fontFlags == "NONE" then
		fontFlags = ""
	end

	text.Value:SetFont(fontPath, barOptions.fontSize, fontFlags)
	text.Value:SetShadowColor(0, 0, 0, 0)
	UpdateBarTextPosition(bar, barOptions)
	text:SetShown(barOptions.showValues)

	if bar.BorderFrame then
		UpdateResourceBarBorder(bar, barOptions)
	end

	if bar.Text then
		bar.Text:SetFrameStrata(bar:GetFrameStrata())
		bar.Text:SetFrameLevel(bar:GetFrameLevel() + 2)
	end
end

local function InitializeBarSkin(bar)
	if not bar or bar.SCMStyled then
		return
	end

	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar.Text.Value:SetTextColor(1, 1, 1, 1)
	bar:SetBackdrop(nil)

	if not bar.BorderFrame then
		bar.BorderFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	end

	bar.BorderFrame:ClearAllPoints()
	bar.BorderFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	bar.BorderFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

	local barOptions = bar.barOptions or SCM.db.profile.options.resourceBar
	UpdateResourceBarBorder(bar, barOptions)
	bar.SCMStyled = true
end

local function BarNeedsContinuousRefresh(bar)
	if not bar.powerToken or not bar:IsShown() then
		return
	end

	if bar.resourceKind == "runes" then
		local _, maxValue, displayValue = GetRuneValues()
		local hasRuneValues = type(displayValue) == "number" and type(maxValue) == "number"
		return hasRuneValues and displayValue < maxValue
	end

	if bar.powerType == Enum.PowerType.Essence then
		local currentValue = UnitPower("player", Enum.PowerType.Essence) or 0
		local maxValue = UnitPowerMax("player", Enum.PowerType.Essence) or 0
		return currentValue < maxValue
	end
end

local function RegisterBarEvents(bar, barOptions)
	bar:UnregisterAllEvents()

	if not bar.powerToken then
		return
	end

	if bar.SCMRegisterUnitAura then
		bar:RegisterUnitEvent("UNIT_AURA", "player")
		return
	end

	if bar.resourceKind == "runes" then
		bar:RegisterEvent("RUNE_POWER_UPDATE")
		return
	end

	local powerUpdateEvent = barOptions.useFrequentPowerUpdates and "UNIT_POWER_FREQUENT" or "UNIT_POWER_UPDATE"
	bar:RegisterUnitEvent(powerUpdateEvent, "player")

	if bar.powerType ~= nil then
		bar:RegisterUnitEvent("UNIT_MAXPOWER", "player")
	end

	if bar.powerType == Enum.PowerType.ComboPoints then
		bar:RegisterUnitEvent("UNIT_POWER_POINT_CHARGE", "player")
	end
end

local function OnResourceBarEvent(bar, event)
	local controller = bar and bar.Controller
	if not controller then
		return
	end

	local maxValue = controller:RefreshBarDisplay(bar)
	local primaryHeightChanged, secondaryHeightChanged = controller:UpdateBarLayout()
	local isPrimaryBar = bar == controller.PrimaryBar
	local isSecondaryBar = bar == controller.SecondaryBar
	local heightChanged = (isPrimaryBar and primaryHeightChanged) or (isSecondaryBar and secondaryHeightChanged)

	if event == "UNIT_MAXPOWER" or heightChanged then
		RefreshBarTicks(bar, maxValue)
	end

	controller:UpdateContainerShownState()
	controller:UpdateRefreshState()
end

local SCMResourceBarControllerMixin = {}
function SCM:ApplyResourceBarHideWhileMountedSettings(value)
	local container = _G[RESOURCE_BAR_FRAME_NAME]
	if not container or InCombatLockdown() then
		return
	end

	if value then
		RegisterAttributeDriver(container, "state-visibility", MOUNTED_VISIBILITY_CONDITION)
		return
	end

	UnregisterAttributeDriver(container, "state-visibility")
	if container.SCMResourceBarInitialized and container.UpdateContainerShownState then
		container:UpdateContainerShownState()
	end
end

local function SetBarHeight(bar, height)
	local previousHeight = bar:GetHeight() or 0
	bar:SetHeight(height)

	return previousHeight ~= (bar:GetHeight() or 0)
end

function SCMResourceBarControllerMixin:ApplyResourceBarOptions()
	local barOptions = SCM.db.profile.options.resourceBar
	self.barOptions = barOptions
	self.primaryBarOptions = barOptions.primaryBar
	self.secondaryBarOptions = barOptions.secondaryBar

	ApplyBarAppearance(self.PrimaryBar, self.primaryBarOptions)
	ApplyBarAppearance(self.SecondaryBar, self.secondaryBarOptions)

	return barOptions
end

function SCMResourceBarControllerMixin:ApplyFrameWidthOptions(bar)
	if InCombatLockdown() then
		return false
	end

	local specificBarOptions = bar.barOptions
	local generalBarOptions = self.barOptions
	local anchor = generalBarOptions.anchorFrame or DEFAULT_RESOURCE_BAR_ANCHOR
	if type(anchor) == "string" then
		anchor = SCM.Utils.GetAnchorFrame(anchor)
	end

	if anchor then
		local widthFromOptions = specificBarOptions.width
		if specificBarOptions.matchAnchorWidth then
			widthFromOptions = anchor:GetWidth() or 0
		end

		local desiredWidth = max(generalBarOptions.minWidth, widthFromOptions)
		local previousWidth = bar:GetWidth() or 0
		bar:SetWidth(desiredWidth)
		local widthChanged = previousWidth ~= (bar:GetWidth() or 0)

		if not bar.SCMResourceBarHook then
			bar.SCMResourceBarHook = true
			anchor:HookScript("OnSizeChanged", function()
				if not InCombatLockdown() and specificBarOptions.matchAnchorWidth then
					SCM:RefreshResourceBarConfig()
				end
			end)
		end

		self:ClearAllPoints()
		self:SetPoint(generalBarOptions.point, anchor, generalBarOptions.relativePoint, generalBarOptions.xOffset, generalBarOptions.yOffset)

		return widthChanged
	end

	return false
end

function SCMResourceBarControllerMixin:UpdateRefreshState()
	local needsContinuousRefresh = BarNeedsContinuousRefresh(self.PrimaryBar) or BarNeedsContinuousRefresh(self.SecondaryBar)
	if not needsContinuousRefresh then
		self:SetScript("OnUpdate", nil)
		self.totalElapsed = nil
		return
	end

	if not self:GetScript("OnUpdate") then
		self:SetScript("OnUpdate", self.OnUpdate)
	end
end

function SCMResourceBarControllerMixin:OnUpdate(elapsed)
	self.totalElapsed = (self.totalElapsed or 0) + elapsed
	if self.totalElapsed < (SCMConstants.RefreshInterval or 0.05) then
		return
	end

	self.totalElapsed = 0
	self:RefreshBarDisplay(self.PrimaryBar)
	self:RefreshBarDisplay(self.SecondaryBar)
	self:UpdateRefreshState()
end

function SCMResourceBarControllerMixin:RefreshResourceBars(refreshTicks)
	local barOptions = self:ApplyResourceBarOptions()
	local primaryBarOptions = barOptions.primaryBar
	local secondaryBarOptions = barOptions.secondaryBar

	if not barOptions.enabled then
		SCM:ApplyResourceBarHideWhileMountedSettings(false)
		self:UnregisterAllEvents()
		self.SCMResourceBarEventsRegistered = false
		self.PrimaryBar:UnregisterAllEvents()
		self.SecondaryBar:UnregisterAllEvents()
		self:SetScript("OnUpdate", nil)
		self.totalElapsed = nil
		ResetResourceBar(self.PrimaryBar)
		ResetResourceBar(self.SecondaryBar)
		self:UpdateContainerShownState()
		return
	end

	local primaryResourceChanged = false
	local secondaryResourceChanged = false

	if primaryBarOptions.enabled then
		primaryResourceChanged = self:ConfigurePrimaryBar()
		RegisterBarEvents(self.PrimaryBar, barOptions)
	else
		self.PrimaryBar:UnregisterAllEvents()
		ResetResourceBar(self.PrimaryBar)
	end

	if secondaryBarOptions.enabled then
		secondaryResourceChanged = self:ConfigureSecondaryBar()
		RegisterBarEvents(self.SecondaryBar, barOptions)
	else
		self.SecondaryBar:UnregisterAllEvents()
		ResetResourceBar(self.SecondaryBar)
	end

	if primaryBarOptions.enabled or secondaryBarOptions.enabled then
		self:RegisterResourceBarEvents()

		local primaryWidthChanged = false
		local secondaryWidthChanged = false
		if primaryBarOptions.enabled then
			primaryWidthChanged = self:ApplyFrameWidthOptions(self.PrimaryBar)
		end
		if secondaryBarOptions.enabled then
			secondaryWidthChanged = self:ApplyFrameWidthOptions(self.SecondaryBar)
		end

		local primaryHeightChanged, secondaryHeightChanged = self:UpdateBarLayout()
		local refreshPrimaryTicks = refreshTicks or primaryResourceChanged or primaryWidthChanged or primaryHeightChanged
		local refreshSecondaryTicks = refreshTicks or secondaryResourceChanged or secondaryWidthChanged or secondaryHeightChanged

		self:RefreshBarDisplay(self.PrimaryBar, refreshPrimaryTicks, true)
		self:RefreshBarDisplay(self.SecondaryBar, refreshSecondaryTicks, true)
		self:UpdateContainerShownState()
		self:UpdateRefreshState()

		EventRegistry:TriggerEvent("SkironCooldownManager.ResourceBar.LayoutUpdated")
	end

	SCM:ApplyResourceBarHideWhileMountedSettings(barOptions.hideWhileMounted)
end

function SCMResourceBarControllerMixin:ConfigurePrimaryBar()
	local powerType, powerToken, altR, altG, altB = UnitPowerType("player")
	if not powerType or not powerToken then
		ResetResourceBar(self.PrimaryBar)
		return false
	end

	if powerType == Enum.PowerType.Mana and ShouldHideManaForCurrentRole(self.primaryBarOptions) then
		ResetResourceBar(self.PrimaryBar)
		return false
	end

	return ConfigureBarForResource(self.PrimaryBar, {
		powerType = powerType,
		powerToken = powerToken,
	}, altR, altG, altB)
end

function SCMResourceBarControllerMixin:ConfigureSecondaryBar()
	local primaryPowerType = UnitPowerType("player")
	local secondaryResource

	if not UnitInVehicle("player") then
		local className = Utils.GetClass()
		local specializationID = Utils.GetSpec()

		secondaryResource = SCMConstants.SpecSecondaryPower[specializationID] or SCMConstants.ClassSecondaryPower[className]
		local requiredPrimaryPowerType = secondaryResource and secondaryResource.showWhenPrimaryPowerType
		if requiredPrimaryPowerType and primaryPowerType ~= requiredPrimaryPowerType then
			secondaryResource = nil
		end

		if not secondaryResource and SCMConstants.ClassManaSecondaryPower[className] then
			secondaryResource = SCMConstants.ClassManaSecondaryPower[className][primaryPowerType]
		end
	end

	if secondaryResource and secondaryResource.powerType == primaryPowerType then
		secondaryResource = nil
	end

	if secondaryResource and secondaryResource.powerType == Enum.PowerType.Mana and ShouldHideManaForCurrentRole(self.secondaryBarOptions) then
		secondaryResource = nil
	end

	if not secondaryResource then
		ResetResourceBar(self.SecondaryBar)
		return false
	end

	return ConfigureBarForResource(self.SecondaryBar, secondaryResource)
end

function SCMResourceBarControllerMixin:RefreshBarDisplay(bar, refreshTicks, skipWidthOptions)
	if not bar.powerToken then
		return
	end

	local currentValue, maxValue, displayValue, resourceSegmentValues = GetCurrentPowerValue(bar.resourceKind, bar.powerType)
	if not (currentValue and maxValue) then
		UpdateSegments(bar)
		if refreshTicks then
			RefreshBarTicks(bar)
		end
		bar:Hide()
		return
	end

	displayValue = displayValue == nil and currentValue or displayValue
	bar:SetMinMaxValues(0, maxValue)
	bar:SetValue(currentValue)
	local widthChanged = not skipWidthOptions and self:ApplyFrameWidthOptions(bar)
	UpdateSegments(bar, maxValue, currentValue, resourceSegmentValues)
	bar:Show()
	if refreshTicks or widthChanged then
		RefreshBarTicks(bar, maxValue)
	end

	local overrideColor = bar.SCMIsPrimaryResourceBar and SCM.primaryResourceBarColorOverride
	if overrideColor then
		bar:SetStatusBarColor(overrideColor.r, overrideColor.g, overrideColor.b)
	elseif bar.resourceKind == "stagger" then
		local colorOverrides = SCM.db.profile.options.resourceBar.powerTypeColorOverrides
		local hasColorOverride = colorOverrides[bar.powerToken]
		if not hasColorOverride then
			UpdateStaggerBarColor(bar, currentValue, maxValue)
		end
	end

	local text = bar.Text
	if not text then
		return maxValue
	end

	local textValue = text.Value
	local overrideText = bar.SCMIsPrimaryResourceBar and SCM.primaryResourceBarTextOverride
	if overrideText ~= nil then
		textValue:SetText(overrideText)
		return maxValue
	end

	if not displayValue then
		textValue:SetText("")
		return maxValue
	end

	if bar.powerType == Enum.PowerType.Mana then
		local manaPercent = UnitPowerPercent("player", bar.powerType, false, CurveConstants.ScaleTo100)
		textValue:SetText(string.format("%d%%", manaPercent))
	else
		textValue:SetText(AbbreviateLargeNumbers(displayValue))
	end

	return maxValue
end

function SCMResourceBarControllerMixin:UpdateBarLayout()
	local barOptions = self.barOptions
	local primaryBarOptions = self.primaryBarOptions
	local secondaryBarOptions = self.secondaryBarOptions
	local primaryShown = self.PrimaryBar:IsShown()
	local secondaryShown = self.SecondaryBar:IsShown()
	local bothShown = primaryShown and secondaryShown
	local primaryHeight = 0
	local secondaryHeight = 0

	if primaryBarOptions then
		primaryHeight = bothShown and primaryBarOptions.heightAlternative or primaryBarOptions.height
	end

	if secondaryBarOptions then
		secondaryHeight = bothShown and secondaryBarOptions.heightAlternative or secondaryBarOptions.height
	end

	local spacing = barOptions.spacing
	local growsUp = barOptions.growDirection == "UP"

	local primaryHeightChanged = false
	local secondaryHeightChanged = false

	self.SecondaryBar:ClearAllPoints()
	self.PrimaryBar:ClearAllPoints()

	if primaryShown then
		primaryHeightChanged = SetBarHeight(self.PrimaryBar, primaryHeight)
		self.PrimaryBar:SetPoint("BOTTOM", self, "BOTTOM")
	end

	if secondaryShown then
		secondaryHeightChanged = SetBarHeight(self.SecondaryBar, secondaryHeight)
		if primaryShown then
			if growsUp then
				self.SecondaryBar:SetPoint("BOTTOM", self.PrimaryBar, "TOP", 0, spacing)
			else
				self.SecondaryBar:SetPoint("TOP", self.PrimaryBar, "BOTTOM", 0, -spacing)
			end
		else
			self.SecondaryBar:SetPoint("BOTTOM", self, "BOTTOM")
		end
	end

	if primaryShown and secondaryShown then
		self:SetHeight(primaryHeight + secondaryHeight + spacing)
	elseif primaryShown or secondaryShown then
		self:SetHeight(primaryShown and primaryHeight or secondaryHeight)
	else
		self:SetHeight(0)
	end

	return primaryHeightChanged, secondaryHeightChanged
end

function SCMResourceBarControllerMixin:UpdateContainerShownState()
	local barOptions = self.barOptions
	if not barOptions.enabled then
		self:Hide()
		return
	end

	if barOptions.hideWhileMounted and self:GetAttribute("statehidden") then
		return
	end

	self:SetShown(self.PrimaryBar:IsShown() or self.SecondaryBar:IsShown())
end

function SCMResourceBarControllerMixin:OnAttributeChanged(name, value)
	if name ~= "statehidden" or value then
		return
	end

	self:UpdateContainerShownState()
end

function SCMResourceBarControllerMixin:OnEvent(event)
	if RESOURCE_BAR_RECONFIGURE_EVENTS[event] then
		self:RefreshResourceBars(event == "UNIT_MAXPOWER")
	end
end

function SCMResourceBarControllerMixin:RegisterResourceBarEvents()
	if self.SCMResourceBarEventsRegistered then
		return
	end

	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
	self:RegisterUnitEvent("UNIT_MAXPOWER", "player")
	self:RegisterEvent("PLAYER_GAINS_VEHICLE_DATA")
	self:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA")
	self.SCMResourceBarEventsRegistered = true
end

function SCMResourceBarControllerMixin:Initialize()
	InitializeBarSkin(self.PrimaryBar)
	InitializeBarSkin(self.SecondaryBar)
	self.PrimaryBar.SCMIsPrimaryResourceBar = true
	self.SecondaryBar.SCMIsPrimaryResourceBar = nil
	self.PrimaryBar.SCMUseSegmentedSecondaryDisplay = false
	self.SecondaryBar.SCMUseSegmentedSecondaryDisplay = true
	self.PrimaryBar.Controller = self
	self.SecondaryBar.Controller = self
	self.PrimaryBar:SetScript("OnEvent", OnResourceBarEvent)
	self.SecondaryBar:SetScript("OnEvent", OnResourceBarEvent)

	self:SetScript("OnAttributeChanged", self.OnAttributeChanged)
	self:SetScript("OnEvent", self.OnEvent)
	self:RegisterResourceBarEvents()

	self:RefreshResourceBars(true)
end

function SCM:InitializeResourceBars()
	local container = _G[RESOURCE_BAR_FRAME_NAME]
	local barOptions = self.db.profile.options.resourceBar
	if not container or container.SCMResourceBarInitialized or not barOptions.enabled then
		return
	end

	local primaryBar = _G["SCM_PrimaryResourceBar"]
	local secondaryBar = _G["SCM_SecondaryResourceBar"]

	container.SCMResourceBarInitialized = true
	container.PrimaryBar = primaryBar
	container.SecondaryBar = secondaryBar
	Mixin(container, SCMResourceBarControllerMixin)
	container:Initialize()
end

function SCM:RefreshResourceBarConfig(refreshTicks)
	local container = _G[RESOURCE_BAR_FRAME_NAME]
	if not container then
		return
	end

	if not container.SCMResourceBarInitialized then
		self:InitializeResourceBars()
		container = _G[RESOURCE_BAR_FRAME_NAME]
		if not container or not container.SCMResourceBarInitialized then
			return
		end
	end

	container:RefreshResourceBars(refreshTicks)
end

function SCM:SetPrimaryResourceBarColorOverride(r, g, b)
	self.primaryResourceBarColorOverride = {
		r = r,
		g = g,
		b = b,
	}

	self:RefreshResourceBarConfig()
	return true
end

function SCM:ClearPrimaryResourceBarColorOverride()
	if not self.primaryResourceBarColorOverride then
		return
	end

	self.primaryResourceBarColorOverride = nil
	self:RefreshResourceBarConfig()
	return true
end

function SCM:SetPrimaryResourceBarTextOverride(text)
	if not text then
		return
	end

	self.primaryResourceBarTextOverride = tostring(text)
	self:RefreshResourceBarConfig()
	return true
end

function SCM:ClearPrimaryResourceBarTextOverride()
	if not self.primaryResourceBarTextOverride then
		return
	end

	self.primaryResourceBarTextOverride = nil
	self:RefreshResourceBarConfig()
	return true
end
