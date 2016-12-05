
local _check_action_throw_grenade_original = PlayerStandard._check_action_throw_grenade
local _check_action_interact_original = PlayerStandard._check_action_interact
local _start_action_reload_original = PlayerStandard._start_action_reload
local _update_reload_timers_original = PlayerStandard._update_reload_timers
local _interupt_action_reload_original = PlayerStandard._interupt_action_reload
local _start_action_charging_weapon_original = PlayerStandard._start_action_charging_weapon
local _end_action_charging_weapon_original = PlayerStandard._end_action_charging_weapon
local _update_charging_weapon_timers_original = PlayerStandard._update_charging_weapon_timers
local _start_action_melee_original = PlayerStandard._start_action_melee
local _update_melee_timers_original = PlayerStandard._update_melee_timers
local _do_melee_damage_original = PlayerStandard._do_melee_damage
local _interupt_action_melee_original = PlayerStandard._interupt_action_melee
local _do_action_intimidate_original = PlayerStandard._do_action_intimidate
local _check_action_primary_attack_original = PlayerStandard._check_action_primary_attack
local update_original = PlayerStandard.update

local TIMEOUT = 0.25

function PlayerStandard:update(t, ...)
	managers.hud:update_inspire_timer(self._ext_movement:morale_boost() and managers.enemy:get_delayed_clbk_expire_t(self._ext_movement:morale_boost().expire_clbk_id) - t or -1)
	return update_original(self, t, ...)
end

function PlayerStandard:_start_action_reload(t)
	_start_action_reload_original(self, t)
	if self._equipped_unit:base():can_reload() and managers.player:current_state() ~= "bleed_out" and SydneyHUD:GetOption("show_reload_interaction") then
		self._state_data._isReloading = true
		managers.hud:show_interaction_bar(0, self._state_data.reload_expire_t or 0)
		self._state_data.reload_offset = t
	end
end

function PlayerStandard:_update_reload_timers(t, dt, input)
	_update_reload_timers_original(self, t, dt, input)
	if SydneyHUD:GetOption("show_reload_interaction") then
		if not self._state_data.reload_expire_t and self._state_data._isReloading then
			managers.hud:hide_interaction_bar(true)
			self._state_data._isReloading = false
		elseif self._state_data._isReloading and managers.player:current_state() ~= "bleed_out" then
			managers.hud:set_interaction_bar_width(
				t and t - self._state_data.reload_offset or 0,
				self._state_data.reload_expire_t and self._state_data.reload_expire_t - self._state_data.reload_offset or 0
			)
		end
	end
end

function PlayerStandard:_interupt_action_reload(t)
	if self._state_data._isReloading and managers.player:current_state() ~= "bleed_out" and SydneyHUD:GetOption("show_reload_interaction") then
		managers.hud:hide_interaction_bar(false)
		self._state_data._isReloading = false
	end
	return _interupt_action_reload_original(self, t)
end

function PlayerStandard:_update_omniscience(t, dt)
	if managers.groupai:state():whisper_mode() then
		local action_forbidden = not managers.player:has_category_upgrade("player", "standstill_omniscience") or managers.player:current_state() == "civilian" or self:_interacting() or self._ext_movement:has_carry_restriction() or self:is_deploying() or self:_changing_weapon() or self:_is_throwing_grenade() or self:_is_meleeing() or self:_on_zipline() or self._moving or self:running() or self:_is_reloading() or self:in_air() or self:in_steelsight() or self:is_equipping() or self:shooting() or not tweak_data.player.omniscience
		if action_forbidden then
			if self._state_data.omniscience_t then
				--managers.player:set_buff_attribute("sixth_sense", "stack_count", 0)
				managers.player:deactivate_buff("sixth_sense")
				self._state_data.omniscience_t = nil
				self._state_data.omniscience_units_detected = {}
			end
			return
		end
		if not self._state_data.omniscience_t then
			managers.player:activate_timed_buff("sixth_sense", tweak_data.player.omniscience.start_t + 0.05)
			managers.player:set_buff_attribute("sixth_sense", "stack_count", 0)
			self._state_data.omniscience_t = t + tweak_data.player.omniscience.start_t
		end
		if t >= self._state_data.omniscience_t then
			local sensed_targets = World:find_units_quick("sphere", self._unit:movement():m_pos(), tweak_data.player.omniscience.sense_radius, World:make_slot_mask(12, 21, 33))
			self._state_data.omniscience_units_detected = self._state_data.omniscience_units_detected or {}
			managers.player:set_buff_attribute("sixth_sense", "stack_count", #sensed_targets, true)
			for _, unit in ipairs(sensed_targets) do
				if alive(unit) and not tweak_data.character[unit:base()._tweak_table].is_escort and not unit:anim_data().tied then
					if not self._state_data.omniscience_units_detected[unit:key()] or t >= self._state_data.omniscience_units_detected[unit:key()] then
						self._state_data.omniscience_units_detected[unit:key()] = t + tweak_data.player.omniscience.target_resense_t
						managers.game_play_central:auto_highlight_enemy(unit, true)
						--managers.player:set_buff_attribute("sixth_sense", "flash")
						break
					end
				end
			end
			self._state_data.omniscience_t = t + tweak_data.player.omniscience.interval_t
			managers.player:activate_timed_buff("sixth_sense", tweak_data.player.omniscience.interval_t + 0.05)
		end
	end
end

function PlayerStandard:_start_action_charging_weapon(...)
	managers.player:activate_buff("bow_charge")
	managers.player:set_buff_attribute("bow_charge", "progress", 0)
	return _start_action_charging_weapon_original(self, ...)
end

function PlayerStandard:_end_action_charging_weapon(...)
	managers.player:deactivate_buff("bow_charge")
	return _end_action_charging_weapon_original(self, ...)
end

function PlayerStandard:_update_charging_weapon_timers(...)
	if self._state_data.charging_weapon then
		local weapon = self._equipped_unit:base()
		if not weapon:charge_fail() then
			managers.player:set_buff_attribute("bow_charge", "progress", weapon:charge_multiplier())
		end
	end
	return _update_charging_weapon_timers_original(self, ...)
end

function PlayerStandard:_start_action_melee(...)
	managers.player:set_buff_attribute("melee_charge", "progress", 0)
	return _start_action_melee_original(self, ...)
end

function PlayerStandard:_update_melee_timers(t, ...)
	if self._state_data.meleeing and self._state_data.melee_start_t and self._state_data.melee_start_t + 0.3 < t then
		managers.player:activate_buff("melee_charge")
		managers.player:set_buff_attribute("melee_charge", "progress", self:_get_melee_charge_lerp_value(t))
	end
	if SydneyHUD:GetOption("show_melee_interaction") then
		if self._state_data.meleeing and not self._state_data.melee_attack_allowed_t and not tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].instant then
			if math.clamp(t - (self._state_data.melee_start_t or 0), 0, tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time) < 0.12 or self._state_data._at_max_melee then
			elseif math.clamp(t - (self._state_data.melee_start_t or 0), 0, tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time) >= tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time then
				managers.hud:hide_interaction_bar(true)
				self._state_data._at_max_melee = true
			elseif math.clamp(t - (self._state_data.melee_start_t or 0), 0, tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time) >= 0.12 and self._state_data._need_show_interact == nil then
				self._state_data._need_show_interact = true
			elseif self._state_data._need_show_interact then
				managers.hud:show_interaction_bar(0, tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time or 0)
				self._state_data._need_show_interact = false
			else
				managers.hud:set_interaction_bar_width(math.clamp(t - (self._state_data.melee_start_t or 0), 0, tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time), tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time)
			end
		end
	end
	return _update_melee_timers_original(self, t, ...)
end

function PlayerStandard:_do_melee_damage(t, ...)
	managers.player:deactivate_buff("melee_charge")
	if SydneyHUD:GetOption("show_melee_interaction") then
		managers.hud:hide_interaction_bar(false)
		self._state_data._need_show_interact = nil
		self._state_data._at_max_melee = nil
	end
	local result = _do_melee_damage_original(self, t, ...)
	if self._state_data.stacking_dmg_mul then
		local stack = self._state_data.stacking_dmg_mul.melee
		if stack then
			if stack[2] > 0 then
				managers.player:activate_timed_buff("melee_stack_damage", (stack[1] or 0) - t)
				managers.player:set_buff_attribute("melee_stack_damage", "stack_count", stack[2])
			else
				managers.player:deactivate_buff("melee_stack_damage")
			end
		end
	end
	return result
end

function PlayerStandard:_interupt_action_melee(...)
	if SydneyHUD:GetOption("show_melee_interaction") and self._state_data.meleeing then
		self._state_data._need_show_interact = nil
		self._state_data._at_max_melee = nil
		managers.hud:hide_interaction_bar(false)
	end
	_interupt_action_melee_original(self, ...)
end

function PlayerStandard:_do_action_intimidate(t, interact_type, ...)
	if interact_type == "cmd_gogo" or interact_type == "cmd_get_up" then
		managers.player:activate_timed_buff("inspire_debuff", self._ext_movement:rally_skill_data().morale_boost_cooldown_t or 3.5)
	end
	return _do_action_intimidate_original(self, t, interact_type, ...)
end

function PlayerStandard:_check_action_primary_attack(t, ...)
	local result = _check_action_primary_attack_original(self, t, ...)
	if self._state_data.stacking_dmg_mul then
		local weapon_category = self._equipped_unit:base():weapon_tweak_data().category
		local stack = self._state_data.stacking_dmg_mul[weapon_category]
		if stack then
			if stack[2] > 0 then
				managers.player:activate_timed_buff("trigger_happy", (stack[1] or 0) - t)
				managers.player:set_buff_attribute("trigger_happy", "stack_count", stack[2])
			else
				managers.player:deactivate_buff("trigger_happy")
			end
		end
	end
	return result
end

function PlayerStandard:_check_action_throw_grenade(t, input, ...)
	if input.btn_throw_grenade_press then
		if SydneyHUD:GetOption("anti_stealth_grenades") and managers.groupai:state():whisper_mode() and (t - (self._last_grenade_t or 0) >= TIMEOUT) then
			self._last_grenade_t = t
			return
		end
	end
	return _check_action_throw_grenade_original(self, t, input, ...)
end

function PlayerStandard:_check_action_interact(t, input, ...)
	if not (self:_check_interact_toggle(t, input) and SydneyHUD:GetOption("push_to_interact")) then
		return _check_action_interact_original(self, t, input, ...)
	end
end

function PlayerStandard:_check_interact_toggle(t, input)
	local interrupt_key_press = input.btn_interact_press
	if SydneyHUD:GetOption("equipment_interrupt") then
		interrupt_key_press = input.btn_use_item_press
	end
	if interrupt_key_press and self:_interacting() then
		self:_interupt_action_interact()
		return true
	elseif input.btn_interact_release and self._interact_params then
		return true
	end
end

Hooks:PostHook(PlayerStandard, "_update_fwd_ray", "uHUDPostPlayerStandardUpdateFwdRay", function(self)
	if self._last_unit then
		local iAngle = 360
		local cAngle = 360
		iAngle = self:getUnitRotation(self._last_unit)
		if iAngle then
			cAngle = cAngle + (iAngle - cAngle)
			if cAngle == 0 then cAngle = 360 end
			managers.hud:set_unit_health_rotation(cAngle)
		end
	end

	if self._fwd_ray and self._fwd_ray.unit then
		local unit = self._fwd_ray.unit
		if unit:in_slot(8) and alive(unit:parent()) then
			unit = unit:parent()
		end
		if managers.groupai:state():turrets() then
			for _, t_unit in pairs(managers.groupai:state():turrets()) do
				if alive(t_unit) and t_unit:movement():team().foes[managers.player:player_unit():movement():team().id] and unit == t_unit then
					unit = t_unit
				end
			end
		end
		if alive(unit) and unit:character_damage() and not unit:character_damage()._dead and not managers.enemy:is_civilian(unit) and managers.enemy:is_enemy(unit) and unit:base() and unit:base()._tweak_table then
			self._last_unit = unit
			managers.hud:set_unit_health_visible(true)
			managers.hud:set_unit_health(unit:character_damage()._health or 0, unit:character_damage()._HEALTH_INIT or 0, unit:base()._tweak_table or "cop")
		else
			if self._last_unit and alive(self._last_unit) then
				managers.hud:set_unit_health(self._last_unit:character_damage()._health or 0, self._last_unit:character_damage()._HEALTH_INIT or 0, self._last_unit:base()._tweak_table or "cop")
				managers.hud:set_unit_health_visible(false)
				return
			end
		end
	else
		if self._last_unit and alive(self._last_unit) then
			managers.hud:set_unit_health(self._last_unit:character_damage()._health or 0, self._last_unit:character_damage()._HEALTH_INIT or 0, self._last_unit:base()._tweak_table or "cop")
			managers.hud:set_unit_health_visible(false)
			return
		end
	end
end)

function PlayerStandard:getUnitRotation(unit)
	if not unit or not alive(unit) then return 360 end
	local unit_position = unit:position()
	local vector = self._camera_unit:position() - unit_position
	local forward = self._camera_unit:rotation():y()
	local rotation = math.floor(vector:to_polar_with_reference(forward, math.UP).spin)
	return -(rotation + 180)
end