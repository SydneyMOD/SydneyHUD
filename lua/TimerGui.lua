
local init_original = TimerGui.init
local set_background_icons_original = TimerGui.set_background_icons
local set_visible_original = TimerGui.set_visible
local update_original = TimerGui.update
local _start_original = TimerGui._start
local _set_done_original = TimerGui._set_done
local _set_jammed_original = TimerGui._set_jammed
local _set_powered = TimerGui._set_powered
local destroy_original = TimerGui.destroy

TimerGui.SPAWNED_ITEMS = {}
TimerGui._LISTENER_CALLBACKS = {}

function TimerGui:init(unit, ...)
	TimerGui.SPAWNED_ITEMS[unit:key()] = { unit = unit, powered = true }
	self._do_listener_callback("on_create", unit)
	init_original(self, unit, ...)
	self._device_type = unit:base().is_drill and "Drill" or unit:base().is_hacking_device and "Hack" or unit:base().is_saw and "Saw"
	TimerGui.SPAWNED_ITEMS[self._unit:key()].type = self._device_type
	self._do_listener_callback("on_type_set", unit, self._device_type)
end

function TimerGui:set_background_icons(...)
	local skills = self._unit:base().get_skill_upgrades and self._unit:base():get_skill_upgrades()
	local interact_ext = self._unit:interaction()
	local can_upgrade = false
	local pinfo = interact_ext and interact_ext.get_player_info_id and interact_ext:get_player_info_id()
	if skills and interact_ext and pinfo then
		for i, _ in pairs(interact_ext:split_info_id(pinfo)) do
			if not skills[i] then
				can_upgrade = true
				break
			end
		end
	end
	TimerGui.SPAWNED_ITEMS[self._unit:key()].can_upgrade = can_upgrade or nil
	self._do_listener_callback("on_can_upgrade", self._unit, can_upgrade)
	return set_background_icons_original(self, ...)
end

function TimerGui:set_visible(visible, ...)
	if not visible and self._unit:base().is_drill then
		TimerGui.SPAWNED_ITEMS[self._unit:key()].active = nil
		self._do_listener_callback("on_set_active", self._unit, visible)
	end
	return set_visible_original(self, visible, ...)
end

function TimerGui:update(unit, t, ...)
	update_original(self, unit, t, ...)
	TimerGui.SPAWNED_ITEMS[self._unit:key()].t = t
	TimerGui.SPAWNED_ITEMS[self._unit:key()].time_left = self._time_left
	self._do_listener_callback("on_update", self._unit, t, self._time_left)
end

function TimerGui:_start(...)
	TimerGui.SPAWNED_ITEMS[self._unit:key()].active = true
	self._do_listener_callback("on_set_active", self._unit, true)
	return _start_original(self, ...)
end

function TimerGui:_set_done(...)
	TimerGui.SPAWNED_ITEMS[self._unit:key()].active = nil
	self._do_listener_callback("on_set_active", self._unit, false)
	return _set_done_original(self, ...)
end

function TimerGui:_set_jammed(jammed, ...)
	TimerGui.SPAWNED_ITEMS[self._unit:key()].jammed = jammed and true or nil
	self._do_listener_callback("on_set_jammed", self._unit, jammed and true or false)
	return _set_jammed_original(self, jammed, ...)
end

function TimerGui:_set_powered(powered, ...)
	TimerGui.SPAWNED_ITEMS[self._unit:key()].powered = powered and true or nil
	self._do_listener_callback("on_set_powered", self._unit, powered and true or false)
	return _set_powered(self, powered, ...)
end

function TimerGui:destroy(...)
	TimerGui.SPAWNED_ITEMS[self._unit:key()] = nil
	self._do_listener_callback("on_destroy", self._unit)
	return destroy_original(self, ...)
end

function TimerGui.register_listener_clbk(name, event, clbk)
	TimerGui._LISTENER_CALLBACKS[event] = TimerGui._LISTENER_CALLBACKS[event] or {}
	TimerGui._LISTENER_CALLBACKS[event][name] = clbk
end

function TimerGui.unregister_listener_clbk(name, event)
	for event_id, listeners in pairs(TimerGui._LISTENER_CALLBACKS) do
		if not event or event_id == event then
			for id, _ in pairs(listeners) do
				if id == name then
					TimerGui._LISTENER_CALLBACKS[event_id][id] = nil
					break
				end
			end
		end
	end
end

function TimerGui._do_listener_callback(event, ...)
	if TimerGui._LISTENER_CALLBACKS[event] then
		for _, clbk in pairs(TimerGui._LISTENER_CALLBACKS[event]) do
			clbk(...)
		end
	end
end
