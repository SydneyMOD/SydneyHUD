function ChatManager:_receive_message(channel_id, name, message, color, icon)
	if not self._receivers[channel_id] then
		return
	end
	local time = SydneyHUD._heist_time
	for i, receiver in ipairs(self._receivers[channel_id]) do
		if SydneyHUD:GetOption("show_heist_time") then
			receiver:receive_message(time .. " " .. name, message, color, icon)
		else
			receiver:receive_message(name, message, color, icon)
		end
	end
end