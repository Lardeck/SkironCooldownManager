local SCM = select(2, ...)
local Constants = SCM.Constants

Constants.CooldownTimer = {}

Constants.CooldownTimer.DisplayStyle = {
	{
		decimalSeconds = "Decimal Seconds (1.1)",
		seconds = "Seconds (10s)",
		secondsOnly = "Seconds (10)",
		clock = "Clock (1:10)",
		minutes = "Minutes (2m)",
		hours = "Hours (1h)",
		days = "Days (1d)",
	},
	{
		"decimalSeconds",
		"seconds",
		"secondsOnly",
		"clock",
		"minutes",
		"hours",
		"days",
	},
}

Constants.CooldownTimer.DisplayStyleSettings = {
	decimalSeconds = {
		step = 0.1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%.1f",
	},
	seconds = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%ds",
	},
	secondsOnly = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d",
	},
	clock = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d:%02d",
	},
	minutes = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dm",
	},
	hours = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dh",
	},
	days = {
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dd",
	},
}

Constants.CooldownTimer.DefaultBreakpoints = {
	{
		threshold = 0,
		displayStyle = "secondsOnly",
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d",
	},
	{
		threshold = 60,
		displayStyle = "clock",
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%d:%02d",
		components = {
			{ div = 60 },
			{ mod = 60 },
		},
	},
	{
		threshold = 120,
		displayStyle = "minutes",
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
		format = "%dm",
		components = {
			{ div = 60 },
		},
	},
}