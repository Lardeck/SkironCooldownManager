local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local Constants = SCM.Constants
local Options = SCM.Options

SCM.MainTabs.CastBar = { value = "CastBar", text = "Cast Bar", order = 6, subgroups = {} }

local FONT_OUTLINES = {
	[""] = "None",
	OUTLINE = "Outline",
	THICKOUTLINE = "Thick Outline",
	MONOCHROME = "Monochrome",
	SLUG = "Slug",
	["OUTLINE SLUG"] = "Outline Slug",
	-- ["THICKOUTLINE SLUG"] = "Thick Outline Slug", -- Seems to be identical to Outline Slug?
	-- ["MONOCHROME SLUG"] = "Monochrome Slug", -- Doesn't seem to do anything?
}

local ICON_POSITIONS = {
	LEFT = "Left",
	RIGHT = "Right",
}

local function AddHeader(widget, text)
	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(18)
	label:SetJustifyH("LEFT")
	label:SetText(text)
	widget:AddChild(label)
end

local function AddAnchorControls(parent, title, anchors, refreshFn, relativeFrameHelp)
	local anchorGroup = AceGUI:Create("InlineGroup")
	anchorGroup:SetTitle(title)
	anchorGroup:SetFullWidth(true)
	anchorGroup:SetLayout("flow")
	parent:AddChild(anchorGroup)

	local relativeTo = AceGUI:Create("EditBox")
	relativeTo:SetRelativeWidth(1)
	relativeTo:SetLabel(relativeFrameHelp or "Anchor Frame")
	relativeTo:SetText(anchors[2] or "")
	relativeTo:SetCallback("OnEnterPressed", function(self, _, text)
		anchors[2] = text ~= "" and text or nil
		self:SetText(anchors[2] or "")
		refreshFn()
	end)
	anchorGroup:AddChild(relativeTo)
	Options.AddAnchorParentAutocomplete(anchorGroup, relativeTo, function(text) anchors[2] = text ~= "" and text or nil refreshFn() end)

	local point = AceGUI:Create("Dropdown")
	point:SetRelativeWidth(0.5)
	point:SetLabel("Point")
	point:SetList(SCM.Constants.AnchorPoints)
	point:SetValue(anchors[1])
	point:SetCallback("OnValueChanged", function(_, _, value)
		anchors[1] = value
		refreshFn()
	end)
	anchorGroup:AddChild(point)

	local relativePoint = AceGUI:Create("Dropdown")
	relativePoint:SetRelativeWidth(0.5)
	relativePoint:SetLabel("Relative Point")
	relativePoint:SetList(SCM.Constants.AnchorPoints)
	relativePoint:SetValue(anchors[3])
	relativePoint:SetCallback("OnValueChanged", function(_, _, value)
		anchors[3] = value
		refreshFn()
	end)
	anchorGroup:AddChild(relativePoint)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(-500, 500, 0.1)
	xOffset:SetValue(anchors[4] or 0)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		anchors[4] = value
		refreshFn()
	end)
	anchorGroup:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.5)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-500, 500, 0.1)
	yOffset:SetValue(anchors[5] or 0)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		anchors[5] = value
		refreshFn()
	end)
	anchorGroup:AddChild(yOffset)
end

local function AddCastBarTextAnchorControls(parent, title, anchors, refreshFn)
	local anchorGroup = AceGUI:Create("InlineGroup")
	anchorGroup:SetTitle(title)
	anchorGroup:SetFullWidth(true)
	anchorGroup:SetLayout("flow")
	parent:AddChild(anchorGroup)

	local enable = AceGUI:Create("CheckBox")
	enable:SetRelativeWidth(1)
	enable:SetLabel("Enable")
	enable:SetValue(anchors.enable)
	enable:SetCallback("OnValueChanged", function(_, _, value)
		anchors.enable = value
		refreshFn()
	end)
	anchorGroup:AddChild(enable)

	local point = AceGUI:Create("Dropdown")
	point:SetRelativeWidth(0.5)
	point:SetLabel("Point")
	point:SetList(SCM.Constants.AnchorPoints)
	point:SetValue(anchors.anchors[1])
	point:SetCallback("OnValueChanged", function(_, _, value)
		anchors.anchors[1] = value
		refreshFn()
	end)
	anchorGroup:AddChild(point)

	local relativePoint = AceGUI:Create("Dropdown")
	relativePoint:SetRelativeWidth(0.5)
	relativePoint:SetLabel("Relative Point")
	relativePoint:SetList(SCM.Constants.AnchorPoints)
	relativePoint:SetValue(anchors.anchors[2])
	relativePoint:SetCallback("OnValueChanged", function(_, _, value)
		anchors.anchors[2] = value
		refreshFn()
	end)
	anchorGroup:AddChild(relativePoint)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(-500, 500, 1)
	xOffset:SetValue(anchors.anchors[3] or 0)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		anchors.anchors[3] = value
		refreshFn()
	end)
	anchorGroup:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.5)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-500, 500, 1)
	yOffset:SetValue(anchors.anchors[4] or 0)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		anchors.anchors[4] = value
		refreshFn()
	end)
	anchorGroup:AddChild(yOffset)
end

local function RefreshCastBar()
	SCM:CreateCastBar()
end

local function UpdateIconControlStates(iconOptions, iconPosition, matchBarHeight, iconZoom, iconSize)
	local iconEnabled = not not iconOptions.enable
	iconPosition:SetDisabled(not iconEnabled)
	matchBarHeight:SetDisabled(not iconEnabled)
	iconZoom:SetDisabled(not iconEnabled)
	iconSize:SetDisabled((not iconEnabled) or iconOptions.matchBarHeight)
end

local function CastBar(self)
	self:ReleaseChildren()

	local rootGroup = AceGUI:Create("InlineGroup")
	rootGroup:SetLayout("fill")
	rootGroup:SetFullWidth(true)
	rootGroup:SetFullHeight(true)
	self:AddChild(rootGroup)

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true)
	rootGroup:AddChild(scrollFrame)

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText("|TInterface\\common\\help-i:40:40:0:0|tRight now the cast bar is still in an experimental state. Please report any bugs on github/curseforge or on discord.")
	label:SetFontObject("Game12Font")
	scrollFrame:AddChild(label)

	local statusGroup = AceGUI:Create("InlineGroup")
	statusGroup:SetFullWidth(true)
	statusGroup:SetLayout("flow")
	scrollFrame:AddChild(statusGroup)

	local currentStatus = AceGUI:Create("Label")
	currentStatus:SetRelativeWidth(0.33)
	currentStatus:SetJustifyH("LEFT")
	currentStatus:SetJustifyV("MIDDLE")
	currentStatus:SetFontObject("Game15Font")
	statusGroup:AddChild(currentStatus)

	if SCM.castBarConfig.active then
		currentStatus:SetText(string.format("Status: |cffea00ffSpecialization|r (%s)", (select(2, SCM.Utils.GetSpec()))))
	else
		currentStatus:SetText("Status: |cfffcf803Profile|r")
	end

	local modifyCurrentSpecialization = AceGUI:Create("CheckBox")
	modifyCurrentSpecialization:SetRelativeWidth(0.33)
	modifyCurrentSpecialization:SetLabel("Use Specialization Config")
	modifyCurrentSpecialization:SetValue(SCM.castBarConfig.active)
	statusGroup:AddChild(modifyCurrentSpecialization)

	local resetCurrentSpecialization = AceGUI:Create("Button")
	resetCurrentSpecialization:SetText("Clear Spec Config")
	resetCurrentSpecialization:SetRelativeWidth(0.33)
	resetCurrentSpecialization:SetDisabled(not SCM.castBarConfig.active)
	resetCurrentSpecialization:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
		GameTooltip:SetText("Clear Spec Config", nil, nil, nil, nil, true)
		GameTooltip:AddLine("This will clear the spec config and fall back to the normal resource bar options.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	resetCurrentSpecialization:SetCallback("OnLeave", function()
		GameTooltip:Hide()
	end)
	statusGroup:AddChild(resetCurrentSpecialization)

	resetCurrentSpecialization:SetCallback("OnClick", function()
		local specCastBarConfig = SCM.specCastBarConfig
		local isActive = specCastBarConfig.active

		wipe(specCastBarConfig)
		specCastBarConfig.active = isActive

		CastBar(self)
		RefreshCastBar()
	end)

	modifyCurrentSpecialization:SetCallback("OnValueChanged", function(_, _, value)
		SCM.castBarConfig.active = value

		if value then
			currentStatus:SetText(string.format("Status: |cffea00ffSpecialization|r (%s)", (select(2, SCM.Utils.GetSpec()))))
		else
			currentStatus:SetText("Status: |cfffcf803Profile|r")
		end

		CastBar(self)
		resetCurrentSpecialization:SetDisabled(not value)
		RefreshCastBar()
	end)

	local options = SCM.castBarConfig
	local iconOptions = options.icon
	local tickOptions = options.ticks
	local sparkOptions = options.spark

	local generalGroup = AceGUI:Create("InlineGroup")
	generalGroup:SetTitle("General")
	generalGroup:SetFullWidth(true)
	generalGroup:SetLayout("flow")
	scrollFrame:AddChild(generalGroup)

	local enable = AceGUI:Create("CheckBox")
	enable:SetRelativeWidth(0.5)
	enable:SetLabel("Enable Cast Bar")
	enable:SetValue(options.enable)
	enable:SetCallback("OnValueChanged", function(_, _, value)
		if value then
			options.enable = true
			RefreshCastBar()
			return
		end

		SCM.ShowReloadPopup({
			checkbox = enable,
			options = options,
			key = "enable",
			value = false,
		})
	end)
	generalGroup:AddChild(enable)

	local matchParentWidth = AceGUI:Create("CheckBox")
	matchParentWidth:SetRelativeWidth(0.5)
	matchParentWidth:SetLabel("Match Parent Width")
	matchParentWidth:SetValue(options.matchParentWidth)
	matchParentWidth:SetCallback("OnValueChanged", function(_, _, value)
		options.matchParentWidth = value
		RefreshCastBar()
	end)
	generalGroup:AddChild(matchParentWidth)

	local width = AceGUI:Create("Slider")
	width:SetRelativeWidth(0.33)
	width:SetLabel("Width")
	width:SetSliderValues(50, 1000, 1)
	width:SetValue(options.width or 270)
	width:SetCallback("OnValueChanged", function(_, _, value)
		options.width = value
		RefreshCastBar()
	end)
	generalGroup:AddChild(width)

	local height = AceGUI:Create("Slider")
	height:SetRelativeWidth(0.33)
	height:SetLabel("Height")
	height:SetSliderValues(8, 80, 1)
	height:SetValue(options.height or 24)
	height:SetCallback("OnValueChanged", function(_, _, value)
		options.height = value
		RefreshCastBar()
	end)
	generalGroup:AddChild(height)

	local fontSize = AceGUI:Create("Slider")
	fontSize:SetRelativeWidth(0.33)
	fontSize:SetLabel("Font Size")
	fontSize:SetSliderValues(6, 32, 1)
	fontSize:SetValue(options.fontSize or 12)
	fontSize:SetCallback("OnValueChanged", function(_, _, value)
		options.fontSize = value
		RefreshCastBar()
	end)
	generalGroup:AddChild(fontSize)

	local texture = AceGUI:Create("LSM30_Statusbar")
	texture:SetRelativeWidth(0.25)
	texture:SetLabel("Texture")
	texture:SetList(LSM:HashTable("statusbar"))
	texture:SetValue(options.texture)
	texture:SetCallback("OnValueChanged", function(self, _, value)
		options.texture = value
		self:SetValue(value)
		RefreshCastBar()
	end)
	generalGroup:AddChild(texture)

	local font = AceGUI:Create("LSM30_Font")
	font:SetRelativeWidth(0.25)
	font:SetLabel("Font")
	font:SetList(LSM:HashTable("font"))
	font:SetValue(options.font)
	font:SetCallback("OnValueChanged", function(self, _, value)
		options.font = value
		self:SetValue(value)
		RefreshCastBar()
	end)
	generalGroup:AddChild(font)

	local fontOutline = AceGUI:Create("Dropdown")
	fontOutline:SetRelativeWidth(0.25)
	fontOutline:SetLabel("Font Outline")
	fontOutline:SetList(Constants.TextOutline, Constants.TextOutlineSorted)
	fontOutline:SetValue(options.fontOutline or "")
	fontOutline:SetCallback("OnValueChanged", function(_, _, value)
		options.fontOutline = value
		RefreshCastBar()
	end)
	generalGroup:AddChild(fontOutline)

	local frameStrata = AceGUI:Create("Dropdown")
	frameStrata:SetRelativeWidth(0.25)
	frameStrata:SetList(SCM.Constants.FrameStrata, SCM.Constants.FrameStrataSorted)
	frameStrata:SetLabel("Frame Strata")
	frameStrata:SetValue(options.frameStrata or "")
	frameStrata:SetCallback("OnValueChanged", function(self, event, value)
		options.frameStrata = value ~= "" and value or nil
		RefreshCastBar()
	end)
	generalGroup:AddChild(frameStrata)

	local iconGroup = AceGUI:Create("InlineGroup")
	iconGroup:SetTitle("Icon")
	iconGroup:SetFullWidth(true)
	iconGroup:SetLayout("flow")
	scrollFrame:AddChild(iconGroup)

	local iconEnable = AceGUI:Create("CheckBox")
	iconEnable:SetRelativeWidth(0.5)
	iconEnable:SetLabel("Show Icon")
	iconEnable:SetValue(iconOptions.enable)
	iconGroup:AddChild(iconEnable)

	local matchBarHeight = AceGUI:Create("CheckBox")
	matchBarHeight:SetRelativeWidth(0.5)
	matchBarHeight:SetLabel("Match Cast Bar Height")
	matchBarHeight:SetValue(iconOptions.matchBarHeight)
	iconGroup:AddChild(matchBarHeight)

	local iconPosition = AceGUI:Create("Dropdown")
	iconPosition:SetRelativeWidth(0.33)
	iconPosition:SetLabel("Placement")
	iconPosition:SetList(ICON_POSITIONS)
	iconPosition:SetValue(iconOptions.position or "LEFT")
	iconPosition:SetCallback("OnValueChanged", function(_, _, value)
		iconOptions.position = value
		RefreshCastBar()
	end)
	iconGroup:AddChild(iconPosition)

	local iconSize = AceGUI:Create("Slider")
	iconSize:SetRelativeWidth(0.33)
	iconSize:SetLabel("Icon Size")
	iconSize:SetSliderValues(8, 80, 1)
	iconSize:SetValue(iconOptions.size or options.height or 24)
	iconSize:SetCallback("OnValueChanged", function(_, _, value)
		iconOptions.size = value
		RefreshCastBar()
	end)
	iconGroup:AddChild(iconSize)

	local iconZoom = AceGUI:Create("Slider")
	iconZoom:SetRelativeWidth(0.33)
	iconZoom:SetLabel("Icon Zoom")
	iconZoom:SetSliderValues(0, 0.49, 0.01)
	iconZoom:SetValue(iconOptions.zoom or 0.08)
	iconZoom:SetCallback("OnValueChanged", function(_, _, value)
		iconOptions.zoom = value
		RefreshCastBar()
	end)
	iconGroup:AddChild(iconZoom)

	iconEnable:SetCallback("OnValueChanged", function(_, _, value)
		iconOptions.enable = value
		UpdateIconControlStates(iconOptions, iconPosition, matchBarHeight, iconZoom, iconSize)
		RefreshCastBar()
	end)

	matchBarHeight:SetCallback("OnValueChanged", function(_, _, value)
		iconOptions.matchBarHeight = value
		UpdateIconControlStates(iconOptions, iconPosition, matchBarHeight, iconZoom, iconSize)
		RefreshCastBar()
	end)

	local tickGroup = AceGUI:Create("InlineGroup")
	tickGroup:SetTitle("Ticks")
	tickGroup:SetFullWidth(true)
	tickGroup:SetLayout("flow")
	scrollFrame:AddChild(tickGroup)

	local tickEnable = AceGUI:Create("CheckBox")
	tickEnable:SetRelativeWidth(0.33)
	tickEnable:SetLabel("Show Ticks")
	tickEnable:SetValue(tickOptions.enable)
	tickEnable:SetCallback("OnValueChanged", function(_, _, value)
		tickOptions.enable = value
		RefreshCastBar()
	end)
	tickGroup:AddChild(tickEnable)

	local tickColor = AceGUI:Create("ColorPicker")
	tickColor:SetRelativeWidth(0.33)
	tickColor:SetLabel("Tick Color")
	tickColor:SetHasAlpha(true)
	tickColor:SetColor(tickOptions.color.r, tickOptions.color.g, tickOptions.color.b, tickOptions.color.a)
	tickColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		tickOptions.color = { r = r, g = g, b = b, a = a }
		RefreshCastBar()
	end)
	tickGroup:AddChild(tickColor)

	local tickWidth = AceGUI:Create("Slider")
	tickWidth:SetRelativeWidth(0.33)
	tickWidth:SetLabel("Tick Width")
	tickWidth:SetSliderValues(1, 10, 0.1)
	tickWidth:SetValue(tickOptions.width)
	tickWidth:SetCallback("OnValueChanged", function(_, _, value)
		tickOptions.width = value
		RefreshCastBar()
	end)
	tickGroup:AddChild(tickWidth)

	local sparkGroup = AceGUI:Create("InlineGroup")
	sparkGroup:SetTitle("Spark")
	sparkGroup:SetFullWidth(true)
	sparkGroup:SetLayout("flow")
	scrollFrame:AddChild(sparkGroup)

	local sparkEnable = AceGUI:Create("CheckBox")
	sparkEnable:SetRelativeWidth(0.33)
	sparkEnable:SetLabel("Show Spark")
	sparkEnable:SetValue(sparkOptions.enable)
	sparkEnable:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.enable = value
		RefreshCastBar()
	end)
	sparkGroup:AddChild(sparkEnable)

	local sparkColor = AceGUI:Create("ColorPicker")
	sparkColor:SetRelativeWidth(0.33)
	sparkColor:SetLabel("Spark Color")
	sparkColor:SetHasAlpha(true)
	sparkColor:SetColor(sparkOptions.color.r, sparkOptions.color.g, sparkOptions.color.b, sparkOptions.color.a)
	sparkColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		sparkOptions.color = { r = r, g = g, b = b, a = a }
		RefreshCastBar()
	end)
	sparkGroup:AddChild(sparkColor)

	local blendMode = AceGUI:Create("Dropdown")
	blendMode:SetRelativeWidth(0.33)
	blendMode:SetList(SCM.Constants.BlendMode, SCM.Constants.BlendModeSorted)
	blendMode:SetLabel("Blend Mode")
	blendMode:SetValue(sparkOptions.blendMode)
	blendMode:SetCallback("OnValueChanged", function(self, event, value)
		sparkOptions.frameStrata = value
		RefreshCastBar()
	end)
	sparkGroup:AddChild(blendMode)

	local sparkWidth = AceGUI:Create("Slider")
	sparkWidth:SetRelativeWidth(0.25)
	sparkWidth:SetLabel("Spark Width")
	sparkWidth:SetSliderValues(1, 50, 0.1)
	sparkWidth:SetValue(sparkOptions.width)
	sparkWidth:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.width = value
		RefreshCastBar()
	end)
	sparkGroup:AddChild(sparkWidth)

	local sparkHeight = AceGUI:Create("Slider")
	sparkHeight:SetRelativeWidth(0.25)
	sparkHeight:SetLabel("Spark Height")
	sparkHeight:SetSliderValues(1, 80, 0.1)
	sparkHeight:SetValue(sparkOptions.height)
	sparkHeight:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.height = value
		RefreshCastBar()
	end)
	sparkGroup:AddChild(sparkHeight)

	local sparkXOffset = AceGUI:Create("Slider")
	sparkXOffset:SetRelativeWidth(0.25)
	sparkXOffset:SetLabel("Spark X-Offset")
	sparkXOffset:SetSliderValues(-20, 20, 0.1)
	sparkXOffset:SetValue(sparkOptions.xOffset)
	sparkXOffset:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.xOffset = value
		RefreshCastBar()
	end)
	sparkGroup:AddChild(sparkXOffset)

	local sparkYOffset = AceGUI:Create("Slider")
	sparkYOffset:SetRelativeWidth(0.25)
	sparkYOffset:SetLabel("Spark Y-Offset")
	sparkYOffset:SetSliderValues(-20, 20, 0.1)
	sparkYOffset:SetValue(sparkOptions.yOffset)
	sparkYOffset:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.yOffset = value
		RefreshCastBar()
	end)
	sparkGroup:AddChild(sparkYOffset)

	local useCustomTexture = AceGUI:Create("CheckBox")
	useCustomTexture:SetRelativeWidth(0.33)
	useCustomTexture:SetLabel("Use Custom Texture")
	useCustomTexture:SetValue(sparkOptions.useCustomTexture)

	sparkGroup:AddChild(useCustomTexture)

	local customTexture = AceGUI:Create("EditBox")
	customTexture:SetRelativeWidth(0.66)
	customTexture:SetLabel("Custom Texture")
	customTexture:SetText(sparkOptions.texture or "")
	customTexture:SetDisabled(not sparkOptions.useCustomTexture)
	customTexture:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
		GameTooltip:SetText("Custom Texture", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Supports LibSharedMedia names and interface paths.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	customTexture:SetCallback("OnLeave", function()
		GameTooltip:Hide()
	end)
	customTexture:SetCallback("OnEnterPressed", function(self, _, text)
		sparkOptions.texture = text
		self:SetText(sparkOptions.texture)
		RefreshCastBar()
	end)

	useCustomTexture:SetCallback("OnValueChanged", function(_, _, value)
		sparkOptions.useCustomTexture = value

		customTexture:SetDisabled(not value)
		RefreshCastBar()
	end)
	sparkGroup:AddChild(customTexture)

	local colorGroup = AceGUI:Create("InlineGroup")
	colorGroup:SetTitle("Colors")
	colorGroup:SetFullWidth(true)
	colorGroup:SetLayout("flow")
	scrollFrame:AddChild(colorGroup)

	local fillColor = AceGUI:Create("ColorPicker")
	fillColor:SetRelativeWidth(0.25)
	fillColor:SetLabel("Foreground Color")
	fillColor:SetHasAlpha(true)
	fillColor:SetColor(options.fgColor.r, options.fgColor.g, options.fgColor.b, options.fgColor.a)
	fillColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		options.fgColor = { r = r, g = g, b = b, a = a }
		RefreshCastBar()
	end)
	colorGroup:AddChild(fillColor)

	local bgColor = AceGUI:Create("ColorPicker")
	bgColor:SetRelativeWidth(0.25)
	bgColor:SetLabel("Background Color")
	bgColor:SetHasAlpha(true)
	bgColor:SetColor(options.bgColor.r, options.bgColor.g, options.bgColor.b, options.bgColor.a)
	bgColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		options.bgColor = { r = r, g = g, b = b, a = a }
		RefreshCastBar()
	end)
	colorGroup:AddChild(bgColor)

	local interruptColor = AceGUI:Create("ColorPicker")
	interruptColor:SetRelativeWidth(0.25)
	interruptColor:SetLabel("Interrupt Color")
	interruptColor:SetHasAlpha(true)
	interruptColor:SetColor(options.interruptColor.r, options.interruptColor.g, options.interruptColor.b, options.interruptColor.a)
	interruptColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		options.interruptColor = { r = r, g = g, b = b, a = a }
		RefreshCastBar()
	end)
	colorGroup:AddChild(interruptColor)

	local borderColor = AceGUI:Create("ColorPicker")
	borderColor:SetRelativeWidth(0.25)
	borderColor:SetLabel("Border Color")
	borderColor:SetHasAlpha(true)
	borderColor:SetColor(options.borderColor.r, options.borderColor.g, options.borderColor.b, options.borderColor.a)
	borderColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		options.borderColor = { r = r, g = g, b = b, a = a }
		RefreshCastBar()
	end)
	colorGroup:AddChild(borderColor)

	for i, color in ipairs(options.empoweredStageColors) do
		local stageIndex = i
		local stageColor = AceGUI:Create("ColorPicker")
		stageColor:SetRelativeWidth(0.2)
		stageColor:SetLabel("Empower " .. stageIndex)
		stageColor:SetHasAlpha(true)
		stageColor:SetColor(color.r, color.g, color.b, color.a)
		stageColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			options.empoweredStageColors[stageIndex] = { r = r, g = g, b = b, a = a }
			RefreshCastBar()
		end)
		colorGroup:AddChild(stageColor)
	end

	local useClassColor = AceGUI:Create("CheckBox")
	useClassColor:SetRelativeWidth(0.33)
	useClassColor:SetLabel("Use Class Color")
	useClassColor:SetValue(options.useClassColor)
	useClassColor:SetCallback("OnValueChanged", function(_, _, value)
		options.useClassColor = value
		RefreshCastBar()
	end)
	colorGroup:AddChild(useClassColor)

	local anchorsGroup = AceGUI:Create("InlineGroup")
	anchorsGroup:SetTitle("Anchors")
	anchorsGroup:SetFullWidth(true)
	anchorsGroup:SetLayout("flow")
	scrollFrame:AddChild(anchorsGroup)

	AddAnchorControls(anchorsGroup, "Cast Bar Anchor", options.anchors, RefreshCastBar)
	AddHeader(anchorsGroup, "Spell name and duration are anchored to the bar area inside the container.")
	AddCastBarTextAnchorControls(anchorsGroup, "Spell Name Anchor", options.spellName, function()
		SCM:RefreshCastBarLayout()
	end)
	AddCastBarTextAnchorControls(anchorsGroup, "Cast Duration Anchor", options.castDuration, function()
		SCM:RefreshCastBarLayout()
	end)

	UpdateIconControlStates(iconOptions, iconPosition, matchBarHeight, iconZoom, iconSize)
	scrollFrame:DoLayout()
	scrollFrame:FixScroll()
	scrollFrame:SetScroll(0)

	RunNextFrame(function()
		if scrollFrame and scrollFrame.scrollframe and scrollFrame.frame and scrollFrame.frame:IsShown() then
			scrollFrame:DoLayout()
			scrollFrame:FixScroll()
		end
	end)
end

SCM.MainTabs.CastBar.callback = CastBar
