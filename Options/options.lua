local addonName, SCM = ...

local AceGUI = LibStub("AceGUI-3.0")
local LibEditModeOverride = LibStub("LibEditModeOverride-1.0")
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local LibWindow = LibStub("LibWindow-1.1")
local Options = SCM.Options
local Utils = SCM.Utils
local ToGlobalGroup = Utils.ToGlobalGroup
local ToBuffBarGroup = Utils.ToBuffBarGroup
local GetCooldownConfigKey = Utils.GetCooldownConfigKey
local UPDATE_SCOPE = SCM.CDM.UPDATE_SCOPE

StaticPopupDialogs["SCM_FORCE_RELOAD_POPUP"] = {
	text = "This requires a UI reload. Reload now?",
	button1 = RELOADUI,
	button2 = CANCEL,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(_, data)
		data.options[data.key] = data.value
		C_UI.Reload()
	end,
	OnCancel = function(_, data)
		if data.checkbox and data.key then
			data.checkbox:SetValue(data.options[data.key])
		end
	end,
}

function SCM.ShowReloadPopup(data)
	StaticPopup_Show("SCM_FORCE_RELOAD_POPUP", nil, nil, data)
end

function SCM.Encode(table)
	local serialized = C_EncodingUtil.SerializeCBOR(table)
	local compressed = C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.OptimizeForSize)
	local encoded = C_EncodingUtil.EncodeBase64(compressed)
	return encoded
end

function SCM.Decode(importString)
	local decoded = C_EncodingUtil.DecodeBase64(importString)
	local decompressed = C_EncodingUtil.DecompressString(decoded)
	local data = C_EncodingUtil.DeserializeCBOR(decompressed)

	return data
end

function Options.GetEffectiveAnchorGroup(anchorIndex, mode)
	if mode == "global" then
		return ToGlobalGroup(anchorIndex)
	end

	if mode == "buffbars" then
		return ToBuffBarGroup(anchorIndex)
	end

	return anchorIndex
end

function Options.ApplyModeConfigUpdate(anchorIndex, mode)
	if mode == "global" then
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, true)
	elseif mode == "buffbars" then
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, false, UPDATE_SCOPE.BUFF_BAR)
	else
		SCM:ApplyAllCDManagerConfigs(true)
	end
end

function Options.AddAnchorParentAutocomplete(_, editBox, onValueSelected)
	local suggestionFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	suggestionFrame:SetPoint("TOPLEFT", editBox.editbox, "BOTTOMLEFT", 0, -2)
	suggestionFrame:SetPoint("TOPRIGHT", editBox.editbox, "BOTTOMRIGHT", 0, -2)
	suggestionFrame:SetFrameStrata("TOOLTIP")
	suggestionFrame:SetFrameLevel(10000)
	suggestionFrame:SetToplevel(true)
	suggestionFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1, })
	suggestionFrame:SetBackdropColor(26/255, 26/255, 26/255, 1)
	suggestionFrame:SetBackdropBorderColor(0, 0, 0, 1)
	suggestionFrame:SetScript("OnUpdate", function(self) if not editBox.frame:IsShown() or (not editBox.editbox:HasFocus() and not self:IsMouseOver()) then self:Hide() end end)
	suggestionFrame:Hide()

	local rows = {}

	local function SelectSuggestion(anchor)
		local text = editBox:GetText() or ""
		local prefix = text:match("^(.*,%s*)[^,]*$") or ""
		local newText = prefix .. anchor
		editBox:SetText(newText)
		suggestionFrame:Hide()
		if onValueSelected then
			onValueSelected(newText)
		end
	end

	local function SetSuggestions(text)
		local token = strtrim((text or ""):match("([^,]*)$") or "")
		local tokenLower = strlower(token)
		local suggestions = {}

		if token == "" then suggestionFrame:Hide() return end

		for _, anchorList in pairs(SCM.Constants.SCMAnchors) do
			if anchorList then
				for label, value in pairs(anchorList) do
					if value then
						local count = (label == "Anchor" and #(SCM.anchorConfig or {})) or (label == "Global Anchor" and #(SCM.globalAnchorConfig or {})) or 1
						for i = 1, count do
							local anchor = label == "Global Anchor" and value:gsub("10#", tostring(SCM.Utils.ToGlobalGroup(i))) or value:gsub("#", i)
							local display = (label == "Anchor" or label == "Global Anchor") and (label .. " #" .. i) or label
							if strfind(strlower(anchor), tokenLower, 1, true) or strfind(strlower(display), tokenLower, 1, true) then
								tinsert(suggestions, { anchor, display })
							end
						end
					end
				end
			end
		end

		if #suggestions == 0 then suggestionFrame:Hide() return end

		for i = 1, #suggestions do
			local row = rows[i]
			if not row then
				row = CreateFrame("Button", nil, suggestionFrame)
				row:SetHeight(18)
				row:SetPoint("LEFT", 2, 0)
				row:SetPoint("RIGHT", -2, 0)
				row.highlight = row:CreateTexture(nil, "OVERLAY")
				row.highlight:SetAllPoints()
				row.highlight:SetColorTexture(204/255, 204/255, 204/255, 0.5)
				row.highlight:SetBlendMode("BLEND")
				row.highlight:Hide()
				row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				row.text:SetPoint("LEFT", 4, 0)
				row.text:SetPoint("RIGHT", -4, 0)
				row.text:SetJustifyH("LEFT")
				row:SetScript("OnEnter", function(self) self.highlight:Show() end)
				row:SetScript("OnLeave", function(self) self.highlight:Hide() end)
				row:SetScript("OnClick", function(self) SelectSuggestion(self.anchor) end)
				rows[i] = row
			end

			local anchor, display = suggestions[i][1], suggestions[i][2]
			local startIndex, endIndex = strfind(strlower(display), tokenLower, 1, true)
			row.anchor = anchor
			row.text:SetText((startIndex and ("|cFF4080FF" .. strsub(display, 1, startIndex - 1) .. "|cFFCCCCCC" .. strsub(display, startIndex, endIndex) .. "|cFF4080FF" .. strsub(display, endIndex + 1) .. "|r")) or ("|cFF4080FF" .. display .. "|r"))
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 2, -2 - ((i - 1) * 18))
			row:SetPoint("TOPRIGHT", -2, -2 - ((i - 1) * 18))
			row:Show()
		end

		for i = #suggestions + 1, #rows do
			rows[i]:Hide()
		end

		suggestionFrame:SetHeight(4 + (#suggestions * 18))
		suggestionFrame:SetFrameLevel(10000)
		suggestionFrame:Show()
	end

	editBox:SetCallback("OnTextChanged", function(_, _, text) SetSuggestions(text) end)
end

function Options.SetAnchorHighlight(anchorFrame, state, color)
	local isActive = state == "active"
	if anchorFrame.SCMHighlightState == state and anchorFrame.isGlowActive == isActive then
		return
	end

	anchorFrame.SCMHighlightState = state
	anchorFrame.isGlowActive = isActive
	LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
	LibCustomGlow.PixelGlow_Start(anchorFrame, color, nil, nil, nil, nil, nil, nil, nil, "SCM")

	if anchorFrame.debugText then
		if state == "active" then
			anchorFrame.debugText:SetTextColor(0.34, 0.70, 0.91, 1)
		else
			anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)
		end
	end
end

function SCM:AddTab(tab)
	if not self.MainTabs[tab.value] and tab.callback then
		self.MainTabs[tab.value] = tab
	end

	if self.OptionsFrame and self.OptionsFrame:IsShown() then
		self.OptionsFrame:DoLayout()
	end
end

function SCM:GetHideWhenInactive()
	LibEditModeOverride:LoadLayouts()
	return LibEditModeOverride:GetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive)
end

function SCM:GetShowTooltip()
	LibEditModeOverride:LoadLayouts()
	return LibEditModeOverride:GetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.ShowTooltips)
end

function SCM:SetHideWhenInactive(value)
	LibEditModeOverride:LoadLayouts()

	if LibEditModeOverride:CanEditActiveLayout() then
		local currentSetting = LibEditModeOverride:GetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive)
		if (value and currentSetting == 1) or (not value and currentSetting == 0) then
			LibEditModeOverride:SetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive, value and 0 or 1)
			LibEditModeOverride:SaveOnly()
			LibEditModeOverride:ApplyChanges()
		end
	end
end

function SCM:SetBuffBarContent(value)
	LibEditModeOverride:LoadLayouts()
	if LibEditModeOverride:CanEditActiveLayout() then
		local currentSetting = LibEditModeOverride:GetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.BarContent)
		if value ~= currentSetting then
			LibEditModeOverride:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.BarContent, value)
			LibEditModeOverride:SaveOnly()
			LibEditModeOverride:ApplyChanges()
		end
	end
end

function SCM:GetVisibilityConditions(options)
	if options.useCustomVisibilityCondition then
		local currentCondition = SecureCmdOptionParse(options.customVisibilityCondition)
		if currentCondition == "show" or currentCondition == "hide" then
			return options.customVisibilityCondition
		else
			return "show"
		end
	else
		local visibility = {}
		if options.hideWhileMounted then
			tinsert(visibility, "[mounted][stance:3]hide")
		end

		if options.hideWhileDead then
			tinsert(visibility, "[@player,dead]hide")
		end

		if options.hideWhileInVehicle then
			tinsert(visibility, "[@player,unithasvehicleui]hide")
		end

		if options.hideWhileResting then
			tinsert(visibility, "[resting]hide")
		end

		if options.hideOutOfCombat then
			tinsert(visibility, "[nocombat]hide")
		end

		if #visibility > 0 then
			return "[combat]show;" .. table.concat(visibility, ";") .. ";show"
		else
			return "show"
		end
	end
end

function SCM:ApplyAttributeDriver()
	if not InCombatLockdown() then
		local conditionals = SCM:GetVisibilityConditions(self.db.profile.options)
		RegisterAttributeDriver(EssentialCooldownViewer, "state-visibility", conditionals)
		RegisterAttributeDriver(UtilityCooldownViewer, "state-visibility", conditionals)
		RegisterAttributeDriver(BuffIconCooldownViewer, "state-visibility", conditionals)

		self:ApplyResourceBarAttributeDriver()
	end
end

function SCM:ApplyOptions()
	if InCombatLockdown() or self.appliedOptions then
		return
	end
	self.appliedOptions = true

	local options = self.db.profile.options
	self:SetHideWhenInactive(options.hideBuffsWhenInactive)
	self:SetBuffBarContent(options.buffBarContent)
	self:ApplyAttributeDriver(options.hideWhileMounted)
	self.Cooldowns:ApplyFormatterSettings()
end

local function OpenOptions()
	SCM.isOptionsOpen = true
	SCM.simulateBuffs = true

	local options = SCM.db.profile.options

	SCM:StopAllGlows()
	SCM:ApplyAllCDManagerConfigs()

	local frame = AceGUI:Create("SCMFrame")
	frame:SetTitle(addonName)
	frame:SetLayout("flow")
	SCM.OptionsFrame = frame
	LibWindow.RegisterConfig(frame.frame, options.optionsWindow)
	LibWindow.SetScale(frame.frame, options.menuScale)
	frame.frame.TitleContainer:HookScript("OnMouseUp", function()
		if options.savePosition then
			LibWindow.SavePosition(frame.frame)
		end
	end)

	if options.savePosition then
		LibWindow.RestorePosition(frame.frame)
	end

	frame:SetHeight(1000)
	frame:SetWidth(850)

	local tabsTbl = {}
	for _, tab in pairs(SCM.MainTabs) do
		tinsert(tabsTbl, tab)
	end
	table.sort(tabsTbl, function(a, b)
		return a.order < b.order
	end)

	local tabs = AceGUI:Create("TabGroup")
	tabs:SetTabs(tabsTbl)
	tabs:SetWidth(frame.frame:GetWidth() - 30)
	tabs:SetFullHeight(true)
	tabs:SetLayout("fill")
	tabs:SetCallback("OnGroupSelected", function(self, event, group)
		self:ReleaseChildren()

		local options = SCM.db.profile.options
		if options.showAnchorHighlight then
			for _, anchorFrame in pairs(SCM.anchorFrames) do
				anchorFrame.debugTexture:Show()
				anchorFrame.debugText:Show()

				if group ~= "CDM" then
					anchorFrame.isGlowActive = false
					anchorFrame.SCMHighlightState = "default"
					LibCustomGlow.PixelGlow_Stop(anchorFrame, "SCM")
					LibCustomGlow.PixelGlow_Start(anchorFrame, nil, nil, nil, nil, nil, nil, nil, nil, "SCM")
					anchorFrame.debugText:SetTextColor(0.90, 0.62, 0, 1)
				end
			end
		else
			for _, anchorFrame in pairs(SCM.anchorFrames) do
				anchorFrame.debugTexture:Hide()
				anchorFrame.debugText:Hide()
			end
		end

		if SCM.MainTabs[group] then
			SCM.MainTabs[group].callback(self, frame, group)
		end
	end)
	tabs:SelectTab("General")
	frame:AddChild(tabs)
	SCM:SkinOptionsFrame(frame, tabs)
	frame:SetCallback("OnClose", function()
		SCM.OptionsFrame = nil
		SCM.isOptionsOpen = nil
		SCM.simulateBuffs = nil
		for _, anchorFrame in pairs(SCM.anchorFrames) do
			anchorFrame.debugTexture:Hide()
			anchorFrame.debugText:Hide()
		end
		SCM.RefreshCooldownViewerData(true)
		RunNextFrame(function()
			SCM:RestoreBlizzardGlows()
		end)

		if options.savePosition then
			LibWindow.SavePosition(frame.frame)
		end
	end)

	if SCM.db.profile.options.showAnchorHighlight then
		for _, anchorFrame in pairs(SCM.anchorFrames) do
			anchorFrame.debugTexture:Show()
			anchorFrame.debugText:Show()
		end
	end

	tabs.border:ClearBackdrop()
end

SLASH_SCM1 = "/scm"
local function HandleMessage(msg, editBox)
	if msg == "debug" then
		local options = SCM.db.profile.options
		options.debug = not options.debug
	else
		if not SCM.OptionsFrame or not SCM.OptionsFrame:IsShown() then
			OpenOptions()
		else
			SCM.OptionsFrame:Release()
			SCM.OptionsFrame = nil
		end
	end
end
SlashCmdList["SCM"] = HandleMessage

function SCM:ToggleOptions()
	HandleMessage()
end
