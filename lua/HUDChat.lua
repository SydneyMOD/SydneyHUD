local receive_message_original = HUDChat.receive_message

function HUDChat:receive_message(name, ...)
	local heisttime = managers.game_play_central and managers.game_play_central:get_heist_timer() or 0
	local hours = math.floor(heisttime / (60*60))
	local minutes = math.floor(heisttime / 60) % 60
	local seconds = math.floor(heisttime % 60)
	if hours > 0 then
		SydneyHUD._heist_time = string.format("%d:%02d:%02d", hours, minutes, seconds)
	else
		SydneyHUD._heist_time = string.format("%02d:%02d", minutes, seconds)
	end

	if SydneyHUD:GetOption("show_heist_time") then
		name = SydneyHUD._heist_time .. " " .. name
	end

	receive_message_original(self, name, ...)
end
