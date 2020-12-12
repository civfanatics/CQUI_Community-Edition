print("*** diplomacydealview_CQUI_expansion2.lua start")
-- ===========================================================================
-- Base File
-- ===========================================================================
include("DiplomacyDealView_Expansion2");

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
print("*** diplomacydealview_CQUI_expansion2.lua end")