
local spawn_original = DoctorBagBase.spawn
local init_original = DoctorBagBase.init
local sync_setup_original = DoctorBagBase.sync_setup
local _set_visual_stage_original = DoctorBagBase._set_visual_stage
local destroy_original = DoctorBagBase.destroy

function DoctorBagBase.spawn(pos, rot, amount_upgrade_lvl, peer_id, ...)
	local unit = spawn_original(pos, rot, amount_upgrade_lvl, peer_id, ...)
	if alive(unit) then
		local key = tostring(unit:key())
		managers.gameinfo:event("doc_bag", "create", key, { unit = unit })
		managers.gameinfo:event("doc_bag", "set_owner", key, { owner = peer_id })
	end
	return unit
end

function DoctorBagBase:init(unit, ...)
	local key = tostring(unit:key())
	managers.gameinfo:event("doc_bag", "create", key, { unit = unit })
	init_original(self, unit, ...)
	managers.gameinfo:event("doc_bag", "set_max_amount", key, { max_amount = self._max_amount })
end

function DoctorBagBase:sync_setup(amount_upgrade_lvl, peer_id, ...)
	managers.gameinfo:event("doc_bag", "set_owner", tostring(self._unit:key()), { owner = peer_id })
	return sync_setup_original(self, amount_upgrade_lvl, peer_id, ...)
end

function DoctorBagBase:_set_visual_stage(...)
	managers.gameinfo:event("doc_bag", "set_amount", tostring(self._unit:key()), { amount = self._amount })
	return _set_visual_stage_original(self, ...)
end

function DoctorBagBase:destroy(...)
	managers.gameinfo:event("doc_bag", "destroy", tostring(self._unit:key()))
	return destroy_original(self, ...)
end

Hooks:PostHook(DoctorBagBase, "take", "SydneyHUD:DoctorBag", function(self, unit)
	SydneyHUD:Replenish(_G.LuaNetworking:LocalPeerID())
end)
