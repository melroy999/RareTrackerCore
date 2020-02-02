-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime
local strsplit = strsplit
local UnitName = UnitName
local GetRealmName = GetRealmName
local GetServerTime = GetServerTime
local GetChannelName = GetChannelName
local JoinTemporaryChannel = JoinTemporaryChannel
local UnitInRaid = UnitInRaid
local UnitInParty = UnitInParty
local select = select
local GetNumDisplayChannels = GetNumDisplayChannels
local next = next
local tonumber = tonumber
local IsQuestFlaggedCompleted = IsQuestFlaggedCompleted
local PlaySoundFile = PlaySoundFile
local pairs = pairs
local LeaveChannelByName = LeaveChannelByName

-- Redefine global variables locally.
local UIParent = UIParent
local C_ChatInfo = C_ChatInfo
local string = string
local TomTom = TomTom

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                    Communication Variables                     ##
-- ####################################################################

-- The time at which you broad-casted the joined the shard group.
RT.arrival_register_time = nil

-- The name and realm of the player.
RT.player_name = UnitName("player").."-"..GetRealmName()

-- A time stamp at which the last message was sent in the rate limited message sender.
RT.last_message_sent = {
    ["CHANNEL"] = 0,
    ["RAID"] = 0,
}

-- The last time the health of an entity has been reported.
-- Used for limiting the number of messages sent to the channel.
RT.last_health_report = {
    ["CHANNEL"] = {},
    ["RAID"] = {},
}

-- ####################################################################
-- ##                     Decoration Call Function                   ##
-- ####################################################################

-- Decorate the module with the default communication functions, if not specified by the module itself.
function RT:AddDefaultCommunicationFunctions(module)
    self.AddDefaultHelperCommunicationFunctions(module)
    self.AddDefaultShardRegistrationFunctions(module)
    self.AddDefaultShardAcknowledgementFunctions(module)
    self.AddDefaultEntityDataShareFunctions(module)
    self.AddDefaultCoreChatManagementFunction(module)
end

-- ####################################################################
-- ##                  Communication Helper Functions                ##
-- ####################################################################

-- A function that enables the delayed execution of a function.
function RT.DelayedExecution(delay, _function)
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

-- Get the id of the general chat.
function RT.GetGeneralChatId()
    local channel_list = {GetChannelList()}
    
    for i=2,#channel_list,3 do
        if channel_list[i]:find(GENERAL) then
            return channel_list[i - 1]
        end
    end
    
    return 0
end

-- Add the default helper functions.
function RT.AddDefaultHelperCommunicationFunctions(module)
    if not module.SendRateLimitedAddonMessage then
        module.SendRateLimitedAddonMessage = function(self, message, target, target_id, target_channel)
            -- We only allow one message to be sent every ~5 seconds.
            if GetTime() - RT.last_message_sent[target_channel] > 5 then
                C_ChatInfo.SendAddonMessage(self.addon_code, message, target, target_id)
                RT.last_message_sent[target_channel] = GetTime()
            end
        end
    end
    
    if not module.GetCompressedSpawnData then
        -- Handle the compression and decompression of spawn data.
        module.GetCompressedSpawnData = function(self, time_stamp)
            local result = ""
            
            for i=1, #self.rare_ids do
                local npc_id = self.rare_ids[i]
                local kill_time = self.last_recorded_death[npc_id]
                
                if kill_time ~= nil then
                    result = result..RT.toBase64(time_stamp - kill_time)..","
                else
                    result = result..RT.toBase64(0)..","
                end
            end
            
            return result:sub(1, #result - 1)
        end
    end
    
    if not module.DecompressSpawnData then
        -- Decompress all the Base64 data sent by a peer to decimal and update the timers.
        module.DecompressSpawnData = function(self, spawn_data, time_stamp)
            local spawn_data_entries = {strsplit(",", spawn_data, #self.rare_ids)}
            for i=1, #self.rare_ids do
                local npc_id = self.rare_ids[i]
                local kill_time = RT.toBase10(spawn_data_entries[i])
                
                if kill_time ~= 0 then
                    if self.last_recorded_death[npc_id] then
                        -- If we already have an entry, take the minimal.
                        if time_stamp - kill_time < self.last_recorded_death[npc_id] then
                            self.last_recorded_death[npc_id] = time_stamp - kill_time
                        end
                    else
                        self.last_recorded_death[npc_id] = time_stamp - kill_time
                    end
                end
            end
        end
    end
end
    
-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

-- Add the default shard group management register functions.
function RT.AddDefaultShardRegistrationFunctions(module)
    if not module.RegisterArrival then
        -- Inform other clients of your arrival.
        module.RegisterArrival = function(self, shard_id)
            -- Attempt to load previous data from our cache.
            if self.db.global.previous_records[shard_id] then
                if GetServerTime() - self.db.global.previous_records[shard_id].time_stamp < 900 then
                    print(string.format(
                        "<%s> Restoring data from previous session in shard "..(shard_id + 42)..".",
                        self.addon_code
                    ))
                    self.last_recorded_death = self.db.global.previous_records[shard_id].time_table
                else
                    self.db.global.previous_records[shard_id] = nil
                end
            end

            self.channel_name = self.addon_code..shard_id
            
            local is_in_channel = false
            if select(1, GetChannelName(self.channel_name)) ~= 0 then
                is_in_channel = true
            end

            -- Announce to the others that you have arrived.
            self.arrival_register_time = GetServerTime()
            self.rare_table_updated = false
                
            if not is_in_channel then
                -- Join the appropriate channel.
                JoinTemporaryChannel(self.channel_name)
                
                -- We want to avoid overwriting existing channel numbers. So delay the channel join.
                RT.DelayedExecution(1, function()
                        print(string.format(
                                "<%s> Requesting rare kill data for shard "..(shard_id + 42)..".", self.addon_code
                        ))
                        C_ChatInfo.SendAddonMessage(
                            self.addon_code,
                            "A-"..shard_id.."-"..self.version..":"..self.arrival_register_time,
                            "CHANNEL",
                            select(1, GetChannelName(self.channel_name))
                        )
                    end
                )
            else
                print(string.format("<%s> Requesting rare kill data for shard "..(shard_id + 42)..".", self.addon_code))
                C_ChatInfo.SendAddonMessage(
                    self.addon_code,
                    "A-"..shard_id.."-"..self.version..":"..self.arrival_register_time,
                    "CHANNEL",
                    select(1, GetChannelName(self.channel_name))
                )
            end
            
            -- Register your arrival within the group.
            if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
                C_ChatInfo.SendAddonMessage(
                    self.addon_code,
                    "AP-"..shard_id.."-"..self.version..":"..self.arrival_register_time,
                    "RAID",
                    nil
                )
            end
        end
    end
    
    if not module.RegisterPresenceWhisper then
        -- Present your data through a whisper.
        module.RegisterPresenceWhisper = function(self, shard_id, target, time_stamp)
            if next(self.last_recorded_death) ~= nil then
                -- Announce to the others that you are still present on the shard.
                C_ChatInfo.SendAddonMessage(
                    self.addon_code,
                    "PW-"..shard_id.."-"..self.version..":"..self:GetCompressedSpawnData(time_stamp),
                    "WHISPER",
                    target
                )
            end
        end
    end
    
    if not module.RegisterPresenceGroup then
        -- Present your data through the raid channel.
        module.RegisterPresenceGroup = function(self, shard_id, time_stamp)
            if next(self.last_recorded_death) ~= nil then
                -- Announce to the others that you are still present on the shard.
                C_ChatInfo.SendAddonMessage(
                    self.addon_code,
                    "PP-"..shard_id.."-"..self.version..":"..self:GetCompressedSpawnData(time_stamp).."-"..time_stamp,
                    "RAID",
                    nil
                )
            end
        end
    end
    
    if not module.RegisterDeparture then
        --Leave the channel.
        module.RegisterDeparture = function(self, shard_id)
            local n_channels = GetNumDisplayChannels()
            local channels_to_leave = {}
            
            -- Leave all channels with the addon prefix.
            for i = 1, n_channels do
                local _, channel_name = GetChannelName(i)
                if channel_name and channel_name:find(self.addon_code) then
                    channels_to_leave[channel_name] = true
                end
            end
            
            for channel_name, _ in pairs(channels_to_leave) do
                LeaveChannelByName(channel_name)
            end
            
            -- Store any timer data we previously had in the saved variables.
            if shard_id then
                self.db.global.previous_records[shard_id] = {}
                self.db.global.previous_records[shard_id].time_stamp = GetServerTime()
                self.db.global.previous_records[shard_id].time_table = self.last_recorded_death
            end
        end
    end
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

-- Add the default shard group management acknowledgement functions.
function RT.AddDefaultShardAcknowledgementFunctions(module)
    if not module.AcknowledgeArrival then
        -- Acknowledge that the player has arrived and whisper your data table.
        module.AcknowledgeArrival = function(self, player, time_stamp)
            -- Notify the newly arrived user of your presence through a whisper.
            if RT.player_name ~= player then
                self:RegisterPresenceWhisper(self.current_shard_id, player, time_stamp)
            end
        end
    end
    
    if not module.AcknowledgeArrivalGroup then
        -- Acknowledge that the player has arrived and whisper your data table.
        module.AcknowledgeArrivalGroup = function(self, player, time_stamp)
            -- Notify the newly arrived user of your presence through a whisper.
            if RT.player_name ~= player then
                if RT.db.global.communication.raid_communication
                        and (UnitInRaid("player") or UnitInParty("player")) then
                    self:RegisterPresenceGroup(self.current_shard_id, time_stamp)
                end
            end
        end
    end
    
    if not module.AcknowledgePresence then
        -- Acknowledge the welcome message of other players and parse and import their tables.
        module.AcknowledgePresence = function(self, spawn_data)
            self:DecompressSpawnData(spawn_data, self.arrival_register_time)
        end
    end
end

-- ####################################################################
-- ##               Entity Information Share Functions               ##
-- ####################################################################

-- Add the default entity information share functions.
function RT.AddDefaultEntityDataShareFunctions(module)
    if not module.RegisterEntityDeath then
        -- Inform the others that a specific entity has died.
        module.RegisterEntityDeath = function(self, shard_id, npc_id, spawn_uid)
            if not self.recorded_entity_death_ids[spawn_uid..npc_id] then
                -- Mark the entity as dead.
                self.last_recorded_death[npc_id] = GetServerTime()
                self.is_alive[npc_id] = nil
                self.current_health[npc_id] = nil
                self.current_coordinates[npc_id] = nil
                self.recorded_entity_death_ids[spawn_uid..npc_id] = true
                self.reported_spawn_uids[npc_id] = nil
                
                -- We want to avoid overwriting existing channel numbers. So delay the channel join.
                RT.DelayedExecution(3, function() self:UpdateDailyKillMark(npc_id) end)
                
                -- Send the death message.
                C_ChatInfo.SendAddonMessage(
                    self.addon_code,
                    "ED-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid,
                    "CHANNEL",
                    select(1, GetChannelName(self.channel_name))
                )
            
                if RT.db.global.communication.raid_communication
                        and (UnitInRaid("player") or UnitInParty("player")) then
                    C_ChatInfo.SendAddonMessage(
                        self.addon_code,
                        "EDP-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid,
                        "RAID",
                        nil
                    )
                end
            end
        end
    end
    
    if not module.RegisterEntityAlive then
        -- Inform the others that you have spotted an alive entity.
        module.RegisterEntityAlive = function(self, shard_id, npc_id, spawn_uid, x, y)
            if self.recorded_entity_death_ids[spawn_uid..npc_id] == nil then
                -- Mark the entity as alive.
                self.is_alive[npc_id] = GetServerTime()
            
                -- Send the alive message.
                if (x == nil or y == nil) and self.rare_coordinates[npc_id] then
                    local location = self.rare_coordinates[npc_id]
                    x = location.x
                    y = location.y
                end
                
                if x ~= nil and y ~= nil then
                    self.current_coordinates[npc_id] = {["x"] = x, ["y"] = y}
                    
                    C_ChatInfo.SendAddonMessage(
                        self.addon_code,
                        "EA-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."-"..x.."-"..y,
                        "CHANNEL",
                        select(1, GetChannelName(self.channel_name))
                    )
                
                    if RT.db.global.communication.raid_communication
                            and (UnitInRaid("player") or UnitInParty("player")) then
                        C_ChatInfo.SendAddonMessage(
                            self.addon_code,
                            "EAP-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."-"..x.."-"..y,
                            "RAID",
                            nil
                        )
                    end
                else
                    C_ChatInfo.SendAddonMessage(
                        self.addon_code,
                        "EA-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."--",
                        "CHANNEL",
                        select(1, GetChannelName(self.channel_name))
                    )
                
                    if RT.db.global.communication.raid_communication
                            and (UnitInRaid("player") or UnitInParty("player")) then
                        C_ChatInfo.SendAddonMessage(
                            self.addon_code,
                            "EAP-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."--",
                            "RAID",
                            nil
                        )
                    end
                end
            end
        end
    end
    
    if not module.RegisterEntityTarget then
        -- Inform the others that you have spotted an alive entity.
        module.RegisterEntityTarget = function(self, shard_id, npc_id, spawn_uid, percentage, x, y)
            if self.recorded_entity_death_ids[spawn_uid..npc_id] == nil then
                -- Mark the entity as targeted and alive.
                self.is_alive[npc_id] = GetServerTime()
                self.current_health[npc_id] = percentage
                self.current_coordinates[npc_id] = {["x"] = x, ["y"] = y}
                self:UpdateStatus(npc_id)
            
                -- Send the target message.
                C_ChatInfo.SendAddonMessage(
                    self.addon_code,
                    "ET-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y,
                    "CHANNEL",
                    select(1, GetChannelName(self.channel_name))
                )
                
                if RT.db.global.communication.raid_communication
                        and (UnitInRaid("player") or UnitInParty("player")) then
                    C_ChatInfo.SendAddonMessage(
                        self.addon_code,
                        "ETP-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y,
                        "RAID",
                        nil
                    )
                end
            end
        end
    end
    
    if not module.RegisterEntityHealth then
        -- Inform the others the health of a specific entity.
        module.RegisterEntityHealth = function(self, shard_id, npc_id, spawn_uid, percentage)
            if not RT.last_health_report["CHANNEL"][npc_id]
                or GetTime() - RT.last_health_report["CHANNEL"][npc_id] > 2 then
                -- Mark the entity as targeted and alive.
                self.is_alive[npc_id] = GetServerTime()
                self.current_health[npc_id] = percentage
                self:UpdateStatus(npc_id)
            
                -- Send the health message, using a rate limited function.
                self:SendRateLimitedAddonMessage(
                    "EH-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."-"..percentage,
                    "CHANNEL",
                    select(1, GetChannelName(self.channel_name)),
                    "CHANNEL"
                )
            end
            
            if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
                if not RT.last_health_report["RAID"][npc_id]
                        or GetTime() - RT.last_health_report["RAID"][npc_id] > 2 then
                    -- Mark the entity as targeted and alive.
                    self.is_alive[npc_id] = GetServerTime()
                    self.current_health[npc_id] = percentage
                    self:UpdateStatus(npc_id)
                
                    -- Send the health message, using a rate limited function.
                    self:SendRateLimitedAddonMessage(
                        "EHP-"..shard_id.."-"..self.version..":"..npc_id.."-"..spawn_uid.."-"..percentage,
                        "RAID",
                        nil,
                        "RAID"
                    )
                end
            end
        end
    end

    if not module.AcknowledgeEntityDeath then
        -- Acknowledge that the entity has died and set the according flags.
        module.AcknowledgeEntityDeath = function(self, npc_id, spawn_uid)
            if not self.recorded_entity_death_ids[spawn_uid..npc_id] then
                -- Mark the entity as dead.
                self.last_recorded_death[npc_id] = GetServerTime()
                self.is_alive[npc_id] = nil
                self.current_health[npc_id] = nil
                self.current_coordinates[npc_id] = nil
                self.recorded_entity_death_ids[spawn_uid..npc_id] = true
                self.reported_spawn_uids[npc_id] = nil
                self:UpdateStatus(npc_id)
                RT.DelayedExecution(3, function() self:UpdateDailyKillMark(npc_id) end)
            end

            if self.waypoints[npc_id] and TomTom then
                TomTom:RemoveWaypoint(self.waypoints[npc_id])
                self.waypoints[npc_id] = nil
            end
        end
    end
    
    if not module.PlaySoundNotification then
        -- Play a sound notification if applicable
        module.PlaySoundNotification = function(self, npc_id, spawn_uid)
            if self.db.global.favorite_rares[npc_id] and not self.reported_spawn_uids[spawn_uid]
                and not self.reported_spawn_uids[npc_id] then
                    
                -- Play a sound file.
                local completion_quest_id = self.completion_quest_ids[npc_id]
                self.reported_spawn_uids[spawn_uid] = true
                
                if not IsQuestFlaggedCompleted(completion_quest_id) then
                    PlaySoundFile(RT.db.global.favorite_alert.favorite_sound_alert)
                end
            end
        end
    end

    if not module.AcknowledgeEntityAlive then
        -- Acknowledge that the entity is alive and set the according flags.
        module.AcknowledgeEntityAlive = function(self, npc_id, spawn_uid, x, y)
            if not self.recorded_entity_death_ids[spawn_uid..npc_id] then
                self.is_alive[npc_id] = GetServerTime()
                self:UpdateStatus(npc_id)
                
                if x ~= nil and y ~= nil then
                    self.current_coordinates[npc_id] = {["x"] = x, ["y"] = y}
                else
                    self.current_coordinates[npc_id] = self.rare_coordinates[npc_id]
                end
                self:PlaySoundNotification(npc_id, spawn_uid)
            end
        end
    end
    
    if not module.AcknowledgeEntityTarget then
        -- Acknowledge that the entity is alive and set the according flags.
        module.AcknowledgeEntityTarget = function(self, npc_id, spawn_uid, percentage, x, y)
            if not self.recorded_entity_death_ids[spawn_uid..npc_id] then
                self.last_recorded_death[npc_id] = nil
                self.is_alive[npc_id] = GetServerTime()
                self.current_health[npc_id] = percentage
                self.current_coordinates[npc_id] = {["x"] = x, ["y"] = y}
                self:UpdateStatus(npc_id)
                self:PlaySoundNotification(npc_id, spawn_uid)
            end
        end
    end
    
    if not module.AcknowledgeEntityHealth then
        -- Acknowledge the health change of the entity and set the according flags.
        module.AcknowledgeEntityHealth = function(self, npc_id, spawn_uid, percentage)
            if not self.recorded_entity_death_ids[spawn_uid..npc_id] then
                self.last_recorded_death[npc_id] = nil
                self.is_alive[npc_id] = GetServerTime()
                self.current_health[npc_id] = percentage
                RT.last_health_report["CHANNEL"][npc_id] = GetTime()
                self:UpdateStatus(npc_id)
                self:PlaySoundNotification(npc_id, spawn_uid)
            end
        end
    end
    
    if not module.AcknowledgeEntityHealthRaid then
        -- Acknowledge the health change of the entity and set the according flags.
        module.AcknowledgeEntityHealthRaid = function(self, npc_id, spawn_uid, percentage)
            if not self.recorded_entity_death_ids[spawn_uid..npc_id] then
                self.last_recorded_death[npc_id] = nil
                self.is_alive[npc_id] = GetServerTime()
                self.current_health[npc_id] = percentage
                RT.last_health_report["RAID"][npc_id] = GetTime()
                self:UpdateStatus(npc_id)
                self:PlaySoundNotification(npc_id, spawn_uid)
            end
        end
    end
end

-- ####################################################################
-- ##                      Core Chat Management                      ##
-- ####################################################################

-- Add the default entity information share functions.
function RT.AddDefaultCoreChatManagementFunction(module)
    if not module.OnChatMessageReceived then
        -- Determine what to do with the received chat message.
        module.OnChatMessageReceived = function(self, player, prefix, shard_id, addon_version, payload)
            -- The format of messages might change over time and as such, versioning is needed.
            -- To ensure optimal performance, all users should use the latest version.
            if not self.reported_version_mismatch and self.version < addon_version and addon_version ~= 9001 then
                print(string.format("<%s> Your version of the %s addon is outdated. "..
                    "Please update to the most recent version at the earliest convenience.",
                    self.addon_code,
                    self.addon_code
                ))
                self.reported_version_mismatch = true
            end
            
            RT:Debug(player, prefix, shard_id, addon_version, payload)
            
            -- Only allow communication if the users are on the same shards and if their addon version is equal.
            if self.current_shard_id == shard_id and self.version == addon_version then
                if prefix == "A" then
                    local time_stamp = tonumber(payload)
                    self:AcknowledgeArrival(player, time_stamp)
                elseif prefix == "PW" then
                    self:AcknowledgePresence(payload)
                elseif prefix == "ED" then
                    local npcs_id_str, spawn_uid = strsplit("-", payload)
                    local npc_id = tonumber(npcs_id_str)
                    self:AcknowledgeEntityDeath(npc_id, spawn_uid)
                elseif prefix == "EA" then
                    local npcs_id_str, spawn_uid, x_str, y_str = strsplit("-", payload)
                    local npc_id, x, y = tonumber(npcs_id_str), tonumber(x_str), tonumber(y_str)
                    self:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
                elseif prefix == "ET" then
                    local npc_id_str, spawn_uid, percentage_str, x_str, y_str = strsplit("-", payload)
                    local npc_id, percentage, x, y = tonumber(npc_id_str), tonumber(percentage_str), tonumber(x_str), tonumber(y_str)
                    self:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
                elseif prefix == "EH" then
                    local npc_id_str, spawn_uid, percentage_str = strsplit("-", payload)
                    local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
                    self:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage)
                elseif RT.db.global.communication.raid_communication then
                    if prefix == "AP" then
                        local time_stamp = tonumber(payload)
                        self:AcknowledgeArrivalGroup(player, time_stamp)
                    elseif prefix == "PP" then
                        local rare_data, arrival_time_str = strsplit("-", payload)
                        local arrival_time = tonumber(arrival_time_str)
                        if self.arrival_register_time == arrival_time then
                            self:AcknowledgePresence(rare_data)
                        end
                    elseif prefix == "EDP" then
                        local npcs_id_str, spawn_uid = strsplit("-", payload)
                        local npc_id = tonumber(npcs_id_str)
                        self:AcknowledgeEntityDeath(npc_id, spawn_uid)
                    elseif prefix == "EAP" then
                        local npcs_id_str, spawn_uid, x_str, y_str = strsplit("-", payload)
                        local npc_id, x, y = tonumber(npcs_id_str), tonumber(x_str), tonumber(y_str)
                        self:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
                    elseif prefix == "ETP" then
                        local npc_id_str, spawn_uid, percentage_str, x_str, y_str = strsplit("-", payload)
                        local npc_id, percentage, x, y = tonumber(npc_id_str), tonumber(percentage_str), tonumber(x_str), tonumber(y_str)
                        self:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
                    elseif prefix == "EHP" then
                        local npc_id_str, spawn_uid, percentage_str = strsplit("-", payload)
                        local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
                        self:AcknowledgeEntityHealthRaid(npc_id, spawn_uid, percentage)
                    end
                end
            end
        end
    end
end
