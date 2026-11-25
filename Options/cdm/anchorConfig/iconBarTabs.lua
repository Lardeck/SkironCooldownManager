local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local Utils = SCM.Utils
local ToGlobalGroup = Utils.ToGlobalGroup
local ToBuffBarGroup = Utils.ToBuffBarGroup
local AceGUI = LibStub("AceGUI-3.0")

StaticPopupDialogs["SCM_RENAME_ANCHOR"] = {
	text = "New Anchor Name",
	button1 = "Rename",
	button2 = "Cancel",
	OnAccept = function(self, data)
		if data and data.callback then
			data.callback(self.EditBox:GetText())
		end
	end,
	EditBoxOnEnterPressed = function(self)
		if self:GetParent():GetButton1():IsEnabled() then
			self:GetParent():GetButton1():Click()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	hasEditBox = true,
}

function SCM:AddGlobalAnchor(anchorTabsTbl)
	local anchorConfig = self.db.profile.globalAnchorConfig
	local nextIndex = #anchorConfig + 1
	anchorConfig[nextIndex] = {
		anchor = { "CENTER", "UIParent", "CENTER", 0, 0 },
		rowConfig = {
			[1] = {
				size = 40,
				limit = 8,
			},
		},
	}
	self:InvalidateAnchorLinks()
	tinsert(anchorTabsTbl, { value = nextIndex, text = "Anchor G" .. nextIndex })
	SCM:ApplyAllCDManagerConfigs()
	return nextIndex
end

function SCM:AddBuffBarAnchor(anchorTabsTbl)
	local anchorConfig = self.buffBarsAnchorConfig
	local nextIndex = #anchorConfig + 1
	anchorConfig[nextIndex] = {
		useGlobalProfileConfig = true,
		anchor = { "CENTER", "UIParent", "CENTER", 0, 0 },
		rowConfig = {
			[1] = {
				iconWidth = 150,
				iconHeight = 40,
				limit = 8,
			},
		},
	}
	Utils.EnsureProfileAnchorConfig(self.db.profile.options, "buffBarsAnchorConfig", nextIndex, anchorConfig[nextIndex])
	self:InvalidateAnchorLinks()
	tinsert(anchorTabsTbl, { value = nextIndex, text = "Anchor B" .. nextIndex })
	SCM:ApplyBuffBarCDManagerConfig()
	return nextIndex
end

local function RemoveDeletedAnchorCustomConfig(configTable, anchorIndex)
	if type(configTable) ~= "table" then
		return
	end

	for id, config in pairs(configTable) do
		if config.anchorGroup == anchorIndex then
			SCM.CustomIcons.ReleaseIcon(id, config)
			configTable[id] = nil
		elseif config.anchorGroup and config.anchorGroup > anchorIndex then
			config.anchorGroup = config.anchorGroup - 1
		end
	end
end

function SCM:RemoveGlobalAnchor(anchorIndex, anchorTabsTbl)
	if self.db.profile.globalAnchorConfig[anchorIndex] then
		tremove(self.db.profile.globalAnchorConfig, anchorIndex)
	end

	local globalAnchorIndex = ToGlobalGroup(#anchorTabsTbl)
	self.anchorFrames[globalAnchorIndex]:Hide()

	for _, globalConfig in pairs({
		self.db.profile.globalCustomConfig.spellConfig,
		self.db.profile.globalCustomConfig.itemConfig,
		self.db.profile.globalCustomConfig.slotConfig,
		self.db.profile.globalCustomConfig.timerConfig,
	}) do
		RemoveDeletedAnchorCustomConfig(globalConfig, anchorIndex)
	end

	for i = #anchorTabsTbl, 1, -1 do
		if anchorTabsTbl[i].value == anchorIndex then
			tremove(anchorTabsTbl, i)
		end
	end
	for i, tab in ipairs(anchorTabsTbl) do
		local anchorName = self.db.profile.globalAnchorConfig[i].anchorName
		local anchorPrefix = "G" .. i
		local anchorLabel = "Anchor " .. anchorPrefix
		if anchorName then
			anchorLabel = anchorPrefix .. " " .. anchorName
		end
		tab.value = i
		tab.text = anchorLabel
	end

	self:InvalidateAnchorLinks()
	SCM:ApplyAllCDManagerConfigs()
end

function SCM:RemoveBuffBarAnchor(anchorIndex, anchorTabsTbl)
	local oldAnchorCount = #self.buffBarsAnchorConfig
	if self.buffBarsAnchorConfig[anchorIndex] then
		tremove(self.buffBarsAnchorConfig, anchorIndex)
	end

	local removedGroup = ToBuffBarGroup(anchorIndex)
	local buffBarAnchorFrame = self.anchorFrames[ToBuffBarGroup(#anchorTabsTbl)]
	if buffBarAnchorFrame then
		buffBarAnchorFrame:Hide()
	end

	for configID, config in pairs(self.spellConfig) do
		local trackedBarGroup = config.source and config.source[Enum.CooldownViewerCategory.TrackedBar]
		if trackedBarGroup == removedGroup then
			config.source[Enum.CooldownViewerCategory.TrackedBar] = nil
			config.anchorGroup[removedGroup] = nil

			if not next(config.anchorGroup) then
				self.spellConfig[configID] = nil
			end
		elseif trackedBarGroup and Utils.IsBuffBarGroup(trackedBarGroup) and trackedBarGroup > removedGroup and trackedBarGroup <= ToBuffBarGroup(oldAnchorCount) then
			local newGroup = trackedBarGroup - 1
			config.source[Enum.CooldownViewerCategory.TrackedBar] = newGroup
			config.anchorGroup[newGroup] = config.anchorGroup[trackedBarGroup]
			config.anchorGroup[trackedBarGroup] = nil
		elseif trackedBarGroup and Utils.IsBuffBarGroup(trackedBarGroup) and not self.buffBarsAnchorConfig[trackedBarGroup - 200] then
			config.source[Enum.CooldownViewerCategory.TrackedBar] = nil
			config.anchorGroup[trackedBarGroup] = nil

			if not next(config.anchorGroup) then
				self.spellConfig[configID] = nil
			end
		end
	end

	for i = #anchorTabsTbl, 1, -1 do
		if anchorTabsTbl[i].value == anchorIndex then
			tremove(anchorTabsTbl, i)
		end
	end
	for i, tab in ipairs(anchorTabsTbl) do
		local anchorConfig = Utils.GetAnchorConfigForGroup(self.currentConfig, i, nil, true)
		local anchorName = anchorConfig and anchorConfig.anchorName
		local anchorPrefix = "B" .. i
		local anchorLabel = "Anchor " .. anchorPrefix
		if anchorName then
			anchorLabel = anchorPrefix .. " " .. anchorName
		end
		tab.value = i
		tab.text = anchorLabel
	end

	self:InvalidateAnchorLinks()
	SCM:ApplyBuffBarCDManagerConfig()
end

function SCM:AddAnchor(anchorTabsTbl)
	local nextIndex = #self.anchorConfig + 1
	self.anchorConfig[nextIndex] = {
		useGlobalProfileConfig = true,
		anchor = { "CENTER", "UIParent", "CENTER", 0, 0 },
		rowConfig = {
			[1] = {
				size = 40,
				limit = 8,
			},
		},
	}
	Utils.EnsureProfileAnchorConfig(self.db.profile.options, "anchorConfig", nextIndex, self.anchorConfig[nextIndex])

	tinsert(anchorTabsTbl, { value = nextIndex, text = "Anchor " .. nextIndex })
	table.sort(anchorTabsTbl, function(a, b)
		return a.value < b.value
	end)

	self:InvalidateAnchorLinks()
	SCM:ApplyAllCDManagerConfigs()

	return nextIndex
end

function SCM:RemoveAnchor(anchorIndex, anchorTabsTbl)
	local oldAnchorCount = #self.anchorConfig
	if self.anchorConfig[anchorIndex] then
		tremove(self.anchorConfig, anchorIndex)
	end

	local removedIndex
	for i, tab in ipairs(anchorTabsTbl) do
		if tab.value == anchorIndex then
			removedIndex = i
			tremove(anchorTabsTbl, i)
			break
		end
	end

	for i = removedIndex, #anchorTabsTbl do
		local anchorConfig = Utils.GetAnchorConfigForGroup(self.currentConfig, i)
		local anchorName = anchorConfig and anchorConfig.anchorName
		local anchorLabel = "Anchor " .. i
		if anchorName then
			anchorLabel = i .. " " .. anchorName
		end
		anchorTabsTbl[i].value = i
		anchorTabsTbl[i].text = anchorLabel
	end

	self.anchorFrames[oldAnchorCount]:Hide()

	for spellID, config in pairs(self.spellConfig) do
		for sourceIndex, anchorGroup in pairs(config.source) do
			if not Utils.IsBuffBarGroup(anchorGroup) and anchorGroup == anchorIndex then
				config.source[sourceIndex] = nil
				config.anchorGroup[anchorGroup] = nil

				if not next(config.source) then
					self.spellConfig[spellID] = nil
				end
			elseif not Utils.IsBuffBarGroup(anchorGroup) and anchorGroup > anchorIndex then
				config.source[sourceIndex] = anchorGroup - 1
				if config.anchorGroup[anchorGroup] then
					config.anchorGroup[anchorGroup - 1] = config.anchorGroup[anchorGroup]
					config.anchorGroup[anchorGroup] = nil
				end
			end
		end
	end

	for _, customConfig in pairs({
		self.customConfig.spellConfig,
		self.customConfig.itemConfig,
		self.customConfig.slotConfig,
		self.customConfig.timerConfig,
	}) do
		RemoveDeletedAnchorCustomConfig(customConfig, anchorIndex)
	end

	self:InvalidateAnchorLinks()
	SCM:ApplyAllCDManagerConfigs()

	return removedIndex
end

function CDMOptions.CreateAnchorTabGroup(parent, frame, mode)
	parent:ReleaseChildren()

	local options = SCM.db.profile.options

	local isGlobal = mode == "global"
	local isBuffBar = mode == "buffbars"

	local anchorTabs = AceGUI:Create("TabGroup")
	anchorTabs:SetLayout("fill")
	anchorTabs:SetFullWidth(true)
	anchorTabs:SetFullHeight(true)
	anchorTabs.frame:SetPoint("TOPLEFT", parent.frame, "TOPLEFT", 0, -30)
	anchorTabs.frame:SetPoint("BOTTOMRIGHT", parent.frame, "BOTTOMRIGHT", 0, -5)
	anchorTabs.frame:SetParent(parent.frame)
	anchorTabs.frame:Show()

	local configKey = isBuffBar and "buffBarsAnchorConfig" or "anchorConfig"
	local sourceConfig = isGlobal and SCM.globalAnchorConfig or SCM[configKey]
	local anchorTabsTbl = {}
	for i, anchorConfig in ipairs(sourceConfig) do
		local anchorPrefix = (isGlobal and "G" .. i) or (isBuffBar and "B" .. i) or i
		if not isGlobal and anchorConfig.useGlobalProfileConfig then
			Utils.EnsureProfileAnchorConfig(options, configKey, i, anchorConfig)
			anchorConfig = options[configKey][i]
		end

		local anchorName = anchorConfig.anchorName
		local anchorLabel = ((isGlobal or isBuffBar) and ("Anchor " .. anchorPrefix)) or ("Anchor " .. i)
		if anchorName then
			anchorLabel = anchorPrefix .. " " .. anchorName
		end
		tinsert(anchorTabsTbl, { value = i, text = anchorLabel })
	end

	anchorTabs:SetTabs(anchorTabsTbl)
	anchorTabs:SetCallback("OnGroupSelected", function(self, event, anchorIndex)
		CDMOptions.SelectAnchor(self, parent, anchorIndex, anchorTabsTbl, mode)
	end)
	parent:AddChild(anchorTabs)
	anchorTabs:SelectTab(1)
end
