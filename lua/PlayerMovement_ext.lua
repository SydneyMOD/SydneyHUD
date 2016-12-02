
local on_morale_boost_original = PlayerMovement.on_morale_boost

function PlayerMovement:on_morale_boost(...)
	managers.player:activate_timed_buff("inspire", tweak_data.upgrades.morale_boost_time)
	return on_morale_boost_original(self, ...)
end
