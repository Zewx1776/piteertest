local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local tracker = require "core.tracker"
local settings = require "core.settings"  -- Make sure to include settings

local task  = {
    name = "Enter Portal",
    shouldExecute = function()
        local portal = utils.get_pit_portal()
        console.print("Enter Portal shouldExecute: Portal found: " .. tostring(portal ~= nil))
        return portal ~= nil
    end,
    Execute = function()
        console.print("Executing the task: Enter Portal.")
        local portal = utils.get_pit_portal()
        if portal then
            local is_player_in_pit = (utils.player_in_zone("EGD_MSWK_World_02") or utils.player_in_zone("EGD_MSWK_World_01")) and settings.enabled
            local is_player_in_cerrigar = utils.player_in_zone("Scos_Cerrigar")
            console.print("Is player in pit: " .. tostring(is_player_in_pit))
            console.print("Is player in Cerrigar: " .. tostring(is_player_in_cerrigar))
            console.print("Settings enabled: " .. tostring(settings.enabled))
            
            if is_player_in_pit then
                console.print("Player is in the pit zone. Clearing path and setting target to portal.")
                explorer:clear_path_and_target()
                explorer:set_custom_target(portal:get_position())
                explorer:move_to_target()

                -- Check if the player is close enough to interact with the portal
                local distance_to_portal = utils.distance_to(portal)
                console.print("Distance to portal: " .. tostring(distance_to_portal))
                if distance_to_portal < 2 then
                    console.print("Player is close enough to the portal. Interacting with the portal.")
                    interact_object(portal)
                    tracker.start_location_reached = false
                    console.print("Set tracker.start_location_reached to false")
                end
            else
                console.print("Player is not in the pit zone.")
                if is_player_in_cerrigar then
                    console.print("Player is in Cerrigar. Interacting with the portal using loot manager.")
                    loot_manager.interact_with_object(portal)
                    tracker.start_location_reached = false
                    console.print("Set tracker.start_location_reached to false")
                else
                    console.print("Player is not in Cerrigar. Using regular interact_object.")
                    interact_object(portal)
                    tracker.start_location_reached = false
                    console.print("Set tracker.start_location_reached to false")
                end
            end
        else
            console.print("Portal not found in Execute function.")
        end
    end
}

return task
