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
local version = 100

-- Track when the last rate-limited message was sent over the specified channel. The table returns the value 0 as default.
local last_message_sent = {}
setmetatable(last_message_sent, {__index = function () return 0 end})

-- ####################################################################
-- ##                       Communication Core                       ##
-- ####################################################################

-- Function that is called when the addon receives a communication.
function RareTracker:OnCommReceived(_, message, distribution, sender)
    local header, payload = strsplit(":", message)
    local _type, shard_id, message_version = strsplit("-", header)
    message_version = tonumber(message_version)
    
    local decoded, error_code = self:Decode(payload)
    self:Debug(_type, shard_id, message_version, decoded, distribution, sender)
end

-- Send a message with the given type and message.
function RareTracker:SendAddonMessage(_type, message, target, target_id)
    local encoded = self:Encode(message)
    
    -- ChatThrottleLib does not take kindly to using the wrong target. Demote to party if needed.
    if target == "Raid" and UnitInParty("player") then
        target = "Party"
    end
    
    self:SendCommMessage(communication_prefix, _type.."-"..self.shard_id.."-"..version..":"..encoded, target, target_id)
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
    if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "AP",
            arrival_register_time,
            "RAID",
            nil
        )
    end
end

function RareTracker:AnnouncePresenceWhisper()
    
end

function RareTracker:AnnouncePresenceGroup()
    
end


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
-- ##                 Channel Announcement Functions                 ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RareTracker:AnnounceEntityDeath(npc_id, spawn_uid)
    self:SendAddonMessage(
        "ED",
        npc_id.."-"..spawn_uid,
        "CHANNEL",
        select(1, GetChannelName(channel_name))
    )

    if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "EDP",
            npc_id.."-"..spawn_uid,
            "RAID",
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

    if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "EAP",
            npc_id.."-"..spawn_uid,
            "RAID",
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

    if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "EAP",
            npc_id.."-"..spawn_uid.."-"..x.."-"..y,
            "RAID",
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
    
    if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        self:SendAddonMessage(
            "ETP",
            npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y,
            "RAID",
            nil
        )
    end
end

-- Inform the others the health of a specific entity.
function RareTracker:AnnounceEntityHealth(npc_id, spawn_uid, percentage)
    -- Send the health message, using a rate limited function.
    self:SendRateLimitedAddonMessage(
        "EH",
        npc_id.."-"..spawn_uid.."-"..percentage,
        "CHANNEL",
        select(1, GetChannelName(channel_name)),
        "CHANNEL"
    )
    
    if RT.db.global.communication.raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
        -- Send the health message, using a rate limited function.
        self:SendRateLimitedAddonMessage(
            "EHP",
            npc_id.."-"..spawn_uid.."-"..percentage,
            "RAID",
            nil,
            "RAID"
        )
    end
end

-- ####################################################################
-- ##                  Communication Helper Functions                ##
-- ####################################################################

-- LibCompress cannot be embedded and needs to be loaded as a separate module.
local libCompress = LibStub:GetLibrary("LibCompress")
local libCompressEncoder = libCompress:GetAddonEncodeTable()

-- Serialize, compress and encode the given data.
function RareTracker:Encode(data)
    local serialization = self:Serialize(data)
    local compression = libCompress:Compress(serialization)
    return libCompressEncoder:Encode(compression)
end

-- Decode, decompress and deserialize the given data.
function RareTracker:Decode(data)
    local decoding = libCompressEncoder:Decode(data)
    local decompression, error_value = libCompress:Decompress(decoding)
    if not error_value then
        local deserialization_success, deserialization = self:Deserialize(decompression)
        if deserialization_success then
            return deserialization, nil
        else
            return nil, "Deserialization Failed"
        end
    else
        return nil, error_value
    end
end

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

-- A function that ensures that a message is sent only once every 'refresh_time' seconds.
function RareTracker:SendRateLimitedAddonMessage(message, target, target_id, refresh_time)
    -- We only allow one message to be sent every ~'refresh_time' seconds.
    if GetTime() - last_message_sent[target] > refresh_time then
        self:SendAddonMessage(message, target, target_id)
        last_message_sent[target] = GetTime()
    end
end