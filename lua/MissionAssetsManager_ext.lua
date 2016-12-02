
local _setup_mission_assets_original = MissionAssetsManager._setup_mission_assets
local sync_unlock_asset_original = MissionAssetsManager.sync_unlock_asset
local unlock_asset_original = MissionAssetsManager.unlock_asset
local sync_load_original = MissionAssetsManager.sync_load
local sync_save_original = MissionAssetsManager.sync_save
local is_unlock_asset_allowed_original = MissionAssetsManager.is_unlock_asset_allowed

function MissionAssetsManager:_setup_mission_assets()
	_setup_mission_assets_original(self)
	if not self:mission_has_preplanning() and SydneyHUD:GetOption("enable_buy_all_assets") then
		self:insert_buy_all_assets_asset()
		self:check_all_assets()
	end
end

function MissionAssetsManager:sync_unlock_asset(asset_id, peer)
	sync_unlock_asset_original(self, asset_id, peer)
	if not self:mission_has_preplanning() and SydneyHUD:GetOption("enable_buy_all_assets") then
		self:update_buy_all_assets_asset_cost()
		self:check_all_assets()
	end
end

function MissionAssetsManager:unlock_asset(asset_id)
	if asset_id ~= "buy_all_assets" or not game_state_machine or not self:is_unlock_asset_allowed() then
		return unlock_asset_original(self, asset_id)
	end
	for _, asset in ipairs(self._global.assets) do
		if self:asset_is_buyable(asset) then
			unlock_asset_original(self, asset.id)
		end
	end
	self:check_all_assets()
end

function MissionAssetsManager:sync_save(data)
	if self:mission_has_preplanning() or not SydneyHUD:GetOption("enable_buy_all_assets") then
		return sync_save_original(self, data)
	end
	local _global = clone(self._global)
	_global.assets = clone(_global.assets)
	for id, asset in ipairs(_global.assets) do
		if asset.id == "buy_all_assets" then
			_global.assets[id] = self._gage_saved
			break
		end
	end
	data.MissionAssetsManager = _global
end

function MissionAssetsManager:sync_load(data)
	if not self:mission_has_preplanning() and SydneyHUD:GetOption("enable_buy_all_assets") then
		self._global = data.MissionAssetsManager
		self:insert_buy_all_assets_asset()
		self:check_all_assets()
	end
	sync_load_original(self, data)
end

function MissionAssetsManager:is_unlock_asset_allowed()
	if not game_state_machine then
		return false
	end
	return is_unlock_asset_allowed_original()
end

-------------------------------------------------------------------------------------------------------

function MissionAssetsManager:mission_has_preplanning()
	return tweak_data.preplanning.locations[Global.game_settings and Global.game_settings.level_id] ~= nil
end

function MissionAssetsManager:asset_is_buyable(asset)
	return asset.id ~= "buy_all_assets" and asset.show and not asset.unlocked and ((Network:is_server() and asset.can_unlock) or (Network:is_client() and self:get_asset_can_unlock_by_id(asset.id)))
end

function MissionAssetsManager:update_buy_all_assets_asset_cost()
	if self._tweak_data.buy_all_assets and not self:mission_has_preplanning() and SydneyHUD:GetOption("enable_buy_all_assets") then
		self._tweak_data.buy_all_assets.money_lock = 0
		for _, asset in ipairs(self._global.assets) do
			if self:asset_is_buyable(asset) then
				self._tweak_data.buy_all_assets.money_lock = self._tweak_data.buy_all_assets.money_lock + (self._tweak_data[asset.id].money_lock or 0)
			end
		end
	end
end

function MissionAssetsManager:insert_buy_all_assets_asset()
	if self._tweak_data.gage_assignment and not self:mission_has_preplanning() and SydneyHUD:GetOption("enable_buy_all_assets") then
		self._tweak_data.buy_all_assets = clone(self._tweak_data.gage_assignment)
		self._tweak_data.buy_all_assets.name_id = "buy_all_assets"
		self._tweak_data.buy_all_assets.unlock_desc_id = "buy_all_assets_desc"
		self._tweak_data.buy_all_assets.visible_if_locked = true
		self._tweak_data.buy_all_assets.no_mystery = true
		self:update_buy_all_assets_asset_cost()
		for _, asset in ipairs(self._global.assets) do
			if asset.id == "gage_assignment" then
				self._gage_saved = deep_clone(asset)
				asset.id = "buy_all_assets"
				asset.unlocked = false
				asset.can_unlock = true
				asset.no_mystery = true
				break
			end
		end
	end
	self:check_all_assets()
end

function MissionAssetsManager:check_all_assets()
	if game_state_machine and not self:mission_has_preplanning() and SydneyHUD:GetOption("enable_buy_all_assets") then
		for _, asset in ipairs(self._global.assets) do
			if self:asset_is_buyable(asset) then
				return
			end
		end
		if not self._all_assets_bought then
			self._tweak_data.buy_all_assets.money_lock = 0
			self._all_assets_bought = true
			unlock_asset_original(self, "buy_all_assets")
		end
	end
end
