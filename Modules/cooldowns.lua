local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns

Cooldowns.Formatter = SCM.Formatter.CreateFormatter()

local function OnCooldownSet(self, ...)
	local handler = self.SCMCooldownCallback
	if handler then
		handler(self, ...)
	end

	SCM.ApplyCooldownSkin(self)
end

function Cooldowns.SetupCooldownHook(cooldownFrame, callback)
	if callback then
		cooldownFrame.SCMCooldownCallback = callback
	end

	if cooldownFrame.SCMCooldownHook then
		return
	end

	hooksecurefunc(cooldownFrame, "SetCooldown", OnCooldownSet)
	cooldownFrame.SCMCooldownHook = true
end

function Cooldowns.IsGlobalCooldown(startTime, duration)
	local globalCooldown = C_Spell.GetSpellCooldown(61304)
	return globalCooldown and globalCooldown.isActive and startTime == globalCooldown.startTime and duration == globalCooldown.duration
end
