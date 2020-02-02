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
    self:InitializeRareTrackerDatabase()
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

function RT:AddDefaultEventHandlerFunctions(module)
    -- Start by defining the default variables.
    module.is_alive = {}
    module.current_health = {}
    module.last_recorded_death = {}
    module.current_coordinates = {}
    module.current_shard_id = nil
    module.recorded_entity_death_ids = {}
    module.reported_vignettes = {}
    module.reported_spawn_uids = {}
    
    -- Continue by adding the default functions.
    if not module.OnEvent then 
        -- Listen to a given set of events and handle them accordingly.
        module.OnEvent = function(self, event, ...)
            if event == "PLAYER_TARGET_CHANGED" then
                self:OnTargetChanged()
            elseif event == "UNIT_HEALTH" and RT.chat_frame_loaded then
                self:OnUnitHealth(...)
            elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and RT.chat_frame_loaded then
                self:OnCombatLogEvent()
            elseif event == "CHAT_MSG_ADDON" then
                self:OnChatMsgAddon(...)
            elseif event == "VIGNETTE_MINIMAP_UPDATED" and RT.chat_frame_loaded then
                self:OnVignetteMinimapUpdated(...)
            elseif event == "CHAT_MSG_MONSTER_YELL" and RT.chat_frame_loaded then
                self:OnChatMsgMonsterYell(...)
            elseif event == "ADDON_LOADED" then
                self:OnAddonLoaded()
            elseif event == "PLAYER_LOGOUT" then
                self:OnPlayerLogout()
            end
        end
    end
    
    if not module.ChangeShard then
        -- Change from the original shard to the other.
        module.ChangeShard = function(self, old_zone_uid, new_zone_uid)
            -- Notify the users in your old shard that you have moved on to another shard.
            self:RegisterDeparture(old_zone_uid)
            
            -- Reset all the data we have, since it has all become useless.
            self.is_alive = {}
            self.current_health = {}
            self.last_recorded_death = {}
            self.recorded_entity_death_ids = {}
            self.current_coordinates = {}
            self.reported_spawn_uids = {}
            self.reported_vignettes = {}
            
            -- Announce your arrival in the new shard.
            self:RegisterArrival(new_zone_uid)
        end
    end
    
    if not module.CheckForShardChange then
        -- Check whether the user has changed shards and proceed accordingly.
        module.CheckForShardChange = function(self, zone_uid)
            local has_changed = false

            if self.current_shard_id ~= zone_uid and zone_uid ~= nil then
                print(string.format("<%s> Moving to shard ", self.addon_code)..(zone_uid + 42)..".")
                self:UpdateShardNumber(zone_uid)
                has_changed = true
                
                if self.current_shard_id == nil then
                    -- Register your arrival on the current shard.
                    self:RegisterArrival(zone_uid)
                else
                    -- Move from one shard to another.
                    self:ChangeShard(self.current_shard_id, zone_uid)
                end
                self.current_shard_id = zone_uid
            end
            
            return has_changed
        end
    end
    
    if not module.CheckForRedirectedRareIds then
        -- Check whether the given npc id needs to be redirected under the current circumstances.
        module.CheckForRedirectedRareIds = function(self, npc_id)
            -- Unused by most plugins.
            return npc_id
        end
    end
    
    if not module.OnTargetChanged then
        -- Called when a target changed event is fired.
        module.OnTargetChanged = function(self)
            if UnitGUID("target") ~= nil then
                -- Get information about the target.
                local guid = UnitGUID("target")
                
                -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
                local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", guid)
                npc_id = tonumber(npc_id)
            
                -- It might occur that the NPC id is nil. Do not proceed in such a case.
                if not npc_id then return end
                
                if not self.banned_NPC_ids[npc_id] and not self.db.global.banned_NPC_ids[npc_id] then
                    if self:CheckForShardChange(zone_uid) then
                        RT:Debug("[Target]", guid)
                    end
                end
                
                --A special check for duplicate NPC ids in different environments (Mecharantula).
                npc_id = self.CheckForRedirectedRareIds(npc_id)
                
                if unittype == "Creature" and self.rare_ids_set[npc_id] then
                    -- Find the health of the entity.
                    local health = UnitHealth("target")
                
                    if health > 0 then
                        -- Get the current position of the player and the health of the entity.
                        local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
                        local x, y = math.floor(pos.x * 10000 + 0.5) / 100, math.floor(pos.y * 10000 + 0.5) / 100
                        local percentage = RT.GetTargetHealthPercentage()
                        
                        -- Mark the entity as alive and report to your peers.
                        self:RegisterEntityTarget(self.current_shard_id, npc_id, spawn_uid, percentage, x, y)
                    else
                        -- Mark the entity has dead and report to your peers.
                        self:RegisterEntityDeath(self.current_shard_id, npc_id, spawn_uid)
                    end
                end
            end
        end
    end
    
    if not module.OnUnitHealth then
        -- Called when a unit health update event is fired.
        module.OnUnitHealth = function(self, unit)
            -- If the unit is not the target, skip.
            if unit ~= "target" then
                return
            end
            
            if UnitGUID("target") ~= nil then
                -- Get information about the target.
                local guid = UnitGUID("target")
                
                -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
                local _, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", guid)
                npc_id = tonumber(npc_id)
            
                -- It might occur that the NPC id is nil. Do not proceed in such a case.
                if not npc_id then return end
                
                if not self.banned_NPC_ids[npc_id] and not self.db.global.banned_NPC_ids[npc_id] then
                    if self:CheckForShardChange(zone_uid) then
                        RT:Debug("[OnUnitHealth]", guid)
                    end
                end
                
                --A special check for duplicate NPC ids in different environments (Mecharantula).
                npc_id = self.CheckForRedirectedRareIds(npc_id)
                
                if self.rare_ids_set[npc_id] then
                    -- Update the current health of the entity.
                    local percentage = RT.GetTargetHealthPercentage()
                    
                    -- Does the entity have any health left?
                    if percentage > 0 then
                        -- Report the health of the entity to your peers.
                        self:RegisterEntityHealth(self.current_shard_id, npc_id, spawn_uid, percentage)
                    else
                        -- Mark the entity has dead and report to your peers.
                        self:RegisterEntityDeath(self.current_shard_id, npc_id, spawn_uid)
                    end
                end
            end
        end
    end
    
    if not module.OnCombatLogEvent then
        -- The flag used to detect guardians or pets.
        local flag_mask = bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_OBJECT)

        -- Called when a unit health update event is fired.
        module.OnCombatLogEvent = function(self)
            -- The event does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
            -- timestamp, subevent, zero, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
            -- destGUID, destName, destFlags, destRaidFlags
            local _, subevent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _ = CombatLogGetCurrentEventInfo()
            
            -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
            local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID)
            npc_id = tonumber(npc_id)
            
            -- It might occur that the NPC id is nil. Do not proceed in such a case.
            if not npc_id then return end
            
            -- Blacklist the entity.
            if not self.db.global.banned_NPC_ids[npc_id] and bit.band(destFlags, flag_mask) > 0 and not self.rare_ids_set[npc_id] then
                self.db.global.banned_NPC_ids[npc_id] = true
            end
            
            -- We can always check for a shard change.
            -- We only take fights between creatures, since they seem to be the only reliable option.
            -- We exclude all pets and guardians, since they might have retained their old shard change.
            if unittype == "Creature" and not self.banned_NPC_ids[npc_id]
                and not self.db.global.banned_NPC_ids[npc_id] and bit.band(destFlags, flag_mask) == 0 then
                
                if self:CheckForShardChange(zone_uid) then
                    RT:Debug("[OnCombatLogEvent]", sourceGUID, destGUID)
                end
            end
            
            --A special check for duplicate NPC ids in different environments (Mecharantula).
            npc_id = self.CheckForRedirectedRareIds(npc_id)
                
            if unittype == "Creature" and self.rare_ids_set[npc_id] then
                if subevent == "UNIT_DIED" then
                    -- Mark the entity has dead and report to your peers.
                    self:RegisterEntityDeath(self.current_shard_id, npc_id, spawn_uid)
                elseif subevent ~= "PARTY_KILL" then
                    -- Report the entity as alive to your peers, if it is not marked as alive already.
                    if self.is_alive[npc_id] == nil then
                        -- The combat log range is quite long, so no coordinates can be provided.
                        self:RegisterEntityAlive(self.current_shard_id, npc_id, spawn_uid, nil, nil)
                    end
                end
            end
        end
    end
    
    if not module.OnVignetteMinimapUpdated then
        -- Called when a vignette on the minimap is updated.
        module.OnVignetteMinimapUpdated = function(self, vignetteGUID, _)
            local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
            local vignetteLocation = C_VignetteInfo.GetVignettePosition(vignetteGUID, C_Map.GetBestMapForUnit("player"))

            if vignetteInfo then
                -- Report the entity.
                -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
                local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", vignetteInfo.objectGUID)
                npc_id = tonumber(npc_id)
            
                -- It might occur that the NPC id is nil. Do not proceed in such a case.
                if not npc_id then return end
                
                if unittype == "Creature" then
                    if not self.banned_NPC_ids[npc_id] and not self.db.global.banned_NPC_ids[npc_id] then
                        if self:CheckForShardChange(zone_uid) then
                            RT:Debug("[OnVignette]", vignetteInfo.objectGUID)
                        end
                    end
                    
                --A special check for duplicate NPC ids in different environments (Mecharantula).
                npc_id = self.CheckForRedirectedRareIds(npc_id)
                    
                    if self.rare_ids_set[npc_id] and not self.reported_vignettes[vignetteGUID] then
                        self.reported_vignettes[vignetteGUID] = {npc_id, spawn_uid}
                        
                        local x, y = 100 * vignetteLocation.x, 100 * vignetteLocation.y
                        self:RegisterEntityAlive(self.current_shard_id, npc_id, spawn_uid, x, y)
                    end
                end
            end
        end
    end
    
    if not module.OnChatMsgMonsterYell then
        -- Called when a monster or entity does a yell emote.
        module.OnChatMsgMonsterYell = function(self, ...)
            local entity_name = select(2, ...)
            local npc_id = self.yell_announcing_rares[entity_name]
            
            if npc_id ~= nil then
                -- Mark the entity as alive.
                self.is_alive[npc_id] = GetServerTime()
                self.current_coordinates[npc_id] = self.rare_coordinates[npc_id]
                self:PlaySoundNotification(npc_id, npc_id)
            end
        end
    end
    
    if not module.OnChatMsgAddon then
        -- Called on every addon message received by the addon.
        module.OnChatMsgAddon = function(self, ...)
            local addon_prefix, message, _, sender = ...

            if addon_prefix == self.addon_code then
                local header, payload = strsplit(":", message)
                local prefix, shard_id, addon_version_str = strsplit("-", header)
                local addon_version = tonumber(addon_version_str)

                self:OnChatMessageReceived(sender, prefix, shard_id, addon_version, payload)
            end
        end
    end
    
    if not module.OnUpdate then
        -- A counter that tracks the time stamp on which the displayed data was updated last.
        module.last_display_update = 0

        -- The last time the icon changed.
        module.last_icon_change = 0

        -- Called on every addon message received by the addon.
        module.OnUpdate = function(self)
            if (self.last_display_update + 1 < GetTime()) then
                for i=1, #self.rare_ids do
                    local npc_id = self.rare_ids[i]
                    
                    -- It might occur that the rare is marked as alive, but no health is known.
                    -- If two minutes pass without a health value, the alive tag will be reset.
                    if self.is_alive[npc_id] and GetServerTime() - self.is_alive[npc_id] > 120 then
                        self.is_alive[npc_id] = nil
                        self.current_health[npc_id] = nil
                        self.reported_spawn_uids[npc_id] = nil
                    end
                    
                    self:UpdateStatus(npc_id)
                end
                
                self.last_display_update = GetTime()
            end
            
            if self.last_icon_change + 2 < GetTime() then
                self.last_icon_change = GetTime()
                
                self.broadcast_icon.icon_state = not self.broadcast_icon.icon_state
                
                if self.broadcast_icon.icon_state then
                    self.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Broadcast.tga")
                else
                    self.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Waypoint.tga")
                end
            end
        end
    end
    
    if not module.OnAddonLoaded then
        -- Give the module a flag that checks whether the addon is loaded.
        module.is_loaded = false
        
        -- Called when the addon loaded event is fired.
        module.OnAddonLoaded = function(self)
            -- OnAddonLoaded might be called multiple times. We only want it to do so once.
            if not self.is_loaded then
                -- Initialize the database.
                self:InitializeRareTrackerDatabase()
                
                -- As a precaution, we remove all actively tracked rares from the blacklist.
                for i=1, #self.rare_ids do
                    local npc_id = self.rare_ids[i]
                    self.db.global.banned_NPC_ids[npc_id] = nil
                end
                
                if not self.db.global.rare_ordering or not self.db.global.version or self.db.global.version ~= self.version then
                    RT:Debug(string.format("<%s> Resetting ordering", self.addon_code))
                    self.db.global.rare_ordering = LinkedSet:New()
                    for i=1, #self.rare_ids do
                        local npc_id = self.rare_ids[i]
                        self.db.global.rare_ordering:AddBack(npc_id)
                    end
                    self.db.global.version = self.version
                else
                    self.db.global.rare_ordering = LinkedSet:New(self.db.global.rare_ordering)
                end
                
                -- Initialize the frame.
                self:InitializeInterface()
                self:CorrectFavoriteMarks()
                
                -- Initialize the configuration menu.
                self:InitializeConfigMenu()
                
                -- Remove any data in the previous records that have expired.
                for key, _ in pairs(self.db.global.previous_records) do
                    if GetServerTime() - self.db.global.previous_records[key].time_stamp > 900 then
                        print(string.format("<%s> Removing cached data for shard ", self.addon_code)..(key + 42)..".")
                        self.db.global.previous_records[key] = nil
                    end
                end
                
                -- Notify the core library that the plugin has loaded successfully.
                RT:NotifyZoneModuleLoaded(self)
                
                self.is_loaded = true
            end
        end
    end
    
    if not module.OnPlayerLogout then
        -- Called when the player logs out, such that we can save the current time table for later use.
        module.OnPlayerLogout = function(self)
            if self.current_shard_id then
                -- Save the records, such that we can use them after a reload.
                self.db.global.previous_records[self.current_shard_id] = {}
                self.db.global.previous_records[self.current_shard_id].time_stamp = GetServerTime()
                self.db.global.previous_records[self.current_shard_id].time_table = self.last_recorded_death
            end
        end
    end
    
    if not module.RegisterEvents then
        -- Register to the events required for the addon to function properly.
        module.RegisterEvents = function(self)
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
            self:RegisterEvent("UNIT_HEALTH")
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:RegisterEvent("CHAT_MSG_ADDON")
            self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
            self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
        end
    end
    
    if not module.UnregisterEvents then
        -- Unregister from the events, to disable the tracking functionality.
        module.UnregisterEvents = function()
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
            self:UnregisterEvent("UNIT_HEALTH")
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:UnregisterEvent("CHAT_MSG_ADDON")
            self:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
            self:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
        end
    end
    
    -- Add the remaining default objects.
    self:AddDefaultUpdateAndEventSubscriptions(module)
    self:AddDefaultDailyResetHandler(module)
end

-- Certain frames and event subscriptions always have to be made.
function RT:AddDefaultUpdateAndEventSubscriptions(module)
    -- Create a frame that handles the frame updates of the addon.
    module.updateHandler = CreateFrame("Frame", string.format("%s.updateHandler", module.addon_code), module)
    module.updateHandler:SetScript("OnUpdate",
        function()
            module:OnUpdate()
        end
    )

    -- Register the event handling of the frame.
    module:SetScript("OnEvent",
        function(self, event, ...)
            self:OnEvent(event, ...)
        end
    )

    module:RegisterEvent("ADDON_LOADED")
    module:RegisterEvent("PLAYER_LOGOUT")
end

-- ####################################################################
-- ##                      Daily Reset Handling                      ##
-- ####################################################################

function RT:AddDefaultDailyResetHandler(module)
    module.daily_reset_handling_frame = CreateFrame("Frame", string.format("%s.daily_reset_handling_frame", module.addon_code), UIParent)

    -- Which timestamp was the last hour?
    local time_table = date("*t", GetServerTime())
    time_table.sec = 0
    time_table.min = 0

    -- Check when the next hourly reset is going to be, by adding 3600 to the previous hour timestamp.
    module.daily_reset_handling_frame.target_time = time(time_table) + 3600 + 60

    -- Add an OnUpdate checker.
    module.daily_reset_handling_frame:SetScript("OnUpdate",
        function(self)
            if GetServerTime() > self.target_time then
                self.target_time = self.target_time + 3600
                
                if module.entities_frame ~= nil then
                    module:UpdateAllDailyKillMarks()
                    RT:Debug(string.format("<%s> Updating daily kill marks.", module.addon_code))
                end
            end
        end
    )
    module.daily_reset_handling_frame:Show()
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
