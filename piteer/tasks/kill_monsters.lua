local utils      = require "core.utils"
local enums      = require "data.enums"
local settings   = require "core.settings"
local navigation = require "core.navigation"
local explorer   = require "core.explorer"

local current_elite_target = nil

local task = {
    name = "Kill Monsters",
    shouldExecute = function()
        --console.print("Checking if the task 'Kill Monsters' should be executed.")
        if not utils.player_on_quest(enums.quests.pit_ongoing) then
            return false
        end

        if current_elite_target and not current_elite_target:is_dead() then
            return true
        end

        local close_enemy = utils.get_closest_enemy()
        if close_enemy and (close_enemy:is_elite() or close_enemy:is_champion() or close_enemy:is_boss()) then
            current_elite_target = close_enemy
            return true
        end

        return close_enemy ~= nil
    end,
    Execute = function()
        --console.print("Executing the task: Kill Monsters.")
        local distance_check = settings.melee_logic and 2 or 6.5
        local enemy = current_elite_target or utils.get_closest_enemy()
        if not enemy then
            --console.print("No enemy found.")
            return false
        end

        if current_elite_target and current_elite_target:is_dead() then
            --console.print("Current elite target is dead. Clearing target.")
            current_elite_target = nil
            return true  -- End this execution to re-evaluate targets
        end

        local within_distance = utils.distance_to(enemy) < distance_check

        if not within_distance then
            --console.print("Enemy is not within distance. Moving to target.")
            local player_pos = get_player_position()
            local enemy_pos = enemy:get_position()

            explorer:clear_path_and_target()
            explorer:set_custom_target(enemy_pos)
            explorer:move_to_target()
        else
            if settings.melee_logic then
                --console.print("Enemy is within melee distance. Moving to melee position.")
                local player_pos = get_player_position()
                local enemy_pos = enemy:get_position()

                explorer:clear_path_and_target()
                explorer:set_custom_target(enemy_pos:get_extended(player_pos, -1.0))
                explorer:move_to_target()
            else
                --console.print("Enemy is within range distance. No action required for ranged attack.")
                -- do nothing for now due to being ranged
            end
        end
    end
}

return task
