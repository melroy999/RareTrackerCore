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
            enable = true,
        },
        favorite_alert = {
            favorite_sound_alert = 552503,
        },
        window = {
            hide = false,
        },
        window_scale = 1.0,
        favorite_rares = {},
        previous_records = {},
        ignore_rares = {},
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
    
    -- Load the database.
    self.db = LibStub("AceDB-3.0"):New("RareTrackerDB2", defaults, true)

    -- Register the callback to the logout function.
    self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
    
    -- Add all the requested zones and rares.
    for key, rare_data in pairs(plugin_data) do
        self:AddRaresForZone(rare_data)
        plugin_data[key] = nil
    end
end

-- A function that is called whenever the addon is enabled by the user.
function RareTracker:OnEnable()
    
end

-- A function that is called whenever the addon is disabled by the user.
function RareTracker:OnDisable()
    
end

-- Called when the player logs out, such that we can save the current time table for later use.
function RareTracker:OnDatabaseShutdown()
    self:SaveRecordedData()
end

-- ####################################################################
-- ##                            Commands                            ##
-- ####################################################################

-- Register the resired chat commands.
RareTracker:RegisterChatCommand("rt2", "OnChatCommand")
RareTracker:RegisterChatCommand("raretracker2", "OnChatCommand")

function RareTracker:OnChatCommand(input)

end

-- ####################################################################
-- ##                      Module Registration                       ##
-- ####################################################################

-- Register a list of rare data that will be processed upon successful load.
function RareTracker:RegisterRaresForZone(rare_data)
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
    
    -- Create a table for favorite and ignored rares for the zone, if they don't exist yet.
    if not self.db.global.favorite_rares[primary_id] then
        self.db.global.favorite_rares[primary_id] = {}
    end
    if not self.db.global.ignore_rares[primary_id] then
        self.db.global.ignore_rares[primary_id] = {}
    end
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