local SCM = select(2, ...)

SCM.Defaults = {}

SCM.DB = {
	classes = {},

	defaultAnchorConfig = {
		[1] = {
			anchor = { "CENTER", "UIParent", "CENTER", 0, -285 },
			rowConfig = {
				[1] = {
					iconHeight = 47,
					iconWidth = 47,
					limit = 8,
				},
			},
		},
		[2] = {
			anchor = { "TOP", "ANCHOR:1", "BOTTOM", 0, 1 },
			rowConfig = {
				[1] = {
					iconHeight = 41,
					iconWidth = 41,
					limit = 8,
				},
			},
		},
		[3] = {
			anchor = { "TOP", "ANCHOR:2", "BOTTOM", 0, 1 },
			rowConfig = {
				[1] = {
					iconHeight = 40,
					iconWidth = 40,
					limit = 8,
				},
			},
		},
	},

	defaultBuffBarsAnchorConfig = {
		[1] = {
			anchor = { "CENTER", "UIParent", "CENTER", 0, 0 },
			rowConfig = {
				[1] = {
					iconWidth = 150,
					iconHeight = 40,
					limit = 8,
				},
			},
		},
	},

	defaultAurasAnchorConfig = {
		[3] = {
			anchor = { "CENTER", "UIParent", "CENTER", 0, 0 },
			rowConfig = {
				[1] = {
					iconHeight = 40,
					iconWidth = 40,
					limit = 8,
				},
			},
		},
	},
}

SCM.DefaultDB = {
	profile = {
		globalAnchorConfig = {
			[1] = {
				anchor = { "CENTER", "UIParent", "CENTER", 0, -360 },
				rowConfig = {
					[1] = {
						iconHeight = 40,
						iconWidth = 40,
						limit = 8,
					},
				},
			},
		},
		globalCustomConfig = {
			spellConfig = {},
			itemConfig = {},
			slotConfig = {},
			timerConfig = {},
			bloodlustConfig = {},
		},
		globalAurasAnchorConfig = {
			[1] = {
				anchor = { "CENTER", "UIParent", "CENTER", 0, 250 },
				rowConfig = {
					[1] = {
						iconHeight = 40,
						iconWidth = 40,
						limit = 8,
					},
				},
			},
		},
		options = {
			anchorElvUIRoles = {
				["HEALER"] = false,
				["DAMAGER"] = true,
				["TANK"] = true,
			},
			anchorEUIRoles = {
				["HEALER"] = false,
				["DAMAGER"] = true,
				["TANK"] = true,
			},
			elvUIAnchors = {},
			anchorConfig = {},
			minimapButton = {
				hide = false,
			},
			showAnchorHighlight = true,
			enableCursor = false,
			cursorUpdateInterval = 0.01,
			checkForDisabledIcons = true,
			hideWhileMounted = false,
			hideWhileDead = false,
			hideWhileInVehicle = false,
			hideWhileResting = false,
			hideOutOfCombat = false,
			useCustomVisibilityCondition = false,
			customVisibilityCondition = "",
			disableBuffBarHideWhenInactive = false,
			buffBarContent = 0,
			debug = false,
			debugGroup = 0,
			savePosition = false,
			menuScale = 1,
			enableSkinning = true,
			pressOverlay = false,
			enableCustomIcons = true,
			simulateAuras = true,
			iconZoom = 0.12,
			keepIconSquareRatio = false,
			iconFrameStrata = "MEDIUM",
			chargeFont = "Expressway",
			chargeFontSize = 22,
			chargeFontOutline = "OUTLINE",
			chargePoint = "CENTER",
			chargeRelativePoint = "BOTTOMRIGHT",
			chargeXOffset = -8,
			chargeYOffset = 10,
			chargeFrameLevel = 3,
			applicationsFrameLevel = 3,
			chargeColour = { r = 1, g = 1, b = 1, a = 1 },
			applicationsColour = { r = 1, g = 1, b = 1, a = 1 },
			craftQualityFrameLevel = 2,
			changeCooldownFont = true,
			cooldownFont = "Expressway",
			cooldownFontSize = 0.6,
			cooldownFontOutline = "OUTLINE",
			cooldownFontColor = { r = 1, g = 1, b = 1, a = 1 },
			cooldownXOffset = 0,
			cooldownYOffset = 0,
			cooldownFrameLevel = 1,
			cooldownMoveTL = false,
			cooldownXOffsetTL = 0,
			cooldownYOffsetTL = 0,
			cooldownMoveBR = false,
			cooldownXOffsetBR = -1,
			cooldownYOffsetBR = 1,

			useCustomGlow = false,
			glowFrameLevel = 2,
			glowType = "Proc",
			borderSize = 1,
			anchorUUF = false,
			anchorElvUI = false,
			temporaryPadding = 0,
			adjustHeight = true,
			anchorsHeightOffset = 0,
			anchorsYOffset = 0,
			borderColor = { r = 0, g = 0, b = 0, a = 1 },
			adjustResourceWidth = true,
			pandemicGlowType = "Proc",
			pandemicGlowOption = "keepPandemicGlow",
			pandemicReplaceWithBorder = false,
			pandemicReplaceWithCustomGlow = false,
			pandemicBorderSize = 2,
			pandemicBorderColor = { r = 1, g = 0, b = 0, a = 1 },
			pandemicCustomGlowTypeOptions = {
				["Proc"] = {
					glowColor = { 0.95, 0.95, 0.32, 1 },
				},
				["Pixel"] = {
					numLines = 8,
					frequency = 0.25,
					length = 2,
					thickness = 2,
					glowColor = { 0.95, 0.95, 0.32, 1 },
					xOffset = 0,
					yOffset = 0,
					border = false,
				},
				["Autocast"] = {
					startAnim = true,
					numParticles = 4,
					frequency = 0.125,
					scale = 1,
					glowColor = { 0.95, 0.95, 0.32, 1 },
				},
				["Button"] = {
					glowColor = { 0.95, 0.95, 0.32, 1 },
					frequency = 0.125,
				},
			},
			recolorActiveSwipe = false,
			disableRegularIconActiveSwipe = false,
			limitActiveSwipeToSelectedSpell = false,
			debuffs = {
				-- Death Knight
				-- Unholy
				-- [77575] = { enabled = true, class = "DEATHKNIGHT" },

				-- Demon Hunter

				-- Druid
				-- Guardian + Balance
				[8921] = { enabled = true, class = "DRUID" }, -- Moonfire
				-- Balance + Restoration
				[93402] = { enabled = true, class = "DRUID" }, -- Sunfire
				-- Restoration + Feral
				[1822] = { enabled = true, class = "DRUID" }, -- Rake
				[1079] = { enabled = true, class = "DRUID" }, -- Rip
				-- Feral
				[155625] = { enabled = true, class = "DRUID" }, -- Moonfire

				-- Evoker

				-- Hunter
				[1264359] = { enabled = false, class = "HUNTER" }, -- Wild Thrash

				-- Mage
				-- Monk

				-- Paladin
				-- Protection + Holy
				[26573] = { enabled = true, class = "PALADIN" }, -- Consecration

				-- Priest
				[10060] = { enabled = false, class = "PRIEST" }, -- Power Infusion
				-- Discipline + Shadow
				[589] = { enabled = true, class = "PRIEST" }, -- Shadow Word: Pain
				-- Shadow
				[34914] = { enabled = true, class = "PRIEST" }, -- Vampiric Touch
				[335467] = { enabled = true, class = "PRIEST" }, -- Shadow Word: Madness

				-- Rogue
				[315496] = { enabled = true, class = "ROGUE" }, -- Slice and Dice
				-- Assassination
				[1943] = { enabled = true, class = "ROGUE" }, -- Rupture
				[32645] = { enabled = true, class = "ROGUE" }, -- Envenom
				[703] = { enabled = true, class = "ROGUE" }, -- Garrote

				-- Shaman
				-- Elemental + Restoration
				[470411] = { enabled = true, class = "SHAMAN" }, -- Flame Shock
				-- Enhancement
				-- [470057] = { enabled = true, class = "SHAMAN" }, -- Flame Shock

				-- Warlock
				-- Destruction
				[348] = { enabled = true, class = "WARLOCK" }, -- Immolate
				-- Affliction
				[172] = { enabled = true, class = "WARLOCK" }, -- Corruption
				[980] = { enabled = true, class = "WARLOCK" }, -- Agony
				[1259790] = { enabled = true, class = "WARLOCK" }, -- Unstable Affliction
				-- Destruction + Affliction
				[445468] = { enabled = true, class = "WARLOCK" }, -- Wither
				-- Demonology
				[264178] = { enabled = true, class = "WARLOCK" }, -- Demonbolt

				-- Warrior
				[772] = { enabled = true, class = "WARRIOR" }, -- Rend
			},
			disableGCD = false,
			activeSwipeColor = { 0, 0, 0, 0.7 },
			normalSwipeColor = { 0.1, 0.1, 0.1, 0.7 },
			castbarXOffset = 0,
			castbarYOffset = 25,
			glowTypeOptions = {
				["Proc"] = {
					glowColor = { 0.95, 0.95, 0.32, 1 },
				},
				["Pixel"] = {
					numLines = 8,
					frequency = 0.25,
					length = 2,
					thickness = 2,
					glowColor = { 0.95, 0.95, 0.32, 1 },
					xOffset = 0,
					yOffset = 0,
					border = false,
				},
				["Autocast"] = {
					startAnim = true,
					numParticles = 4,
					frequency = 0.125,
					scale = 1,
					glowColor = { 0.95, 0.95, 0.32, 1 },
				},
				["Button"] = {
					glowColor = { 0.95, 0.95, 0.32, 1 },
					frequency = 0.125,
				},
			},
			buffBarOptions = {
				barTexture = "Solid",
				borderSize = 2,
				borderColor = { r = 0, g = 0, b = 0, a = 1 },
				backgroundColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.5 },
				foregroundColor = { r = 0.5, g = 0.5, b = 1, a = 1 },
				font = "Expressway",
				fontSize = 15,
				fontOutline = "OUTLINE",
				hideSpellName = false,
				nameXOffset = 5,
				nameYOffset = 0,
				nameColor = { r = 1, g = 1, b = 1, a = 1 },
				hideDuration = false,
				durationXOffset = -8,
				durationYOffset = 0,
				durationColor = { r = 1, g = 1, b = 1, a = 1 },
			},
			resourceBars = {
				"PrimaryResourceBar",
				"SecondaryResourceBar",
			},
			optionsWindow = {},
			resourceBar = {
				enabled = true,
				hideWhileMounted = false,
				hideWhileDead = false,
				hideWhileInVehicle = false,
				hideWhileResting = false,
				hideOutOfCombat = false,
				useCustomVisibilityCondition = false,
				customVisibilityCondition = "",
				anchorFrame = "ANCHOR:1",
				point = "BOTTOM",
				relativePoint = "TOP",
				xOffset = 0,
				yOffset = 0,
				spacing = -1,
				growDirection = "UP",
				frameStrata = "BACKGROUND",
				useFrequentPowerUpdates = true,
				maelstromOverflowColor = { r = 0.25, g = 0.70, b = 1.00 },
				comboPointsOverflowColor = { r = 0.25, g = 0.70, b = 1.00 },
				runeRechargeColor = { r = 0.55, g = 0.55, b = 0.55 },
				staggerDisplayAsPercent = false,
				staggerColors = {
					light = { r = 0.52, g = 1.00, b = 0.52 },
					moderate = { r = 1.00, g = 0.98, b = 0.72 },
					heavy = { r = 1.00, g = 0.42, b = 0.42 },
				},
				minWidth = 200,
				powerTypeColorOverrides = {
					MANA = { enabled = false, color = { r = 0.00, g = 0.45, b = 1.00 } },
					RAGE = { enabled = false, color = { r = 1.00, g = 0.15, b = 0.15 } },
					FOCUS = { enabled = false, color = { r = 1.00, g = 0.50, b = 0.25 } },
					ENERGY = { enabled = false, color = { r = 1.00, g = 0.85, b = 0.10 } },
					COMBO_POINTS = { enabled = false, color = { r = 1.00, g = 0.96, b = 0.41 } },
					RUNES = { enabled = false, color = { r = 0.55, g = 0.55, b = 0.55 } },
					RUNIC_POWER = { enabled = false, color = { r = 0.00, g = 0.82, b = 1.00 } },
					SOUL_SHARDS = { enabled = false, color = { r = 0.50, g = 0.32, b = 0.55 } },
					LUNAR_POWER = { enabled = false, color = { r = 0.30, g = 0.52, b = 0.90 } },
					HOLY_POWER = { enabled = false, color = { r = 0.95, g = 0.90, b = 0.60 } },
					MAELSTROM = { enabled = false, color = { r = 0.00, g = 0.50, b = 1.00 } },
					CHI = { enabled = false, color = { r = 0.71, g = 1.00, b = 0.92 } },
					INSANITY = { enabled = false, color = { r = 0.40, g = 0.00, b = 0.80 } },
					ARCANE_CHARGES = { enabled = false, color = { r = 0.10, g = 0.10, b = 0.98 } },
					FURY = { enabled = false, color = { r = 0.79, g = 0.26, b = 0.99 } },
					PAIN = { enabled = false, color = { r = 1.00, g = 0.61, b = 0.00 } },
					ESSENCE = { enabled = false, color = { r = 0.32, g = 0.84, b = 0.90 } },
					STAGGER = { enabled = false, color = { r = 0.52, g = 1.00, b = 0.52 } },
					MAELSTROM_WEAPON = { enabled = false, color = { r = 0.00, g = 0.50, b = 1.00 } },
					SOUL_FRAGMENTS = { enabled = false, color = { r = 0.35, g = 0.25, b = 0.73 } },
					SOUL_FRAGMENTS_VENGEANCE = { enabled = false, color = { r = 0.35, g = 0.25, b = 0.73 } },
					TIP_OF_THE_SPEAR = { enabled = false, color = { r = 1.00, g = 0.82, b = 0.20 } },
					ICICLES = { enabled = false, color = { r = 0.50, g = 0.78, b = 1.00 } },
					SPELL_CHARGES_FIRE_BLAST = { enabled = false, color = { r = 1.00, g = 0.34, b = 0.12 } },
					SPELL_CHARGES_SERENITY = { enabled = false, color = { r = 1.00, g = 1.00, b = 1.00 } },
				},
				primaryBar = {
					enabled = true,
					frameLevel = 1,
					matchAnchorWidth = true,
					width = 200,
					hideManaRoles = {
						["TANK"] = true,
						["DAMAGER"] = true,
						["HEALER"] = true,
					},
					font = "Expressway",
					fontSize = 21,
					textXOffset = 0,
					textYOffset = -1,
					textOutline = "OUTLINE",
					texture = "Solid",
					useBackgroundTexture = true,
					backgroundTexture = "Solid",
					backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 },
					showTicks = true,
					tickWidth = 2,
					tickColor = { r = 0, g = 0, b = 0, a = 1 },
					showBorder = true,
					backdropSize = 2,
					backdropColor = { r = 0, g = 0, b = 0, a = 1 },
					height = 20,
					heightAlternative = 20,
					showValues = true,
					forceMana = false,
					showPercentageSign = true,
					showRawMana = false,
					manaValueOrder = 1,
					useSmoothPowerUpdates = false,
					spark = {
						enable = false,
						width = 2,
						height = 22,
						color = { r = 1, g = 1, b = 1, a = 1 },
						texture = "Solid",
						xOffset = 0,
						yOffset = 0,
						useCustomTexture = false,
						blendMode = "ADD",
					},
					druidFormPowerTypes = {
						[102] = {
							[0] = "none",
							[1] = Enum.PowerType.Rage,
							[2] = Enum.PowerType.Energy,
							[3] = "none",
							[4] = Enum.PowerType.LunarPower,
						},
						[103] = {
							[0] = "none",
							[1] = Enum.PowerType.Rage,
							[2] = Enum.PowerType.Energy,
							[3] = "none",
							[4] = Enum.PowerType.LunarPower,
						},
						[104] = {
							[0] = "none",
							[1] = Enum.PowerType.Rage,
							[2] = Enum.PowerType.Energy,
							[3] = "none",
							[4] = Enum.PowerType.LunarPower,
						},
						[105] = {
							[0] = "none",
							[1] = Enum.PowerType.Rage,
							[2] = Enum.PowerType.Energy,
							[3] = "none",
							[4] = Enum.PowerType.LunarPower,
						},
					},
				},
				secondaryBar = {
					enabled = true,
					frameLevel = 1,
					matchAnchorWidth = true,
					width = 200,
					hideManaRoles = {
						["TANK"] = true,
						["DAMAGER"] = true,
						["HEALER"] = true,
					},
					font = "Expressway",
					fontSize = 27,
					textXOffset = 0,
					textYOffset = 5,
					textOutline = "OUTLINE",
					texture = "Solid",
					useBackgroundTexture = true,
					backgroundTexture = "Solid",
					backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 },
					showTicks = true,
					tickWidth = 2,
					tickColor = { r = 0, g = 0, b = 0, a = 1 },
					showBorder = true,
					backdropSize = 2,
					backdropColor = { r = 0, g = 0, b = 0, a = 1 },
					height = 20,
					heightAlternative = 20,
					showValues = true,
					disableMaelstromOverflow = false,
					forceMana = false,
					showPercentageSign = true,
					showRawMana = false,
					manaValueOrder = 1,
					useSmoothPowerUpdates = false,
					spark = {
						enable = false,
						width = 2,
						height = 22,
						color = { r = 1, g = 1, b = 1, a = 1 },
						texture = "Solid",
						xOffset = 0,
						yOffset = 0,
						useCustomTexture = false,
						blendMode = "ADD",
					},
					druidFormPowerTypes = {
						[102] = {
							[0] = "none",
							[1] = "none",
							[2] = Enum.PowerType.ComboPoints,
							[3] = "none",
							[4] = "none",
						},
						[103] = {
							[0] = "none",
							[1] = "none",
							[2] = Enum.PowerType.ComboPoints,
							[3] = "none",
							[4] = "none",
						},
						[104] = {
							[0] = "none",
							[1] = "none",
							[2] = Enum.PowerType.ComboPoints,
							[3] = "none",
							[4] = "none",
						},
						[105] = {
							[0] = "none",
							[1] = "none",
							[2] = Enum.PowerType.ComboPoints,
							[3] = "none",
							[4] = "none",
						},
					},
				},
			},
			castBar = {
				enable = true,
				minWidth = 200,
				width = 270,
				height = 24,
				texture = "Solid",
				font = "Expressway",
				fontSize = 12,
				fontOutline = "OUTLINE",
				frameStrata = "BACKGROUND",
				matchParentWidth = true,
				useClassColor = false,
				fgColor = { r = 0.5, g = 0.5, b = 1, a = 1 },
				bgColor = { r = 0, g = 0, b = 0, a = 0.8 },
				interruptColor = { r = 1, g = 0.25, b = 0.25, a = 1 },
				showBorder = true,
				borderSize = 1,
				borderColor = { r = 0, g = 0, b = 0, a = 1 },
				empoweredStageColors = {
					{ r = 0.35, g = 0.75, b = 1.00, a = 0.35 },
					{ r = 0.45, g = 1.00, b = 0.55, a = 0.35 },
					{ r = 1.00, g = 0.85, b = 0.25, a = 0.35 },
					{ r = 1.00, g = 0.50, b = 0.25, a = 0.35 },
					{ r = 0.85, g = 0.45, b = 1.00, a = 0.35 },
				},
				anchors = { "BOTTOM", "SCM_SecondaryResourceBar,SCM_PrimaryResourceBar,ANCHOR:1", "TOP", 0, 0 },
				icon = {
					enable = true,
					matchBarHeight = true,
					size = 24,
					zoom = 0.08,
					position = "LEFT",
				},
				ticks = {
					enable = true,
					width = 2,
					color = { r = 1, g = 1, b = 1, a = 1 },
				},
				spark = {
					enable = false,
					width = 2,
					height = 22,
					color = { r = 1, g = 1, b = 1, a = 1 },
					texture = "Solid",
					xOffset = 0,
					yOffset = 0,
					useCustomTexture = false,
					blendMode = "ADD",
				},
				spellName = {
					enable = true,
					anchors = { "LEFT", "LEFT", 3, 0 },
				},
				castDuration = {
					enable = true,
					anchors = { "RIGHT", "RIGHT", -3, 0 },
				},
			},
			testSetting = {
				[193063] = false,
			},
		},
	},
}

SCM.DefaultClassConfig = {
	spellConfig = {},
	anchorConfig = {},
	buffBarsAnchorConfig = {},
	itemConfig = {},
	customConfig = {},
}

SCM.Defaults.ActiveSwipeCooldownIDs = {
	version = 120105,
	cooldownIDs = {
		[88334] = 8921,
		[90218] = 8921,
		[93500] = 8921,
		[137439] = 8921,
		[143884] = 8921,
		[88314] = 93402,
		[90587] = 93402,
		[93501] = 93402,
		[137447] = 93402,
		[143951] = 93402,
		[71314] = 1822,
		[90576] = 1822,
		[91905] = 1822,
		[137448] = 1822,
		[138407] = 1822,
		[144018] = 1822,
		[71316] = 1079,
		[90572] = 1079,
		[91924] = 1079,
		[137449] = 1079,
		[138408] = 1079,
		[144085] = 1079,
		[88273] = 155625,
		[93159] = 155625,
		[148127] = 1264359,
		[12424] = 26573,
		[29346] = 26573,
		[179821] = 26573,
		[2057] = 10060,
		[2233] = 10060,
		[8193] = 10060,
		[74950] = 10060,
		[76932] = 10060,
		[100178] = 10060,
		[198967] = 10060,
		[2602] = 589,
		[94103] = 589,
		[105853] = 589,
		[108367] = 589,
		[108961] = 589,
		[196287] = 589,
		[105852] = 34914,
		[108366] = 34914,
		[11348] = 335467,
		[147200] = 335467,
		[103941] = 315496,
		[107199] = 315496,
		[111932] = 315496,
		[111933] = 315496,
		[134918] = 315496,
		[30847] = 1943,
		[105314] = 1943,
		[30853] = 32645,
		[105493] = 32645,
		[30844] = 703,
		[91850] = 703,
		[12665] = 470411,
		[13380] = 470411,
		[33015] = 470411,
		[113083] = 470411,
		[113506] = 470411,
		[142075] = 470411,
		[133441] = 348,
		[164597] = 348,
		[91902] = 172,
		[126023] = 172,
		[91901] = 980,
		[125986] = 980,
		[34925] = 1259790,
		[125297] = 1259790,
		[1979] = 264178,
		[106837] = 772,
		[106901] = 772,
		[107399] = 772,
		[107521] = 772,
	},
}

SCM.Defaults.GlobalSettingsTabs = {
	{ value = "General", text = "General" },
	{ value = "Auras", text = "Auras" },
	{ value = "Icons", text = "Icons" },
	{ value = "Cooldowns", text = "Cooldowns" },
	{ value = "Glow", text = "Glow" },
	{ value = "BuffBar", text = "Buff Bars" },
}
