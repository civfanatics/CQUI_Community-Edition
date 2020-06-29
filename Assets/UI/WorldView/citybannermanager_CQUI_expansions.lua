-- ===========================================================================
-- CityBannerManager for Expansion 1 and Expansion 2
-- ===========================================================================
-- Functions and objects common to basegame and expansions
include( "citybannermanager_CQUI.lua");

-- ===========================================================================
-- Cached Base Functions (Expansions only)
-- ===========================================================================
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_CityBanner_Uninitialize = CityBanner.Uninitialize;
BASE_CQUI_CityBanner_UpdateInfo = CityBanner.UpdateInfo;
BASE_CQUI_CityBanner_UpdatePopulation = CityBanner.UpdatePopulation;
BASE_CQUI_CityBanner_UpdateRangeStrike = CityBanner.UpdateRangeStrike;
BASE_CQUI_CityBanner_UpdateStats = CityBanner.UpdateStats;

-- ============================================================================
-- CQUI Expansion Extension Functions
-- ============================================================================
function CityBanner.Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle)
    print_debug("CityBannerManager_CQUI_Expansions: CityBanner:Initialize ENTRY: playerID:"..tostring(playerID).." cityID:"..tostring(cityID).." districtID:"..tostring(districtID).." bannerType:"..tostring(bannerType).." bannerStyle:"..tostring(bannerStyle));
    CQUI_Common_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);

    if (IsBannerTypeCityCenter(bannerType) and (self.CQUI_DistrictBuiltIM == nil)) then
        self.CQUI_DistrictBuiltIM = InstanceManager:new( "CQUI_DistrictBuilt", "Icon", self.m_Instance.CQUI_Districts );
    end
end

-- ============================================================================
function CityBanner.Uninitialize(self)
    print_debug("CityBannerManager_CQUI_Expansions: CityBanner.Uninitialize ENTRY");
    BASE_CQUI_CityBanner_Uninitialize(self);

    -- CQUI : Clear CQUI_DistrictBuiltIM
    if self.CQUI_DistrictBuiltIM then
        self.CQUI_DistrictBuiltIM:DestroyInstances();
    end
end

-- ============================================================================
function CityBanner.UpdateInfo(self, pCity : table )
    print_debug("CityBannerManager_CQUI_Expansions: CityBanner.UpdateInfo ENTRY  pCity:"..tostring(pCity));
    BASE_CQUI_CityBanner_UpdateInfo(self, pCity);

    if (pCity == nil) then
        return;
    end

    --CQUI : Unlocked citizen check
    if (playerID == Game.GetLocalPlayer() and IsCQUI_SmartBanner_Unmanaged_CitizenEnabled()) then
        local tParameters :table = {};
        tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);

        local tResults:table = CityManager.GetCommandTargets( pCity, CityCommandTypes.MANAGE, tParameters );
        if tResults ~= nil then
            local tPlots:table = tResults[CityCommandResults.PLOTS];
            local tUnits:table = tResults[CityCommandResults.CITIZENS];
            local tMaxUnits:table = tResults[CityCommandResults.MAX_CITIZENS];
            local tLockedUnits:table = tResults[CityCommandResults.LOCKED_CITIZENS];
            if tPlots ~= nil and (table.count(tPlots) > 0) then
                for i,plotId in pairs(tPlots) do
                    local kPlot :table = Map.GetPlotByIndex(plotId);
                    if (tMaxUnits[i] >= 1 and tUnits[i] >= 1 and tLockedUnits[i] <= 0) then
                        local instance:table = self.m_InfoIconIM:GetInstance();
                        instance.Icon:SetIcon("EXCLAMATION");
                        instance.Icon:SetToolTipString(Locale.Lookup("LOC_CQUI_SMARTBANNER_UNLOCKEDCITIZEN_TOOLTIP"));
                        instance.Button:RegisterCallback(Mouse.eLClick, OnCityBannerClick);
                        instance.Button:SetVoid1(pCity:GetOriginalOwner());
                        instance.Button:SetVoid2(cityID);
                        break;
                    end
                end
            end
        end
    end

    self:Resize();
end

-- ============================================================================
function CityBanner.UpdatePopulation(self, isLocalPlayer:boolean, pCity:table, pCityGrowth:table)
    print_debug("CityBannerManager_CQUI_Expansions: CityBanner:UpdatePopulation:  pCity: "..tostring(pCity).."  pCityGrowth:"..tostring(pCityGrowth));
    BASE_CQUI_CityBanner_UpdatePopulation(self, isLocalPlayer, pCity, pCityGrowth);

    if (isLocalPlayer == false) then
        return;
    end

    local currentPopulation:number = pCity:GetPopulation();
    -- XP1+, grab the first instance
    local populationInstance = CQUI_GetInstanceObject(self.m_StatPopulationIM);

    -- Get real housing from improvements value
    local localPlayerID = Game.GetLocalPlayer();

    -- CQUI : housing left
    if (IsCQUI_SmartBanner_PopulationEnabled()) then
        local cqui_HousingFromImprovementsCalc = CQUI_GetRealHousingFromImprovementsValue(pCity, localPlayerID);
        if (cqui_HousingFromImprovementsCalc ~= nil) then    -- CQUI real housing from improvements fix to show correct values when waiting for the next turn
            local housingText, housingLeft = CQUI_GetHousingString(pCity, cqui_HousingFromImprovementsCalc, true);
            populationInstance.CQUI_CityHousing:SetText(housingText);
            populationInstance.CQUI_CityHousing:SetHide(false);

            -- CQUI : add housing left to tooltip
            local popTooltip = populationInstance.FillMeter:GetToolTipString();
            local CQUI_housingLeftPopupText = "[NEWLINE] [ICON_Housing]" .. Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ": " .. housingLeft;
            popTooltip = popTooltip .. CQUI_housingLeftPopupText;
            populationInstance.FillMeter:SetToolTipString(popTooltip);
        end
    else
        populationInstance.CQUI_CityHousing:SetHide(true);
    end
end

-- ============================================================================
function CityBanner.UpdateStats(self)
    print_debug("CityBannerManager_CQUI_Expansions: CityBanner.UpdateStats ENTRY");
    BASE_CQUI_CityBanner_UpdateStats(self);

    local pDistrict:table = self:GetDistrict();
    if (pDistrict ~= nil and IsBannerTypeCityCenter(self.m_Type)) then
        local localPlayerID:number = Game.GetLocalPlayer();
        local pCity        :table  = self:GetCity();
        local iCityOwner   :number = pCity:GetOwner();

        if (localPlayerID == iCityOwner and self.CQUI_DistrictBuiltIM ~= nil) then
            -- On first call into UpdateStats, CQUI_DistrictBuiltIM may not be instantiated yet
            -- However this is called often enough that it's not a problem
            -- Update the built districts 
            self.CQUI_DistrictBuiltIM:ResetInstances(); -- CQUI : Reset CQUI_DistrictBuiltIM
            local pCityDistricts:table = pCity:GetDistricts();
            if (IsCQUI_SmartBanner_DistrictsEnabled()) then
                for i, district in pCityDistricts:Members() do
                    local districtType = district:GetType();
                    local districtInfo:table = GameInfo.Districts[districtType];
                    local isBuilt = pCityDistricts:HasDistrict(districtInfo.Index, true);
                    if (isBuilt == true
                        and districtInfo.DistrictType ~= "DISTRICT_WONDER"
                        and districtInfo.DistrictType ~= "DISTRICT_CITY_CENTER") then
                        SetDetailIcon(self.CQUI_DistrictBuiltIM:GetInstance(), "ICON_"..districtInfo.DistrictType);
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- CQUI Replacement Functions
-- ============================================================================
function OnCityStrikeButtonClick( playerID, cityID )
    print_debug("CityBannerManager_CQUI_Expansions: OnCityStrikeButtonClick ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    CQUI_OnCityRangeStrikeButtonClick(playerID, cityID);
end

-- ===========================================================================
function OnDistrictRangeStrikeButtonClick( playerID, districtID )
    print_debug("CityBannerManager_CQUI_Expansions: OnDistrictRangeStrikeButtonClick ENTRY playerID:"..tostring(playerID).." districtID:"..tostring(districtID));
    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        return;
    end

    local pDistrict = pPlayer:GetDistricts():FindID(districtID);
    if (pDistrict == nil) then
        return;
    end;

    UI.DeselectAll();
    UI.SelectDistrict(pDistrict);
    -- CQUI (Azurency) : Look at the district plot
    UI.LookAtPlot(pDistrict:GetX(), pDistrict:GetY());
    UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_RANGE_ATTACK);
end

-- ===========================================================================
--  CQUI Initialize Function
-- ===========================================================================
function Initialize_CQUI_expansions()
    print_debug("CityBannerManager_CQUI_Expansions: Initialize CQUI CityBannerManager")
    -- Events are initialized in the common file
end
Initialize_CQUI_expansions();
