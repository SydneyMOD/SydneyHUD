
local init_original = SecurityCamera.init
local _start_tape_loop_original = SecurityCamera._start_tape_loop
local _deactivate_tape_loop_restart_original = SecurityCamera._deactivate_tape_loop_restart
local _deactivate_tape_loop_original = SecurityCamera._deactivate_tape_loop
local on_unit_set_enabled_original = SecurityCamera.on_unit_set_enabled
local generate_cooldown_original = SecurityCamera.generate_cooldown
local destroy_original = SecurityCamera.destroy

function SecurityCamera:init(unit, ...)
	managers.gameinfo:event("camera", "create", tostring(unit:key()), { unit = unit } )
	return init_original(self, unit, ...)
end

function SecurityCamera:_start_tape_loop(...)
	_start_tape_loop_original(self, ...)
	managers.gameinfo:event("camera", "start_tape_loop", tostring(self._unit:key()), { tape_loop_expire_t = self._tape_loop_end_t + 5 })
end

function SecurityCamera:_deactivate_tape_loop_restart(...)
	managers.gameinfo:event("camera", "stop_tape_loop", tostring(self._unit:key()))
	return _deactivate_tape_loop_restart_original(self, ...)
end

function SecurityCamera:_deactivate_tape_loop(...)
	managers.gameinfo:event("camera", "stop_tape_loop", tostring(self._unit:key()))
	return _deactivate_tape_loop_original(self, ...)
end

function SecurityCamera:on_unit_set_enabled(enabled, ...)
	managers.gameinfo:event("camera", "set_enabled", tostring(self._unit:key()), { enabled = enabled })
	return on_unit_set_enabled_original(self, enabled, ...)
end

function SecurityCamera:generate_cooldown(...)
	managers.gameinfo:event("camera", "set_broken", tostring(self._unit:key()), { broken = true } )
	return generate_cooldown_original(self, ...)
end

function SecurityCamera:destroy(...)
	destroy_original(self, ...)
	managers.gameinfo:event("camera", "destroy", tostring(self._unit:key()))
end