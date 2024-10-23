local utils      = require "core.utils"
local enums      = require "data.enums"
local navigation = require "core.navigation"
local settings   = require "core.settings"
local tracker    = require "core.tracker"
local explorerlite   = require "core.explorerlite"
local pitLevels  = require "data.pitlevels"

local last_open  = 0

-- Add this function to reset all necessary values
local function reset_pit_values()
    tracker.finished_time = 0
    tracker.pit_start_time = 0
    explorerlite.is_task_running = false
    tracker:set_boss_task_running(false)
    -- Reset last_reset in exit_pit.lua
    -- Since we can't directly access variables in other files,
    -- we'll need to create a function in exit_pit.lua to reset it
    if exit_pit and exit_pit.reset_last_reset then
        exit_pit.reset_last_reset()
    end
end

local function set_height_of_valid_position(point)
    --console.print("Setting height of valid position.")
    return utility.set_height_of_valid_position(point)
end

local function set_offset_target(original_position, offset)
    return vec3:new(
        original_position:x() + offset,
        original_position:y() + offset,
        original_position:z()
    )
end

local task = {
    name = "Open Pit",
    shouldExecute = function()
        return utils.player_in_zone("Scos_Cerrigar") and not utils.get_pit_portal()
    end,
    Execute = function()
        console.print("Executing the task: Open Pit.")
        --explorerlite:reset_exploration()
        
        reset_pit_values()
        
        tracker.pit_start_time = get_time_since_inject()
        if tracker.finished_time ~= 0 then
            console.print("Resetting tracker finished time to 0.")
            tracker.finished_time = 0
        end

        local obelisk = utils.get_obelisk()
        if obelisk then
            local obelisk_position = obelisk:get_position()
            console.print("Setting target to obelisk.")
            explorerlite:set_custom_target(obelisk_position)
            explorerlite:move_to_target()

            -- Check distance to obelisk after moving to target
            if utils.distance_to(obelisk) < 2 then
                console.print("Interacting with obelisk.")
                loot_manager.interact_with_object(obelisk)

                if utils.distance_to(obelisk) < 3 and get_time_since_inject() - last_open > 2 then
                    console.print("Opening pit portal.")
                    local pit_level = settings.pit_level
                    local actual_address = pitLevels[pit_level] or pitLevels[1]

                    utility.open_pit_portal(actual_address)
                    last_open = get_time_since_inject()
                    explorerlite.is_task_running = false
                end
            elseif utils.distance_to(obelisk) < 4 then
                console.print("Not close enough to interact with obelisk.")
                local offset_position = set_offset_target(enums.positions.obelisk_position, 0.1)
                console.print("Setting new target slightly offset from obelisk.")
                explorerlite:set_custom_target(offset_position)
                explorerlite:move_to_target()
            else
                console.print("Too far from obelisk. Moving closer.")
                explorerlite:set_custom_target(obelisk_position)
                explorerlite:move_to_target()
            end
        else
            console.print("Obelisk not found. Pathfinding to obelisk position.")
            explorerlite:set_custom_target(enums.positions.obelisk_position)
            explorerlite:move_to_target()
        end
    end
}

return task
