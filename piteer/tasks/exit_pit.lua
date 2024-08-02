local utils      = require "core.utils"
local enums      = require "data.enums"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"

local last_reset = 0
local task = {
    name = "Exit Pit",
    shouldExecute = function()
        --console.print("Checking if the task 'Exit Pit' should be executed.")
        return utils.player_on_quest(enums.quests.pit_started) and not utils.player_on_quest(enums.quests.pit_ongoing) --and
               --not utils.loot_on_floor()
    end,
    Execute = function()
        console.print("Executing the task: Exit Pit.")
        explorer.is_task_running = true  -- Set the flag
        console.print("Setting explorer task running flag to true.")
        explorer:clear_path_and_target()
        console.print("Clearing path and target in explorer.")
        
        if tracker.finished_time == 0 then
            console.print("Setting finished time in tracker.")
            tracker.finished_time = get_time_since_inject()
        end

        if get_time_since_inject() > tracker.finished_time + 7 then
            if get_time_since_inject() - last_reset > 10 then
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