-- ===========================================================================
-- CityBannerManager for Basegame (Vanilla)
-- ===========================================================================
-- Functions and objects common to basegame and expansions
include("citybannermanager_CQUI.lua");

-- #59 Infixo they are local and not visible in this file
local m_isReligionLensActive:boolean = false;
local m_HexColoringReligion:number = UILens.CreateLensLayerHash("Hex_Coloring_Religion");
local DATA_FIELD_RELIGION_ICONS_IM:string = "m_IconsIM";
local DATA_FIELD_RELIGION_FOLLOWER_LIST_IM:string = "m_FollowerListIM";
local DATA_FIELD_RELIGION_POP_CHART_IM  :string = "m_PopChartIM";
local DATA_FIELD_RELIGION_INFO_INSTANCE :string = "m_ReligionInfoInst";
local RELIGION_POP_CHART_TOOLTIP_HEADER :string = Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP_HEADER");
local COLOR_RELIGION_DEFAULT            :number = UI.GetColorValueFromHexLiteral(0x02000000);

-- ===========================================================================
-- Cached Base Functions (Basegame only)
-- ===========================================================================
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_CityBanner_UpdateProduction = CityBanner.UpdateProduction;
BASE_CQUI_CityBanner_UpdateStats = CityBanner.UpdateStats;

-- ===========================================================================
-- CQUI Basegame Extension Functions
-- ===========================================================================
--function CityBanner.Initialize( self : CityBanner, playerID: number, cityID : number, districtID : number, bannerType : number, bannerStyle : number)
function CityBanner.Initialize( self, playerID, cityID, districtID, bannerType, bannerStyle)
    print_debug("CityBannerManager_CQUI_basegame: CityBanner:Initialize ENTRY: playerID:"..tostring(playerID).." cityID:"..tostring(cityID).." districtID:"..tostring(districtID).." bannerType:"..tostring(bannerType).." bannerStyle:"..tostring(bannerStyle));
    CQUI_Common_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);
end

-- ===========================================================================
function CityBanner.UpdateProduction(self)
    -- Single line difference between this and the base version that allows the icon of that
    -- which is being built to appear in the CityBanner
    print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateProduction ENTRY");
    BASE_CQUI_CityBanner_UpdateProduction(self);

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

-- ===========================================================================
function CityBanner.UpdateStats(self)
    -- Most of the logic here is basegame only, XP1/XP2 do this work in the CityBanner.UpdatePopulation function
    print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateStats ENTRY");
    BASE_CQUI_CityBanner_UpdateStats(self);

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
        -- TODO: This logic in this if statement appears in all 3 of the citybannermanager files, can be put into single common file
        local cqui_HousingFromImprovementsCalc = CQUI_GetRealHousingFromImprovementsValue(pCity, localPlayerID)
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
            --local CTLS = "[COLOR:"..popTurnLeftColor.."]"..turnsUntilGrowth.."[ENDCOLOR]  [[COLOR:"..housingLeftColor.."]"..housingLeftText.."[ENDCOLOR]]  ";
            self.m_Instance.CityPopTurnsLeft:SetText(housingString);
            self.m_Instance.CityPopTurnsLeft:SetHide(false);

            -- CQUI : add housing left to tooltip
            local popTooltip = GetPopulationTooltip(self, turnsUntilGrowth, currentPopulation, foodSurplus); -- self.m_Instance.CityPopulation:GetToolTipString(); --populationInstance.FillMeter:GetToolTipString();
            local CQUI_housingLeftPopupText = "[NEWLINE] [ICON_Housing]" .. Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ": " .. housingLeft;
            popTooltip = popTooltip .. CQUI_housingLeftPopupText;
            self.m_Instance.CityPopulation:SetToolTipString(popTooltip);
        end
    else
        self.m_Instance.CityPopTurnsLeft:SetHide(true);
    end
end

-- ===========================================================================
-- CQUI Basegame Replacement Functions
-- Functions that override the unmodified versions in the game
-- ===========================================================================
function CityBanner.UpdateName( self )
    print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateName ENTRY");

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
    -- districtType:number == Index
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

    if (self.m_Instance.CityBuiltDistrictAqueduct ~= nil) then
        self.m_Instance.CQUI_DistrictsContainer:SetHide(true);
        self.m_Instance.CQUI_DistrictAvailable:SetHide(true);
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
        CQUI_UpdateSuzerainIcon(pPlayer, self);
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
    print_debug("CityBannerManager_CQUI_basegame: OnCityRangeStrikeButtonClick ENTRY");

    -- Call the common code for handling the City Strike button
    CQUI_OnCityRangeStrikeButtonClick(playerID, cityID);
end

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
-- #59 Infixo overwritten because changes are deep inside it
function CityBanner.UpdateReligion( self )

    local cityInst          :table = self.m_Instance;
    local pCity             :table = self:GetCity();
    local pCityReligion     :table = pCity:GetReligion();
    local eMajorityReligion :number = pCityReligion:GetMajorityReligion();
    local religionsInCity   :table = pCityReligion:GetReligionsInCity();
    self.m_eMajorityReligion = eMajorityReligion;

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

    -- Hide the meter and bail out if the religion lens isn't active
    if (not m_isReligionLensActive or table.count(religionsInCity) == 0) then
        if cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE] then
            cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE].ReligionInfoContainer:SetHide(true);
        end
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
        local localPlayerVis:table = PlayersVisibility[Game.GetLocalPlayer()];
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
                UILens.SetLayerHexesColoredArea( m_HexColoringReligion, Game.GetLocalPlayer(), plots, majorityReligionColor );
            end
        end
    end

    -- Find or create religion info instance
    local religionInfoInst = {};
    if cityInst.ReligionInfoAnchor and cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE] == nil then
        ContextPtr:BuildInstanceForControl( "ReligionInfoInstance", religionInfoInst, cityInst.ReligionInfoAnchor );
        cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE] = religionInfoInst;
    else
        religionInfoInst = cityInst[DATA_FIELD_RELIGION_INFO_INSTANCE];
    end

    -- Update religion info instance
    if religionInfoInst and religionInfoInst.ReligionInfoContainer then
        -- Create or reset icon instance manager
        local iconIM:table = cityInst[DATA_FIELD_RELIGION_ICONS_IM];
        if (iconIM == nil) then
            iconIM = InstanceManager:new("ReligionIconInstance", "ReligionIconContainer", religionInfoInst.ReligionInfoIconStack);
            cityInst[DATA_FIELD_RELIGION_ICONS_IM] = iconIM;
        else
            iconIM:ResetInstances();
        end

        -- Create or reset follower list instance manager
        local followerListIM:table = cityInst[DATA_FIELD_RELIGION_FOLLOWER_LIST_IM];
        if (followerListIM == nil) then
            followerListIM = InstanceManager:new("ReligionFollowerListInstance", "ReligionFollowerListContainer", religionInfoInst.ReligionFollowerListStack);
            cityInst[DATA_FIELD_RELIGION_FOLLOWER_LIST_IM] = followerListIM;
        else
            followerListIM:ResetInstances();
        end

        -- Create or reset pop chart instance manager
        local popChartIM:table = cityInst[DATA_FIELD_RELIGION_POP_CHART_IM];
        if (popChartIM == nil) then
            popChartIM = InstanceManager:new("ReligionPopChartInstance", "PopChartMeter", religionInfoInst.ReligionPopChartContainer);
            cityInst[DATA_FIELD_RELIGION_POP_CHART_IM] = popChartIM;
        else
            popChartIM:ResetInstances();
        end

        local populationChartTooltip:string = RELIGION_POP_CHART_TOOLTIP_HEADER;

        -- Add religion icons for each active religion
        for i,religionInfo in ipairs(activeReligions) do
            local religionDef:table = GameInfo.Religions[religionInfo.Religion];

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
            local iconInst:table = iconIM:GetInstance();
            iconInst.ReligionIconButton:SetIcon(icon);
            iconInst.ReligionIconButton:SetColor(religionColor);
            iconInst.ReligionIconButtonBacking:SetColor(religionColor);
            --iconInst.ReligionIconButtonBacking:SetToolTipString(religionName); -- #59 Infixo new field and tooltip
            iconInst.ReligionIconFollowers:SetText(religionInfo.Followers);
            iconInst.ReligionIconContainer:SetToolTipString(
                Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP", religionName, religionInfo.Followers, Round(religionInfo.LifetimePressure)).."[NEWLINE]"..
                Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", "+"..tostring(Round(religionInfo.Pressure, 1))));
            
            
            -- Add followers to detailed info list
            local followerListInst:table = followerListIM:GetInstance();
            followerListInst.ReligionFollowerIcon:SetIcon(icon);
            followerListInst.ReligionFollowerIcon:SetColor(religionColor);
            followerListInst.ReligionFollowerIconBacking:SetColor(religionColor);
            followerListInst.ReligionFollowerCount:SetText(religionInfo.Followers);
            followerListInst.ReligionFollowerPressure:SetText(Locale.Lookup("LOC_CITY_BANNER_RELIGIOUS_PRESSURE", Round(religionInfo.Pressure)));

            -- Add the follower tooltip to the population chart tooltip
            local followerTooltip:string = Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP", religionName, religionInfo.Followers, Round(religionInfo.LifetimePressure));
            followerListInst.ReligionFollowerIconBacking:SetToolTipString(followerTooltip);
            populationChartTooltip = populationChartTooltip .. "[NEWLINE][NEWLINE]" .. followerTooltip;
        end

        religionInfoInst.ReligionPopChartContainer:SetToolTipString(populationChartTooltip);
        
        religionInfoInst.ReligionFollowerListStack:CalculateSize();
        religionInfoInst.ReligionFollowerListScrollPanel:CalculateInternalSize();
        religionInfoInst.ReligionFollowerListScrollPanel:ReprocessAnchoring();

        -- Add populations to pie chart in reverse order
        for i = #activeReligions, 1, -1 do
            local religionInfo = activeReligions[i];
            local religionColor = UI.GetColorValue(religionInfo.Color);

            local popChartInst:table = popChartIM:GetInstance();
            popChartInst.PopChartMeter:SetPercent(religionInfo.AccumulativeFillPercent);
            popChartInst.PopChartMeter:SetColor(religionColor);
        end

        -- Update population pie chart majority religion icon
        if (eMajorityReligion > 0) then
            local iconName : string = "ICON_" .. GameInfo.Religions[eMajorityReligion].ReligionType;
            religionInfoInst.ReligionPopChartIcon:SetIcon(iconName);
            religionInfoInst.ReligionPopChartIcon:SetHide(false);
        else
            religionInfoInst.ReligionPopChartIcon:SetHide(true);
        end

        -- Show what religion we will eventually turn into
        local nextReligion = pCityReligion:GetNextReligion();
        local turnsTillNextReligion:number = pCityReligion:GetTurnsToNextReligion();
        if nextReligion and nextReligion ~= -1 and turnsTillNextReligion > 0 then
            local pNextReligionDef:table = GameInfo.Religions[nextReligion];

            -- Religion icon
            if religionInfoInst.ConvertingReligionIcon then
                local religionIcon = "ICON_" .. pNextReligionDef.ReligionType;
                religionInfoInst.ConvertingReligionIcon:SetIcon(religionIcon);
                local religionColor = UI.GetColorValue(pNextReligionDef.Color);
                religionInfoInst.ConvertingReligionIcon:SetColor(religionColor);
                religionInfoInst.ConvertingReligionIconBacking:SetColor(religionColor);
                religionInfoInst.ConvertingReligionIconBacking:SetToolTipString(Locale.Lookup(pNextReligionDef.Name));
            end

            -- Converting text
            local convertString = Locale.Lookup("LOC_CITY_BANNER_CONVERTS_IN_X_TURNS", turnsTillNextReligion);
            religionInfoInst.ConvertingReligionLabel:SetText(convertString);
            religionInfoInst.ReligionConversionTurnsStack:SetHide(false);

            -- If the turns till conversion are less than 10 play the warning flash animation
            religionInfoInst.ConvertingSoonAlphaAnim:SetToBeginning();
            if turnsTillNextReligion <= 10 then
                religionInfoInst.ConvertingSoonAlphaAnim:Play();
            else
                religionInfoInst.ConvertingSoonAlphaAnim:Stop();
            end
        else
            religionInfoInst.ReligionConversionTurnsStack:SetHide(true);
        end

        -- Show how much religion this city is exerting outwards
        local outwardReligiousPressure = pCityReligion:GetPressureFromCity();
        religionInfoInst.ExertedReligiousPressure:SetText(Locale.Lookup("LOC_CITY_BANNER_RELIGIOUS_PRESSURE", Round(outwardReligiousPressure)));

        -- Reset buttons to default state
        religionInfoInst.ReligionInfoButton:SetHide(false);
        religionInfoInst.ReligionInfoDetailedButton:SetHide(true);

        -- Register callbacks to open/close detailed info
        religionInfoInst.ReligionInfoButton:RegisterCallback( Mouse.eLClick, function() OnReligionInfoButtonClicked(religionInfoInst, pCity); end);
        religionInfoInst.ReligionInfoDetailedButton:RegisterCallback( Mouse.eLClick, function() OnReligionInfoDetailedButtonClicked(religionInfoInst, pCity); end);

        religionInfoInst.ReligionInfoContainer:SetHide(false);
    end
end

-- ===========================================================================
-- CQUI Custom Functions (Common to basegame only)
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
