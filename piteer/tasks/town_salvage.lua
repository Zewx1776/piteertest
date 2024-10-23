local utils = require "core.utils"
local enums = require "data.enums"
local explorerlite = require "core.explorerlite"
local settings = require "core.settings"
local tracker = require "core.tracker"
local gui = require "gui"

local salvage_state = {
    INIT = "INIT",
    TELEPORTING = "TELEPORTING",
    MOVING_TO_BLACKSMITH = "MOVING_TO_BLACKSMITH",
    INTERACTING_WITH_BLACKSMITH = "INTERACTING_WITH_BLACKSMITH",
    SALVAGING = "SALVAGING",
    MOVING_TO_PORTAL = "MOVING_TO_PORTAL",
    INTERACTING_WITH_PORTAL = "INTERACTING_WITH_PORTAL",
    FINISHED = "FINISHED",
}

local uber_table = {
    { name = "Tyrael's Might", sno = 1901484 },
    { name = "The Grandfather", sno = 223271 },
    { name = "Andariel's Visage", sno = 241930 },
    { name = "Ahavarion, Spear of Lycander", sno = 359165 },
    { name = "Doombringer", sno = 221017 },
    { name = "Harlequin Crest", sno = 609820 },
    { name = "Melted Heart of Selig", sno = 1275935 },
    { name = "‍Ring of Starless Skies", sno = 1306338 },
    { name = "Shroud of False Death", sno = 2059803 },
    { name = "Nesekem, the Herald", sno = 1982241 },
    { name = "Heir of Perdition", sno = 2059799 },
    { name = "Shattered Vow", sno = 2059813 }
}

local function is_uber_item(sno_to_check)
    for _, entry in ipairs(uber_table) do
        if entry.sno == sno_to_check then
            return true
        end
    end
    return false
end

local function salvage_low_greater_affix_items()
    local local_player = get_local_player()
    if not local_player then
        return
    end

    local inventory_items = local_player:get_inventory_items()
    for _, inventory_item in pairs(inventory_items) do
        if inventory_item and not inventory_item:is_locked() then
            local display_name = inventory_item:get_display_name()
            local greater_affix_count = utils.get_greater_affix_count(display_name)
            local item_id = inventory_item:get_sno_id()

            if greater_affix_count < settings.greater_affix_threshold and not is_uber_item(item_id) then
                loot_manager.salvage_specific_item(inventory_item)
            end
        end
    end
end

local town_salvage_task = {
    name = "Town Salvage",
    current_state = salvage_state.INIT,
    max_retries = 5,
    current_retries = 0,
    max_teleport_attempts = 5,
    teleport_wait_time = 30,
    last_teleport_check_time = 0,
    last_blacksmith_interaction_time = 0,
    last_salvage_action_time = 0,
    last_salvage_completion_check_time = 0,
    last_portal_interaction_time = 0,
    teleport_start_time = 0,
    teleport_attempts = 0,
    interaction_time = 0,
    last_salvage_time = 0,
    portal_interact_time = 0,
    reset_salvage_time = 0,
}

function town_salvage_task.shouldExecute()
    local player = get_local_player()
    local inventory_full = utils.is_inventory_full()
    local in_cerrigar = utils.player_in_zone("Scos_Cerrigar")
    
    if inventory_full then
        tracker.needs_salvage = true
        return true
    end
    
    if in_cerrigar and tracker.needs_salvage then
        return true
    end
    
    return false
end

function town_salvage_task.Execute()
    tracker:set_boss_task_running(true)
    console.print("Executing Town Salvage Task")
    console.print("Current state: " .. town_salvage_task.current_state)

    if town_salvage_task.current_retries >= town_salvage_task.max_retries then
        console.print("Max retries reached. Resetting task.")
        town_salvage_task.reset()
        return
    end

    if town_salvage_task.current_state == salvage_state.INIT then
        town_salvage_task.init_salvage()
    elseif town_salvage_task.current_state == salvage_state.TELEPORTING then
        town_salvage_task.handle_teleporting()
    elseif town_salvage_task.current_state == salvage_state.MOVING_TO_BLACKSMITH then
        town_salvage_task.move_to_blacksmith()
    elseif town_salvage_task.current_state == salvage_state.INTERACTING_WITH_BLACKSMITH then
        town_salvage_task.interact_with_blacksmith()
    elseif town_salvage_task.current_state == salvage_state.SALVAGING then
        town_salvage_task.salvage_items()
    elseif town_salvage_task.current_state == salvage_state.MOVING_TO_PORTAL then
        town_salvage_task.move_to_portal()
    elseif town_salvage_task.current_state == salvage_state.INTERACTING_WITH_PORTAL then
        town_salvage_task.interact_with_portal()
    elseif town_salvage_task.current_state == salvage_state.FINISHED then
        town_salvage_task.finish_salvage()
    end
end

function town_salvage_task.init_salvage()
    console.print("Initializing salvage process")
    if not utils.player_in_zone("Scos_Cerrigar") and get_local_player():get_item_count() >= 21 then
        town_salvage_task.current_state = salvage_state.TELEPORTING
        town_salvage_task.teleport_start_time = get_time_since_inject()
        town_salvage_task.teleport_attempts = 0
        town_salvage_task.teleport_to_town()
        console.print("Player not in Cerrigar, initiating teleport")
    else
        town_salvage_task.current_state = salvage_state.MOVING_TO_BLACKSMITH
        console.print("Player in Cerrigar, moving to blacksmith")
    end
end

function town_salvage_task.teleport_to_town()
    console.print("Teleporting to town")
    explorerlite:clear_path_and_target()
    teleport_to_waypoint(enums.waypoints.CERRIGAR)
    town_salvage_task.teleport_start_time = get_time_since_inject()
    console.print("Teleport command issued")
end

function town_salvage_task.handle_teleporting()
    local current_time = get_time_since_inject()
    if current_time - town_salvage_task.last_teleport_check_time >= 5 then
        town_salvage_task.last_teleport_check_time = current_time
        local current_zone = get_current_world():get_current_zone_name()
        console.print("Current zone: " .. tostring(current_zone))
        
        if current_zone:find("Cerrigar") or utils.player_in_zone("Scos_Cerrigar") then
            console.print("Teleport complete, moving to blacksmith")
            town_salvage_task.current_state = salvage_state.MOVING_TO_BLACKSMITH
            town_salvage_task.teleport_attempts = 0 -- Reset attempts counter
        else
            console.print("Teleport unsuccessful, retrying...")
            town_salvage_task.teleport_attempts = (town_salvage_task.teleport_attempts or 0) + 1
            
            if town_salvage_task.teleport_attempts >= town_salvage_task.max_teleport_attempts then
                console.print("Max teleport attempts reached. Resetting task.")
                town_salvage_task.reset()
                return
            end
            
            town_salvage_task.teleport_to_town()
        end
    end
end

function town_salvage_task.move_to_blacksmith()
    tracker:set_boss_task_running(false)
    console.print("Moving to blacksmith")
    console.print("Explorer object: " .. tostring(explorerlite))
    console.print("set_custom_target exists: " .. tostring(type(explorerlite.set_custom_target) == "function"))
    console.print("move_to_target exists: " .. tostring(type(explorerlite.move_to_target) == "function"))
    
    local blacksmith = utils.get_blacksmith()
    if blacksmith then
        explorerlite:set_custom_target(blacksmith:get_position())
        explorerlite:move_to_target()
        if utils.distance_to(blacksmith) < 2 then
            console.print("Reached blacksmith")
            town_salvage_task.current_state = salvage_state.INTERACTING_WITH_BLACKSMITH
        end
    else
        console.print("No blacksmith found, trying alternative positions...")
        local alternative_positions = {
            enums.positions.blacksmith_position,
            vec3:new(-1672.0946044922, -597.67523193359, 36.9287109375),  -- Add more alternative positions here
            vec3:new(-1672.1946044922, -597.57523193359, 36.8287109375),
        }
        
        for _, pos in ipairs(alternative_positions) do
            explorerlite:set_custom_target(pos)
            explorerlite:move_to_target()
            if utils.distance_to(pos) < 5 then
                console.print("Reached alternative position near blacksmith")
                town_salvage_task.current_state = salvage_state.INTERACTING_WITH_BLACKSMITH
                return
            end
        end
        
        console.print("Failed to reach blacksmith or alternative positions")
        town_salvage_task.current_retries = town_salvage_task.current_retries + 1
    end
end

function town_salvage_task.interact_with_blacksmith()
    console.print("Interacting with blacksmith")
    local blacksmith = utils.get_blacksmith()
    if blacksmith then
        local current_time = get_time_since_inject()
        if current_time - town_salvage_task.last_blacksmith_interaction_time >= 2 then
            town_salvage_task.last_blacksmith_interaction_time = current_time
            interact_vendor(blacksmith)
            console.print("Interacted with blacksmith, waiting 5 seconds before salvaging")
            town_salvage_task.interaction_time = current_time
            town_salvage_task.current_state = salvage_state.SALVAGING
        end
    else
        console.print("Blacksmith not found, moving back")
        town_salvage_task.current_state = salvage_state.MOVING_TO_BLACKSMITH
    end
end

function town_salvage_task.salvage_items()
    console.print("Salvaging items")
    
    local current_time = get_time_since_inject()
    
    if not town_salvage_task.interaction_time or current_time - town_salvage_task.interaction_time >= 1 then
        if not town_salvage_task.last_salvage_time then
            salvage_low_greater_affix_items()
            town_salvage_task.last_salvage_time = current_time
            console.print("Salvage action performed, waiting 2 seconds before checking results")
        elseif current_time - town_salvage_task.last_salvage_time >= 2 then
            local item_count = get_local_player():get_item_count()
            console.print("Current item count: " .. item_count)
            
            if item_count <= 19 then
                tracker.has_salvaged = true
                tracker.needs_salvage = false
                console.print("Salvage complete, item count is 25 or less. Finishing task.")
                town_salvage_task.finish_salvage()
            else
                console.print("Item count is still above 25, retrying salvage")
                town_salvage_task.current_retries = town_salvage_task.current_retries + 1
                if town_salvage_task.current_retries >= town_salvage_task.max_retries then
                    console.print("Max retries reached. Resetting task.")
                    town_salvage_task.reset()
                else
                    town_salvage_task.last_salvage_time = nil  -- Reset this to allow immediate salvage on next cycle
                    town_salvage_task.current_state = salvage_state.INTERACTING_WITH_BLACKSMITH
                end
            end
        end
    else
        console.print("Waiting for 5-second delay after blacksmith interaction")
    end
end

function town_salvage_task.move_to_portal()
    tracker:set_boss_task_running(false)
    console.print("Moving to portal")
    explorerlite:set_custom_target(enums.positions.portal_position)
    explorerlite:move_to_target()
    if utils.distance_to(enums.positions.portal_position) < 5 then
        console.print("Reached portal")
        town_salvage_task.current_state = salvage_state.INTERACTING_WITH_PORTAL
        town_salvage_task.portal_interact_time = 0  -- Initialize portal interaction timer
    end
end

function town_salvage_task.interact_with_portal()
    tracker:set_boss_task_running(true)
    console.print("Interacting with portal")
    local portal = utils.get_town_portal()
    local current_time = get_time_since_inject()
    local current_zone = get_current_world():get_current_zone_name()
    
    if portal then
        if current_zone:find("Cerrigar") or utils.player_in_zone("Scos_Cerrigar") then
            if town_salvage_task.last_portal_interaction_time == nil or current_time - town_salvage_task.last_portal_interaction_time >= 1 then
                console.print("Still in Cerrigar, attempting to interact with portal")
                interact_object(portal)
                town_salvage_task.last_portal_interaction_time = current_time
                town_salvage_task.portal_interaction_start_time = current_time  -- Add this line
            end
        else
            if town_salvage_task.portal_interaction_start_time and current_time - town_salvage_task.portal_interaction_start_time >= 5 then
                console.print("Successfully left Cerrigar and waited 5 seconds")
                tracker.has_salvaged = false
                tracker.needs_salvage = false
                town_salvage_task.reset()
                return
            else
                console.print("Waiting for 5 seconds after leaving Cerrigar...")
                return  -- Add this line to prevent the task from completing immediately
            end
        end
    
        if town_salvage_task.portal_interact_time == 0 then
            console.print("Starting portal interaction timer.")
            town_salvage_task.portal_interact_time = current_time
        elseif current_time - town_salvage_task.portal_interact_time >= 30 then
            console.print("Portal interaction timed out after 30 seconds. Resetting task.")
            town_salvage_task.reset()
        else
            console.print(string.format("Waiting for portal interaction... Time elapsed: %.2f seconds", current_time - town_salvage_task.portal_interact_time))
        end
    else
        console.print("Town portal not found")
        tracker.has_salvaged = false
        tracker.needs_salvage = false
        town_salvage_task.reset()
        town_salvage_task.current_state = salvage_state.INIT  -- Go back to moving if portal not found
    end
end

function town_salvage_task.finish_salvage()
    console.print("Finishing salvage task")
    tracker.has_salvaged = true
    tracker.needs_salvage = false
    town_salvage_task.reset()
    console.print("Town salvage task finished")
end

function town_salvage_task.reset()
    console.print("Resetting town salvage task")
    town_salvage_task.current_state = salvage_state.INIT
    town_salvage_task.portal_interact_time = 0
    town_salvage_task.reset_salvage_time = 0
    town_salvage_task.current_retries = 0
    tracker:set_boss_task_running(true)
    explorerlite.is_task_running = false
    console.print("Reset town_salvage_task and related tracker flags")
end

return town_salvage_task
