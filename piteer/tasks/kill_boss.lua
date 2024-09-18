local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local tracker = require "core.tracker"

local ROTATION_RADIUS = 6 -- Adjust this value to change the radius of the rotation points
local ROTATION_POINTS = 7
local BAD_ACTORS = {
    "fxkit_damaging_persistentCylindrical_demonic_core_fxMesh",
    "demonic",  -- This will match any actor name containing "demonic"
    "uber",
    "npc"      -- This will match any actor name containing "uber"
}

local function calculate_rotation_points(boss_pos)
    local points = {}
    for i = 1, ROTATION_POINTS do
        local angle = (i - 1) * (2 * math.pi / ROTATION_POINTS)
        local x = boss_pos:x() + ROTATION_RADIUS * math.cos(angle)
        local y = boss_pos:y() + ROTATION_RADIUS * math.sin(angle)
        local point = vec3:new(x, y, boss_pos:z())
        point = utility.set_height_of_valid_position(point)
        table.insert(points, point)
    end
    return points
end

local function render_points(points)
    for i, point in ipairs(points) do
        graphics.circle_3d(point, 0.5, color_white(255), 2.0)
    end
end

local function find_safe_point(points, current_index, direction)
    local num_points = #points
    local next_index = current_index
    for _ = 1, num_points - 1 do
        next_index = (next_index - 1 + direction + num_points) % num_points + 1
        if not evade.is_dangerous_position(points[next_index]) then
            return next_index
        end
    end
    return nil  -- If no safe point is found
end

local function is_safe_path(start_pos, end_pos)
    return not evade.is_position_passing_dangerous_zone(end_pos, start_pos)
end

local function find_furthest_point(points, bad_actor_pos)
    local furthest_point = nil
    local max_distance = 0
    local player_pos = get_player_position()
    for _, point in ipairs(points) do
        local distance = utils.distance_to(point, bad_actor_pos)
        if distance > max_distance and not evade.is_dangerous_position(point) and is_safe_path(player_pos, point) then
            max_distance = distance
            furthest_point = point
        end
    end
    return furthest_point
end

local function find_bad_actors()
    local bad_actor_list = {}
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        for _, bad_actor_pattern in ipairs(BAD_ACTORS) do
            if name:match(bad_actor_pattern) then
                table.insert(bad_actor_list, actor)
                break
            end
        end
    end
    return bad_actor_list
end

local function use_movement_spell_to_target(target)
    local local_player = get_local_player()
    if not local_player then return false end

    local movement_spell_id = {
        288106, -- Sorcerer teleport
        358761, -- Rogue dash
        355606, -- Rogue shadow step
        337031  -- General Evade
    }

    for _, spell_id in ipairs(movement_spell_id) do
        if local_player:is_spell_ready(spell_id) then
            local success = cast_spell.position(spell_id, target, 3.0)
            if success then
                console.print("Successfully used movement spell to target.")
                return true
            end
        end
    end
    
    console.print("Failed to use movement spell.")
    return false
end

local current_point_index = 1
local movement_direction = 1

local rotation_points = {}
local is_boss_task_active = false

local task = {
    name = "Kill Boss",
    shouldExecute = function()
        if not utils.player_on_quest(enums.quests.pit_ongoing) then
            return false
        end

        local close_enemy = utils.get_closest_enemy()
        return close_enemy ~= nil and close_enemy:is_boss()
    end,
    Execute = function()
        is_boss_task_active = true
        tracker:set_boss_task_running(true)
        explorer:clear_path_and_target()
        explorer.enabled = false

        local boss = utils.get_closest_enemy()
        if not boss or not boss:is_boss() then 
            is_boss_task_active = false
            return false 
        end

        local boss_pos = boss:get_position()
        rotation_points = calculate_rotation_points(boss_pos)

        local player_pos = get_player_position()
        local current_point = rotation_points[current_point_index]

        -- Check for bad actors
        local bad_actors = find_bad_actors()
        for _, bad_actor in ipairs(bad_actors) do
            local furthest_point = find_furthest_point(rotation_points, bad_actor:get_position())
            if furthest_point then
                if not use_movement_spell_to_target(furthest_point) then
                    pathfinder.request_move(furthest_point)
                end
                return
            end
        end

        -- Normal rotation logic
        if utils.distance_to(player_pos, current_point) < 1 then
            local next_index = find_safe_point(rotation_points, current_point_index, movement_direction)
            
            if next_index then
                current_point_index = next_index
            else
                -- If no safe point is found, reverse direction
                movement_direction = -movement_direction
                next_index = find_safe_point(rotation_points, current_point_index, movement_direction)
                if next_index then
                    current_point_index = next_index
                else
                    -- If still no safe point, stay at the current point
                    console.print("No safe points found. Staying at current position.")
                end
            end
        end

        pathfinder.request_move(rotation_points[current_point_index])

        --is_boss_task_active = false
        --tracker:set_boss_task_running(false)
        --explorer:clear_path_and_target()
        --explorer.enabled = true

        --if not success then
        --    print("Error in Kill Boss task: " .. tostring(error))
        --end
    end
}

-- Add this at the end of the file
on_render(function()
    if is_boss_task_active then
        render_points(rotation_points)
    end
end)

return task