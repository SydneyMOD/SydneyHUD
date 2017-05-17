function MissionAssetsManager:unlock_all_buyable_assets()
	if SydneyHUD:GetOption("enable_buy_all_assets") then
		for _, asset in ipairs(self._global.assets) do
			if self:asset_is_buyable(asset) then
				self:unlock_asset(asset.id)
			end
		end
	end
end

function MissionAssetsManager:asset_is_buyable(asset)
	return self:asset_is_locked(asset) and (Network:is_server() and asset.can_unlock or Network:is_client() and self:get_asset_can_unlock_by_id(asset.id))
end

function MissionAssetsManager:asset_is_locked(asset)
	return asset.show and not asset.unlocked
end

function MissionAssetsManager:has_locked_assets()
	local level_id = managers.job:current_level_id()
	if not tweak_data.preplanning or not tweak_data.preplanning.locations or not tweak_data.preplanning.locations[level_id] then
		for _, asset in ipairs(self._global.assets) do
			if self:asset_is_locked(asset) then
				return true
			end
		end
	end
	return false
end

function MissionAssetsManager:has_buyable_assets()
	local level_id = managers.job:current_level_id()
	if self:is_unlock_asset_allowed() and not tweak_data.preplanning or not tweak_data.preplanning.locations or not tweak_data.preplanning.locations[level_id] then
		local asset_costs = self:get_total_assets_costs()
		if asset_costs > 0 then
			return true
		end
	end
	return false
end

function MissionAssetsManager:get_total_assets_costs()
	local total_costs = 0
	for _, asset in ipairs(self._global.assets) do
		if self:asset_is_buyable(asset) then
			total_costs = total_costs + (asset.id and managers.money:get_mission_asset_cost_by_id(asset.id) or 0)
		end
	end
	return total_costs
end
