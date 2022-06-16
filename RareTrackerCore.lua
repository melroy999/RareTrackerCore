-- Redefine often used functions locally.
local GetServerTime = GetServerTime
local InterfaceOptionsFrame_Show = InterfaceOptionsFrame_Show
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local tinsert = tinsert
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local CreateFrame = CreateFrame
local GetTime = GetTime

-- Redefine global variables locally.
local C_Map = C_Map
local UIParent = UIParent

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

-- Create the primary addon object.
RareTracker = LibStub("AceAddon-3.0"):NewAddon("RareTracker", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")

-- Create the frame, such that the position will be saved correctly.
RareTracker.gui = CreateFrame("Frame", "RT", UIParent)

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                           Variables                            ##
-- ####################################################################

-- Create a mapping from the zone id to the primary zone id.
RareTracker.zone_id_to_primary_id = {}

-- Create a mapping from primary id to zone data.
RareTracker.primary_id_to_data = {}

-- A master list of all tracked rares.
RareTracker.tracked_npc_ids = {}

-- A master list of all tracked rares.
RareTracker.completion_quest_to_npc_ids = {}

-- The short-hand code of the addon.
RareTracker.addon_code = "RT"

-- Define the default settings.
local defaults = {
    global = {
        communication = {
            raid_communication = true,
        },
        debug = {
            enable = false,
        },
        favorite_alert = {
            favorite_alert_sound_channel = "SFX",
            favorite_sound_alert = 552503,
        },
        window = {
            hide = false,
            scale = 1.0,
            hide_killed_entities = false,
            force_display_in_english = false,
            show_time_in_seconds = false,
        },
        previous_records = {},
        favorite_rares = {},
        ignored_rares = {},
        banned_NPC_ids = {},
        version = 0,
    },
    profile = {
        minimap = {
            hide = false,
        },
    },
}

-- ####################################################################
-- ##                  Module Registration Variables                 ##
-- ####################################################################

-- Keep a list of modules that have been registered, such that we can add them when loaded.
local plugin_data = {}

-- A metatable that simplifies accessing rare data.
local rare_data_metatable = {
    __index = function(t, k)
        if k == "name" then
            return t[1]
        elseif k == "quest_id" then
            return t[2]
        elseif k == "coordinates" then
            return t[3]
        else
            return nil
        end
    end
}

-- ####################################################################
-- ##                  Module Registration Messages                  ##
-- ####################################################################

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
local banned_NPC_ids = {
    154297, 150202, 154304, 152108, 151300, 151310, 142666, 142668, 69792, 62821, 62822, 32639, 32638, 89715, 89713, 180182, 180181, 180483, 180208, 183143
}

-- Fired when new all rare tracker modules have registered their data to the core.
function RareTracker:PLAYER_LOGIN()
    -- We no longer need the player login event. Unsubscribe.
    self:UnregisterEvent("PLAYER_LOGIN")
    
    -- Add all the requested zones and rares.
    for primary_id, rare_data in pairs(plugin_data) do
        self:AddRaresForModule(rare_data)
        plugin_data[primary_id] = nil
    end

    -- As a precaution, we remove all actively tracked rares from the blacklist.
    for npc_id, _ in pairs(self.tracked_npc_ids) do
        self.db.global.banned_NPC_ids[npc_id] = nil
    end
    
    -- There are several npcs that always have to be banned.
    for _, npc_id in pairs(banned_NPC_ids) do
        self.db.global.banned_NPC_ids[npc_id] = true
    end
    
    -- Import previous settings when applicable.
    self:ImportOldSettings()

    self:InitializeOptionsMenu()
    self:InitializeRareTrackerLDB()
    
    -- Register the resired chat commands.
    self:RegisterChatCommand("rtc", "OnChatCommand")
    self:RegisterChatCommand("raretracker", "OnChatCommand")
    
    -- Initialize the interface.
    self:InitializeInterface()
    self:CorrectFavoriteMarks()
    self:AddDailyResetHandler()
    
    -- Register all the events that have to be tracked continuously.
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneTransition")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnZoneTransition")
    self:RegisterEvent("ZONE_CHANGED", "OnZoneTransition")
end

-- ####################################################################
-- ##                 Module Registration Functions                  ##
-- ####################################################################

-- Register a list of rare data that will be processed upon successful load.
function RareTracker.RegisterRaresForModule(rare_data)
    tinsert(plugin_data, rare_data)
end

-- Register a list of rare entities for a given zone id/zone ids.
function RareTracker:AddRaresForModule(rare_data)
    local primary_id = rare_data.target_zones[1]
    
    -- Only define the data for the zone once by making a pointer to the primary id.
    for _, value in pairs(rare_data.target_zones) do
        self.zone_id_to_primary_id[value] = primary_id
    end
    
    -- Store the data.
    self.primary_id_to_data[primary_id] = rare_data
    for key, _ in pairs(rare_data.entities) do
        setmetatable(rare_data.entities[key], rare_data_metatable)
    end
    
    -- Construct the inverse quest id list.
    for key, value in pairs(rare_data.entities) do
        if value.quest_id then
            if not self.completion_quest_to_npc_ids[value.quest_id] then
                self.completion_quest_to_npc_ids[value.quest_id] = {}
            end
            tinsert(self.completion_quest_to_npc_ids[value.quest_id], key)
        end
    end
    
    -- Populate the master list of tracked npcs.
    for npc_id, _ in pairs(rare_data.entities) do
        self.tracked_npc_ids[npc_id] = true
    end
    
    -- Create an ordering (alphabetical is the default).
    -- If an order is defined by the module, use that order instead!
    if rare_data.rare_order then
        self.primary_id_to_data[primary_id].ordering = rare_data.rare_order
    else
        local ordering = {}
        for npc_id, _ in pairs(rare_data.entities) do
            table.insert(ordering, npc_id)
        end
        table.sort(ordering, function(a, b)
            return rare_data.entities[a].name < rare_data.entities[b].name
        end)
        self.primary_id_to_data[primary_id].ordering = ordering
    end
end

-- Extract all the re-usable data from the old databases and put them in the new one.
function RareTracker:ImportOldSettings()
    self:ImportOldSettingFromDB(RareTrackerNazjatarDB)
    self:ImportOldSettingFromDB(RareTrackerMechagonDB)
    self:ImportOldSettingFromDB(RareTrackerUldumDB)
    self:ImportOldSettingFromDB(RareTrackerValeDB)
end

-- Extract all the re-usable data from the old database and put them in the new one.
function RareTracker:ImportOldSettingFromDB(db)
    if db and not db.has_been_imported then
        if db.global.favorite_rares then
            for npc_id, _ in pairs(db.global.favorite_rares) do
                self.db.global.favorite_rares[npc_id] = true
            end
        end
        if db.global.ignore_rares then
            for npc_id, _ in pairs(db.global.ignore_rares) do
                self.db.global.ignored_rares[npc_id] = true
            end
        end
        db.has_been_imported = true
    end
end

-- ####################################################################
-- ##                     Standard Ace3 Methods                      ##
-- ####################################################################

-- A function that is called when the addon is first loaded.
-- Note: we have to delay the initialization until all the rare data has been gathered.
function RareTracker:OnInitialize()
    -- Register the addon's prefix and the associated communication function.
    self:RegisterComm(self.addon_code)
        
    -- Load the database.
    self.db = LibStub("AceDB-3.0"):New("RareTrackerDB", defaults, true)

    -- Register the callback to the logout function.
    self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
    
    -- Remove any data in the previous records that have expired.
    for shard_id, _ in pairs(self.db.global.previous_records) do
        if GetServerTime() - self.db.global.previous_records[shard_id].time_stamp > 900 then
            self:Debug("Removing cached data for shard "..shard_id)
            self.db.global.previous_records[shard_id] = nil
        end
    end
    
    -- Remove any data in the previous records that are outdated because of an addon update.
    for shard_id, _ in pairs(self.db.global.previous_records) do
        local version = self.db.global.previous_records[shard_id].version
        if not version or version < 1 then
            self:Debug("Removing cached data for shard "..shard_id)
            self.db.global.previous_records[shard_id] = nil
        end
    end
    
    -- Wait for the player login event before initializing the rest of the data.
    self:RegisterEvent("PLAYER_LOGIN")
end

-- Called when the player logs out, such that we can save the current time table for later use.
function RareTracker:OnDatabaseShutdown()
    self:SaveRecordedData()
end

-- ####################################################################
-- ##                            Commands                            ##
-- ####################################################################

-- Remember when the last refresh was issued by the user, to block refresh spamming.
RareTracker.last_data_refresh = 0

-- A function that is called when calling a chat command.
function RareTracker:OnChatCommand(input)
    input = input:trim()
    if not input or input == "" then
        InterfaceOptionsFrame_Show()
        InterfaceOptionsFrame_OpenToCategory(self.options_frame)
    else
        local _, _, cmd, _ = string.find(input, "%s?(%w+)%s?(.*)")
        local zone_id = C_Map.GetBestMapForUnit("player")
        if cmd == "show" then
            if zone_id and self.zone_id_to_primary_id[zone_id] then
                self.gui:Show()
                self.db.global.window.hide = false
            else
                print(L["<RT> The rare window cannot be shown, since the current zone is not covered by any of the zone modules."])
            end
        elseif cmd == "hide" then
            if zone_id and self.zone_id_to_primary_id[zone_id] then
                self.gui:Hide()
            end
            self.db.global.window.hide = true
        elseif cmd == "refresh" then
            if self.shard_id ~= nil and GetServerTime() - self.last_data_refresh > 600 then
                -- Reset all tracked data.
                self:ResetTrackedData()
                self.db.global.previous_records[self.shard_id] = nil

                -- Re-register the arrival.
                self.last_data_refresh = GetServerTime()
                self:AnnounceArrival()

                print(L["<RT> Resetting current rare timers and requesting up-to-date data."])
            elseif self.shard_id == nil then
                print(L["<RT> Please target a non-player entity prior to resetting, "..
                      "such that the addon can determine the current shard id."])
            else
                print(L["<RT> The reset button is on cooldown. Please note that a reset is not needed "..
                      "to receive new timers. If it is your intention to reset the data, "..
                      "please do a /reload and click the reset button again."])
            end
        end
    end
end

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Get the current health of the entity, rounded down to an integer.
function RareTracker.GetTargetHealthPercentage(target)
	-- Find the current and maximum health of the current target.
	local max_hp = UnitHealthMax(target)
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
    -- Return the amount of health as a percentage.
	return math.floor((100 * UnitHealth(target)) / UnitHealthMax(target))
end

-- A function that enables the delayed execution of a function.
function RareTracker:DelayedExecution(delay, _function)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame.start_time = GetTime()
	frame:SetScript("OnUpdate",
		function(f)
			if GetTime() - f.start_time > delay then
                if not pcall(_function) then
                    self:Debug("Delayed execution failed.")
                end
                
				f:SetScript("OnUpdate", nil)
				f:Hide()
                f:SetParent(nil)
			end
		end
	)
	frame:Show()
end

-- A print function used for debug purposes.
function RareTracker:Debug(...)
	if self.db and self.db.global.debug.enable then
		print("[Debug.RT]", ...)
	end
end