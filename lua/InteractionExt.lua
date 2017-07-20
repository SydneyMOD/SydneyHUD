
local set_tweak_data_original = BaseInteractionExt.set_tweak_data
local SecurityCameraInteractionExt_set_active_original = SecurityCameraInteractionExt.set_active
local interact_start_original = BaseInteractionExt.interact_start

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

function BaseInteractionExt:interact_start(player, data)
	local interact_timer = 0
	if self:_timer_value() then
		interact_timer = self:_get_timer()
	end
	if SydneyHUD:GetOption("push_to_interact") and self:can_interact(player) and interact_timer >= SydneyHUD:GetOption("push_to_interact_delay") then
		local btn_cancel = SydneyHUD:GetOption("equipment_interrupt") and (managers.localization:btn_macro("use_item", true) or managers.localization:get_default_macro("BTN_USE_ITEM")) or (managers.localization:btn_macro("interact", true) or managers.localization:get_default_macro("BTN_INTERACT"))
		managers.hud:show_interact({
			text = managers.localization:text(self.tweak_data == "corpse_alarm_pager" and "sydneyhud_int_locked_pager" or "sydneyhud_int_locked", {BTN_CANCEL = btn_cancel}),
			icon = self._tweak_data.icon,
			force = true
		})
	end
	return interact_start_original(self, player, data)
end