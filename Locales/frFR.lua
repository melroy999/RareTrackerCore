-- The French locale.
local L = LibStub("AceLocale-3.0"):NewLocale("RareTracker", "frFR")
if not L then return end

-- Status messages.
-- L["<RT> The rare window cannot be shown, since the current zone is not covered by any of the zone modules."] = ""
-- L["<RT> Your version of the %s addon is outdated. Please update to the most recent version at the earliest convenience."] = ""
L["<RT> Resetting current rare timers and requesting up-to-date data."] = "<RT> Remise-à-zéro des timers actuels et requête de données à jour."
L["<RT> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."] = "<RT> Veuillez sélectionner une entité non joueuse avant la remise-à-zéro, afin de permettre à l'addon de déterminer le shard id actuel."
L["<RT> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."] = "<RT> Le bouton de remise-à-zéro est en recharge. Il est à noté qu'un reset n'est pas nécessaire pour recevoir les nouveaux timers. Si vous voulez effectivement réinitialiser les dnnées, veuillez faire un /reload puis cliquer à nouveau sur le bouton de reset."

-- Chat messages.
L["<RT> %s has died"] = "<RT> %s est mort."
L["<RT> %s (%s%%)"] = "<RT> %s (%s%%)"
L["<RT> %s (%s%%) seen at ~(%.2f, %.2f)"] = "<RT> %s (%s%%) vu à ~(%.2f, %.2f)"
L["<RT> %s was last seen ~%s minutes ago"] = "<RT> %s vu pour la dernière fois il y a ~%s minutes"
L["<RT> %s seen alive, vignette at ~(%.2f, %.2f)"] = "<RT> %s vu en vie à la position ~(%.2f, %.2f)"
L["<RT> %s seen alive (combat log)"] = "<RT> %s vu en vie (log de combat)"

-- Rare frame instructions.
L["Click on the squares to add rares to your favorites."] = "Cliquer sur les carrés pour ajouter des rares à vos favoris."
L["Click on the squares to announce rare timers."] = "Cliquer sur les carrés pour annoncer les timers."
L["Left click: report to general chat"] = "Clique gauche : annoncer sur le canal général."
L["Control-left click: report to party/raid chat"] = "Control-clique gauche : annoncer au groupe/raid."
L["Alt-left click: report to say"] = "Alt-clique gauche : annoncer en /dire"
L["Right click: set waypoint if available"] = "Clique droit : placer un waypoint si possible."
L["Reset your data and replace it with the data of others."] = "Réinitialiser vos données et les remplace avec celles des autres."
L["Note: you do not need to press this button to receive new timers."] = "Note : vous n'avez pas besoin d'utiliser ce bouton pour recevoir les nouveaux timers."

-- Addon icon instructions.
L["Left-click: hide/show RT"] = "Clique-gauche : montrer ou masquer RT"
L["Right-click: show options"] = "Clique-droit : afficher les options."

-- Option menu strings.
L["Favorite sound alert"] = "Son d'alerte favori."
-- L["Show/hide the RT minimap icon."] = ""
-- L["Enable communication over party/raid channel"] = ""
-- L["Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."] = ""
L["Enable debug mode"] = "Activer le mode debug."
-- L["Show RT debug output in the chat."] = ""
L["Rare window scale"] = "Échelle de la fenêtre de rare"
-- L["Set the scale of the rare window."] = ""
L["Disable All"] = "Désactiver tous"
-- L["Disable all non-favorite rares in the list."] = ""
L["Enable All"] = "Activer tous"
-- L["Enable all rares in the list."] = ""
L["Reset Favorites"] = "Ré-initialiser les favoris"
-- L["Reset the list of favorite rares."] = ""
-- L["Active Rares"] = ""
L["Show minimap icon"] = "Afficher l'icone de la minimap."
-- L["Shared Options"] = ""
-- L["General"] = ""

-- Rare frame strings.
L["Shard ID: %s"] = "Shard ID: %s"
L["Unknown"] = "Inconnu"