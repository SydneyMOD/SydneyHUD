Hooks:PostHook(HuskPlayerMovement, '_start_bleedout', "SydneyHUD:DownOther", function(self, ...)
	local peer_id = SydneyHUD:Peer_Info(self._unit)
	if peer_id then
		SydneyHUD:Down(peer_id)
	end
end)