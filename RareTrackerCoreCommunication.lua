-- Redefine often used functions locally.
local GetTime = GetTime
local strsplit = strsplit
local UnitName = UnitName
local GetServerTime = GetServerTime
local GetChannelName = GetChannelName
local JoinTemporaryChannel = JoinTemporaryChannel
local UnitInRaid = UnitInRaid
local UnitInParty = UnitInParty
local select = select
local GetNumDisplayChannels = GetNumDisplayChannels
local next = next
local tonumber = tonumber
local pairs = pairs
local max = max
local SendChatMessage = SendChatMessage
local GetChannelList = GetChannelList
local LeaveChannelByName = LeaveChannelByName

-- Redefine global variables locally.
local string = string
local GENERAL = GENERAL

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                    Communication Variables                     ##
-- ####################################################################

-- The time at which the user joined the channel.
local arrival_register_time = nil

-- The name of the channel.
local channel_name = nil

-- The communication channel version.
local version = 10
-- Version 1: Initial version
-- Version 2: Change in format of rare tables, which now include the guid of the kill.
-- Version 3: Change in format of certain messages. Deleted and added several other messages.
-- Version 10: Version changed to notify old users that an update is required. 

-- Track for each rare whether you received the data from others, such that we can overwrite your faulty data.
RareTracker.is_npc_data_from_other = {}

-- Track when the last health report was for a given npc.
local last_health_report = {
    ["CHANNEL"] = {},
    ["RAID"] = {}
}
setmetatable(last_health_report["CHANNEL"], {__index = function() return 0 end})
setmetatable(last_health_report["RAID"], {__index = function() return 0 end})

-- ####################################################################
-- ##                       Communication Core                       ##
-- ####################################################################

-- Function that is called when the addon receives a communication.
function RareTracker:OnCommReceived(_, message, distribution, player)
    -- Skip if the message is sent by the player.
    if player == UnitName("player") then return end
    
    local header, serialization = strsplit(":", message)
    local prefix, shard_id, message_version = strsplit("-", header)
    message_version = tonumber(message_version)
    local _, payload = self:Deserialize(serialization)
    
    self:Debug("Receiving:", prefix, shard_id, message_version, payload, distribution, player)
    
    -- The format of messages might change over time and as such, versioning is needed.
    -- To ensure optimal performance, all users should use the latest version.
    if not self.reported_version_mismatch and version < message_version and message_version ~= 9001 then
        print(L["<RT> Your version of the RareTracker addon is outdated. Please update to the most recent version at the earliest convenience."])
        self.reported_version_mismatch = true
    end
    
    -- Only allow communication if the users are on the same shards and if their addon version is equal.
    if self.shard_id == shard_id and version == message_version then
        if prefix == "A" then
            local time_stamp = tonumber(payload)
            self:AcknowledgeArrival(player, time_stamp)
        elseif prefix == "PW" then
            self:AcknowledgeRecordedData(payload)
        elseif prefix == "ED" then
            local npc_id, spawn_uid = strsplit("-", payload)
            npc_id = tonumber(npc_id)
            self:AcknowledgeEntityDeath(npc_id, spawn_uid)
        elseif prefix == "EA" then
            local npc_id, spawn_uid = strsplit("-", payload)
            npc_id = tonumber(npc_id)
            self:AcknowledgeEntityAlive(npc_id, spawn_uid)
        elseif prefix == "EV" then
            local npc_id, spawn_uid, x, y = strsplit("-", payload)
            npc_id, x, y = tonumber(npc_id), tonumber(x), tonumber(y)
            self:AcknowledgeEntityVignette(npc_id, spawn_uid, x, y)
        elseif prefix == "EH" then
            local npc_id, spawn_uid, percentage, x, y = strsplit("-", payload)
            npc_id, percentage, x, y = tonumber(npc_id), tonumber(percentage), tonumber(x), tonumber(y)
            self:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage, x, y, "CHANNEL")
        elseif self.db.global.communication.raid_communication then
            if prefix == "AP" then
                local time_stamp = tonumber(payload)
                self:AcknowledgeGroupArrival(time_stamp)
            elseif prefix == "PP" then
                self:AcknowledgeRecordedData(payload)
            elseif prefix == "EDP" then
                local npc_id, spawn_uid = strsplit("-", payload)
                npc_id = tonumber(npc_id)
                self:AcknowledgeEntityDeath(npc_id, spawn_uid)
            elseif prefix == "EAP" then
                local npc_id, spawn_uid = strsplit("-", payload)
                npc_id = tonumber(npc_id)
                self:AcknowledgeEntityAlive(npc_id, spawn_uid)
            elseif prefix == "EVP" then
                local npc_id, spawn_uid, x, y = strsplit("-", payload)
                npc_id, x, y = tonumber(npc_id), tonumber(x), tonumber(y)
                self:AcknowledgeEntityVignette(npc_id, spawn_uid, x, y)
            elseif prefix == "EHP" then
                local npc_id, spawn_uid, percentage, x, y = strsplit("-", payload)
                npc_id, percentage, x, y = tonumber(npc_id), tonumber(percentage), tonumber(x), tonumber(y)
                self:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage, x, y, "RAID")
            end
        end
    end
end

-- Send a message with the given type and message.
function RareTracker:SendAddonMessage(prefix, message, target, target_id)
    -- Serialize the message.
    local payload = self:Serialize(message)

    -- ChatThrottleLib does not take kindly to using the wrong target. Demote to party if needed.
    if target == "RAID" and UnitInParty("player") then
        target = "PARTY"
    end
    
    self:Debug("Sending:", prefix, self.shard_id, version, message, target, target_id)
    
    self:SendCommMessage(self.addon_code, prefix.."-"..self.shard_id.."-"..version..":"..payload, target, target_id)
end

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

-- Announce that you have arrived on the shard.
function RareTracker:AnnounceArrival()
    -- Save the current channel name and join a channel.
    channel_name = self.addon_code..self.zone_id.."S"..self.shard_id
            
    local is_in_channel = false
    if select(1, GetChannelName(channel_name)) ~= 0 then
        is_in_channel = true
    end

    -- Announce to the others that you have arrived.
    arrival_register_time = GetServerTime()

    if not is_in_channel then
        -- Join the appropriate channel.
        JoinTemporaryChannel(channel_name)
        self:Debug("Joining channel", channel_name)
        
        -- The channel join is not always instant. Wait for a second to be sure.
        self:DelayedExecution(1, function()
            self:Debug("Requesting rare kill data for shard "..self.shard_id)
            self:SendAddonMessage("A", arrival_register_time, "CHANNEL", select(1, GetChannelName(channel_name)))
        end)
        
        -- Potentially warn users of previous versions, if applicable.
        self:WarnUsersUsingPreviousVersion()
    else
        self:Debug("Requesting rare kill data for shard "..self.shard_id)
        self:SendAddonMessage("A", arrival_register_time, "CHANNEL", select(1, GetChannelName(channel_name)))
    end
    
    -- Register your arrival within the group.
    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage("AP", arrival_register_time, "RAID", nil)
    end
end

-- The previously used addon prefixes for the given zones.
local old_channel_prefixes = {
    [1462] = "RTM",
    [1522] = "RTM",
    [1355] = "RTN",
    [1527] = "RTU",
    [1530] = "RTV",
    [1579] = "RTV"
}

-- Warn users that are still using the previous version of the addon that they need to update.
function RareTracker:WarnUsersUsingPreviousVersion()
    if self.zone_id and old_channel_prefixes[self.zone_id] and self.shard_id then
        local old_channel_name = old_channel_prefixes[self.zone_id]..self.shard_id
    
        -- Join the appropriate channel.
        JoinTemporaryChannel(old_channel_name)
        self:Debug("Joining old channel", old_channel_name, "for warning purposes")
        
        -- Send an empty message over the channel.
        self:DelayedExecution(1, function()
            self:Debug("Sending outdated warning over", old_channel_name)

            -- Needs to be done outside of the function, otherwise we error.
            local target_id = select(1, GetChannelName(old_channel_name))
            self:SendCommMessage(
                old_channel_prefixes[self.zone_id],
                "OLD-"..self.shard_id.."-"..version..":OLD_VERSION_PLEASE_UPDATE",
                "CHANNEL",
                target_id
            )
        end)

        -- Leave the channel with a delay.
        self:DelayedExecution(5, function()
            self:Debug("Leaving old channel", old_channel_name)
            LeaveChannelByName(old_channel_name)
        end)
    end
end

-- Present your data through a whisper.
function RareTracker:PresentRecordedDataThroughWhisper(target, time_stamp)
    if next(self.last_recorded_death) then
        local time_table = {}
        for npc_id, kill_data in pairs(self.last_recorded_death) do
            local kill_time, spawn_uid = unpack(kill_data)
            time_table[self.ToBase64(npc_id)] = {self.ToBase64(time_stamp - kill_time), spawn_uid}
        end
        
        -- Add the time stamp to the table, such that the receiver can verify.
        time_table["time_stamp"] = self.ToBase64(time_stamp)
        
        self:SendAddonMessage("PW", time_table, "WHISPER", target)
    end
end

-- Present your data through a party/raid message.
function RareTracker:PresentRecordedDataInGroup(time_stamp)
    if next(self.last_recorded_death) then
        local time_table = {}
        for npc_id, kill_data in pairs(self.last_recorded_death) do
            local kill_time, spawn_uid = unpack(kill_data)
            time_table[self.ToBase64(npc_id)] = {self.ToBase64(time_stamp - kill_time), spawn_uid}
        end
        
        -- Add the time stamp to the table, such that the receiver can verify.
        time_table["time_stamp"] = self.ToBase64(time_stamp)
        
        self:SendAddonMessage("PP", time_table, "RAID", nil)
    end
end

-- Leave all the RareTracker shard channels that are in other zones.
function RareTracker:LeaveShardChannelsInOtherZones()
    local n_channels = GetNumDisplayChannels()
    local channels_to_leave = {}
    
    -- Leave all channels with the addon prefix.
    for i = 1, n_channels do
        local _, _channel_name = GetChannelName(i)
        if _channel_name and _channel_name:find(self.addon_code) and not channel_name == _channel_name then
            if not self.zone_id or not _channel_name:find(self.addon_code..self.zone_id.."S") then
                channels_to_leave[_channel_name] = true
            end
        end
    end
    
    for _channel_name, _ in pairs(channels_to_leave) do
        LeaveChannelByName(_channel_name)
        self:Debug("Leaving channel", _channel_name)
    end
end

-- Leave the rare tracker channel the user was previously part of, if any.
function RareTracker:LeavePreviousShardChannel()
    if channel_name and self.shard_id then
        LeaveChannelByName(channel_name)
        self:Debug("Leaving channel", channel_name)
    end
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

-- Acknowledge that the player has arrived and whisper your data table.
function RareTracker:AcknowledgeArrival(player, time_stamp)
    -- Notify the newly arrived user of your presence through a whisper.
    self:PresentRecordedDataThroughWhisper(player, time_stamp)
end

-- Acknowledge that the player has arrived and send your data table to the group.
function RareTracker:AcknowledgeGroupArrival(time_stamp)
    -- Notify the newly arrived user of your presence through a whisper.
    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:PresentRecordedDataInGroup(time_stamp)
    end
end

-- Acknowledge the welcome message of other players and parse and import their tables.
function RareTracker:AcknowledgeRecordedData(spawn_data)
    -- Get the time stamp in base 10.
    local time_stamp = self.ToBase10(spawn_data["time_stamp"])

    -- Only acknowledge the given data matches your registration time.
    if time_stamp == arrival_register_time then
        -- Remove the time stamp from the table!
        spawn_data["time_stamp"] = nil
        
        for base64_npc_id, kill_data in pairs(spawn_data) do
            -- TODO Check if the spawn data is appropriate for the current zone.
            local base64_time_passed_since_kill, spawn_uid = unpack(kill_data)
            local kill_time = arrival_register_time - self.ToBase10(base64_time_passed_since_kill)
            local npc_id = self.ToBase10(base64_npc_id)

            if self.last_recorded_death[npc_id] and self.is_npc_data_provided_by_other_player[npc_id] then
                self.last_recorded_death[npc_id] = {max(self.last_recorded_death[npc_id][1], kill_time), spawn_uid}
            else
                self.last_recorded_death[npc_id] = {kill_time, spawn_uid}
                self.is_npc_data_provided_by_other_player[npc_id] = true
            end
            self.recorded_entity_death_ids[spawn_uid..npc_id] = true
        end
    end
end

-- ####################################################################
-- ##                   Rare Announcement Functions                  ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RareTracker:AnnounceEntityDeath(npc_id, spawn_uid)
    local message = npc_id.."-"..spawn_uid
    self:SendAddonMessage("ED", message, "CHANNEL", select(1, GetChannelName(channel_name)))
    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage("EDP", message, "RAID", nil)
    end
end

-- Inform the others that you have spotted an alive entity.
function RareTracker:AnnounceEntityAlive(npc_id, spawn_uid)
    local message = npc_id.."-"..spawn_uid
    self:SendAddonMessage("EA", message, "CHANNEL", select(1, GetChannelName(channel_name)))
    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage("EAP", message, "RAID", nil)
    end
    
end

-- Inform the others that you have spotted an alive entity and include the coordinates.
function RareTracker:AnnounceEntityVignette(npc_id, spawn_uid, x, y)
    local message = npc_id.."-"..spawn_uid.."-"..x.."-"..y
    self:SendAddonMessage("EV", message, "CHANNEL", select(1, GetChannelName(channel_name)))
    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage("EVP", message, "RAID", nil)
    end
end

-- Inform the others the health of a specific entity.
function RareTracker:AnnounceEntityHealth(npc_id, spawn_uid, percentage)
    local message = npc_id.."-"..spawn_uid.."-"..percentage
    
    -- Send the health message, using a rate limited function.
    if GetTime() - last_health_report["CHANNEL"][npc_id] > 5 then
        self:SendAddonMessage("EH", message, "CHANNEL", select(1, GetChannelName(channel_name)))
        last_health_report["CHANNEL"][npc_id] = GetTime()
    end
    if GetTime() - last_health_report["RAID"][npc_id] > 5 then
        if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
            -- Send the health message, using a rate limited function.
            self:SendAddonMessage("EHP", message, "RAID", nil)
        end
        last_health_report["RAID"][npc_id] = GetTime()
    end
end

-- Inform the others the health of a specific entity, including the most recent coordinates.
function RareTracker:AnnounceEntityHealthWithCoordinates(npc_id, spawn_uid, percentage, x, y)
    local message = npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y
    
    -- Send the health message, using a rate limited function.
    if GetTime() - last_health_report["CHANNEL"][npc_id] > 5 then
        self:SendAddonMessage("EH", message, "CHANNEL", select(1, GetChannelName(channel_name)))
        last_health_report["CHANNEL"][npc_id] = GetTime()
    end
    if GetTime() - last_health_report["RAID"][npc_id] > 5 then
        if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
            self:SendAddonMessage("EHP", message, "RAID", nil)
        end
        last_health_report["RAID"][npc_id] = GetTime()
    end
end

-- ####################################################################
-- ##                   Rare Registration Functions                  ##
-- ####################################################################

 -- Acknowledge that the entity has died and set the according flags.
function RareTracker:AcknowledgeEntityDeath(npc_id, spawn_uid)
    self:ProcessEntityDeath(npc_id, spawn_uid, false)
end

-- Acknowledge that the entity is alive and set the according flags.
function RareTracker:AcknowledgeEntityAlive(npc_id, spawn_uid)
    self:ProcessEntityAlive(npc_id, spawn_uid, false)
end

-- Acknowledge that the entity is alive and set the according flags.
function RareTracker:AcknowledgeEntityVignette(npc_id, spawn_uid, x, y)
    self:ProcessEntityVignette(npc_id, spawn_uid, x, y, false)
end

-- Acknowledge the health change of the entity and set the according flags.
function RareTracker:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage, x, y, target)
    -- Add a small random factor to avoid having everyone report at the same time after the cooldown is over.
    last_health_report[target][npc_id] = GetTime() + 3 * (0.5 - math.random())
    self:ProcessEntityHealth(npc_id, spawn_uid, percentage, x, y, false)
end

-- ####################################################################
-- ##                           Chat Reports                         ##
-- ####################################################################

-- Report the status of the given rare in the desired channel.
function RareTracker:ReportRareInChat(npc_id, target, name, health, last_death, loc)
    -- Construct the message.
    local message = nil
    if self.current_health[npc_id] then
        if loc then
            local x, y = unpack(loc)
            message = string.format(L["<RT> %s (%s%%) seen at ~(%.2f, %.2f)"], name, health, x, y)
        else
            message = string.format(L["<RT> %s (%s%%)"], name, health)
        end
    elseif self.last_recorded_death[npc_id] then
        if GetServerTime() - last_death < 60 then
            message = string.format(L["<RT> %s has died"], name)
        else
            message = string.format(L["<RT> %s was last seen ~%s minutes ago"], name, math.floor((GetServerTime() - last_death) / 60))
        end
    elseif self.is_alive[npc_id] then
        if loc then
            local x, y = unpack(loc)
            message = string.format(L["<RT> %s seen alive, vignette at ~(%.2f, %.2f)"], name, x, y)
        else
            message = string.format(L["<RT> %s seen alive (combat log)"], name)
        end
    end
    
    -- Send the message.
    if message then
        if target == "CHANNEL" then
            SendChatMessage(message, target, nil, self.GetGeneralChatId())
        else
            SendChatMessage(message, target, nil, nil)
        end
    end
end

-- ####################################################################
-- ##                  Communication Helper Functions                ##
-- ####################################################################

-- Get the id of the general chat.
function RareTracker.GetGeneralChatId()
    local channel_list = {GetChannelList()}
    
    for i=2,#channel_list,3 do
        if channel_list[i]:find(GENERAL) then
            return channel_list[i - 1]
        end
    end
    
    return 0
end