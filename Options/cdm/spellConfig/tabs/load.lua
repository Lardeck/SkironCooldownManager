local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")
local LoadConditions = SCM.LoadConditions
local CONSTANTS = SCM.Constants.CHARACTER

local function GetDefaultLoadRaceNames()
	local loadedRaces = {}
	local raceNames = {}
	local raceIDs = {}

	for raceID, raceData in pairs(CONSTANTS.RACES) do
		local raceInfo = C_CreatureInfo.GetRaceInfo(raceID)

		if raceInfo then
			local raceName = raceInfo.clientFileString
			if raceName == "Scourge" then
				raceName = "Undead"
			end

			if type(raceData) == "table" then
				raceName = raceName .. " (" .. raceData.faction .. ")"
			end

			raceNames[raceID] = raceName

			local raceFile = string.lower(raceInfo.clientFileString)
			local maleAtlas = SCM.Utils.GetRaceAtlas(raceFile, "male")
			local femaleAtlas = SCM.Utils.GetRaceAtlas(raceFile, "female")
			local raceIcons = ""

			if C_Texture.GetAtlasInfo(maleAtlas) then
				raceIcons = CreateAtlasMarkup(maleAtlas, 16, 16) .. " "
			end

			if C_Texture.GetAtlasInfo(femaleAtlas) then
				raceIcons = raceIcons .. CreateAtlasMarkup(femaleAtlas, 16, 16) .. " "
			end

			loadedRaces[raceID] = raceIcons .. raceName
			tinsert(raceIDs, raceID)
		end
	end

	table.sort(raceIDs, function(raceIDA, raceIDB)
		return raceNames[raceIDA] < raceNames[raceIDB]
	end)

	return loadedRaces, raceIDs
end

function CDMOptions.CreateLoadTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	if buttonData.isCustom then
		local useLoadClass = AceGUI:Create("CheckBox")
		useLoadClass:SetLabel("Class")
		useLoadClass:SetRelativeWidth(0.5)
		useLoadClass:SetValue(buttonConfig.useLoadClass)
		iconSettingsTabs:AddChild(useLoadClass)

		local loadClass = AceGUI:Create("Dropdown")
		loadClass:SetRelativeWidth(0.5)
		loadClass:SetLabel("Classes")
		loadClass:SetList(SCM.Utils.GetClassList(false))
		loadClass:SetMultiselect(true)
		loadClass:SetDisabled(not buttonConfig.useLoadClass)
		loadClass:SetCallback("OnValueChanged", function(_, _, key, value)
			buttonConfig.loadClasses = buttonConfig.loadClasses or LoadConditions.GetDefaultLoadClasses()
			buttonConfig.loadClasses[key] = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)

		if not buttonConfig.loadClasses then
			buttonConfig.loadClasses = LoadConditions.GetDefaultLoadClasses()
		end

		for key, value in pairs(buttonConfig.loadClasses) do
			loadClass:SetItemValue(key, value)
		end

		useLoadClass:SetCallback("OnValueChanged", function(self, event, value)
			buttonConfig.useLoadClass = value or nil
			loadClass:SetDisabled(not value)
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)

		iconSettingsTabs:AddChild(loadClass)

		if not SCM.isForever then
			local useLoadRole = AceGUI:Create("CheckBox")
			useLoadRole:SetLabel("Role")
			useLoadRole:SetRelativeWidth(0.5)
			useLoadRole:SetValue(buttonConfig.useLoadRole)
			iconSettingsTabs:AddChild(useLoadRole)

			local loadRole = AceGUI:Create("Dropdown")
			loadRole:SetRelativeWidth(0.5)
			loadRole:SetLabel("Roles")
			loadRole:SetList(SCM.Constants.CHARACTER.ROLES)
			loadRole:SetMultiselect(true)
			loadRole:SetDisabled(not buttonConfig.useLoadRole)
			loadRole:SetCallback("OnValueChanged", function(_, _, key, value)
				buttonConfig.loadRoles = buttonConfig.loadRoles or {}
				buttonConfig.loadRoles[key] = value
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			if not buttonConfig.loadRoles then
				buttonConfig.loadRoles = { ["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false }
			end

			for key, value in pairs(buttonConfig.loadRoles) do
				loadRole:SetItemValue(key, value)
			end

			useLoadRole:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.useLoadRole = value or nil
				loadRole:SetDisabled(not value)
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			iconSettingsTabs:AddChild(loadRole)
		end
	end

	local useLoadRace = AceGUI:Create("CheckBox")
	useLoadRace:SetLabel("Race")
	useLoadRace:SetRelativeWidth(0.5)
	useLoadRace:SetValue(buttonConfig.useLoadRace)
	iconSettingsTabs:AddChild(useLoadRace)

	local loadRaces = AceGUI:Create("Dropdown")
	loadRaces:SetRelativeWidth(0.5)
	loadRaces:SetLabel("Races")
	loadRaces:SetList(GetDefaultLoadRaceNames())
	loadRaces:SetMultiselect(true)
	loadRaces:SetDisabled(not buttonConfig.useLoadRace)
	loadRaces:SetCallback("OnValueChanged", function(_, _, key, value)
		buttonConfig.loadRaces = buttonConfig.loadRaces or LoadConditions.GetDefaultLoadRaces()
		buttonConfig.loadRaces[key] = value

		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)

	if not buttonConfig.loadRaces then
		buttonConfig.loadRaces = LoadConditions.GetDefaultLoadRaces()
	end

	for key, value in pairs(buttonConfig.loadRaces) do
		loadRaces:SetItemValue(key, value)
	end

	useLoadRace:SetCallback("OnValueChanged", function(self, event, value)
		buttonConfig.useLoadRace = value or nil
		loadRaces:SetDisabled(not value)
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)

	iconSettingsTabs:AddChild(loadRaces)

	local useSpellKnown = AceGUI:Create("CheckBox")
	useSpellKnown:SetLabel(buttonConfig.useSpellKnown == nil and "|cFFFF0000Spell Not Known" or "Spell Known")
	useSpellKnown:SetRelativeWidth(0.5)
	useSpellKnown:SetValue(buttonConfig.useSpellKnown)
	useSpellKnown:SetTriState(true)
	iconSettingsTabs:AddChild(useSpellKnown)

	local loadSpellKnown = AceGUI:Create("EditBox")
	loadSpellKnown:SetRelativeWidth(0.5)
	loadSpellKnown:SetLabel("SpellID")
	loadSpellKnown:SetText(buttonConfig.spellKnownSpellID and tostring(buttonConfig.spellKnownSpellID) or "")
	loadSpellKnown:SetDisabled(buttonConfig.useSpellKnown == false)
	loadSpellKnown:SetCallback("OnEnterPressed", function(_, _, value)
		buttonConfig.spellKnownSpellID = tonumber(value)
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)

	useSpellKnown:SetCallback("OnValueChanged", function(self, event, value)
		buttonConfig.useSpellKnown = value

		if buttonConfig.useSpellKnown == nil then
			useSpellKnown:SetLabel("|cFFFF0000Spell Not Known")
		else
			useSpellKnown:SetLabel("Spell Known")
		end

		loadSpellKnown:SetDisabled(buttonConfig.useSpellKnown == false)
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)

	iconSettingsTabs:AddChild(loadSpellKnown)

	iconSettings:DoLayout()
	scrollFrame:DoLayout()
end
