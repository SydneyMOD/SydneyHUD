
local init_original = EnemyManager.init
local register_enemy_original = EnemyManager.register_enemy
local on_enemy_died_original = EnemyManager.on_enemy_died
local on_enemy_destroyed_original = EnemyManager.on_enemy_destroyed
local register_civilian_original = EnemyManager.register_civilian
local on_civilian_died_original = EnemyManager.on_civilian_died
local on_civilian_destroyed_original = EnemyManager.on_civilian_destroyed

EnemyManager._LISTENER_CALLBACKS = {}
EnemyManager.MINION_UNITS = {}

EnemyManager._UNIT_TYPES = {
	cop = "cop",    --All non-special police
	tank = "tank",
	spooc = "spooc",
	taser = "taser",
	shield = "shield",
	sniper = "sniper",
	mobster_boss = "mobster_boss",
	hector_boss = "mobster_boss",
	hector_boss_no_armor = "mobster_boss",
	gangster = "thug",
	mobster = "thug",
	biker_escape = "thug",
	security = "security",
	gensec = "security",
	turret = "turret",      --SWAT turrets
	civilian = "civilian",  --All civilians
	phalanx_vip = "phalanx",
	phalanx_minion = "phalanx",
}

EnemyManager._UNIT_TYPE_IGNORE = {
	drunk_pilot = true,
	escort = true,
	old_hoxton_mission = true,
}

function EnemyManager:init(...)
	init_original(self, ...)
	self._minion_count = 0
	self._total_enemy_count = 0
	self._unit_count = {}
	for _, utype in pairs(EnemyManager._UNIT_TYPES) do
		self._unit_count[utype] = 0
	end
end

function EnemyManager:get_delayed_clbk_expire_t(clbk_id)
	for _, clbk in ipairs(self._delayed_clbks) do
		if clbk[1] == clbk_id then
			return clbk[2]
		end
	end
end

function EnemyManager:register_enemy(unit, ...)
	self:_change_enemy_count(unit, 1)
	return register_enemy_original(self, unit, ...)
end

function EnemyManager:on_enemy_died(unit, ...)
	self:_change_enemy_count(unit, -1)
	self:_check_minion(unit, true)
	return on_enemy_died_original(self, unit, ...)
end

function EnemyManager:on_enemy_destroyed(unit, ...)
	if alive(unit) and unit:character_damage() and not unit:character_damage():dead() then
		self:_change_enemy_count(unit, -1)
		self:_check_minion(unit)
	end
	return on_enemy_destroyed_original(self, unit, ...)
end

function EnemyManager:register_civilian(unit, ...)
	self:_change_civilian_count(unit, 1)
	return register_civilian_original(self, unit, ...)
end

function EnemyManager:on_civilian_died(unit, ...)
	self:_change_civilian_count(unit, -1)
	return on_civilian_died_original(self, unit, ...)
end

function EnemyManager:on_civilian_destroyed(unit, ...)
	if alive(unit) and unit:character_damage() and not unit:character_damage():dead() then
		self:_change_civilian_count(unit, -1)
	end
	return on_civilian_destroyed_original(self, unit, ...)
end

function EnemyManager:_check_minion(unit, killed)
	if EnemyManager.MINION_UNITS[unit:key()] then
		self:remove_minion_unit(unit, killed)
	end
end

function EnemyManager:_change_enemy_count(unit, change)
	local tweak = unit:base()._tweak_table
	if not EnemyManager._UNIT_TYPE_IGNORE[tweak] then
		local u_type = EnemyManager._UNIT_TYPES[tweak] or "cop"
		self._total_enemy_count = self._total_enemy_count + change
		self._unit_count[u_type] = self._unit_count[u_type] + change
		self._do_listener_callback("on_total_enemy_count_change", self._total_enemy_count)
		self._do_listener_callback("on_" .. u_type .. "_count_change", self._unit_count[u_type])
	end
end

function EnemyManager:_change_swat_turret_count(change)
	self._unit_count.turret = self._unit_count.turret + change
	self._do_listener_callback("on_turret_count_change", self._unit_count.turret)
end

function EnemyManager:_change_civilian_count(unit, change)
	local tweak = unit:base()._tweak_table
	if not EnemyManager._UNIT_TYPE_IGNORE[tweak] then
		self._unit_count.civilian = self._unit_count.civilian + change
		self._do_listener_callback("on_civilian_count_change", self._unit_count.civilian)
	end
end

function EnemyManager:unit_count(u_type)
	return u_type and (self._unit_count[u_type] or 0) or self._total_enemy_count
end

function EnemyManager:add_minion_unit(unit, owner_id, health_mult, damage_mult)
	if not EnemyManager.MINION_UNITS[unit:key()] then
		self._minion_count = self._minion_count + 1
		EnemyManager.MINION_UNITS[unit:key()] = { unit = unit }
		self._do_listener_callback("on_add_minion_unit", unit)
		self._do_listener_callback("on_minion_count_change", self._minion_count)
	end
	if not EnemyManager.MINION_UNITS[unit:key()].owner_id and owner_id then
		EnemyManager.MINION_UNITS[unit:key()].owner_id = owner_id
		self._do_listener_callback("on_minion_set_owner", unit, owner_id)
	end
	if not EnemyManager.MINION_UNITS[unit:key()].health_mult and health_mult then
		EnemyManager.MINION_UNITS[unit:key()].health_mult = health_mult
		self._do_listener_callback("on_minion_set_health_mult", unit, health_mult)
	end
	if not EnemyManager.MINION_UNITS[unit:key()].damage_mult and damage_mult then
		EnemyManager.MINION_UNITS[unit:key()].damage_mult = damage_mult
		self._do_listener_callback("on_minion_set_damage_mult", unit, damage_mult)
	end
end

function EnemyManager:remove_minion_unit(unit, killed)
	if EnemyManager.MINION_UNITS[unit:key()] then
		self._minion_count = self._minion_count - 1
		EnemyManager.MINION_UNITS[unit:key()] = nil
		self._do_listener_callback("on_remove_minion_unit", unit, killed)
		self._do_listener_callback("on_minion_count_change", self._minion_count)
	end
end

function EnemyManager:update_minion_health(unit, health)
	if EnemyManager.MINION_UNITS[unit:key()] then
		EnemyManager.MINION_UNITS[unit:key()].health = health
		self._do_listener_callback("on_minion_health_change", unit, health)
	end
end

function EnemyManager:minion_count()
	return table.size(self.MINION_UNITS)
end

function EnemyManager.register_listener_clbk(name, event, clbk)
	EnemyManager._LISTENER_CALLBACKS[event] = EnemyManager._LISTENER_CALLBACKS[event] or {}
	EnemyManager._LISTENER_CALLBACKS[event][name] = clbk
end

function EnemyManager.unregister_listener_clbk(name, event)
	for event_id, listeners in pairs(EnemyManager._LISTENER_CALLBACKS) do
		if not event or event_id == event then
			for id, _ in pairs(listeners) do
				if id == name then
					EnemyManager._LISTENER_CALLBACKS[event_id][id] = nil
					break
				end
			end
		end
	end
end

function EnemyManager._do_listener_callback(event, ...)
	if EnemyManager._LISTENER_CALLBACKS[event] then
		for _, clbk in pairs(EnemyManager._LISTENER_CALLBACKS[event]) do
			clbk(...)
		end
	end
end
