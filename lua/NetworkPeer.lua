Hooks:Add("BaseNetworkSessionOnPeerRemoved", "SydneyHUD:PeerRemoved", function(peer, peer_id, reason)
	SydneyHUD._down_count[peer_id] = 0
end)
