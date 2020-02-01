-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

RT = LibStub("AceAddon-3.0"):NewAddon("RareTracker", "AceConsole-3.0", "AceEvent-3.0")

-- local RT = CreateFrame("Frame", "RT", UIParent);

-- Create a list of pointers to each of the zone modules.
RT.zone_modules = {}

-- Create a mapping from zone id to module.
RT.zone_id_to_module = {}

-- The zone_uid can be used to distinguish different shards of the zone.
RT.current_shard_id = nil

-- The last zone the user was in.
RT.last_zone_id = nil

-- ####################################################################
-- ##                         Saved Variables                        ##
-- ####################################################################

-- Setting saved in the saved variables.
RTDB = {}

-- Remember whether the user wants to see the window or not.
RTDB.show_window = nil

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Get the current health of the entity, rounded down to an integer.
function RT.GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
	return math.floor((100 * UnitHealth("target")) / UnitHealthMax("target"))
end

-- A print function used for debug purposes.
function RT:Debug(...)
	if self.db.global.debug.enable then
		print(...)
	end
end
