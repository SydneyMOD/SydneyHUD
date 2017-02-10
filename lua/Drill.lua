
local set_autorepair_original = Drill.set_autorepair

function Drill:set_autorepair(...)
	set_autorepair_original(self, ...)
	SydneyHUD._autorepair_map[tostring(self._unit:key())] = self._autorepair and true or false
end