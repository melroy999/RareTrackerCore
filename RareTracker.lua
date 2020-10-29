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

-- Keep a list of modules that have been registered, such that we can add them when loaded.
local plugin_data = {}

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
            favorite_sound_alert = 552503,
        },
        window = {
            hide = false,
            scale = 1.0
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
-- ##                     Standard Ace3 Methods                      ##
-- ####################################################################

-- A function that is called when the addon is first loaded.
function RareTracker:OnInitialize()
    -- Register the addon's prefix and the associated communication function.
    RareTracker:RegisterComm("RareTracker")
    
    -- Add all the requested zones and rares.
    for primary_id, rare_data in pairs(plugin_data) do
        self:AddRaresForZone(rare_data)
        plugin_data[primary_id] = nil
    end
    
    -- Load the database.
    self.db = LibStub("AceDB-3.0"):New("RareTrackerDB2", defaults, true)
    self:InitializeRareTrackerLDB()
    self:InitializeOptionsMenu()

    -- Register the callback to the logout function.
    self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
    
    -- As a precaution, we remove all actively tracked rares from the blacklist.
    for npc_id, _ in pairs(self.tracked_npc_ids) do
        self.db.global.banned_NPC_ids[npc_id] = nil
    end

    -- Remove any data in the previous records that have expired.
    for shard_id, _ in pairs(self.db.global.previous_records) do
        if GetServerTime() - self.db.global.previous_records[shard_id].time_stamp > 900 then
            self:Debug("Removing cached data for shard "..shard_id)
            self.db.global.previous_records[shard_id] = nil
        end
    end
    
    -- Initialize the interface.
    self:InitializeInterface()
    self:CorrectFavoriteMarks()
    self:AddDailyResetHandler()
    
    -- Register all the events that have to be tracked continuously.
    RareTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneTransition")
    RareTracker:RegisterEvent("PLAYER_ENTERING_WORLD", "OnZoneTransition")
    RareTracker:RegisterEvent("ZONE_CHANGED", "OnZoneTransition")
    
    -- Register the resired chat commands.
    RareTracker:RegisterChatCommand("rt2", "OnChatCommand")
    RareTracker:RegisterChatCommand("raretracker2", "OnChatCommand")
end

-- A function that is called whenever the addon is enabled by the user.
-- function RareTracker:OnEnable()
--
-- end

-- A function that is called whenever the addon is disabled by the user.
-- function RareTracker:OnDisable()
--
-- end

-- Called when the player logs out, such that we can save the current time table for later use.
function RareTracker:OnDatabaseShutdown()
    self:SaveRecordedData()
end

-- ####################################################################
-- ##                            Commands                            ##
-- ####################################################################

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
                print("<RT> The rare window cannot be shown, since the current zone is not covered by any of the zone modules.")
            end
        elseif cmd == "hide" then
            if zone_id and self.zone_id_to_primary_id[zone_id] then
                self.gui:Hide()
            end
            self.db.global.window.hide = true
        end
    end
end

-- ####################################################################
-- ##                      Module Registration                       ##
-- ####################################################################

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

-- Register a list of rare data that will be processed upon successful load.
function RareTracker.RegisterRaresForZone(rare_data)
    tinsert(plugin_data, rare_data)
end

-- Register a list of rare entities for a given zone id/zone ids.
function RareTracker:AddRaresForZone(rare_data)
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
    local ordering = {}
    for npc_id, _ in pairs(rare_data.entities) do
        table.insert(ordering, npc_id)
    end

    table.sort(ordering, function(a, b)
        return rare_data.entities[a].name < rare_data.entities[b].name
    end)
    self.primary_id_to_data[primary_id].ordering = ordering
end

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Get the current health of the entity, rounded down to an integer.
function RareTracker.GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
    -- Return the amount of health as a percentage.
	return math.floor((100 * UnitHealth("target")) / UnitHealthMax("target"))
end

-- A function that enables the delayed execution of a function.
function RareTracker.DelayedExecution(delay, _function)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame.start_time = GetTime()
	frame:SetScript("OnUpdate",
		function(self)
			if GetTime() - self.start_time > delay then
				_function()
				self:SetScript("OnUpdate", nil)
				self:Hide()
                self:SetParent(nil)
			end
		end
	)
	frame:Show()
end

-- A print function used for debug purposes.
function RareTracker:Debug(...)
	if self.db.global.debug.enable then
		print("[Debug.RT]", ...)
	end
end