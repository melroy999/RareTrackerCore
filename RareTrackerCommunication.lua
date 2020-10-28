-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                    Communication Variables                     ##
-- ####################################################################

-- The communication prefix of the addon.
local communication_prefix = "RareTracker"

-- The time at which the user joined the channel.
local arrival_register_time = nil

-- The name of the channel.
local channel_name = nil

-- The communication channel version.
local version = 1

-- The name and realm of the player.
local player_name = UnitName("player").."-"..GetRealmName()

-- Track when the last health report was for a given npc.
local last_health_report = {
    ["CHANNEL"] = {},
    ["Raid"] = {}
}
setmetatable(last_health_report["CHANNEL"], {__index = function() return 0 end})
setmetatable(last_health_report["Raid"], {__index = function() return 0 end})

-- ####################################################################
-- ##                       Communication Core                       ##
-- ####################################################################

-- Function that is called when the addon receives a communication.
function RareTracker:OnCommReceived(_, message, distribution, player)
    self:Debug(message, distribution, player)
    
    -- Skip if the message is sent by the player.
    if player_name == player then return end
    
    local header, serialization = strsplit(":", message)
    local prefix, shard_id, message_version = strsplit("-", header)
    message_version = tonumber(message_version)
    local deserialization_success, payload = self:Deserialize(serialization)
    
    -- The format of messages might change over time and as such, versioning is needed.
    -- To ensure optimal performance, all users should use the latest version.
    if not self.reported_version_mismatch and version < message_version and message_version ~= 9001 then
        print("<RT> Your version of the RareTracker addon is outdated. Please update to the most recent version at the earliest convenience.")
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
            local npc_id, spawn_uid, x, y = strsplit("-", payload)
            npc_id, x, y = tonumber(npc_id), tonumber(x), tonumber(y)
            self:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
        elseif prefix == "ET" then
            local npc_id, spawn_uid, percentage, x, y = strsplit("-", payload)
            npc_id, percentage, x, y = tonumber(npc_id), tonumber(percentage), tonumber(x), tonumber(y)
            self:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
        elseif prefix == "EH" then
            local npc_id, spawn_uid, percentage = strsplit("-", payload)
            npc_id, percentage = tonumber(npc_id), tonumber(percentage)
            self:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage)
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
                local npc_id, spawn_uid, x, y = strsplit("-", payload)
                npc_id, x, y = tonumber(npc_id), tonumber(x), tonumber(y)
                self:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
            elseif prefix == "ETP" then
                local npc_id, spawn_uid, percentage, x, y = strsplit("-", payload)
                npc_id, percentage, x, y = tonumber(npc_id), tonumber(percentage), tonumber(x), tonumber(y)
                self:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
            elseif prefix == "EHP" then
                local npc_id, spawn_uid, percentage = strsplit("-", payload)
                npc_id, percentage = tonumber(npc_id), tonumber(percentage)
                self:AcknowledgeEntityHealthRaid(npc_id, spawn_uid, percentage)
            end
        end
    end
end

-- Send a message with the given type and message.
function RareTracker:SendAddonMessage(prefix, message, target, target_id)
    -- Serialize the message.
    message = self:Serialize(message)

    -- ChatThrottleLib does not take kindly to using the wrong target. Demote to party if needed.
    if target == "Raid" and UnitInParty("player") then
        target = "Party"
    end
    
    self:SendCommMessage(communication_prefix, prefix.."-"..self.shard_id.."-"..version..":"..message, target, target_id)
end

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

function RareTracker:AnnounceArrival()
    -- Save the current channel name and join a channel.
    channel_name = self.addon_code..self.shard_id
            
    local is_in_channel = false
    if select(1, GetChannelName(channel_name)) ~= 0 then
        is_in_channel = true
    end

    -- Announce to the others that you have arrived.
    arrival_register_time = GetServerTime()
    -- TODO self.rare_table_updated = false
        
    if not is_in_channel then
        -- Join the appropriate channel.
        JoinTemporaryChannel(channel_name)
        
        -- We want to avoid overwriting existing channel numbers. So delay the channel join.
        self.DelayedExecution(1, function()
                self:Debug("Requesting rare kill data for shard "..self.shard_id)
                self:SendAddonMessage(
                    "A", 
                    arrival_register_time,
                    "CHANNEL",
                    select(1, GetChannelName(channel_name))
                )
            end
        )
    else
        self:Debug("Requesting rare kill data for shard "..self.shard_id)
        self:SendAddonMessage(
            "A",
            arrival_register_time,
            "CHANNEL",
            select(1, GetChannelName(channel_name))
        )
    end
    
    -- Register your arrival within the group.
    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "AP",
            arrival_register_time,
            "Raid",
            nil
        )
    end
end

-- Present your data through a whisper.
function RareTracker:PresentRecordedDataThroughWhisper(target, time_stamp)  
    if next(self.last_recorded_death) then
        local time_table = {}
        for npc_id, kill_time in pairs(self.last_recorded_death) do
            time_table[self:ToBase64(npc_id)] = self:ToBase64(time_stamp - kill_time)
        end
        
        -- Add the time stamp to the table, such that the receiver can verify.
        time_table["time_stamp"] = self:ToBase64(time_stamp)
        
        self:SendAddonMessage("PW", time_table, "WHISPER", target)
    end
end

-- Present your data through a party/raid message.
function RareTracker:PresentRecordedDataInGroup(time_stamp)
    if next(self.last_recorded_death) then
        local time_table = {}
        for npc_id, kill_time in pairs(self.last_recorded_death) do
            time_table[self:ToBase64(npc_id)] = self:ToBase64(time_stamp - kill_time)
        end
        
        -- Add the time stamp to the table, such that the receiver can verify.
        time_table["time_stamp"] = self:ToBase64(time_stamp)
        
        self:SendAddonMessage("PP", time_table, "Raid", nil)
    end
end

-- Leave all the RareTracker shard channels that the player is currently part of.
function RareTracker:LeaveAllShardChannels()
    local n_channels = GetNumDisplayChannels()
    local channels_to_leave = {}
    
    -- Leave all channels with the addon prefix.
    for i = 1, n_channels do
        local _, channel_name = GetChannelName(i)
        if channel_name and channel_name:find(communication_prefix) then
            channels_to_leave[channel_name] = true
        end
    end
    
    for channel_name, _ in pairs(channels_to_leave) do
        LeaveChannelByName(channel_name)
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
    local time_stamp = self:ToBase10(spawn_data["time_stamp"])

    -- Only acknowledge the given data matches your registration time.
    if time_stamp == arrival_register_time then
        -- Remove the time stamp from the table!
        spawn_data["time_stamp"] = nil
        
        for base64_npc_id, base64_time_passed_since_kill in pairs(spawn_data) do
            local kill_time = arrival_register_time - self:ToBase10(base64_time_passed_since_kill)
            local npc_id = self:ToBase10(base64_npc_id)
            if self.last_recorded_death[npc_id] then
                self.last_recorded_death[npc_id] = min(self.last_recorded_death[npc_id], kill_time)
            else
                self.last_recorded_death[npc_id] = kill_time
            end
        end
    end
end

-- ####################################################################
-- ##                   Rare Announcement Functions                  ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RareTracker:AnnounceEntityDeath(npc_id, spawn_uid)
    self:SendAddonMessage(
        "ED",
        npc_id.."-"..spawn_uid,
        "CHANNEL",
        select(1, GetChannelName(channel_name))
    )

    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "EDP",
            npc_id.."-"..spawn_uid,
            "Raid",
            nil
        )
    end
end

-- Inform the others that you have spotted an alive entity.
function RareTracker:AnnounceEntityAlive(npc_id, spawn_uid)
    self:SendAddonMessage(
        "EA",
        npc_id.."-"..spawn_uid,
        "CHANNEL",
        select(1, GetChannelName(channel_name))
    )

    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "EAP",
            npc_id.."-"..spawn_uid,
            "Raid",
            nil
        )
    end
    
end

-- Inform the others that you have spotted an alive entity and include the coordinates.
function RareTracker:AnnounceEntityAliveWithCoordinates(npc_id, spawn_uid, x, y)
    self:SendAddonMessage(
        "EA",
        npc_id.."-"..spawn_uid.."-"..x.."-"..y,
        "CHANNEL",
        select(1, GetChannelName(channel_name))
    )

    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "EAP",
            npc_id.."-"..spawn_uid.."-"..x.."-"..y,
            "Raid",
            nil
        )
    end
end

-- Inform the others that you have spotted an alive entity.
function RareTracker:AnnounceEntityTarget(npc_id, spawn_uid, percentage, x, y)
    self:SendAddonMessage(
        "ET",
        npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y,
        "CHANNEL",
        select(1, GetChannelName(channel_name))
    )
    
    if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "ETP",
            npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y,
            "Raid",
            nil
        )
    end
end

-- Inform the others the health of a specific entity.
function RareTracker:AnnounceEntityHealth(npc_id, spawn_uid, percentage)
    -- Send the health message, using a rate limited function.
    if GetTime() - last_health_report["CHANNEL"][npc_id] > 5 then
        self:SendAddonMessage(
            "EH",
            npc_id.."-"..spawn_uid.."-"..percentage,
            "CHANNEL",
            select(1, GetChannelName(channel_name))
        )
        last_health_report["CHANNEL"][npc_id] = GetTime()
    end
    
    if GetTime() - last_health_report["Raid"][npc_id] > 5 then
        if self.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
            -- Send the health message, using a rate limited function.
            self:SendAddonMessage(
                "EHP",
                npc_id.."-"..spawn_uid.."-"..percentage,
                "Raid",
                nil
            )
        end
        last_health_report["Raid"][npc_id] = GetTime()
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
function RareTracker:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
    self:ProcessEntityAlive(npc_id, spawn_uid, x, y, false)
end

-- Acknowledge that the entity is alive and set the according flags.
function RareTracker:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
    self:ProcessEntityTarget(npc_id, spawn_uid, percentage, x, y, false)
end

-- Acknowledge the health change of the entity and set the according flags.
function RareTracker:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage)
    last_health_report["CHANNEL"][npc_id] = GetTime()
    self:ProcessEntityHealth(npc_id, spawn_uid, percentage, false)
end

-- Acknowledge the health change of the entity and set the according flags.
function RareTracker:AcknowledgeEntityHealthRaid(npc_id, spawn_uid, percentage)
    last_health_report["Raid"][npc_id] = GetTime()
    self:ProcessEntityHealth(npc_id, spawn_uid, percentage, false)
end

-- ####################################################################
-- ##                           Chat Reports                         ##
-- ####################################################################

-- Report the status of the given rare in the desired channel.
function RareTracker:ReportRareInChat(target, name, health, last_death, loc)
    -- Construct the message.
    local message = nil
    if self.current_health[npc_id] then
        if loc then
            message = string.format(L["<%s> %s (%s%%) seen at ~(%.2f, %.2f)"], self.addon_code, name, health, loc.x, loc.y)
        else
            message = string.format(L["<%s> %s (%s%%)"], self.addon_code, name, health)
        end
    elseif self.last_recorded_death[npc_id] ~= nil then
        if GetServerTime() - last_death < 60 then
            message = string.format(L["<%s> %s has died"], self.addon_code, name)
        else
            message = string.format(L["<%s> %s was last seen ~%s minutes ago"], self.addon_code, name, math.floor((GetServerTime() - last_death) / 60))
        end
    elseif self.is_alive[npc_id] then
        if loc then
            message = string.format(L["<%s> %s seen alive, vignette at ~(%.2f, %.2f)"], self.addon_code, name, loc.x, loc.y)
        else
            message = string.format(L["<%s> %s seen alive (combat log)"], self.addon_code, name)
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