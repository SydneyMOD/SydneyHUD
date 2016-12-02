
local init_original = PlayerManager.init
local update_original = PlayerManager.update
local count_up_player_minions_original = PlayerManager.count_up_player_minions
local count_down_player_minions_original = PlayerManager.count_down_player_minions
local update_hostage_skills_original = PlayerManager.update_hostage_skills
local activate_temporary_upgrade_original = PlayerManager.activate_temporary_upgrade
local activate_temporary_upgrade_by_level_original = PlayerManager.activate_temporary_upgrade_by_level
local deactivate_temporary_upgrade_original = PlayerManager.deactivate_temporary_upgrade
local aquire_team_upgrade_original = PlayerManager.aquire_team_upgrade
local unaquire_team_upgrade_original = PlayerManager.unaquire_team_upgrade
local add_synced_team_upgrade_original = PlayerManager.add_synced_team_upgrade
local peer_dropped_out_original = PlayerManager.peer_dropped_out

PlayerManager._CHECK_BUFF_ACED = {
	overkill = function() return managers.player:has_category_upgrade("player", "overkill_all_weapons") end,
	pain_killer = function(level) return (level and level > 1) end,
	swan_song = function() return managers.player:has_category_upgrade("player", "berserker_no_ammo_cost") end,
}

PlayerManager._TEAM_BUFFS = {
	damage_dampener = {
		hostage_multiplier =  "crew_chief_9",
	},
	stamina = {
		multiplier = "endurance",
		passive_multiplier = "crew_chief_3",
		hostage_multiplier =  "crew_chief_9",
	},
	health = {
		passive_multiplier = "crew_chief_5",
		hostage_multiplier = "crew_chief_9",
	},
	armor = {
		multiplier =  "crew_chief_7",
		regen_time_multiplier = "bulletproof",
		passive_regen_time_multiplier = "armorer",
	},
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
}

PlayerManager._TEMPORARY_BUFFS = {
	dmg_multiplier_outnumbered = "underdog",
	dmg_dampener_outnumbered = "underdog_aced",
	dmg_dampener_outnumbered_strong = "overdog",
	dmg_dampener_close_contact = "close_combat",
	combat_medic_damage_multiplier = "combat_medic",
	overkill_damage_multiplier = "overkill",
	no_ammo_cost = "bullet_storm",
	passive_revive_damage_reduction = "pain_killer",
	berserker_damage_multiplier = "swan_song",
	first_aid_damage_reduction = "quick_fix",
	melee_life_leech = "life_drain",
	loose_ammo_restore_health = "medical_supplies",
	loose_ammo_give_team = "ammo_give_out",
}

PlayerManager.ACTIVE_TEAM_BUFFS = {}
PlayerManager.ACTIVE_BUFFS = {}
PlayerManager._LISTENER_CALLBACKS = {}

function PlayerManager:init(...)
	init_original(self, ...)
	for category, data in pairs(self._global.team_upgrades) do
		for upgrade, _ in pairs(data) do
			local buff = PlayerManager._TEAM_BUFFS[category] and PlayerManager._TEAM_BUFFS[category][upgrade]
			if buff then
				self:activate_team_buff(buff, 0)
			--else
				--DEBUG_PRINT("warnings", "Attempting to activate undefined local team buff: " .. tostring(category) .. ", " .. tostring(upgrade) .. "\n")
			end
		end
	end
end

function PlayerManager:update(t, dt, ...)
	update_original(self, t, dt, ...)
	local expired_buffs = {}
	for buff, data in pairs(PlayerManager.ACTIVE_BUFFS) do
		if data.timed then
			if data.expire_t <= t then
				table.insert(expired_buffs, buff)
			else
				self:set_buff_attribute(buff, "progress", 1 - (t - data.activation_t) / data.duration)
			end
		end
	end
	for _, buff in ipairs(expired_buffs) do
		self:deactivate_buff(buff)
	end
	self._t = t
end

function PlayerManager:count_up_player_minions(...)
	local result = count_up_player_minions_original(self, ...)
	if self._local_player_minions > 0 and self:has_category_upgrade("player", "minion_master_speed_multiplier") then
		self:activate_buff("partner_in_crime")
		self:set_buff_attribute("partner_in_crime", "aced", self:has_category_upgrade("player", "minion_master_health_multiplier"))
	end
	return result
end

function PlayerManager:count_down_player_minions(...)
	local result = count_down_player_minions_original(self, ...)
	if self._local_player_minions <= 0 then
		self:deactivate_buff("partner_in_crime")
	end
	return result
end

function PlayerManager:update_hostage_skills(...)
	local stack_count = (managers.groupai and managers.groupai:state():hostage_count() or 0) + (self:num_local_minions() or 0)
	if self:has_team_category_upgrade("health", "hostage_multiplier") or self:has_team_category_upgrade("stamina", "hostage_multiplier") or self:has_team_category_upgrade("damage_dampener", "hostage_multiplier") then
		self:set_buff_active("hostage_situation", stack_count > 0)
		self:set_buff_attribute("hostage_situation", "stack_count", stack_count)
	end
	if self:has_category_upgrade("player", "hostage_health_regen_addend") then
		self:set_buff_active("hostage_taker", stack_count > 0)
		self:set_buff_attribute("hostage_taker", "aced", self:upgrade_level("player", "hostage_health_regen_addend", 0) > 1)
	end
	return update_hostage_skills_original(self, ...)
end

function PlayerManager:activate_temporary_upgrade(category, upgrade, ...)
	local upgrade_value = self:upgrade_value(category, upgrade)
	if upgrade_value ~= 0 then
		local buff = PlayerManager._TEMPORARY_BUFFS[upgrade]
		if buff then
			self:activate_timed_buff(buff, upgrade_value[2])
			local check_aced = PlayerManager._CHECK_BUFF_ACED[buff]
			if check_aced then
				self:set_buff_attribute(buff, "aced", check_aced() or false)
			end
		--else
			--DEBUG_PRINT("warnings", "Attempting to activate undefined buff: " .. tostring(category) .. ", " .. tostring(upgrade) .. "\n")
		end
	end
	return activate_temporary_upgrade_original(self, category, upgrade, ...)
end

function PlayerManager:activate_temporary_upgrade_by_level(category, upgrade, level, ...)
	local upgrade_level = self:upgrade_level(category, upgrade, 0) or 0
	if level > upgrade_level then
		local upgrade_value = self:upgrade_value_by_level(category, upgrade, level, 0)
		if upgrade_value ~= 0 then
			local buff = PlayerManager._TEMPORARY_BUFFS[upgrade]
			if buff then
				self:activate_timed_buff(buff, upgrade_value[2])
				local check_aced = PlayerManager._CHECK_BUFF_ACED[buff]
				if check_aced then
					self:set_buff_attribute(buff, "aced", check_aced() or false)
				end
			--else
				--DEBUG_PRINT("warnings", "Attempting to activate undefined buff: " .. tostring(category) .. ", " .. tostring(upgrade) .. " (" .. "level: " .. tostring(level) .. ")\n")
			end
		end
	end
	return activate_temporary_upgrade_by_level_original(self, category, upgrade, level, ...)
end

function PlayerManager:deactivate_temporary_upgrade(category, upgrade, ...)
	local upgrade_value = self:upgrade_value(category, upgrade)
	if self._temporary_upgrades[category] and upgrade_value ~= 0 then
		local buff = PlayerManager._TEMPORARY_BUFFS[upgrade]
		if buff then
			self:deactivate_buff(buff)
		--else
			--DEBUG_PRINT("warnings", "Attempting to deactivate undefined buff: " .. tostring(category) .. ", " .. tostring(upgrade) .. "\n")
		end
	end
	return deactivate_temporary_upgrade_original(self, category, upgrade, ...)
end

function PlayerManager:aquire_team_upgrade(upgrade, ...)
	aquire_team_upgrade_original(self, upgrade, ...)
	local buff = PlayerManager._TEAM_BUFFS[upgrade.category] and PlayerManager._TEAM_BUFFS[upgrade.category][upgrade.upgrade]
	if buff then
		self:activate_team_buff(buff, 0)
	--else
		--DEBUG_PRINT("warnings", "Attempting to activate undefined local team buff: " .. tostring(upgrade.category) .. ", " .. tostring(upgrade.upgrade) .. "\n")
	end
end

function PlayerManager:unaquire_team_upgrade(upgrade, ...)
	unaquire_team_upgrade_original(self, upgrade, ...)
	local buff = PlayerManager._TEAM_BUFFS[upgrade.category] and PlayerManager._TEAM_BUFFS[upgrade.category][upgrade.upgrade]
	if buff then
		self:deactivate_team_buff(buff, 0)
	--else
		--DEBUG_PRINT("warnings", "Attempting to deactivate undefined local team buff: " .. tostring(upgrade.category) .. ", " .. tostring(upgrade.upgrade) .. "\n")
	end
end

function PlayerManager:add_synced_team_upgrade(peer_id, category, upgrade, ...)
	add_synced_team_upgrade_original(self, peer_id, category, upgrade, ...)
	local buff = PlayerManager._TEAM_BUFFS[category] and PlayerManager._TEAM_BUFFS[category][upgrade]
	if buff then
		self:activate_team_buff(buff, peer_id)
	--else
		--DEBUG_PRINT("warnings", "Attempting to activate undefined team buff: " .. tostring(category) .. ", " .. tostring(upgrade) .. " from peer ID: " .. tostring(peer_id) .. "\n")
	end
end

function PlayerManager:peer_dropped_out(peer, ...)
	local peer_id = peer:id()
	local buffs = {}
	for category, data in pairs(self._global.synced_team_upgrades[peer_id] or {}) do
		for upgrade, _ in pairs(data) do
			local buff = PlayerManager._TEAM_BUFFS[category] and PlayerManager._TEAM_BUFFS[category][upgrade]
			if buff then
				table.insert(buffs, buff)
			--else
				--DEBUG_PRINT("warnings", "Attempting to deactivate undefined local team buff: " .. tostring(category) .. ", " .. tostring(upgrade) .. "\n")
			end
		end
	end
	peer_dropped_out_original(self, peer, ...)
	for _, buff in pairs(buffs) do
		self:deactivate_team_buff(buff, peer_id)
	end
end



function PlayerManager:activate_team_buff(buff, peer)
	PlayerManager.ACTIVE_TEAM_BUFFS[buff] = PlayerManager.ACTIVE_TEAM_BUFFS[buff] or {}
	if not PlayerManager.ACTIVE_TEAM_BUFFS[buff][peer] then
		PlayerManager.ACTIVE_TEAM_BUFFS[buff][peer] = true
		PlayerManager.ACTIVE_TEAM_BUFFS[buff].count = (PlayerManager.ACTIVE_TEAM_BUFFS[buff].count or 0) + 1
		--DEBUG_PRINT("buff_basic", "TEAM BUFF ADD: " .. tostring(buff) .. " -> " .. tostring(PlayerManager.ACTIVE_TEAM_BUFFS[buff].count) .. "\n")
		if PlayerManager.ACTIVE_TEAM_BUFFS[buff].count == 1 then
			--DEBUG_PRINT("buff_basic", "\tACTIVATE\n")
			PlayerManager._do_listener_callback("on_buff_activated", buff)
		end
	end
end

function PlayerManager:deactivate_team_buff(buff, peer)
	if PlayerManager.ACTIVE_TEAM_BUFFS[buff] and PlayerManager.ACTIVE_TEAM_BUFFS[buff][peer] then
		PlayerManager.ACTIVE_TEAM_BUFFS[buff][peer] = nil
		PlayerManager.ACTIVE_TEAM_BUFFS[buff].count = PlayerManager.ACTIVE_TEAM_BUFFS[buff].count - 1
		--DEBUG_PRINT("buff_basic", "TEAM BUFF REMOVE: " .. tostring(buff) .. " -> " .. tostring(PlayerManager.ACTIVE_TEAM_BUFFS[buff].count) .. "\n")
		if PlayerManager.ACTIVE_TEAM_BUFFS[buff].count <= 0 then
			--DEBUG_PRINT("buff_basic", "\tDEACTIVATE\n")
			PlayerManager.ACTIVE_TEAM_BUFFS[buff] = nil
			PlayerManager._do_listener_callback("on_buff_deactivated", buff)
		end
	end
end

function PlayerManager:set_buff_active(buff, status)
	if status then
		self:activate_buff(buff)
	else
		self:deactivate_buff(buff)
	end
end

function PlayerManager:activate_buff(buff)
	if not PlayerManager.ACTIVE_BUFFS[buff] then
		PlayerManager._do_listener_callback("on_buff_activated", buff)
		PlayerManager.ACTIVE_BUFFS[buff] = {}
	end
end

function PlayerManager:deactivate_buff(buff)
	if PlayerManager.ACTIVE_BUFFS[buff] then
		PlayerManager._do_listener_callback("on_buff_deactivated", buff)
		PlayerManager.ACTIVE_BUFFS[buff] = nil
	end
end

function PlayerManager:activate_timed_buff(buff, duration)
	self:activate_buff(buff)
	PlayerManager.ACTIVE_BUFFS[buff].timed = true
	PlayerManager.ACTIVE_BUFFS[buff].activation_t = self._t
	if PlayerManager.ACTIVE_BUFFS[buff].duration ~= duration then
		PlayerManager.ACTIVE_BUFFS[buff].duration = duration
		PlayerManager._do_listener_callback("on_buff_set_duration", buff, duration)
	end
	local expiration_t = self._t + duration
	if PlayerManager.ACTIVE_BUFFS[buff].expire_t ~=  expiration_t then
		PlayerManager.ACTIVE_BUFFS[buff].expire_t = expiration_t
		PlayerManager._do_listener_callback("on_buff_set_expiration", buff, expiration_t)
	end
end

function PlayerManager:refresh_timed_buff(buff)
	if PlayerManager.ACTIVE_BUFFS[buff] then
		PlayerManager.ACTIVE_BUFFS[buff].activation_t = self._t
		local expire_t = self._t + PlayerManager.ACTIVE_BUFFS[buff].duration
		PlayerManager.ACTIVE_BUFFS[buff].expire_t = expire_t
		PlayerManager._do_listener_callback("on_buff_set_expiration", buff, expire_t)
		PlayerManager._do_listener_callback("on_buff_refresh", buff)
	end
end

function PlayerManager:set_buff_attribute(buff, attribute, ...)
	if PlayerManager.ACTIVE_BUFFS[buff] then
		PlayerManager.ACTIVE_BUFFS[buff][attribute] = { ... }
	end
	PlayerManager._do_listener_callback("on_buff_set_" .. attribute, buff, ...)
end


function PlayerManager.register_listener_clbk(name, event, clbk)
	PlayerManager._LISTENER_CALLBACKS[event] = PlayerManager._LISTENER_CALLBACKS[event] or {}
	PlayerManager._LISTENER_CALLBACKS[event][name] = clbk
end

function PlayerManager.unregister_listener_clbk(name, event)
	for event_id, listeners in pairs(PlayerManager._LISTENER_CALLBACKS) do
		if not event or event_id == event then
			for id, _ in pairs(listeners) do
				if id == name then
					PlayerManager._LISTENER_CALLBACKS[event_id][id] = nil
					break
				end
			end
		end
	end
end

function PlayerManager._do_listener_callback(event, ...)
	if PlayerManager._LISTENER_CALLBACKS[event] then
		for _, clbk in pairs(PlayerManager._LISTENER_CALLBACKS[event]) do
			clbk(...)
		end
	end
end
