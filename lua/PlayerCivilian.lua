
local _check_action_interact_original = PlayerCivilian._check_action_interact
local _start_action_interact_original = PlayerCivilian._start_action_interact

function PlayerCivilian:_check_action_interact(t, input, ...)
	if not (self:_check_interact_toggle(t, input) and SydneyHUD:GetOption("push_to_interact") and SydneyHUD:GetOption("push_to_interact_delay") <= self._interact_expire_t) then
		return _check_action_interact_original(self, t, input, ...)
	end
end

