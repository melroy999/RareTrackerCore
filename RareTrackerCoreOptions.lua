-- Redefine often used functions locally.
local InterfaceOptionsFrame_Show = InterfaceOptionsFrame_Show
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local LibStub = LibStub
local pairs = pairs

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerCore", true)

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

-- Get an incremental order index to enforce the ordering of options.
RT.current_order_index = 0
function RT:GetOrder()
    self.current_order_index = self.current_order_index + 1
    return self.current_order_index
end

-- Refresh the option menu.
function RT:NotifyOptionsChange()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("RareTrackerCore")
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

function RT.GetDefaultModuleDatabaseValues()
    return {
        global = {
            window_scale = 1.0,
            favorite_rares = {},
            previous_records = {},
            ignore_rares = {},
            banned_NPC_ids = {},
            version = 0,
        }
    }
end

function RT:InitializeRareTrackerDatabase()
    self.defaults = {
        global = {
            communication = {
                raid_communication = true,
            },
            debug = {
                enable = false,
            },
            favorite_alert = {
                favorite_sound_alert = 552503,
            },
            window = {
                hide = false,
            }
        },
        profile = {
            minimap = {
                hide = false,
            },
        },
    }
    
    -- Load the database.
    self.db = LibStub("AceDB-3.0"):New("RareTrackerDB", self.defaults, true)
end

function RT:InitializeRareTrackerLDB()
    self.ldb_data = {
        type = "data source",
        text = "RT",
        icon = "Interface\\AddOns\\RareTrackerCore\\Icons\\RareTrackerIcon",
        OnClick = function(_, button)
            if button == "LeftButton" then
                local zone_id = C_Map.GetBestMapForUnit("player")
                if zone_id and self.zone_id_to_module[zone_id] then
                    local module = self.zone_id_to_module[zone_id]
                    if module:IsShown() then
                        module:Hide()
                        self.db.global.window.hide = true
                    else
                        module:Show()
                        self.db.global.window.hide = false
                    end
                else
                    print("<RT> The rare window cannot be shown, since the current zone is not covered by any of the zone modules.")
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
    self.ldb = LibStub("LibDataBroker-1.1"):NewDataObject("RareTrackerCore", self.ldb_data)
    
    -- Register the icon.
    self.icon = LibStub("LibDBIcon-1.0")
    self.icon:Register("RareTrackerIcon", self.ldb, self.db.profile.minimap)
    if self.db.profile.minimap.hide then
        self.icon:Hide("RareTrackerIcon")
    end
end

function RT:InitializeOptionsMenu()
    self.options_table = {
        name = "RareTracker (RT)",
        handler = RT,
        type = 'group',
        childGroups = "tree",
        order = self:GetOrder(),
        args = {
            general = {
                type = "group",
                name = "General",
                order = self:GetOrder(),
                args = {
                    general = {
                        type = "group",
						name = "Shared Options",
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
                                desc = L["Enable communication over party/raid channel, "..
                                    "to provide CRZ functionality while in a party or raid group."],
                                width = "full",
                                order = self:GetOrder(),
                                get = function()
                                    return self.db.global.communication.raid_communication
                                end,
                                set = function(_, val)
                                    self.db.global.communication.raid_communication = val
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
                            favorite_alert = {
                                type = "select",
                                name = L["Favorite sound alert"],
                                style = "dropdown",
                                values = sound_options,
                                order = self:GetOrder(),
                                get = function()
                                    return self.db.global.favorite_alert.favorite_sound_alert
                                end,
                                set = function(_, val)
                                    self.db.global.favorite_alert.favorite_sound_alert = val
                                    PlaySoundFile(val)
                                end
                            },
                        }
                    }
                }
            }
        }
    }
    
    -- Register the options.
    LibStub("AceConfig-3.0"):RegisterOptionsTable("RareTrackerCore", self.options_table)
    self.options_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RareTrackerCore", "RareTracker")
    
    -- Create a profiles tab.
    self.profile_options = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("RareTrackerCore-Profiles", self.profile_options)
    self.profile_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RareTrackerCore-Profiles", "Profiles", "RareTracker")
end