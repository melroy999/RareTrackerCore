-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- Register the data for the target zone.
local rare_data = {
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {1355},
    ["zone_name"] = "Nazjatar",
    ["rares"] = {
        [152415] = L[152415], -- "Alga the Eyeless"
        [152416] = L[152416], -- "Allseer Oma'kil"
        [152794] = L[152794], -- "Amethyst Spireshell"
        [152566] = L[152566], -- "Anemonar"
        [150191] = L[150191], -- "Avarius"
        [152361] = L[152361], -- "Banescale the Packfather"
        [152712] = L[152712], -- "Blindlight"
        [149653] = L[149653], -- "Carnivorous Lasher"
        [152464] = L[152464], -- "Caverndark Terror"
        [152556] = L[152556], -- "Chasm-Haunter"
        [152756] = L[152756], -- "Daggertooth Terror"
        [152291] = L[152291], -- "Deepglider"
        [152414] = L[152414], -- "Elder Unu"
        [152555] = L[152555], -- "Elderspawn Nalaada"
        [65090] = L[65090], -- "Fabious"
        [152553] = L[152553], -- "Garnetscale"
        [152448] = L[152448], -- "Iridescent Glimmershell"
        [152567] = L[152567], -- "Kelpwillow"
        [152323] = L[152323], -- "King Gakula"
        [144644] = L[144644], -- "Mirecrawler"
        [152465] = L[152465], -- "Needlespine"
        [152397] = L[152397], -- "Oronu"
        [152681] = L[152681], -- "Prince Typhonus"
        [152682] = L[152682], -- "Prince Vortran"
        [150583] = L[150583], -- "Rockweed Shambler"
        [151870] = L[151870], -- "Sandcastle"
        [152795] = L[152795], -- "Sandclaw Stoneshell"
        [152548] = L[152548], -- "Scale Matriarch Gratinax"
        [152545] = L[152545], -- "Scale Matriarch Vynara"
        [152542] = L[152542], -- "Scale Matriarch Zodia"
        [152552] = L[152552], -- "Shassera"
        [153658] = L[153658], -- "Shiz'narasz the Consumer"
        [152359] = L[152359], -- "Siltstalker the Packmother"
        [152290] = L[152290], -- "Soundless"
        [153898] = L[153898], -- "Tidelord Aquatus"
        [153928] = L[153928], -- "Tidelord Dispersius"
        [154148] = L[152290], -- "Tidemistress Leth'sindra"
        [152360] = L[152360], -- "Toxigore the Alpha"
        [152568] = L[152568], -- "Urduu"
        [151719] = L[151719], -- "Voice in the Deeps"
        [150468] = L[150468], -- "Vor'koth"
    }
}
RareTracker:RegisterRaresForZone(rare_data)