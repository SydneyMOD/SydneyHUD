
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