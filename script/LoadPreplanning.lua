-- Preplanned - By ThatGuyFromBreakingBad, r3ddr4gOn's, djmattyg007
-- LoadPreplanning.lua
-- v1.32.0_0

function sp_chatMessage(username, message)
    if managers.chat then
        managers.chat:send_message(1, username, message)
    end
end

function sp_checkMode()
    if managers.preplanning:has_current_level_preplanning() then
        return "preplanning"
    elseif managers.assets:get_every_asset_ids() then
        return "assets"
    else
        return "unknown"
    end
end

function MElement(sp_melementtype, sp_id)
    local lockData = tweak_data:get_raw_value("preplanning", "types", sp_melementtype, "upgrade_lock") or false
    if not lockData or managers.player:has_category_upgrade(lockData.category, lockData.upgrade) then
        managers.preplanning:reserve_mission_element(sp_melementtype, sp_id)
    end
end

function Vote(sp_votetype, sp_id)
    managers.preplanning:vote_on_plan(sp_votetype, sp_id)
end

function MAsset(sp_id)
    if managers.assets:is_asset_unlockable(sp_id) then
        managers.assets:unlock_asset(sp_id)
    end
end

if managers.preplanning and managers.job and managers.network then
    local sp_current_level_id =  managers.job:current_real_job_id() .. "_" .. managers.job:current_level_id()
    local save_filename = SavePath:gsub("/", "\\") .. "preplanning\\" .. sp_current_level_id .. ".lua"
    local sp_file = io.open(save_filename, "r")
    local sp_mode = sp_checkMode()

    if sp_file == nil then
        sp_chatMessage(username, "No saved " .. sp_mode .. ".")
    else
        sp_file:close()
        dofile(save_filename)
        sp_chatMessage(username, sp_mode:sub(1, 1):upper() .. sp_mode:sub(2) .. " loaded.")
    end
end