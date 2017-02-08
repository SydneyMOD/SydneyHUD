
local trigger_happy_original = PlayerAction.TriggerHappy.Function

function PlayerAction.TriggerHappy.Function(player_manager, damage_bonus, max_stacks, max_time, ...)
	managers.gameinfo:event("buff", "activate", "trigger_happy")
	managers.gameinfo:event("buff", "set_duration", "trigger_happy", { expire_t = max_time })
	trigger_happy_original(player_manager, damage_bonus, max_stacks, max_time, ...)
	managers.gameinfo:event("buff", "deactivate", "trigger_happy")
end