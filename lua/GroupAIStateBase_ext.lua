
local init_original = GroupAIStateBase.init
local update_original = GroupAIStateBase.update
local register_turret_original = GroupAIStateBase.register_turret
local unregister_turret_original = GroupAIStateBase.unregister_turret
local set_whisper_mode_original = GroupAIStateBase.set_whisper_mode
local convert_hostage_to_criminal_original = GroupAIStateBase.convert_hostage_to_criminal
local sync_converted_enemy_original = GroupAIStateBase.sync_converted_enemy
local on_hostage_state_original = GroupAIStateBase.on_hostage_state
local sync_hostage_headcount_original = GroupAIStateBase.sync_hostage_headcount
local _upd_criminal_suspicion_progress_original = GroupAIStateBase._upd_criminal_suspicion_progress

GroupAIStateBase._LISTENER_CALLBACKS = {}

function GroupAIStateBase:init(...)
	self._civilian_hostages = 0
	self._wave_counter = 0
	return init_original(self, ...)
end

function GroupAIStateBase:update(t, ...)
	if self._client_hostage_count_expire_t and t < self._client_hostage_count_expire_t then
		self:_client_hostage_count_cbk()
	end
	return update_original(self, t, ...)
end

function GroupAIStateBase:register_turret(unit, ...)
	self._turrets_registered = self._turrets_registered or {}
	if not self._turrets_registered[unit:key()] then
		self._turrets_registered[unit:key()] = true
		managers.enemy:_change_swat_turret_count(1)
	end
	return register_turret_original(self, unit, ...)
end

function GroupAIStateBase:unregister_turret(unit, ...)
	self._turrets_registered = self._turrets_registered or {}
	if self._turrets_registered[unit:key()] then
		self._turrets_registered[unit:key()] = nil
		managers.enemy:_change_swat_turret_count(-1)
	end
	return unregister_turret_original(self, unit, ...)
end

function GroupAIStateBase:set_whisper_mode(enabled, ...)
	set_whisper_mode_original(self, enabled, ...)
	if (enabled) then
		managers.hud:set_hud_mode("stealth")
	else
		managers.hud:set_hud_mode("loud")
	end
	self._do_listener_callback("on_whisper_mode_change", enabled)
end

function GroupAIStateBase:convert_hostage_to_criminal(unit, peer_unit, ...)
	convert_hostage_to_criminal_original(self, unit, peer_unit, ...)
	if unit:brain()._logic_data.is_converted then
		local peer_id = peer_unit and managers.network:session():peer_by_unit(peer_unit):id() or managers.network:session():local_peer():id()
		local owner_base = peer_unit and peer_unit:base() or managers.player
		local health_mult = 1
		local damage_mult = 1
		local joker_level = (owner_base:upgrade_level("player", "convert_enemies_health_multiplier", 0) or 0)
		local partner_in_crime_level = (owner_base:upgrade_level("player", "passive_convert_enemies_health_multiplier", 0) or 0)
		if joker_level > 0 then
			health_mult = health_mult * tweak_data.upgrades.values.player.convert_enemies_health_multiplier[joker_level]
			damage_mult = damage_mult * tweak_data.upgrades.values.player.convert_enemies_damage_multiplier[joker_level]
		end
		if partner_in_crime_level > 0 then
			health_mult = health_mult * tweak_data.upgrades.values.player.passive_convert_enemies_health_multiplier[partner_in_crime_level]
		end
		managers.enemy:add_minion_unit(unit, peer_id, health_mult, damage_mult)
	end
end

function GroupAIStateBase:sync_converted_enemy(converted_enemy, ...)
	sync_converted_enemy_original(self, converted_enemy, ...)
	managers.enemy:add_minion_unit(converted_enemy)
end

function GroupAIStateBase:on_hostage_state(...)
	on_hostage_state_original(self, ...)
	self:_update_hostage_count()
end

function GroupAIStateBase:sync_hostage_headcount(...)
	sync_hostage_headcount_original(self, ...)
	if Network:is_server() then
		self:_update_hostage_count()
	else
		self._client_hostage_count_expire_t = self._t + 10
	end
end

function GroupAIStateBase:hostage_count_by_type(u_type)
	if u_type == "cop_hostage" then
		return self:police_hostage_count()      --Default function, updated for client-side
	elseif u_type == "civilian_hostage" then
		return self:civilian_hostage_count()    --Custom function
	elseif u_type == nil then
		return  self:hostage_count()    --Default function, total hostages
	end
end

function GroupAIStateBase:civilian_hostage_count()
	return self._civilian_hostages
end

function GroupAIStateBase:_client_hostage_count_cbk()
	local old_police_count = self._police_hostage_headcount
	local old_civ_hostages = self._civilian_hostages
	local police_count = 0
	for _, u_data in pairs(managers.enemy:all_enemies()) do
		if u_data and u_data.unit and u_data.unit.anim_data and u_data.unit:anim_data() then
			if u_data.unit:anim_data().surrender then
				police_count = police_count + 1
			end
		end
	end
	self._police_hostage_headcount = police_count
	self._civilian_hostages = self:hostage_count() - self._police_hostage_headcount
	if old_police_count ~= self._police_hostage_headcount or old_civ_hostages ~= self._civilian_hostages then
		self:_update_hostage_count()
	end
end

function GroupAIStateBase:_update_hostage_count()
	if Network:is_server() then
		self._civilian_hostages = self._hostage_headcount - self._police_hostage_headcount
	end
	self._do_listener_callback("on_civilian_count_change", managers.enemy:unit_count("civilian"))
	self._do_listener_callback("on_civilian_hostage_count_change", self:civilian_hostage_count())
	self._do_listener_callback("on_cop_hostage_count_change", self:police_hostage_count())
end


function GroupAIStateBase.register_listener_clbk(name, event, clbk)
	GroupAIStateBase._LISTENER_CALLBACKS[event] = GroupAIStateBase._LISTENER_CALLBACKS[event] or {}
	GroupAIStateBase._LISTENER_CALLBACKS[event][name] = clbk
end

function GroupAIStateBase.unregister_listener_clbk(name, event)
	for event_id, listeners in pairs(GroupAIStateBase._LISTENER_CALLBACKS) do
		if not event or event_id == event then
			for id, _ in pairs(listeners) do
				if id == name then
					GroupAIStateBase._LISTENER_CALLBACKS[event_id][id] = nil
					break
				end
			end
		end
	end
end

function GroupAIStateBase._do_listener_callback(event, ...)
	if GroupAIStateBase._LISTENER_CALLBACKS[event] then
		for _, clbk in pairs(GroupAIStateBase._LISTENER_CALLBACKS[event]) do
			clbk(...)
		end
	end
end

function GroupAIStateBase:_upd_criminal_suspicion_progress(...)
	if self._ai_enabled then
		for obs_key, obs_susp_data in pairs(self._suspicion_hud_data or {}) do
			local unit = obs_susp_data.u_observer
			if managers.enemy:is_civilian(unit) then
				local waypoint = managers.hud._hud.waypoints["susp1" .. tostring(obs_key)]
				if waypoint then
					local color, arrow_color
					if SydneyHUD:GetOption("enable_pacified") and unit:anim_data().drop then
						if not obs_susp_data._subdued_civ then
							obs_susp_data._alerted_civ = nil
							obs_susp_data._subdued_civ = true
							color = Color(0.0, 1.0, 0.0)
							arrow_color = Color(0.0, 0.3, 0.0)
						end
					elseif obs_susp_data.alerted then
						if not obs_susp_data._alerted_civ then
							obs_susp_data._subdued_civ = nil
							obs_susp_data._alerted_civ = true
							color = Color.white
							arrow_color = tweak_data.hud.detected_color
						end
					end
					if color then
						waypoint.bitmap:set_color(color)
						waypoint.arrow:set_color(arrow_color:with_alpha(0.75))
					end
				end
			end
		end
	end
	return _upd_criminal_suspicion_progress_original(self, ...)
end
