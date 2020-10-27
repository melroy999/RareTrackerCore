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
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                        Interface Control                       ##
-- ####################################################################

-- Prepare the window's data and show it on the screen.
function RareTracker:OpenWindow()
    self:Debug("Opening Window")
    
    -- Update the data to coincide with the currenly tracked content.
    self:UpdateShardNumber()
    
    -- TODO
    
    -- Show the window if it is not hidden.
    if not self.db.global.window.hide then
        self.gui:Show()
    end
end

-- Close the window and do cleanup.
function RareTracker:CloseWindow()
    self:Debug("Closing Window")
    
    -- Simply hide the interface.
    self.gui:Hide()
end

-- ####################################################################
-- ##                Rare Entity Window Update Functions             ##
-- ####################################################################

-- Update the shard number in the shard number display.
function RareTracker:UpdateShardNumber()
    if self.shard_id then
        self.gui.shard_id_frame.status_text:SetText(string.format(L["Shard ID: %s"], self.shard_id))
    else
        self.gui.shard_id_frame.status_text:SetText(string.format(L["Shard ID: %s"], L["Unknown"]))
    end
end

-- Update the status for the given entity.
function RareTracker:UpdateStatus(npc_id)
    local f = self.gui.entities_frame.entities[npc_id]

    if self.current_health[npc_id] then
        f.status:SetText(self.current_health[npc_id].."%")
        f.status:SetFontObject("GameFontGreen")
        f.announce.texture:SetColorTexture(0, 1, 0, 1)
    elseif self.is_alive[npc_id] then
        f.status:SetText("N/A")
        f.status:SetFontObject("GameFontGreen")
        f.announce.texture:SetColorTexture(0, 1, 0, 1)
    elseif self.last_recorded_death[npc_id] ~= nil then
        local last_death = self.last_recorded_death[npc_id]
        f.status:SetText(math.floor((GetServerTime() - last_death) / 60).."m")
        f.status:SetFontObject("GameFontNormal")
        f.announce.texture:SetColorTexture(0, 0, 1, front_opacity)
    else
        f.status:SetText("--")
        f.status:SetFontObject("GameFontNormal")
        f.announce.texture:SetColorTexture(0, 0, 0, front_opacity)
    end
end

-- Update the daily kill mark of the given entity.
function RareTracker:UpdateDailyKillMark(npc_id, primary_id)
    -- Not all npcs have a completion quest.
    local quest_id = self.primary_id_to_data[primary_id].entities[npc_id].quest_id
    if not quest_id then return end
    
    -- Multiple NPCs might share the same quest id.
    local npc_ids = self.completion_quest_to_npc_ids[quest_id]
    local is_completed = IsQuestFlaggedCompleted(quest_id)
    
    for _, target_npc_id in pairs(npc_ids) do
        local f = self.gui.entities_frame.entities[target_npc_id].name
        f:SetFontObject((is_completed and "GameFontRed") or "GameFontNormal")
    end
end

-- Update the daily kill marks of all the currently tracked entities.
function RareTracker:UpdateAllDailyKillMarks()
    local primary_id = self.last_zone_id
    for _, npc_id in pairs(self.primary_id_to_data[primary_id].entities) do
        self:UpdateDailyKillMark(npc_id, primary_id)
    end
end

-- ####################################################################
-- ##                          Initialization                        ##
-- ####################################################################

-- Create an entry within the entity frame for the given entity.
function RareTracker:InitializeRareTableEntry(npc_id, rare_data, parent)
    local f = CreateFrame("Frame", string.format("%s.entities_frame.entities[%s]", self.addon_code, npc_id), parent)
    f:SetSize(entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width, 12)
    
    -- Create the favorite button.
    f.favorite = CreateFrame("CheckButton", string.format("%s.entities_frame.entities[%s].favorite", self.addon_code, npc_id), f)
    f.favorite:SetSize(10, 10)
    f.favorite:SetPoint("TOPLEFT", 1, 0)
    
    f.favorite.texture = f.favorite:CreateTexture(nil, "BACKGROUND")
    f.favorite.texture:SetColorTexture(0, 0, 0, front_opacity)
    f.favorite.texture:SetAllPoints(f.favorite)
    
     -- Add an action listener.
    f.favorite:SetScript("OnClick", function()
        if self.db.global.favorite_rares[npc_id] then
            self.db.global.favorite_rares[npc_id] = nil
            f.favorite.texture:SetColorTexture(0, 0, 0, front_opacity)
        else
            self.db.global.favorite_rares[npc_id] = true
            f.favorite.texture:SetColorTexture(0, 1, 0, 1)
        end
        self:NotifyOptionsChange()
    end)

    -- Add a button that announces the rare/adds a waypoint when applicable.
    -- Add the announce/waypoint button.
    f.announce = CreateFrame("Button", string.format("%s.entities_frame.entities[%s].announce", self.addon_code, npc_id), f)
    f.announce:SetSize(10, 10)
    f.announce:SetPoint("TOPLEFT", frame_padding + favorite_rares_width + 1, 0)
    
    f.announce.texture = f.announce:CreateTexture(nil, "BACKGROUND")
    f.announce.texture:SetColorTexture(0, 0, 0, front_opacity)
    f.announce.texture:SetAllPoints(f.announce)
    
    f.announce:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    f.announce:SetScript("OnClick", function(_, button)
        local name = self.rare_names[npc_id]
        local health = self.current_health[npc_id]
        local last_death = self.last_recorded_death[npc_id]
        local loc = self.current_coordinates[npc_id]
        
        if button == "LeftButton" then
            -- The default target is general chat.
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
            
            -- Send the message.
            self:ReportRareInChat(target, name, health, last_death, loc)
        else
            -- Does the user have tom tom? if so, add a waypoint if it exists.
            if TomTom ~= nil and loc and not self.waypoints[npc_id] then
                self.waypoints[npc_id] = TomTom:AddWaypointToCurrentZone(loc.x, loc.y, name)
            end
        end
    end)

    -- Add the entities name.
    f.name = f:CreateFontString(nil, nil, "GameFontNormal")
    f.name:SetPoint("TOPLEFT", 2 * frame_padding + 2 * favorite_rares_width + 10, 0)
    f.name:SetJustifyH("LEFT")
    f.name:SetJustifyV("TOP")
    f.name:SetText(rare_data.name)
    
    -- Add the timer/health entry.
    f.status = f:CreateFontString(nil, nil, "GameFontNormal")
    f.status:SetSize(entity_status_width, 12)
    f.status:SetPoint("TOPRIGHT", 0, 0)
    f.status:SetText("--")
    f.status:SetJustifyH("MIDDLE")
    f.status:SetJustifyV("TOP")
    
    parent.entities[npc_id] = f
end

-- Initialize the rare table frame.
function RareTracker:InitializeRareTableFrame(parent)
    -- First, add the frames for the backdrop and make sure that the hierarchy is created.
    local f = CreateFrame("Frame", string.format("%s.entities_frame", self.addon_code), parent)
    f:SetPoint("TOPLEFT", frame_padding, -(2 * frame_padding + shard_id_frame_height))
    
    f.entity_name_backdrop = CreateFrame("Frame", string.format("%s.entities_frame.entity_name_backdrop", self.addon_code), f)
    f.entity_name_backdrop:SetPoint("TOPLEFT", f, 2 * frame_padding + 2 * favorite_rares_width, 0)
    
    f.entity_name_backdrop.texture = f.entity_name_backdrop:CreateTexture(nil, "BACKGROUND")
    f.entity_name_backdrop.texture:SetColorTexture(0, 0, 0, front_opacity)
    f.entity_name_backdrop.texture:SetAllPoints(f.entity_name_backdrop)
    
    f.entity_status_backdrop = CreateFrame("Frame", string.format("%s.entities_frame.entity_status_backdrop", self.addon_code), f)
    f.entity_status_backdrop:SetPoint("TOPRIGHT", f, 0, 0)
    
    f.entity_status_backdrop.texture = f.entity_status_backdrop:CreateTexture(nil, "BACKGROUND")
    f.entity_status_backdrop.texture:SetColorTexture(0, 0, 0, front_opacity)
    f.entity_status_backdrop.texture:SetAllPoints(f.entity_status_backdrop)
    
    -- Next, create frames for all rares in the table.
    f.entities = {}
    
    -- Create a frame entry for all of the NPC ids, even the ignored ones.
    -- The ordering and hiding of rares will be done later.
    for _, data in pairs(self.primary_id_to_data) do
        for npc_id, rare_data in pairs(data.entities) do
            self:InitializeRareTableEntry(npc_id, rare_data, f)
        end
    end
    
    -- Arrange the table such that it fits the user's wishes. Resize the frames appropriately.
    -- TODO self:ReorganizeRareTableFrame(f)
    
    parent.entities_frame = f
end

-- Display the current shard number at the top of the frame.
function RareTracker:InitializeShardNumberFrame(parent)
    local f = CreateFrame("Frame", string.format("%s.shard_id_frame", self.addon_code), parent)
    local width = entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width
    local height = shard_id_frame_height
    f:SetSize(width, height)
    f:SetPoint("TOPLEFT", parent, frame_padding, -frame_padding)
  
    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetColorTexture(0, 0, 0, front_opacity)
    f.texture:SetAllPoints(f)
    
    f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
    f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -3)
    f.status_text:SetText(string.format(L["Shard ID: %s"], L["Unknown"]))
    
    parent.shard_id_frame = f
end

-- Initialize the favorite icon in the rare entities frame.
function RareTracker:InitializeFavoriteIconFrame(parent)
    local f = CreateFrame("Frame", string.format("%s.favorite_icon", self.addon_code), parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPLEFT", parent, frame_padding + 1, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetTexture("Interface\\AddOns\\RareTracker\\Icons\\Favorite.tga")
    f.texture:SetSize(10, 10)
    f.texture:SetPoint("CENTER", f)
    
    -- TODO implement tooltip.
    parent.favorite_icon = f
end

-- Initialize the alternating announce icon in the rare entities frame.
function RareTracker:InitializeAnnounceIconFrame(parent)
    local f = CreateFrame("Frame", string.format("%s.broadcast_icon", self.addon_code), parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPLEFT", parent, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetTexture("Interface\\AddOns\\RareTracker\\Icons\\Broadcast.tga")
    f.texture:SetSize(10, 10)
    f.texture:SetPoint("CENTER", f)
    
    f.icon_state = false
    
    -- TODO implement tooltip.
    
    parent.broadcast_icon = f
end

-- Initialize the reload button in the rare entities frame.
function RareTracker:InitializeReloadButton(parent)
    local f = CreateFrame("Button", string.format("%s.reload_button", self.addon_code), parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPRIGHT", parent, -3 * frame_padding - favorite_rares_width, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetTexture("Interface\\AddOns\\RareTracker\\Icons\\Reload.tga")
    f.texture:SetSize(10, 10)
    f.texture:SetPoint("CENTER", f)
    
    -- TODO implement reload button and tooltips.
    f:SetScript("OnClick", function() end)
    
    parent.reload_button = f
end

-- Initialize the close button in the rare entities frame.
function RareTracker:InitializeCloseButton(parent)
    local f = CreateFrame("Button", string.format("%s.close_button", self.addon_code), parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPRIGHT", parent, -2 * frame_padding, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetTexture("Interface\\AddOns\\RareTracker\\Icons\\Cross.tga")
    f.texture:SetSize(10, 10)
    f.texture:SetPoint("CENTER", f)
    
    f:SetScript("OnClick", function()
        parent:Hide()
        self.db.global.window.hide = true
    end)

    parent.close_button = f
end

-- Initialize the addon's entity frame.
function RareTracker:InitializeInterface()
    local f = CreateFrame("Frame", self.addon_code, UIParent)
    
    f:SetSize(
        entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding,
        shard_id_frame_height + 2 * frame_padding
    )
    f:SetPoint("CENTER")
            
    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetColorTexture(0, 0, 0, background_opacity)
    f.texture:SetAllPoints(f)
    
    -- Create a sub-frame for the entity names.
    self:InitializeShardNumberFrame(f)
    self:InitializeRareTableFrame(f)
    
    -- Add icons for the favorite and broadcast columns.
    self:InitializeFavoriteIconFrame(f)
    self:InitializeAnnounceIconFrame(f)
    
    -- Create a reset button.
    self:InitializeReloadButton(f)
    self:InitializeCloseButton(f)
    
    -- Make the window moveable and ensure that the window stays where the user puts it.
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    -- Enforce the user-defined scale of the window.
    f:SetScale(self.db.global.window_scale)
    
    -- The default state of the window is hidden.
    f:Hide()
    
    self.gui = f
end