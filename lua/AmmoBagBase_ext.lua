
local spawn_original = AmmoBagBase.spawn
local init_original = AmmoBagBase.init
local sync_setup_original = AmmoBagBase.sync_setup
local _set_visual_stage_original = AmmoBagBase._set_visual_stage
local destroy_original = AmmoBagBase.destroy

AmmoBagBase.SPAWNED_BAGS = {}

function AmmoBagBase.spawn(pos, rot, ammo_upgrade_lvl, peer_id, ...)
	local unit = spawn_original(pos, rot, ammo_upgrade_lvl, peer_id, ...)
	AmmoBagBase.SPAWNED_BAGS[unit:key()] = AmmoBagBase.SPAWNED_BAGS[unit:key()] or { unit = unit }
	AmmoBagBase.SPAWNED_BAGS[unit:key()].owner = peer_id
	UnitBase._do_listener_callback("on_bag_create", unit, "ammo_bag")
	UnitBase._do_listener_callback("on_bag_owner_update", unit, peer_id)
	return unit
end

function AmmoBagBase:init(unit, ...)
	AmmoBagBase.SPAWNED_BAGS[unit:key()] = AmmoBagBase.SPAWNED_BAGS[unit:key()] or { unit = unit }
	self._do_listener_callback("on_bag_create", unit, "ammo_bag")
	init_original(self, unit, ...)
	AmmoBagBase.SPAWNED_BAGS[unit:key()].max_amount = self._max_ammo_amount * 100
	self._do_listener_callback("on_bag_max_amount_update", unit, self._max_ammo_amount * 100)
end

function AmmoBagBase:sync_setup(ammo_upgrade_lvl, peer_id, ...)
	AmmoBagBase.SPAWNED_BAGS[self._unit:key()].owner = peer_id
	self._do_listener_callback("on_bag_owner_update", self._unit, peer_id)
	return sync_setup_original(self, ammo_upgrade_lvl, peer_id, ...)
end

function AmmoBagBase:_set_visual_stage(...)
	AmmoBagBase.SPAWNED_BAGS[self._unit:key()].amount = self._ammo_amount * 100
	self._do_listener_callback("on_bag_amount_update", self._unit, self._ammo_amount * 100)
	return _set_visual_stage_original(self, ...)
end

function AmmoBagBase:destroy(...)
	AmmoBagBase.SPAWNED_BAGS[self._unit:key()] = nil
	self._do_listener_callback("on_bag_destroy", self._unit)
	return destroy_original(self, ...)
end
