-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                    Communication Variables                     ##
-- ####################################################################

-- The communication prefix of the addon.
RareTracker.communication_prefix = "RareTracker"

-- Track when the last rate-limited message was sent over the specified channel. The table returns the value 0 as default.
RareTracker.last_message_sent = {}
setmetatable(RareTracker.last_message_sent, {__index = function () return 0 end})

-- ####################################################################
-- ##                       Communication Core                       ##
-- ####################################################################

-- Function that is called when the addon receives a communication.
function RareTracker:OnCommReceived(prefix, message, distribution, sender)
    local decoded, error_code = self:Decode(message)
    print(prefix, decoded, distribution, sender)
end

function RareTracker:SendComm(message, target, target_id)
    local encoded = self:Encode(message)
    
    -- ChatThrottleLib does not take kindly to using the wrong target. Demote to party if needed.
    if target == "Raid" and UnitInParty("player") then
        target = "Party"
    elseif target == "Party" and UnitInRaid("player") then
        target = "Raid"
    end
    
    self:SendCommMessage(self.communication_prefix, encoded, target, target_id)
end

function RareTracker:SendCommTest()
    self:SendComm("Hello", "Raid", nil)
    self:SendRateLimitedAddonMessage(RTU.rare_names, "Raid", nil, 5)
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
    -- We only allow one message to be sent every ~5 seconds.
    if GetTime() - self.last_message_sent[target] > 5 then
        self:SendComm(message, target, target_id)
        self.last_message_sent[target] = GetTime()
    end
end