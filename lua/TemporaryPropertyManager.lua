
local activate_property_original = TemporaryPropertyManager.activate_property
local remove_property_original = TemporaryPropertyManager.remove_property

function TemporaryPropertyManager:activate_property(prop, time, value, ...)
	managers.gameinfo:event("temporary_buff", "activate", { duration = time, category = "temporary", upgrade = prop, value = value })
	return activate_property_original(self, prop, time, value, ...)
end

function TemporaryPropertyManager:remove_property(prop, ...)
	managers.gameinfo:event("temporary_buff", "deactivate", { category = "temporary", upgrade = prop })
	return remove_property_original(self, prop, ...)
end