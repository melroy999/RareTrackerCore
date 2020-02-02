-- ####################################################################
-- ##                       Module Management                        ##
-- ####################################################################

-- Register that a zone module exists.
function RT:RegisterZoneModule(module)
    self.zone_modules[#RT.zone_modules + 1] = module
    module.module_loaded = false
    
    -- Add default decoration functions.
    self:AddDefaultCommunicationFunctions(module)
    self:AddDefaultEventHandlerFunctions(module)
end

-- Perform all actions that can only be done after a module has been loaded.
function RT:NotifyZoneModuleLoaded(module)
    for key, _ in pairs(module.target_zones) do
        self.zone_id_to_module[key] = module
    end
    module.module_loaded = true
    self:CheckAllModulesLoaded()
    
    self:OnZoneTransition()
end

function RT:CheckAllModulesLoaded()
    -- Check if all modules have been loaded.
    for _, module in pairs(self.zone_modules) do
        if not module.module_loaded then
            return
        end
    end
    
    -- Do a delayed initialization of the addon such that all module options can be loaded beforehand.
    self:InitializeRareTrackerLDB()
    self:InitializeOptionsMenu()
end