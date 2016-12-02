
--Propagates down to equipment (and other things we don't care about). Just make sure events are named appropriately to avoid overlap
UnitBase._LISTENER_CALLBACKS = {}

function UnitBase:set_equipment_active(equipment, status, offset)
	local base_class = _G[equipment]
	local bag_data = base_class.SPAWNED_BAGS[self._unit:key()]
	if bag_data then
		bag_data.active = status
		bag_data.amount_offset = offset or 0
		base_class._do_listener_callback("on_bag_set_active", self._unit, status)
		base_class._do_listener_callback("on_bag_amount_offset_update", self._unit, offset or 0)
	elseif self._is_aggregated and status then
		base_class.AGGREAGATED_ITEM_ACTIVE = true
		base_class._do_listener_callback("on_bag_set_active", nil, true)
	end
end

function UnitBase.register_listener_clbk(name, event, clbk)
	UnitBase._LISTENER_CALLBACKS[event] = GroupAIStateBase._LISTENER_CALLBACKS[event] or {}
	UnitBase._LISTENER_CALLBACKS[event][name] = clbk
end

function UnitBase.unregister_listener_clbk(name, event)
	for event_id, listeners in pairs(UnitBase._LISTENER_CALLBACKS) do
		if not event or event_id == event then
			for id, _ in pairs(listeners) do
				if id == name then
					UnitBase._LISTENER_CALLBACKS[event_id][id] = nil
					break
				end
			end
		end
	end
end

function UnitBase._do_listener_callback(event, ...)
	if UnitBase._LISTENER_CALLBACKS[event] then
		for _, clbk in pairs(UnitBase._LISTENER_CALLBACKS[event]) do
			clbk(...)
		end
	end
end
