-- Redefine often used functions locally.
local UnitGUID = UnitGUID
local strsplit = strsplit
local UnitHealth = UnitHealth
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local C_VignetteInfo = C_VignetteInfo
local GetServerTime = GetServerTime
local CreateFrame = CreateFrame
local GetChannelList = GetChannelList
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local PlaySoundFile = PlaySoundFile
local select = select
local date = date
local time = time

-- Redefine often used variables locally.
local C_Map = C_Map
local COMBATLOG_OBJECT_TYPE_GUARDIAN = COMBATLOG_OBJECT_TYPE_GUARDIAN
local COMBATLOG_OBJECT_TYPE_PET = COMBATLOG_OBJECT_TYPE_PET
local COMBATLOG_OBJECT_TYPE_OBJECT = COMBATLOG_OBJECT_TYPE_OBJECT
local bit = bit
local UIParent = UIParent

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                          Event Variables                       ##
-- ####################################################################

-- The last zone id that was encountered.
RareTracker.zone_id = nil

-- The current shard id.
RareTracker.shard_id = nil

-- A flag used to detect guardians or pets.
local companion_type_mask = bit.bor(
    COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_OBJECT
)

-- A flag that will notify whether the char frame has loaded successfully, to avoid overwriting the chat order.
local chat_frame_loaded = false

-- Track whether an entity is considered to be alive.
RareTracker.is_alive = {}

-- Track the current health of the entity.
RareTracker.current_health = {}

-- Track when the entity was last seen dead.
RareTracker.last_recorded_death = {}

-- Track the reported current coordinates of the rares.
RareTracker.current_coordinates = {}

-- Record all spawn uids that are detected, such that we don't report the same spawn multiple times.
RareTracker.reported_spawn_uids = {}

-- A list of waypoints.
RareTracker.waypoints = {}

-- Record all entities that died, such that we don't overwrite existing death.
local recorded_entity_death_ids = {}

-- Record all vignettes that are detected, such that we don't report the same spawn multiple times.
local reported_vignettes = {}

-- For some reason... the Sha of Anger is a... vehicle?
local valid_unit_types = {
    ["Creature"] = true,
    ["Vehicle"] = true
}

-- ####################################################################
-- ##                           Event Handlers                       ##
-- ####################################################################

-- Called whenever the user changes to a new zone or area.
function RareTracker:OnZoneTransition()
    -- The zone the player is in.
    local zone_id = C_Map.GetBestMapForUnit("player")
    
    -- Update the zone id and keep the last id.
    local last_zone_id = self.zone_id
    self.zone_id = self.zone_id_to_primary_id[zone_id]
    
    -- Check if the zone id changed. If so, update the list of rares to display when appropriate.
    if self.zone_id_to_primary_id[zone_id] and self.zone_id_to_primary_id[zone_id] ~= self.zone_id_to_primary_id[last_zone_id] then
        self:ChangeZone()
    end
    
    -- Show/hide the interface when appropriate.
    if self.zone_id_to_primary_id[zone_id] and not self.zone_id_to_primary_id[last_zone_id] then
        self:OpenWindow()
        self:RegisterTrackingEvents()
    elseif not self.zone_id_to_primary_id[zone_id] and self.zone_id_to_primary_id[last_zone_id] then
        self:CloseWindow()
        self:UnregisterTrackingEvents()
    end
end

-- Fetch the new list of rares and ensure that these rares are properly displayed.
function RareTracker:ChangeZone()
    -- Leave the channel associated with the current shard id and save the data.
    self.LeaveAllShardChannels()
    self:SaveRecordedData()
    
    -- Reset all tracked data.
    self:ResetTrackedData()
    
    -- Reset the shard id
    self:ChangeShard(nil)
    
    -- Ensure that the correct data is shown in the window.
    self:UpdateDisplayList()
    
    self:Debug("Changing zone to", self.zone_id)
end

-- Transfer to a new shard, reset current data and join the appropriate channel.
function RareTracker:ChangeShard(zone_uid)
    -- Leave the channel associated with the current shard id and save the data.
    self.LeaveAllShardChannels()
    self:SaveRecordedData()
    
    -- Reset all tracked data.
    self:ResetTrackedData()
    
    -- Set the new shard id.
    self.shard_id = zone_uid
    
    -- Update the shard number in the display.
    self:UpdateShardNumber()
    
    if self.shard_id then
        -- Change the shard id to the new shard and add the channel.
        self:LoadRecordedData()
        self:AnnounceArrival()
    end
end

-- Check whether the user has changed shards and proceed accordingly.
-- Return true if the shard changed, false otherwise.
function RareTracker:CheckForShardChange(zone_uid)
    if self.shard_id ~= zone_uid and zone_uid ~= nil then
        self:Debug("Moving to shard "..zone_uid)
        self:ChangeShard(zone_uid)
        return true
    end
    return false
end

-- Check whether the given npc id needs to be redirected under the current circumstances.
function RareTracker:CheckForRedirectedRareIds(npc_id)
    local NPCIdRedirection = self.primary_id_to_data[self.zone_id].NPCIdRedirection
    if NPCIdRedirection then
        return NPCIdRedirection(npc_id)
    end
    return npc_id
end

-- This event is fired whenever the player's target is changed, including when the target is lost.
function RareTracker:PLAYER_TARGET_CHANGED()
    -- Get information about the target.
    local guid = UnitGUID("target")
    
    if chat_frame_loaded and guid then
        -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
        local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", guid)
        npc_id = tonumber(npc_id)
        
        -- It might occur that the NPC id is nil. Do not proceed in such a case.
        if not npc_id then return end
        
        -- Certain entities retain their zone_uid even after moving shards. Ignore them.
        if not self.db.global.banned_NPC_ids[npc_id] then
            if self:CheckForShardChange(zone_uid) then
                self:Debug("[Target]", guid)
            end
        end
        
        --A special check for duplicate NPC ids in different environments (Mecharantula).
        npc_id = self:CheckForRedirectedRareIds(npc_id)
        
        if valid_unit_types[unittype] and self.primary_id_to_data[self.zone_id].entities[npc_id] then
            -- Find the health of the entity.
            local health = UnitHealth("target")
        
            if health > 0 then
                -- Get the current position of the player and the health of the entity.
                local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
                local x, y = math.floor(pos.x * 10000 + 0.5) / 100, math.floor(pos.y * 10000 + 0.5) / 100
                local percentage = self.GetTargetHealthPercentage()
                
                -- Mark the entity as alive and report to your peers.
                self:ProcessEntityTarget(npc_id, spawn_uid, percentage, x, y, true)
            else
                -- Mark the entity has dead and report to your peers.
                self:ProcessEntityDeath(npc_id, spawn_uid, true)
            end
        end
    end
end

-- Fired whenever a unit's health is affected.
function RareTracker:UNIT_HEALTH(_, unit)
    -- Get information about the target.
    local guid = UnitGUID("target")
    
    if chat_frame_loaded and unit == "target" and guid then
        -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
        local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", guid)
        npc_id = tonumber(npc_id)
    
        -- It might occur that the NPC id is nil. Do not proceed in such a case.
        if not npc_id then return end
        
        if not self.db.global.banned_NPC_ids[npc_id] then
            if self:CheckForShardChange(zone_uid) then
                self:Debug("[OnUnitHealth]", guid)
            end
        end
        
        --A special check for duplicate NPC ids in different environments (Mecharantula).
        npc_id = self:CheckForRedirectedRareIds(npc_id)
        
        if valid_unit_types[unittype] and self.primary_id_to_data[self.zone_id].entities[npc_id] then
            -- Update the current health of the entity.
            local percentage = self.GetTargetHealthPercentage()
            
            -- Does the entity have any health left?
            if percentage > 0 then
                -- Report the health of the entity to your peers.
                self:ProcessEntityHealth(npc_id, spawn_uid, percentage, true)
            else
                -- Mark the entity has dead and report to your peers.
                self:ProcessEntityDeath(npc_id, spawn_uid, true)
            end
        end
    end
end

-- Fires for combat events such as a player casting a spell or an NPC taking damage.
function RareTracker:COMBAT_LOG_EVENT_UNFILTERED()
    if chat_frame_loaded then
        -- The event does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
        -- timestamp, subevent, zero, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        -- destGUID, destName, destFlags, destRaidFlags
        local _, subevent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _ = CombatLogGetCurrentEventInfo()
        
        -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
        local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID)
        npc_id = tonumber(npc_id)
        
        -- It might occur that the NPC id is nil. Do not proceed in such a case.
        if not npc_id or not destFlags then return end
        
        -- Blacklist the entity.
        if not self.db.global.banned_NPC_ids[npc_id] and bit.band(destFlags, companion_type_mask) > 0 and not self.tracked_npc_ids[npc_id] then
            self.db.global.banned_NPC_ids[npc_id] = true
        end
        
        -- We can always check for a shard change.
        -- We only take fights between creatures, since they seem to be the only reliable option.
        -- We exclude all pets and guardians, since they might have retained their old shard change.
        if valid_unit_types[unittype] and not self.db.global.banned_NPC_ids[npc_id] and bit.band(destFlags, companion_type_mask) == 0 then
            if self:CheckForShardChange(zone_uid) then
                self:Debug("[OnCombatLogEvent]", sourceGUID, destGUID)
            end
        end
        
        --A special check for duplicate NPC ids in different environments (Mecharantula).
        npc_id = self:CheckForRedirectedRareIds(npc_id)
            
        if valid_unit_types[unittype] and self.primary_id_to_data[self.zone_id].entities[npc_id] and bit.band(destFlags, companion_type_mask) == 0 then
            if subevent == "UNIT_DIED" then
                -- Mark the entity has dead and report to your peers.
                self:ProcessEntityDeath(npc_id, spawn_uid, true)
            elseif subevent ~= "PARTY_KILL" then
                -- Report the entity as alive to your peers, if it is not marked as alive already.
                if not self.is_alive[npc_id] then
                    -- The combat log range is quite long, so no coordinates can be provided.
                    self:ProcessEntityAlive(npc_id, spawn_uid, nil, nil, true)
                end
            end
        end
    end
end

-- Fired whenever a vignette appears or disappears in the minimap.
function RareTracker:VIGNETTE_MINIMAP_UPDATED(_, vignetteGUID, _)
    if chat_frame_loaded then
        local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
        local vignetteLocation = C_VignetteInfo.GetVignettePosition(vignetteGUID, C_Map.GetBestMapForUnit("player"))

        if vignetteInfo and vignetteLocation then
            -- Report the entity.
            -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
            local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", vignetteInfo.objectGUID)
            npc_id = tonumber(npc_id)
        
            -- It might occur that the NPC id is nil. Do not proceed in such a case.
            if not npc_id then return end
            
            if valid_unit_types[unittype] then
                if not self.db.global.banned_NPC_ids[npc_id] then
                    if self:CheckForShardChange(zone_uid) then
                        self:Debug("[OnVignette]", vignetteInfo.objectGUID)
                    end
                end
                
                --A special check for duplicate NPC ids in different environments (Mecharantula).
                npc_id = self:CheckForRedirectedRareIds(npc_id)
                    
                if self.primary_id_to_data[self.zone_id].entities[npc_id] and not reported_vignettes[vignetteGUID] then
                    reported_vignettes[vignetteGUID] = {npc_id, spawn_uid}
                    local x, y = 100 * vignetteLocation.x, 100 * vignetteLocation.y
                    self:ProcessEntityAlive(npc_id, spawn_uid, x, y, true)
                end
            end
        end
    end
end

-- Fires when an NPC speaks.
function RareTracker:OnMonsterChatMessage(_, ...)
    if chat_frame_loaded then
        local data = self.primary_id_to_data[self.zone_id]

        -- Attempt to match by name or text, using the function provided by the plugin.
        local text, name = select(1, ...), select(2, ...)
        local npc_id = data.FindMatchForName and data.FindMatchForName(self, name) or data.FindMatchForText and data.FindMatchForText(self, text)
        if npc_id then
            -- We found a match.
            self.is_alive[npc_id] = GetServerTime()
            self.current_coordinates[npc_id] = self.primary_id_to_data[self.zone_id].entities[npc_id].coordinates
            self:PlaySoundNotification(npc_id, npc_id)
        end
    end
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
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "OnMonsterChatMessage")
    self:RegisterEvent("CHAT_MSG_MONSTER_SAY", "OnMonsterChatMessage")
    self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "OnMonsterChatMessage")
end

-- Unregister all events that aren't necessary when outside of tracking zones.
function RareTracker:UnregisterTrackingEvents()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("UNIT_HEALTH")
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
    self:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
    self:UnregisterEvent("CHAT_MSG_MONSTER_SAY")
    self:UnregisterEvent("CHAT_MSG_MONSTER_EMOTE")
end

-- Reset all the currently tracked data.
function RareTracker:ResetTrackedData()
    self.is_alive = {}
    self.current_health = {}
    self.last_recorded_death = {}
    self.current_coordinates = {}
    recorded_entity_death_ids = {}
    self.reported_spawn_uids = {}
    reported_vignettes = {}
end

-- Save all the recorded data in the database.
function RareTracker:SaveRecordedData()
    if self.shard_id then
        -- Store the timer data for the shard in the saved variables.
        self.db.global.previous_records[self.shard_id] = {}
        self.db.global.previous_records[self.shard_id].time_stamp = GetServerTime()
        self.db.global.previous_records[self.shard_id].time_table = self.last_recorded_death
    end
end

-- Attempt to load previous data from our cache.
function RareTracker:LoadRecordedData()
    if self.db.global.previous_records[self.shard_id] then
        if GetServerTime() - self.db.global.previous_records[self.shard_id].time_stamp < 900 then
            self:Debug("Restoring data from previous session in shard "..self.shard_id)
            self.last_recorded_death = self.db.global.previous_records[self.shard_id].time_table
        else
            self:Debug("Resetting stored data for "..self.shard_id)
            self.db.global.previous_records[self.shard_id] = nil
        end
    end
end

-- Play a sound notification if applicable
function RareTracker:PlaySoundNotification(npc_id, spawn_uid)
    if self.db.global.favorite_rares[npc_id] and not self.reported_spawn_uids[spawn_uid] and not self.reported_spawn_uids[npc_id] then
        -- Play a sound file.
        local completion_quest_id = self.primary_id_to_data[self.zone_id].entities[npc_id].quest_id
        self.reported_spawn_uids[spawn_uid] = true
        
        if not IsQuestFlaggedCompleted(completion_quest_id) then
            PlaySoundFile(self.db.global.favorite_alert.favorite_sound_alert)
        end
    end
end

-- ####################################################################
-- ##                Process Rare Event Helper Functions             ##
-- ####################################################################

-- Process that an entity has died.
function RareTracker:ProcessEntityDeath(npc_id, spawn_uid, make_announcement)
    if not recorded_entity_death_ids[spawn_uid..npc_id] then
        -- Mark the entity as dead.
        self.last_recorded_death[npc_id] = GetServerTime()
        self.is_alive[npc_id] = nil
        self.current_health[npc_id] = nil
        self.current_coordinates[npc_id] = nil
        recorded_entity_death_ids[spawn_uid..npc_id] = true
        self.reported_spawn_uids[spawn_uid] = nil
        self.reported_spawn_uids[npc_id] = nil
        
        -- Update the status of the rare in the display.
        self:UpdateStatus(npc_id)
                
        -- We need to delay the update daily kill mark check, since the servers don't update it instantly.
        local primary_id = self.zone_id
        if primary_id then
            self:DelayedExecution(3, function() self:UpdateDailyKillMark(npc_id, primary_id) end)
        end
        
        -- Remove the waypoint if applicable.
        if self.waypoints[npc_id] and TomTom then
            TomTom:RemoveWaypoint(self.waypoints[npc_id])
            self.waypoints[npc_id] = nil
        end
        
        -- Send the death message.
        if make_announcement then
            self:AnnounceEntityDeath(npc_id, spawn_uid)
        end
    end
end

-- Process that an entity has been seen alive.
function RareTracker:ProcessEntityAlive(npc_id, spawn_uid, x, y, make_announcement)
    if not recorded_entity_death_ids[spawn_uid..npc_id] then
        -- Mark the entity as alive.
        self.is_alive[npc_id] = GetServerTime()
        
        -- Update the status of the rare in the display.
        self:UpdateStatus(npc_id)

        -- Find coordinates.
        if (x == nil or y == nil) and self.primary_id_to_data[self.zone_id].entities[npc_id].coordinates then
            local location = self.primary_id_to_data[self.zone_id].entities[npc_id].coordinates
            x = location.x
            y = location.y
        end
        
        -- Make a sound announcement if appropriate.
        self:PlaySoundNotification(npc_id, spawn_uid)
        
        -- Send the alive message.
        if x ~= nil and y ~= nil then
            self.current_coordinates[npc_id] = {["x"] = x, ["y"] = y}
            if make_announcement then
                self:AnnounceEntityAliveWithCoordinates(npc_id, spawn_uid, x, y)
            end
        elseif make_announcement then
            self:AnnounceEntityAlive(npc_id, spawn_uid)
        end
    end
end

-- Process that an entity has been targeted.
function RareTracker:ProcessEntityTarget(npc_id, spawn_uid, percentage, x, y, make_announcement)
    if not recorded_entity_death_ids[spawn_uid..npc_id] then
        -- Mark the entity as targeted and alive.
        self.last_recorded_death[npc_id] = nil
        self.is_alive[npc_id] = GetServerTime()
        self.current_health[npc_id] = percentage
        self.current_coordinates[npc_id] = {["x"] = x, ["y"] = y}
        
        -- Update the status of the rare in the display.
        self:UpdateStatus(npc_id)
        
        -- Make a sound announcement if appropriate.
        self:PlaySoundNotification(npc_id, spawn_uid)
    
        -- Send the target message.
        if make_announcement then
            self:AnnounceEntityTarget(npc_id, spawn_uid, percentage, x, y)
        end
    end
end

-- Process an enemy health update.
function RareTracker:ProcessEntityHealth(npc_id, spawn_uid, percentage, make_announcement)
    if not recorded_entity_death_ids[spawn_uid..npc_id] then
        -- Update the health of the entity.
        self.last_recorded_death[npc_id] = nil
        self.is_alive[npc_id] = GetServerTime()
        self.current_health[npc_id] = percentage
        self:UpdateStatus(npc_id)
        
        -- Update the status of the rare in the display.
        self:UpdateStatus(npc_id)
        
        -- Make a sound announcement if appropriate.
        self:PlaySoundNotification(npc_id, spawn_uid)
        
        -- Send the health update message.
        if make_announcement then
            self:AnnounceEntityHealth(npc_id, spawn_uid, percentage)
        end
    end
end

-- ####################################################################
-- ##                      Daily Reset Handling                      ##
-- ####################################################################

-- Certain updates need to be made every hour because of the lack of daily reset/new world quest events.
function RareTracker:AddDailyResetHandler()
    -- There is no event for the daily reset, so do a precautionary check every hour.
    local f = CreateFrame("Frame", "RT.daily_reset_handling_frame", self.gui)

    -- Which timestamp was the last hour?
    local time_table = date("*t", GetServerTime())
    time_table.sec = 0
    time_table.min = 0

    -- Check when the next hourly reset is going to be, by adding 3600 to the previous hour timestamp.
    -- Add a 60 second offset, since the kill mark update might be delayed.
    f.target_time = time(time_table) + 3600 + 60

    -- Add an OnUpdate checker.
    f:SetScript("OnUpdate",
        function(_f)
            if GetServerTime() > _f.target_time then
                _f.target_time = _f.target_time + 3600
                
                if self.gui.entities_frame ~= nil then
                    self:UpdateAllDailyKillMarks()
                    self:Debug(L["<RT> Updating daily kill marks."])
                    self:UpdateDisplayList()
                    self:Debug("Updating display list.")
                end
            end
        end
    )
    f:Show()
    self.gui.daily_reset_handling_frame = f
end

-- ####################################################################
-- ##                       Channel Wait Frame                       ##
-- ####################################################################

-- One of the issues encountered is that the chat might be joined before the default channels.
-- In such a situation, the order of the channels changes, which is undesirable.
-- Thus, we block certain events until these chats have been loaded.
local message_delay_frame = CreateFrame("Frame", "RT.message_delay_frame", UIParent)
message_delay_frame.start_time = GetServerTime()
message_delay_frame.num_of_retries = 0
message_delay_frame:SetScript("OnUpdate",
	function(self)
		if GetServerTime() - self.start_time > 0 then
			if #{GetChannelList()} == 0 and message_delay_frame.num_of_retries < 3 then
                if #{EnumerateServerChannels()} > 0 then
                    pcall(RareTracker.Debug, RareTracker, "Retry", self.num_of_retries)
                    self.num_of_retries = self.num_of_retries + 1
                end
				self.start_time = GetServerTime()
            else
                pcall(RareTracker.Debug, RareTracker, "Chat frame is loaded.")
				chat_frame_loaded = true
				self:SetScript("OnUpdate", nil)
				self:Hide()
			end
		end
	end
)
message_delay_frame:Show()