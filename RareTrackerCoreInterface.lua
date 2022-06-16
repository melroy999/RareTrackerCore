-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local IsLeftControlKeyDown = IsLeftControlKeyDown
local IsRightControlKeyDown = IsRightControlKeyDown
local UnitInRaid = UnitInRaid
local IsLeftAltKeyDown = IsLeftAltKeyDown
local IsRightAltKeyDown = IsRightAltKeyDown
local GetServerTime = GetServerTime
local GetTime = GetTime
local C_QuestLog = C_QuestLog
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local pairs = pairs
local print = print
local wipe = wipe

-- Redefine global variables locally.
local string = string
local UIParent = UIParent

-- Width and height variables used to customize the window.
local entity_name_width = 208
local entity_status_width = 50
local frame_padding = 4
local favorite_rares_width = 10
local shard_id_frame_height = 16

-- Values for the opacity of the background and foreground.
local background_opacity = 0.4
local foreground_opacity = 0.6

-- The list of currently tracked npcs. Used for cleanup.
local target_npc_ids = {}

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
    -- Update all the kill marks. Also make a delayed call in case the quest marks aren't loaded.
    self:UpdateAllDailyKillMarks()
    self:DelayedExecution(3, function() self:UpdateAllDailyKillMarks() end)
    
    -- Show the window if it is not hidden.
    if not self.db.global.window.hide then
        self.gui:Show()
    end
end

-- Close the window and do cleanup.
function RareTracker:CloseWindow()
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
    elseif self.last_recorded_death[npc_id] then
        local last_death, _ = unpack(self.last_recorded_death[npc_id])
        local current_time = GetServerTime()
        local minutes = math.floor((current_time - last_death) / 60)
        if self.db.global.window.show_time_in_seconds then
            local seconds = (current_time - last_death) % 60
            f.status:SetText(minutes..":"..string.format("%02d", seconds))
        else
            f.status:SetText(minutes.."m")
        end
        f.status:SetFontObject("GameFontNormal")
        f.announce.texture:SetColorTexture(0, 0, 1, foreground_opacity)
    else
        f.status:SetText("--")
        f.status:SetFontObject("GameFontNormal")
        f.announce.texture:SetColorTexture(0, 0, 0, foreground_opacity)
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
    local primary_id = self.zone_id
    if primary_id then
        for npc_id, _ in pairs(self.primary_id_to_data[primary_id].entities) do
            self:UpdateDailyKillMark(npc_id, primary_id)
        end

        -- Update the visibility of entities.
        self:UpdateEntityVisibility()
    end
end

-- Update the visibility of rares in the entity frame based on the used settings.
function RareTracker:UpdateEntityVisibility()
    local f = self.gui.entities_frame
    
    -- Do not continue if the required information is unavailable.
    local primary_id = self.zone_id
    if not primary_id or not self.primary_id_to_data[primary_id] then return end
    
    -- Show and hide entities based on the used settings.
    local n = 0
    for _, npc_id in pairs(self.primary_id_to_data[primary_id].ordering) do
        -- Note: ignored rares are already removed from the list by the update display list function.
        if target_npc_ids[npc_id] then
            if self.db.global.window.hide_killed_entities then
                -- Find the quest id and hide the entry if already killed today.
                local quest_id = self.primary_id_to_data[primary_id].entities[npc_id].quest_id
                if quest_id and IsQuestFlaggedCompleted(quest_id) then
                    -- Hide the entity, since it has been killed already.
                    f.entities[npc_id]:Hide()
                else
                    -- Display the entity.
                    f.entities[npc_id]:SetPoint("TOPLEFT", f, 0, -n * 12 - 5)
                    f.entities[npc_id]:Show()
                    n = n + 1
                end
            else
                -- Display the entity.
                f.entities[npc_id]:SetPoint("TOPLEFT", f, 0, -n * 12 - 5)
                f.entities[npc_id]:Show()
                n = n + 1
            end
        end
    end
  
    -- Resize the appropriate frames.
    self:UpdateEntityFrameDimensions(n, f)
end

-- Update the data that is displayed to apply to the current zone and other parameters.
function RareTracker:UpdateDisplayList()
    -- Hide all frames that are currently marked as visible.
    local f = self.gui.entities_frame
    for npc_id, _ in pairs(target_npc_ids) do
        f.entities[npc_id]:Hide()
    end
    
    -- If no data is present for the given zone, then there are no targets.
    wipe(target_npc_ids)
    local primary_id = self.zone_id
    if primary_id and self.primary_id_to_data[primary_id] then
        -- Gather the candidate npc ids, using the plugin provider when defined.
        if self.primary_id_to_data[primary_id].SelectTargetEntities then
            self.primary_id_to_data[primary_id].SelectTargetEntities(self, target_npc_ids)
        else
            for npc_id, _ in pairs(self.primary_id_to_data[primary_id].entities) do
                target_npc_ids[npc_id] = true
            end
        end

        -- Filter out all ignored entities and count the number of entries we will have in total.
        -- Give all of the table entries their new positions and show them when appropriate.
        local n = 0
        for _, npc_id in pairs(self.primary_id_to_data[primary_id].ordering) do
            if target_npc_ids[npc_id] then
                if self.db.global.ignored_rares[npc_id] then
                    target_npc_ids[npc_id] = nil
                else
                    f.entities[npc_id]:SetPoint("TOPLEFT", f, 0, -n * 12 - 5)
                    f.entities[npc_id]:Show()
                    n = n + 1
                end
            end
        end
        
        -- Resize the appropriate frames.
        self:UpdateEntityFrameDimensions(n, f)
    end
end

-- Resize the entities portion of the tracking window.
function RareTracker:UpdateEntityFrameDimensions(n, f)
    self.gui:SetSize(
        entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding,
        shard_id_frame_height + 3 * frame_padding + n * 12 + 8
    )
    
    f:SetSize(
        entity_name_width + entity_status_width + 2 * favorite_rares_width + 3 * frame_padding,
        n * 12 + 8
    )
    f.entity_name_backdrop:SetSize(entity_name_width, f:GetHeight())
    f.entity_status_backdrop:SetSize(entity_status_width, f:GetHeight())
end

-- Ensure that all the favorite marks of the entities are set correctly.
function RareTracker:CorrectFavoriteMarks()
    for npc_id, _ in pairs(self.tracked_npc_ids) do
        if self.db.global.favorite_rares[npc_id] then
            self.gui.entities_frame.entities[npc_id].favorite.texture:SetColorTexture(0, 1, 0, 1)
        else
            self.gui.entities_frame.entities[npc_id].favorite.texture:SetColorTexture(0, 0, 0, foreground_opacity)
        end
    end
end

-- Update the status of all npcs that are currently being tracked.
function RareTracker:UpdateStatusTrackedEntities()
    for npc_id, _ in pairs(target_npc_ids) do
        -- It might occur that the rare is marked as alive, but no health is known.
        -- If two minutes pass without a health value, the alive tag will be reset.
        if self.is_alive[npc_id] and GetServerTime() - self.is_alive[npc_id] > 120 then
            self.is_alive[npc_id] = nil
            self.current_health[npc_id] = nil
            self.reported_spawn_uids[npc_id] = nil
            self.current_coordinates[npc_id] = nil
        end
        
        self:UpdateStatus(npc_id)
    end
end

-- Switch between the report and waypoint icons.
function RareTracker.CycleReportWaypointIcon(f)
    f.icon_state = not f.icon_state
                
    if f.icon_state then
        f.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Broadcast.tga")
    else
        f.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Waypoint.tga")
    end
end

-- ####################################################################
-- ##                          Initialization                        ##
-- ####################################################################

-- Create an entry within the entity frame for the given entity.
function RareTracker:InitializeRareTableEntry(npc_id, rare_data, parent)
    local f = CreateFrame("Frame", string.format("RT.entities_frame.entities[%s]", npc_id), parent)
    f:SetSize(entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width, 12)
    
    -- Create the favorite button.
    f.favorite = CreateFrame("CheckButton", string.format("RT.entities_frame.entities[%s].favorite", npc_id), f)
    f.favorite:SetSize(10, 10)
    f.favorite:SetPoint("TOPLEFT", 1, 0)
    
    f.favorite.texture = f.favorite:CreateTexture(nil, "BACKGROUND")
    f.favorite.texture:SetColorTexture(0, 0, 0, foreground_opacity)
    f.favorite.texture:SetAllPoints(f.favorite)
    
     -- Add an action listener.
    f.favorite:SetScript("OnClick", function()
        if self.db.global.favorite_rares[npc_id] then
            self.db.global.favorite_rares[npc_id] = nil
            f.favorite.texture:SetColorTexture(0, 0, 0, foreground_opacity)
        else
            self.db.global.favorite_rares[npc_id] = true
            f.favorite.texture:SetColorTexture(0, 1, 0, 1)
        end
        self.NotifyOptionsChange()
    end)

    -- Add a button that announces the rare/adds a waypoint when applicable.
    -- Add the announce/waypoint button.
    f.announce = CreateFrame("Button", string.format("RT.entities_frame.entities[%s].announce", npc_id), f)
    f.announce:SetSize(10, 10)
    f.announce:SetPoint("TOPLEFT", frame_padding + favorite_rares_width + 1, 0)
    
    f.announce.texture = f.announce:CreateTexture(nil, "BACKGROUND")
    f.announce.texture:SetColorTexture(0, 0, 0, foreground_opacity)
    f.announce.texture:SetAllPoints(f.announce)
    
    f.announce:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    f.announce:SetScript("OnClick", function(_, button)
        local name = rare_data.name
        local health = self.current_health[npc_id]
        local last_death = nil
        if self.last_recorded_death[npc_id] then
            last_death, _ = unpack(self.last_recorded_death[npc_id])
        end
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
            self:ReportRareInChat(npc_id, target, name, health, last_death, loc)
        else
            -- Put down a waypoint.
            local loc = self.current_coordinates[npc_id] or self.primary_id_to_data[self.zone_id].entities[npc_id].coordinates
            if loc then
                if IsLeftAltKeyDown() or IsRightAltKeyDown() then
                    self:ReportRareCoordinatesInChat(npc_id, "CHANNEL", name, loc)
                elseif IsLeftControlKeyDown() or IsRightControlKeyDown() then
                    local target = "PARTY"
                    if UnitInRaid("player") then
                        target = "RAID"
                    end
                    self:ReportRareCoordinatesInChat(npc_id, target, name, loc)
                else
                    local x, y = unpack(loc)
                    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(self.zone_id, x/100, y/100))
                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                end
            end
        end
    end)

    -- Add the entities name.
    f.name = f:CreateFontString(nil, nil, "GameFontNormal")
    f.name:SetSize(entity_name_width, 12)
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
    local f = CreateFrame("Frame", "RT.entities_frame", parent)
    f:SetPoint("TOPLEFT", frame_padding, -(2 * frame_padding + shard_id_frame_height))
    
    f.entity_name_backdrop = CreateFrame("Frame", "RT.entities_frame.entity_name_backdrop", f)
    f.entity_name_backdrop:SetPoint("TOPLEFT", f, 2 * frame_padding + 2 * favorite_rares_width, 0)
    
    f.entity_name_backdrop.texture = f.entity_name_backdrop:CreateTexture(nil, "BACKGROUND")
    f.entity_name_backdrop.texture:SetColorTexture(0, 0, 0, foreground_opacity)
    f.entity_name_backdrop.texture:SetAllPoints(f.entity_name_backdrop)
    
    f.entity_status_backdrop = CreateFrame("Frame", "RT.entities_frame.entity_status_backdrop", f)
    f.entity_status_backdrop:SetPoint("TOPRIGHT", f, 0, 0)
    
    f.entity_status_backdrop.texture = f.entity_status_backdrop:CreateTexture(nil, "BACKGROUND")
    f.entity_status_backdrop.texture:SetColorTexture(0, 0, 0, foreground_opacity)
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
    
    -- Ensure that the data in the window updates periodically.
    f.last_display_update = GetTime()
    f:SetScript("OnUpdate", function()
        if f.last_display_update + 1 < GetTime() then
            f.last_display_update = GetTime()
            self:UpdateStatusTrackedEntities()
        end
    end)
    
    parent.entities_frame = f
end

-- Display the current shard number at the top of the frame.
function RareTracker.InitializeShardNumberFrame(parent)
    local f = CreateFrame("Frame", "RT.shard_id_frame", parent)
    local width = entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width
    local height = shard_id_frame_height
    f:SetSize(width, height)
    f:SetPoint("TOPLEFT", parent, frame_padding, -frame_padding)
  
    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetColorTexture(0, 0, 0, foreground_opacity)
    f.texture:SetAllPoints(f)
    
    f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
    f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -3)
    f.status_text:SetText(string.format(L["Shard ID: %s"], L["Unknown"]))
    
    parent.shard_id_frame = f
end

-- Initialize the favorite icon in the rare entities frame.
function RareTracker.InitializeFavoriteIconFrame(parent)
    local f = CreateFrame("Frame", "RT.favorite_icon", parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPLEFT", parent, frame_padding + 1, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetSize(10, 10)
    f.texture:SetPoint("CENTER", f)
    f.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Favorite.tga")

    parent.favorite_icon = f
end

-- Initialize the alternating announce icon in the rare entities frame.
function RareTracker:InitializeAnnounceIconFrame(parent)
    local f = CreateFrame("Frame", "RT.broadcast_icon", parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPLEFT", parent, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetSize(10, 10)
    f.texture:SetPoint("CENTER", f)
    f.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Broadcast.tga")
    
    -- Make the icon swap periodically by adding an update handler.
    f.icon_state = false
    f.last_icon_change = GetTime()
    f:SetScript("OnUpdate", function()
        if f.last_icon_change + 2 < GetTime() then
            f.last_icon_change = GetTime()
            self.CycleReportWaypointIcon(f)
        end
    end)
    
    parent.broadcast_icon = f
end

-- Initialize the close button in the rare entities frame.
function RareTracker:InitializeInfoButton(parent)
    local f = CreateFrame("Button", "RT.info_button", parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPRIGHT", parent, -3 * frame_padding - favorite_rares_width, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Info.tga")
    f.texture:SetSize(10, 10)
    f.texture:SetPoint("CENTER", f)
    
    f:SetScript("OnClick", function()
        InterfaceOptionsFrame_Show()
        InterfaceOptionsFrame_OpenToCategory(self.info_frame)
    end)

    parent.info_button = f
end

-- Initialize the close button in the rare entities frame.
function RareTracker:InitializeCloseButton(parent)
    local f = CreateFrame("Button", "RT.close_button", parent)
    f:SetSize(10, 10)
    f:SetPoint("TOPRIGHT", parent, -2 * frame_padding, -(frame_padding + 3))

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetTexture("Interface\\AddOns\\RareTrackerCore\\Icons\\Cross.tga")
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
    local f = self.gui
    
    f:SetSize(
        entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding,
        shard_id_frame_height + 2 * frame_padding
    )
    if self.db.global.window.position then
        local anchor, x, y = unpack(self.db.global.window.position)
        f:SetPoint(anchor, x, y)
    else
        f:SetPoint("CENTER")
    end
            
    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetColorTexture(0, 0, 0, background_opacity)
    f.texture:SetAllPoints(f)
    
    -- Create a sub-frame for the entity names.
    self.InitializeShardNumberFrame(f)
    self:InitializeRareTableFrame(f)
    
    -- Add icons for the favorite and broadcast columns.
    self.InitializeFavoriteIconFrame(f)
    self:InitializeAnnounceIconFrame(f)
    
    -- Create an info and close button.
    self:InitializeInfoButton(f)
    self:InitializeCloseButton(f)
    
    -- Make the window moveable and ensure that the window stays where the user puts it.
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(_f)
        _f:StopMovingOrSizing()
        local _, _, anchor, x, y = _f:GetPoint()
        self.db.global.window.position = {anchor, x, y}
        self:Debug("New frame position", anchor, x, y)
    end)
    
    -- Enforce the user-defined scale of the window.
    f:SetScale(self.db.global.window.scale)
    
    -- The default state of the window is hidden.
    f:Hide()
end