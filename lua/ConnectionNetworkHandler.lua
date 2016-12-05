
local sync_outfit_original = ConnectionNetworkHandler.sync_outfit

function ConnectionNetworkHandler:sync_outfit(outfit_string, outfit_version, outfit_signature, sender, ...)
	local peer = self._verify_sender(sender)
	if peer and managers.hud then
		managers.hud:set_slot_detection(peer:id(), outfit_string, false)
	end
	return sync_outfit_original(self, outfit_string, outfit_version, outfit_signature, sender, ...)
end
