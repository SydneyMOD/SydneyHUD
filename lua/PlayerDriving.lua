
local _start_action_exit_vehicle_original = PlayerDriving._start_action_exit_vehicle
local _check_action_exit_vehicle_original = PlayerDriving._check_action_exit_vehicle

function PlayerDriving:_start_action_exit_vehicle(t)
	if not self:_interacting() then
		return _start_action_exit_vehicle_original(self, t)
	end
end

function PlayerDriving:_check_action_exit_vehicle(t, input, ...)
	local exit_timer = self._exit_vehicle_expire_t or 0
	if not (self:_check_interact_toggle(t, input) and SydneyHUD:GetOption("push_to_interact") and exit_timer >= SydneyHUD:GetOption("push_to_interact_delay")) then
		return _check_action_exit_vehicle_original(self, t, input, ...)
	end
end

function PlayerDriving:_check_interact_toggle(t, input)
	local interrupt_key_press = input.btn_interact_press
	if SydneyHUD:GetOption("equipment_interrupt") then
		interrupt_key_press = input.btn_use_item_press
	end
	if interrupt_key_press and self:_interacting() then
		self:_interupt_action_exit_vehicle()
		return true
	elseif input.btn_interact_release and self:_interacting() then
		return true
	end
end

function PlayerDriving:_set_camera_limits(mode)
	if mode == "driving" then
		self._camera_unit:base():set_limits(180, 20)
	elseif mode == "passenger" then
		self._camera_unit:base():set_limits(100, 30)
	elseif mode == "shooting" then
		self._camera_unit:base():set_limits(180, 40)
	end
end
