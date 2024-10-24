local utils = require "core.utils"
local enums = require "data.enums"
local explorerlite = require "core.explorerlite"
local settings = require "core.settings"
local gui = require "gui"
local tracker = require "core.tracker"

--- @field get_obols fun(self:game.object):number 

-- Print the number of obols before the task definition
local player = get_local_player()
if player then
    local obols = player:get_obols()
    console.print("Current number of obols: " .. obols)
end

local is_running = false  -- State variable moved outside the task table

local task = {
    name = "Obol Vendor",
    shouldExecute = function()
        local player = get_local_player()
        local obols = player:get_obols()
        console.print("Checking shouldExecute: Obols = " .. obols .. ", Is running = " .. tostring(is_running))
        if not is_running then
            local should_start = utils.player_in_zone("Scos_Cerrigar") and obols > 1000
            console.print("Should start task: " .. tostring(should_start))
            return should_start
        else
            local should_continue = utils.player_in_zone("Scos_Cerrigar") and obols >= 100
            console.print("Should continue task: " .. tostring(should_continue))
            return should_continue
        end
    end,
    Execute = function()
        is_running = true
        console.print("Starting Execute function")
        
        local gambler = utils.get_gambler()
        if gambler then
            console.print("Setting target to GAMBLER: " .. gambler:get_skin_name())
            explorerlite:set_custom_target(gambler)
            explorerlite:move_to_target()

            local distance = utils.distance_to(gambler)
            console.print("Distance to gambler: " .. distance)
            
            -- Check if we're close enough to interact or if the vendor screen is already open
            if distance < 2 or loot_manager.is_in_vendor_screen() then
                if not loot_manager.is_in_vendor_screen() then
                    console.print("Player is close enough to the gambler. Interacting with the gambler.")
                    interact_vendor(gambler)
                end

                console.print("Checking if vendor screen is open")
                if loot_manager.is_in_vendor_screen() then
                    console.print("Vendor screen is open. Attempting to buy items.")
                    local vendor_items = loot_manager.get_vendor_items()
                    console.print("Vendor items type: " .. type(vendor_items))

                    -- Print information about the vendor_items object
                    console.print("Printing vendor_items information:")
                    if type(vendor_items) == "userdata" and vendor_items.size then
                        local size = vendor_items:size()
                        console.print("  Size: " .. tostring(size))
                        
                        local player_obols = get_local_player():get_obols()
                        console.print("Player obols: " .. tostring(player_obols))
                        
                        local affordable_items = {}
                        
                        for i = 1, size do  -- Changed from 0 to 1, and from size-1 to size
                            local item = vendor_items:get(i)
                            if item then
                                local display_name = item:get_display_name()
                                local price = item:get_price()
                                local skin_name = item:get_skin_name()
                                local name = item:get_name()
                                local sno_id = item:get_sno_id()
                                console.print("Item " .. i .. ":")
                                console.print("  Display Name: " .. tostring(display_name))
                                console.print("  Skin Name: " .. tostring(skin_name))
                                console.print("  Name: " .. tostring(name))
                                console.print("  SNO ID: " .. tostring(sno_id))
                                console.print("  Price: " .. tostring(price))
                                console.print("  Player obols: " .. tostring(player_obols))

                                if display_name == settings.gamble_category and price and player_obols and price <= player_obols then
                                    console.print("Attempting to buy " .. tostring(display_name))
                                    local success = loot_manager.buy_item(item)
                                    console.print("Buy attempt result: " .. tostring(success))
                                else
                                    console.print("Skipping item: " .. tostring(display_name))
                                end
                            else
                                console.print("Item " .. i .. " is nil")
                            end
                        end
                    else
                        console.print("Vendor items is not a userdata")
                    end
                else
                    console.print("Vendor screen did not open. Skipping purchase.")
                end
            else
                console.print("Player is too far from gambler. Setting new target slightly offset from gambler.")
                local gambler_pos = gambler:get_position()
                -- Check if gambler_pos is a table with x, y, z fields
                if type(gambler_pos) == "table" and type(gambler_pos.x) == "number" and type(gambler_pos.y) == "number" and type(gambler_pos.z) == "number" then
                    local offset_pos = vec3:new(gambler_pos.x + 0.1, gambler_pos.y + 0.1, gambler_pos.z)
                    explorerlite:set_custom_target(offset_pos)
                    explorerlite:move_to_target()
                else
                    console.print("Error: Invalid gambler position")
                    -- Set a default target or handle the error as appropriate
                    explorerlite:set_custom_target(gambler)
                    explorerlite:move_to_target()
                end
            end

            return true
        else
            console.print("No gambler found")
            tracker:set_boss_task_running(false)
            explorerlite:set_custom_target(enums.positions.gambler_position)
            explorerlite:move_to_target()
            
            local player = get_local_player()
            local obols = player:get_obols()
            console.print("Current obols: " .. obols)
            if obols < 100 then
                console.print("Obols below 100, stopping task")
                is_running = false
            end
            
            return false
        end 
    end
}

return task
