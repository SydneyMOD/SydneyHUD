
local spawned_player_original = PlayerManager.spawned_player
local disable_cooldown_upgrade_original = PlayerManager.disable_cooldown_upgrade
local activate_temporary_upgrade_original = PlayerManager.activate_temporary_upgrade
local activate_temporary_upgrade_by_level_original = PlayerManager.activate_temporary_upgrade_by_level
local deactivate_temporary_upgrade_original = PlayerManager.deactivate_temporary_upgrade
local count_up_player_minions_original = PlayerManager.count_up_player_minions
local count_down_player_minions_original = PlayerManager.count_down_player_minions
local update_hostage_skills_original = PlayerManager.update_hostage_skills
local set_melee_dmg_multiplier_original = PlayerManager.set_melee_dmg_multiplier
local on_killshot_original = PlayerManager.on_killshot
local aquire_team_upgrade_original = PlayerManager.aquire_team_upgrade
local unaquire_team_upgrade_original = PlayerManager.unaquire_team_upgrade
local add_synced_team_upgrade_original = PlayerManager.add_synced_team_upgrade
local peer_dropped_out_original = PlayerManager.peer_dropped_out
local on_headshot_dealt_original = PlayerManager.on_headshot_dealt
local _on_messiah_recharge_event_original = PlayerManager._on_messiah_recharge_event
local use_messiah_charge_original = PlayerManager.use_messiah_charge
local mul_to_property_original = PlayerManager.mul_to_property
local set_property_original = PlayerManager.set_property
local remove_property_original = PlayerManager.remove_property
local add_to_temporary_property_original = PlayerManager.add_to_temporary_property
local chk_wild_kill_counter_original = PlayerManager.chk_wild_kill_counter
local set_synced_cocaine_stacks_original = PlayerManager.set_synced_cocaine_stacks
local activate_ability_original = PlayerManager.activate_ability
local speed_up_ability_cooldown_original = PlayerManager.speed_up_ability_cooldown
local has_enabled_cooldown_upgrade_original = PlayerManager.has_enabled_cooldown_upgrade

local PLAYER_HAS_SPAWNED = false
function PlayerManager:spawned_player(id, ...)
	spawned_player_original(self, id, ...)

	if id == 1 then
		if not PLAYER_HAS_SPAWNED then
			PLAYER_HAS_SPAWNED = true

			for category, data in pairs(self._global.team_upgrades) do
				for upgrade, value in pairs(data) do
					local value = self:team_upgrade_value(category, upgrade, 0)
					managers.gameinfo:event("team_buff", "activate", { peer = 0, category = category, upgrade = upgrade, value = value })
				end
			end
		end

		if self:has_category_upgrade("player", "messiah_revive_from_bleed_out") and (self._messiah_charges or 0) > 0 then
			managers.gameinfo:event("buff", "activate", "messiah")
			managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
		end

		self._is_sociopath = self:has_category_upgrade("player", "killshot_regen_armor_bonus") or
				self:has_category_upgrade("player", "killshot_close_regen_armor_bonus") or
				self:has_category_upgrade("player", "killshot_close_panic_chance") or
				self:has_category_upgrade("player", "melee_kill_life_leech")
	end
end

function PlayerManager:disable_cooldown_upgrade(category, upgrade, ...)
	disable_cooldown_upgrade_original(self, category, upgrade, ...)

	if self._global.cooldown_upgrades[category] and self._global.cooldown_upgrades[category][upgrade] then
		local t = Application:time()
		local expire_t = self._global.cooldown_upgrades[category][upgrade].cooldown_time

		if expire_t > t then
			managers.gameinfo:event("temporary_buff", "activate", { t = t, expire_t = expire_t, category = category, upgrade = upgrade })
		end
	end
end

function PlayerManager:activate_temporary_upgrade(category, upgrade, ...)
	activate_temporary_upgrade_original(self, category, upgrade, ...)

	if self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade] then
		local t = Application:time()
		local expire_t = self._temporary_upgrades[category][upgrade].expire_time
		local level
		local upgrade_level = self:upgrade_level(category, upgrade, 0)
		if upgrade_level > 0 then
			level = upgrade_level
		end
		local value = self:temporary_upgrade_value(category, upgrade, 0)

		if expire_t > t then
			managers.gameinfo:event("temporary_buff", "activate", { t = t, expire_t = expire_t, category = category, upgrade = upgrade, level = level, value = value })
		end
	end
end

function PlayerManager:activate_temporary_upgrade_by_level(category, upgrade, level, ...)
	activate_temporary_upgrade_by_level_original(self, category, upgrade, level, ...)

	if self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade] then
		local t = Application:time()
		local expire_t = self._temporary_upgrades[category][upgrade].expire_time
		local value = self:temporary_upgrade_value(category, upgrade, 0)
		if expire_t > t then
			managers.gameinfo:event("temporary_buff", "activate", { t = t, expire_t = expire_t, category = category, upgrade = upgrade, level = level, value = value })
		end
	end
end

function PlayerManager:deactivate_temporary_upgrade(category, upgrade, ...)
	if self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade] then
		managers.gameinfo:event("temporary_buff", "deactivate", { category = category, upgrade = upgrade })
	end

	return deactivate_temporary_upgrade_original(self, category, upgrade, ...)
end

function PlayerManager:count_up_player_minions(...)
	local result = count_up_player_minions_original(self, ...)
	if self._local_player_minions > 0 then
		if self:has_category_upgrade("player", "minion_master_speed_multiplier") then
			managers.gameinfo:event("buff", "activate", "partner_in_crime")
		end
		if self:has_category_upgrade("player", "minion_master_health_multiplier") then
			managers.gameinfo:event("buff", "activate", "partner_in_crime_aced")
		end
	end
	return result
end

function PlayerManager:count_down_player_minions(...)
	local result = count_down_player_minions_original(self, ...)
	if self._local_player_minions <= 0 then
		managers.gameinfo:event("buff", "deactivate", "partner_in_crime")
		managers.gameinfo:event("buff", "deactivate", "partner_in_crime_aced")
	end
	return result
end

function PlayerManager:update_hostage_skills(...)
	local hostages = managers.groupai and managers.groupai:state():hostage_count() or 0
	local minions = self:num_local_minions() or 0
	local stack_count = hostages + minions

	if self:has_team_category_upgrade("health", "hostage_multiplier") or self:has_team_category_upgrade("stamina", "hostage_multiplier") or self:has_team_category_upgrade("damage_dampener", "hostage_multiplier") then
		if stack_count > 0 then
			local value = self:team_upgrade_value("damage_dampener", "hostage_multiplier", 0)
			managers.gameinfo:event("buff", "activate", "hostage_situation")
			managers.gameinfo:event("buff", "set_stack_count", "hostage_situation", { stack_count = stack_count })
			if value ~= 0 then
				managers.gameinfo:event("buff", "set_value", "hostage_situation", { value = value })
			end
		else
			managers.gameinfo:event("buff", "deactivate", "hostage_situation")
		end
	end

	if self:has_category_upgrade("player", "hostage_health_regen_addend") then
		if stack_count > 0 then
			managers.gameinfo:event("buff", "activate", "hostage_taker")
			--managers.gameinfo:event("buff", "set_stack_count", "hostage_taker", { stack_count = stack_count })
		else
			managers.gameinfo:event("buff", "deactivate", "hostage_taker")
		end
	end

	return update_hostage_skills_original(self, ...)
end

function PlayerManager:set_melee_dmg_multiplier(...)
	local old_mult = self._melee_dmg_mul
	set_melee_dmg_multiplier_original(self, ...)
	if old_mult ~= self._melee_dmg_mul then
		managers.gameinfo:event("buff", "change_stack_count", "bloodthirst_basic", { difference = 1 })
	end
	managers.gameinfo:event("buff", "set_value", "bloodthirst_basic", { value = self._melee_dmg_mul })
end

function PlayerManager:on_killshot(...)
	local last_killshot = self._on_killshot_t
	local result = on_killshot_original(self, ...)

	if self._is_sociopath and self._on_killshot_t ~= last_killshot then
		managers.gameinfo:event("timed_buff", "activate", "sociopath_debuff", { expire_t = self._on_killshot_t })
	end

	return result
end

function PlayerManager:aquire_team_upgrade(upgrade, ...)
	aquire_team_upgrade_original(self, upgrade, ...)
	local value = self:team_upgrade_value(upgrade.category, upgrade.upgrade, 0)
	managers.gameinfo:event("team_buff", "activate", { peer = 0, category = upgrade.category, upgrade = upgrade.upgrade, value = value })
end

function PlayerManager:unaquire_team_upgrade(upgrade, ...)
	unaquire_team_upgrade_original(self, upgrade, ...)
	managers.gameinfo:event("team_buff", "deactivate", { peer = 0, category = upgrade.category, upgrade = upgrade.upgrade })
end

function PlayerManager:add_synced_team_upgrade(peer_id, category, upgrade, ...)
	add_synced_team_upgrade_original(self, peer_id, category, upgrade, ...)

	local value = self:team_upgrade_value(category, upgrade, 0)
	managers.gameinfo:event("team_buff", "activate", { peer = peer_id, category = category, upgrade = upgrade, value = value })
end

function PlayerManager:peer_dropped_out(peer, ...)
	local peer_id = peer:id()

	for category, data in pairs(self._global.synced_team_upgrades[peer_id] or {}) do
		for upgrade, value in pairs(data) do
			managers.gameinfo:event("team_buff", "deactivate", { peer = peer_id, category = category, upgrade = upgrade })
		end
	end

	return peer_dropped_out_original(self, peer, ...)
end

function PlayerManager:on_headshot_dealt(...)
	local t = Application:time()
	if (self._on_headshot_dealt_t or 0) <= t and self:has_category_upgrade("player", "headshot_regen_armor_bonus") then
		managers.gameinfo:event("timed_buff", "activate", "bullseye_debuff", { t = t, duration = tweak_data.upgrades.on_headshot_dealt_cooldown or 0 })
	end

	return on_headshot_dealt_original(self, ...)
end

function PlayerManager:_on_messiah_recharge_event(...)
	_on_messiah_recharge_event_original(self, ...)

	if self._messiah_charges > 0 then
		managers.gameinfo:event("buff", "activate", "messiah")
		managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
	else
		managers.gameinfo:event("buff", "deactivate", "messiah")
	end
end

function PlayerManager:use_messiah_charge(...)
	use_messiah_charge_original(self, ...)

	if self._messiah_charges > 0 then
		managers.gameinfo:event("buff", "activate", "messiah")
		managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
	else
		managers.gameinfo:event("buff", "deactivate", "messiah")
	end
end

function PlayerManager:mul_to_property(name, value, ...)
	mul_to_property_original(self, name, value, ...)
	managers.gameinfo:event("buff", "change_stack_count", name, { difference = 1 })
	managers.gameinfo:event("buff", "set_value", name, { value = self:get_property(name, 1) })
end

function PlayerManager:set_property(name, value, ...)
	set_property_original(self, name, value, ...)

	if name == "revive_damage_reduction" then
		managers.gameinfo:event("buff", "activate", "combat_medic_passive")
		managers.gameinfo:event("buff", "set_value", "combat_medic_passive", { value = value })
	end
end

function PlayerManager:remove_property(name, ...)
	remove_property_original(self, name, ...)

	if name == "revive_damage_reduction" then
		managers.gameinfo:event("buff", "deactivate", "combat_medic_passive")
	end
end

function PlayerManager:add_to_temporary_property(name, time, ...)
	add_to_temporary_property_original(self, name, time, ...)

	if name == "bullet_storm" then
		local t = self._temporary_properties._properties[name][2]
		managers.gameinfo:event("timed_buff", "activate", name, { expire_t = t })
	end
end

function PlayerManager:chk_wild_kill_counter(...)
	local t = Application:time()
	local player = self:player_unit()
	local expire_t

	if alive(player) and (managers.player:has_category_upgrade("player", "wild_health_amount") or managers.player:has_category_upgrade("player", "wild_armor_amount")) then
		local dmg = player:character_damage()
		local missing_health_ratio = math.clamp(1 - dmg:health_ratio(), 0, 1)
		local missing_armor_ratio = math.clamp(1 - dmg:armor_ratio(), 0, 1)
		local less_armor_wild_cooldown = managers.player:upgrade_value("player", "less_armor_wild_cooldown", 0)
		local less_health_wild_cooldown = managers.player:upgrade_value("player", "less_health_wild_cooldown", 0)
		local trigger_cooldown = tweak_data.upgrades.wild_trigger_time or 30

		if less_health_wild_cooldown ~= 0 and less_health_wild_cooldown[1] ~= 0 then
			local missing_health_stacks = math.floor(missing_health_ratio / less_health_wild_cooldown[1])
			trigger_cooldown = trigger_cooldown - less_health_wild_cooldown[2] * missing_health_stacks
		end
		if less_armor_wild_cooldown ~= 0 and less_armor_wild_cooldown[1] ~= 0 then
			local missing_armor_stacks = math.floor(missing_armor_ratio / less_armor_wild_cooldown[1])
			trigger_cooldown = trigger_cooldown - less_armor_wild_cooldown[2] * missing_armor_stacks
		end

		expire_t = t + math.max(trigger_cooldown, 0)
	end

	local old_stacks = 0
	if self._wild_kill_triggers then
		old_stacks = #self._wild_kill_triggers
		for i = 1, #self._wild_kill_triggers, 1 do
			if self._wild_kill_triggers[i] > t then
				break
			end
			old_stacks = old_stacks - 1
		end
	end

	chk_wild_kill_counter_original(self, ...)

	if self._wild_kill_triggers and #self._wild_kill_triggers > old_stacks then
		managers.gameinfo:event("timed_stack_buff", "add_stack", "biker", { t = t, expire_t = expire_t })
	end
end

function PlayerManager:set_synced_cocaine_stacks(...)
	set_synced_cocaine_stacks_original(self, ...)

	local max_stack = 0
	for peer_id, data in pairs(self._global.synced_cocaine_stacks) do
		if data.in_use and data.amount > max_stack then
			max_stack = data.amount
		end
	end

	local ratio = max_stack / tweak_data.upgrades.max_total_cocaine_stacks
	if ratio > 0 then
		managers.gameinfo:event("buff", "activate", "maniac")
		managers.gameinfo:event("buff", "set_value", "maniac", { value = string.format("%.0f%%", ratio*100), show_value = true } )
	else
		managers.gameinfo:event("buff", "deactivate", "maniac")
	end
end

function PlayerManager:activate_ability(ability, ...)
	activate_ability_original(self, ability, ...)

	if self["_cooldown_" .. ability] then
		local t = TimerManager:game():time()
		local duration = self["_cooldown_" .. ability] - t
		managers.gameinfo:event("timed_buff", "activate", ability .. "_debuff", { duration = duration })
	end
end

function PlayerManager:speed_up_ability_cooldown(ability, time, ...)
	speed_up_ability_cooldown_original(self, ability, time, ...)

	if self["_cooldown_" .. ability] then
		managers.gameinfo:event("timed_buff", "decrease_duration", ability .. "_debuff", { decrease = time })
	end
end

if SydneyHUD:GetOption("inspire_ace_chat_info") then
	function PlayerManager:has_enabled_cooldown_upgrade(category, upgrade)
		if category == "cooldown" and upgrade == "long_dis_revive" then
			if self._global.cooldown_upgrades[category][upgrade] then
				local remaining = self._global.cooldown_upgrades[category][upgrade].cooldown_time - Application:time()
				if remaining > 0 then
					local text = string.format("%.1f sec", remaining)
					SydneyHUD:SendChatMessage(managers.localization:text("inspire_ace_chat_info"), text, false, "FF9800")
				end
			end
		end
		return has_enabled_cooldown_upgrade_original(self, category, upgrade)
	end
end