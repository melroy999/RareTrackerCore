# RareTrackerCore (RT)

The **RareTrackerCore (RT)** addon is the central component of my collection of rare tracker addons, used to track and share rare spawn timers in popular zones. The addon takes inspiration from the [RareCoordinator](https://www.curseforge.com/wow/addons/rarecoordinator) addon authored by [elvador](https://www.curseforge.com/members/elvador/followers), which is an addon that has served a similar purpose on the Timeless Isle. RareTrackerCore uses a hidden chat channel to communicate with other clients located in the same shard, such that it can always provide the most up-to-date rare spawn timers.

## Available modules
- [RareTrackerMechagon (RTM)](https://www.curseforge.com/wow/addons/raretrackermechagon-rtm) for Mechagon
- [RareTrackerNazjatar (RTN)](https://www.curseforge.com/wow/addons/raretrackernazjatar-rtn) for Nazjatar
- [RareTrackerUldum (RTU)](https://www.curseforge.com/wow/addons/raretrackeruldum-rtu) for Uldum
- [RareTrackerVale (RTV)](https://www.curseforge.com/wow/addons/raretrackervale-rtv) for the Vale of Eternal Blossoms
- [RareTrackerWorldBosses (RTWB)](https://www.curseforge.com/wow/addons/raretrackerworldbosses-rtwb) for world bosses

## Instructions
RareTrackerCore relies on a peer to peer network and as such, it will only function optimally if multiple players are using the addon simultaneously. The communication component will activate once the the player has targeted a non-player entity, or when a combat log event nearby has been processed: this step is required, since it enables the addon to extract an unique identifier for the shard.

### Rare status frame
The status frame can be toggled on and off by pressing the minimap button. Alternatively, one can use the **/rt show** and **/rt hide** commands. The frame can be moved by dragging it to the desired position. The data in the status frame can be reset by pressing the refresh button located at the top right of the frame, which will repopulate the frame with the data of your peers. The options menu located in the interface options provides the option to ignore certain rares, such that they do not appear in your rare overview.

### Favorites
Rares can be marked as favorites by enabling their check marks, located in the first column of the displayed table. Entities that are marked as favorite are announced through an auditory warning. Additionally, the rares that are marked as favorites are saved globally for the entire account.

### Announcements
Rares can be announced by left-clicking the button in the second column of the frame: if the rare is alive, the health percentage and a set of coordinates will be written to general chat; otherwise, the addon will report the time that has passed since the rare has been seen last by one of the addon's users.

The user can also report to the party/raid chat by holding the control key in addition to left clicking on the announce button. Alternatively, a player can report to the say channel by holding the alt key while clicking the report button.

### Waypoints
Upon targeting a rare, the player's coordinates will be passed to all users, such that they can easily find rares that do not have a fixed spawn point. Right clicking the button in the second column of the frame automatically creates a waypoint for the rare, if available. Additionally, Waypoints are automatically removed upon the entity's death.

### Options Menu
The options menu can be opened by right clicking the minimap icon, or using the command /rt. In the option menu, the user can select the desired sound alert for the favorite warnings. Additionally, it provides options to hide the minimap, scale the window and disable the party/raid communication module. Moreover, it provides reset buttons for your favorites and the dynamically generated blacklist.

## Requested Features
- ~~Scrape general chat to receive more update timers for rares:~~ *will not be added unless I find a reliable way to avoid spoofing of messages.*
- ~~Automated announcements:~~ *this request will not be supported, since blizzard changed the API to block this type of behavior.*
- An overview showing the kill status of rares by alts: *little gain compared to a simple spreadsheet, but can be done if there is more demand for it.*


## Localization
I aim to provide localization for all languages, but I cannot do so alone--I would certainly appreciate help in making the appropriate translations! The following progress has been made so far:

- frFR: Partial localization has been provided by [xfluxlr8pj63](https://www.curseforge.com/members/xfluxlr8pj63/projects).
- zhCN: Partial localization has been provided by [cikichen](https://www.curseforge.com/members/cikichen/projects). The remaining localization strings have been provided by [adavak](https://github.com/adavak).
- ruRU: Localization has been provided by [dak1ne-4th](https://github.com/dak1ne-4th).

