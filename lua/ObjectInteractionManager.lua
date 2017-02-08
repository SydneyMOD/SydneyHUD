
local init_original = ObjectInteractionManager.init
local update_original = ObjectInteractionManager.update
local add_unit_original = ObjectInteractionManager.add_unit
local remove_unit_original = ObjectInteractionManager.remove_unit
local interact_original = ObjectInteractionManager.interact
local _update_targeted_original = ObjectInteractionManager._update_targeted

function ObjectInteractionManager:init(...)
	init_original(self, ...)
	self._queued_units = {}
	if managers.gameinfo then
		managers.gameinfo:register_listener("pager_contour_remover", "pager", "answered", callback(nil, _G, "pager_answered_clbk"))
	end
end

function pager_answered_clbk(event, key, data)
	managers.enemy:add_delayed_clbk("contour_remove_" .. key, callback(nil, _G, "remove_answered_pager_contour_clbk", data.unit), Application:time() + 0.01)
end

function remove_answered_pager_contour_clbk(unit)
	if alive(unit) and SydneyHUD:GetOption("remove_answered_pager_contour") then
		unit:contour():remove(tweak_data.interaction.corpse_alarm_pager.contour_preset)
	end
end

function ObjectInteractionManager:update(t, ...)
	update_original(self, t, ...)
	self:_process_queued_units(t)
end

function ObjectInteractionManager:add_unit(unit, ...)
	self:add_unit_clbk(unit)
	return add_unit_original(self, unit, ...)
end

function ObjectInteractionManager:remove_unit(unit, ...)
	self:remove_unit_clbk(unit)
	return remove_unit_original(self, unit, ...)
end

function ObjectInteractionManager:interact(...)
	if alive(self._active_unit) and self._active_unit:interaction().tweak_data == "corpse_alarm_pager" then
		managers.gameinfo:event("pager", "set_answered", tostring(self._active_unit:key()))
	end

	return interact_original(self, ...)
end

function ObjectInteractionManager:add_unit_clbk(unit)
	self._queued_units[tostring(unit:key())] = unit
end

function ObjectInteractionManager:remove_unit_clbk(unit, interact_id)
	local key = tostring(unit:key())
	if self._queued_units[key] then
		self._queued_units[key] = nil
	else
		local id = interact_id or unit:interaction().tweak_data
		local editor_id = unit:editor_id()
		managers.gameinfo:event("interactive_unit", "remove", key, { unit = unit, editor_id = editor_id, interact_id = id })
	end
end

function ObjectInteractionManager:_process_queued_units(t)
	for key, unit in pairs(self._queued_units) do
		if alive(unit) then
			local interact_id = unit:interaction().tweak_data
			local editor_id = unit:editor_id()
			managers.gameinfo:event("interactive_unit", "add", key, { unit = unit, editor_id = editor_id, interact_id = interact_id })
		end
	end

	self._queued_units = {}
end

function ObjectInteractionManager:_update_targeted(...)
	_update_targeted_original(self, ...)
	if SydneyHUD:GetOption("hold_to_pick") then
		if alive(self._active_unit) then
			local t = Application:time()
			if self._active_unit:base() and self._active_unit:base().small_loot and managers.menu:get_controller():get_input_bool("interact") and (t >= (self._next_auto_pickup_t or 0)) then
				self._next_auto_pickup_t = t + SydneyHUD:GetOption("hold_to_pick_delay")
				self:interact(managers.player:player_unit())
			end
		end
	end
end
