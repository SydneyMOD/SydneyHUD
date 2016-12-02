local silenced = false
local get_start_pressed_controller_index_original = MenuTitlescreenState.get_start_pressed_controller_index
local _load_savegames_done_original = MenuTitlescreenState._load_savegames_done

function MenuTitlescreenState:get_start_pressed_controller_index(...)
	local num_connected = 0
	local keyboard_index = nil

	for index, controller in ipairs(self._controller_list) do
		if controller._was_connected then
			num_connected = num_connected + 1
		end
		if controller._default_controller_id == "keyboard" then
			keyboard_index = index
		end
	end

	if num_connected == 1 and keyboard_index ~= nil then
		silenced = true
		return keyboard_index
	else
		return get_start_pressed_controller_index_original(self, ...)
	end
end

function MenuTitlescreenState:_load_savegames_done(...)
	if silenced then
		self:gsm():change_state_by_name("menu_main")
	else
		_load_savegames_done_original(self, ...)
	end
end
