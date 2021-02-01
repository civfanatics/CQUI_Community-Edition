include("CQUICommon.lua");

-- #59 Infixo they are local and not visible in this file
local m_isReligionLensActive:boolean = false;
local m_HexColoringReligion:number = UILens.CreateLensLayerHash("Hex_Coloring_Religion");
local DATA_FIELD_RELIGION_ICONS_IM:string = "m_IconsIM";
local DATA_FIELD_RELIGION_FOLLOWER_LIST_IM:string = "m_FollowerListIM";
local DATA_FIELD_RELIGION_POP_CHART_IM  :string = "m_PopChartIM";
local DATA_FIELD_RELIGION_INFO_INSTANCE :string = "m_ReligionInfoInst";
local RELIGION_POP_CHART_TOOLTIP_HEADER :string = Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP_HEADER");
local COLOR_RELIGION_DEFAULT            :number = UI.GetColorValueFromHexLiteral(0x02000000);

-- BASEGAME
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_CityBanner_UpdateProduction = CityBanner.UpdateProduction;
BASE_CQUI_CityBanner_UpdateStats = CityBanner.UpdateStats;

-- EXPANSIONS
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_CityBanner_Uninitialize = CityBanner.Uninitialize;
BASE_CQUI_CityBanner_UpdateInfo = CityBanner.UpdateInfo;
BASE_CQUI_CityBanner_UpdatePopulation = CityBanner.UpdatePopulation;
BASE_CQUI_CityBanner_UpdateStats = CityBanner.UpdateStats;

-- Basegame override, but need to keep pointer in case expansions is loaded
BASE_CQUI_CityBanner_UpdateName = CityBanner.UpdateName;

-- ============================================================================
-- CQUI Extension Functions
-- ============================================================================
function CityBanner.Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle)
    -- basegame and expansions

    -- print_debug("CityBannerManager_CQUI_Expansions: CityBanner:Initialize ENTRY: playerID:"..tostring(playerID).." cityID:"..tostring(cityID).." districtID:"..tostring(districtID).." bannerType:"..tostring(bannerType).." bannerStyle:"..tostring(bannerStyle));
    CQUI_Common_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);
end

-- ===========================================================================
-- Basegame only
function CityBanner.UpdateProduction(self)
    -- Single line difference between this and the base version that allows the icon of that
    -- which is being built to appear in the CityBanner
    -- print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateProduction ENTRY");
    BASE_CQUI_CityBanner_UpdateProduction(self);

    -- Do this with the Vanilla/Basegame only, not expansions
    if (g_bIsBaseGame) then
        local localPlayerID :number = Game.GetLocalPlayer();
        local pCity         :table = self:GetCity();
        local pBuildQueue   :table  = pCity:GetBuildQueue();

        if (localPlayerID == pCity:GetOwner() and pBuildQueue ~= nil) then
            -- if there is anything in the build queue, it will have a hash, otherwise the hash is 0.
            local currentProductionHash :number = pBuildQueue:GetCurrentProductionTypeHash();

            if (currentProductionHash ~= 0) then
                -- This single line is responsible for the icon of what is being produced showing in the City Banner
                self.m_Instance.ProductionIndicator:SetHide(false);
            end
        end
    end
end

-- ===========================================================================
function CityBanner.UpdateStats(self)
    BASE_CQUI_CityBanner_UpdateStats(self);

    if (g_bIsBaseGame) then
        UpdateStatsBasegame(self);
    else
        UpdateStatsExpansions(self);
    end
end

-- ===========================================================================
function UpdateStatsBasegame(self)
    -- Most of the logic here is basegame only, XP1/XP2 do this work in the CityBanner.UpdatePopulation function
    -- print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateStats ENTRY");

    -- CQUI get real housing from improvements value (do this regardless of whether or not the banners will be updated)
    local pCity         :table  = self:GetCity();
    local localPlayerID :number = Game.GetLocalPlayer();

    if (IsBannerTypeCityCenter(self.m_Type) == false) then
        return;
    end

    if (self.m_Player ~= Players[localPlayerID]) then
        return;
    end

    if (IsCQUI_SmartBannerEnabled() == false) then
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
end


-- ============================================================================
function UpdateStatsExpansions(self)
    -- print_debug("CityBannerManager_CQUI_Expansions: CityBanner.UpdateStats ENTRY");

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
end

-- ===========================================================================
-- CQUI Basegame Replacement Functions
-- Functions that override the unmodified versions in the game
-- ===========================================================================
function CityBanner.UpdateName( self )
    -- print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateName ENTRY");

    -- This code applies to vanilla/basegame only (early return from function!)
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        return BASE_CQUI_CityBanner_UpdateName(self);
    end

    if (IsBannerTypeCityCenter(self.m_Type) == false) then
        return;
    end

    local pCity : table = self:GetCity();
    if (pCity == nil) then
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

    local pCityDistricts:table  = pCity:GetDistricts();
    if (IsCQUI_SmartBannerEnabled() and self.m_Instance.CityBuiltDistrictAqueduct ~= nil) then
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
    local pPlayerConfig :table = PlayerConfigurations[owner];
    local isMinorCiv :boolean = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
    if (isMinorCiv) then
        CQUI_UpdateCityStateBannerSuzerain(pPlayer, self);
        CQUI_UpdateCityStateBannerAtWarIcon(pPlayer, self);
    end

    self.m_Instance.CityQuestIcon:SetToolTipString(questTooltip);
    self.m_Instance.CityQuestIcon:SetText(statusString);
    self.m_Instance.CityName:SetText( cityName );
    self.m_Instance.CityNameStack:ReprocessAnchoring();
    self.m_Instance.ContentStack:ReprocessAnchoring();
    self:Resize();
end

-- ===========================================================================
-- Basegame and Expansions call this two different things (OnCityRangeStrikeButtonClick and OnCityStrikeButtonClick, respectively)
function OnCityRangeStrikeButtonClick( playerID, cityID )
    -- print_debug("CityBannerManager_CQUI_basegame: OnCityRangeStrikeButtonClick ENTRY");

    -- Call the common code for handling the City Strike button
    CQUI_OnCityRangeStrikeButtonClick(playerID, cityID);
end


-- ===========================================================================
-- CQUI Custom Functions (Common to basegame only)
-- ===========================================================================
function CQUI_OnLensLayerOn( layerNum:number )
    --print("FUN OnLensLayerOn", layerNum);
    if layerNum == m_HexColoringReligion then
        m_isReligionLensActive = true;
        RealizeReligion();
    end
end

-- ===========================================================================
function CQUI_OnLensLayerOff( layerNum:number )
    --print("FUN OnLensLayerOff", layerNum);
    if layerNum == m_HexColoringReligion then
        m_isReligionLensActive = false;
        RealizeReligion();
    end
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
-- CQUI Initialize Function
-- ===========================================================================
function Initialize_CQUI_basegame()
    print_debug("CityBannerManager_CQUI_basegame: Initialize CQUI CityBannerManager");
    -- Events are initialized in the common file
    Events.LensLayerOff.Add(CQUI_OnLensLayerOff);
    Events.LensLayerOn.Add(CQUI_OnLensLayerOn);
end
Initialize_CQUI_basegame();