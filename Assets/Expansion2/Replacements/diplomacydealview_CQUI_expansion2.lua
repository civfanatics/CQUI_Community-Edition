-- ===========================================================================
-- Base File
-- ===========================================================================
-- Firaxis does that wildcard include at the end of their diplomacydealview, which would grab their DiplomacyDealView_Expansion2 file, so we just need to include DipolmacyDealView
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