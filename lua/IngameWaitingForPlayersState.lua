
local update_original = IngameWaitingForPlayersState.update

local SKIP_BLACKSCREEN = SydneyHUD:GetOption("skip_black_screen")

function IngameWaitingForPlayersState:update(...)
	SydneyHUD._autorepair_map = {}
	update_original(self, ...)
	if self._skip_promt_shown and SKIP_BLACKSCREEN then
		self:_skip()
	end
end
