
local update_stats_screen_original = HUDStatsScreen._update_stats_screen_day
local init_original = HUDStatsScreen.init
local show_original = HUDStatsScreen.show

local custom_character_colors = {
	dallas = Color(1, 0, 0.6, 0.8),
	wolf = Color(1, 0.4, 0, 0),
	chains = Color(1, 0.6, 0.8, 0.2),
	hoxton = Color(1, 1, 0.2, 0.7),
	jowi = Color(1, 0.43, 0.48, 0.55),
	old_hoxton = Color(1, 1, 0.43, 0.78),
	female_1 = Color(1, 0.54, 0.17, 0.89),
	dragan = Color(1, 1, 0.14, 0),
	jacket = Color(1, 0.9, 0.91, 0.98),
	bonnie = Color(1, 0.91, 0.59, 0.48),
	--sokol = Color(1, 1, 1, 1),
	--dragon = Color(1, 1, 1, 1),
	--bodhi = Color(1, 1, 1, 1),
	--jimmy = Color(1, 1, 1, 1),

	-- defaults to Color.white, if not set
}

function HUDStatsScreen:init()
	init_original(self)
	local right_panel = self._full_hud_panel:child("right_panel")
	local day_wrapper_panel = right_panel:child("day_wrapper_panel")
	self:clean_up(right_panel)
	if managers.job:is_current_job_professional() then
		day_wrapper_panel:child("day_title"):set_color(Color.red)
	end
	local paygrade_text = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "paygrade_text",
		color = Color.yellow,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "0",
		align = "right",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	local paygrade_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "paygrade_title",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "DIFFICULTY:",
		align = "left",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	--local job_stars = managers.job:current_job_stars()
	--local job_and_difficulty_stars = managers.job:current_job_and_difficulty_stars()
	local difficulty_stars = managers.job:current_difficulty_stars()
	local difficulty = tweak_data.difficulties[difficulty_stars + 2] or 1
	local difficulty_string_id = tweak_data.difficulty_name_ids[difficulty]
	paygrade_text:set_text(managers.localization:to_upper_text(difficulty_string_id))
	paygrade_text:set_y(math.round(day_wrapper_panel:child("day_title"):bottom()))
	paygrade_title:set_top(paygrade_text:top())
	local day_payout_text = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "day_payout_text",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "0",
		align = "right",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	local day_payout_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "day_payout_title",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "PAYOUT:",
		align = "left",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	day_payout_text:set_text(managers.experience:cash_string(0))
	day_payout_text:set_y(math.round(paygrade_text:bottom()))
	day_payout_title:set_top(day_payout_text:top())
	local offshore_payout_text = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "offshore_payout_text",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "0",
		align = "right",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	local offshore_payout_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "offshore_payout_title",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "OFFSHORE PAYOUT:",
		align = "left",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	offshore_payout_text:set_y(math.round(day_payout_text:bottom()))
	offshore_payout_title:set_top(offshore_payout_text:top())
	local cleaner_costs_text = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "cleaner_costs_text",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "0",
		align = "right",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	local cleaner_costs_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "cleaner_costs_title",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "CLEANER COSTS:",
		align = "left",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	cleaner_costs_text:set_y(math.round(offshore_payout_text:bottom()))
	cleaner_costs_title:set_top(cleaner_costs_text:top())
	local spending_cash_text = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "spending_cash_text",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "0",
		align = "right",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	local spending_cash_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "spending_cash_title",
		color = Color.white,
		font_size = 16,
		font = tweak_data.hud_stats.objectives_font,
		text = "SPENDING CASH:",
		align = "left",
		vertical = "top",
		w = day_wrapper_panel:w()/2-5,
		h = 18
	})
	spending_cash_text:set_y(math.round(cleaner_costs_text:bottom()))
	spending_cash_title:set_top(spending_cash_text:top())
	local blank = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "blank",
		color = Color.white,
		font_size = tweak_data.hud_stats.loot_size,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 25
	})
	blank:set_y(math.round(spending_cash_text:bottom()))
	local blanka = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "blanka",
		color = Color.white,
		font_size = tweak_data.hud_stats.loot_size,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 25
	})
	blanka:set_y(math.round(blank:bottom()))
	local accuracy_text = day_wrapper_panel:text({
		layer = 0,
		x =  -215,
		y = 0,
		name = "accuracy_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local accuracy_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "accuracy_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "ACCURACY:",
		align = "left",
		vertical = "top",
		h = 18
	})
	accuracy_text:set_y(math.round(blanka:bottom()))
	accuracy_title:set_top(accuracy_text:top())
	local headshot_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "headshot_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local headshot_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "headshot_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "HEADSHOTS:",
		align = "left",
		vertical = "top",
		h = 18
	})
	headshot_text:set_y(math.round(accuracy_text:bottom()))
	headshot_title:set_top(headshot_text:top())
	local total_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "total_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local total_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "total_killed_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "TOTAL KILLS:",
		align = "left",
		vertical = "top",
		h = 18
	})
	total_killed_text:set_y(math.round(headshot_text:bottom()))
	total_killed_title:set_top(total_killed_text:top())
	local non_specials_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "non_specials_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local non_specials_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "non_specials_killed_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "NON SPECIALS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	non_specials_killed_text:set_y(math.round(total_killed_text:bottom()))
	non_specials_killed_title:set_top(non_specials_killed_text:top())
	local tanks_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "tanks_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local tanks_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "tanks_killed_title",
		color = Color.red, -- RED
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "BULLDOZERS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	tanks_killed_text:set_y(math.round(non_specials_killed_text:bottom()))
	tanks_killed_title:set_top(tanks_killed_text:top())
	local tank_green_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "tank_green_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local tank_green_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "tank_green_killed_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "GREEN DOZERS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	tank_green_killed_text:set_y(math.round(tanks_killed_text:bottom()))
	tank_green_killed_title:set_top(tank_green_killed_text:top())
	local tank_black_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "tank_black_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local tank_black_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "tank_black_killed_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "BLACK DOZERS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	tank_black_killed_text:set_y(math.round(tank_green_killed_text:bottom()))
	tank_black_killed_title:set_top(tank_black_killed_text:top())
	local tank_skull_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "tank_skull_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local tank_skull_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "tank_skull_killed_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "SKULLDOZERS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	tank_skull_killed_text:set_y(math.round(tank_black_killed_text:bottom()))
	tank_skull_killed_title:set_top(tank_skull_killed_text:top())
	local cloakers_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "cloakers_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local cloakers_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "cloakers_killed_title",
		color = tweak_data.screen_colors.friend_color, -- Green
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "CLOAKERS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	cloakers_killed_text:set_y(math.round(tank_skull_killed_text:bottom()))
	cloakers_killed_title:set_top(cloakers_killed_text:top())
	local shields_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "shields_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local shields_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "shields_killed_title",
		color = Color("888888"), -- Grey
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "SHIELDS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	shields_killed_text:set_y(math.round(cloakers_killed_text:bottom()))
	shields_killed_title:set_top(shields_killed_text:top())
	local snipers_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "snipers_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local snipers_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "snipers_killed_title",
		color = Color("FF9912"), -- Orange/Yellow
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "SNIPERS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	snipers_killed_text:set_y(math.round(shields_killed_text:bottom()))
	snipers_killed_title:set_top(snipers_killed_text:top())
	local tasers_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "tasers_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local tasers_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "tasers_killed_title",
		color = Color.cyan, -- Blue
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "TASERS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	tasers_killed_text:set_y(math.round(snipers_killed_text:bottom()))
	tasers_killed_title:set_top(tasers_killed_text:top())
	local phalanx_vip_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "phalanx_vip_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local phalanx_vip_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "phalanx_vip_killed_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "WINTER KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	phalanx_vip_killed_text:set_y(math.round(tasers_killed_text:bottom()))
	phalanx_vip_killed_title:set_top(phalanx_vip_killed_text:top())
	local phalanx_minion_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "phalanx_minion_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local phalanx_minion_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "phalanx_minion_killed_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "WINTER'S MINIONS KILLED:",
		align = "left",
		vertical = "top",
		h = 18
	})
	phalanx_minion_killed_text:set_y(math.round(phalanx_vip_killed_text:bottom()))
	phalanx_minion_killed_title:set_top(phalanx_minion_killed_text:top())
	local melee_killed_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "melee_killed_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local melee_killed_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "melee_killed_title",
		color = Color("8B4500"), -- Brown
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "MELEE KILLS:",
		align = "left",
		vertical = "top",
		h = 18
	})
	melee_killed_text:set_y(math.round(phalanx_minion_killed_text:bottom()))
	melee_killed_title:set_top(melee_killed_text:top())
	blank = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "blank",
		color = Color.white,
		font_size = tweak_data.hud_stats.loot_size,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 25
	})
	blank:set_y(math.round(melee_killed_text:bottom()))
	local revives_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "revives_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local revives_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "revives_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "REVIVES:",
		align = "left",
		vertical = "top",
		h = 18
	})
	revives_text:set_y(math.round(blank:bottom()))
	revives_title:set_top(revives_text:top())
	local downs_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "downs_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local downs_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "downs_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "DOWNS:",
		align = "left",
		vertical = "top",
		h = 18
	})
	downs_text:set_y(math.round(revives_text:bottom()))
	downs_title:set_top(downs_text:top())
	blank = day_wrapper_panel:text({
		layer = 0,
		x =  0,
		y = 0,
		name = "blank",
		color = Color.white,
		font_size = tweak_data.hud_stats.loot_size,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 25
	})
	blank:set_y(math.round(downs_text:bottom()))
	local time_text = day_wrapper_panel:text({
		layer = 0,
		x =  -220,
		y = 0,
		name = "time_text",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "",
		align = "right",
		vertical = "top",
		h = 18
	})
	local time_title = day_wrapper_panel:text({
		layer = 0,
		x = 0,
		y = 0,
		name = "time_title",
		color = Color.white,
		font_size = 15,
		font = tweak_data.hud_stats.objectives_font,
		text = "TIME:",
		align = "left",
		vertical = "top",
		h = 18
	})
	time_text:set_y(math.round(blank:bottom()))
	time_title:set_top(time_text:top())
	local mask_icon = "guis/textures/pd2/blackmarket/icons/masks/grin"
	local mask_color = Color(1, 0.8, 0.5, 0.2)
	local old_character_name = managers.criminals:local_character_name()
	local character_name = CriminalsManager.convert_old_to_new_character_workname(old_character_name)
	local character_table = tweak_data.blackmarket.characters[old_character_name]
	if not character_table then
		character_table = tweak_data.blackmarket.characters.locked[character_name]
	end
	if character_table then
		local guis_catalog = "guis/"
		local bundle_folder = character_table.texture_bundle_folder
		if bundle_folder then
			guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
		end
		mask_icon = guis_catalog .. "textures/pd2/blackmarket/icons/characters/" .. character_name
		mask_color = custom_character_colors[character_name] or Color.white
	end
	local logo = right_panel:bitmap({
		name = "ghost_icon",
		texture = mask_icon,
		w = day_wrapper_panel:w()/2-5,
		h = day_wrapper_panel:w()/2-5,
		blend_mode = "add",
		color = mask_color
	})
	logo:set_left(day_wrapper_panel:w()/2+40)
	logo:set_top(30)
	self:update(day_wrapper_panel)
end

function HUDStatsScreen:update(day_wrapper_panel)
	day_wrapper_panel:child("cleaner_costs_text"):set_text(managers.experience:cash_string(managers.money:get_civilian_deduction() * (managers.statistics:session_total_civilian_kills() or 0)) .. " (" .. (managers.statistics:session_total_civilian_kills() or 0) .. ")")
	day_wrapper_panel:child("offshore_payout_text"):set_text(managers.experience:cash_string(managers.money:get_potential_payout_from_current_stage() - math.round(managers.money:get_potential_payout_from_current_stage() * managers.money:get_tweak_value("money_manager", "offshore_rate"))))
	day_wrapper_panel:child("spending_cash_text"):set_text(managers.experience:cash_string(math.round(managers.money:get_potential_payout_from_current_stage() * managers.money:get_tweak_value("money_manager", "offshore_rate")) - managers.money:get_civilian_deduction() * (managers.statistics:session_total_civilian_kills() or 0)))
	day_wrapper_panel:child("accuracy_text"):set_text(managers.statistics:session_hit_accuracy() .. "%")
	day_wrapper_panel:child("headshot_text"):set_text(managers.statistics._global.session.killed.total.head_shots)
	day_wrapper_panel:child("tanks_killed_text"):set_text(managers.statistics._global.session.killed.tank_green.count + managers.statistics._global.session.killed.tank_black.count + managers.statistics._global.session.killed.tank_skull.count)
	day_wrapper_panel:child("tank_green_killed_text"):set_text(managers.statistics._global.session.killed.tank_green.count)
	day_wrapper_panel:child("tank_black_killed_text"):set_text(managers.statistics._global.session.killed.tank_black.count)
	day_wrapper_panel:child("tank_skull_killed_text"):set_text(managers.statistics._global.session.killed.tank_skull.count)
	day_wrapper_panel:child("cloakers_killed_text"):set_text(managers.statistics._global.session.killed.spooc.count)
	day_wrapper_panel:child("shields_killed_text"):set_text(managers.statistics._global.session.killed.shield.count)
	day_wrapper_panel:child("snipers_killed_text"):set_text(managers.statistics._global.session.killed.sniper.count)
	day_wrapper_panel:child("tasers_killed_text"):set_text(managers.statistics._global.session.killed.taser.count)
	day_wrapper_panel:child("phalanx_vip_killed_text"):set_text(managers.statistics._global.session.killed.phalanx_vip.count)
	day_wrapper_panel:child("phalanx_minion_killed_text"):set_text(managers.statistics._global.session.killed.phalanx_minion.count)
	day_wrapper_panel:child("melee_killed_text"):set_text(managers.statistics._global.session.killed.total.melee)
	day_wrapper_panel:child("total_killed_text"):set_text(managers.statistics._global.session.killed.total.count)
	day_wrapper_panel:child("non_specials_killed_text"):set_text(managers.statistics._global.session.killed.total.count - managers.statistics:session_total_specials_kills() - managers.statistics:session_total_civilian_kills())
	day_wrapper_panel:child("revives_text"):set_text(managers.statistics._global.session.revives.player_count + managers.statistics._global.session.revives.npc_count)
	day_wrapper_panel:child("downs_text"):set_text(managers.statistics._global.session.downed.bleed_out + managers.statistics._global.session.downed.incapacitated)
	day_wrapper_panel:child("time_text"):set_text(os.date('%X'))
	if 0 <= math.round(managers.money:get_potential_payout_from_current_stage() * managers.money:get_tweak_value("money_manager", "offshore_rate")) - managers.money:get_civilian_deduction() * (managers.statistics:session_total_civilian_kills() or 0) then
		day_wrapper_panel:child("spending_cash_text"):set_color(tweak_data.screen_colors.friend_color)
	else
		day_wrapper_panel:child("spending_cash_text"):set_color(tweak_data.screen_colors.heat_cold_color)
	end
end

function HUDStatsScreen:clean_up(right_panel)
	--right_panel:child("ghost_icon"):set_visible(false)
	right_panel:child("day_wrapper_panel"):child("ghostable_text"):set_visible(false)
	right_panel:child("day_wrapper_panel"):child("paygrade_title"):set_visible(false)
	right_panel:child("day_wrapper_panel"):child("risk_text"):set_visible(false)
	right_panel:child("day_wrapper_panel"):child("day_payout"):set_visible(false)
	right_panel:child("day_wrapper_panel"):child("day_description"):set_visible(false)
	right_panel:child("day_wrapper_panel"):child("bains_plan"):set_visible(false)
end

function HUDStatsScreen:_update_stats_screen_day(right_panel)
	update_stats_screen_original(self, right_panel)
	self:clean_up(right_panel)
	self:update(right_panel:child("day_wrapper_panel"))
end

-- Lobby Player Info compat
function HUDStatsScreen:show()
	show_original(self)
	local right_panel = managers.hud:script(managers.hud.STATS_SCREEN_FULLSCREEN).panel:child("right_panel")
	if right_panel then
		local dwp = right_panel:child("day_wrapper_panel")
		if dwp then
			local y = dwp:child("accuracy_text"):top()
			local x = dwp:w() / 2 - 5
			for i = 1, 4 do
				local name = dwp:child("lpi_team_text_name" .. tostring(i))
				if name then
					name:set_x(x - 5)
					name:set_top(y)
					name:set_font_size(18)
				end
				local skills = dwp:child("lpi_team_text_skills" .. tostring(i))
				if skills then
					skills:set_x(x)
					skills:set_top(y + 20)
					skills:set_font_size(15)
				end
				local perk = dwp:child("lpi_team_text_perk" .. tostring(i))
				if perk then
					perk:set_x(x)
					perk:set_top(y + 36)
					perk:set_font_size(15)
				end
				y = y + 52
			end
		end
	end
end
