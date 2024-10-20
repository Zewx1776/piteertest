local settings = require "core.settings"
local explorer = require "core.explorer"
local task_manager = {}
local tasks = {}
local current_task = nil
local finished_time = 0

function task_manager.set_finished_time(time)
    finished_time = time
end

function task_manager.get_finished_time()
    return finished_time
end

function task_manager.register_task(task)
    table.insert(tasks, task)
end

local last_call_time = 0.0
function task_manager.execute_tasks()
    local current_core_time = get_time_since_inject()
    if current_core_time - last_call_time < 0.2 then
        return -- quick ej slide frames
    end

    last_call_time = current_core_time

    local is_exit_or_finish_active = false
    for _, task in ipairs(tasks) do
        if task.shouldExecute() then
            current_task = task
            if task.name == "Exit Pit" or task.name == "Finish Pit" then
                is_exit_or_finish_active = true
            end
            task.Execute()
            break -- Execute only one task per pulse
        end
    end

    -- Set the flag in the explorer module
    explorer.is_task_running = is_exit_or_finish_active

    if not current_task then
        current_task = { name = "Idle" } -- Default state when no task is active
    end
end

function task_manager.get_current_task()
    return current_task or { name = "Idle" }
end

-- Modify the task registration order
local task_files = {
    "enter_portal",
    "stupid_ladder",
    "kill_boss",
    "kill_monsters",
    "finish_pit",  -- Move finish_pit earlier in the list
    --"exit_pit",    -- Place exit_pit immediately after finish_pit
    "explore_pit",
    "town_salvage",
    "town_sell",
    "town_repaair",
    "open_pit"
}

for _, file in ipairs(task_files) do
    local task = require("tasks." .. file)
    task_manager.register_task(task)
end

-- If you still want to conditionally add exit_pit based on settings,
-- you can remove it from the task_files list above and keep this part:
local exit_pit_task = require("tasks.exit_pit")
if settings.exit_pit_enabled then
    task_manager.register_task(exit_pit_task)
end

return task_manager
