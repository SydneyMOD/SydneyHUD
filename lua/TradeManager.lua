Hooks:PostHook(TradeManager, 'on_player_criminal_death', "SydneyHUD:Criminal_Custody", function(self, criminal_name, respawn_penalty, hostages_killed, skip_netsend)
	SydneyHUD:Custody(_G.LuaNetworking:LocalPeerID(), true)
end)
