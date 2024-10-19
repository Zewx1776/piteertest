local utils      = require "core.utils"
local enums      = require "data.enums"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"
local settings   = require "core.settings"

local last_reset = get_time_since_inject()
local cooldown_period = 60 -- 60 seconds cooldown
local last_reset_time = 0
local first_run = true

local task = {
    name = "Exit Pit",
    shouldExecute = function()
        return settings.exit_pit_enabled and
               utils.get_object_by_name(enums.misc.gizmo_paragon_glyph_upgrade) ~= nil and
               not utils.get_pit_portal()
    end,
    Execute = function()
        console.print("Executing the task: Exit Pit.")
        explorer.is_task_running = true  -- Set the flag
        explorer:clear_path_and_target()

        if first_run then
            console.print("First run of Exit Pit task. Resetting tracker.finished_time to 0.")
            tracker.finished_time = 0
            first_run = false
        end

        console.print("Debug: Current time: " .. get_time_since_inject())
        console.print("Debug: tracker.finished_time: " .. tracker.finished_time)
        console.print("Debug: Time since last reset: " .. (get_time_since_inject() - last_reset))

        if get_time_since_inject() > tracker.finished_time + 10 then
            if get_time_since_inject() - last_reset > 20 and get_time_since_inject() - last_reset_time > cooldown_period then
                last_reset = get_time_since_inject()
                last_reset_time = get_time_since_inject()
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
