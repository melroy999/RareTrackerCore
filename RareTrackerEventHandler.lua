-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                          Event Variables                       ##
-- ####################################################################

-- The last zone id that was encountered.
RareTracker.last_zone_id = nil

-- A flag used to detect guardians or pets.
RareTracker.pet_mask = bit.bor(
    COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_OBJECT
)

-- ####################################################################
-- ##                           Event Handlers                       ##
-- ####################################################################

-- Called whenever the user changes to a new zone or area.
function RareTracker:OnZoneTransition()
    -- The zone the player is in.
    local zone_id = C_Map.GetBestMapForUnit("player")
    
    -- Check if the zone id changed. If so, update the list of rares to display when appropriate.
    if self.zone_id_to_primary_id[zone_id] and self.zone_id_to_primary_id[zone_id] ~= self.zone_id_to_primary_id[self.last_zone_id] then
        self:ChangeZone(zone_id)
    end
    
    -- Show/hide the interface when appropriate.
    if self.zone_id_to_primary_id[zone_id] and not self.zone_id_to_primary_id[self.last_zone_id] then
        self:OpenWindow()
        self:RegisterTrackingEvents()
    elseif not self.zone_id_to_primary_id[zone_id] and self.zone_id_to_primary_id[self.last_zone_id] then
        self:CloseWindow()
        self:UnregisterTrackingEvents()
    end

    -- Update the zone id.
    self.last_zone_id = zone_id
end

-- Fetch the new list of rares and ensure that these rares are properly displayed.
function RareTracker:ChangeZone(zone_id)
    -- TODO
    print("Changing zone to", zone_id)
end

-- This event is fired whenever the player's target is changed, including when the target is lost. 
function RareTracker:PLAYER_TARGET_CHANGED()

end

-- Fired whenever a unit's health is affected. 
function RareTracker:UNIT_HEALTH(unit)
    
end

-- Fires for combat events such as a player casting a spell or an NPC taking damage.
function RareTracker:COMBAT_LOG_EVENT_UNFILTERED()

end

-- Fired whenever a vignette appears or disappears in the minimap.
function RareTracker:VIGNETTE_MINIMAP_UPDATED(vignetteGUID, _)
    
end

-- Fires when an NPC yells, such as a raid boss or in Alterac Valley.
function RareTracker:CHAT_MSG_MONSTER_YELL(...)
    
end

-- ####################################################################
-- ##                   Event Handler Helper Functions               ##
-- ####################################################################

-- Register the events that are needed for the proper tracking of rares.
function RareTracker:RegisterTrackingEvents()
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

-- Unregister all events that aren't necessary when outside of tracking zones.
function RareTracker:UnregisterTrackingEvents()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("UNIT_HEALTH")
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
    self:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
end

-- ####################################################################
-- ##                   Event Handling Initialization                ##
-- ####################################################################
    
-- Register all the events that have to be tracked continuously.
RareTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneTransition")
RareTracker:RegisterEvent("PLAYER_ENTERING_WORLD", "OnZoneTransition")
RareTracker:RegisterEvent("ZONE_CHANGED", "OnZoneTransition")