
local init_original = ECMJammerBase.init
local setup_original = ECMJammerBase.setup
local sync_setup_original = ECMJammerBase.sync_setup
local set_active_original = ECMJammerBase.set_active
local _set_feedback_active_original = ECMJammerBase._set_feedback_active
local update_original = ECMJammerBase.update
local contour_interaction_original = ECMJammerBase.contour_interaction
local destroy_original = ECMJammerBase.destroy

function ECMJammerBase:init(unit, ...)
	self._ecm_unit_key = tostring(unit:key())
	managers.gameinfo:event("ecm", "create", self._ecm_unit_key, { unit = unit })
	return init_original(self, unit, ...)
end

function ECMJammerBase:setup(upgrade_lvl, owner, ...)
	managers.gameinfo:event("ecm", "set_owner", self._ecm_unit_key, { owner = owner })
	managers.gameinfo:event("ecm", "set_upgrade_level", self._ecm_unit_key, { upgrade_level = upgrade_lvl })
	return setup_original(self, upgrade_lvl, owner, ...)
end

function ECMJammerBase:sync_setup(upgrade_lvl, peer_id, ...)
	managers.gameinfo:event("ecm", "set_owner", self._ecm_unit_key, { owner = peer_id })
	managers.gameinfo:event("ecm", "set_upgrade_level", self._ecm_unit_key, { upgrade_level = upgrade_lvl })
	return sync_setup_original(self, upgrade_lvl, peer_id, ...)
end

function ECMJammerBase:set_active(active, ...)
	if self._jammer_active ~= active then
		managers.gameinfo:event("ecm", "set_jammer_active", self._ecm_unit_key, { jammer_active = active })
	end

	return set_active_original(self, active, ...)
end

function ECMJammerBase:_set_feedback_active(state, ...)
	if not state and self._feedback_active then
		local peer_id = managers.network:session():local_peer():id()

		if self._owner_id == peer_id and managers.player:has_category_upgrade("ecm_jammer", "can_retrigger") then
			self._retrigger_delay = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
			managers.gameinfo:event("ecm", "set_retrigger_active", self._ecm_unit_key, { retrigger_active = true })
		end
	end

	return _set_feedback_active_original(self, state, ...)
end

function ECMJammerBase:update(unit, t, dt, ...)
	update_original(self, unit, t, dt, ...)

	if self._jammer_active then
		if string.format("%.1f", self._battery_life) == "5.0" and SydneyHUD:GetOption("ecm_battery_chat_info") then -- 5.0sec remining
			local name = "ECM batt."
			local message = "5sec remining"
			if not managers.chat:is_spam(name, message) then
				if SydneyHUD:GetOption("ecm_battery_chat_info_feed") then
					SydneyHUD:SendChatMessage(name, message, true)
					SydneyHUD:SaveChatMessage(name, message)
				else
					SydneyHUD:SendChatMessage(name, message)
					SydneyHUD:SaveChatMessage(name, message)
				end
			end
		elseif SydneyHUD._chat then
			SydneyHUD:RemoveChatMessage("current")
		end
	end

	if not self._battery_empty then
		managers.gameinfo:event("ecm", "set_jammer_battery", self._ecm_unit_key, { jammer_battery = self._battery_life })
	end

	if self._retrigger_delay then
		self._retrigger_delay = self._retrigger_delay - dt
		managers.gameinfo:event("ecm", "set_retrigger_delay", self._ecm_unit_key, { retrigger_delay = self._retrigger_delay })

		if self._retrigger_delay <= 0 then
			self._retrigger_delay = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
		end
	end
end

function ECMJammerBase:contour_interaction(...)
	if alive(self._unit) and self._owner_id == managers.network:session():local_peer():id() and managers.player:has_category_upgrade("ecm_jammer", "can_activate_feedback") then
		self._retrigger_delay = nil
		managers.gameinfo:event("ecm", "set_retrigger_active", self._ecm_unit_key, { retrigger_active = false })
	end

	return contour_interaction_original(self, ...)
end

function ECMJammerBase:destroy(...)
	managers.gameinfo:event("ecm", "set_retrigger_active", self._ecm_unit_key, { retrigger_active = false })
	managers.gameinfo:event("ecm", "destroy", self._ecm_unit_key)
	destroy_original(self, ...)
end
