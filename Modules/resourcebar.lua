local SCM = select(2, ...)
local LSM = LibStub("LibSharedMedia-3.0")

local Utils = SCM.Utils
local RESOURCE_BAR_FRAME_NAME = "SCM_ResourceBarContainer"
local ANCHOR_PROXY_SIZE_CHANGED_EVENT = "SkironCooldownManager.AnchorProxy.SizeChanged"

local UNIT_POWER_SPELL_IDS = Constants.UnitPowerSpellIDs
local SPELL_ID_VOID_METAMORPHOSIS = UNIT_POWER_SPELL_IDS.VOID_METAMORPHOSIS_SPELL_ID or 1217607
local SPELL_ID_DARK_HEART = UNIT_POWER_SPELL_IDS.DARK_HEART_SPELL_ID or 1225789
local SPELL_ID_SILENCE_THE_WHISPERS = UNIT_POWER_SPELL_IDS.SILENCE_THE_WHISPERS_SPELL_ID or 1227702
local SPELL_ID_MAELSTROM_WEAPON = UNIT_POWER_SPELL_IDS.MAELSTROM_WEAPON or 344179
local SPELL_ID_SOUL_FRAGMENTS = 228477
local SPELL_ID_TIP_OF_THE_SPEAR = 260286
local SPELL_ID_ICICLES = 205473

local SCMConstants = SCM.Constants
local CHARGED_COMBO_POINT_COLOR = SCMConstants.ChargedComboPointColor
local DEFAULT_RESOURCE_BAR_ANCHOR = "ANCHOR:1"
local RESOURCE_BAR_RECONFIGURE_EVENTS = {
	PLAYER_ENTERING_WORLD = true,
	PLAYER_SPECIALIZATION_CHANGED = true,
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
	local barOptions = SCM.resourceBarConfig
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
	if UnitClassBase("player") == "MAGE" and Utils.GetSpec() == 62 then
		return false
	end

	local role = select(5, Utils.GetSpec())
	return barOptions.hideManaRoles[role]
end

local function GetDruidFormPowerTypes(barOptions)
	local druidFormPowerTypes = barOptions.druidFormPowerTypes
	if not druidFormPowerTypes then
		return
	end

	local specID = Utils.GetSpec()
	return druidFormPowerTypes[specID] or druidFormPowerTypes
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
	-- FUCK PIXEL PERFECT ISSUES
	backdropInfo.edgeSize = backdropSize
	return backdropInfo
end

local function CalculateResourceBarPixelInset(region)
	if region.barOptions and not region.barOptions.showBorder then
		return 0
	end

	local backdropSize = (region.barOptions and region.barOptions.backdropSize) or 0
	if backdropSize <= 0 then
		return 0
	end

	return PixelUtil.GetNearestPixelSize(backdropSize * 0.5, region:GetEffectiveScale(), 1)
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
	for _, region in ipairs({ borderFrame:GetRegions() }) do
		if region:IsObjectType("Texture") then
			region:SetTexelSnappingBias(0)
			region:SetSnapToPixelGrid(false)
		end
	end

	local color = barOptions.backdropColor or {}
	local alpha = color.a == nil and 1 or color.a
	borderFrame:SetBackdropBorderColor(color.r or 0, color.g or 0, color.b or 0, alpha)
	borderFrame:Show()
end

local function SetRegionPoint(region, bar)
	local inset = CalculateResourceBarPixelInset(bar)
	region:ClearAllPoints()
	PixelUtil.SetPoint(region, "TOPLEFT", bar, "TOPLEFT", inset, -inset)
	PixelUtil.SetPoint(region, "BOTTOMRIGHT", bar, "BOTTOMRIGHT", -inset, inset)
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
	backgroundTexture:SetTexelSnappingBias(0)
	backgroundTexture:SetSnapToPixelGrid(false)
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
		-- maxValue = GetCollapsingStarCost() or 0
		maxValue = 40
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

local function GetIciclesValue()
	local currentValue = 0
	local maxValue = 5

	local auraData = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_ID_ICICLES)
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

local function GetVengeanceSoulFragmentValue()
	local maxValue = 6
	local currentValue = C_Spell.GetSpellCastCount(SPELL_ID_SOUL_FRAGMENTS) or 0

	return currentValue, maxValue, currentValue
end

local function GetCurrentPowerValue(resourceKind, powerType, spellID, segmentCount)
	if resourceKind == "runes" then
		return GetRuneValues()
	end

	if resourceKind == "spellCharges" then
		if not spellID or not segmentCount then
			return
		end

		local chargeInfo = C_Spell.GetSpellCharges(spellID)
		if not chargeInfo then
			return
		end

		return chargeInfo.currentCharges, segmentCount, chargeInfo.currentCharges, chargeInfo
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

	if resourceKind == "vengeanceSoulFragments" then
		return GetVengeanceSoulFragmentValue()
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

	if resourceKind == "icicles" then
		return GetIciclesValue()
	end

	local currentValue = UnitPower("player", powerType)
	local maxValue = UnitPowerMax("player", powerType)
	return currentValue, maxValue
end

local function UpdateStaggerBarColor(bar, currentValue, maxValue, resourceBarOptions)
	if issecretvalue(currentValue) or issecretvalue(maxValue) then
		return
	end

	local staggerPercent = maxValue > 0 and currentValue / maxValue or 0
	local staggerColors = resourceBarOptions.staggerColors
	local color = staggerColors.light

	if staggerPercent >= 0.60 then
		color = staggerColors.heavy
	elseif staggerPercent >= 0.30 then
		color = staggerColors.moderate
	end

	bar:SetStatusBarColor(color.r, color.g, color.b)
	return staggerPercent
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
	PixelUtil.SetPoint(text, "CENTER", anchorRegion, "CENTER", barOptions.textXOffset, barOptions.textYOffset)
end

local function HideRechargeSegment(bar)
	if not bar or not bar.RechargeSegment then
		return
	end

	bar.RechargeSegment:Hide()
	bar.RechargeSegment:SetAlpha(0)
	bar.RechargeSegment:ClearAllPoints()
	bar.RechargeSegment:SetMinMaxValues(0, 1)
	bar.RechargeSegment:SetValue(0)
end

local function UpdateRechargeSegment(bar)
	if not bar or not bar.RechargeSegment then
		return
	end

	local texturePath = bar.SCMTexturePath or LSM:Fetch("statusbar", bar.barOptions.texture)
	local r, g, b = GetPowerColor(bar.powerToken, bar.powerType)
	bar.RechargeSegment:SetStatusBarTexture(texturePath)
	bar.RechargeSegment:GetStatusBarTexture():SetTexelSnappingBias(0)
	bar.RechargeSegment:GetStatusBarTexture():SetSnapToPixelGrid(false)
	bar.RechargeSegment:SetStatusBarColor(r, g, b)
end

local function GetSegmentBarSize(bar, segmentCount)
	local segmentWidth = bar:GetWidth() / segmentCount
	local segmentHeight = bar:GetHeight()
	local borderSize = 0
	local barOptions = bar.barOptions

	if barOptions and barOptions.showBorder then
		borderSize = (barOptions.backdropSize or 0) * 2
	end

	return segmentWidth, max(0, segmentHeight - borderSize)
end

local function UpdateSpellChargeRecharge(bar, chargeInfo)
	if bar.resourceKind ~= "spellCharges" or not chargeInfo or not chargeInfo.isActive or not bar.spellID or (bar.barOptions and bar.barOptions.textOnly) then
		HideRechargeSegment(bar)
		return
	end

	local duration = C_Spell.GetSpellChargeDuration(bar.spellID, true)
	if not duration then
		HideRechargeSegment(bar)
		return
	end

	local segmentCount = GetNumSegments(bar, bar.segmentCount)
	if not segmentCount or segmentCount <= 0 then
		HideRechargeSegment(bar)
		return
	end

	local segmentWidth, segmentHeight = GetSegmentBarSize(bar, segmentCount)
	local segment = bar.RechargeSegment
	local statusBarTexture = bar:GetStatusBarTexture()

	if not segment then
		segment = CreateFrame("StatusBar", nil, bar)
		segment:SetMinMaxValues(0, 1)
		segment:SetAlpha(0)
		bar.RechargeSegment = segment
	end

	segment:SetFrameLevel(bar:GetFrameLevel())
	segment:ClearAllPoints()
	segment:SetPoint("LEFT", statusBarTexture, "RIGHT", 0, 0)
	segment:SetWidth(segmentWidth)
	segment:SetHeight(segmentHeight)
	UpdateRechargeSegment(bar)
	segment:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)
	segment:SetAlpha(C_CurveUtil.EvaluateColorValueFromBoolean(duration:IsZero(), 0, 1))
	segment:Show()
end

local function HideResourceBarSpark(bar)
	if bar.Spark then
		bar.Spark:Hide()
	end
end

local function ApplyResourceBarSparkOptions(bar, sparkAnchor, optionsChanged)
	if not optionsChanged or not sparkAnchor then
		return
	end

	local spark = bar.Spark
	local sparkOptions = bar.barOptions and bar.barOptions.spark
	local color = sparkOptions.color
	local width = sparkOptions.width
	local height = sparkOptions.height
	local blendMode = sparkOptions.blendMode

	local texture = sparkOptions.texture
	local texturePath = "Interface\\Buttons\\WHITE8x8"
	if type(texture) == "string" and texture ~= "" then
		if texture:find("\\", 1, true) then
			texturePath = texture
		end

		local sharedMediaPath = LSM:Fetch("statusbar", texture)
		if sharedMediaPath then
			texturePath = sharedMediaPath
		end
	end
	if bar.SparkFrame then
		bar.SparkFrame:SetFrameStrata(bar:GetFrameStrata())
		bar.SparkFrame:SetFrameLevel(bar:GetFrameLevel() + 4)
	end

	spark:SetSize(width, height)
	spark:SetBlendMode(blendMode)
	spark:SetTexture(texturePath)
	spark:SetVertexColor(color.r, color.g, color.g, color.a)
	spark:SetAlpha(1)
	spark:SetTexelSnappingBias(0)
	spark:SetSnapToPixelGrid(false)
	spark:ClearAllPoints()
	PixelUtil.SetPoint(spark, "LEFT", sparkAnchor, "RIGHT", sparkOptions.xOffset, sparkOptions.yOffset)
end

local function ResetResourceBar(bar)
	bar.resourceKind = nil
	bar.powerType = nil
	bar.powerToken = nil
	bar.spellID = nil
	bar.segmentCount = nil
	bar.SCMRegisterUnitAura = nil
	bar.Text.Value:SetText("")

	HideRegions(bar.SegmentTicks)
	HideRegions(bar.SegmentFillBars)
	HideRegions(bar.RuneSegmentBars)
	HideRechargeSegment(bar)
	HideResourceBarSpark(bar)
	if bar.SegmentTickFrame then
		bar.SegmentTickFrame:Hide()
	end

	bar.SCMSegmentedDisplay = nil
	bar.SCMConfiguredSegmentCount = nil

	bar:GetStatusBarTexture():SetAlpha(1)

	bar:Hide()
end

local function ConfigureBarForResource(bar, resource, altR, altG, altB)
	local resourceKind = resource.resourceKind or "power"
	local powerType = resource.powerType
	local powerToken = resource.powerToken
	local spellID = resource.spellID
	local registerUnitAura = resource.registerUnitAura
	local segmentCount = resource.segmentCount

	if resource.segmentCountTalentSpellID and resource.talentSegmentCount and IsPlayerSpell(resource.segmentCountTalentSpellID) then
		segmentCount = resource.talentSegmentCount
	end

	if bar.SCMUseSegmentedSecondaryDisplay and powerType == Enum.PowerType.Mana then
		segmentCount = nil
	elseif resourceKind == "maelstromWeapon" and bar.barOptions and bar.barOptions.disableMaelstromOverflow then
		segmentCount = 10
	end

	local resourceChanged = bar.resourceKind ~= resourceKind
		or bar.powerType ~= powerType
		or bar.powerToken ~= powerToken
		or bar.spellID ~= spellID
		or bar.SCMRegisterUnitAura ~= registerUnitAura
		or bar.SCMConfiguredSegmentCount ~= segmentCount

	bar.resourceKind = resourceKind
	bar.powerType = powerType
	bar.powerToken = powerToken
	bar.spellID = spellID
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
	local tickFrame = bar.SegmentTickFrame

	if not tickFrame then
		tickFrame = CreateFrame("Frame", nil, bar)
		bar.SegmentTickFrame = tickFrame
	end

	tickFrame:ClearAllPoints()
	tickFrame:SetAllPoints(bar)
	tickFrame:SetFrameStrata(bar:GetFrameStrata())
	tickFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
	tickFrame:Show()

	if bar.SegmentTicks[1] and bar.SegmentTicks[1]:GetParent() ~= tickFrame then
		HideRegions(bar.SegmentTicks)
		bar.SegmentTicks = {}
	end

	for tickIndex = #bar.SegmentTicks + 1, tickCount do
		local tick = bar.SegmentTicks[tickIndex] or tickFrame:CreateTexture(nil, "OVERLAY")
		tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a)
		tick:SetTexelSnappingBias(0)
		tick:SetSnapToPixelGrid(false)
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

	if not barOptions or barOptions.textOnly or not barOptions.showTicks or not hasSegmentTicks or type(segmentCount) ~= "number" or segmentCount <= 1 then
		HideRegions(bar.SegmentTicks)
		if bar.SegmentTickFrame then
			bar.SegmentTickFrame:Hide()
		end
		return
	end

	local tickWidth = barOptions.tickWidth
	if not tickWidth or tickWidth <= 0 then
		HideRegions(bar.SegmentTicks)
		if bar.SegmentTickFrame then
			bar.SegmentTickFrame:Hide()
		end
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
		tick:SetTexelSnappingBias(0)
		tick:SetSnapToPixelGrid(false)
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
		local _, currentMaxValue = GetCurrentPowerValue(bar.resourceKind, bar.powerType, bar.spellID, bar.segmentCount)
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
		segmentBar:GetStatusBarTexture():SetTexelSnappingBias(0)
		segmentBar:GetStatusBarTexture():SetSnapToPixelGrid(false)
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
	local runeRechargeColor = bar.resourceKind == "runes" and SCM.resourceBarConfig.runeRechargeColor
	local overflowR, overflowG, overflowB = CHARGED_COMBO_POINT_COLOR.r, CHARGED_COMBO_POINT_COLOR.g, CHARGED_COMBO_POINT_COLOR.b

	if bar.resourceKind == "maelstromWeapon" then
		local overflowColor = SCM.resourceBarConfig.maelstromOverflowColor
		if overflowColor and overflowColor.r and overflowColor.g and overflowColor.b then
			overflowR, overflowG, overflowB = overflowColor.r, overflowColor.g, overflowColor.b
		end
	end

	local chargedSegments = GetChargedSegmentMap(bar, segmentCount, currentValue)
	local segmentProgressValues = GetProgressValues(bar, segmentCount, currentValue, resourceSegmentValues)
	local segmentWidth, segmentHeight = GetSegmentBarSize(bar, segmentCount)

	for segmentIndex = 1, segmentCount do
		local segmentBar = segmentBars[segmentIndex]
		segmentBar:ClearAllPoints()
		segmentBar:SetStatusBarTexture(texturePath)
		segmentBar:GetStatusBarTexture():SetTexelSnappingBias(0)
		segmentBar:GetStatusBarTexture():SetSnapToPixelGrid(false)
		segmentBar:SetPoint("LEFT", (segmentIndex - 1) * segmentWidth, 0)
		segmentBar:SetWidth(segmentWidth)
		segmentBar:SetHeight(segmentHeight)
		if barOptions.textOnly then
			segmentBar:GetStatusBarTexture():Hide()
		else
			segmentBar:GetStatusBarTexture():Show()
		end

		local segmentR, segmentG, segmentB = r, g, b
		local segmentProgress = segmentProgressValues[segmentIndex] or 0
		if runeRechargeColor and segmentProgress > 0 and segmentProgress < 1 then
			segmentR, segmentG, segmentB = runeRechargeColor.r, runeRechargeColor.g, runeRechargeColor.b
		elseif chargedSegments and chargedSegments[segmentIndex] then
			if bar.resourceKind == "maelstromWeapon" then
				segmentR, segmentG, segmentB = overflowR, overflowG, overflowB
			else
				segmentR, segmentG, segmentB = CHARGED_COMBO_POINT_COLOR.r, CHARGED_COMBO_POINT_COLOR.g, CHARGED_COMBO_POINT_COLOR.b
			end
		end

		segmentBar:SetStatusBarColor(segmentR, segmentG, segmentB)
		segmentBar:SetValue(segmentProgress)
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

	if not barOptions.textOnly then
		local texturePath = LSM:Fetch("statusbar", barOptions.texture)
		bar.SCMTexturePath = texturePath
		bar:SetStatusBarTexture(texturePath)
		bar:GetStatusBarTexture():SetTexelSnappingBias(0)
		bar:GetStatusBarTexture():SetSnapToPixelGrid(false)
		bar:GetStatusBarTexture():Show()

		if bar.SegmentFillBars then
			for _, segmentBar in ipairs(bar.SegmentFillBars) do
				segmentBar:SetStatusBarTexture(texturePath)
				segmentBar:GetStatusBarTexture():SetTexelSnappingBias(0)
				segmentBar:GetStatusBarTexture():SetSnapToPixelGrid(false)
				segmentBar:GetStatusBarTexture():Show()
			end
		end
		UpdateRechargeSegment(bar)

		local statusBarTexture = bar:GetStatusBarTexture()
		statusBarTexture:SetTexelSnappingBias(0)
		statusBarTexture:SetSnapToPixelGrid(false)
		SetRegionPoint(statusBarTexture, bar)
		UpdateResourceBarBackgroundTexture(bar, barOptions)
	else
		bar:GetStatusBarTexture():Hide()
		bar.Background:Hide()
		HideRechargeSegment(bar)
		if bar.SegmentTickFrame then
			bar.SegmentTickFrame:Hide()
		end
		if bar.SegmentFillBars then
			for _, segmentBar in ipairs(bar.SegmentFillBars) do
				segmentBar:GetStatusBarTexture():Hide()
			end
		end
	end

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
		if barOptions.textOnly then
			bar.BorderFrame:Hide()
		else
			UpdateResourceBarBorder(bar, barOptions)
		end
	end

	if bar.Text then
		bar.Text:SetFrameStrata(bar:GetFrameStrata())
		if bar.SegmentTickFrame then
			bar.SegmentTickFrame:SetFrameStrata(bar:GetFrameStrata())
			bar.SegmentTickFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
		end
		if bar.SparkFrame then
			bar.SparkFrame:SetFrameStrata(bar:GetFrameStrata())
			bar.SparkFrame:SetFrameLevel(bar:GetFrameLevel() + 4)
		end
		bar.Text:SetFrameLevel(bar:GetFrameLevel() + 3)
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

	if not bar.SparkFrame then
		bar.SparkFrame = CreateFrame("Frame", nil, bar)
		bar.SparkFrame:SetAllPoints(bar)
		bar.SparkFrame:SetClipsChildren(true)
		bar.SparkFrame:SetFrameLevel(bar:GetFrameLevel() + 4)
	end

	if not bar.Spark then
		bar.Spark = bar.SparkFrame:CreateTexture(nil, "OVERLAY", nil, 2)
		bar.Spark:SetTexelSnappingBias(0)
		bar.Spark:SetSnapToPixelGrid(false)
		bar.Spark:Hide()
	end

	-- If anyone wants to explain to me how to fix this then I'm all ears
	bar.BorderFrame:ClearAllPoints()
	PixelUtil.SetPoint(bar.BorderFrame, "TOPLEFT", bar, "TOPLEFT", 0, 0)
	PixelUtil.SetPoint(bar.BorderFrame, "BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

	local barOptions = bar.barOptions or SCM.resourceBarConfig
	UpdateResourceBarBorder(bar, barOptions)
	bar.SCMStyled = true
end

local function BarNeedsContinuousRefresh(bar)
	if not bar.powerToken or not bar:IsShown() then
		return
	end

	if bar.resourceKind == "stagger" then
		return true
	end

	if bar.resourceKind == "runes" then
		local _, maxValue, displayValue = GetRuneValues()
		local hasRuneValues = type(displayValue) == "number" and type(maxValue) == "number"
		return hasRuneValues and displayValue < maxValue
	end

	if bar.resourceKind == "spellCharges" then
		local chargeInfo = bar.spellID and C_Spell.GetSpellCharges(bar.spellID)
		return chargeInfo ~= nil and chargeInfo.isActive
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

	if bar.resourceKind == "spellCharges" then
		bar:RegisterEvent("SPELL_UPDATE_CHARGES")
		return
	end

	if bar.resourceKind == "vengeanceSoulFragments" then
		bar:RegisterUnitEvent("UNIT_AURA", "player")
		bar:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
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
function SCM:ApplyResourceBarAttributeDriver(forceHide)
	local container = _G[RESOURCE_BAR_FRAME_NAME]
	if not container or InCombatLockdown() then
		return
	end

	if forceHide then
		RegisterAttributeDriver(container, "state-visibility", "hide")
	else
		RegisterAttributeDriver(container, "state-visibility", SCM:GetVisibilityConditions(self.resourceBarConfig))
	end

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
	local barOptions = SCM.resourceBarConfig
	self.barOptions = barOptions
	self.primaryBarOptions = barOptions.primaryBar
	self.secondaryBarOptions = barOptions.secondaryBar

	ApplyBarAppearance(self.PrimaryBar, self.primaryBarOptions)
	ApplyBarAppearance(self.SecondaryBar, self.secondaryBarOptions)

	return barOptions
end

function SCMResourceBarControllerMixin:UpdateActiveAnchorFrame(anchor)
	local activeAnchor, activeAnchorGroup
	if type(anchor) == "string" then
		activeAnchor, _, activeAnchorGroup = Utils.GetActiveAnchorFrame(anchor)
	else
		activeAnchor = anchor
	end

	self.SCMActiveAnchorFrame = activeAnchor
	self.SCMActiveAnchorGroup = activeAnchorGroup
	return activeAnchor
end

function SCMResourceBarControllerMixin:ApplyFrameWidthOptions(bar)
	local specificBarOptions = bar.barOptions
	local generalBarOptions = self.barOptions
	local anchor = self.SCMActiveAnchorFrame or self:UpdateActiveAnchorFrame(generalBarOptions.anchorFrame or DEFAULT_RESOURCE_BAR_ANCHOR)

	if anchor then
		local widthFromOptions = specificBarOptions.width
		if specificBarOptions.matchAnchorWidth then
			widthFromOptions = anchor:GetWidth() or 0
		end

		local desiredWidth = max(generalBarOptions.minWidth, widthFromOptions)
		local previousWidth = bar:GetWidth() or 0
		bar:SetWidth(desiredWidth)
		local widthChanged = previousWidth ~= (bar:GetWidth() or 0)

		bar.SCMResourceBarHooks = bar.SCMResourceBarHooks or {}
		if not anchor.SCMProxyGroup and not bar.SCMResourceBarHooks[anchor] then
			bar.SCMResourceBarHooks[anchor] = true
			anchor:HookScript("OnSizeChanged", function(changedAnchor)
				local barOptions = bar.barOptions
				local controller = bar.Controller
				local generalBarOptions = controller and controller.barOptions or SCM.resourceBarConfig
				if bar:IsProtected() or not (generalBarOptions.enabled and barOptions and barOptions.enabled and barOptions.matchAnchorWidth) then
					return
				end

				if controller and controller.SCMActiveAnchorFrame == changedAnchor then
					SCM:RefreshResourceBarConfig()
				end
			end)
		end

		--No idea whats going in with these fucking pixels. BRB taking a math class
		self:ClearAllPoints()
		PixelUtil.SetPoint(self, generalBarOptions.point, anchor, generalBarOptions.relativePoint, generalBarOptions.xOffset, generalBarOptions.yOffset)

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

function SCMResourceBarControllerMixin:RefreshResourceBars(refreshTicks, optionsChanged)
	local barOptions = self:ApplyResourceBarOptions()
	local primaryBarOptions = barOptions.primaryBar
	local secondaryBarOptions = barOptions.secondaryBar

	if not barOptions.enabled then
		SCM:ApplyResourceBarAttributeDriver(true)
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
		self:UpdateActiveAnchorFrame(barOptions.anchorFrame or DEFAULT_RESOURCE_BAR_ANCHOR)

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

		self:RefreshBarDisplay(self.PrimaryBar, refreshPrimaryTicks, true, optionsChanged)
		self:RefreshBarDisplay(self.SecondaryBar, refreshSecondaryTicks, true, optionsChanged)
		self:UpdateContainerShownState()
		self:UpdateRefreshState()

		EventRegistry:TriggerEvent("SkironCooldownManager.ResourceBar.LayoutUpdated")
	end

	SCM:ApplyResourceBarAttributeDriver()
end

function SCMResourceBarControllerMixin:ConfigurePrimaryBar()
	local powerType, powerToken, altR, altG, altB = UnitPowerType("player")

	local forceMana = false
	if SCM.resourceBarConfig.active then
		if UnitClassBase("player") == "DRUID" then
			local shapeshiftFormID = GetShapeshiftFormID()
			local customPowerType
			local druidFormPowerTypes = GetDruidFormPowerTypes(self.primaryBarOptions)
			if not shapeshiftFormID or shapeshiftFormID == 36 then
				customPowerType = druidFormPowerTypes and druidFormPowerTypes[0]
			elseif shapeshiftFormID == DRUID_BEAR_FORM then
				customPowerType = druidFormPowerTypes and druidFormPowerTypes[1]
			elseif shapeshiftFormID == DRUID_CAT_FORM then
				customPowerType = druidFormPowerTypes and druidFormPowerTypes[2]
			elseif shapeshiftFormID == DRUID_TRAVEL_FORM or shapeshiftFormID == DRUID_FLIGHT_FORM or shapeshiftFormID == DRUID_AQUATIC_FORM then
				customPowerType = druidFormPowerTypes and druidFormPowerTypes[3]
			elseif shapeshiftFormID >= DRUID_MOONKIN_FORM_1 and shapeshiftFormID <= DRUID_MOONKIN_FORM_2 then
				customPowerType = druidFormPowerTypes and druidFormPowerTypes[4]
			end
			--
			if customPowerType == "none" then
				powerType = nil
				powerToken = nil
			else
				powerType = customPowerType
				powerToken = nil
				--
				if powerType == Enum.PowerType.Mana then
					powerToken = "MANA"
					forceMana = true
				elseif powerType == Enum.PowerType.Rage then
					powerToken = "RAGE"
				elseif powerType == Enum.PowerType.Energy then
					powerToken = "ENERGY"
				elseif powerType == Enum.PowerType.LunarPower then
					powerToken = "LUNAR_POWER"
				end

				local colorInfo = PowerBarColor[powerToken]
				if colorInfo then
					altR, altG, altB = colorInfo.r, colorInfo.g, colorInfo.b
				end
			end
		elseif self.primaryBarOptions.forceMana then
			forceMana = true
			powerType = Enum.PowerType.Mana
			powerToken = "MANA"
		end
	end

	if not powerType or not powerToken then
		ResetResourceBar(self.PrimaryBar)
		return false
	end

	if powerType == Enum.PowerType.Mana and ShouldHideManaForCurrentRole(self.primaryBarOptions) and not forceMana then
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

	if not UnitHasVehicleUI("player") then
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

	local forceMana = false
	if SCM.resourceBarConfig.active then
		if UnitClassBase("player") == "DRUID" then
			local shapeshiftFormID = GetShapeshiftFormID()
			local customSecondaryResource
			local druidFormPowerTypes = GetDruidFormPowerTypes(self.secondaryBarOptions)

			if not shapeshiftFormID then
				customSecondaryResource = druidFormPowerTypes and druidFormPowerTypes[0]
			elseif shapeshiftFormID == DRUID_BEAR_FORM then
				customSecondaryResource = druidFormPowerTypes and druidFormPowerTypes[1]
			elseif shapeshiftFormID == DRUID_CAT_FORM then
				customSecondaryResource = druidFormPowerTypes and druidFormPowerTypes[2]
			elseif shapeshiftFormID == DRUID_TRAVEL_FORM or shapeshiftFormID == DRUID_FLIGHT_FORM or shapeshiftFormID == DRUID_AQUATIC_FORM then
				customSecondaryResource = druidFormPowerTypes and druidFormPowerTypes[3]
			elseif shapeshiftFormID >= DRUID_MOONKIN_FORM_1 and shapeshiftFormID <= DRUID_MOONKIN_FORM_2 then
				customSecondaryResource = druidFormPowerTypes and druidFormPowerTypes[4]
			end

			if customSecondaryResource == "none" then
				secondaryResource = nil
			else
				local primaryResourcePowerType = self.PrimaryBar.powerType
				if customSecondaryResource ~= primaryResourcePowerType then
					secondaryResource = SCMConstants.DruidSecondaryResourceByPowerType[customSecondaryResource]
					forceMana = secondaryResource and customSecondaryResource == Enum.PowerType.Mana
				else
					secondaryResource = nil
				end
			end
		elseif self.secondaryBarOptions.forceMana then
			local primaryResourcePowerType = self.PrimaryBar.powerType
			if primaryResourcePowerType ~= Enum.PowerType.Mana then
				forceMana = true
				secondaryResource = {
					powerType = Enum.PowerType.Mana,
					powerToken = "MANA",
				}
			end
		end
	end

	if secondaryResource and secondaryResource.powerType == Enum.PowerType.Mana and ShouldHideManaForCurrentRole(self.secondaryBarOptions) and not forceMana then
		secondaryResource = nil
	end

	if not secondaryResource then
		ResetResourceBar(self.SecondaryBar)
		return false
	end

	return ConfigureBarForResource(self.SecondaryBar, secondaryResource)
end

function SCMResourceBarControllerMixin:RefreshBarDisplay(bar, refreshTicks, skipWidthOptions, optionsChanged)
	if not bar.powerToken then
		HideResourceBarSpark(bar)
		return
	end

	local currentValue, maxValue, displayValue, resourceSegmentValues = GetCurrentPowerValue(bar.resourceKind, bar.powerType, bar.spellID, bar.segmentCount)
	local missingValues = maxValue == nil
	if bar.resourceKind ~= "spellCharges" then
		missingValues = missingValues or currentValue == nil
	end

	if missingValues then
		if bar.resourceKind == "spellCharges" then
			HideRegions(bar.SegmentFillBars)
			HideRegions(bar.RuneSegmentBars)
			HideRechargeSegment(bar)
			bar:GetStatusBarTexture():SetAlpha(1)
		else
			UpdateSegments(bar)
		end
		if refreshTicks then
			RefreshBarTicks(bar)
		end
		HideResourceBarSpark(bar)
		bar:Hide()
		return
	end

	if bar.resourceKind ~= "spellCharges" and displayValue == nil then
		displayValue = currentValue
	end
	bar:SetMinMaxValues(0, maxValue)
	bar:SetValue(currentValue)
	if not skipWidthOptions then
		self:UpdateActiveAnchorFrame(self.barOptions.anchorFrame or DEFAULT_RESOURCE_BAR_ANCHOR)
	end
	local widthChanged = not skipWidthOptions and self:ApplyFrameWidthOptions(bar)
	if bar.resourceKind == "spellCharges" then
		bar.SCMSegmentedDisplay = nil
		HideRegions(bar.SegmentFillBars)
		HideRegions(bar.RuneSegmentBars)
		bar:GetStatusBarTexture():SetAlpha(1)
		UpdateSpellChargeRecharge(bar, resourceSegmentValues)
	elseif bar.resourceKind == "vengeanceSoulFragments" then
		bar.SCMSegmentedDisplay = nil
		HideRegions(bar.SegmentFillBars)
		bar:GetStatusBarTexture():SetAlpha(1)
	else
		HideRechargeSegment(bar)
		UpdateSegments(bar, maxValue, currentValue, resourceSegmentValues)
	end
	bar:Show()

	local spark = bar.Spark
	local barOptions = bar.barOptions
	local sparkOptions = barOptions.spark
	if spark and sparkOptions.enable and not barOptions.textOnly then
		local sparkAnchor
		local sparkFrameAlpha = 1
		local showSpark = true
		if bar.resourceKind == "spellCharges" then
			local rechargeSegment = bar.RechargeSegment
			if rechargeSegment and rechargeSegment:IsShown() then
				sparkAnchor = rechargeSegment:GetStatusBarTexture()
			end
			showSpark = sparkAnchor ~= nil
		else
			sparkFrameAlpha = currentValue
		end

		if showSpark then
			sparkAnchor = sparkAnchor or bar:GetStatusBarTexture()
			ApplyResourceBarSparkOptions(bar, sparkAnchor, optionsChanged)
			if bar.SparkFrame then
				bar.SparkFrame:SetAlpha(sparkFrameAlpha)
			end

			spark:Show()
		else
			HideResourceBarSpark(bar)
		end
	elseif spark then
		HideResourceBarSpark(bar)
	end

	if refreshTicks or widthChanged then
		RefreshBarTicks(bar, maxValue)
	end

	local staggerPercent
	local overrideColor = bar.SCMIsPrimaryResourceBar and SCM.primaryResourceBarColorOverride
	if overrideColor then
		bar:SetStatusBarColor(overrideColor.r, overrideColor.g, overrideColor.b)
	elseif bar.resourceKind == "stagger" then
		staggerPercent = UpdateStaggerBarColor(bar, currentValue, maxValue, self.barOptions)
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

	if bar.resourceKind == "spellCharges" then
		textValue:SetText(displayValue)
		return maxValue
	end

	if bar.resourceKind == "vengeanceSoulFragments" then
		textValue:SetText(tostring(displayValue))
		return maxValue
	end

	if not displayValue then
		textValue:SetText("")
		return maxValue
	end

	if bar.resourceKind == "stagger" and self.barOptions.staggerDisplayAsPercent then
		staggerPercent = staggerPercent or (not issecretvalue(maxValue) and not issecretvalue(currentValue) and (maxValue > 0 and currentValue / maxValue or 0)) or 0
		textValue:SetText(floor(staggerPercent * 100 + 0.5) .. "%")
	elseif bar.powerType == Enum.PowerType.Mana then
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
	local frameStrata = barOptions.frameStrata or "BACKGROUND"

	local primaryHeightChanged = false
	local secondaryHeightChanged = false

	self.SecondaryBar:ClearAllPoints()
	self.PrimaryBar:ClearAllPoints()

	if primaryShown then
		primaryHeightChanged = SetBarHeight(self.PrimaryBar, primaryHeight)
		self.PrimaryBar:SetPoint("BOTTOM", self, "BOTTOM")
		self.PrimaryBar:SetFrameStrata(frameStrata)
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
		self.SecondaryBar:SetFrameStrata(frameStrata)
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
	EventRegistry:RegisterCallback(ANCHOR_PROXY_SIZE_CHANGED_EVENT, function(_, proxyGroup, proxy, _width, _height, _selectedAnchorRef, isActiveProxy)
		local barOptions = SCM.resourceBarConfig
		local primaryBarOptions = barOptions.primaryBar
		local secondaryBarOptions = barOptions.secondaryBar
		local primaryMatchesAnchor = primaryBarOptions.enabled and primaryBarOptions.matchAnchorWidth
		local secondaryMatchesAnchor = secondaryBarOptions.enabled and secondaryBarOptions.matchAnchorWidth
		if not (barOptions.enabled and isActiveProxy and (primaryMatchesAnchor or secondaryMatchesAnchor)) then
			return
		end

		if self.SCMActiveAnchorFrame == proxy or self.SCMActiveAnchorGroup == proxyGroup then
			self.SCMActiveAnchorFrame = proxy
			SCM:RefreshResourceBarConfig()
		end
	end, self)

	self:RefreshResourceBars(true)
end

function SCM:InitializeResourceBars()
	local container = _G[RESOURCE_BAR_FRAME_NAME]
	local barOptions = self.resourceBarConfig
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

function SCM:RefreshResourceBarConfig(refreshTicks, optionsChanged)
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

	container:RefreshResourceBars(refreshTicks, optionsChanged)
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
