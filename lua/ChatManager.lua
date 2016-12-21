function ChatManager:_receive_message(channel_id, name, message, color, icon)
	local time = SydneyHUD._heist_time
	if not self._receivers[channel_id] then
		return
	end
	for i, receiver in ipairs(self._receivers[channel_id]) do
		receiver:receive_message(time .. " " .. name, message, color, icon)
	end
end