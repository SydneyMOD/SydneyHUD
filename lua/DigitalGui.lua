
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

function DigitalGui:init(unit, ...)
	self._info_key = tostring(unit:key())
	self._ignore = self.TYPE == "number"	--Maybe need move to after init?
	return init_original(self, unit, ...)
end

function DigitalGui:update(unit, t, ...)
	update_original(self, unit, t, ...)
	self:_do_timer_callback("update", t, self._timer)
end

function DigitalGui:timer_set(timer, ...)
	if not self._info_created and Network:is_server() then
		self._info_created = true
		self:_do_timer_callback("create", self._unit, self, "digital")
	end
	self:_do_timer_callback("set", timer)
	return timer_set_original(self, timer, ...)
end

function DigitalGui:timer_start_count_up(...)
	self:_do_timer_callback("start_count_up")
	return timer_start_count_up_original(self, ...)
end

function DigitalGui:timer_start_count_down(...)
	self:_do_timer_callback("start_count_down")
	return timer_start_count_down_original(self, ...)
end

function DigitalGui:timer_pause(...)
	self:_do_timer_callback("pause")
	return timer_pause_original(self, ...)
end

function DigitalGui:timer_resume(...)
	self:_do_timer_callback("resume")
	return timer_resume_original(self, ...)
end

function DigitalGui:_timer_stop(...)
	self:_do_timer_callback("stop")
	return _timer_stop_original(self, ...)
end

function DigitalGui:load(data, ...)
	self:_do_timer_callback("create", self._unit, self, "digital")

	load_original(self, data, ...)

	local state = data.DigitalGui
	if state.timer then
		self:_do_timer_callback("set", state.timer)
	end
	if state.timer_count_up then
		self:_do_timer_callback("start_count_up")
	end
	if state.timer_count_down then
		self:_do_timer_callback("start_count_down")
	end
	if state.timer_paused then
		self:_do_timer_callback("pause")
	end
end

function DigitalGui:destroy(...)
	self:_do_timer_callback("destroy")
	return destroy_original(self, ...)
end


function DigitalGui:_do_timer_callback(event, ...)
	if not self._ignore then
		managers.gameinfo:event("timer", event, self._info_key, ...)
	end
end