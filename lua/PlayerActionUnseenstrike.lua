
local unseenstrike_original = PlayerAction.UnseenStrike.Function
-- local unseenstrike_start_original = PlayerAction.UnseenStrikeStart.Function

function PlayerAction.UnseenStrike.Function(player_manager, min_time, ...)
	local function on_damage_taken()
		managers.gameinfo:event("buff", "set_duration", "unseen_strike_debuff", { duration = min_time })
	end

	managers.player:register_message(Message.OnPlayerDamage, "unseen_strike_debuff_listener", on_damage_taken)
	managers.gameinfo:event("buff", "activate", "unseen_strike_debuff")
	on_damage_taken()
	unseenstrike_original(player_manager, min_time, ...)
	managers.player:unregister_message(Message.OnPlayerDamage, "unseen_strike_debuff_listener")
	managers.gameinfo:event("buff", "deactivate", "unseen_strike_debuff")
end

--[[
function PlayerAction.UnseenStrikeStart.Function(player_manager, max_duration, ...)
	local start_t = Application:time()

	local function on_damage_taken()
		local stop_t = Application:time()
		local diff = stop_t - start_t
		local offset = diff - math.floor(diff/max_duration) * max_duration	--Has error margin, grows every reset
		managers.gameinfo:event("buff", "set_duration", "unseen_strike", { t = stop_t - offset, duration = max_duration })
	end

	managers.player:register_message(Message.OnPlayerDamage, "unseen_strike_buff_listener", on_damage_taken)
	managers.gameinfo:event("buff", "activate", "unseen_strike")
	unseenstrike_start_original(player_manager, max_duration, ...)
	managers.player:unregister_message(Message.OnPlayerDamage, "unseen_strike_buff_listener")
	managers.gameinfo:event("buff", "deactivate", "unseen_strike")
end
]]
