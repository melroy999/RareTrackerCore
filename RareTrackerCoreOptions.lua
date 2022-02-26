-- Redefine often used functions locally.
local InterfaceOptionsFrame_Show = InterfaceOptionsFrame_Show
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local PlaySoundFile = PlaySoundFile
local pairs = pairs
local tinsert = tinsert

-- Redefine often used variables locally.
local C_Map = C_Map

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

-- Get an incremental order index to enforce the ordering of options.
RareTracker.current_order_index = 0
function RareTracker:GetOrder()
    self.current_order_index = self.current_order_index + 1
    return self.current_order_index
end

-- Refresh the option menu.
function RareTracker.NotifyOptionsChange()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("RareTracker")
end

-- ####################################################################
-- ##                             Options                            ##
-- ####################################################################

-- The provided sound options.
local sound_options = {
    [-1] = "",
    [566121] = "Rubber Ducky",
    [566543] = "Cartoon FX",
    [566982] = "Explosion",
    [566240] = "Shing!",
    [566946] = "Wham!",
    [566076] = "Simon Chime",
    [567275] = "War Drums",
    [567386] = "Scourge Horn",
    [566508] = "Pygmy Drums",
    [567283] = "Cheer",
    [569518] = "Humm",
    [568975] = "Short Circuit",
    [569215] = "Fel Portal",
    [568582] = "Fel Nova",
    [569200] = "PVP Flag",
    [543587] = "Beware!",
    [564859] = "Laugh",
    [552503] = "Not Prepared",
    [554554] = "I am Unleashed",
    [554236] = "I see you",
}

local sound_channel_options = {
    ["SFX"] = "SFX",
    ["Master"] = "Master",
    ["Music"] = "Music",
    ["Ambience"] = "Ambience",
    ["Dialog"] = "Dialog",
}


-- Initialize the minimap button.
function RareTracker:InitializeRareTrackerLDB()
    self.ldb_data = {
        type = "data source",
        text = "RT",
        icon = "Interface\\AddOns\\RareTrackerCore\\Icons\\RareTrackerIcon",
        OnClick = function(_, button)
            if button == "LeftButton" then
                local zone_id = C_Map.GetBestMapForUnit("player")
                if zone_id and self.zone_id_to_primary_id[zone_id] then
                    if self.gui:IsShown() then
                        self.gui:Hide()
                        self.db.global.window.hide = true
                    else
                        self.gui:Show()
                        self.db.global.window.hide = false
                    end
                else
                    print(L["<RT> The rare window cannot be shown, since the current zone is not covered by any of the zone modules."])
                end
            else
                InterfaceOptionsFrame_Show()
                InterfaceOptionsFrame_OpenToCategory(self.options_frame)
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("RareTracker")
            tooltip:AddLine(L["Left-click: hide/show RT"], 1, 1, 1)
            tooltip:AddLine(L["Right-click: show options"], 1, 1, 1)
            tooltip:Show()
        end
    }
    self.ldb = LibStub("LibDataBroker-1.1"):NewDataObject("RareTracker", self.ldb_data)
    
    -- Register the icon.
    self.icon = LibStub("LibDBIcon-1.0")
    self.icon:Register("RareTrackerIcon", self.ldb, self.db.profile.minimap)
    if self.db.profile.minimap.hide then
        self.icon:Hide("RareTrackerIcon")
    end
end

-- Initialize the options menu for the addon.
function RareTracker:InitializeOptionsMenu()
    self.options_table = {
        name = "RareTracker (RTC)",
        handler = RareTracker,
        type = 'group',
        childGroups = "tree",
        order = self:GetOrder(),
        args = {
            general = {
                type = "group",
                name = L["General"],
                order = self:GetOrder(),
                args = {
                    general = {
                        type = "group",
						name = L["Shared Options"],
						order = self:GetOrder(),
						inline = true,
                        args = {
                            minimap = {
                                type = "toggle",
                                name = L["Show minimap icon"],
                                desc = L["Show/hide the RT minimap icon."],
                                width = "full",
                                order = self:GetOrder(),
                                get = function()
                                    return not self.db.profile.minimap.hide
                                end,
                                set = function(_, val)
                                    self.db.profile.minimap.hide = not val
                                    if self.db.profile.minimap.hide then
                                        self.icon:Hide("RareTrackerIcon")
                                    else
                                        self.icon:Show("RareTrackerIcon")
                                    end
                                end
                            },
                            communication = {
                                type = "toggle",
                                name = L["Enable communication over party/raid channel"],
                                desc = L["Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."],
                                width = "full",
                                order = self:GetOrder(),
                                get = function()
                                    return self.db.global.communication.raid_communication
                                end,
                                set = function(_, val)
                                    self.db.global.communication.raid_communication = val
                                end
                            },
                            hide_killed_entities = {
                                type = "toggle",
                                name = L["Hide rares that have already been killed today"],
                                desc = L["Do not display rares in the list that will no longer yield any loot due to having already been killed today."],
                                width = "full",
                                order = self:GetOrder(),
                                get = function()
                                    return self.db.global.window.hide_killed_entities
                                end,
                                set = function(_, val)
                                    self.db.global.window.hide_killed_entities = val
                                    self:UpdateEntityVisibility()
                                end
                            },
                            debug = {
                                type = "toggle",
                                name = L["Enable debug mode"],
                                desc = L["Show RT debug output in the chat."],
                                width = "full",
                                order = self:GetOrder(),
                                get = function()
                                    return self.db.global.debug.enable
                                end,
                                set = function(_, val)
                                    self.db.global.debug.enable = val
                                end
                            },
                            window_scale = {
                                type = "range",
                                name = L["Rare window scale"],
                                desc = L["Set the scale of the rare window."],
                                min = 0.5,
                                max = 2,
                                step = 0.05,
                                isPercent = true,
                                order = self:GetOrder(),
                                width = 1.2,
                                get = function()
                                    return self.db.global.window.scale
                                end,
                                set = function(_, val)
                                    self.db.global.window.scale = val
                                    self.gui:SetScale(val)
                                end
                            },
                            favorite_alert = {
                                type = "select",
                                name = L["Favorite sound alert"],
                                style = "dropdown",
                                values = sound_options,
                                order = self:GetOrder(),
                                width = 1.2,
                                get = function()
                                    return self.db.global.favorite_alert.favorite_sound_alert
                                end,
                                set = function(_, val)
                                    self.db.global.favorite_alert.favorite_sound_alert = val
                                    PlaySoundFile(val, self.db.global.favorite_alert.favorite_alert_sound_channel)
                                end
                            },
                            favorite_alert_sound_channel = {
                                type = "select",
                                name = L["Favorite sound alert channel"],
                                style = "dropdown",
                                values = sound_channel_options,
                                order = self:GetOrder(),
                                width = 1.2,
                                get = function()
                                    return self.db.global.favorite_alert.favorite_alert_sound_channel
                                end,
                                set = function(_, val)
                                    self.db.global.favorite_alert.favorite_alert_sound_channel = val
                                end
                            }
                        }
                    }
                }
            }
        }
    }
    
    -- Group the plugins by plugin name.
    local plugin_to_primary_ids = {}
    for primary_id, rare_data in pairs(self.primary_id_to_data) do
        if not plugin_to_primary_ids[rare_data.plugin_name] then
            plugin_to_primary_ids[rare_data.plugin_name] = {}
        end
        tinsert(plugin_to_primary_ids[rare_data.plugin_name], primary_id)
    end
    
    -- Sort each of the lists on alphabetical order.
    local plugin_index_table = {}
    for plugin_name, primary_ids in pairs(plugin_to_primary_ids) do
        table.sort(primary_ids, function(a, b)
            return self.primary_id_to_data[a].zone_name < self.primary_id_to_data[b].zone_name
        end)
        tinsert(plugin_index_table, plugin_name)
    end
    table.sort(plugin_index_table)
    
    -- Add the options for the plugins.
    for _, plugin_name in pairs(plugin_index_table) do
        self:InitializeOptionsMenuForPlugin(plugin_name, plugin_to_primary_ids[plugin_name])
    end
    
    -- Register the options.
    LibStub("AceConfig-3.0"):RegisterOptionsTable("RareTracker", self.options_table)
    self.options_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RareTracker", "RareTracker")
    
    -- Create a pane with info/instructions on how to use the addon.
    self.info_table = {
        name = L["User Manual"],
        handler = RareTracker,
        type = 'group',
        childGroups = "tree",
        order = self:GetOrder(),
        args = {
            general_description_1 = {
                name = L["The RareTracker addon relies on a peer to peer network, and as such, it will require multiple players to be using the addon simultaneously to work optimally. The communication component activates once the the player has targeted a non-player entity, or when a combat log event nearby is processed: this step is required, since it enables the addon to extract an unique identifier for the shard."],
                type = 'description',
                order = self:GetOrder(),
                fontSize = "medium"
            },
            spacer = {
                name = " ",
                type = 'description',
                order = self:GetOrder(),
                fontSize = "medium"
            },
            favorites = {
                name = L["Favorites"],
                type = 'group',
                inline = true,
                order = self:GetOrder(),
                args = {
                    favorite_description_1 = {
                        name = L["A rare can be marked as favorite by [clicking] the leftmost square beside the rare's name. When a rare is marked as favorite, a sound alert is given when the rare is seen by yourself or other players."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    }
                }
            },
            filtering = {
                name = L["Rare Filtering"],
                type = 'group',
                inline = true,
                order = self:GetOrder(),
                args = {
                    filtering_description_1 = {
                        name = L["Rares can be removed from the window by deselecting them in the associated module's option menu. Favorited rares cannot be hidden from the window."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    }
                }
            },
            announcements = {
                name = L["Announcements"],
                type = 'group',
                inline = true,
                order = self:GetOrder(),
                args = {
                    announcement_description_1 = {
                        name = L["Given that not everyone is using the addon, it can be useful to share information with other players through. To report the current status of a rare, you can do the following:"],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    spacer = {
                        name = "",
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "small"
                    },
                    announcement_description_2 = {
                        name = L[" - [Left click] the rightmost square to report to general chat."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    announcement_description_3 = {
                        name = L[" - [Ctrl-left click] the rightmost square to report to the party/raid chat."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    announcement_description_4 = {
                        name = L[" - [Alt-left click] the rightmost square to report to say."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                }
            },
            waypoints = {
                name = L["Waypoints"],
                type = 'group',
                inline = true,
                order = self:GetOrder(),
                args = {
                    waypoint_description_1 = {
                        name = L["In patch 9.0.2, Blizzard has added locational pins that players can share with others."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    spacer = {
                        name = "",
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "small"
                    },
                    waypoint_description_2 = {
                        name = L[" - [Right click] the rightmost square to set a pin on your map."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    waypoint_description_3 = {
                        name = L[" - [Alt-right click] the rightmost square to share a map pin through the general chat."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    waypoint_description_4 = {
                        name = L[" - [Shift-right click] the rightmost square to share a map pin through party/raid chat."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                }
            },
            chat = {
                name = "Chat Commands",
                type = 'group',
                inline = true,
                order = self:GetOrder(),
                args = {
                    chat_description_1 = {
                        name = L[" - [/rtc show] shows the RareTracker window."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    chat_description_2 = {
                        name = L[" - [/rtc hide] hides the RareTracker window."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                    chat_description_3 = {
                        name = L[" - [/rtc refresh] reset your data and replace it with the data of others."],
                        type = 'description',
                        order = self:GetOrder(),
                        fontSize = "medium"
                    },
                }
            },
        }
    }
    
    -- Register the info panel.
    LibStub("AceConfig-3.0"):RegisterOptionsTable("RareTracker-User Manual", self.info_table)
    self.info_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RareTracker-User Manual", "User Manual", "RareTracker")
    
    -- Create a profiles tab.
    -- self.profile_options = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    -- LibStub("AceConfig-3.0"):RegisterOptionsTable("RareTracker-Profiles", self.profile_options)
    -- self.profile_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RareTracker-Profiles", "Profiles", "RareTracker")
end

-- Add the options for the given plugin.
function RareTracker:InitializeOptionsMenuForPlugin(plugin_name, primary_ids)
    local options = self.options_table.args

    -- Add the default options for the given plugin.
    options[plugin_name] = {
        type = "group",
        name = L[plugin_name],
        order = self:GetOrder(),
        args = {
            description = {
                type = "description",
                name = "RareTracker"..self.primary_id_to_data[primary_ids[1]].plugin_name_abbreviation,
                order = self:GetOrder(),
                fontSize = "large",
                width = "full",
            },
            spacer_1 = {
                type = "description",
                name = "",
                order = self:GetOrder(),
                fontSize = "small",
                width = "full",
            },
        }
    }
    
    -- Add menu options defined by the plugins.
    for _, primary_id in pairs(primary_ids) do
        local rare_data = self.primary_id_to_data[primary_id]
        if rare_data.GetOptionsTable then
            for key, option in pairs(rare_data.GetOptionsTable(self)) do
                options[plugin_name].args[key] = option
            end
        end
    end
    
    -- Add the remaining menu options defined per default.
    options[plugin_name].args["enable_all"] = {
        type = "execute",
        name = L["Enable All"],
        desc = L["Enable all rares in the list."],
        order = self:GetOrder(),
        width = 0.75,
        func = function()
            for _, primary_id in pairs(primary_ids) do
                for npc_id, _ in pairs(self.primary_id_to_data[primary_id].entities) do
                    self.db.global.ignored_rares[npc_id] = nil
                end
            end
            self:UpdateDisplayList()
        end
    }
    options[plugin_name].args["disable_all"] = {
        type = "execute",
        name = L["Disable All"],
        desc = L["Disable all non-favorite rares in the list."],
        order = self:GetOrder(),
        width = 0.75,
        func = function(_)
            for _, primary_id in pairs(primary_ids) do
                for npc_id, _ in pairs(self.primary_id_to_data[primary_id].entities) do
                    if self.db.global.favorite_rares[npc_id] ~= true then
                      self.db.global.ignored_rares[npc_id] = true
                    end
                end
            end
            self:UpdateDisplayList()
        end
    }
    options[plugin_name].args["reset_favorites"] = {
        type = "execute",
        name = L["Reset Favorites"],
        desc = L["Reset the list of favorite rares."],
        order = self:GetOrder(),
        width = 0.75,
        func = function()
            for _, primary_id in pairs(primary_ids) do
                for npc_id, _ in pairs(self.primary_id_to_data[primary_id].entities) do
                    self.db.global.favorite_rares[npc_id] = nil
                end
            end
            self:CorrectFavoriteMarks()
        end
    }
    options[plugin_name].args["ignore"] = {
        type = "group",
        name = L["Active Rares"],
        order = self:GetOrder(),
        inline = true,
        args = {
            -- To be filled dynamically.
        }
    }
    
    -- Add checkboxes for all of the rares.
    for _, primary_id in pairs(primary_ids) do
        for _, npc_id in pairs(self.primary_id_to_data[primary_id].ordering) do
            options[plugin_name].args.ignore.args[""..npc_id] = {
                type = "toggle",
                name = self.primary_id_to_data[primary_id].entities[npc_id].name,
                width = "full",
                order = self:GetOrder(),
                get = function()
                    return not self.db.global.ignored_rares[npc_id]
                end,
                set = function(_, val)
                    if val then
                        self.db.global.ignored_rares[npc_id] = nil
                    else
                        self.db.global.ignored_rares[npc_id] = true
                    end
                    self:UpdateDisplayList()
                end,
                disabled = function()
                    return self.db.global.favorite_rares[npc_id]
                end
            }
        end
    end
end