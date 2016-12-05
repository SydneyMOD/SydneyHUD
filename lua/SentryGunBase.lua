
local spawn_original = SentryGunBase.spawn
local init_original = SentryGunBase.init
local sync_setup_original = SentryGunBase.sync_setup
local activate_as_module_original = SentryGunBase.activate_as_module
local destroy_original = SentryGunBase.destroy

SentryGunBase.SPAWNED_SENTRIES = {}

function SentryGunBase.spawn(owner, pos, rot, peer_id, verify_equipment, unit_idstring_index, ...)
	local unit = spawn_original(owner, pos, rot, peer_id, verify_equipment, unit_idstring_index, ...)
	if not SentryGunBase.SPAWNED_SENTRIES[unit:key()] then
		SentryGunBase.SPAWNED_SENTRIES[unit:key()] = { unit = unit }
		UnitBase._do_listener_callback("on_sentry_create", unit)
	end
	SentryGunBase.SPAWNED_SENTRIES[unit:key()].owner = peer_id
	UnitBase._do_listener_callback("on_sentry_owner_update", unit, peer_id)
	return unit
end

function SentryGunBase:init(unit, ...)
	if not SentryGunBase.SPAWNED_SENTRIES[unit:key()] then
		SentryGunBase.SPAWNED_SENTRIES[unit:key()] = { unit = unit }
		UnitBase._do_listener_callback("on_sentry_create", unit)
	end
	init_original(self, unit, ...)
end

function SentryGunBase:sync_setup(upgrade_lvl, peer_id, ...)
	SentryGunBase.SPAWNED_SENTRIES[self._unit:key()].owner = peer_id
	UnitBase._do_listener_callback("on_sentry_owner_update", self._unit, peer_id)
	local result = sync_setup_original(self, upgrade_lvl, peer_id, ...)
	self._owner_id = self._owner_id or peer_id
	return result
end

function SentryGunBase:activate_as_module(...)
	SentryGunBase.SPAWNED_SENTRIES[self._unit:key()] = nil
	UnitBase._do_listener_callback("on_sentry_destroy", self._unit)
	return activate_as_module_original(self, ...)
end

function SentryGunBase:destroy(...)
	SentryGunBase.SPAWNED_SENTRIES[self._unit:key()] = nil
	UnitBase._do_listener_callback("on_sentry_destroy", self._unit)
	return destroy_original(self, ...)
end
