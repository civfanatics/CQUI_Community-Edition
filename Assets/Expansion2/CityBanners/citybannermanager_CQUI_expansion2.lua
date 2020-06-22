-- ===========================================================================
-- Base File
-- ===========================================================================
-- Civ6 Expansion 2 replaces this file entirely
include( "CityBannerManager.lua" );
include( "CQUICommon.lua" );
include( "GameCapabilities" );

-- TEMP, until I can figure out why the setting in CQUICommon is not honored
CQUI_ShowDebugPrint = true;

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_CityBanner_Uninitialize = CityBanner.Uninitialize;
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_CityBanner_UpdatePopulation = CityBanner.UpdatePopulation;
BASE_CQUI_CityBanner_UpdateStats = CityBanner.UpdateStats;
BASE_CQUI_CityBanner_UpdateInfo = CityBanner.UpdateInfo;
BASE_CQUI_CityBanner_UpdateRangeStrike = CityBanner.UpdateRangeStrike;
BASE_CQUI_Reload = Reload;
BASE_CQUI_OnShutdown = OnShutdown;
BASE_CQUI_OnInterfaceModeChanged = OnInterfaceModeChanged;

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
--  We have to re-do the declaration on the ones we need because they're declared as local in that other file
local COLOR_CITY_GREEN       :number = UI.GetColorValueFromHexLiteral(0xFF4CE710);
local COLOR_CITY_RED         :number = UI.GetColorValueFromHexLiteral(0xFF0101F5);
local COLOR_CITY_YELLOW      :number = UI.GetColorValueFromHexLiteral(0xFF2DFFF8);

local BANNERSTYLE_LOCAL_TEAM :number = 0;
local BANNERSTYLE_OTHER_TEAM :number = 1;

local m_isReligionLensActive :boolean = false;
local m_isLoyaltyLensActive  :boolean = false;

-- ===========================================================================
--  CQUI Members
-- ===========================================================================

-- CQUI real housing from improvements tables
local CQUI_HousingFromImprovementsTable :table = {};
local CQUI_HousingUpdated :table = {};

-- CQUI taken from PlotInfo
local CQUI_ShowYieldsOnCityHover = false;
local CQUI_PlotIM        :table = InstanceManager:new( "CQUI_WorkedPlotInstance", "Anchor", Controls.CQUI_WorkedPlotContainer );
local CQUI_uiWorldMap    :table = {};
local CQUI_yieldsOn      :boolean = false;
local CQUI_Hovering      :boolean = false;
local CQUI_NextPlot4Away :number = nil;

local CQUI_ShowCitizenIconsOnCityHover   :boolean = false;
local CQUI_ShowCityManageAreaOnCityHover :boolean = true;
local CQUI_CityManageAreaShown           :boolean = false;
local CQUI_CityManageAreaShouldShow      :boolean = false;

local CQUI_WorkIconSize      :number  = 48;
local CQUI_WorkIconAlpha              = 0.60;
local CQUI_SmartWorkIcon     :boolean = true;
local CQUI_SmartWorkIconSize :number  = 64;
local CQUI_SmartWorkIconAlpha         = 0.45;
local CQUI_SmartBanner                   = true;
local CQUI_SmartBanner_Unmanaged_Citizen    :boolean = false;
local CQUI_SmartBanner_Districts            :boolean = true;
local CQUI_SmartBanner_Population           :boolean = true;
-- TODO: This only exists in the Basegame version... should this also be in Expansion2?
--       Would need to look at self.m_Instance.CityCultureTurnsLeft and the XML as well...
local CQUI_SmartBanner_Cultural             :boolean = true; 

local CQUI_cityMaxBuyPlotRange :number = tonumber(GlobalParameters.CITY_MAX_BUY_PLOT_RANGE);
local CQUI_CityYields          :number = UILens.CreateLensLayerHash("City_Yields");
local CQUI_CitizenManagement   :number = UILens.CreateLensLayerHash("Citizen_Management");

-- ============================================================================
function CQUI_OnSettingsInitialized()
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnSettingsInitialized ENTRY")
    CQUI_ShowYieldsOnCityHover = GameConfiguration.GetValue("CQUI_ShowYieldsOnCityHover");
    CQUI_SmartBanner = GameConfiguration.GetValue("CQUI_Smartbanner");
    CQUI_SmartBanner_Unmanaged_Citizen = GameConfiguration.GetValue("CQUI_Smartbanner_UnlockedCitizen");
    CQUI_SmartBanner_Districts = GameConfiguration.GetValue("CQUI_Smartbanner_Districts");
    CQUI_SmartBanner_Population = GameConfiguration.GetValue("CQUI_Smartbanner_Population");

    CQUI_WorkIconSize = GameConfiguration.GetValue("CQUI_WorkIconSize");
    CQUI_WorkIconAlpha = GameConfiguration.GetValue("CQUI_WorkIconAlpha") / 100;
    CQUI_SmartWorkIcon = GameConfiguration.GetValue("CQUI_SmartWorkIcon");
    CQUI_SmartWorkIconSize = GameConfiguration.GetValue("CQUI_SmartWorkIconSize");
    CQUI_SmartWorkIconAlpha = GameConfiguration.GetValue("CQUI_SmartWorkIconAlpha") / 100;

    CQUI_ShowCitizenIconsOnCityHover = GameConfiguration.GetValue("CQUI_ShowCitizenIconsOnCityHover");
    CQUI_ShowCityManageAreaOnCityHover = GameConfiguration.GetValue("CQUI_ShowCityManageAreaOnCityHover");
    CQUI_ShowCityManageAreaInScreen = GameConfiguration.GetValue("CQUI_ShowCityMangeAreaInScreen");
end

-- ============================================================================
function CQUI_OnSettingsUpdate()
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnSettingsUpdate ENTRY");
    CQUI_OnSettingsInitialized();
    Reload();
end
LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );

-- ============================================================================
-- CQUI Extension Functions
-- ============================================================================
function CityBanner.Uninitialize(self)
    print_debug("CityBannerManager_CQUI_Expansion2: CityBanner.Uninitialize ENTRY");
    BASE_CQUI_CityBanner_Uninitialize(self);

    -- CQUI : Clear CQUI_DistrictBuiltIM
    if self.CQUI_DistrictBuiltIM then
        self.CQUI_DistrictBuiltIM:DestroyInstances();
    end
end

-- ============================================================================
function CityBanner.Initialize(self, playerID: number, cityID : number, districtID : number, bannerType : number, bannerStyle : number)
    print_debug("CityBannerManager_CQUI_Expansion2: CityBanner:Initialize ENTRY: playerID:"..tostring(playerID).." cityID:"..tostring(cityID).." districtID:"..tostring(districtID).." bannerType:"..tostring(bannerType).." bannerStyle:"..tostring(bannerStyle));
    BASE_CQUI_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);
    
    if (bannerType == BANNERTYPE_CITY_CENTER) then
        if self.CQUI_DistrictBuiltIM == nil then
            self.CQUI_DistrictBuiltIM = InstanceManager:new( "CQUI_DistrictBuilt", "Icon", self.m_Instance.CQUI_Districts );
        end
    end

    if (bannerType == BANNERTYPE_CITY_CENTER 
        and bannerStyle == BANNERSTYLE_LOCAL_TEAM 
        and playerID == Game.GetLocalPlayer()) then
        self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseEnter, CQUI_OnBannerMouseOver );
        self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseExit, CQUI_OnBannerMouseExit );
    end
end

-- ============================================================================
function CityBanner.UpdatePopulation(self, isLocalPlayer:boolean, pCity:table, pCityGrowth:table)
    print_debug("CityBannerManager_CQUI_Expansion2: CityBanner:UpdatePopulation:  pCity: "..tostring(pCity).."  pCityGrowth:"..tostring(pCityGrowth));
    BASE_CQUI_CityBanner_UpdatePopulation(self, isLocalPlayer, pCity, pCityGrowth);

    if (isLocalPlayer == false) then
        return;
    end

    local currentPopulation:number = pCity:GetPopulation();
    -- XP1+, grab the first instance
    local populationInstance = CQUI_GetFirstInstance(self.m_StatPopulationIM);

    -- Get real housing from improvements value
    local localPlayerID = Game.GetLocalPlayer();
    local pCityID = pCity:GetID();
    if (CQUI_HousingUpdated[localPlayerID] == nil or CQUI_HousingUpdated[localPlayerID][pCityID] ~= true) then
        CQUI_RealHousingFromImprovements(pCity, localPlayerID, pCityID);
    end

    local CQUI_housingLeftPopupText = "";
    -- CQUI : housing left
    if (CQUI_SmartBanner and CQUI_SmartBanner_Population) then
        local CQUI_HousingFromImprovements = CQUI_HousingFromImprovementsTable[localPlayerID][pCityID];    -- CQUI real housing from improvements value
        if (CQUI_HousingFromImprovements ~= nil) then    -- CQUI real housing from improvements fix to show correct values when waiting for the next turn
            local housingLeft = pCityGrowth:GetHousing() - pCityGrowth:GetHousingFromImprovements() + CQUI_HousingFromImprovements - currentPopulation; -- CQUI calculate real housing
            CQUI_housingLeftPopupText = housingLeft;

            local housingLeftColor = "StatNormalCS";
            if (housingLeft > 0.5 and housingLeft <= 1.5) then
                housingLeftColor = "WarningMinor";
            elseif (housingLeft <= 0.5) then
                housingLeftColor = "WarningMajor";
            end

            if (housingLeft >= 0.5) then
                housingLeft = "+"..housingLeft;
            end

            local housingText = "[COLOR:"..housingLeftColor.."]"..housingLeft.."[ENDCOLOR]";
            populationInstance.CQUI_CityHousing:SetText(housingText);
            populationInstance.CQUI_CityHousing:SetHide(false);
        end
    else
        populationInstance.CQUI_CityHousing:SetHide(true);
    end
    -- CQUI : End of housing left

    -- CQUI : add housing left to tooltip
    if CQUI_SmartBanner and CQUI_SmartBanner_Population then
        local popTooltip = populationInstance.FillMeter:GetToolTipString();
        CQUI_housingLeftPopupText = "[NEWLINE] [ICON_Housing]" .. Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ": " .. CQUI_housingLeftPopupText;
        print_debug("CityBannerManager_CQUI_Expansion2: CQUI_housingLeftPopupText: "..CQUI_housingLeftPopupText)
        print_debug("CityBannerManager_CQUI_Expansion2: popTooltip before:"..tostring(popTooltip));
        popTooltip = popTooltip .. CQUI_housingLeftPopupText;
        print_debug("CityBannerManager_CQUI_Expansion2: popTooltip:"..tostring(popTooltip));
        populationInstance.FillMeter:SetToolTipString(popTooltip);
    end
    
end

-- ============================================================================
function CityBanner.UpdateStats(self)
    print_debug("CityBannerManager_CQUI_Expansion2: CityBanner.UpdateStats ENTRY");
    BASE_CQUI_CityBanner_UpdateStats(self);

    local pDistrict:table = self:GetDistrict();
    if (pDistrict ~= nil and self.m_Type == BANNERTYPE_CITY_CENTER) then
        local localPlayerID:number = Game.GetLocalPlayer();
        local pCity        :table  = self:GetCity();
        local iCityOwner   :number = pCity:GetOwner();

        if (localPlayerID == iCityOwner) then
            -- On first call into UpdateStats, CQUI_DistrictBuiltIM may not be instantiated yet
            if (self.CQUI_DistrictBuiltIM == nil) then
              print_debug("CityBannerManager_CQUI_Expansion2: updatestats:  CQUI_DistrictBuiltIM is nil, creating new");
              self.CQUI_DistrictBuiltIM = InstanceManager:new( "CQUI_DistrictBuilt", "Icon", self.m_Instance.CQUI_Districts );
            end

            -- Update the built districts 
            self.CQUI_DistrictBuiltIM:ResetInstances(); -- CQUI : Reset CQUI_DistrictBuiltIM
            local pCityDistricts:table = pCity:GetDistricts();
            if CQUI_SmartBanner_Districts then
                for i, district in pCityDistricts:Members() do
                    local districtType = district:GetType();
                    local districtInfo:table = GameInfo.Districts[districtType];
                    local isBuilt = pCityDistricts:HasDistrict(districtInfo.Index, true);
                    if isBuilt and districtInfo.Index ~= 0 then
                        SetDetailIcon(self.CQUI_DistrictBuiltIM:GetInstance(), "ICON_"..districtInfo.DistrictType);
                    end
                end
            end
        end
    end
end

-- ============================================================================
function CityBanner.UpdateInfo(self, pCity : table )
    print_debug("CityBannerManager_CQUI_Expansion2: CityBanner.UpdateInfo ENTRY  pCity"..tostring(pCity));
    BASE_CQUI_CityBanner_UpdateInfo(self, pCity);

    if (pCity == nil) then
        return;
    end

    --CQUI : Unlocked citizen check
    if (playerID == Game.GetLocalPlayer() and CQUI_SmartBanner and CQUI_SmartBanner_Unmanaged_Citizen) then
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
function CityBanner.UpdateRangeStrike(self)
    -- Move the CityStrike icon and button to the top of the City bar; similar to the Sukritact Simple UI Mod (which puts it on the right)
    BASE_CQUI_CityBanner_UpdateRangeStrike(self);

    local cityBanner = self.m_Instance;
    if (cityBanner == nil) then
        return;
    end

    if (self.m_Type == BANNERTYPE_CITY_CENTER) then
        -- The standard icon has an "attachment" piece that looks like it hangs down from the City Banner
        -- Rotating it makes it look like it's attached to the part above
        -- TODO: Make this configurable?  (Where if not set, it just uses the standard location)
        cityBanner.CityStrike:Rotate(180);
        cityBanner.CityStrike:SetSizeVal(36,45);
        cityBanner.CityStrike:SetAnchor("C,T");
        cityBanner.CityStrike:SetOffsetVal(0,10);

        cityBanner.CityStrikeButton:SetAnchor("C,C");
        cityBanner.CityStrikeButton:SetOffsetVal(0,0);
    end
end


-- ============================================================================
function Reload()
    print_debug("CityBannerManager_CQUI_Expansion2: Reload ENTRY");
    BASE_CQUI_Reload();

    local pLocalPlayerVis:table = PlayersVisibility[Game.GetLocalPlayer()];
    if pLocalPlayerVis ~= nil then
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
function OnShutdown()
    print_debug("CityBannerManager_CQUI_Expansion2: OnShutdown ENTRY");
    -- CQUI values
    LuaEvents.GameDebug_AddValue("CityBannerManager", "CQUI_HousingFromImprovementsTable", CQUI_HousingFromImprovementsTable);
    LuaEvents.GameDebug_AddValue("CityBannerManager", "CQUI_HousingUpdated", CQUI_HousingUpdated);
    CQUI_PlotIM:DestroyInstances();

    BASE_CQUI_OnShutdown();
end

-- ============================================================================
function OnInterfaceModeChanged( oldMode:number, newMode:number )
    print_debug("CityBannerManager_CQUI_Expansion2: OnInterfaceModeChanged ENTRY");
    BASE_CQUI_OnInterfaceModeChanged(oldMode, newMode);

    if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
      CQUI_CityManageAreaShown = false;
      CQUI_CityManageAreaShouldShow = false;
    end
end

-- ============================================================================
-- CQUI Replacement Functions
-- ============================================================================
function CityBanner.SetHealthBarColor( self )
    print_debug("CityBannerManager_CQUI_Expansion2: CityBanner.SetHealthBarColor ENTRY");
  -- The basegame file has a minor bug where if percent is exactly 0.40, then no color is set.
    if self.m_Instance.CityHealthBar == nil then
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

-- ============================================================================
function OnCityBannerClick( playerID:number, cityID:number )
    print_debug("CityBannerManager_CQUI_Expansion2: OnCityBannerClick ENTRY  playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    -- TODO: This can probably be done as an extension function, rather than as an entire replacement...
    --       there are 2 lines in total that differ from the base OnCityBannerClick function (marked below)
    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        return;
    end

    local pCity = pPlayer:GetCities():FindID(cityID);
    if (pCity == nil) then
        return;
    end

    if (pPlayer:IsFreeCities()) then
        UI.LookAtPlotScreenPosition( pCity:GetX(), pCity:GetY(), 0.5, 0.5 );
        return;
    end

    local localPlayerID;
    if (WorldBuilder.IsActive()) then
        localPlayerID = playerID; -- If WorldBuilder is active, allow the user to select the city
    else
        localPlayerID = Game.GetLocalPlayer();
    end

    if (pPlayer:GetID() == localPlayerID) then
        UI.SelectCity( pCity );
        UI.SetCycleAdvanceTimer(0);  -- Cancel any auto-advance timer
        -- CQUI Customization BEGIN ===============================================================
        UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);
        -- CQUI Customization END =================================================================
    elseif (localPlayerID == PlayerTypes.OBSERVER
            or localPlayerID == PlayerTypes.NONE
            or pPlayer:GetDiplomacy():HasMet(localPlayerID)) then

        -- CQUI Customization BEGIN ===============================================================
        LuaEvents.CQUI_CityviewDisable(); -- Make sure the cityview is disable
        -- CQUI Customization END =================================================================
        local pPlayerConfig :table    = PlayerConfigurations[playerID];
        local isMinorCiv  :boolean  = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
        print_debug("CityBannerManager_CQUI_Expansion2: clicked player " .. playerID .. " city.  IsMinor?: ",isMinorCiv);

        if (UI.GetInterfaceMode() == InterfaceModeTypes.MAKE_TRADE_ROUTE) then
            local plotID = Map.GetPlotIndex(pCity:GetX(), pCity:GetY());
            LuaEvents.CityBannerManager_MakeTradeRouteDestination( plotID );
        else
            if (isMinorCiv) then
                if (UI.GetInterfaceMode() ~= InterfaceModeTypes.SELECTION) then
                    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
                end

                LuaEvents.CityBannerManager_RaiseMinorCivPanel( playerID ); -- Go directly to a city-state
            else
                LuaEvents.CityBannerManager_TalkToLeader( playerID );
            end
        end
    end
end

-- ===========================================================================
function OnProductionClick( playerID, cityID )
    OnCityBannerClick( playerID, cityID);
end

-- ===========================================================================
function OnCityStrikeButtonClick( playerID, cityID )
    print_debug("CityBannerManager_CQUI_Expansion2: OnCityStrikeButtonClick ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    local pPlayer = Players[playerID];
    if (pPlayer == nil) then
        return;
    end

    local pCity = pPlayer:GetCities():FindID(cityID);
    if (pCity == nil) then
        return;
    end;

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
LuaEvents.CQUI_CityRangeStrike.Add( OnCityStrikeButtonClick ); -- AZURENCY : to acces it in the actionpannel on the city range attack button

-- ===========================================================================
function OnDistrictRangeStrikeButtonClick( playerID, districtID )
    print_debug("CityBannerManager_CQUI_Expansion2: OnDistrictRangeStrikeButtonClick ENTRY playerID:"..tostring(playerID).." districtID:"..tostring(districtID));
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
LuaEvents.CQUI_DistrictRangeStrike.Add( OnDistrictRangeStrikeButtonClick ); -- AZURENCY : to acces it in the actionpannel on the district range attack button

-- ===========================================================================
function OnDistrictAddedToMap( playerID: number, districtID : number, cityID :number, districtX : number, districtY : number, districtType:number, percentComplete:number )
    print_debug("CityBannerManager_CQUI_Expansion2: OnDistrictAddedToMap ENTRY playerID:"..tostring(playerID).." districtID:"..tostring(districtID).." cityID:"..tostring(cityID).." districtXY:"..tostring(districtX)..","..tostring(districtY).." districtType:"..tostring(districtType).." pctComplete:"..tostring(percentComplete));
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
    -- It is possible that the city is not there yet. e.g. city-center district is placed, the city is placed immediately afterward.
    if (pCity ~= nil) then
        return;
    end

    -- Is the district at the city? i.e. its a city-center?
    if (pCity:GetX() == pDistrict:GetX() and pCity:GetY() == pDistrict:GetY()) then
        -- Yes, just update the city banner with the district ID.
        local cityBanner:table = GetCityBanner( playerID, pCity:GetID() );
        if cityBanner then
            cityBanner.m_DistrictID = districtID;
            cityBanner:UpdateRangeStrike();
            cityBanner:UpdateStats();
            cityBanner:UpdateColor();
        end
    else
        -- Create a banner for a district that is not the city-center
        local miniBanner:table = GetMiniBanner( playerID, districtID );
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
            if playerID == Game.GetLocalPlayer() then
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
                    if PlayerConfigurations[playerID]:GetCivilizationTypeName() == "CIVILIZATION_NETHERLANDS" then
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
    print_debug("CityBannerManager_CQUI_Expansion2: OnImprovementAddedToMap ENTRY locXY:"..tostring(locX)..","..tostring(locY).." eImprovementType:"..tostring(eImprovementType).." eOwner:"..tostring(eOwner));
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
    if eOwner == Game.GetLocalPlayer() then
        if improvementData.ImprovementType == "IMPROVEMENT_FORT" then
            if PlayerConfigurations[eOwner]:GetCivilizationTypeName() == "CIVILIZATION_POLAND" then
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
function OnGameDebugReturn( context:string, contextTable:table )
    print_debug("CityBannerManager_CQUI_Expansion2: OnGameDebugReturn ENTRY context:"..tostring(context).." contextTable:"..tostring(contextTable));
    if context == "CityBannerManager" then
        m_isLoyaltyLensActive = contextTable["m_isLoyaltyLensActive"];
        m_isReligionLensActive = contextTable["m_isReligionLensActive"];

        -- CQUI cached values
        CQUI_HousingFromImprovementsTable = contextTable["CQUI_HousingFromImprovementsTable"]
        CQUI_HousingUpdated = contextTable["CQUI_HousingUpdated"]
        -- CQUI settings
        CQUI_OnSettingsUpdate()

        RealizeReligion();
        RealizeLoyalty();
    end
end

-- ============================================================================
-- CQUI Custom Functions
-- ============================================================================
-- CQUI -- When a banner is moused over, display the relevant yields and next culture plot
function CQUI_OnBannerMouseOver(playerID: number, cityID: number)
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnBannerMouseOver ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    if (CQUI_ShowYieldsOnCityHover == false) then
       return;
    end

    CQUI_Hovering = true;

    -- Astog: Fix for lens being shown when other lenses are on.
    -- Astog: Don't show this lens if any unit is selected.
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
    tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);

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

    local yields      :table = {};
    local yieldsIndex :table = {};

    if (tPlots ~= nil and table.count(tPlots) ~= 0) and (UILens.IsLayerOn(CQUI_CitizenManagement) == false) then
        CQUI_yieldsOn = UserConfiguration.ShowMapYield();
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
        end -- for loop
    end

    tResults  = CityManager.GetCommandTargets( kCity, CityCommandTypes.PURCHASE, tParameters );
    if tResults == nil then
        return;
    end

    tPlots    = tResults[CityCommandResults.PLOTS];
    if (tPlots ~= nil and table.count(tPlots) ~= 0) and UILens.IsLayerOn(CQUI_CitizenManagement) == false then
        for i,plotId in pairs(tPlots) do
            local kPlot :table = Map.GetPlotByIndex(plotId);
            local index:number = kPlot:GetIndex();
            local pInstance :table =  CQUI_GetInstanceAt(index);

            if (index == pNextPlotID ) then
                pInstance.CQUI_NextPlotLabel:SetString("[ICON_Turn]" .. Locale.Lookup("LOC_HUD_CITY_IN_TURNS" , TurnsUntilExpansion ) .. "   ");
                pInstance.CQUI_NextPlotButton:SetHide( false );
            end

            table.insert(yields, plotId);
            yieldsIndex[index] = plotId;
        end

        local plotCount = Map.GetPlotCount();

        if (CQUI_yieldsOn == false and not UILens.IsLayerOn(CQUI_CitizenManagement)) then
            UILens.SetLayerHexesArea(CQUI_CityYields, Game.GetLocalPlayer(), yields);
            UILens.ToggleLayerOn( CQUI_CityYields );
        end
    elseif UILens.IsLayerOn(CQUI_CitizenManagement) == false then
        local pInstance :table = CQUI_GetInstanceAt(pNextPlotID);
        if (pInstance ~= nil) then
            pInstance.CQUI_NextPlotLabel:SetString("[ICON_Turn]" .. Locale.Lookup("LOC_HUD_CITY_IN_TURNS" , TurnsUntilExpansion ) .. "   ");
            pInstance.CQUI_NextPlotButton:SetHide( false );
            CQUI_NextPlot4Away = pNextPlotID;
        end
    end --i if/else
end
  
-- ===========================================================================
-- CQUI -- When a banner is moused over, and the mouse leaves the banner, remove display of the relevant yields and next culture plot
function CQUI_OnBannerMouseExit(playerID: number, cityID: number)
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnBannerMouseExit ENTRY playerID:"..tostring(playerID).." cityID:"..tostring(cityID));
    if (not CQUI_Hovering) then
        return;
    end

    CQUI_yieldsOn = UserConfiguration.ShowMapYield();

    if (CQUI_yieldsOn == false and not UILens.IsLayerOn(CQUI_CitizenManagement)) then
        UILens.ClearLayerHexes( CQUI_CityYields );
    end
  
    local kPlayer = Players[playerID];
    local kCities = kPlayer:GetCities();
    local kCity   = kCities:FindID(cityID);
  
    local tParameters :table = {};
    tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);
    tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
  
    local tResults  :table = CityManager.GetCommandTargets( kCity, CityCommandTypes.MANAGE, tParameters );
  
    if tResults == nil then
        -- Add error message here
        return;
    end
  
    -- Astog: Fix for lens being cleared when having other lenses on
    if CQUI_ShowCityManageAreaOnCityHover
       and UI.GetInterfaceMode() ~= InterfaceModeTypes.CITY_MANAGEMENT
       and CQUI_CityManageAreaShown then
        LuaEvents.CQUI_ClearCitizenManagement();
        CQUI_CityManageAreaShown = false;
    end
  
    local tPlots :table = tResults[CityCommandResults.PLOTS];
  
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

-- CQUI taken from PlotInfo
-- ===========================================================================
--  Obtain an existing instance of plot info or allocate one if it doesn't already exist.
--  plotIndex Game engine index of the plot
-- ===========================================================================
function CQUI_GetInstanceAt( plotIndex:number )
    --print_debug("CityBannerManager_CQUI_Expansion2: CQUI_GetInstanceAt ENTRY plotIndex:"..tostring(plotIndex));
    local pInstance:table = CQUI_uiWorldMap[plotIndex];

    if pInstance == nil then
        pInstance = CQUI_PlotIM:GetInstance();
        CQUI_uiWorldMap[plotIndex] = pInstance;
        local worldX:number, worldY:number = UI.GridToWorld( plotIndex );
        pInstance.Anchor:SetWorldPositionVal( worldX, worldY, 20 );
        -- Make it so that the button can't be clicked while it's in this temporary state, this stops it from blocking clicks intended for the citybanner
        pInstance.CitizenButton:SetConsumeMouseButton(false);
        pInstance.Anchor:SetHide( false );
    end

    return pInstance;
end

-- ===========================================================================
function CQUI_ReleaseInstanceAt( plotIndex:number)
    --print_debug("CityBannerManager_CQUI_Expansion2: CQUI_ReleaseInstanceAt ENTRY plotIndex:"..tostring(plotIndex));
  local pInstance :table = CQUI_uiWorldMap[plotIndex];

    if pInstance ~= nil then
      pInstance.Anchor:SetHide( true );
      -- Return the button to normal so that it can be clicked again
      pInstance.CitizenButton:SetConsumeMouseButton(true);
      -- m_AdjacentPlotIconIM:ReleaseInstance( pInstance );
      CQUI_uiWorldMap[plotIndex] = nil;
    end
end

-- ===========================================================================
function CQUI_OnInfluenceGiven()
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnInfluenceGiven ENTRY");
    for i, pPlayer in ipairs(PlayerManager.GetAliveMinors()) do
        local iPlayer = pPlayer:GetID();
        -- AZURENCY : check if there's a CapitalCity
        if pPlayer:GetCities():GetCapitalCity() ~= nil then
            local iCapital = pPlayer:GetCities():GetCapitalCity():GetID();
            local bannerInstance = GetCityBanner(iPlayer, iCapital);
            CQUI_UpdateSuzerainIcon(pPlayer, bannerInstance);
        end
    end
end

-- ===========================================================================
function CQUI_UpdateSuzerainIcon( pPlayer:table, bannerInstance )
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_UpdateSuzerainIcon ENTRY");
    if bannerInstance == nil then
        return;
    end

    local pPlayerInfluence :table  = pPlayer:GetInfluence();
    local suzerainID       :number = pPlayerInfluence:GetSuzerain();
    if suzerainID ~= -1 then
        local pPlayerConfig :table  = PlayerConfigurations[suzerainID];
        local leader        :string = pPlayerConfig:GetLeaderTypeName();
        if GameInfo.CivilizationLeaders[leader] == nil then
            UI.DataError("Banners found a leader \""..leader.."\" which is not/no longer in the game; icon may be whack.");
        else
            local suzerainTooltip = Locale.Lookup("LOC_CITY_STATES_SUZERAIN_LIST") .. " ";
            if pPlayer:GetDiplomacy():HasMet(suzerainID) then
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
-- CQUI calculate real housing from improvements
-- NOTE: Housing Values from Improvements determined by adding integers, and halved once all housing has been calculated
--       The basegame function doesn't include the half-value (e.g. as Non-Maya, 3 farms is 1.5, but basegame returns only 1).
--       Basegame also appears to consider the Maya as +1 Housing in addition to the 0.5 for each farm (so, 1.5 for each Mayan farm)
--       In basegame, when Maya have 2 farms, pCity:GetGrowth():GetHousingFromImprovements() will return a value of 3

function CQUI_RealHousingFromImprovements(pCity, PlayerID, pCityID)
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_RealHousingFromImprovements ENTRY  pCity:"..tostring(pCity).." PlayerID:"..tostring(PlayerID).." pCityID:"..tostring(pCityID));

    local realHousingValue = CQUI_GetRealHousingFromImprovements(pCity, PlayerID, pCityID, CQUI_cityMaxBuyPlotRange);

    if CQUI_HousingFromImprovementsTable[PlayerID] == nil then
        CQUI_HousingFromImprovementsTable[PlayerID] = {};
    end

    if CQUI_HousingUpdated[PlayerID] == nil then
        CQUI_HousingUpdated[PlayerID] = {};
    end

    CQUI_HousingFromImprovementsTable[PlayerID][pCityID] =  realHousingValue;
    CQUI_HousingUpdated[PlayerID][pCityID] = true;
    LuaEvents.CQUI_RealHousingFromImprovementsCalculated(pCityID, realHousingValue);
end

-- ===========================================================================
-- CQUI update city's real housing from improvements
function CQUI_OnCityInfoUpdated(PlayerID, pCityID)
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnCityInfoUpdated ENTRY PlayerID:"..tostring(PlayerID).." pCityID:"..tostring(pCityID));
    CQUI_HousingUpdated[PlayerID][pCityID] = nil;
end

-- ===========================================================================
-- CQUI update all cities real housing from improvements
function CQUI_OnAllCitiesInfoUpdated(PlayerID)
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnCityInfoUpdated ENTRY PlayerID:"..tostring(PlayerID));
    local m_pCity:table = Players[PlayerID]:GetCities();
    for i, pCity in m_pCity:Members() do
        local pCityID = pCity:GetID();
        CQUI_OnCityInfoUpdated(PlayerID, pCityID)
    end
end

-- ===========================================================================
-- CQUI update close to a culture bomb cities data and real housing from improvements
function CQUI_OnCityLostTileToCultureBomb(PlayerID, x, y)
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnCityLostTileToCultureBomb ENTRY PlayerID:"..tostring(PlayerID).." LocationXY:"..tostring(x)..","..tostring(y));
    local m_pCity:table = Players[PlayerID]:GetCities();
    for i, pCity in m_pCity:Members() do
        if Map.GetPlotDistance( pCity:GetX(), pCity:GetY(), x, y ) <= 4 then
            local pCityID = pCity:GetID();
            CQUI_OnCityInfoUpdated(PlayerID, pCityID)
            CityManager.RequestCommand(pCity, CityCommandTypes.SET_FOCUS, nil);
        end
    end
end

-- ===========================================================================
-- CQUI erase real housing from improvements data everywhere when a city removed from map
function CQUI_OnCityRemovedFromMap(PlayerID, pCityID)
    print_debug("CityBannerManager_CQUI_Expansion2: CQUI_OnCityRemovedFromMap ENTRY PlayerID:"..tostring(PlayerID).." pCityID:"..tostring(pCityID));
    if playerID == Game.GetLocalPlayer() then
        CQUI_HousingFromImprovementsTable[PlayerID][pCityID] = nil;
        CQUI_HousingUpdated[PlayerID][pCityID] = nil;
        LuaEvents.CQUI_RealHousingFromImprovementsCalculated(pCityID, nil);
    end
end

-- ===========================================================================
function CQUI_GetFirstInstance(instanceObj)
    retobj = nil;
    -- in XP1 and later the instance objects are arrays, and we very typically just need the first
    for _, inst in pairs(instanceObj.m_AllocatedInstances) do
        retobj = inst
        break
    end

    return retobj;
end


-- ===========================================================================
--  Game Engine EVENT
-- ===========================================================================
function OnCityWorkerChanged(ownerPlayerID:number, cityID:number)
    print_debug("CityBannerManager_CQUI_Expansion2: OnCityWorkerChanged ENTRY ownerPlayerID:"..tostring(ownerPlayerID).." cityID:"..tostring(cityID));
    if (Game.GetLocalPlayer() == ownerPlayerID) then
        RefreshBanner( ownerPlayerID, cityID )
    end
end

-- ===========================================================================
--  CQUI Initialize Function
-- ===========================================================================
function Initialize()
    print_debug("CityBannerManager_CQUI_Expansion2: Initialize CQUI CityBanner Expansion 2")
    -- CQUI related events
    LuaEvents.CQUI_SettingsInitialized.Add(       CQUI_OnSettingsInitialized );
    LuaEvents.CQUI_CityInfoUpdated.Add(           CQUI_OnCityInfoUpdated );    -- CQUI update city's real housing from improvements
    LuaEvents.CQUI_AllCitiesInfoUpdated.Add(      CQUI_OnAllCitiesInfoUpdated );    -- CQUI update all cities real housing from improvements
    LuaEvents.CQUI_CityLostTileToCultureBomb.Add( CQUI_OnCityLostTileToCultureBomb );    -- CQUI update close to a culture bomb cities data and real housing from improvements
    Events.CityWorkerChanged.Add(                 OnCityWorkerChanged);
    Events.CityRemovedFromMap.Add(                CQUI_OnCityRemovedFromMap );    -- CQUI erase real housing from improvements data everywhere when a city removed from map
    Events.CitySelectionChanged.Add(              CQUI_OnBannerMouseExit );
    Events.InfluenceGiven.Add(                    CQUI_OnInfluenceGiven );

    -- TODO: Investigate exactly how the OnSettingsInitialized gets called, because unless doing this here, it doesn't seem to be called until the settings UI is brought up.
    -- CQUI_OnSettingsInitialized();
end
Initialize();


