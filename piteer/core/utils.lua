local settings = require "core.settings"
local enums    = require "data.enums"
local utils    = {}

function utils.distance_to(target)
    local player_pos = get_player_position()
    local target_pos

    if target.get_position then
        target_pos = target:get_position()
    elseif target.x then
        target_pos = target
    end

    return player_pos:dist_to(target_pos)
end

function addUber(actorAddress, uberData)
    if not settings.found_ubers[actorAddress] then
        settings.found_ubers[actorAddress] = uberData
    end
end

---@param identifier string|number string or number of the aura to check for
---@param count? number stacks of the buff to require (optional)
function utils.player_has_aura(identifier, count)
    local buffs = get_local_player():get_buffs()
    local found = 0

    for _, buff in pairs(buffs) do
        if (type(identifier) == "string" and buff:name() == identifier) or
            (type(identifier) == "number" and buff.name_hash == identifier) then
            found = found + 1
            if not count or found >= count then
                return true
            end
        end
    end

    return false
end

---Returns wether the player is on the quest provided or not
---@param quest_id integer
---@return boolean
function utils.player_on_quest(quest_id)
    local quests = get_quests()
    for _, quest in pairs(quests) do
        if quest:get_id() == quest_id then
            return true
        end
    end

    return false
end

---Returns wether the player is in the zone name specified
---@param zname string
function utils.player_in_zone(zname)
    return get_current_world():get_current_zone_name() == zname
end

---@return game.object|nil
function utils.get_closest_enemy()
    local elite_only = settings.elites_only
    local player_pos = get_player_position()
    local enemies = target_selector.get_near_target_list(player_pos, 90)
    local closest_elite, closest_normal
    local min_elite_dist, min_normal_dist = math.huge, math.huge

    for _, enemy in pairs(enemies) do
        local dist = player_pos:dist_to(enemy:get_position())
        local is_elite = enemy:is_elite() or enemy:is_champion() or enemy:is_boss()

        if is_elite then
            if dist < min_elite_dist then
                closest_elite = enemy
                min_elite_dist = dist
            end
        elseif not elite_only then
            if dist < min_normal_dist then
                closest_normal = enemy
                min_normal_dist = dist
            end
        end
    end

    return closest_elite or (not elite_only and closest_normal) or nil
end

function utils.get_pit_portal()
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == enums.portal_names.demise or name == enums.portal_names.guardians_lair or name == enums.portal_names.pit_portal then
            return actor
        end
    end
end

local uber_table = { -- Should be all uber items :)
    { name = "Tyrael's Might", sno = 1901484 },
    { name = "The Grandfather", sno = 223271 },
    { name = "Andariel's Visage", sno = 241930 },
    { name = "Ahavarion, Spear of Lycander", sno = 359165 },
    { name = "Doombringer", sno = 221017 },
    { name = "Harlequin Crest", sno = 609820 },
    { name = "Melted Heart of Selig", sno = 1275935 },
    { name = "‍Ring of Starless Skies", sno = 1306338 }
}

function utils.is_uber_item(sno_to_check)
    for _, entry in pairs(uber_table) do
        if entry.sno == sno_to_check then
            return true
        end
    end
    return false
end


function utils.get_obelisk()
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == enums.misc.obelisk then
            return actor
        end
    end
end

function utils.loot_on_floor()
    return loot_manager.any_item_around(get_player_position(), 30, true, true)
end

function utils.get_start_location_0()
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == enums.misc.start_location then
            return actor
        end
    end
    --console.print("No start location found")
    return nil
end

function utils.get_blacksmith()
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == enums.misc.blacksmith then
            console.print("blacksmith location found: " .. name)
            return actor
        end
    end
    --console.print("No start location found")
    return nil
end

function utils.get_jeweler()
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == enums.misc.jeweler then
            local position = actor:get_position()
            console.print(string.format("Jeweler location found: %s at position: (x: %f, y: %f, z: %f)", name, position:x(), position:y(), position:z()))
            return actor
        end
    end
    --console.print("No start location found")
    return nil
end

function utils.get_greater_affix_count(display_name)
    local count = 0
    for _ in display_name:gmatch("GreaterAffix") do
       count = count + 1
    end
    return count
end

function utils.loot_on_floor()
    local items = loot_manager.get_all_items_chest_sort_by_distance()
    if #items > 0 then
        for _, item in pairs(items) do
            local item_data = item:get_item_info()
            if item_data then
                if settings.only_uber then
                    if utils.is_uber_item(item_data:get_sno_id()) then
                        if loot_manager.is_lootable_item(item, true, false) and item_data:get_rarity() > 4 then
                            return true
                        end
                    end
                else
                    if loot_manager.is_lootable_item(item, true, false) and item_data:get_rarity() > 4 then
                        return true
                    end
                end
              
            end
        end
    end
end


function utils.get_town_portal()
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == enums.misc.portal then
           return actor
        end
    end
end


function utils.is_inventory_full()
    return get_local_player():get_item_count() >= 28
end


function utils.get_object_by_name(object_name)
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == object_name then
            return actor
        end
    end
    return nil
end

return utils
