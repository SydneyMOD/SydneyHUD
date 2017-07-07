local mark_minion_original = UnitNetworkHandler.mark_minion
local hostage_trade_original = UnitNetworkHandler.hostage_trade
local unit_traded_original = UnitNetworkHandler.unit_traded
local interaction_set_active_original = UnitNetworkHandler.interaction_set_active
local alarm_pager_interaction_original = UnitNetworkHandler.alarm_pager_interaction
local sync_teammate_progress_original = UnitNetworkHandler.sync_teammate_progress
local sync_swansong_hud_original = UnitNetworkHandler.sync_swansong_hud
local sync_contour_state_orignal = UnitNetworkHandler.sync_contour_state

function UnitNetworkHandler:mark_minion(unit, owner_id, joker_level, ...)
	mark_minion_original(self, unit, owner_id, joker_level, ...)
	if alive(unit) and unit:in_slot(16) then
		local key = tostring(unit:key())
		local damage_mult = managers.player:upgrade_value_by_level("player", "convert_enemies_damage_multiplier", joker_level, 1)
		managers.gameinfo:event("minion", "add", key, { unit = unit })
		managers.gameinfo:event("minion", "set_owner", key, { owner = owner_id })
		if damage_mult > 1 then
			managers.gameinfo:event("minion", "set_damage_multiplier", key, { damage_multiplier = damage_mult })
		end
	end
end

function UnitNetworkHandler:hostage_trade(unit, ...)
	if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit) then
		managers.gameinfo:event("minion", "remove", tostring(unit:key()))
	end
	return hostage_trade_original(self, unit, ...)
end

function UnitNetworkHandler:unit_traded(unit, ...)
	if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit) then
		managers.gameinfo:event("minion", "remove", tostring(unit:key()))
	end
	return unit_traded_original(self, unit, ...)
end

function UnitNetworkHandler:interaction_set_active(unit, u_id, active, tweak_data, flash, sender, ...)
	if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_sender(sender) then
		if tweak_data == "corpse_alarm_pager" then
			if not alive(unit) then
				local u_data = managers.enemy:get_corpse_unit_data_from_id(u_id)
				unit = u_data and u_data.unit
			end
			if alive(unit) then
				--if not active then
					--managers.gameinfo:event("pager", "remove", tostring(unit:key()))
				if not flash then
					managers.gameinfo:event("pager", "set_answered", tostring(unit:key()))
				end
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
				managers.gameinfo:event("pager", "set_answered", tostring(unit_data.unit:key()))
			--else
				--managers.gameinfo:event("pager", "remove", tostring(unit_data.unit:key()))
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

Hooks:PostHook(UnitNetworkHandler, "sync_doctor_bag_taken", "SydneyHUD:DoctorBagOther", function(self, unit, amount, sender)
	local peer = self._verify_sender(sender)
	local peer_id = peer and peer:id()
	if peer_id then
		SydneyHUD:Replenish(peer_id)
	end
end)

Hooks:PostHook(UnitNetworkHandler, 'set_trade_death', "SydneyHUD:CustodyOther", function(self, criminal_name, respawn_penalty, hostages_killed)
	SydneyHUD:Custody(criminal_name)
end)
