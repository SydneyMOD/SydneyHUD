
local init_original = GrenadeCrateBase.init
local _set_visual_stage_original = GrenadeCrateBase._set_visual_stage
local destroy_original = GrenadeCrateBase.destroy
local custom_init_original = CustomGrenadeCrateBase.init
local custom_destroy_original = CustomGrenadeCrateBase.destroy

GrenadeCrateBase.SPAWNED_BAGS = {}
GrenadeCrateBase.AGGREGATED_BAGS = {}

--TODO: Fix this dumb-ass stacking implementation, preferably before I get to pay for being lazy

function GrenadeCrateBase:init(unit, ...)
	GrenadeCrateBase.SPAWNED_BAGS[unit:key()] = { unit = unit }
	self._do_listener_callback("on_bag_create", unit, "grenade_crate")
	init_original(self, unit, ...)
	GrenadeCrateBase.SPAWNED_BAGS[self._unit:key()].max_amount = self._max_grenade_amount
	self._do_listener_callback("on_bag_max_amount_update", unit, self._max_grenade_amount)
end

function GrenadeCrateBase:_set_visual_stage(...)
	if self._is_aggregated then
		GrenadeCrateBase.AGGREGATED_BAGS[self._unit:key()].amount = self._grenade_amount
		local total = GrenadeCrateBase.total_aggregated_amount()
		self._do_listener_callback("on_bag_amount_update", nil, total)
		if total <= 0 then
			GrenadeCrateBase.AGGREAGATED_ITEM_ACTIVE = nil
			self._do_listener_callback("on_bag_set_active", nil, false)
		end
	else
		GrenadeCrateBase.SPAWNED_BAGS[self._unit:key()].amount = self._grenade_amount
		self._do_listener_callback("on_bag_amount_update", self._unit, self._grenade_amount)
	end

	return _set_visual_stage_original(self, ...)
end

function GrenadeCrateBase:destroy(...)
	GrenadeCrateBase.SPAWNED_BAGS[self._unit:key()] = nil
	self._do_listener_callback("on_bag_destroy", self._unit)
	return destroy_original(self, ...)
end

function CustomGrenadeCrateBase:init(unit, ...)
	self._is_aggregated = true
	GrenadeCrateBase.AGGREGATED_BAGS[unit:key()] = { unit = unit }
	custom_init_original(self, unit, ...)
	GrenadeCrateBase.AGGREGATED_BAGS[self._unit:key()].max_amount = self._max_grenade_amount
	self._do_listener_callback("on_bag_max_amount_update", nil, GrenadeCrateBase.total_aggregated_max_amount())
end

function CustomGrenadeCrateBase:destroy(...)
	GrenadeCrateBase.AGGREGATED_BAGS[self._unit:key()] = nil
	if GrenadeCrateBase.total_aggregated_amount() <= 0 then
		self._do_listener_callback("on_bag_destroy", nil)
	else
		self._do_listener_callback("on_bag_amount_update", nil, GrenadeCrateBase.total_aggregated_amount())
	end
	return custom_destroy_original(self, ...)
end


function GrenadeCrateBase.total_aggregated_amount()
	local amount = 0
	for _, data in pairs(GrenadeCrateBase.AGGREGATED_BAGS) do
		amount = amount + data.amount
	end
	return amount
end

function GrenadeCrateBase.total_aggregated_max_amount()
	local max_amount = 0
	for _, data in pairs(GrenadeCrateBase.AGGREGATED_BAGS) do
		max_amount = max_amount + data.max_amount
	end
	return max_amount
end
