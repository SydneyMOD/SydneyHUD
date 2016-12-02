
local _setup_item_rows_original = MenuNodeMainGui._setup_item_rows

function MenuNodeMainGui:_setup_item_rows(node, ...)
	_setup_item_rows_original(self, node, ...)
	local mod_name = "SydneyHUD"
	if alive(self._version_string) and not self["_" .. mod_name .. "_version_added"] then
		local version, revision = SydneyHUD:GetVersion()
		local fullversion = mod_name .. " v" .. version .. "r" .. revision
		revision = "r" .. revision
		local versionstring = self._version_string:text()
		if versionstring == Application:version() then
			self._version_string:set_text("PAYDAY2 v" .. versionstring .. " with " .. fullversion)
		elseif self["_JackPackVersion_version_added"] then
			local jackpack_version = SydneyHUD:GetJackPackVersion()
			self._version_string:set_text(versionstring .. " (" .. mod_name .. " " .. revision .. ")")
			if jackpack_version ~= version and not SydneyHUD._pack_warning then
				SydneyHUD._pack_warning = true
				QuickMenu:new("JackPack update", "Guys, the new JackPack... go get it!", {
					[1] = {text = "Go to downloads page", callback = function()
						SydneyHUD:ShowJackPackDownloads()
					end},
					[2] = {text = "Remind me later", is_cancel_button = true}
				}, true)
			end
		else
			self._version_string:set_text(versionstring .. " and " .. fullversion)
		end
		self["_" .. mod_name .. "_version_added"] = true
	end
	if SydneyHUD._poco_conf and not SydneyHUD._poco_warning then
		SydneyHUD._fixed_poco_conf = deep_clone(SydneyHUD._poco_conflicting_defaults)
		for k, v in pairs(SydneyHUD._poco_conf) do
			if not SydneyHUD._fixed_poco_conf[k] then
				SydneyHUD._fixed_poco_conf[k] = v
			else
				for k2, v2 in pairs(SydneyHUD._poco_conf[k]) do
					SydneyHUD._fixed_poco_conf[k][k2] = v2
				end
			end
		end
		local conflict_found = nil
		local conflicts = {}
		local buff = SydneyHUD._fixed_poco_conf.buff
		if buff then
			if buff.hideInteractionCircle ~= nil then
				SydneyHUD._fixed_poco_conf.buff.hideInteractionCircle = nil
				table.insert(conflicts, "buff.hideInteractionCircle")
				conflict_found = true
			end
		end
		local game = SydneyHUD._fixed_poco_conf.game
		if game then
			if game.interactionClickStick ~= false then
				SydneyHUD._fixed_poco_conf.game.interactionClickStick = false
				table.insert(conflicts, "game.interactionClickStick")
				conflict_found = true
			end
			if game.truncateNames ~= nil then
				SydneyHUD._fixed_poco_conf.game.truncateNames = nil
				table.insert(conflicts, "game.truncateNames")
				conflict_found = true
			end
		end
		local playerBottom = SydneyHUD._fixed_poco_conf.playerBottom
		if playerBottom then
			if playerBottom.showRank ~= false then
				SydneyHUD._fixed_poco_conf.playerBottom.showRank = false
				table.insert(conflicts, "playerBottom.showRank")
				conflict_found = true
			end
			if playerBottom.uppercaseNames ~= false then
				SydneyHUD._fixed_poco_conf.playerBottom.uppercaseNames = false
				table.insert(conflicts, "playerBottom.uppercaseNames")
				conflict_found = true
			end
		end
		if conflict_found then
			local menu_title = "SydneyHUD: PocoHUD config incompatible"
			local menu_message = "Found some conflicting PocoHUD settings: " .. json.encode(conflicts) ..  " - Fixing these now."
			local menu_options = {
				[1] = {
					text = "ok",
					is_cancel_button = true
				}
			}
			QuickMenu:new( menu_title, menu_message, menu_options, true )
			SydneyHUD:ApplyFixedPocoSettings()
		end
		local recommendation_found = nil
		local recommendations = {}
		buff = SydneyHUD._fixed_poco_conf.buff
		if buff then
			if buff.showBoost ~= false then
				SydneyHUD._fixed_poco_conf.buff.showBoost = false
				table.insert(recommendations, "buff.showBoost")
				recommendation_found = true
			end
			if buff.showCharge ~= false then
				SydneyHUD._fixed_poco_conf.buff.showCharge = false
				table.insert(recommendations, "buff.showCharge")
				recommendation_found = true
			end
			if buff.showECM ~= false then
				SydneyHUD._fixed_poco_conf.buff.showECM = false
				table.insert(recommendations, "buff.showECM")
				recommendation_found = true
			end
			if buff.showInteraction ~= false then
				SydneyHUD._fixed_poco_conf.buff.showInteraction = false
				table.insert(recommendations, "buff.showInteraction")
				recommendation_found = true
			end
			if buff.showReload ~= false then
				SydneyHUD._fixed_poco_conf.buff.showReload = false
				table.insert(recommendations, "buff.showReload")
				recommendation_found = true
			end
			if buff.showShield ~= false then
				SydneyHUD._fixed_poco_conf.buff.showShield = false
				table.insert(recommendations, "buff.showShield")
				recommendation_found = true
			end
			if buff.showStamina ~= false then
				SydneyHUD._fixed_poco_conf.buff.showStamina = false
				table.insert(recommendations, "buff.showStamina")
				recommendation_found = true
			end
			if buff.showSwanSong ~= false then
				SydneyHUD._fixed_poco_conf.buff.showSwanSong = false
				table.insert(recommendations, "buff.showSwanSong")
				recommendation_found = true
			end
			if buff.showTapeLoop ~= false then
				SydneyHUD._fixed_poco_conf.buff.showTapeLoop = false
				table.insert(recommendations, "buff.showTapeLoop")
				recommendation_found = true
			end
			if buff.simpleBusyIndicator ~= false then
				SydneyHUD._fixed_poco_conf.buff.simpleBusyIndicator = false
				table.insert(recommendations, "buff.simpleBusyIndicator")
				recommendation_found = true
			end
		end
		playerBottom = SydneyHUD._fixed_poco_conf.playerBottom
		if playerBottom then
			if not playerBottom.showDetectionRisk or playerBottom.showDetectionRisk > 0 then
				SydneyHUD._fixed_poco_conf.playerBottom.showDetectionRisk = 0
				table.insert(recommendations, "playerBottom.showDetectionRisk")
				recommendation_found = true
			end
			if not playerBottom.showDowns or playerBottom.showDowns > 0 then
				SydneyHUD._fixed_poco_conf.playerBottom.showDowns = 0
				table.insert(recommendations, "playerBottom.showDowns")
				recommendation_found = true
			end
			if not playerBottom.showInteraction or playerBottom.showInteraction > 0 then
				SydneyHUD._fixed_poco_conf.playerBottom.showInteraction = 0
				table.insert(recommendations, "playerBottom.showInteraction")
				recommendation_found = true
			end
			if not playerBottom.showInteractionTime or playerBottom.showInteractionTime > 0 then
				SydneyHUD._fixed_poco_conf.playerBottom.showInteractionTime = 0
				table.insert(recommendations, "playerBottom.showInteractionTime")
				recommendation_found = true
			end
			if not playerBottom.showKill or playerBottom.showKill > 0 then
				SydneyHUD._fixed_poco_conf.playerBottom.showKill = 0
				table.insert(recommendations, "playerBottom.showKill")
				recommendation_found = true
			end
			if not playerBottom.showSpecial or playerBottom.showSpecial > 0 then
				SydneyHUD._fixed_poco_conf.playerBottom.showSpecial = 0
				table.insert(recommendations, "playerBottom.showSpecial")
				recommendation_found = true
			end
		end
		if recommendation_found and SydneyHUD:GetOption("show_poco_recommendations") then
			local menu_title = "SydneyHUD: PocoHUD config redundant"
			local menu_message = "Found some redundant PocoHUD settings: " .. json.encode(recommendations) ..  " - You don't need to fix these, but it's recommended, since they would just clutter the screen."
			local menu_options = {
				[1] = {
					text = "ok, fix recommendations",
					callback = function()
						SydneyHUD:ApplyFixedPocoSettings()
					end
				},
				[2] = {
					text = "no, keep these",
					is_cancel_button = true
				},
				[3] = {
					text = "no, keep these and don't remind me later",
					callback = function()
						SydneyHUD._data.show_poco_recommendations = false
						SydneyHUD:Save()
					end
				}
			}
			QuickMenu:new( menu_title, menu_message, menu_options, true )
		end
		SydneyHUD._poco_warning = true
	end
end
