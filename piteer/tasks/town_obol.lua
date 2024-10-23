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
            local should_start = utils.player_in_zone("Scos_Cerrigar") and obols > 1500
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

                    local item_count = vendor_items:size()
                    console.print("Vendor items count: " .. item_count)

                    for i = 0, item_count - 1 do
                        local item = vendor_items:get(i)
                        if item then
                            local display_name = item:get_display_name()
                            local price = item:get_price()
                            local player_obols = get_local_player():get_obols()
                            console.print("Item " .. i .. ": " .. display_name .. ", Price: " .. price .. ", Player obols: " .. player_obols)

                            if display_name == settings.gamble_category and price <= player_obols then
                                console.print("Attempting to buy " .. display_name)
                                local success = loot_manager.buy_item(item)
                                console.print("Buy attempt result: " .. tostring(success))
                            else
                                console.print("Skipping item: " .. display_name)
                            end
                        else
                            console.print("Item " .. i .. " is nil")
                        end
                    end
                else
                    console.print("Vendor screen did not open. Skipping purchase.")
                end
            else
                console.print("Player is too far from gambler. Setting new target slightly offset from gambler.")
                local gambler_pos = gambler:get_position()
                local offset_pos = vector3f.new(gambler_pos.x + 0.1, gambler_pos.y + 0.1, gambler_pos.z)
                explorerlite:set_custom_target(offset_pos)
                explorerlite:move_to_target()
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
