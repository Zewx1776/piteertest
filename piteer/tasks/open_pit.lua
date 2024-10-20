local utils      = require "core.utils"
local enums      = require "data.enums"
local navigation = require "core.navigation"
local settings   = require "core.settings"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"
local pitLevels  = require "data.pitlevels"

local last_open  = 0

-- Add this function to reset all necessary values
local function reset_pit_values()
    tracker.finished_time = 0
    tracker.pit_start_time = 0
    explorer.is_task_running = false
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

local function move_to_random_point_3_units_away()
    local player_pos = get_player_position()
    local angle = math.random() * 2 * math.pi
    local random_point = vec3:new(
        player_pos:x() + 3 * math.cos(angle),
        player_pos:y() + 3 * math.sin(angle),
        player_pos:z()
    )
    random_point = set_height_of_valid_position(random_point) -- Correctly reference the function

    if utility.is_point_walkeable(random_point) then
        explorer:set_custom_target(random_point)
        explorer:move_to_target()
        return true
    else
        console.print("Random point is not walkable.")
        return false
    end
end

local task = {
    name = "Open Pit",
    shouldExecute = function()
        return utils.player_in_zone("Scos_Cerrigar") and not utils.get_pit_portal()
    end,
    Execute = function()
        console.print("Executing the task: Open Pit.")
        explorer.reset_exploration()  -- This should now work correctly
        
        -- Add this line to reset all necessary values
        reset_pit_values()
        
        tracker.pit_start_time = get_time_since_inject()
        if tracker.finished_time ~= 0 then
            console.print("Resetting tracker finished time to 0.")
            tracker.finished_time = 0
        end

        local obelisk = utils.get_obelisk()
        if obelisk then
            console.print("Setting target to obelisk.")
            explorer:set_custom_target(enums.positions.obelisk_position)
            explorer:move_to_target()

            -- Check distance to obelisk after moving to target
            if utils.distance_to(obelisk) < 3 then
                console.print("Interacting with obelisk.")
                loot_manager.interact_with_object(obelisk)

                if utils.distance_to(obelisk) < 3 and get_time_since_inject() - last_open > 2 then
                    console.print("Opening pit portal.")
                    local pit_level = settings.pit_level
                    local actual_address = pitLevels[pit_level] or pitLevels[1]

                    utility.open_pit_portal(actual_address)
                    last_open = get_time_since_inject()
                    explorer.is_task_running = false
                end
            else
                console.print("Not close enough to interact with obelisk.")
            end
        else
            console.print("Obelisk not found. Pathfinding to obelisk position.")
            explorer:set_custom_target(enums.positions.obelisk_position)
            explorer:move_to_target()
        end

        -- Move to a random point 3 units away from the player position
        if not move_to_random_point_3_units_away() then
            console.print("Failed to move to a random point 3 units away.")
        end
    end
}

return task
