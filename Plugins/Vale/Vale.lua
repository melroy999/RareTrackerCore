-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- Group rares by the assaults they are active in.
-- Notes: used the values found in the HandyNotes_VisionsOfNZoth addon.
local assault_rare_ids = {
    [3155826] = { -- West (MAN)
        160825, 160878, 160893, 160872, 160874, 160876, 160810, 160868, 160826, 160930, 160920, 160867, 160922, 157468, 160906
    }, [3155832] = { -- Mid (MOG)
        157466, 157183, 157287, 157153, 157171, 157160, 160968, 157290, 157162, 156083, 157291, 157279, 155958, 154600, 157468, 157443, 160906
    }, [3155841] = { -- East (EMP)
        154447, 154467, 154559, 157267, 157266, 154106, 154490, 157176, 157468, 154394, 154332, 154495, 154087, 159087, 160906
    }
}

-- Register the data for the target zone.
local rare_data = {
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {1530, 1579},
    ["zone_name"] = "Vale of Eternal Blossoms",
    ["plugin_name"] = "Vale of Eternal Blossoms",
    ["plugin_name_abbreviation"] = "Vale",
    ["SelectTargetEntities"] = function(self, target_npc_ids)
        local map_texture = C_MapExplorationInfo.GetExploredMapTextures(1530)
        if map_texture then
            local assault_id = map_texture[1].fileDataIDs[1]
            for _, npc_id in pairs(assault_rare_ids[assault_id]) do
                target_npc_ids[npc_id] = true
            end
        else
            for npc_id, _ in pairs(self.primary_id_to_data[1530].entities) do
                target_npc_ids[npc_id] = true
            end
        end
    end,
    ["entities"] = { 
        --npc_id = {name, quest_id, coordinates}
        [160825] = {L[160825], 58300, {["x"] = 20, ["y"] = 75}}, -- "Amber-Shaper Esh'ri"
        [157466] = {L[157466], 57363, {["x"] = 34, ["y"] = 68}}, -- "Anh-De the Loyal"
        [154447] = {L[154447], 56237, {["x"] = 57, ["y"] = 41}}, -- "Brother Meller"
        [160878] = {L[160878], 58307, {["x"] = 6, ["y"] = 70}}, -- "Buh'gzaki the Blasphemous"
        [160893] = {L[160893], 58308, {["x"] = 6, ["y"] = 64}}, -- "Captain Vor'lek"
        [154467] = {L[154467], 56255, {["x"] = 81, ["y"] = 65}}, -- "Chief Mek-mek"
        [157183] = {L[157183], 58296, {["x"] = 19, ["y"] = 68}}, -- "Coagulated Anima"
        [159087] = {L[159087], 57834, nil}, -- "Corrupted Bonestripper"
        [154559] = {L[154559], 56323, {["x"] = 67, ["y"] = 68}}, -- "Deeplord Zrihj"
        [160872] = {L[160872], 58304, {["x"] = 27, ["y"] = 67}}, -- "Destroyer Krox'tazar"
        [157287] = {L[157287], 57349, {["x"] = 42, ["y"] = 57}}, -- "Dokani Obliterator"
        [160874] = {L[160874], 58305, {["x"] = 12, ["y"] = 41}}, -- "Drone Keeper Ak'thet"
        [160876] = {L[160876], 58306, {["x"] = 10, ["y"] = 41}}, -- "Enraged Amber Elemental"
        [157267] = {L[157267], 57343, {["x"] = 45, ["y"] = 45}}, -- "Escaped Mutation"
        [157153] = {L[157153], 57344, {["x"] = 30, ["y"] = 38}}, -- "Ha-Li"
        [160810] = {L[160810], 58299, {["x"] = 29, ["y"] = 53}}, -- "Harbinger Il'koxik"
        [160868] = {L[160868], 58303, {["x"] = 13, ["y"] = 51}}, -- "Harrier Nir'verash"
        [157171] = {L[157171], 57347, {["x"] = 28, ["y"] = 40}}, -- "Heixi the Stonelord"
        [160826] = {L[160826], 58301, {["x"] = 20, ["y"] = 61}}, -- "Hive-Guard Naz'ruzek"
        [157160] = {L[157160], 57345, {["x"] = 12, ["y"] = 31}}, -- "Houndlord Ren"
        [160930] = {L[160930], 58312, {["x"] = 18, ["y"] = 66}}, -- "Infused Amber Ooze"
        [160968] = {L[160968], 58295, {["x"] = 17, ["y"] = 12}}, -- "Jade Colossus"
        [157290] = {L[157290], 57350, {["x"] = 27, ["y"] = 11}}, -- "Jade Watcher"
        [160920] = {L[160920], 58310, {["x"] = 18, ["y"] = 9}}, -- "Kal'tik the Blight"
        [157266] = {L[157266], 57341, {["x"] = 46, ["y"] = 59}}, -- "Kilxl the Gaping Maw"
        [160867] = {L[160867], 58302, {["x"] = 26, ["y"] = 38}}, -- "Kzit'kovok"
        [160922] = {L[160922], 58311, {["x"] = 15, ["y"] = 37}}, -- "Needler Zhesalla"
        [154106] = {L[154106], 56094, {["x"] = 90, ["y"] = 46}}, -- "Quid"
        [157162] = {L[157162], 57346, {["x"] = 22, ["y"] = 12}}, -- "Rei Lun"
        [154490] = {L[154490], 56302, {["x"] = 64, ["y"] = 52}}, -- "Rijz'x the Devourer"
        [156083] = {L[156083], 56954, {["x"] = 46, ["y"] = 57}}, -- "Sanguifang"
        [160906] = {L[160906], 58309, {["x"] = 27, ["y"] = 43}}, -- "Skiver"
        [157291] = {L[157291], 57351, {["x"] = 18, ["y"] = 38}}, -- "Spymaster Hul'ach"
        [157279] = {L[157279], 57348, {["x"] = 26, ["y"] = 75}}, -- "Stormhowl"
        [155958] = {L[155958], 58507, {["x"] = 29, ["y"] = 22}}, -- "Tashara"
        [154600] = {L[154600], 56332, {["x"] = 47, ["y"] = 64}}, -- "Teng the Awakened"
        [157176] = {L[157176], 57342, {["x"] = 52, ["y"] = 42}}, -- "The Forgotten"
        [157468] = {L[157468], 57364, {["x"] = 10, ["y"] = 67}}, -- "Tisiphon"
        [154394] = {L[154394], 56213, {["x"] = 87, ["y"] = 42}}, -- "Veskan the Fallen"
        [154332] = {L[154332], 56183, {["x"] = 67, ["y"] = 28}}, -- "Voidtender Malketh"
        [154495] = {L[154495], 56303, {["x"] = 53, ["y"] = 62}}, -- "Will of N'Zoth"
        [157443] = {L[157443], 57358, {["x"] = 54, ["y"] = 49}}, -- "Xiln the Mountain"
        [154087] = {L[154087], 56084, {["x"] = 71, ["y"] = 41}}, -- "Zror'um the Infinite"
    }
}
RareTracker:RegisterRaresForZone(rare_data)