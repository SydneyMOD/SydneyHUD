--[[
   _____           __                 __  ____  ______
  / ___/__  ______/ /___  ___  __  __/ / / / / / / __ \        ____
  \__ \/ / / / __  / __ \/ _ \/ / / / /_/ / / / / / / /	 _  __/ / /
 ___/ / /_/ / /_/ / / / /  __/ /_/ / __  / /_/ / /_/ /	| |/ /_  _/
/____/\__, /\__,_/_/ /_/\___/\__, /_/ /_/\____/_____/	|___/ /_/
     /____/                 /____/

		All-In-One mod for PAYDAY2      Developed by SydneyMOD Team
]]


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
	SydneyHUD.info = "[SydneyHUD Info] "
	SydneyHUD.warn = "[SydneyHUD Warn] "
	SydneyHUD.error = "[SydneyHUD Error] "
	SydneyHUD.dev = "[SydneyHUD Dev] "

	-- var for script
	SydneyHUD._autorepair_map = {}
	SydneyHUD._current_phase = ""
	SydneyHUD._pre_phase = ""

	SydneyHUD._current_wave = 0
	SydneyHUD._pre_wave = 0

	SydneyHUD._heist_time = "00:00"
	SydneyHUD._last_removed_time = 0

	SydneyHUD._down_count = {}

	SydneyHUD._language =
	{
		[1] = "english",
		[2] = "japanese",
		[3] = "french",
		[4] = "russian",
		[5] = "portuguese"
	}

	-- var for util
	SydneyHUD._calls = SydneyHUD._calls or {}
	SydneyHUD._chat = {}
	SydneyHUD._path = ModPath
	SydneyHUD._lua_path = ModPath .. "lua/"
	SydneyHUD._data_path = SavePath .. "SydneyHUD.json"
	SydneyHUD._poco_path = SavePath .. "hud3_config.json"
	SydneyHUD._data = {}
	SydneyHUD._menus = {
		"sydneyhud_options",
		"sydneyhud_core",

		"sydneyhud_gadget_options",
		"sydneyhud_gadget_options_others",
		"sydneyhud_gadget_options_player",
		"sydneyhud_gadget_options_sniper",
		"sydneyhud_gadget_options_turret",

		"sydneyhud_hud_lists_options",
		"sydneyhud_hud_lists_options_civilian_color",
		"sydneyhud_hud_lists_options_enemy_color",
		"sydneyhud_hud_lists_options_left",
		"sydneyhud_hud_lists_options_right",

		"sydneyhud_chat_info",
		"sydneyhud_experimental",
		"sydneyhud_gameplay_tweaks",
		"sydneyhud_hps_meter",
		"sydneyhud_interact_tweaks",
		"sydneyhud_kill_counter_options",
		"sydneyhud_menu_tweaks",

		"sydneyhud_hud_tweaks",
		"sydneyhud_hud_tweaks_assault",
		"sydneyhud_hud_tweaks_interact",
		"sydneyhud_hud_tweaks_name",
		"sydneyhud_hud_tweaks_panel",
		"sydneyhud_hud_tweaks_waypoint"
	}
	SydneyHUD._hook_files = {
		["core/lib/utils/coreapp"] = "Coreapp.lua",
		["core/lib/managers/menu/items/coremenuitemslider"] = "CoreItemSlider.lua",
		["lib/managers/chatmanager"] = "ChatManager.lua",
		["lib/managers/enemymanager"] = "EnemyManager.lua",
		["lib/managers/group_ai_states/groupaistatebase"] = "GroupAIStateBase.lua",
		["lib/managers/hud/hudchat"] = "HUDChat.lua",
		["lib/managers/hud/hudassaultcorner"] = "HUDAssaultCorner.lua",
		["lib/managers/hud/hudinteraction"] = "HUDInteraction.lua",
		["lib/managers/hud/hudpresenter"] = "HUDPresenter.lua",
		["lib/managers/hud/hudstatsscreen"] = "HUDStatsScreen.lua",
		["lib/managers/hud/hudsuspicion"] = "HUDSuspicion.lua",
		["lib/managers/hud/hudteammate"] = "HUDTeammate.lua",
		["lib/managers/hudmanager"] = "HUDManager.lua",
		["lib/managers/hudmanagerpd2"] = "HUDManagerPD2.lua",
		["lib/managers/localizationmanager"] = "LocalizationManager.lua",
		["lib/managers/menu/blackmarketgui"] = "BlackMarketGUI.lua",
		["lib/managers/menu/contractboxgui"] = "ContractBoxGui.lua",
		["lib/managers/menu/lootdropscreengui"] = "LootDropScreenGui.lua",
		["lib/managers/menu/menubackdropgui"] = "MenuBackDropGUI.lua",
		["lib/managers/menu/menucomponentmanager"] = "MenuComponentManager.lua",
		["lib/managers/menu/menunodegui"] = "MenuNodeGui.lua",
		["lib/managers/menu/menuscenemanager"] = "MenuSceneManager.lua",
		["lib/managers/menu/missionbriefinggui"] = "MissionBriefingGui.lua",
		["lib/managers/menu/stageendscreengui"] = "StageEndScreenGui.lua",
		["lib/managers/menumanager"] = "MenuManager.lua",
		["lib/managers/missionassetsmanager"] = "MissionAssetsManager.lua",
		["lib/managers/objectinteractionmanager"] = "ObjectInteractionManager.lua",
		["lib/managers/playermanager"] = "PlayerManager.lua",
		["lib/managers/trademanager"] = "TradeManager.lua",
		["lib/network/base/handlers/connectionnetworkhandler"] = "ConnectionNetworkHandler.lua",
		["lib/network/base/networkpeer"] = "NetworkPeer.lua",
		["lib/network/handlers/unitnetworkhandler"] = "UnitNetworkHandler.lua",
		["lib/player_actions/skills/playeractionammoefficiency"] = "PlayerActionAmmoefficiency.lua",
		["lib/player_actions/skills/playeractionbloodthirstbase"] = "PlayerActionBloodthirstBase.lua",
		["lib/player_actions/skills/playeractiondireneed"] = "PlayerActionDireneed.lua",
		["lib/player_actions/skills/playeractionexperthandling"] = "PlayerActionExperthandling.lua",
		["lib/player_actions/skills/playeractionshockandawe"] = "PlayerActionShockandawe.lua",
		["lib/player_actions/skills/playeractiontriggerhappy"] = "PlayerActionTriggerhappy.lua",
		["lib/player_actions/skills/playeractionunseenstrike"] = "PlayerActionUnseenstrike.lua",
		["lib/setups/setup"] = "Setup.lua",
		["lib/states/ingamewaitingforplayers"] = "IngameWaitingForPlayersState.lua",
		["lib/tweak_data/charactertweakdata"] = "CharacterTweakData.lua",
		["lib/tweak_data/playertweakdata"] = "PlayerTweakData.lua",
		["lib/units/beings/player/huskplayermovement"] = "HuskPlayerMovement.lua",
		["lib/units/beings/player/playerdamage"] = "PlayerDamage.lua",
		["lib/units/beings/player/playermovement"] = "PlayerMovement.lua",
		["lib/units/beings/player/states/playerbleedout"] = "PlayerBleedOut.lua",
		["lib/units/beings/player/states/playercarry"] = "PlayerCarry.lua",
		["lib/units/beings/player/states/playercivilian"] = "PlayerCivilian.lua",
		["lib/units/beings/player/states/playerdriving"] = "PlayerDriving.lua",
		["lib/units/beings/player/states/playermaskoff"] = "PlayerMaskOff.lua",
		["lib/units/beings/player/states/playerstandard"] = "PlayerStandard.lua",
		["lib/units/civilians/civiliandamage"] = "CivilianDamage.lua",
		["lib/units/enemies/cop/copdamage"] = "CopDamage.lua",
		["lib/units/equipment/ammo_bag/ammobagbase"] = "AmmoBagBase.lua",
		["lib/units/equipment/bodybags_bag/bodybagsbagbase"] = "BodyBagBase.lua",
		["lib/units/equipment/doctor_bag/doctorbagbase"] = "DoctorBagBase.lua",
		["lib/units/equipment/ecm_jammer/ecmjammerbase"] = "ECMJammerBase.lua",
		["lib/units/equipment/grenade_crate/grenadecratebase"] = "GrenadeCrateBase.lua",
		["lib/units/equipment/sentry_gun/sentrygunbase"] = "SentryGunBase.lua",
		["lib/units/equipment/sentry_gun/sentrygundamage"] = "SentryGunDamage.lua",
		["lib/units/interactions/interactionext"] = "InteractionExt.lua",
		["lib/units/props/digitalgui"] = "DigitalGui.lua",
		["lib/units/props/drill"] = "Drill.lua",
		["lib/units/props/securitycamera"] = "SecurityCamera.lua",
		["lib/units/props/securitylockgui"] = "SecurityLockGui.lua",
		["lib/units/props/timergui"] = "TimerGui.lua",
		["lib/units/weapons/newraycastweaponbase"] = "NewRayCastWeaponBase.lua",
		["lib/units/weapons/sentrygunweapon"] = "SentryGunWeapon.lua",
		["lib/units/weapons/weaponflashlight"] = "WeaponFlashlight.lua",
		["lib/units/weapons/weaponlaser"] = "WeaponLaser.lua",
		["lib/utils/temporarypropertymanager"] = "TemporaryPropertyManager.lua"
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

	local upcoming = {}
	local incoming = {}
	local removals = {}

	function SydneyHUD:DelayedCallsUpdate(time, deltaTime)
		local immutable = self._calls
		for k, v in pairs(immutable) do
			v.currentTime = v.currentTime + deltaTime
			if v.currentTime >= v.timeToWait then
				if v.functionCall then
					local status = pcall(v.functionCall)
					if not status then
						log(SydneyHUD.warn .. "Execution of callback has failed: " .. tostring(k))
					end
				end
			else
				upcoming[k] = v
			end
		end

		for k, v in pairs(self._calls) do
			upcoming[k] = v
		end
		for k, v in pairs(removals) do
			if upcoming[k] ~= nil then
				upcoming[k] = nil
			end
		end

		for key, __ in pairs(immutable) do
			immutable[key] = nil
		end
		for key, __ in pairs(self._calls) do
			self._calls[key] = nil
		end
		for key, __ in pairs(removals) do
			removals[key] = nil
		end

		self._calls, upcoming, incoming = upcoming, self._calls, immutable
	end

	function SydneyHUD:DelayedCallsAdd(id, time, func)
		local data = self._calls[id]
		if data == nil then
			self._calls[id] = {
				functionCall = func,
				timeToWait = time,
				currentTime = 0
			}
		else
			data.functionCall = func
			data.timeToWait = time
			data.currentTime = 0
		end
	end

	function SydneyHUD:DelayedCallsRemove(id)
		local data = self._calls[id]
		if data == nil then
			removals[id] = true
		else
			self._calls[id] = nil
		end
	end

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
				log(SydneyHUD.error .. "Could not open file '" .. fileName .. "'!")
			end
		end)
		if not success then
			log(SydneyHUD.error .. "File: " .. fileName .. "\n" .. errorMsg)
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
		local id = string.match(self._path, "(%w+)[\\/]$") or "SydneyHUD"
		local mod = BLT.Mods:GetMod(id)
		return tostring(mod and mod:GetVersion() or "(n/a)")
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
		--[[
		if not tostring(color):find('Color') then
			color = nil
		end
		--]]
		if color and #color == 6 then
			color = Color(color)
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

	function SydneyHUD:SaveChatMessage(name, message) -- WIP
		table.insert(self._chat, tostring(name .. ": " .. message))
	end

	function SydneyHUD:RemoveChatMessage(type, message) -- WIP
		if not type then
			type = "current"
		end

		if type == "all" then
			for _, _ in ipairs(self._chat) do
				table.remove(self._chat)
			end
		elseif type == "current" then
			table.remove(self._chat)
		elseif type == "select" then
			for num, mes in ipairs(self._chat) do
				if mes == message then
					table.remove(self._chat, num)
				end
			end
		end
	end

	function SydneyHUD:Replenish(peer_id)
		local peer = managers.network:session():peer(peer_id)
		if peer then
			local down = "down"
			-- NOTE: Add existence check of _down_count (can be nil when not downed)
			if self._down_count[peer_id] and self._down_count[peer_id] > 1 then
				down = "downs"
			end
			-- NOTE: Display 0 instead of nil
			local message = peer:name() .. " +" .. tostring(self._down_count[peer_id] or 0) .. " " .. down
			local is_feed = SydneyHUD:GetOption("replenished_chat_info_feed")
			if SydneyHUD:GetOption("replenished_chat_info") then
				self:SendChatMessage("Replenished", message, is_feed, "00ff04")
			end
			self._down_count[peer_id] = 0
		end
	end

	function SydneyHUD:Down(peer_id, local_peer)
		local peer = managers.network:session():peer(peer_id)
		if peer then
			local warn_down = 3

			if Global.game_settings.one_down then
				warn_down = 1
			end

			if local_peer then
				local nine_lives = managers.player:upgrade_value('player', 'additional_lives', 0) or 0
				warn_down = warn_down + nine_lives
			end

			if not SydneyHUD._down_count[peer_id] then
				SydneyHUD._down_count[peer_id] = 1
			else
				SydneyHUD._down_count[peer_id] = SydneyHUD._down_count[peer_id] + 1
			end

			if SydneyHUD._down_count[peer_id] == warn_down and SydneyHUD:GetOption("critical_down_warning_chat_info") then
				local message = peer:name() .. " was downed " .. tostring(SydneyHUD._down_count[peer_id]) .. " times"
				local is_feed = SydneyHUD:GetOption("critical_down_warning_chat_info_feed")
				self:SendChatMessage("Warning!", message, is_feed, "ff0000")
			elseif SydneyHUD:GetOption("down_warning_chat_info") then
				local message = peer:name() .. " was downed (" .. tostring(SydneyHUD._down_count[peer_id]) .. "/" .. warn_down .. ")"
				local is_feed = SydneyHUD:GetOption("down_warning_chat_info_feed")
				self:SendChatMessage("Warning", message, is_feed, "ff0000")
			end
		end
	end

	function SydneyHUD:Custody(criminal_name, local_peer)
		local peer_id = criminal_name
		if not local_peer then
			for __, data in pairs(managers.criminals._characters) do
				if data.token and criminal_name == data.name then
					peer_id = data.peer_id
					break
				end
			end
		end
		local peer = managers.network:session():peer(peer_id)
		if peer then
			SydneyHUD._down_count[peer_id] = 0
		end
	end

	function SydneyHUD:Peer_id_To_Peer(peer_id)
		local session = managers.network:session()
		return session and session:peer(peer_id)
	end

	function SydneyHUD:Peer(input)
		local t = type(input)
		if t == 'userdata' then
			return alive(input) and input:network():peer()
		elseif t == 'number' then
			return self:Peer_id_To_Peer(input)
		elseif t == 'string' then
			return self:Peer(managers.criminals:character_peer_id_by_name(input))
		end
	end

	function SydneyHUD:Peer_Info(input)
		local peer = self:Peer(input)
		return peer and peer:id() or 0
	end

	SydneyHUD:Load()
	SydneyHUD.setup = true
	log(SydneyHUD.info .. "SydneyHUD loaded.")
end

if RequiredScript then
	local requiredScript = RequiredScript:lower()
	if SydneyHUD._hook_files[requiredScript] then
		SydneyHUD:SafeDoFile(SydneyHUD._lua_path .. SydneyHUD._hook_files[requiredScript])
	else
		log(SydneyHUD.warn .. "unlinked script called: " .. requiredScript)
	end
end
