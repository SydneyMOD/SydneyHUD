
local update_original = PlayerMovement.update
local on_morale_boost_original = PlayerMovement.on_morale_boost

function PlayerMovement:update(unit, t, ...)
	self:_update_uppers_buff(t)
	return update_original(self, unit, t, ...)
end

function PlayerMovement:on_morale_boost(...)
	managers.gameinfo:event("timed_buff", "activate", "inspire", { duration = tweak_data.upgrades.morale_boost_time })
	return on_morale_boost_original(self, ...)
end

local FAK_IN_RANGE = false
local FAK_RECHECK_T = 0
local FAK_RECHECK_INTERVAL = 0.25
function PlayerMovement:_update_uppers_buff(t)
	if t > FAK_RECHECK_T and alive(self._unit) then
		if FirstAidKitBase.GetFirstAidKit(self._unit:position()) then
			if not FAK_IN_RANGE then
				FAK_IN_RANGE = true
				managers.gameinfo:event("buff", "activate", "uppers")
			end
		elseif FAK_IN_RANGE then
			FAK_IN_RANGE = false
			managers.gameinfo:event("buff", "deactivate", "uppers")
		end
		FAK_RECHECK_T = t + FAK_RECHECK_INTERVAL
	end
end

Hooks:PostHook( PlayerMovement , "_upd_underdog_skill" , "uHUDPostPlayerMovementUpdUnderdogSkill" , function( self , t )

	if not self._underdog_skill_data.has_dmg_dampener then return end
	
	if not self._attackers or self:downed() then
		managers.hud:hide_underdog()
		return
	end
	
	local my_pos = self._m_pos
	local nr_guys = 0
	local activated
	for u_key, attacker_unit in pairs(self._attackers) do
		if not alive(attacker_unit) then
			self._attackers[u_key] = nil
			managers.hud:hide_underdog()
			return
		end
		local attacker_pos = attacker_unit:movement():m_pos()
		local dis_sq = mvector3.distance_sq(attacker_pos, my_pos)
		if dis_sq < self._underdog_skill_data.max_dis_sq and math.abs(attacker_pos.z - my_pos.z) < 250 then
			nr_guys = nr_guys + 1
			if nr_guys >= self._underdog_skill_data.nr_enemies then
				activated = true
				managers.hud:show_underdog()
			end
		else
		end
	end

end )