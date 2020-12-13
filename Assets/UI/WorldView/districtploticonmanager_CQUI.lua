print("*** districtploticonmanager_CQUI.lua start")
-- ===========================================================================
-- Base File
-- ===========================================================================
include("DistrictPlotIconManager");

function Initialize()
    LuaEvents.CQUI_DistrictPlotIconManager_ClearEveything.Add(ClearEveything);
    LuaEvents.CQUI_Realize2dArtForDistrictPlacement.Add(Realize2dArtForDistrictPlacement);
end
Initialize();
print("*** districtploticonmanager_CQUI.lua end")