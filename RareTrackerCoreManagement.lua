-- ####################################################################
-- ##                       Module Management                        ##
-- ####################################################################

-- Register that a zone module exists.
function RT:RegisterZoneModule(module)
    RT.zone_modules[#RT.zone_modules + 1] = module
end

-- Perform all actions that can only be done after a module has been loaded.
function RT:NotifyZoneModuleLoaded(module)
    for key, _ in pairs(module.target_zones) do
        self.zone_id_to_module[key] = module
    end
    self:OnZoneTransition()
end