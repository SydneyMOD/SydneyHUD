local setup_original = NewRaycastWeaponBase.setup
local on_enabled_original = NewRaycastWeaponBase.on_enabled
local on_equip_original = NewRaycastWeaponBase.on_equip
local toggle_gadget_original = NewRaycastWeaponBase.toggle_gadget

function NewRaycastWeaponBase:setup(...)
	setup_original(self, ...)
	if self._has_gadget then
		self:_setup_laser()
		if alive(self._second_gun) then
			self._second_gun:base():_setup_laser()
		end
	end
end

function NewRaycastWeaponBase:_setup_laser()
	if self._has_gadget then
		local gadgets = clone(self._has_gadget)
		table.sort(gadgets, function(x, y)
			local xd = self._parts[x]
			local yd = self._parts[y]
			if not xd then
				return false
			end
			if not yd then
				return true
			end
			return xd.unit:base().GADGET_TYPE > yd.unit:base().GADGET_TYPE
		end)

		for i, part_id in ipairs(gadgets) do
			local base = self._parts[part_id] and self._parts[part_id].unit:base()
			if base and base.GADGET_TYPE and base.GADGET_TYPE == (WeaponLaser.GADGET_TYPE or "") then
				base:set_color_by_theme("player")
				self:set_gadget_on(i or 0, false)
				break
			end
		end
	end
end

function NewRaycastWeaponBase:on_enabled(...)
	on_enabled_original(self, ...)

	if SydneyHUD:GetOption("auto_laser") and not self._saved_gadget_state then
		self:_setup_laser()
		--[[
		if alive(self._second_gun) then
		self._second_gun:base():_setup_laser()
		end
		--]]
		self._saved_gadget_state = self._gadget_on or 0
	end
end

function NewRaycastWeaponBase:on_equip(...)
	on_equip_original(self, ...)
	self:set_gadget_on(self._saved_gadget_state or 0, false)
end

function NewRaycastWeaponBase:toggle_gadget(...)
	toggle_gadget_original(self, ...)
	self._saved_gadget_state = self._gadget_on or 0
end
