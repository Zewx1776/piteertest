local tracker = {
    finished_time = 0,
    pit_start_time = 0,
    boss_task_running = false,  
    finished_time = 0,
    pit_start_time = 0,
    ga_chest_opened = false,
    selected_chest_opened = false,
    gold_chest_opened = false,
    finished_chest_looting = false,
    has_salvaged = false,
    exit_horde_start_time = 0,
    has_entered = false,
    start_dungeon_time = nil,
    horde_opened = false,
    first_run = false,
    exit_horde_completion_time = 0,
    exit_horde_completed = true,
    wave_start_time = 0,
    needs_salvage = false,
    victory_lap = false,
    victory_positions = nil,
    locked_door_found = false,
    boss_killed = false,
    teleported_from_town = false,
    start_time = 0
}

-- Add these functions to manage the flag
function tracker:set_boss_task_running(value)
    self.boss_task_running = value
end

function tracker:is_boss_task_running()
    return self.boss_task_running
end

function tracker.set_teleported_from_town(value)
    tracker.teleported_from_town = value
end

return tracker
