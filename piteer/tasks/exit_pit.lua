local utils      = require "core.utils"
local enums      = require "data.enums"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"
local settings   = require "core.settings"

local last_reset = 0
local task = {
    name = "Exit Pit",
    shouldExecute = function()
        return settings.exit_pit_enabled and
               utils.get_object_by_name(enums.misc.gizmo_paragon_glyph_upgrade) ~= nil and
               utils.get_pit_portal() == nil
    end,
    Execute = function()
        console.print("Executing the task: Exit Pit.")
        explorer.is_task_running = true  -- Set the flag
        console.print("Setting explorer task running flag to true.")
        explorer:clear_path_and_target()
        tracker:set_boss_task_running(true)
        console.print("Clearing path and target in explorer.")
        
        if tracker.finished_time == 0 then
            console.print("Setting finished time in tracker.")
            tracker.finished_time = get_time_since_inject()
        end

        if get_time_since_inject() > tracker.finished_time + 10 then
            if get_time_since_inject() - last_reset > 20 then
                last_reset = get_time_since_inject()
                reset_all_dungeons()
                console.print("Resetting all dungeons at time: " .. get_time_since_inject())
            end
        end

        -- Check if the player is no longer on the quest 'pit_started'
        if not utils.player_on_quest(enums.quests.pit_started) then
            console.print("Player is no longer on the quest 'pit_started'. Exiting task.")
            explorer.is_task_running = false  -- Reset the flag
            return task
        end

        explorer.is_task_running = false  -- Reset the flag
        console.print("Setting explorer task running flag to false.")
    end
}

return task
