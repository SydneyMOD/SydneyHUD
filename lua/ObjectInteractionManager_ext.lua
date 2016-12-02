
local init_original = ObjectInteractionManager.init
local update_original = ObjectInteractionManager.update
local add_unit_original = ObjectInteractionManager.add_unit
local remove_unit_original = ObjectInteractionManager.remove_unit
local interact_original = ObjectInteractionManager.interact
local interupt_action_interact_original = ObjectInteractionManager.interupt_action_interact

ObjectInteractionManager._LISTENER_CALLBACKS = {}
ObjectInteractionManager.ACTIVE_PAGERS = {}

ObjectInteractionManager.COMPOSITE_LOOT_UNITS = {
	[103428] = 4, [103429] = 3, [103430] = 2, [103431] = 1, --Shadow Raid armor
	gen_pku_warhead_box = 2,        --[132925] = 2, [132926] = 2, [132927] = 2,     --Meltdown warhead cases
	--hold_open_bomb_case = 4,      --The Bomb heists cases, extra cases on docks screws with counter...
	--[102913] = 1, [102915] = 1, [102916] = 1,     --Train Heist turret (unit fixed, need workaround)
}

ObjectInteractionManager.LOOT_TYPE_FROM_INTERACTION_ID = {
	--If you add stuff here, make sure you add it to HUDList.LootItem.LOOT_ICON_MAP as well
	weapon_case =                                   "weapon",
	samurai_armor =                         "armor",
	gen_pku_warhead_box =   "warhead",
	--hold_open_bomb_case = "bomb"
	--crate_loot_crowbar =                  "container",
	--crate_loot =                                          "container",
	--crate_loot_close =                            "container",
	--Crates and suitcases etc interaction ID's here -> type "container"
}

ObjectInteractionManager.LOOT_TYPE_FROM_CARRY_ID = {
	--If you add stuff here, make sure you add it to HUDList.LootItem.LOOT_ICON_MAP as well
	gold =									"gold",
	money =									"money",
	diamonds =								"jewelry",
	painting =								"painting",
	mus_artifact_paint =					"painting",
	coke =									"coke",
	coke_pure =								"coke",
	meth =									"meth",
	weapon =								"weapon",
	circuit =								"server",
	turret =								"turret",
	ammo =									"shell",
	artifact_statue =						"artifact",
	mus_artifact =							"artifact",
	samurai_suit =							"armor",
	sandwich =								"toast",
	hope_diamond =							"diamond",
	cro_loot1 =								"bomb",
	cro_loot2 =								"bomb",
	evidence_bag =							"evidence",
	warhead =								"warhead",
	din_pig =								"pig",
	safe_wpn =								"safe",
	safe_ovk =								"safe",
	unknown =								"dentist",
	meth_half =								"meth",
	masterpiece_painting =					"painting",
	master_server =							"server",
	lost_artifact =							"artifact",
	prototype =								"prototype",
	present =								"present",
	goat =									"goat",
	counterfeit_money =						"money",
	mad_master_server_value_1 =				"server",
	mad_master_server_value_2 =				"server",
	mad_master_server_value_3 =				"server",
	mad_master_server_value_4 =				"server",
	weapon_glock =							"weapon",
	weapon_scar =							"weapon",
	drk_bomb_part = 						"bomb"
}

ObjectInteractionManager.LOOT_TYPE_LEVEL_COMPENSATION = {
	framing_frame_3 =                                               { gold = 16, },
}

ObjectInteractionManager.LOOT_BAG_INTERACTION_ID = {
	painting_carry_drop = true,     --Painting
	carry_drop = true,                                      --Generic bag
}

ObjectInteractionManager.IGNORE_EDITOR_ID = {
	watchdogs_2 = { --Watchdogs day 2 (8x coke)
		[100054] = true,
		[100058] = true,
		[100426] = true,
		[100427] = true,
		[100428] = true,
		[100429] = true,
		[100491] = true,
		[100492] = true,
		[100494] = true,
		[100495] = true,
	},
	family = {      --Diamond store (1x money)
		[100899] = true,
	},      --Hotline Miami day 1 (1x money)
	mia_1 = {       --Hotline Miami day 1 (1x money)
		[104526] = true,
	},
	welcome_to_the_jungle_1 = {     --Big Oil day 1 (1x money, 1x gold)
		[100886] = true,
		[100872] = true,
	},
	mus = { --The Diamond (RNG)
		[300047] = true,
		[300686] = true,
		[300457] = true,
		[300458] = true,
		[301343] = true,
		[301346] = true,
	},
	arm_und = {     --Transport: Underpass (8x money)
		[101237] = true,
		[101238] = true,
		[101239] = true,
		[103835] = true,
		[103836] = true,
		[103837] = true,
		[103838] = true,
		[101240] = true,
	},
	ukrainian_job = {       --Ukrainian Job (1x money)
		[101514] = true,
	},
	firestarter_2 = {       --Firestarter day 2 (1x keycard)
		[107208] = true,
	},
	big = { --Big Bank (1x keycard)
		[101499] = true,
	},
	roberts = {     --GO Bank (1x keycard)
		[106104] = true,
	},
}
ObjectInteractionManager.IGNORE_EDITOR_ID.watchdogs_2_day = table.deep_map_copy(ObjectInteractionManager.IGNORE_EDITOR_ID.watchdogs_2)
ObjectInteractionManager.IGNORE_EDITOR_ID.welcome_to_the_jungle_1_night = table.deep_map_copy(ObjectInteractionManager.IGNORE_EDITOR_ID.welcome_to_the_jungle_1)

ObjectInteractionManager.SPECIAL_PICKUP_TYPE_FROM_INTERACTION_ID = {
	--If you add stuff here, make sure you add it to HUDList.SpecialPickupItem.SPECIAL_PICKUP_ICON_MAP as well
	gen_pku_crowbar =					"crowbar",
	pickup_keycard =					"keycard",
	pickup_hotel_room_keycard =			"keycard",
	gage_assignment =					"courier",
	pickup_boards =						"planks",
	stash_planks_pickup =				"planks",
	muriatic_acid =						"meth_ingredients",
	hydrogen_chloride =					"meth_ingredients",
	caustic_soda =						"meth_ingredients",
	gen_pku_blow_torch =				"Blowtorch"
}

ObjectInteractionManager.EQUIPMENT_INTERACTION_ID = {
	firstaid_box = { class = "DoctorBagBase", offset = -1 },
	ammo_bag = { class = "AmmoBagBase" },
	doctor_bag = { class = "DoctorBagBase" },
	bodybags_bag = { class = "BodyBagsBagBase" },
	grenade_crate = { class = "GrenadeCrateBase" },
}

ObjectInteractionManager.TRIGGERS = {
	[136843] = {
		136844, 136845, 136846, 136847, --HB armory ammo shelves
		136859, 136860, 136864, 136865, 136866, 136867, 136868, 136869, 136870, --HB armory grenades
	},
	[151868] = { 151611 }, --GGC armory ammo shelf 1
	[151869] = {
		151612, --GGC armory ammo shelf 2
		151596, 151597, 151598, --GGC armory grenades
	},
	--[101835] = { 101470, 101472, 101473 },        --HB infirmary med boxes (not needed, triggers on interaction activation)
}

ObjectInteractionManager.INTERACTION_TRIGGERS = {
	requires_ecm_jammer_double = {
		[Vector3(-2217.05, 2415.52, -354.502)] = 136843,        --HB armory door 1
		[Vector3(1817.05, 3659.48, 45.4985)] = 136843,  --HB armory door 2
	},
	drill = {
		[Vector3(142, 3098, -197)] = 151868,    --GGC armory cage 1 alt 1
		[Vector3(-166, 3413, -197)] = 151869,   --GGC armory cage 2 alt 1
		[Vector3(3130, 1239, -195.5)] = 151868, --GGC armory cage X alt 2       (may be reversed)
		[Vector3(3445, 1547, -195.5)] = 151869, --GGC armory cage Y alt 2       (may be reversed)
	},
}

function ObjectInteractionManager:init(...)
	init_original(self, ...)
	self._queued_units = {}
	self._pager_count = 0
	self._total_loot_count = { bagged = 0, unbagged = 0 }
	self._loot_count = {}
	self._loot_units_added = {}
	self._special_pickup_count = {}
	for _, type_id in pairs(ObjectInteractionManager.LOOT_TYPE_FROM_CARRY_ID) do
		self._loot_count[type_id] = { bagged = 0, unbagged = 0 }
	end
	for _, type_id in pairs(ObjectInteractionManager.LOOT_TYPE_FROM_INTERACTION_ID) do
		self._loot_count[type_id] = { bagged = 0, unbagged = 0 }
	end
	for _, type_id in pairs(ObjectInteractionManager.SPECIAL_PICKUP_TYPE_FROM_INTERACTION_ID) do
		self._special_pickup_count[type_id] = 0
	end
	self._unit_triggers = {}
	self._trigger_blocks = {}
	GroupAIStateBase.register_listener_clbk("ObjectInteractionManager_cancel_pager_listener", "on_whisper_mode_change", callback(self, self, "_whisper_mode_change"))
end

function ObjectInteractionManager:update(t, ...)
	update_original(self, t, ...)
	self:_check_queued_units(t)
end

function ObjectInteractionManager:add_unit(unit, ...)
	for pos, trigger_id in pairs(ObjectInteractionManager.INTERACTION_TRIGGERS[unit:interaction().tweak_data] or {}) do
		if mvector3.distance(unit:position(), pos) <= 10 then
			self:block_trigger(trigger_id, true)
			break
		end
	end
	table.insert(self._queued_units, unit)
	return add_unit_original(self, unit, ...)
end

function ObjectInteractionManager:remove_unit(unit, ...)
	for pos, trigger_id in pairs(ObjectInteractionManager.INTERACTION_TRIGGERS[unit:interaction().tweak_data] or {}) do
		if mvector3.distance(unit:position(), pos) <= 10 then
			self._trigger_blocks[trigger_id] = false
			break
		end
	end
	self:_check_remove_unit(unit)
	return remove_unit_original(self, unit, ...)
end

function ObjectInteractionManager:interact(...)
	if alive(self._active_unit) and self._active_unit:interaction().tweak_data == "corpse_alarm_pager" then
		self:pager_answered(self._active_unit)
	end
	return interact_original(self, ...)
end

function ObjectInteractionManager:interupt_action_interact(...)
	if alive(self._active_unit) and self._active_unit:interaction() and self._active_unit:interaction().tweak_data == "corpse_alarm_pager" then
		self:pager_ended(self._active_unit)
	end
	return interupt_action_interact_original(self, ...)
end


function ObjectInteractionManager:_check_queued_units(t)
	local level_id = managers.job:current_level_id()
	local ignore_ids = level_id and ObjectInteractionManager.IGNORE_EDITOR_ID[level_id]
	for _, unit in ipairs(self._queued_units) do
		if alive(unit) then
			local editor_id = unit:editor_id()
			if not (ignore_ids and ignore_ids[editor_id]) then
				local carry_id = unit:carry_data() and unit:carry_data():carry_id()
				local interaction_id = unit:interaction().tweak_data
				local loot_type_id = carry_id and ObjectInteractionManager.LOOT_TYPE_FROM_CARRY_ID[carry_id] or ObjectInteractionManager.LOOT_TYPE_FROM_INTERACTION_ID[interaction_id]
				local special_pickup_type_id = ObjectInteractionManager.SPECIAL_PICKUP_TYPE_FROM_INTERACTION_ID[interaction_id]
				if ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id] then
					local data = ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id]
					local blocked
					for trigger_id, editor_ids in pairs(ObjectInteractionManager.TRIGGERS) do
						if table.contains(editor_ids, editor_id) then
							blocked = self._trigger_blocks[trigger_id]
							self._unit_triggers[trigger_id] = self._unit_triggers[trigger_id] or {}
							table.insert(self._unit_triggers[trigger_id], { unit = unit, class = data.class, offset = data.offset })
							break
						end
					end
					--io.write("Equipment unit " .. tostring(editor_id) .. " (" .. tostring(data.class) .. ") made interactive, blocked: " .. tostring(blocked) .. "\n")
					unit:base():set_equipment_active(data.class, not blocked, data.offset)
				elseif loot_type_id then
					local count = ObjectInteractionManager.COMPOSITE_LOOT_UNITS[editor_id] or ObjectInteractionManager.COMPOSITE_LOOT_UNITS[interaction_id] or 1
					self._loot_units_added[unit:key()] = loot_type_id
					self:_change_loot_count(unit, loot_type_id, count, ObjectInteractionManager.LOOT_BAG_INTERACTION_ID[interaction_id] or false)
				elseif special_pickup_type_id then
					self:_change_special_pickup_count(unit, special_pickup_type_id, 1)
				elseif interaction_id == "corpse_alarm_pager" then
					self:_pager_started(unit)
				end
				self._do_listener_callback("on_unit_added", unit)
			end
		end
	end
	self._queued_units = {}
end

function ObjectInteractionManager:_check_remove_unit(unit)
	for i, queued_unit in ipairs(self._queued_units) do
		if queued_unit:key() == unit:key() then
			table.remove(self._queued_units, i)
			return
		end
	end
	local level_id = managers.job:current_level_id()
	local ignore_ids = level_id and ObjectInteractionManager.IGNORE_EDITOR_ID[level_id]
	local editor_id = unit:editor_id()
	if not (ignore_ids and ignore_ids[editor_id]) then
		local carry_id = unit:carry_data() and unit:carry_data():carry_id()
		local interaction_id = unit:interaction().tweak_data
		local loot_type_id = carry_id and ObjectInteractionManager.LOOT_TYPE_FROM_CARRY_ID[carry_id] or ObjectInteractionManager.LOOT_TYPE_FROM_INTERACTION_ID[interaction_id]
		local special_pickup_type_id = ObjectInteractionManager.SPECIAL_PICKUP_TYPE_FROM_INTERACTION_ID[interaction_id]
		if ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id] then
			unit:base():set_equipment_active(ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id].class, false)
		elseif loot_type_id or self._loot_units_added[unit:key()] then
			local count = -(ObjectInteractionManager.COMPOSITE_LOOT_UNITS[editor_id] or ObjectInteractionManager.COMPOSITE_LOOT_UNITS[interaction_id] or 1)
			loot_type_id = loot_type_id or self._loot_units_added[unit:key()]
			self:_change_loot_count(unit, loot_type_id, count, ObjectInteractionManager.LOOT_BAG_INTERACTION_ID[interaction_id] or false)
			self._loot_units_added[unit:key()] = nil
		elseif special_pickup_type_id then
			self:_change_special_pickup_count(unit, special_pickup_type_id, -1)
		elseif interaction_id == "corpse_alarm_pager" then
			self:pager_ended(unit)
		end
		self._do_listener_callback("on_unit_removed", unit)
	end
end

function ObjectInteractionManager:_change_loot_count(unit, loot_type, change, bagged)
	self._total_loot_count.bagged = self._total_loot_count.bagged + (bagged and change or 0)
	self._loot_count[loot_type].bagged = self._loot_count[loot_type].bagged + (bagged and change or 0)
	self._total_loot_count.unbagged = self._total_loot_count.unbagged + (bagged and 0 or change)
	self._loot_count[loot_type].unbagged = self._loot_count[loot_type].unbagged + (bagged and 0 or change)
	local total_compensation = self:_get_loot_level_compensation()
	local type_compensation = self:_get_loot_level_compensation(loot_type)
	self._do_listener_callback("on_total_loot_count_change", self._total_loot_count.unbagged - total_compensation, self._total_loot_count.bagged)
	self._do_listener_callback("on_" .. loot_type .. "_count_change", self._loot_count[loot_type].unbagged - type_compensation, self._loot_count[loot_type].bagged)
end

function ObjectInteractionManager:_get_loot_level_compensation(loot_type)
	local count = 0
	local level_id = managers.job and managers.job:current_level_id()
	local level_data = level_id and ObjectInteractionManager.LOOT_TYPE_LEVEL_COMPENSATION[level_id]
	for id, amount in pairs(level_data or {}) do
		if not loot_type or loot_type == id then
			count = count + amount
		end
	end
	return count
end

function ObjectInteractionManager:loot_count(loot_type)
	local data = loot_type and self._loot_count[loot_type] or self._total_loot_count
	local compensation = self:_get_loot_level_compensation(loot_type)
	return data.unbagged - compensation, data.bagged
end

function ObjectInteractionManager:_change_special_pickup_count(unit, pickup_type, change)
	self._special_pickup_count[pickup_type] = self._special_pickup_count[pickup_type] + change
	self._do_listener_callback("on_" .. pickup_type .. "_count_change", self._special_pickup_count[pickup_type])
end

function ObjectInteractionManager:special_pickup_count(pickup_type)
	return self._special_pickup_count[pickup_type]
end

function ObjectInteractionManager:_pager_started(unit)
	if not ObjectInteractionManager.ACTIVE_PAGERS[unit:key()] then
		self._pager_count = self._pager_count + 1
		ObjectInteractionManager.ACTIVE_PAGERS[unit:key()] = { unit = unit }
		self._do_listener_callback("on_pager_count_change", self._pager_count)
		self._do_listener_callback("on_pager_started", unit)
	end
end

function ObjectInteractionManager:pager_ended(unit)
	if ObjectInteractionManager.ACTIVE_PAGERS[unit:key()] then
		ObjectInteractionManager.ACTIVE_PAGERS[unit:key()] = nil
		self._do_listener_callback("on_pager_ended", unit)
	end
end

function ObjectInteractionManager:pager_answered(unit)
	if ObjectInteractionManager.ACTIVE_PAGERS[unit:key()] and not ObjectInteractionManager.ACTIVE_PAGERS[unit:key()].answered then
		ObjectInteractionManager.ACTIVE_PAGERS[unit:key()].answered = true
		self._do_listener_callback("on_pager_answered", unit)
	end
end

function ObjectInteractionManager:_whisper_mode_change(status)
	if not status then
		for _, data in pairs(ObjectInteractionManager.ACTIVE_PAGERS) do
			self:pager_ended(data.unit)
		end
		self._do_listener_callback("on_remove_all_pagers")
	end
end

function ObjectInteractionManager:used_pager_count()
	return self._pager_count
end

function ObjectInteractionManager:block_trigger(trigger_id, status)
	if ObjectInteractionManager.TRIGGERS[trigger_id] then
		--io.write("ObjectInteractionManager:block_trigger(" .. tostring(trigger_id) .. ", " .. tostring(status) .. ")\n")
		self._trigger_blocks[trigger_id] = status
		for _, data in ipairs(self._unit_triggers[trigger_id] or {}) do
			if alive(data.unit) then
				--io.write("Set active " .. tostring(data.unit:editor_id()) .. ": " .. tostring(not status) .. "\n")
				data.unit:base():set_equipment_active(data.class, not status, data.offset)
			end
		end
	end
end


function ObjectInteractionManager.register_listener_clbk(name, event, clbk)
	ObjectInteractionManager._LISTENER_CALLBACKS[event] = ObjectInteractionManager._LISTENER_CALLBACKS[event] or {}
	ObjectInteractionManager._LISTENER_CALLBACKS[event][name] = clbk
end

function ObjectInteractionManager.unregister_listener_clbk(name, event)
	for event_id, listeners in pairs(ObjectInteractionManager._LISTENER_CALLBACKS) do
		if not event or event_id == event then
			for id, _ in pairs(listeners) do
				if id == name then
					ObjectInteractionManager._LISTENER_CALLBACKS[event_id][id] = nil
					break
				end
			end
		end
	end
end

function ObjectInteractionManager._do_listener_callback(event, ...)
	if ObjectInteractionManager._LISTENER_CALLBACKS[event] then
		for _, clbk in pairs(ObjectInteractionManager._LISTENER_CALLBACKS[event]) do
			clbk(...)
		end
	end
end
