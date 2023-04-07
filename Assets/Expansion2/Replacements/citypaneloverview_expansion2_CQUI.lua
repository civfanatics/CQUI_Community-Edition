-- ===========================================================================
-- Base File
-- ===========================================================================
include("CityPanelOverview_Expansion2");

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_AutoapplyLoyaltyLensInCity :boolean = true;
local CQUI_AutoapplyPowerLensInCity :boolean = true;
local CQUI_ShowCityManageOverLenses :boolean = false;

function CQUI_OnSettingsUpdate()
    CQUI_AutoapplyLoyaltyLensInCity = GameConfiguration.GetValue("CQUI_AutoapplyLoyaltyLensInCity");
    CQUI_AutoapplyPowerLensInCity = GameConfiguration.GetValue("CQUI_AutoapplyPowerLensInCity");
    CQUI_ShowCityManageOverLenses = GameConfiguration.GetValue("CQUI_ShowCityManageOverLenses");
end

LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);

-- ===========================================================================
-- Functions
-- ===========================================================================
function ViewPanelAmenities(data:table)
    BASE_ViewPanelAmenities(data);  -- AZURENCY : this is the base game version

    --kInstance = m_kAmenitiesIM:GetInstance();
    --kInstance.Amenity:SetText( Locale.Lookup("LOC_HUD_CITY_AMENITIES_LOST_FROM_GOVERNORS") );
    --kInstance.AmenityYield:SetText( Locale.ToNumber(data.AmenitiesFromGovernors) );
    CQUI_BuildAmenityBubbleInstance("ICON_GOVERNOR_THE_EDUCATOR", data.AmenitiesFromGovernors, "LOC_REPORTS_GOVERNOR");
end

function RefreshCulturalIdentityPanel()
    --UILens.SetActive("Loyalty");
    if (CQUI_AutoapplyLoyaltyLensInCity) then
        SetDesiredLens("Loyalty");
        
        if (not CQUI_ShowCityManageOverLenses) then
            LuaEvents.CQUI_HideCitizenManagementLens();
        end
    else
        SetDesiredLens("CityManagement");
    end
    LuaEvents.CityPanelTabRefresh();
end

function RefreshPowerPanel()
    --UILens.SetActive("Power");
    if (CQUI_AutoapplyPowerLensInCity) then
        SetDesiredLens("Power");

        if (not CQUI_ShowCityManageOverLenses) then
            LuaEvents.CQUI_HideCitizenManagementLens();
        end
    else
        SetDesiredLens("CityManagement");
    end

    LuaEvents.CityPanelTabRefresh();
end