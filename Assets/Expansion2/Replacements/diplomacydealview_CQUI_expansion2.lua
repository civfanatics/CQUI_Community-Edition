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
<<<<<<< HEAD
  print("DiplomacyDealView_CQUI_Expansion2 LateInitialize ENTRY");
  BASE_CQUI_LateInitialize();
=======
    BASE_CQUI_LateInitialize();

    print("CQUI Diplomacy Deal View for expansion 2 loaded");
>>>>>>> master
end