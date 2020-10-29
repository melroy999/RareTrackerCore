-- Redefine often used functions locally.
local UnitBuff = UnitBuff

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- Link drill codes to their respective entities.
local drill_announcing_rares = {
    ["CC88"] = 152113,
    ["JD41"] = 153200,
    ["CC73"] = 154739,
    ["TR35"] = 150342,
    ["JD99"] = 153205,
    ["CC61"] = 154701,
    ["TR28"] = 153206,
}

-- Certain npcs have yell emotes to announce their arrival.
local yell_announcing_rares = {
    [L[151934]] = 151934, -- "Arachnoid Harvester"
    [L[151625]] = 151623, -- "The Scrap King"
    [L[151940]] = 151940, -- "Uncle T'Rogg",
    [L[151308]] = 151308, -- "Boggac Skullbash"
    [L[153228]] = 153228, -- "Gear Checker Cogstar"
    [L[151124]] = 151124, -- "Mechagonian Nullifier"
    [L[151296]] = 151296, -- "OOX-Avenger/MG"
    [L[150937]] = 150937, -- "Seaspit"
    [L[152932]] = 153000, -- "Sparkqueen P'Emp, announced by Razak Ironsides"
}

-- Register the data for the target zone.
local rare_data = {
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {1462, 1522},
    ["zone_name"] = "Mechagon",
    ["plugin_name"] = "Mechagon",
    ["plugin_name_abbreviation"] = "Mechagon",
    ["entities"] = {
        --npc_id = {name, quest_id, coordinates}
        [151934] = {L[151934], 55512, {["x"] = 52.86, ["y"] = 40.94}}, -- "Arachnoid Harvester"
        [154342] = {L[154342], 55512, {["x"] = 52.86, ["y"] = 40.94}}, -- "Arachnoid Harvester (F)"
        -- [155060] = {L[155060], 56419, {["x"] = 80.96, ["y"] = 20.19}}, -- "Doppel Ganger"
        [152113] = {L[152113], 55858, {["x"] = 68.40, ["y"] = 48.14}}, -- "The Kleptoboss"
        [154225] = {L[154225], 56182, {["x"] = 57.34, ["y"] = 58.30}}, -- "The Rusty Prince (F)"
        [151623] = {L[151623], 55364, {["x"] = 72.13, ["y"] = 50.00}}, -- "The Scrap King (M)"
        [151625] = {L[151625], 55364, {["x"] = 72.13, ["y"] = 50.00}}, -- "The Scrap King"
        [151940] = {L[151940], 55538, {["x"] = 58.13, ["y"] = 22.16}}, -- "Uncle T'Rogg"
        -- [150394] = {L[150394], 55546, {["x"] = 53.26, ["y"] = 50.08}}, -- "Armored Vaultbot"
        [153200] = {L[153200], 55857, {["x"] = 51.24, ["y"] = 50.21}}, -- "Boilburn"
        [151308] = {L[151308], 55539, {["x"] = 55.52, ["y"] = 25.37}}, -- "Boggac Skullbash"
        [152001] = {L[152001], 55537, {["x"] = 65.57, ["y"] = 24.18}}, -- "Bonepicker"
        [154739] = {L[154739], 56368, {["x"] = 31.27, ["y"] = 86.14}}, -- "Caustic Mechaslime"
        [149847] = {L[149847], 55812, {["x"] = 82.53, ["y"] = 20.78}}, -- "Crazed Trogg (Orange)"
        [152569] = {L[152569], 55812, {["x"] = 82.53, ["y"] = 20.78}}, -- "Crazed Trogg (Green)"
        [152570] = {L[152570], 55812, {["x"] = 82.53, ["y"] = 20.78}}, -- "Crazed Trogg (Blue)"
        [151569] = {L[151569], 55514, {["x"] = 35.03, ["y"] = 42.53}}, -- "Deepwater Maw"
        [150342] = {L[150342], 55814, {["x"] = 63.24, ["y"] = 25.43}}, -- "Earthbreaker Gulroc"
        [154153] = {L[154153], 56207, {["x"] = 55.34, ["y"] = 55.16}}, -- "Enforcer KX-T57"
        [151202] = {L[151202], 55513, {["x"] = 65.69, ["y"] = 51.85}}, -- "Foul Manifestation"
        [135497] = {L[135497], 55367, nil}, -- "Fungarian Furor"
        [153228] = {L[153228], 55852, nil}, -- "Gear Checker Cogstar"
        [153205] = {L[153205], 55855, {["x"] = 59.58, ["y"] = 67.34}}, -- "Gemicide"
        [154701] = {L[154701], 56367, {["x"] = 77.97, ["y"] = 50.28}}, -- "Gorged Gear-Cruncher"
        [151684] = {L[151684], 55399, {["x"] = 77.23, ["y"] = 44.74}}, -- "Jawbreaker"
        [152007] = {L[152007], 55369, nil}, -- "Killsaw"
        [151933] = {L[151933], 55544, {["x"] = 60.68, ["y"] = 42.11}}, -- "Malfunctioning Beastbot"
        [151124] = {L[151124], 55207, {["x"] = 57.16, ["y"] = 52.57}}, -- "Mechagonian Nullifier"
        [151672] = {L[151672], 55386, {["x"] = 87.98, ["y"] = 20.81}}, -- "Mecharantula"
        [8821909] = {L[8821909], 55386, {["x"] = 87.98, ["y"] = 20.81}}, -- "Mecharantula"
        [151627] = {L[151627], 55859, {["x"] = 61.03, ["y"] = 60.97}}, -- "Mr. Fixthis"
        [151296] = {L[151296], 55515, {["x"] = 57.16, ["y"] = 39.46}}, -- "OOX-Avenger/MG"
        [153206] = {L[153206], 55853, {["x"] = 56.21, ["y"] = 36.25}}, -- "Ol' Big Tusk"
        [152764] = {L[152764], 55856, {["x"] = 55.77, ["y"] = 60.05}}, -- "Oxidized Leachbeast"
        [151702] = {L[151702], 55405, {["x"] = 22.67, ["y"] = 68.75}}, -- "Paol Pondwader"
        [150575] = {L[150575], 55368, {["x"] = 39.49, ["y"] = 53.46}}, -- "Rumblerocks"
        [152182] = {L[152182], 55811, {["x"] = 66.04, ["y"] = 79.20}}, -- "Rustfeather"
        [155583] = {L[155583], 56737, {["x"] = 82.46, ["y"] = 77.55}}, -- "Scrapclaw"
        [150937] = {L[150937], 55545, {["x"] = 19.39, ["y"] = 80.33}}, -- "Seaspit"
        [153000] = {L[153000], 55810, {["x"] = 81.64, ["y"] = 22.13}}, -- "Sparkqueen P'Emp"
        [153226] = {L[153226], 55854, {["x"] = 25.61, ["y"] = 77.30}}, -- "Steel Singer Freza"
    },
    ["NPCIdRedirection"] = function(npc_id)
        -- Check whether the entity is Mecharantula.
        if npc_id == 151672 then
            -- Check if the player has the time displacement buff.
            for i=1,40 do
                local spell_id = select(10, UnitBuff("player", i))
                if spell_id == nil then
                    break
                elseif spell_id == 296644 then
                    -- Change the NPC id to a bogus id.
                    npc_id = 8821909
                    break
                end
            end
        end
        return npc_id
    end,
    ["FindMatchForText"] = function(self, text)
        -- Check if any of the drill rig designations is contained in the broadcast text.
        for designation, npc_id in pairs(drill_announcing_rares) do
            if text:find(designation) then
                self:ProcessEntityAlive(npc_id, npc_id, nil, nil, false)
                return
            end
        end
    end,
    ["FindMatchForName"] = function(self, name)
        local npc_id = yell_announcing_rares[name]
        if npc_id then
            self:ProcessEntityAlive(npc_id, npc_id, nil, nil, false)
        end
    end
}
RareTracker.RegisterRaresForZone(rare_data)