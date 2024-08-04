local utils      = require "core.utils"
local enums      = require "data.enums"
local navigation = require "core.navigation"
local settings   = require "core.settings"
local tracker    = require "core.tracker"
local explorer   = require "core.explorer"

local last_open  = 0

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
        --console.print("Checking if the task 'Open Pit' should be executed.")
        return utils.player_in_zone("Scos_Cerrigar") and not utils.get_pit_portal()
    end,
    Execute = function()
        console.print("Executing the task: Open Pit.")
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

                if utils.distance_to(obelisk) < 2 and get_time_since_inject() - last_open > 2 then
                    console.print("Opening pit portal.")
                    local pit_level = settings.pit_level
                    local actual_address = 0x1C34EB

                    if pit_level <= 16 then
                        if math.abs(pit_level - 1) <= math.abs(pit_level - 31) then
                            actual_address = 0x1C34EB
                        else
                            actual_address = 0x1C352B
                        end
                    elseif pit_level <= 61 then
                        if math.abs(pit_level - 31) <= math.abs(pit_level - 51) then
                            actual_address = 0x1C352B
                        elseif math.abs(pit_level - 51) <= math.abs(pit_level - 61) then
                            actual_address = 0x1C3554
                        else
                            actual_address = 0x1C3568
                        end
                    elseif pit_level <= 81 then
                        if math.abs(pit_level - 61) <= math.abs(pit_level - 75) then
                            actual_address = 0x1C3568
                        elseif math.abs(pit_level - 75) <= math.abs(pit_level - 81) then
                            actual_address = 0x1C3586
                        else
                            actual_address = 0x1C3595
                        end
                    elseif pit_level <= 101 then
                        if math.abs(pit_level - 81) <= math.abs(pit_level - 98) then
                            actual_address = 0x1C3595
                        elseif math.abs(pit_level - 98) <= math.abs(pit_level - 100) then
                            actual_address = 0x1C35BC
                        else
                            actual_address = 0x1C35C1
                        end
                    elseif pit_level <= 121 then
                        if math.abs(pit_level - 101) <= math.abs(pit_level - 119) then
                            actual_address = 0x1D6CEF
                        elseif math.abs(pit_level - 119) <= math.abs(pit_level - 121) then
                            actual_address = 0x1D6D1D
                        else
                            actual_address = 0x1D6D21
                        end
                    elseif pit_level <= 129 then
                        if math.abs(pit_level - 121) <= math.abs(pit_level - 129) then
                            actual_address = 0x1D6D21
                        else
                            actual_address = 0x1D6D36
                        end
                    else
                        if math.abs(pit_level - 129) <= math.abs(pit_level - 141) then
                            actual_address = 0x1D6D36
                        else
                            actual_address = 0x1D6D4E
                        end
                    end

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