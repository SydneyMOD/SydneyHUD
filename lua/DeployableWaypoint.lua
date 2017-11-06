if not SydneyHUD:GetOption("show_deployable_waypoint") then return end

DeployableWaypoint = DeployableWaypoint or class(CustomWaypoint)
function DeployableWaypoint:init(id, ws, data)
	DeployableWaypoint.super.init(self, id, ws, data)

	self._type = data.type
	self._panel:set_size(35, 60)

	self._icon = self._panel:bitmap({
		name = "icon",
		texture = data.texture,
		texture_rect = data.texture_rect,
		w = self._panel:w(),
		h = self._panel:w(),
	})

	local text_size = self._panel:h() - self._icon:h()
	self._text = self._panel:text({
		name = "text",
		font = tweak_data.hud.medium_font_noshadow,
		font_size = text_size * 0.95,
		align = "center",
		vertical = "center",
		w = self._panel:w(),
		h = text_size,
		y = self._icon:h(),
	})

	self._cached_data = data.deployable_data or {}
end

function DeployableWaypoint:post_init()
	DeployableWaypoint.super.post_init(self)

	self:set_amount(self._cached_data)
	self:set_owner(self._cached_data)
	self:set_upgrades(self._cached_data)

	self._cached_data = nil
end

function DeployableWaypoint:_check_onscreen_visibility(distance, ...)
	return distance < 1000
end

function DeployableWaypoint:set_amount(data)

end

function DeployableWaypoint:set_owner(data)
	local color = data.owner and tweak_data.chat_colors[data.owner] and tweak_data.chat_colors[data.owner]:with_alpha(1) or Color.white
	self._icon:set_color(color)
end

function DeployableWaypoint:set_upgrades(data)

end


BagDeployableWaypoint = BagDeployableWaypoint or class(DeployableWaypoint)
function BagDeployableWaypoint:set_amount(data)
	local amount = (data.amount or 0) + (data.amount_offset or 0)
	self._text:set_text(string.format("%.0f", amount))
end


AmmoBagDeployableWaypoint = AmmoBagDeployableWaypoint or class(BagDeployableWaypoint)
function AmmoBagDeployableWaypoint:init(...)
	AmmoBagDeployableWaypoint.super.init(self, ...)

	self._panel:set_h(self._panel:h() + self._icon:h())

	local size = self._icon:h()

	self._upgrade_icon = self._panel:bitmap({
		name = "upgrade_icon",
		texture = "guis/textures/pd2/skilltree_2/icons_atlas_2",
		texture_rect = { 4 * 80, 5 * 80, 80, 80 },
		w = size,
		h = size,
		visible = false,
	})
	self._upgrade_icon:set_bottom(self._panel:h())

	self._aced_icon = self._panel:bitmap({
		name = "aced_icon",
		texture = "guis/textures/pd2/skilltree_2/ace_symbol",
		w = self._upgrade_icon:w(),
		h = self._upgrade_icon:w(),
		visible = false,
		layer = self._upgrade_icon:layer() - 1,
	})
	self._aced_icon:set_center(self._upgrade_icon:center())
end

function AmmoBagDeployableWaypoint:set_amount(data)
	local amount = (data.amount or 0) + (data.amount_offset or 0)
	self._text:set_text(string.format("%.0f%%", amount * 100))
end

function AmmoBagDeployableWaypoint:set_upgrades(data)
	local bullet_storm_level = data.upgrades and data.upgrades.bullet_storm or 0
	self._upgrade_icon:set_visible(bullet_storm_level > 0)
	self._aced_icon:set_visible(bullet_storm_level > 1)
end


SentryDeployableWaypoint = SentryDeployableWaypoint or class(DeployableWaypoint)
function SentryDeployableWaypoint:set_amount(data)
	local amount = data.ammo_ratio or 0
	self._text:set_text(string.format("%.0f%%", amount * 100))
end



local wp_map = {
	ammo_bag = { texture = "guis/textures/pd2/skilltree/icons_atlas", texture_rect = { 1*64, 0, 64, 64 }, class = AmmoBagDeployableWaypoint },
	doc_bag = { texture = "guis/textures/pd2/skilltree/icons_atlas", texture_rect = { 2*64, 7*64, 64, 64 }, class = BagDeployableWaypoint },
	body_bag = { texture = "guis/textures/pd2/skilltree/icons_atlas", texture_rect = { 5*64, 11*64, 64, 64 }, class = BagDeployableWaypoint },
	grenade_crate = { texture = "guis/dlcs/big_bank/textures/pd2/pre_planning/preplan_icon_types", texture_rect = { 1*48, 0, 48, 48 }, class = BagDeployableWaypoint },
	sentry = { texture = "guis/textures/pd2/skilltree/icons_atlas", texture_rect = { 7*64, 5*64, 64, 64 }, class = SentryDeployableWaypoint },
}

local function add_wp(id, type, unit, key)
	local map = wp_map[type]
	local class = map.class or DeployableWaypoint
	local params = {
		position = unit:interaction():interact_position(),
		type = type,
		texture = map.texture,
		texture_rect = map.texture_rect,
		deployable_data = managers.gameinfo:get_deployables(type, key),
	}

	managers.waypoints:add_waypoint(id, class, params)
end

local function bag_clbk(event, key, data)
	if data.aggregate_members then return end

	local id = "bag_wp_" .. key

	if event == "set_active" then
		if data.active then
			add_wp(id, data.type, data.unit, key)
		else
			managers.waypoints:remove_waypoint(id)
		end
	elseif managers.waypoints:get_waypoint(id) then
		if event == "set_amount_offset" then event = "set_amount" end

		managers.waypoints:do_callback(id, event, data)
	end
end

local function add_events()
	for _, t in pairs({ "ammo_bag", "doc_bag", "body_bag", "grenade_crate" }) do
		managers.gameinfo:register_listener(t .. "_waypoint_listener", t, "set_active", bag_clbk)
		managers.gameinfo:register_listener(t .. "_waypoint_listener", t, "set_owner", bag_clbk)
		managers.gameinfo:register_listener(t .. "_waypoint_listener", t, "set_amount", bag_clbk)
		managers.gameinfo:register_listener(t .. "_waypoint_listener", t, "set_amount_offset", bag_clbk)
		managers.gameinfo:register_listener(t .. "_waypoint_listener", t, "set_upgrades", bag_clbk)
	end
end

if GameInfoManager then
	GameInfoManager.add_post_init_event(add_events)
end