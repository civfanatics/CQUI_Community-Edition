-- ===========================================================================
-- Base File
-- ===========================================================================
-- TODO: This is a temporary workaround until a more elegant solution to the problem of Firaxis calling the include DiplomacyDealView_* at the end of their DiplomacyDealView.lua file
--       Perhaps the ScriptReplacement isn't necessary anymore (for files that do not entirely replace the Firaxis versions), etc?
--       This if statement wraps the contents in this file, the lack of indentation is intended
if (diplomacydealview_CQUI_basegame_loaded == nil) then

print("******* diplomacydealview_CQUI_basegame LOADING");
diplomacydealview_CQUI_basegame_loaded = 1;
include("DiplomacyDealView");

g_LocalPlayer = nil;
g_OtherPlayer = nil;

-- With the January 2021 update, Firaxis declared this object globally with the Expansion2 files, and kept it as local in the Vanilla and Expansion1.
-- Declaring this here is therefore necessary as diplomacydealview_CQUI.lua references the g_IconOnlyIM object.
g_IconOnlyIM = InstanceManager:new( "IconOnly", "SelectButton", Controls.IconOnlyContainer );

include("diplomacydealview_CQUI.lua");

-- ===========================================================================
--  CQUI OnShowMakeDeal to set the g_LocalPlayer and g_OtherPlayer
-- ===========================================================================
function CQUI_OnShowMakeDeal(otherPlayerID)
    g_LocalPlayer = Players[Game.GetLocalPlayer()];
    g_OtherPlayer = Players[otherPlayerID];
    OnShowMakeDeal(otherPlayerID);
end
LuaEvents.DiploPopup_ShowMakeDeal.Add(CQUI_OnShowMakeDeal);
LuaEvents.DiploPopup_ShowMakeDeal.Remove(OnShowMakeDeal);

-- ===========================================================================
--  CQUI OnShowMakeDemand to set the g_LocalPlayer and g_OtherPlayer
-- ===========================================================================
function CQUI_OnShowMakeDemand(otherPlayerID)
    g_LocalPlayer = Players[Game.GetLocalPlayer()];
    g_OtherPlayer = Players[otherPlayerID];
    OnShowMakeDemand(otherPlayerID);
end
LuaEvents.DiploPopup_ShowMakeDemand.Add(CQUI_OnShowMakeDemand);
LuaEvents.DiploPopup_ShowMakeDemand.Remove(OnShowMakeDemand);

-- ===========================================================================
function Initialize()
    print("CQUI Diplomacy Deal View loaded");
end
Initialize();

-- TEMP Else case
else
    print("******* diplomacydealview_CQUI_basegame not loaded SKIPPED");

-- This "end" is for the include wildcard workaround, see note at top.
end
