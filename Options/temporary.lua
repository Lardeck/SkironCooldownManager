local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

SCM.MainTabs.Temporary = { value = "Temporary", text = "Custom Anchoring", order = 8, subgroups = {} }

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

	local ufSettings = AceGUI:Create("InlineGroup")
	ufSettings:SetFullWidth(true)
	ufSettings:SetLayout("flow")
	ufSettings:SetTitle("Unit Frames")
	generalFrame:AddChild(ufSettings)

	local anchorElvUI = AceGUI:Create("CheckBox")
	anchorElvUI:SetRelativeWidth(0.5)
	anchorElvUI:SetLabel("Reanchor ElvUI")
	anchorElvUI:SetValue(options.anchorElvUI)
	anchorElvUI:SetCallback("OnValueChanged", function(_, _, value)
		options.anchorElvUI = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	ufSettings:AddChild(anchorElvUI)

	local anchorElvUIRoles = AceGUI:Create("Dropdown")
	anchorElvUIRoles:SetRelativeWidth(0.5)
	anchorElvUIRoles:SetLabel("Reanchor ElvUI Roles")
	anchorElvUIRoles:SetList(SCM.Constants.CHARACTER.ROLES)
	anchorElvUIRoles:SetMultiselect(true)
	anchorElvUIRoles:SetCallback("OnValueChanged", function(_, _, key, value)
		options.anchorElvUIRoles[key] = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	for key, value in pairs(options.anchorElvUIRoles) do
		anchorElvUIRoles:SetItemValue(key, value)
	end
	ufSettings:AddChild(anchorElvUIRoles)

	local anchorEUI = AceGUI:Create("CheckBox")
	anchorEUI:SetRelativeWidth(0.5)
	anchorEUI:SetLabel("Reanchor EUI")
	anchorEUI:SetValue(options.anchorEUI)
	anchorEUI:SetCallback("OnValueChanged", function(_, _, value)
		options.anchorEUI = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	ufSettings:AddChild(anchorEUI)

	local anchorEUIRoles = AceGUI:Create("Dropdown")
	anchorEUIRoles:SetRelativeWidth(0.5)
	anchorEUIRoles:SetLabel("Reanchor EUI Roles")
	anchorEUIRoles:SetList(SCM.Constants.CHARACTER.ROLES)
	anchorEUIRoles:SetMultiselect(true)
	anchorEUIRoles:SetCallback("OnValueChanged", function(_, _, key, value)
		options.anchorEUIRoles[key] = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	for key, value in pairs(options.anchorEUIRoles) do
		anchorEUIRoles:SetItemValue(key, value)
	end
	ufSettings:AddChild(anchorEUIRoles)

	local space = AceGUI:Create("Slider")
	space:SetRelativeWidth(0.5)
	space:SetValue(options.temporaryPadding)
	space:SetLabel("Space Offset")
	space:SetSliderValues(-50, 50, 0.1)
	space:SetCallback("OnValueChanged", function(_, _, value)
		options.temporaryPadding = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	ufSettings:AddChild(space)

	-- local adjustHeight = AceGUI:Create("CheckBox")
	-- adjustHeight:SetRelativeWidth(0.5)
	-- adjustHeight:SetLabel("Adjust Height")
	-- adjustHeight:SetValue(options.adjustHeight)
	-- adjustHeight:SetCallback("OnValueChanged", function(_, _, value)
	-- 	options.adjustHeight = value
	-- 	SCM:ApplyAllCDManagerConfigs()
	-- end)
	-- adjustHeight:SetCallback("OnEnter", function()
	-- 	GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
	-- 	GameTooltip:SetText("Adjust Height", nil, nil, nil, nil, true)
	-- 	GameTooltip:AddLine("Disabling this options requires a reload. ElvUI users probably have to manually set their old height again.", 1, 1, 1, true)
	-- 	GameTooltip:Show()
	-- end)
	-- adjustHeight:SetCallback("OnLeave", function()
	-- 	GameTooltip:Hide()
	-- end)
	-- uufSettings:AddChild(adjustHeight)
-- 
	-- local heightOffset = AceGUI:Create("Slider")
	-- heightOffset:SetRelativeWidth(0.5)
	-- heightOffset:SetValue(options.anchorsHeightOffset)
	-- heightOffset:SetLabel("Height Offset")
	-- heightOffset:SetSliderValues(-50, 50, 0.1)
	-- heightOffset:SetCallback("OnValueChanged", function(_, _, value)
	-- 	options.anchorsHeightOffset = value
	-- 	SCM:ApplyAllCDManagerConfigs()
	-- end)
	-- uufSettings:AddChild(heightOffset)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.5)
	xOffset:SetValue(options.anchorsYOffset)
	xOffset:SetLabel("Y-Offset")
	xOffset:SetSliderValues(-50, 50, 0.1)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		options.anchorsYOffset = value
		SCM:ApplyAllCDManagerConfigs()
	end)
	ufSettings:AddChild(xOffset)

	local groupLootSettings = AceGUI:Create("InlineGroup")
	groupLootSettings:SetLayout("flow")
	groupLootSettings:SetFullWidth(true)
	groupLootSettings:SetTitle("Group Loot")
	generalFrame:AddChild(groupLootSettings)

	local canPositionGroupLoot = SCM.CanPositionGroupLoot()
	local groupLootAnchor = AceGUI:Create("CheckBox")
	groupLootAnchor:SetRelativeWidth(0.5)
	groupLootAnchor:SetLabel(canPositionGroupLoot and "Enable Group Loot Anchor" or "Group Loot Anchor (managed by ElvUI)")
	groupLootAnchor:SetValue(canPositionGroupLoot and options.groupLootAnchor.enabled)
	groupLootAnchor:SetDisabled(not canPositionGroupLoot)
	groupLootAnchor:SetCallback("OnValueChanged", function(_, _, value)
		if value then
			options.groupLootAnchor.enabled = true
			SCM:ApplyGroupLootAnchor()
			return
		end

		SCM.ShowReloadPopup({
			checkbox = groupLootAnchor,
			options = options.groupLootAnchor,
			key = "enabled",
			value = false,
		})
	end)
	groupLootSettings:AddChild(groupLootAnchor)

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
