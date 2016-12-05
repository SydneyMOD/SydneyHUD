
local update_original = StageEndScreenGui.update

local SKIP_STAT_SCREEN = SydneyHUD:GetOption("skip_stat_screen")
local SKIP_STAT_SCREEN_DELAY = SydneyHUD:GetOption("stat_screen_skip")

function StageEndScreenGui:update(t, ...)
	update_original(self, t, ...)
	if not self._button_not_clickable and SKIP_STAT_SCREEN_DELAY >= 0 and SKIP_STAT_SCREEN then
		self._auto_continue_t = self._auto_continue_t or (t + SKIP_STAT_SCREEN_DELAY)
		if t >= self._auto_continue_t then
			managers.menu_component:post_event("menu_enter")
			game_state_machine:current_state()._continue_cb()
		end
	end
end
