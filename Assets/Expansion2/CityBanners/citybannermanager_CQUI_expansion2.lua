-- ===========================================================================
-- CityBannerManager for Expansion 1 and Expansion 2
-- ===========================================================================
-- Functions and objects common to basegame and expansions
-- The CityBannerManager code specific to the expansions is the same for Expansion1 and Expansion2
print("******** citybannermanager_CQUI_expansion2.lua START")

include("CQUICommon.lua");
-- TODO: This is a temporary workaround until a more elegant solution to the problem of Firaxis calling the include CityBannerManager_* at the end of their CityBannerManager.lua file
--       Perhaps the ScriptReplacement isn't necessary anymore (for files that do not entirely replace the Firaxis versions), etc?
--       Should only have to check for expansion2 (gathering storm), the exp1 version of this file loads only if exp2 is NOT enabled
if (g_bIsGatheringStorm and citybannermanager_CQUI_expansion2_loaded == nil) then
    print("******* citybannermanager_CQUI_expansion2 LOADING")
    citybannermanager_CQUI_expansion2_loaded = 1;
    include( "citybannermanager_CQUI_expansions.lua");
else
    print("******* citybannermanager_CQUI_expansion2_loaded conditions not met, skipping")
end

print("******** citybannermanager_CQUI_expansion2.lua END")
