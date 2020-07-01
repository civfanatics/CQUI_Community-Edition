-- ===========================================================================
-- CityBannerManager for Expansion 1 and Expansion 2
-- ===========================================================================
-- Functions and objects common to basegame and expansions
include( "citybannermanager_CQUI.lua");

-- #59 Infixo they are local and not visible in this file
local m_isReligionLensActive:boolean = false;
local m_HexColoringReligion:number = UILens.CreateLensLayerHash("Hex_Coloring_Religion");
local DATA_FIELD_RELIGION_ICONS_IM:string = "m_IconsIM";
local DATA_FIELD_RELIGION_FOLLOWER_LIST_IM:string = "m_FollowerListIM";
local DATA_FIELD_RELIGION_POP_CHART_IM		:string = "m_PopChartIM";
local RELIGION_POP_CHART_TOOLTIP_HEADER		:string = Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP_HEADER");

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
-- #59 Infixo overwritten because changes are deep inside it
function CityBanner:UpdateReligion()
    --print("FUN CityBanner:UpdateReligion()");

	local pCity				:table = self:GetCity();
	local pCityReligion		:table = pCity:GetReligion();
	local localPlayerID		:number = Game.GetLocalPlayer();
	local eMajorityReligion	:number = pCityReligion:GetMajorityReligion();

	self.m_eMajorityReligion = eMajorityReligion;
	self:UpdateInfo(pCity);

	local cityInst			:table = self.m_Instance;
	local religionInfo		:table = cityInst.ReligionInfo;
	local religionsInCity	:table = pCityReligion:GetReligionsInCity();

	-- Hide the meter and bail out if the religion lens isn't active
	if(not m_isReligionLensActive or table.count(religionsInCity) == 0) then
		if religionInfo then
			religionInfo.ReligionInfoContainer:SetHide(true);
		end
		return;
	end

	-- Update religion icon + religious pressure animation
	local majorityReligionColor:number = COLOR_RELIGION_DEFAULT;
	if(eMajorityReligion >= 0) then
		majorityReligionColor = UI.GetColorValue(GameInfo.Religions[eMajorityReligion].Color);
	end
	
	-- Preallocate total fill so we can stagger the meters
	local totalFillPercent:number = 0;
	local iCityPopulation:number = pCity:GetPopulation();

	-- Get a list of religions present in this city
	local activeReligions:table = {};
	local numOfActiveReligions:number = 0;
	local pReligionsInCity:table = pCityReligion:GetReligionsInCity();
	for _, cityReligion in pairs(pReligionsInCity) do
		local religion:number = cityReligion.Religion;
        if religion == -1 then religion = 0; end -- #59 Infixo include a pantheon
		--if(religion >= 0) then
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

			numOfActiveReligions = numOfActiveReligions + 1;
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

	if(table.count(activeReligions) > 0) then
		local localPlayerVis:table = PlayersVisibility[localPlayerID];
		if (localPlayerVis ~= nil) then
			-- Holy sites get a different color and texture
			local holySitePlotIDs:table = {};
			local cityDistricts:table = pCity:GetDistricts();
			local playerDistricts:table = self.m_Player:GetDistricts();
			for i, district in cityDistricts:Members() do
				local districtType:string = GameInfo.Districts[district:GetType()].DistrictType;
				if(districtType == "DISTRICT_HOLY_SITE") then
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
			if(table.count(plots) > 0) then
				UILens.SetLayerHexesColoredArea( m_HexColoringReligion, localPlayerID, plots, majorityReligionColor );
			end
		end
	end

	if religionInfo then
		-- Create or reset icon instance manager
		local iconIM:table = cityInst[DATA_FIELD_RELIGION_ICONS_IM];
		if(iconIM == nil) then
			iconIM = InstanceManager:new("ReligionIconInstance", "ReligionIconContainer", religionInfo.ReligionInfoIconStack);
			cityInst[DATA_FIELD_RELIGION_ICONS_IM] = iconIM;
		else
			iconIM:ResetInstances();
		end

		-- Create or reset follower list instance manager
		local followerListIM:table = cityInst[DATA_FIELD_RELIGION_FOLLOWER_LIST_IM];
		if(followerListIM == nil) then
			followerListIM = InstanceManager:new("ReligionFollowerListInstance", "ReligionFollowerListContainer", religionInfo.ReligionFollowerListStack);
			cityInst[DATA_FIELD_RELIGION_FOLLOWER_LIST_IM] = followerListIM;
		else
			followerListIM:ResetInstances();
		end

		-- Create or reset pop chart instance manager
		local popChartIM:table = cityInst[DATA_FIELD_RELIGION_POP_CHART_IM];
		if(popChartIM == nil) then
			popChartIM = InstanceManager:new("ReligionPopChartInstance", "PopChartMeter", religionInfo.ReligionPopChartContainer);
			cityInst[DATA_FIELD_RELIGION_POP_CHART_IM] = popChartIM;
		else
			popChartIM:ResetInstances();
		end

		local populationChartTooltip:string = RELIGION_POP_CHART_TOOLTIP_HEADER;

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

		-- Add religion icons for each active religion
		for i,religionInfo in ipairs(activeReligions) do
			local religionDef:table = GameInfo.Religions[religionInfo.Religion];

			local icon = "ICON_" .. religionDef.ReligionType;
			local religionColor = UI.GetColorValue(religionDef.Color);
		
			-- The first index is the predominant religion. Label it as such.
			local religionName = "";
			if i == 1 and numOfActiveReligions > 1 then
				religionName = Locale.Lookup("LOC_CITY_BANNER_PREDOMINANT_RELIGION", Game.GetReligion():GetName(religionDef.Index));
			else
				religionName = Game.GetReligion():GetName(religionDef.Index);
			end

			-- Add icon to main icon list
			-- If our only active religion is the same religion we're being converted to don't show an icon for it
			--if numOfActiveReligions > 1 or nextReligion ~= religionInfo.Religion then -- #59 Infixo show all religions
				local iconInst:table = iconIM:GetInstance();
				iconInst.ReligionIconButton:SetIcon(icon);
				iconInst.ReligionIconButton:SetColor(religionColor);
				iconInst.ReligionIconButtonBacking:SetColor(religionColor);
				--iconInst.ReligionIconButtonBacking:SetToolTipString(religionName); -- #59 Infixo new field and tooltip
                iconInst.ReligionIconFollowers:SetText(religionInfo.Followers);
                iconInst.ReligionIconContainer:SetToolTipString(
                    Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP", religionName, religionInfo.Followers, Round(religionInfo.LifetimePressure)).."[NEWLINE]"..
                    Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", "+"..tostring(Round(religionInfo.Pressure, 1))));
			--end

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

		religionInfo.ReligionPopChartContainer:SetToolTipString(populationChartTooltip);
	
		religionInfo.ReligionFollowerListStack:CalculateSize();
		religionInfo.ReligionFollowerListScrollPanel:CalculateInternalSize();
		religionInfo.ReligionFollowerListScrollPanel:ReprocessAnchoring();

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
			religionInfo.ReligionPopChartIcon:SetIcon(iconName);
			religionInfo.ReligionPopChartIcon:SetHide(false);
		else
			religionInfo.ReligionPopChartIcon:SetHide(true);
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
end

-- ===========================================================================
--  CQUI Initialize Function
-- ===========================================================================
function Initialize_CQUI_expansions()
    print_debug("CityBannerManager_CQUI_Expansions: Initialize CQUI CityBannerManager")
	Events.LensLayerOff.Add(CQUI_OnLensLayerOff);
	Events.LensLayerOn.Add(CQUI_OnLensLayerOn);
end
Initialize_CQUI_expansions();
