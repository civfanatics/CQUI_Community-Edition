-- ===========================================================================
-- CQUI Common Functions to all CityBannerManager instances
-- This is what should go in the citybannermanager_CQUI file, the specific-to-basegame things go the _basegame file
-- ===========================================================================
include( "CityBannerManager" );
include( "CQUICommon.lua" );

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnCityBannerClick = OnCityBannerClick;
BASE_CQUI_OnGameDebugReturn = OnGameDebugReturn;
BASE_CQUI_OnInterfaceModeChanged = OnInterfaceModeChanged;
BASE_CQUI_OnShutdown = OnShutdown;
BASE_CQUI_Reload = Reload;

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
--  We have to re-do the declaration on the ones we need because they're declared as local in that other file

local COLOR_CITY_GREEN           = UI.GetColorValueFromHexLiteral(0xFF4CE710);
local COLOR_CITY_RED             = UI.GetColorValueFromHexLiteral(0xFF0101F5);
local COLOR_CITY_YELLOW          = UI.GetColorValueFromHexLiteral(0xFF2DFFF8);
local BANNERTYPE_CITY_CENTER     = 0;
local BANNERTYPE_ENCAMPMENT      = 1;
local BANNERTYPE_AERODROME       = 2;
local BANNERTYPE_MISSILE_SILO    = 3;
local BANNERTYPE_OTHER_DISTRICT  = 4;
local BANNERSTYLE_LOCAL_TEAM     = 0;
local BANNERSTYLE_OTHER_TEAM     = 1;

local CQUI_WorkIconSize       = 48;
local CQUI_WorkIconAlpha      = 0.60;
local CQUI_SmartWorkIcon      = true;
local CQUI_SmartWorkIconSize  = 64;
local CQUI_SmartWorkIconAlpha = 0.45;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
-- CQUI real housing from improvements tables
local CQUI_HousingFromImprovementsTable = {};
local CQUI_HousingUpdated               = {};

local CQUI_PlotIM        = InstanceManager:new( "CQUI_WorkedPlotInstance", "Anchor", Controls.CQUI_WorkedPlotContainer );
local CQUI_UIWorldMap    = {};
local CQUI_YieldsOn      = false;
local CQUI_Hovering      = false;
local CQUI_NextPlot4Away = nil;

local CQUI_ShowYieldsOnCityHover         = false;
local CQUI_ShowCitizenIconsOnCityHover   = false;
local CQUI_ShowCityManageAreaOnCityHover = true;
local CQUI_CityManageAreaShown           = false;
local CQUI_CityManageAreaShouldShow      = false;

local CQUI_SmartBanner                   = true;
local CQUI_SmartBanner_Unmanaged_Citizen = false;
local CQUI_SmartBanner_Districts         = true;
local CQUI_SmartBanner_Population        = true;
local CQUI_SmartBanner_Cultural          = true;

local CQUI_CityMaxBuyPlotRange = tonumber(GlobalParameters.CITY_MAX_BUY_PLOT_RANGE);
local CQUI_CityYields          = UILens.CreateLensLayerHash("City_Yields");
local CQUI_CitizenManagement   = UILens.CreateLensLayerHash("Citizen_Management");

-- ===========================================================================
function CQUI_OnSettingsInitialized()
    print_debug("CityBannerManager_CQUI: CQUI_OnSettingsInitialized ENTRY")
    CQUI_ShowYieldsOnCityHover  = GameConfiguration.GetValue("CQUI_ShowYieldsOnCityHover");
    CQUI_SmartBanner            = GameConfiguration.GetValue("CQUI_Smartbanner");
    CQUI_SmartBanner_Districts  = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_Districts");
    CQUI_SmartBanner_Population = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_Population");
    CQUI_SmartBanner_Cultural   = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_Cultural");
    CQUI_SmartBanner_Unmanaged_Citizen = CQUI_SmartBanner and GameConfiguration.GetValue("CQUI_Smartbanner_UnlockedCitizen");

    CQUI_WorkIconSize       = GameConfiguration.GetValue("CQUI_WorkIconSize");
    CQUI_WorkIconAlpha      = GameConfiguration.GetValue("CQUI_WorkIconAlpha") / 100;
    CQUI_SmartWorkIcon      = GameConfiguration.GetValue("CQUI_SmartWorkIcon");
    CQUI_SmartWorkIconSize  = GameConfiguration.GetValue("CQUI_SmartWorkIconSize");
    CQUI_SmartWorkIconAlpha = GameConfiguration.GetValue("CQUI_SmartWorkIconAlpha") / 100;

    CQUI_ShowCitizenIconsOnCityHover   = GameConfiguration.GetValue("CQUI_ShowCitizenIconsOnCityHover");
    CQUI_ShowCityManageAreaOnCityHover = GameConfiguration.GetValue("CQUI_ShowCityManageAreaOnCityHover");
    CQUI_ShowCityManageAreaInScreen    = GameConfiguration.GetValue("CQUI_ShowCityMangeAreaInScreen");
end

-- ===========================================================================
function CQUI_OnSettingsUpdate()
    print_debug("CityBannerManager_CQUI: CQUI_OnSettingsUpdate ENTRY")
    CQUI_OnSettingsInitialized();
    Reload();
end

-- ===========================================================================
-- Common code to both basegame and expansions during the CityBanner.Initialize function
function CQUI_Common_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle)
    -- Defined in the respective basegame/expansion files
    BASE_CQUI_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);

    if (self.m_Instance.CityBannerButton == nil) then
        return;
    end

    -- Register the MouseOver callbacks
    if (bannerType == BANNERTYPE_CITY_CENTER 
        and bannerStyle == BANNERSTYLE_LOCAL_TEAM 
        and playerID == Game.GetLocalPlayer()) then
        -- Register the callbacks 
        self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseEnter, CQUI_OnBannerMouseOver );
        self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseExit,  CQUI_OnBannerMouseExit );
    end
end

-- ===========================================================================
-- CQUI Extension Functions (Common to basegame and expansions)
-- Functions that enhance the unmodified versions
-- ===========================================================================
function OnCityBannerClick( playerID, cityID )
    print_debug("CityBannerManager_CQUI: OnCityBannerClick ENTRY  playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    BASE_CQUI_OnCityBannerClick(playerID, cityID);

    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        return;
    end

    if (pPlayer:GetID() == localPlayerID) then
        UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);
    elseif (localPlayerID == PlayerTypes.OBSERVER
            or localPlayerID == PlayerTypes.NONE
            or pPlayer:GetDiplomacy():HasMet(localPlayerID)) then
        LuaEvents.CQUI_CityviewDisable(); -- Make sure the cityview is disable
    end

    return;
end

-- ============================================================================
function OnGameDebugReturn( context:string, contextTable:table )
    print_debug("CityBannerManager_CQUI: OnGameDebugReturn ENTRY context:"..tostring(context).." contextTable:"..tostring(contextTable));
    if (context == "CityBannerManager") then
        -- CQUI cached values
        CQUI_HousingFromImprovementsTable = contextTable["CQUI_HousingFromImprovementsTable"];
        CQUI_HousingUpdated = contextTable["CQUI_HousingUpdated"];
        -- CQUI settings
        CQUI_OnSettingsUpdate();
    end

    BASE_CQUI_OnGameDebugReturn(context, contextTable);
end

-- ===========================================================================
function OnInterfaceModeChanged( oldMode:number, newMode:number )
    print_debug("CityBannerManager_CQUI: OnInterfaceModeChanged ENTRY");
    BASE_CQUI_OnInterfaceModeChanged(oldMode, newMode);

    if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
      CQUI_CityManageAreaShown = false;
      CQUI_CityManageAreaShouldShow = false;
    end
end

-- ===========================================================================
function OnProductionClick( playerID, cityID )
    print_debug("CityBannerManager_CQUI: OnProductionClick ENTRY");
    OnCityBannerClick( playerID, cityID);
end

-- ===========================================================================
function OnShutdown()
    print_debug("CityBannerManager_CQUI: OnShutdown ENTRY");
    -- CQUI values
    LuaEvents.GameDebug_AddValue("CityBannerManager", "CQUI_HousingFromImprovementsTable", CQUI_HousingFromImprovementsTable);
    LuaEvents.GameDebug_AddValue("CityBannerManager", "CQUI_HousingUpdated", CQUI_HousingUpdated);
    CQUI_PlotIM:DestroyInstances();

    BASE_CQUI_OnShutdown();
end

-- ===========================================================================
function Reload()
    print_debug("CityBannerManager_CQUI: Reload ENTRY");
    BASE_CQUI_Reload();

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
end

-- ============================================================================
-- CQUI Replacement Functions (Common to both basegame and expansions)
-- ============================================================================
function CityBanner.SetHealthBarColor( self )
    -- The basegame file has a minor bug where if percent is exactly 0.40, then no color is set.
    print_debug("CityBannerManager_CQUI: CityBanner.SetHealthBarColor ENTRY");
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
end

-- ===========================================================================
function OnDistrictAddedToMap( playerID, districtID, cityID, districtX, districtY, districtType, percentComplete )
    print_debug("CityBannerManager_CQUI: OnDistrictAddedToMap ENTRY playerID:"..tostring(playerID).." districtID:"..tostring(districtID).." cityID:"..tostring(cityID).." districtXY:"..tostring(districtX)..","..tostring(districtY).." districtType:"..tostring(districtType).." pctComplete:"..tostring(percentComplete));

    local locX = districtX;
    local locY = districtY;
    local type = districtType;

    local pPlayer = Players[playerID];

    if (pPlayer == nil) then
        return;
    end

    local pDistrict = pPlayer:GetDistricts():FindID(districtID);
    if (pDistrict == nil) then
        return;
    end

    local pCity = pDistrict:GetCity();
    local cityID = pCity:GetID();
    if (pCity == nil) then
        -- It is possible that the city is not there yet. e.g. city-center district is placed, the city is placed immediately afterward.
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

            -- CQUI update city's real housing from improvements when completed a district that triggers a Culture Bomb
            -- TODO: Is there no way to do this when the culture bomb happens?
            if (playerID == Game.GetLocalPlayer()) then
                if (districtType == GameInfo.Districts["DISTRICT_ENCAMPMENT"].Index) then
                    if (PlayerConfigurations[playerID]:GetCivilizationTypeName() == "CIVILIZATION_POLAND") then
                        CQUI_OnCityInfoUpdated(playerID, cityID);
                    end
                elseif (districtType == GameInfo.Districts["DISTRICT_HOLY_SITE"].Index or districtType == GameInfo.Districts["DISTRICT_LAVRA"].Index) then
                    if (PlayerConfigurations[playerID]:GetCivilizationTypeName() == "CIVILIZATION_KHMER") then
                        CQUI_OnCityInfoUpdated(playerID, cityID);
                    else
                        local playerReligion :table = pPlayer:GetReligion();
                        local playerReligionType :number = playerReligion:GetReligionTypeCreated();
                        if (playerReligionType ~= -1) then
                            local cityReligion :table = pCity:GetReligion();
                            local eDominantReligion :number = cityReligion:GetMajorityReligion();
                            if (eDominantReligion == playerReligionType) then
                                local pGameReligion :table = Game.GetReligion();
                                local pAllReligions :table = pGameReligion:GetReligions();
                                for _, kFoundReligion in ipairs(pAllReligions) do
                                    if (kFoundReligion.Religion == eDominantReligion) then
                                        for _, belief in pairs(kFoundReligion.Beliefs) do
                                            if (GameInfo.Beliefs[belief].BeliefType == "BELIEF_BURIAL_GROUNDS") then
                                                CQUI_OnCityInfoUpdated(playerID, cityID);
                                                break;
                                            end
                                        end

                                        break;
                                    end
                                end
                            end
                        end
                    end
                elseif (districtType == GameInfo.Districts["DISTRICT_HARBOR"].Index) then
                    if (PlayerConfigurations[playerID]:GetCivilizationTypeName() == "CIVILIZATION_NETHERLANDS") then
                        CQUI_OnCityInfoUpdated(playerID, cityID);
                    end
                elseif (districtType == GameInfo.Districts["DISTRICT_INDUSTRIAL_ZONE"].Index or districtType == GameInfo.Districts["DISTRICT_HANSA"].Index) then
                    local pGreatPeople :table  = Game.GetGreatPeople();
                    local pTimeline :table = pGreatPeople:GetPastTimeline();
                    for _, kPerson in ipairs(pTimeline) do
                        if (GameInfo.GreatPersonIndividuals[kPerson.Individual].GreatPersonIndividualType == "GREAT_PERSON_INDIVIDUAL_MIMAR_SINAN") then
                            if playerID == kPerson.Claimant then
                                CQUI_OnCityInfoUpdated(playerID, cityID);
                            end

                            break;
                        end
                    end
                end
            end
        elseif (miniBanner ~= nil and pDistrict:IsComplete()) then
            miniBanner:UpdateStats();
        end
    end -- else not city center
end

-- ===========================================================================
function OnImprovementAddedToMap(locX, locY, eImprovementType, eOwner)
    print_debug("CityBannerManager_CQUI: OnImprovementAddedToMap ENTRY locXY:"..tostring(locX)..","..tostring(locY).." eImprovementType:"..tostring(eImprovementType).." eOwner:"..tostring(eOwner));
    if eImprovementType == -1 then
        UI.DataError("Received -1 eImprovementType for ("..tostring(locX)..","..tostring(locY)..") and owner "..tostring(eOwner));
        return;
    end

    local improvementData:table = GameInfo.Improvements[eImprovementType];

    if improvementData == nil then
        UI.DataError("No database entry for eImprovementType #"..tostring(eImprovementType).." for ("..tostring(locX)..","..tostring(locY)..") and owner "..tostring(eOwner));
        return;
    end

    -- CQUI update city's real housing from improvements when built an improvement that triggers a Culture Bomb
    if (eOwner == Game.GetLocalPlayer()) then
        if (improvementData.ImprovementType == "IMPROVEMENT_FORT") then
            if (PlayerConfigurations[eOwner]:GetCivilizationTypeName() == "CIVILIZATION_POLAND") then
                local ownerCity = Cities.GetPlotPurchaseCity(locX, locY);
                local cityID = ownerCity:GetID();
                CQUI_OnCityInfoUpdated(eOwner, cityID);
            end
        end
    end

    -- Right now we're only interested in the Airstrip improvement, or Mountain Tunnel/Road
    if (improvementData.AirSlots == 0 and improvementData.WeaponSlots == 0 and improvementData.ImprovementType ~= "IMPROVEMENT_MOUNTAIN_TUNNEL" and improvementData.ImprovementType ~= "IMPROVEMENT_MOUNTAIN_ROAD" ) then
        return;
    end

    local pPlayer:table = Players[eOwner];
    local localPlayerID:number = Game.GetLocalPlayer();
    if (pPlayer ~= nil) then
        local plotID = Map.GetPlotIndex(locX, locY);
        if (plotID ~= nil) then
            local miniBanner = GetMiniBanner( eOwner, plotID );
            if (miniBanner == nil) then
                if (improvementData.AirSlots > 0) then
                    --we're passing -1 as the cityID and the plotID as the districtID argument since Airstrips aren't associated with a city or a district
                    AddMiniBannerToMap( eOwner, -1, plotID, BANNERTYPE_AERODROME );
                elseif (improvementData.WeaponSlots > 0) then
                    local ownerCity = Cities.GetPlotPurchaseCity(locX, locY);
                    local cityID = ownerCity:GetID();
                    -- we're passing the plotID as the districtID argument because we need the location of the improvement
                    AddMiniBannerToMap( eOwner, cityID, plotID, BANNERTYPE_MISSILE_SILO );
                elseif (improvementData.ImprovementType == "IMPROVEMENT_MOUNTAIN_TUNNEL") then
                    AddMiniBannerToMap( eOwner, -1, plotID, BANNERTYPE_MOUNTAIN_TUNNEL );
                elseif (improvementData.ImprovementType == "IMPROVEMENT_MOUNTAIN_ROAD") then
                    AddMiniBannerToMap( eOwner, -1, plotID, BANNERTYPE_QHAPAQ_NAN);
                end
            else
                miniBanner:UpdateStats();
                miniBanner:UpdateColor();
            end
        end
    end
end

-- ===========================================================================
-- CQUI Custom Functions (Common to basegame and expansions)
-- ===========================================================================
function CQUI_GetHousingString(pCity, cqui_HousingFromImprovementsCalc)
    print_debug("CityBannerManager_CQUI: CQUI_GetHousingString ENTRY");
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
    return housingString, housingLeft;
end

-- ===========================================================================
-- CQUI calculate real housing from improvements
function CQUI_GetRealHousingFromImprovementsValue(pCity, localPlayerID)
    print_debug("CityBannerManager_CQUI: CQUI_GetRealHousingFromImprovementsValue ENTRY  pCity:"..tostring(pCity).." localPlayerID:"..tostring(localPlayerID).." pCityID:"..tostring(pCityID));
    local pCityID :number = pCity:GetID();
    if (CQUI_HousingUpdated[localPlayerID] == nil or CQUI_HousingUpdated[localPlayerID][pCityID] ~= true) then
        CQUI_RealHousingFromImprovements(pCity, localPlayerID, pCityID);
    end

    return CQUI_HousingFromImprovementsTable[localPlayerID][pCityID];
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
    -- Enabling this print_debug is very noisy
    -- print_debug("CityBannerManager_CQUI: CQUI_GetInstanceAt ENTRY plotIndex:"..tostring(plotIndex));
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

    return pInstance;
end

-- ===========================================================================
-- CQUI calculate real housing from improvements
function CQUI_RealHousingFromImprovements(pCity, localPlayerID, pCityID)
    -- NOTE: Housing Values from Improvements determined by adding integers, and halved once all housing has been calculated
    --       The basegame function doesn't include the half-value (e.g. as Non-Maya, 3 farms is 1.5, but basegame returns only 1).
    --       Basegame also appears to consider the Maya as +1 Housing in addition to the 0.5 for each farm (so, 1.5 for each Mayan farm)
    --       In basegame, when Maya have 2 farms, pCity:GetGrowth():GetHousingFromImprovements() will return a value of 3
    print_debug("CityBannerManager_CQUI: CQUI_RealHousingFromImprovements ENTRY  pCity:"..tostring(pCity).." localPlayerID:"..tostring(localPlayerID).." pCityID:"..tostring(pCityID));

    local cityX:number, cityY:number = pCity:GetX(), pCity:GetY();
    local iNumHousing:number = 0; 
    -- Add data from Housing field in Improvements divided by TilesRequired which is usually 2
    -- Checks all of the plots available to the city and gathers the housing value from any improved
    -- Logic for this calculation suggested by Infixio
    for _, plotIndex in ipairs(Map.GetCityPlots():GetPurchasedPlots(pCity)) do
        local pPlot:table = Map.GetPlotByIndex(plotIndex);
        if (pPlot ~= nil 
            and pPlot:GetImprovementType() > -1
            and not pPlot:IsImprovementPillaged()
            and Map.GetPlotDistance(cityX, cityY, pPlot:GetX(), pPlot:GetY()) <= CQUI_CityMaxBuyPlotRange) then
            local imprInfo:table = GameInfo.Improvements[pPlot:GetImprovementType()];
            iNumHousing = iNumHousing + (imprInfo.Housing / imprInfo.TilesRequired);
        end
    end

    local baseHousingFromImprovements = pCity:GetGrowth():GetHousingFromImprovements();
    -- This effectively adds any half values that may be missing
    local realHousingValue = baseHousingFromImprovements + Round(iNumHousing - math.floor(iNumHousing), 1);
    print_debug("CQUI_GetRealHousingFromImprovementsValue: BaseHousingFromImprovements: "..tostring(baseHousingFromImprovements).." iNumHousing: "..tostring(iNumHousing).."  Updated housing value: "..tostring(realHousingValue));

    if CQUI_HousingFromImprovementsTable[localPlayerID] == nil then
        CQUI_HousingFromImprovementsTable[localPlayerID] = {};
    end

    if CQUI_HousingUpdated[localPlayerID] == nil then
        CQUI_HousingUpdated[localPlayerID] = {};
    end

    CQUI_HousingFromImprovementsTable[localPlayerID][pCityID] =  realHousingValue;
    CQUI_HousingUpdated[localPlayerID][pCityID] = true;
    LuaEvents.CQUI_RealHousingFromImprovementsCalculated(pCityID, realHousingValue);
end

-- ===========================================================================
function CQUI_ReleaseInstanceAt( plotIndex:number)
    -- Enabling this print_debug is very noisy
    -- print_debug("CityBannerManager_CQUI: CQUI_ReleaseInstanceAt ENTRY plotIndex:"..tostring(plotIndex));
    local pInstance :table = CQUI_UIWorldMap[plotIndex];

    if (pInstance ~= nil) then
        pInstance.Anchor:SetHide( true );
        -- Return the button to normal so that it can be clicked again
        pInstance.CitizenButton:SetConsumeMouseButton(true);
        CQUI_UIWorldMap[plotIndex] = nil;
    end
end

-- ===========================================================================
-- CQUI update all cities real housing from improvements
function CQUI_OnAllCitiesInfoUpdated(localPlayerID)
    print_debug("CityBannerManager_CQUI: CQUI_OnCityInfoUpdated ENTRY localPlayerID:"..tostring(localPlayerID));
    local m_pCity:table = Players[localPlayerID]:GetCities();
    for i, pCity in m_pCity:Members() do
        local pCityID = pCity:GetID();
        CQUI_OnCityInfoUpdated(localPlayerID, pCityID)
    end
end

-- ===========================================================================
-- When a banner is moused over, display the relevant yields and next culture plot
function CQUI_OnBannerMouseOver(playerID: number, cityID: number)
    print_debug("CityBannerManager_CQUI: CQUI_OnBannerMouseOver ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    if (CQUI_ShowYieldsOnCityHover == false) then
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

        local plotCount = Map.GetPlotCount();

        if (CQUI_YieldsOn == false and not UILens.IsLayerOn(CQUI_CitizenManagement)) then
            UILens.SetLayerHexesArea(CQUI_CityYields, Game.GetLocalPlayer(), yields);
            UILens.ToggleLayerOn( CQUI_CityYields );
        end
    elseif (UILens.IsLayerOn(CQUI_CitizenManagement) == false) then
        local pInstance :table = CQUI_GetInstanceAt(pNextPlotID);
        if (pInstance ~= nil) then
            pInstance.CQUI_NextPlotLabel:SetString("[ICON_Turn]" .. Locale.Lookup("LOC_HUD_CITY_IN_TURNS" , TurnsUntilExpansion ) .. "   ");
            pInstance.CQUI_NextPlotButton:SetHide( false );
            CQUI_NextPlot4Away = pNextPlotID;
        end
    end
end

-- ===========================================================================
-- When a banner is moused over, and the mouse leaves the banner, remove display of the relevant yields and next culture plot
function CQUI_OnBannerMouseExit(playerID: number, cityID: number)
    print_debug("CityBannerManager_CQUI: CQUI_OnBannerMouseExit ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    if (not CQUI_Hovering) then
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
        print_debug("CQUI_OnBannerMouseExit: CityManager.GetCommandTargets returned nil!");
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
end

-- ===========================================================================
-- CQUI update city's real housing from improvements
function CQUI_OnCityInfoUpdated(localPlayerID, pCityID)
    print_debug("CityBannerManager_CQUI: CQUI_OnCityInfoUpdated ENTRY localPlayerID:"..tostring(localPlayerID).." pCityID:"..tostring(pCityID));
    CQUI_HousingUpdated[localPlayerID][pCityID] = nil;
end

-- ===========================================================================
-- CQUI update close to a culture bomb cities data and real housing from improvements
function CQUI_OnCityLostTileToCultureBomb(localPlayerID, x, y)
    print_debug("CityBannerManager_CQUI: CQUI_OnCityLostTileToCultureBomb ENTRY localPlayerID:"..tostring(localPlayerID).." LocationXY:"..tostring(x)..","..tostring(y));
    local m_pCity:table = Players[localPlayerID]:GetCities();
    for i, pCity in m_pCity:Members() do
        if Map.GetPlotDistance( pCity:GetX(), pCity:GetY(), x, y ) <= 4 then
            local pCityID = pCity:GetID();
            CQUI_OnCityInfoUpdated(localPlayerID, pCityID)
            CityManager.RequestCommand(pCity, CityCommandTypes.SET_FOCUS, nil);
        end
    end
end
-- ===========================================================================
-- CQUI erase real housing from improvements data everywhere when a city removed from map
function CQUI_OnCityRemovedFromMap(localPlayerID, pCityID)
    print_debug("CityBannerManager_CQUI: CQUI_OnCityRemovedFromMap ENTRY localPlayerID:"..tostring(localPlayerID).." pCityID:"..tostring(pCityID));
    if playerID == Game.GetLocalPlayer() then
        CQUI_HousingFromImprovementsTable[localPlayerID][pCityID] = nil;
        CQUI_HousingUpdated[localPlayerID][pCityID] = nil;
        LuaEvents.CQUI_RealHousingFromImprovementsCalculated(pCityID, nil);
    end
end

-- ===========================================================================
-- Common handler for the City Strike Button (Vanilla and the expansions have 2 different functions for this)
function CQUI_OnCityRangeStrikeButtonClick( playerID, cityID )
    print_debug("CityBannerManager_CQUI: CQUI_OnCityRangeStrikeButtonClick ENTRY localPlayerID:"..tostring(localPlayerID).." pCityID:"..tostring(pCityID));
    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        return;
    end

    local pCity = pPlayer:GetCities():FindID(cityID);
    if (pCity == nil) then
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
end

-- ===========================================================================
function CQUI_OnInfluenceGiven()
    print_debug("CityBannerManager_CQUI: CQUI_OnInfluenceGiven ENTRY");
    for i, pPlayer in ipairs(PlayerManager.GetAliveMinors()) do
        local iPlayer = pPlayer:GetID();
        -- AZURENCY : check if there's a CapitalCity
        if (pPlayer:GetCities():GetCapitalCity() ~= nil) then
            local iCapital = pPlayer:GetCities():GetCapitalCity():GetID();
            local bannerInstance = GetCityBanner(iPlayer, iCapital);
            CQUI_UpdateSuzerainIcon(pPlayer, bannerInstance);
        end
    end
end

-- ===========================================================================
function CQUI_UpdateSuzerainIcon( pPlayer:table, bannerInstance )
    print_debug("CityBannerManager_CQUI: CQUI_UpdateSuzerainIcon ENTRY");
    if (bannerInstance == nil) then
        return;
    end

    local pPlayerInfluence :table  = pPlayer:GetInfluence();
    local suzerainID       :number = pPlayerInfluence:GetSuzerain();
    if (suzerainID ~= -1) then
        local pPlayerConfig :table  = PlayerConfigurations[suzerainID];
        local leader        :string = pPlayerConfig:GetLeaderTypeName();
        if (GameInfo.CivilizationLeaders[leader] == nil) then
            UI.DataError("Banners found a leader \""..leader.."\" which is not/no longer in the game; icon may be whack.");
        else
            local suzerainTooltip = Locale.Lookup("LOC_CITY_STATES_SUZERAIN_LIST") .. " ";
            if (pPlayer:GetDiplomacy():HasMet(suzerainID)) then
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetIcon("ICON_" .. leader);
                if (suzerainID == Game.GetLocalPlayer()) then
                    bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetToolTipString(suzerainTooltip .. Locale.Lookup("LOC_CITY_STATES_YOU"));
                else
                    bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetToolTipString(suzerainTooltip .. Locale.Lookup(pPlayerConfig:GetPlayerName()));
                end
            else
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetIcon("ICON_LEADER_DEFAULT");
                bannerInstance.m_Instance.CQUI_CivSuzerainIcon:SetToolTipString(suzerainTooltip .. Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER"));
            end

            bannerInstance:Resize();
            bannerInstance.m_Instance.CQUI_CivSuzerain:SetOffsetX(bannerInstance.m_Instance.ContentStack:GetSizeX()/2 - 5);
            bannerInstance.m_Instance.CQUI_CivSuzerain:SetHide(false);
        end
    else
        bannerInstance.m_Instance.CQUI_CivSuzerain:SetHide(true);
    end
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
-- Game Engine EVENT
-- ===========================================================================
function OnCityWorkerChanged(ownerPlayerID:number, cityID:number)
    print_debug("CityBannerManager_CQUI: OnCityWorkerChanged ENTRY ownerPlayerID:"..tostring(ownerPlayerID).." cityID:"..tostring(cityID));
    if (Game.GetLocalPlayer() == ownerPlayerID) then
        RefreshBanner( ownerPlayerID, cityID )
    end
end

-- ===========================================================================
--  CQUI Initialize Function
-- ===========================================================================
function Initialize_CQUI()
    print_debug("CityBannerManager_CQUI: Initialize_CQUI CQUI CityBannerManager (Common File)")
    -- CQUI related events
    LuaEvents.CQUI_AllCitiesInfoUpdated.Add(CQUI_OnAllCitiesInfoUpdated);    -- CQUI update all cities real housing from improvements
    LuaEvents.CQUI_CityInfoUpdated.Add(CQUI_OnCityInfoUpdated);    -- CQUI update city's real housing from improvements
    LuaEvents.CQUI_CityLostTileToCultureBomb.Add(CQUI_OnCityLostTileToCultureBomb);    -- CQUI update close to a culture bomb cities data and real housing from improvements
    LuaEvents.CQUI_CityRangeStrike.Add(CQUI_OnCityRangeStrikeButtonClick); -- AZURENCY : to acces it in the actionpannel on the city range attack button
    LuaEvents.CQUI_DistrictRangeStrike.Add(OnDistrictRangeStrikeButtonClick); -- AZURENCY : to acces it in the actionpannel on the district range attack button
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);

    Events.CityRemovedFromMap.Add(CQUI_OnCityRemovedFromMap);    -- CQUI erase real housing from improvements data everywhere when a city removed from map
    Events.CitySelectionChanged.Add(CQUI_OnBannerMouseExit);
    Events.CityWorkerChanged.Add(OnCityWorkerChanged);
    Events.InfluenceGiven.Add(CQUI_OnInfluenceGiven);
end
Initialize_CQUI();
