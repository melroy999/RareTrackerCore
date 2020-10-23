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

-- ####################################################################
-- ##                     Standard Ace3 Methods                      ##
-- ####################################################################

-- A function that is called when the addon is first loaded.
function RareTracker:OnInitialize()
    -- Register the addon's prefix and the associated communication function.
    RareTracker:RegisterComm("RareTracker")
end

-- A function that is called whenever the addon is enabled by the user.
function RareTracker:OnEnable()
    
end

-- A function that is called whenever the addon is disabled by the user.
function RareTracker:OnDisable()
    
end

-- Called when the player logs out, such that we can save the current time table for later use.
function RareTracker:OnDatabaseShutdown()
    
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

RareTracker.rare_data = {
    -- Define the zone(s) in which the rares are present.
    ["target_zones"] = {1355},
    ["zone_name"] = "Nazjatar",
    ["rare_ids"] = {0, 1, 2, 3, 4}
}

-- Register a list of rare entities for a given zone id/zone ids.
function RareTracker:RegisterRaresForZone(rare_data)
    -- Only define the data for the zone once by making a pointer to the primary id.
    for _, value in pairs(rare_data.target_zones) do
        self.zone_id_to_primary_id[value] = rare_data.target_zones[1]
    end
end

RareTracker:RegisterRaresForZone(RareTracker.rare_data)

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
	if true then
	-- if self.db.global.debug.enable then
		print("[Debug]", ...)
	end
end