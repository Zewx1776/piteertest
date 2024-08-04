local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local tracker = require "core.tracker"

local task  = {
    name = "Enter Portal",
    shouldExecute = function()
        --console.print("Checking if the task should be executed.")
        return utils.get_pit_portal()
    end,
    Execute = function()
        console.print("Executing the task: Enter Portal.")
        local portal = utils.get_pit_portal()
        if portal then
            if utils.player_on_quest(enums.quests.pit_ongoing) then
                console.print("Player is on the quest 'pit_ongoing'. Clearing path and setting target to portal.")
                explorer:clear_path_and_target()
                explorer:set_custom_target(portal:get_position())
                explorer:move_to_target()

                -- Check if the player is close enough to interact with the portal
                if utils.distance_to(portal) < 2 then
                    console.print("Player is close enough to the portal. Interacting with the portal.")
                    interact_object(portal)
                end
            else
                console.print("Player is not on the quest 'pit_ongoing'. Interacting with the portal using loot manager.")
                loot_manager.interact_with_object(portal)
            end
        end
    end
}

return task