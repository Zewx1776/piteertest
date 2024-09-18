local tracker = {
    finished_time = 0,
    pit_start_time = 0,
    boss_task_running = false,  -- Renamed field
}

-- Add these functions to manage the flag
function tracker:set_boss_task_running(value)
    self.boss_task_running = value
end

function tracker:is_boss_task_running()
    return self.boss_task_running
end

return tracker
