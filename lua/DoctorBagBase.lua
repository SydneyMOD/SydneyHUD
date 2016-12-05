
local spawn_original = DoctorBagBase.spawn
local init_original = DoctorBagBase.init
local sync_setup_original = DoctorBagBase.sync_setup
local _set_visual_stage_original = DoctorBagBase._set_visual_stage
local destroy_original = DoctorBagBase.destroy

DoctorBagBase.SPAWNED_BAGS = {}

function DoctorBagBase.spawn(pos, rot, bits, peer_id, ...)
	local unit = spawn_original(pos, rot, bits, peer_id, ...)
	DoctorBagBase.SPAWNED_BAGS[unit:key()] = DoctorBagBase.SPAWNED_BAGS[unit:key()] or { unit = unit }
	DoctorBagBase.SPAWNED_BAGS[unit:key()].owner = peer_id
	UnitBase._do_listener_callback("on_bag_create", unit, "doc_bag")
	UnitBase._do_listener_callback("on_bag_owner_update", unit, peer_id)
	return unit
end

function DoctorBagBase:init(unit, ...)
	DoctorBagBase.SPAWNED_BAGS[unit:key()] = DoctorBagBase.SPAWNED_BAGS[unit:key()] or { unit = unit }
	self._do_listener_callback("on_bag_create", unit, "doc_bag")
	init_original(self, unit, ...)
	DoctorBagBase.SPAWNED_BAGS[unit:key()].max_amount = self._max_amount
	self._do_listener_callback("on_bag_max_amount_update", unit, self._max_amount)
end

function DoctorBagBase:sync_setup(bits, peer_id, ...)
	DoctorBagBase.SPAWNED_BAGS[self._unit:key()].owner = peer_id
	self._do_listener_callback("on_bag_owner_update", self._unit, peer_id)
	return sync_setup_original(self, bits, peer_id, ...)
end

function DoctorBagBase:_set_visual_stage(...)
	DoctorBagBase.SPAWNED_BAGS[self._unit:key()].amount = self._amount
	self._do_listener_callback("on_bag_amount_update", self._unit, self._amount)
	return _set_visual_stage_original(self, ...)
end

function DoctorBagBase:destroy(...)
	DoctorBagBase.SPAWNED_BAGS[self._unit:key()] = nil
	self._do_listener_callback("on_bag_destroy", self._unit)
	return destroy_original(self, ...)
end
