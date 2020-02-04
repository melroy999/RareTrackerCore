-- Redefine often used functions locally.
local LibStub = LibStub
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local print = print

-- Redefine often used variables locally.
local math = math

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

-- Create the primary addon object.
RT = LibStub("AceAddon-3.0"):NewAddon("RareTrackerCore", "AceConsole-3.0", "AceEvent-3.0")

-- Create a list of pointers to each of the zone modules.
RT.zone_modules = {}

-- Create a mapping from zone id to module.
RT.zone_id_to_module = {}

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
		print("[Debug]", ...)
	end
end
