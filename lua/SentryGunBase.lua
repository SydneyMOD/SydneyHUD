
local spawn_original = SentryGunBase.spawn
local init_original = SentryGunBase.init
local sync_setup_original = SentryGunBase.sync_setup
local destroy_original = SentryGunBase.destroy

function SentryGunBase.spawn(owner, pos, rot, peer_id, ...)
	local unit = spawn_original(owner, pos, rot, peer_id, ...)
	if alive(unit) then
		managers.gameinfo:event("sentry", "create", tostring(unit:key()), { unit = unit })
		managers.gameinfo:event("sentry", "set_owner", tostring(unit:key()), { owner = peer_id })
	end
	return unit
end

function SentryGunBase:init(unit, ...)
	managers.gameinfo:event("sentry", "create", tostring(unit:key()), { unit = unit })
	init_original(self, unit, ...)
end

function SentryGunBase:sync_setup(upgrade_lvl, peer_id, ...)
	managers.gameinfo:event("sentry", "set_owner", tostring(self._unit:key()), { owner = peer_id })
	local result = sync_setup_original(self, upgrade_lvl, peer_id, ...)
	self._owner_id = self._owner_id or peer_id
	return result
end

function SentryGunBase:destroy(...)
	managers.gameinfo:event("sentry", "destroy", tostring(self._unit:key()))
	return destroy_original(self, ...)
end
