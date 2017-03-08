
local init_original = SentryGunWeapon.init
local change_ammo_original = SentryGunWeapon.change_ammo
local sync_ammo_original = SentryGunWeapon.sync_ammo
local load_original = SentryGunWeapon.load

function SentryGunWeapon:init(...)
	init_original(self, ...)
	managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })

	if tweak_data.blackmarket.deployables[self._unit:base():get_type()] then
		managers.enemy:add_delayed_clbk("sentry_post_init_" .. tostring(self._unit:key()), callback(self, self, "post_init"), Application:time() + 0.1)
	end
end

function SentryGunWeapon:post_init()
	local is_enable_ap =false

	if self._unit:base():is_owner() then
		is_enable_ap = managers.player:has_category_upgrade("sentry_gun", "ap_bullets")
	end

	if SydneyHUD:GetOption("auto_sentry_ap") and is_enable_ap then
		if alive(self._fire_mode_unit) and alive(self._unit) then
			local firemode_interaction = self._fire_mode_unit:interaction()
			if firemode_interaction and firemode_interaction:can_interact(managers.player:player_unit()) then
				self:_switch_fire_mode()
				managers.network:session():send_to_peers_synched("sentrygun_sync_state", self._unit)
				self._unit:event_listener():call("on_switch_fire_mode", self._use_armor_piercing)
			end
		end
	end
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