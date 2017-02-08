
local spawn_original = AmmoBagBase.spawn
local init_original = AmmoBagBase.init
local sync_setup_original = AmmoBagBase.sync_setup
local _set_visual_stage_original = AmmoBagBase._set_visual_stage
local destroy_original = AmmoBagBase.destroy

function AmmoBagBase.spawn(pos, rot, ammo_upgrade_lvl, peer_id, ...)
	local unit = spawn_original(pos, rot, ammo_upgrade_lvl, peer_id, ...)
	if alive(unit) then
		local key = tostring(unit:key())
		managers.gameinfo:event("ammo_bag", "create", key, { unit = unit })
		managers.gameinfo:event("ammo_bag", "set_owner", key, { owner = peer_id })
	end
	return unit
end

function AmmoBagBase:init(unit, ...)
	local key = tostring(unit:key())
	managers.gameinfo:event("ammo_bag", "create", key, { unit = unit })
	init_original(self, unit, ...)
	managers.gameinfo:event("ammo_bag", "set_max_amount", key, { max_amount = self._max_ammo_amount })
end

function AmmoBagBase:sync_setup(ammo_upgrade_lvl, peer_id, ...)
	managers.gameinfo:event("ammo_bag", "set_owner", tostring(self._unit:key()), { owner = peer_id })
	return sync_setup_original(self, ammo_upgrade_lvl, peer_id, ...)
end

function AmmoBagBase:_set_visual_stage(...)
	managers.gameinfo:event("ammo_bag", "set_amount", tostring(self._unit:key()), { amount = self._ammo_amount })
	return _set_visual_stage_original(self, ...)
end

function AmmoBagBase:destroy(...)
	managers.gameinfo:event("ammo_bag", "destroy", tostring(self._unit:key()))
	return destroy_original(self, ...)
end