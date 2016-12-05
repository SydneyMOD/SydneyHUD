
local _start_tape_loop_original = SecurityCamera._start_tape_loop
local _deactivate_tape_loop_original = SecurityCamera._deactivate_tape_loop

function SecurityCamera:_start_tape_loop(tape_loop_t, ...)
	ObjectInteractionManager._do_listener_callback("on_tape_loop_start", self._unit, tape_loop_t + 6)
	return _start_tape_loop_original(self, tape_loop_t, ...)
end

function SecurityCamera:_deactivate_tape_loop(...)
	ObjectInteractionManager._do_listener_callback("on_tape_loop_stop", self._unit)
	return _deactivate_tape_loop_original(self, ...)
end
