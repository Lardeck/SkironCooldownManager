local SCM = select(2, ...)

local LoadConditions = SCM.LoadConditions

function LoadConditions.GetDefaultLoadClasses()
	local loadClasses = {}
	for classFile in pairs(SCM.Utils.GetClassList(false)) do
		loadClasses[classFile] = false
	end
	return loadClasses
end

function LoadConditions.GetDefaultLoadRaces()
	local loadRaces = {}
	for raceID in pairs(SCM.Constants.CHARACTER.RACES) do
		loadRaces[raceID] = false
	end
	return loadRaces
end

local function MatchesLoadFilter(loadFilter, value)
	if loadFilter then
		if not next(loadFilter) then
			return false
		end

		return loadFilter[value]
	end

	return true
end

function LoadConditions.ShouldLoad(config)
	if config.useLoadRole and not MatchesLoadFilter(config.loadRoles, SCM.currentRole) then
		return false
	end

	if config.useLoadClass and not MatchesLoadFilter(config.loadClasses, SCM.currentClass) then
		return false
	end

	if config.useLoadRace and not MatchesLoadFilter(config.loadRaces, SCM.currentRace) then
		return false
	end

	if config.useSpellKnown or config.useSpellKnown == nil then
		if not config.spellKnownSpellID or type(config.spellKnownSpellID) ~= "number" then
			return true
		end

		local isSpellKnown = C_SpellBook.IsSpellKnown(config.spellKnownSpellID)
		return (config.useSpellKnown and isSpellKnown) or (config.useSpellKnown == nil and not isSpellKnown)
	end

	return true
end
