if not Steam then
	return
end

--[[
	We setup the global table for our mod, along with some path variables, and a data table.
	We cache the ModPath directory, so that when our hooks are called, we aren't using the ModPath from a
		different mod.
]]
SydneyHUD = SydneyHUD or {}
if not SydneyHUD.setup then

	--[[
		Alias for EZ to write log

		Info: Infomation Log. Something successed.
		Warn: Warning Log. Something Errored, but can keep working.
		Error: Error Log. Something Errored. Can not keep working.
		Dev: Develop Log. Printing var, Breakpoint.
	]]
	info = "[SydneyHUD Info] "
	warn = "[SydneyHUD Warn] "
	error = "[SydneyHUD Error] "
	dev = "[SydneyHUD Dev] "

	-- var for script
	-- IDK why lua can not create blank var and use niled var
	SydneyHUD._current_phase = ""
	SydneyHUD._pre_phase = ""

	SydneyHUD._current_wave = 0
	SydneyHUD._pre_wave = 0

	SydneyHUD._language =
	{
		[1] = "english",
		[2] = "japanese"
	}

	-- var for util
	SydneyHUD._path = ModPath
	SydneyHUD._lua_path = ModPath .. "lua/"
	SydneyHUD._data_path = SavePath .. "SydneyHUD.json"
	SydneyHUD._poco_path = SavePath .. "hud3_config.json"
	SydneyHUD._data = {}
	SydneyHUD._menus = {
		"sydneyhud_options",
		"sydneyhud_menu_tweaks",
		"sydneyhud_hud_tweaks",
		"hud_lists_options",
		"kill_counter_options",
		"hps_meter",
		"interact_tweaks",
		"gadget_options",
		"sydneyhud_gameplay_tweaks",
		"sydneyhud_chat_info"
	}
	SydneyHUD._hook_files = {
		["lib/managers/menumanager"] = "MenuManager.lua",
		["lib/managers/group_ai_states/groupaistatebase"] = "GroupAIStateBase.lua",
		["lib/managers/hud/hudassaultcorner"] = "HUDAssaultCorner.lua",
		["lib/managers/hud/hudinteraction"] = "HUDInteraction.lua",
		["lib/managers/hud/hudstatsscreen"] = "HUDStatsScreen.lua",
		["lib/managers/hud/hudpresenter"] = "HUDPresenter.lua",
		["lib/managers/hud/hudsuspicion"] = "HUDSuspicion.lua",
		["lib/managers/hud/hudteammate"] = "HUDTeammate.lua",
		["lib/managers/menu/lootdropscreengui"] = "LootDropScreenGui.lua",
		["lib/managers/menu/menubackdropgui"] = "MenuBackDropGUI.lua",
		["lib/managers/menu/menunodegui"] = "MenuNodeGui.lua",
		["lib/managers/menu/menuscenemanager"] = "MenuSceneManager.lua",
		["lib/managers/menu/stageendscreengui"] = "StageEndScreenGui.lua",
		["lib/managers/enemymanager"] = "EnemyManager.lua",
		["lib/managers/hudmanager"] = "HUDManager.lua",
		["lib/managers/hudmanagerpd2"] = "HUDManagerPD2.lua",
		["lib/managers/localizationmanager"] = "LocalizationManager.lua",
		["lib/managers/missionassetsmanager"] = "MissionAssetsManager.lua",
		["lib/managers/objectinteractionmanager"] = "ObjectInteractionManager.lua",
		["lib/managers/playermanager"] = "PlayerManager.lua",
		["lib/network/base/handlers/connectionnetworkhandler"] = "ConnectionNetworkHandler.lua",
		["lib/network/handlers/unitnetworkhandler"] = "UnitNetworkHandler.lua",
		["lib/states/ingamewaitingforplayers"] = "IngameWaitingForPlayersState.lua",
		["lib/units/beings/player/states/playercivilian"] = "PlayerCivilian.lua",
		["lib/units/beings/player/states/playerdriving"] = "PlayerDriving.lua",
		["lib/units/beings/player/states/playerstandard"] = "PlayerStandard.lua",
		["lib/units/beings/player/playerdamage"] = "PlayerDamage.lua",
		["lib/units/beings/player/playermovement"] = "PlayerMovement.lua",
		["lib/units/equipment/ammo_bag/ammobagbase"] = "AmmoBagBase.lua",
		["lib/units/equipment/bodybags_bag/bodybagsbagbase"] = "BodyBagBase.lua",
		["lib/units/equipment/doctor_bag/doctorbagbase"] = "DoctorBagBase.lua",
		["lib/units/equipment/ecm_jammer/ecmjammerbase"] = "ECMJammerBase.lua",
		["lib/units/equipment/grenade_crate/grenadecratebase"] = "GrenadeCrateBase.lua",
		["lib/units/equipment/sentry_gun/sentrygunbase"] = "SentryGunBase.lua",
		["lib/units/equipment/sentry_gun/sentrygundamage"] = "SentryGunDamage.lua",
		["lib/units/enemies/cop/copdamage"] = "CopDamage.lua",
		["lib/units/props/digitalgui"] = "DigitalGui.lua",
		["lib/units/props/missiondoor"] = "MissionDoor.lua",
		["lib/units/props/securitycamera"] = "SecurityCamera.lua",
		["lib/units/props/timergui"] = "TimerGui.lua",
		["lib/units/weapons/newraycastweaponbase"] = "NewRayCastWeaponBase.lua",
		["lib/units/weapons/sentrygunweapon"] = "SentryGunWeapon.lua",
		["lib/units/weapons/weaponflashlight"] = "WeaponFlashlight.lua",
		["lib/units/weapons/weaponlaser"] = "WeaponLaser.lua",
		["lib/units/unitbase"] = "UnitBase.lua",

		["lib/units/beings/player/huskplayermovement"] = "HuskPlayerMovement.lua",
		["lib/managers/menu/blackmarketgui"] = "BlackMarketGUI.lua",
		-- ["lib/setups/menusetup"] = "MenuSetup.lua",  -- Disable this cause use this code without setting to steam advanced option "-skip_intro". So I'll made setting menu. wait for that.

		["lib/units/beings/player/states/playermaskoff"] = "PlayerMaskOff.lua",
		["lib/tweak_data/playertweakdata"] = "PlayerTweakData.lua"
	}
	SydneyHUD._poco_conflicting_defaults = {
		buff = {
			mirrorDirection = true,
			showBoost = true,
			showCharge = true,
			showECM = true,
			showInteraction = true,
			showReload = true,
			showShield = true,
			showStamina = true,
			showSwanSong = true,
			showTapeLoop = true,
			simpleBusyIndicator = true
		},
		game = {
			interactionClickStick = true
		},
		playerBottom = {
			showRank = true,
			uppercaseNames = true
		}
	}

	--[[
		A simple save function that json encodes our _data table and saves it to a file.
	]]
	function SydneyHUD:Save()
		local file = io.open(self._data_path, "w+")
		if file then
			file:write(json.encode(self._data))
			file:close()
		end
	end

	--[[
		A simple load function that decodes the saved json _data table if it exists.
	]]
	function SydneyHUD:Load()
		self:LoadDefaults()
		local file = io.open(self._data_path, "r")
		if file then
			local configt = json.decode(file:read("*all"))
			file:close()
			for k,v in pairs(configt) do
				self._data[k] = v
			end
		end
		self:Save()
		self:CheckPoco()
	end

	function SydneyHUD:GetOption(id)
		return self._data[id]
	end

	function SydneyHUD:LoadDefaults()
		local default_file = io.open(self._path .."menu/default_values.json")
		self._data = json.decode(default_file:read("*all"))
		default_file:close()
	end

	function SydneyHUD:InitAllMenus()
		for _,menu in pairs(self._menus) do
			MenuHelper:LoadFromJsonFile(self._path .. "menu/" .. menu .. ".json", self, self._data)
		end
	end

	function SydneyHUD:ForceReloadAllMenus()
		for _,menu in pairs(self._menus) do
			for _,_item in pairs(MenuHelper:GetMenu(menu)._items_list) do
				if _item._type == "toggle" then
					_item.selected = self._data[_item._parameters.name] and 1 or 2
				elseif _item._type == "multi_choice" then
					_item._current_index = self._data[_item._parameters.name]
				elseif _item._type == "slider" then
					_item._value = self._data[_item._parameters.name]
				end
			end
		end
	end

	function SydneyHUD:CheckPoco()
		local file = io.open(self._poco_path)
		if file then
			self._poco_conf = json.decode(file:read("*all"))
			file:close()
		end
	end

	function SydneyHUD:ApplyFixedPocoSettings()
		local file = io.open(self._poco_path, "w+")
		if file and self._fixed_poco_conf then
			file:write(json.encode(self._fixed_poco_conf))
			file:close()
			local menu_title = "SydneyHUD: PocoHUD config fixed"
			local menu_message = "Config fixed. You NEED to restart the game NOW, to finish the process."
			local menu_options = {
				[1] = {
					text = "ok, i understand",
					is_cancel_button = true,
				}
			}
			QuickMenu:new(menu_title, menu_message, menu_options, true)
		end
	end

	function SydneyHUD:SafeDoFile(fileName)
		local success, errorMsg = pcall(function()
			if io.file_is_readable(fileName) then
				dofile(fileName)
			else
				log("[SydneyHUD Error] Could not open file '" .. fileName .. "'! Does it exist, is it readable?")
			end
		end)
		if not success then
			log("[SydneyHUD Error]\nFile: " .. fileName .. "\n" .. errorMsg)
		end
	end

	function SydneyHUD:MakeOutlineText(panel, bg, txt)
		bg.name = nil
		local bgs = {}
		for i = 1, 4 do
			table.insert(bgs, panel:text(bg))
		end
		bgs[1]:set_x(txt:x() - 1)
		bgs[1]:set_y(txt:y() - 1)
		bgs[2]:set_x(txt:x() + 1)
		bgs[2]:set_y(txt:y() - 1)
		bgs[3]:set_x(txt:x() - 1)
		bgs[3]:set_y(txt:y() + 1)
		bgs[4]:set_x(txt:x() + 1)
		bgs[4]:set_y(txt:y() + 1)
		return bgs
	end

	function SydneyHUD:GetVersion()
		local version = "1.0"
		-- local revision = "0"
		for k, v in pairs(LuaModManager.Mods) do
			local info = v.definition
			if info["name"] == "SydneyHUD" then
				version = info["version"]
			end
		end
		return version -- , revision
	end

	function SydneyHUD:SendChatMessage(name, message, isfeed, color)
		if not message then
			message = name
			name = ""
		end
		if not isfeed then
			isfeed = false
		end
		isfeed = isfeed or false
		if not tostring(color):find('Color') then
			color = nil
		end
		message = tostring(message)
		--if managers and managers.chat and managers.chat._receives and managers.chat._receivers[1] then
			for __, rcvr in pairs(managers.chat._receivers[1]) do
				rcvr:receive_message(name or "*", message, color or tweak_data.chat_colors[5])
			end
		--end
		if Network:is_server() and isfeed then
			local num_player_slots = BigLobbyGlobals and BigLobbyGlobals:num_player_slots() or 4
			for i=2,num_player_slots do
				local peer = managers.network:session():peer(i)
				if peer then
					peer:send("send_chat_message", ChatManager.GAME, name .. ": " .. message)
				end
			end
		end
	end

	SydneyHUD:Load()
	SydneyHUD.setup = true
	log("[SydneyHUD Info] SydneyHUD loaded.")
end

if RequiredScript then
	local requiredScript = RequiredScript:lower()
	if SydneyHUD._hook_files[requiredScript] then
		SydneyHUD:SafeDoFile(SydneyHUD._lua_path .. SydneyHUD._hook_files[requiredScript])
	else
		log("[SydneyHUD Warn] unlinked script called: " .. requiredScript)
	end
end
