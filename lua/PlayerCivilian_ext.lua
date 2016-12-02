
local _check_action_interact_original = PlayerCivilian._check_action_interact

function PlayerCivilian:_check_action_interact(t, input, ...)
	if not (self:_check_interact_toggle(t, input) and SydneyHUD:GetOption("push_to_interact")) then
		return _check_action_interact_original(self, t, input, ...)
	end
end
