Hooks:PostHook(PlayerBleedOut, '_enter', "SydneyHUD:Down", function(self, enter_data)
	SydneyHUD:Down(_G.LuaNetworking:LocalPeerID(), true)
end)
