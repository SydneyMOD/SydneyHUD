
local experthandling_original = PlayerAction.ExpertHandling.Function

function PlayerAction.ExpertHandling.Function(player_manager, accuracy_bonus, max_stacks, max_time, ...)
	managers.gameinfo:event("buff", "activate", "desperado")
	managers.gameinfo:event("buff", "set_duration", "desperado", { expire_t = max_time })
	experthandling_original(player_manager, accuracy_bonus, max_stacks, max_time, ...)
	managers.gameinfo:event("buff", "deactivate", "desperado")
end