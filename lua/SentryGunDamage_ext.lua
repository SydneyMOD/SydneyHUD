
local init_original = SentryGunDamage.init
local set_health_original = SentryGunDamage.set_health
local _apply_damage_original = SentryGunDamage._apply_damage
local die_original = SentryGunDamage.die
local load_original = SentryGunDamage.load

function SentryGunDamage:init(...)
	init_original(self, ...)
	if SentryGunBase.SPAWNED_SENTRIES[self._unit:key()] then
		SentryGunBase.SPAWNED_SENTRIES[self._unit:key()].active = true
		UnitBase._do_listener_callback("on_sentry_set_active", self._unit, true)
		self:_update_health()
	end
end

function SentryGunDamage:set_health(...)
	set_health_original(self, ...)
	self:_update_health()
end

function SentryGunDamage:_apply_damage(...)
	local result = _apply_damage_original(self, ...)
	self:_update_health()
	return result
end

function SentryGunDamage:die(...)
	die_original(self, ...)
	if SentryGunBase.SPAWNED_SENTRIES[self._unit:key()] then
		SentryGunBase.SPAWNED_SENTRIES[self._unit:key()].active = nil
		UnitBase._do_listener_callback("on_sentry_set_active", self._unit, false)
	end
end

function SentryGunDamage:load(...)
	load_original(self, ...)
	self:_update_health()
end


function SentryGunDamage:_update_health()
	if SentryGunBase.SPAWNED_SENTRIES[self._unit:key()] then
		SentryGunBase.SPAWNED_SENTRIES[self._unit:key()].health = self:health_ratio()
		UnitBase._do_listener_callback("on_sentry_health_update", self._unit, self:health_ratio())
	end
end
