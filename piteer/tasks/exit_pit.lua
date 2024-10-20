local utils      = require "core.utils"
local enums      = require "data.enums"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"
local settings   = require "core.settings"

local last_reset = get_time_since_inject()
local cooldown_period = 60 -- 60 seconds cooldown
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
        explorer.is_task_running = true
        explorer:clear_path_and_target()

        if first_run then
            console.print("First run of Exit Pit task. Resetting tracker.finished_time to current time.")
            tracker.finished_time = get_time_since_inject()
            first_run = false
        end

        local current_time = get_time_since_inject()
        local time_since_finish = current_time - tracker.finished_time
        local time_since_last_reset = current_time - last_reset

        console.print("Debug: Current time: " .. current_time)
        console.print("Debug: tracker.finished_time: " .. tracker.finished_time)
        console.print("Debug: Time since finish: " .. time_since_finish)
        console.print("Debug: Time since last reset: " .. time_since_last_reset)

        if time_since_finish > 40 then
            if time_since_last_reset > cooldown_period then
                last_reset = current_time
                reset_all_dungeons()
                console.print("Resetting all dungeons at time: " .. current_time)
            else
                console.print("Cooldown period not met. Skipping reset. Time remaining: " .. (cooldown_period - time_since_last_reset))
            end
        else
            console.print("Not enough time has passed since last finish. Time remaining: " .. (40 - time_since_finish))
        end

        explorer.is_task_running = false
    end
}

return task
