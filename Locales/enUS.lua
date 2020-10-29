-- The default locale, which is in the English language.
local L = LibStub("AceLocale-3.0"):NewLocale("RareTracker", "enUS", true, true)
if not L then return end

-- Option menu strings.
L["Rare window scale"] = "Rare window scale"
L["Set the scale of the rare window."] = "Set the scale of the rare window."
L["Disable All"] = "Disable All"
L["Disable all non-favorite rares in the list."] = "Disable all non-favorite rares in the list."
L["Enable All"] = "Enable All"
L["Enable all rares in the list."] = "Enable all rares in the list."
L["Reset Favorites"] = "Reset Favorites"
L["Reset the list of favorite rares."] = "Reset the list of favorite rares."
L["General Options"] = "General Options"
L["Rare List Options"] = "Rare List Options"
L["Active Rares"] = "Active Rares"
L["Favorite sound alert"] = "Favorite sound alert"
L["Show minimap icon"] = "Show minimap icon"
L["Enable debug mode"] = "Enable debug mode"
L["Show RT debug output in the chat."] = "Show RT debug output in the chat."
L["Show/hide the RT minimap icon."] = "Show/hide the RT minimap icon."
L["Enable communication over party/raid channel"] = "Enable communication over party/raid channel"
L["Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."] = "Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."

-- Addon icon instructions.
L["Left-click: hide/show RT"] = "Left-click: hide/show RT"
L["Right-click: show options"] = "Right-click: show options"

-- Chat messages.
L["<RT> %s has died"] = "<RT> %s has died"
L["<RT> %s (%s%%)"] = "<RT> %s (%s%%)"
L["<RT> %s (%s%%) seen at ~(%.2f, %.2f)"] = "<RT> %s (%s%%) seen at ~(%.2f, %.2f)"
L["<RT> %s was last seen ~%s minutes ago"] = "<RT> %s was last seen ~%s minutes ago"
L["<RT> %s seen alive, vignette at ~(%.2f, %.2f)"] = "<RT> %s seen alive, vignette at ~(%.2f, %.2f)"
L["<RT> %s seen alive (combat log)"] = "<RT> %s seen alive (combat log)"

-- Rare frame instructions.
L["Click on the squares to add rares to your favorites."] = "Click on the squares to add rares to your favorites."
L["Click on the squares to announce rare timers."] = "Click on the squares to announce rare timers."
L["Left click: report to general chat"] = "Left click: report to general chat"
L["Control-left click: report to party/raid chat"] = "Control-left click: report to party/raid chat"
L["Alt-left click: report to say"] = "Alt-left click: report to say"
L["Right click: set waypoint if available"] = "Right click: set waypoint if available"
L["Reset your data and replace it with the data of others."] = "Reset your data and replace it with the data of others."
L["Note: you do not need to press this button to receive new timers."] = "Note: you do not need to press this button to receive new timers."

-- Rare frame strings.
L["Shard ID: %s"] = "Shard ID: %s"
L["Unknown"] = "Unknown"

-- Status messages.
L["<RT> Resetting current rare timers and requesting up-to-date data."] = "<RT> Resetting current rare timers and requesting up-to-date data."
L["<RT> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."] = "<RT> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."
L["<RT> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."] = "<RT> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."
L["<RT> Failed to register AddonPrefix '%s'. %s will not function properly."] = "<RT> Failed to register AddonPrefix '%s'. %s will not function properly."
L["<RT> Moving to shard "] = "<RT> Moving to shard "
L["<RT> Removing cached data for shard "] = "<RT> Removing cached data for shard "
L["<RT> Restoring data from previous session in shard "] = "<RT> Restoring data from previous session in shard "
L["<RT> Requesting rare kill data for shard "] = "<RT> Requesting rare kill data for shard "
L["<RT> Resetting ordering"] = "<RT> Resetting ordering"
L["<RT> Updating daily kill marks."] = "<RT> Updating daily kill marks."
L["<RT> Your version of the %s addon is outdated. Please update to the most recent version at the earliest convenience."] = "<RT> Your version of the %s addon is outdated. Please update to the most recent version at the earliest convenience."