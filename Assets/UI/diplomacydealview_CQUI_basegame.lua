-- ===========================================================================
-- Base File
-- ===========================================================================
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