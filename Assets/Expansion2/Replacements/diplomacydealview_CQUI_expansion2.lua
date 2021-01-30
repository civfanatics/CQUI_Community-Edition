-- ===========================================================================
-- Base File
-- ===========================================================================
-- TODO: This is a temporary workaround until a more elegant solution to the problem of Firaxis calling the include DiplomacyDealView_* at the end of their DiplomacyDealView.lua file
--       Perhaps the ScriptReplacement isn't necessary anymore (for files that do not entirely replace the Firaxis versions), etc?
--       This if statement wraps the contents in this file, the lack of indentation is intended
if (diplomacydealview_CQUI_expansion2_loaded == nil) then

diplomacydealview_CQUI_expansion2_loaded = 1;
print("*****&& diplomacydealview_CQUI_expansion2 LOADING");
-- calling the include for DiplomacyDealView here should also include the diplomacydealview_CQUI.lua; however we guard against that file being loaded twice 
include("DiplomacyDealView"); 

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_LateInitialize = LateInitialize;

-- ===========================================================================
-- CQUI File
-- ===========================================================================
include("diplomacydealview_CQUI.lua");

-- ===========================================================================
function LateInitialize()
    BASE_CQUI_LateInitialize();

    print("CQUI Diplomacy Deal View for expansion 2 loaded");
end

-- TEMP else case
else
    print("*****&& diplomacydealview_CQUI_expansion2_loaded is NOT nil, skipping load");

-- This "end" is for the include wildcard workaround, see note at top.
end

