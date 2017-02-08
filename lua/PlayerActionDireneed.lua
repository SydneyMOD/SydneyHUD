
local direneed_original = PlayerAction.DireNeed.Function

function PlayerAction.DireNeed.Function(...)
	managers.gameinfo:event("buff", "activate", "dire_need")
	direneed_original(...)
	managers.gameinfo:event("buff", "deactivate", "dire_need")
end