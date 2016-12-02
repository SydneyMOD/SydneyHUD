-- Preplanned - By ThatGuyFromBreakingBad
-- LoadPreplanning.lua
-- v1.34.3_0

function MElement(sp_melementtype, sp_id)
    local lockData = tweak_data:get_raw_value("preplanning", "types", sp_melementtype, "upgrade_lock") or false
    if not lockData or managers.player:has_category_upgrade(lockData.category, lockData.upgrade) then
        managers.preplanning:reserve_mission_element(sp_melementtype, sp_id)
    end
end

function Vote(sp_votetype, sp_id)
    managers.preplanning:vote_on_plan(sp_votetype, sp_id)
end

if managers.preplanning and managers.job and managers.network then
    local sp_current_level_id =  managers.job:current_real_job_id() .. "_" .. managers.job:current_level_id()
    dofile(SavePath .. "preplanning/" .. sp_current_level_id .. ".lua")
    if managers.chat then
        managers.chat:feed_system_message(ChatManager.GAME, "Preplanned: Preplanning loaded")
    end
end
