-- ####################################################################
-- ##                       Module Management                        ##
-- ####################################################################

-- Register that a zone module exists.
function RT:RegisterZoneModule(module)
    self.zone_modules[#RT.zone_modules + 1] = module
    module.module_loaded = false
end

-- Perform all actions that can only be done after a module has been loaded.
function RT:NotifyZoneModuleLoaded(module)
    for key, _ in pairs(module.target_zones) do
        self.zone_id_to_module[key] = module
    end
    module.module_loaded = true
    self:ExecuteAllModulesLoaded()
    
    self:OnZoneTransition()
end

function RT:ExecuteAllModulesLoaded()
    -- Check if all modules have been loaded.
    for _, module in pairs(self.zone_modules) do
        if not module.module_loaded then
            return
        end
    end
    
    -- Add all the module options to the option menu.
    self:InitializeOptionsMenu()
end