-- Preplanned - By ThatGuyFromBreakingBad, r3ddr4gOn's, djmattyg007
-- SavePreplanning.lua
-- v1.32.0_0

local sp_endl = "\n"

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

function sp_toMAssetString(sp_id)
    return "MAsset(" .. sp_formatString(sp_id) .. ")"
end

function sp_chatMessage(username, message)
    if managers.chat then
        managers.chat:send_message(1, username, message)
    end
end

function sp_ensureSavePathExists()
    local fullpath = SavePath:gsub("/", "\\") .. "preplanning"
    log("SavePreplanning: Creating " .. fullpath)
    os.execute("mkdir " .. fullpath)
end

function sp_saveReservedMissionElements(sp_peer_id, sp_file)
    local sp_reserved_mission_elements = managers.preplanning._reserved_mission_elements
    if sp_reserved_mission_elements and next(sp_reserved_mission_elements) ~= nil then
        for sp_id, sp_reserved_mission_element in pairs(sp_reserved_mission_elements) do
            if sp_reserved_mission_element.peer_id == sp_peer_id then
                sp_melementtype, sp_index = unpack(sp_reserved_mission_element.pack)
                sp_file:write(sp_toMElementString(sp_melementtype, sp_id), sp_endl)
            end
        end
    end
end

function sp_savePlayerVotes(sp_peer_id, sp_file)
    local sp_player_votes = managers.preplanning:get_player_votes(sp_peer_id)
    if sp_player_votes then
        for sp_plan, sp_data in pairs(sp_player_votes) do
            sp_votetype, sp_index = unpack(sp_data)
            sp_file:write(sp_toVoteString(sp_votetype, managers.preplanning:get_mission_element_id(sp_votetype, sp_index)), sp_endl)
        end
    end
end

function sp_saveReservedMissionAssets(sp_peer_id, sp_file)
    local sp_all_mission_assets = managers.assets:get_every_asset_ids()
    if sp_all_mission_assets and next(sp_all_mission_assets) ~= nil then
        local asset_string
        for i, sp_id in ipairs(sp_all_mission_assets) do
            if managers.assets:get_asset_unlocked_by_id(sp_id) and managers.assets:get_asset_no_mystery_by_id(sp_id) then
                asset_string = sp_toMAssetString(sp_id)
                sp_file:write(sp_toMAssetString(sp_id), sp_endl)
            end
        end
    end
end

if managers.preplanning and managers.job and managers.network then
    local sp_peer_id = managers.network:session():local_peer():id()
    local sp_current_level_id = managers.job:current_real_job_id() .. "_" .. managers.job:current_level_id()

    if sp_current_level_id and sp_peer_id then
        local save_filename = SavePath .. "preplanning\\" .. sp_current_level_id .. ".lua"
        local sp_file = io.open(save_filename, "w")
        if sp_file == nil then
            sp_ensureSavePathExists()
            sp_file = io.open(save_filename, "w")
        end

        local finish_msg = ""
        if managers.preplanning:has_current_level_preplanning() then
            sp_saveReservedMissionElements(sp_peer_id, sp_file)
            sp_savePlayerVotes(sp_peer_id, sp_file)
            finish_msg = "Preplanning saved."
        elseif managers.assets:get_every_asset_ids() then
            sp_saveReservedMissionAssets(sp_peer_id, sp_file)
            finish_msg = "Assets saved."
        else
            finish_msg = "Nothing to save."
        end
        sp_file:close()
        sp_chatMessage(username, finish_msg)
    end
end