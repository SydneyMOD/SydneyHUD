
local is_dlc_latest_locked_original = MenuCallbackHandler.is_dlc_latest_locked

function MenuCallbackHandler:is_dlc_latest_locked(...)
	if SydneyHUD:GetOption("remove_ads") then
		return false
	else
		return is_dlc_latest_locked_original(self, ...)
	end
end

--[[
	Load our localization keys for our menu, and menu items.
]]
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_sydneyhud", function(loc)
	for _, filename in pairs(file.GetFiles(SydneyHUD._path .. "loc/")) do
		local str = filename:match('^(.*).json$')
		-- if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
		local langid = SydneyHUD:GetOption("language")
		-- log(dev..langid)
		if str == SydneyHUD._language[langid] then
			loc:load_localization_file(SydneyHUD._path .. "loc/" .. filename)
			log(info.."language: "..filename)
			break
		end
	end
	loc:load_localization_file(SydneyHUD._path .. "loc/english.json", false)
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_sydneyhud", function(menu_manager, nodes)
	if nodes.main then
		MenuHelper:AddMenuItem(nodes.main, "crimenet_contract_special", "menu_cn_premium_buy", "menu_cn_premium_buy_desc", "crimenet", "after")
	end
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenus_sydneyhud", function(menu_manager, menu_nodes)
	--[[
		Add "Reset all options" to the sydneyhud main menu.
	]]
	MenuHelper:AddButton({
		id = "sydneyhud_reset",
		title = "sydneyhud_reset",
		desc = "sydneyhud_reset_desc",
		callback = "callback_sydneyhud_reset",
		menu_id = "sydneyhud_options",
		priority = 100
	})
	MenuHelper:AddDivider({
		id = "sydneyhud_reset_divider",
		size = 16,
		menu_id = "sydneyhud_options",
		priority = 99
	})
end)

--[[
	Setup our menu callbacks, load our saved data, and build the menu from our json file.
]]
Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_sydneyhud", function(menu_manager)

	--[[
		Setup our callbacks as defined in our item callback keys, and perform our logic on the data retrieved.
	]]

	-- Screen skipping
	MenuCallbackHandler.callback_skip_black_screen = function(self, item)
		SydneyHUD._data.skip_black_screen = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_skip_stat_screen = function(self, item)
		SydneyHUD._data.skip_stat_screen = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_stat_screen_skip = function(self, item)
		SydneyHUD._data.stat_screen_skip = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_skip_card_picking = function(self, item)
		SydneyHUD._data.skip_card_picking = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_skip_loot_screen = function(self, item)
		SydneyHUD._data.skip_loot_screen = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_loot_screen_skip = function(self, item)
		SydneyHUD._data.loot_screen_skip = item:value()
		SydneyHUD:Save()
	end

	-- HUD panel
	MenuCallbackHandler.callback_counter_font_size = function(self, item)
		SydneyHUD._data.counter_font_size = item:value()
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_improved_ammo_count = function(self, item)
		SydneyHUD._data.improved_ammo_count = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_right_list_scale = function(self, item)
		SydneyHUD._data.right_list_scale = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_left_list_scale = function(self, item)
		SydneyHUD._data.left_list_scale = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_buff_list_scale = function(self, item)
		SydneyHUD._data.buff_list_scale = item:value()
		SydneyHUD:Save()
	end

	-- HUD Lists (Timers)
	MenuCallbackHandler.callback_show_timers = function(self, item)
		SydneyHUD._data.show_timers = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_equipment = function(self, item)
		SydneyHUD._data.show_equipment = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_sentries = function(self, item)
		SydneyHUD._data.show_sentries = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_ecms = function(self, item)
		SydneyHUD._data.show_ecms = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_ecm_retrigger = function(self, item)
		SydneyHUD._data.show_ecm_retrigger = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_minions = function(self, item)
		SydneyHUD._data.show_minions = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_pagers = function(self, item)
		SydneyHUD._data.show_pagers = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_tape_loop = function(self, item)
		SydneyHUD._data.show_tape_loop = (item:value() == "on")
		SydneyHUD:Save()
	end

	-- HUD Lists (Counters)
	MenuCallbackHandler.callback_show_enemies = function(self, item)
		SydneyHUD._data.show_enemies = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_aggregate_enemies = function(self, item)
		SydneyHUD._data.aggregate_enemies = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_turrets = function(self, item)
		SydneyHUD._data.show_turrets = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_civilians = function(self, item)
		SydneyHUD._data.show_civilians = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_hostages = function(self, item)
		SydneyHUD._data.show_hostages = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_aggregate_hostages = function(self, item)
		SydneyHUD._data.aggregate_hostages = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_minion_count = function(self, item)
		SydneyHUD._data.show_minion_count = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_pager_count = function(self, item)
		SydneyHUD._data.show_pager_count = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_camera_count = function(self, item)
		SydneyHUD._data.show_camera_count = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_loot = function(self, item)
		SydneyHUD._data.show_loot = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_aggregate_loot = function(self, item)
		SydneyHUD._data.aggregate_loot = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_separate_bagged_loot = function(self, item)
		SydneyHUD._data.separate_bagged_loot = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_gage_packages = function(self, item)
		SydneyHUD._data.show_gage_packages = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_special_pickups = function(self, item)
		SydneyHUD._data.show_special_pickups = (item:value() == "on")
		SydneyHUD:Save()
	end

	-- HUD Lists (Buffs)
	MenuCallbackHandler.callback_show_buffs = function(self, item)
		SydneyHUD._data.show_buffs = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_enemy_color_r = function(self, item)
		SydneyHUD._data.enemy_color_r = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enemy_color_g = function(self, item)
		SydneyHUD._data.enemy_color_g = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enemy_color_b = function(self, item)
		SydneyHUD._data.enemy_color_b = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_civilian_color_r = function(self, item)
		SydneyHUD._data.civilian_color_r = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_civilian_color_g = function(self, item)
		SydneyHUD._data.civilian_color_g = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_civilian_color_b = function(self, item)
		SydneyHUD._data.civilian_color_b = item:value()
		SydneyHUD:Save()
	end

	-- Kill counter
	MenuCallbackHandler.callback_enable_kill_counter = function(self, item)
		SydneyHUD._data.enable_kill_counter = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_special_kills = function(self, item)
		SydneyHUD._data.show_special_kills = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_headshot_kills = function(self, item)
		SydneyHUD._data.show_headshot_kills = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_ai_kills = function(self, item)
		SydneyHUD._data.show_ai_kills = (item:value() == "on")
		SydneyHUD:Save()
	end

	-- HPS Meter
	MenuCallbackHandler.callback_enable_hps_meter = function(self, item)
		SydneyHUD._data.enable_hps_meter = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_hps_refresh_rate = function(self, item)
		SydneyHUD._data.hps_refresh_rate = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_hps_current = function(self, item)
		SydneyHUD._data.show_hps_current = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_current_hps_timeout = function(self, item)
		SydneyHUD._data.current_hps_timeout = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_hps_total = function(self, item)
		SydneyHUD._data.show_hps_total = (item:value() == "on")
		SydneyHUD:Save()
	end

	-- Flashlight extender
	MenuCallbackHandler.callback_enable_flashlight_extender = function(self, item)
		SydneyHUD._data.enable_flashlight_extender = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_flashlight_range = function(self, item)
		SydneyHUD._data.flashlight_range = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_flashlight_angle = function(self, item)
		SydneyHUD._data.flashlight_angle = item:value()
		SydneyHUD:Save()
	end

	-- Laser options
	MenuCallbackHandler.callback_enable_laser_options = function(self, item)
		SydneyHUD._data.enable_laser_options = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_r = function(self, item)
		SydneyHUD._data.laser_color_r = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_g = function(self, item)
		SydneyHUD._data.laser_color_g = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_b = function(self, item)
		SydneyHUD._data.laser_color_b = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_rainbow = function(self, item)
		SydneyHUD._data.laser_color_rainbow = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_a = function(self, item)
		SydneyHUD._data.laser_color_a = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_glow = function(self, item)
		SydneyHUD._data.laser_glow = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_light = function(self, item)
		SydneyHUD._data.laser_light = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_laser_options_others = function(self, item)
		SydneyHUD._data.enable_laser_options_others = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_r_others = function(self, item)
		SydneyHUD._data.laser_color_r_others = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_g_others = function(self, item)
		SydneyHUD._data.laser_color_g_others = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_b_others = function(self, item)
		SydneyHUD._data.laser_color_b_others = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_rainbow_others = function(self, item)
		SydneyHUD._data.laser_color_rainbow_others = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_a_others = function(self, item)
		SydneyHUD._data.laser_color_a_others = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_glow_others = function(self, item)
		SydneyHUD._data.laser_glow_others = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_light_others = function(self, item)
		SydneyHUD._data.laser_light_others = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_laser_options_snipers = function(self, item)
		SydneyHUD._data.enable_laser_options_snipers = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_r_snipers = function(self, item)
		SydneyHUD._data.laser_color_r_snipers = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_g_snipers = function(self, item)
		SydneyHUD._data.laser_color_g_snipers = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_b_snipers = function(self, item)
		SydneyHUD._data.laser_color_b_snipers = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_rainbow_snipers = function(self, item)
		SydneyHUD._data.laser_color_rainbow_snipers = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_a_snipers = function(self, item)
		SydneyHUD._data.laser_color_a_snipers = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_glow_snipers = function(self, item)
		SydneyHUD._data.laser_glow_snipers = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_light_snipers = function(self, item)
		SydneyHUD._data.laser_light_snipers = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_laser_options_turret = function(self, item)
		SydneyHUD._data.enable_laser_options_turret = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_r_turret = function(self, item)
		SydneyHUD._data.laser_color_r_turret = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_g_turret = function(self, item)
		SydneyHUD._data.laser_color_g_turret = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_b_turret = function(self, item)
		SydneyHUD._data.laser_color_b_turret = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_rainbow_turret = function(self, item)
		SydneyHUD._data.laser_color_rainbow_turret = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_a_turret = function(self, item)
		SydneyHUD._data.laser_color_a_turret = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_glow_turret = function(self, item)
		SydneyHUD._data.laser_glow_turret = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_light_turret = function(self, item)
		SydneyHUD._data.laser_light_turret = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_laser_options_turretr = function(self, item)
		SydneyHUD._data.enable_laser_options_turretr = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_r_turretr = function(self, item)
		SydneyHUD._data.laser_color_r_turretr = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_g_turretr = function(self, item)
		SydneyHUD._data.laser_color_g_turretr = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_b_turretr = function(self, item)
		SydneyHUD._data.laser_color_b_turretr = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_rainbow_turretr = function(self, item)
		SydneyHUD._data.laser_color_rainbow_turretr = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_a_turretr = function(self, item)
		SydneyHUD._data.laser_color_a_turretr = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_glow_turretr = function(self, item)
		SydneyHUD._data.laser_glow_turretr = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_light_turretr = function(self, item)
		SydneyHUD._data.laser_light_turretr = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_laser_options_turretm = function(self, item)
		SydneyHUD._data.enable_laser_options_turretm = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_r_turretm = function(self, item)
		SydneyHUD._data.laser_color_r_turretm = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_g_turretm = function(self, item)
		SydneyHUD._data.laser_color_g_turretm = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_b_turretm = function(self, item)
		SydneyHUD._data.laser_color_b_turretm = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_rainbow_turretm = function(self, item)
		SydneyHUD._data.laser_color_rainbow_turretm = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_color_a_turretm = function(self, item)
		SydneyHUD._data.laser_color_a_turretm = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_glow_turretm = function(self, item)
		SydneyHUD._data.laser_glow_turretm = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_laser_light_turretm = function(self, item)
		SydneyHUD._data.laser_light_turretm = item:value()
		SydneyHUD:Save()
	end

	-- Interact Tweak
	MenuCallbackHandler.callback_push_to_interact = function(self, item)
		SydneyHUD._data.push_to_interact = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_equipment_interrupt = function(self, item)
		SydneyHUD._data.equipment_interrupt = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_hold_to_pick = function(self, item)
		SydneyHUD._data.hold_to_pick = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_hold_to_pick_delay = function(self, item)
		SydneyHUD._data.hold_to_pick_delay = item:value()
		SydneyHUD:Save()
	end

	-- Other
	MenuCallbackHandler.callback_show_enemy_health = function(self, item)
		SydneyHUD._data.show_enemy_health = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_health_bar_color = function(self, item)
		SydneyHUD._data.health_bar_color = item:value()
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_remove_ads = function(self, item)
		SydneyHUD._data.remove_ads = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_lobby_skins_mode = function(self, item)
		SydneyHUD._data.lobby_skins_mode = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_buy_all_assets = function(self, item)
		SydneyHUD._data.enable_buy_all_assets = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_remove_answered_pager_contour = function(self, item)
		SydneyHUD._data.remove_answered_pager_contour = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_pacified = function(self, item)
		SydneyHUD._data.enable_pacified = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_suspicion_text = function(self, item)
		SydneyHUD._data.show_suspicion_text = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_melee_interaction = function(self, item)
		SydneyHUD._data.show_melee_interaction = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_reload_interaction = function(self, item)
		SydneyHUD._data.show_reload_interaction = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_interaction_circle = function(self, item)
		SydneyHUD._data.show_interaction_circle = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_interaction_text = function(self, item)
		SydneyHUD._data.show_interaction_text = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_text_borders = function(self, item)
		SydneyHUD._data.show_text_borders = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_truncate_name_tags = function(self, item)
		SydneyHUD._data.truncate_name_tags = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_client_ranks = function(self, item)
		SydneyHUD._data.show_client_ranks = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_own_rank = function(self, item)
		SydneyHUD._data.show_own_rank = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_colorize_names = function(self, item)
		SydneyHUD._data.colorize_names = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_stamina_meter = function(self, item)
		SydneyHUD._data.show_stamina_meter = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_armor_timer = function(self, item)
		SydneyHUD._data.show_armor_timer = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_show_inspire_timer = function(self, item)
		SydneyHUD._data.show_inspire_timer = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_anti_stealth_grenades = function(self, item)
		SydneyHUD._data.anti_stealth_grenades = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_center_assault_banner = function(self, item)
		SydneyHUD._data.center_assault_banner = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enable_enhanced_assault_banner = function(self, item)
		SydneyHUD._data.enable_enhanced_assault_banner = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enhanced_assault_spawns = function(self, item)
		SydneyHUD._data.enhanced_assault_spawns = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enhanced_assault_time = function(self, item)
		SydneyHUD._data.enhanced_assault_time = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_enhanced_assault_count = function(self, item)
		SydneyHUD._data.enhanced_assault_count = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_interaction_color_r = function(self, item)
		SydneyHUD._data.interaction_color_r = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_interaction_color_g = function(self, item)
		SydneyHUD._data.interaction_color_g = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_interaction_color_b = function(self, item)
		SydneyHUD._data.interaction_color_b = item:value()
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_anti_bobble = function(self, item)
		SydneyHUD._data.anti_bobble = (item:value() == "on")
		SydneyHUD:Save()
	end

	-- Chat Info
	MenuCallbackHandler.callback_show_heist_time = function(self, item)
		SydneyHUD._data.show_heist_time = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_assault_phase_chat_info = function(self, item)
		SydneyHUD._data.assault_phase_chat_info = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_assault_phase_chat_info_feed = function(self, item)
		SydneyHUD._data.assault_phase_chat_info_feed = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_ecm_battery_chat_info = function(self, item)
		SydneyHUD._data.ecm_battery_chat_info = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_ecm_battery_chat_info_feed = function(self, item)
		SydneyHUD._data.ecm_battery_chat_info_feed = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_inspire_ace_chat_info = function(self, item)
		SydneyHUD._data.inspire_ace_chat_info = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_down_warning_chat_info = function(self, item)
		SydneyHUD._data.down_warning_chat_info = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_critical_down_warning_chat_info = function(self, item)
		SydneyHUD._data.critical_down_warning_chat_info = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_down_warning_chat_info_feed = function(self, item)
		SydneyHUD._data.down_warning_chat_info_feed = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_critical_down_warning_chat_info_feed = function(self, item)
		SydneyHUD._data.critical_down_warning_chat_info_feed = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_replenished_chat_info = function(self, item)
		SydneyHUD._data.replenished_chat_info = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_replenished_chat_info_feed = function(self, item)
		SydneyHUD._data.replenished_chat_info_feed = (item:value() == "on")
		SydneyHUD:Save()
	end

	-- EXPERIMENTAL
	MenuCallbackHandler.callback_waypoint_color_r = function(self, item)
		SydneyHUD._data.waypoint_color_r = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_waypoint_color_g = function(self, item)
		SydneyHUD._data.waypoint_color_g = item:value()
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_waypoint_color_b = function(self, item)
		SydneyHUD._data.waypoint_color_b = item:value()
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_civilian_spot = function(self, item)
		SydneyHUD._data.civilian_spot = (item:value() == "on")
		SydneyHUD:Save()
	end
	MenuCallbackHandler.callback_civilian_spot_voice = function(self, item)
		SydneyHUD._data.civilian_spot_voice = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_clean_flashbang = function(self, item)
		SydneyHUD._data.clean_flashbang = (item:value() == "on")
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_new_icon = function(self, item)
		SydneyHUD._data.new_icon = (item:value() == "on")
		SydneyHUD:Save()
	end

	-- SydneyHUD
	MenuCallbackHandler.callback_sydneyhud_language = function(self, item)
		SydneyHUD._data.language = item:value()
		SydneyHUD:Save()
	end

	MenuCallbackHandler.callback_sydneyhud_reset = function(self, item)
		local menu_title = managers.localization:text("sydneyhud_reset")
		local menu_message = managers.localization:text("sydneyhud_reset_message")
		local menu_options = {
			[1] = {
				text = managers.localization:text("sydneyhud_reset_ok"),
				callback = function()
					SydneyHUD:LoadDefaults()
					SydneyHUD:ForceReloadAllMenus()
					SydneyHUD:Save()
				end,
			},
			[2] = {
				text = managers.localization:text("sydneyhud_reset_cancel"),
				is_cancel_button = true,
			},
		}
		QuickMenu:new(menu_title, menu_message, menu_options, true)
	end

	--[[
		Load our previously saved data from our save file.
	]]
	SydneyHUD:Load()
	SydneyHUD:InitAllMenus()

	--[[
		Set keybind defaults
	]]
	LuaModManager:SetPlayerKeybind("load_pre", LuaModManager:GetPlayerKeybind("load_pre") or "f5")
	LuaModManager:SetPlayerKeybind("save_pre", LuaModManager:GetPlayerKeybind("save_pre") or "f6")
end)
