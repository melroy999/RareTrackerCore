-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- Register the data for the target zone.
local rare_data = {
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {1355},
    ["zone_name"] = "Nazjatar",
    ["entities"] = {
    --   npc_id = {name, quest_id, coordinates}
        [152415] = {L[152415], 56279, nil}, -- "Alga the Eyeless"
        [152416] = {L[152416], 56280, nil}, -- "Allseer Oma'kil"
        [152794] = {L[152794], 56268, nil}, -- "Amethyst Spireshell"
        [152566] = {L[152566], 56281, nil}, -- "Anemonar"
        [150191] = {L[150191], 55584, nil}, -- "Avarius"
        [152361] = {L[152361], 56282, nil}, -- "Banescale the Packfather"
        [152712] = {L[152712], 56269, nil}, -- "Blindlight"
        [149653] = {L[149653], 55366, nil}, -- "Carnivorous Lasher"
        [152464] = {L[152464], 56283, nil}, -- "Caverndark Terror"
        [152556] = {L[152556], 56270, nil}, -- "Chasm-Haunter"
        [152756] = {L[152756], 56271, nil}, -- "Daggertooth Terror"
        [152291] = {L[152291], 56272, nil}, -- "Deepglider"
        [152414] = {L[152414], 56284, nil}, -- "Elder Unu"
        [152555] = {L[152555], 56285, nil}, -- "Elderspawn Nalaada"
        [65090] = {L[65090] , nil, nil}, -- "Fabious"
        [152553] = {L[152553], 56273, nil}, -- "Garnetscale"
        [152448] = {L[152448], 56286, nil}, -- "Iridescent Glimmershell"
        [152567] = {L[152567], 56287, nil}, -- "Kelpwillow"
        [152323] = {L[152323], 55671, nil}, -- "King Gakula"
        [144644] = {L[144644], 56274, nil}, -- "Mirecrawler"
        [152465] = {L[152465], 56275, nil}, -- "Needlespine"
        [152397] = {L[152397], 56288, nil}, -- "Oronu"
        [152681] = {L[152681], 56289, nil}, -- "Prince Typhonus"
        [152682] = {L[152682], 56290, nil}, -- "Prince Vortran"
        [150583] = {L[150583], 56291, nil}, -- "Rockweed Shambler"
        [151870] = {L[151870], 56276, nil}, -- "Sandcastle"
        [152795] = {L[152795], 56277, nil}, -- "Sandclaw Stoneshell"
        [152548] = {L[152548], 56292, nil}, -- "Scale Matriarch Gratinax"
        [152545] = {L[152545], 56293, nil}, -- "Scale Matriarch Vynara"
        [152542] = {L[152542], 56294, nil}, -- "Scale Matriarch Zodia"
        [152552] = {L[152552], 56295, nil}, -- "Shassera"
        [153658] = {L[153658], 56296, nil}, -- "Shiz'narasz the Consumer"
        [152359] = {L[152359], 56297, nil}, -- "Siltstalker the Packmother"
        [152290] = {L[152290], 56298, nil}, -- "Soundless"
        [153898] = {L[153898], 56122, nil}, -- "Tidelord Aquatus"
        [153928] = {L[153928], 56123, nil}, -- "Tidelord Dispersius"
        [154148] = {L[152290], 56106, nil}, -- "Tidemistress Leth'sindra"
        [152360] = {L[152360], 56278, nil}, -- "Toxigore the Alpha"
        [152568] = {L[152568], 56299, nil}, -- "Urduu"
        [151719] = {L[151719], 56300, nil}, -- "Voice in the Deeps"
        [150468] = {L[150468], 55603, nil}, -- "Vor'koth"
    }
}
RareTracker:RegisterRaresForZone(rare_data)