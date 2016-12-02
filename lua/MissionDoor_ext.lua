
local deactivate_original = MissionDoor.deactivate

function MissionDoor:deactivate(...)
	managers.interaction:block_trigger(self._unit:editor_id(), false)
	return deactivate_original(self, ...)
end
