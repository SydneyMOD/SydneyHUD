
local init_original = ECMJammerBase.init
local set_active_original = ECMJammerBase.set_active
local _set_feedback_active_original = ECMJammerBase._set_feedback_active
local update_original = ECMJammerBase.update
local sync_net_event_original = ECMJammerBase.sync_net_event
local destroy_original = ECMJammerBase.destroy

ECMJammerBase.SPAWNED_ECMS = {}

function ECMJammerBase:init(...)
	init_original(self, ...)
	ECMJammerBase.SPAWNED_ECMS[self._unit:key()] = { unit = self._unit }
	self._do_listener_callback("on_ecm_create", self._unit)
end

function ECMJammerBase:set_active(active, ...)
	if self._jammer_active ~= active then
		ECMJammerBase.SPAWNED_ECMS[self._unit:key()].active = active
		self._do_listener_callback("on_ecm_set_active", self._unit, active)
	end
	return set_active_original(self, active, ...)
end

function ECMJammerBase:_set_feedback_active(state, ...)
	if not state then
		local peer_id = managers.network:session() and managers.network:session():local_peer() and managers.network:session():local_peer():id()
		if peer_id and (peer_id == self._owner_id) and managers.player:has_category_upgrade("ecm_jammer", "can_retrigger") then
			ECMJammerBase.SPAWNED_ECMS[self._unit:key()].retrigger_t = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
			self._do_listener_callback("on_ecm_set_retrigger", self._unit, true)
		end
	end
	return _set_feedback_active_original(self, state, ...)
end

function ECMJammerBase:update(unit, t, dt, ...)
	update_original(self, unit, t, dt, ...)
	if self._jammer_active then
			ECMJammerBase.SPAWNED_ECMS[self._unit:key()].t = t
			ECMJammerBase.SPAWNED_ECMS[self._unit:key()].battery_life = self._battery_life
			self._do_listener_callback("on_ecm_update", self._unit, t, self._battery_life)
	end
	if ECMJammerBase.SPAWNED_ECMS[self._unit:key()].retrigger_t then
		local rt = ECMJammerBase.SPAWNED_ECMS[self._unit:key()].retrigger_t - dt
		if rt <= 0 then
			self:_deactivate_feedback_retrigger()
		else
			ECMJammerBase.SPAWNED_ECMS[self._unit:key()].t = t
			ECMJammerBase.SPAWNED_ECMS[self._unit:key()].retrigger_t = rt
			self._do_listener_callback("on_ecm_update_retrigger_delay", self._unit, t, rt)
		end
	end
end

function ECMJammerBase:sync_net_event(event_id, ...)
	if event_id == self._NET_EVENTS.feedback_restart  then
		self:_deactivate_feedback_retrigger()
	end
	return sync_net_event_original(self, event_id, ...)
end

function ECMJammerBase:destroy(...)
	destroy_original(self, ...)
	self:_deactivate_feedback_retrigger()
	ECMJammerBase.SPAWNED_ECMS[self._unit:key()] = nil
end


function ECMJammerBase:_deactivate_feedback_retrigger()
	if ECMJammerBase.SPAWNED_ECMS[self._unit:key()].retrigger_t then
		ECMJammerBase.SPAWNED_ECMS[self._unit:key()].retrigger_t = nil
		self._do_listener_callback("on_ecm_set_retrigger", self._unit, false)
	end
end
