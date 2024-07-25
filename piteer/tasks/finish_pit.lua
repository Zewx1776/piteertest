local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"

local start_time = 0

local task = {
    name = "Finish Pit",
    shouldExecute = function()
        --console.print("Checking if the task 'Finish Pit' should be executed.")
        return utils.player_on_quest(enums.quests.pit_started) and 
               not utils.player_on_quest(enums.quests.pit_ongoing) and
               utils.loot_on_floor()
    end,
    Execute = function()
        console.print("Executing the task: Finish Pit.")
        explorer.is_task_running = true  -- Set the flag
        console.print("Setting explorer task running flag to true.")
        explorer:clear_path_and_target()
        console.print("Clearing path and target in explorer.")
        
        if start_time == 0 then
            console.print("Setting start time.")
            start_time = get_time_since_inject()
        end

        local items = loot_manager.get_all_items_chest_sort_by_distance()
        if #items > 0 then
            for _, item in pairs(items) do
                if loot_manager.is_lootable_item(item, true, false) then
                    console.print("Setting custom target to item and interacting with it.")
                    explorer:set_custom_target(item)
                    interact_object(item)
                end
            end
        end

        -- Check if 5 seconds have passed
        if get_time_since_inject() - start_time > 15 then
            console.print("5 seconds have passed, resetting start time and task running flag.")
            start_time = 0  -- Reset the start time for the next execution
            explorer.is_task_running = false  -- Reset the flag
            return task
        end

        return task
    end
}

return task
