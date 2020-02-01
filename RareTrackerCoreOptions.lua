-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTracker", true)

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

-- Get an incremental order index to enforce the ordering of options.
RT.current_order_index = 0
function RT:GetOrder()
    RT.current_order_index = RT.current_order_index + 1
    return RT.current_order_index
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

local defaults = {
    global = {
        minimap = {
            hide = false,
        },
        communication = {
            raid_communication = true,
        },
        debug = {
            enable = false,
        },
        favorite_alert = {
            favorite_sound_alert = 552503,
        },
    },
}

local ldb_data = {
    type = "data source",
    text = "RT",
    icon = "Interface\\AddOns\\RareTrackerCore\\Icons\\RareTrackerIcon",
    OnClick = function(_, button)
        local i = 0
    end,
    OnTooltipShow = function(tooltip)
        tooltip:SetText("RareTracker")
        tooltip:AddLine(L["Left-click: hide/show RT"], 1, 1, 1)
        tooltip:AddLine(L["Right-click: show options"], 1, 1, 1)
        tooltip:Show()
    end
}

function RT:InitializeRareTrackerDB()
    self.db = LibStub("AceDB-3.0"):New("RareTrackerDB", defaults)
    self.ldb = LibStub("LibDataBroker-1.1"):NewDataObject("RareTracker", ldb_data)
    
    -- Register the icon.
    self.icon = LibStub("LibDBIcon-1.0")
    self.icon:Register("RareTrackerIcon", self.ldb, self.db.profile.minimap)
end

function RT:InitializeOptionsMenu()
    self.options_table = {
        name = "RareTracker",
        handler = RT,
        type = 'group',
        childGroups = "tree",
        order = self.GetOrder(),
        args = {
            general = {
                type = "group",
                name = "General Options",
                order = self.GetOrder(),
                args = {
                    minimap = {
                        type = "toggle",
                        name = "Show minimap icon",
                        desc = "Show/hide the RT minimap icon.",
                        width = "full",
                        order = self.GetOrder(),
                        get = function() 
                            return not self.db.global.minimap.hide 
                        end,
                        set = function(info, val)
                            self.db.global.minimap.hide = not val
                        end
                    },
                    communication = {
                        type = "toggle",
                        name = "Enable communication over party/raid channel",
                        desc = "Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group.",
                        width = "full",
                        order = self.GetOrder(),
                        get = function() 
                            return self.db.global.communication.raid_communication 
                        end,
                        set = function(info, val)
                            self.db.global.communication.raid_communication = val
                        end
                    },
                    debug = {
                        type = "toggle",
                        name = "Enable debug mode",
                        desc = "Show RT debug output in the chat.",
                        width = "full",
                        order = self.GetOrder(),
                        get = function() 
                            return self.db.global.debug.enable
                        end,
                        set = function(info, val)
                            self.db.global.debug.enable = val
                        end
                    },
                    favorite_alert = {
                        type = "select",
                        name = "Favorite sound alert",
                        style = "dropdown",
                        values = sound_options,
                        order = self.GetOrder(),
                        get = function() 
                            return self.db.global.favorite_alert.favorite_sound_alert 
                        end,
                        set = function(info, val)
                            self.db.global.favorite_alert.favorite_sound_alert = val
                        end
                    },
                    -- window_scale = {
                    --     type = "range",
                    --     name = "Rare window scale",
                    --     min = 0.5,
                    --     max = 2,
                    --     step = 0.05,
                    --     order = self.GetOrder(),
                    -- }
                }
            }
        }
    }
    
    -- Register the options.
    LibStub("AceConfig-3.0"):RegisterOptionsTable("RareTracker", self.options_table)
    self.options_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RareTracker", "RareTracker")
end