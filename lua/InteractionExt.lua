
local set_tweak_data_original = BaseInteractionExt.set_tweak_data
local SecurityCameraInteractionExt_set_active_original = SecurityCameraInteractionExt.set_active

function BaseInteractionExt:set_tweak_data(...)
	local old_tweak = self.tweak_data
	local was_active = self:active()
	set_tweak_data_original(self, ...)
	if was_active and self:active() and self.tweak_data ~= old_tweak then
		managers.interaction:remove_unit_clbk(self._unit, old_tweak)
		managers.interaction:add_unit_clbk(self._unit)
	end
end

function SecurityCameraInteractionExt:set_active(active, ...)
	if --[[self._unit:enabled() and]] self:active() ~= active then
		managers.gameinfo:event("camera", "set_active", tostring(self._unit:key()), { active = active and true or false } )
	end
	return SecurityCameraInteractionExt_set_active_original(self, active, ...)
end