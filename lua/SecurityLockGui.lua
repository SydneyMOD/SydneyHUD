
local init_original = SecurityLockGui.init
local update_original = SecurityLockGui.update
local _start_original = SecurityLockGui._start
local _set_done_original = SecurityLockGui._set_done
local _set_jammed_original = SecurityLockGui._set_jammed
local _set_powered = SecurityLockGui._set_powered
local destroy_original = SecurityLockGui.destroy

function SecurityLockGui:init(unit, ...)
	self._info_key = tostring(unit:key())
	managers.gameinfo:event("timer", "create", self._info_key, unit, self, "securitylock")
	init_original(self, unit, ...)
end

function SecurityLockGui:update(unit, t, ...)
	update_original(self, unit, t, ...)
	managers.gameinfo:event("timer", "update", self._info_key, t, self._current_timer)
end

function SecurityLockGui:_start(...)
	managers.gameinfo:event("timer", "set_active", self._info_key, true)
	return _start_original(self, ...)
end

function SecurityLockGui:_set_done(...)
	managers.gameinfo:event("timer", "set_active", self._info_key, false)
	return _set_done_original(self, ...)
end

function SecurityLockGui:_set_jammed(jammed, ...)
	managers.gameinfo:event("timer", "set_jammed", self._info_key, jammed and true or false)
	return _set_jammed_original(self, jammed, ...)
end

function SecurityLockGui:_set_powered(powered, ...)
	managers.gameinfo:event("timer", "set_powered", self._info_key, powered and true or false)
	return _set_powered(self, powered, ...)
end

function SecurityLockGui:destroy(...)
	managers.gameinfo:event("timer", "destroy", self._info_key)
	return destroy_original(self, ...)
end