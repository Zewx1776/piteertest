local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local tracker = require "core.tracker"

local task = {
    name = "Stupid Ladder",
    shouldExecute = function()
        local traversal_controller = utils.get_object_by_name(enums.misc.traversal_controller)
        local should_execute = traversal_controller ~= nil and not tracker.traversal_controller_reached
        --console.print("Stupid Ladder should execute: " .. tostring(should_execute))
        return should_execute
    end,
    Execute = function()
        explorer.is_task_running = true
        local traversal_controller = utils.get_object_by_name(enums.misc.traversal_controller)
        
        if traversal_controller then
            local controller_pos = traversal_controller:get_position()
            
            explorer:set_custom_target(controller_pos)
            explorer:move_to_target()

            local distance = utils.distance_to(controller_pos)

            if distance < 1 then
                tracker.traversal_controller_reached = true
                -- Add any additional actions you want to perform when reaching the controller
            end
        end
        explorer.is_task_running = false
    end
}

return task
