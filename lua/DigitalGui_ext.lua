
local init_original = DigitalGui.init
local update_original = DigitalGui.update
local timer_set_original = DigitalGui.timer_set
local timer_start_count_up_original = DigitalGui.timer_start_count_up
local timer_start_count_down_original = DigitalGui.timer_start_count_down
local timer_pause_original = DigitalGui.timer_pause
local timer_resume_original = DigitalGui.timer_resume
local _timer_stop_original = DigitalGui._timer_stop
local load_original = DigitalGui.load
local destroy_original = DigitalGui.destroy

DigitalGui.SPAWNED_ITEMS = {}
DigitalGui._LISTENER_CALLBACKS = {}

DigitalGui._DEFAULT_CALLBACKS = {
	update = function(unit, t, timer)
		DigitalGui.SPAWNED_ITEMS[unit:key()].t = t
		DigitalGui.SPAWNED_ITEMS[unit:key()].timer = timer
		DigitalGui._do_listener_callback("on_timer_update", unit, t, timer)
	end,
	timer_set = function(unit, timer)
		DigitalGui._DEFAULT_CALLBACKS.update(unit, Application:time(), timer)
	end,
	timer_start_count = function(unit, up)
		if unit:digital_gui()._visible then
			DigitalGui.SPAWNED_ITEMS[unit:key()].active = true
			DigitalGui._do_listener_callback("on_set_active", unit, true)
			DigitalGui._DEFAULT_CALLBACKS.timer_pause(unit, false)
		end
	end,
	timer_pause = function(unit, paused)
		DigitalGui.SPAWNED_ITEMS[unit:key()].jammed = paused and true or nil
		DigitalGui._do_listener_callback("on_set_jammed", unit, paused and true or false)
	end,
	timer_stop = function(unit)
		DigitalGui.SPAWNED_ITEMS[unit:key()].active = nil
		DigitalGui._do_listener_callback("on_set_active", unit, false)
	end
}

local function stop_on_pause(unit, paused)
	if paused then
		DigitalGui._DEFAULT_CALLBACKS.timer_stop(unit)
	else
		DigitalGui._DEFAULT_CALLBACKS.timer_pause(unit, paused)
	end
end

local function stop_on_loud_pause(unit, paused)
	if not managers.groupai:state():whisper_mode() and paused then
		DigitalGui._DEFAULT_CALLBACKS.timer_stop(unit)
	else
		DigitalGui._DEFAULT_CALLBACKS.timer_pause(unit, paused)
	end
end

DigitalGui._TIMER_DATA = {
	[132864] = {    --Meltdown vault temperature
		class = "TemperatureGaugeItem",
		params = { start = 0, goal = 50 },
		timer_set = function(unit, timer, ...)
			if timer > 0 then
				DigitalGui._DEFAULT_CALLBACKS.timer_start_count(unit, true)
			end
			DigitalGui._DEFAULT_CALLBACKS.timer_set(unit, timer, ...)
		end,
		timer_start_count = function(unit, ...)
			unit:digital_gui()._ignore = true
			DigitalGui._DEFAULT_CALLBACKS.timer_stop(unit)
		end,
		timer_pause = false,
	},
	[139706] = { timer_pause = stop_on_pause },     --Hoxton Revenge alarm  (UNTESTED)
	[132675] = { timer_pause = stop_on_loud_pause },        --Hoxton Revenge panic room time lock   (UNTESTED)
	[101936] = { timer_pause = stop_on_pause },     --GO Bank time lock
	[133922] = { timer_pause = stop_on_loud_pause },        --The Diamond pressure plates timer
	[130320] = { }, --The Diamond outer time lock
	[130395] = { }, --The Diamond inner time lock
	[101457] = { }, --Big Bank time lock door #1
	[104671] = { }, --Big Bank time lock door #2
	[167575] = { }, --Golden Grin BFD timer
}

for _, editor_id in ipairs({ 130022, 130122, 130222, 130322, 130422, 130522 }) do               --Train heist vaults (1-6)
	DigitalGui._TIMER_DATA[editor_id] = { timer_pause = stop_on_loud_pause }
end

function DigitalGui:init(unit, ...)
	init_original(self, unit, ...)
	if self.TYPE == "number" then
		self._ignore = true
	else
		DigitalGui.SPAWNED_ITEMS[unit:key()] = { unit = unit, jammed = false, powered = true }
	end
end

function DigitalGui:update(unit, t, ...)
	update_original(self, unit, t, ...)
	self:_do_timer_callback("update", t, self._timer)
end

function DigitalGui:timer_set(timer, ...)
	if not self._timer_callbacks and not self._ignore and Network:is_server() then
		self:_setup_timer_data()
	end
	self:_do_timer_callback("timer_set", timer)
	return timer_set_original(self, timer, ...)
end

function DigitalGui:timer_start_count_up(...)
	self:_do_timer_callback("timer_start_count", true)
	return timer_start_count_up_original(self, ...)
end

function DigitalGui:timer_start_count_down(...)
	self:_do_timer_callback("timer_start_count", false)
	return timer_start_count_down_original(self, ...)
end

function DigitalGui:timer_pause(...)
	self:_do_timer_callback("timer_pause", true)
	return timer_pause_original(self, ...)
end

function DigitalGui:timer_resume(...)
	self:_do_timer_callback("timer_pause", false)
	return timer_resume_original(self, ...)
end

function DigitalGui:_timer_stop(...)
	self:_do_timer_callback("timer_stop")
	return _timer_stop_original(self, ...)
end

function DigitalGui:load(data, ...)
	if not self._ignore then
		self:_setup_timer_data()
		--DEBUG_PRINT("timer", "TIMER EVENT: load (" ..tostring(self._name_id or self._unit:editor_id()) .. ")\n", true)
	end
	load_original(self, data, ...)
	local state = data.DigitalGui
	if state.timer then
		self:_do_timer_callback("timer_set", state.timer)
	end
	if state.timer_count_up then
		self:_do_timer_callback("timer_start_count", true)
	end
	if state.timer_count_down then
		self:_do_timer_callback("timer_start_count", false)
	end
	if state.timer_paused then
		self:_do_timer_callback("timer_pause", true)
	end
end

function DigitalGui:destroy(...)
	DigitalGui.SPAWNED_ITEMS[self._unit:key()] = nil
	DigitalGui._do_listener_callback("on_destroy", self._unit)
	return destroy_original(self, ...)
end


function DigitalGui:_do_timer_callback(event, ...)
	if not self._ignore then
--[[
		if event ~= "update" then
			local str = "TIMER EVENT: " .. tostring(event) .. " (" .. tostring(self._name_id or self._unit:editor_id()) .. ")\n"
			for i, v in ipairs({ ... }) do
				str = str .. "\t" .. tostring(v) .. "\n"
			end
			DEBUG_PRINT("timer", str, event ~= "update")
		end
]]
		if self._timer_callbacks[event] == false then
			return
		elseif self._timer_callbacks[event] then
			self._timer_callbacks[event](self._unit, ...)
		elseif DigitalGui._DEFAULT_CALLBACKS[event] then
			DigitalGui._DEFAULT_CALLBACKS[event](self._unit, ...)
		end
	end
end

function DigitalGui:_setup_timer_data()
	local timer_data = DigitalGui._TIMER_DATA[self._unit:editor_id()] or {}
	DigitalGui.SPAWNED_ITEMS[self._unit:key()].class = timer_data.class
	DigitalGui.SPAWNED_ITEMS[self._unit:key()].params = timer_data.params
	DigitalGui.SPAWNED_ITEMS[self._unit:key()].ignore = timer_data.ignore
	self._name_id = timer_data.name_id
	self._ignore = timer_data.ignore
	self._timer_callbacks = {
		update = timer_data.update,
		timer_set = timer_data.timer_set,
		timer_start_count = timer_data.timer_start_count,
		timer_start_count = timer_data.timer_start_count,
		timer_pause = timer_data.timer_pause,
		timer_stop = timer_data.timer_stop,
	}
	DigitalGui._do_listener_callback("on_create", self._unit, timer_data.class, timer_data.params)
end

function DigitalGui.register_listener_clbk(name, event, clbk)
	DigitalGui._LISTENER_CALLBACKS[event] = DigitalGui._LISTENER_CALLBACKS[event] or {}
	DigitalGui._LISTENER_CALLBACKS[event][name] = clbk
end

function DigitalGui.unregister_listener_clbk(name, event)
	for event_id, listeners in pairs(DigitalGui._LISTENER_CALLBACKS) do
		if not event or event_id == event then
			for id, _ in pairs(listeners) do
				if id == name then
					DigitalGui._LISTENER_CALLBACKS[event_id][id] = nil
					break
				end
			end
		end
	end
end

function DigitalGui._do_listener_callback(event, ...)
	if DigitalGui._LISTENER_CALLBACKS[event] then
		for _, clbk in pairs(DigitalGui._LISTENER_CALLBACKS[event]) do
			clbk(...)
		end
	end
end
