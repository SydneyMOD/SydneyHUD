local setup_original = NewRaycastWeaponBase.setup

function NewRaycastWeaponBase:setup(...)
	setup_original(self, ...)
	if self._has_gadget then
		self:_setup_laser()
		if alive(self._second_gun) then
			self._second_gun:base():_setup_laser()
		end
	end
end

--[[
local on_enabled_original = NewRaycastWeaponBase.on_enabled

function NewRaycastWeaponBase:on_enabled(...)
	on_enabled_original(self, ...)

	if SydneyHUD:GetOption("auto_laser") and not self._saved_gadget_state then
		self:_setup_laser()

		self._saved_gadget_state = self._gadget_on or 0
	end
end
--]]

function NewRaycastWeaponBase:_setup_laser()
	for _, part in pairs(self._parts) do
		local base = part.unit and part.unit:base()
		if base and base.set_color_by_theme then
			base:set_color_by_theme("player")
		end
	end
end