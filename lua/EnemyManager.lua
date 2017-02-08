
local on_enemy_registered_original = EnemyManager.on_enemy_registered
local on_enemy_unregistered_original = EnemyManager.on_enemy_unregistered
local register_civilian_original = EnemyManager.register_civilian
local on_civilian_died_original = EnemyManager.on_civilian_died
local on_civilian_destroyed_original = EnemyManager.on_civilian_destroyed

function EnemyManager:on_enemy_registered(unit, ...)
	managers.gameinfo:event("unit", "add", tostring(unit:key()), { unit = unit })
	return on_enemy_registered_original(self, unit, ...)
end

function EnemyManager:on_enemy_unregistered(unit, ...)
	managers.gameinfo:event("unit", "remove", tostring(unit:key()))
	return on_enemy_unregistered_original(self, unit, ...)
end

function EnemyManager:register_civilian(unit, ...)
	managers.gameinfo:event("unit", "add", tostring(unit:key()), { unit = unit })
	return register_civilian_original(self, unit, ...)
end

function EnemyManager:on_civilian_died(unit, ...)
	managers.gameinfo:event("unit", "remove", tostring(unit:key()))
	return on_civilian_died_original(self, unit, ...)
end

function EnemyManager:on_civilian_destroyed(unit, ...)
	managers.gameinfo:event("unit", "remove", tostring(unit:key()))
	return on_civilian_destroyed_original(self, unit, ...)
end

function EnemyManager:get_delayed_clbk_expire_t(clbk_id)
	for _, clbk in ipairs(self._delayed_clbks) do
		if clbk[1] == clbk_id then
			return clbk[2]
		end
	end
end
