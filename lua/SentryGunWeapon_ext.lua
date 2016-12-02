
local init_original = SentryGunWeapon.init
local change_ammo_original = SentryGunWeapon.change_ammo
local sync_ammo_original = SentryGunWeapon.sync_ammo
local load_original = SentryGunWeapon.load

function SentryGunWeapon:init(...)
	init_original(self, ...)
	self:_update_ammo()
end

function SentryGunWeapon:change_ammo(...)
	change_ammo_original(self, ...)
	self:_update_ammo()
end

function SentryGunWeapon:sync_ammo(...)
	sync_ammo_original(self, ...)
	self:_update_ammo()
end

function SentryGunWeapon:load(...)
	load_original(self, ...)
	self:_update_ammo()
end

function SentryGunWeapon:_update_ammo()
	if SentryGunBase.SPAWNED_SENTRIES[self._unit:key()] then
		local ammo_ratio = self:ammo_ratio()
		SentryGunBase.SPAWNED_SENTRIES[self._unit:key()].ammo = ammo_ratio
		UnitBase._do_listener_callback("on_sentry_ammo_update", self._unit, ammo_ratio)
	end
end
