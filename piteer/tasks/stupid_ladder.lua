local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local tracker = require "core.tracker"

local task = {
    name = "Stupid Ladder",
    shouldExecute = function()
        console.print("Checking if Stupid Ladder should execute...")
        local traversal_controller = utils.get_object_by_name(enums.misc.traversal_controller)
        local should_execute = traversal_controller ~= nil and not tracker.traversal_controller_reached
        console.print("Stupid Ladder should execute: " .. tostring(should_execute))
        return should_execute
    end,
    Execute = function()
        console.print("Executing the task: Stupid Ladder")
        explorer.is_task_running = true  -- Added this line
        local traversal_controller = utils.get_object_by_name(enums.misc.traversal_controller)
        
        if traversal_controller then
            console.print("Traversal Controller found")
            local controller_pos = traversal_controller:get_position()
            console.print("Controller position: " .. tostring(controller_pos:x()) .. ", " .. tostring(controller_pos:y()) .. ", " .. tostring(controller_pos:z()))
            
            console.print("Clearing path and setting custom target")
            explorer:clear_path_and_target()
            explorer:set_custom_target(controller_pos)
            
            console.print("Moving to target")
            explorer:move_to_target()

            local distance = utils.distance_to(controller_pos)
            console.print("Distance to controller: " .. tostring(distance))

            if distance < 2 then
                console.print("Reached Traversal Controller")
                tracker.traversal_controller_reached = true
                console.print("Set tracker.traversal_controller_reached to true")
                -- Add any additional actions you want to perform when reaching the controller
                console.print("Performing additional actions (if any)")
            else
                console.print("Not close enough to Traversal Controller yet")
            end
        else
            console.print("Traversal Controller not found")
        end
        explorer.is_task_running = false  -- Added this line to reset the flag after execution
    end
}

return task
