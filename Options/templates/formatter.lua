local SCM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local Templates = SCM.Templates
local Constants = SCM.Constants.Formatter

function Templates.AddFormatterOptions(parent, formatter, options)
	options = options or {}

	local breakpoints = formatter.breakpoints

	local formatterSettings = AceGUI:Create("SimpleGroup")
	formatterSettings:SetLayout("flow")
	formatterSettings:SetFullWidth(true)
	parent:AddChild(formatterSettings)

	local breakpointRows = AceGUI:Create("SimpleGroup")
	breakpointRows:SetUserData("table", {
		columns = options.showPrecisionAndRounding and { 1, 2, 70, 1, 1, 70 } or { 1, 2, 70, 70 },
		spaceH = 6,
		spaceV = 8,
		alignH = "fill",
		alignV = "BOTTOM",
	})
	breakpointRows:SetLayout("Table")
	breakpointRows:SetFullWidth(true)
	formatterSettings:AddChild(breakpointRows)

	local function RefreshBreakpointRows()
		breakpointRows:PauseLayout()
		breakpointRows:ReleaseChildren()

		for breakpointIndex, breakpoint in ipairs(breakpoints) do
			local minValueInput = AceGUI:Create("EditBox")
			minValueInput:SetFullWidth(true)
			minValueInput:SetLabel("Min Value (s)")
			minValueInput:SetText(tostring(breakpoint.threshold))
			minValueInput:SetCallback("OnEnterPressed", function(self, _, text)
				local value = tonumber(text)

				if not value or value < 0 then
					self:SetText(tostring(breakpoint.threshold))
					return
				end

				breakpoint.threshold = value
				table.sort(breakpoints, function(firstBreakpoint, secondBreakpoint)
					return firstBreakpoint.threshold < secondBreakpoint.threshold
				end)

				formatter:Update()
				RefreshBreakpointRows()
			end)
			breakpointRows:AddChild(minValueInput)

			local breakpointDisplayStyle = AceGUI:Create("Dropdown")
			breakpointDisplayStyle:SetFullWidth(true)
			breakpointDisplayStyle:SetLabel("Display Style")
			breakpointDisplayStyle:SetList(Constants.DisplayStyle[1], Constants.DisplayStyle[2])
			breakpointDisplayStyle:SetValue(breakpoint.displayStyle)
			breakpointRows:AddChild(breakpointDisplayStyle)

			local breakpointColor = AceGUI:Create("ColorPicker")
			breakpointColor:SetFullWidth(true)
			breakpointColor:SetLabel("Color")
			breakpointColor:SetHasAlpha(options.hasAlpha)
			breakpointColor:SetColor(unpack(breakpoint.color or { 1, 1, 1, 1 }))
			breakpointColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
				breakpoint.color = { r, g, b, a }

				formatter:Update()
			end)
			breakpointRows:AddChild(breakpointColor)

			local breakpointPrecision, breakpointRounding

			if options.showPrecisionAndRounding then
				breakpointPrecision = AceGUI:Create("Dropdown")
				breakpointPrecision:SetFullWidth(true)
				breakpointPrecision:SetLabel("Precision")
				breakpointPrecision:SetList({ [0] = "12", [1] = "12.3", [2] = "12.34" }, { 0, 1, 2 })
				breakpointPrecision:SetValue(breakpoint.precision or 1)
				breakpointPrecision:SetDisabled(breakpoint.displayStyle ~= "decimalSeconds")
				breakpointPrecision:SetCallback("OnValueChanged", function(_, _, value)
					breakpoint.precision = value

					formatter:Update()
				end)
				breakpointRows:AddChild(breakpointPrecision)

				local roundingModes = Enum.NumericRuleFormatRounding

				breakpointRounding = AceGUI:Create("Dropdown")
				breakpointRounding:SetFullWidth(true)
				breakpointRounding:SetLabel("Round Mode")
				breakpointRounding:SetList({ [roundingModes.Nearest] = "Round", [roundingModes.Up] = "Ceil", [roundingModes.Down] = "Floor" }, {
					roundingModes.Down,
					roundingModes.Up,
					roundingModes.Nearest,
				})
				breakpointRounding:SetValue(breakpoint.rounding)
				breakpointRounding:SetCallback("OnValueChanged", function(_, _, value)
					breakpoint.rounding = value

					formatter:Update()
				end)
				breakpointRows:AddChild(breakpointRounding)
			end

			breakpointDisplayStyle:SetCallback("OnValueChanged", function(_, _, value)
				breakpoint.displayStyle = value
				breakpoint.rounding = Constants.DisplayStyleSettings[value].rounding

				if breakpointPrecision then
					breakpointPrecision:SetDisabled(value ~= "decimalSeconds")
					breakpointRounding:SetValue(breakpoint.rounding)
				end

				formatter:Update()
			end)

			local removeBreakpointButton = AceGUI:Create("Button")
			removeBreakpointButton:SetFullWidth(true)
			removeBreakpointButton:SetText("Delete")
			removeBreakpointButton:SetDisabled(#breakpoints <= 1)
			removeBreakpointButton:SetCallback("OnClick", function()
				tremove(breakpoints, breakpointIndex)

				formatter:Update()
				RefreshBreakpointRows()
			end)
			breakpointRows:AddChild(removeBreakpointButton)
		end

		breakpointRows:ResumeLayout()
		breakpointRows:DoLayout()
		parent:DoLayout()
	end

	local addBreakpointButton = AceGUI:Create("Button")
	addBreakpointButton:SetWidth(150)
	addBreakpointButton:SetText("Add Row")
	addBreakpointButton:SetCallback("OnClick", function()
		local newBreakpoint = CopyTable(breakpoints[#breakpoints])
		newBreakpoint.threshold = newBreakpoint.threshold * 2
		breakpoints[#breakpoints + 1] = newBreakpoint

		formatter:Update()
		RefreshBreakpointRows()
	end)
	formatterSettings:AddChild(addBreakpointButton)

	table.sort(breakpoints, function(firstBreakpoint, secondBreakpoint)
		return firstBreakpoint.threshold < secondBreakpoint.threshold
	end)

	RefreshBreakpointRows()
	formatter:Update()
end
