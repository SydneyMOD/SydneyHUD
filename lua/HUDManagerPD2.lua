
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

function HUDManager:_setup_player_info_hud_pd2(...)
	_setup_player_info_hud_pd2_original(self, ...)

	managers.hudlist = HUDListManager:new()
end

function HUDManager:update(t, dt, ...)
	if managers.hudlist then
		managers.hudlist:update(t, dt)
	end
	-- log(math.floor(1/dt) .. " FPS")
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
	right_list_height_offset = SydneyHUD:GetOption("center_assault_banner") and 0 or 50,   --Margin from top for the right list
	right_list_scale = 1,   --Size scale of right list
	left_list_height_offset = 80,   --Margin from top for the left list
	left_list_scale = 1,    --Size scale of left list
	buff_list_height_offset = 80,   --Margin from bottom for the buff list
	buff_list_scale = 1,    --Size scale of buff list

	--Left side list
	show_timers = SydneyHUD:GetOption("show_timers"),     --Drills, time locks, hacking etc.
	show_equipment = SydneyHUD:GetOption("show_equipment"),  --Deployables (ammo, doc bags, body bags)
	show_sentries = SydneyHUD:GetOption("show_sentries"),   --Deployable sentries
	hide_empty_sentries = SydneyHUD:GetOption("hide_empty_sentries"),     --Hide sentries with no ammo if player lacks the skill to refill them
	show_ecms = SydneyHUD:GetOption("show_ecms"),       --Active ECMs
	show_ecm_retrigger = SydneyHUD:GetOption("show_ecm_retrigger"),      --Countdown for players own ECM feedback retrigger delay
	show_minions = SydneyHUD:GetOption("show_minions"),    --Converted enemies, type and health
	show_pagers = SydneyHUD:GetOption("show_pagers"),     --Show currently active pagers
	show_tape_loop = SydneyHUD:GetOption("show_tape_loop"),  --Show active tape loop duration
	remove_answered_pager_contour = SydneyHUD:GetOption("remove_answered_pager_contour"),   --Removes the interaction contour on answered pagers

	--Right side list
	show_enemies = SydneyHUD:GetOption("show_enemies"),            --Currently spawned enemies
	aggregate_enemies = SydneyHUD:GetOption("aggregate_enemies"),      --Don't split enemies on type; use a single entry for all
	show_turrets = SydneyHUD:GetOption("show_turrets"),    --Show active SWAT turrets
	show_civilians = SydneyHUD:GetOption("show_civilians"),  --Currently spawned, untied civs
	show_hostages = SydneyHUD:GetOption("show_hostages"),   --Currently tied civilian and dominated cops
	show_minion_count = SydneyHUD:GetOption("show_minion_count"),       --Current number of jokered enemies
	show_pager_count = SydneyHUD:GetOption("show_pager_count"),        --Show number of triggered pagers (only counts pagers triggered while you were present)
	show_loot = SydneyHUD:GetOption("show_loot"),       --Show spawned and active loot bags/piles (may not be shown if certain mission parameters has not been met)
	aggregate_loot = SydneyHUD:GetOption("aggregate_loot"), --Don't split loot on type; use a single entry for all
	separate_bagged_loot = SydneyHUD:GetOption("separate_bagged_loot"),     --Show bagged loot as a separate value
	show_special_pickups = SydneyHUD:GetOption("show_special_pickups"),    --Show number of special equipment/items
	show_gage_packages = SydneyHUD:GetOption("show_gage_packages"),    --Show number of gage packages

	--Buff list
	show_buffs = SydneyHUD:GetOption("show_buffs")       --Active effects (buffs/debuffs). Also see HUDList.BuffItemBase.IGNORED_BUFFS table to ignore specific buffs that you don't want listed, or enable some of those not shown by default
}

function HUDListManager:init()
	self._lists = {}

	self:_setup_left_list()
	self:_setup_right_list()
	self:_setup_buff_list()

	self:_set_remove_answered_pager_contour()

	GroupAIStateBase.register_listener_clbk("HUDList_whisper_mode_change", "on_whisper_mode_change", callback(self, self, "_whisper_mode_change"))
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
		{ atlas = true, h = 2/3, w = 2/3, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.ammo_bag.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.ammo_bag.atlas[2] * 64, 64, 64 }, valign = "top", halign = "right" },
		{ atlas = true, h = 2/3, w = 2/3, texture_rect = { HUDList.EquipmentItem.EQUIPMENT_TABLE.doc_bag.atlas[1] * 64, HUDList.EquipmentItem.EQUIPMENT_TABLE.doc_bag.atlas[2] * 64, 64, 64 }, valign = "bottom", halign = "left" },
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
	self:_set_show_equipment()
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

	list:register_item("unit_count_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 1 })
	list:register_item("hostage_count_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 4 })
	list:register_item("loot_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 2 })
	list:register_item("special_pickup_list", HUDList.HorizontalList, { align = "top", w = list_width, h = 50 * scale, right_to_left = true, item_margin = 3, priority = 4 })

	self:_set_show_enemies()
	self:_set_show_turrets()
	self:_set_show_civilians()
	self:_set_show_hostages()
	self:_set_show_minion_count()
	self:_set_show_pager_count()
	self:_set_show_loot()
	self:_set_show_special_pickups()
end

function HUDListManager:_setup_buff_list()
	local hud_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel
	local scale = HUDListManager.ListOptions.buff_list_scale or 1
	local list_height = 45 * scale
	local list_width = hud_panel:w()
	local x = 0
	local y = hud_panel:bottom() - ((HUDListManager.ListOptions.buff_list_height_offset or 80) + list_height)

	self:register_list("buff_list", HUDList.HorizontalList, {
		align = "center",
		x = x,
		y = y,
		w = list_width,
		h = list_height,
		centered = true,
		item_margin = 0,
		item_move_speed = 300,
		fade_time = 0.15,
	})

	self:_set_show_buffs()
end

function HUDListManager:_pager_event(event, unit)
	local pager_list = self:list("left_side_list"):item("pagers")

	if event == "add" then
		pager_list:register_item(tostring(unit:key()), HUDList.PagerItem, unit):activate()
	elseif event == "remove" then
		pager_list:unregister_item(tostring(unit:key()))
	elseif event == "answer" then
		pager_list:item(tostring(unit:key())):set_answered()
	elseif event == "remove_contour" then
		managers.enemy:add_delayed_clbk("contour_remove_" .. tostring(unit:key()), callback(self, self, "_remove_pager_contour_clbk", unit), Application:time() + 0.01)
	end
end

function HUDListManager:_remove_pager_contour_clbk(unit)
	if alive(unit) then
		unit:contour():remove(tweak_data.interaction.corpse_alarm_pager.contour_preset)
	end
end

function HUDListManager:_minion_event(event, unit, arg1)
	local minion_list = self:list("left_side_list"):item("minions")

	if event == "add" then
		local item = minion_list:register_item(tostring(unit:key()), HUDList.MinionItem, unit)
		item:activate()
	elseif event == "remove" then
		--local killed = arg1
		minion_list:unregister_item(tostring(unit:key()))
	elseif event == "set_owner" then
		minion_list:item(tostring(unit:key())):set_owner(arg1)
	elseif event == "set_health_mult" then
		minion_list:item(tostring(unit:key())):set_health_multiplier(arg1)
	elseif event == "set_damage_mult" then
		minion_list:item(tostring(unit:key())):set_damage_multiplier(arg1)
	elseif event == "change_health" then
		minion_list:item(tostring(unit:key())):set_health(arg1)
	end
end

function HUDListManager:_ecm_event(event, unit, arg1, arg2)
	local ecm_list = self:list("left_side_list"):item("ecms")

	if event == "add" then
		ecm_list:register_item(tostring(unit:key()), HUDList.ECMItem)
	elseif event == "remove" then
		ecm_list:unregister_item(tostring(unit:key()))
	elseif event == "update_battery" then
		ecm_list:item(tostring(unit:key())):update_timer(arg1, arg2)
	elseif event == "jammer_status_change" then
		ecm_list:item(tostring(unit:key())):set_active(arg1)
	end
end

function HUDListManager:_ecm_retrigger_event(event, unit, arg1, arg2)
	local list = self:list("left_side_list"):item("ecm_retrigger")

	if event == "set_active" then
		if arg1 then
			list:register_item(tostring(unit:key()), HUDList.ECMRetriggerItem):activate()
		else
			list:unregister_item(tostring(unit:key()))
		end
	elseif event == "update" then
		list:item(tostring(unit:key())):update_timer(arg1, arg2)
	end
end

function HUDListManager:_bag_equipment_event(event, unit, arg1)
	local equipment_list = self:list("left_side_list"):item("equipment")
	--local key = type(unit) == "string" and ("aggregated_" .. unit) or tostring(unit:key())
	local key = unit and tostring(unit:key()) or "aggregated"

	if event == "add" then
		equipment_list:register_item(key, HUDList.BagEquipmentItem, arg1, unit)
	elseif event == "remove" then
		equipment_list:unregister_item(key)
	else
		local item = equipment_list:item(key)

		if item then
			if event == "update_owner" then
				item:set_owner(arg1)
			elseif event == "update_max" then
				item:set_max_amount(arg1 or 0)
			elseif event == "update_amount" then
				item:set_amount(arg1 or 0)
			elseif event == "update_amount_offset" then
				item:set_amount_offset(arg1 or 0)
			elseif event == "set_active" then
				if item:get_type() == "body_bag" and not managers.groupai:state():whisper_mode() then
					arg1 = false
				end
				item:set_active(arg1)
			end
		end
	end
end

function HUDListManager:_sentry_equipment_event(event, unit, arg1)
	local equipment_list = self:list("left_side_list"):item("equipment")
	local key = unit:key()

	if event == "add" then
		equipment_list:register_item(key, HUDList.SentryEquipmentItem, unit)
	elseif event == "remove" then
		equipment_list:unregister_item(key)
	else
		local item = equipment_list:item(key)

		if item then
			if event == "update_owner" then
				item:set_owner(arg1)
			elseif event == "update_ammo" then
				item:set_ammo_ratio(arg1 or 0)
				if HUDListManager.ListOptions.hide_empty_sentries then
					if not managers.player:has_category_upgrade("sentry_gun", "can_reload") then
						item:set_active((arg1 or 0) > 0)
					end
				end
			elseif event == "update_health" then
				item:set_health_ratio(arg1 or 0)
			elseif event == "set_active" then
				item:set_active(arg1)
			end
		end
	end
end

function HUDListManager:_timer_event(event, unit, arg1, arg2)
	local timer_list = self:list("left_side_list"):item("timers")

	if event == "add" then
		timer_list:register_item(tostring(unit:key()), arg1 or HUDList.TimerItem, unit, arg2)
	elseif event == "remove" then
		timer_list:unregister_item(tostring(unit:key()))
	elseif event == "set_active" then
		timer_list:item(tostring(unit:key())):set_active(arg1)
	elseif event == "set_jammed" then
		timer_list:item(tostring(unit:key())):set_jammed(arg1)
	elseif event == "timer_update" then
		timer_list:item(tostring(unit:key())):update_timer(arg1, arg2)

	--Drill/hack/saw stuff
	elseif event == "upgrade_update" then
		timer_list:item(tostring(unit:key())):set_can_upgrade(arg1)
	elseif event == "set_powered" then
		timer_list:item(tostring(unit:key())):set_powered(arg1)
	elseif event == "type_update" then
		timer_list:item(tostring(unit:key())):set_type(arg1)
	end
end

function HUDListManager:_tape_loop_event(event, unit, duration)
	local tape_loop_list = self:list("left_side_list"):item("tape_loop")

	if event == "start" then
		local item = tape_loop_list:register_item(tostring(unit:key()), HUDList.TapeLoopItem, unit)
		item:set_duration(duration)
		item:activate()
	elseif event == "stop" then
		tape_loop_list:unregister_item(tostring(unit:key()))
	end
end

function HUDListManager:_whisper_mode_change(status)
	for _, item in pairs(self:list("left_side_list"):item("equipment"):items()) do
		if item:get_type() == "body_bag" then
			item:set_active(item:current_amount() > 0 and status)
		end
	end
end

--Left list config
function HUDListManager:_set_show_timers()
	local list = self:list("left_side_list"):item("timers")

	local timer_listener_name = "HUDListManager_timer_items_listener"
	local timer_listeners = {
		on_create = callback(self, self, "_timer_event", "add"),
		on_destroy = callback(self, self, "_timer_event", "remove"),
		on_set_active = callback(self, self, "_timer_event", "set_active"),
		on_set_jammed = callback(self, self, "_timer_event", "set_jammed"),
		on_timer_update = callback(self, self, "_timer_event", "timer_update"),
	}
	local drill_listener_name = "HUDListManager_drill_items_listener"
	local drill_listeners = {
		on_create = callback(self, self, "_timer_event", "add"),
		on_destroy = callback(self, self, "_timer_event", "remove"),
		on_set_active = callback(self, self, "_timer_event", "set_active"),
		on_set_jammed = callback(self, self, "_timer_event", "set_jammed"),
		on_update = callback(self, self, "_timer_event", "timer_update"),
		on_can_upgrade = callback(self, self, "_timer_event", "upgrade_update"),
		on_set_powered = callback(self, self, "_timer_event", "set_powered"),
		on_type_set = callback(self, self, "_timer_event", "type_update"),
	}

	if HUDListManager.ListOptions.show_timers then
		local timer_types = { DigitalGui, TimerGui }

		for _, class in pairs(timer_types) do
			for key, data in pairs(class.SPAWNED_ITEMS) do
				if not data.ignore then
					local item = list:register_item(tostring(key), data.class or HUDList.TimerItem, data.unit, data.params)
					item:set_can_upgrade(data.can_upgrade)
					item:set_active(data.active)
					item:set_jammed(data.jammed)
					item:set_powered(data.powered)
					if data.t and data.time_left then
						item:update_timer(data.t, data.time_left)
					end
					if data.type then
						item:set_type(data.type)
					end
				end
			end
		end

		for event, clbk in pairs(timer_listeners) do
			DigitalGui.register_listener_clbk(timer_listener_name, event, clbk)
		end
		for event, clbk in pairs(drill_listeners) do
			TimerGui.register_listener_clbk(drill_listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(timer_listeners) do
			DigitalGui.unregister_listener_clbk(timer_listener_name, event)
		end
		for event, _ in pairs(drill_listeners) do
			TimerGui.unregister_listener_clbk(drill_listener_name, event)
		end
	end
end

function HUDListManager:_set_show_equipment()
	local list = self:list("left_side_list"):item("equipment")

	local listener_name = "HUDListManager_bag_items_listener"
	local listeners = {
		on_bag_create = callback(self, self, "_bag_equipment_event", "add"),
		on_bag_destroy = callback(self, self, "_bag_equipment_event", "remove"),
		on_bag_owner_update = callback(self, self, "_bag_equipment_event", "update_owner"),
		on_bag_max_amount_update = callback(self, self, "_bag_equipment_event", "update_max"),
		on_bag_amount_update = callback(self, self, "_bag_equipment_event", "update_amount"),
		on_bag_amount_offset_update = callback(self, self, "_bag_equipment_event", "update_amount_offset"),
		on_bag_set_active = callback(self, self, "_bag_equipment_event", "set_active"),
	}

	if HUDListManager.ListOptions.show_equipment then
		local equipment_types = {
			doc_bag = DoctorBagBase,
			ammo_bag = AmmoBagBase,
			body_bag = BodyBagsBagBase,
			grenade_crate = GrenadeCrateBase,
		}

		for type, class in pairs(equipment_types) do
			for _, data in pairs(class.SPAWNED_BAGS) do
				local unit = data.unit
				self:_bag_equipment_event("add", unit, type)
				self:_bag_equipment_event("update_owner", unit, data.owner)
				self:_bag_equipment_event("update_max", unit, data.max_amount)
				self:_bag_equipment_event("update_amount", unit, data.amount)
				self:_bag_equipment_event("update_amount_offset", unit, data.amount_offset)
				self:_bag_equipment_event("set_active", unit, data.active)
			end

			if class.AGGREGATED_BAGS then
				self:_bag_equipment_event("add", nil, type)
				self:_bag_equipment_event("update_max", nil, class.total_aggregated_max_amount())
				self:_bag_equipment_event("update_amount", nil, class.total_aggregated_amount())
				self:_bag_equipment_event("set_active", nil, class.AGGREAGATED_ITEM_ACTIVE)
			end
		end

		for event, clbk in pairs(listeners) do
			UnitBase.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			UnitBase.unregister_listener_clbk(listener_name, event)
		end
	end
end

function HUDListManager:_set_show_sentries()

	local list = self:list("left_side_list"):item("equipment")

	local listener_name = "HUDListManager_sentry_items_listener"
	local listeners = {
		on_sentry_create = callback(self, self, "_sentry_equipment_event", "add"),
		on_sentry_destroy = callback(self, self, "_sentry_equipment_event", "remove"),
		on_sentry_owner_update = callback(self, self, "_sentry_equipment_event", "update_owner"),
		on_sentry_ammo_update = callback(self, self, "_sentry_equipment_event", "update_ammo"),
		on_sentry_health_update = callback(self, self, "_sentry_equipment_event", "update_health"),
		on_sentry_set_active = callback(self, self, "_sentry_equipment_event", "set_active"),
	}

	if HUDListManager.ListOptions.show_sentries then
			for _, data in pairs(SentryGunBase.SPAWNED_SENTRIES) do
				local unit = data.unit
				self:_sentry_equipment_event("add", unit, "sentry")
				self:_sentry_equipment_event("update_owner", unit, data.owner)
				self:_sentry_equipment_event("update_ammo", unit, data.ammo)
				self:_sentry_equipment_event("update_health", unit, data.health)
				self:_sentry_equipment_event("set_active", unit, data.active)
			end

		for event, clbk in pairs(listeners) do
			UnitBase.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			UnitBase.unregister_listener_clbk(listener_name, event)
		end
	end
end

function HUDListManager:_set_show_minions()
	local list = self:list("left_side_list"):item("minions")

	local listener_name = "HUDListManager_minion_items_listener"
	local listeners = {
		on_add_minion_unit = callback(self, self, "_minion_event", "add"),
		on_remove_minion_unit = callback(self, self, "_minion_event", "remove"),
		on_minion_set_owner = callback(self, self, "_minion_event", "set_owner"),
		on_minion_set_health_mult = callback(self, self, "_minion_event", "set_health_mult"),
		on_minion_set_damage_mult = callback(self, self, "_minion_event", "set_damage_mult"),
		on_minion_health_change = callback(self, self, "_minion_event", "change_health"),
	}

	if HUDListManager.ListOptions.show_minions then
		for key, data in pairs(EnemyManager.MINION_UNITS) do
			local item = list:register_item(tostring(key), HUDList.MinionItem, data.unit)
			item:activate()
			item:set_owner(data.owner_id)
			item:set_upgrade(data.upgraded)
			item:set_health(data.health, true)
		end

		for event, clbk in pairs(listeners) do
			EnemyManager.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			EnemyManager.unregister_listener_clbk(listener_name, event)
		end
	end
end

function HUDListManager:_set_show_pagers()
	local list = self:list("left_side_list"):item("pagers")

	local listener_name = "HUDListManager_active_pager_items_listener"
	local listeners = {
		on_pager_started = callback(self, self, "_pager_event", "add"),
		on_pager_ended = callback(self, self, "_pager_event", "remove"),
		on_pager_answered = callback(self, self, "_pager_event", "answer"),
	}

	if HUDListManager.ListOptions.show_pagers then
		for key, data in pairs(ObjectInteractionManager.ACTIVE_PAGERS) do
			local item = list:register_item(tostring(key), HUDList.PagerItem, data.unit)
			item:activate()
			if data.answered then
				item:set_answered()
			end
		end

		for event, clbk in pairs(listeners) do
			ObjectInteractionManager.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			ObjectInteractionManager.unregister_listener_clbk(listener_name, event)
		end
	end
end

function HUDListManager:_set_show_ecms()
	local list = self:list("left_side_list"):item("ecms")

	local listener_name = "HUDListManager_ecm_items_listener"
	local listeners = {
		on_ecm_create = callback(self, self, "_ecm_event", "add"),
		on_ecm_destroy = callback(self, self, "_ecm_event", "remove"),
		on_ecm_update = callback(self, self, "_ecm_event", "update_battery"),
		on_ecm_set_active = callback(self, self, "_ecm_event", "jammer_status_change"),
	}

	if HUDListManager.ListOptions.show_ecms then
		for key, data in pairs(ECMJammerBase.SPAWNED_ECMS) do
			local item = list:register_item(tostring(key), HUDList.ECMItem)
			item:set_active(data.active)
			item:update_timer(data.t, data.battery_life)
		end

		for event, clbk in pairs(listeners) do
			UnitBase.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			UnitBase.unregister_listener_clbk(listener_name, event)
		end
	end
end

function HUDListManager:_set_show_ecm_retrigger()
	local list = self:list("left_side_list"):item("ecm_retrigger")

	local listener_name = "HUDListManager_ecm_retrigger_listener"
	local listeners = {
		on_ecm_set_retrigger = callback(self, self, "_ecm_retrigger_event", "set_active"),
		on_ecm_update_retrigger_delay = callback(self, self, "_ecm_retrigger_event", "update"),
	}

	if HUDListManager.ListOptions.show_ecm_retrigger then
		for key, data in pairs(ECMJammerBase.SPAWNED_ECMS) do
			if data.retrigger_t then
				local item = list:register_item(tostring(key), HUDList.ECMRetriggerItem)
				item:set_active(true)
				item:update_timer(data.t, data.retrigger_t)
			end
		end

		for event, clbk in pairs(listeners) do
			UnitBase.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			UnitBase.unregister_listener_clbk(listener_name, event)
		end
	end
end

function HUDListManager:_set_remove_answered_pager_contour()
	local listener_name = "HUDListManager_remove_pager_contour_listener"
	local listeners = {
		on_pager_answered = callback(self, self, "_pager_event", "remove_contour")
	}

	if HUDListManager.ListOptions.remove_answered_pager_contour then
		for event, clbk in pairs(listeners) do
			ObjectInteractionManager.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for event, _ in pairs(listeners) do
			ObjectInteractionManager.unregister_listener_clbk(listener_name, event)
		end
	end
end

function HUDListManager:_set_show_tape_loop()
	local list = self:list("left_side_list"):item("tape_loop")

	local listener_name = "HUDListManager_tape_loop_listener"
	local listeners = {
		on_tape_loop_start = callback(self, self, "_tape_loop_event", "start"),
		on_tape_loop_stop = callback(self, self, "_tape_loop_event", "stop"),
	}

	if HUDListManager.ListOptions.show_tape_loop then
		for event, clbk in pairs(listeners) do
			ObjectInteractionManager.register_listener_clbk(listener_name, event, clbk)
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			ObjectInteractionManager.unregister_listener_clbk(listener_name, event)
		end
	end
end

--Right list config
function HUDListManager:_set_show_enemies()
	local list = self:list("right_side_list"):item("unit_count_list")

	if HUDListManager.ListOptions.show_enemies then
		if HUDListManager.ListOptions.aggregate_enemies then
			local data = HUDList.UnitCountItem.ENEMY_ICON_MAP.all
			list:register_item("all", data.class or HUDList.UnitCountItem)
		else
			for name, data in pairs(HUDList.UnitCountItem.ENEMY_ICON_MAP) do
				if not data.manual_add then
					list:register_item(name, data.class or HUDList.UnitCountItem)
				end
			end
		end
	else
		for name, data in pairs(HUDList.UnitCountItem.ENEMY_ICON_MAP) do
			if not data.manual_add then
				list:unregister_item(name, true)
			end
		end
		list:unregister_item("all", true)
	end
end

function HUDListManager:_set_aggregate_enemies()
	local list = self:list("right_side_list"):item("unit_count_list")

	for name, data in pairs(HUDList.UnitCountItem.ENEMY_ICON_MAP) do
		if not data.manual_add then
			list:unregister_item(name, true)
		end
		list:unregister_item("all", true)
	end

	self:_set_show_enemies()
end

function HUDListManager:_set_show_turrets()
	local list = self:list("right_side_list"):item("unit_count_list")
	local data = HUDList.UnitCountItem.MISC_ICON_MAP.turret

	if HUDListManager.ListOptions.show_turrets then
		list:register_item("turret", data.class or HUDList.UnitCountItem)
	else
		list:unregister_item("turret", true)
	end
end

function HUDListManager:_set_show_civilians()
	local list = self:list("right_side_list"):item("unit_count_list")
	local data = HUDList.UnitCountItem.MISC_ICON_MAP.civilian

	if HUDListManager.ListOptions.show_civilians then
		list:register_item("civilian", data.class or HUDList.UnitCountItem)
	else
		list:unregister_item("civilian", true)
	end
end

function HUDListManager:_set_show_hostages()
	--local list = self:list("right_side_list"):item("hostage_count_list")
	local list = self:list("right_side_list"):item("unit_count_list")

	if HUDListManager.ListOptions.show_hostages then
		for name, data in pairs(HUDList.UnitCountItem.HOSTAGE_ICON_MAP) do
			if not data.manual_add then
				list:register_item(name, data.class or HUDList.HostageUnitCountItem)
			end
		end
	else
		for name, data in pairs(HUDList.UnitCountItem.HOSTAGE_ICON_MAP) do
			if not data.manual_add then
				list:unregister_item(name, true)
			end
		end
	end
end

function HUDListManager:_set_show_minion_count()
	--local list = self:list("right_side_list"):item("hostage_count_list")
	local list = self:list("right_side_list"):item("unit_count_list")
	local data = HUDList.UnitCountItem.MISC_ICON_MAP.minion

	if HUDListManager.ListOptions.show_minion_count then
		list:register_item("minion", data.class or HUDList.UnitCountItem)
	else
		list:unregister_item("minion", true)
	end
end

function HUDListManager:_set_show_pager_count()
	local list = self:list("right_side_list"):item("hostage_count_list")

	if HUDListManager.ListOptions.show_pager_count then
		list:register_item("PagerCount", HUDList.UsedPagersItem)
	else
		list:unregister_item("PagerCount", true)
	end
end

function HUDListManager:_set_show_loot()
	local list = self:list("right_side_list"):item("loot_list")

	if HUDListManager.ListOptions.show_loot then
		if HUDListManager.ListOptions.aggregate_loot then
			local data = HUDList.LootItem.LOOT_ICON_MAP.all
			list:register_item("all", data.class or HUDList.LootItem)
		else
			for name, data in pairs(HUDList.LootItem.LOOT_ICON_MAP) do
				if not data.manual_add then
					list:register_item(name, data.class or HUDList.LootItem)
				end
			end
		end
	else
		for name, data in pairs(HUDList.LootItem.LOOT_ICON_MAP) do
			if not data.manual_add then
				list:unregister_item(name, true)
			end
		end
		list:unregister_item("all", true)
	end
end

function HUDListManager:_set_aggregate_loot()
	local list = self:list("right_side_list"):item("loot_list")

	for name, _ in pairs(HUDList.LootItem.LOOT_ICON_MAP) do
		list:unregister_item(name, true)
	end

	self:_set_show_loot()
end

function HUDListManager:_set_show_special_pickups()
	local list = self:list("right_side_list"):item("special_pickup_list")

	for _, item in pairs(list:items()) do
		item:delete(true)
	end

	if HUDListManager.ListOptions.show_special_pickups or HUDListManager.ListOptions.show_gage_packages then
		for id, data in pairs(HUDList.SpecialPickupItem.SPECIAL_PICKUP_ICON_MAP) do
			if (id ~= "courier" and HUDListManager.ListOptions.show_special_pickups) or (id == "courier" and HUDListManager.ListOptions.show_gage_packages) then
				list:register_item(id, data.class or HUDList.SpecialPickupItem)
			end
		end
	end
end

function HUDListManager:_buff_activation(status, buff, ...)
	local data = HUDList.BuffItemBase.COMPOSITE_ITEMS[buff]

	if not HUDList.BuffItemBase.IGNORED_BUFFS[data and data.item or buff] then
		local item = self:list("buff_list"):item(data and data.item or buff)

		if item then
			if status then
				item:activate()
			elseif not (data and data.keep_on_deactivation) then
				item:deactivate()
			end

			if data then
				if data.level then
					item:set_level(data.level(), true)
				end
				if data.aced then
					item:set_aced(data.aced(), true)
				end
			end
		end
	end
end

function HUDListManager:_buff_event(event, buff, ...)
	local data = HUDList.BuffItemBase.COMPOSITE_ITEMS[buff]

	if not HUDList.BuffItemBase.IGNORED_BUFFS[data and data.item or buff] then
		local item = self:list("buff_list"):item(data and data.item or buff)

		if item then
			item[event](item, ...)
		end
	end
end

function HUDListManager:_set_show_buffs()
	local list = self:list("buff_list")

	local listener_name = "HUDListManager_buff_listener"
	local listeners = {
		on_buff_activated = callback(self, self, "_buff_activation", true),
		on_buff_deactivated = callback(self, self, "_buff_activation", false),
		--on_buff_set_duration = callback(self, self, "_buff_event", "set_duration"),
		--on_buff_set_expiration = callback(self, self, "_buff_event", "set_expiration"),
		on_buff_refresh = callback(self, self, "_buff_event", "refresh"),
		on_buff_set_aced = callback(self, self, "_buff_event", "set_aced"),
		on_buff_set_level = callback(self, self, "_buff_event", "set_level"),
		on_buff_set_stack_count = callback(self, self, "_buff_event", "set_stack_count"),
		on_buff_set_flash = callback(self, self, "_buff_event", "set_flash"),
		on_buff_set_progress = callback(self, self, "_buff_event", "set_progress"),
	}

	if HUDListManager.ListOptions.show_buffs then
		for name, data in pairs(HUDList.BuffItemBase.BUFF_MAP) do
			local item = list:register_item(name, data.class or "BuffItemBase", data)
			if data.aced then
				item:set_aced(data.aced)
			end

			if data.level then
				item:set_level(data.level)
			end

			if data.no_fade then
				item:set_fade_time(0)
			end
		end

		for _, src in ipairs({ PlayerManager.ACTIVE_BUFFS, PlayerManager.ACTIVE_TEAM_BUFFS }) do
			for buff, data in pairs(src) do
				self:_buff_activation(true, buff)

				for _, info in ipairs({ "aced", "level", "stack_count", "progress", "flash" }) do
					if data[info] then
						self:_buff_event("set_" .. info, buff, unpack(data[info]))
					end
				end
			end
		end

		if PlayerManager.register_listener_clbk then
			for event, clbk in pairs(listeners) do
				PlayerManager.register_listener_clbk(listener_name, event, clbk)
			end
		end
	else
		for _, item in pairs(list:items()) do
			item:delete(true)
		end

		for event, _ in pairs(listeners) do
			PlayerManager.unregister_listener_clbk(listener_name, event)
		end
	end
end



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--LIST CLASS DEFINITION BLOCK
do

	HUDList = HUDList or {}

	HUDList.ItemBase = HUDList.ItemBase or class()
	function HUDList.ItemBase:init(parent_list, name, params)
		self._parent_list = parent_list
		self._name = name
		self._align = params.align or "center"
		self._fade_time = params.fade_time or 0.25
		self._move_speed = params.move_speed or 150
		self._priority = params.priority

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

	function HUDList.ItemBase:post_init(...) end
	function HUDList.ItemBase:destroy() end
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
			--self._panel:stop()            --Should technically do this, but screws with unrelated animations for some reason...
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
		--      self._parent_list:set_item_visible(self, false)
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

	--TODO: Move this color stuff. Good to have, but has nothing to do with the list and should be localized to subclasses where it is used
	HUDList.ItemBase.DEFAULT_COLOR_TABLE = {
		{ ratio = 0.0, color = Color(1, 0.9, 0.1, 0.1) }, --Red
		{ ratio = 0.5, color = Color(1, 0.9, 0.9, 0.1) }, --Yellow
		{ ratio = 1.0, color = Color(1, 0.1, 0.9, 0.1) } --Green
	}
	function HUDList.ItemBase:_get_color_from_table(value, max_value, color_table, default_color)
		color_table = color_table or HUDList.ItemBase.DEFAULT_COLOR_TABLE
		local ratio = math.clamp(value / max_value, 0, 1)
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
		for _, item in pairs(self._items) do
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
		for _, item in pairs(self._items) do
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

		--local threshold = self._static_item and 1 or 0        --TODO

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
			for _, item in ipairs(self._shown_items) do
				if not item:hidden() then
					total_width = total_width + item:panel():w() + self._item_margin
				end
			end
			total_width = total_width - self._item_margin

			local left = (self._panel:w() - math.min(total_width, self._panel:w())) / 2

			if self._static_item then
				self._static_item:move(left, self._static_item:panel():y(), instant_move)
				left = left + self._static_item:panel():w() + self._item_margin
			end

			for _, item in ipairs(self._shown_items) do
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
			for _, item in ipairs(self._shown_items) do
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
			for _, item in ipairs(self._shown_items) do
				if not item:hidden() then
					total_height = total_height + item:panel():h() + self._item_margin
				end
			end
			total_height = total_height - self._item_margin

			local top = (self._panel:h() - math.min(total_height, self._panel:h())) / 2

			if self._static_item then
				self._static_item:move(self._static_item:panel():x(), top, instant_move)
				top = top + self._static_item:panel():h() + self._item_margin
			end

			for _, item in ipairs(self._shown_items) do
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
			for _, item in ipairs(self._shown_items) do
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

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--LIST ITEM CLASS DEFINITION BLOCK
do

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

		self._listener_clbks = {}
		self._count = 0
	end

	function HUDList.RightListItem:post_init()
		for _, data in ipairs(self._listener_clbks) do
			data.server.register_listener_clbk(data.name, data.event, data.clbk)
		end
	end

	function HUDList.RightListItem:destroy()
		for _, data in ipairs(self._listener_clbks) do
			data.server.unregister_listener_clbk(data.name, data.event)
		end

		HUDList.RightListItem.super.destroy(self)
	end

	function HUDList.RightListItem:set_count(num)
		self._count = num
		self._text:set_text(tostring(self._count))
		if self._count > 0 then
			self:activate()
		else
			self:deactivate()
		end
	end

	function HUDList.RightListItem:_animate_change(text, duration, incr)
		text:set_color(Color.white)

		local t = duration
		while t > 0 do
			local dt = coroutine.yield()
			t = math.max(t - dt, 0)
			local ratio = math.sin(t/duration * 1440 + 90) * 0.5 + 0.5
			text:set_color(Color(incr and ratio or 1, incr and 1 or ratio, ratio))
		end

		text:set_color(Color.white)
	end

--[[
	local enemy_color = Color(1, 1, 1)--Color(0.8, 0.9, 0, 0)
	local guard_color = enemy_color
	local special_color = enemy_color
	local turret_color = enemy_color
	local thug_color = Color(1, 1, 1)--enemy_color--Color(1, 0.6, 0)
	local civilian_color = Color(1, 1, 1)
	local hostage_color = civilian_color
]]

	local enemy_color = Color(SydneyHUD:GetOption("enemy_color_r"), SydneyHUD:GetOption("enemy_color_g"), SydneyHUD:GetOption("enemy_color_b"))
	local guard_color = enemy_color
	local special_color = enemy_color
	local turret_color = enemy_color
	local thug_color = enemy_color
	local civilian_color = Color(SydneyHUD:GetOption("civilian_color_r"), SydneyHUD:GetOption("civilian_color_g"), SydneyHUD:GetOption("civilian_color_b"))
	local hostage_color = civilian_color

	HUDList.UnitCountItem = HUDList.UnitCountItem or class(HUDList.RightListItem)
	HUDList.UnitCountItem.ENEMY_ICON_MAP = {
		all =				{ atlas = {0, 5}, color = enemy_color, manual_add = true },     --Aggregated enemies
		cop =				{ atlas = {0, 5}, color = enemy_color, priority = 5 },  --Non-special police
		sniper =			{ atlas = {6, 5}, color = special_color, priority = 6 },
		tank =				{ atlas = {3, 1}, color = special_color, priority = 6 },
		taser =				{ atlas = {3, 5}, color = special_color, priority = 6 },
		spooc =				{ atlas = {1, 3}, color = special_color, priority = 6 },
		shield =			{ texture = "guis/textures/pd2/hud_buff_shield", color = special_color, priority = 6 },
		security =			{ spec = {1, 4}, color = guard_color, priority = 4 },
		mobster_boss =			{ atlas = {1, 1}, color = thug_color, priority = 4 },
		thug =				{ atlas = {4, 12}, color = thug_color, priority = 4 },
		phalanx =			{ texture = "guis/textures/pd2/hud_buff_shield", color = special_color, priority = 7 },
	}

	HUDList.UnitCountItem.HOSTAGE_ICON_MAP = {
		cop_hostage =           { atlas = {2, 8}, color = hostage_color, priority = 2 },
		civilian_hostage =      { atlas = {4, 7}, color = hostage_color, priority = 1 },
	}
	HUDList.UnitCountItem.MISC_ICON_MAP = {
		turret =                { atlas = {7, 5}, color = turret_color, priority = 4 },
		civilian =      { atlas = {6, 7}, color = civilian_color, priority = 3, class = "CivilianUnitCountItem" },
		minion =        { atlas = {6, 8}, color = hostage_color, priority = 0, class = "MinionCountItem" },
	}
	function HUDList.UnitCountItem:init(parent, name, unit_data)
		unit_data = unit_data or HUDList.UnitCountItem.ENEMY_ICON_MAP[name] or HUDList.UnitCountItem.HOSTAGE_ICON_MAP[name] or HUDList.UnitCountItem.MISC_ICON_MAP[name]
		local params = unit_data.priority and { priority = unit_data.priority }
		HUDList.UnitCountItem.super.init(self, parent, name, unit_data, params)

		if name == "all" then
			table.insert(self._listener_clbks, { server = EnemyManager, name = "total_enemy_count", event = "on_total_enemy_count_change", clbk = callback(self, self, "set_count") })
		else
			table.insert(self._listener_clbks, { server = EnemyManager, name = name .. "_count", event = "on_" .. name .. "_count_change", clbk = callback(self, self, "set_count") })
			self._unit_type = name

			if name == "shield" then        --Shield special case for screwing around with the icon
				self._shield_filler = self._panel:rect({
					name = "shield_filler",
					w = self._icon:w() * 0.4,
					h = self._icon:h() * 0.4,
					color = special_color,
					blend_mode = "normal",
					layer = self._icon:layer() - 1,
				})
				self._shield_filler:set_center(self._icon:center())
			--[[
				self._icon:set_w(self._panel:w() * 0.8)
				self._icon:set_right(self._panel:right() - self._icon:w() * 0.2)

				self._shield_icon = self._panel:bitmap({
					name = "shield_icon",
					texture = "guis/textures/pd2/skilltree/icons_atlas",
					texture_rect = { 2 * 64, 0, 64 * 0.3, 64 },
					rotation = 180,
					h = self._panel:w(),
					w = self._panel:w() * 0.4,
					blend_mode = "normal",
					color = special_color,
				})
				self._shield_icon:set_right(self._panel:right())
			]]
			end
		end

		self:set_count(managers.enemy:unit_count(self._unit_type) or 0)
	end

	HUDList.CivilianUnitCountItem = HUDList.CivilianUnitCountItem or class(HUDList.UnitCountItem)
	function HUDList.CivilianUnitCountItem:init(parent, name, unit_data)
		HUDList.CivilianUnitCountItem.super.init(self, parent, name, unit_data)
		table.insert(self._listener_clbks, { server = GroupAIStateBase, name = "civilian_count", event = "on_civilian_count_change", clbk = callback(self, self, "set_count") })
	end

	function HUDList.CivilianUnitCountItem:set_count(count)
		HUDList.CivilianUnitCountItem.super.set_count(self, count - (managers.groupai:state():civilian_hostage_count() or 0))
	end

	HUDList.HostageUnitCountItem = HUDList.HostageUnitCountItem or class(HUDList.UnitCountItem)
	function HUDList.HostageUnitCountItem:init(parent, name, unit_data)
		HUDList.HostageUnitCountItem.super.init(self, parent, name, unit_data)
		self._listener_clbks = {}       --Clear table of default EnemyManager callbacks
		table.insert(self._listener_clbks, { server = GroupAIStateBase, name = name .. "_count", event = "on_" .. name .. "_count_change", clbk = callback(self, self, "set_count") })
		self:set_count(managers.groupai:state():hostage_count_by_type(self._unit_type) or 0)
	end

	HUDList.MinionCountItem = HUDList.MinionCountItem or class(HUDList.UnitCountItem)
	function HUDList.MinionCountItem:init(parent, name, unit_data)
		HUDList.MinionCountItem.super.init(self, parent, name, unit_data)
		self:set_count(managers.enemy:minion_count() or 0)
	end


	HUDList.UsedPagersItem = HUDList.UsedPagersItem or class(HUDList.RightListItem)
	function HUDList.UsedPagersItem:init(parent, name)
		HUDList.UsedPagersItem.super.init(self, parent, name, { spec = {1, 4} })

		table.insert(self._listener_clbks, { server = ObjectInteractionManager, name = "used_pager_count", event = "on_pager_count_change", clbk = callback(self, self, "set_count") })
		table.insert(self._listener_clbks, { server = ObjectInteractionManager, name = "used_pager_count", event = "on_remove_all_pagers", clbk = callback(self, self, "delete") })

		self:set_count(managers.interaction:used_pager_count() or 0)
	end

	function HUDList.UsedPagersItem:set_count(num)
		HUDList.UsedPagersItem.super.set_count(self, num)

		if self._count >= 5 then
			self._text:set_color(Color.red)
		end
	end


	HUDList.SpecialPickupItem = HUDList.SpecialPickupItem or class(HUDList.RightListItem)
	HUDList.SpecialPickupItem.SPECIAL_PICKUP_ICON_MAP = {
		crowbar =			{ hudpickups = { 0, 64, 32, 32 } },
		keycard =			{ hudpickups = { 32, 0, 32, 32 } },
		courier =			{ atlas = { 6, 0 } },
		planks =			{ hudpickups = { 0, 32, 32, 32 } },
		meth_ingredients =	{ waypoints = { 192, 32, 32, 32 } },
		Blowtorch =			{ hudpickups = { 96, 192, 32, 32 } }
	}
	function HUDList.SpecialPickupItem:init(parent, name, pickup_data)
		pickup_data = pickup_data or HUDList.SpecialPickupItem.SPECIAL_PICKUP_ICON_MAP[name]
		HUDList.SpecialPickupItem.super.init(self, parent, name, pickup_data)

		self._id = name
		table.insert(self._listener_clbks, { server = ObjectInteractionManager, name = "special_pickup_count_" .. name, event = "on_" .. name .. "_count_change", clbk = callback(self, self, "set_count") })

		self:set_count(managers.interaction:special_pickup_count(self._id) or 0)
	end


	HUDList.LootItem = HUDList.LootItem or class(HUDList.RightListItem)
	HUDList.LootItem.LOOT_ICON_MAP = {
		--If you add stuff here, be sure to add the loot type to ObjectInteractionManager as well
		all =			{ manual_add = true },  --Aggregated loot
		gold =			{ text = "Gold" },
		money =			{ text = "Money" },
		jewelry =		{ text = "Jewelry" },
		painting =		{ text = "Painting" },
		coke =			{ text = "Coke" },
		meth =			{ text = "Meth" },
		weapon =		{ text = "Weapon" },
		server =		{ text = "Server" },
		turret =		{ text = "Turret" },
		shell =			{ text = "Shell" },
		artifact =		{ text = "Artifact" },
		armor =			{ text = "Armor" },
		toast =			{ text = "Toast" },
		diamond =		{ text = "Diamond" },
		bomb =			{ text = "Bomb" },
		evidence =		{ text = "Evidence" },
		warhead =		{ text = "Warhead" },
		dentist =		{ text = "Unknown" },
		pig =			{ text = "Pig" },
		safe =			{ text = "Safe" },
		prototype =		{ text = "Prototype" },
		present =		{ text = "Present" },
		goat =			{ text = "Goat" }
		--container =   { text = "?" },
	}
	function HUDList.LootItem:init(parent, name, loot_data)
		loot_data = loot_data or HUDList.LootItem.LOOT_ICON_MAP[name]
		HUDList.LootItem.super.init(self, parent, name, loot_data.icon_data or { hudtabs = { 32, 32, 32, 32 }, alpha = 0.75, w_ratio = 1.2 })

		self._icon:set_center(self._panel:center())
		self._icon:set_top(self._panel:top())
		if HUDListManager.ListOptions.separate_bagged_loot then
			self._text:set_font_size(self._text:font_size() * 0.9)
		end

		if loot_data.text then
			self._name_text = self._panel:text({
				name = "text",
				text = string.sub(loot_data.text, 1, 5) or "",
				align = "center",
				vertical = "center",
				w = self._panel:w(),
				h = self._panel:w(),
				color = Color(0.0, 0.0, 0.5), -- default: 0.0, 0.5, 0.0
				blend_mode = "normal",
				font = tweak_data.hud_corner.assault_font,
				font_size = self._panel:w() * 0.4,
				layer = 10
			})
			self._name_text:set_center(self._icon:center())
			self._name_text:set_y(self._name_text:y() + self._icon:h() * 0.1)
		end

		if name == "all" then
			table.insert(self._listener_clbks, { server = ObjectInteractionManager, name = "loot_count_total", event = "on_total_loot_count_change", clbk = callback(self, self, "set_count") })
		else
			self._id = name
			table.insert(self._listener_clbks, { server = ObjectInteractionManager, name = "loot_count_" .. name, event = "on_" .. name .. "_count_change", clbk = callback(self, self, "set_count") })
		end

		self._bagged_count = 0
		local unbagged, bagged = managers.interaction:loot_count(self._id)
		self:set_count(bagged or 0, unbagged or 0)
	end

	function HUDList.LootItem:set_count(value, bagged_value)
		local old_total = self._count + self._bagged_count
		local new_total = value + bagged_value
		if old_total > 0 and new_total > 0 then
			self._text:stop()
			self._text:animate(callback(self, self, "_animate_change"), 1, old_total < new_total)
		end

		self._count = value
		self._bagged_count = bagged_value
		if HUDListManager.ListOptions.separate_bagged_loot then
			self._text:set_text(self._count .. "/" .. self._bagged_count)
		else
			self._text:set_text(new_total)
		end

		if self._count > 0 or self._bagged_count > 0 then
			self:activate()
		else
			self:deactivate()
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
	HUDList.TimerItem.DISABLED_COLOR = Color(1, 1, 0, 0)
	HUDList.TimerItem.FLASH_SPEED = 2
	function HUDList.TimerItem:init(parent, name, unit)
		HUDList.ItemBase.init(self, parent, name, { align = "left", w = parent:panel():h() * 4/5, h = parent:panel():h() })

		self._show_distance = true
		self._jammed = false
		self._powered = true
		self._unit = unit
		self._name = name
		self._flash_color_table = {
			{ ratio = 0.0, color = self.DISABLED_COLOR },
			{ ratio = 1.0, color = self.STANDARD_COLOR }
		}
		self._current_color = self.STANDARD_COLOR

		self._type_text = self._panel:text({
			name = "type_text",
			text = "Timer",
			align = "center",
			vertical = "top",
			w = self._panel:w(),
			h = self._panel:h() * 0.3,
			color = Color.white,
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
			color = Color.white,
			font = tweak_data.hud_corner.assault_font,
			font_size = self._box:h() * 0.4
		})

		self._time_text = self._box:text({
			name = "time",
			align = "center",
			vertical = "bottom",
			w = self._box:w(),
			h = self._box:h(),
			color = Color.white,
			font = tweak_data.hud_corner.assault_font,
			font_size = self._box:h() * 0.6
		})

		self:_set_colors(self._current_color)
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

	function HUDList.TimerItem:update_timer(t, time_left)
		self._remaining = time_left
		self._time_text:set_text(string.format("%d:%02d", time_left/60, time_left%60))
	end

	function HUDList.TimerItem:set_jammed(status)
		self._jammed = status
		self:_check_is_running()
	end

	function HUDList.TimerItem:set_powered(status)
		self._powered = status
		self:_check_is_running()
	end

	function HUDList.TimerItem:_check_is_running()
		if not self._jammed and self._powered then
			self:_set_colors(self._current_color)
		end
	end

	function HUDList.TimerItem:_set_colors(color)
		self._time_text:set_color(color)
		self._type_text:set_color(color)
		self._distance_text:set_color(color)
	end

	function HUDList.TimerItem:set_can_upgrade(status)
		self._can_upgrade = status
		self._current_color = status and self.UPGRADE_COLOR or self.STANDARD_COLOR
		self._flash_color_table[2].color = status and self.UPGRADE_COLOR or self.STANDARD_COLOR
		self:_set_colors(self._current_color)
	end

	function HUDList.TimerItem:set_type(type)
		self._type_text:set_text(type)
	end


	HUDList.TemperatureGaugeItem = HUDList.TemperatureGaugeItem or class(HUDList.TimerItem)
	function HUDList.TemperatureGaugeItem:init(parent, name, unit, params)
		HUDList.TimerItem.init(self, parent, name, unit)

		self:set_type("Temp")
		self._start = params.start
		self._goal = params.goal
		self._last_value = self._start
	end

	function HUDList.TemperatureGaugeItem:update(t, dt)

	end

	function HUDList.TemperatureGaugeItem:update_timer(t, value)
		local ratio = math.clamp((value - self._start) / (self._goal - self._start), 0, 1) * 100
		local dv = math.abs(self._last_value - value)
		local estimate = "n/a"

		if dv > 0 then
			local time_left = math.round(math.abs(self._goal - value) / dv)
			estimate = string.format("%d:%02d", time_left/60, time_left%60)
		end

		self._distance_text:set_text(string.format("%.0f%%", ratio))
		self._time_text:set_text(estimate)
		self._last_value = value
	end


	HUDList.EquipmentItem = HUDList.EquipmentItem or class(HUDList.ItemBase)
	HUDList.EquipmentItem.EQUIPMENT_TABLE = {
		sentry = {                              atlas = { 7, 5 }, priority = 1 },
		ammo_bag = {            atlas = { 1, 0 }, priority = 3 },
		doc_bag = {                     atlas = { 2, 7 }, priority = 4 },
		body_bag = {                    atlas = { 5, 11 }, priority = 5 },
		grenade_crate = {       preplanning = { 1, 0 }, priority = 2 },
	}
	function HUDList.EquipmentItem:init(parent, name, equipment_type, unit)
		local data = HUDList.EquipmentItem.EQUIPMENT_TABLE[equipment_type]

		HUDList.ItemBase.init(self, parent, name, { align = "center", w = parent:panel():h() * 4/5, h = parent:panel():h(), priority = data.priority })

		self._unit = unit
		self._type = equipment_type
		local texture = data.atlas and "guis/textures/pd2/skilltree/icons_atlas" or data.preplanning and "guis/dlcs/big_bank/textures/pd2/pre_planning/preplan_icon_types"
		local x, y = unpack((data.atlas or data.preplanning) or { 0, 0 })
		local w = data.atlas and 64 or data.preplanning and 48
		local texture_rect = (data.atlas or data.preplanning) and { x * w, y * w, w, w }

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

		self._info_text = self._panel:text({
			name = "info",
			text = "",
			align = "center",
			vertical = "bottom",
			w = self._panel:w(),
			h = self._panel:h() * 0.4,
			color = Color.white,
			layer = 1,
			font = tweak_data.hud_corner.assault_font,
			font_size = self._panel:h() * 0.4,
		})
		self._info_text:set_bottom(self._panel:bottom())
	end

	function HUDList.EquipmentItem:set_owner(peer_id)
		self._owner = peer_id
		self:_set_color()
	end

	function HUDList.EquipmentItem:get_type()
		return self._type
	end

	function HUDList.EquipmentItem:_set_color()
		if self._owner then
			local color = self._owner > 0 and tweak_data.chat_colors[self._owner]:with_alpha(1) or Color.white
			self._icon:set_color(color)
		end
	end

	HUDList.BagEquipmentItem = HUDList.BagEquipmentItem or class(HUDList.EquipmentItem)

	function HUDList.BagEquipmentItem:init(parent, name, equipment_type, unit)
		HUDList.EquipmentItem.init(self, parent, name, equipment_type, unit)
		self._amount_format = "%.0f" .. (equipment_type == "ammo_bag" and "%%" or "")
		self._amount_offset = 0
	end

	function HUDList.BagEquipmentItem:current_amount()
		return self._current_amount
	end

	function HUDList.BagEquipmentItem:set_max_amount(max_amount)
		self._max_amount = (max_amount or 0) + self._amount_offset
		self:_update_info_text()
	end

	function HUDList.BagEquipmentItem:set_amount(amount)
		self._current_amount = (amount or 0) + self._amount_offset
		self:_update_info_text()
	end

	function HUDList.BagEquipmentItem:set_amount_offset(offset)
		self._amount_offset = offset or 0
		self:set_max_amount(self._max_amount)
		self:set_amount(self._current_amount)
	end

	function HUDList.BagEquipmentItem:_update_info_text()
		if self._current_amount and self._max_amount then
			self._info_text:set_text(string.format(self._amount_format, self._current_amount))
			self._info_text:set_color(self:_get_color_from_table(self._current_amount, self._max_amount))
		end
	end


	HUDList.SentryEquipmentItem = HUDList.SentryEquipmentItem or class(HUDList.EquipmentItem)
	function HUDList.SentryEquipmentItem:init(parent, name, unit)
		HUDList.EquipmentItem.init(self, parent, name, "sentry", unit)
		self:set_ammo_ratio(unit:weapon() and unit:weapon():ammo_ratio() or 0)
		self:set_ammo_ratio(unit:character_damage() and unit:character_damage():health_ratio() or 0)
	end

	function HUDList.SentryEquipmentItem:set_ammo_ratio(ratio)
		self._ammo_ratio = ratio or 0
		self._info_text:set_text(string.format("%.0f%%", self._ammo_ratio * 100))
	end

	function HUDList.SentryEquipmentItem:set_health_ratio(ratio)
		self._health_ratio = ratio or 0
		self._info_text:set_color(self:_get_color_from_table(self._health_ratio, 1))
	end


	HUDList.MinionItem = HUDList.MinionItem or class(HUDList.ItemBase)
	HUDList.MinionItem._UNIT_NAMES = {
		security = "Security",
		gensec = "Security",
		cop = "Cop",
		fbi = "FBI",
		swat = "SWAT",
		heavy_swat = "H. SWAT",
		fbi_swat = "FBI SWAT",
		fbi_heavy_swat = "H. FBI SWAT",
		city_swat = "GenSec",
	}
	function HUDList.MinionItem:init(parent, name, unit)
		HUDList.MinionItem.super.init(self, parent, name, { align = "center", w = parent:panel():h() * 4/5, h = parent:panel():h() })

		self._unit = unit
		self._max_health = unit:character_damage()._HEALTH_INIT
		local type_str = self._UNIT_NAMES[unit:base()._tweak_table] or "UNKNOWN"

		self._health_bar = self._panel:bitmap({
			name = "radial_health",
			texture = "guis/textures/pd2/hud_health",
			texture_rect = { 64, 0, -64, 64 },
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
			texture_rect = { 64, 0, -64, 64 },
			--render_template = "VertexColorTexturedRadial",
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
			text = type_str,
			align = "center",
			vertical = "top",
			w = self._panel:w(),
			h = self._panel:w() * 0.3,
			color = Color.white,
			layer = 3,
			font = tweak_data.hud_corner.assault_font,
			font_size = math.min(8 / string.len(type_str), 1) * 0.25 * self._panel:h(),
		})

		self:set_health(self._max_health, true)
	end

	function HUDList.MinionItem:set_health(health, skip_animate)
		self._health_bar:set_color(Color(1, health / self._max_health, 1, 1))

		if not (skip_animate or self._dead) then
			self._hit_indicator:stop()
			self._hit_indicator:animate(callback(self, self, "_animate_damage"))
		end
	end

	function HUDList.MinionItem:set_owner(peer_id)
		self._unit_type:set_color(peer_id and tweak_data.chat_colors[peer_id]:with_alpha(1) or Color(1, 1, 1, 1))
	end

	function HUDList.MinionItem:set_health_multiplier(mult)
		local max_mult = tweak_data.upgrades.values.player.convert_enemies_health_multiplier[1] * tweak_data.upgrades.values.player.passive_convert_enemies_health_multiplier[2]
		local alpha = math.clamp(1 - (mult - max_mult) / (1 - max_mult), 0, 1) * 0.8 + 0.2
		self._outline:set_alpha(alpha)
	end

	function HUDList.MinionItem:set_damage_multiplier(mult)
		self._damage_upgrade_text:set_alpha(mult > 1 and 1 or 0.5)
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
	function HUDList.PagerItem:init(parent, name, unit)
		HUDList.PagerItem.super.init(self, parent, name, { align = "left", w = parent:panel():h(), h = parent:panel():h() })

		self._unit = unit
		self._max_duration_t = 12
		self._duration_t = self._max_duration_t

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
			text = string.format("%.1fs", self._duration_t)
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
	end

	function HUDList.PagerItem:set_duration(duration_t)
		self._duration_t = duration_t
	end

	function HUDList.PagerItem:set_answered()
		if not self._answered then
			self._answered = true
			self._timer_text:set_color(Color(1, 0.1, 0.9, 0.1))
		end
	end

	function HUDList.PagerItem:update(t, dt)
		if not self._answered then
			self._duration_t = math.max(self._duration_t - dt, 0)
			self._timer_text:set_text(string.format("%.1fs", self._duration_t))
			self._timer_text:set_color(self:_get_color_from_table(self._duration_t, self._max_duration_t))
		end

		local distance = 0
		if alive(self._unit) and alive(managers.player:player_unit()) then
			distance = mvector3.normalize(managers.player:player_unit():position() - self._unit:position()) / 100
		end
		self._distance_text:set_text(string.format("%.0fm", distance))
	end


	HUDList.ECMItem = HUDList.ECMItem or class(HUDList.ItemBase)
	function HUDList.ECMItem:init(parent, name)
		HUDList.ItemBase.init(self, parent, name, { align = "right", w = parent:panel():h(), h = parent:panel():h() })

		battery_upgrade_level = managers.player:upgrade_level("ecm_jammer", "duration_multiplier", 0) + managers.player:upgrade_level("ecm_jammer", "duration_multiplier_2", 0) + 1

		self._max_duration = tweak_data.upgrades.ecm_jammer_base_battery_life * ECMJammerBase.battery_life_multiplier[battery_upgrade_level]

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

	function HUDList.ECMItem:update_timer(t, time_left)
		self._text:set_text(string.format("%.1f", time_left))
		self._text:set_color(self:_get_color_from_table(time_left, self._max_duration))
	end


	HUDList.ECMRetriggerItem = HUDList.ECMRetriggerItem or class(HUDList.ECMItem)
	function HUDList.ECMRetriggerItem:init(parent, name)
		HUDList.ECMRetriggerItem.super.init(self, parent, name)

		self._max_duration = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
	end

	function HUDList.ECMRetriggerItem:update_timer(t, time_left)
		local text
		if time_left > 60 then
			text = string.format("%d:%02d", time_left/60, time_left%60)
		else
			text = string.format("%d", time_left)
		end
		self._text:set_text(text)
		self._text:set_color(self:_get_color_from_table(self._max_duration - time_left, self._max_duration))
	end

	HUDList.TapeLoopItem = HUDList.TapeLoopItem or class(HUDList.ItemBase)
	function HUDList.TapeLoopItem:init(parent, name, unit)
		HUDList.TapeLoopItem.super.init(self, parent, name, { align = "right", w = parent:panel():h(), h = parent:panel():h() })

		self._unit = unit

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

	function HUDList.TapeLoopItem:set_duration(duration)
		self._duration = duration
		self._text:set_text(string.format("%.1f", self._duration))
		if self._duration <= 0 then
			self:delete()
		end
	end

	function HUDList.TapeLoopItem:update(t, dt)
		self:set_duration(math.max(self._duration - dt, 0))
	end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	--Buff list

	HUDList.BuffItemBase = HUDList.BuffItemBase or class(HUDList.ItemBase)
	HUDList.BuffItemBase.ICON_COLORS = {
		buff = {
			icon = Color.white,
			flash = Color.red,
			bg = Color(0.75, 1, 1, 1),
			aced_icon = Color.white,
			--level_icon = Color(0.4, 0, 1, 0),
		},
		team = {
			icon = Color.white,
			flash = Color.red,
			bg = Color(0.5, 0.2, 1, 0.2),
			aced_icon = Color.white,
			--level_icon = Color(0.4, 0, 1, 0),
		},
		debuff = {
			icon = Color.white,
			flash = Color.red,
			bg = Color(1, 0, 0),
			aced_icon = Color.white,
			--level_icon = Color(0.4, 0, 1, 0),
		},
	}

	HUDList.BuffItemBase.BUFF_MAP = {
		hostage_situation = {                   spec = { 0, 1 },                priority = 2,   type = "buff" },
		partner_in_crime = {                    atlas = { 1, 10 },      priority = 2,   type = "buff" },
		hostage_taker = {                               atlas = { 2, 10 },      priority = 2,   type = "buff",
			icon_scale = 1.35
		},
		underdog = {                                            atlas = { 2, 1 },               priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		overdog = {                                             spec = { 6, 4 },                priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		close_combat = {                                spec = { 5, 4 },                priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		combat_medic = {                                atlas = { 5, 7 },               priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		overkill = {                                                    atlas = { 3, 2 },               priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		bullet_storm = {                                        atlas = { 4, 5 },               priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		pain_killer = {                                 atlas = { 0, 10 },      priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		swan_song = {                                   atlas = { 5, 12 },      priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		quick_fix = {                                           atlas = { 1, 11 },      priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		trigger_happy = {                               atlas = { 7, 11 },      priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		inspire = {                                                     atlas = { 4, 9 },               priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		melee_stack_damage = {  spec = { 5, 4 },                priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		damage_to_hot = {                       spec = { 4, 6 },                priority = 3,   type = "buff",                  class = "TimedBuffItem" },
		sixth_sense = {                                 atlas = { 6, 10 },      priority = 3,   type = "buff",                  class = "TimedBuffItem",
			flash_color = Color.blue,
			flash_speed = tweak_data.player.omniscience.interval_t * 0.5
		},
		bow_charge = {                                                                                          priority = 3,   type = "buff",                  class = "ChargedBuffItem",
			texture = "guis/dlcs/west/textures/pd2/blackmarket/icons/weapons/plainsrider",
			icon_rotation = 90,
			icon_w_ratio = 0.5,
			icon_scale = 2,
			flash_speed = 0.2,
			no_fade = true
		},
		melee_charge = {                                atlas = { 4, 10 },      priority = 3,   type = "buff",                  class = "ChargedBuffItem",
			flash_speed = 0.2,
			no_fade = true
		},
		berserker = {                                           atlas = { 2, 2 },               priority = 2,   type = "buff",                  class = "BerserkerBuffItem" },
		crew_chief = {                                  atlas = { 2, 7 },               priority = 1,   type = "team" },
		leadership = {                                  atlas = { 7, 7 },               priority = 1,   type = "team" },
		bulletproof = {                                 atlas = { 6, 4 },               priority = 1,   type = "team",
			aced = true,
		},
		armorer = {                                             spec = { 6, 0 },                priority = 1,   type = "team",
			level = 9,
		},
		endurance = {                                   atlas = { 1, 8 },               priority = 1,   type = "team",
			aced = true,
		},
		life_drain = {                                          spec = { 7, 4 },                priority = 5,   type = "debuff",                class = "TimedBuffItem" },
		medical_supplies = {                    spec = { 4, 5 },                priority = 5,   type = "debuff",                class = "TimedBuffItem" },
		ammo_give_out = {                       spec = { 5, 5 },                priority = 5,   type = "debuff",                class = "TimedBuffItem" },
		inspire_debuff = {                              atlas = { 4, 9 },               priority = 5,   type = "debuff",                class = "TimedBuffItem" },
		bullseye_debuff = {                     atlas = { 6, 11 },      priority = 5,   type = "debuff",                class = "TimedBuffItem" },
		tension_debuff = {                              spec = { 0, 5 },                priority = 5,   type = "debuff",                class = "TimedBuffItem" },
		damage_to_hot_debuff = {        spec = { 4, 6 },                priority = 5,   type = "debuff",                class = "TimedBuffItem" },
		armor_regen_debuff = {          spec = { 6, 0 },                priority = 5,   type = "debuff",                class = "TimedBuffItem",
			no_fade = true
		},
		suppression_debuff = {          atlas = { 7, 0 },               priority = 5,   type = "debuff",                class = "SuppressionBuffItem",
			flash_speed = 0.25,
			no_fade = true
		},
	}

	HUDList.BuffItemBase.IGNORED_BUFFS = {
		hostage_situation = false,
		partner_in_crime = false,
		hostage_taker = false,
		underdog = false,
		underdog_aced = false,
		overdog = false,
		close_combat = false,
		combat_medic = false,
		overkill = false,
		bullet_storm = false,
		pain_killer = false,
		swan_song = false,
		quick_fix = false,
		trigger_happy = false,
		inspire = false,
		melee_stack_damage = false,
		damage_to_hot = false,
		sixth_sense = false,
		bow_charge = false,
		melee_charge = false,
		berserker = false,
		crew_chief = false,
		crew_chief_3 = false,
		crew_chief_5 = false,
		crew_chief_7 = false,
		crew_chief_9 = false,
		leadership = false,
		leadership_aced = false,
		bulletproof = false,
		armorer = false,
		endurance = false,
		life_drain = false,
		medical_supplies = false,
		ammo_give_out = false,
		inspire_debuff = false,
		bullseye_debuff = false,
		tension_debuff = false,
		damage_to_hot_debuff = false,
		armor_regen_debuff = false,
		suppression_debuff = true,
	}

	HUDList.BuffItemBase.COMPOSITE_ITEMS = {
		underdog_aced = {               item = "underdog",              keep_on_deactivation = true,
			aced = function()
				return true
			end
		},
		leadership = {                  item = "leadership",
			aced = function()
				return managers.player:has_team_category_upgrade("weapon", "recoil_multiplier") or managers.player:has_team_category_upgrade("weapon", "suppression_recoil_multiplier")
			end
		},
		crew_chief_3 = {                item = "crew_chief",
			level = function()
				if managers.player:has_team_category_upgrade("health", "hostage_multiplier") or managers.player:has_team_category_upgrade("stamina", "hostage_multiplier")  or managers.player:has_team_category_upgrade("damage_dampener", "hostage_multiplier") then
					return 9
				elseif managers.player:has_team_category_upgrade("armor", "multiplier") then
					return 7
				elseif managers.player:has_team_category_upgrade("health", "passive_multiplier") then
					return 5
				elseif managers.player:has_team_category_upgrade("stamina", "passive_multiplier") then
					return 3
				else
					return 0
				end
			end
		},
	}
	HUDList.BuffItemBase.COMPOSITE_ITEMS.leadership_aced = table.deep_map_copy(HUDList.BuffItemBase.COMPOSITE_ITEMS.leadership)
	HUDList.BuffItemBase.COMPOSITE_ITEMS.leadership_aced.keep_on_deactivation = true
	HUDList.BuffItemBase.COMPOSITE_ITEMS.crew_chief_5 = table.deep_map_copy(HUDList.BuffItemBase.COMPOSITE_ITEMS.crew_chief_3)
	HUDList.BuffItemBase.COMPOSITE_ITEMS.crew_chief_5.keep_on_deactivation = true
	HUDList.BuffItemBase.COMPOSITE_ITEMS.crew_chief_7 = table.deep_map_copy(HUDList.BuffItemBase.COMPOSITE_ITEMS.crew_chief_5)
	HUDList.BuffItemBase.COMPOSITE_ITEMS.crew_chief_9 = table.deep_map_copy(HUDList.BuffItemBase.COMPOSITE_ITEMS.crew_chief_5)

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

		self._stack_bg = self._panel:bitmap({
			w = 26 * self:panel():w()/45,
			h = 26 * self:panel():w()/45,
			blend_mode = "normal",
			texture ="guis/textures/pd2/equip_count",
			layer = 2,
			alpha = 0.8,
			visible = false
		})
		self._stack_bg:set_right(self._panel:w())
		self._stack_bg:set_bottom(self._panel:h())

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
			font_size = self._stack_bg:h() * 0.55,
			visible = false,
		})
		self._stack_text:set_center(self._stack_bg:center())

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

	HUDList.TimedBuffItem = HUDList.TimedBuffItem or class(HUDList.BuffItemBase)
	function HUDList.TimedBuffItem:init(parent, name, icon)
		HUDList.TimedBuffItem.super.init(self, parent, name, icon)

		self._timer = CircleBitmapGuiObject:new(self._panel, {
			use_bg = true,
			radius = 0.9 * self:panel():w() / 2,
			color = Color(1, 1, 1, 1),
			blend_mode = "add",
			layer = 0
		})
		self._timer._circle:set_center(self._icon:center())
	end

	function HUDList.TimedBuffItem:set_duration(duration)
		self._duration = duration
	end

	function HUDList.TimedBuffItem:refresh()
		self:set_progress(0)
	end

	function HUDList.TimedBuffItem:set_progress(ratio)
		self._timer._circle:set_color(Color(1, ratio, 1, 1))    --TODO: why the hell wont set_current directly on the timer work?
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

	HUDList.BerserkerBuffItem = HUDList.BerserkerBuffItem or class(HUDList.BuffItemBase)
	function HUDList.BerserkerBuffItem:init(parent, name)
		HUDList.BuffItemBase.init(self, parent, name, HUDList.BuffItemBase.BUFF_MAP.berserker)

		self._text = self._panel:text({
			name = "text",
			text = "0",
			valign = "bottom",
			halign = "center",
			align = "center",
			vertical = "bottom",
			horizontal = "center",
			w = self._icon:w(),
			h = math.round(self._icon:w() * 0.4),
			layer = 0,
			color = Color.white,
			font = tweak_data.hud_corner.assault_font,
			font_size = math.round(self._icon:w() * 0.4),
			blend_mode = "normal"
		})
		self._icon:set_top(self:panel():top() + self._icon:h() * 0.1) --Extra space for ace card bg
		self._flash_icon:set_center(self._icon:center())
		self._bg:set_center(self._icon:center())
		self._text:set_center(self._icon:center())
		self._text:set_bottom(self:panel():bottom())
		self._text_bg = self._panel:rect({
			name = "text_bg",
			color = Color.black,
			layer = -1,
			alpha = 0.5,
			blend_mode = "normal",
			w = self._text:w(),
			h = self._text:h(),
		})
		self._text_bg:set_center(self._text:center())
	end

	function HUDList.BerserkerBuffItem:set_progress(ratio)
		self._text:set_color(self:_get_color_from_table(ratio, 1))
		self._text:set_text(string.format("%.0f", ratio * 100) .. "%")

		local _, _, w, _ = self._text:text_rect()
		self._text_bg:set_w(w)
		self._text_bg:set_center(self._text:center())
	end

	HUDList.SuppressionBuffItem = HUDList.SuppressionBuffItem or class(HUDList.TimedBuffItem)
	function HUDList.SuppressionBuffItem:set_progress(ratio)
		HUDList.SuppressionBuffItem.super.set_progress(self, ratio)

		local max = tweak_data.player.suppression.max_value
		local current = ratio * (tweak_data.player.suppression.decay_start_delay + max)
		if current > max and not self._flashing then
			self._flashing = true
			self:set_flash(true)
		elseif current < max and self._flashing then
			self._flashing = nil
			self:stop_flash()
		end
	end

end
