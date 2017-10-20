if not SydneyHUD:GetOption("show_timer_waypoint") then return end

TimerWaypoint = TimerWaypoint or class(CustomWaypoint)

local function format_time_string(value)
	local frmt_string

	if value >= 60 then
		frmt_string = string.format("%d:%02d", math.floor(value / 60), math.ceil(value % 60))
	elseif value >= 9.9 then
		frmt_string = string.format("%d", math.ceil(value))
	elseif value >= 0 then
		frmt_string = string.format("%.1f", value)
	else
		frmt_string = string.format("%.1f", 0)
	end

	return frmt_string
end

function TimerWaypoint:init(id, ws, data)
	TimerWaypoint.super.init(self, id, ws, data)

	self._panel:set_size(40, 60)

	self._icon = self._panel:bitmap({
		name = "icon",
		texture = data.texture,
		texture_rect = data.texture_rect,
		w = self._panel:w() * 0.875,
		h = self._panel:w() * 0.875,
		x = self._panel:w() * 0.125,
	})

	local text_size = self._panel:h() - self._icon:h()
	self._text = self._panel:text({
		name = "text",
		font = tweak_data.hud.medium_font_noshadow,
		font_size = text_size * 0.95,
		align = "center",
		vertical = "center",
		w = self._panel:w(),
		h = text_size,
		y = self._icon:h(),
	})
end

function TimerWaypoint:_check_offscreen_visibility(...)
	return self._disabled and TimerWaypoint.super._check_offscreen_visibility(self, ...)
end

function TimerWaypoint:_onscreen_state_change()
	self._text:set_visible(self._onscreen)

	if self._onscreen then
		self._icon:set_y(0)
	else
		self._arrow_radius = self._icon:w() * 0.75
		self._icon:set_center(self._panel:w()/2, self._panel:h() / 2)
	end

	return TimerWaypoint.super._onscreen_state_change(self)
end

function TimerWaypoint:set_text(value)
	--self._text:set_text(string.format("%.0f", value))
	self._text:set_text(format_time_string(value))
end

function TimerWaypoint:set_jammed(status)
	self._jammed = status
	self:_check_running()
end

function TimerWaypoint:set_powered(status)
	self._unpowered = not status
	self:_check_running()
end

function TimerWaypoint:_check_running()
	self._disabled = self._jammed or self._unpowered
	local color = self._disabled and Color.red or Color.white
	self._icon:set_color(color)
	self._text:set_color(color)
	self._arrow:set_color(color)
end


MeltdownTimerWaypoint = MeltdownTimerWaypoint or class(TimerWaypoint)

function MeltdownTimerWaypoint:set_text(value)
	self._text:set_text(string.format("%d/50", math.floor(value)))
end


local icon_table = {
	drill = "pd2_drill",
	hack = "pd2_computer",
	saw = "wp_saw",
	timer = "pd2_computer",
	securitylock = "pd2_computer",
	digital = "pd2_computer",
}

local function timer_clbk(event, key, data)
	local id = "timer_wp_" .. key

	if event == "set_active" then
		if data.active then
			local texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon_table[data.device_type or "timer"])
			local params = {
				position = data.unit:position(),
				texture = texture,
				texture_rect = texture_rect,
				show_offscreen = true,
			}

			managers.waypoints:add_waypoint(id, data.id == 132864 and MeltdownTimerWaypoint or TimerWaypoint, params)
		else
			managers.waypoints:remove_waypoint(id)
		end
	elseif event == "update" then
		managers.waypoints:do_callback(id, "set_text", (data.timer_value or 0))
	elseif event == "set_jammed" then
		managers.waypoints:do_callback(id, "set_jammed", data.jammed)
	elseif event == "set_powered" then
		managers.waypoints:do_callback(id, "set_powered", data.powered)
	end
end


local function add_events()
	managers.gameinfo:register_listener("timer_waypoint_listener", "timer", "set_active", timer_clbk)
	managers.gameinfo:register_listener("timer_waypoint_listener", "timer", "update", timer_clbk)
	managers.gameinfo:register_listener("timer_waypoint_listener", "timer", "set_jammed", timer_clbk)
	managers.gameinfo:register_listener("timer_waypoint_listener", "timer", "set_powered", timer_clbk)
end

if GameInfoManager then
	GameInfoManager.add_post_init_event(add_events)
end