-- The default locale, which is in the English language.
local L = LibStub("AceLocale-3.0"):NewLocale("RareTracker", "enUS", true, true)
if not L then return end

-- Status messages.
L["<RT> The rare window cannot be shown, since the current zone is not covered by any of the zone modules."] = "<RTC> The rare window cannot be shown, since the current zone is not covered by any of the zone modules."
L["<RT> Your version of the RareTracker addon is outdated. Please update to the most recent version at the earliest convenience."] = "<RTC> Your version of the RareTracker addon is outdated. Please update to the most recent version at the earliest convenience."
L["<RT> Resetting current rare timers and requesting up-to-date data."] = "<RTC> Resetting current rare timers and requesting up-to-date data."
L["<RT> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."] = "<RTC> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."
L["<RT> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."] = "<RTC> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."
L["<RT> Moving to shard "] = "<RTC> Moving to shard "

-- Chat messages.
L["<RT> %s has died"] = "<RTC> %s has died"
L["<RT> %s (%s%%)"] = "<RTC> %s (%s%%)"
L["<RT> %s (%s%%) seen at %s"] = "<RTC> %s (%s%%) seen at %s"
L["<RT> %s was last seen ~%s minutes ago"] = "<RTC> %s was last seen ~%s minutes ago"
L["<RT> %s seen alive, vignette at %s"] = "<RTC> %s seen alive, vignette at %s"
L["<RT> %s seen alive (combat log)"] = "<RTC> %s seen alive (combat log)"

-- Rare frame instructions.
L["Click on the squares to add rares to your favorites."] = "Click on the squares to add rares to your favorites."
L["Click on the squares to announce rare timers."] = "Click on the squares to announce rare timers."
L["Left click: report to general chat"] = "Left click: report to general chat"
L["Control-left click: report to party/raid chat"] = "Control-left click: report to party/raid chat"
L["Alt-left click: report to say"] = "Alt-left click: report to say"
L["Right click: set waypoint if available"] = "Right click: set waypoint if available"
L["Reset your data and replace it with the data of others."] = "Reset your data and replace it with the data of others."
L["Note: you do not need to press this button to receive new timers."] = "Note: you do not need to press this button to receive new timers."

-- Addon icon instructions.
L["Left-click: hide/show RT"] = "Left-click: hide/show RTC"
L["Right-click: show options"] = "Right-click: show options"

-- Option menu strings.
L["Favorite sound alert"] = "Favorite sound alert"
L["Show/hide the RT minimap icon."] = "Show/hide the RTC minimap icon."
L["Enable communication over party/raid channel"] = "Enable communication over party/raid channel"
L["Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."] = "Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."
L["Enable debug mode"] = "Enable debug mode"
L["Show RT debug output in the chat."] = "Show RTC debug output in the chat."
L["Rare window scale"] = "Rare window scale"
L["Set the scale of the rare window."] = "Set the scale of the rare window."
L["Disable All"] = "Disable All"
L["Disable all non-favorite rares in the list."] = "Disable all non-favorite rares in the list."
L["Enable All"] = "Enable All"
L["Enable all rares in the list."] = "Enable all rares in the list."
L["Reset Favorites"] = "Reset Favorites"
L["Reset the list of favorite rares."] = "Reset the list of favorite rares."
L["Active Rares"] = "Active Rares"
L["Show minimap icon"] = "Show minimap icon"
L["Shared Options"] = "Shared Options"
L["General"] = "General"
L["Display and report the death timers with seconds included"] = "Display and report the death timers with seconds included"
L["Display and report the death timers in the format \"mm:ss\", instead of just minutes."] = "Display and report the death timers in the format \"mm:ss\", instead of just minutes."

-- Rare frame strings.
L["Shard ID: %s"] = "Shard ID: %s"
L["Unknown"] = "Unknown"