local SCM = select(2, ...)

local Formatter = SCM.Formatter

SCMFormatterMixin = {}

function SCMFormatterMixin:Init(breakpoints)
	self.numericRuleFormatter = C_StringUtil.CreateNumericRuleFormatter()

	if breakpoints then
		self:SetBreakpoints(breakpoints)
	end
end

function SCMFormatterMixin:SetBreakpoints(breakpoints)
	self.breakpoints = breakpoints

	self:Update()
end

function SCMFormatterMixin:ApplyToCooldown(cooldownFrame)
	cooldownFrame:SetCountdownFormatter(self.numericRuleFormatter)
end

function SCMFormatterMixin:SetDurationTextBinding(binding)
	self.durationTextBinding = binding

	binding:SetFormatter(self.numericRuleFormatter)
end

function SCMFormatterMixin:Update()
	for _, breakpoint in ipairs(self.breakpoints) do
		Formatter.UpdateBreakpoint(breakpoint)
	end

	self.numericRuleFormatter:SetBreakpoints(self.breakpoints)

	local binding = self.durationTextBinding

	if binding then
		local idleText = self.showIdleDuration and self.numericRuleFormatter:FormatNumber(0) or ""

		binding:SetExpiredText(idleText)
		binding:SetZeroDurationText(idleText)
		binding:UpdateFontString()
	end
end

function Formatter.CreateFormatter(breakpoints)
	local formatter = CreateFromMixins(SCMFormatterMixin)

	formatter:Init(breakpoints)

	return formatter
end

function Formatter.GetBreakpointComponents(displayStyle, minValue)
	if displayStyle == "clock" then
		if minValue >= 86400 then
			return { { div = 86400 }, { div = 3600, mod = 24 } }
		elseif minValue >= 3600 then
			return { { div = 3600 }, { div = 60, mod = 60 } }
		end

		return { { div = 60 }, { mod = 60 } }
	elseif displayStyle == "minutes" then
		return { { div = 60 } }
	elseif displayStyle == "hours" then
		return { { div = 3600 } }
	elseif displayStyle == "days" then
		return { { div = 86400 } }
	end
end

function Formatter.UpdateBreakpoint(breakpoint)
	local style = SCM.Constants.Formatter.DisplayStyleSettings[breakpoint.displayStyle]
	local decimals = breakpoint.precision or 1
	local isDecimal = breakpoint.displayStyle == "decimalSeconds"

	breakpoint.step = isDecimal and 10 ^ -decimals or style.step
	breakpoint.rounding = breakpoint.rounding or style.rounding
	breakpoint.format = isDecimal and string.format("%%.%df", decimals) or style.format

	breakpoint.components = Formatter.GetBreakpointComponents(breakpoint.displayStyle, breakpoint.threshold)

	if breakpoint.color then
		breakpoint.format = CreateColor(unpack(breakpoint.color)):WrapTextInColorCode(breakpoint.format)
	end
end
