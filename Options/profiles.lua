local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

SCM.MainTabs.Profiles = { value = "Profiles", text = "Profiles", order = 9, subgroups = {} }

local profileIncludeOptions = {
	{ key = "includeResourceBar", label = "Resource Bar Settings" },
	{ key = "includeCastBar", label = "Cast Bar Settings" },
	{ key = "includeGlobalSettings", label = "Global Settings" },
	{ key = "includeGlobalAnchors", label = "Global Icon Anchors" },
}

local function CreateProfileOptionControls(parent, state, onRefresh)
	local RefreshControls

	local specificClassCheckbox = AceGUI:Create("CheckBox")
	specificClassCheckbox:SetLabel("Class")
	specificClassCheckbox:SetRelativeWidth(0.5)
	specificClassCheckbox:SetValue(state.useSpecificClass)
	parent:AddChild(specificClassCheckbox)

	local classDropdown = AceGUI:Create("Dropdown")
	classDropdown:SetLabel("Select Class")
	classDropdown:SetList(SCM.Utils.GetClassList(true))
	classDropdown:SetRelativeWidth(0.5)
	classDropdown:SetDisabled(true)
	classDropdown.text:SetJustifyH("LEFT")
	classDropdown:SetValue(state.selectedClass)
	parent:AddChild(classDropdown)

	local specificSpecCheckbox = AceGUI:Create("CheckBox")
	specificSpecCheckbox:SetLabel("Specific Spec")
	specificSpecCheckbox:SetRelativeWidth(0.5)
	specificSpecCheckbox:SetValue(state.useSpecificSpec)
	specificSpecCheckbox:SetDisabled(true)
	parent:AddChild(specificSpecCheckbox)

	local specDropdown = AceGUI:Create("Dropdown")
	specDropdown:SetLabel("Select Spec")
	specDropdown:SetList({})
	specDropdown:SetRelativeWidth(0.5)
	specDropdown:SetDisabled(true)
	specDropdown.text:SetJustifyH("LEFT")
	specDropdown:SetValue(state.selectedSpec)
	parent:AddChild(specDropdown)

	for _, option in ipairs(profileIncludeOptions) do
		local checkbox = AceGUI:Create("CheckBox")
		checkbox:SetLabel(option.label)
		checkbox:SetRelativeWidth(0.25)
		checkbox:SetValue(state[option.key])
		parent:AddChild(checkbox)

		checkbox:SetCallback("OnValueChanged", function(_, _, value)
			state[option.key] = value
			RefreshControls()
		end)
	end

	RefreshControls = function()
		state.selectedClass = classDropdown:GetValue()
		local hasSpecificClass = state.useSpecificClass and state.selectedClass ~= nil
		local filteredSpecs = hasSpecificClass and SCM.Utils.GetSpecList(state.selectedClass) or {}
		local hasSpecs = next(filteredSpecs) ~= nil

		classDropdown:SetDisabled(not state.useSpecificClass)
		specificSpecCheckbox:SetDisabled(not hasSpecificClass or not hasSpecs)

		if (not hasSpecificClass or not hasSpecs) and state.useSpecificSpec then
			state.useSpecificSpec = false
			specificSpecCheckbox:SetValue(false)
		end

		specDropdown:SetList(filteredSpecs)
		if not filteredSpecs[specDropdown:GetValue()] then
			specDropdown:SetValue(nil)
		end
		state.selectedSpec = specDropdown:GetValue()
		specDropdown:SetDisabled(not state.useSpecificSpec or not hasSpecs)

		if onRefresh then
			onRefresh(state)
		end
	end

	specificClassCheckbox:SetCallback("OnValueChanged", function(_, _, value)
		state.useSpecificClass = value
		if not value then
			state.useSpecificSpec = false
			state.selectedSpec = nil
			specificSpecCheckbox:SetValue(false)
			specDropdown:SetValue(nil)
		end
		RefreshControls()
	end)

	classDropdown:SetCallback("OnValueChanged", function(_, _, value)
		if not state.useSpecificClass then
			return
		end

		state.selectedClass = value
		state.selectedSpec = nil
		specDropdown:SetValue(nil)
		RefreshControls()
	end)

	specificSpecCheckbox:SetCallback("OnValueChanged", function(_, _, value)
		state.useSpecificSpec = value
		if not value then
			state.selectedSpec = nil
			specDropdown:SetValue(nil)
		end
		RefreshControls()
	end)

	specDropdown:SetCallback("OnValueChanged", function(_, _, value)
		state.selectedSpec = value
		RefreshControls()
	end)

	RefreshControls()

	return RefreshControls
end

local function CreateImportEditBox(Profiles, widget, frame, group)
	widget:ReleaseChildren()

	local importSettings = {
		useSpecificClass = true,
		useSpecificSpec = false,
		selectedClass = "ALL",
		includeResourceBar = true,
		includeCastBar = true,
		includeGlobalSettings = true,
		includeGlobalAnchors = true,
	}

	local importGroup = AceGUI:Create("InlineGroup")
	importGroup:SetFullWidth(true)
	importGroup:SetFullHeight(true)
	importGroup:SetLayout("flow")
	widget:AddChild(importGroup)

	local profileName = AceGUI:Create("EditBox")
	profileName:SetFullWidth(true)
	profileName:SetLabel("Profile Name (Optional)")
	importGroup:AddChild(profileName)

	CreateProfileOptionControls(importGroup, importSettings)

	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:SetFullWidth(true)
	editBox:SetFullHeight(true)
	editBox:SetLabel("Import")
	editBox:SetFocus()
	editBox.editBox:HighlightText()
	editBox.editBox:SetScript("OnEscapePressed", function()
		Profiles(widget, frame, group)
	end)

	editBox.frame:SetClipsChildren(true)
	importGroup:AddChild(editBox)

	return editBox, profileName, importSettings
end

local function CreateExportEditBox(Profiles, widget, frame, group, exportString)
	if not exportString then
		return
	end

	widget:ReleaseChildren()

	local editGroup = AceGUI:Create("InlineGroup")
	editGroup:SetFullWidth(true)
	editGroup:SetFullHeight(true)
	editGroup:SetLayout("fill")
	widget:AddChild(editGroup)

	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:SetLabel("Export")
	editBox:SetText(exportString)
	editBox:SetFocus()
	editBox.editBox:HighlightText()
	editBox.editBox:SetScript("OnEscapePressed", function()
		Profiles(widget, frame, group)
	end)
	editBox.button:Hide()
	editBox.frame:SetClipsChildren(true)
	editGroup:AddChild(editBox)
end

local function Profiles(widget, frame, group)
	widget:ReleaseChildren()

	local profilesGroup = AceGUI:Create("InlineGroup")
	profilesGroup:SetFullWidth(true)
	profilesGroup:SetFullHeight(true)
	profilesGroup:SetLayout("flow")
	widget:AddChild(profilesGroup)

	local importGroup = AceGUI:Create("InlineGroup")
	importGroup:SetTitle("Import")
	importGroup:SetFullWidth(true)
	importGroup:SetLayout("flow")
	profilesGroup:AddChild(importGroup)

	local importButton = AceGUI:Create("Button")
	importButton:SetText("Import")
	importButton:SetRelativeWidth(1)
	importButton:SetCallback("OnClick", function()
		local editBox, profileName, importSettings = CreateImportEditBox(Profiles, widget, frame, group)
		editBox:SetCallback("OnEnterPressed", function(self, event, text)
			SCM:ImportProfile(profileName:GetText(), text, importSettings)
			Profiles(widget, frame, group)
		end)
	end)
	importGroup:AddChild(importButton)

	local exportGroup = AceGUI:Create("InlineGroup")
	exportGroup:SetTitle("Export Profile")
	exportGroup:SetFullWidth(true)
	exportGroup:SetLayout("flow")
	profilesGroup:AddChild(exportGroup)

	local exportState = {
		useSpecificClass = false,
		useSpecificSpec = false,
		includeResourceBar = false,
		includeCastBar = false,
		includeGlobalSettings = false,
		includeGlobalAnchors = false,
	}

	local exportButton
	local refreshExportControls = CreateProfileOptionControls(exportGroup, exportState, function(state)
		if not exportButton then
			return
		end

		local hasSpecificClass = state.useSpecificClass and state.selectedClass ~= nil
		local hasOptions = state.includeResourceBar or state.includeCastBar or state.includeGlobalSettings or state.includeGlobalAnchors
		exportButton:SetDisabled((state.useSpecificClass and not state.selectedClass) or (state.useSpecificSpec and not state.selectedSpec) or (not hasSpecificClass and not hasOptions))
	end)

	exportButton = AceGUI:Create("Button")
	exportButton:SetText("Export")
	exportButton:SetRelativeWidth(1)
	exportButton:SetCallback("OnClick", function()
		local selectedClass = exportState.useSpecificClass and exportState.selectedClass or nil
		local selectedSpec = exportState.useSpecificSpec and exportState.selectedSpec or nil
		CreateExportEditBox(
			Profiles,
			widget,
			frame,
			group,
			SCM:ExportProfile(selectedClass, selectedSpec, {
				includeResourceBar = exportState.includeResourceBar,
				includeCastBar = exportState.includeCastBar,
				includeGlobalSettings = exportState.includeGlobalSettings,
				includeGlobalAnchors = exportState.includeGlobalAnchors,
			})
		)
	end)
	exportGroup:AddChild(exportButton)
	refreshExportControls()

	local dbOptionsGroup = AceGUI:Create("InlineGroup")
	dbOptionsGroup:SetTitle("Profile Management")
	dbOptionsGroup:SetFullWidth(true)
	dbOptionsGroup:SetLayout("fill")
	profilesGroup:AddChild(dbOptionsGroup)

	local profileOptions = AceDBOptions:GetOptionsTable(SCM.db)
	SCM.LibDualSpec:EnhanceOptions(profileOptions, SCM.db)
	AceConfig:RegisterOptionsTable("SCM_Profiles_OptionTable", profileOptions)
	AceConfigDialog:Open("SCM_Profiles_OptionTable", dbOptionsGroup)
end

SCM.MainTabs.Profiles.callback = Profiles
