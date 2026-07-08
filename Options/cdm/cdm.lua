local SCM = select(2, ...)
local Options = SCM.Options

Options.CDM = {}
local CDMOptions = Options.CDM

local AceGUI = LibStub("AceGUI-3.0")
local Utils = SCM.Utils

SCM.MainTabs.CDM = { value = "CDM", text = "Cooldown Manager", order = 2, subgroups = {} }

local function GetSpellAnchorGroupConfig(order, sourceIndex)
	if sourceIndex ~= Enum.CooldownViewerCategory.TrackedBuff and sourceIndex ~= num.CooldownViewerCategory.TrackedBars then
		return {
			order = order,
		}
	end

	return {
		order = order,
		usedStates = {
			active = true,
			inactive = true,
		},
		selectedStates = { "active", "inactive" },
		stateOptions = {
			active = {
				selectedOptions = { "visibility" },
				visibility = {
					value = "show",
				},
			},
			inactive = {
				selectedOptions = { "visibility" },
				visibility = {
					value = "hide",
				},
			},
		},
	}
end

function SCM:AddSpellToConfig(anchorGroup, order, info, displayData, sourceIndex)
	local spellID = displayData.spellID
	if displayData.linkedSpellIDs and #displayData.linkedSpellIDs == 1 then
		spellID = displayData.linkedSpellIDs[1]
	end

	local effectiveAnchorGroup = anchorGroup
	if sourceIndex == Enum.CooldownViewerCategory.TrackedBar then
		effectiveAnchorGroup = Utils.NormalizeBuffBarGroup(anchorGroup)
		if not effectiveAnchorGroup then
			return
		end
	end

	local cooldownID = displayData.cooldownID or info.cooldownID
	local configID = Utils.GetCooldownConfigKey(cooldownID)
	if not configID then
		return
	end

	if not self.spellConfig[configID] then
		self.spellConfig[configID] = {
			spellID = spellID,
			cooldownID = cooldownID,
			source = {
				[sourceIndex] = effectiveAnchorGroup,
			},
			anchorGroup = {
				[effectiveAnchorGroup] = GetSpellAnchorGroupConfig(order, sourceIndex),
			},
		}
	else
		self.spellConfig[configID].spellID = spellID
		self.spellConfig[configID].cooldownID = cooldownID or self.spellConfig[configID].cooldownID
		self.spellConfig[configID].source[sourceIndex] = effectiveAnchorGroup
		self.spellConfig[configID].anchorGroup[effectiveAnchorGroup] = GetSpellAnchorGroupConfig(order, sourceIndex)
	end
end

function SCM:RemoveSpellFromConfig(anchorIndex, data)
	local configID = data.id or Utils.GetCooldownConfigKey(data.cooldownID)
	local spellConfig = configID and self.spellConfig[configID]
	if spellConfig then
		for category, anchorGroup in pairs(spellConfig.source) do
			if anchorGroup == anchorIndex then
				spellConfig.source[category] = nil
			end
		end

		spellConfig.anchorGroup[anchorIndex] = nil

		if not next(spellConfig.anchorGroup) then
			self.spellConfig[configID] = nil
		end
	end
end

function CDMOptions.IsSpellInData(cooldownID, source)
	local configID = Utils.GetCooldownConfigKey(cooldownID)
	local spellConfig = configID and SCM.spellConfig[configID]
	local pairedSource = Utils.GetPairedSource(source)
	return spellConfig and (spellConfig.source[source] or (pairedSource and spellConfig.source[pairedSource]))
end

function CDMOptions.ShowIconSettingsMessage(parentWidget, scrollFrame, message)
	--parentWidget:SetTitle("")

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText(message)
	label:SetFontObject("Game12Font")
	parentWidget:AddChild(label)

	parentWidget:DoLayout()
	scrollFrame:DoLayout()
end

local function CDM(self, frame, group)
	local modeTabs = AceGUI:Create("TabGroup")
	modeTabs:SetLayout("fill")
	modeTabs:SetFullWidth(true)
	modeTabs:SetFullHeight(true)

	local tabs = {
		{ value = "spec", text = "|cFFFFFFFFSpecialization|r: Icons" },
		{ value = "buffbars", text = "|cFFFFFFFFSpecialization|r: Bars" },
		{ value = "global", text = "|cFFFFFFFFGlobal|r: Icons" },
		{ value = "copy", text = "|cFFFFFFFFCopy|r Anchors" },
	}

	modeTabs:SetTabs(tabs)
	modeTabs:SetCallback("OnGroupSelected", function(widget, event, mode)
		if mode == "copy" then
			CDMOptions.CreateCopyAnchorTab(widget, frame, modeTabs)
		else
			CDMOptions.CreateAnchorTabGroup(widget, frame, mode)
		end
	end)
	self:AddChild(modeTabs)
	modeTabs:SelectTab("spec")

	self.typeTab = modeTabs
end

SCM.MainTabs.CDM.callback = CDM
