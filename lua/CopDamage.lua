
local convert_to_criminal_original = CopDamage.convert_to_criminal
local _on_damage_received_original = CopDamage._on_damage_received
local chk_killshot_original = CopDamage.chk_killshot
local bullet_original = CopDamage.damage_bullet
local explosion_original = CopDamage.damage_explosion
local melee_original = CopDamage.damage_melee
local fire_original = CopDamage.damage_fire
local sync_bullet_original = CopDamage.sync_damage_bullet
local sync_explosion_original = CopDamage.sync_damage_explosion
local sync_melee_original = CopDamage.sync_damage_melee
local sync_fire_original = CopDamage.sync_damage_fire
local sync_damage_dot_original = CopDamage.sync_damage_dot

function CopDamage:_update_minion_dmg_resist(data)
	if alive(self._unit) then
		managers.gameinfo:event("minion", "set_damage_resistance", tostring(self._unit:key()), data)
	end
end

function CopDamage:convert_to_criminal(...)
	convert_to_criminal_original(self, ...)
	if self._damage_reduction_multiplier < 1 then
		local key = tostring(self._unit:key())
		local data = { damage_resistance = self._damage_reduction_multiplier }
		managers.enemy:add_delayed_clbk(key .. "_update_minion_dmg_resist", callback(self, self, "_update_minion_dmg_resist", data), 0)
	end
end

function CopDamage:_on_damage_received(damage_info, ...)
	if self._unit:in_slot(16) then
		managers.gameinfo:event("minion", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
	end
	return _on_damage_received_original(self, damage_info, ...)
end

Hooks:PreHook( CopDamage , "_on_damage_received" , "uHUDPreCopDamageOnDamageReceived" , function( self , damage_info )

	if self._uws and alive( self._uws ) then
		self._uws:panel():stop()
		World:newgui():destroy_workspace( self._uws )
		self._uws = nil
	end

	self._uws = World:newgui():create_world_workspace( 165 , 100 , self._unit:movement():m_head_pos() + Vector3( 0 , 0 , 70 ) , Vector3( 50 , 0 , 0 ) , Vector3( 0 , 0 , -50 ) )
	self._uws:set_billboard( self._uws.BILLBOARD_BOTH )

	local panel = self._uws:panel():panel({
		visible = SydneyHUD:GetOption("show_damage_popup"),
		name 	= "damage_panel",
		layer 	= 0
	})

	local text = panel:text({
		text 		= string.format( damage_info.damage * 10 >= 10 and "%d" or "%.1f" , damage_info.damage * 10 ),
		layer 		= 1,
		align 		= "left",
		vertical 	= "bottom",
		font 		= tweak_data.menu.pd2_large_font,
		font_size 	= 70,
		color 		= Color.white
	})

	local attacker_unit = damage_info and damage_info.attacker_unit

	if alive( attacker_unit ) and attacker_unit:base() and attacker_unit:base().thrower_unit then
		attacker_unit = attacker_unit:base():thrower_unit()
	end

	if attacker_unit and managers.network:session() and managers.network:session():peer_by_unit( attacker_unit ) then
		local peer_id = managers.network:session():peer_by_unit( attacker_unit ):id()
		local c = tweak_data.chat_colors[ peer_id ]
		text:set_color( c )
	end

	if damage_info.result.type == "death" then
		text:set_text( managers.localization:get_default_macro( "BTN_SKULL" ) .. text:text() )
		text:set_range_color( 0 , 1 , Color.red )
	end

	panel:animate( function( p )
		over( 5 , function( o )
			self._uws:set_world( 165 , 100 , self._unit:movement():m_head_pos() + Vector3( 0 , 0 , 70 ) + Vector3( 0 , 0 , math.lerp( 0 , 50 , o ) ) , Vector3( 50 , 0 , 0 ) , Vector3( 0 , 0 , -50 ) )
			text:set_color( text:color():with_alpha( 0.5 + ( math.sin( o * 750 ) + 0.5 ) / 4 ) )
			panel:set_alpha( math.lerp( 1 , 0 , o ) )
		end )
		panel:remove( text )
		World:newgui():destroy_workspace( self._uws )
	end )

end )

Hooks:PostHook( CopDamage , "destroy" , "uHUDPostCopDamageDestroy" , function( self , ... )

	if self._uws and alive( self._uws ) then
		World:newgui():destroy_workspace( self._uws )
		self._uws = nil
	end

end )

function CopDamage:chk_killshot(attacker_unit, ...)
	if alive(attacker_unit) then
		local key = tostring(attacker_unit:key())
		if attacker_unit:in_slot(16) and managers.gameinfo:get_minions(key) then
			managers.gameinfo:event("minion", "increment_kills", key)
		elseif attacker_unit:in_slot(25) and managers.gameinfo:get_sentries(key) then
			managers.gameinfo:event("sentry", "increment_kills", key)
		end
	end
	return chk_killshot_original(self, attacker_unit, ...)
end

function CopDamage:_process_kill(aggressor, i_body)
	if alive(aggressor) and aggressor:base() then
		if aggressor:base().sentry_gun then
			aggressor = aggressor:base():get_owner() or managers.criminals:character_unit_by_peer_id(aggressor:base()._owner_id)
		elseif aggressor:base()._projectile_entry then
			aggressor = aggressor:base()._thrower_unit
		end
	end
	if alive(aggressor) then
		local panel_id
		if aggressor == managers.player:player_unit() then
			panel_id = HUDManager.PLAYER_PANEL
		else
			local char_data = managers.criminals:character_data_by_unit(aggressor)
			panel_id = char_data and char_data.panel_id
		end
		if panel_id then
			local body_name = i_body and self._unit:body(i_body) and self._unit:body(i_body):name()
			local headshot = self._head_body_name and body_name and body_name == self._ids_head_body_name or false
			local is_special = managers.groupai:state()._special_unit_types[self._unit:base()._tweak_table] or false
			managers.hud:increment_kill_count(panel_id, is_special, headshot)
			return
		end
	end
end

function CopDamage:damage_bullet(attack_data, ...)
	local result = bullet_original(self, attack_data, ...)
	if result and result.type == "death" then self:_process_kill(attack_data.attacker_unit, self._unit:get_body_index(attack_data.col_ray.body:name())) end
	return result
end

function CopDamage:damage_explosion(attack_data, ...)
	if not self:dead() then
		explosion_original(self, attack_data, ...)
		if self:dead() and alive(attack_data.attacker_unit) then
			self:_process_kill(attack_data.attacker_unit, attack_data.col_ray and attack_data.col_ray.body and self._unit:get_body_index(attack_data.col_ray.body:name()))
		end
	end
end

function CopDamage:damage_melee(attack_data, ...)
	local result = melee_original(self, attack_data, ...)
	if result and result.type == "death" then self:_process_kill(attack_data.attacker_unit, self._unit:get_body_index(attack_data.col_ray.body:name())) end
	return result
end

function CopDamage:damage_fire(attack_data, ...)
	--TODO: Fix this when Overkill has learned how to code
	if not self:dead() then
		fire_original(self, attack_data, ...)
		if self:dead() and alive(attack_data.attacker_unit) then
			self:_process_kill(attack_data.attacker_unit, attack_data.col_ray and attack_data.col_ray.body and self._unit:get_body_index(attack_data.col_ray.body:name()))
		end
	end
	--local result = fire_original(self, attack_data, ...)
	--if result and result.type == "death" then self:_process_kill(attack_data.attacker_unit, self._unit:get_body_index(attack_data.col_ray.body:name())) end
	--return result
end

function CopDamage:sync_damage_bullet(attacker_unit, damage_percent, i_body, hit_offset_height, variant, death, ...)
	if death then self:_process_kill(attacker_unit, i_body) end
	return sync_bullet_original(self, attacker_unit, damage_percent, i_body, hit_offset_height, variant, death, ...)
end

function CopDamage:sync_damage_explosion(attacker_unit, damage_percent, i_attack_variant, death, direction, weapon_unit, ...)
	if death then self:_process_kill(attacker_unit) end
	return sync_explosion_original(self, attacker_unit, damage_percent, i_attack_variant, death, direction, weapon_unit, ...)
end

function CopDamage:sync_damage_melee(attacker_unit, damage_percent, damage_effect_percent, i_body, hit_offset_height, variant, death, ...)
	if death then
		self:_process_kill(attacker_unit, i_body)
	end
	return sync_melee_original(self, attacker_unit, damage_percent, damage_effect_percent, i_body, hit_offset_height, variant, death, ...)
end

function CopDamage:sync_damage_fire(attacker_unit, damage_percent, start_dot_dance_antimation, death, direction, weapon_type, weapon_id, healed, ...)
	if death then
		self:_process_kill(attacker_unit)
	end
	return sync_fire_original(self, attacker_unit, damage_percent, start_dot_dance_antimation, death, direction, weapon_type, weapon_id, healed, ...)
end

function CopDamage:sync_damage_dot(attacker_unit, damage_percent, death, variant, hurt_animation, weapon_id, ...)
	if death then
		self:_process_kill(attacker_unit)
	end
	return sync_damage_dot_original(self, attacker_unit, damage_percent, death, variant, hurt_animation, weapon_id, ...)
end
