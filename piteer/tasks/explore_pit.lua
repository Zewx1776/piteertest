local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"

local task  = {
    name = "Explore Pit",
    shouldExecute = function()
        return utils.player_on_quest(enums.quests.pit_ongoing) and 
               not utils.get_closest_enemy() and
               not explorer.is_task_running
    end,
    Execute = function()
        if not explorer.is_task_running then
            explorer.enabled = true
        end
    end
}
return task
