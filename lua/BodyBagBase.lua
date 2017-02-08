
local spawn_original = BodyBagsBagBase.spawn
local init_original = BodyBagsBagBase.init
local sync_setup_original = BodyBagsBagBase.sync_setup
local _set_visual_stage_original = BodyBagsBagBase._set_visual_stage
local destroy_original = BodyBagsBagBase.destroy

function BodyBagsBagBase.spawn(pos, rot, upgrade_lvl, peer_id, ...)
	local unit = spawn_original(pos, rot, upgrade_lvl, peer_id, ...)
	if alive(unit) then
		local key = tostring(unit:key())
		managers.gameinfo:event("body_bag", "create", key, { unit = unit })
		managers.gameinfo:event("body_bag", "set_owner", key, { owner = peer_id })
	end
	return unit
end

function BodyBagsBagBase:init(unit, ...)
	local key = tostring(unit:key())
	managers.gameinfo:event("body_bag", "create", key, { unit = unit })
	init_original(self, unit, ...)
	managers.gameinfo:event("body_bag", "set_max_amount", key, { max_amount = self._max_bodybag_amount })
end

function BodyBagsBagBase:sync_setup(upgrade_lvl, peer_id, ...)
	managers.gameinfo:event("body_bag", "set_owner", tostring(self._unit:key()), { owner = peer_id })
	return sync_setup_original(self, upgrade_lvl, peer_id, ...)
end

function BodyBagsBagBase:_set_visual_stage(...)
	managers.gameinfo:event("body_bag", "set_amount", tostring(self._unit:key()), { amount = self._bodybag_amount })
	return _set_visual_stage_original(self, ...)
end

function BodyBagsBagBase:destroy(...)
	managers.gameinfo:event("body_bag", "destroy", tostring(self._unit:key()))
	return destroy_original(self, ...)
end