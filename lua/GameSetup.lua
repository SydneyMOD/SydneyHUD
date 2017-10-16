if GameSetup then

	local init_managers_original = GameSetup.init_managers
	local update_original = GameSetup.update

	function GameSetup:init_managers(managers, ...)
		managers.waypoints = managers.waypoints or WaypointManager:new()
		return init_managers_original(self, managers, ...)
	end

	function GameSetup:update(t, dt, ...)
		managers.waypoints:update(t, dt)
		return update_original(self, t, dt, ...)
	end
	
else

	WaypointManager = WaypointManager or class()

	function WaypointManager:init()
		self._waypoints = {}
		self._waypoint_index = {}
		self._index_update_required = false
		self._ws = Overlay:gui():create_screen_workspace()
		self._panel = self._ws:panel()
		self._w, self._h = self._panel:size()
		
		WaypointManager.OFFSCREEN_RADIUS = { 
			circle = { 
				x = math.min(self._w, self._h) * 0.45, 
				y = math.min(self._w, self._h) * 0.45
			},
			ellipse = {
				x = self._w * 0.45,
				y = self._h * 0.45,
			},
		}
	end

	function WaypointManager:update(t, dt)
		local cam = managers.viewport:get_current_camera()
		
		if not (cam and alive(self._panel)) then return end
		
		if self._index_update_required then
			self._waypoint_index = {}
			
			for id, _ in pairs(self._waypoints) do
				table.insert(self._waypoint_index, id)
			end
			
			self._index_update_required = false
		end
		
		for _, id in ipairs(self._waypoint_index) do
			if self._waypoints[id] then
				self._waypoints[id]:update(t, dt, cam)
			end
		end
	end

	function WaypointManager:get_waypoint(id)
		return self._waypoints[id]
	end

	function WaypointManager:get_waypoints()
		return self._waypoints
	end

	function WaypointManager:add_waypoint(id, class, data)
		if not self._waypoints[id] then
			local item_class = type(class) == "string" and _G[class] or class
			if item_class then
				self._waypoints[id] = item_class:new(id, self._ws, data)
				self._waypoints[id]:setup_arrow()
				self._waypoints[id]:post_init()
				table.insert(self._waypoint_index, id)
			end
		end
		
		return self._waypoints[id]
	end

	function WaypointManager:remove_waypoint(id)
		if self._waypoints[id] then
			if alive(self._panel) and alive(self._waypoints[id]:panel()) then
				self._panel:remove(self._waypoints[id]:panel())
			end
			
			self._waypoints[id]:destroy()
			self._waypoints[id] = nil
			self._index_update_required = true
		end
	end

	function WaypointManager:do_callback(id, clbk, ...)
		local wp = self._waypoints[id]
		
		if wp then
			if wp[clbk] then
				wp[clbk](wp, ...)
			else
				printf("Warning: No callback function %s for waypoint ID %s", clbk, id)
			end
		end
	end
	
	
	CustomWaypoint = CustomWaypoint or class()

	CustomWaypoint.OFFSCREEN_TYPE = "border"	--circle, ellipse, border
	CustomWaypoint.OFFSCREEN_RADIUS_SCALE = 1	--Radius multiplier for circle/ellipse offscreen size
	CustomWaypoint.TRANSIT_SPEED = 0.35			--Transition time from offscreen position to onscreen position when not using border offscreen mode

	function CustomWaypoint:init(id, ws, data)
		data = data or {}
		self._id = id
		self._ws = ws
		self._panel = self._ws:panel():panel({ name = id, visible = false })
		self._position = data.position and mvector3.copy(data.position)
		self._show_offscreen = data.show_offscreen
		self._enabled = true
		self._visible = false
		self._onscreen = false
		self._transition_t = 1
		
		local arrow_icon, arrow_texture_rect = tweak_data.hud_icons:get_icon_data("wp_arrow")
		self._arrow = self._panel:bitmap({
			name = "offscreen_arrow",
			texture = arrow_icon,
			texture_rect = arrow_texture_rect,
			visible = false,
			w = 20,
			h = 20,
		})
	end
	
	function CustomWaypoint:setup_arrow()
		self._arrow_radius = self._arrow_radius or math.max(self._panel:w(), self._panel:h())
		self._arrow_center = self._arrow_center or { self._panel:w() / 2, self._panel:h() / 2 }
	end

	function CustomWaypoint:panel()
		return self._panel
	end

	function CustomWaypoint:set_enabled(status)
		self._enabled = status
		if not status then
			self:_set_visible(false)
		end
		
		return self._enabled
	end

	function CustomWaypoint:update(t, dt, cam)
		if self:_alive() then
			if self._enabled then
				self._position = self:_update_world_position(t, dt)
				local distance, dot, angle, x, y, direction = self:_update_world_data(cam)
				
				if self._visible then
					self:_update_screen_position(t, dt, x, y)
					if not self._onscreen then
						self:_update_offscreen_arrow(t, dt, direction.x, direction.y)
					end
				end
				
				self:_update(t, dt, distance, dot, angle, x, y)
			else
				self:_update_disabled(t, dt)
			end
		else
			managers.waypoints:remove_waypoint(self._id)
		end
	end

	function CustomWaypoint:_set_onscreen(status)
		if self._onscreen ~= status then
			self._onscreen = status
			self._transition_t = self._visible and WaypointManager.OFFSCREEN_RADIUS[self.OFFSCREEN_TYPE] and 0 or 1
			self._arrow:set_visible(not status)
			self:_onscreen_state_change()
		end
		
		return self._onscreen
	end

	function CustomWaypoint:_set_visible(status)
		if self._visible ~= status then
			self._visible = status
			self._panel:set_visible(self._visible)
			self:_visibility_state_change()
		end
		
		return self._visible
	end

	local direction = Vector3()
	local screen_pos = Vector3()
	function CustomWaypoint:_update_world_data(cam)
		local pw, ph = self._ws:panel():size()
		local w, h = self._panel:size()
		mvector3.set(screen_pos, self._ws:world_to_screen(cam, self._position))
		mvector3.set(direction, self._position)
		mvector3.subtract(direction, cam:position())
		
		local distance = mvector3.normalize(direction)
		local dot = mvector3.dot(cam:rotation():y(), direction)
		local angle = math.acos(dot)
		local displace_x, displace_y = self:_displace_screen_position()
		local x, y = mvector3.x(screen_pos) + displace_x, mvector3.y(screen_pos) + displace_y
		
		self:_set_onscreen(
			dot >= 0 and 
			(x + w/2 > 0) and 
			(x - w/2 < pw) and 
			(y + h/2 > 0) and 
			(y - h/2 < ph)
		)
		
		local visible_offscreen = self:_check_offscreen_visibility(distance, dot, angle)
		self:_set_visible(self._onscreen and self:_check_onscreen_visibility(distance, dot, angle) or visible_offscreen)
		
		if self._visible then
			if not self._onscreen then	
				mvector3.set_static(direction, x - pw/2, y - ph/2, 0)
				mvector3.normalize(direction)
				x, y = self:_convert_offscreen_position(x, y, pw, ph, direction)
			end
			
			--Clamp to screen space if it should remain visible offscreen
			if visible_offscreen then
				x = math.clamp(x, w/2 + 10, pw - w/2 - 10)
				y = math.clamp(y, h/2 + 5, ph - h/2 - 5)
			end
		end
		
		return distance, dot, angle, x, y, direction
	end
	
	function CustomWaypoint:_convert_offscreen_position(x, y, w, h, direction)
		local radius = WaypointManager.OFFSCREEN_RADIUS[self.OFFSCREEN_TYPE]
		local hw, hh = w/2, h/2
		local tx, ty
		
		if radius then	--Offscreen shown on a screen-centered ellipse/circle
			tx = hw + direction.x * radius.x * self.OFFSCREEN_RADIUS_SCALE
			ty = hh + direction.y * radius.y * self.OFFSCREEN_RADIUS_SCALE
		else	--Offscreen shown on screen edge
			local dx, dy = x - hw, y - hh	--Translate to origin frame
			local adx, ady = math.abs(dx), math.abs(dy) --Project into first quadrant
			local k = ady/adx
			
			ty = k * hw
			if 0 <= ty and ty <= hh then	--Right edge intersection
				tx = hw
			else	--Top edge intersection
				tx = hh/k
				ty = hh
			end
			
			--Project back into original quadrant and translate back to original frame
			tx = tx * (dx < adx and -1 or 1) + hw
			ty = ty * (dy < ady and -1 or 1) + hh
		end
		
		return tx, ty
	end

	function CustomWaypoint:_update_screen_position(t, dt, x, y)
		if self._visible then
			if self._transition_t < 1 then
				self._transition_t = math.clamp(self._transition_t + dt / self.TRANSIT_SPEED, 0, 1)
				
				local a = Vector3(self._panel:center())
				local b = Vector3(x, y)
				local tmp = math.bezier({ a, a, b, b }, self._transition_t)
				x, y = tmp.x, tmp.y
			end
			
			self._panel:set_center(x, y)
		end
	end

	function CustomWaypoint:_update_offscreen_arrow(t, dt, dx, dy)
		self._arrow:set_rotation(math.atan2(dy, dx))
		self._arrow:set_center(self._arrow_center[1] + dx * self._arrow_radius,  self._arrow_center[2] + dy * self._arrow_radius)
	end

	
	function CustomWaypoint:post_init()

	end

	function CustomWaypoint:destroy()

	end
	
	function CustomWaypoint:_alive()
		return true
	end

	function CustomWaypoint:_update_world_position(t, dt)
		return self._position
	end
	
	function CustomWaypoint:_displace_screen_position()
		return 0, 0
	end

	function CustomWaypoint:_check_onscreen_visibility(distance, dot, angle)
		return true
	end

	function CustomWaypoint:_check_offscreen_visibility(distance, dot, angle)
		return self._show_offscreen
	end

	function CustomWaypoint:_update(t, dt, distance, dot, angle, x, y)

	end

	function CustomWaypoint:_update_disabled(t, dt)

	end

	function CustomWaypoint:_onscreen_state_change()
		
	end

	function CustomWaypoint:_visibility_state_change()
		
	end
	
end