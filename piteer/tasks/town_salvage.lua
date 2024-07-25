local utils = require "core.utils"
local enums = require "data.enums"

local task  = {
    name = "Town Salvage",
    shouldExecute = function()
        --console.print("Checking if the task 'Town Salvage' should be executed.")
        return utils.player_in_zone("Scos_Cerrigar") and get_local_player():get_item_count() >= 20
    end,
    Execute = function()
        console.print("Executing the task: Town Salvage.")
        auto_play.repair_routine = function()
            console.print("Setting auto_play.repair_routine to an empty function.")
        end
    end
}

return task
