-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_SpawnHolySiteIconAtLocation = SpawnHolySiteIconAtLocation;
BASE_CQUI_OnImprovementAddedToMap = OnImprovementAddedToMap;
BASE_CQUI_OnShutdown = OnShutdown;
BASE_CQUI_OnGameDebugReturn = OnGameDebugReturn;
BASE_CQUI_OnInterfaceModeChanged = OnInterfaceModeChanged;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_WorkIconSize      :number  = 48;
local CQUI_WorkIconAlpha              = 0.60;
local CQUI_SmartWorkIcon     :boolean = true;
local CQUI_SmartWorkIconSize :number  = 64;
local CQUI_SmartWorkIconAlpha         = 0.45;

local CQUI_HousingFromImprovementsTable  :table   = {};
local CQUI_HousingUpdated                :table   = {};
local CQUI_ShowYieldsOnCityHover         :boolean = false;
local CQUI_PlotIM                        :table   = InstanceManager:new( "CQUI_WorkedPlotInstance", "Anchor", Controls.CQUI_WorkedPlotContainer );
local CQUI_uiWorldMap                    :table   = {};
local CQUI_yieldsOn                      :boolean = false;
local CQUI_Hovering                      :boolean = false;
local CQUI_NextPlot4Away                 :number  = nil;
local CQUI_ShowCitizenIconsOnCityHover   :boolean = false;
local CQUI_ShowCityManageAreaOnCityHover :boolean = true;
local CQUI_CityManageAreaShown           :boolean = false;
local CQUI_CityManageAreaShouldShow      :boolean = false;
local CQUI_CityYields                    :number  = UILens.CreateLensLayerHash("City_Yields");
local CQUI_CitizenManagement             :number  = UILens.CreateLensLayerHash("Citizen_Management");
local g_smartbanner                      :boolean = true;
local g_smartbanner_unmanaged_citizen    :boolean = false;
local g_smartbanner_districts            :boolean = true;
local g_smartbanner_population           :boolean = true;
local g_smartbanner_cultural             :boolean = true;

function CQUI_OnSettingsInitialized()
  CQUI_ShowYieldsOnCityHover = GameConfiguration.GetValue("CQUI_ShowYieldsOnCityHover");
  g_smartbanner              = GameConfiguration.GetValue("CQUI_Smartbanner");
  g_smartbanner_districts    = GameConfiguration.GetValue("CQUI_Smartbanner_Districts");
  g_smartbanner_population   = GameConfiguration.GetValue("CQUI_Smartbanner_Population");
  g_smartbanner_cultural     = GameConfiguration.GetValue("CQUI_Smartbanner_Cultural");
  g_smartbanner_unmanaged_citizen = GameConfiguration.GetValue("CQUI_Smartbanner_UnlockedCitizen");

  CQUI_WorkIconSize       = GameConfiguration.GetValue("CQUI_WorkIconSize");
  CQUI_WorkIconAlpha      = GameConfiguration.GetValue("CQUI_WorkIconAlpha") / 100;
  CQUI_SmartWorkIcon      = GameConfiguration.GetValue("CQUI_SmartWorkIcon");
  CQUI_SmartWorkIconSize  = GameConfiguration.GetValue("CQUI_SmartWorkIconSize");
  CQUI_SmartWorkIconAlpha = GameConfiguration.GetValue("CQUI_SmartWorkIconAlpha") / 100;

  CQUI_ShowCitizenIconsOnCityHover   = GameConfiguration.GetValue("CQUI_ShowCitizenIconsOnCityHover");
  CQUI_ShowCityManageAreaOnCityHover = GameConfiguration.GetValue("CQUI_ShowCityManageAreaOnCityHover");
  CQUI_ShowCityManageAreaInScreen    = GameConfiguration.GetValue("CQUI_ShowCityMangeAreaInScreen")
end

function CQUI_OnSettingsUpdate()
  CQUI_OnSettingsInitialized();
  Reload();
end
LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );



-- ===========================================================================
-- CQUI Extension Functions
-- ===========================================================================
function CityBanner.Initialize( self : CityBanner, playerID: number, cityID : number, districtID : number, bannerType : number, bannerStyle : number)
  BASE_CQUI_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);

  if (self.m_Instance.CityBannerButton == nil) then
    return;
  end
  -- Register the MouseOver callbacks
  if (bannerType == BANNERTYPE_CITY_CENTER) and (bannerStyle == BANNERSTYLE_LOCAL_TEAM) then
    if (playerID == Game.GetLocalPlayer()) then
      -- Register the callbacks 
      self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseEnter, CQUI_OnBannerMouseOver );
      self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseExit,  CQUI_OnBannerMouseExit );
    end
  end
end

-- ===========================================================================
function SpawnHolySiteIconAtLocation( locX : number, locY:number, label:string )
  BASE_CQUI_SpawnHolySiteIconAtLocation(locX, locY, label);
  iconInst.HolySiteIcon:SetTexture(198, 88, "FontIcons");
  iconInst.Anchor:SetSizeX(iconInst.HolySiteIcon:GetSizeX() + iconInst.HolySiteLabel:GetSizeX());
  iconInst.Anchor:SetToolTipString(Locale.Lookup("LOC_UI_RELIGION_HOLY_SITE_BONUS_TT", label));
end

-- ===========================================================================
function OnImprovementAddedToMap(locX, locY, eImprovementType, eOwner)
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

  BASE_CQUI_OnImprovementAddedToMap(locX, locY, eImprovementType, eOwner);
end

-- ===========================================================================
function OnShutdown()
  -- CQUI values
  LuaEvents.GameDebug_AddValue("CityBannerManager", "CQUI_HousingFromImprovementsTable", CQUI_HousingFromImprovementsTable);
  LuaEvents.GameDebug_AddValue("CityBannerManager", "CQUI_HousingUpdated", CQUI_HousingUpdated);

  BASE_CQUI_OnShutdown();

  CQUI_PlotIM:DestroyInstances();
end

-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
  if context == "CityBannerManager" then
    -- CQUI cached values
    CQUI_HousingFromImprovementsTable = contextTable["CQUI_HousingFromImprovementsTable"];
    CQUI_HousingUpdated = contextTable["CQUI_HousingUpdated"];
    -- CQUI settings
    CQUI_OnSettingsUpdate();
  end

  BASE_CQUI_OnGameDebugReturn;
end

-- ===========================================================================
function OnInterfaceModeChanged( oldMode:number, newMode:number )
  BASE_CQUI_OnInterfaceModeChanged(oldMode, newMode);

  if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
    CQUI_CityManageAreaShown = false
    CQUI_CityManageAreaShouldShow = false
  end
end

-- ===========================================================================
-- CQUI Replacement Functions
-- ===========================================================================
function CityBanner.UpdateStats( self : CityBanner)
  self:UpdateName();
  local pDistrict:table = self:GetDistrict();
  local localPlayerID:number = Game.GetLocalPlayer();

  if (pDistrict ~= nil) then
    local districtHitpoints     :number = pDistrict:GetMaxDamage(DefenseTypes.DISTRICT_GARRISON);
    local currentDistrictDamage :number = pDistrict:GetDamage(DefenseTypes.DISTRICT_GARRISON);
    local wallHitpoints         :number = pDistrict:GetMaxDamage(DefenseTypes.DISTRICT_OUTER);
    local currentWallDamage     :number = pDistrict:GetDamage(DefenseTypes.DISTRICT_OUTER);
    local garrisonDefense       :number = math.floor(pDistrict:GetDefenseStrength() + 0.5);

    if self.m_Type == BANNERTYPE_CITY_CENTER then
      local pCity         :table = self:GetCity();
      local currentPopulation :number = pCity:GetPopulation();
      local pCityGrowth   :table  = pCity:GetGrowth();
      local pBuildQueue   :table  = pCity:GetBuildQueue();
      local pCityData     :table  = GetCityData(pCity);
      local foodSurplus   :number = pCityGrowth:GetFoodSurplus();
      local isGrowing     :boolean= pCityGrowth:GetTurnsUntilGrowth() ~= -1;
      local isStarving    :boolean= pCityGrowth:GetTurnsUntilStarvation() ~= -1;
      local pCityCulture  :table  = pCity:GetCulture();

      local iModifiedFood;
      local total :number;

      if pCityData.TurnsUntilGrowth > -1 then
        local growthModifier =  math.max(1 + (pCityData.HappinessGrowthModifier/100) + pCityData.OtherGrowthModifiers, 0); -- This is unintuitive but it's in parity with the logic in City_Growth.cpp
        iModifiedFood = Round(pCityData.FoodSurplus * growthModifier, 2);
        total = iModifiedFood * pCityData.HousingMultiplier;
      else
        total = pCityData.FoodSurplus;
      end

      local turnsUntilGrowth :number = 0; -- It is possible for zero... no growth and no starving.
      if isGrowing then
        turnsUntilGrowth = pCityGrowth:GetTurnsUntilGrowth();
      elseif isStarving then
        turnsUntilGrowth = -pCityGrowth:GetTurnsUntilStarvation();  -- Make negative
      end

      self.m_Instance.CityPopulation:SetText(GetCityPopulationText(self, currentPopulation));

      if (self.m_Player == Players[localPlayerID]) then --Only show growth data if the player is you
        local popTurnLeftColor = "";
        if turnsUntilGrowth > 0 then
          popTurnLeftColor = "StatGoodCS";
        elseif turnsUntilGrowth < 0 then
          popTurnLeftColor = "StatBadCS";
        else
          popTurnLeftColor = "StatNormalCS";
        end

        if g_smartbanner and g_smartbanner_cultural then
          local turnsUntilBorderGrowth = pCityCulture:GetTurnsUntilExpansion();
          self.m_Instance.CityCultureTurnsLeft:SetText(turnsUntilBorderGrowth);
          self.m_Instance.CityCultureTurnsLeft:SetHide(false);
        else
          self.m_Instance.CityCultureTurnsLeft:SetHide(true);
        end

        -- CQUI get real housing from improvements value
        local pCityID = pCity:GetID();
        if (CQUI_HousingUpdated[localPlayerID] == nil or CQUI_HousingUpdated[localPlayerID][pCityID] ~= true) then
          CQUI_RealHousingFromImprovements(pCity, localPlayerID, pCityID);
        end

        if (g_smartbanner and g_smartbanner_population) then
          local CQUI_HousingFromImprovements = CQUI_HousingFromImprovementsTable[localPlayerID][pCityID];    -- CQUI real housing from improvements value
          if CQUI_HousingFromImprovements ~= nil then    -- CQUI real housing from improvements fix to show correct values when waiting for the next turn
            local popTooltip:string = GetPopulationTooltip(self, turnsUntilGrowth, currentPopulation, total);
            self.m_Instance.CityPopulation:SetToolTipString(popTooltip);
            local housingLeft = pCityGrowth:GetHousing() - pCityGrowth:GetHousingFromImprovements() + CQUI_HousingFromImprovements - currentPopulation;    -- CQUI calculate real housing
            local housingLeftText = housingLeft;
            local housingLeftColor = "Error";
            if housingLeft > 1.5 then
              housingLeftColor = "StatGoodCS";
              housingLeftText = "+"..housingLeft;
              --COLOR: Green
            elseif housingLeft <= 1.5 and housingLeft > 0.5 then
              housingLeftColor = "WarningMinor";
              housingLeftText = "+"..housingLeft;
              --COLOR: Yellow
            elseif housingLeft == 0.5 then
              housingLeftColor = "WarningMajor";
              housingLeftText = "+"..housingLeft;
            elseif housingLeft < 0.5 and housingLeft >= -4.5 then
              housingLeftColor = "WarningMajor";
            end

            local CTLS = "[COLOR:"..popTurnLeftColor.."]"..turnsUntilGrowth.."[ENDCOLOR]  [[COLOR:"..housingLeftColor.."]"..housingLeftText.."[ENDCOLOR]]  ";
            self.m_Instance.CityPopTurnsLeft:SetText(CTLS);
            self.m_Instance.CityPopTurnsLeft:SetHide(false);
          end
        else
          self.m_Instance.CityPopTurnsLeft:SetHide(true);
        end
      end

      local food             :number = pCityGrowth:GetFood();
      local growthThreshold  :number = pCityGrowth:GetGrowthThreshold();
      local foodSurplus      :number = pCityGrowth:GetFoodSurplus();
      local foodpct          :number = Clamp( food / growthThreshold, 0.0, 1.0 );
      local foodpctNextTurn  :number = 0;
      if turnsUntilGrowth > 0 then
        local foodGainNextTurn = foodSurplus * pCityGrowth:GetOverallGrowthModifier();
        foodpctNextTurn = (food + foodGainNextTurn) / growthThreshold;
        foodpctNextTurn = Clamp( foodpctNextTurn, 0.0, 1.0 );
      end

      self.m_Instance.CityPopulationMeter:SetPercent(foodpct);
      self.m_Instance.CityPopulationNextTurn:SetPercent(foodpctNextTurn);

      -- Update insufficient housing icon
      if self.m_Instance.CityHousingInsufficientIcon ~= nil then
        self.m_Instance.CityHousingInsufficientIcon:SetToolTipString(Locale.Lookup("LOC_CITY_BANNER_HOUSING_INSUFFICIENT"));
        if pCityGrowth:GetHousing() < pCity:GetPopulation() then
          self.m_Instance.CityHousingInsufficientIcon:SetHide(false);
        else
          self.m_Instance.CityHousingInsufficientIcon:SetHide(true);
        end
      end

      --- CITY PRODUCTION ---
      self:UpdateProduction();

      --- DEFENSE INFO ---
      local garrisonDefString :string = Locale.Lookup("LOC_CITY_BANNER_GARRISON_DEFENSE_STRENGTH");
      local defValue = garrisonDefense;
      local defTooltip = garrisonDefString .. ": " .. garrisonDefense;
      local healthTooltip :string = Locale.Lookup("LOC_CITY_BANNER_GARRISON_HITPOINTS", ((districtHitpoints - currentDistrictDamage) .. "/" .. districtHitpoints));
      if (wallHitpoints > 0) then
        self.m_Instance.DefenseIcon:SetHide(true);
        self.m_Instance.ShieldsIcon:SetHide(false);
        self.m_Instance.CityDefenseBarBacking:SetHide(false);
        self.m_Instance.CityHealthBarBacking:SetHide(false);
        self.m_Instance.CityDefenseBar:SetHide(false);
        healthTooltip = healthTooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_CITY_BANNER_OUTER_DEFENSE_HITPOINTS", ((wallHitpoints - currentWallDamage) .. "/" .. wallHitpoints));
        self.m_Instance.CityDefenseBar:SetPercent((wallHitpoints - currentWallDamage) / wallHitpoints);
      else
        self.m_Instance.CityDefenseBar:SetHide(true)
        self.m_Instance.CityDefenseBarBacking:SetHide(true);
        self.m_Instance.CityHealthBarBacking:SetHide(true);
      end

      self.m_Instance.DefenseNumber:SetText(defValue);
      self.m_Instance.DefenseNumber:SetToolTipString(defTooltip);
      self.m_Instance.CityHealthBarBacking:SetToolTipString(healthTooltip);
      self.m_Instance.CityHealthBarBacking:SetHide(false);
      if(districtHitpoints > 0) then
        self.m_Instance.CityHealthBar:SetPercent((districtHitpoints - currentDistrictDamage) / districtHitpoints);
      else
        self.m_Instance.CityHealthBar:SetPercent(0);
      end

      self:SetHealthBarColor();
      if (((districtHitpoints-currentDistrictDamage) / districtHitpoints) == 1 and wallHitpoints == 0) then
        self.m_Instance.CityHealthBar:SetHide(true);
        self.m_Instance.CityHealthBarBacking:SetHide(true);
      else
        self.m_Instance.CityHealthBar:SetHide(false);
        self.m_Instance.CityHealthBarBacking:SetHide(false);
      end

      self.m_Instance.DefenseStack:CalculateSize();
      self.m_Instance.DefenseStack:ReprocessAnchoring();
      self.m_Instance.BannerStrengthBacking:SetSizeX(self.m_Instance.DefenseStack:GetSizeX() + 30);
      self.m_Instance.BannerStrengthBacking:SetToolTipString(defTooltip);

      -- Update under siege icon
      if pDistrict:IsUnderSiege() then
        self.m_Instance.CityUnderSiegeIcon:SetHide(false);
      else
        self.m_Instance.CityUnderSiegeIcon:SetHide(true);
      end

      -- Update occupied icon
      if pCity:IsOccupied() then
        self.m_Instance.CityOccupiedIcon:SetHide(false);
      else
        self.m_Instance.CityOccupiedIcon:SetHide(true);
      end

      -- Update insufficient amenities icon
      if self.m_Instance.CityAmenitiesInsufficientIcon ~= nil then
        self.m_Instance.CityAmenitiesInsufficientIcon:SetToolTipString(Locale.Lookup("LOC_CITY_BANNER_AMENITIES_INSUFFICIENT"));
        if pCityGrowth:GetAmenitiesNeeded() > pCityGrowth:GetAmenities() then
          self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(false);
        else
          self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(true);
        end
      end
    else -- it should be a miniBanner
      if (self.m_Type == BANNERTYPE_ENCAMPMENT) then
        self:UpdateEncampmentBanner();
      elseif (self.m_Type == BANNERTYPE_AERODROME) then
        self:UpdateAerodromeBanner();
      elseif (self.m_Type == BANNERTYPE_OTHER_DISTRICT) then
        self:UpdateDistrictBanner();
      end
    end
  else  --it's a banner not associated with a district
    if (self.m_IsImprovementBanner) then
      local bannerPlot = Map.GetPlot(self.m_PlotX, self.m_PlotY);
      if (bannerPlot ~= nil) then
        if (self.m_Type == BANNERTYPE_AERODROME) then
          self:UpdateAerodromeBanner();
        elseif (self.m_Type == BANNERTYPE_MISSILE_SILO) then
          self:UpdateWMDBanner();
        end
      end
    end
  end
end

-- ===========================================================================
function OnCityBannerClick( playerID:number, cityID:number )
  local pPlayer = Players[playerID];
  if (pPlayer == nil) then
    return;
  end

  local pCity = pPlayer:GetCities():FindID(cityID);
  if (pCity == nil) then
    return;
  end

  -- Code in basegame file, applies to Tutorial mode only. 
  -- Disabling here as it's unlikely to be a problem within the realm of this mod
  -- if m_isMapDeselectDisabled then
  --  return;
  -- end

  local localPlayerID;
  if (WorldBuilder.IsActive()) then
    localPlayerID = playerID; -- If WorldBuilder is active, allow the user to select the city
  else
    localPlayerID = Game.GetLocalPlayer();
  end

  if (pPlayer:GetID() == localPlayerID) then
    UI.SelectCity( pCity );
    UI.SetCycleAdvanceTimer(0); -- Cancel any auto-advance timer
    -- CQUI CUSTOMIZED CODE BEGIN
    UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);
    -- CQUI CUSTOMIZED CODE END
  elseif(localPlayerID == PlayerTypes.OBSERVER
      or localPlayerID == PlayerTypes.NONE
      or pPlayer:GetDiplomacy():HasMet(localPlayerID)) then

    -- CQUI CUSTOMIZED CODE BEGIN
    LuaEvents.CQUI_CityviewDisable(); -- Make sure the cityview is disable
    -- CQUI CUSTOMIZED CODE END
    local pPlayerConfig :table    = PlayerConfigurations[playerID];
    local isMinorCiv  :boolean  = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
    --print("clicked player " .. playerID .. " city.  IsMinor?: ",isMinorCiv);

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
end

-- ===========================================================================
function OnProductionClick( playerID, cityID )
  OnCityBannerClick( playerID, cityID);
end

-- ===========================================================================
function CityBanner.UpdateName( self : CityBanner )
  if (self.m_Type == BANNERTYPE_CITY_CENTER) then
    local pCity : table = self:GetCity();
    if pCity ~= nil then
      local owner     :number = pCity:GetOwner();
      local pPlayer   :table  = Players[owner];
      local capitalIcon :string = (pPlayer ~= nil and pPlayer:IsMajor() and pCity:IsCapital()) and "[ICON_Capital]" or "";
      local cityName    :string = capitalIcon .. Locale.ToUpper(pCity:GetName());

      if not self:IsTeam() then
        local civType:string = PlayerConfigurations[owner]:GetCivilizationTypeName();
        if civType ~= nil then
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
      if pDistrict and pDistrict:IsUnderSiege() then
        self.m_Instance.CityUnderSiegeIcon:SetHide(false);
      else
        self.m_Instance.CityUnderSiegeIcon:SetHide(true);
      end

      -- Update district icons
      -- districtType:number == Index
      function GetDistrictIndexSafe(sDistrict)
        if GameInfo.Districts[sDistrict] == nil then return -1;
        else return GameInfo.Districts[sDistrict].Index; end
      end

      local iAquaduct       = GetDistrictIndexSafe("DISTRICT_AQUEDUCT");
      local iBath           = GetDistrictIndexSafe("DISTRICT_BATH");
      local iNeighborhood   = GetDistrictIndexSafe("DISTRICT_NEIGHBORHOOD");
      local iMbanza         = GetDistrictIndexSafe("DISTRICT_MBANZA");
      local iCampus         = GetDistrictIndexSafe("DISTRICT_CAMPUS");
      local iTheater        = GetDistrictIndexSafe("DISTRICT_THEATER");
      local iAcropolis      = GetDistrictIndexSafe("DISTRICT_ACROPOLIS");
      local iIndustrial     = GetDistrictIndexSafe("DISTRICT_INDUSTRIAL_ZONE");
      local iHansa          = GetDistrictIndexSafe("DISTRICT_HANSA");
      local iCommerce       = GetDistrictIndexSafe("DISTRICT_COMMERCIAL_HUB");
      local iEncampment     = GetDistrictIndexSafe("DISTRICT_ENCAMPMENT");
      local iHarbor         = GetDistrictIndexSafe("DISTRICT_HARBOR");
      local iRoyalNavy      = GetDistrictIndexSafe("DISTRICT_ROYAL_NAVY_DOCKYARD");
      local iSpaceport      = GetDistrictIndexSafe("DISTRICT_SPACEPORT");
      local iEntComplex     = GetDistrictIndexSafe("DISTRICT_ENTERTAINMENT_COMPLEX");
      local iHolySite       = GetDistrictIndexSafe("DISTRICT_HOLY_SITE");
      local iAerodrome      = GetDistrictIndexSafe("DISTRICT_AERODROME");
      local iStreetCarnival = GetDistrictIndexSafe("DISTRICT_STREET_CARNIVAL");
      local iLavra          = GetDistrictIndexSafe("DISTRICT_LAVRA");

      if self.m_Instance.CityBuiltDistrictAquaduct ~= nil then
        self.m_Instance.CityUnlockedCitizen:SetHide(true);
        self.m_Instance.CityBuiltDistrictAquaduct:SetHide(true);
        self.m_Instance.CityBuiltDistrictBath:SetHide(true);
        self.m_Instance.CityBuiltDistrictNeighborhood:SetHide(true);
        self.m_Instance.CityBuiltDistrictMbanza:SetHide(true);
        self.m_Instance.CityBuiltDistrictCampus:SetHide(true);
        self.m_Instance.CityBuiltDistrictCommercial:SetHide(true);
        self.m_Instance.CityBuiltDistrictEncampment:SetHide(true);
        self.m_Instance.CityBuiltDistrictTheatre:SetHide(true);
        self.m_Instance.CityBuiltDistrictAcropolis:SetHide(true);
        self.m_Instance.CityBuiltDistrictIndustrial:SetHide(true);
        self.m_Instance.CityBuiltDistrictHansa:SetHide(true);
        self.m_Instance.CityBuiltDistrictHarbor:SetHide(true);
        self.m_Instance.CityBuiltDistrictRoyalNavy:SetHide(true);
        self.m_Instance.CityBuiltDistrictSpaceport:SetHide(true);
        self.m_Instance.CityBuiltDistrictEntertainment:SetHide(true);
        self.m_Instance.CityBuiltDistrictHoly:SetHide(true);
        self.m_Instance.CityBuiltDistrictAerodrome:SetHide(true);
        self.m_Instance.CityBuiltDistrictStreetCarnival:SetHide(true);
        self.m_Instance.CityBuiltDistrictLavra:SetHide(true);
      end

      local pCityDistricts:table  = pCity:GetDistricts();
      if g_smartbanner and self.m_Instance.CityBuiltDistrictAquaduct ~= nil then
        --Unlocked citizen check
        if g_smartbanner_unmanaged_citizen then
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
                if(tMaxUnits[i] >= 1 and tUnits[i] >= 1 and tLockedUnits[i] <= 0) then
                  self.m_Instance.CityUnlockedCitizen:SetHide(false);
                end
              end
            end
          end
        end
        -- End Unlocked Citizen Check

        if g_smartbanner_districts then
          for i, district in pCityDistricts:Members() do
            local districtType = district:GetType();
            local districtInfo:table = GameInfo.Districts[districtType];
            local isBuilt = pCityDistricts:HasDistrict(districtInfo.Index, true);
            if isBuilt then
              if (districtType == iAquaduct)       then self.m_Instance.CityBuiltDistrictAquaduct:SetHide(false);       end
              if (districtType == iBath)           then self.m_Instance.CityBuiltDistrictBath:SetHide(false);           end
              if (districtType == iNeighborhood)   then self.m_Instance.CityBuiltDistrictNeighborhood:SetHide(false);   end
              if (districtType == iMbanza)         then self.m_Instance.CityBuiltDistrictMbanza:SetHide(false);         end
              if (districtType == iCampus)         then self.m_Instance.CityBuiltDistrictCampus:SetHide(false);         end
              if (districtType == iCommerce)       then self.m_Instance.CityBuiltDistrictCommercial:SetHide(false);     end
              if (districtType == iEncampment)     then self.m_Instance.CityBuiltDistrictEncampment:SetHide(false);     end
              if (districtType == iTheater)        then self.m_Instance.CityBuiltDistrictTheatre:SetHide(false);        end
              if (districtType == iAcropolis)      then self.m_Instance.CityBuiltDistrictAcropolis:SetHide(false);      end
              if (districtType == iIndustrial)     then self.m_Instance.CityBuiltDistrictIndustrial:SetHide(false);     end
              if (districtType == iHansa)          then self.m_Instance.CityBuiltDistrictHansa:SetHide(false);          end
              if (districtType == iHarbor)         then self.m_Instance.CityBuiltDistrictHarbor:SetHide(false);         end
              if (districtType == iRoyalNavy)      then self.m_Instance.CityBuiltDistrictRoyalNavy:SetHide(false);      end
              if (districtType == iSpaceport)      then self.m_Instance.CityBuiltDistrictSpaceport:SetHide(false);      end
              if (districtType == iEntComplex)     then self.m_Instance.CityBuiltDistrictEntertainment:SetHide(false);  end
              if (districtType == iHolySite)       then self.m_Instance.CityBuiltDistrictHoly:SetHide(false);           end
              if (districtType == iAerodrome)      then self.m_Instance.CityBuiltDistrictAerodrome:SetHide(false);      end
              if (districtType == iStreetCarnival) then self.m_Instance.CityBuiltDistrictStreetCarnival:SetHide(false); end
              if (districtType == iLavra)          then self.m_Instance.CityBuiltDistrictLavra:SetHide(false);          end
            end
          end
        end
      end

      -- Update insufficient housing icon
      if self.m_Instance.CityHousingInsufficientIcon ~= nil then
        local pCityGrowth:table = pCity:GetGrowth();
        if pCityGrowth and pCityGrowth:GetHousing() < pCity:GetPopulation() then
          self.m_Instance.CityHousingInsufficientIcon:SetHide(false);
        else
          self.m_Instance.CityHousingInsufficientIcon:SetHide(true);
        end
      end

      -- Update insufficient amenities icon
      if self.m_Instance.CityAmenitiesInsufficientIcon ~= nil then
        local pCityGrowth:table = pCity:GetGrowth();
        if pCityGrowth and pCityGrowth:GetAmenitiesNeeded() > pCityGrowth:GetAmenities() then
          self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(false);
        else
          self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(true);
        end
      end

      -- Update occupied icon
      if self.m_Instance.CityOccupiedIcon ~= nil then
        if pCity:IsOccupied() then
          self.m_Instance.CityOccupiedIcon:SetHide(false);
        else
          self.m_Instance.CityOccupiedIcon:SetHide(true);
        end
      end

      -- CQUI: Show leader icon for the suzerain
      local pPlayerConfig :table = PlayerConfigurations[owner];
      local isMinorCiv :boolean = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
      if isMinorCiv then
        CQUI_UpdateSuzerainIcon(pPlayer, self);
      end

      self.m_Instance.CityQuestIcon:SetToolTipString(questTooltip);
      self.m_Instance.CityQuestIcon:SetText(statusString);
      self.m_Instance.CityName:SetText( cityName );
      self.m_Instance.CityNameStack:ReprocessAnchoring();
      self.m_Instance.ContentStack:ReprocessAnchoring();
      self:Resize();
    end
  end
end

-- ===========================================================================
function OnCityRangeStrikeButtonClick( playerID, cityID )
  local pPlayer = Players[playerID];
  if (pPlayer == nil) then
    return;
  end

  local pCity = pPlayer:GetCities():FindID(cityID);
  if (pCity == nil) then
    return;
  end

  -- AZURENCY : Enter the range city mode on click (not on hover of a button, the old workaround)
  LuaEvents.CQUI_Strike_Enter();
  -- AZURENCY : Allow to switch between different city range attack (clicking on the range button of one
  -- city and after on the range button of another city, without having to ESC or right click)
  UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
  --ARISTOS: fix for the range strike not showing odds window
  UI.DeselectAll();
  UI.SelectCity( pCity );
  UI.SetInterfaceMode(InterfaceModeTypes.CITY_RANGE_ATTACK);
end

-- ===========================================================================
function OnDistrictAddedToMap( playerID: number, districtID : number, cityID :number, districtX : number, districtY : number, districtType:number, percentComplete:number )

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
  if (pCity == nil) then
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
      cityBanner:SetColor();
    end
  else
    -- Create a banner for a district that is not the city-center
    local miniBanner = GetMiniBanner( playerID, districtID );
    if (miniBanner == nil) then
      if ( GameInfo.Districts[pDistrict:GetType()].AirSlots > 0 ) then
        if (pDistrict:IsComplete()) then
          AddMiniBannerToMap( playerID, cityID, districtID, BANNERTYPE_AERODROME );
        end
      elseif (pDistrict:GetDefenseStrength() > 0 ) then
        if pDistrict:IsComplete() then
          AddMiniBannerToMap( playerID, cityID, districtID, BANNERTYPE_ENCAMPMENT );
        end
      else
        AddMiniBannerToMap( playerID, cityID, districtID, BANNERTYPE_OTHER_DISTRICT );
      end

      if (pDistrict:IsComplete()) then
        -- CQUI update city's real housing from improvements when completed a district that triggers a Culture Bomb
        if playerID == Game.GetLocalPlayer() then
          if districtType == GameInfo.Districts["DISTRICT_ENCAMPMENT"].Index then
            if PlayerConfigurations[playerID]:GetCivilizationTypeName() == "CIVILIZATION_POLAND" then
              CQUI_OnCityInfoUpdated(playerID, cityID);
            end
          elseif districtType == GameInfo.Districts["DISTRICT_HOLY_SITE"].Index or districtType == GameInfo.Districts["DISTRICT_LAVRA"].Index then
            if PlayerConfigurations[playerID]:GetCivilizationTypeName() == "CIVILIZATION_KHMER" then
              CQUI_OnCityInfoUpdated(playerID, cityID);
            else
              local playerReligion :table = pPlayer:GetReligion();
              local playerReligionType :number = playerReligion:GetReligionTypeCreated();
              if playerReligionType ~= -1 then
                local cityReligion :table = pCity:GetReligion();
                local eDominantReligion :number = cityReligion:GetMajorityReligion();
                if eDominantReligion == playerReligionType then
                  local pGameReligion :table = Game.GetReligion();
                  local pAllReligions :table = pGameReligion:GetReligions();
                  for _, kFoundReligion in ipairs(pAllReligions) do
                    if kFoundReligion.Religion == eDominantReligion then
                      for _, belief in pairs(kFoundReligion.Beliefs) do
                        if GameInfo.Beliefs[belief].BeliefType == "BELIEF_BURIAL_GROUNDS" then
                          CQUI_OnCityInfoUpdated(playerID, cityID);
                          break;
                        end
                      end
                      break;
                    end -- if Religion == eDominantReligion
                  end -- for loop
                end -- if Religion == playerReligionType
              end -- if playerReligonType ~= 1
            end -- else (not KHMER)
          end -- elseif District is HolySite or Larva
        end -- if PlayerId == Game.GetLocalPlayer()
      end -- if District is complete
    else -- else if minibanner was nil
      miniBanner:UpdateStats();
    end
  end -- else (not the city center)
end

-- ===========================================================================
-- CQUI Custom Functions
-- ===========================================================================
function CQUI_OnBannerMouseOver(playerID: number, cityID: number)
-- When a banner is moused over, display the relevant yields and next culture plot
if(CQUI_ShowYieldsOnCityHover) then
    CQUI_Hovering = true;
    -- Astog: Fix for lens being shown when other lenses are on.
    -- Astog: Don't show this lens if any unit is selected.
    -- This prevents the need to check if every lens is on or not, like builder, religious lens.
    if CQUI_ShowCityManageAreaOnCityHover
        and not UILens.IsLayerOn(CQUI_CitizenManagement)
        and UI.GetInterfaceMode() == InterfaceModeTypes.SELECTION
        and UI.GetHeadSelectedUnit() == nil then
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

    if (tPlots ~= nil and table.count(tPlots) ~= 0) and UILens.IsLayerOn(CQUI_CitizenManagement) == false then
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
      end
    end

    tResults = CityManager.GetCommandTargets(kCity, CityCommandTypes.PURCHASE, tParameters);
    if tResults == nil then
      return;
    end

    tPlots = tResults[CityCommandResults.PLOTS];

    if (tPlots ~= nil and table.count(tPlots) ~= 0 and UILens.IsLayerOn(CQUI_CitizenManagement)) == false then
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

      if (CQUI_yieldsOn == false and not UILens.IsLayerOn(CQUI_CitizenManagement)) then
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
end

-- ===========================================================================
function CQUI_OnBannerMouseExit(playerID: number, cityID: number)
-- When a banner is moused over, and the mouse leaves the banner, remove display of the relevant yields and next culture plot
  if (not CQUI_Hovering) then
    return;
  end

  CQUI_yieldsOn = UserConfiguration.ShowMapYield();

  if (CQUI_yieldsOn == false and not UILens.IsLayerOn(CQUI_CitizenManagement)) then
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
    print("** CQUI_OnBannerMouseExit: CityManager.GetCommandTargets returned nil!");
    return;
  end

  -- Astog: Fix for lens being cleared when having other lenses on
  if CQUI_ShowCityManageAreaOnCityHover
     and UI.GetInterfaceMode() ~= InterfaceModeTypes.CITY_MANAGEMENT
     and CQUI_CityManageAreaShown then
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

-- CQUI taken from PlotInfo
-- ===========================================================================
--  Obtain an existing instance of plot info or allocate one if it doesn't
--  already exist.
--  plotIndex Game engine index of the plot
-- ===========================================================================
function CQUI_GetInstanceAt( plotIndex:number )
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
  for i, pPlayer in ipairs(PlayerManager.GetAliveMinors()) do
    local iPlayer = pPlayer:GetID();
    local iCapital = pPlayer:GetCities():GetCapitalCity():GetID();
    local bannerInstance = GetCityBanner(iPlayer, iCapital);
    CQUI_UpdateSuzerainIcon(pPlayer, bannerInstance);
  end
end

-- ===========================================================================
function CQUI_UpdateSuzerainIcon( pPlayer:table, bannerInstance:CityBanner )
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
        if(suzerainID == Game.GetLocalPlayer()) then
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
function CQUI_RealHousingFromImprovements(pCity, PlayerID, pCityID)
  local CQUI_HousingFromImprovements = 0;
  local kCityPlots :table = Map.GetCityPlots():GetPurchasedPlots(pCity);
  if kCityPlots ~= nil then
    for _, plotID in pairs(kCityPlots) do
      local kPlot	:table = Map.GetPlotByIndex(plotID);
      if Map.GetPlotDistance( pCity:GetX(), pCity:GetY(), kPlot:GetX(), kPlot:GetY() ) <= 3 then
        local eImprovementType :number = kPlot:GetImprovementType();
        if eImprovementType ~= -1 then
          if not kPlot:IsImprovementPillaged() then
            local kImprovementData = GameInfo.Improvements[eImprovementType].Housing;
            if kImprovementData == 1 then    -- farms, pastures etc.
              if GameInfo.Improvements[eImprovementType].ImprovementType == "IMPROVEMENT_FARM" and HasTrait("TRAIT_CIVILIZATION_MAYAB", Game.GetLocalPlayer()) then
                CQUI_HousingFromImprovements = CQUI_HousingFromImprovements + 2;
              else
                CQUI_HousingFromImprovements = CQUI_HousingFromImprovements + 1;
              end
            elseif kImprovementData == 2 then    -- stepwells, kampungs
              if GameInfo.Improvements[eImprovementType].ImprovementType == "IMPROVEMENT_STEPWELL" then    -- stepwells
                local CQUI_PlayerResearchedSanitation :boolean = Players[Game.GetLocalPlayer()]:GetTechs():HasTech(GameInfo.Technologies["TECH_SANITATION"].Index);    -- check if a player researched Sanitation
                if not CQUI_PlayerResearchedSanitation then
                  CQUI_HousingFromImprovements = CQUI_HousingFromImprovements + 2;
                else
                  CQUI_HousingFromImprovements = CQUI_HousingFromImprovements + 4;
                end
              else    -- kampungs
                local CQUI_PlayerResearchedMassProduction :boolean = Players[Game.GetLocalPlayer()]:GetTechs():HasTech(GameInfo.Technologies["TECH_MASS_PRODUCTION"].Index);    -- check if a player researched Mass Production
                if not CQUI_PlayerResearchedMassProduction then
                  CQUI_HousingFromImprovements = CQUI_HousingFromImprovements + 2;
                else
                  CQUI_HousingFromImprovements = CQUI_HousingFromImprovements + 4;
                end
              end
            end
          end
        end
      end
    end

    CQUI_HousingFromImprovements = CQUI_HousingFromImprovements * 0.5;
    if CQUI_HousingFromImprovementsTable[PlayerID] == nil then
      CQUI_HousingFromImprovementsTable[PlayerID] = {};
    end

    if CQUI_HousingUpdated[PlayerID] == nil then
      CQUI_HousingUpdated[PlayerID] = {};
    end

    CQUI_HousingFromImprovementsTable[PlayerID][pCityID] = CQUI_HousingFromImprovements;
    CQUI_HousingUpdated[PlayerID][pCityID] = true;
    LuaEvents.CQUI_RealHousingFromImprovementsCalculated(pCityID, CQUI_HousingFromImprovements);
  end
end

-- ===========================================================================
-- CQUI update city's real housing from improvements
function CQUI_OnCityInfoUpdated(PlayerID, pCityID)
  CQUI_HousingUpdated[PlayerID][pCityID] = nil;
end

-- ===========================================================================
-- CQUI update all cities real housing from improvements
function CQUI_OnAllCitiesInfoUpdated(PlayerID)
  local m_pCity:table = Players[PlayerID]:GetCities();
  for i, pCity in m_pCity:Members() do
    local pCityID = pCity:GetID();
    CQUI_OnCityInfoUpdated(PlayerID, pCityID)
  end
end

-- ===========================================================================
-- CQUI update close to a culture bomb cities data and real housing from improvements
function CQUI_OnCityLostTileToCultureBomb(PlayerID, x, y)
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
  if playerID == Game.GetLocalPlayer() then
    CQUI_HousingFromImprovementsTable[PlayerID][pCityID] = nil;
    CQUI_HousingUpdated[PlayerID][pCityID] = nil;
    LuaEvents.CQUI_RealHousingFromImprovementsCalculated(pCityID, nil);
  end
end

-- ===========================================================================
-- Game Engine EVENT
-- ===========================================================================
function OnCityWorkerChanged(ownerPlayerID:number, cityID:number)
  if (Game.GetLocalPlayer() == ownerPlayerID) then
    RefreshBanner( ownerPlayerID, cityID )
  end
end

-- ===========================================================================
-- CQUI Initialize Function
-- ===========================================================================
function Initialize()
  Events.CityWorkerChanged.Add(           OnCityWorkerChanged );

  LuaEvents.CQUI_CityInfoUpdated.Add( CQUI_OnCityInfoUpdated );    -- CQUI update city's real housing from improvements
  LuaEvents.CQUI_AllCitiesInfoUpdated.Add( CQUI_OnAllCitiesInfoUpdated );    -- CQUI update all cities real housing from improvements
  LuaEvents.CQUI_CityLostTileToCultureBomb.Add( CQUI_OnCityLostTileToCultureBomb );    -- CQUI update close to a culture bomb cities data and real housing from improvements
  Events.CityRemovedFromMap.Add( CQUI_OnCityRemovedFromMap );    -- CQUI erase real housing from improvements data everywhere when a city removed from map

  LuaEvents.CQUI_CityRangeStrike.Add( OnCityRangeStrikeButtonClick ); -- AZURENCY : to acces it in the actionpannel on the city range attack button
  LuaEvents.CQUI_DistrictRangeStrike.Add( OnDistrictRangeStrikeButtonClick ); -- AZURENCY : to acces it in the actionpannel on the district range attack button

  LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsInitialized );
  Events.CitySelectionChanged.Add( CQUI_OnBannerMouseExit );
  Events.InfluenceGiven.Add( CQUI_OnInfluenceGiven );
end
Initialize();

