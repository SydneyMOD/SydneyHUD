local _get_max_move_speed_original = HuskPlayerMovement._get_max_move_speed

function HuskPlayerMovement:_get_max_move_speed(...)
	return _get_max_move_speed_original(self, ...) * 2 -- the int 2 is const value, TODO: changeable int value
end

Hooks:PostHook(HuskPlayerMovement, '_start_bleedout', "SydneyHUD:DownOther", function(self, ...)
	local peer_id = SydneyHUD:Peer_Info(self._unit)
	if peer_id then
		SydneyHUD:Down(peer_id)
	end
end)