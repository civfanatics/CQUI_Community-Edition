-- ===========================================================================
--	CQUI CivilopediaScreen.lua replacement
--  This file matches the Firaxis version of CivilopediaScreen.lua, save for the lines referencing CQUI
-- ===========================================================================

-- Include all of the base civilopedia logic
include("CivilopediaSupport");

-- Include the CQUI extension
include("civilopediasupport_CQUI.lua");

-- Now that all of the utility functions have been defined and all of the scaffolding in place...
-- Load all of the Civilopedia pages.
-- These individual files will define the page layouts referenced in the database.
-- By keeping the pages separated from each other and the base logic, modders can quickly add new page layouts
-- or replace existing ones.
include("CivilopediaPage_", true);


-- Initialize the pedia!
Initialize();