--TODO: See if camera counter can be fixed

printf = printf or function(...) end

if RequiredScript == "lib/setups/setup" and Setup then

	local init_managers_original = Setup.init_managers
	local update_original = Setup.update

	function Setup:init_managers(managers, ...)
		managers.gameinfo = managers.gameinfo or GameInfoManager:new()
		managers.gameinfo:post_init()
		return init_managers_original(self, managers, ...)
	end

	function Setup:update(t, dt, ...)
		managers.gameinfo:update(t, dt)
		return update_original(self, t, dt, ...)
	end

end

if RequiredScript == "lib/setups/setup" and not Setup then

	GameInfoManager = GameInfoManager or class()

	GameInfoManager._TIMER_CALLBACKS = {
		default = {
			--Digital specific functions
			set = function(timers, key, timer)
				GameInfoManager._TIMER_CALLBACKS.default.update(timers, key, Application:time(), timer)
			end,
			start_count_up = function(timers, key)
				if timers[key] and timers[key].ext._visible then
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
				end
			end,
			start_count_down = function(timers, key)
				if timers[key] and timers[key].ext._visible then
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
				end
			end,
			pause = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, true)
			end,
			resume = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
			end,
			stop = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, false)
			end,

			--General functions
			update = function(timers, key, t, timer)
				if timers[key] then
					timers[key].timer_value = timer
					managers.gameinfo:_listener_callback("timer", "update", key, timers[key])
				end
			end,
			set_active = function(timers, key, status)
				if timers[key] and timers[key].active ~= status then
					timers[key].active = status
					managers.gameinfo:_listener_callback("timer", "set_active", key, timers[key])
				end
			end,
			set_jammed = function(timers, key, status)
				if timers[key] and timers[key].jammed ~= status then
					timers[key].jammed = status
					managers.gameinfo:_listener_callback("timer", "set_jammed", key, timers[key])
				end
			end,
			set_powered = function(timers, key, status)
				if timers[key] and timers[key].powered ~= status then
					timers[key].powered = status
					managers.gameinfo:_listener_callback("timer", "set_powered", key, timers[key])
				end
			end,
			set_upgradable = function(timers, key, status)
				if timers[key] and timers[key].upgradable ~= status then
					timers[key].upgradable = status
					managers.gameinfo:_listener_callback("timer", "set_upgradable", key, timers[key])
				end
			end,
		},
		overrides = {
			--Common functions
			stop_on_loud_pause = function(...)
				if not managers.groupai:state():whisper_mode() then
					GameInfoManager._TIMER_CALLBACKS.default.stop(...)
				else
					GameInfoManager._TIMER_CALLBACKS.default.pause(...)
				end
			end,
			stop_on_pause = function(...)
				GameInfoManager._TIMER_CALLBACKS.default.stop(...)
			end,

			[132864] = {	--Meltdown vault temperature
				set = function(timers, key, timer)
					if timer > 0 then
						GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					end
					GameInfoManager._TIMER_CALLBACKS.default.set(timers, key, timer)
				end,
				start_count_down = function(timers, key)
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, false)
				end,
				pause = function(...) end,
			},
			[101936] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--GO Bank time lock
			[139706] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Hoxton Revenge alarm	(UNTESTED)
			[132675] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Hoxton Revenge panic room time lock	(UNTESTED)
			[133922] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--The Diamond pressure plates timer
			[130022] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130122] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130222] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130422] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130522] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			--[130320] = { },	--The Diamond outer time lock
			--[130395] = { },	--The Diamond inner time lock
			--[101457] = { },	--Big Bank time lock door #1
			--[104671] = { },	--Big Bank time lock door #2
			--[167575] = { },	--Golden Grin BFD timer
			--[135034] = { },	--Lab rats cloaker safe 1
			--[135076] = { },	--Lab rats cloaker safe 2
			--[135246] = { },	--Lab rats cloaker safe 3
			--[135247] = { },	--Lab rats cloaker safe 4
			[141821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[141822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[141823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[140321] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[140322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[140323] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[139821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[139822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[139823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[141321] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[141322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[141323] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[140821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
			[140822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
			[140823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
		}
	}

	GameInfoManager._INTERACTIONS = {
		INTERACTION_TO_CALLBACK = {
			corpse_alarm_pager =				"_pager_event",
			gen_pku_crowbar =					"_special_equipment_interaction_handler",
			pickup_keycard =					"_special_equipment_interaction_handler",
			pickup_hotel_room_keycard =			"_special_equipment_interaction_handler",
			gage_assignment =					"_special_equipment_interaction_handler",
			pickup_boards =						"_special_equipment_interaction_handler",
			stash_planks_pickup =				"_special_equipment_interaction_handler",
			muriatic_acid =						"_special_equipment_interaction_handler",
			hydrogen_chloride =					"_special_equipment_interaction_handler",
			caustic_soda =						"_special_equipment_interaction_handler",
			press_pick_up =						"_special_equipment_interaction_handler",
			ring_band = 						"_special_equipment_interaction_handler",
			firstaid_box =						"_deployable_interaction_handler",
			ammo_bag =							"_deployable_interaction_handler",
			doctor_bag =						"_deployable_interaction_handler",
			bodybags_bag =						"_deployable_interaction_handler",
			grenade_crate =						"_deployable_interaction_handler",
		},
		INTERACTION_TO_CARRY = {
			weapon_case =					"weapon",
			weapon_case_axis_z =			"weapon",
			samurai_armor =					"samurai_suit",
			gen_pku_warhead_box =			"warhead",
			corpse_dispose =				"person",
			hold_open_case =				"drone_control_helmet",	--May be reused in future heists for other loot
			cut_glass = 					"showcase",
			diamonds_pickup = 				"diamonds_dah",
			red_diamond_pickup = 			"red_diamond",
			red_diamond_pickup_no_axis = 	"red_diamond",

			hold_open_shopping_bag = 		"shopping_bag",
			hold_take_toy = 				"robot_toy",
			hold_take_wine = 				"ordinary_wine",
			hold_take_expensive_wine = 		"expensive_vine",
			hold_take_diamond_necklace =	"diamond_necklace",
			hold_take_vr_headset = 			"vr_headset",
			hold_take_shoes = 				"women_shoes",
			hold_take_old_wine = 			"old_wine",
		},
		BAGGED_IDS = {
			painting_carry_drop = true,
			carry_drop = true,
			safe_carry_drop = true,
			goat_carry_drop = true,
		},
		COMPOSITE_LOOT_UNITS = {
			gen_pku_warhead_box = 2,	--[132925] = 2, [132926] = 2, [132927] = 2,	--Meltdown warhead cases
			--hold_open_bomb_case = 4,	--The Bomb heists cases, extra cases on docks screws with counter...
			[103428] = 4, [103429] = 3, [103430] = 2, [103431] = 1,	--Shadow Raid armor
			--[102913] = 1, [102915] = 1, [102916] = 1,	--Train Heist turret (unit fixed, need workaround)
			[105025] = 10, [105026] = 9, [104515] = 8, [104518] = 7, [104517] = 6, [104522] = 5, [104521] = 4, [104520] = 3, [104519] = 2, [104523] = 1, --Slaughterhouse alt 1.
			[105027] = 10, [105028] = 9, [104525] = 8, [104524] = 7, [104490] = 6, [100779] = 5, [100778] = 4, [100777] = 3, [100773] = 2, [100771] = 1, --Slaughterhouse alt 2.
		},
		CONDITIONAL_IGNORE_IDS = {
			ff3_vault = function(wall_id)
				if managers.job:current_level_id() == "framing_frame_3" then
					for _, unit in pairs(World:find_units_quick("all", 1)) do
						if unit:editor_id() == wall_id then
							return true
						end
					end
				end
			end,

			--FF3 lounge vault
			[100548] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			[100549] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			[100550] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			[100551] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			[100552] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			[100553] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			[100554] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			[100555] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(100448) end,
			--FF3 bedroom vault
			[100556] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			[100557] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			[100558] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			[100559] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			[100560] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			[100561] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			[100562] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			[100563] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101431) end,
			--FF3 upstairs vault
			[100564] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
			[100566] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
			[100567] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
			[100568] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
			[100569] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
			[100570] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
			[100571] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
			[100572] = function() return GameInfoManager._INTERACTIONS.CONDITIONAL_IGNORE_IDS.ff3_vault(101423) end,
		},
		IGNORE_IDS = {
			watchdogs_2 = {	--Watchdogs day 2 (8x coke)
				[100054] = true, [100058] = true, [100426] = true, [100427] = true, [100428] = true, [100429] = true, [100491] = true, [100492] = true, [100494] = true, [100495] = true,
			},
			family = {	--Diamond store (1x money)
				[100899] = true,
			},	--Hotline Miami day 1 (1x money)
			mia_1 = {	--Hotline Miami day 1 (1x money)
				[104526] = true,
			},
			welcome_to_the_jungle_1 = {	--Big Oil day 1 (1x money, 1x gold)
				[100886] = true, [100872] = true,
			},
			mus = {	--The Diamond (RNG)
				[300047] = true, [300686] = true, [300457] = true, [300458] = true, [301343] = true, [301346] = true,
			},
			arm_und = {	--Transport: Underpass (8x money)
				[101237] = true, [101238] = true, [101239] = true, [103835] = true, [103836] = true, [103837] = true, [103838] = true, [101240] = true,
			},
			ukrainian_job = {	--Ukrainian Job (3x money)
				[101514] = true,
				[102052] = true,
				[102402] = true,
			},
			firestarter_2 = {	--Firestarter day 2 (1x keycard)
				[107208] = true,
			},
			big = {	--Big Bank (1x keycard)
				[101499] = true,
			},
			roberts = {	--GO Bank (1x keycard)
				[106104] = true,
			},
			jewelry_store = {	--Jewelry Store (2x money)
				[102052] = true,
				[102402] = true,
			},
			fish = {	--Yacht (1x artifact painting)
				[500533] = true,
			},
			dah = {	-- The Diamond Heist (1x Red Diamond Showcase)
				[100952] = true,
			}
		},
	}
	GameInfoManager._INTERACTIONS.IGNORE_IDS.watchdogs_2_day = table.deep_map_copy(GameInfoManager._INTERACTIONS.IGNORE_IDS.watchdogs_2)
	GameInfoManager._INTERACTIONS.IGNORE_IDS.welcome_to_the_jungle_1_night = table.deep_map_copy(GameInfoManager._INTERACTIONS.IGNORE_IDS.welcome_to_the_jungle_1)

	GameInfoManager.CAMERAS = {
		["6c5d032fe7e08d01"] = "standard",	--units/payday2/equipment/gen_equipment_security_camera/gen_equipment_security_camera
		["0c721a9fa6d2fe0a"] = "standard",	--units/world/props/security_camera/security_camera
		["c64ffaefb39415bc"] = "standard",	--units/world/props/security_camera/security_camera_white
		["490a9313f945cccf"] = "drone",		--units/pd2_dlc_dark/equipment/gen_drone_camera/gen_drone_camera
	}

	GameInfoManager._EQUIPMENT = {
		SENTRY_KEYS = {
			--unit:name():key() for friendly sentries
			["07bd083cc5f2d3ba"] = true,	--Standard U100+
			["c71d763cd8d33588"] = true,	--Suppressed U100+
			["b1f544e379409e6c"] = true,	--GGC BFD sentries
		},
		INTERACTION_ID_TO_TYPE = {
			firstaid_box =						"doc_bag",
			ammo_bag =							"ammo_bag",
			doctor_bag =						"doc_bag",
			bodybags_bag =						"body_bag",
			grenade_crate =						"grenade_crate",
		},
		AMOUNT_OFFSETS = {
			--interaction_id or editor_id
			firstaid_box = -1,	--GGC drill asset, HB infirmary
		},
		AGGREAGATE_ITEMS = {
			["first_aid_kit"] = "first_aid_kits",	-- Aggregate all FAKs
			hox_2 = {	--Hoxton breakout
				[136859] = "armory_grenade",
				[136870] = "armory_grenade",
				[136869] = "armory_grenade",
				[136864] = "armory_grenade",
				[136866] = "armory_grenade",
				[136860] = "armory_grenade",
				[136867] = "armory_grenade",
				[136865] = "armory_grenade",
				[136868] = "armory_grenade",
				[136846] = "armory_ammo",
				[136844] = "armory_ammo",
				[136845] = "armory_ammo",
				[136847] = "armory_ammo",
				[101470] = "infirmary_cabinet",
				[101472] = "infirmary_cabinet",
				[101473] = "infirmary_cabinet",
			},
			kenaz = {	--GGC
				[151596] = "armory_grenade",
				[151597] = "armory_grenade",
				[151598] = "armory_grenade",
				[151611] = "armory_ammo",
				[151612] = "armory_ammo",
			},
			born = {	--Biker heist
				[100776] = "bunker_grenade",
				[101226] = "bunker_grenade",
				[101469] = "bunker_grenade",
				[101472] = "bunker_ammo",
				[101473] = "bunker_ammo",
			},
			spa = {		--10-10
				[132935] = "armory_ammo",
				[132938] = "armory_ammo",
				[133085] = "armory_ammo",
				[133088] = "armory_ammo",
				[133835] = "armory_ammo",
				[133838] = "armory_ammo",
				[134135] = "armory_ammo",
				[134138] = "armory_ammo",
				[137885] = "armory_ammo",
				[137888] = "armory_ammo",
			},
		},
	}

	GameInfoManager._UNITS = {
		TWEAK_ID_BY_NAME = {
			[tostring(Idstring("units/pd2_dlc_born/characters/npc_male_mechanic/npc_male_mechanic"))] = "mechanic",
			[tostring(Idstring("units/pd2_dlc_born/characters/npc_male_mechanic/npc_male_mechanic_husk"))] = "mechanic"
		}
	}

	GameInfoManager._BUFFS = {
		on_activate = {
			armor_break_invulnerable_debuff = function(id, data)
				local upgrade_value = managers.player:upgrade_value("temporary", "armor_break_invulnerable")
				managers.gameinfo:event("timed_buff", "activate", "armor_break_invulnerable", { t = data.t, duration = upgrade_value and upgrade_value[1] or 0 })
			end,
		},
		on_set_duration = {
			overkill = function(id, data)
				if managers.player:has_category_upgrade("player", "overkill_all_weapons") then
					managers.gameinfo:event("timed_buff", "activate", "overkill_aced", data)
				end
			end,
		},
		on_set_value = {
			overkill = function(id, data)
				if managers.player:has_category_upgrade("player", "overkill_all_weapons") then
					managers.gameinfo:event("buff", "set_value", "overkill_aced", { value = data.value })
				end
			end,
		},

		--Temporary upgrades
		temporary = {
			chico_injector = "chico_injector",
			damage_speed_multiplier = "second_wind",
			dmg_multiplier_outnumbered = "underdog",
			dmg_dampener_outnumbered = "underdog_aced",
			dmg_dampener_outnumbered_strong = "overdog",
			dmg_dampener_close_contact = { "close_contact_1", "close_contact_2", "close_contact_3" },
			overkill_damage_multiplier = "overkill",
			--melee_kill_increase_reload_speed = "bloodthirst_aced",
			passive_revive_damage_reduction = { "pain_killer", "pain_killer_aced" },
			berserker_damage_multiplier = { "swan_song", "swan_song_aced" },
			first_aid_damage_reduction = "quick_fix",
			increased_movement_speed = "running_from_death_aced",
			reload_weapon_faster = "running_from_death_basic",
			revive_damage_reduction = "combat_medic",
			revived_damage_resist = "up_you_go",
			swap_weapon_faster = "running_from_death_basic",
			team_damage_speed_multiplier_received = "second_wind",
			melee_life_leech = "life_drain_debuff",
			loose_ammo_restore_health = "medical_supplies_debuff",
			loose_ammo_give_team = "ammo_give_out_debuff",
			armor_break_invulnerable = "armor_break_invulnerable_debuff",
			single_shot_fast_reload = "aggressive_reload_aced",
			unseen_strike = "unseen_strike",

			--"properties"
			bloodthirst_reload_speed = "bloodthirst_aced",
			revived_damage_reduction = "pain_killer",
		},
		cooldown = {
			long_dis_revive = "inspire_revive_debuff",
		},
		--Team upgrades
		damage_dampener = {
			hostage_multiplier =  { id = "crew_chief_9", level = 9 },
			team_damage_reduction = { id = "crew_chief_1", level = 1 },
		},
		stamina = {
			multiplier = { id = "endurance", level = 0 },
			passive_multiplier = { id = "crew_chief_3", level = 3 },
			hostage_multiplier =  { id = "crew_chief_9", level = 9 },
		},
		health = {
			passive_multiplier = { id = "crew_chief_5", level = 5 },
			hostage_multiplier = { id = "crew_chief_9", level = 9 },
		},
		armor = {
			multiplier =  { id = "crew_chief_7", level = 7 },
			regen_time_multiplier = { id = "bulletproof", level = 0 },
			passive_regen_time_multiplier = { id = "armorer_9", level = 9 },
		},
		damage = {
			hostage_absorption = { id = "forced_friendship", level = 0 },
		},
--[[
		weapon = {
			recoil_multiplier = "leadership_aced",
			suppression_recoil_multiplier = "leadership_aced",
		},
		pistol = {
			recoil_multiplier = "leadership",
			suppression_recoil_multiplier = "leadership",
		},
		akimbo = {
			recoil_multiplier = "leadership",
			suppression_recoil_multiplier = "leadership",
		},
]]
	}

	function GameInfoManager:init()
		self._t = 0
		self._scheduled_callbacks = {}
		self._listeners = {}

		self._timers = {}
		self._units = {}
		self._unit_count = {}
		self._minions = {}
		self._turrets = {}
		self._pagers = {}
		self._loot = {}
		self._special_equipment = {}
		self._ecms = {}
		self._deployables = {
			ammo_bag = {},
			doc_bag = {},
			body_bag = {},
			grenade_crate = {},
		}
		self._sentries = {}
		self._buffs = {}
		self._player_actions = {}
		self._cameras = {}

		self._auto_expire_timers = {
			on_expire = {},
			expire_t = {},
		}
		self._timed_buff_expire_clbk = callback(self, self, "_on_timed_buff_expired")
		self._timed_stack_expire_clbk = callback(self, self, "_on_timed_stack_expired")
		self._player_actions_expire_clbk = callback(self, self, "_on_player_action_expired")
	end

	function GameInfoManager:post_init()
		for _, clbk in ipairs(GameInfoManager.post_init_events or {}) do
			clbk()
		end

		GameInfoManager.post_init_events = nil
	end

	function GameInfoManager:update(t, dt)
		self._t = t
		self:_update_player_timer_expiration(t, dt)

		while self._scheduled_callbacks[1] and self._scheduled_callbacks[1].t <= t do
			local data = table.remove(self._scheduled_callbacks, 1)
			data.clbk(unpack(data.args))
		end
	end

	function GameInfoManager:add_scheduled_callback(id, delay, clbk, ...)
		local t = self._t + delay
		local pos = 1

		for i, data in ipairs(self._scheduled_callbacks) do
			if data.t >= t then break end
			pos = pos + 1
		end

		table.insert(self._scheduled_callbacks, pos, { id = id, t = t, clbk = clbk, args = { ... } })
	end

	function GameInfoManager:remove_scheduled_callback(id)
		for i = 1, #self._scheduled_callbacks, 1 do
			if data.id == id then
				table.remove(self._scheduled_callbacks, i)
				i = i - 1
			end
		end
	end

	function GameInfoManager:event(source, ...)
		local target = "_" .. source .. "_event"

		if self[target] then
			self[target](self, ...)
		else
			printf("Error: No event handler for %s\n", target)
		end
	end

	function GameInfoManager:get_timers(key)
		if key then
			return self._timers[key]
		else
			return self._timers
		end
	end

	function GameInfoManager:get_units(key)
		if key then
			return self._units[key]
		else
			return self._units
		end
	end

	function GameInfoManager:get_unit_count(id)
		if id then
			return self._unit_count[id] or 0
		else
			return self._unit_count
		end
	end

	function GameInfoManager:get_minions(key)
		if key then
			return self._minions[key]
		else
			return self._minions
		end
	end

	function GameInfoManager:get_pagers(key)
		if key then
			return self._pagers[key]
		else
			return self._pagers
		end
	end

	function GameInfoManager:get_special_equipment(key)
		if key then
			return self._special_equipment[key]
		else
			return self._special_equipment
		end
	end

	function GameInfoManager:get_loot(key)
		if key then
			return self._loot[key]
		else
			return self._loot
		end
	end

	function GameInfoManager:get_ecms(key)
		if key then
			return self._ecms[key]
		else
			return self._ecms
		end
	end

	function GameInfoManager:get_cameras(key)
		if key then
			return self._cameras[key]
		else
			return self._cameras
		end
	end

	function GameInfoManager:get_deployables(type, key)
		if type and key then
			return self._deployables[type][key]
		elseif type then
			return self._deployables[type]
		else
			return self._deployables
		end
	end

	function GameInfoManager:get_sentries(key)
		if key then
			return self._sentries[key]
		else
			return self._sentries
		end
	end

	function GameInfoManager:get_buffs(id)
		if id then
			return self._buffs[id]
		else
			return self._buffs
		end
	end

	function GameInfoManager:get_player_actions(id)
		if id then
			return self._player_actions[id]
		else
			return self._player_actions
		end
	end

	function GameInfoManager:_timer_event(event, key, ...)
		if event == "create" then
			if not self._timers[key] then
				local unit, ext, device_type = ...
				local id = unit:editor_id()
				self._timers[key] = { unit = unit, ext = ext, device_type = device_type, id = id, jammed = false, powered = true, upgradable = false }
				self:_listener_callback("timer", "create", key, self._timers[key])
			end
		elseif event == "destroy" then
			if self._timers[key] then
				GameInfoManager._TIMER_CALLBACKS.default.set_active(self._timers, key, false)
				self:_listener_callback("timer", "destroy", key, self._timers[key])
				self._timers[key] = nil
			end
		elseif self._timers[key] then
			local timer_id = self._timers[key].id
			local timer_override = GameInfoManager._TIMER_CALLBACKS.overrides[timer_id]

			if timer_override and timer_override[event] then
				timer_override[event](self._timers, key, ...)
			else
				GameInfoManager._TIMER_CALLBACKS.default[event](self._timers, key, ...)
			end
		end
	end

	function GameInfoManager:_unit_event(event, key, data)
		if event == "add" then
			if not self._units[key] then
				local unit_type = data.unit:base()._tweak_table
				self._units[key] = { unit = data.unit, type = unit_type }
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", unit_type, 1)
			end
		elseif event == "remove" then
			if self._units[key] then
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", self._units[key].type, -1)
				self._units[key] = nil

				if self._minions[key] then
					self:_minion_event("remove", key)
				end
			end
		end
	end

	function GameInfoManager:_unit_count_event(event, unit_type, value)
		if event == "change" then
			if value ~= 0 then
				self._unit_count[unit_type] = (self._unit_count[unit_type] or 0) + value
				self:_listener_callback("unit_count", "change", unit_type, value)
			end
		elseif event == "set" then
			self:_unit_count_event("change", unit_type, value - (self._unit_count[unit_type] or 0))
		end
	end

	function GameInfoManager:_minion_event(event, key, data)
		if event == "add" then
			if not self._minions[key] then
				self._minions[key] = { unit = data.unit, kills = 0 }
				self:_listener_callback("minion", "add", key, self._minions[key])
				self:_unit_count_event("change", "minion", 1)
			end
		elseif self._minions[key] then
			if event == "remove" then
				self:_listener_callback("minion", "remove", key, self._minions[key])
				self:_unit_count_event("change", "minion", -1)
				self._minions[key] = nil
			else
				if event == "set_health_ratio" then
					self._minions[key].health_ratio = data.health_ratio
				elseif event == "increment_kills" then
					event = "set_kills"
					self._minions[key].kills = self._minions[key].kills + 1
				elseif event == "set_owner" then
					self._minions[key].owner = data.owner
				elseif event == "set_damage_resistance" then
					self._minions[key].damage_resistance = data.damage_resistance
				elseif event == "set_damage_multiplier" then
					self._minions[key].damage_multiplier = data.damage_multiplier
				end

				self:_listener_callback("minion", event, key, self._minions[key])
			end
		end
	end

	function GameInfoManager:_turret_event(event, key, unit)
		if event == "add" then
			if not self._turrets[key] then
				self._turrets[key] = unit
				self:_unit_count_event("change", "turret", 1)
			end
		elseif event == "remove" then
			if self._turrets[key] then
				self:_unit_count_event("change", "turret", -1)
				self._turrets[key] = nil
			end
		end
	end

	function GameInfoManager:_interactive_unit_event(event, key, data)
		local lookup = GameInfoManager._INTERACTIONS
		local level_id = managers.job:current_level_id()

		if lookup.IGNORE_IDS[level_id] and lookup.IGNORE_IDS[level_id][data.editor_id] then
			return
		end

		if lookup.CONDITIONAL_IGNORE_IDS[data.editor_id] then
			if lookup.CONDITIONAL_IGNORE_IDS[data.editor_id]() then
				return
			end
		end

		local interact_clbk = lookup.INTERACTION_TO_CALLBACK[data.interact_id]

		if interact_clbk then
			self[interact_clbk](self, event, key, data)
		else
			local carry_id = data.unit:carry_data() and data.unit:carry_data():carry_id() or lookup.INTERACTION_TO_CARRY[data.interact_id] or (self._loot[key] and self._loot[key].carry_id)

			if carry_id then
				data.carry_id = carry_id
				self:_loot_interaction_handler(event, key, data)
			else
				self:_listener_callback("interactable_unit", event, key, data.unit, data.interact_id, carry_id)
			end
		end
	end

	function GameInfoManager:_pager_event(event, key, data)
		if event == "add" then
			if not self._pagers[key] then
				local t = Application:time()

				self._pagers[key] = {
					unit = data.unit,
					active = true,
					answered = false,
					start_t = t,
					expire_t = t + 12,
				}
				self:_listener_callback("pager", "add", key, self._pagers[key])
			end
		elseif self._pagers[key] then
			if event == "remove" then
				if self._pagers[key].active then
					self._pagers[key].active = nil
					self:_listener_callback("pager", "remove", key, self._pagers[key])
				end
			elseif event == "set_answered" then
				if not self._pagers[key].answered then
					self._pagers[key].answered = true
					self:_listener_callback("pager", "set_answered", key, self._pagers[key])
				end
			end
		end
	end

	function GameInfoManager:_special_equipment_interaction_handler(event, key, data)
		if event == "add" then
			if not self._special_equipment[key] then
				self._special_equipment[key] = { unit = data.unit, interact_id = data.interact_id }
				self:_listener_callback("special_equipment", "add", key, self._special_equipment[key])
				self:_special_equipment_count_event("change", data.interact_id, 1, self._special_equipment[key])
			end
		elseif event == "remove" then
			if self._special_equipment[key] then
				self:_listener_callback("special_equipment", "remove", key, self._special_equipment[key])
				self:_special_equipment_count_event("change", data.interact_id, -1, self._special_equipment[key])
				self._special_equipment[key] = nil
			end
		end
	end

	function GameInfoManager:_special_equipment_count_event(event, interact_id, value, data)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("special_equipment_count", "change", interact_id, value, data)
			end
		end
	end

	function GameInfoManager:_deployable_interaction_handler(event, key, data)
		local type = GameInfoManager._EQUIPMENT.INTERACTION_ID_TO_TYPE[data.interact_id]

		if self._deployables[type][key] then
			local active = event == "add"
			local offset = GameInfoManager._EQUIPMENT.AMOUNT_OFFSETS[data.unit:editor_id()] or GameInfoManager._EQUIPMENT.AMOUNT_OFFSETS[data.interact_id]

			self:_bag_deployable_event("set_active", key, { active = active }, type)

			if active and offset then
				self:_bag_deployable_event("set_amount_offset", key, { amount_offset = offset }, type)
			end
		end
	end

	function GameInfoManager:_loot_interaction_handler(event, key, data)
		if event == "add" then
			if not self._loot[key] then
				local composite_lookup = GameInfoManager._INTERACTIONS.COMPOSITE_LOOT_UNITS
				local count = composite_lookup[data.editor_id] or composite_lookup[data.interact_id] or 1
				local bagged = GameInfoManager._INTERACTIONS.BAGGED_IDS[data.interact_id] and true or false

				self._loot[key] = { unit = data.unit, carry_id = data.carry_id, count = count, bagged = bagged }
				self:_listener_callback("loot", "add", key, self._loot[key])
				self:_loot_count_event("change", data.carry_id, bagged, count, self._loot[key])
			end
		elseif event == "remove" then
			if self._loot[key] then
				self:_listener_callback("loot", "remove", key, self._loot[key])
				self:_loot_count_event("change", data.carry_id, self._loot[key].bagged, -self._loot[key].count, self._loot[key])
				self._loot[key] = nil
			end
		end
	end

	function GameInfoManager:_loot_count_event(event, carry_id, bagged, value, data)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("loot_count", "change", carry_id, bagged, value, data)
			end
		end
	end

	function GameInfoManager:_ecm_event(event, key, data)
		if event == "create" then
			if not self._ecms[key] then
				self._ecms[key] = { unit = data.unit }
				self:_listener_callback("ecm", event, key, self._ecms[key])
			end
		elseif self._ecms[key] then
			if event == "set_jammer_battery" then
				if self._ecms[key].jammer_active then
					self._ecms[key].jammer_battery = data.jammer_battery
					self:_listener_callback("ecm", event, key, self._ecms[key])
				end
			elseif event == "set_retrigger_delay" then
				if self._ecms[key].retrigger_active then
					self._ecms[key].retrigger_delay = data.retrigger_delay
					self:_listener_callback("ecm", event, key, self._ecms[key])
				end
			elseif event == "set_jammer_active" then
				if self._ecms[key].jammer_active ~= data.jammer_active then
					self._ecms[key].jammer_active = data.jammer_active
					self:_listener_callback("ecm", event, key, self._ecms[key])
				end
			elseif event == "set_retrigger_active" then
				if self._ecms[key].retrigger_active ~= data.retrigger_active then
					self._ecms[key].retrigger_active = data.retrigger_active
					self:_listener_callback("ecm", event, key, self._ecms[key])
				end
			elseif event == "set_owner" then
				self._ecms[key].owner = data.owner
				self:_listener_callback("ecm", event, key, self._ecms[key])
			elseif event == "set_upgrade_level" then
				self._ecms[key].upgrade_level = data.upgrade_level
				self:_listener_callback("ecm", event, key, self._ecms[key])
			elseif event == "destroy" then
				self:_listener_callback("ecm", event, key, self._ecms[key])
				self._ecms[key] = nil
			end
		end
	end

	function GameInfoManager:_doc_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "doc_bag")
	end

	function GameInfoManager:_ammo_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "ammo_bag")
	end

	function GameInfoManager:_body_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "body_bag")
	end

	function GameInfoManager:_grenade_crate_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "grenade_crate")
	end

	function GameInfoManager:_bag_deployable_event(event, key, data, type)
		if event == "create" then
			if not self._deployables[type][key] then
				self._deployables[type][key] = { unit = data.unit, type = type }
				self:_listener_callback(type, "create", key, self._deployables[type][key])
			end
		elseif self._deployables[type][key] then
			local function update_aggregate_attribute(aggregate_key, attr)
				if not self._deployables[type][aggregate_key] then return end

				local total = 0
				for k, v in pairs(self._deployables[type][aggregate_key].aggregate_members or {}) do
					if self._deployables[type][k].active then
						total = total + (self._deployables[type][k][attr] or 0)
					end
				end

				self._deployables[type][aggregate_key][attr] = total
				self:_listener_callback(type, "set_" .. attr, aggregate_key, self._deployables[type][aggregate_key])
			end

			local aggregate_key = GameInfoManager._EQUIPMENT.AGGREAGATE_ITEMS[self._deployables[type][key].unit:editor_id()]

			if event == "destroy" then
				self:_listener_callback(type, "destroy", key, self._deployables[type][key])
				self._deployables[type][key] = nil

				if aggregate_key and self._deployables[type][aggregate_key] then
					self._deployables[type][aggregate_key].aggregate_members[key] = nil

					if next(self._deployables[type][aggregate_key].aggregate_members or {}) == nil then
						self:_listener_callback(type, "destroy", aggregate_key, self._deployables[type][aggregate_key])
						self._deployables[type][aggregate_key] = nil
					end
				end
			elseif event == "set_active" then
				if aggregate_key then
					self._deployables[type][key].aggregate_key = aggregate_key
				end

				if self._deployables[type][key].active ~= data.active then
					self._deployables[type][key].active = data.active
					self:_listener_callback(type, "set_active", key, self._deployables[type][key])
				end

				if aggregate_key then
					self._deployables[type][aggregate_key] = self._deployables[type][aggregate_key] or {
						position = self._deployables[type][key].unit:interaction():interact_position(),
						aggregate_members = {},
					}
					self._deployables[type][aggregate_key].aggregate_members[key] = true
					--TODO: Update position for each member added?

					local aggregate_active = false
					for k, v in pairs(self._deployables[type][aggregate_key].aggregate_members or {}) do
						if self._deployables[type][k].active then
							aggregate_active = true
							break
						end
					end

					if self._deployables[type][aggregate_key].active ~= aggregate_active then
						self._deployables[type][aggregate_key].active = aggregate_active
						self:_listener_callback(type, "set_active", aggregate_key, self._deployables[type][aggregate_key])
					end

					update_aggregate_attribute(aggregate_key, "amount")
					update_aggregate_attribute(aggregate_key, "max_amount")
					update_aggregate_attribute(aggregate_key, "amount_offset")
				end
			elseif event == "set_owner" then
				self._deployables[type][key].owner = data.owner
				self:_listener_callback(type, "set_owner", key, self._deployables[type][key])

				--if aggregate_key then
				--	self._deployables[type][aggregate_key].owner = owner
				--	self:_listener_callback(type, "set_owner", aggregate_key, self._deployables[type][aggregate_key])
				--end
			elseif event == "set_max_amount" then
				self._deployables[type][key].max_amount = data.max_amount
				self:_listener_callback(type, "set_max_amount", key, self._deployables[type][key])

				if aggregate_key then
					update_aggregate_attribute(aggregate_key, "max_amount")
				end
			elseif event == "set_amount_offset" then
				self._deployables[type][key].amount_offset = data.amount_offset
				self:_listener_callback(type, "set_amount_offset", key, self._deployables[type][key])

				if aggregate_key then
					update_aggregate_attribute(aggregate_key, "amount_offset")
				end
			elseif event == "set_amount" then
				self._deployables[type][key].amount = data.amount
				self:_listener_callback(type, "set_amount", key, self._deployables[type][key])

				if aggregate_key then
					update_aggregate_attribute(aggregate_key, "amount")
				end
			end
		end
	end

	function GameInfoManager:_sentry_event(event, key, data)
		if event == "create" then
			if not self._sentries[key] and GameInfoManager._EQUIPMENT.SENTRY_KEYS[tostring(data.unit:name():key())] then
				self._sentries[key] = { unit = data.unit, kills = 0 }
				self:_listener_callback("sentry", event, key, self._sentries[key])
			end
		elseif self._sentries[key] then
			if event == "set_active" then
				if self._sentries[key].active == data.active then return end
				self._sentries[key].active = data.active
			elseif event == "set_ammo_ratio" then
				self._sentries[key].ammo_ratio = data.ammo_ratio
			elseif event == "increment_kills" then
				event = "set_kills"
				self._sentries[key].kills = self._sentries[key].kills + 1
			elseif event == "set_health_ratio" then
				self._sentries[key].health_ratio = data.health_ratio
			elseif event == "set_owner" then
				self._sentries[key].owner = data.owner
			elseif event == "destroy" then
				self:_sentry_event("set_active", key, { active = false })
				self._sentries[key] = nil
			end

			self:_listener_callback("sentry", event, key, self._sentries[key])
		end
	end

	function GameInfoManager:_whisper_mode_event(event, key, status)
		self:_listener_callback("whisper_mode", "change", key, status)
	end

	function GameInfoManager:_temporary_buff_event(event, data)
		local buff_data = GameInfoManager._BUFFS[data.category][data.upgrade]
		local id = data.level and type(buff_data) == "table" and buff_data[data.level] or buff_data

		if id then
			self:_timed_buff_event(event, id, data)
			if data.value ~= 0 then
				self:_buff_event("set_value", id, { value = data.value })
			end
		else
			printf("Unknown temporary buff event: %s %s %s\n", event, data.category, data.upgrade)
			for k, v in pairs(data or {}) do
				printf("\t%s -> %s", tostring(k), tostring(v))
			end
		end
	end

	function GameInfoManager:_timed_buff_event(event, id, data)
		self:_buff_event(event, id, data)

		if event == "activate" then
			self:_buff_event("set_duration", id, { t = data.t, duration = data.duration, expire_t = data.expire_t })
			self:_add_player_timer_expiration(id, id, self._buffs[id].expire_t, self._timed_buff_expire_clbk)
		elseif event == "deactivate" then
			self:_remove_player_timer_expiration(id)
		end
	end

	function GameInfoManager:_timed_stack_buff_event(event, id, data)
		--printf("GameInfoManager:_timed_stack_buff_event(%s, %s, %s)\n", tostring(event), tostring(id), tostring(data))

		if event == "add_stack" then
			if not self._buffs[id] then
				self:_buff_event("activate", id)
				self._buffs[id].stacks = {}
			end

			local t = data.t or Application:time()
			local expire_t = data.expire_t or data.duration and (data.duration + t) or t
			local key = string.format("%s_%f_%f", id, t, math.random())

			local i = #self._buffs[id].stacks
			while self._buffs[id].stacks[i] and self._buffs[id].stacks[i].expire_t > expire_t do
				i = i - 1
			end
			table.insert(self._buffs[id].stacks, i + 1, { key = key, t = t, expire_t = expire_t })
			self:_add_player_timer_expiration(key, id, expire_t, self._timed_stack_expire_clbk)

			self:_listener_callback("buff", "add_timed_stack", id, self._buffs[id])
		end
	end

	function GameInfoManager:_buff_event(event, id, data)
		--printf("GameInfoManager:_buff_event(%s %s)\n", event, id)

		if event == "activate" then
			if not self._buffs[id] then
				self._buffs[id] = data or {}
			else
				return
			end
		elseif self._buffs[id] then
			if event == "deactivate" then
				self._buffs[id] = nil
			elseif event == "set_duration" then
				local t = data.t or Application:time()
				local expire_t = data.expire_t or data.duration and (data.duration + t) or t
				self._buffs[id].t = t
				self._buffs[id].expire_t = expire_t
			elseif event == "set_stack_count" then
				self._buffs[id].stack_count = data.stack_count
			elseif event == "change_stack_count" then
				self._buffs[id].stack_count = (self._buffs[id].stack_count or 0) + data.difference
				event = "set_stack_count"
			elseif event == "set_progress" then
				self._buffs[id].progress = data.progress
			elseif event == "set_value" then
				self._buffs[id].show_value = data.show_value
				self._buffs[id].value = data.value
			elseif event == "decrease_duration" then
				self._buffs[id].expire_t = self._buffs[id].expire_t - data.decrease
				event = "set_duration"
				self:_remove_player_timer_expiration(id)
				self:_add_player_timer_expiration(id, id, self._buffs[id].expire_t, self._timed_buff_expire_clbk)
			end
		else
			return
		end

		self:_listener_callback("buff", event, id, self._buffs[id])

		local clbk_name = "on_" .. event
		if GameInfoManager._BUFFS[clbk_name] and GameInfoManager._BUFFS[clbk_name][id] then
			GameInfoManager._BUFFS[clbk_name][id](id, self._buffs[id])
		end
	end

	function GameInfoManager:_team_buff_event(event, data)
		local buff_data = GameInfoManager._BUFFS[data.category] and GameInfoManager._BUFFS[data.category][data.upgrade]
		local id = buff_data and buff_data.id
		local level = buff_data and buff_data.level

		if id then
			if event == "activate" then
				local was_active = self._buffs[id]

				if not was_active then
					self:_buff_event("activate", id)
					self._buffs[id].peers = {}
					self._buffs[id].level = level
				end

				if not self._buffs[id].peers[data.peer] then
					self._buffs[id].peers[data.peer] = true
					self:_buff_event("change_stack_count", id, { difference = 1 })
				end

				if not was_active and data.value ~= 0 then
					self:_buff_event("set_value", id, { value = data.value })
				end
			elseif event == "deactivate" then
				if self._buffs[id] and self._buffs[id].peers[data.peer] then
					self._buffs[id].peers[data.peer] = nil
					self:_buff_event("change_stack_count", id, { difference = -1 })

					if next(self._buffs[id].peers) == nil then
						self:_buff_event("deactivate", id)
					end
				end
			end
		else
			printf("Unknown team buff event: %s %s %s\n", event, data.category, data.upgrade)
		end
	end

	function GameInfoManager:_player_action_event(event, id, data)
		--printf("GameInfoManager:_player_action_event(%s %s)", event, id)

		if event == "activate" then
			if not self._player_actions[id] then
				self._player_actions[id] = {}
				self:_listener_callback("player_action", "activate", id, self._player_actions[id])
			end

			if data and (data.duration or data.expire_t) then
				self:_player_action_event("set_duration", id, data)
				self:_add_player_timer_expiration(id, id, self._player_actions[id].expire_t, self._player_actions_expire_clbk)
			end
		elseif self._player_actions[id] then
			if event == "deactivate" then
				self:_remove_player_timer_expiration(id)
				self._player_actions[id] = nil
			elseif event == "set_duration" then
				local t = data.t or Application:time()
				local expire_t = data.expire_t or data.duration and (data.duration + t) or t
				self._player_actions[id].t = t
				self._player_actions[id].expire_t = expire_t
			elseif event == "set_data" then
				self._player_actions[id].data = data
			end

			self:_listener_callback("player_action", event, id, self._player_actions[id])
		end
	end

	function GameInfoManager:_camera_event(event, key, data)
		if event == "create" then
			if not self._cameras[key] then
				self._cameras[key] = { unit = data.unit }
				self:_listener_callback("camera", event, key, self._cameras[key])
			end
		elseif self._cameras[key] then
			if event == "set_active" then
				if self._cameras[key].active == data.active then return end
				self._cameras[key].active = data.active
			elseif event == "start_tape_loop" then
				self._cameras[key].tape_loop_expire_t = data.tape_loop_expire_t
				self._cameras[key].tape_loop_start_t = Application:time()
			elseif event == "stop_tape_loop" then
				self._cameras[key].tape_loop_expire_t = nil
				self._cameras[key].tape_loop_start_t = nil
			end

			self:_listener_callback("camera", event, key, self._cameras[key])

			if event == "destroy" then
				self._cameras[key] = nil
			end
		end
	end


	function GameInfoManager:register_listener(listener_id, source_type, event, clbk, keys, data_only)
		local listener_keys = nil

		if keys then
			listener_keys = {}
			for _, key in ipairs(keys) do
				listener_keys[key] = true
			end
		end

		self._listeners[source_type] = self._listeners[source_type] or {}
		self._listeners[source_type][event] = self._listeners[source_type][event] or {}
		self._listeners[source_type][event][listener_id] = { clbk = clbk, keys = listener_keys, data_only = data_only }
	end

	function GameInfoManager:unregister_listener(listener_id, source_type, event)
		if self._listeners[source_type] then
			if self._listeners[source_type][event] then
				self._listeners[source_type][event][listener_id] = nil
			end
		end
	end

	function GameInfoManager:_listener_callback(source, event, key, ...)
		for listener_id, data in pairs(self._listeners[source] and self._listeners[source][event] or {}) do
			if not data.keys or data.keys[key] then
				if data.data_only then
					data.clbk(...)
				else
					data.clbk(event, key, ...)
				end
			end
		end
	end

	function GameInfoManager:_add_player_timer_expiration(key, id, expire_t, expire_clbk)
		if self._auto_expire_timers.on_expire[key] then
			self:_remove_player_timer_expiration(key)
		end

		local expire_data = { key = key, id = id, expire_t = expire_t }
		local t_size = #self._auto_expire_timers.expire_t

		if (t_size <= 0) or (expire_t >= self._auto_expire_timers.expire_t[t_size].expire_t) then
			table.insert(self._auto_expire_timers.expire_t, expire_data)
		else
			for i = 1, t_size, 1 do
				if expire_t < self._auto_expire_timers.expire_t[i].expire_t then
					table.insert(self._auto_expire_timers.expire_t, i, expire_data)
					break
				end
			end
		end

		self._auto_expire_timers.on_expire[key] = expire_clbk
	end

	function GameInfoManager:_remove_player_timer_expiration(key)
		if self._auto_expire_timers.on_expire[key] then
			for i, data in ipairs(self._auto_expire_timers.expire_t) do
				if data.key == key then
					table.remove(self._auto_expire_timers.expire_t, i)
					break
				end
			end

			self._auto_expire_timers.on_expire[key] = nil
		end
	end

	function GameInfoManager:_update_player_timer_expiration(ut, udt)
		local t = Application:time()
		local dt = t - self._t
		self._t = t

		while self._auto_expire_timers.expire_t[1] and self._auto_expire_timers.expire_t[1].expire_t < t do
			local data = self._auto_expire_timers.expire_t[1]
			local id = data.id
			local key = data.key
			self._auto_expire_timers.on_expire[key](t, key, id)
			self:_remove_player_timer_expiration(key)
		end
	end

	function GameInfoManager:_on_timed_buff_expired(t, key, id)
		self:_buff_event("deactivate", id)
	end

	function GameInfoManager:_on_timed_stack_expired(t, key, id)
		if self._buffs[id].stacks[1] then
			table.remove(self._buffs[id].stacks, 1)
			self:_listener_callback("buff", "remove_timed_stack", id, self._buffs[id])

			if #self._buffs[id].stacks <= 0 then
				self:_buff_event("deactivate", id)
			end
		end
	end

	function GameInfoManager:_on_player_action_expired(t, key, id)
		self:_player_action_event("deactivate", id)
	end

	function GameInfoManager:_recount_active_cameras()
		local count = 0

		for key, cam_data in pairs(self._cameras) do
			--if cam_data.enabled then
				--printf("Camera (%s): D:%s E:%s A:%s B:%s T:%s\n", key, tostring(cam_data.is_drone and true or false), tostring(cam_data.enabled and true or false), tostring(cam_data.active and true or false), tostring(cam_data.broken and true or false), tostring(cam_data.tape_loop_expire_t and true or false))
			--end

			if --[[cam_data.enabled and]] not cam_data.broken and (cam_data.active or cam_data.tape_loop_expire_t) then
				count = count + 1
			end
		end

		self._upd_camera_count = nil
		self:_listener_callback("camera_count", "set_count", nil, count)

		return count
	end


	function GameInfoManager.add_post_init_event(clbk)
		if managers and managers.gameinfo then
			clbk()
		else
			GameInfoManager.post_init_events = GameInfoManager.post_init_events or {}
			table.insert(GameInfoManager.post_init_events, clbk)
		end
	end

end
