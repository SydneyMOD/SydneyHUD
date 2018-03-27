
local _check_action_interact_original = PlayerCivilian._check_action_interact

function PlayerCivilian:_check_action_interact(t, input, ...)
	local check_interact = self._interact_params or 0

	if not (self:_check_interact_toggle(t, input) and SydneyHUD:GetOption("push_to_interact") and check_interact.timer >= SydneyHUD:GetOption("push_to_interact_delay")) then
		return _check_action_interact_original(self, t, input, ...)
	end
end
