
local set_health_original = PlayerDamage.set_health
local _damage_screen_original = PlayerDamage._damage_screen
local build_suppression_original = PlayerDamage.build_suppression
local restore_armor_original = PlayerDamage.restore_armor
local _upd_health_regen_original = PlayerDamage._upd_health_regen
local add_damage_to_hot_original = PlayerDamage.add_damage_to_hot
local update_original = PlayerDamage.update
local change_health_original = PlayerDamage.change_health

PlayerDamage._ARMOR_REGEN_TABLE = {
	[tweak_data.upgrades.values.player.headshot_regen_armor_bonus[1] ] = "bullseye_debuff",
	[tweak_data.upgrades.values.player.killshot_regen_armor_bonus[1] ] = "tension_debuff",
	[tweak_data.upgrades.values.player.headshot_regen_armor_bonus[2] ] = "bullseye_debuff",
	[tweak_data.upgrades.values.player.killshot_regen_armor_bonus[1] + tweak_data.upgrades.values.player.killshot_close_regen_armor_bonus[1] ] = "tension_debuff",
}

function PlayerDamage:change_health(change_of_health)
	managers.hud:change_health(math.max(0, change_of_health or 0))
	return change_health_original(self, change_of_health)
end

function PlayerDamage:update(...)
	update_original(self, ...)
	managers.hud:update_armor_timer(self._regenerate_timer or 0)
end

function PlayerDamage:set_health(...)
	set_health_original(self, ...)

	local threshold = tweak_data.upgrades.player_damage_health_ratio_threshold
	local ratio = self:health_ratio()
	if managers.player:has_category_upgrade("player", "melee_damage_health_ratio_multiplier") then
		if ratio <= threshold then
			managers.player:activate_buff("berserker")
			managers.player:set_buff_attribute("berserker", "progress", 1 - ratio / math.max(0.01, threshold))
			managers.player:set_buff_attribute("berserker", "aced", managers.player:has_category_upgrade("player", "damage_health_ratio_multiplier"), true)
		else
			managers.player:deactivate_buff("berserker")
		end
	end
end

function PlayerDamage:_damage_screen(...)
	_damage_screen_original(self, ...)
	local delay = (self._regenerate_timer or 0) + (self._supperssion_data.decay_start_t and (self._supperssion_data.decay_start_t - managers.player:player_timer():time()) or 0)
	managers.player:activate_timed_buff("armor_regen_debuff", delay)
end

function PlayerDamage:build_suppression(amount, ...)
	if not self:_chk_suppression_too_soon(amount) then
		build_suppression_original(self, amount, ...)
		if self._supperssion_data.value > 0 then
			managers.player:activate_timed_buff("suppression_debuff", tweak_data.player.suppression.decay_start_delay + self._supperssion_data.value)
		end
		if self._supperssion_data.value == tweak_data.player.suppression.max_value then
			if self:get_real_armor() < self:_total_armor() then
				managers.player:refresh_timed_buff("armor_regen_debuff")
			end
		end
	end
end

function PlayerDamage:restore_armor(armor_regen, ...)
	restore_armor_original(self, armor_regen, ...)
	local buff = PlayerDamage._ARMOR_REGEN_TABLE[armor_regen]
	if buff then
		local cooldown_key = buff == "bullseye_debuff" and "on_headshot_dealt_cooldown" or "on_killshot_cooldown"
		managers.player:activate_timed_buff(buff, tweak_data.upgrades[cooldown_key])
	end
	if self:get_real_armor() >= self:_total_armor() then
		managers.player:deactivate_buff("armor_regen_debuff")
	end
end

function PlayerDamage:_upd_health_regen(...)
	local old_stack_count = #self._damage_to_hot_stack
	_upd_health_regen_original(self, ...)
	if #self._damage_to_hot_stack ~= old_stack_count then
		managers.player:set_buff_attribute("damage_to_hot", "stack_count", #self._damage_to_hot_stack)
	end
end

function PlayerDamage:add_damage_to_hot(...)
	if not (self:got_max_doh_stacks() or self:need_revive() or self:dead() or self._check_berserker_done) then
		local duration = ((self._doh_data.total_ticks or 1) + managers.player:upgrade_value("player", "damage_to_hot_extra_ticks", 0)) * self._doh_data.tick_time
		local stacks = (#self._damage_to_hot_stack or 0) + 1
		managers.player:activate_timed_buff("damage_to_hot_debuff", tweak_data.upgrades.damage_to_hot_data.stacking_cooldown)
		managers.player:activate_timed_buff("damage_to_hot", duration)
		managers.player:set_buff_attribute("damage_to_hot", "stack_count", stacks)
	end
	return add_damage_to_hot_original(self, ...)
end
