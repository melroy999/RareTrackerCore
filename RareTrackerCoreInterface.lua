-- Redefine often used functions locally.
local print = print

-- Redefine global variables locally.
local C_ChatInfo = C_ChatInfo
local string = string

-- ####################################################################
-- ##                           Interface                            ##
-- ####################################################################

-- Add the default interface functions.
function RT.AddDefaultInterfaceFunctions(module)
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
            
            if C_ChatInfo.RegisterAddonMessagePrefix(self.addon_code) ~= true then
                print(string.format(
                    "<%s> Failed to register AddonPrefix '%s'. %s will not function properly.",
                    self.addon_code, self.addon_code, self.addon_code
                ))
            end
            
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
    