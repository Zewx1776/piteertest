local utils      = require "core.utils"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"
local exit_pit   = require "tasks.exit_pit"

local task = {
    name = "Exit Pit After Time",
    shouldExecute = function()
        return tracker.pit_start_time > 0 and (get_time_since_inject() - tracker.pit_start_time) > 60
    end,
    Execute = function()
        console.print("Executing the task: Exit Pit After Time.")
        exit_pit.Execute()
        tracker.pit_start_time = 0  -- Reset the pit start time
    end
}

return task