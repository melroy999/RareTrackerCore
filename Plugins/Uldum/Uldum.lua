-- Redefine often used variables locally.
local C_MapExplorationInfo = C_MapExplorationInfo

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- Rare ids that have loot, which will be used as a default fallback option if no assault is active (introduction not done).
local rare_ids_with_loot = {
    157593, -- "Amalgamation of Flesh"
    162147, -- "Malevolent Drone"
    158633, -- "Gaze of N'Zoth"
    157134, -- "Ishak of the Four Winds"
    154604, -- "Lord Aj'qirai"
    157146, -- "Rotfeaster"
    162140, -- "Skikx'traz"
    158636, -- "The Grand Executor"
    157473, -- "Yiphrim the Will Ravager"
}

-- Group rares by the assaults they are active in.
-- Notes: used the values found in the HandyNotes_VisionsOfNZoth addon.
local assault_rare_ids = {
    [3165083] = { -- West (AQR)
        155703, 154578, 154576, 162172, 162370, 162171, 162147, 162163, 155531, 157134, 154604, 156078, 162196, 162142, 156299,
        162173, 160532, 162140, 162372, 162352, 151878, 162170, 162141, 157472, 158531, 152431, 157470, 157390, 157476, 158595,
        157473, 157469
    },
    [3165092] = { -- South (EMP)
        158557, 155703, 154578, 154576, 162172, 158594, 158491, 158633, 158597, 158528, 160623, 155531, 157134, 156655, 162196,
        156299, 161033, 156654, 160532, 151878, 158636, 157472, 158531, 152431, 157470, 157390, 157476, 158595, 157473, 157469
    },
    [3165098] = { -- East (AMA)
        157170, 151883, 155703, 154578, 154576, 162172, 152757, 157120, 151995, 155531, 157134, 157157, 152677, 162196, 157146,
        152040, 151948, 162372, 162352, 151878, 151897, 151609, 152657, 151852, 157164, 162141, 157167, 157593, 157188, 152788,
        157472, 158531, 152431, 157470, 157390, 157476, 158595, 157473, 157469
    }
}

-- Register the data for the target zone.
local rare_data = {
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {1527},
    ["zone_name"] = "Uldum",
    ["plugin_name"] = "Uldum",
    ["plugin_name_abbreviation"] = "Uldum",
    ["SelectTargetEntities"] = function(self, target_npc_ids)
        local map_texture = C_MapExplorationInfo.GetExploredMapTextures(1527)
        if map_texture then
            local assault_id = map_texture[1].fileDataIDs[1]
            for _, npc_id in pairs(assault_rare_ids[assault_id]) do
                target_npc_ids[npc_id] = true
            end
        else
            if self.db.global.uldum and self.db.global.uldum.enable_rare_filter then
                for _, npc_id in pairs(rare_ids_with_loot) do
                    target_npc_ids[npc_id] = true
                end
            else
                for npc_id, _ in pairs(self.primary_id_to_data[1527].entities) do
                    target_npc_ids[npc_id] = true
                end
            end
        end
    end,
    ["GetOptionsTable"] = function(self) return {
            ["filter_list"] = {
                type = "toggle",
                name = L["Enable filter fallback"],
                desc = L["Show only rares that drop special loot (mounts/pets/toys)"..
                    " when no assault data is available."],
                width = "full",
                order = self:GetOrder(),
                get = function()
                    if not self.db.global.uldum then
                        self.db.global.uldum = {}
                        self.db.global.uldum.enable_rare_filter = true
                    end
                    return self.db.global.uldum.enable_rare_filter
                end,
                set = function(_, val)
                    self.db.global.uldum.enable_rare_filter = val
                    self:UpdateDisplayList()
                end
            }
        }
    end,
    ["entities"] = {
        --npc_id = {name, quest_id, coordinates}
        [157170] = {L[157170], 57281, {["x"] = 64, ["y"] = 26}}, -- "Acolyte Taspu"
        [158557] = {L[158557], 57669, {["x"] = 66.77, ["y"] = 74.33}}, -- "Actiss the Deceiver"
        [157593] = {L[157593], 57667, {["x"] = 70, ["y"] = 50}}, -- "Amalgamation of Flesh"
        [151883] = {L[151883], 55468, {["x"] = 69, ["y"] = 49}}, -- "Anaua"
        [155703] = {L[155703], 56834, {["x"] = 32, ["y"] = 64}}, -- "Anq'uri the Titanic"
        [157472] = {L[157472], 57437, {["x"] = 50, ["y"] = 79}}, -- "Aphrom the Guise of Madness"
        [154578] = {L[154578], 58612, {["x"] = 39, ["y"] = 25}}, -- "Aqir Flayer"
        [154576] = {L[154576], 58614, {["x"] = 31, ["y"] = 57}}, -- "Aqir Titanus"
        [162172] = {L[162172], 58694, {["x"] = 38, ["y"] = 45}}, -- "Aqir Warcaster"
        [162370] = {L[162370], 58718, {["x"] = 44, ["y"] = 42}}, -- "Armagedillo"
        [152757] = {L[152757], 55710, {["x"] = 65.3, ["y"] = 51.6}}, -- "Atekhramun"
        [162171] = {L[162171], 58699, {["x"] = 45, ["y"] = 57}}, -- "Captain Dunewalker"
        [157167] = {L[157167], 57280, {["x"] = 75, ["y"] = 52}}, -- "Champion Sen-mat"
        [162147] = {L[162147], 58696, {["x"] = 30, ["y"] = 49}}, -- "Corpse Eater"
        [158531] = {L[158531], 57665, {["x"] = 50, ["y"] = 79}}, -- "Corrupted Neferset Guard"
        [158594] = {L[158594], 57672, {["x"] = 49, ["y"] = 38}}, -- "Doomsayer Vathiris"
        [158491] = {L[158491], 57662, {["x"] = 48, ["y"] = 70}}, -- "Falconer Amenophis"
        [157120] = {L[157120], 57258, {["x"] = 75, ["y"] = 68}}, -- "Fangtaker Orsa"
        [158633] = {L[158633], 57680, {["x"] = 55, ["y"] = 53}}, -- "Gaze of N'Zoth"
        [158597] = {L[158597], 57675, {["x"] = 54, ["y"] = 43}}, -- "High Executor Yothrim"
        [158528] = {L[158528], 57664, {["x"] = 53.68, ["y"] = 79.33}}, -- "High Guard Reshef"
        [162163] = {L[162163], 58701, {["x"] = 42, ["y"] = 58}}, -- "High Priest Ytaessis"
        [151995] = {L[151995], 55502, {["x"] = 80, ["y"] = 47}}, -- "Hik-Ten the Taskmaster"
        [160623] = {L[160623], 58206, {["x"] = 60, ["y"] = 39}}, -- "Hungering Miasma"
        [152431] = {L[152431], 55629, {["x"] = 77, ["y"] = 52}}, -- "Kaneb-ti"
        [155531] = {L[155531], 56823, {["x"] = 19, ["y"] = 58}}, -- "Infested Wastewander Captain"
        [157134] = {L[157134], 57259, {["x"] = 73, ["y"] = 83}}, -- "Ishak of the Four Winds"
        [156655] = {L[156655], 57433, {["x"] = 71, ["y"] = 73}}, -- "Korzaran the Slaughterer"
        [154604] = {L[154604], 56340, {["x"] = 34, ["y"] = 18}}, -- "Lord Aj'qirai"
        [156078] = {L[156078], 56952, {["x"] = 30, ["y"] = 66}}, -- "Magus Rehleth"
        [157157] = {L[157157], 57277, {["x"] = 66, ["y"] = 20}}, -- "Muminah the Incandescent"
        [152677] = {L[152677], 55684, {["x"] = 61, ["y"] = 24}}, -- "Nebet the Ascended"
        [162196] = {L[162196], 58681, {["x"] = 35, ["y"] = 17}}, -- "Obsidian Annihilator"
        [162142] = {L[162142], 58693, {["x"] = 37, ["y"] = 59}}, -- "Qho"
        [157470] = {L[157470], 57436, {["x"] = 51, ["y"] = 88}}, -- "R'aas the Anima Devourer"
        [156299] = {L[156299], 57430, {["x"] = 58, ["y"] = 57}}, -- "R'khuzj the Unfathomable"
        [162173] = {L[162173], 58864, {["x"] = 28, ["y"] = 13}}, -- "R'krox the Runt"
        [157390] = {L[157390], 57434, nil}, -- "R'oyolok the Reality Eater"
        [157146] = {L[157146], 57273, {["x"] = 69, ["y"] = 32}}, -- "Rotfeaster"
        [152040] = {L[152040], 55518, {["x"] = 70, ["y"] = 42}}, -- "Scoutmaster Moswen"
        [151948] = {L[151948], 55496, {["x"] = 74, ["y"] = 65}}, -- "Senbu the Pridefather"
        [161033] = {L[161033], 58333, {["x"] = 57, ["y"] = 38}}, -- "Shadowmaw"
        [156654] = {L[156654], 57432, {["x"] = 59, ["y"] = 83}}, -- "Shol'thoss the Doomspeaker"
        [160532] = {L[160532], 58169, {["x"] = 61, ["y"] = 75}}, -- "Shoth the Darkened"
        [157476] = {L[157476], 57439, {["x"] = 55, ["y"] = 80}}, -- "Shugshul the Flesh Gorger"
        [162140] = {L[162140], 58697, {["x"] = 21, ["y"] = 61}}, -- "Skikx'traz"
        [162372] = {L[162372], 58715, {["x"] = 67, ["y"] = 68}}, -- "Spirit of Cyrus the Black"
        [162352] = {L[162352], 58716, {["x"] = 52, ["y"] = 40}}, -- "Spirit of Dark Ritualist Zakahn"
        [151878] = {L[151878], 58613, {["x"] = 79, ["y"] = 64}}, -- "Sun King Nahkotep"
        [151897] = {L[151897], 55479, {["x"] = 85, ["y"] = 57}}, -- "Sun Priestess Nubitt"
        [151609] = {L[151609], 55353, {["x"] = 73, ["y"] = 74}}, -- "Sun Prophet Epaphos"
        [152657] = {L[152657], 55682, {["x"] = 66, ["y"] = 35}}, -- "Tat the Bonechewer"
        [158636] = {L[158636], 57688, {["x"] = 49, ["y"] = 82}}, -- "The Grand Executor"
        [157188] = {L[157188], 57285, {["x"] = 84, ["y"] = 47}}, -- "The Tomb Widow"
        [158595] = {L[158595], 57673, {["x"] = 65, ["y"] = 72}}, -- "Thoughtstealer Vos"
        [152788] = {L[152788], 55716, {["x"] = 68, ["y"] = 64}}, -- "Uat-ka the Sun's Wrath"
        [162170] = {L[162170], 58702, {["x"] = 34, ["y"] = 26}}, -- "Warcaster Xeshro"
        [151852] = {L[151852], 55461, {["x"] = 80, ["y"] = 52}}, -- "Watcher Rehu"
        [157473] = {L[157473], 57438, nil}, -- "Yiphrim the Will Ravager"
        [157164] = {L[157164], 57279, {["x"] = 80, ["y"] = 57}}, -- "Zealot Tekem"
        [157469] = {L[157469], 57435, nil}, -- "Zoth'rum the Intellect Pillager"
        [162141] = {L[162141], 58695, {["x"] = 40, ["y"] = 41}}, -- "Zuythiz"
    }
}
RareTracker.RegisterRaresForZone(rare_data)