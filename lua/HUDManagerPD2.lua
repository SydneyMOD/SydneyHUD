
local function format_time_string(value)
	local frmt_string

	if value >= 60 then
		frmt_string = string.format("%d:%02d", math.floor(value / 60), math.ceil(value % 60))
	elseif value >= 9.9 then
		frmt_string = string.format("%d", math.ceil(value))
	elseif value >= 0 then
		frmt_string = string.format("%.1f", value)
	else
		frmt_string = string.format("%.1f", 0)
	end

	return frmt_string
end

local init_original = HUDManager.init
local _setup_player_info_hud_pd2_original = HUDManager._setup_player_info_hud_pd2
local _create_downed_hud_original = HUDManager._create_downed_hud
local update_original = HUDManager.update
local set_stamina_value_original = HUDManager.set_stamina_value
local set_max_stamina_original = HUDManager.set_max_stamina
local set_mugshot_downed_original = HUDManager.set_mugshot_downed
local set_mugshot_custody_original = HUDManager.set_mugshot_custody
local set_mugshot_normal_original = HUDManager.set_mugshot_normal
local teammate_progress_original = HUDManager.teammate_progress
local feed_heist_time_original = HUDManager.feed_heist_time
local show_casing_original = HUDManager.show_casing
local hide_casing_original = HUDManager.hide_casing
local sync_start_assault_original = HUDManager.sync_start_assault
local sync_end_assault_original = HUDManager.sync_end_assault
local show_point_of_no_return_timer_original = HUDManager.show_point_of_no_return_timer
local hide_point_of_no_return_timer_original = HUDManager.hide_point_of_no_return_timer
local set_player_condition_original = HUDManager.set_player_condition
local set_slot_outfit_original = HUDManager.set_slot_outfit
local add_teammate_panel_original = HUDManager.add_teammate_panel
local show_interact_original = HUDManager.show_interact
local remove_interact_original = HUDManager.remove_interact
local custom_radial_original = HUDManager.set_teammate_custom_radial

function HUDManager:init(...)
	init_original(self, ...)
	self._deferred_detections = {}
end

function HUDManager:set_slot_outfit(peer_id, criminal_name, outfit, ...)
	self:set_slot_detection(peer_id, outfit, true)
	return set_slot_outfit_original(self, peer_id, criminal_name, outfit, ...)
end

function HUDManager:add_teammate_panel(character_name, player_name, ai, peer_id, ...)
	local result = add_teammate_panel_original(self, character_name, player_name, ai, peer_id, ...)
	for pid, risk in pairs(self._deferred_detections) do
		for panel_id, _ in ipairs(self._hud.teammate_panels_data) do
			if self._teammate_panels[panel_id]:peer_id() == pid then
				self._teammate_panels[panel_id]:set_detection_risk(risk)
				self._deferred_detections[pid] = nil
			end
		end
	end
	return result
end

function HUDManager:set_slot_detection(peer_id, outfit, unpacked)
	if not unpacked or not outfit then
		outfit = managers.blackmarket:unpack_outfit_from_string(outfit)
	end
	local risk = managers.blackmarket:get_suspicion_offset_of_outfit_string(outfit, tweak_data.player.SUSPICION_OFFSET_LERP or 0.75)
	for panel_id, _ in ipairs(self._hud.teammate_panels_data) do
		if self._teammate_panels[panel_id].set_detection_risk and peer_id == managers.network:session():local_peer():id() and self._teammate_panels[panel_id]._main_player or self._teammate_panels[panel_id]:peer_id() == peer_id then
			self._teammate_panels[panel_id]:set_detection_risk(risk)
			return
		end
	end
	self._deferred_detections[peer_id] = risk
end

function HUDManager:set_player_condition(icon_data, text)
	set_player_condition_original(self, icon_data, text)
	if icon_data == "mugshot_in_custody" then
		self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(true)
	elseif icon_data == "mugshot_normal" then
		self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(false)
	end
end

function HUDManager:change_health(...)
	self._teammate_panels[self.PLAYER_PANEL]:change_health(...)
end

function HUDManager:_create_downed_hud(...)
	_create_downed_hud_original(self, ...)
	if SydneyHUD:GetOption("center_assault_banner") then
		local timer_msg = self._hud_player_downed._hud_panel:child("downed_panel"):child("timer_msg")
		timer_msg:set_y(50)
		self._hud_player_downed._hud.timer:set_y(math.round(timer_msg:bottom() - 6))
	end
end

function HUDManager:show_casing(...)
	self._hud_heist_timer._heist_timer_panel:set_visible(not SydneyHUD:GetOption("center_assault_banner"))
	if self:alive("guis/mask_off_hud") and SydneyHUD:GetOption("center_assault_banner") then
		self:script("guis/mask_off_hud").mask_on_text:set_y(50)
	end
	show_casing_original(self, ...)
end

function HUDManager:hide_casing(...)
	hide_casing_original(self, ...)
	self._hud_heist_timer._heist_timer_panel:set_visible(true)
end

function HUDManager:sync_start_assault(...)
	self._hud_heist_timer._heist_timer_panel:set_visible(not SydneyHUD:GetOption("center_assault_banner"))
	managers.groupai:state()._wave_counter = (managers.groupai:state()._wave_counter or 0) + 1
	sync_start_assault_original(self, ...)
end

function HUDManager:sync_end_assault(...)
	sync_end_assault_original(self, ...)
	self._hud_heist_timer._heist_timer_panel:set_visible(true)
end

function HUDManager:show_point_of_no_return_timer(...)
	self._hud_heist_timer._heist_timer_panel:set_visible(not SydneyHUD:GetOption("center_assault_banner"))
	show_point_of_no_return_timer_original(self, ...)
end

function HUDManager:hide_point_of_no_return_timer(...)
	hide_point_of_no_return_timer_original(self, ...)
	self._hud_heist_timer._heist_timer_panel:set_visible(true)
end

function HUDManager:feed_heist_time(t, ...)
	if SydneyHUD:GetOption("enable_corpse_remover_plus") then
		if t - SydneyHUD._last_removed_time >= SydneyHUD:GetOption("remove_interval") then

			if SydneyHUD:GetOption("remove_shield") then
				if managers.enemy then
					local enemy_data = managers.enemy._enemy_data
					local corpses = enemy_data.corpses
					for u_key, u_data in pairs(corpses) do
						if u_data.unit:inventory() ~= nil then
							u_data.unit:inventory():destroy_all_items()
						end
					end
				end
			end

			if SydneyHUD:GetOption("remove_body") then
				if managers.enemy and not managers.groupai:state():whisper_mode() then
					managers.enemy:dispose_all_corpses()
				end
			end

			SydneyHUD._last_removed_time = t
		end
	end

	if self._hud_assault_corner then
		self._hud_assault_corner:feed_heist_time(t)
	end
	feed_heist_time_original(self, t, ...)
	self._teammate_panels[self.PLAYER_PANEL]:change_health(0) -- force refresh hps meter atleast every second.
end

function HUDManager:update_armor_timer(...)
	self._teammate_panels[self.PLAYER_PANEL]:update_armor_timer(...)
end

function HUDManager:update_inspire_timer(...)
	self._teammate_panels[self.PLAYER_PANEL]:update_inspire_timer(...)
end

function HUDManager:teammate_progress(peer_id, type_index, enabled, tweak_data_id, timer, success, ...)
	teammate_progress_original(self, peer_id, type_index, enabled, tweak_data_id, timer, success, ...)
	local label = self:_name_label_by_peer_id(peer_id)
	local panel = self:teammate_panel_from_peer_id(peer_id)
	if panel then
		if label then
			self._teammate_panels[panel]:set_interact_text((label.panel:child("action"):text()))
		end
		self._teammate_panels[panel]:set_interact_visibility(enabled)
	end
end

function HUDManager:_mugshot_id_to_panel_id(id)
	for _, data in pairs(managers.criminals:characters()) do
		if data.data.mugshot_id == id then
			return data.data.panel_id
		end
	end
end

function HUDManager:_mugshot_id_to_unit(id)
	for _, data in pairs(managers.criminals:characters()) do
		if data.data.mugshot_id == id then
			return data.unit
		end
	end
end

function HUDManager:set_mugshot_downed(id)
	local panel_id = self:_mugshot_id_to_panel_id(id)
	local unit = self:_mugshot_id_to_unit(id)
	if panel_id and unit and unit:movement().current_state_name and unit:movement():current_state_name() == "bleed_out" then
		self._teammate_panels[panel_id]:increment_revives()
	end
	return set_mugshot_downed_original(self, id)
end

function HUDManager:set_mugshot_custody(id)
	local panel_id = self:_mugshot_id_to_panel_id(id)
	if panel_id then
		self._teammate_panels[panel_id]:reset_revives()
		self._teammate_panels[panel_id]:set_player_in_custody(true)
	end
	return set_mugshot_custody_original(self, id)
end

function HUDManager:set_mugshot_normal(id)
	local panel_id = self:_mugshot_id_to_panel_id(id)
	if panel_id then
		self._teammate_panels[panel_id]:set_player_in_custody(false)
	end
	return set_mugshot_normal_original(self, id)
end

function HUDManager:reset_teammate_revives(panel_id)
	if self._teammate_panels[panel_id] then
		self._teammate_panels[panel_id]:reset_revives()
	end
end

function HUDManager:set_mugshot_voice(id, active)
	local panel_id = self:_mugshot_id_to_panel_id(id)
	if panel_id and panel_id ~= HUDManager.PLAYER_PANEL then
		self._teammate_panels[panel_id]:set_voice_com(active)
	end
end

function HUDManager:set_hud_mode(mode)
	for _, panel in pairs(self._teammate_panels or {}) do
		panel:set_hud_mode(mode)
	end
end

function HUDManager:teammate_panel_from_peer_id(id)
	for panel_id, panel in pairs(self._teammate_panels or {}) do
		if panel._peer_id == id then
			return panel_id
		end
	end
end

function HUDManager:set_stamina_value(value, ...)
	self._teammate_panels[HUDManager.PLAYER_PANEL]:set_current_stamina(value)
	return set_stamina_value_original(self, value, ...)
end

function HUDManager:set_max_stamina(value, ...)
	self._teammate_panels[HUDManager.PLAYER_PANEL]:set_max_stamina(value)
	return set_max_stamina_original(self, value, ...)
end

function HUDManager:increment_kill_count(teammate_panel_id, is_special, headshot)
	self._teammate_panels[teammate_panel_id]:increment_kill_count(is_special, headshot)
end

function HUDManager:reset_kill_count(teammate_panel_id)
	self._teammate_panels[teammate_panel_id]:reset_kill_count()
end

function HUDManager:press_substitute(text, new)
	return text:gsub("Hold", new)
end

function HUDManager.show_interact(self, data)
	if self._interact_visible and not data.force then
		return
	end

	if SydneyHUD:GetOption("push_to_interact") and 0 >= SydneyHUD:GetOption("push_to_interact_delay")  then
		data.text = HUDManager:press_substitute(data.text, "Press")
	end

	self._interact_visible = true
	return show_interact_original(self, data)
end

function HUDManager.remove_interact(self)
	self._interact_visible = nil
	return remove_interact_original(self)
end

function HUDManager:show_underdog()
	if not SydneyHUD:GetOption("show_underdog_aced") then
		self._teammate_panels[ HUDManager.PLAYER_PANEL ]:hide_underdog()
		return
	end

	self._teammate_panels[ HUDManager.PLAYER_PANEL ]:show_underdog()

end

function HUDManager:hide_underdog()

	self._teammate_panels[ HUDManager.PLAYER_PANEL ]:hide_underdog()

end

function HUDManager:_setup_player_info_hud_pd2(...)
	_setup_player_info_hud_pd2_original(self, ...)

	if managers.gameinfo then
		managers.hudlist = managers.hudlist or HUDListManager:new()
	end
end

function HUDManager:update(t, dt, ...)
	if managers.hudlist then
		managers.hudlist:update(Application:time(), dt)	--TEST. See if this improves oddity with durations
	end

	return update_original(self, t, dt, ...)
end

function HUDManager:change_list_setting(setting, value)
	if managers.hudlist then
		return managers.hudlist:change_setting(setting, value)
	else
		HUDListManager.ListOptions[setting] = value
		return true
	end
end

HUDListManager = HUDListManager or class()

HUDListManager.ListOptions = {
	--General settings
	right_list_height_offset = 		SydneyHUD:GetOption("center_assault_banner") and 0 or 50,	--Margin from top for the right list
	right_list_scale = 				SydneyHUD:GetOption("right_list_scale") or 1,	--Size scale of right list
	left_list_height_offset = 		80,	--Margin from top for the left list
	left_list_scale = 				SydneyHUD:GetOption("left_list_scale") or 1,	--Size scale of left list
	buff_list_height_offset = 		80,	--Margin from bottom for the buff list
	buff_list_scale = 				SydneyHUD:GetOption("buff_list_scale") or 1,	--Size scale of buff list

	--Left side list
	show_timers = 					SydneyHUD:GetOption("show_timers"),	--Drills, time locks, hacking etc.
	show_ammo_bags = 				SydneyHUD:GetOption("show_equipment"),	--Show ammo bags/shelves and remaining amount, color-coded by owner
	show_doc_bags = 				SydneyHUD:GetOption("show_equipment"),	--Show doc bags/cabinets and remaining charges, color-coded by owner
	show_body_bags = 				SydneyHUD:GetOption("show_equipment"),	--Show body bags and remaining amount, color-coded by owner. Auto-disabled if heist goes loud
	show_grenade_crates = 			SydneyHUD:GetOption("show_equipment"),	--Show grenade crates with remaining amount
	show_sentries = 				SydneyHUD:GetOption("show_sentries"),	--Deployable sentries
	show_ecms = 					SydneyHUD:GetOption("show_ecms"),	--Active ECMs with time remaining
	show_ecm_retrigger = 			SydneyHUD:GetOption("show_ecm_retrigger"),	--Countdown for player owned ECM feedback retrigger delay
	show_minions = 					SydneyHUD:GetOption("show_minions"),	--Converted enemies, type and health
	show_pagers = 					SydneyHUD:GetOption("show_pagers"),	--Show currently active pagers
	show_tape_loop = 				SydneyHUD:GetOption("show_tape_loop"),	--Show active tape loop duration

	--Right side list
	show_enemies = 					SydneyHUD:GetOption("show_enemies"),		--Currently spawned enemies
	aggregate_enemies = 			SydneyHUD:GetOption("aggregate_enemies"),	--Aggregate all enemies into a single item
	show_turrets = 					SydneyHUD:GetOption("show_turrets"),	--Show active SWAT turrets
	show_civilians = 				SydneyHUD:GetOption("show_civilians"),	--Currently spawned, untied civs
	show_hostages = 				SydneyHUD:GetOption("show_hostages"),	--Currently tied civilian and dominated cops
	aggregate_hostages = 			SydneyHUD:GetOption("aggregate_hostages"),	--Aggregate all hostages into a single item
	show_minion_count = 			SydneyHUD:GetOption("show_minion_count"),	--Current number of jokered enemies
	show_pager_count = 				SydneyHUD:GetOption("show_pager_count"),	--Show number of triggered pagers (only counts pagers triggered while you were present). Auto-disabled if heist goes loud
	show_camera_count = 			SydneyHUD:GetOption("show_camera_count"),	--Show number of active cameras on the map. Auto-disabled if heist goes loud (experimental, has some issues)
	show_loot = 					SydneyHUD:GetOption("show_loot"),	--Show spawned and active loot bags/piles (may not be shown if certain mission parameters has not been met)
	aggregate_loot = 				SydneyHUD:GetOption("aggregate_loot"),	--Aggregate all loot into a single item
	separate_bagged_loot = 			SydneyHUD:GetOption("separate_bagged_loot"),	 --Show bagged/unbagged loot as separate values
	show_special_pickups = 			SydneyHUD:GetOption("show_special_pickups"),	--Show number of special equipment/items
	show_gage_packages = 			SydneyHUD:GetOption("show_gage_packages"),	--Show number of gage packages

	--Buff list
	show_buffs = SydneyHUD:GetOption("show_buffs")	--Active effects (buffs/debuffs)
	--Also see HUDList.BuffItemBase.MAP table for the buff icon definitions. Adding/changing the ignore flag to true or false will show/hide individual buffs
}

HUDListManager.TIMER_SETTINGS = {
	shoutout_raid = {
		[132864] = {	--Meltdown vault temperature
			class = "TemperatureGaugeItem",
			params = { start = 0, goal = 50 },
		},
	},
	nail = {
		[135076] = { ignore = true },	--Lab rats cloaker safe 2
		[135246] = { ignore = true },	--Lab rats cloaker safe 3
		[135247] = { ignore = true },	--Lab rats cloaker safe 4
	},
	help = {
		[400003] = { ignore = true },	--Prison Nightmare Big Loot timer
	},
	hvh = {
		[100007] = { ignore = true },	--Cursed kill room timer
		[100888] = { ignore = true },	--Cursed kill room timer
		[100889] = { ignore = true },	--Cursed kill room timer
		[100891] = { ignore = true },	--Cursed kill room timer
		[100892] = { ignore = true },	--Cursed kill room timer
		[100878] = { ignore = true },	--Cursed kill room timer
		[100176] = { ignore = true },	--Cursed kill room timer
		[100177] = { ignore = true },	--Cursed kill room timer
		[100029] = { ignore = true },	--Cursed kill room timer
		[141821] = { ignore = true },	--Cursed kill room safe 1 timer
		[141822] = { ignore = true },	--Cursed kill room safe 1 timer
		[140321] = { ignore = true },	--Cursed kill room safe 2 timer
		[140322] = { ignore = true },	--Cursed kill room safe 2 timer
		[139821] = { ignore = true },	--Cursed kill room safe 3 timer
		[139822] = { ignore = true },	--Cursed kill room safe 3 timer
		[141321] = { ignore = true },	--Cursed kill room safe 4 timer
		[141322] = { ignore = true },	--Cursed kill room safe 4 timer
		[140821] = { ignore = true },	--Cursed kill room safe 5 timer
		[140822] = { ignore = true },	--Cursed kill room safe 5 timer
	}
}

HUDListManager.UNIT_TYPES = {
	cop = 						{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	cop_scared = 				{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	cop_female = 				{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	fbi = 						{ type_id = "cop",			category = "enemies",	long_name = "FBI" },
	swat = 						{ type_id = "cop",			category = "enemies",	long_name = "SWAT" },
	heavy_swat = 				{ type_id = "cop",			category = "enemies",	long_name = "H. SWAT" },
	fbi_swat = 					{ type_id = "cop",			category = "enemies",	long_name = "FBI SWAT" },
	fbi_heavy_swat = 			{ type_id = "cop",			category = "enemies",	long_name = "H. FBI SWAT" },
	city_swat = 				{ type_id = "cop",			category = "enemies",	long_name = "Elite" },
	bolivian_indoors =			{ type_id = "security",		category = "enemies",	long_name = "Sosa Security" },
	security = 					{ type_id = "security",		category = "enemies",	long_name = "Sec. guard" },
	security_undominatable =	{ type_id = "security",		category = "enemies",	long_name = "Sec. guard" },
	gensec = 					{ type_id = "security",		category = "enemies",	long_name = "GenSec" },
	bolivian =					{ type_id = "thug",			category = "enemies",	long_name = "Sosa Thug" },
	gangster = 					{ type_id = "thug",			category = "enemies",	long_name = "Gangster" },
	mobster = 					{ type_id = "thug",			category = "enemies",	long_name = "Mobster" },
	biker = 					{ type_id = "thug",			category = "enemies",	long_name = "Biker" },
	biker_escape = 				{ type_id = "thug",			category = "enemies",	long_name = "Biker" },
	tank = 						{ type_id = "tank",			category = "enemies",	long_name = "Bulldozer" },
	tank_hw = 					{ type_id = "tank",			category = "enemies",	long_name = "Headless Bulldozer" },
	tank_medic = 				{ type_id = "tank",			category = "enemies",	long_name = "Medic Bulldozer" },
	tank_mini = 				{ type_id = "tank",			category = "enemies",	long_name = "Minigun Bulldozer" },
	spooc = 					{ type_id = "spooc",		category = "enemies",	long_name = "Cloaker" },
	taser = 					{ type_id = "taser",		category = "enemies",	long_name = "Taser" },
	shield = 					{ type_id = "shield",		category = "enemies",	long_name = "Shield" },
	sniper = 					{ type_id = "sniper",		category = "enemies",	long_name = "Sniper" },
	medic = 					{ type_id = "medic",		category = "enemies",	long_name = "Medic" },
	biker_boss =				{ type_id = "thug_boss",	category = "enemies",	long_name = "Biker Boss" },
	chavez_boss =				{ type_id = "thug_boss",	category = "enemies",	long_name = "Chavez" },
	drug_lord_boss =			{ type_id = "thug_boss",	category = "enemies",	long_name = "Sosa Boss" },
	drug_lord_boss_stealth =	{ type_id = "thug_boss",	category = "enemies",	long_name = "Sosa Boss" },
	mobster_boss = 				{ type_id = "thug_boss",	category = "enemies",	long_name = "Commissar" },
	hector_boss = 				{ type_id = "thug_boss",	category = "enemies",	long_name = "Hector" },
	hector_boss_no_armor = 		{ type_id = "thug_boss",	category = "enemies",	long_name = "Hector" },
	phalanx_vip = 				{ type_id = "phalanx",		category = "enemies",	long_name = "Cpt. Winter" },
	phalanx_minion = 			{ type_id = "phalanx",		category = "enemies",	long_name = "Phalanx" },
	civilian = 					{ type_id = "civ",			category = "civilians",	long_name = "Civilian" },
	civilian_female = 			{ type_id = "civ",			category = "civilians",	long_name = "Civilian" },
	bank_manager = 				{ type_id = "civ",			category = "civilians",	long_name = "Bank mngr." },
	--drunk_pilot = 			{ type_id = "unique",		category = "civilians",	long_name = "Pilot" },	--White X-mas
	--escort = 					{ type_id = "unique",		category = "civilians",	long_name = "Escort" },	--?
	--old_hoxton_mission = 		{ type_id = "unique",		category = "civilians",	long_name = "Hoxton" },	--Hox Breakout/BtM (Locke)
	--inside_man = 				{ type_id = "unique",		category = "civilians",	long_name = "Insider" },	--FWB
	--boris = 					{ type_id = "unique",		category = "civilians",	long_name = "Boris" },	--Goat sim
	--escort_undercover = 		{ type_id = "unique",		category = "civilians",	long_name = "Taxman" },	--Undercover

	--Custom unit definitions
	turret = 					{ type_id = "turret",		category = "turrets",	long_name = "SWAT Turret" },
	cop_hostage =				{ type_id = "cop_hostage",	category = "hostages",	long_name = "Dominated" },
	civ_hostage =				{ type_id = "civ_hostage",	category = "hostages",	long_name = "Hostage" },
	minion =					{ type_id = "minion",		category = "minions",	long_name = "Joker" },
}

HUDListManager.SPECIAL_PICKUP_TYPES = {
	gen_pku_crowbar =					"crowbar",
	pickup_keycard =					"keycard",
	pickup_hotel_room_keycard =			"keycard",
	gage_assignment =					"courier",
	pickup_case = 						"gage_case",
	pickup_keys = 						"gage_key",
	hold_take_mask = 					"paycheck_masks",
	pickup_boards =						"planks",
	stash_planks_pickup =				"planks",
	muriatic_acid =						"meth_ingredients",
	hydrogen_chloride =					"meth_ingredients",
	caustic_soda =						"meth_ingredients",
	gen_pku_blow_torch =				"blowtorch",
	drk_pku_blow_torch = 				"blowtorch",
	hold_born_receive_item_blow_torch = "blowtorch",
	thermite = 							"thermite",
	gasoline_engine = 					"thermite",
	gen_pku_thermite = 					"thermite",
	gen_pku_thermite_paste = 			"thermite",
	gen_int_thermite_rig = 				"thermite",
	hold_take_gas_can = 				"thermite",
	gen_pku_thermite_paste_z_axis = 	"thermite",
	c4_bag = 							"c4",
	money_wrap_single_bundle = 			"small_loot",
	money_wrap_single_bundle_active = 	"small_loot",
	money_wrap_single_bundle_dyn = 		"small_loot",
	cas_chips_pile = 					"small_loot",
	diamond_pickup = 					"small_loot",
	diamond_pickup_pal = 				"small_loot",
	diamond_pickup_axis = 				"small_loot",
	safe_loot_pickup = 					"small_loot",
	pickup_tablet = 					"small_loot",
	pickup_phone = 						"small_loot",
	press_pick_up =						"secret_item",
	hold_pick_up_turtle = 				"secret_item",
	diamond_single_pickup_axis = 		"secret_item",
	ring_band = 						"rings",
	glc_hold_take_handcuffs = 			"handcuffs",
	hold_take_missing_animal_poster = 	"poster",
	press_take_folder = 				"poster",
	--take_confidential_folder_icc = 	"poster",
	take_jfr_briefcase = 				"briefcase",
}

HUDListManager.LOOT_TYPES = {
	ammo =						"shell",
	artifact_statue =			"artifact",
	bike_part_light = 			"bike",
	bike_part_heavy = 			"bike",
	circuit =					"server",
	cloaker_cocaine = 			"coke",
	cloaker_gold = 				"gold",
	cloaker_money = 			"money",
	coke =						"coke",
	coke_pure =					"coke",
	counterfeit_money =			"money",
	cro_loot1 =					"bomb",
	cro_loot2 =					"bomb",
	diamonds =					"jewelry",
	diamond_necklace = 			"jewelry",
	din_pig =					"pig",
	drk_bomb_part =				"bomb",
	rone_control_helmet =		"drone_ctrl",
	evidence_bag =				"evidence",
	expensive_vine = 			"wine",
	goat = 						"goat",
	gold =						"gold",
	hope_diamond =				"diamond",
	diamonds_dah = 				"diamonds",
	red_diamond = 				"diamond",
	lost_artifact = 			"artifact",
	mad_master_server_value_1 =	"server",
	mad_master_server_value_2 =	"server",
	mad_master_server_value_3 =	"server",
	mad_master_server_value_4 =	"server",
	master_server = 			"server",
	masterpiece_painting =		"painting",
	meth =						"meth",
	meth_half =					"meth",
	money =						"money",
	mus_artifact =				"artifact",
	mus_artifact_paint =		"painting",
	old_wine = 					"wine",
	ordinary_wine = 			"wine",
	painting =					"painting",
	person =					"body",
	present = 					"present",
	prototype = 				"prototype",
	robot_toy = 				"toy",
	safe_ovk =					"safe",
	safe_wpn =					"safe",
	samurai_suit =				"armor",
	sandwich =					"toast",
	special_person =			"body",
	toothbrush = 				"toothbrush",
	turret =					"turret",
	unknown =					"dentist",
	vr_headset = 				"vr",
	warhead =					"warhead",
	weapon =					"weapon",
	weapon_glock =				"weapon",
	weapon_scar =				"weapon",
	women_shoes = 				"shoes",
	yayo = 						"coke",
}

HUDListManager.POTENTIAL_LOOT_TYPES = {
	crate = 					"crate",
	xmas_present = 				"xmas_present",
	shopping_bag = 				"shopping_bag",
	showcase = 					"showcase",
}

HUDListManager.LOOT_TYPES_CONDITIONS = {
	body = function(id, data)
		if managers.job:current_level_id() == "mad" then -- Boiling Point
			return data.bagged or data.unit:editor_id() ~= -1
		end

		--TODO: Bodies need to be omitted from aggregation, okayish for PB heist but bad for generic stealth maps
		--return managers.groupai and managers.groupai:state():whisper_mode()
	end,
	crate = function(id, data)
		local level_id = managers.job:current_level_id()
		local disabled_lvls = {
			"election_day_3", 		-- Election Day Day 2 Warehouse
			"election_day_3_skip1",
			"election_day_3_skip2",
			"mia_1",		 		-- Hotline Miami Day 1
			"pal" 					-- Counterfeit
		}
		return not (level_id and table.contains(disabled_lvls, level_id))
	end,
	showcase = function(id, data)
		local level_id = managers.job:current_level_id()
		local disabled_lvls = {
			"mus", 		-- The Diamond
		}
		return not (level_id and table.contains(disabled_lvls, level_id))
	end
}

HUDListManager.BUFFS = {
	--Buff list items affected by specific buffs/debuffs. Add entries if buff ID differs from the HUDList buff entry for some reason, or if a single buff ID affect multiple items
	berserker = { "berserker", "damage_increase", "melee_damage_increase" },
	berserker_aced = { "berserker", "damage_increase" },
	bloodthirst_basic = { "bloodthirst_basic", "melee_damage_increase" },
	close_contact_1 = { "close_contact", "damage_reduction" },
	close_contact_2 = { "close_contact", "damage_reduction" },
	close_contact_3 = { "close_contact", "damage_reduction" },
	combat_medic = { "combat_medic", "damage_reduction" },
	combat_medic_passive = { "combat_medic_passive", "damage_reduction" },
	die_hard = { "die_hard", "damage_reduction" },
	hostage_situation = { "hostage_situation", "damage_reduction" },
	melee_stack_damage = { "melee_stack_damage", "melee_damage_increase" },
	overdog = { "overdog", "damage_reduction" },
	overkill = { "overkill", "damage_increase" },
	overkill_aced = { "overkill", "damage_increase" },
	pain_killer = { "painkiller", "damage_reduction" },			--TODO: UNTESTED
	pain_killer_aced = { "painkiller", "damage_reduction" },		--TODO: UNTESTED
	partner_in_crime_aced = { "partner_in_crime" },
	quick_fix = { "quick_fix", "damage_reduction" },
	running_from_death_basic = { "running_from_death" },
	running_from_death_aced = { "running_from_death" },
	swan_song_aced = { "swan_song" },
	trigger_happy = { "trigger_happy", "damage_increase" },
	underdog = { "underdog", "damage_increase" },
	underdog_aced = { "underdog", "damage_reduction" },
	up_you_go = { "up_you_go", "damage_reduction" },
	yakuza_recovery = { "yakuza" },
	yakuza_speed = { "yakuza" },

	armorer_9 = { "armorer" },
	crew_chief_1 = { "crew_chief", "damage_reduction" },	--Bonus for <50% health changed separately through set_value
	crew_chief_3 = { "crew_chief" },
	crew_chief_5 = { "crew_chief" },
	crew_chief_9 = { "crew_chief" },	--Damage reduction from hostages covered by hostage_situation

	--Debuffs that are merged into the buff itself
	composite_debuffs = {
		armor_break_invulnerable_debuff = "armor_break_invulnerable",
		grinder_debuff = "grinder",
		chico_injector_debuff = "chico_injector",
		delayed_damage_debuff = "delayed_damage",
		maniac_debuff = "maniac",
		sicario_dodge_debuff = "sicario_dodge",
		smoke_screen_grenade_debuff = "smoke_screen_grenade",
		tag_team_debuff = "tag_team",
		unseen_strike_debuff = "unseen_strike",
		uppers_debuff = "uppers",
		interact_debuff = "interact",
	},
}

function HUDListManager:init()
	self._lists = {}
	self._unit_count_listeners = 0

	self:_setup_left_list()
	self:_setup_right_list()
	self:_setup_buff_list()

	managers.gameinfo:register_listener("HUDList_whisper_mode_listener", "whisper_mode", "change", callback(self, self, "_whisper_mode_change"))
end

function HUDListManager:update(t, dt)
	for _, list in pairs(self._lists) do
		if list:is_active() then
			list:update(t, dt)
		end
	end
end

function HUDListManager:list(name)
	return self._lists[name]
end

function HUDListManager:change_setting(setting, value)
	local clbk = "_set_" .. setting
	if HUDListManager[clbk] and HUDListManager.ListOptions[setting] ~= value then
		HUDListManager.ListOptions[setting] = value
		self[clbk](self)
		return true
	end
end

function HUDListManager:register_list(name, class, params, ...)
	if not self._lists[name] then
		class = type(class) == "string" and _G.HUDList[class] or class
		self._lists[name] = class and class:new(nil, name, params, ...)
	end

	return self._lists[name]
end

function HUDListManager:unregister_list(name, instant)
	if self._lists[name] then
		self._lists[name]:delete(instant)
	end
	self._lists[name] = nil
end

function HUDListManager:_setup_left_list()
	local list_width = 600
	local list_height = 800
	local x = 0
	local y = HUDListManager.ListOptions.left_list_height_offset or 40
	local scale = HUDListManager.ListOptions.left_list_scale or 1
	local list = self:register_list("left_side_list", HUDList.VerticalList, { align = "left", x = x, y = y, w = list_width, h = list_height, top_to_bottom = true, item_margin = 5 })

	--Timers
	local timer_list = list:register_item("timers", HUDList.HorizontalList, { align = "top", w = list_width, h = 40 * scale, left_to_right = true, item_margin = 5 })
	timer_list:set_static_item(HUDList.LeftListIcon, 1, 4/5, {
		{ atlas = true, texture_rect = { 3 * 64, 6 * 64, 64, 64 } },
	})

	--Deployables
	local equipment_list = list:register_item("equipment", HUDList.HorizontalList, { align = "top", w = list_width, h = 40 * scale, left_to_right = true, item_margin = 5 })
	equipment_list:set_static_item(HUDList.LeftListIcon, 1, 1, {
		--{ atlas = true, h = 2/3, w = 2/3, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.ammo_bag.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.ammo_bag.atlas[2] * 64, 64, 64 }, valign = "top", halign = "right" },
		--{ atlas = true, h = 2/3, w = 2/3, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.doc_bag.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.doc_bag.atlas[2] * 64, 64, 64 }, valign = "bottom", halign = "left" },
		{ atlas = true, h = 0.55, w = 0.55, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.ammo_bag.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.ammo_bag.atlas[2] * 64, 64, 64 }, valign = "top", halign = "right" },
		{ atlas = true, h = 0.55, w = 0.55, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.doc_bag.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.doc_bag.atlas[2] * 64, 64, 64 }, valign = "top", halign = "left" },
		{ atlas = true, h = 0.55, w = 0.55, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.sentry.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.sentry.atlas[2] * 64, 64, 64 }, valign = "bottom", halign = "right" },
		{ atlas = true, h = 0.55, w = 0.55, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.body_bag.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.body_bag.atlas[2] * 64, 64, 64 }, valign = "bottom", halign = "left" },
	})

	--Minions
	local minion_list = list:register_item("minions", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, left_to_right = true, item_margin = 5 })
	minion_list:set_static_item(HUDList.LeftListIcon, 1, 4/5, {
		{ atlas = true, texture_rect = { 6 * 64, 8 * 64, 64, 64 } },
	})

	--Pagers
	local pager_list = list:register_item("pagers", HUDList.HorizontalList, { align = "top", w = list_width, h = 40 * scale, left_to_right = true, item_margin = 5 })
	pager_list:set_static_item(HUDList.LeftListIcon, 1, 1, {
		{ spec = true, texture_rect = { 1 * 64, 4 * 64, 64, 64 } },
	})

	--ECMs
	local ecm_list = list:register_item("ecms", HUDList.HorizontalList, { align = "top", w = list_width, h = 30 * scale, left_to_right = true, item_margin = 5 })
	ecm_list:set_static_item(HUDList.LeftListIcon, 1, 1, {
		{ atlas = true, texture_rect = { 1 * 64, 4 * 64, 64, 64 } },
	})

	--ECM trigger
	local retrigger_list = list:register_item("ecm_retrigger", HUDList.HorizontalList, { align = "top", w = list_width, h = 30 * scale, left_to_right = true, item_margin = 5 })
	retrigger_list:set_static_item(HUDList.LeftListIcon, 1, 1, {
		{ atlas = true, texture_rect = { 6 * 64, 2 * 64, 64, 64 } },
	})

	--Tape loop
	local tape_loop_list = list:register_item("tape_loop", HUDList.HorizontalList, { align = "top", w = list_width, h = 30 * scale, left_to_right = true, item_margin = 5 })
	tape_loop_list:set_static_item(HUDList.LeftListIcon, 1, 1, {
		{ atlas = true, texture_rect = { 4 * 64, 2 * 64, 64, 64 } },
	})

	self:_set_show_timers()
	self:_set_show_ammo_bags()
	self:_set_show_doc_bags()
	self:_set_show_body_bags()
	self:_set_show_grenade_crates()
	self:_set_show_sentries()
	self:_set_show_minions()
	self:_set_show_pagers()
	self:_set_show_ecms()
	self:_set_show_ecm_retrigger()
	self:_set_show_tape_loop()
end

function HUDListManager:_setup_right_list()
	local list_width = 800
	local list_height = 800
	local x = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel:right() - list_width
	local y = HUDListManager.ListOptions.right_list_height_offset or 0
	local scale = HUDListManager.ListOptions.right_list_scale or 1
	local list = self:register_list("right_side_list", HUDList.VerticalList, { align = "right", x = x, y = y, w = list_width, h = list_height, top_to_bottom = true, item_margin = 5 })

	local unit_count_list = list:register_item("unit_count_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 1 })
	local stealth_list = list:register_item("stealth_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 4 })
	local loot_list = list:register_item("loot_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 2 })
	local special_equipment_list = list:register_item("special_pickup_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 4 })

	self:_set_show_enemies()
	self:_set_show_turrets()
	self:_set_show_civilians()
	self:_set_show_hostages()
	self:_set_show_minion_count()
	self:_set_show_pager_count()
	self:_set_show_camera_count()
	self:_set_show_loot()
	self:_set_show_special_pickups()
end

function HUDListManager:_setup_buff_list()
	local hud_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel
	local scale = HUDListManager.ListOptions.buff_list_scale or 1
	local list_height = 70 * scale
	local list_width = hud_panel:w()
	local x = 0
	local y = hud_panel:bottom() - ((HUDListManager.ListOptions.buff_list_height_offset or 80) + list_height)

	local buff_list = self:register_list("buff_list", HUDList.HorizontalList, {
		align = "center",
		x = x,
		y = y ,
		w = list_width,
		h = list_height,
		centered = true,
		item_margin = 0,
		item_move_speed = 300,
		fade_time = 0.15,
	})

	self:_set_show_buffs()
end

function HUDListManager:_whisper_mode_change(event, key, status)
	--Need this to update corpse counter for stealth heist
	--[[
	for _, item in pairs(self:list("right_side_list"):item("loot_list"):items()) do
		item:update_value()
	end
	]]
end

function HUDListManager:_get_buff_items(id)
	local buff_list = self:list("buff_list")
	local items = {}

	local function register_item(item_id)
		local item_data = HUDList.BuffItemBase.MAP[item_id]

		if item_data and not item_data.ignore then
			local item =
			buff_list:item(item_id) or
					buff_list:register_item(item_id, item_data.class or "BuffItemBase", item_data)
			table.insert(items, item)
		end
	end

	if HUDListManager.BUFFS[id] then
		for _, item_id in ipairs(HUDListManager.BUFFS[id]) do
			register_item(item_id)
		end
	else
		register_item(id)
	end

	return items
end

function HUDListManager:_get_units_by_category(category)
	local all_types = {}
	local all_ids = {}

	for unit_id, data in pairs(HUDListManager.UNIT_TYPES) do
		if data.category == category then
			all_types[data.type_id] = all_types[data.type_id] or {}
			table.insert(all_types[data.type_id], unit_id)
			table.insert(all_ids, unit_id)
		end
	end

	return all_types, all_ids
end

function HUDListManager:_update_unit_count_list_items(list, id, members, show)
	if show then
		local data = HUDList.UnitCountItem.MAP[id]
		local item = list:register_item(id, data.class or HUDList.UnitCountItem, id, members)
	else
		list:unregister_item(id, true)
	end
end

function HUDListManager:_update_deployable_list_items(type, enabled)
	local list = self:list("left_side_list"):item("equipment")
	local listener_id = string.format("HUDListManager_%s_listener", type)
	local events = { "set_active" }
	local clbk = callback(self, self, string.format("_%s_event", type))

	for _, event in pairs(events) do
		if enabled then
			managers.gameinfo:register_listener(listener_id, type, event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, type, event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_deployables(type)) do
		if enabled then
			clbk("set_active", key, data)
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_bag_deployable_event(event, key, data, class, bag_type)
	if data.aggregate_key then return end

	local equipment_list = self:list("left_side_list"):item("equipment")

	if event == "set_active" then
		if data.active then
			equipment_list:register_item(key, class, data, bag_type)
		else
			equipment_list:unregister_item(key)
		end
	end
end



--Event handlers
function HUDListManager:_timer_event(event, key, data)
	local settings = HUDListManager.TIMER_SETTINGS[data.id] or {}

	if not settings.ignore then
		local timer_list = self:list("left_side_list"):item("timers")

		if event == "set_active" then
			if data.active then
				timer_list:register_item(key, settings.class or HUDList.TimerItem, data, settings.params):activate()
			else
				timer_list:unregister_item(key)
			end
		end
	end
end

function HUDListManager:_minion_event(event, key, data)
	local minion_list = self:list("left_side_list"):item("minions")

	if event == "add" then
		minion_list:register_item(key, HUDList.MinionItem, data):activate()
	elseif event == "remove" then
		minion_list:unregister_item(key)
	end
end

function HUDListManager:_pager_event(event, key, data)
	local pager_list = self:list("left_side_list"):item("pagers")

	if event == "add" then
		pager_list:register_item(key, HUDList.PagerItem, data):activate()
	elseif event == "remove" then
		pager_list:unregister_item(key)
	end
end

function HUDListManager:_ecm_event(event, key, data)
	local list = self:list("left_side_list"):item("ecms")

	if event == "set_jammer_active" then
		if data.jammer_active then
			list:register_item(key, HUDList.ECMItem, data):activate()
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_ecm_retrigger_event(event, key, data)
	local list = self:list("left_side_list"):item("ecm_retrigger")

	if event == "set_retrigger_active" then
		if data.retrigger_active then
			list:register_item(key, HUDList.ECMRetriggerItem, data):activate()
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_tape_loop_event(event, key, data)
	local list = self:list("left_side_list"):item("tape_loop")

	if event == "start_tape_loop" then
		list:register_item(key, HUDList.TapeLoopItem, data):activate()
	elseif event == "stop_tape_loop" then
		list:unregister_item(key)
	end
end

function HUDListManager:_sentry_equipment_event(event, key, data)
	local equipment_list = self:list("left_side_list"):item("equipment")

	if event == "set_active" then
		if data.active then
			equipment_list:register_item(key, HUDList.SentryEquipmentItem, data):activate()
		end
	elseif event == "destroy" then
		equipment_list:unregister_item(key)
	end
end

function HUDListManager:_buff_event(event, id, data)
	--printf("(%.3f) HUDListManager:_buff_event(%s, %s)", Application:time(), tostring(event), tostring(id))

	local items = self:_get_buff_items(id)

	for _, item in ipairs(items) do
		if item[event] then
			item[event](item, id, data)
		--else
			--printf("(%.3f) HUDListManager:_buff_event: No matching function for event %s for buff %s", event, id)
		end
	end

	if HUDListManager.BUFFS.composite_debuffs[id] then
		if event == "activate" or event == "deactivate" or event == "set_duration" then
			local debuff_parent_id = HUDListManager.BUFFS.composite_debuffs[id]
			self:_buff_event(event .. "_debuff", debuff_parent_id, data)
		end
	end
end

function HUDListManager:_player_action_event(event, id, data)
	self:_buff_event(event, id, data)
end

function HUDListManager:_ammo_bag_event(event, key, data)
	self:_bag_deployable_event(event, key, data, HUDList.AmmoBagItem, "ammo_bag")
end

function HUDListManager:_doc_bag_event(event, key, data)
	self:_bag_deployable_event(event, key, data, HUDList.BagEquipmentItem, "doc_bag")
end

function HUDListManager:_body_bag_event(event, key, data)
	self:_bag_deployable_event(event, key, data, HUDList.BodyBagItem, "body_bag")
end

function HUDListManager:_grenade_crate_event(event, key, data)
	self:_bag_deployable_event(event, key, data, HUDList.BagEquipmentItem, "grenade_crate")
end

--Left list config
function HUDListManager:_set_show_timers()
	local list = self:list("left_side_list"):item("timers")
	local listener_id = "HUDListManager_timer_listener"
	local events = { "set_active" }
	local clbk = callback(self, self, "_timer_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_timers then
			managers.gameinfo:register_listener(listener_id, "timer", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "timer", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_timers()) do
		if HUDListManager.ListOptions.show_timers then
			clbk("set_active", key, data)
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_set_show_minions()
	local listener_id = "HUDListManager_minion_listener"
	local events = { "add", "remove" }
	local clbk = callback(self, self, "_minion_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_minions then
			managers.gameinfo:register_listener(listener_id, "minion", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "minion", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_minions()) do
		clbk(HUDListManager.ListOptions.show_minions and "add" or "remove", key, data)
	end
end

function HUDListManager:_set_show_pagers()
	local list = self:list("left_side_list"):item("pagers")
	local listener_id = "HUDListManager_pager_listener"
	local events = { "add", "remove" }
	local clbk = callback(self, self, "_pager_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_pagers then
			managers.gameinfo:register_listener(listener_id, "pager", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "pager", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_pagers()) do
		if HUDListManager.ListOptions.show_pagers then
			if data.active then
				clbk("add", key, data)
			end
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_set_show_ecms()
	local list = self:list("left_side_list"):item("ecms")
	local listener_id = "HUDListManager_ecm_listener"
	local events = { "set_jammer_active" }
	local clbk = callback(self, self, "_ecm_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_ecms then
			managers.gameinfo:register_listener(listener_id, "ecm", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "ecm", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_ecms()) do
		if HUDListManager.ListOptions.show_ecms then
			clbk("set_jammer_active", key, data)
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_set_show_ecm_retrigger()
	local list = self:list("left_side_list"):item("ecm_retrigger")
	local listener_id = "HUDListManager_ecm_listener"
	local events = { "set_retrigger_active" }
	local clbk = callback(self, self, "_ecm_retrigger_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_ecm_retrigger then
			managers.gameinfo:register_listener(listener_id, "ecm", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "ecm", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_ecms()) do
		if HUDListManager.ListOptions.show_ecm_retrigger then
			clbk("set_retrigger_active", key, data)
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_set_show_ammo_bags()
	self:_update_deployable_list_items("ammo_bag", HUDListManager.ListOptions.show_ammo_bags)
end

function HUDListManager:_set_show_doc_bags()
	self:_update_deployable_list_items("doc_bag", HUDListManager.ListOptions.show_doc_bags)
end

function HUDListManager:_set_show_body_bags()
	self:_update_deployable_list_items("body_bag", HUDListManager.ListOptions.show_body_bags)
end

function HUDListManager:_set_show_grenade_crates()
	self:_update_deployable_list_items("grenade_crate", HUDListManager.ListOptions.show_grenade_crates)
end

function HUDListManager:_set_show_tape_loop()
	local list = self:list("left_side_list"):item("tape_loop")
	local listener_id = "HUDListManager_tape_loop_listener"
	local events = { "start_tape_loop", "stop_tape_loop" }
	local clbk = callback(self, self, "_tape_loop_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_tape_loop then
			managers.gameinfo:register_listener(listener_id, "camera", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "camera", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_cameras()) do
		if data.tape_loop_expire_t and HUDListManager.ListOptions.show_tape_loop then
			clbk("start_tape_loop", key, data)
		else
			list:unregister_item(key)
		end
	end
end

function HUDListManager:_set_show_sentries()
	local listener_id = "HUDListManager_sentry_listener"
	local events = { "set_active", "destroy" }
	local spawned_items = managers.gameinfo:get_sentries()

	if HUDListManager.ListOptions.show_sentries then
		local clbk = callback(self, self, "_sentry_equipment_event")

		for key, data in pairs(spawned_items) do
			self:_sentry_equipment_event("set_active", key, data)
		end

		for _, event in pairs(events) do
			managers.gameinfo:register_listener(listener_id, "sentry", event, clbk)
		end
	else
		local list = self:list("left_side_list"):item("equipment")

		for _, event in pairs(events) do
			managers.gameinfo:unregister_listener(listener_id, "sentry", event)
		end

		for key, data in pairs(spawned_items) do
			list:unregister_item(key)
		end
	end
end

--Right list config
function HUDListManager:_set_show_enemies()
	local list = self:list("right_side_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("enemies")

	if HUDListManager.ListOptions.aggregate_enemies then
		self:_update_unit_count_list_items(list, "enemies", all_ids, HUDListManager.ListOptions.show_enemies)
	else
		for unit_type, unit_ids in pairs(all_types) do
			self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_enemies)
		end
	end
end

function HUDListManager:_set_aggregate_enemies()
	local list = self:list("right_side_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("enemies")
	all_types.enemies = {}

	for unit_type, unit_ids in pairs(all_types) do
		list:unregister_item(unit_type)
	end

	self:_set_show_enemies()
end

function HUDListManager:_set_show_civilians()
	local list = self:list("right_side_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("civilians")

	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_civilians)
	end
end

function HUDListManager:_set_show_hostages()
	local list = self:list("right_side_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("hostages")

	if HUDListManager.ListOptions.aggregate_hostages then
		self:_update_unit_count_list_items(list, "hostages", all_ids, HUDListManager.ListOptions.show_hostages)
	else
		for unit_type, unit_ids in pairs(all_types) do
			self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_hostages)
		end
	end
end

function HUDListManager:_set_aggregate_hostages()
	local list = self:list("right_side_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("hostages")
	all_types.hostages = {}

	for unit_type, unit_ids in pairs(all_types) do
		local item = list:item(unit_type)
		if item then
			item:delete(true)
		end
	end

	self:_set_show_hostages()
end

function HUDListManager:_set_show_minion_count()
	local list = self:list("right_side_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("minions")

	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_minion_count)
	end
end

function HUDListManager:_set_show_turrets()
	local list = self:list("right_side_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("turrets")

	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_turrets)
	end
end

function HUDListManager:_set_show_pager_count()
	local list = self:list("right_side_list"):item("stealth_list")

	if HUDListManager.ListOptions.show_pager_count then
		list:register_item("PagerCount", HUDList.UsedPagersItem)
	else
		list:unregister_item("PagerCount", true)
	end
end

function HUDListManager:_set_show_camera_count()
	local list = self:list("right_side_list"):item("stealth_list")

	if HUDListManager.ListOptions.show_camera_count then
		list:register_item("CameraCount", HUDList.CameraCountItem)
	else
		list:unregister_item("CameraCount", true)
	end
end

function HUDListManager:_set_show_special_pickups()
	local list = self:list("right_side_list"):item("special_pickup_list")
	local all_ids = {}
	local all_types = {}

	for pickup_id, pickup_type in pairs(HUDListManager.SPECIAL_PICKUP_TYPES) do
		all_types[pickup_type] = all_types[pickup_type] or {}
		table.insert(all_types[pickup_type], pickup_id)
		table.insert(all_ids, pickup_id)
	end

	for pickup_type, members in pairs(all_types) do
		if (pickup_type ~= "courier" and HUDListManager.ListOptions.show_special_pickups) or (pickup_type == "courier" and HUDListManager.ListOptions.show_gage_packages) then
			list:register_item(pickup_type, HUDList.SpecialPickupItem, pickup_type, members)
		else
			list:unregister_item(pickup_type, true)
		end
	end
end

function HUDListManager:_set_show_loot()
	local list = self:list("right_side_list"):item("loot_list")
	local all_ids = {}
	local all_types = {}

	for loot_id, loot_type in pairs(HUDListManager.LOOT_TYPES) do
		all_types[loot_type] = all_types[loot_type] or {}
		table.insert(all_types[loot_type], loot_id)
		table.insert(all_ids, loot_id)
	end

	if HUDListManager.ListOptions.aggregate_loot then
		if HUDListManager.ListOptions.show_loot then
			list:register_item("aggregate", HUDList.LootItem, "aggregate", all_ids)
		else
			list:unregister_item("aggregate", true)
		end
	else
		for loot_type, members in pairs(all_types) do
			if HUDListManager.ListOptions.show_loot then
				list:register_item(loot_type, HUDList.LootItem, loot_type, members)
			else
				list:unregister_item(loot_type, true)
			end
		end
	end
end

function HUDListManager:_set_aggregate_loot()
	local list = self:list("right_side_list"):item("loot_list")
	local all_ids = {}
	local all_types = {}
	all_types.aggregate = {}

	for loot_id, loot_type in pairs(HUDListManager.LOOT_TYPES) do
		all_types[loot_type] = all_types[loot_type] or {}
		table.insert(all_types[loot_type], loot_id)
		table.insert(all_ids, loot_id)
	end

	for loot_type, loot_id in pairs(all_types) do
		list:unregister_item(loot_type)
	end

	self:_set_show_loot()
end

function HUDListManager:_set_separate_bagged_loot()
	for _, item in pairs(self:list("right_side_list"):item("loot_list"):items()) do
		item:update_value()
	end
end

--Buff list
function HUDListManager:_set_show_buffs()
	local listener_id = "HUDListManager_buff_listener"
	local sources = {
		buff = {
			"activate",
			"deactivate",
			"set_duration",
			"set_stack_count",
			"add_timed_stack",
			"remove_timed_stack",
			"set_value",
			clbk = callback(self, self, "_buff_event"),
		},
		player_action = {
			"activate",
			"deactivate",
			"set_duration",
			clbk = callback(self, self, "_player_action_event"),
		},
	}

	for src, data in pairs(sources) do
		for _, event in ipairs(data) do
			if HUDListManager.ListOptions.show_buffs then
				managers.gameinfo:register_listener(listener_id, src, event, data.clbk)
			else
				managers.gameinfo:unregister_listener(listener_id, src, event)
			end
		end
	end

	if HUDListManager.ListOptions.show_buffs then
		for id, data in pairs(managers.gameinfo:get_buffs()) do
			self:_buff_event("activate", id)

			if data.stacks then
				self:_buff_event("add_timed_stack", id, data)
			end

			if data.t and data.expire_t then
				self:_buff_event("set_duration", id, data)
			end

			if data.stack_count then
				self:_buff_event("set_stack_count", id, data)
			end

			if data.value then
				self:_buff_event("set_value", id, data)
			end
		end

		for id, data in pairs(managers.gameinfo:get_player_actions()) do
			self:_player_action_event("activate", id, data)

			if data.t and data.expire_t then
				self:_player_action_event("set_duration", id, data)
			end

			if data.data then
				self:_player_action_event("set_data", id, data)
			end
		end
	else
		for _, item in pairs(self:list("buff_list"):items()) do
			item:delete()
		end
	end
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--LIST CLASS DEFINITION BLOCK
HUDList = HUDList or {}

HUDList.ItemBase = HUDList.ItemBase or class()
function HUDList.ItemBase:init(parent_list, name, params)
	self._parent_list = parent_list
	self._name = name
	self._align = params.align or "center"
	self._fade_time = params.fade_time or 0.25
	self._move_speed = params.move_speed or 150
	self._priority = params.priority
	self._listener_clbks = {}

	self._panel = (self._parent_list and self._parent_list:panel() or params.native_panel or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel):panel({
		name = name,
		visible = true,
		alpha = 0,
		w = params.w or 0,
		h = params.h or 0,
		x = params.x or 0,
		y = params.y or 0,
		layer = 10
	})
end

function HUDList.ItemBase:post_init()
	for i, data in ipairs(self._listener_clbks) do
		for _, event in pairs(data.event) do
			managers.gameinfo:register_listener(data.name, data.source, event, data.clbk, data.keys, data.data_only)
		end
	end
end

function HUDList.ItemBase:destroy()
	for i, data in ipairs(self._listener_clbks) do
		for _, event in pairs(data.event) do
			managers.gameinfo:unregister_listener(data.name, data.source, event)
		end
	end
end

function HUDList.ItemBase:name() return self._name end
function HUDList.ItemBase:panel() return self._panel end
function HUDList.ItemBase:parent_list() return self._parent_list end
function HUDList.ItemBase:align() return self._align end
function HUDList.ItemBase:is_active() return self._active end
function HUDList.ItemBase:priority() return self._priority end
function HUDList.ItemBase:fade_time() return self._fade_time end
function HUDList.ItemBase:hidden() return self._force_hide end

function HUDList.ItemBase:_set_item_visible(status)
	self._panel:set_visible(status and not self._force_hide)
end

function HUDList.ItemBase:set_force_hide(status)
	self._force_hide = status
	self:_set_item_visible(self._active)
	if self._parent_list then
		self._parent_list:set_item_hidden(self, status)
	end
end

function HUDList.ItemBase:set_priority(priority)
	self._priority = priority
end

function HUDList.ItemBase:set_fade_time(time)
	self._fade_time = time
end

function HUDList.ItemBase:set_move_speed(speed)
	self._move_speed = speed
end

function HUDList.ItemBase:set_active(status)
	if status then
		self:activate()
	else
		self:deactivate()
	end
end

function HUDList.ItemBase:activate()
	self._active = true
	self._scheduled_for_deletion = nil
	self:_show()
end

function HUDList.ItemBase:deactivate()
	self._active = false
	self:_hide()
end

function HUDList.ItemBase:delete(instant)
	self._scheduled_for_deletion = true
	self._active = false
	self:_hide(instant)
end

function HUDList.ItemBase:_delete()
	self:destroy()
	if alive(self._panel) then
		--self._panel:stop()		--Should technically do this, but screws with unrelated animations for some reason...
		if self._parent_list then
			self._parent_list:_remove_item(self)
			self._parent_list:set_item_visible(self, false)
		end
		if alive(self._panel:parent()) then
			self._panel:parent():remove(self._panel)
		end
	end
end

function HUDList.ItemBase:_show(instant)
	if alive(self._panel) then
		--self._panel:set_visible(true)
		self:_set_item_visible(true)
		self:_fade(1, instant)
		if self._parent_list then
			self._parent_list:set_item_visible(self, true)
		end
	end
end

function HUDList.ItemBase:_hide(instant)
	if alive(self._panel) then
		self:_fade(0, instant)
		if self._parent_list then
			self._parent_list:set_item_visible(self, false)
		end
	end
end

function HUDList.ItemBase:_fade(target_alpha, instant)
	self._panel:stop()
	--if self._panel:alpha() ~= target_alpha then
	--self._active_fade = { instant = instant, alpha = target_alpha }
	self._active_fade = { instant = instant or self._panel:alpha() == target_alpha, alpha = target_alpha }
	--end
	self:_animate_item()
end

function HUDList.ItemBase:move(x, y, instant)
	if alive(self._panel) then
		self._panel:stop()
		--if self._panel:x() ~= x or self._panel:y() ~= y then
		--self._active_move = { instant = instant, x = x, y = y }
		self._active_move = { instant = instant or (self._panel:x() == x and self._panel:y() == y), x = x, y = y }
		--end
		self:_animate_item()
	end
end

function HUDList.ItemBase:cancel_move()
	self._panel:stop()
	self._active_move = nil
	self:_animate_item()
end

function HUDList.ItemBase:_animate_item()
	if alive(self._panel) and self._active_fade then
		self._panel:animate(callback(self, self, "_animate_fade"), self._active_fade.alpha, self._active_fade.instant)
	end

	if alive(self._panel) and self._active_move then
		self._panel:animate(callback(self, self, "_animate_move"), self._active_move.x, self._active_move.y, self._active_move.instant)
	end
end

function HUDList.ItemBase:_animate_fade(panel, alpha, instant)
	if not instant and self._fade_time > 0 then
		local fade_time = self._fade_time
		local init_alpha = panel:alpha()
		local change = alpha > init_alpha and 1 or -1
		local T = math.abs(alpha - init_alpha) * fade_time
		local t = 0

		while alive(panel) and t < T do
			panel:set_alpha(math.clamp(init_alpha + t * change * 1 / fade_time, 0, 1))
			t = t + coroutine.yield()
		end
	end

	self._active_fade = nil
	if alive(panel) then
		panel:set_alpha(alpha)
		--panel:set_visible(alpha > 0)
		self:_set_item_visible(alpha > 0)
	end
	--if self._parent_list and alpha == 0 then
	--	self._parent_list:set_item_visible(self, false)
	--end
	if self._scheduled_for_deletion then
		self:_delete()
	end
end

function HUDList.ItemBase:_animate_move(panel, x, y, instant)
	if not instant and self._move_speed > 0 then
		local move_speed = self._move_speed
		local init_x = panel:x()
		local init_y = panel:y()
		local x_change = x > init_x and 1 or x < init_x and -1
		local y_change = y > init_y and 1 or y < init_y and -1
		local T = math.max(math.abs(x - init_x) / move_speed, math.abs(y - init_y) / move_speed)
		local t = 0

		while alive(panel) and t < T do
			if x_change then
				panel:set_x(init_x  + t * x_change * move_speed)
			end
			if y_change then
				panel:set_y(init_y  + t * y_change * move_speed)
			end
			t = t + coroutine.yield()
		end
	end

	self._active_move = nil
	if alive(panel) then
		panel:set_x(x)
		panel:set_y(y)
	end
end

--TODO: Move this stuff. Good to have, but has nothing to do with the list and should be localized to subclasses where it is used
HUDList.ItemBase.DEFAULT_COLOR_TABLE = {
	{ ratio = 0.0, color = Color(1, 0.9, 0.1, 0.1) }, --Red
	{ ratio = 0.5, color = Color(1, 0.9, 0.9, 0.1) }, --Yellow
	{ ratio = 1.0, color = Color(1, 0.1, 0.9, 0.1) } --Green
}
function HUDList.ItemBase:_get_color_from_table(value, max_value, color_table, default_color)
	local color_table = color_table or HUDList.ItemBase.DEFAULT_COLOR_TABLE
	local ratio = math.clamp(value / max_value, 0 , 1)
	local tmp_color = color_table[#color_table].color
	local color = default_color or Color(tmp_color.alpha, tmp_color.red, tmp_color.green, tmp_color.blue)

	for i, data in ipairs(color_table) do
		if ratio < data.ratio then
			local nxt = color_table[math.clamp(i-1, 1, #color_table)]
			local scale = (ratio - data.ratio) / (nxt.ratio - data.ratio)
			color = Color(
				(data.color.alpha or 1) * (1-scale) + (nxt.color.alpha or 1) * scale,
				(data.color.red or 0) * (1-scale) + (nxt.color.red or 0) * scale,
				(data.color.green or 0) * (1-scale) + (nxt.color.green or 0) * scale,
				(data.color.blue or 0) * (1-scale) + (nxt.color.blue or 0) * scale)
			break
		end
	end

	return color
end

function HUDList.ItemBase:_create_icons(data)
	local icons_added = {}

	for i, icon in ipairs(data) do
		local x, y = unpack((icon.atlas or icon.spec) or { 0, 0 })
		local texture = icon.texture
				or icon.spec and "guis/textures/pd2/specialization/icons_atlas"
				or icon.atlas and "guis/textures/pd2/skilltree/icons_atlas"
				or icon.waypoints and "guis/textures/pd2/pd2_waypoints"
				or icon.hudtabs and "guis/textures/pd2/hud_tabs"
				or icon.hudpickups and "guis/textures/pd2/hud_pickups"
				or icon.hudicons and "guis/textures/hud_icons"
				or icon.sydney and "guis/textures/controller"
		local texture_rect = (icon.spec or icon.atlas) and { x * 64, y * 64, 64, 64 } or icon.waypoints or icon.hudtabs or icon.hudpickups or icon.hudicons or icon.sydney or icon.texture_rect

		local new_icon = self._panel:bitmap({
			name = data.name or "icon",
			texture = texture,
			texture_rect = texture_rect,
			h = icon.h or self._panel:h(),
			w = icon.w or self._panel:w(),
			alpha = icon.alpha or 1,
			blend_mode = icon.blend_mode or "normal",
			color = icon.color or Color.white,
			layer = icon.layer or 0,
		})

		if icon.halign == "center" then
			new_icon:set_center_x(self._panel:w() / 2)
		elseif icon.halign == "right" then
			new_icon:set_right(self._panel:w())
		end

		if icon.valign == "center" then
			new_icon:set_center_y(self._panel:h() / 2)
		elseif icon.valign == "bottom" then
			new_icon:set_bottom(self._panel:h())
		end

		table.insert(icons_added, new_icon)
	end

	return icons_added
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

HUDList.ListBase = HUDList.ListBase or class(HUDList.ItemBase) --DO NOT INSTANTIATE THIS CLASS
function HUDList.ListBase:init(parent, name, params)
	params.fade_time = params.fade_time or 0
	HUDList.ListBase.super.init(self, parent, name, params)

	self._stack = params.stack or false
	self._queue = not self._stack
	self._item_fade_time = params.item_fade_time
	self._item_move_speed = params.item_move_speed
	self._item_margin = params.item_margin or 0
	self._margin = params.item_margin or 0
	self._stack = params.stack or false
	self._items = {}
	self._shown_items = {}
end

function HUDList.ListBase:item(name)
	return self._items[name]
end

function HUDList.ListBase:items()
	return self._items
end

function HUDList.ListBase:num_items()
	return table.size(self._items)
end

function HUDList.ListBase:active_items()
	local count  = 0
	for name, item in pairs(self._items) do
		if item:is_active() then
			count = count + 1
		end
	end
	return count
end

function HUDList.ListBase:shown_items()
	return #self._shown_items
end

function HUDList.ListBase:update(t, dt)
	local delete_items = {}
	for name, item in pairs(self._items) do
		if item.update and item:is_active() then
			item:update(t, dt)
		end
	end
end

function HUDList.ListBase:register_item(name, class, ...)
	if not self._items[name] then
		class = type(class) == "string" and _G.HUDList[class] or class
		local new_item = class and class:new(self, name, ...)

		if new_item then
			if self._item_fade_time then
				new_item:set_fade_time(self._item_fade_time)
			end
			if self._item_move_speed then
				new_item:set_move_speed(self._item_move_speed)
			end
			new_item:post_init(...)
			self:_set_default_item_position(new_item)
		end

		self._items[name] = new_item
	end

	return self._items[name]
end

function HUDList.ListBase:unregister_item(name, instant)
	if self._items[name] then
		self._items[name]:delete(instant)
	end
end

function HUDList.ListBase:set_static_item(class, ...)
	self:delete_static_item()

	if type(class) == "string" then
		class = _G.HUDList[class]
	end

	self._static_item = class and class:new(self, "static_list_item", ...)
	if self._static_item then
		self:setup_static_item()
		self._static_item:panel():show()
		self._static_item:panel():set_alpha(1)
	end

	return self._static_item
end

function HUDList.ListBase:delete_static_item()
	if self._static_item then
		self._static_item:delete(true)
		self._static_item = nil
	end
end

function HUDList.ListBase:set_item_visible(item, visible)
	local index
	for i, shown_item in ipairs(self._shown_items) do
		if shown_item == item then
			index = i
			break
		end
	end

	--local threshold = self._static_item and 1 or 0	--TODO

	if visible and not index then
		if #self._shown_items <= 0 then
			self:activate()
		end

		local insert_index = #self._shown_items + 1
		if item:priority() then
			for i, list_item in ipairs(self._shown_items) do
				if not list_item:priority() or (list_item:priority() > item:priority()) then
					insert_index = i
					break
				end
			end
		end

		table.insert(self._shown_items, insert_index, item)
	elseif not visible and index then
		table.remove(self._shown_items, index)
		if #self._shown_items <= 0 then
			managers.enemy:add_delayed_clbk("visibility_cbk_" .. self._name, callback(self, self, "_cbk_update_visibility"), Application:time() + item:fade_time())
			--self:deactivate()
		end
	else
		return
	end

	self:_update_item_positions(item)
end

function HUDList.ListBase:set_item_hidden(item, hidden)
	self:_update_item_positions(nil, true)
end

function HUDList.ListBase:_cbk_update_visibility()
	if #self._shown_items <= 0 then
		self:deactivate()
	end
end

function HUDList.ListBase:_remove_item(item)
	self._items[item:name()] = nil
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

HUDList.HorizontalList = HUDList.HorizontalList or class(HUDList.ListBase)
function HUDList.HorizontalList:init(parent, name, params)
	params.align = params.align == "top" and "top" or params.align == "bottom" and "bottom" or "center"
	HUDList.HorizontalList.super.init(self, parent, name, params)
	self._left_to_right = params.left_to_right
	self._right_to_left = params.right_to_left and not self._left_to_right
	self._centered = params.centered and not (self._right_to_left or self._left_to_right)
end

function HUDList.HorizontalList:_set_default_item_position(item)
	local offset = self._panel:h() - item:panel():h()
	local y = item:align() == "top" and 0 or item:align() == "bottom" and offset or offset / 2
	item:panel():set_top(y)
end

function HUDList.HorizontalList:setup_static_item()
	local item = self._static_item
	local offset = self._panel:h() - item:panel():h()
	local y = item:align() == "top" and 0 or item:align() == "bottom" and offset or offset / 2
	local x = self._left_to_right and 0 or self._panel:w() - item:panel():w()
	item:panel():set_left(x)
	item:panel():set_top(y)
	self:_update_item_positions()
end

function HUDList.HorizontalList:_update_item_positions(insert_item, instant_move)
	if self._centered then
		local total_width = self._static_item and (self._static_item:panel():w() + self._item_margin) or 0
		for i, item in ipairs(self._shown_items) do
			if not item:hidden() then
				total_width = total_width + item:panel():w() + self._item_margin
			end
		end
		total_width = total_width - self._item_margin

		local left = (self._panel:w() - math.min(total_width, self._panel:w())) / 2

		if self._static_item then
			self._static_item:move(left, item:panel():y(), instant_move)
			left = left + self._static_item:panel():w() + self._item_margin
		end

		for i, item in ipairs(self._shown_items) do
			if not item:hidden() then
				if insert_item and item == insert_item then
					if item:panel():x() ~= left then
						item:panel():set_x(left - item:panel():w() / 2)
						item:move(left, item:panel():y(), instant_move)
					end
				else
					item:move(left, item:panel():y(), instant_move)
				end
				left = left + item:panel():w() + self._item_margin
			end
		end
	else
		local prev_width = self._static_item and (self._static_item:panel():w() + self._item_margin) or 0
		for i, item in ipairs(self._shown_items) do
			if not item:hidden() then
				local width = item:panel():w()
				local new_x = (self._left_to_right and prev_width) or (self._panel:w() - (width+prev_width))
				if insert_item and item == insert_item then
					item:panel():set_x(new_x)
					item:cancel_move()
				else
					item:move(new_x, item:panel():y(), instant_move)
				end

				prev_width = prev_width + width + self._item_margin
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

HUDList.VerticalList = HUDList.VerticalList or class(HUDList.ListBase)
function HUDList.VerticalList:init(parent, name, params)
	params.align = params.align == "left" and "left" or params.align == "right" and "right" or "center"
	HUDList.VerticalList.super.init(self, parent, name, params)
	self._top_to_bottom = params.top_to_bottom
	self._bottom_to_top = params.bottom_to_top and not self._top_to_bottom
	self._centered = params.centered and not (self._bottom_to_top or self._top_to_bottom)
end

function HUDList.VerticalList:_set_default_item_position(item)
	local offset = self._panel:w() - item:panel():w()
	local x = item:align() == "left" and 0 or item:align() == "right" and offset or offset / 2
	item:panel():set_left(x)
end

function HUDList.VerticalList:setup_static_item()
	local item = self._static_item
	local offset = self._panel:w() - item:panel():w()
	local x = item:align() == "left" and 0 or item:align() == "right" and offset or offset / 2
	local y = self._top_to_bottom and 0 or self._panel:h() - item:panel():h()
	item:panel():set_left(x)
	item:panel():set_y(y)
	self:_update_item_positions()
end

function HUDList.VerticalList:_update_item_positions(insert_item, instant_move)
	if self._centered then
		local total_height = self._static_item and (self._static_item:panel():h() + self._item_margin) or 0
		for i, item in ipairs(self._shown_items) do
			if not item:hidden() then
				total_height = total_width + item:panel():h() + self._item_margin
			end
		end
		total_height = total_height - self._item_margin

		local top = (self._panel:h() - math.min(total_height, self._panel:h())) / 2

		if self._static_item then
			self._static_item:move(item:panel():x(), top, instant_move)
			top = top + self._static_item:panel():h() + self._item_margin
		end

		for i, item in ipairs(self._shown_items) do
			if not item:hidden() then
				if insert_item and item == insert_item then
					if item:panel():y() ~= top then
						item:panel():set_y(top - item:panel():h() / 2)
						item:move(item:panel():x(), top, instant_move)
					end
				else
					item:move(item:panel():x(), top, instant_move)
				end
				top = top + item:panel():h() + self._item_margin
			end
		end
	else
		local prev_height = self._static_item and (self._static_item:panel():h() + self._item_margin) or 0
		for i, item in ipairs(self._shown_items) do
			if not item:hidden() then
				local height = item:panel():h()
				local new_y = (self._top_to_bottom and prev_height) or (self._panel:h() - (height+prev_height))
				if insert_item and item == insert_item then
					item:panel():set_y(new_y)
					item:cancel_move()
				else
					item:move(item:panel():x(), new_y, instant_move)
				end
				prev_height = prev_height + height + self._item_margin
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--LIST ITEM CLASS DEFINITION BLOCK

--Right list

HUDList.RightListItem = HUDList.RightListItem or class(HUDList.ItemBase)
function HUDList.RightListItem:init(parent, name, icon, params)
	params = params or {}
	params.align = params.align or "right"
	params.w = params.w or parent:panel():h() / 2
	params.h = params.h or parent:panel():h()
	HUDList.RightListItem.super.init(self, parent, name, params)

	local x, y = unpack((icon.atlas or icon.spec) or { 0, 0 })
	local texture = icon.texture
			or icon.spec and "guis/textures/pd2/specialization/icons_atlas"
			or icon.atlas and "guis/textures/pd2/skilltree/icons_atlas"
			or icon.waypoints and "guis/textures/pd2/pd2_waypoints"
			or icon.hudtabs and "guis/textures/pd2/hud_tabs"
			or icon.hudpickups and "guis/textures/pd2/hud_pickups"
			or icon.hudicons and "guis/textures/hud_icons"
	local texture_rect = (icon.spec or icon.atlas) and { x * 64, y * 64, 64, 64 } or icon.waypoints or icon.hudtabs or icon.hudpickups or icon.hudicons or icon.texture_rect

	self._icon = self._panel:bitmap({
		name = "icon",
		texture = texture,
		texture_rect = texture_rect,
		h = self._panel:w() * (icon.h_ratio or 1),
		w = self._panel:w() * (icon.w_ratio or 1),
		alpha = icon.alpha or 1,
		blend_mode = icon.blend_mode or "normal",
		color = icon.color or Color.white,
	})

	self._box = HUDBGBox_create(self._panel, {
		w = self._panel:w(),
		h = self._panel:w(),
	}, {})
	self._box:set_bottom(self._panel:bottom())

	self._text = self._box:text({
		name = "text",
		text = "",
		align = "center",
		vertical = "center",
		w = self._box:w(),
		h = self._box:h(),
		color = Color.white,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.6
	})

	self._count = 0
end

function HUDList.RightListItem:get_count()
	return self._count or 0
end

function HUDList.RightListItem:change_count(diff)
	self:set_count(self._count + diff)
end

function HUDList.RightListItem:set_count(num)
	self._count = num
	self._text:set_text(tostring(self._count))
	self:set_active(self._count > 0)
end

local enemy_color = Color(SydneyHUD:GetOption("enemy_color_r"), SydneyHUD:GetOption("enemy_color_g"), SydneyHUD:GetOption("enemy_color_b"))
local guard_color = enemy_color
local special_color = enemy_color
local turret_color = enemy_color
local thug_color = enemy_color
local civilian_color = Color(SydneyHUD:GetOption("civilian_color_r"), SydneyHUD:GetOption("civilian_color_g"), SydneyHUD:GetOption("civilian_color_b"))
local hostage_color = civilian_color

HUDList.UnitCountItem = HUDList.UnitCountItem or class(HUDList.RightListItem)
HUDList.UnitCountItem.MAP = {
	--TODO: Security and cop are both able to be dominate/jokered. Specials could cause issues if made compatible. Straight subtraction won't work. Should be fine for aggregated enemy counter
	enemies =		{ atlas = {0, 5}, color = enemy_color, --[[subtract = { "cop_hostage", "minion" }]] },	--Aggregated enemies
	hostages =		{ atlas = {4, 7}, color = hostage_color, priority = 1 },	--Aggregated hostages

	cop =				{ atlas = {0, 5}, color = enemy_color, priority = 5, --[[subtract = { "cop_hostage", "minion" }]] },	--Non-special police. Subtract type iffy if specials are dominated/converted
	security =		{ spec = {1, 4}, color = guard_color, priority = 4 },
	thug =			{ atlas = {4, 12}, color = thug_color, priority = 4 },
	tank =			{ atlas = {3, 1}, color = special_color, priority = 6 },
	spooc =			{ atlas = {1, 3}, color = special_color, priority = 6 },
	taser =			{ atlas = {3, 5}, color = special_color, priority = 6 },
	shield =			{ texture = "guis/textures/pd2/hud_buff_shield", color = special_color, priority = 6 },
	sniper =			{ atlas = {6, 5}, color = special_color, priority = 6 },
	medic =			{ atlas = {5, 7}, color = special_color, priority = 6 },
	thug_boss =		{ atlas = {1, 1}, color = thug_color, priority = 4 },
	phalanx =		{ texture = "guis/textures/pd2/hud_buff_shield", color = special_color, priority = 7 },

	turret =			{ atlas = {7, 5}, color = turret_color, priority = 4 },
	unique =			{ atlas = {3, 8}, color = civilian_color, priority = 3, },
	cop_hostage =	{ atlas = {2, 8}, color = hostage_color, priority = 2 },
	civ_hostage =	{ atlas = {4, 7}, color = hostage_color, priority = 1 },
	minion =			{ atlas = {6, 8}, color = hostage_color, priority = 0 },
	civ =				{ atlas = {6, 7}, color = civilian_color, priority = 3, subtract = { "civ_hostage" } },
}
function HUDList.UnitCountItem:init(parent, name, id, unit_types)
	local unit_data = HUDList.UnitCountItem.MAP[id]
	local params = { priority = unit_data.priority }

	HUDList.UnitCountItem.super.init(self, parent, name, unit_data, params)

	self._id = id
	self._unit_types = {}
	self._subtract_types = {}
	self._unit_count = {}

	local total_count = 0
	local keys = {}

	for _, unit_id in pairs(unit_types or {}) do
		local count = managers.gameinfo:get_unit_count(unit_id)
		total_count = total_count + count
		self._unit_count[unit_id] = count
		self._unit_types[unit_id] = true
		table.insert(keys, unit_id)
	end

	for _, unit_id in pairs(unit_data.subtract or {}) do
		local count = managers.gameinfo:get_unit_count(unit_id)
		total_count = total_count - count
		self._unit_count[unit_id] = count
		self._subtract_types[unit_id] = true
		table.insert(keys, unit_id)
	end

	self._listener_clbks = {
		{
			name = string.format("HUDList_%s_unit_count_listener", id),
			source = "unit_count",
			event = { "change" },
			clbk = callback(self, self, "_change_count_clbk"),
			keys = keys
		}
	}

	if self._id == "shield" then	--Shield special case for filling the shield icon
		self._shield_filler = self._panel:rect({
			name = "shield_filler",
			w = self._icon:w() * 0.4,
			h = self._icon:h() * 0.4,
			color = special_color,
			blend_mode = "normal",
			layer = self._icon:layer() - 1,
		})
		self._shield_filler:set_center(self._icon:center())
	end

	self:set_count(total_count)
end

function HUDList.UnitCountItem:_change_count_clbk(event, unit_type, value)
	self._unit_count[unit_type] = self._unit_count[unit_type] + value

	if self._subtract_types[unit_type] then
		self:change_count(-value)
	else
		self:change_count(value)
	end
end


HUDList.UsedPagersItem = HUDList.UsedPagersItem or class(HUDList.RightListItem)
function HUDList.UsedPagersItem:init(parent, name)
	HUDList.UsedPagersItem.super.init(self, parent, name, { spec = {1, 4} })

	self._listener_clbks = {
		{
			name = "HUDList_pager_count_listener",
			source = "pager",
			event = { "add" },
			clbk = callback(self, self, "_add_pager"),
		},
		{
			name = "HUDList_pager_count_listener",
			source = "whisper_mode",
			event = { "change" },
			clbk = callback(self, self, "_whisper_mode_change"),
			data_only = true,
		}
	}

	self:set_count(table.size(managers.gameinfo:get_pagers()))
end

function HUDList.UsedPagersItem:_add_pager(...)
	self:change_count(1)
end

function HUDList.UsedPagersItem:_whisper_mode_change(status)
	self:set_active(self._count > 0 and status)
end

function HUDList.UsedPagersItem:set_count(num)
	if managers.groupai:state():whisper_mode() then
		HUDList.UsedPagersItem.super.set_count(self, num)

		if self._count >= 5 then
			self._text:set_color(Color.red)
		end
	end
end


HUDList.CameraCountItem = HUDList.CameraCountIteM or class(HUDList.RightListItem)
function HUDList.CameraCountItem:init(parent, name)
	HUDList.CameraCountItem.super.init(self, parent, name, { atlas = {4, 2} })

	self._listener_clbks = {
		{
			name = "HUDList_camera_count_listener",
			source = "camera_count",
			event = { "set_count" },
			clbk = callback(self, self, "set_count"),
			data_only = true,
		}
	}

	self:set_count(managers.gameinfo:_recount_active_cameras())
end


HUDList.SpecialPickupItem = HUDList.SpecialPickupItem or class(HUDList.RightListItem)
if SydneyHUD:GetOption("new_icon") then
	HUDList.SpecialPickupItem.MAP = {
		crowbar =					{ sydney = { 0, 0, 32, 32 } },
		keycard =					{ sydney = { 32, 0, 32, 32 } },
		planks =					{ hudpickups = { 0, 32, 32, 32 } },
		meth_ingredients =			{ waypoints  = { 192, 32, 32, 32 } },
		blowtorch = 				{ hudpickups = { 96, 192, 32, 32 } },
		thermite = 					{ hudpickups = { 64, 64, 32, 32 } },
		c4 = 						{ hudicons	 = { 36, 242, 32, 32 } },
		small_loot = 				{ hudpickups = { 32, 224, 32, 32} },
		briefcase = 				{ hudpickups = { 96, 224, 32, 32} },
		courier =					{ sydney = { 224, 0, 32, 32 } },
		gage_case = 				{ skills 	 = { 1, 0 } },
		gage_key = 					{ hudpickups = { 32, 64, 32, 32 } },
		paycheck_masks = 			{ hudpickups = { 128, 32, 32, 32 } },
		secret_item =				{ sydney = { 96, 0, 32, 32 } }, -- TODO: find an actual icon for secret_item. this is still the blowtorch icon
		rings = 					{ texture = "guis/textures/pd2/level_ring_small", w_ratio = 0.5, h_ratio = 0.5 },
		poster = 					{ hudpickups = { 96, 96, 32, 32 } },
		handcuffs = 				{ hud_icons  = {294,469, 40, 40 } }
	}
else
	HUDList.SpecialPickupItem.MAP = {
		crowbar =					{ hudpickups = { 0, 64, 32, 32 } },
		keycard =					{ hudpickups = { 32, 0, 32, 32 } },
		planks =					{ hudpickups = { 0, 32, 32, 32 } },
		meth_ingredients =			{ waypoints  = { 192, 32, 32, 32 } },
		blowtorch = 				{ hudpickups = { 96, 192, 32, 32 } },
		thermite = 					{ hudpickups = { 64, 64, 32, 32 } },
		c4 = 						{ hudicons	 = { 36, 242, 32, 32 } },
		small_loot = 				{ hudpickups = { 32, 224, 32, 32} },
		briefcase = 				{ hudpickups = { 96, 224, 32, 32} },
		courier = 					{ texture = "guis/dlcs/gage_pack_jobs/textures/pd2/endscreen/gage_assignment" },
		gage_case = 				{ skills 	 = { 1, 0 } },
		gage_key = 					{ hudpickups = { 32, 64, 32, 32 } },
		paycheck_masks = 			{ hudpickups = { 128, 32, 32, 32 } },
		secret_item =				{ waypoints  = { 96, 64, 32, 32 } },
		rings = 					{ texture = "guis/textures/pd2/level_ring_small", w_ratio = 0.5, h_ratio = 0.5 },
		poster = 					{ hudpickups = { 96, 96, 32, 32 } },
		handcuffs = 				{ hud_icons  = {294,469, 40, 40 } }
	}
end
function HUDList.SpecialPickupItem:init(parent, name, id, members)
	local pickup_data = HUDList.SpecialPickupItem.MAP[id]
	local params = { priority = pickup_data.priority }

	HUDList.SpecialPickupItem.super.init(self, parent, name, pickup_data, params)

	self._pickup_types = {}

	local keys = {}
	for _, pickup_id in pairs(members) do
		self._pickup_types[pickup_id] = true
		table.insert(keys, pickup_id)
	end

	local total_count = 0
	for _, data in pairs(managers.gameinfo:get_special_equipment()) do
		if self._pickup_types[data.interact_id] then
			total_count = total_count + 1
		end
	end

	self._listener_clbks = {
		{
			name = string.format("HUDList_%s_special_pickup_count_listener", id),
			source = "special_equipment_count",
			event = { "change" },
			clbk = callback(self, self, "_change_special_equipment_count_clbk"),
			keys = keys
		}
	}

	self:set_count(total_count)
end

function HUDList.SpecialPickupItem:_change_special_equipment_count_clbk(event, interact_id, value, data)
	self:change_count(value)
end


HUDList.LootItem = HUDList.LootItem or class(HUDList.RightListItem)
HUDList.LootItem.MAP = {
	aggregate =		{ text = "" },			--Aggregated loot

	armor =			{ text = "Armor" },   	-- Shadow Raid
	artifact =		{ text = "Artifact" },   -- Shadow Raid, The Diamond, The Yacht Heist
	bike =			{ text = "Bike Part" },  -- Biker Heist
	body =			{ text = "Body" },   	-- Boiling Point
	bomb =			{ text = "Bomb" },  	-- The Bomb: Dockyard/Forest, Murky Station
	coke =			{ text = "Coke" },
	dentist =		{ text = "Unknown" },	-- Golden Grin Casino
	diamond =		{ text = "Diamond" },	-- The Diamond, The Diamond Heist Red Diamond
	diamonds =		{ text = "Diamond" }, 	-- The Diamond Heist
	drone_ctrl =	{ text = "Drone" },		-- Biker Heist
	evidence =		{ text = "Evidence" },	-- Hoxton Revenge
	goat =			{ text = "Goat" },		-- Goat Simulator
	gold =			{ text = "Gold" },
	jewelry =		{ text = "Jewelry" },
	meth =			{ text = "Meth" },
	money =			{ text = "Money" },
	painting =		{ text = "Painting" },
	pig =			{ text = "Pig" },		-- Slaughterhouse
	present =		{ text = "Present" },	-- Santa's Workshop
	prototype =		{ text = "Prototype" },
	safe =			{ text = "Safe" },		-- Aftershock
	server =		{ text = "Server" },
	shell =			{ text = "Shell" },		-- Transport: Train Heist
	shoes =			{ text = "Shoes" },		-- Stealing Xmas
	toast =			{ text = "Toast" },		-- White Xmas
	toothbrush =	{ text = "Toothbrush" },-- Panic Room
	toy =			{ text = "Toy" },		-- Stealing Xmas
	turret =		{ text = "Turret" },	-- Transport: Train Heist
	vr = 			{ text = "Headset" },	-- Stealing Xmas
	warhead =		{ text = "Warhead" },	-- Meltdown
	weapon =		{ text = "Weapon" },
	wine =			{ text = "Wine" },		-- Stealing Xmas
	crate =	 		{ text = "Crate" },
	xmas_present = 	{ text = "Present" },	-- White Xmas
	shopping_bag = 	{ text = "Bag" },		-- White Xmas
	showcase =		{ text = "Showcase" }	-- Diamond Heist
}
function HUDList.LootItem:init(parent, name, id, members)
	local loot_data = HUDList.LootItem.MAP[id]

	HUDList.LootItem.super.init(self, parent, name, loot_data.icon_data or { hudtabs = { 32, 33, 32, 32 }, alpha = 0.75, w_ratio = 1.2 })

	self._id = id
	self._loot_types = {}
	self._total_count = 0
	self._bagged_count = 0
	self._unbagged_count = 0

	self._icon:set_center(self._panel:center())
	self._icon:set_top(self._panel:top())

	if loot_data.text then
		self._name_text = self._panel:text({
			name = "text",
			text = string.sub(loot_data.text, 1, 5) or "",
			align = "center",
			vertical = "center",
			w = self._panel:w() * 0.8,
			h = self._panel:w(),
			color = Color(0.0, 0.5, 1.0),
			blend_mode = "normal",
			font = tweak_data.hud_corner.assault_font,
			font_size = self._panel:w() * 0.4,
			layer = 10
		})
		self._name_text:set_center(self._icon:center())
		self._name_text:set_y(self._name_text:y() + self._icon:h() * 0.1)
	end

	local keys = {}

	for _, loot_id in pairs(members) do
		self._loot_types[loot_id] = true
		table.insert(keys, loot_id)
	end

	self._listener_clbks = {
		{
			name = string.format("HUDList_%s_loot_count_listener", id),
			source = "loot_count",
			event = { "change" },
			clbk = callback(self, self, "_change_loot_count_clbk"),
			keys = keys
		}
	}

	self:update_value()
end

function HUDList.LootItem:update_value()
	local total_unbagged = 0
	local total_bagged = 0

	for _, data in pairs(managers.gameinfo:get_loot()) do
		if self._loot_types[data.carry_id] then
			local loot_type = HUDListManager.LOOT_TYPES[data.carry_id]
			local condition_clbk = HUDListManager.LOOT_TYPES_CONDITIONS[loot_type]

			if not condition_clbk or condition_clbk(loot_type, data) then
				if data.bagged then
					total_bagged = total_bagged + data.count
				else
					total_unbagged = total_unbagged + data.count
				end
			end
		end
	end

	self:set_count(total_unbagged, total_bagged)
end

function HUDList.LootItem:get_count()
	return self._unbagged_count or 0, self._bagged_count or 0
end

function HUDList.LootItem:set_count(unbagged, bagged)
	self._unbagged_count = unbagged
	self._bagged_count = bagged
	self._total_count = self._unbagged_count + self._bagged_count

	if HUDListManager.ListOptions.separate_bagged_loot then
		self._text:set_text(self._unbagged_count .. "/" .. self._bagged_count)
	else
		self._text:set_text(self._total_count)
	end

	self:set_active(self._total_count > 0)
end

function HUDList.LootItem:_change_loot_count_clbk(event, carry_id, bagged, value, data)
	local loot_type = HUDListManager.LOOT_TYPES[carry_id]
	local condition_clbk = HUDListManager.LOOT_TYPES_CONDITIONS[loot_type]

	if not condition_clbk or condition_clbk(loot_type, data) then
		local bagged_count = self._bagged_count
		local unbagged_count = self._unbagged_count

		if bagged then
			bagged_count = bagged_count + value
		else
			unbagged_count = unbagged_count + value
		end

		self:set_count(unbagged_count, bagged_count)
	end
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Left list items

HUDList.LeftListIcon = HUDList.LeftListIcon or class(HUDList.ItemBase)
function HUDList.LeftListIcon:init(parent, name, ratio_w, ratio_h, icons)
	HUDList.ItemBase.init(self, parent, name, { align = "center", w = parent:panel():h() * (ratio_w or 1), h = parent:panel():h() * (ratio_h or 1) })

	self._icons = {}
	for i, icon in ipairs(icons) do
		local texture = icon.spec and "guis/textures/pd2/specialization/icons_atlas"
				or icon.atlas and "guis/textures/pd2/skilltree/icons_atlas"
				or icon.waypoints and "guis/textures/pd2/pd2_waypoints"
				or icon.texture

		local bitmap = self._panel:bitmap({
			name = "icon_" .. tostring(i),
			texture = texture,
			texture_rect = icon.texture_rect or nil,
			h = self:panel():w() * (icon.h or 1),
			w = self:panel():w() * (icon.w or 1),
			blend_mode = "add",
			color = icon.color or Color.white,
		})

		bitmap:set_center(self._panel:center())
		if icon.valign == "top" then
			bitmap:set_top(self._panel:top())
		elseif icon.valign == "bottom" then
			bitmap:set_bottom(self._panel:bottom())
		end
		if icon.halign == "left" then
			bitmap:set_left(self._panel:left())
		elseif icon.halign == "right" then
			bitmap:set_right(self._panel:right())
		end

		table.insert(self._icons, bitmap)
	end
end

HUDList.TimerItem = HUDList.TimerItem or class(HUDList.ItemBase)
HUDList.TimerItem.STANDARD_COLOR = Color(1, 1, 1, 1)
HUDList.TimerItem.UPGRADE_COLOR = Color(1, 0.0, 0.8, 1.0)
HUDList.TimerItem.AUTOREPAIR_COLOR = Color(1, 1, 0, 1)
HUDList.TimerItem.DISABLED_COLOR = Color(1, 1, 0, 0)
HUDList.TimerItem.FLASH_SPEED = 2
HUDList.TimerItem.DEVICE_TYPES = {
	digital = "Timer",
	drill = "Drill",
	hack = "Hack",
	saw = "Saw",
	timer = "Timer",
	securitylock = "Hack",
}
function HUDList.TimerItem:init(parent, name, data)
	HUDList.ItemBase.init(self, parent, name, { align = "left", w = parent:panel():h() * 4/5, h = parent:panel():h() })

	self._show_distance = true
	self._unit = data.unit
	self._device_type = data.device_type
	self._jammed = data.jammed
	self._powered = data.powered
	self._upgradable = data.upgradable

	self._type_text = self._panel:text({
		name = "type_text",
		text = self.DEVICE_TYPES[self._device_type] or "Timer",
		align = "center",
		vertical = "top",
		w = self._panel:w(),
		h = self._panel:h() * 0.3,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:h() * 1/3
	})

	self._box = HUDBGBox_create(self._panel, {
		w = self._panel:w(),
		h = self._panel:h() * 0.7,
	}, {})
	self._box:set_bottom(self._panel:bottom())

	self._distance_text = self._box:text({
		name = "distance",
		align = "center",
		vertical = "top",
		w = self._box:w(),
		h = self._box:h(),
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.4
	})

	self._time_text = self._box:text({
		name = "time",
		align = "center",
		vertical = "bottom",
		w = self._box:w(),
		h = self._box:h(),
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.6
	})

	local current_color = self:_get_color()
	self._flash_color_table = {
		{ ratio = 0.0, color = self.DISABLED_COLOR },
		{ ratio = 1.0, color = current_color }
	}
	self:_set_colors(current_color)

	self:_set_jammed(data)
	self:_set_powered(data)
	self:_set_upgradable(data)
	self:_update_timer(data)

	local key = tostring(self._unit:key())
	local id = string.format("HUDList_timer_listener_%s", key)
	local events = {
		update = callback(self, self, "_update_timer"),
		set_jammed = callback(self, self, "_set_jammed"),
		set_powered = callback(self, self, "_set_powered"),
		set_upgradable = callback(self, self, "_set_upgradable"),
	}

	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = id, source = "timer", event = { event }, clbk = clbk, keys = { key }, data_only = true })
	end
end

function HUDList.TimerItem:update(t, dt)
	if not alive(self._unit) then
		self:delete()
		return
	end

	local player = managers.player:player_unit()
	local distance = alive(player) and (mvector3.normalize(player:position() - self._unit:position()) / 100) or 0
	self._distance_text:set_text(string.format("%.0fm", distance))

	if self._jammed or not self._powered then
		local new_color = self:_get_color_from_table(math.sin(t*360 * self.FLASH_SPEED) * 0.5 + 0.5, 1, self._flash_color_table, self.STANDARD_COLOR)
		self:_set_colors(new_color)
	end
end

function HUDList.TimerItem:_update_timer(data)
	self._remaining = data.timer_value or 0
	self._time_text:set_text(format_time_string(self._remaining))
end

function HUDList.TimerItem:_set_jammed(data)
	self._jammed = data.jammed
	self:_check_is_running()
end

function HUDList.TimerItem:_set_powered(data)
	self._powered = data.powered
	self:_check_is_running()
end

function HUDList.TimerItem:_get_color()
	local current_color = self._upgradable and self.UPGRADE_COLOR or self.STANDARD_COLOR
	if self._device_type == "drill" then
		if SydneyHUD._autorepair_map[tostring(self._unit:key())] then
			current_color = self.AUTOREPAIR_COLOR
		end
	end
	return current_color
end

function HUDList.TimerItem:_set_upgradable(data)
	self._upgradable = data.upgradable
	local current_color = self:_get_color()
	self._flash_color_table[2].color = current_color
	self:_set_colors(current_color)
end

function HUDList.TimerItem:_check_is_running()
	if not self._jammed and self._powered then
		self:_set_colors(self._flash_color_table[2].color)
	end
end

function HUDList.TimerItem:_set_colors(color)
	self._time_text:set_color(color)
	self._type_text:set_color(color)
	self._distance_text:set_color(color)
end


HUDList.TemperatureGaugeItem = HUDList.TemperatureGaugeItem or class(HUDList.TimerItem)
function HUDList.TemperatureGaugeItem:init(parent, name, timer_data, params)
	self._start = params.start
	self._goal = params.goal
	self._last_value = self._start

	HUDList.TimerItem.init(self, parent, name, timer_data)

	self._type_text:set_text("Temp")
end

function HUDList.TemperatureGaugeItem:update(t, dt)

end

function HUDList.TemperatureGaugeItem:_update_timer(data)
	local dv = math.abs(self._last_value - data.timer_value)
	local estimate = "n/a"

	if dv > 0 then
		local time_left = math.abs(self._goal - data.timer_value) / dv
		estimate = format_time_string(time_left)
	end

	self._distance_text:set_text(string.format("%d / %d", data.timer_value, self._goal))
	self._time_text:set_text(estimate)
	self._last_value = data.timer_value
end


HUDList.EquipmentItem = HUDList.EquipmentItem or class(HUDList.ItemBase)
HUDList.EquipmentItem.EQUIPMENT_TABLE = {
	sentry =				{ atlas = { 7, 5 }, priority = 1 },
	ammo_bag =			{ atlas = { 1, 0 }, priority = 3 },
	doc_bag =			{ atlas = { 2, 7 }, priority = 4 },
	body_bag =			{ atlas = { 5, 11 }, priority = 5 },
	grenade_crate =	{ preplanning = { 1, 0 }, priority = 2 },
}
function HUDList.EquipmentItem:init(parent, name, data, equipment_type)
	local icon_data = HUDList.EquipmentItem.EQUIPMENT_TABLE[equipment_type]

	HUDList.EquipmentItem.super.init(self, parent, name, { align = "center", w = parent:panel():h() * 4/5, h = parent:panel():h(), priority = icon_data.priority })

	self._unit = data.unit
	self._key = name --normally unit:key(), exception for aggregated items that have no singular unit
	self._equipment_type = equipment_type

	local texture =
	icon_data.atlas and "guis/textures/pd2/skilltree/icons_atlas" or
			icon_data.preplanning and "guis/dlcs/big_bank/textures/pd2/pre_planning/preplan_icon_types"
	local x, y = unpack((icon_data.atlas or icon_data.preplanning) or { 0, 0 })
	local w = icon_data.atlas and 64 or icon_data.preplanning and 48
	local texture_rect = (icon_data.atlas or icon_data.preplanning) and { x * w, y * w, w, w }

	self._box = HUDBGBox_create(self._panel, {
		w = self._panel:w(),
		h = self._panel:h(),
	}, {})

	self._icon = self._panel:bitmap({
		name = "icon",
		texture = texture,
		texture_rect = texture_rect,
		h = self:panel():w() * 0.8,
		w = self:panel():w() * 0.8,
		blend_mode = "add",
		layer = 0,
		color = Color.white,
	})
	self._icon:set_center(self._panel:center())
	self._icon:set_top(self._panel:top())

	self:_set_owner(data)

	local id = string.format("HUDList_equipment_listener_%s", self._key)
	local events = {
		set_owner = callback(self, self, "_set_owner"),
	}

	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = id, source = self._equipment_type, event = { event }, clbk = clbk, keys = { self._key }, data_only = true })
	end

	if not self._defer_activation then
		self:activate()
	end
end

function HUDList.EquipmentItem:_set_owner(data)
	if data.owner then
		self._owner = data.owner
		self:_set_color()
	end
end

function HUDList.EquipmentItem:is_player_owner()
	return self._owner == managers.network:session():local_peer():id()
end

function HUDList.EquipmentItem:get_type()
	return self._equipment_type
end

function HUDList.EquipmentItem:_set_color()
	local color = self._owner and self._owner > 0 and tweak_data.chat_colors[self._owner]:with_alpha(1) or Color.white
	self._icon:set_color(color)
end


HUDList.BagEquipmentItem = HUDList.BagEquipmentItem or class(HUDList.EquipmentItem)
function HUDList.BagEquipmentItem:init(parent, name, data, equipment_type)
	HUDList.BagEquipmentItem.super.init(self, parent, name, data, equipment_type)

	self._info_text = self._panel:text({
		name = "info",
		align = "center",
		vertical = "bottom",
		w = self._panel:w(),
		h = self._panel:h() * 0.4,
		color = Color.white,
		layer = 1,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:h() * 0.4,
	})
	self._info_text:set_bottom(self._panel:h())

	self:_set_max_amount(data)
	self:_set_amount(data)
	self:_set_amount_offset(data)

	local id = string.format("HUDList_equipment_listener_%s", self._key)
	local events = {
		set_max_amount = callback(self, self, "_set_max_amount"),
		set_amount = callback(self, self, "_set_amount"),
		set_amount_offset = callback(self, self, "_set_amount_offset"),
	}

	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = id, source = self._equipment_type, event = { event }, clbk = clbk, keys = { self._key }, data_only = true })
	end
end

function HUDList.BagEquipmentItem:amount()
	return self._amount + (self._amount_offset or 0)
end

function HUDList.BagEquipmentItem:_set_max_amount(data)
	if data.max_amount then
		self._max_amount = data.max_amount
		self:_update_info_text()
	end
end

function HUDList.BagEquipmentItem:_set_amount(data)
	if data.amount then
		self._amount = data.amount
		self:_update_info_text()
	end
end

function HUDList.BagEquipmentItem:_set_amount_offset(data)
	if data.amount_offset then
		self._amount_offset = data.amount_offset
		self:_update_info_text()
	end
end

function HUDList.BagEquipmentItem:_update_info_text()
	if self._amount and self._max_amount then
		local offset = self._amount_offset or 0
		self._info_text:set_text(string.format("%.0f", self._amount + offset))
		self._info_text:set_color(self:_get_color_from_table(self._amount + offset, self._max_amount + offset))
	end
end


HUDList.AmmoBagItem = HUDList.AmmoBagItem or class(HUDList.BagEquipmentItem)
function HUDList.AmmoBagItem:_update_info_text()
	if self._amount and self._max_amount then
		local offset = self._amount_offset or 0
		self._info_text:set_text(string.format("%.0f%%", (self._amount + offset) * 100))
		self._info_text:set_color(self:_get_color_from_table(self._amount + offset, self._max_amount + offset))
	end
end


HUDList.BodyBagItem = HUDList.BodyBagItem or class(HUDList.BagEquipmentItem)
function HUDList.BodyBagItem:init(...)
	self._defer_activation = true

	HUDList.BodyBagItem.super.init(self, ...)

	table.insert(self._listener_clbks, {
		name = string.format("HUDList_equipment_listener_%s", self._key),
		source = "whisper_mode",
		event = { "change" },
		clbk = callback(self, self, "_whisper_mode_change"),
		data_only = true,
	})

	self:set_active(managers.groupai:state():whisper_mode())
end

function HUDList.BodyBagItem:_whisper_mode_change(status)
	self:set_active(self:amount() > 0 and status)
end


HUDList.SentryEquipmentItem = HUDList.SentryEquipmentItem or class(HUDList.EquipmentItem)
function HUDList.SentryEquipmentItem:init(parent, name, data)
	HUDList.SentryEquipmentItem.super.init(self, parent, name, data, "sentry")

	self._bar_bg = self._panel:rect({
		name = "bar_bg",
		x = self._panel:w() * 0.1,
		w = self._panel:w() * 0.8,
		h = self._panel:h() * 0.3,
		color = Color.black,
		alpha = 0.5,
		layer = 0,
	})
	self._bar_bg:set_bottom(self._panel:h() * 0.9)

	self._health_bar = self._panel:rect({
		name = "health_bar",
		x = self._bar_bg:x(),
		y = self._bar_bg:y(),
		h = self._bar_bg:h() * 0.5,
		color = Color(0.7, 0.0, 0.0),
		layer = 1,
	})

	self._ammo_bar = self._panel:rect({
		name = "ammo_bar",
		x = self._bar_bg:x(),
		y = self._bar_bg:y() + self._bar_bg:h() * 0.5,
		h = self._bar_bg:h() * 0.5,
		color = Color(0.0, 0.7, 0.0),
		layer = 1,
	})

	self._kills = self._panel:text({
		name = "kills",
		text = "0",
		align = "left",
		vertical = "top",
		w = self._panel:w(),
		h = self._panel:h(),
		color = Color.white,
		layer = 10,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:h() * 0.5,
	})

	self:_set_ammo_ratio(data)
	self:_set_health_ratio(data)

	local id = string.format("HUDList_equipment_listener_%s", self._key)
	local events = {
		set_ammo_ratio = callback(self, self, "_set_ammo_ratio"),
		set_health_ratio = callback(self, self, "_set_health_ratio"),
		set_kills = callback(self, self, "_set_kills"),
	}

	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = id, source = "sentry", event = { event }, clbk = clbk, keys = { self._key }, data_only = true })
	end
end

function HUDList.SentryEquipmentItem:_set_ammo_ratio(data)
	if data.ammo_ratio then
		self._ammo_ratio = data.ammo_ratio
		self._ammo_bar:set_w(self._bar_bg:w() * self._ammo_ratio)

		if self._ammo_ratio <= 0 then
			self:_set_inactive()
		end
	end
end

function HUDList.SentryEquipmentItem:_set_health_ratio(data)
	if data.health_ratio then
		self._health_ratio = data.health_ratio or 0
		self._health_bar:set_w(self._bar_bg:w() * self._health_ratio)

		if self._health_ratio <= 0 then
			self:_set_inactive()
		end
	end
end

function HUDList.SentryEquipmentItem:_set_kills(data)
	self._kills:set_text(tostring(data.kills))
end

function HUDList.SentryEquipmentItem:_set_inactive()
	if self:is_player_owner() then
		if not self._animating then
			self._icon:animate(callback(self, self, "_animate_inactive"), Color.red)
		end
	else
		self:deactivate()
	end
end

function HUDList.SentryEquipmentItem:_animate_inactive(icon, flash_color)
	self._animating = true
	local base_color = icon:color()
	local t = 0

	while self._animating do
		local s = math.sin(t*720) * 0.5 + 0.5
		local r = math.lerp(base_color.r, flash_color.r, s)
		local g = math.lerp(base_color.g, flash_color.g, s)
		local b = math.lerp(base_color.b, flash_color.b, s)
		icon:set_color(Color(r, g, b))
		t = t + coroutine.yield()
	end

	self:_set_color()
end


HUDList.MinionItem = HUDList.MinionItem or class(HUDList.ItemBase)
function HUDList.MinionItem:init(parent, name, data)
	HUDList.MinionItem.super.init(self, parent, name, { align = "center", w = parent:panel():h() * 4/5, h = parent:panel():h() })

	self._unit = data.unit
	local type_string = HUDListManager.UNIT_TYPES[self._unit:base()._tweak_table] and
			HUDListManager.UNIT_TYPES[self._unit:base()._tweak_table].long_name or "UNDEF"

	self._health_bar = self._panel:bitmap({
		name = "radial_health",
		texture = "guis/textures/pd2/hud_health",
		render_template = "VertexColorTexturedRadial",
		blend_mode = "add",
		layer = 2,
		color = Color(1, 1, 0, 0),
		w = self._panel:w(),
		h = self._panel:w(),
	})
	self._health_bar:set_bottom(self._panel:bottom())

	self._hit_indicator = self._panel:bitmap({
		name = "radial_health",
		texture = "guis/textures/pd2/hud_radial_rim",
		blend_mode = "add",
		layer = 1,
		color = Color.red,
		alpha = 0,
		w = self._panel:w(),
		h = self._panel:w(),
	})
	self._hit_indicator:set_center(self._health_bar:center())

	self._outline = self._panel:bitmap({
		name = "outline",
		texture = "guis/textures/pd2/hud_shield",
		blend_mode = "add",
		w = self._panel:w() * 0.95,
		h = self._panel:w() * 0.95,
		layer = 1,
		alpha = 0,
		color = Color(0.8, 0.8, 1.0),
	})
	self._outline:set_center(self._health_bar:center())

	self._damage_upgrade_text = self._panel:text({
		name = "type",
		text = "W",
		align = "center",
		vertical = "center",
		w = self._panel:w(),
		h = self._panel:w(),
		color = Color.white,
		layer = 3,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:w() * 0.4,
		alpha  = 0.5
	})
	self._damage_upgrade_text:set_bottom(self._panel:bottom())

	self._unit_type = self._panel:text({
		name = "type",
		text = type_string,
		align = "center",
		vertical = "top",
		w = self._panel:w(),
		h = self._panel:w() * 0.3,
		color = Color.white,
		layer = 3,
		font = tweak_data.hud_corner.assault_font,
		font_size = math.min(8 / string.len(type_string), 1) * 0.25 * self._panel:h(),
	})

	self._kills = self._panel:text({
		name = "kills",
		text = "0",
		align = "right",
		vertical = "bottom",
		w = self._panel:w(),
		h = self._panel:w(),
		color = Color.white,
		layer = 10,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:w() * 0.4,
	})
	self._kills:set_center(self._health_bar:center())

	if data.health_ratio then
		self:_set_health_ratio(data, true)
	end
	if data.damage_resistance then
		self:_set_damage_resistance(data)
	end
	if data.damage_multiplier then
		self:_set_damage_multiplier(data)
	end

	local key = tostring(self._unit:key())
	local id = string.format("HUDList_minion_listener_%s", key)
	local events = {
		set_health_ratio = callback(self, self, "_set_health_ratio"),
		set_owner = callback(self, self, "_set_owner"),
		set_kills = callback(self, self, "_set_kills"),
		set_damage_resistance = callback(self, self, "_set_damage_resistance"),
		set_damage_multiplier = callback(self, self, "_set_damage_multiplier"),
	}

	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = id, source = "minion", event = { event }, clbk = clbk, keys = { key }, data_only = true })
	end
end

function HUDList.MinionItem:_set_health_ratio(data, skip_animate)
	self._health_bar:set_color(Color(1, data.health_ratio, 1, 1))
	if not skip_animate then
		self._hit_indicator:stop()
		self._hit_indicator:animate(callback(self, self, "_animate_damage"))
	end
end

function HUDList.MinionItem:_set_owner(data)
	self._unit_type:set_color(data.owner and tweak_data.chat_colors[data.owner]:with_alpha(1) or Color(1, 1, 1, 1))
end

function HUDList.MinionItem:_set_kills(data)
	self._kills:set_text(data.kills)
end

function HUDList.MinionItem:_set_damage_resistance(data)
	local max_mult = tweak_data.upgrades.values.player.convert_enemies_health_multiplier[1] * tweak_data.upgrades.values.player.passive_convert_enemies_health_multiplier[2]
	local alpha = math.clamp(1 - (data.damage_resistance - max_mult) / (1 - max_mult), 0, 1) * 0.8 + 0.2
	self._outline:set_alpha(alpha)
end

function HUDList.MinionItem:_set_damage_multiplier(data)
	self._damage_upgrade_text:set_alpha(data.damage_multiplier > 1 and 1 or 0.5)
end

function HUDList.MinionItem:_animate_damage(icon)
	local duration = 1
	local t = duration
	icon:set_alpha(1)

	while t > 0 do
		local dt = coroutine.yield()
		t = math.clamp(t - dt, 0, duration)
		icon:set_alpha(t/duration)
	end

	icon:set_alpha(0)
end


HUDList.PagerItem = HUDList.PagerItem or class(HUDList.ItemBase)
function HUDList.PagerItem:init(parent, name, data)
	HUDList.PagerItem.super.init(self, parent, name, { align = "left", w = parent:panel():h(), h = parent:panel():h() })

	self._unit = data.unit
	self._start_t = data.start_t
	self._expire_t = data.expire_t
	self._remaining = data.expire_t - Application:time()
	self._duration = data.expire_t - data.start_t

	self._box = HUDBGBox_create(self._panel, {
		w = self._panel:w(),
		h = self._panel:h(),
	}, {})

	self._timer_text = self._box:text({
		name = "time",
		align = "center",
		vertical = "top",
		w = self._box:w(),
		h = self._box:h(),
		color = Color.red,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.5,
	})

	self._distance_text = self._box:text({
		name = "distance",
		align = "center",
		vertical = "bottom",
		w = self._box:w(),
		h = self._box:h(),
		color = Color.white,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.5,
		text = "DIST"
	})

	local key = tostring(self._unit:key())
	table.insert(self._listener_clbks, {
		name = string.format("HUDList_pager_listener_%s", key),
		source = "pager",
		event = { "set_answered" },
		clbk = callback(self, self, "_set_answered"),
		keys = { key },
		data_only = true
	})
end

function HUDList.PagerItem:_set_answered()
	if not self._answered then
		self._answered = true
		self._timer_text:set_color(Color(1, 0.1, 0.9, 0.1))
	end
end

function HUDList.PagerItem:update(t, dt)
	if not self._answered then
		self._remaining = math.max(self._remaining - dt, 0)
		self._timer_text:set_text(format_time_string(self._remaining))
		self._timer_text:set_color(self:_get_color_from_table(self._remaining, self._duration))
	end

	local distance = 0
	if alive(self._unit) and alive(managers.player:player_unit()) then
		distance = mvector3.distance(managers.player:player_unit():position(), self._unit:position()) / 100
	end
	self._distance_text:set_text(string.format("%.0fm", distance))
end


HUDList.ECMItem = HUDList.ECMItem or class(HUDList.ItemBase)
function HUDList.ECMItem:init(parent, name, data)
	HUDList.ECMItem.super.init(self, parent, name, { align = "right", w = parent:panel():h(), h = parent:panel():h() })

	self._unit = data.unit
	self._max_duration = tweak_data.upgrades.ecm_jammer_base_battery_life

	self._box = HUDBGBox_create(self._panel, {
		w = self._panel:w(),
		h = self._panel:h(),
	}, {})

	self._text = self._box:text({
		name = "text",
		align = "center",
		vertical = "center",
		w = self._box:w(),
		h = self._box:h(),
		color = Color.white,
		font = tweak_data.hud_corner.assault_font,
		layer = 10,
		font_size = self._box:h() * 0.6,
	})

	--TODO: Pager block indicator element

	self:_set_jammer_battery(data)
	self:_set_upgrade_level(data)

	local key = tostring(self._unit:key())
	local id = string.format("HUDList_ecm_jammer_listener_%s", key)
	local events = {
		set_upgrade_level = callback(self, self, "_set_upgrade_level"),
		set_jammer_battery = callback(self, self, "_set_jammer_battery"),
	}

	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = id, source = "ecm", event = { event }, clbk = clbk, keys = { key }, data_only = true })
	end
end

function HUDList.ECMItem:_set_upgrade_level(data)
	if data.upgrade_level then
		self._blocks_pager = data.upgrade_level == 3
		self._max_duration = tweak_data.upgrades.ecm_jammer_base_battery_life * ECMJammerBase.battery_life_multiplier[data.upgrade_level]
		--TODO: Update pager block element
	end
end

function HUDList.ECMItem:_set_jammer_battery(data)
	if data.jammer_battery then
		self._text:set_text(format_time_string(data.jammer_battery))
		self._text:set_color(self:_get_color_from_table(data.jammer_battery, self._max_duration))
	end
end


HUDList.ECMRetriggerItem = HUDList.ECMRetriggerItem or class(HUDList.ItemBase)
function HUDList.ECMRetriggerItem:init(parent, name, data)
	HUDList.ECMRetriggerItem.super.init(self, parent, name, { align = "right", w = parent:panel():h(), h = parent:panel():h() })

	self._max_duration = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60

	self._box = HUDBGBox_create(self._panel, {
		w = self._panel:w(),
		h = self._panel:h(),
	}, {})

	self._text = self._box:text({
		name = "text",
		align = "center",
		vertical = "center",
		w = self._box:w(),
		h = self._box:h(),
		color = Color.white,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.6,
	})

	self:_set_retrigger_delay(data)

	local key = tostring(data.unit:key())
	table.insert(self._listener_clbks, {
		name = string.format("HUDList_ecm_retrigger_listener_%s", key),
		source = "ecm",
		event = { "set_retrigger_delay" },
		clbk = callback(self, self, "_set_retrigger_delay"),
		keys = { key },
		data_only = true
	})
end

function HUDList.ECMRetriggerItem:_set_retrigger_delay(data)
	if data.retrigger_delay then
		self._text:set_text(format_time_string(data.retrigger_delay))
		self._text:set_color(self:_get_color_from_table(self._max_duration - data.retrigger_delay, self._max_duration))
	end
end


HUDList.TapeLoopItem = HUDList.TapeLoopItem or class(HUDList.ItemBase)
function HUDList.TapeLoopItem:init(parent, name, data)
	HUDList.TapeLoopItem.super.init(self, parent, name, { align = "right", w = parent:panel():h(), h = parent:panel():h() })

	self._unit = data.unit
	self._expire_t = data.tape_loop_expire_t

	self._box = HUDBGBox_create(self._panel, {
		w = self._panel:w(),
		h = self._panel:h(),
	}, {})

	self._text = self._box:text({
		name = "text",
		align = "center",
		vertical = "center",
		w = self._box:w(),
		h = self._box:h(),
		color = Color.white,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.6,
	})
end

function HUDList.TapeLoopItem:update(t, dt)
	local duration = math.max(0, self._expire_t - t)
	self._text:set_text(format_time_string(duration))
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Buff list
HUDList.BuffItemBase = HUDList.BuffItemBase or class(HUDList.ItemBase)

HUDList.BuffItemBase.ICON_COLOR = {
	STANDARD = Color.white,
	DEBUFF = Color.red,
	TEAM = Color.green,
}

HUDList.BuffItemBase.MAP = {
	--Buffs
	aggressive_reload_aced = {
		atlas_new = tweak_data.skilltree.skills.speedy_reload.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	ammo_efficiency = {
		atlas_new = tweak_data.skilltree.skills.single_shot_ammo_return.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	armor_break_invulnerable = {
		spec = {6, 1},
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	berserker = {
		atlas_new = tweak_data.skilltree.skills.wolverine.icon_xy,
		class = "BerserkerBuffItem",
		priority = 3,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	biker = {
		spec = {0, 0},
		texture_bundle_folder = "wild",
		class = "BikerBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	bloodthirst_aced = {
		atlas_new = tweak_data.skilltree.skills.bloodthirst.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ace_icon = true,
		title = "Aced",
		ignore = false,
	},
	bloodthirst_basic = {
		atlas_new = tweak_data.skilltree.skills.bloodthirst.icon_xy,
		class = "BuffItemBase",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		title = "Basic",
		ignore = true,
	},
	bullet_storm = {
		atlas_new = tweak_data.skilltree.skills.ammo_reservoir.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	sixth_sense = {
		atlas_new = tweak_data.skilltree.skills.chameleon.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	close_contact = {
		spec = {5, 4},
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	combat_medic = {
		atlas_new = tweak_data.skilltree.skills.combat_medic.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	combat_medic_passive = {
		atlas_new = tweak_data.skilltree.skills.combat_medic.icon_xy,
		class = "BuffItemBase",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	desperado = {
		atlas_new = tweak_data.skilltree.skills.expert_handling.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	die_hard = {
		atlas_new = tweak_data.skilltree.skills.show_of_force.icon_xy,
		class = "BuffItemBase",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	dire_need = {
		atlas_new = tweak_data.skilltree.skills.dire_need.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	grinder = {
		spec = {4, 6},
		class = "TimedStacksBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	hostage_situation = {
		spec = {0, 1},
		class = "BuffItemBase",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	hostage_taker = {
		atlas_new = tweak_data.skilltree.skills.black_marketeer.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		invert_timers = true,
		ignore = true,
	},
	melee_stack_damage = {
		spec = {5, 4},
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	chico_injector = {
		spec = {0,0},
		texture_bundle_folder = "chico",
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	inspire = {
		atlas_new = tweak_data.skilltree.skills.inspire.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	maniac = {
		spec = {0, 0},
		texture_bundle_folder = "coco",
		class = "BuffItemBase",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	messiah = {
		atlas_new = tweak_data.skilltree.skills.messiah.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	overdog = {
		spec = {6, 4},
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	overkill = {
		atlas_new = tweak_data.skilltree.skills.overkill.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	painkiller = {
		atlas_new = tweak_data.skilltree.skills.fast_learner.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	partner_in_crime = {
		atlas_new = tweak_data.skilltree.skills.control_freak.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	running_from_death = {
		atlas_new = tweak_data.skilltree.skills.running_from_death.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	quick_fix = {
		atlas_new = tweak_data.skilltree.skills.tea_time.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	second_wind = {
		atlas_new = tweak_data.skilltree.skills.scavenger.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	lock_n_load = {
		atlas_new = tweak_data.skilltree.skills.shock_and_awe.icon_xy,
		class = "ShockAndAweBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	swan_song = {
		atlas_new = tweak_data.skilltree.skills.perseverance.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	tooth_and_claw = {
		spec = {0, 3},
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	trigger_happy = {
		atlas_new = tweak_data.skilltree.skills.trigger_happy.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	underdog = {
		atlas_new = tweak_data.skilltree.skills.underdog.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	unseen_strike = {
		atlas_new = tweak_data.skilltree.skills.unseen_strike.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	up_you_go = {
		atlas_new = tweak_data.skilltree.skills.up_you_go.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},
	uppers = {
		atlas_new = tweak_data.skilltree.skills.tea_cookies.icon_xy,
		class = "TimedBuffItem",
		priority = 4,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = false,
	},
	yakuza = {
		spec = {2, 7},
		class = "BerserkerBuffItem",
		priority = 3,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		ignore = true,
	},

	--Debuffs
	anarchist_armor_recovery_debuff = {
		spec = {0, 1},
		texture_bundle_folder = "opera",
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = false,
	},
	ammo_give_out_debuff = {
		spec = {5, 5},
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = false,
	},
	armor_break_invulnerable_debuff = {
		spec = {6, 1},
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = true,	--Composite debuff
	},
	bullseye_debuff = {
		atlas_new = tweak_data.skilltree.skills.prison_wife.icon_xy,
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = false,
	},
	grinder_debuff = {
		spec = {4, 6},
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = true,	--Composite debuff
	},
	chico_injector_debuff = {
		spec = {0,0},
		texture_bundle_folder = "chico",
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = true,	--Composite debuff
	},
	inspire_debuff = {
		atlas_new = tweak_data.skilltree.skills.inspire.icon_xy,
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		title = "Boost",
		ignore = false,
	},
	inspire_revive_debuff = {
		atlas_new = tweak_data.skilltree.skills.inspire.icon_xy,
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ace_icon = true,
		title = "Revive",
		ignore = false,
	},
	life_drain_debuff = {
		spec = {7, 4},
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = false,
	},
	medical_supplies_debuff = {
		spec = {4, 5},
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = false,
	},
	unseen_strike_debuff = {
		atlas_new = tweak_data.skilltree.skills.unseen_strike.icon_xy,
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = true,	--Composite debuff
	},
	uppers_debuff = {
		atlas_new = tweak_data.skilltree.skills.tea_cookies.icon_xy,
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = true,	--Composite debuff
	},
	sociopath_debuff = {
		spec = {3, 5},
		class = "TimedBuffItem",
		priority = 8,
		color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF,
		ignore = false,
	},

	--Team buffs
	armorer = {
		spec = {6, 0},
		class = "TeamBuffItem",
		priority = 1,
		color = HUDList.BuffItemBase.ICON_COLOR.TEAM,
		ignore = false,
	},
	bulletproof = {
		spec = {6, 2},
		class = "TeamBuffItem",
		priority = 1,
		color = HUDList.BuffItemBase.ICON_COLOR.TEAM,
		ignore = false,
	},
	crew_chief = {
		spec = {2, 0},
		class = "TeamBuffItem",
		priority = 1,
		color = HUDList.BuffItemBase.ICON_COLOR.TEAM,
		ignore = false,
	},
	endurance = {
		atlas = tweak_data.skilltree.skills.triathlete.icon_xy,
		class = "TeamBuffItem",
		priority = 1,
		color = HUDList.BuffItemBase.ICON_COLOR.TEAM,
		ignore = true,
	},
	forced_friendship = {
		atlas = tweak_data.skilltree.skills.triathlete.icon_xy,
		class = "TeamBuffItem",
		priority = 1,
		color = HUDList.BuffItemBase.ICON_COLOR.TEAM,
		ignore = true,
	},

	--Composite buffs
	damage_increase = {
		spec = {7, 0},
		class = "DamageIncreaseBuff",
		priority = 2,
		title = "+Dmg",
		ignore = false,
	},
	damage_reduction = {
		atlas = { 6, 4 },
		class = "DamageReductionBuff",
		priority = 2,
		title = "-Dmg",
		ignore = false,
	},
	melee_damage_increase = {
		atlas = { 4, 10 },
		class = "MeleeDamageIncreaseBuff",
		priority = 2,
		title = "+M.Dmg",
		ignore = false,
	},

	--Player actions
	anarchist_armor_regeneration = {
		spec = {0, 0},
		texture_bundle_folder = "opera",
		class = "TimedBuffItem",
		priority = 9,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		invert_timers = true,
		ignore = false,
	},
	standard_armor_regeneration = {
		spec = {6, 0},
		class = "TimedBuffItem",
		priority = 9,
		color = HUDList.BuffItemBase.ICON_COLOR.STANDARD,
		invert_timers = true,
		ignore = false,
	},
	melee_charge = {
		atlas = { 4, 10 },
		class = "TimedBuffItem",
		priority = 9,
		title = "M.Charge",
		ignore = false,
	},
	reload = {
		atlas_new = tweak_data.skilltree.skills.speedy_reload.icon_xy,
		class = "TimedBuffItem",
		priority = 9,
		title = "Reload",
		ignore = false,
	},
	interact = {
		atlas_new = tweak_data.skilltree.skills.second_chances.icon_xy,
		class = "TimedBuffItem",
		priority = 9,
		title = "Interact",
		ignore = false,
	},
}

function HUDList.BuffItemBase:init(parent, name, icon, w, h)
	HUDList.BuffItemBase.super.init(self, parent, name, { priority = icon.priority, align = "bottom", w = w or parent:panel():h() * 0.6, h = h or parent:panel():h() })

	local texture = icon.texture
	local texture_rect = icon.texture_rect

	if icon.atlas or icon.atlas_new or icon.spec then
		local rect = icon.atlas_new and 80 or 64
		local x, y = unpack(icon.atlas_new or icon.atlas or icon.spec)
		texture_rect = { x * rect, y * rect, rect, rect }

		texture = "guis/"
		if icon.texture_bundle_folder then
			texture = string.format("%sdlcs/%s/", texture, icon.texture_bundle_folder)
		end
		texture = string.format("%stextures/pd2/%s", texture, icon.atlas_new and "skilltree_2/icons_atlas_2" or icon.atlas and "skilltree/icons_atlas" or "specialization/icons_atlas")
	end

	self._default_icon_color = icon.color or Color.white
	local progress_bar_width = self._panel:w() * 0.05
	local icon_size = self._panel:w() - progress_bar_width * 4

	self._icon = self._panel:bitmap({
		name = "icon",
		texture = texture,
		texture_rect = texture_rect,
		valign = "center",
		align = "center",
		h = icon_size,
		w = icon_size,
		blend_mode = icon.blend_mode or "normal",
		color = self._default_icon_color,
		rotation = icon.icon_rotation or 0,
	})
	self._icon:set_center(self:panel():center())

	self._ace_icon = self._panel:bitmap({
		name = "ace_icon",
		texture = "guis/textures/pd2/skilltree_2/ace_symbol",
		valign = "center",
		align = "center",
		h = icon_size * 1.5,
		w = icon_size * 1.5,
		blend_mode = "normal",
		color = self._default_icon_color,
		layer = self._icon:layer() - 1,
		visible = icon.ace_icon and true or false,
	})
	self._ace_icon:set_center(self._icon:center())

	self._bg = self._panel:rect({
		name = "bg",
		h = self._icon:h(),
		w = self._icon:w(),
		blend_mode = "normal",
		layer = self._ace_icon:layer() - 1,
		color = Color.black,
		alpha = 0.2,
	})
	self._bg:set_center(self._icon:center())

	self._title = self._panel:text({
		name = "title",
		text = icon.title or "",
		align = "center",
		vertical = "top",
		w = self._panel:w(),
		h = (self._panel:h() - icon_size) / 2,
		layer = 10,
		color = Color.white,
		font = tweak_data.hud_corner.assault_font,
		font_size = 0.7 * (self._panel:h() - icon_size) / 2,
		blend_mode = "normal",
	})

	self._value = self._panel:text({
		name = "value",
		align = "center",
		vertical = "bottom",
		w = self._panel:w(),
		h = (self._panel:h() - icon_size) / 2,
		layer = 10,
		color = Color.white,
		font = tweak_data.hud_corner.assault_font,
		font_size = 0.7 * (self._panel:h() - icon_size) / 2,
		blend_mode = "normal",
	})
	self._value:set_bottom(self._panel:h())

	self._progress_bar_debuff = PanelFrame:new(self._panel, {
		--invert_progress = icon.invert_timers,
		bar_w = progress_bar_width,
		w = self._panel:w(),
		h = self._panel:w(),
		color = Color.red,
	})
	self._progress_bar_debuff:panel():set_center(self._icon:center())
	self._progress_bar_debuff:panel():set_visible(false)
	self._progress_bar_debuff:set_ratio(1)

	self._progress_bar = PanelFrame:new(self._panel, {
		invert_progress = icon.invert_timers,
		bar_w = progress_bar_width,
		w = self._panel:w() - (progress_bar_width+1),
		h = self._panel:w() - (progress_bar_width+1),
		color = icon.progress_color or self._default_icon_color,
	})
	self._progress_bar:panel():set_center(self._icon:center())
	self._progress_bar:panel():set_visible(false)
	self._progress_bar:set_ratio(1)

	self._progress_bar_inner = PanelFrame:new(self._panel, {
		invert_progress = icon.invert_timers,
		bar_w = progress_bar_width,
		w = self._panel:w() - (progress_bar_width+1) * 2,
		h = self._panel:w() - (progress_bar_width+1) * 2,
		color = icon.progress_color or self._default_icon_color,
	})
	self._progress_bar_inner:panel():set_center(self._icon:center())
	self._progress_bar_inner:panel():set_visible(false)
	self._progress_bar_inner:set_ratio(1)

	self._stack_bg = self._panel:bitmap({
		w = self._icon:w() * 0.4,
		h = self._icon:h() * 0.4,
		blend_mode = "normal",
		texture = "guis/textures/pd2/equip_count",
		texture_rect = { 5, 5, 22, 22 },
		layer = 2,
		alpha = 0.8,
		visible = false
	})
	self._stack_bg:set_right(self._icon:right())
	self._stack_bg:set_bottom(self._icon:bottom())

	self._stack_text = self._panel:text({
		name = "stack_text",
		text = "",
		valign = "center",
		align = "center",
		vertical = "center",
		w = self._stack_bg:w(),
		h = self._stack_bg:h(),
		layer = 3,
		color = Color.black,
		blend_mode = "normal",
		font = tweak_data.hud.small_font,
		font_size = self._stack_bg:h() * 0.85,
		visible = false,
	})
	self._stack_text:set_center(self._stack_bg:center())
end

function HUDList.BuffItemBase:post_init()
	self:set_fade_time(0)
	self:set_move_speed(0)
end

function HUDList.BuffItemBase:activate(id)
	self._buff_active = true
	self:_set_progress(0)
	self:_set_progress_inner(0)
	HUDList.BuffItemBase.super.activate(self)
end

function HUDList.BuffItemBase:deactivate(id)
	self._buff_active = false
	self._expire_t = nil
	self._start_t = nil
	self:_set_progress(0)
	self:_set_progress_inner(0)
	if not self._debuff_active then
		HUDList.BuffItemBase.super.deactivate(self)
	else
		self._icon:set_color(HUDList.BuffItemBase.ICON_COLOR.DEBUFF)
		self._ace_icon:set_color(HUDList.BuffItemBase.ICON_COLOR.DEBUFF)
	end
end

function HUDList.BuffItemBase:activate_debuff(id)
	if not self._debuff_active then
		self._debuff_active = true
		self._icon:set_color(HUDList.BuffItemBase.ICON_COLOR.DEBUFF)
		self._ace_icon:set_color(HUDList.BuffItemBase.ICON_COLOR.DEBUFF)
		HUDList.BuffItemBase.super.activate(self)
	end
end

function HUDList.BuffItemBase:deactivate_debuff(id)
	if self._debuff_active then
		self._debuff_active = false

		if self._debuff_expire_t and not self._has_text then
			self._value:set_text("")
		end

		self._debuff_expire_t = nil
		self._debuff_start_t = nil
		self._progress_bar_debuff:panel():set_visible(false)
		self._icon:set_color(self._default_icon_color)
		self._ace_icon:set_color(self._default_icon_color)
		if not self._buff_active then
			HUDList.BuffItemBase.super.deactivate(self)
		end
	end
end

function HUDList.BuffItemBase:set_duration(id, data)
	self._start_t = data.t
	self._expire_t = data.expire_t
	self._progress_bar:panel():set_visible(true)
end

function HUDList.BuffItemBase:set_duration_debuff(id, data)
	self._debuff_start_t = data.t
	self._debuff_expire_t = data.expire_t

	self._progress_bar_debuff:panel():set_visible(true)

	if self._buff_active and self._expire_t and self._expire_t < self._debuff_expire_t then
		self._icon:set_color(self._default_icon_color)
		self._ace_icon:set_color(self._default_icon_color)
	end
end

function HUDList.BuffItemBase:set_progress(id, data)
	self:_set_progress(data.progress)
end

function HUDList.BuffItemBase:set_stack_count(id, data)
	self:_set_stack_count(data.stack_count)
end

function HUDList.BuffItemBase:set_value(id, data)
	if data.show_value then
		self:_set_text(tostring(data.value))
	end
end

function HUDList.BuffItemBase:_update_debuff(t, dt)
	self:_set_progress_debuff((t - self._debuff_start_t) / (self._debuff_expire_t - self._debuff_start_t))

	if t > self._debuff_expire_t then
		self._debuff_start_t = nil
		self._debuff_expire_t = nil
		self._progress_bar_debuff:panel():set_visible(false)
	end
end

function HUDList.BuffItemBase:_set_progress(r)
	self._progress_bar:set_ratio(1-r)
end

function HUDList.BuffItemBase:_set_progress_inner(r)
	self._progress_bar_inner:set_ratio(1-r)
end

function HUDList.BuffItemBase:_set_progress_debuff(r)
	self._progress_bar_debuff:set_ratio(r)
end

function HUDList.BuffItemBase:_set_stack_count(count)
	self._stack_bg:set_visible(count and true or false)
	self._stack_text:set_visible(count and true or false)
	self._stack_text:set_text(count or 0)
end

function HUDList.BuffItemBase:_set_text(str)
	self._has_text = str and true or false
	self._value:set_text(tostring(str))
end


HUDList.BerserkerBuffItem = HUDList.BerserkerBuffItem or class(HUDList.BuffItemBase)
function HUDList.BerserkerBuffItem:set_value(id, data)
	if data.show_value then
		self:_set_text(string.format("%.0f%%", data.value * 100))
	end
end


HUDList.ShockAndAweBuffItem = HUDList.ShockAndAweBuffItem or class(HUDList.BuffItemBase)
function HUDList.ShockAndAweBuffItem:set_value(id, data)
	if data.show_value then
		self:_set_text(string.format("+%.0f%%", (data.value-1) * 100))
	end
end


HUDList.TimedBuffItem = HUDList.TimedBuffItem or class(HUDList.BuffItemBase)
function HUDList.TimedBuffItem:init(...)
	HUDList.TimedBuffItem.super.init(self, ...)
end

function HUDList.TimedBuffItem:update(t, dt)
	local time_str = {}

	if self._debuff_active and self._debuff_expire_t then
		self:_update_debuff(t, dt)

		if self._debuff_expire_t then
			table.insert(time_str, {
				str = string.format("%.1f", self._debuff_expire_t - t),
				color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF
			})
		end
	end

	if self._buff_active and self._expire_t then
		self:_set_progress((t - self._start_t) / (self._expire_t - self._start_t))

		if t > self._expire_t then
			self._start_t = nil
			self._expire_t = nil
			self._progress_bar:panel():set_visible(false)
		end

		if self._expire_t then
			table.insert(time_str, { str = string.format("%.1f", self._expire_t - t) })
		end
	end

	if not self._has_text and #time_str > 0 then
		local color_ranges = {}
		local str = ""
		local offset = 0

		for i, data in ipairs(time_str) do
			str = str .. data.str
			table.insert(color_ranges, { offset, string.len(str), data.color or HUDList.BuffItemBase.ICON_COLOR.STANDARD })
			if i < #time_str then
				str = str .. " "
			end
			offset = offset + string.len(str)
		end

		self._value:set_text(str)

		for _, data in ipairs(color_ranges) do
			self._value:set_range_color(data[1], data[2], data[3])
		end
	end
end


HUDList.TimedStacksBuffItem = HUDList.TimedStacksBuffItem or class(HUDList.BuffItemBase)
function HUDList.TimedStacksBuffItem:init(...)
	HUDList.TimedStacksBuffItem.super.init(self, ...)
	self._stacks = {}
end

function HUDList.TimedStacksBuffItem:update(t, dt)
	local time_str = {}

	if self._debuff_active and self._debuff_expire_t then
		self:_update_debuff(t, dt)

		if self._debuff_expire_t then
			table.insert(time_str, {
				str = string.format("%.1f", self._debuff_expire_t - t),
				color = HUDList.BuffItemBase.ICON_COLOR.DEBUFF
			})
		end
	end

	if #self._stacks > 0 then
		local stack = self._stacks[#self._stacks]
		self:_set_progress((stack.expire_t - t) / (stack.expire_t - stack.t))
	else
		self:_set_progress(0)
	end

	if #self._stacks > 1 then
		local stack = self._stacks[1]
		self:_set_progress_inner((stack.expire_t - t) / (stack.expire_t - stack.t))
	else
		self:_set_progress_inner(0)
	end

	if not self._has_text and #time_str > 0 then
		local color_ranges = {}
		local str = ""
		local offset = 0

		for i, data in ipairs(time_str) do
			str = str .. data.str
			table.insert(color_ranges, { offset, string.len(str), data.color or HUDList.BuffItemBase.ICON_COLOR.STANDARD })
			if i < #time_str then
				str = str .. " "
			end
			offset = offset + string.len(str)
		end

		self._value:set_text(str)

		for _, data in ipairs(color_ranges) do
			self._value:set_range_color(data[1], data[2], data[3])
		end
	end
end

function HUDList.TimedStacksBuffItem:add_timed_stack(id, data)
	self:_update_stacks(data.stacks)
end

function HUDList.TimedStacksBuffItem:remove_timed_stack(id, data)
	self:_update_stacks(data.stacks)
end

function HUDList.TimedStacksBuffItem:_update_stacks(stacks)
	self._stacks = stacks
	self:_set_stack_count(#self._stacks)
	self._progress_bar:panel():set_visible(#self._stacks > 0)
	self._progress_bar_inner:panel():set_visible(#self._stacks > 1)
end


HUDList.BikerBuffItem = HUDList.BikerBuffItem or class(HUDList.TimedStacksBuffItem)
function HUDList.BikerBuffItem:_set_stack_count(count)
	local charges = tweak_data.upgrades.wild_max_triggers_per_time - count
	if charges <= 0 then
		self:activate_debuff()
	else
		self:deactivate_debuff()
	end

	HUDList.BikerBuffItem.super._set_stack_count(self, charges)
end


HUDList.TeamBuffItem = HUDList.TeamBuffItem or class(HUDList.BuffItemBase)
function HUDList.TeamBuffItem:init(...)
	HUDList.TeamBuffItem.super.init(self, ...)
	self._members = {}
end

function HUDList.TeamBuffItem:set_stack_count(id, data)
	--HUDList.TeamBuffItem.super.set_stack_count(self, data)
	self._members[id] = { level = data.level, count = data.stack_count or 0 }
	self:_recheck_level()
end

function HUDList.TeamBuffItem:_recheck_level()
	local max_level = 0

	for id, data in pairs(self._members) do
		if data.count > 0 then
			max_level = math.max(data.level, max_level)
		end
	end

	self:_set_text(max_level > 0 and tostring(max_level) or "")
end


HUDList.CompositeBuff = HUDList.CompositeBuff or class(HUDList.BuffItemBase)
function HUDList.CompositeBuff:init(...)
	HUDList.CompositeBuff.super.init(self, ...)
	self._member_buffs = {}
	self._progress_bar:panel():set_visible(true)
	self._progress_bar_inner:panel():set_visible(true)
end

function HUDList.CompositeBuff:activate(id)
	HUDList.CompositeBuff.super.activate(self, id)

	if not self._member_buffs[id] then
		self._member_buffs[id] = {}
		--self:_check_buffs()
	end
end

function HUDList.CompositeBuff:deactivate(id)
	if self._member_buffs[id] then
		self._member_buffs[id] = nil
		self:_check_buffs()

		if next(self._member_buffs) == nil then
			HUDList.CompositeBuff.super.deactivate(self, id)
		end
	end
end

function HUDList.CompositeBuff:update(t, dt)
	if self._min_expire_buff then
		self:_set_progress_inner((t - self._member_buffs[self._min_expire_buff].start_t) / (self._member_buffs[self._min_expire_buff].expire_t - self._member_buffs[self._min_expire_buff].start_t))
	end

	if self._max_expire_buff then
		self:_set_progress((t - self._member_buffs[self._max_expire_buff].start_t) / (self._member_buffs[self._max_expire_buff].expire_t - self._member_buffs[self._max_expire_buff].start_t))
	end
end

function HUDList.CompositeBuff:set_duration(id, data)
	if self._member_buffs[id] then
		self._member_buffs[id].start_t = data.t
		self._member_buffs[id].expire_t = data.expire_t
		--self:_check_buffs()
	end
end

function HUDList.CompositeBuff:set_stack_count(id, data)
	if self._member_buffs[id] and self._member_buffs[id].stack_count ~= data.stack_count then
		self._member_buffs[id].stack_count = data.stack_count
		--self:_check_buffs()
	end
end

function HUDList.CompositeBuff:set_value(id, data)
	if self._member_buffs[id] and self._member_buffs[id].value ~= data.value then
		--printf("HUDList.CompositeBuff:set_value(%s, %s)", id, tostring(data.value))
		self._member_buffs[id].value = data.value
		self:_check_buffs()
	end
end

function HUDList.CompositeBuff:_check_buffs()
	local max_expire
	local min_expire

	for id, data in pairs(self._member_buffs) do
		if data.expire_t then
			if not max_expire or data.expire_t > self._member_buffs[max_expire].expire_t then
				max_expire = id
			end
			if not min_expire or data.expire_t < self._member_buffs[min_expire].expire_t then
				min_expire = id
			end
		end
	end

	self._max_expire_buff = max_expire
	self._min_expire_buff = min_expire

	if not self._max_expire_buff then
		self._progress_bar:set_ratio(1)
	end

	if not self._min_expire_buff or self._member_buffs[self._min_expire_buff].expire_t == self._member_buffs[self._max_expire_buff].expire_t then
		self._min_expire_buff = nil
		self._progress_bar_inner:set_ratio(1)
	end

	self:_update_value()
end


HUDList.DamageIncreaseBuff = HUDList.DamageIncreaseBuff or class(HUDList.CompositeBuff)
function HUDList.DamageIncreaseBuff:init(...)
	HUDList.DamageIncreaseBuff.super.init(self, ...)

	self._buff_weapon_requirements = {
		overkill = {
			shotgun = true,
			saw = true,
		},
		berserker = {
			saw = true,
		},
	}

	self._buff_weapon_exclusions = {
		overkill_aced = {
			shotgun = true,
			saw = true,
		},
		berserker_aced = {
			saw = true,
		},
	}

	self._buff_effects = {
		berserker = function(active_buffs)
			return 1 + (active_buffs.berserker.value or 0) * managers.player:upgrade_value("player", "melee_damage_health_ratio_multiplier", 0)
		end,
		berserker_aced = function(active_buffs)
			return 1 + (active_buffs.berserker_aced.value or 0) * managers.player:upgrade_value("player", "damage_health_ratio_multiplier", 0)
		end,
	}
end

function HUDList.DamageIncreaseBuff:update(t, dt)
	HUDList.DamageIncreaseBuff.super.update(self, t, dt)

	if not alive(self._player_unit) and alive(managers.player:player_unit()) then
		self._player_unit = managers.player:player_unit()
		self._player_unit:inventory():add_listener("DamageIncreaseBuff", { "equip" }, callback(self, self, "_on_weapon_equipped"))
		self:_on_weapon_equipped(self._player_unit)
	end
end

function HUDList.DamageIncreaseBuff:_on_weapon_equipped(unit)
	self._weapon_unit = unit:inventory():equipped_unit()
	self._weapon_id = self._weapon_unit:base():get_name_id()
	self._weapon_tweak = self._weapon_unit:base():weapon_tweak_data()

	self:_update_value()
end

function HUDList.DamageIncreaseBuff:_update_value()
	local text = ""

	if alive(self._weapon_unit) then
		if self._weapon_tweak.ignore_damage_upgrades then
			text = "(0%)"
		else
			local weapon_category = self._weapon_tweak.category
			local value = 1

			for id, data in pairs(self._member_buffs) do
				if not self._buff_weapon_requirements[id] or self._buff_weapon_requirements[id][weapon_category] then
					if not (self._buff_weapon_exclusions[id] and self._buff_weapon_exclusions[id][weapon_category]) then
						local clbk = self._buff_effects[id]
						value = value * (clbk and clbk(self._member_buffs) or (data.value or 1))
					end
				end
			end

			text = string.format("+%.0f%%", (value-1)*100)
		end
	end

	self:_set_text(text)
end

HUDList.MeleeDamageIncreaseBuff = HUDList.MeleeDamageIncreaseBuff or class(HUDList.CompositeBuff)
function HUDList.MeleeDamageIncreaseBuff:init(...)
	HUDList.MeleeDamageIncreaseBuff.super.init(self, ...)

	self._buff_effects = {
		berserker = function(value)
			return 1 + (value or 0) * managers.player:upgrade_value("player", "melee_damage_health_ratio_multiplier", 0)
		end,
	}
end

function HUDList.MeleeDamageIncreaseBuff:_update_value()
	local value = 1

	for id, data in pairs(self._member_buffs) do
		local clbk = self._buff_effects[id]
		value = value * (clbk and clbk(data.value) or (data.value or 1))
	end

	self:_set_text(string.format("+%.0f%%", (value-1)*100))
end

HUDList.DamageReductionBuff = HUDList.DamageReductionBuff or class(HUDList.CompositeBuff)
function HUDList.DamageReductionBuff:init(...)
	HUDList.DamageReductionBuff.super.init(self, ...)
	self._buff_effects = {}
end

function HUDList.DamageReductionBuff:_update_value()
	local value = 1

	for id, data in pairs(self._member_buffs) do
		local clbk = self._buff_effects[id]
		value = value * (clbk and clbk(self._member_buffs) or (data.value or 1))
	end

	self:_set_text(string.format("-%.0f%%", (1-value)*100))
end


PanelFrame = PanelFrame or class()

function PanelFrame:init(parent, settings)
	settings = settings or {}

	local h = settings.h or parent:h()
	local w = settings.w or parent:w()
	local total = 2*w + 2*h

	self._panel = parent:panel({
		w = w,
		h = h,
		alpha = settings.alpha or 1,
	})

	self._invert_progress = settings.invert_progress
	self._stages = { 0, w/total, (w+h)/total, (2*w+h)/total, 1 }
	self._top = self._panel:rect({})
	self._bottom = self._panel:rect({})
	self._left = self._panel:rect({})
	self._right = self._panel:rect({})

	self:set_width(settings.bar_w or 2)
	self:set_color(settings.color or Color.white)
	self:reset()
end

function PanelFrame:panel()
	return self._panel
end

function PanelFrame:set_width(w)
	self._top:set_h(w)
	self._top:set_top(0)
	self._bottom:set_h(w)
	self._bottom:set_bottom(self._panel:h())
	self._left:set_w(w)
	self._left:set_left(0)
	self._right:set_w(w)
	self._right:set_right(self._panel:w())
end

function PanelFrame:set_color(c)
	self._top:set_color(c)
	self._bottom:set_color(c)
	self._left:set_color(c)
	self._right:set_color(c)
end

function PanelFrame:reset()
	self._current_stage = 1
	self._top:set_w(self._panel:w())
	self._right:set_h(self._panel:h())
	self._right:set_bottom(self._panel:h())
	self._bottom:set_w(self._panel:w())
	self._bottom:set_right(self._panel:w())
	self._left:set_h(self._panel:h())
end

function PanelFrame:set_ratio(r)
	r = math.clamp(r, 0, 1)
	if self._invert_progress then
		r = 1-r
	end

	if r < self._stages[self._current_stage] then
		self:reset()
	end

	while r > self._stages[self._current_stage + 1] do
		if self._current_stage == 1 then
			self._top:set_w(0)
		elseif self._current_stage == 2 then
			self._right:set_h(0)
		elseif self._current_stage == 3 then
			self._bottom:set_w(0)
		elseif self._current_stage == 4 then
			self._left:set_h(0)
		end
		self._current_stage = self._current_stage + 1
	end

	local low = self._stages[self._current_stage]
	local high = self._stages[self._current_stage + 1]
	local stage_progress = (r - low) / (high - low)

	if self._current_stage == 1 then
		self._top:set_w(self._panel:w() * (1-stage_progress))
		self._top:set_right(self._panel:w())
	elseif self._current_stage == 2 then
		self._right:set_h(self._panel:h() * (1-stage_progress))
		self._right:set_bottom(self._panel:h())
	elseif self._current_stage == 3 then
		self._bottom:set_w(self._panel:w() * (1-stage_progress))
	elseif self._current_stage == 4 then
		self._left:set_h(self._panel:h() * (1-stage_progress))
	end
end

--[[
if false then
	HUDList.BuffItemBase.BUFF_MAP = {
		bow_charge = {
			priority = 3,
			type = "buff",
			class = "ChargedBuffItem",
			texture = "guis/dlcs/west/textures/pd2/blackmarket/icons/weapons/plainsrider",
			icon_rotation = 90,
			icon_w_ratio = 0.5,
			icon_scale = 2,
			flash_speed = 0.2,
			no_fade = true
		},
	}

	function HUDList.BuffItemBase:init(parent, name, icon, w, h)
		HUDList.BuffItemBase.super.init(self, parent, name, { priority = icon.priority, align = "bottom", w = w or parent:panel():h(), h = h or parent:panel():h() })

		local x, y = unpack(icon.atlas or icon.spec or { 0, 0 })
		local texture = icon.atlas and "guis/textures/pd2/skilltree/icons_atlas" or icon.spec and "guis/textures/pd2/specialization/icons_atlas" or icon.texture
		local texture_rect = (icon.atlas or icon.spec) and { x * 64, y * 64, 64, 64 } or icon.rect

		self._icon = self._panel:bitmap({
			name = "icon",
			texture = texture,
			texture_rect = texture_rect,
			valign = "center",
			align = "center",
			h = self:panel():w() * 0.7 * (icon.icon_scale or 1) * (icon.icon_h_ratio or 1),
			w = self:panel():w() * 0.7 * (icon.icon_scale or 1) * (icon.icon_w_ratio or 1),
			blend_mode = "normal",
			layer = 0,
			color = icon.icon_color or HUDList.BuffItemBase.ICON_COLORS[icon.type].icon or Color.white,
			rotation = icon.icon_rotation or 0,
		})
		self._icon:set_center(self:panel():center())

		self._flash_icon = self._panel:bitmap({
			name = "flash_icon",
			texture = texture,
			texture_rect = texture_rect,
			valign = "center",
			align = "center",
			layer = 0,
			h = self._icon:h(),
			w = self._icon:w(),
			blend_mode = "normal",
			color = icon.flash_color or HUDList.BuffItemBase.ICON_COLORS[icon.type].flash or Color.blue,
			alpha = 0,
			rotation = icon.icon_rotation or 0,
		})
		self._flash_icon:set_center(self._icon:center())

		self._bg = self._panel:bitmap({
			name = "bg",
			texture = "guis/textures/pd2/skilltree/ace",
			texture_rect = { 37, 28, 54, 70 },
			valign = "center",
			align = "center",
			layer = 0,
			h = self._icon:h(),
			w = 0.8 * self._icon:w(),
			blend_mode = "normal",
			layer = -1,
			color = icon.bg_color or HUDList.BuffItemBase.ICON_COLORS[icon.type].bg or Color.white,
		})
		self._bg:set_center(self._icon:center())

		self._ace_icon = self._panel:bitmap({
			name = "ace_icon",
			texture = "guis/textures/pd2/infamous_symbol",
			texture_rect = { 2, 5, 12, 16 },
			w = 1.15 * 12 * self:panel():w()/45,
			h = 1.15 * 16 * self:panel():w()/45,
			blend_mode = "normal",
			valign = "center",
			align = "center",
			layer = 2,
			color = icon.aced_icon_color or HUDList.BuffItemBase.ICON_COLORS[icon.type].aced_icon or Color.white,
			visible = false,
		})

		self._level_bg = self._panel:bitmap({
			texture = "guis/textures/pd2/infamous_symbol",
			texture_rect = { 2, 5, 12, 16 },
			w = 1.15 * 12 * self:panel():w()/45,
			h = 1.15 * 16 * self:panel():w()/45,
			blend_mode = "normal",
			valign = "center",
			align = "center",
			layer = 2,
			color = icon.level_icon_color or HUDList.BuffItemBase.ICON_COLORS[icon.type].level_icon or Color.white,
			visible = false,
		})
		self._level_text = self._panel:text({
			name = "level_text",
			text = "",
			valign = "center",
			align = "center",
			vertical = "center",
			w = self._level_bg:w(),
			h = self._level_bg:h(),
			layer = 3,
			color = Color.black,
			blend_mode = "normal",
			font = tweak_data.hud.small_font,
			font_size = self._level_bg:h() * 0.75,
			visible = false,
		})
		self._level_text:set_top(self._level_bg:top())
		self._level_text:set_left(self._level_bg:left())



		self._flash_speed = icon.flash_speed
	end

	function HUDList.BuffItemBase:deactivate(...)
		HUDList.BuffItemBase.super.deactivate(self, ...)
		self:set_aced(false, true)
		self:set_level(0, true)
	end

	function HUDList.BuffItemBase:set_aced(status, override)
		if override then
			self._is_aced = status
		else
			self._is_aced = self._is_aced or status
		end
		self._ace_icon:set_visible(self._is_aced)
	end

	function HUDList.BuffItemBase:set_level(new_level, override)
		self._current_level = override and new_level or math.max(self._current_level or 0, new_level)
		self._level_text:set_text(tostring(self._current_level))
		self._level_bg:set_visible(self._current_level > 1)
		self._level_text:set_visible(self._current_level > 1)
	end

	function HUDList.BuffItemBase:set_stack_count(new_count, show_zero)
		if not show_zero and new_count <= 0 then
			self._stack_text:set_visible(false)
			self._stack_bg:set_visible(false)
			self._stack_text:set_text("")
		else
			self._stack_text:set_visible(true)
			self._stack_bg:set_visible(true)
			self._stack_text:set_text(tostring(new_count))
		end
	end

	function HUDList.BuffItemBase:set_flash(continuous)
		self:stop_flash()
		self._flash_icon:animate(callback(self, self, "_animate_flash"), self._flash_speed or 0.5, continuous)
	end

	function HUDList.BuffItemBase:stop_flash()
		self._flash_icon:stop()
		self._flash_icon:set_alpha(0)
		self._icon:set_alpha(1)
	end

	function HUDList.BuffItemBase:_animate_flash(icon, duration, continuous)
		repeat
			local t = duration
			while t > 0 do
				local dt = coroutine.yield()
				t = math.max(t - dt, 0)
				local value = math.sin(t/duration * 180)
				self._flash_icon:set_alpha(value)
				self._icon:set_alpha(1-value)
			end
		until not continuous

		self._flash_icon:set_alpha(0)
		self._icon:set_alpha(1)
	end


	HUDList.ChargedBuffItem = HUDList.ChargedBuffItem or class(HUDList.TimedBuffItem)
	function HUDList.ChargedBuffItem:init(...)
		HUDList.ChargedBuffItem.super.init(self, ...)
		self._bg:set_visible(false)
	end

	function HUDList.ChargedBuffItem:set_progress(ratio)
		HUDList.ChargedBuffItem.super.set_progress(self, ratio)
		if ratio >= 1 and not self._flashing then
			self._flashing = true
			self:set_flash(true)
		elseif ratio == 0 and self._flashing then
			self._flashing = nil
			self:stop_flash()
		end
	end

end
--]]
function HUDManager:set_teammate_custom_radial(i, data)
	if SydneyHUD:GetOption("swansong_effect") then
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
		if not hud.panel:child("swan_song_left") then
			local swan_song_left = hud.panel:bitmap({
				name = "swan_song_left",
				visible = false,
				texture = "guis/textures/alphawipe_test",
				layer = 0,
				color = Color(0, 0.7, 1),
				blend_mode = "add",
				w = hud.panel:w(),
				h = hud.panel:h(),
				x = 0,
				y = 0
			})
		end
		local swan_song_left = hud.panel:child("swan_song_left")
		if i == 4 and data.current < data.total and data.current > 0 and swan_song_left then
			swan_song_left:set_visible(true)
			local hudinfo = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
			swan_song_left:animate(hudinfo.flash_icon, 4000000000)
		elseif hud.panel:child("swan_song_left") then
			swan_song_left:stop()
			swan_song_left:set_visible(false)
		end
		if swan_song_left and data.current == 0 then
			swan_song_left:set_visible(false)
		end
	end
	return custom_radial_original(self, i, data)
end
