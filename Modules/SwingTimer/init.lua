local SCM = select(2, ...)

local SWING_TIMER_LABELS = {
	MainHand = SWING_TIMER_MAIN_HAND,
	OffHand = SWING_TIMER_OFF_HAND,
	Ranged = SWING_TIMER_RANGED,
}

local FORMATTER_OPTION_KEYS = { "durationDecimals", "durationRounding" }

local function MigrateFormatterSettings(options)
	local defaults = SCM.DefaultDB.profile.options.swingTimer
	for _, key in ipairs(FORMATTER_OPTION_KEYS) do
		local value = rawget(options, key)
		if value then
			for swingType in pairs(SWING_TIMER_LABELS) do
				local barOptions = options[swingType]
				if barOptions[key] == defaults[swingType][key] then
					barOptions[key] = value
				end
			end
			options[key] = nil
		end
	end

	for swingType in pairs(SWING_TIMER_LABELS) do
		local barOptions = options[swingType]
		if barOptions.durationDecimals or barOptions.durationRounding or barOptions.durationColor then
			local breakpoint = barOptions.durationBreakpoints[1]
			breakpoint.precision = barOptions.durationDecimals or breakpoint.precision
			breakpoint.displayStyle = breakpoint.precision == 0 and "secondsOnly" or "decimalSeconds"
			breakpoint.rounding = barOptions.durationRounding or breakpoint.rounding
			breakpoint.color = barOptions.durationColor or breakpoint.color
			barOptions.durationDecimals = nil
			barOptions.durationRounding = nil
			barOptions.durationColor = nil
		end
	end
end

function SCM:InitializeSwingTimer()
	local swingTimerOptions = self.db.profile.options.swingTimer
	MigrateFormatterSettings(swingTimerOptions)
	self.SwingTimers = self.SwingTimers or {}

	for swingType, typeText in pairs(SWING_TIMER_LABELS) do
		if not self.SwingTimers[swingType] then
			local timer = CreateFrame("Frame", "SCM_SwingTimer" .. swingType, UIParent, "SCMSwingTimerBarTemplate")
			timer:Init(Enum.PlayerSwingType[swingType], typeText, swingTimerOptions[swingType])
			self.SwingTimers[swingType] = timer
		end
	end
	self:RefreshSwingTimerConfig()
end
