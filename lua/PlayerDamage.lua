
local init_original = PlayerDamage.init
local add_damage_to_hot_original = PlayerDamage.add_damage_to_hot
local set_health_original = PlayerDamage.set_health
local _upd_health_regen_original = PlayerDamage._upd_health_regen
local _start_regen_on_the_side_original = PlayerDamage._start_regen_on_the_side
local _regenerate_armor_original = PlayerDamage._regenerate_armor
local _update_armor_grinding_original = PlayerDamage._update_armor_grinding
local _on_damage_armor_grinding_original = PlayerDamage._on_damage_armor_grinding
local change_regenerate_speed_original = PlayerDamage.change_regenerate_speed
local build_suppression_original = PlayerDamage.build_suppression
local set_armor_original = PlayerDamage.set_armor
local _check_bleed_out_original = PlayerDamage._check_bleed_out
local update_original = PlayerDamage.update
local change_health_original = PlayerDamage.change_health

local HEALTH_RATIO_BONUSES = {
	melee_damage_health_ratio_multiplier = { category = "melee", buff_id = "berserker" },
	damage_health_ratio_multiplier = { category = "damage", buff_id = "berserker_aced" },
	armor_regen_damage_health_ratio_multiplier = { category = "armor_regen", buff_id = "yakuza_recovery" },
	movement_speed_damage_health_ratio_multiplier = { category = "movement_speed", buff_id = "yakuza_speed" },
}
local LAST_HEALTH_RATIO = 0
local LAST_ARMOR_REGEN_BUFF_RESET = 0
local LAST_CHECK_T = 0
local ARMOR_GRIND_ACTIVE = false

function PlayerDamage:change_health(change_of_health)
	managers.hud:change_health(math.max(0, change_of_health or 0))
	return change_health_original(self, change_of_health)
end

function PlayerDamage:update(...)
	update_original(self, ...)
	managers.hud:update_armor_timer(self._regenerate_timer or 0)
end

function PlayerDamage:init(...)
	init_original(self, ...)

	if managers.player:has_category_upgrade("player", "damage_to_armor") then
		local function on_damage(dmg_info)
			if self._unit == dmg_info.attacker_unit then
				local t = Application:time()
				if (self._damage_to_armor.elapsed == t) or (t - self._damage_to_armor.elapsed > self._damage_to_armor.target_tick) then
					managers.gameinfo:event("timed_buff", "activate", "anarchist_armor_recovery_debuff", { t = t, duration = self._damage_to_armor.target_tick })
				end
			end
		end

		CopDamage.register_listener("anarchist_debuff_listener", {"on_damage"}, on_damage)
	end

	self._listener_holder:add("custom_on_damage", { "on_damage" }, callback(self, self, "_custom_on_damage_clbk"))
end

function PlayerDamage:add_damage_to_hot(...)
	local num_old_stacks = #self._damage_to_hot_stack or 0

	add_damage_to_hot_original(self, ...)

	local num_new_stacks = #self._damage_to_hot_stack or 0

	if num_new_stacks > num_old_stacks then
		local stack_duration = ((self._doh_data.total_ticks or 1) + managers.player:upgrade_value("player", "damage_to_hot_extra_ticks", 0)) * (self._doh_data.tick_time or 1)
		managers.gameinfo:event("timed_buff", "activate", "grinder_debuff", { duration = tweak_data.upgrades.damage_to_hot_data.stacking_cooldown })
		managers.gameinfo:event("timed_stack_buff", "add_stack", "grinder", { duration = stack_duration })
	end
end

function PlayerDamage:set_health(...)
	set_health_original(self, ...)

	local health_ratio = self:health_ratio()

	if health_ratio ~= LAST_HEALTH_RATIO then
		LAST_HEALTH_RATIO = health_ratio

		for upgrade, data in pairs(HEALTH_RATIO_BONUSES) do
			if managers.player:has_category_upgrade("player", upgrade) then
				local bonus_ratio = managers.player:get_damage_health_ratio(health_ratio, data.category)
				if bonus_ratio > 0 then
					managers.gameinfo:event("buff", "activate", data.buff_id)
					managers.gameinfo:event("buff", "set_value", data.buff_id, { value = bonus_ratio, show_value = true })
				else
					managers.gameinfo:event("buff", "deactivate", data.buff_id)
				end
			end
		end

		if managers.player:has_category_upgrade("player", "passive_damage_reduction") then
			local threshold = managers.player:upgrade_value("player", "passive_damage_reduction")
			local value = managers.player:team_upgrade_value("damage_dampener", "team_damage_reduction")
			if health_ratio < threshold then
				value = 2 * value - 1
			end
			managers.gameinfo:event("buff", "set_value", "crew_chief_1", { value = value })
		end
	end
end

function PlayerDamage:_upd_health_regen(t, ...)
	local old_timer = self._health_regen_update_timer

	local result = _upd_health_regen_original(self, t, ...)

	if self._health_regen_update_timer then
		if self._health_regen_update_timer > (old_timer or 0) and self:health_ratio() < 1 then
			--TODO: Muscle regen?
			managers.gameinfo:event("buff", "set_duration", "hostage_taker", { duration = self._health_regen_update_timer })
		end
	end
end

function PlayerDamage:_start_regen_on_the_side(time, ...)
	if not self._regen_on_the_side and time > 0 then
		managers.gameinfo:event("timed_buff", "activate", "tooth_and_claw", { duration = time })
	end

	return _start_regen_on_the_side_original(self, time, ...)
end

function PlayerDamage:_update_armor_grinding(t, ...)
	_update_armor_grinding_original(self, t, ...)

	if self._armor_grinding.elapsed == 0 and ARMOR_GRIND_ACTIVE then
		managers.gameinfo:event("player_action", "set_duration", "anarchist_armor_regeneration", { duration = self._armor_grinding.target_tick })
	end
end

function PlayerDamage:_on_damage_armor_grinding(...)
	if not ARMOR_GRIND_ACTIVE then
		local t = Application:time() - (self._armor_grinding.elapsed or 0)
		managers.gameinfo:event("player_action", "activate", "anarchist_armor_regeneration")
		managers.gameinfo:event("player_action", "set_duration", "anarchist_armor_regeneration", { t = t, duration = self._armor_grinding.target_tick })
		ARMOR_GRIND_ACTIVE = true
	end
	return _on_damage_armor_grinding_original(self, ...)
end

function PlayerDamage:change_regenerate_speed(...)
	change_regenerate_speed_original(self, ...)
	self:_check_armor_regen_timer()
end

function PlayerDamage:build_suppression(...)
	build_suppression_original(self, ...)
	if self:get_real_armor() < self:_max_armor() then
		LAST_ARMOR_REGEN_BUFF_RESET = Application:time()
		self:_check_armor_regen_timer()
	end
end

function PlayerDamage:set_armor(armor, ...)
	set_armor_original(self, armor, ...)

	if armor >= self:_total_armor() then
		ARMOR_GRIND_ACTIVE = false
		managers.gameinfo:event("player_action", "deactivate", "anarchist_armor_regeneration")
		managers.gameinfo:event("player_action", "deactivate", "standard_armor_regeneration")
	end
end

function PlayerDamage:_check_bleed_out(...)
	local last_uppers = self._uppers_elapsed or 0

	local result = _check_bleed_out_original(self, ...)

	if (self._uppers_elapsed or 0) > last_uppers then
		managers.gameinfo:event("timed_buff", "activate", "uppers_debuff", { duration = self._UPPERS_COOLDOWN })
	end
end


function PlayerDamage:_custom_on_damage_clbk()
	if not self:is_downed() then
		LAST_ARMOR_REGEN_BUFF_RESET = Application:time()
		self:_check_armor_regen_timer()
	end
end

function PlayerDamage:_check_armor_regen_timer()
	if self._regenerate_timer then
		local t = managers.player:player_timer():time()
		local duration = self._regenerate_timer / (self._regenerate_speed or 1)

		if self._supperssion_data.decay_start_t and self._supperssion_data.decay_start_t > t then
			duration = duration + (self._supperssion_data.decay_start_t - t)
		end

		if duration > 0 and t > LAST_CHECK_T then
			LAST_CHECK_T = t
			managers.gameinfo:event("player_action", "activate", "standard_armor_regeneration")
			managers.gameinfo:event("player_action", "set_duration", "standard_armor_regeneration", { t = LAST_ARMOR_REGEN_BUFF_RESET, duration = duration })
		end
	end
end