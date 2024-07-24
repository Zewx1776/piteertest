local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"

local task  = {
    name = "Explore Pit",
    shouldExecute = function()
        console.print("Checking if the task 'Explore Pit' should be executed.")
        return utils.player_on_quest(enums.quests.pit_ongoing) and not utils.get_closest_enemy()
    end,
    Execute = function()
        console.print("Executing the task: Explore Pit.")
        explorer.enabled = true
    end
}

return task
