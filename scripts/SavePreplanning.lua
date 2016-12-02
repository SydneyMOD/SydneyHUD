-- Preplanned - By ThatGuyFromBreakingBad
-- SavePreplanning.lua
-- v1.34.3_0

function sp_formatString(sp_value)
    if type(sp_value) == "string" then
        return string.format("%q", sp_value)
    else
        return sp_value
    end
end

function sp_toMElementString(melementtype, sp_id)
    return "MElement(" .. sp_formatString(melementtype) .. ", " .. sp_formatString(sp_id) .. ")"
end

function sp_toVoteString(sp_votetype, sp_id)
    return "Vote(" .. sp_formatString(sp_votetype) .. ", " .. sp_formatString(sp_id) .. ")"
end

if managers.preplanning and managers.job and managers.network then
    local sp_peer_id = managers.network:session():local_peer():id()
    local sp_current_level_id = managers.job:current_real_job_id() .. "_" .. managers.job:current_level_id()
    if sp_current_level_id and sp_peer_id then
		local sp_endl = "\n"
		local sp_file = io.open(SavePath .. "preplanning/" .. sp_current_level_id .. ".lua", "w")
			local sp_reserved_mission_elements = managers.preplanning._reserved_mission_elements
			if sp_reserved_mission_elements then
				for sp_id, sp_reserved_mission_element in pairs(sp_reserved_mission_elements) do
					if sp_reserved_mission_element.peer_id == sp_peer_id then
						sp_melementtype, sp_index = unpack(sp_reserved_mission_element.pack)
						sp_file:write(sp_toMElementString(sp_melementtype, sp_id), sp_endl)
					end
				end
			end
			local sp_player_votes = managers.preplanning:get_player_votes(sp_peer_id)
			if sp_player_votes then
				for sp_plan, sp_data in pairs(sp_player_votes) do
					sp_votetype, sp_index = unpack(sp_data)
					sp_file:write(sp_toVoteString(sp_votetype, managers.preplanning:get_mission_element_id(sp_votetype, sp_index)), sp_endl)
				end
			end
		sp_file:close()
		if managers.chat then
			managers.chat:feed_system_message(ChatManager.GAME, "Preplanned: Saved preplanning")
		end
    end
end
