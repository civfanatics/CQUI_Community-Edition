-- ===========================================================================
-- CQUI CityBannerManager function extensions/replacements
-- All of the CityBannerManager code, for both BaseGame and Expansions, in one file
-- because the Firaxis CityBannerManager.lua now calls 'Include("CityBannerManager_", true)' at the end of their file
print("*** CQUI: CityBannerManager_CQUI.lua File Loaded");
include("CQUICommon.lua");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_CityBanner_UpdateName = CityBanner.UpdateName;
BASE_CQUI_CityBanner_UpdateProduction = CityBanner.UpdateProduction;
BASE_CQUI_CityBanner_UpdateRangeStrike = CityBanner.UpdateRangeStrike;
BASE_CQUI_CityBanner_UpdateStats = CityBanner.UpdateStats;
BASE_CQUI_OnGameDebugReturn = OnGameDebugReturn;
BASE_CQUI_OnInterfaceModeChanged = OnInterfaceModeChanged;
BASE_CQUI_OnShutdown = OnShutdown;
BASE_CQUI_Initialize = Initialize;

-- These functions only exist in the Expansions
BASE_CQUI_CityBanner_Uninitialize = nil;
BASE_CQUI_CityBanner_UpdateInfo = nil;
BASE_CQUI_CityBanner_UpdatePopulation = nil;
if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
    -- These functions only exist in the CityBannerManager Expansions versions
    BASE_CQUI_CityBanner_Uninitialize = CityBanner.Uninitialize;
    BASE_CQUI_CityBanner_UpdateInfo = CityBanner.UpdateInfo;
    BASE_CQUI_CityBanner_UpdatePopulation = CityBanner.UpdatePopulation;
end

-- CQUI Enhancements for Barbarian Clans Mode
BASE_CQUI_UpdateTribeBannerConversionBar = UpdateTribeBannerConversionBar;

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
--  We have to re-do the declaration on the ones we need because they're declared as local in the Firaxis files

local COLOR_CITY_GREEN           = UI.GetColorValueFromHexLiteral(0xFF4CE710);
local COLOR_CITY_RED             = UI.GetColorValueFromHexLiteral(0xFF0101F5);
local COLOR_CITY_YELLOW          = UI.GetColorValueFromHexLiteral(0xFF2DFFF8);
local BANNERSTYLE_LOCAL_TEAM     = 0;
local BANNERSTYLE_OTHER_TEAM     = 1;

local CQUI_WorkIconSize       = 48;
local CQUI_WorkIconAlpha      = 0.60;
local CQUI_SmartWorkIcon      = true;
local CQUI_SmartWorkIconSize  = 64;
local CQUI_SmartWorkIconAlpha = 0.45;

local CQUI_CityRangeStrikeTopYOffset          = 10;
local CQUI_CityRangeStrikeBottomYOffset       = -6;
local CQUI_EncampmentRangeStrikeTopYOffset    = 10;
local CQUI_EncampmentRangeStrikeBottomYOffset = -4;

local m_LoadGameViewStateComplete:boolean         = false;
local m_isReligionLensActive:boolean              = false;
local m_HexColoringReligion:number                = UILens.CreateLensLayerHash("Hex_Coloring_Religion");
local DATA_FIELD_RELIGION_ICONS_IM:string         = "m_IconsIM";
local DATA_FIELD_RELIGION_FOLLOWER_LIST_IM:string = "m_FollowerListIM";
local DATA_FIELD_RELIGION_POP_CHART_IM:string     = "m_PopChartIM";
local DATA_FIELD_RELIGION_INFO_INSTANCE:string    = "m_ReligionInfoInst";
local RELIGION_POP_CHART_TOOLTIP_HEADER:string    = Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP_HEADER");
local COLOR_RELIGION_DEFAULT:number               = UI.GetColorValueFromHexLiteral(0x02000000);

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
-- Instantiated in the Initialize function
local CQUI_PlotIM        = {};
local CQUI_UIWorldMap    = {};
local CQUI_YieldsOn      = false;
local CQUI_Hovering      = false;
local CQUI_NextPlot4Away = nil;

local CQUI_ShowYieldsOnCityHover         = false;
local CQUI_ShowCitizenIconsOnCityHover   = false;
local CQUI_ShowCityManageAreaOnCityHover = true;
local CQUI_CityManageAreaShown           = false;
local CQUI_CityManageAreaShouldShow      = false;
local CQUI_ShowSuzerainInCityStateBanner = true;
local CQUI_ShowSuzerainDisabled          = 0;
local CQUI_ShowSuzerainCivIcon           = 1;
local CQUI_ShowSuzerainLeaderIcon        = 2;
local CQUI_ShowSuzerainInCityStateBanner = CQUI_ShowSuzerainCivIcon;
local CQUI_ShowSuzerainLabelInCityStateBanner = true;
local CQUI_ShowWarIconInCityStateBanner       = true;

local CQUI_SmartBanner                    = true;
local CQUI_SmartBanner_Unmanaged_Citizen  = false;
local CQUI_SmartBanner_Districts          = true;
local CQUI_SmartBanner_Population         = true;
local CQUI_SmartBanner_Cultural           = true;
local CQUI_SmartBanner_DistrictsAvailable = true;

local CQUI_CityMaxBuyPlotRange = tonumber(GlobalParameters.CITY_MAX_BUY_PLOT_RANGE);
local CQUI_CityYields          = UILens.CreateLensLayerHash("City_Yields");
local CQUI_CitizenManagement   = UILens.CreateLensLayerHash("Citizen_Management");

-- ===========================================================================
function CQUI_OnSettingsInitialized()
    -- print("CityBannerManager_CQUI: CQUI_OnSettingsInitialized ENTRY")
    CQUI_ShowYieldsOnCityHover              = GameConfiguration.GetValue("CQUI_ShowYieldsOnCityHover");
    CQUI_ShowCitizenIconsOnCityHover        = GameConfiguration.GetValue("CQUI_ShowCitizenIconsOnCityHover");
    CQUI_ShowCityManageAreaOnCityHover      = GameConfiguration.GetValue("CQUI_ShowCityManageAreaOnCityHover");
    CQUI_ShowSuzerainInCityStateBanner      = GameConfiguration.GetValue("CQUI_ShowSuzerainInCityStateBanner");
    CQUI_ShowSuzerainLabelInCityStateBanner = GameConfiguration.GetValue("CQUI_ShowSuzerainLabelInCityStateBanner");
    CQUI_ShowWarIconInCityStateBanner       = GameConfiguration.GetValue("CQUI_ShowWarIconInCityStateBanner");

    CQUI_SmartBanner            = GameConfiguration.GetValue("CQUI_Smartbanner");
    CQUI_SmartBanner_Districts  = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_Districts");
    CQUI_SmartBanner_Population = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_Population");
    CQUI_SmartBanner_Cultural   = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_Cultural");
    CQUI_SmartBanner_Unmanaged_Citizen  = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_UnlockedCitizen");
    CQUI_SmartBanner_DistrictsAvailable = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_DistrictsAvailable");

    CQUI_WorkIconSize       = GameConfiguration.GetValue("CQUI_WorkIconSize");
    CQUI_WorkIconAlpha      = GameConfiguration.GetValue("CQUI_WorkIconAlpha") / 100;
    CQUI_SmartWorkIcon      = GameConfiguration.GetValue("CQUI_SmartWorkIcon");
    CQUI_SmartWorkIconSize  = GameConfiguration.GetValue("CQUI_SmartWorkIconSize");
    CQUI_SmartWorkIconAlpha = GameConfiguration.GetValue("CQUI_SmartWorkIconAlpha") / 100;

    CQUI_RelocateCityStrike       = GameConfiguration.GetValue("CQUI_RelocateCityStrike");
    CQUI_RelocateEncampmentStrike = GameConfiguration.GetValue("CQUI_RelocateEncampmentStrike");
    -- print("CityBannerManager_CQUI: CQUI_OnSettingsInitialized EXIT")
end

-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- print("CityBannerManager_CQUI: CQUI_OnSettingsUpdate ENTRY")
    CQUI_OnSettingsInitialized();
    -- Only refresh the banners when the Load Game state is done
    if (m_LoadGameViewStateComplete) then
        CQUI_Refresh_Banners();
    end

    -- print("CityBannerManager_CQUI: CQUI_OnSettingsUpdate EXIT")
end

-- ============================================================================
-- CQUI Extension Functions (Functions that will call the original Firaxis functions to do some of the work)
-- ============================================================================
-- CityBanner.Initialize --  Register additional actions for both BaseGame and Expansions
function CityBanner.Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle)
    -- print("CityBannerManager_CQUI: CityBanner:Initialize ENTRY: playerID:"..tostring(playerID).." cityID:"..tostring(cityID).." districtID:"..tostring(districtID).." bannerType:"..tostring(bannerType).." bannerStyle:"..tostring(bannerStyle));
    BASE_CQUI_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);

    if (self.m_Instance.CityNameButton == nil) then
        -- print("CityBannerManager_CQUI: CityBanner:Initalize EXIT (CityNameButton nil)");
        return;
    end

    -- Register the MouseOver callbacks
    if (IsBannerTypeCityCenter(bannerType)) then
        -- Register the callbacks 
        self.m_Instance.CityNameButton:RegisterCallback( Mouse.eMouseEnter, CQUI_OnBannerMouseEnter );
        self.m_Instance.CityNameButton:RegisterCallback( Mouse.eMouseExit,  CQUI_OnBannerMouseExit );
        -- Re-register normal click as it gets hidden by a new button
        self.m_Instance.CityNameButton:RegisterCallback( Mouse.eLClick, OnCityBannerClick );
        self.m_Instance.CityNameButton:SetVoid1(playerID);
        self.m_Instance.CityNameButton:SetVoid2(cityID);

        -- If this is one of the expansions, create the CQUI_DistrictBuiltIM object for the District icons in the banner
        if ((g_bIsRiseAndFall or g_bIsGatheringStorm) and IsCQUI_CityBannerXMLLoaded() and (self.CQUI_DistrictBuiltIM == nil)) then
            self.CQUI_DistrictBuiltIM = InstanceManager:new( "CQUI_DistrictBuilt", "Icon", self.m_Instance.CQUI_Districts );
        end
    end

    -- print("CityBannerManager_CQUI: CityBanner:Initalize EXIT");
end

-- ===========================================================================
-- CityBanner.UpdateProduction -- additional work applicable only to the base game banners
-- Single line difference between this and the base version that allows the icon the item being built to appear in the CityBanner
function CityBanner.UpdateProduction(self)
    -- print("CityBannerManager_CQUI: CityBanner.UpdateProduction ENTRY");
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        -- The Expansions version of this function include a City object parameter
        local pCity:table = self:GetCity();
        -- print("CityBannerManager_CQUI: CityBanner.UpdateProduction EXIT (Expansions)");
        return BASE_CQUI_CityBanner_UpdateProduction(self, pCity);
    end

    -- BaseGame only, note the BaseGame UpdateProduction does not include a City object parameter
    BASE_CQUI_CityBanner_UpdateProduction(self);
    local localPlayerID :number = Game.GetLocalPlayer();
    local pCity         :table = self:GetCity();
    local pBuildQueue   :table  = pCity:GetBuildQueue();

    if (localPlayerID == pCity:GetOwner() and pBuildQueue ~= nil) then
        -- if there is anything in the build queue, it will have a hash, otherwise the hash is 0.
        local currentProductionHash :number = pBuildQueue:GetCurrentProductionTypeHash();

        if (currentProductionHash ~= 0 and IsCQUI_CityBannerXMLLoaded()) then
            -- This single line is responsible for the icon of what is being produced showing in the City Banner
            self.m_Instance.ProductionIndicator:SetHide(false);
        end
    end

    -- print("CityBannerManager_CQUI: CityBanner.UpdateProduction EXIT");
end

-- ===========================================================================
-- CityBanner.UpdateStats -- different things are done for the basegame and for the expansions, so call out to the appropriate function
function CityBanner.UpdateStats(self)
    -- print("CityBannerManager_CQUI: CityBanner.UpdateStats ENTRY");
    BASE_CQUI_CityBanner_UpdateStats(self);

    if (g_bIsBaseGame) then
        CQUI_CityBanner_UpdateStats_BaseGame(self);
    else
        CQUI_CityBanner_UpdateStats_Expansions(self);
    end

    -- print("CityBannerManager_CQUI: CityBanner.UpdateStats EXIT");
end

-- ===========================================================================
-- CityBanner UpdateStats for the base game (vanilla).
-- The Expansions do much of the work found in this funciton in the CityBanner.UpdatePopulation function
function CQUI_CityBanner_UpdateStats_BaseGame(self)
    -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_BaseGame ENTRY");
    -- BASE_CQUI_CityBanner_UpdateStats function was called by CityBanner.UpdateStats
    -- CQUI get real housing from improvements value (do this regardless of whether or not the banners will be updated)
    local pCity         :table  = self:GetCity();
    local localPlayerID :number = Game.GetLocalPlayer();

    if (IsBannerTypeCityCenter(self.m_Type) == false) then
        -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_BaseGame EXIT (Not City Center)");
        return;
    end

    if (self.m_Player ~= Players[localPlayerID]) then
        -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_BaseGame EXIT (Not LocalPlayerID)");
        return;
    end

    if (IsCQUI_CityBannerXMLLoaded() == false) then
        -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_BaseGame EXIT (CQUI XML not loaded)");
        return;
    end

    if (IsCQUI_SmartBannerEnabled() == false) then
        -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_BaseGame EXIT (SmartBannerNotEnabled)");
        return;
    end

    if (IsCQUI_SmartBanner_CulturalEnabled()) then
        -- Show the turns left until border expansion to the left of the population
        local pCityCulture = pCity:GetCulture();
        local turnsUntilBorderGrowth = pCityCulture:GetTurnsUntilExpansion();
        self.m_Instance.CityCultureTurnsLeft:SetText(turnsUntilBorderGrowth);
        self.m_Instance.CityCultureTurnsLeft:SetHide(false);
    else
        self.m_Instance.CityCultureTurnsLeft:SetHide(true);
    end

    if (IsCQUI_SmartBanner_PopulationEnabled()) then
        local cqui_HousingFromImprovementsCalc = CQUI_GetRealHousingFromImprovements(pCity);
        if (cqui_HousingFromImprovementsCalc ~= nil) then
            -- Basegame text includes the number of turns remaining before city growth
            local currentPopulation :number  = pCity:GetPopulation();
            local pCityGrowth       :table   = pCity:GetGrowth();
            local foodSurplus       :number  = pCityGrowth:GetFoodSurplus();
            local isGrowing         :boolean = pCityGrowth:GetTurnsUntilGrowth() ~= -1;
            local isStarving        :boolean = pCityGrowth:GetTurnsUntilStarvation() ~= -1;

            local turnsUntilGrowth  :number  = 0; -- It is possible for zero... no growth and no starving.
            local popTurnLeftColor  :string  = "StatNormalCS"; -- Value if 0
            if (isGrowing) then
                turnsUntilGrowth = pCityGrowth:GetTurnsUntilGrowth();
                popTurnLeftColor = "StatGoodCS";
            elseif (isStarving) then
                turnsUntilGrowth = -1 * pCityGrowth:GetTurnsUntilStarvation();
                popTurnLeftColor = "StatBadCS";
            end

            -- CQUI real housing from improvements fix to show correct values when waiting for the next turn
            local housingString, housingLeft = CQUI_GetHousingString(pCity, cqui_HousingFromImprovementsCalc);
            housingString = "[COLOR:"..popTurnLeftColor.."]"..turnsUntilGrowth.."[ENDCOLOR] ["..housingString.."] ";
            self.m_Instance.CityPopTurnsLeft:SetText(housingString);
            self.m_Instance.CityPopTurnsLeft:SetHide(false);

            -- Firaxis removed the GetPopulationTooltip function and placed it inline with the January 2021 update
            local popTooltip:string = Locale.Lookup("LOC_CITY_BANNER_POPULATION") .. ": " .. currentPopulation;
            if turnsUntilGrowth > 0 then
                popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_TURNS_GROWTH", turnsUntilGrowth);
                popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_FOOD_SURPLUS", toPlusMinusString(foodSurplus));
            elseif turnsUntilGrowth == 0 then
                popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_STAGNATE");
            elseif turnsUntilGrowth < 0 then
                popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_TURNS_STARVATION", -turnsUntilGrowth);
            end

            local CQUI_housingLeftPopupText = "[NEWLINE] [ICON_Housing]" .. Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ": " .. housingLeft;
            popTooltip = popTooltip .. CQUI_housingLeftPopupText;
            self.m_Instance.CityPopulation:SetToolTipString(popTooltip);
        end
    else
        self.m_Instance.CityPopTurnsLeft:SetHide(true);
    end

    -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_BaseGame EXIT");
end

-- ============================================================================
-- CityBanner UpdateStats for the expansions (Rise and Fall / Gathering Storm)
function CQUI_CityBanner_UpdateStats_Expansions(self)
    -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_Expansions ENTRY");
    -- BASE_CQUI_CityBanner_UpdateStats function was called by CityBanner.UpdateStats

    if (IsCQUI_CityBannerXMLLoaded() == false) then
        -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_Expansions EXIT (CQUI XML not loaded)");
        return;
    end

    local pDistrict:table = self:GetDistrict();
    if (pDistrict ~= nil and IsBannerTypeCityCenter(self.m_Type)) then
        local localPlayerID:number = Game.GetLocalPlayer();
        local pCity        :table  = self:GetCity();
        local iCityOwner   :number = pCity:GetOwner();

        if (localPlayerID == iCityOwner and self.CQUI_DistrictBuiltIM ~= nil) then
            -- On first call into UpdateStats, CQUI_DistrictBuiltIM may not be instantiated yet
            -- However this is called often enough that it's not a problem
            self.CQUI_DistrictBuiltIM:ResetInstances(); -- CQUI : Reset CQUI_DistrictBuiltIM
            self.m_Instance.CQUI_DistrictAvailable:SetHide(true);
            local pCityDistricts:table = pCity:GetDistricts();
            if (IsCQUI_SmartBanner_DistrictsEnabled()) then
                local districtTooltipString = "";
                local districtCount = 0;
                local neighborhoodAdded = false;
                -- Update the built districts 
                for i, district in pCityDistricts:Members() do
                    local districtType = district:GetType();
                    local districtInfo:table = GameInfo.Districts[districtType];
                    local isBuilt = pCityDistricts:HasDistrict(districtInfo.Index, true);
                    -- If the district is built, is not the City Center, is not a Wonder, and a Neighborhood Icon has already been shown...
                    if (isBuilt == true
                       and districtInfo.DistrictType ~= "DISTRICT_WONDER"
                       and districtInfo.DistrictType ~= "DISTRICT_CITY_CENTER"
                       and (districtInfo.DistrictType ~= "DISTRICT_NEIGHBORHOOD" or neighborhoodAdded == false)) then
                        SetDetailIcon(self.CQUI_DistrictBuiltIM:GetInstance(), "ICON_"..districtInfo.DistrictType);
                        districtTooltipString = districtTooltipString .. "[ICON_".. districtInfo.DistrictType .. "] ".. Locale.Lookup(districtInfo.Name) .. "[NEWLINE]";
                        districtCount = districtCount + 1;
                        if (districtInfo.DistrictType == "DISTRICT_NEIGHBORHOOD") then
                            neighborhoodAdded = true;
                        end
                    end
                end

                -- Trim the trailing [NEWLINE]
                districtTooltipString = string.sub(districtTooltipString, 1, string.len(districtTooltipString) - 9);

                -- Determine the overlap of the district icons based on the number built
                -- Note: GetNumZonedDistrictsRequiringPopulation does not include Aqueducts or Neighborhoods
                -- The padding value was -12 before this dynamic calculation was introduced
                local districtIconPadding = 8 + districtCount;
                if districtIconPadding < 12 then districtIconPadding = 12; end
                if districtIconPadding > 20 then districtIconPadding = 20; end
                self.m_Instance.CQUI_Districts:SetStackPadding(districtIconPadding * -1);
                self.m_Instance.CQUI_Districts:CalculateSize(); -- Sets the correct banner width with the padding update
                self.m_Instance.CQUI_DistrictsContainer:SetToolTipString(districtTooltipString);
            end

            if (IsCQUI_SmartBanner_DistrictsAvailableEnabled()) then
                -- Infixo: 2020-06-08 district available flag and tooltip
                local iDistrictsNum:number         = pCityDistricts:GetNumZonedDistrictsRequiringPopulation();
                local iDistrictsPossibleNum:number = pCityDistricts:GetNumAllowedDistrictsRequiringPopulation();
                if iDistrictsPossibleNum > iDistrictsNum then
                    self.m_Instance.CQUI_DistrictAvailable:SetHide(false);
                    self.m_Instance.CQUI_DistrictAvailable:SetToolTipString( string.format("%s %d / %d", Locale.Lookup("LOC_HUD_DISTRICTS"), iDistrictsNum, iDistrictsPossibleNum) );
                else
                    self.m_Instance.CQUI_DistrictAvailable:SetHide(true);
                end
            end
        end
    end

    -- print("CityBannerManager_CQUI: CQUI_CityBanner_UpdateStats_Expansions EXIT");
end

-- ============================================================================
-- CityBanner.Uninitialize is called in Expansions only
function CityBanner.Uninitialize(self)
    -- print("CityBannerManager_CQUI: CityBanner.Uninitialize ENTRY");
    BASE_CQUI_CityBanner_Uninitialize(self);

    -- CQUI : Clear CQUI_DistrictBuiltIM
    if self.CQUI_DistrictBuiltIM then
        self.CQUI_DistrictBuiltIM:DestroyInstances();
    end

    -- print("CityBannerManager_CQUI: CityBanner.Uninitialize EXIT");
end

-- ============================================================================
function CityBanner.UpdateInfo(self, pCity : table )
    -- print("CityBannerManager_CQUI: CityBanner.UpdateInfo ENTRY  pCity:"..tostring(pCity));
    BASE_CQUI_CityBanner_UpdateInfo(self, pCity);

    if (pCity == nil) then
        -- print("CityBannerManager_CQUI: CityBanner.UpdateInfo EXIT (pCity nil)");
        return;
    end

    if (IsCQUI_CityBannerXMLLoaded() == false) then
        -- print("CityBannerManager_CQUI: CityBanner.UpdateInfo EXIT (CQUI XML not loaded)");
        return;
    end

    local playerID:number = pCity:GetOwner();
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

    -- #62 Infixo always show an original owner of the city if different than the current one
    -- this piece of code is taken from CityBannerManager.lua to allow an extra line inside a tooltip
    local pPlayer:table = Players[playerID];
    if pPlayer == nil then
        -- print("CityBannerManager_CQUI: CityBanner.UpdateInfo EXIT (original city owner)");
        return;
    end
    
    local tooltip:string, tooltipOrignal:string = "", "";

    -- #62 Infixo check if this city was previously owned by someone else
    local originalOwner:number = pCity:GetOriginalOwner();
    
    if originalOwner ~= playerID then
        if pCity:IsOriginalCapital() then
            tooltipOrignal = Locale.Lookup("LOC_CQUI_CITY_BANNER_ORIGINAL_CAPITAL_TT", PlayerConfigurations[originalOwner]:GetCivilizationShortDescription());
        else
            tooltipOrignal = Locale.Lookup("LOC_CQUI_CITY_BANNER_ORIGINAL_CITY_TT",    PlayerConfigurations[originalOwner]:GetCivilizationShortDescription());
        end
    end

    if pPlayer:IsMajor() then
        if pCity:IsOriginalCapital() and originalOwner == playerID then
            -- Original capital
            tooltip = Locale.Lookup("LOC_CITY_BANNER_ORIGINAL_CAPITAL_TT", PlayerConfigurations[playerID]:GetCivilizationShortDescription()); -- no need for original owner info
        elseif pCity:IsCapital() then
            -- New capital
            tooltip = Locale.Lookup("LOC_CITY_BANNER_NEW_CAPITAL_TT",      PlayerConfigurations[playerID]:GetCivilizationShortDescription()) .. tooltipOrignal;
        else
            -- Other cities
            tooltip = Locale.Lookup("LOC_CITY_BANNER_OTHER_CITY_TT",       PlayerConfigurations[playerID]:GetCivilizationShortDescription()) .. tooltipOrignal;
        end
        -- espionage info (added in XP2)
        if g_bIsGatheringStorm and GameCapabilities.HasCapability("CAPABILITY_ESPIONAGE") then
            if Game.GetLocalPlayer() == playerID or HasEspionageView(playerID, pCity:GetID()) then
                tooltip = tooltip .. Locale.Lookup("LOC_ESPIONAGE_VIEW_ENABLED_TT");
            else
                tooltip = tooltip .. Locale.Lookup("LOC_ESPIONAGE_VIEW_DISABLED_TT");
            end
        end
    elseif pPlayer:IsMinor() then
        CQUI_UpdateCityStateBannerSuzerain(pPlayer, self);
        CQUI_UpdateCityStateBannerAtWarIcon(pPlayer, self);
    elseif pPlayer:IsFreeCities() then
        tooltip = Locale.Lookup("LOC_CITY_BANNER_FREE_CITY_TT") .. tooltipOrignal;
    else -- city states
        tooltip = Locale.Lookup("LOC_CITY_BANNER_CITY_STATE_TT") .. tooltipOrignal; -- just in case CS could capture capitals?
    end

    -- update the tooltip
    local cityIconInstance:table = self.m_InfoIconIM:GetAllocatedInstance();
    cityIconInstance.Button:SetToolTipString(tooltip);

    self:Resize();
    -- print("CityBannerManager_CQUI: CityBanner.UpdateInfo EXIT");
end

-- ============================================================================
-- CityBanner.UpdatePopulation is called in Expansions only
function CityBanner.UpdatePopulation(self, isLocalPlayer:boolean, pCity:table, pCityGrowth:table)
    -- print("CityBannerManager_CQUI: CityBanner:UpdatePopulation: ENTRY pCity: "..tostring(pCity).."  pCityGrowth:"..tostring(pCityGrowth));
    BASE_CQUI_CityBanner_UpdatePopulation(self, isLocalPlayer, pCity, pCityGrowth);

    if (isLocalPlayer == false) then
        -- print("CityBannerManager_CQUI: CityBanner:UpdatePopulation EXIT (not localplayer)");
        return;
    end

    if (IsCQUI_CityBannerXMLLoaded() == false) then
        -- print("CityBannerManager_CQUI: CityBanner:UpdatePopulation EXIT (CQUI XML not loaded)");
        return;
    end

    local currentPopulation:number = pCity:GetPopulation();
    -- XP1+, grab the first instance
    local populationInstance = CQUI_GetInstanceObject(self.m_StatPopulationIM);

    -- Get real housing from improvements value
    local localPlayerID = Game.GetLocalPlayer();

    -- CQUI : housing left
    if (IsCQUI_SmartBanner_PopulationEnabled()) then
        local cqui_HousingFromImprovementsCalc = CQUI_GetRealHousingFromImprovements(pCity);
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

    if (IsCQUI_SmartBanner_CulturalEnabled()) then
        -- Show the turns left until border expansion to the left of the population
        local pCityCulture = pCity:GetCulture();
        local turnsUntilBorderGrowth = pCityCulture:GetTurnsUntilExpansion();
        populationInstance.CityCultureTurnsLeft:SetText(turnsUntilBorderGrowth);
        populationInstance.CityCultureTurnsLeft:SetHide(false);

        local popTooltip = populationInstance.FillMeter:GetToolTipString();
        -- The Locale.Lookup for Border Growth requires the value be included... but doesn't then put that value in the string itself, apparently.
        popTooltip = popTooltip .. "[NEWLINE] [ICON_Culture]" ..tostring(turnsUntilBorderGrowth).. " " .. Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_BORDER_GROWTH", turnsUntilBorderGrowth);
        populationInstance.FillMeter:SetToolTipString(popTooltip);
    else
        populationInstance.CityCultureTurnsLeft:SetHide(true);
    end

    -- print("CityBannerManager_CQUI: CityBanner:UpdatePopulation EXIT");
end

-- ============================================================================
-- Move the CityStrike icon and button to the top of the City bar; similar to the Sukritact Simple UI Mod (which puts it on the right)
-- This function should work, regardless of whether the CQUI XMLs are loaded
function CityBanner.UpdateRangeStrike(self)
    -- print("CityBannerManager_CQUI: CityBanner.UpdateRangeStrike ENTRY");
    BASE_CQUI_CityBanner_UpdateRangeStrike(self);

    local banner = self.m_Instance;
    if (banner == nil) then
        -- print("CityBannerManager_CQUI: CityBanner.UpdateRangeStrike EXIT (banner nil)");
        return;
    end

    if (self.m_Type == BANNERTYPE_CITY_CENTER) then
        if (CQUI_RelocateCityStrike == true) then
            -- instance, rotation, offsetY, anchor
            CQUI_SetCityStrikeButtonLocation(banner, 180, CQUI_CityRangeStrikeTopYOffset, "C,T");
        else
            CQUI_SetCityStrikeButtonLocation(banner, 0, CQUI_CityRangeStrikeBottomYOffset, "C,B");
        end
    end

    if (self.m_Type == BANNERTYPE_ENCAMPMENT) then
        if (CQUI_RelocateEncampmentStrike == true) then
            CQUI_SetCityStrikeButtonLocation(banner, 180, CQUI_EncampmentRangeStrikeTopYOffset, "C,T");
        else
            CQUI_SetCityStrikeButtonLocation(banner, 0, CQUI_EncampmentRangeStrikeBottomYOffset, "C,B");
        end
    end

    -- print("CityBannerManager_CQUI: CityBanner.UpdateRangeStrike EXIT");
end

-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
    -- print("CityBannerManager_CQUI: OnGameDebugReturn ENTRY context:"..tostring(context).." contextTable:"..tostring(contextTable));
    if (context == "CityBannerManager") then
        -- CQUI settings
        CQUI_OnSettingsUpdate();
    end

    BASE_CQUI_OnGameDebugReturn(context, contextTable);
    -- print("CityBannerManager_CQUI: OnGameDebugReturn EXIT");
end

-- ===========================================================================
function OnInterfaceModeChanged( oldMode:number, newMode:number )
    -- print("CityBannerManager_CQUI: OnInterfaceModeChanged ENTRY");
    BASE_CQUI_OnInterfaceModeChanged(oldMode, newMode);

    if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
      CQUI_CityManageAreaShown = false;
      CQUI_CityManageAreaShouldShow = false;
    end

    -- print("CityBannerManager_CQUI: OnInterfaceModeChanged EXIT");
end

-- ===========================================================================
function OnProductionClick( playerID, cityID )
    -- print("CityBannerManager_CQUI: OnProductionClick ENTRY");
    OnCityBannerClick( playerID, cityID);
    -- print("CityBannerManager_CQUI: OnProductionClick EXIT");
end

-- ===========================================================================
function OnShutdown()
    -- print("CityBannerManager_CQUI: OnShutdown ENTRY");
    if (IsCQUI_CityBannerXMLLoaded()) then
        CQUI_PlotIM:DestroyInstances();
    end

    BASE_CQUI_OnShutdown();
    -- print("CityBannerManager_CQUI: OnShutdown EXIT");
end

-- ===========================================================================
-- CQUI CityBanner Hybrid Replacement/Extension Functions
-- Functions that are replacements only in same cases; extensions in other cases (see comments)
-- ===========================================================================
-- CityBanner.UpdateName does work for BaseGame only, Expansions call the BASE_CQUI_CityBanner_UpdateName and return
function CityBanner.UpdateName( self )
    -- print("CityBannerManager_CQUI: CityBanner.UpdateName ENTRY");

    -- This code applies to vanilla/basegame only (early return from function!)
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        -- print("CityBannerManager_CQUI: CityBanner.UpdateName EXIT (Expansions)");
        return BASE_CQUI_CityBanner_UpdateName(self);
    end

    if (IsBannerTypeCityCenter(self.m_Type) == false) then
        -- print("CityBannerManager_CQUI: CityBanner.UpdateName EXIT (Not IsBannerTypeCityCenter)");
        return;
    end

    local pCity : table = self:GetCity();
    if (pCity == nil) then
        -- print("CityBannerManager_CQUI: CityBanner.UpdateName EXIT (city is nil)");
        return;
    end

    local owner       :number = pCity:GetOwner();
    local pPlayer     :table  = Players[owner];
    local capitalIcon :string = (pPlayer ~= nil and pPlayer:IsMajor() and pCity:IsCapital()) and "[ICON_Capital]" or "";
    local cityName    :string = capitalIcon .. Locale.ToUpper(pCity:GetName());

    if (not self:IsTeam()) then
        local civType:string = PlayerConfigurations[owner]:GetCivilizationTypeName();
        if (civType ~= nil) then
            self.m_Instance.CivIcon:SetIcon("ICON_" .. civType);
        else
            UI.DataError("Invalid type name returned by GetCivilizationTypeName");
        end
    end

    local questsManager : table = Game.GetQuestsManager();
    local questTooltip  : string = Locale.Lookup("LOC_CITY_STATES_QUESTS");
    local statusString  : string = "";
    if (questsManager ~= nil) then
        for questInfo in GameInfo.Quests() do
            if (questsManager:HasActiveQuestFromPlayer(Game.GetLocalPlayer(), owner, questInfo.Index)) then
                statusString = "[ICON_CityStateQuest]";
                questTooltip = questTooltip .. "[NEWLINE]" .. questInfo.IconString .. questsManager:GetActiveQuestName(Game.GetLocalPlayer(), owner, questInfo.Index);
            end
        end
    end

    -- Update under siege icon
    local pDistrict:table = self:GetDistrict();
    if (pDistrict and pDistrict:IsUnderSiege()) then
        self.m_Instance.CityUnderSiegeIcon:SetHide(false);
    else
        self.m_Instance.CityUnderSiegeIcon:SetHide(true);
    end
    
    -- Update district icons
    local districts = {};
    if (IsCQUI_CityBannerXMLLoaded()) then
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_ACROPOLIS")]             = { Icon = "[ICON_DISTRICT_ACROPOLIS]", Instance = self.m_Instance.CityBuiltDistrictAcropolis };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_AQUEDUCT")]              = { Icon = "[ICON_DISTRICT_AQUEDUCT]", Instance = self.m_Instance.CityBuiltDistrictAqueduct };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_AERODROME")]             = { Icon = "[ICON_DISTRICT_AERODROME]", Instance = self.m_Instance.CityBuiltDistrictAerodrome };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_BATH")]                  = { Icon = "[ICON_DISTRICT_BATH]", Instance = self.m_Instance.CityBuiltDistrictBath };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_CAMPUS")]                = { Icon = "[ICON_DISTRICT_CAMPUS]", Instance = self.m_Instance.CityBuiltDistrictCampus };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_COMMERCIAL_HUB")]        = { Icon = "[ICON_DISTRICT_COMMERCIAL_HUB]", Instance = self.m_Instance.CityBuiltDistrictCommercial };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_ENCAMPMENT")]            = { Icon = "[ICON_DISTRICT_ENCAMPMENT]", Instance = self.m_Instance.CityBuiltDistrictEncampment };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_ENTERTAINMENT_COMPLEX")] = { Icon = "[ICON_DISTRICT_ENTERTAINMENT_COMPLEX]", Instance = self.m_Instance.CityBuiltDistrictEntertainment };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_HANSA")]                 = { Icon = "[ICON_DISTRICT_HANSA]", Instance = self.m_Instance.CityBuiltDistrictHansa };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_HARBOR")]                = { Icon = "[ICON_DISTRICT_HARBOR]", Instance = self.m_Instance.CityBuiltDistrictHarbor };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_HOLY_SITE")]             = { Icon = "[ICON_DISTRICT_HOLY_SITE]", Instance = self.m_Instance.CityBuiltDistrictHoly };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_INDUSTRIAL_ZONE")]       = { Icon = "[ICON_DISTRICT_INDUSTRIAL_ZONE]", Instance = self.m_Instance.CityBuiltDistrictIndustrial };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_LAVRA")]                 = { Icon = "[ICON_DISTRICT_LAVRA]", Instance = self.m_Instance.CityBuiltDistrictLavra };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_MBANZA")]                = { Icon = "[ICON_DISTRICT_MBANZA]", Instance = self.m_Instance.CityBuiltDistrictMbanza };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_NEIGHBORHOOD")]          = { Icon = "[ICON_DISTRICT_NEIGHBORHOOD]", Instance = self.m_Instance.CityBuiltDistrictNeighborhood };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_OBSERVATORY")]           = { Icon = "[ICON_DISTRICT_OBSERVATORY]", Instance = self.m_Instance.CityBuiltDistrictObservatory };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_ROYAL_NAVY_DOCKYARD")]   = { Icon = "[ICON_DISTRICT_ROYAL_NAVY_DOCKYARD]", Instance = self.m_Instance.CityBuiltDistrictRoyalNavy };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_SPACEPORT")]             = { Icon = "[ICON_DISTRICT_SPACEPORT]", Instance = self.m_Instance.CityBuiltDistrictSpaceport };
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_STREET_CARNIVAL")]       = { Icon = "[ICON_DISTRICT_ENTERTAINMENT_COMPLEX]", Instance = self.m_Instance.CityBuiltDistrictStreetCarnival }; -- Icon uses Entertainment Complex (see XML)
        districts[CQUI_GetDistrictIndexSafe("DISTRICT_THEATER")]               = { Icon = "[ICON_DISTRICT_THEATER]", Instance = self.m_Instance.CityBuiltDistrictTheater };

        -- Checking if CityBuildDistrictAqueduct is not nil answers the question of whether or not m_Instance is valid
        if (self.m_Instance.CityBuiltDistrictAqueduct ~= nil) then
            self.m_Instance.CQUI_DistrictsContainer:SetHide(true);
            self.m_Instance.CQUI_DistrictAvailable:SetHide(true);
            self.m_Instance.CityUnlockedCitizen:SetHide(true);
            for k,v in pairs(districts) do
                districts[k].Instance:SetHide(true);
            end
        end
    end

    local pCityDistricts:table  = pCity:GetDistricts();
    if (IsCQUI_SmartBannerEnabled() and IsCQUI_CityBannerXMLLoaded() and self.m_Instance.CityBuiltDistrictAqueduct ~= nil) then
        --Unlocked citizen check
        if (IsCQUI_SmartBanner_Unmanaged_CitizenEnabled()) then
            local tParameters :table = {};
            tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);

            local tResults  :table = CityManager.GetCommandTargets( pCity, CityCommandTypes.MANAGE, tParameters );
            if tResults ~= nil then
                local tPlots       :table = tResults[CityCommandResults.PLOTS];
                local tUnits       :table = tResults[CityCommandResults.CITIZENS];
                local tMaxUnits    :table = tResults[CityCommandResults.MAX_CITIZENS];
                local tLockedUnits :table = tResults[CityCommandResults.LOCKED_CITIZENS];
                if tPlots ~= nil and (table.count(tPlots) > 0) then
                    for i,plotId in pairs(tPlots) do
                        local kPlot :table = Map.GetPlotByIndex(plotId);
                        if (tMaxUnits[i] >= 1 and tUnits[i] >= 1 and tLockedUnits[i] <= 0) then
                            self.m_Instance.CityUnlockedCitizen:SetHide(false);
                            self.m_Instance.CityUnlockedCitizen:SetToolTipString(Locale.Lookup("LOC_CQUI_SMARTBANNER_UNLOCKEDCITIZEN_TOOLTIP"));
                        end
                    end
                end
            end
        end
        -- End Unlocked Citizen Check

        if (IsCQUI_SmartBanner_DistrictsEnabled()) then
            local districtTooltipString = "";
            local districtsBuilt = 0;
            local neighborhoodAdded = false;
            for i, district in pCityDistricts:Members() do
                local districtType = district:GetType();
                local districtInfo:table = GameInfo.Districts[districtType];
                local isBuilt = pCityDistricts:HasDistrict(districtInfo.Index, true);
                if (isBuilt) then
                    -- Items in the districts table are populated above; it does not include City Center or 
                    if (districts[districtType] ~= nil
                       and (districts[districtType].Instance ~= self.m_Instance.CityBuiltDistrictNeighborhood or neighborhoodAdded == false)) then
                        districtTooltipString = districtTooltipString .. districts[districtType].Icon .. " " .. Locale.Lookup(districtInfo.Name) .. "[NEWLINE]";
                        districtsBuilt = districtsBuilt + 1;
                        districts[districtType].Instance:SetHide(false);
                        if (districts[districtType].Instance == self.m_Instance.CityBuiltDistrictNeighborhood) then
                            neighborhoodAdded = true;
                        end
                    end
                end -- if isBuilt
            end -- for loop

            -- Trim the trailing [NEWLINE]
            districtTooltipString = string.sub(districtTooltipString, 1, string.len(districtTooltipString) - 9);

            -- Determine the overlap of the district icons based on the number built
            -- Note: GetNumZonedDistrictsRequiringPopulation does not include Aqueducts or Neighborhoods
            -- The padding value was -12 before this dynamic calculation was introduced
            local districtIconPadding = 6 + districtsBuilt;
            if districtIconPadding < 8 then districtIconPadding = 8; end
            if districtIconPadding > 14 then districtIconPadding = 14; end
            self.m_Instance.CQUI_DistrictsContainer:SetHide(false);
            self.m_Instance.CQUI_Districts:SetStackPadding(districtIconPadding * -1);
            self.m_Instance.CQUI_Districts:CalculateSize();  -- Sets the correct banner width with the padding update
            self.m_Instance.CQUI_DistrictsContainer:SetToolTipString(districtTooltipString);
        end

        if (IsCQUI_SmartBanner_DistrictsAvailableEnabled()) then
            -- Infixo: 2020-07-08 district available flag and tooltip
            local iDistrictsNum:number         = pCityDistricts:GetNumZonedDistrictsRequiringPopulation();
            local iDistrictsPossibleNum:number = pCityDistricts:GetNumAllowedDistrictsRequiringPopulation();
            if iDistrictsPossibleNum > iDistrictsNum then
                self.m_Instance.CQUI_DistrictAvailable:SetHide(false);
                self.m_Instance.CQUI_DistrictAvailable:SetToolTipString( string.format("%s %d / %d", Locale.Lookup("LOC_HUD_DISTRICTS"), iDistrictsNum, iDistrictsPossibleNum) );
            else
                self.m_Instance.CQUI_DistrictAvailable:SetHide(true);
            end
        end
    end -- if CQUI_SmartBanner and there's a district to show

    -- Update insufficient housing icon
    if (self.m_Instance.CityHousingInsufficientIcon ~= nil) then
        local pCityGrowth:table = pCity:GetGrowth();
        if (pCityGrowth and pCityGrowth:GetHousing() < pCity:GetPopulation()) then
            self.m_Instance.CityHousingInsufficientIcon:SetHide(false);
        else
            self.m_Instance.CityHousingInsufficientIcon:SetHide(true);
        end
    end

    -- Update insufficient amenities icon
    if (self.m_Instance.CityAmenitiesInsufficientIcon ~= nil) then
        local pCityGrowth:table = pCity:GetGrowth();
        if pCityGrowth and pCityGrowth:GetAmenitiesNeeded() > pCityGrowth:GetAmenities() then
            self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(false);
        else
            self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(true);
        end
    end

    -- Update occupied icon
    if (self.m_Instance.CityOccupiedIcon ~= nil) then
        if pCity:IsOccupied() then
            self.m_Instance.CityOccupiedIcon:SetHide(false);
        else
            self.m_Instance.CityOccupiedIcon:SetHide(true);
        end
    end

    -- CQUI: Show leader icon for the suzerain
    if (IsCQUI_CityBannerXMLLoaded()) then
        local pPlayerConfig :table = PlayerConfigurations[owner];
        local isMinorCiv :boolean = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
        if (isMinorCiv) then
            CQUI_UpdateCityStateBannerSuzerain(pPlayer, self);
            CQUI_UpdateCityStateBannerAtWarIcon(pPlayer, self);
        end
    end

    self.m_Instance.CityQuestIcon:SetToolTipString(questTooltip);
    self.m_Instance.CityQuestIcon:SetText(statusString);
    self.m_Instance.CityName:SetText( cityName );
    self.m_Instance.CityNameStack:ReprocessAnchoring();
    self.m_Instance.ContentStack:ReprocessAnchoring();
    self:Resize();
    -- print("CityBannerManager_CQUI: CityBanner.UpdateName EXIT");
end

-- ===========================================================================
-- CQUI CityBanner Replacement Functions
-- Functions that override the unmodified versions in the game
-- ===========================================================================
function CityBanner.SetHealthBarColor( self )
    -- The basegame file has a minor bug where if percent is exactly 0.40, then no color is set.
    -- print("CityBannerManager_CQUI: CityBanner.SetHealthBarColor ENTRY");
    if (self.m_Instance.CityHealthBar == nil) then
        -- This normal behaviour in the case of missile silo and aerodrome minibanners
        return;
    end

    local percent = self.m_Instance.CityHealthBar:GetPercent();
    if (percent > 0.80 ) then
        self.m_Instance.CityHealthBar:SetColor( COLOR_CITY_GREEN );
    elseif (percent > 0.40) then
        self.m_Instance.CityHealthBar:SetColor( COLOR_CITY_YELLOW );
    elseif (percent <= 0.40) then
        self.m_Instance.CityHealthBar:SetColor( COLOR_CITY_RED );
    end

    -- print("CityBannerManager_CQUI: CityBanner.SetHealthBarColor EXIT");
end

-- ===========================================================================
-- #59 Infixo overwritten because changes are deep inside it
function CityBanner.UpdateReligion(self)
    -- print("CityBannerManager_CQUI: CityBanner:UpdateReligion ENTRY");

    local cityInst          :table = self.m_Instance;
    local pCity             :table = self:GetCity();
    local pCityReligion     :table = pCity:GetReligion();
    local localPlayerID     :number = Game.GetLocalPlayer();
    local eMajorityReligion :number = pCityReligion:GetMajorityReligion();
    local religionsInCity   :table = pCityReligion:GetReligionsInCity();
    local religionInfo      :table = {};
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        -- The instance for the basegame banner is built or pointed at later on in this function
        -- For some reason or other, creating that instance here results in an error
        religionInfo = cityInst.ReligionInfo;
    end

    self.m_eMajorityReligion = eMajorityReligion;

    if (g_bIsBaseGame) then
        -- The Basegame has the ReligionBannerIcon for the color, Expansions do not have this container
        if (eMajorityReligion > 0) then
            local iconName : string = "ICON_" .. GameInfo.Religions[eMajorityReligion].ReligionType;
            local majorityReligionColor : number = UI.GetColorValue(GameInfo.Religions[eMajorityReligion].Color);
            if (majorityReligionColor ~= nil) then
                self.m_Instance.ReligionBannerIcon:SetColor(majorityReligionColor);
            end
            local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName,22);
            if (textureOffsetX ~= nil) then
                self.m_Instance.ReligionBannerIcon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
            end
            self.m_Instance.ReligionBannerIconContainer:SetHide(false);
            self.m_Instance.ReligionBannerIconContainer:SetToolTipString(Game.GetReligion():GetName(eMajorityReligion));
        elseif (pCityReligion:GetActivePantheon() >= 0) then
            local iconName : string = "ICON_" .. GameInfo.Religions[0].ReligionType;
            local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName,22);
            if (textureOffsetX ~= nil) then
                self.m_Instance.ReligionBannerIcon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
            end
            self.m_Instance.ReligionBannerIconContainer:SetHide(false);
            self.m_Instance.ReligionBannerIconContainer:SetToolTipString(Locale.Lookup("LOC_HUD_CITY_PANTHEON_TT", GameInfo.Beliefs[pCityReligion:GetActivePantheon()].Name));
        else
            self.m_Instance.ReligionBannerIconContainer:SetHide(true);
        end
     
        self:Resize();
    else
        -- Only called in the Expansions code
        self:UpdateInfo(pCity);
    end
    

    -- Hide the meter and bail out if the religion lens isn't active
    if (not m_isReligionLensActive or table.count(religionsInCity) == 0) then
        if (g_bIsBaseGame and cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE] ~= nil and cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE].ReligionInfoContainer ~= nil) then
            cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE].ReligionInfoContainer:SetHide(true);
        elseif ((g_bIsRiseAndFall or g_bIsGatheringStorm) and religionInfo ~= nil and religionInfo.ReligionInfoContainer ~= nil) then
            religionInfo.ReligionInfoContainer:SetHide(true);
        end
        -- print("CityBannerManager_CQUI: CityBanner:UpdateReligion EXIT (Lens not active)");
        return;
    end

    -- Update religion icon + religious pressure animation
    local majorityReligionColor:number = COLOR_RELIGION_DEFAULT;
    if (eMajorityReligion >= 0) then
        majorityReligionColor = UI.GetColorValue(GameInfo.Religions[eMajorityReligion].Color);
    end
    
    -- Preallocate total fill so we can stagger the meters
    local totalFillPercent:number = 0;
    local iCityPopulation:number = pCity:GetPopulation();

    -- Get a list of religions present in this city
    local activeReligions:table = {};
    local pReligionsInCity:table = pCityReligion:GetReligionsInCity();
    for _, cityReligion in pairs(pReligionsInCity) do
        local religion:number = cityReligion.Religion;
        if religion == -1 then religion = 0; end -- #59 Infixo include a pantheon
            --if (religion >= 0) then
            local followers:number = cityReligion.Followers;
            local fillPercent:number = followers / iCityPopulation;
            totalFillPercent = totalFillPercent + fillPercent;

            table.insert(activeReligions, {
                Religion=religion,
                Followers=followers,
                Pressure=pCityReligion:GetTotalPressureOnCity(religion),
                LifetimePressure=cityReligion.Pressure,
                FillPercent=fillPercent,
                Color=GameInfo.Religions[religion].Color });
        --end
    end

    -- Sort religions by largest number of followers
    -- #59 Infixo sort by followers, then by lifetime pressure
    table.sort(activeReligions,
        function(a,b)
            if a.Followers ~= b.Followers then
                return a.Followers > b.Followers;
            else
                return a.LifetimePressure > b.LifetimePressure;
            end
        end
    );

    -- After sort update accumulative fill percent
    local accumulativeFillPercent = 0.0;
    for i, religion in ipairs(activeReligions) do
        accumulativeFillPercent = accumulativeFillPercent + religion.FillPercent;
        religion.AccumulativeFillPercent = accumulativeFillPercent;
    end

    if (table.count(activeReligions) > 0) then
        local localPlayerVis:table = PlayersVisibility[localPlayerID];
        if (localPlayerVis ~= nil) then
            -- Holy sites get a different color and texture
            local holySitePlotIDs:table = {};
            local cityDistricts:table = pCity:GetDistricts();
            local playerDistricts:table = self.m_Player:GetDistricts();
            for i, district in cityDistricts:Members() do
                local districtType:string = GameInfo.Districts[district:GetType()].DistrictType;
                if (districtType == "DISTRICT_HOLY_SITE") then
                    local locX:number = district:GetX();
                    local locY:number = district:GetY();
                    if localPlayerVis:IsVisible(locX, locY) then
                        local plot:table  = Map.GetPlot(locX, locY);
                        local holySiteFaithYield:number = district:GetReligionHealRate();
                        SpawnHolySiteIconAtLocation(locX, locY, "+" .. holySiteFaithYield);
                        holySitePlotIDs[plot:GetIndex()] = true;
                    end
                    break;
                end
            end

            -- Color hexes in this city the same color as religion
            local plots:table = Map.GetCityPlots():GetPurchasedPlots(pCity);
            if (table.count(plots) > 0) then
                UILens.SetLayerHexesColoredArea( m_HexColoringReligion, localPlayerID, plots, majorityReligionColor );
            end
        end
    end

    if (g_bIsBaseGame) then
        -- Basegame/Vanilla: Find or create religion info instance
        if cityInst.ReligionInfoAnchor and cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE] == nil then
            ContextPtr:BuildInstanceForControl( "ReligionInfoInstance", religionInfo, cityInst.ReligionInfoAnchor );
            cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE] = religionInfo;
        else
            religionInfo = cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE];
        end
    end

    if religionInfo then
        -- Create or reset icon instance manager
        local iconIM:table = cityInst[DATA_FIELD_RELIGION_ICONS_IM];
        if (iconIM == nil) then
            -- TODO what happens if this is a thing that does not exist?
            -- TODO update: it seemed to be okay maybe this just failed and we're protected later
            iconIM = InstanceManager:new("ReligionIconInstance", "ReligionIconContainer", religionInfo.ReligionInfoIconStack);
            cityInst[DATA_FIELD_RELIGION_ICONS_IM] = iconIM;
        else
            iconIM:ResetInstances();
        end

        -- Create or reset follower list instance manager
        local followerListIM:table = cityInst[DATA_FIELD_RELIGION_FOLLOWER_LIST_IM];
        if (followerListIM == nil) then
            followerListIM = InstanceManager:new("ReligionFollowerListInstance", "ReligionFollowerListContainer", religionInfo.ReligionFollowerListStack);
            cityInst[DATA_FIELD_RELIGION_FOLLOWER_LIST_IM] = followerListIM;
        else
            followerListIM:ResetInstances();
        end

        -- Create or reset pop chart instance manager
        local popChartIM:table = cityInst[DATA_FIELD_RELIGION_POP_CHART_IM];
        if (popChartIM == nil) then
            popChartIM = InstanceManager:new("ReligionPopChartInstance", "PopChartMeter", religionInfo.ReligionPopChartContainer);
            cityInst[DATA_FIELD_RELIGION_POP_CHART_IM] = popChartIM;
        else
            popChartIM:ResetInstances();
        end

        local populationChartTooltip:string = RELIGION_POP_CHART_TOOLTIP_HEADER;

        -- Add religion icons for each active religion
        for i,activeReligionInfo in ipairs(activeReligions) do
            local religionDef:table = GameInfo.Religions[activeReligionInfo.Religion];

            local icon = "ICON_" .. religionDef.ReligionType;
            local religionColor = UI.GetColorValue(religionDef.Color);
        
            -- The first index is the predominant religion. Label it as such.
            local religionName = "";
            if i == 1 then
                religionName = Locale.Lookup("LOC_CITY_BANNER_PREDOMINANT_RELIGION", Game.GetReligion():GetName(religionDef.Index));
            else
                religionName = Game.GetReligion():GetName(religionDef.Index);
            end

            -- Add icon to main icon list
            -- If our only active religion is the same religion we're being converted to don't show an icon for it
            --if numOfActiveReligions > 1 or nextReligion ~= activeReligionInfo.Religion then -- #59 Infixo show all religions
            local iconInst:table = iconIM:GetInstance();
            iconInst.ReligionIconButton:SetIcon(icon);
            iconInst.ReligionIconButton:SetColor(religionColor);
            iconInst.ReligionIconButtonBacking:SetColor(religionColor);
            -- #59 Infixo new field and tooltip
            if (IsCQUI_CityBannerXMLLoaded()) then
                iconInst.ReligionIconFollowers:SetText(activeReligionInfo.Followers);
                iconInst.ReligionIconContainer:SetToolTipString(Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP", religionName, activeReligionInfo.Followers, Round(activeReligionInfo.LifetimePressure)).."[NEWLINE]"..
                                                                Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", "+"..tostring(Round(activeReligionInfo.Pressure, 1))));
            else
                -- Apply tooltip to unmodified object
                iconInst.ReligionIconButtonBacking:SetToolTipString(religionName); 
            end
            --end

            -- Add followers to detailed info list
            local followerListInst:table = followerListIM:GetInstance();
            followerListInst.ReligionFollowerIcon:SetIcon(icon);
            followerListInst.ReligionFollowerIcon:SetColor(religionColor);
            followerListInst.ReligionFollowerIconBacking:SetColor(religionColor);
            followerListInst.ReligionFollowerCount:SetText(activeReligionInfo.Followers);
            followerListInst.ReligionFollowerPressure:SetText(Locale.Lookup("LOC_CITY_BANNER_RELIGIOUS_PRESSURE", Round(activeReligionInfo.Pressure)));

            -- Add the follower tooltip to the population chart tooltip
            local followerTooltip:string = Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP", religionName, activeReligionInfo.Followers, Round(activeReligionInfo.LifetimePressure));
            followerListInst.ReligionFollowerIconBacking:SetToolTipString(followerTooltip);
            populationChartTooltip = populationChartTooltip .. "[NEWLINE][NEWLINE]" .. followerTooltip;
        end

        religionInfo.ReligionPopChartContainer:SetToolTipString(populationChartTooltip);
        religionInfo.ReligionFollowerListStack:CalculateSize();
        religionInfo.ReligionFollowerListScrollPanel:CalculateInternalSize();
        religionInfo.ReligionFollowerListScrollPanel:ReprocessAnchoring();

        -- Add populations to pie chart in reverse order
        for i = #activeReligions, 1, -1 do
            local activeReligionInfo = activeReligions[i];
            local religionColor = UI.GetColorValue(activeReligionInfo.Color);

            local popChartInst:table = popChartIM:GetInstance();
            popChartInst.PopChartMeter:SetPercent(activeReligionInfo.AccumulativeFillPercent);
            popChartInst.PopChartMeter:SetColor(religionColor);
        end

        -- Update population pie chart majority religion icon
        if (eMajorityReligion > 0) then
            local iconName : string = "ICON_" .. GameInfo.Religions[eMajorityReligion].ReligionType;
            religionInfo.ReligionPopChartIcon:SetIcon(iconName);
            religionInfo.ReligionPopChartIcon:SetHide(false);
        else
            religionInfo.ReligionPopChartIcon:SetHide(true);
        end

        -- Show what religion we will eventually turn into
        local nextReligion = pCityReligion:GetNextReligion();
        local turnsTillNextReligion:number = pCityReligion:GetTurnsToNextReligion();
        if nextReligion and nextReligion ~= -1 and turnsTillNextReligion > 0 then
            local pNextReligionDef:table = GameInfo.Religions[nextReligion];

            -- Religion icon
            if religionInfo.ConvertingReligionIcon then
                local religionIcon = "ICON_" .. pNextReligionDef.ReligionType;
                religionInfo.ConvertingReligionIcon:SetIcon(religionIcon);
                local religionColor = UI.GetColorValue(pNextReligionDef.Color);
                religionInfo.ConvertingReligionIcon:SetColor(religionColor);
                religionInfo.ConvertingReligionIconBacking:SetColor(religionColor);
                religionInfo.ConvertingReligionIconBacking:SetToolTipString(Locale.Lookup(pNextReligionDef.Name));
            end

            -- Converting text
            local convertString = Locale.Lookup("LOC_CITY_BANNER_CONVERTS_IN_X_TURNS", turnsTillNextReligion);
            religionInfo.ConvertingReligionLabel:SetText(convertString);
            religionInfo.ReligionConversionTurnsStack:SetHide(false);

            -- If the turns till conversion are less than 10 play the warning flash animation
            religionInfo.ConvertingSoonAlphaAnim:SetToBeginning();
            if turnsTillNextReligion <= 10 then
                religionInfo.ConvertingSoonAlphaAnim:Play();
            else
                religionInfo.ConvertingSoonAlphaAnim:Stop();
            end
        else
            religionInfo.ReligionConversionTurnsStack:SetHide(true);
        end
        -- Show how much religion this city is exerting outwards
        local outwardReligiousPressure = pCityReligion:GetPressureFromCity();
        religionInfo.ExertedReligiousPressure:SetText(Locale.Lookup("LOC_CITY_BANNER_RELIGIOUS_PRESSURE", Round(outwardReligiousPressure)));

        -- Reset buttons to default state
        religionInfo.ReligionInfoButton:SetHide(false);
        religionInfo.ReligionInfoDetailedButton:SetHide(true);

        -- Register callbacks to open/close detailed info
        religionInfo.ReligionInfoButton:RegisterCallback( Mouse.eLClick, function() OnReligionInfoButtonClicked(religionInfo, pCity); end);
        religionInfo.ReligionInfoDetailedButton:RegisterCallback( Mouse.eLClick, function() OnReligionInfoDetailedButtonClicked(religionInfo, pCity); end);

        religionInfo.ReligionInfoContainer:SetHide(false);
    end

    -- print("CityBannerManager_CQUI: CityBanner:UpdateReligion EXIT");
end

-- ============================================================================
function OnCityBannerClick( playerID, cityID )
    -- print("CityBannerManager_CQUI: OnCityBannerClick ENTRY  playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        return;
    end

    local pCity = pPlayer:GetCities():FindID(cityID);
    if (pCity == nil) then
        -- print("CityBannerManager_CQUI: OnCityBannerClick EXIT (pCity nil)");
        return;
    end

    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        if (pPlayer:IsFreeCities()) then
            UI.LookAtPlotScreenPosition( pCity:GetX(), pCity:GetY(), 0.5, 0.5 );
            -- print("CityBannerManager_CQUI: OnCityBannerClick EXIT (FreeCity)");
            return;
        end
    end
    
    local localPlayerID;
    if (WorldBuilder.IsActive()) then
        localPlayerID = playerID;   -- If WorldBuilder is active, allow the user to select the city
    else
        localPlayerID = Game.GetLocalPlayer();
    end

    if (pPlayer:GetID() == localPlayerID) then
        UI.SelectCity( pCity );
        UI.SetCycleAdvanceTimer(0);     -- Cancel any auto-advance timer
        UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);
    elseif (localPlayerID == PlayerTypes.OBSERVER 
            or localPlayerID == PlayerTypes.NONE 
            or pPlayer:GetDiplomacy():HasMet(localPlayerID)) then
        LuaEvents.CQUI_CityviewDisable(); -- Make sure the cityview is disable
        local pPlayerConfig :table   = PlayerConfigurations[playerID];
        local isMinorCiv    :boolean = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
        -- print("clicked player " .. playerID .. " city.  IsMinor?: ",isMinorCiv);

        if UI.GetInterfaceMode() == InterfaceModeTypes.MAKE_TRADE_ROUTE then
            local plotID = Map.GetPlotIndex(pCity:GetX(), pCity:GetY());
            LuaEvents.CityBannerManager_MakeTradeRouteDestination( plotID );    
        else        
            if isMinorCiv then
                if UI.GetInterfaceMode() ~= InterfaceModeTypes.SELECTION then
                    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
                end
                LuaEvents.CityBannerManager_RaiseMinorCivPanel( playerID ); -- Go directly to a city-state
            else
                LuaEvents.CityBannerManager_TalkToLeader( playerID );
            end
        end
    end

    -- print("CityBannerManager_CQUI: OnCityBannerClick EXIT");
end

-- ===========================================================================
-- Basegame and Expansions call this two different things (OnCityRangeStrikeButtonClick and OnCityStrikeButtonClick, respectively)
function OnCityRangeStrikeButtonClick( playerID, cityID )
    -- print("CityBannerManager_CQUI: OnCityRangeStrikeButtonClick ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));

    -- Call the common code for handling the City Strike button
    CQUI_OnCityRangeStrikeButtonClick(playerID, cityID);
    -- print("CityBannerManager_CQUI: OnCityRangeStrikeButtonClick EXIT");
end

-- ===========================================================================
-- City Strike Button for the Expansion banners
function OnCityStrikeButtonClick( playerID, cityID )
    -- print("CityBannerManager_CQUI: OnCityStrikeButtonClick ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    CQUI_OnCityRangeStrikeButtonClick(playerID, cityID);
    -- print("CityBannerManager_CQUI: OnCityStrikeButtonClick EXIT");
end

-- ===========================================================================
function OnDistrictAddedToMap( playerID: number, districtID : number, cityID :number, districtX : number, districtY : number, districtType:number, percentComplete:number )
    -- print("CityBannerManager_CQUI: OnDistrictAddedToMap ENTRY playerID:"..tostring(playerID).." districtID:"..tostring(districtID).." cityID:"..tostring(cityID).." districtXY:"..tostring(districtX)..","..tostring(districtY).." districtType:"..tostring(districtType).." pctComplete:"..tostring(percentComplete));
    local pPlayer = Players[playerID];

    if (pPlayer == nil) then
        -- print("CityBannerManager_CQUI: OnDistrictAddedToMap playerID:"..tostring(playerID).." EXIT (player nil)");
        return;
    end

    local pDistrict = pPlayer:GetDistricts():FindID(districtID);
    if (pDistrict == nil) then
        -- print("CityBannerManager_CQUI: OnDistrictAddedToMap playerID:"..tostring(playerID).." EXIT (district nil)");
        return;
    end

    local pCity = pDistrict:GetCity();
    local cityID = pCity:GetID();
    if (pCity == nil) then
        -- It is possible that the city is not there yet. e.g. city-center district is placed, the city is placed immediately afterward.
        -- print("CityBannerManager_CQUI: OnDistrictAddedToMap playerID:"..tostring(playerID).." EXIT (city nil)");
        return;
    end

    -- Is the district at the city? i.e. its a city-center?
    if (pCity:GetX() == pDistrict:GetX() and pCity:GetY() == pDistrict:GetY()) then
        -- Yes, just update the city banner with the district ID.
        local cityBanner = GetCityBanner( playerID, pCity:GetID() );
        if (cityBanner ~= nil) then
            cityBanner.m_DistrictID = districtID;
            cityBanner:UpdateRangeStrike();
            cityBanner:UpdateStats();
            -- Vanilla/Basegame uses SetColor, Expansions use UpdateColor
            -- Otherwise this function is the same for both basegame and expansion
            if (cityBanner.UpdateColor ~= nil) then
                cityBanner:UpdateColor();
            else
                cityBanner:SetColor();
            end
        end
    else
        -- Create a banner for a district that is not the city-center
        local miniBanner = GetMiniBanner( playerID, districtID );
        if (miniBanner == nil and pDistrict:IsComplete()) then
            if (GameInfo.Districts[pDistrict:GetType()].AirSlots > 0) then
                if pDistrict:IsComplete() then
                    AddMiniBannerToMap( playerID, cityID, districtID, BANNERTYPE_AERODROME );
                end
            elseif (pDistrict:GetDefenseStrength() > 0) then
                if pDistrict:IsComplete() then
                    AddMiniBannerToMap( playerID, cityID, districtID, BANNERTYPE_ENCAMPMENT );
                end
            else
                AddMiniBannerToMap( playerID, cityID, districtID, BANNERTYPE_OTHER_DISTRICT );
            end
        elseif (miniBanner ~= nil and pDistrict:IsComplete()) then
            miniBanner:UpdateStats();
            miniBanner:UpdateRangeStrike();
            miniBanner:UpdatePosition();
        end
    end -- else not city center

    -- print("CityBannerManager_CQUI: OnDistrictAddedToMap playerID:"..tostring(playerID).." EXIT");
end

-- ===========================================================================
-- CQUI Custom Functions
-- ===========================================================================
function CQUI_OnLensLayerOn( layerNum:number )
    -- print("CityBannerManager_CQUI: CQUI_OnLensLayerOn ENTRY, layerNum: ", layerNum);
    if layerNum == m_HexColoringReligion then
        m_isReligionLensActive = true;
        RealizeReligion();
    end

    -- print("CityBannerManager_CQUI: CQUI_OnLensLayerOn EXIT");
end

-- ===========================================================================
function CQUI_OnLensLayerOff( layerNum:number )
    -- print("CityBannerManager_CQUI: CQUI_OnLensLayerOff ENTRY, layerNum:", layerNum);
    if layerNum == m_HexColoringReligion then
        m_isReligionLensActive = false;
        RealizeReligion();
    end

    -- print("CityBannerManager_CQUI: CQUI_OnLensLayerOff EXIT");
end

-- ===========================================================================
function CQUI_GetDistrictIndexSafe(sDistrict)
    if GameInfo.Districts[sDistrict] == nil then
        return -1;
    else 
        return GameInfo.Districts[sDistrict].Index;
    end
end

-- ===========================================================================
function CQUI_GetHousingString(pCity, cqui_HousingFromImprovementsCalc)
    -- print("CityBannerManager_CQUI: CQUI_GetHousingString ENTRY");
    -- TODO: Consider unifying what this looks like on the basegame and the expansions
    --       Basegame puts Turns left until Pop increase on left with housing value in brackets next to it
    local pCityGrowth   :table  = pCity:GetGrowth();
    local curPopulation :number = pCity:GetPopulation();

    local housingLeft = pCityGrowth:GetHousing() - pCityGrowth:GetHousingFromImprovements() + cqui_HousingFromImprovementsCalc - curPopulation;
    local housingLeftText = housingLeft;
    local housingLeftColor = "";
    if housingLeft > 1.5 then
        -- Green
        housingLeftColor = "StatGoodCS";
    elseif housingLeft > 0.5 and housingLeft <= 1.5 then
        -- Yellow
        housingLeftColor = "WarningMinor";
    else
        -- Bright Red
        housingLeftColor = "WarningMajor";
    end

    -- Add + to front of text if positive
    if (housingLeft > 0) then
        housingLeftText = "+"..housingLeftText;
    end

    local housingString = "[COLOR:"..housingLeftColor.."]"..housingLeft.."[ENDCOLOR]";

    -- returning two values, the UI string and the housing remaining value that was calculated
    -- print("CityBannerManager_CQUI: CQUI_GetHousingString EXIT");
    return housingString, housingLeft;
end

-- ===========================================================================
function CQUI_GetInstanceObject(instanceObj)
    retobj = nil;
    -- in XP1 and later the instance objects are arrays, and we very typically just need the first
    for _, inst in pairs(instanceObj.m_AllocatedInstances) do
        retobj = inst
        break
    end

    return retobj;
end

-- ===========================================================================
function CQUI_GetInstanceAt( plotIndex:number )
    -- Obtain an existing instance of plot info or allocate one if it doesn't already exist.
    -- plotIndex Game engine index of the plot (taken from PlotInfo)
    -- Enabling this print is very noisy
    -- print("CityBannerManager_CQUI: CQUI_GetInstanceAt ENTRY plotIndex:"..tostring(plotIndex));
    local pInstance:table = CQUI_UIWorldMap[plotIndex];

    if (pInstance == nil) then
        pInstance = CQUI_PlotIM:GetInstance();
        CQUI_UIWorldMap[plotIndex] = pInstance;
        local worldX:number, worldY:number = UI.GridToWorld( plotIndex );
        pInstance.Anchor:SetWorldPositionVal( worldX, worldY, 20 );
        -- Make it so that the button can't be clicked while it's in this temporary state, this stops it from blocking clicks intended for the citybanner
        pInstance.CitizenButton:SetConsumeMouseButton(false);
        pInstance.Anchor:SetHide( false );
    end

    -- print("CityBannerManager_CQUI: CQUI_GetInstanceAt EXIT");
    return pInstance;
end

-- ===========================================================================
function CQUI_Refresh_Banners()
    -- print("CityBannerManager_CQUI: CQUI_Refresh_Banners ENTRY");

    local pLocalPlayerVis:table = PlayersVisibility[Game.GetLocalPlayer()];
    if (pLocalPlayerVis ~= nil) then
        local players = Game.GetPlayers();
        for i, player in ipairs(players) do
            local playerID      :number = player:GetID();
            local pPlayerCities :table = players[i]:GetCities();
      
            for _, city in pPlayerCities:Members() do
                local cityID:number = city:GetID();
                RefreshBanner(playerID, cityID) -- CQUI : refresh the banner info
            end
        end
    end

    -- print("CityBannerManager_CQUI: CQUI_Refresh_Banners EXIT");
end

-- ===========================================================================
function CQUI_ReleaseInstanceAt( plotIndex:number)
    -- Enabling this print is very noisy
    -- print("CityBannerManager_CQUI: CQUI_ReleaseInstanceAt ENTRY plotIndex:"..tostring(plotIndex));
    local pInstance :table = CQUI_UIWorldMap[plotIndex];

    if (pInstance ~= nil) then
        pInstance.Anchor:SetHide( true );
        -- Return the button to normal so that it can be clicked again
        pInstance.CitizenButton:SetConsumeMouseButton(true);
        CQUI_UIWorldMap[plotIndex] = nil;
    end

    -- print("CityBannerManager_CQUI: CQUI_ReleaseInstanceAt EXIT");
end

-- ===========================================================================
-- When a banner is moused over, display the relevant yields and next culture plot
function CQUI_OnBannerMouseEnter(playerID: number, cityID: number)
    -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseEnter ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    if (CQUI_ShowYieldsOnCityHover == false or playerID ~= Game.GetLocalPlayer() or IsCQUI_CityBannerXMLLoaded() == false) then
        -- Doesn't make sense to show when not self; if wanting to show an allied player is desired, then code needs some cleanup 
        -- as it currently shows tiles for the local player city by that city ID value (cityID values are only unique per player, not universally)
        -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseEnter EXIT (ShowYieldsOnCityHover/CQUIXmlLoaded is false)");
        return;
    end

    CQUI_Hovering = true;
    -- Fix for lens being shown when other lenses are on.
    -- Don't show this lens if any unit is selected.
    -- This prevents the need to check if every lens is on or not, like builder, religious lens.
    if (CQUI_ShowCityManageAreaOnCityHover
          and not UILens.IsLayerOn(CQUI_CitizenManagement)
          and UI.GetInterfaceMode() == InterfaceModeTypes.SELECTION
          and UI.GetHeadSelectedUnit() == nil) then
        LuaEvents.CQUI_ShowCitizenManagement(cityID);
        CQUI_CityManageAreaShown = true;
    end

    local kPlayer = Players[playerID];
    local kCities = kPlayer:GetCities();
    local kCity   = kCities:FindID(cityID);

    local tParameters :table = {};
    tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);
    tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE]  = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);

    local tResults  :table = CityManager.GetCommandTargets( kCity, CityCommandTypes.MANAGE, tParameters );
    if tResults == nil then
        -- Add error message here
        -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseEnter EXIT (No command targets for Manage)");
        return;
    end

    local tPlots       :table = tResults[CityCommandResults.PLOTS];
    local tUnits       :table = tResults[CityCommandResults.CITIZENS];
    local tMaxUnits    :table = tResults[CityCommandResults.MAX_CITIZENS];
    local tLockedUnits :table = tResults[CityCommandResults.LOCKED_CITIZENS];

    local pCityCulture        :table  = kCity:GetCulture();
    local pNextPlotID         :number = pCityCulture:GetNextPlot();
    local TurnsUntilExpansion :number = pCityCulture:GetTurnsUntilExpansion();

    local yields :table = {};
    local yieldsIndex :table = {};

    if (tPlots ~= nil and table.count(tPlots) ~= 0 and UILens.IsLayerOn(CQUI_CitizenManagement) == false) then
        CQUI_YieldsOn = UserConfiguration.ShowMapYield();
        for i,plotId in pairs(tPlots) do
            local kPlot :table = Map.GetPlotByIndex(plotId);
            local workerCount = kPlot:GetWorkerCount();
            local index:number = kPlot:GetIndex();
            local pInstance :table =  CQUI_GetInstanceAt(index);
            local numUnits:number = tUnits[i];
            local maxUnits:number = tMaxUnits[i];

            if CQUI_ShowCitizenIconsOnCityHover then
                -- If this plot is getting worked
                if workerCount > 0 and kPlot:IsCity() == false then
                    pInstance.CitizenButton:SetHide(false);
                    pInstance.CitizenButton:SetTextureOffsetVal(0, 256);
                    if (CQUI_SmartWorkIcon) then
                        pInstance.CitizenButton:SetSizeVal(CQUI_SmartWorkIconSize, CQUI_SmartWorkIconSize);
                        pInstance.CitizenButton:SetAlpha(CQUI_SmartWorkIconAlpha);
                    else
                        pInstance.CitizenButton:SetSizeVal(CQUI_WorkIconSize, CQUI_WorkIconSize);
                        pInstance.CitizenButton:SetAlpha(CQUI_WorkIconAlpha);
                    end
                end

                if (tLockedUnits[i] > 0) then
                    pInstance.LockedIcon:SetHide(false);
                    if (CQUI_SmartWorkIcon) then
                        pInstance.LockedIcon:SetAlpha(CQUI_SmartWorkIconAlpha);
                    else
                        pInstance.LockedIcon:SetAlpha(CQUI_WorkIconAlpha);
                    end
                else
                    pInstance.LockedIcon:SetHide(true);
                end
            end

            table.insert(yields, plotId);
            yieldsIndex[index] = plotId;
        end
    end

    tResults = CityManager.GetCommandTargets(kCity, CityCommandTypes.PURCHASE, tParameters);
    if tResults == nil then
        -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseEnter EXIT (No command targets for Purchase)");
        return;
    end

    tPlots = tResults[CityCommandResults.PLOTS];
    if (tPlots ~= nil and table.count(tPlots) ~= 0 and UILens.IsLayerOn(CQUI_CitizenManagement) == false) then
        for i,plotId in pairs(tPlots) do
            local kPlot :table = Map.GetPlotByIndex(plotId);
            local index:number = kPlot:GetIndex();
            local pInstance :table =  CQUI_GetInstanceAt(index);

            if (index == pNextPlotID) then
                pInstance.CQUI_NextPlotLabel:SetString("[ICON_Turn]" .. Locale.Lookup("LOC_HUD_CITY_IN_TURNS" , TurnsUntilExpansion ) .. "   ");
                pInstance.CQUI_NextPlotButton:SetHide( false );
            end

            table.insert(yields, plotId);
            yieldsIndex[index] = plotId;
        end
    elseif (UILens.IsLayerOn(CQUI_CitizenManagement) == false) then
        local pInstance :table = CQUI_GetInstanceAt(pNextPlotID);
        if (pInstance ~= nil) then
            pInstance.CQUI_NextPlotLabel:SetString("[ICON_Turn]" .. Locale.Lookup("LOC_HUD_CITY_IN_TURNS" , TurnsUntilExpansion ) .. "   ");
            pInstance.CQUI_NextPlotButton:SetHide( false );
            CQUI_NextPlot4Away = pNextPlotID;
        end
    end

    if (CQUI_YieldsOn == false and not UILens.IsLayerOn(CQUI_CitizenManagement)) then
        UILens.SetLayerHexesArea(CQUI_CityYields, Game.GetLocalPlayer(), yields);
        UILens.ToggleLayerOn( CQUI_CityYields );
    end

    -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseEnter EXIT");
end

-- ===========================================================================
-- When a banner is moused over, and the mouse leaves the banner, remove display of the relevant yields and next culture plot
function CQUI_OnBannerMouseExit(playerID: number, cityID: number)
    -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseExit ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    if (not CQUI_Hovering) then
        -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseExit EXIT (not CQUI_Hovering)");
        return;
    end

    CQUI_YieldsOn = UserConfiguration.ShowMapYield();

    if (CQUI_YieldsOn == false and not UILens.IsLayerOn(CQUI_CitizenManagement)) then
        UILens.ClearLayerHexes( CQUI_CityYields );
    end

    local kPlayer = Players[playerID];
    local kCities = kPlayer:GetCities();
    local kCity = kCities:FindID(cityID);

    local tParameters :table = {};
    tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);
    tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE]  = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);

    local tResults  :table = CityManager.GetCommandTargets( kCity, CityCommandTypes.MANAGE, tParameters );

    if tResults == nil then
        -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseExit EXIT: CityManager.GetCommandTargets for type Manage returned nil!");
        return;
    end

    -- Astog: Fix for lens being cleared when having other lenses on
    if (CQUI_ShowCityManageAreaOnCityHover
          and UI.GetInterfaceMode() ~= InterfaceModeTypes.CITY_MANAGEMENT
          and CQUI_CityManageAreaShown) then
        LuaEvents.CQUI_ClearCitizenManagement()
        CQUI_CityManageAreaShown = false;
    end

    local tPlots    :table = tResults[CityCommandResults.PLOTS];

    if (tPlots ~= nil and table.count(tPlots) ~= 0) then
        for i,plotId in pairs(tPlots) do
            local kPlot :table = Map.GetPlotByIndex(plotId);
            local index:number = kPlot:GetIndex();
            pInstance = CQUI_ReleaseInstanceAt(index);
        end
    end

    tResults  = CityManager.GetCommandTargets( kCity, CityCommandTypes.PURCHASE, tParameters );
    tPlots    = tResults[CityCommandResults.PLOTS];
    if (tPlots ~= nil and table.count(tPlots) ~= 0) then
        for i,plotId in pairs(tPlots) do
            local kPlot :table = Map.GetPlotByIndex(plotId);
            local index:number = kPlot:GetIndex();
            pInstance = CQUI_ReleaseInstanceAt(index);
        end
    end

    if (CQUI_NextPlot4Away ~= nil) then
        pInstance = CQUI_ReleaseInstanceAt(CQUI_NextPlot4Away);
        CQUI_NextPlot4Away = nil;
    end

    -- print("CityBannerManager_CQUI: CQUI_OnBannerMouseExit EXIT");
end

-- ===========================================================================
-- CQUI update close to a culture bomb cities data and real housing from improvements
function CQUI_OnCityLostTileToCultureBomb(localPlayerID, x, y)
    -- print("CityBannerManager_CQUI: CQUI_OnCityLostTileToCultureBomb ENTRY localPlayerID:"..tostring(localPlayerID).." LocationXY:"..tostring(x)..","..tostring(y));
    local m_pCity:table = Players[localPlayerID]:GetCities();
    for i, pCity in m_pCity:Members() do
        if Map.GetPlotDistance( pCity:GetX(), pCity:GetY(), x, y ) <= 4 then
            local pCityID = pCity:GetID();
            CityManager.RequestCommand(pCity, CityCommandTypes.SET_FOCUS, nil);
        end
    end

    -- print("CityBannerManager_CQUI: CQUI_OnCityLostTileToCultureBomb EXIT");
end

-- ===========================================================================
-- Common handler for the City Strike Button (Vanilla and the expansions have 2 different functions for this)
function CQUI_OnCityRangeStrikeButtonClick( playerID, cityID )
    -- print("CityBannerManager_CQUI: CQUI_OnCityRangeStrikeButtonClick ENTRY localPlayerID:"..tostring(localPlayerID).." pCityID:"..tostring(pCityID));
    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        return;
    end

    local pCity = pPlayer:GetCities():FindID(cityID);
    if (pCity == nil) then
        -- print("CityBannerManager_CQUI: CQUI_OnCityRangeStrikeButtonClick EXIT (City not found)");
        return;
    end

    -- allow to leave the strike range mode on 2nd click
    if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_RANGE_ATTACK then
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
        LuaEvents.CQUI_Strike_Exit();
        -- print("CityBannerManager_CQUI: CQUI_OnCityRangeStrikeButtonClick EXIT (Leave StrikeRange Mode)");
        return;
    end

    -- Enter the range city mode on click (not on hover of a button, the old workaround)
    LuaEvents.CQUI_Strike_Enter();
    -- Allow to switch between different city range attack (clicking on the range button of one
    -- city and after on the range button of another city, without having to ESC or right click)
    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
    -- Fix for the range strike not showing odds window
    UI.DeselectAll();
    UI.SelectCity( pCity );
    UI.SetInterfaceMode(InterfaceModeTypes.CITY_RANGE_ATTACK);

    -- print("CityBannerManager_CQUI: CQUI_OnCityRangeStrikeButtonClick EXIT");
end

-- ===========================================================================
function CQUI_OnDiplomacyDeclareWarMakePeace( firstPlayerID, secondPlayerID )
    -- print("CityBannerManager_CQUI: CQUI_OnDiplomacyDeclareWarMakePeace ENTRY  firstplayerID:"..tostring(firstPlayerID).."  secondPlayerID:"..tostring(secondPlayerID));
    local localPlayerID = Game.GetLocalPlayer();
    if (localPlayerID == nil or IsCQUI_CityBannerXMLLoaded() == false) then
        -- print("CityBannerManager_CQUI: CQUI_OnDiplomacyDeclareWarMakePeace EXIT: Game.GetLocalPlayer returned nil!")
        return;
    end

    local pOtherPlayerID:number = nil;
    if (localPlayerID == firstPlayerID) then
        pOtherPlayerID = secondPlayerID;
    elseif (localPlayerID == secondPlayerID) then
        pOtherPlayerID = firstPlayerID;
    else
        -- Do nothing, return
        -- print("CityBannerManager_CQUI: CQUI_OnDiplomacyDeclareWarMakePeace EXIT: Local Player is neither firstPlayerID ("..tostring(firstPlayerID)..") nor secondPlayerID ("..tostring(secondPlayerID)..")");
        return;
    end

    pOtherPlayer = Players[pOtherPlayerID];
    if (pOtherPlayer ~= nil and pOtherPlayer:IsMinor()) then
        local pOtherPlayerCities = pOtherPlayer:GetCities();
        for _,cityInstance in pOtherPlayerCities:Members() do
            local bannerInstance = GetCityBanner(pOtherPlayerID, cityInstance:GetID());
            CQUI_UpdateCityStateBannerAtWarIcon(pOtherPlayer, bannerInstance);
            RefreshBanner(pOtherPlayerID, cityInstance:GetID())
        end
    end

    -- print("CityBannerManager_CQUI: CQUI_OnDiplomacyDeclareWarMakePeace EXIT");
end

-- ===========================================================================
-- Common handler for the District Strike Button
function CQUI_OnDistrictRangeStrikeButtonClick( playerID, districtID )
    -- print("CityBannerManager_CQUI: CQUI_OnDistrictRangeStrikeButtonClick ENTRY playerID:"..tostring(playerID).." districtID:"..tostring(districtID));
    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        -- print("CityBannerManager_CQUI: CQUI_OnDistrictRangeStrikeButtonClick EXIT (pPlayer == nil)");
        return;
    end

    local pDistrict = pPlayer:GetDistricts():FindID(districtID);
    if (pDistrict == nil) then
        -- print("CityBannerManager_CQUI: CQUI_OnDistrictRangeStrikeButtonClick EXIT (pDistrict == nil)");
        return;
    end;

    -- allow to leave the strike range mode on 2nd click
    if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_RANGE_ATTACK then
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
        -- print("CityBannerManager_CQUI: CQUI_OnDistrictRangeStrikeButtonClick EXIT (interface mode, leave on 2nd click)");
        return;
    end
    
    UI.DeselectAll();
    UI.SelectDistrict(pDistrict);
    -- CQUI (Azurency) : Look at the district plot
    UI.LookAtPlot(pDistrict:GetX(), pDistrict:GetY());
    UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_RANGE_ATTACK);
    -- print("CityBannerManager_CQUI: CQUI_OnDistrictRangeStrikeButtonClick EXIT");
end

-- ===========================================================================
function CQUI_OnInfluenceGiven()
    -- print("CityBannerManager_CQUI: CQUI_OnInfluenceGiven ENTRY");
    for i, pPlayer in ipairs(PlayerManager.GetAliveMinors()) do
        local iPlayer = pPlayer:GetID();
        -- AZURENCY : check if there's a CapitalCity
        if (pPlayer:GetCities():GetCapitalCity() ~= nil) then
            local iCapital = pPlayer:GetCities():GetCapitalCity():GetID();
            local bannerInstance = GetCityBanner(iPlayer, iCapital);
            CQUI_UpdateCityStateBannerSuzerain(pPlayer, bannerInstance);
        end
    end

    -- print("CityBannerManager_CQUI: CQUI_OnInfluenceGiven EXIT");
end

-- ===========================================================================
function CQUI_SetCityStrikeButtonLocation(cityBannerInstance, rotate, offsetY, anchor)
    cityBannerInstance.CityStrike:Rotate(rotate);
    cityBannerInstance.CityStrike:SetOffsetVal(0, offsetY);
    cityBannerInstance.CityStrike:SetAnchor(anchor);
end

-- ===========================================================================
function CQUI_UpdateCityStateBannerAtWarIcon( pCityState, bannerInstance )
    -- print("CityBannerManager_CQUI: CQUI_UpdateCityStateBannerAtWarIcon ENTRY");
    if (IsCQUI_CityBannerXMLLoaded()) then
        if (IsCQUI_ShowWarIconInCityStateBannerEnabled()) then
            local localPlayerID = Game.GetLocalPlayer();
            if (localPlayerID ~= nil
                and pCityState:GetDiplomacy() ~= nil
                and pCityState:GetDiplomacy():IsAtWarWith(localPlayerID)) then
                bannerInstance.m_Instance.CQUI_AtWarWithCSIcon:SetHide(false);
            else
                bannerInstance.m_Instance.CQUI_AtWarWithCSIcon:SetHide(true);
            end
        else
            bannerInstance.m_Instance.CQUI_AtWarWithCSIcon:SetHide(true);
        end
    end

    -- print("CityBannerManager_CQUI: CQUI_UpdateCityStateBannerAtWarIcon EXIT");
end

-- ===========================================================================
function CQUI_UpdateCityStateBannerSuzerain( pPlayer:table, bannerInstance )
    -- print("CityBannerManager_CQUI: CQUI_UpdateCityStateBannerSuzerain ENTRY  pPlayer:"..tostring(pPlayer).."  bannerInstance:"..tostring(bannerInstance));
    if (bannerInstance == nil) then
        -- print("CityBannerManager_CQUI: CQUI_UpdateCityStateBannerSuzerain EXIT (bannerInstance is nil)");
        return;
    end

    if (IsCQUI_CityBannerXMLLoaded() == false) then
        -- print("CityBannerManager_CQUI: CQUI_UpdateCityStateBannerSuzerain EXIT (CQUI XML not loaded)");
        return;
    end

    local pPlayerInfluence :table  = pPlayer:GetInfluence();
    local suzerainID :number = pPlayerInfluence:GetSuzerain();
    if (suzerainID ~= -1 and IsCQUI_ShowSuzerainInCityStateBannerEnabled()) then
        local pPlayerConfig :table  = PlayerConfigurations[suzerainID];
        local suzerainTooltip = Locale.Lookup("LOC_CITY_STATES_SUZERAIN_LIST") .. " ";
        local localPlayerID :number = Game.GetLocalPlayer();
        local pLocalPlayerDiplomacy :table = Players[localPlayerID]:GetDiplomacy();
        local suzerainTokens = pPlayerInfluence:GetMostTokensReceived();
        local localPlayerTokens = pPlayerInfluence:GetTokensReceived(localPlayerID);
        if (pLocalPlayerDiplomacy:HasMet(suzerainID) or suzerainID == Game.GetLocalPlayer()) then
            if (CQUI_ShowSuzerainInCityStateBanner == CQUI_ShowSuzerainLeaderIcon) then -- We confirmed above that the icon is to be shown
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetColor(UI.GetColorValueFromHexLiteral(0xFFFFFFFF));
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetIcon("ICON_" .. pPlayerConfig:GetLeaderTypeName());
            else
                local backColor, frontColor = UI.GetPlayerColors(suzerainID);
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetIcon("ICON_" ..  pPlayerConfig:GetCivilizationTypeName());
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetColor(frontColor);
                bannerInstance.m_Instance.CQUI_CivSuzerainIconBackground:SetColor(backColor);
            end

            if (suzerainID == Game.GetLocalPlayer()) then
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetToolTipString(suzerainTooltip .. Locale.Lookup("LOC_CITY_STATES_YOU"));
            else
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetToolTipString(suzerainTooltip .. Locale.Lookup(pPlayerConfig:GetPlayerName()));
            end
        else
            bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetIcon("ICON_LEADER_DEFAULT");
            bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetToolTipString(suzerainTooltip .. Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER"));
        end

        if (IsCQUI_ShowSuzerainLabelInCityStateBannerEnabled()) then
            bannerInstance.m_Instance.CQUI_SuzerainEnvoys:SetHide(false);
            bannerInstance.m_Instance.CQUI_SuzerainEnvoys:SetText(suzerainTokens);
            if (suzerainID == Game.GetLocalPlayer()) then
                bannerInstance.m_Instance.CQUI_LocalPlayerEnvoys:SetHide(true);
            else
                bannerInstance.m_Instance.CQUI_LocalPlayerEnvoys:SetText("[COLOR_RED]" .. localPlayerTokens .. "[ENDCOLOR]"); 
                bannerInstance.m_Instance.CQUI_LocalPlayerEnvoys:SetHide(false);
            end
        else
            bannerInstance.m_Instance.CQUI_LocalPlayerEnvoys:SetHide(true);
            bannerInstance.m_Instance.CQUI_SuzerainEnvoys:SetHide(true);
        end

        bannerInstance.m_Instance.CQUI_CivSuzerain:SetHide(false);
        bannerInstance:Resize();
    else
        bannerInstance.m_Instance.CQUI_CivSuzerain:SetHide(true);
    end

    -- print("CityBannerManager_CQUI: CQUI_UpdateCityStateBannerSuzerain EXIT");
end

-- ===========================================================================
function CQUI_OnLoadGameViewStateDone()
    -- Called when the LoadGame View is completed
    -- Workaround the weirdness with the City Banners showing up in the wrong place by calling the OnRefreshBannerPositions function,
    -- which finds all of the banners and updates their positions
    m_LoadGameViewStateComplete = true;
    OnRefreshBannerPositions();
    CQUI_Refresh_Banners();
end

-- ===========================================================================
-- CQUI Enhancements for Barbarian Clans Mode
-- ===========================================================================
-- This is called every turn and whenever an action associated with the Barbarian clans happens
-- it has enough information for us to do things with those banners
function UpdateTribeBannerConversionBar(barbarianTribeEntry : table)
    -- print("CityBannerManager_CQUI: UpdateTribeBannerConversionBar ENTRY");
    BASE_CQUI_UpdateTribeBannerConversionBar(barbarianTribeEntry);

    if (IsCQUI_CityBannerXMLLoaded() == false) then
        -- print("CityBannerManager_CQUI: UpdateTribeBannerConversionBar EXIT (CQUI XML not loaded)");
        return;
    end

    barbarianTribeEntry.BannerInstance.TribeIconBribedBacking:SetHide(true);
    barbarianTribeEntry.BannerInstance.BribedTurnsLeft:SetHide(true);
    barbarianTribeEntry.BannerInstance.TribeIconIncitedAgainstUsBacking:SetHide(true);
    barbarianTribeEntry.BannerInstance.TribeIconIncitedByUsBacking:SetHide(true);
    barbarianTribeEntry.BannerInstance.TribeRansomUnitBacking:SetHide(true);
    barbarianTribeEntry.BannerInstance.CanHireUnit:SetHide(true);

    local pBarbarianManager : table = Game.GetBarbarianManager();
    local tribeIndex : number = pBarbarianManager:GetTribeIndexAtLocation(barbarianTribeEntry.Plot:GetX(),barbarianTribeEntry.Plot:GetY());
    if (tribeIndex == nil) then
        -- print("** Could not find tribeIndex at plot: "..tostring(barbarianTribeEntry.Plot:GetX())..","..tostring(barbarianTribeEntry.Plot:GetY()));
        -- print("CityBannerManager_CQUI: UpdateTribeBannerConversionBar EXIT (no tribeIndex at plot)");
        return;
    end

    local localPlayerID : number = Game.GetLocalPlayer();
    local bribedTurnsRemaining : number = pBarbarianManager:GetTribeBribeTurnsRemaining(tribeIndex, localPlayerID);
    if (bribedTurnsRemaining > 0) then
        barbarianTribeEntry.BannerInstance.TribeIconBribedBacking:SetHide(false);
        barbarianTribeEntry.BannerInstance.BribedTurnsLeft:SetHide(false);
        barbarianTribeEntry.BannerInstance.BribedTurnsLeft:SetText(bribedTurnsRemaining);
        -- TODO: This string says "you bribed this unit", which doesn't make sense on the city banner, so it needs a custom string
        barbarianTribeEntry.BannerInstance.TribeIconBribedBacking:SetToolTipString(Locale.Lookup("LOC_BARBARIAN_STATUS_BRIBED", bribedTurnsRemaining));
    end

    -- Check if we incited them or if they were incited against us
    local inciteTargetID : number = pBarbarianManager:GetTribeInciteTargetPlayer(tribeIndex);
    if (inciteTargetID >= 0) then
        if (inciteTargetID == localPlayerID) then
            --Add incited against us to the unit tooltip
            local inciteSourcePlayer : table = PlayerConfigurations[pBarbarianManager:GetTribeInciteSourcePlayer(tribeIndex)];
            local inciteSourcePlayerName : string = inciteSourcePlayer:GetPlayerName();
            local toolTipString = Locale.Lookup("LOC_BARBARIAN_STATUS_INCITED_AGAINST_YOU", inciteSourcePlayerName);
            barbarianTribeEntry.BannerInstance.TribeIconIncitedAgainstUsBacking:SetHide(false);
            barbarianTribeEntry.BannerInstance.TribeIconIncitedAgainstUsBacking:SetToolTipString(toolTipString);
        else
            local inciteSourceID : number = pBarbarianManager:GetTribeInciteSourcePlayer(tribeIndex);
            if(inciteSourceID == localPlayerID)then
                --Add incited by us to the unit tooltip
                local inciteTargetPlayer : table = PlayerConfigurations[pBarbarianManager:GetTribeInciteTargetPlayer(tribeIndex)];
                local inciteTargetPlayerName : string = inciteTargetPlayer:GetPlayerName();
                local toolTipString = Locale.Lookup("LOC_BARBARIAN_STATUS_INCITED_BY_YOU", inciteTargetPlayerName);
                barbarianTribeEntry.BannerInstance.TribeIconIncitedByUsBacking:SetHide(false);
                barbarianTribeEntry.BannerInstance.TribeIconIncitedByUsBacking:SetToolTipString(toolTipString);
            end
        end
    end

    -- Check if they have a unit we can ransom, or if they can be hired
    local pTribePlotIndex = Map.GetPlotIndex(barbarianTribeEntry.Plot:GetX(),barbarianTribeEntry.Plot:GetY());
    local tParameters : table = {};
    tParameters[PlayerOperations.PARAM_PLOT_ONE] = pTribePlotIndex;
    if (localPlayerID ~= -1) then
        local bShowRansom = UI.CanStartPlayerOperation(localPlayerID, PlayerOperations.RANSOM_CLAN, tParameters, true);
        if (bShowRansom) then
            barbarianTribeEntry.BannerInstance.TribeRansomUnitBacking:SetHide(false);
            -- TODO: Add a string here for the ToolTip (this just says "Ransom Unit")
            barbarianTribeEntry.BannerInstance.TribeRansomUnitBacking:SetToolTipString(Locale.Lookup("LOC_UNITCOMMAND_TREAT_WITH_CLAN_RANSOM_DESCRIPTION"));
        end

        -- Calling HIRE_CLAN if you do not have a city will result in the game crashing
        local pActivePlayer = Players[localPlayerID];
        if (pActivePlayer:GetCities():GetCount() >= 1) then
            local bCanStartHire = UI.CanStartPlayerOperation(localPlayerID, PlayerOperations.HIRE_CLAN, tParameters, false);
            if (bCanStartHire) then
                -- I don't want an icon that shows on the bar like the others as this (you can hire a unit) would be something that is very common
                -- As the gold icons and similar cannot be made smaller than they already are... use an asterisk, consider something better later on?
                barbarianTribeEntry.BannerInstance.CanHireUnit:SetHide(false);
                barbarianTribeEntry.BannerInstance.CanHireUnit:SetText("*");
                -- TODO: Add a string for the tool tip - this just says "Hire Clan"
                barbarianTribeEntry.BannerInstance.CanHireUnit:SetToolTipString(Locale.Lookup("LOC_UNITCOMMAND_TREAT_WITH_CLAN_HIRE_DESCRIPTION"));
            end
        end
    end

    -- Calculate and set the proper width of the banner
    barbarianTribeEntry.BannerInstance.TribeStatusStack:CalculateSize();
    barbarianTribeEntry.BannerInstance.Banner_Base:SetSizeX(barbarianTribeEntry.BannerInstance.TribeStatusStack:GetSizeX() + 10);
    -- print("CityBannerManager_CQUI - UpdateTribeBannerConversionBar EXIT");
end

-- ===========================================================================
-- Utility Functions for use by the Basegame and Expansions CityBannerManager files
-- These functions are here in order to allow all CQUI Objects be declared as local
-- ===========================================================================
function IsBannerTypeCityCenter(bannerType)
    if (bannerType == BANNERTYPE_CITY_CENTER) then
        return true;
    end

    return false;
end

-- ===========================================================================
function IsCQUI_SmartBannerEnabled()
    return CQUI_SmartBanner;
end

-- ===========================================================================
function IsCQUI_SmartBanner_CulturalEnabled()
    return (CQUI_SmartBanner and CQUI_SmartBanner_Cultural);
end

-- ===========================================================================
function IsCQUI_SmartBanner_DistrictsEnabled()
    return (CQUI_SmartBanner and CQUI_SmartBanner_Districts);
end

-- ===========================================================================
function IsCQUI_SmartBanner_PopulationEnabled()
    return (CQUI_SmartBanner and CQUI_SmartBanner_Population);
end

-- ===========================================================================
function IsCQUI_SmartBanner_Unmanaged_CitizenEnabled()
    return (CQUI_SmartBanner and CQUI_SmartBanner_Unmanaged_Citizen);
end

-- ===========================================================================
function IsCQUI_SmartBanner_DistrictsAvailableEnabled()
    return (CQUI_SmartBanner and CQUI_SmartBanner_DistrictsAvailable);
end

-- ===========================================================================
function IsCQUI_ShowSuzerainInCityStateBannerEnabled()
    return (CQUI_SmartBanner and (CQUI_ShowSuzerainInCityStateBanner ~= CQUI_ShowSuzerainDisabled));
end

-- ===========================================================================
function IsCQUI_ShowSuzerainLabelInCityStateBannerEnabled()
    return (IsCQUI_ShowSuzerainInCityStateBannerEnabled() and CQUI_ShowSuzerainLabelInCityStateBanner);
end

-- ===========================================================================
function IsCQUI_ShowWarIconInCityStateBannerEnabled()
    return (CQUI_SmartBanner and CQUI_ShowWarIconInCityStateBanner);
end

-- ===========================================================================
-- Used for checking to see if the XML is actually loaded
local CQUI_IssuedMissingXMLWarning = false;
function IsCQUI_CityBannerXMLLoaded()
    retVal = true;

    if (g_bIsGatheringStorm) then
        retVal = retVal and (Controls.CQUI_EmptyContainer_CityBannerInstances_Exp2 ~= nil);
        retVal = retVal and (Controls.CQUI_EmptyContainer_CityReligionInstances_Exp2 ~= nil);
    elseif (g_bIsRiseAndFall) then
        retVal = retVal and (Controls.CQUI_EmptyContainer_CityBannerInstances_Exp1 ~= nil);
        retVal = retVal and (Controls.CQUI_EmptyContainer_CityReligionInstances_Exp1 ~= nil);
    end

    -- This control is in basegame and the expansions, in CityBannerManager.xml
    retVal = retVal and (Controls.CQUI_WorkedPlotContainer ~= nil);

    if (retVal == false and CQUI_IssuedMissingXMLWarning == false) then
        -- prints in the log once, so we don't spam the thing
        print("****** CQUI ERROR: One or more of the CQUI version of the City Bannner XML files did not load properly!  CQUI effects cannot applied!");
        CQUI_IssuedMissingXMLWarning = true;
    end

    return retVal;
end

-- ===========================================================================
-- Game Engine EVENT
-- ===========================================================================
function OnCityWorkerChanged(ownerPlayerID:number, cityID:number)
    -- print("CityBannerManager_CQUI: OnCityWorkerChanged ENTRY ownerPlayerID:"..tostring(ownerPlayerID).." cityID:"..tostring(cityID));
    if (Game.GetLocalPlayer() == ownerPlayerID) then
        RefreshBanner( ownerPlayerID, cityID )
    end

    -- print("CityBannerManager_CQUI: OnCityWorkerChanged EXIT");
end

-- ===========================================================================
-- CQUI Initialize Function
-- ===========================================================================
function Initialize()
    -- Note: since the Firaxis CityBannerManager.lua does an "Include" of this file
    --       the existing "Initialize" can be replaced in this manner.
    --       "Inititalize" is not called by that original CityBannerManager.lua file until after the Include is done.
    -- print("CityBannerManager_CQUI: Initialize ENTRY");
    BASE_CQUI_Initialize();
    if (IsCQUI_CityBannerXMLLoaded()) then
        CQUI_PlotIM = InstanceManager:new( "CQUI_WorkedPlotInstance", "Anchor", Controls.CQUI_WorkedPlotContainer );
    end

    -- CQUI related events, which still have some function even if the XML is not loaded
    LuaEvents.CQUI_CityLostTileToCultureBomb.Add(CQUI_OnCityLostTileToCultureBomb);    -- CQUI update close to a culture bomb cities data and real housing from improvements
    LuaEvents.CQUI_CityRangeStrike.Add(CQUI_OnCityRangeStrikeButtonClick); -- AZURENCY : to acces it in the actionpannel on the city range attack button
    LuaEvents.CQUI_DistrictRangeStrike.Add(CQUI_OnDistrictRangeStrikeButtonClick); -- AZURENCY : to acces it in the actionpannel on the district range attack button
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);

    Events.CitySelectionChanged.Add(CQUI_OnBannerMouseExit);
    Events.CityWorkerChanged.Add(OnCityWorkerChanged);
    Events.InfluenceGiven.Add(CQUI_OnInfluenceGiven);
    Events.LensLayerOff.Add(CQUI_OnLensLayerOff);
    Events.LensLayerOn.Add(CQUI_OnLensLayerOn);
    -- Workaround for issue where the Banners appear in weird places or not at all
    Events.LoadGameViewStateDone.Add(CQUI_OnLoadGameViewStateDone);
    Events.DiplomacyDeclareWar.Add(CQUI_OnDiplomacyDeclareWarMakePeace);
    Events.DiplomacyMakePeace.Add(CQUI_OnDiplomacyDeclareWarMakePeace);
    -- print("CityBannerManager_CQUI: Initialize EXIT");
end
