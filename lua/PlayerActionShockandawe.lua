
local shockandawe_original = PlayerAction.ShockAndAwe.Function

function PlayerAction.ShockAndAwe.Function(player_manager, target_enemies, max_reload_increase, min_reload_increase, penalty, min_bullets, ...)
	local kill_count = 1

	local function on_enemy_killed(weapon_unit, variant)
		if alive(weapon_unit) then
			kill_count = kill_count + 1

			if kill_count >= target_enemies then
				local min_threshold = min_bullets + (weapon_unit:base():is_category("smg", "assault_rifle", "lmg") and player_manager:upgrade_value("player", "automatic_mag_increase", 0) or 0)
				local max_threshold = math.floor(min_threshold + math.log(min_reload_increase/max_reload_increase) / math.log(penalty))
				local ammo = weapon_unit:base():get_ammo_max_per_clip()
				local bonus = math.clamp(max_reload_increase * math.pow(penalty, ammo - min_threshold), min_reload_increase, max_reload_increase)

				managers.gameinfo:event("buff", "activate", "lock_n_load")
				managers.gameinfo:event("buff", "set_value", "lock_n_load", { value = bonus, show_value = true })
				managers.player:unregister_message(Message.OnEnemyKilled, "lock_n_load_buff_listener")
			end
		end
	end

	managers.player:register_message(Message.OnEnemyKilled, "lock_n_load_buff_listener", on_enemy_killed)
	shockandawe_original(player_manager, target_enemies, max_reload_increase, min_reload_increase, penalty, min_bullets, ...)
	managers.gameinfo:event("buff", "deactivate", "lock_n_load")
end