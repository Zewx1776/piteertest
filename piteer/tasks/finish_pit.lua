local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local settings = require "core.settings"

local start_time = 0
local loot_processed = false  -- Add a flag to track loot processing

local task = {
    name = "Finish Pit",
    shouldExecute = function()
        return utils.player_on_quest(enums.quests.pit_started) and 
               not utils.player_on_quest(enums.quests.pit_ongoing) and
               utils.loot_on_floor() and
               not loot_processed  -- Only execute if loot has not been processed
    end,
    Execute = function()
        console.print("Executing the task: Finish Pit.")
        explorer.is_task_running = true  -- Set the flag
        explorer:clear_path_and_target()
        
        if start_time == 0 then
            start_time = get_time_since_inject()
        end

        local items = loot_manager.get_all_items_chest_sort_by_distance()
        if settings.loot_enabled then
            if #items > 0 then
                for _, item in pairs(items) do
                    if loot_manager.is_lootable_item(item, true, false) then
                        console.print("Setting custom target to item and interacting with it.")
                        explorer:set_custom_target(item)
                        interact_object(item)
                    end
                end
            end
        else
            if #items > 0 then
                for _, item in pairs(items) do
                      if loot_manager.is_lootable_item(item, true, false) then
                        console.print("Setting custom target to item")
                        explorer:set_custom_target(item)
                        explorer:move_to_target()
                    end
                end
            end
        end

        if get_time_since_inject() - start_time > 25 then
            start_time = 0  -- Reset the start time for the next execution
            loot_processed = true  -- Set the flag indicating loot has been processed
            explorer.is_task_running = false  -- Reset the flag
            return task
        end

        explorer.is_task_running = false  -- Reset the flag
        return task
    end
}

return task