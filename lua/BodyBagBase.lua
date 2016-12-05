
local spawn_original = BodyBagsBagBase.spawn
local init_original = BodyBagsBagBase.init
local sync_setup_original = BodyBagsBagBase.sync_setup
local _set_visual_stage_original = BodyBagsBagBase._set_visual_stage
local destroy_original = BodyBagsBagBase.destroy

BodyBagsBagBase.SPAWNED_BAGS = {}

function BodyBagsBagBase.spawn(pos, rot, upgrade_lvl, peer_id, ...)
	local unit = spawn_original(pos, rot, upgrade_lvl, peer_id, ...)
	BodyBagsBagBase.SPAWNED_BAGS[unit:key()] = BodyBagsBagBase.SPAWNED_BAGS[unit:key()] or { unit = unit }
	BodyBagsBagBase.SPAWNED_BAGS[unit:key()].owner = peer_id
	UnitBase._do_listener_callback("on_bag_create", unit, "body_bag")
	UnitBase._do_listener_callback("on_bag_owner_update", unit, peer_id)
	return unit
end

function BodyBagsBagBase:init(unit, ...)
	BodyBagsBagBase.SPAWNED_BAGS[unit:key()] = BodyBagsBagBase.SPAWNED_BAGS[unit:key()] or { unit = unit }
	self._do_listener_callback("on_bag_create", unit, "body_bag")
	init_original(self, unit, ...)
	BodyBagsBagBase.SPAWNED_BAGS[self._unit:key()].max_amount = self._max_bodybag_amount
	self._do_listener_callback("on_bag_max_amount_update", unit, self._max_bodybag_amount)
end

function BodyBagsBagBase:sync_setup(ammo_upgrade_lvl, peer_id, ...)
	BodyBagsBagBase.SPAWNED_BAGS[self._unit:key()].owner = peer_id
	self._do_listener_callback("on_bag_owner_update", self._unit, peer_id)
	return sync_setup_original(self, ammo_upgrade_lvl, peer_id, ...)
end

function BodyBagsBagBase:_set_visual_stage(...)
	BodyBagsBagBase.SPAWNED_BAGS[self._unit:key()].amount = self._bodybag_amount
	self._do_listener_callback("on_bag_amount_update", self._unit, self._bodybag_amount)
	return _set_visual_stage_original(self, ...)
end

function BodyBagsBagBase:destroy(...)
	BodyBagsBagBase.SPAWNED_BAGS[self._unit:key()] = nil
	self._do_listener_callback("on_bag_destroy", self._unit)
	return destroy_original(self, ...)
end
