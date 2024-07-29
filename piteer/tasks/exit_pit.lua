local utils      = require "core.utils"
local enums      = require "data.enums"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"
local settings   = require "core.settings"
local finish_pit = require "tasks.finish_pit"  -- Import the finish_pit task

local last_reset = 0
local task = {
    name = "Exit Pit",
    shouldExecute = function()
        return utils.player_on_quest(enums.quests.pit_started) and 
               not utils.player_on_quest(enums.quests.pit_ongoing) and
               (not utils.loot_on_floor() or not settings.loot_enabled)
    end,
    Execute = function()
        console.print("Executing the task: Exit Pit.")
        explorer.is_task_running = true  -- Set the flag
        explorer:clear_path_and_target()
        
        if tracker.finished_time == 0 then
            tracker.finished_time = get_time_since_inject()
        end

        if get_time_since_inject() > tracker.finished_time + 7 then
            if get_time_since_inject() - last_reset > 10 then
                last_reset = get_time_since_inject()
                reset_all_dungeons()
                console.print("Resetting all dungeons at time: " .. get_time_since_inject())
            end
        end

        if not utils.player_on_quest(enums.quests.pit_started) then
            explorer.is_task_running = false  -- Reset the flag
            finish_pit.loot_processed = false  -- Reset the loot_processed flag
            return task
        end

        explorer.is_task_running = false  -- Reset the flag
    end
}

return task