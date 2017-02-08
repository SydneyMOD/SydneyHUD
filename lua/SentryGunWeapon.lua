
local init_original = SentryGunWeapon.init
local change_ammo_original = SentryGunWeapon.change_ammo
local sync_ammo_original = SentryGunWeapon.sync_ammo
local load_original = SentryGunWeapon.load

function SentryGunWeapon:init(...)
	init_original(self, ...)
	managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
end

function SentryGunWeapon:change_ammo(...)
	change_ammo_original(self, ...)
	managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
end

function SentryGunWeapon:sync_ammo(...)
	sync_ammo_original(self, ...)
	managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
end

function SentryGunWeapon:load(...)
	load_original(self, ...)
	managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
end