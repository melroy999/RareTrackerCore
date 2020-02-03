-- Redefine often used functions locally.
local pairs = pairs

-- ####################################################################
-- ##                       Module Management                        ##
-- ####################################################################

-- Register that a zone module exists.
function RT:RegisterZoneModule(module)
    self.zone_modules[#RT.zone_modules + 1] = module
    module.module_loaded = false
    
    -- Add default decoration functions.
    self:AddDefaultCommunicationFunctions(module)
    self.AddDefaultEventHandlerFunctions(module)
    self:AddDefaultInterfaceFunctions(module)
end

-- Perform all actions that can only be done after a module has been loaded.
function RT:NotifyZoneModuleLoaded(module)
    for key, _ in pairs(module.target_zones) do
        self.zone_id_to_module[key] = module
    end
    
    module:AddModuleOptions(self.options_table.args)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("RareTrackerCore", self.options_table)
    
    self:OnZoneTransition()
end