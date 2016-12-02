
local text_original = LocalizationManager.text

-- This hack allows us to reroute every call for texts.
function LocalizationManager:text(string_id, ...)
	if string_id == "hud_assault_enhanced" then
		-- enhanced assault banner
		return self:hud_assault_enhanced()
	else
		-- fallback to default
		return text_original(self, string_id, ...)
	end
end

function LocalizationManager:hud_assault_enhanced()
	if not SydneyHUD:GetOption("enable_enhanced_assault_banner") then
		return self:text("hud_assault_assault")
	else
		local groupaistate = managers.groupai:state()
		local finaltext = "Assault Phase: "
		if groupaistate:get_hunt_mode() then
			finaltext = finaltext .. "endless"
		else
			finaltext = finaltext .. groupaistate._task_data.assault.phase
			local spawns = groupaistate:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.force_pool) * groupaistate:_get_balancing_multiplier(tweak_data.group_ai.besiege.assault.force_pool_balance_mul)
			if spawns >= 0 and SydneyHUD:GetOption("enhanced_assault_spawns") then
				finaltext = finaltext .. " /// Spawns Left: " .. string.format("%d", spawns - groupaistate._task_data.assault.force_spawned)
			end
			if SydneyHUD:GetOption("enhanced_assault_time") then
				local atime = groupaistate._task_data.assault.phase_end_t + math.lerp(groupaistate:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.sustain_duration_min), groupaistate:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.sustain_duration_max), math.random()) * groupaistate:_get_balancing_multiplier(tweak_data.group_ai.besiege.assault.sustain_duration_balance_mul) + tweak_data.group_ai.besiege.assault.fade_duration * 2
				if atime < 0 then
					finaltext = finaltext .. " /// OVERDUE"
				elseif atime > 0 then
					finaltext = finaltext .. " /// Time Left: " .. string.format("%.2f", atime + 350 - groupaistate._t)
				end
			end
		end
		if SydneyHUD:GetOption("enhanced_assault_count") then
			finaltext = finaltext .. " /// Wave: " .. string.format("%d", groupaistate._wave_counter or 0)
		end
		return finaltext
	end
end
