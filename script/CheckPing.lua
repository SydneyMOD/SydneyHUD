function Ping()
	local _ping = 0
	if managers and Network and Network:is_client() then
		if managers.network then
			if managers.network:session() then
				local peer = managers.network:session():peer(1) or {}
				local local_peer = managers.network:session():local_peer() or {}
				if peer and peer ~= local_peer then
					local _qos = Network:qos(peer:rpc()) or {}
					_ping = _qos and _qos.ping or 0
					_ping = math.floor(_ping)
				end
			end
		end
		log("[SydneyHUD Info] ping: " .. _ping)
		local _dialog_data = {}
		if _ping > 0 then
			_dialog_data = {
				title = "[HOST PING]",
				text = tostring(_ping) .. "ms",
				button_list = {{ text = "OK", is_cancel_button = true }},
				id = tostring(math.random(0,0xFFFFFFFF))
			}
		else
			_dialog_data = {
				title = "[HOST PING]",
				text = "You got something strange, try it later by pressing keybind.",
				button_list = {{ text = "OK", is_cancel_button = true }},
				id = tostring(math.random(0,0xFFFFFFFF))
			}
		end
		if managers.system_menu then
			managers.system_menu:show(_dialog_data)
		end
	end
end

Ping()
