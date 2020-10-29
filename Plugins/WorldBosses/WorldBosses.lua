-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

RareTracker.RegisterRaresForZone({
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {379},
    ["zone_name"] = "Kun-Lai Summit",
    ["plugin_name"] = "World Bosses",
    ["plugin_name_abbreviation"] = "WorldBosses",
    ["entities"] = {
        --npc_id = {name, quest_id, coordinates}
        [60491] = {L[60491], 32099, nil}, -- "Sha of Anger"
    }
})

RareTracker.RegisterRaresForZone({
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {376},
    ["zone_name"] = "Valley of the Four Winds",
    ["plugin_name"] = "World Bosses",
    ["plugin_name_abbreviation"] = "WorldBosses",
    ["entities"] = {
        --npc_id = {name, quest_id, coordinates}
        [62346] = {L[62346], 32098, nil}, -- "Galleon"
    }
})

RareTracker.RegisterRaresForZone({
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {504},
    ["zone_name"] = "Isle of Thunder",
    ["plugin_name"] = "World Bosses",
    ["plugin_name_abbreviation"] = "WorldBosses",
    ["entities"] = {
        --npc_id = {name, quest_id, coordinates}
        [69099] = {L[69099], 32518, nil}, -- "Nalak"
    }
})

RareTracker.RegisterRaresForZone({
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {507},
    ["zone_name"] = "Isle of Giants",
    ["plugin_name"] = "World Bosses",
    ["plugin_name_abbreviation"] = "WorldBosses",
    ["entities"] = {
        --npc_id = {name, quest_id, coordinates}
        [69161] = {L[69161], 32519, nil}, -- "Oondasta"
    }
})

RareTracker.RegisterRaresForZone({
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {542},
    ["zone_name"] = "Spires of Arak",
    ["plugin_name"] = "World Bosses",
    ["plugin_name_abbreviation"] = "WorldBosses",
    ["entities"] = {
        --npc_id = {name, quest_id, coordinates}
        [87493] = {L[87493], 37474, nil}, -- "Rukhmar"
    }
})