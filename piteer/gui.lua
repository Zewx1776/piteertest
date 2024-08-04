local gui = {}
local plugin_label = "piteer v2"

local function create_checkbox(key)
    return checkbox:new(false, get_hash(plugin_label .. "_" .. key))
end

gui.loot_modes_options = {
    "Nothing",  -- will get stuck
    "Sell",     -- will sell all and keep going
    "Salvage",  -- will salvage all and keep going
    "Stash",    -- nothing for now, will get stuck, but in future can be added
}

gui.loot_modes_enum = {
    NOTHING = 0,
    SELL = 1,
    SALVAGE = 2,
    STASH = 3,
}

gui.elements = {
    main_tree = tree_node:new(0),
    main_toggle = create_checkbox("main_toggle"),
    settings_tree = tree_node:new(1),
    melee_logic = create_checkbox("melee_logic"),
    elite_only_toggle = create_checkbox("elite_only"),
    pit_level = input_text:new(get_hash("piteer_pit_level_unique_id")),
    pit_level_slider = slider_int:new(1, 190, 1, 1984),
    loot_toggle = create_checkbox("loot_toggle"),
    loot_modes = combo_box:new(0, get_hash("piteer_loot_modes")),
    path_angle_slider = slider_int:new(0, 360, 10, get_hash("path_angle_slider")), -- 10 is a default value
    reset_time_slider = slider_int:new(60, 900, 60, get_hash("reset_time_slider")), -- New slider for reset time in seconds
}

function gui.render()
    if not gui.elements.main_tree:push("Piteer V2") then return end

    gui.elements.main_toggle:render("Enable", "Enable the bot")
    
    if gui.elements.settings_tree:push("Settings") then
        gui.elements.melee_logic:render("Melee", "Do we need to move into Melee?")
        gui.elements.elite_only_toggle:render("Elite Only", "Do we only want to seek out elites in the Pit?")
        gui.elements.pit_level_slider:render("Pit Level", "Which Pit level do you want to enter?")
        --gui.elements.pit_level:render("Level", "Which level do you want to enter?", false, "", "")
        gui.elements.loot_toggle:render("Enable Looting", "Toggle looting on/off")        
        gui.elements.loot_modes:render("Loot Modes", gui.loot_modes_options, "Nothing and Stash will get you stuck for now")
        gui.elements.path_angle_slider:render("Path Angle", "Adjust the angle for path filtering (0-360 degrees)")
        gui.elements.reset_time_slider:render("Reset Time (seconds)", "Set the time in seconds for resetting all dungeons") -- Render the new slider
        gui.elements.settings_tree:pop()
    end

    gui.elements.main_tree:pop()
end

return gui
