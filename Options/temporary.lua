local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

SCM.MainTabs.Temporary = { value = "Temporary", text = "Temporary", order = 8, subgroups = {} }

local function Temporary(self, frame, group)
	local options = SCM.db.profile.options

	local generalFrame = AceGUI:Create("InlineGroup")
	generalFrame:SetLayout("flow")
	generalFrame:SetFullWidth(true)
	generalFrame:SetFullHeight(true)
	self:AddChild(generalFrame)

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText("|TInterface\\common\\help-i:40:40:0:0|tSome options will be removed once a better alternative has been found/made.")
	label:SetFontObject("Game12Font")
	generalFrame:AddChild(label)

	local uufSettings = AceGUI:Create("InlineGroup")
	uufSettings:SetFullWidth(true)
	uufSettings:SetLayout("flow")
	uufSettings:SetTitle("Unit Frames")
	generalFrame:AddChild(uufSettings)

	local anchorElvUI = AceGUI:Create("CheckBox")
	anchorElvUI:SetRelativeWidth(0.5)
	anchorElvUI:SetLabel("Reanchor ElvUI")
	anchorElvUI:SetValue(options.anchorElvUI)
	anchorElvUI:SetCallback("OnValueChanged", function(_, _, value)
		options.anchorElvUI = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	uufSettings:AddChild(anchorElvUI)

	local anchorElvUIRoles = AceGUI:Create("Dropdown")
	anchorElvUIRoles:SetRelativeWidth(0.5)
	anchorElvUIRoles:SetLabel("Reanchor ElvUI Roles")
	anchorElvUIRoles:SetList(SCM.Constants.Roles)
	anchorElvUIRoles:SetMultiselect(true)
	anchorElvUIRoles:SetCallback("OnValueChanged", function(_, _, key, value)
		options.anchorElvUIRoles[key] = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	for key, value in pairs(options.anchorElvUIRoles) do
		anchorElvUIRoles:SetItemValue(key, value)
	end
	uufSettings:AddChild(anchorElvUIRoles)

	local space = AceGUI:Create("Slider")
	space:SetRelativeWidth(0.5)
	space:SetValue(options.temporaryPadding)
	space:SetLabel("Space Offset")
	space:SetSliderValues(-50, 50, 0.1)
	space:SetCallback("OnValueChanged", function(_, _, value)
		options.temporaryPadding = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	uufSettings:AddChild(space)

	local adjustHeight = AceGUI:Create("CheckBox")
	adjustHeight:SetRelativeWidth(0.5)
	adjustHeight:SetLabel("Adjust Height")
	adjustHeight:SetValue(options.adjustHeight)
	adjustHeight:SetCallback("OnValueChanged", function(_, _, value)
		options.adjustHeight = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	adjustHeight:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
		GameTooltip:SetText("Adjust Height", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Disabling this options requires a reload. ElvUI users probably have to manually set their old height again.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	adjustHeight:SetCallback("OnLeave", function()
		GameTooltip:Hide()
	end)
	uufSettings:AddChild(adjustHeight)

	local heightOffset = AceGUI:Create("Slider")
	heightOffset:SetRelativeWidth(0.5)
	heightOffset:SetValue(options.anchorsHeightOffset)
	heightOffset:SetLabel("Height Offset")
	heightOffset:SetSliderValues(-50, 50, 0.1)
	heightOffset:SetCallback("OnValueChanged", function(_, _, value)
		options.anchorsHeightOffset = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	uufSettings:AddChild(heightOffset)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetValue(options.anchorsYOffset)
	xOffset:SetLabel("Y-Offset")
	xOffset:SetSliderValues(-50, 50, 0.1)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		options.anchorsYOffset = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	uufSettings:AddChild(xOffset)

	local resourceBarSettings = AceGUI:Create("InlineGroup")
	resourceBarSettings:SetLayout("flow")
	resourceBarSettings:SetFullWidth(true)
	resourceBarSettings:SetTitle("Resource Bar")
	generalFrame:AddChild(resourceBarSettings)

	local adjustResourceWidth = AceGUI:Create("CheckBox")
	adjustResourceWidth:SetRelativeWidth(0.5)
	adjustResourceWidth:SetLabel("Adjust Resource Bar Width")
	adjustResourceWidth:SetValue(options.adjustResourceWidth)
	adjustResourceWidth:SetCallback("OnValueChanged", function(_, _, value)
		options.adjustResourceWidth = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	resourceBarSettings:AddChild(adjustResourceWidth)

	local listContainer = AceGUI:Create("SimpleGroup")
	listContainer:SetLayout("flow")
	listContainer:SetFullWidth(true)

	local function RefreshList()
		listContainer:ReleaseChildren()

		for i, name in ipairs(options.resourceBars) do
			local row = AceGUI:Create("SimpleGroup")
			row:SetLayout("flow")
			row:SetFullWidth(true)
			listContainer:AddChild(row)

			local label = AceGUI:Create("Label")
			label:SetText(name)
			label:SetRelativeWidth(0.8)
			row:AddChild(label)

			local removeBtn = AceGUI:Create("Button")
			removeBtn:SetText("Delete")
			removeBtn:SetRelativeWidth(0.15)
			removeBtn:SetCallback("OnClick", function()
				table.remove(options.resourceBars, i)
				RefreshList()
			end)
			row:AddChild(removeBtn)
		end

		listContainer:DoLayout()
		resourceBarSettings:DoLayout()
		generalFrame:DoLayout()
	end

	local addResourceBarButton = AceGUI:Create("EditBox")
	addResourceBarButton:SetRelativeWidth(0.8)
	addResourceBarButton:SetLabel("Add Frame Name")
	addResourceBarButton:SetCallback("OnEnterPressed", function(self, _, value)
		if value and value ~= "" then
			table.insert(options.resourceBars, value)
			self:SetText("")
			RefreshList()
			SCM:ApplyAllCDManagerConfigs()
		end
	end)
	resourceBarSettings:AddChild(addResourceBarButton)
	resourceBarSettings:AddChild(listContainer)

	RefreshList()
end

SCM.MainTabs.Temporary.callback = Temporary
