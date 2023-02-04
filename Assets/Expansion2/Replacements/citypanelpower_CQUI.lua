-- ===========================================================================
-- Base File
-- ===========================================================================
include("CityPanelPower");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnRefresh = OnRefresh;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_ShowCityDetailAdvisor :boolean = false;

function CQUI_OnSettingsUpdate()
    CQUI_ShowCityDetailAdvisor = GameConfiguration.GetValue("CQUI_ShowCityDetailAdvisor") == 1;
end

-- ===========================================================================
--  CQUI modified OnRefresh functiton
--  Hide advisor if option is disabled
-- ===========================================================================
function OnRefresh()
    if ContextPtr:IsHidden() then
        return;
    end
    
    local localPlayerID = Game.GetLocalPlayer();
    local pPlayer = Players[localPlayerID];
    if (pPlayer == nil) then
        return;
    end
    local pCity = UI.GetHeadSelectedCity();
    if (pCity == nil) then
        return;
    end

    BASE_CQUI_OnRefresh();

  -- Hide the advisor if option is disabled
  if not Controls.PowerAdvisor:IsHidden() then
      Controls.PowerAdvisor:SetHide( CQUI_ShowCityDetailAdvisor == false );
  end

end

-- ===========================================================================
function Initialize_CityPanelPower_CQUI()
    LuaEvents.CityPanelTabRefresh.Remove(BASE_CQUI_OnRefresh);
    Events.CitySelectionChanged.Remove( BASE_CQUI_OnRefresh );
    LuaEvents.CityPanelTabRefresh.Add(OnRefresh);
    Events.CitySelectionChanged.Add( OnRefresh );

    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize_CityPanelPower_CQUI();