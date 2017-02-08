
local init_original = SentryGunDamage.init
local set_health_original = SentryGunDamage.set_health
local sync_health_original = SentryGunDamage.sync_health
local _apply_damage_original = SentryGunDamage._apply_damage
local die_original = SentryGunDamage.die
local load_original = SentryGunDamage.load

function SentryGunDamage:init(...)
	init_original(self, ...)
	managers.gameinfo:event("sentry", "set_active", tostring(self._unit:key()), { active = true })
	managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
end

function SentryGunDamage:set_health(...)
	set_health_original(self, ...)
	managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
end

function SentryGunDamage:sync_health(...)
	sync_health_original(self, ...)
	managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
end

function SentryGunDamage:_apply_damage(...)
	local result = _apply_damage_original(self, ...)
	managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
	return result
end

function SentryGunDamage:die(...)
	managers.gameinfo:event("sentry", "set_active", tostring(self._unit:key()), { active = false })
	return die_original(self, ...)
end

function SentryGunDamage:load(...)
	load_original(self, ...)
	managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
end