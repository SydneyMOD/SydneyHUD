
local mark_minion_original = UnitNetworkHandler.mark_minion
local hostage_trade_original = UnitNetworkHandler.hostage_trade
local unit_traded_original = UnitNetworkHandler.unit_traded
local interaction_set_active_original = UnitNetworkHandler.interaction_set_active
local alarm_pager_interaction_original = UnitNetworkHandler.alarm_pager_interaction
local sync_teammate_progress_original = UnitNetworkHandler.sync_teammate_progress

function UnitNetworkHandler:mark_minion(unit, owner_id, joker_level, partner_in_crime_level, ...)
	mark_minion_original(self, unit, owner_id, joker_level, partner_in_crime_level, ...)
	if self._verify_character(unit) then
		local health_mult = 1
		local damage_mult = 1
		if joker_level > 0 then
			health_mult = health_mult * tweak_data.upgrades.values.player.convert_enemies_health_multiplier[joker_level]
			damage_mult = damage_mult * tweak_data.upgrades.values.player.convert_enemies_damage_multiplier[joker_level]
		end
		if partner_in_crime_level > 0 then
			health_mult = health_mult * tweak_data.upgrades.values.player.passive_convert_enemies_health_multiplier[partner_in_crime_level]
		end
		managers.enemy:add_minion_unit(unit, owner_id, health_mult, damage_mult)
	end
end

function UnitNetworkHandler:hostage_trade(unit, ...)
	if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit) then
		managers.enemy:remove_minion_unit(unit)
	end
	return hostage_trade_original(self, unit, ...)
end

function UnitNetworkHandler:unit_traded(unit, position, rotation, ...)
	if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit) then
		managers.enemy:remove_minion_unit(unit)
	end
	return unit_traded_original(self, unit, position, rotation, ...)
end

function UnitNetworkHandler:interaction_set_active(unit, u_id, active, tweak_data, flash, sender, ...)
	if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_sender(sender) then
		if tweak_data == "corpse_alarm_pager" then
			if not alive(unit) then
				local u_data = managers.enemy:get_corpse_unit_data_from_id(u_id)
				if not u_data then return end
				unit = u_data and u_data.unit
			end
			if not active then
				managers.interaction:pager_ended(unit)
			elseif not flash then
				managers.interaction:pager_answered(unit)
			end
		end
	end
	return interaction_set_active_original(self, unit, u_id, active, tweak_data, flash, sender, ...)
end

function UnitNetworkHandler:alarm_pager_interaction(u_id, tweak_table, status, sender, ...)
	if self._verify_gamestate(self._gamestate_filter.any_ingame) then
		local unit_data = managers.enemy:get_corpse_unit_data_from_id(u_id)
		if unit_data and unit_data.unit:interaction():active() and unit_data.unit:interaction().tweak_data == tweak_table and self._verify_sender(sender) then
			if status == 1 then
				managers.interaction:pager_answered(unit_data.unit)
			else
				managers.interaction:pager_ended(unit_data.unit)
			end
		end
	end
	return alarm_pager_interaction_original(self, u_id, tweak_table, status, sender, ...)
end

function UnitNetworkHandler:sync_teammate_progress(type_index, enabled, tweak_data_id, timer, success, sender, ...)
	local sender_peer = self._verify_sender(sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not sender_peer then
		return
	end
	if type_index and tweak_data_id and success and type_index == 1 and (tweak_data_id == "doctor_bag" or tweak_data_id == "firstaid_box") then
		managers.hud:reset_teammate_revives(managers.hud:teammate_panel_from_peer_id(sender_peer:id()))
	end
	return sync_teammate_progress_original(self, type_index, enabled, tweak_data_id, timer, success, sender, ...)
end
