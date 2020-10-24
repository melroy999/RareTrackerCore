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
end

-- Close the window and do cleanup.
function RareTracker:CloseWindow()
    self:Debug("Closing Window")
end

function RareTracker:UpdateShardNumber()
    
end