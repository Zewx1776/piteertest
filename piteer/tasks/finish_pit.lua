local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local settings = require "core.settings"
local tracker = require "core.tracker"

local start_time = 0

local task = {
    name = "Finish Pit",
    shouldExecute = function()
        console.print("Checking if Finish Pit task should execute...")
        return utils.get_object_by_name(enums.misc.gizmo_paragon_glyph_upgrade) ~= nil
    end,
    Execute = function()
        console.print("Executing the task: Finish Pit.")
        explorer.is_task_running = true
        explorer:clear_path_and_target()
        
        tracker:set_boss_task_running(false)
        
        local current_time = get_time_since_inject()
        console.print(string.format("Current time: %.2f, Start time: %.2f", current_time, start_time))
        
        if start_time == 0 then
            start_time = current_time
            console.print(string.format("Setting start time to: %.2f", start_time))
        end

        if current_time - start_time > 100 then
            console.print("More than 100 seconds have passed. Resetting task.")
            start_time = 0
            explorer.is_task_running = false
            return task
        end

        local items = loot_manager.get_all_items_chest_sort_by_distance()
        console.print(string.format("Found %d items to process", #items))

        if settings.loot_enabled then
            console.print("Loot is enabled. Processing items...")
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
            console.print("Loot is disabled. Moving to items...")
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

        current_time = get_time_since_inject()
        console.print(string.format("Current time: %.2f, Start time: %.2f", current_time, start_time))
        if current_time - start_time > 25 then
            console.print("25 seconds have passed. Resetting task and dungeons.")
            start_time = 0
            explorer.is_task_running = false
            reset_all_dungeons()
            return task
        end

        explorer.is_task_running = false
        console.print("Finish Pit task completed.")
        return task
    end
}

return task
