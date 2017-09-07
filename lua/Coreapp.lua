Hooks:Add("MenuUpdate", "SydneyHUD_DelayedCalls_MenuUpdate", function(t, dt)
	SydneyHUD:DelayedCallsUpdate(t, dt)
end)

Hooks:Add("GameSetupUpdate", "SydneyHUD_DelayedCalls_GameSetupUpdate", function(t, dt)
	SydneyHUD:DelayedCallsUpdate(t, dt)
end)