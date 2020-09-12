-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local IsLeftControlKeyDown = IsLeftControlKeyDown
local IsRightControlKeyDown = IsRightControlKeyDown
local UnitInRaid = UnitInRaid
local IsLeftAltKeyDown = IsLeftAltKeyDown
local IsRightAltKeyDown = IsRightAltKeyDown
local SendChatMessage = SendChatMessage
local GetServerTime = GetServerTime
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local pairs = pairs
local print = print

-- Redefine global variables locally.
local C_ChatInfo = C_ChatInfo
local string = string
local UIParent = UIParent
local TomTom = TomTom

-- Width and height variables used to customize the window.
local entity_name_width = 208
local entity_status_width = 50
local frame_padding = 4
local favorite_rares_width = 10
local shard_id_frame_height = 16

-- Values for the opacity of the background and foreground.
local background_opacity = 0.4
local front_opacity = 0.6

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerCore", true)

-- ####################################################################
-- ##                     Decoration Call Function                   ##
-- ####################################################################

-- Decorate the module with the default interface functions, if not specified by the module itself.
function RT:AddDefaultInterfaceFunctions(module)
    self.AddDefaultInterfaceControlFunctions(module)
    self.AddDefaultEntityFrameFunctions(module)
end

-- ####################################################################
-- ##                        Interface Control                       ##
-- ####################################################################

-- Add the default interface control functions.
function RT.AddDefaultInterfaceControlFunctions(module)
    if not module.StartInterface then
        -- Open and start the interface and subscribe to all the required events.
        module.StartInterface = function(self)
            -- Reset the data, since we cannot guarantee its correctness.
            self.is_alive = {}
            self.current_health = {}
            self.last_recorded_death = {}
            self.current_coordinates = {}
            self.reported_spawn_uids = {}
            self.reported_vignettes = {}
            self.waypoints = {}
            self.current_shard_id = nil
            self:UpdateShardNumber(nil)
            self:UpdateAllDailyKillMarks()
            self:RegisterEvents()
            
            -- Attempt to register a prefix for the addon. All modules are given their own code for clarity.
            if C_ChatInfo.RegisterAddonMessagePrefix(self.addon_code) ~= true then
                print(string.format(
                    L["<%s> Failed to register AddonPrefix '%s'. %s will not function properly."],
                    self.addon_code, self.addon_code, self.addon_code
                ))
            end
            
            -- Show the window if it is not hidden.
            if not RT.db.global.window.hide then
                self:Show()
            end
        end
    end
    
    if not module.CloseInterface then
        -- Close and stop the interface and unsubscribe from all the required events.
        module.CloseInterface = function(self)
            -- Reset the data.
            self.is_alive = {}
            self.current_health = {}
            self.last_recorded_death = {}
            self.current_coordinates = {}
            self.reported_spawn_uids = {}
            self.reported_vignettes = {}
            self.current_shard_id = nil
            self:UpdateShardNumber(nil)
            
            -- Register the user's departure and disable event listeners.
            self:RegisterDeparture(self.current_shard_id)
            self:UnregisterEvents()
            
            -- Hide the interface.
            self:Hide()
        end
    end
end

-- ####################################################################
-- ##                       Rare Entities Window                     ##
-- ####################################################################

-- Add the default entity frame initialization and control functions.
function RT.AddDefaultEntityFrameFunctions(module)
    -- Add the default variables.
    module.last_reload_time = 0
    
    if not module.InitializeShardNumberFrame then
        -- Display the current shard number at the top of the frame.
        module.InitializeShardNumberFrame = function(self)
            local f = CreateFrame("Frame", string.format("%s.shard_id_frame", self.addon_code), self)
            f:SetSize(
                entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width,
                shard_id_frame_height
            )
          
            local texture = f:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(f)
            f.texture = texture
            
            f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
            f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -3)
            f.status_text:SetText(string.format(L["Shard ID: %s"], L["Unknown"]))
            f:SetPoint("TOPLEFT", self, frame_padding, -frame_padding)
            
            return f
        end
    end
    
    if not module.CreateRareTableEntry then
        -- Create an entry within the entity frame for the given entity.
        module.CreateRareTableEntry = function(self, npc_id, parent_frame)
            local f = CreateFrame(
                "Frame", string.format("%s.entities_frame.entities[%s]", self.addon_code, npc_id), parent_frame
            )
            f:SetSize(entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width, 12)
            
            -- Add the favorite button.
            f.favorite = CreateFrame(
                "CheckButton", string.format("%s.entities_frame.entities[%s].favorite", self.addon_code, npc_id), f
            )
            f.favorite:SetSize(10, 10)
            local texture = f.favorite:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(f.favorite)
            f.favorite.texture = texture
            f.favorite:SetPoint("TOPLEFT", 1, 0)
            
            -- Add an action listener.
            f.favorite:SetScript("OnClick", function()
                if self.db.global.favorite_rares[npc_id] then
                    self.db.global.favorite_rares[npc_id] = nil
                    f.favorite.texture:SetColorTexture(0, 0, 0, front_opacity)
                else
                    self.db.global.favorite_rares[npc_id] = true
                    f.favorite.texture:SetColorTexture(0, 1, 0, 1)
                end
                RT:NotifyOptionsChange()
            end)
            
            -- Add the announce/waypoint button.
            f.announce = CreateFrame(
                "Button", string.format("%s.entities_frame.entities[%s].announce", self.addon_code, npc_id), f
            )
            f.announce:SetSize(10, 10)
            texture = f.announce:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(f.announce)
            f.announce.texture = texture
            f.announce:SetPoint("TOPLEFT", frame_padding + favorite_rares_width + 1, 0)
            f.announce:RegisterForClicks("LeftButtonDown", "RightButtonDown")
            
            -- Add an action listener.
            f.announce:SetScript("OnClick",
                function(_, button)
                    local name = self.rare_names[npc_id]
                    local health = self.current_health[npc_id]
                    local last_death = self.last_recorded_death[npc_id]
                    local loc = self.current_coordinates[npc_id]
                    
                    if button == "LeftButton" then
                        local target = "CHANNEL"
                        
                        if IsLeftControlKeyDown() or IsRightControlKeyDown() then
                            if UnitInRaid("player") then
                                target = "RAID"
                            else
                                target = "PARTY"
                            end
                        elseif IsLeftAltKeyDown() or IsRightAltKeyDown() then
                            target = "SAY"
                        end
                        
                        local channel_id = RT.GetGeneralChatId()
                    
                        if self.current_health[npc_id] then
                            -- SendChatMessage
                            if loc then
                                SendChatMessage(
                                    string.format(
                                        L["<%s> %s (%s%%) seen at ~(%.2f, %.2f)"],
                                        self.addon_code,
                                        name,
                                        health,
                                        loc.x,
                                        loc.y
                                    ),
                                    target,
                                    nil,
                                    channel_id
                                )
                            else
                                SendChatMessage(
                                    string.format(L["<%s> %s (%s%%)"], self.addon_code, name, health),
                                    target,
                                    nil,
                                    channel_id
                                )
                            end
                        elseif self.last_recorded_death[npc_id] ~= nil then
                            if GetServerTime() - last_death < 60 then
                                SendChatMessage(
                                    string.format(L["<%s> %s has died"], self.addon_code, name),
                                    target,
                                    nil,
                                    channel_id
                                )
                            else
                                SendChatMessage(
                                    string.format(
                                        L["<%s> %s was last seen ~%s minutes ago"],
                                        self.addon_code,
                                        name,
                                        math.floor((GetServerTime() - last_death) / 60)
                                    ),
                                    target,
                                    nil,
                                    channel_id
                                )
                            end
                        elseif self.is_alive[npc_id] then
                            if loc then
                                SendChatMessage(
                                    string.format(
                                        L["<%s> %s seen alive, vignette at ~(%.2f, %.2f)"],
                                        self.addon_code, name,
                                        loc.x,
                                        loc.y
                                    ),
                                    target,
                                    nil,
                                    channel_id
                                )
                            else
                                SendChatMessage(
                                    string.format(L["<%s> %s seen alive (combat log)"], self.addon_code, name),
                                    target,
                                    nil,
                                    channel_id
                                )
                            end
                        end
                    else
                        -- does the user have tom tom? if so, add a waypoint if it exists.
                        if TomTom ~= nil and loc and not self.waypoints[npc_id] then
                            self.waypoints[npc_id] = TomTom:AddWaypointToCurrentZone(loc.x, loc.y, name)
                        end
                    end
                end
            )
            
            -- Add the entities name.
            f.name = f:CreateFontString(nil, nil, "GameFontNormal")
            f.name:SetJustifyH("LEFT")
            f.name:SetJustifyV("TOP")
            f.name:SetPoint("TOPLEFT", 2 * frame_padding + 2 * favorite_rares_width + 10, 0)
            f.name:SetText(self.rare_names[npc_id])
            
            -- Add the timer/health entry.
            f.status = f:CreateFontString(nil, nil, "GameFontNormal")
            f.status:SetPoint("TOPRIGHT", 0, 0)
            f.status:SetText("--")
            f.status:SetJustifyH("MIDDLE")
            f.status:SetJustifyV("TOP")
            f.status:SetSize(entity_status_width, 12)
            
            return f
        end
    end
    
    if not module.InitializeRareTableEntries then
        -- Initialize the rare entries in the table for all the npcs.
        module.InitializeRareTableEntries = function(self, parent_frame)
            -- Create a holder for all the entries.
            parent_frame.entities = {}
            
            -- Create a frame entry for all of the NPC ids, even the ignored ones.
            -- The ordering and hiding of rares will be done later.
            for i=1, #self.rare_ids do
                local npc_id = self.rare_ids[i]
                parent_frame.entities[npc_id] = self:CreateRareTableEntry(npc_id, parent_frame)
            end
        end
    end
    
    if not module.ReorganizeRareTableFrame then
        -- Reorganize the entries within the rare table.
        module.ReorganizeRareTableFrame = function(self, f)
            -- How many ignored rares do we have?
            local n = 0
            for _, npc_id in pairs(self.rare_ids) do
                if self.db.global.ignore_rares[npc_id] then
                    n = n + 1
                end
            end
            
            -- Resize all the frames.
            self:SetSize(
                entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding,
                shard_id_frame_height + 3 * frame_padding + (#self.rare_ids - n) * 12 + 8
            )
            f:SetSize(
                entity_name_width + entity_status_width + 2 * favorite_rares_width + 3 * frame_padding,
                (#self.rare_ids - n) * 12 + 8
            )
            f.entity_name_backdrop:SetSize(entity_name_width, f:GetHeight())
            f.entity_status_backdrop:SetSize(entity_status_width, f:GetHeight())
            
            -- Give all of the table entries their new positions.
            local i = 1
            self.db.global.rare_ordering:ForEach(function(npc_id, _)
                if self.db.global.ignore_rares[npc_id] then
                    f.entities[npc_id]:Hide()
                else
                    f.entities[npc_id]:SetPoint("TOPLEFT", f, 0, -(i - 1) * 12 - 5)
                    f.entities[npc_id]:Show()
                    i = i + 1
                end
            end)
        end
    end
    
    if not module.InitializeRareTableFrame then
        -- Initialize the rare table frame.
        module.InitializeRareTableFrame = function(self, f)
            -- First, add the frames for the backdrop and make sure that the hierarchy is created.
            f:SetPoint("TOPLEFT", frame_padding, -(2 * frame_padding + shard_id_frame_height))
            
            f.entity_name_backdrop = CreateFrame(
                "Frame", string.format("%s.entities_frame.entity_name_backdrop", self.addon_code), f
            )
            local texture = f.entity_name_backdrop:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(f.entity_name_backdrop)
            f.entity_name_backdrop.texture = texture
            f.entity_name_backdrop:SetPoint("TOPLEFT", f, 2 * frame_padding + 2 * favorite_rares_width, 0)
            
            f.entity_status_backdrop = CreateFrame(
                "Frame", string.format("%s.entities_frame.entity_status_backdrop", self.addon_code), f
            )
            texture = f.entity_status_backdrop:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(f.entity_status_backdrop)
            f.entity_status_backdrop.texture = texture
            f.entity_status_backdrop:SetPoint("TOPRIGHT", f, 0, 0)
            
            -- Next, add all the rare entries to the table.
            self:InitializeRareTableEntries(f)
            
            -- Arrange the table such that it fits the user's wishes. Resize the frames appropriately.
            self:ReorganizeRareTableFrame(f)
        end
    end
    
    if not module.UpdateStatus then
        -- Update the status for the given entity.
        module.UpdateStatus = function(self, npc_id)
            local target = self.entities_frame.entities[npc_id]

            if self.current_health[npc_id] then
                target.status:SetText(self.current_health[npc_id].."%")
                target.status:SetFontObject("GameFontGreen")
                target.announce.texture:SetColorTexture(0, 1, 0, 1)
            elseif self.is_alive[npc_id] then
                target.status:SetText("N/A")
                target.status:SetFontObject("GameFontGreen")
                target.announce.texture:SetColorTexture(0, 1, 0, 1)
            elseif self.last_recorded_death[npc_id] ~= nil then
                local last_death = self.last_recorded_death[npc_id]
                target.status:SetText(math.floor((GetServerTime() - last_death) / 60).."m")
                target.status:SetFontObject("GameFontNormal")
                target.announce.texture:SetColorTexture(0, 0, 1, front_opacity)
            else
                target.status:SetText("--")
                target.status:SetFontObject("GameFontNormal")
                target.announce.texture:SetColorTexture(0, 0, 0, front_opacity)
            end
        end
    end
    
    if not module.UpdateShardNumber then
        -- Update the shard number in the shard number display.
        module.UpdateShardNumber = function(self, shard_number)
            if shard_number then
                self.shard_id_frame.status_text:SetText(string.format(L["Shard ID: %s"], (shard_number + 42)))
            else
                self.shard_id_frame.status_text:SetText(string.format(L["Shard ID: %s"], L["Unknown"]))
            end
        end
    end

    if not module.CorrectFavoriteMarks then
        -- Ensure that all the favorite marks of the entities are set correctly.
        module.CorrectFavoriteMarks = function(self)
            for _, npc_id in pairs(self.rare_ids) do
                if self.db.global.favorite_rares[npc_id] then
                    self.entities_frame.entities[npc_id].favorite.texture:SetColorTexture(0, 1, 0, 1)
                else
                    self.entities_frame.entities[npc_id].favorite.texture:SetColorTexture(0, 0, 0, front_opacity)
                end
            end
        end
    end

    if not module.UpdateDailyKillMark then
        -- Update the daily kill mark of the given entity.
        module.UpdateDailyKillMark = function(self, npc_id)
            if not self.completion_quest_ids[npc_id] then
                return
            end
            
            -- Multiple NPCs might share the same quest id.
            local completion_quest_id = self.completion_quest_ids[npc_id]
            local npc_ids = self.completion_quest_inverse[completion_quest_id]
            
            for _, target_npc_id in pairs(npc_ids) do
                if self.completion_quest_ids[target_npc_id]
                        and IsQuestFlaggedCompleted(self.completion_quest_ids[target_npc_id]) then
                    self.entities_frame.entities[target_npc_id].name:SetText(self.rare_display_names[target_npc_id])
                    self.entities_frame.entities[target_npc_id].name:SetFontObject("GameFontRed")
                else
                    self.entities_frame.entities[target_npc_id].name:SetText(self.rare_display_names[target_npc_id])
                    self.entities_frame.entities[target_npc_id].name:SetFontObject("GameFontNormal")
                end
            end
        end
    end

    if not module.UpdateAllDailyKillMarks then
        -- Update the daily kill marks of all the tracked entities.
        module.UpdateAllDailyKillMarks = function(self)
            for _, npc_id in pairs(self.rare_ids) do
                self:UpdateDailyKillMark(npc_id)
            end
        end
    end
    
    if not module.InitializeFavoriteIconFrame then
        -- Initialize the favorite icon in the rare entities frame.
        module.InitializeFavoriteIconFrame = function(self)
            self.favorite_icon = CreateFrame("Frame", string.format("%s.favorite_icon", self.addon_code), self)
            self.favorite_icon:SetSize(10, 10)
            self.favorite_icon:SetPoint("TOPLEFT", self, frame_padding + 1, -(frame_padding + 3))

            self.favorite_icon.texture = self.favorite_icon:CreateTexture(nil, "OVERLAY")
            self.favorite_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Favorite.tga")
            self.favorite_icon.texture:SetSize(10, 10)
            self.favorite_icon.texture:SetPoint("CENTER", self.favorite_icon)
            
            self.favorite_icon.tooltip = CreateFrame("Frame", nil, UIParent)
            self.favorite_icon.tooltip:SetSize(300, 18)
            
            local texture = self.favorite_icon.tooltip:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(self.favorite_icon.tooltip)
            self.favorite_icon.tooltip.texture = texture
            self.favorite_icon.tooltip:SetPoint("TOPLEFT", self, 0, 19)
            self.favorite_icon.tooltip:Hide()
            
            self.favorite_icon.tooltip.text = self.favorite_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.favorite_icon.tooltip.text:SetJustifyH("LEFT")
            self.favorite_icon.tooltip.text:SetJustifyV("TOP")
            self.favorite_icon.tooltip.text:SetPoint("TOPLEFT", self.favorite_icon.tooltip, 5, -3)
            self.favorite_icon.tooltip.text:SetText(L["Click on the squares to add rares to your favorites."])
            
            self.favorite_icon:SetScript("OnEnter", function(icon) icon.tooltip:Show() end)
            self.favorite_icon:SetScript("OnLeave", function(icon) icon.tooltip:Hide() end)
        end
    end
    
    if not module.InitializeAnnounceIconFrame then
        -- Initialize the alternating announce icon in the rare entities frame.
        module.InitializeAnnounceIconFrame = function(self)
            self.broadcast_icon = CreateFrame("Frame", string.format("%s.broadcast_icon", self.addon_code), self)
            self.broadcast_icon:SetSize(10, 10)
            self.broadcast_icon:SetPoint(
                "TOPLEFT", self, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3)
            )

            self.broadcast_icon.texture = self.broadcast_icon:CreateTexture(nil, "OVERLAY")
            self.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Broadcast.tga")
            self.broadcast_icon.texture:SetSize(10, 10)
            self.broadcast_icon.texture:SetPoint("CENTER", self.broadcast_icon)
            self.broadcast_icon.icon_state = false
            
            self.broadcast_icon.tooltip = CreateFrame("Frame", nil, UIParent)
            self.broadcast_icon.tooltip:SetSize(273, 68)
            
            local texture = self.broadcast_icon.tooltip:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(self.broadcast_icon.tooltip)
            self.broadcast_icon.tooltip.texture = texture
            self.broadcast_icon.tooltip:SetPoint("TOPLEFT", self, 0, 69)
            self.broadcast_icon.tooltip:Hide()
            
            self.broadcast_icon.tooltip.text1 = self.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.broadcast_icon.tooltip.text1:SetJustifyH("LEFT")
            self.broadcast_icon.tooltip.text1:SetJustifyV("TOP")
            self.broadcast_icon.tooltip.text1:SetPoint("TOPLEFT", self.broadcast_icon.tooltip, 5, -3)
            self.broadcast_icon.tooltip.text1:SetText(L["Click on the squares to announce rare timers."])
            
            self.broadcast_icon.tooltip.text2 = self.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.broadcast_icon.tooltip.text2:SetJustifyH("LEFT")
            self.broadcast_icon.tooltip.text2:SetJustifyV("TOP")
            self.broadcast_icon.tooltip.text2:SetPoint("TOPLEFT", self.broadcast_icon.tooltip, 5, -15)
            self.broadcast_icon.tooltip.text2:SetText(L["Left click: report to general chat"])
            
            self.broadcast_icon.tooltip.text3 = self.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.broadcast_icon.tooltip.text3:SetJustifyH("LEFT")
            self.broadcast_icon.tooltip.text3:SetJustifyV("TOP")
            self.broadcast_icon.tooltip.text3:SetPoint("TOPLEFT", self.broadcast_icon.tooltip, 5, -27)
            self.broadcast_icon.tooltip.text3:SetText(L["Control-left click: report to party/raid chat"])
            
            self.broadcast_icon.tooltip.text4 = self.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.broadcast_icon.tooltip.text4:SetJustifyH("LEFT")
            self.broadcast_icon.tooltip.text4:SetJustifyV("TOP")
            self.broadcast_icon.tooltip.text4:SetPoint("TOPLEFT", self.broadcast_icon.tooltip, 5, -39)
            self.broadcast_icon.tooltip.text4:SetText(L["Alt-left click: report to say"])
              
            self.broadcast_icon.tooltip.text5 = self.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.broadcast_icon.tooltip.text5:SetJustifyH("LEFT")
            self.broadcast_icon.tooltip.text5:SetJustifyV("TOP")
            self.broadcast_icon.tooltip.text5:SetPoint("TOPLEFT", self.broadcast_icon.tooltip, 5, -51)
            self.broadcast_icon.tooltip.text5:SetText(L["Right click: set waypoint if available"])
            
            self.broadcast_icon:SetScript("OnEnter", function(icon) icon.tooltip:Show() end)
            self.broadcast_icon:SetScript("OnLeave", function(icon) icon.tooltip:Hide() end)
        end
    end
    
    if not module.InitializeReloadButton then
        -- Initialize the reload button in the rare entities frame.
        module.InitializeReloadButton = function(self)
            self.reload_button = CreateFrame("Button", string.format("%s.reload_button", self.addon_code), self)
            self.reload_button:SetSize(10, 10)
            self.reload_button:SetPoint(
                "TOPRIGHT", self, -3 * frame_padding - favorite_rares_width, -(frame_padding + 3)
            )

            self.reload_button.texture = self.reload_button:CreateTexture(nil, "OVERLAY")
            self.reload_button.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Reload.tga")
            self.reload_button.texture:SetSize(10, 10)
            self.reload_button.texture:SetPoint("CENTER", self.reload_button)
            
            -- Create a tooltip window.
            self.reload_button.tooltip = CreateFrame("Frame", nil, UIParent)
            self.reload_button.tooltip:SetSize(390, 34)
            
            local texture = self.reload_button.tooltip:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, front_opacity)
            texture:SetAllPoints(self.reload_button.tooltip)
            self.reload_button.tooltip.texture = texture
            self.reload_button.tooltip:SetPoint("TOPLEFT", self, 0, 35)
            self.reload_button.tooltip:Hide()
            
            self.reload_button.tooltip.text1 = self.reload_button.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.reload_button.tooltip.text1:SetJustifyH("LEFT")
            self.reload_button.tooltip.text1:SetJustifyV("TOP")
            self.reload_button.tooltip.text1:SetPoint("TOPLEFT", self.reload_button.tooltip, 5, -3)
            self.reload_button.tooltip.text1:SetText(L["Reset your data and replace it with the data of others."])
            
            self.reload_button.tooltip.text2 = self.reload_button.tooltip:CreateFontString(nil, nil, "GameFontNormal")
            self.reload_button.tooltip.text2:SetJustifyH("LEFT")
            self.reload_button.tooltip.text2:SetJustifyV("TOP")
            self.reload_button.tooltip.text2:SetPoint("TOPLEFT", self.reload_button.tooltip, 5, -15)
            self.reload_button.tooltip.text2:SetText(
                L["Note: you do not need to press this button to receive new timers."]
            )
            
            -- Hide and show the tooltip on mouseover.
            self.reload_button:SetScript("OnEnter", function(icon) icon.tooltip:Show() end)
            self.reload_button:SetScript("OnLeave", function(icon) icon.tooltip:Hide() end)
            
            self.reload_button:SetScript("OnClick", function()
                if self.current_shard_id ~= nil and GetServerTime() - self.last_reload_time > 600 then
                    print(string.format(
                        L["<%s> Resetting current rare timers and requesting up-to-date data."], self.addon_code
                    ))
                    self.is_alive = {}
                    self.current_health = {}
                    self.last_recorded_death = {}
                    self.recorded_entity_death_ids = {}
                    self.current_coordinates = {}
                    self.reported_spawn_uids = {}
                    self.reported_vignettes = {}
                    self.last_reload_time = GetServerTime()
                    
                    -- Reset the cache.
                    self.db.global.previous_records[self.current_shard_id] = nil
                    
                    -- Re-register your arrival in the shard.
                    self:RegisterArrival(self.current_shard_id)
                elseif self.current_shard_id == nil then
                    print(string.format(L["<%s> Please target a non-player entity prior to resetting, "..
                            "such that the addon can determine the current shard id."], self.addon_code))
                else
                    print(string.format(
                        L["<%s> The reset button is on cooldown. Please note that a reset is not needed "..
                        "to receive new timers. If it is your intention to reset the data, "..
                        "please do a /reload and click the reset button again."], self.addon_code
                    ))
                end
            end)
        end
    end
    
    if not module.InitializeCloseButton then
        -- Initialize the close button in the rare entities frame.
        module.InitializeCloseButton = function(self)
            self.close_button = CreateFrame("Button", string.format("%s.close_button", self.addon_code), self)
            self.close_button:SetSize(10, 10)
            self.close_button:SetPoint("TOPRIGHT", self, -2 * frame_padding, -(frame_padding + 3))

            self.close_button.texture = self.close_button:CreateTexture(nil, "OVERLAY")
            self.close_button.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Cross.tga")
            self.close_button.texture:SetSize(10, 10)
            self.close_button.texture:SetPoint("CENTER", self.close_button)
            
            self.close_button:SetScript("OnClick", function()
                self:Hide()
                RT.db.global.window.hide = true
            end)
        end
    end
    
    if not module.InitializeInterface then
        -- Initialize the addon's entity frame.
        module.InitializeInterface = function(self)
            self:SetSize(
                entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding,
                shard_id_frame_height + 3 * frame_padding + #self.rare_ids * 12 + 8
            )
            
            local texture = self:CreateTexture(nil, "BACKGROUND")
            texture:SetColorTexture(0, 0, 0, background_opacity)
            texture:SetAllPoints(self)
            self.texture = texture
            self:SetPoint("CENTER")
            
            -- Create a sub-frame for the entity names.
            self.shard_id_frame = self:InitializeShardNumberFrame()
            self.entities_frame = CreateFrame("Frame", string.format("%s.entities_frame", self.addon_code), self)
            self:InitializeRareTableFrame(self.entities_frame)

            self:SetMovable(true)
            self:EnableMouse(true)
            self:RegisterForDrag("LeftButton")
            self:SetScript("OnDragStart", self.StartMoving)
            self:SetScript("OnDragStop", self.StopMovingOrSizing)
            
            -- Add icons for the favorite and broadcast columns.
            self:InitializeFavoriteIconFrame()
            self:InitializeAnnounceIconFrame()
            
            -- Create a reset button.
            self:InitializeReloadButton()
            self:InitializeCloseButton()
            self:SetClampedToScreen(true)
            
            -- Enforce the user-defined scale of the window.
            self:SetScale(self.db.global.window_scale)
            
            self:Hide()
        end
    end
end



    