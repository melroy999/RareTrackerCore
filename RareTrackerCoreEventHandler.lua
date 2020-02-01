-- Redefine often used functions locally.
local UnitGUID = UnitGUID
local strsplit = strsplit
local UnitHealth = UnitHealth
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local C_VignetteInfo = C_VignetteInfo
local GetServerTime = GetServerTime
local LinkedSet = LinkedSet
local CreateFrame = CreateFrame
local GetChannelList = GetChannelList

-- Redefine often used variables locally.
local C_Map = C_Map
local COMBATLOG_OBJECT_TYPE_GUARDIAN = COMBATLOG_OBJECT_TYPE_GUARDIAN
local COMBATLOG_OBJECT_TYPE_PET = COMBATLOG_OBJECT_TYPE_PET
local COMBATLOG_OBJECT_TYPE_OBJECT = COMBATLOG_OBJECT_TYPE_OBJECT
local UIParent = UIParent
local C_MapExplorationInfo = C_MapExplorationInfo

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                         Event Handlers                         ##
-- ####################################################################

function RT:OnEnable()
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function RT:OnInitialize()
    self:InitializeRareTrackerData()
    self:RegisterChatCommand("rt", "ChatCommand")
    self:RegisterChatCommand("raretracker", "ChatCommand")
end

function RT:OnDisable()
    
end

function RT:ZONE_CHANGED()
    self:OnZoneTransition()
end

function RT:ZONE_CHANGED_NEW_AREA()
    self:OnZoneTransition()
end

function RT:PLAYER_ENTERING_WORLD()
    self:OnZoneTransition()
end

-- ####################################################################
-- ##                        Event Functions                         ##
-- ####################################################################

function RT:OnZoneTransition()
    -- The zone the player is in.
    local zone_id = C_Map.GetBestMapForUnit("player")
    
    -- Find the associated modules of the current zone and the last zone.
    local current_zone_module = self.zone_id_to_module[zone_id]
    local previous_zone_module = self.zone_id_to_module[self.last_zone_id]
    
    -- Check if we have to leave the previous zone.
    if previous_zone_module and not previous_zone_module.target_zones[zone_id] then
        previous_zone_module:RegisterDeparture(previous_zone_module.current_shard_id)
        previous_zone_module:CloseInterface()
    end
    
    -- Check if we have entered a new zone.
    if current_zone_module and not current_zone_module.target_zones[self.last_zone_id] then
        current_zone_module:StartInterface()
    end
    
    self.last_zone_id = zone_id
end

-- ####################################################################
-- ##                            Commands                            ##
-- ####################################################################

function RT:ChatCommand(input)
    input = input:trim()
    if not input or input == "" then
        InterfaceOptionsFrame_Show()
        InterfaceOptionsFrame_OpenToCategory(self.options_frame)
    else
        local _, _, cmd, _ = string.find(input, "%s?(%w+)%s?(.*)")
        if cmd == "show" then
            if self.last_zone_id and self.zone_id_to_module[self.last_zone_id] then
                self.zone_id_to_module[self.last_zone_id]:Show()
                self.db.global.window.hide = false
            end
        elseif cmd == "hide" then
            if self.last_zone_id and self.zone_id_to_module[self.last_zone_id] then
                self.zone_id_to_module[self.last_zone_id]:Hide()
            end
            self.db.global.window.hide = true
        end
    end
end

-- ####################################################################
-- ##                       Channel Wait Frame                       ##
-- ####################################################################

-- One of the issues encountered is that the chat might be joined before the default channels.
-- In such a situation, the order of the channels changes, which is undesirable.
-- Thus, we block certain events until these chats have been loaded.
RT.chat_frame_loaded = false

local message_delay_frame = CreateFrame("Frame", "RT.message_delay_frame", UIParent)
message_delay_frame.start_time = GetServerTime()
message_delay_frame:SetScript("OnUpdate",
	function(self)
		if GetServerTime() - self.start_time > 0 then
			if #{GetChannelList()} == 0 then
				self.start_time = GetServerTime()
			else
				RT.chat_frame_loaded = true
				self:SetScript("OnUpdate", nil)
				self:Hide()
			end
		end
	end
)
message_delay_frame:Show()
