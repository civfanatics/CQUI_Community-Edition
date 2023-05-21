-- ===========================================================================
-- CQUI CityPanel lua
-- CQUI Civ5-style city panel creates many differences from the unmodified version of this file from Firaxis
-- Differences are noted in file below
-- ===========================================================================

-- Copyright 2016-2019, Firaxis Games

-- ===========================================================================
-- CityPanel v3
-- ===========================================================================

include( "AdjacencyBonusSupport" ); -- GetAdjacentYieldBonusString()
include( "CitySupport" );
include( "Civ6Common" );        -- GetYieldString()
include( "Colors" );
include( "InstanceManager" );
include( "SupportFunctions" );      -- Round(), Clamp()
include( "PortraitSupport" );
include( "ToolTipHelper" );
include( "GameCapabilities" );
include( "MapUtilities" );
include( "CQUICommon.lua" );
-- ===========================================================================
--  DEBUG
--  Toggle these for temporary debugging help.
-- ===========================================================================
local m_debugAllowMultiPanel  :boolean = false;   -- (false default) Let's multiple sub-panels show at one time.

-- ===========================================================================
--  GLOBALS
--  Accessible in overriden files.
-- ===========================================================================
g_pCity = nil;
g_growthPlotId = -1;
g_growthHexTextWidth = -1;

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
local ANIM_OFFSET_OPEN                      :number = -73;
local ANIM_OFFSET_OPEN_WITH_PRODUCTION_LIST :number = -250;
local SIZE_SMALL_RELIGION_ICON              :number = 22;
local SIZE_LEADER_ICON                      :number = 32;
local SIZE_PRODUCTION_ICON                  :number = 32; -- TODO: Switch this to 38 when the icons go in.
local SIZE_MAIN_ROW_LEFT_WIDE               :number = 270;
local SIZE_MAIN_ROW_LEFT_COLLAPSED          :number = 157;
local TXT_NO_PRODUCTION                     :string = Locale.Lookup("LOC_HUD_CITY_PRODUCTION_NOTHING_PRODUCED");
local MAX_BEFORE_TRUNC_TURN_LABELS          :number = 160;
local MAX_BEFORE_TRUNC_STATIC_LABELS        :number = 112;
local HEX_GROWTH_TEXT_PADDING               :number = 10;

local UV_CITIZEN_GROWTH_STATUS    :table  = {};
        UV_CITIZEN_GROWTH_STATUS[0] = {u=0, v=0};     -- revolt
        UV_CITIZEN_GROWTH_STATUS[1] = {u=0, v=0};     -- unrest
        UV_CITIZEN_GROWTH_STATUS[2] = {u=0, v=0};     -- unhappy
        UV_CITIZEN_GROWTH_STATUS[3] = {u=0, v=50};    -- displeased
        UV_CITIZEN_GROWTH_STATUS[4] = {u=0, v=100};   -- content (normal)
        UV_CITIZEN_GROWTH_STATUS[5] = {u=0, v=150};   -- happy
        UV_CITIZEN_GROWTH_STATUS[6] = {u=0, v=200};   -- ecstatic

local UV_HOUSING_GROWTH_STATUS    :table = {};
        UV_HOUSING_GROWTH_STATUS[0] = {u=0, v=0};   -- slowed
        UV_HOUSING_GROWTH_STATUS[1] = {u=0, v=100};   -- normal

local UV_CITIZEN_STARVING_STATUS    :table = {};
        UV_CITIZEN_STARVING_STATUS[0] = {u=0, v=0};   -- starving
        UV_CITIZEN_STARVING_STATUS[1] = {u=0, v=100};   -- normal

local PANEL_INFOLINE_LOCATIONS:table = {};
        PANEL_INFOLINE_LOCATIONS[0] = 20;
        PANEL_INFOLINE_LOCATIONS[1] = 45;
        PANEL_INFOLINE_LOCATIONS[2] = 71;
        PANEL_INFOLINE_LOCATIONS[3] = 94;

local PANEL_BUTTON_LOCATIONS:table = {};
        PANEL_BUTTON_LOCATIONS[0] = {x=85, y=18};
        PANEL_BUTTON_LOCATIONS[1] = {x=99, y=42};
        PANEL_BUTTON_LOCATIONS[2] = {x=95, y=69};
        PANEL_BUTTON_LOCATIONS[3] = {x=79, y=90};
local HOUSING_LABEL_OFFSET:number = 66;

m_PurchasePlot = UILens.CreateLensLayerHash("Purchase_Plot");
local m_CitizenManagement :number = UILens.CreateLensLayerHash("Citizen_Management");

-- ===========================================================================
--  MEMBERS
-- ===========================================================================
local m_kData           :table  = nil;
local m_isInitializing  :boolean= false;
local m_isShowingPanels :boolean= false;
local m_pPlayer         :table  = nil;
local m_primaryColor    :number = UI.GetColorValueFromHexLiteral(0xcafef00d);
local m_secondaryColor  :number = UI.GetColorValueFromHexLiteral(0xf00d1ace);
local m_kTutorialDisabledControls :table = nil;
local m_CurrentPanelLine:number = 0;

-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
local CQUI_bSukUI:boolean = Modding.IsModActive("805cc499-c534-4e0a-bdce-32fb3c53ba38"); -- Sukritact's Simple UI Adjustments

-- ====================CQUI Cityview==========================================
local CQUI_cityview = false;
local CQUI_usingStrikeButton = false;
local CQUI_wonderMode = false;
local CQUI_hiddenMode = false;
local CQUI_growthTile = true;

-- ===========================================================================
-- Manager for enabling the City View
-- Enters the city view and enables all the other components
-- These components include the city overview panel and the production panel
-- ===========================================================================
function CQUI_CityviewEnableManager()
    CQUI_cityview = true;
    CQUI_wonderMode = false;
    CQUI_hiddenMode = false;
    LuaEvents.CQUI_ProductionPanel_CityviewEnable();
    LuaEvents.CQUI_CityPanel_CityviewEnable();
    LuaEvents.CQUI_CityPanelOverview_CityviewEnable();
    LuaEvents.CQUI_WorldInput_CityviewEnable();
end

-- ===========================================================================
-- Manager for disabling the City View
-- Leaves the city view and disables all the other components
-- These components include the city overview panel and the production panel
-- ===========================================================================
function CQUI_CityviewDisableManager()
    CQUI_cityview = false;
    CQUI_wonderMode = false;
    CQUI_hiddenMode = false;
    LuaEvents.CQUI_ProductionPanel_CityviewDisable();
    LuaEvents.CQUI_CityPanel_CityviewDisable();
    LuaEvents.CQUI_CityPanelOverview_CityviewDisable();
    LuaEvents.CQUI_WorldInput_CityviewDisable();
end

-- ===========================================================================
-- Decide what to do based on the current city view status
-- Restore the standard city view if in district/building placement mode
-- Otherwise leave the city view entirely
-- ===========================================================================
function CQUI_CityviewDisableCurrentMode()
    -- If we are in the District/Building placement mode, return to the standard city view
    if (CQUI_wonderMode) then
        LuaEvents.CQUI_CityviewEnable();

    -- If not in District/Building placement mode, then exit out of the city view entirely
    -- If we are in the standard city view mode or it is hidden, exit out of the city view entirely
    elseif (CQUI_cityview or CQUI_hiddenMode) then
        LuaEvents.CQUI_CityviewDisable();
    end
end

-- ===========================================================================
-- Enable's this file's city view elements
-- ===========================================================================
function CQUI_OnCityviewEnabled()
    if ContextPtr:IsHidden() or Controls.CityPanelSlide:IsReversing() then
        ContextPtr:SetHide(false);
        Controls.CityPanelAlpha:SetToBeginning();
        Controls.CityPanelAlpha:Play();
        Controls.CityPanelSlide:SetToBeginning();
        Controls.CityPanelSlide:Play();
    end
    UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);
    Refresh();
    UILens.ToggleLayerOn(m_PurchasePlot);
    UILens.ToggleLayerOn(m_CitizenManagement);
    UI.SetFixedTiltMode(true);
    DisplayGrowthTile();
end

-- ===========================================================================
-- Disables this file's city view elements
-- ===========================================================================
function CQUI_OnCityviewDisabled()
    Close();
    UI.DeselectAllCities();
    UILens.ToggleLayerOff(m_PurchasePlot);
    UILens.ToggleLayerOff(m_CitizenManagement);
    UI.SetFixedTiltMode(false);
    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
end

-- ===========================================================================
-- Sets the mode to district/building placement mode
-- ===========================================================================
function CQUI_WonderModeEnabled()
    CQUI_cityview = false;
    CQUI_wonderMode = true;
    CQUI_hiddenMode = false;
    Close();
    UILens.ToggleLayerOff(m_PurchasePlot);
    UILens.ToggleLayerOff(m_CitizenManagement);
end

-- ===========================================================================
-- AZURENCY : CQUI_CityviewDisableManager() call an unwanted UI.SetInterfaceMode(InterfaceModeTypes.SELECTION), this does not
-- ===========================================================================
function CQUI_HideCityInterface()
    CQUI_cityview = false;
    CQUI_wonderMode = false;
    CQUI_hiddenMode = true;
    LuaEvents.CQUI_ProductionPanel_CityviewDisable();
    Close();
    UILens.ToggleLayerOff(m_PurchasePlot);
    UILens.ToggleLayerOff(m_CitizenManagement);
    UI.SetFixedTiltMode(false);
    LuaEvents.CQUI_CityPanelOverview_CityviewDisable();
    LuaEvents.CQUI_WorldInput_CityviewDisable();
    HideGrowthTile(); -- AZURENCY : added the clear ClearGrowthTile() because why might not deselect the city but still want it hidden
end

-- City view lua events
LuaEvents.CQUI_CityviewEnable.Add( CQUI_CityviewEnableManager);
LuaEvents.CQUI_CityviewDisable.Add( CQUI_CityviewDisableManager);
LuaEvents.CQUI_CityviewDisableCurrentMode.Add( CQUI_CityviewDisableCurrentMode);

-- CityPanel specific city view lua events
LuaEvents.CQUI_CityPanel_CityviewEnable.Add( CQUI_OnCityviewEnabled);
LuaEvents.CQUI_CityPanel_CityviewDisable.Add( CQUI_OnCityviewDisabled);
LuaEvents.CQUI_CityviewHide.Add(CQUI_HideCityInterface);

-- Strike button lua events
LuaEvents.CQUI_Strike_Enter.Add (function() CQUI_usingStrikeButton = true; end)
LuaEvents.CQUI_Strike_Exit.Add (function() CQUI_usingStrikeButton = false; end)

-- ===========================================================================
-- GAME Event
-- Called whenever the interface mode is changed
-- ===========================================================================
function CQUI_OnInterfaceModeChanged( eOldMode:number, eNewMode:number )
    if (eNewMode == InterfaceModeTypes.CITY_RANGE_ATTACK or eNewMode == InterfaceModeTypes.DISTRICT_RANGE_ATTACK or CQUI_usingStrikeButton) then
        LuaEvents.CQUI_CityviewHide(); -- AZURENCY : always hide the cityview if new mode is CITY_RANGE_ATTACK
    elseif (eOldMode == InterfaceModeTypes.CITY_MANAGEMENT or eOldMode == InterfaceModeTypes.DISTRICT_PLACEMENT or eOldMode == InterfaceModeTypes.BUILDING_PLACEMENT) then
        if (eNewMode == InterfaceModeTypes.DISTRICT_PLACEMENT or eNewMode == InterfaceModeTypes.BUILDING_PLACEMENT) then
            if (g_pCity == nil) then
                g_pCity = UI.GetHeadSelectedCity();
            end

            if (g_pCity ~= nil and UI.GetHeadSelectedCity()) then
                CQUI_WonderModeEnabled();

                -- If entering District/Building placement mode and the citizen management lens isn't on, refresh the purchase plots
                -- This ensures that the tile shadowing effect is present
                if (not UILens.IsLayerOn(m_CitizenManagement)) then
                    LuaEvents.CQUI_RefreshPurchasePlots();
                end

                -- Only display the growth tile if it can be built on by the selected District/Building
                CQUI_DisplayGrowthTileIfValid();

            else
                print("-- CQUI CityPanel.lua CQUI_OnInterfaceModeChanged: g_pCity is nil, or no city is selected");
                LuaEvents.CQUI_CityviewDisable();
            end
        elseif (eNewMode ~= InterfaceModeTypes.CITY_MANAGEMENT) then
            if (CQUI_wonderMode and UI.GetHeadSelectedCity()) then
                LuaEvents.CQUI_CityviewEnable();
            else
                LuaEvents.CQUI_CityviewDisable();
            end
        else
            LuaEvents.CQUI_CityviewEnable();
        end
    elseif (eOldMode == InterfaceModeTypes.CITY_RANGE_ATTACK) then
        if (eNewMode == InterfaceModeTypes.CITY_MANAGEMENT) then
            LuaEvents.CQUI_CityviewEnable(); -- AZURENCY : always show the cityview if new mode is CITY_MANAGEMENT
        else
            UI.DeselectAllCities()
        end
    end
end

-- ===========================================================================
-- Show the growth tile if the district or building can be placed there
-- ===========================================================================
function CQUI_DisplayGrowthTileIfValid()
    -- Get the selected city if needed
    if (g_pCity == nil) then
        g_pCity = UI.GetHeadSelectedCity();
    end

    -- Stop if there is no city selected
    if (g_pCity == nil) then
        return;
    end

    -- Make sure the growth tile is hidden
    HideGrowthTile();

    local newGrowthPlot:number = g_pCity:GetCulture():GetNextPlot();
    if (newGrowthPlot ~= -1) then
        local mode = UI.GetInterfaceMode();
        if (mode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
            local districtHash:number = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
            local district:table      = GameInfo.Districts[districtHash];
            local kPlot   :table      = Map.GetPlotByIndex(newGrowthPlot);
            if kPlot:CanHaveDistrict(district.Index, m_pPlayer, g_pCity:GetID()) then
                DisplayGrowthTile();
            end
        elseif (mode == InterfaceModeTypes.BUILDING_PLACEMENT) then
            local buildingHash :number = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_BUILDING_TYPE);
            local building = GameInfo.Buildings[buildingHash];
            local kPlot       :table          = Map.GetPlotByIndex(newGrowthPlot);
            if kPlot:CanHaveWonder(building.Index, m_pPlayer, g_pCity:GetID()) then
                DisplayGrowthTile();
            end
        end
    end
end

-- ===========================================================================
-- Clear city culture growth tile overlay if one exists
-- ===========================================================================
function CQUI_ClearGrowthTile()
    if g_growthPlotId ~= -1 then
        UILens.ClearHex(m_PurchasePlot, g_growthPlotId);
        g_growthPlotId = -1;
    end
end

-- ===========================================================================
-- GAME Event
-- Called whenever the city selection is changed
-- ===========================================================================
function CQUI_OnCitySelectionChanged( ownerPlayerID:number, cityID:number, i:number, j:number, k:number, isSelected:boolean, isEditable:boolean)
    if (ownerPlayerID == Game.GetLocalPlayer()) then
        if (isSelected) then
            -- Determine if should switch to cityview mode
            local shouldSwitchToCityview:boolean = true;
            if (UI.GetInterfaceMode() == InterfaceModeTypes.ICBM_STRIKE) then
                -- During ICBM_STRIKE only switch to cityview if we're selecting a city
                -- which doesn't own the active missile silo
                local siloPlotX:number = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_X0);
                local siloPlotY:number = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_Y0);
                local siloPlot:table = Map.GetPlot(siloPlotX, siloPlotY);
                if (siloPlot) then
                    local owningCity = Cities.GetPlotPurchaseCity(siloPlot);
                    if (owningCity:GetID() == cityID) then
                        shouldSwitchToCityview = false;
                    end
                end
            end
            if (CQUI_usingStrikeButton) then
                shouldSwitchToCityview = false;
                -- AZURENCY : Set the strike mode back to the default value
                CQUI_usingStrikeButton = false;
            end
            if (shouldSwitchToCityview) then
                LuaEvents.CQUI_CityviewEnable();
                Refresh();
            end
        else
            HideGrowthTile();

            -- If no city is selected and the city view is still up, close it
            -- This should only be the case when only calling something like UI.DeselectAllCities()
            -- Leaving the city view up in this case can cause some bad UI
            if (UI.GetHeadSelectedCity() == nil and (CQUI_cityview or CQUI_wonderMode or CQUI_hiddenMode)) then
                LuaEvents.CQUI_CityviewDisable();
            end
        end
    end
end

-- ===========================================================================
-- CQUI modified OnNextCity
-- Called when the next city button is clicked
-- ===========================================================================
function CQUI_OnNextCity()
    local kCity:table = UI.GetHeadSelectedCity();
    UI.SelectNextCity(kCity);
    UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small");
end

-- ===========================================================================
-- CQUI modified OnPreviousCity
-- Called when the previous city button is clicked
-- ===========================================================================
function CQUI_OnPreviousCity()
    local kCity:table = UI.GetHeadSelectedCity();
    UI.SelectPrevCity(kCity);
    UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small");
end

-- ===========================================================================
-- GAME Event
-- Called when the loading screen is closed
-- ===========================================================================
function CQUI_OnLoadScreenClose()
    CQUI_RecenterCameraGameStart();
end

-- ===========================================================================
--  Recenter camera at start of game
-- ===========================================================================
function CQUI_RecenterCameraGameStart()
    local startX, startY;
    local ePlayer :number = Game.GetLocalPlayer();
    local kPlayer         = Players[ePlayer];
    local cities = kPlayer:GetCities();

    -- If there is a city, center on the capital
    -- Else, center on a unit
    if cities:GetCount() > 0 then
            capital = cities:GetCapitalCity();
            startX = capital:GetX();
            startY = capital:GetY();
    else
            local units = kPlayer:GetUnits();
            local firstUnit = units:FindID(0);
            startX = firstUnit:GetX();
            startY = firstUnit:GetY();
    end
    UI.LookAtPlot( startX, startY );
end

-- ===========================================================================
-- Sets the visibility of the tile growth overlay
-- ===========================================================================
function CQUI_SetGrowthTile(state)
    GameConfiguration.SetValue("CQUI_ShowCultureGrowth", state);
    LuaEvents.CQUI_SettingsUpdate();
end

-- ===========================================================================
-- Toggles the visibility of the tile growth overlay
-- ===========================================================================
function CQUI_ToggleGrowthTile()
    CQUI_SetGrowthTile(not CQUI_growthTile);
end

-- ===========================================================================
function CQUI_SettingsUpdate()
    CQUI_growthTile = GameConfiguration.GetValue("CQUI_ShowCultureGrowth");
    if (g_growthPlotId ~= -1 and not CQUI_growthTile) then
        UILens.ClearHex(m_PurchasePlot, g_growthPlotId);
        g_growthPlotId = -1;
    end
    if (UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT) then
        DisplayGrowthTile();
    end
end
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
--
-- ===========================================================================
function Close()
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Controls.CityPanelAlpha:SetToBeginning();
    Controls.CityPanelAlpha:Play();
    Controls.CityPanelSlide:SetToBeginning();
    Controls.CityPanelSlide:Play();
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    ContextPtr:SetHide( true );
end

-- ===========================================================================
--  Helper, display the 3-way state of a yield based on the enum.
--  yieldData,  A YIELD_STATE
--  yieldName,  The name tied used in the check and ignore controls.
-- ===========================================================================
function RealizeYield3WayCheck( yieldData:number, yieldType, yieldToolTip )

    local yieldInfo = GameInfo.Yields[yieldType];
    if (yieldInfo) then

        local controlLookup = {
            YIELD_FOOD = "Food",
            YIELD_PRODUCTION = "Production",
            YIELD_GOLD = "Gold",
            YIELD_SCIENCE = "Science",
            YIELD_CULTURE = "Culture",
            YIELD_FAITH = "Faith",
        };

        local yieldName = controlLookup[yieldInfo.YieldType];
        if (yieldName) then

            local checkControl = Controls[yieldName.."Check"];
            local ignoreControl = Controls[yieldName.."Ignore"];
            local gridControl = Controls[yieldName.."Grid"];

            if (checkControl and ignoreControl and gridControl) then

                local toolTip = "";

                if yieldData == YIELD_STATE.FAVORED then
                    checkControl:SetCheck(true);  -- Just visual, no callback!
                    checkControl:SetDisabled(false);
                    ignoreControl:SetHide(true);

                    toolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_FOCUSING", yieldInfo.Name) .. "[NEWLINE][NEWLINE]";
                elseif yieldData == YIELD_STATE.IGNORED then
                    checkControl:SetCheck(false); -- Just visual, no callback!
                    checkControl:SetDisabled(true);
                    ignoreControl:SetHide(false);

                    toolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_IGNORING", yieldInfo.Name) .. "[NEWLINE][NEWLINE]";
                else
                    checkControl:SetCheck(false);
                    checkControl:SetDisabled(false);
                    ignoreControl:SetHide(true);

                    toolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_CITIZENS", yieldInfo.Name) .. "[NEWLINE][NEWLINE]";
                end

                if (#yieldToolTip > 0) then
                    toolTip = toolTip .. yieldToolTip;
                else
                    toolTip = toolTip .. Locale.Lookup("LOC_HUD_CITY_YIELD_NOTHING");
                end

                gridControl:SetToolTipString(toolTip);
            end
        end

    end
end

-- ===========================================================================
--  Set the health meter
-- ===========================================================================
function RealizeHealthMeter( control:table, percent:number )
    if  ( percent > 0.7 ) then
        control:SetColor( COLORS.METER_HP_GOOD );
    elseif ( percent > 0.4 )  then
        control:SetColor( COLORS.METER_HP_OK );
    else
        control:SetColor( COLORS.METER_HP_BAD );
    end

    -- Meter control is half circle, so add enough to start at half point and condense % into the half area
    percent = (percent * 0.5) + 0.5;
    control:SetPercent( percent );
end

-- ===========================================================================
--  Main city panel
-- ===========================================================================
function ViewMain( data:table )
    m_primaryColor, m_secondaryColor  = UI.GetPlayerColors( m_pPlayer:GetID() );

    if (m_primaryColor == nil or m_secondaryColor == nil or m_primaryColor == 0 or m_secondaryColor == 0) then
        UI.DataError("Couldn't find player colors for player - " .. (m_pPlayer and tostring(m_pPlayer:GetID()) or "nil"));
    end
    
    local darkerBackColor = UI.DarkenLightenColor(m_primaryColor,-85,100);
    local brighterBackColor = UI.DarkenLightenColor(m_primaryColor,90,255);
    m_CurrentPanelLine = 0;

    -- Name data
    Controls.CityName:SetText((data.IsCapital and "[ICON_Capital]" or "") .. Locale.ToUpper( Locale.Lookup(data.CityName)));
    Controls.CityName:SetToolTipString(data.IsCapital and Locale.Lookup("LOC_HUD_CITY_IS_CAPITAL") or nil );

    -- Banner and icon colors
    Controls.Banner:SetColor(m_primaryColor);
    Controls.BannerLighter:SetColor(brighterBackColor);
    Controls.BannerDarker:SetColor(darkerBackColor);
    Controls.CircleBacking:SetColor(m_primaryColor);
    Controls.CircleLighter:SetColor(brighterBackColor);
    Controls.CircleDarker:SetColor(darkerBackColor);
    Controls.CityName:SetColor(m_secondaryColor);
    Controls.CivIcon:SetColor(m_secondaryColor);

    -- Set Population --
    Controls.PopulationNumber:SetText(data.Population);

    -- Damage meters ---
    RealizeHealthMeter( Controls.CityHealthMeter, data.HitpointPercent );
    if (data.CityWallTotalHP > 0) then
        Controls.CityWallHealthMeters:SetHide(false);
        --RealizeHealthMeter( Controls.WallHealthMeter, data.CityWallHPPercent );
        local percent     = (data.CityWallHPPercent * 0.5) + 0.5;
        Controls.WallHealthMeter:SetPercent( percent );
    else
        Controls.CityWallHealthMeters:SetHide(true);
    end

    -- Update city health tooltip
    local tooltip:string = Locale.Lookup("LOC_HUD_UNIT_PANEL_HEALTH_TOOLTIP", data.HitpointsCurrent, data.HitpointsTotal);
    if (data.CityWallTotalHP > 0) then
        tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_HUD_UNIT_PANEL_WALL_HEALTH_TOOLTIP", data.CityWallCurrentHP, data.CityWallTotalHP);
    end
    Controls.CityHealthMeters:SetToolTipString(tooltip);

    local civType:string = PlayerConfigurations[data.Owner]:GetCivilizationTypeName();
    if civType ~= nil then
        Controls.CivIcon:SetIcon("ICON_" .. civType);
    else
        UI.DataError("Invalid type name returned by GetCivilizationTypeName");
    end

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- Divine Yuri's Tooltip calculations (Some changes made for CQUI)
    local selectedCity  = UI.GetHeadSelectedCity();
    -- Food yield correction
    local iModifiedFood;
    local totalFood :number;
    if data.TurnsUntilGrowth > -1 then
        local growthModifier =  math.max(1 + (data.HappinessGrowthModifier/100) + data.OtherGrowthModifiers, 0); -- This is unintuitive but it's in parity with the logic in City_Growth.cpp
        iModifiedFood = Round(data.FoodSurplus * growthModifier, 2);
        if data.Occupied then
            totalFood = iModifiedFood * data.OccupationMultiplier;
        else
            totalFood = iModifiedFood * data.HousingMultiplier;
        end
    else
        totalFood = data.FoodSurplus;
    end

    -- Food p/turn tooltip
    local realFoodPerTurnToolTip = data.FoodPerTurnToolTip .."[NEWLINE]"..
        toPlusMinusString(-(data.FoodPerTurn - data.FoodSurplus)).." "..Locale.Lookup("LOC_HUD_CITY_FROM_POPULATION").."[NEWLINE][NEWLINE]"..
        GetColorPercentString(1 + data.HappinessGrowthModifier/100, 2) .. " "..Locale.Lookup("LOC_HUD_CITY_HAPPINESS_GROWTH_BONUS").."[NEWLINE]"..
        GetColorPercentString(1 + data.OtherGrowthModifiers, 2) .. " "..Locale.Lookup("LOC_HUD_CITY_OTHER_GROWTH_BONUSES").."[NEWLINE]"..
        GetColorPercentString(data.HousingMultiplier, 2).." "..Locale.Lookup("LOC_HUD_CITY_HOUSING_MULTIPLIER");
    if data.Occupied then
        realFoodPerTurnToolTip = realFoodPerTurnToolTip.."[NEWLINE]".."x"..data.OccupationMultiplier..Locale.Lookup("LOC_HUD_CITY_OCCUPATION_MULTIPLIER");
    end

    -- Religion tooltip/icon
    local ReligionTooltip :string;
    if ((table.count(data.Religions) > 1) or (data.PantheonBelief > -1)) then
        ReligionTooltip = Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME") .. ":[NEWLINE]";

        if data.PantheonBelief > -1 then
            local kPantheonBelief = GameInfo.Beliefs[data.PantheonBelief];
            ReligionTooltip = ReligionTooltip..Locale.Lookup(kPantheonBelief.Name).."[NEWLINE]"..Locale.Lookup(kPantheonBelief.Description);
        end

        if (table.count(data.Religions) > 0) then
            local religiousMinorities = "";
            local religiousMinoritiesExist = false;
            for _,religion in ipairs(data.Religions) do
                local religionName :string = Game.GetReligion():GetName(religion.ID);
                local iconName     :string = "ICON_" .. religion.ReligionType;
                if religion == data.Religions[DATA_DOMINANT_RELIGION] then
                    Controls.ReligionIcon:SetIcon("ICON_" .. religion.ReligionType);
                    ReligionTooltip = ReligionTooltip.."[NEWLINE][NEWLINE]"..Locale.Lookup("LOC_UI_RELIGION_NUM_FOLLOWERS_TT", religionName, religion.Followers);
                else
                    if ( religion.ID > -1 and religion.Followers > 0) then
                        religiousMinoritiesExist = true;
                        religiousMinorities = religiousMinorities.. "[NEWLINE]"..Locale.Lookup("LOC_UI_RELIGION_NUM_FOLLOWERS_TT", religionName, religion.Followers);
                    end
                end
            end

            for _, beliefIndex in ipairs(data.BeliefsOfDominantReligion) do
                local kBelief     :table = GameInfo.Beliefs[beliefIndex];
                ReligionTooltip = ReligionTooltip.."[NEWLINE][NEWLINE]"..Locale.Lookup(kBelief.Name).."[NEWLINE]"..Locale.Lookup(kBelief.Description);
            end

            if religiousMinoritiesExist then
                ReligionTooltip = ReligionTooltip.."[NEWLINE]---------------------[NEWLINE]"..Locale.Lookup("LOC_HUD_CITY_RELIGIOUS_MINORITIES").."[NEWLINE]"..religiousMinorities;
            end
        end
    else
        ReligionTooltip = Locale.Lookup("LOC_RELIGIONPANEL_NO_RELIGION");
    end

    -- District tooltip
    local DistrictTooltip = "";
    for i, district in ipairs(data.BuildingsAndDistricts) do
        if district.isBuilt then
            local districtName = district.Name;
            if district.isPillaged then
                districtName = districtName .. " "..Locale.Lookup("LOC_HUD_CITY_PILLAGED").." "
            end

            if ( i == 1 ) then
                DistrictTooltip = DistrictTooltip..""..districtName;
            else
                DistrictTooltip = DistrictTooltip.."[NEWLINE]"..districtName;
            end

            --district.YieldBonus
            for _,building in ipairs(district.Buildings) do
                if building.isBuilt then
                    local buildingName = building.Name;
                    if building.isPillaged then
                        buildingName = buildingName .. " "..Locale.Lookup("LOC_HUD_CITY_PILLAGED").." "
                    end
                    DistrictTooltip = DistrictTooltip.."[NEWLINE]".."[ICON_BULLET]"..buildingName;
                end
            end
        end
    end

    -- Amenities tooltip
    local HappinessTooltipString = Locale.Lookup(GameInfo.Happinesses[data.Happiness].Name);
    HappinessTooltipString = HappinessTooltipString.."[NEWLINE]";
    local tableChanges = {};

    -- Inline function declaration
    function repeatAvoidAddNew( TextKey, dataID, isNegative, special)
        local textValue = Locale.Lookup(TextKey, "");
        if (isNegative) then
            if special then
                table.insert(tableChanges, {Amenities = -data[dataID], AmenityType = textValue.." "});
            elseif (data["AmenitiesLostFrom"..dataID] ~= 0) then
                table.insert(tableChanges, {Amenities = -data["AmenitiesLostFrom"..dataID], AmenityType = textValue});
            end
        else
            if ( data["AmenitiesFrom"..dataID] > 0) then
                table.insert(tableChanges, {Amenities = data["AmenitiesFrom"..dataID], AmenityType = textValue});
            end
        end
    end

    data.AmenitiesFromDistricts = data.AmenitiesFromDistricts or 0;
    data.AmenitiesFromNaturalWonders = data.AmenitiesFromNaturalWonders or 0;
    data.AmenitiesFromTraits = data.AmenitiesFromTraits or 0;
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_LUXURIES",           "Luxuries"                        );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_CIVICS",             "Civics"                          );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_ENTERTAINMENT",      "Entertainment"                   );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_GREAT_PEOPLE",       "GreatPeople"                     );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_CITY_STATES",        "CityStates"                      );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_RELIGION",           "Religion"                        );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_NATIONAL_PARKS",     "NationalParks"                   );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_STARTING_ERA",       "StartingEra"                     );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_IMPROVEMENTS",       "Improvements"                    );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_LOST_FROM_WAR_WEARINESS", "WarWeariness",         true      );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_LOST_FROM_BANKRUPTCY",    "Bankruptcy",           true      );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_DISTRICTS",          "Districts"                       );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_NATURAL_WONDERS",    "NaturalWonders"                  );
    repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_FROM_TRAITS",             "Traits"                          );
    if g_bIsRiseAndFall or g_bIsGatheringStorm then
        repeatAvoidAddNew("LOC_HUD_CITY_AMENITIES_LOST_FROM_GOVERNORS", "Governors");
    end

    repeatAvoidAddNew("LOC_HUD_REPORTS_FROM_POPULATION",                "AmenitiesRequiredNum", true, true);
    for _, aTable in pairs(tableChanges)do
        HappinessTooltipString = HappinessTooltipString..string.format("[NEWLINE]%+d %s", aTable.Amenities, aTable.AmenityType:sub(1, -2));
    end

    if data.HappinessGrowthModifier ~= 0 then
        local growthInfo:string =
            GetColorPercentString(Round(1 + (data.HappinessGrowthModifier/100), 2)) .. " " ..
            Locale.Lookup("LOC_HUD_CITY_CITIZEN_GROWTH") .. "[NEWLINE]" ..
            GetColorPercentString(Round(1 + (data.HappinessNonFoodYieldModifier/100), 2)) .. " "..
            Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_ALL_YIELDS") );
        HappinessTooltipString = HappinessTooltipString.."[NEWLINE][NEWLINE]"..growthInfo;
    end

    -- Housing tooltip
    local HousingTooltip = "";
    if data.HousingMultiplier == 0 then
        HousingTooltip = Locale.Lookup("LOC_HUD_CITY_POPULATION_GROWTH_HALTED");
    else
        if data.HousingMultiplier <= 0.5 then
            HousingTooltip = Locale.Lookup("LOC_HUD_CITY_POPULATION_GROWTH_SLOWED", (1 - data.HousingMultiplier) * 100);
        else
            HousingTooltip = Locale.Lookup("LOC_HUD_CITY_POPULATION_GROWTH_NORMAL");
        end
    end

    -- Production info
    local buildQueue  = selectedCity:GetBuildQueue();
    local currentProductionHash = buildQueue:GetCurrentProductionTypeHash();
    local productionHash = 0;

    if ( currentProductionHash == 0 ) then
        productionHash = buildQueue:GetPreviousProductionTypeHash();
    else
        productionHash = currentProductionHash;
    end

    local currentProductionInfo :table = GetProductionInfoOfCity( data.City, productionHash );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    -- Set icons and values for the yield checkboxes
    Controls.CultureCheck:GetTextButton():SetText(    "[ICON_Culture]"    ..toPlusMinusString(data.CulturePerTurn) );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- Food value is calculated above
    Controls.FoodCheck:GetTextButton():SetText(       "[ICON_Food]"       ..toPlusMinusString(totalFood) );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Controls.ProductionCheck:GetTextButton():SetText( "[ICON_Production]" ..toPlusMinusString(data.ProductionPerTurn) );
    Controls.ScienceCheck:GetTextButton():SetText(    "[ICON_Science]"    ..toPlusMinusString(data.SciencePerTurn) );
    Controls.FaithCheck:GetTextButton():SetText(      "[ICON_Faith]"      ..toPlusMinusString(data.FaithPerTurn) );
    Controls.GoldCheck:GetTextButton():SetText(       "[ICON_Gold]"       ..toPlusMinusString(data.GoldPerTurn) );

    -- Set the Yield checkboxes based on the game state
    RealizeYield3WayCheck( data.YieldFilters[YieldTypes.CULTURE], YieldTypes.CULTURE, data.CulturePerTurnToolTip);
    RealizeYield3WayCheck( data.YieldFilters[YieldTypes.FAITH], YieldTypes.FAITH, data.FaithPerTurnToolTip);
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- Food value is calcuated above
    RealizeYield3WayCheck( data.YieldFilters[YieldTypes.FOOD], YieldTypes.FOOD, realFoodPerTurnToolTip);
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    RealizeYield3WayCheck( data.YieldFilters[YieldTypes.GOLD], YieldTypes.GOLD, data.GoldPerTurnToolTip);
    RealizeYield3WayCheck( data.YieldFilters[YieldTypes.PRODUCTION], YieldTypes.PRODUCTION, data.ProductionPerTurnToolTip);
    RealizeYield3WayCheck( data.YieldFilters[YieldTypes.SCIENCE], YieldTypes.SCIENCE, data.SciencePerTurnToolTip);

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- #33 Infixo SukUI integration
    if CQUI_bSukUI then
        local toPlusMinus = function(value) return Locale.ToNumber(value, "+#,###.#;-#,###.#") end
        LuaEvents.SetSuk_YieldTooltip(Controls.CultureGrid,    data.YieldFilters[YieldTypes.CULTURE],    toPlusMinus(data.CulturePerTurn),    data.CulturePerTurnToolTip);
        LuaEvents.SetSuk_YieldTooltip(Controls.FaithGrid,      data.YieldFilters[YieldTypes.FAITH],      toPlusMinus(data.FaithPerTurn),      data.FaithPerTurnToolTip);
        LuaEvents.SetSuk_YieldTooltip(Controls.FoodGrid,       data.YieldFilters[YieldTypes.FOOD],       toPlusMinus(totalFood),              realFoodPerTurnToolTip); -- different here
        LuaEvents.SetSuk_YieldTooltip(Controls.GoldGrid,       data.YieldFilters[YieldTypes.GOLD],       toPlusMinus(data.GoldPerTurn),       data.GoldPerTurnToolTip);
        LuaEvents.SetSuk_YieldTooltip(Controls.ProductionGrid, data.YieldFilters[YieldTypes.PRODUCTION], toPlusMinus(data.ProductionPerTurn), data.ProductionPerTurnToolTip);
        LuaEvents.SetSuk_YieldTooltip(Controls.ScienceGrid,    data.YieldFilters[YieldTypes.SCIENCE],    toPlusMinus(data.SciencePerTurn),    data.SciencePerTurnToolTip);
    end
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    if m_isShowingPanels then
        Controls.LabelButtonRows:SetSizeX( SIZE_MAIN_ROW_LEFT_COLLAPSED );
    else
        Controls.LabelButtonRows:SetSizeX( SIZE_MAIN_ROW_LEFT_WIDE );
    end

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- also show the districts possible value
    Controls.BreakdownNum:SetText( data.DistrictsNum.."/"..data.DistrictsPossibleNum );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Controls.BreakdownGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
    Controls.BreakdownButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
    Controls.BreakdownButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);
    m_CurrentPanelLine = m_CurrentPanelLine + 1;

    -- Hide Religion / Faith UI in some scenarios
    if not GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_RELIGION_TAB") then
        Controls.ReligionGrid:SetHide(true);
        Controls.ReligionIcon:SetHide(true);
        Controls.ReligionButton:SetHide(true);
    else
        Controls.ReligionGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
        Controls.ReligionButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
        Controls.ReligionButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);
        m_CurrentPanelLine = m_CurrentPanelLine + 1;
    end

    if not GameCapabilities.HasCapability("CAPABILITY_FAITH") then
        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
        -- Controls.ProduceWithFaithCheck:SetHide(true);
        -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
        Controls.FaithGrid:SetHide(true);
    end

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Controls.BreakdownGrid:SetToolTipString(DistrictTooltip);
    Controls.AmenitiesGrid:SetToolTipString(HappinessTooltipString);
    Controls.ReligionGrid:SetToolTipString(ReligionTooltip);
    Controls.HousingGrid:SetToolTipString(HousingTooltip);
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    local amenitiesNumText = data.AmenitiesNetAmount;
    if (data.AmenitiesNetAmount > 0) then
        amenitiesNumText = "+" .. amenitiesNumText;
    end
    Controls.AmenitiesNum:SetText( amenitiesNumText );
    local colorName:string = GetHappinessColor( data.Happiness );
    Controls.AmenitiesNum:SetColorByName( colorName );
    Controls.AmenitiesGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
    Controls.AmenitiesButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
    Controls.AmenitiesButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);
    m_CurrentPanelLine = m_CurrentPanelLine + 1;

    Controls.ReligionNum:SetText( data.ReligionFollowers );

    Controls.HousingNum:SetText( data.Population );
    colorName = GetPercentGrowthColor( data.HousingMultiplier );
    Controls.HousingNum:SetColorByName( colorName );

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Controls.HousingMax:SetText( data.Housing - data.HousingFromImprovements + CQUI_GetRealHousingFromImprovements(selectedCity) );    -- CQUI calculate real housing
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Controls.HousingLabels:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x - HOUSING_LABEL_OFFSET);
    Controls.HousingGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
    Controls.HousingButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
    Controls.HousingButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);

    Controls.BreakdownLabel:SetHide( m_isShowingPanels );
    Controls.ReligionLabel:SetHide( m_isShowingPanels );
    Controls.AmenitiesLabel:SetHide( m_isShowingPanels );
    Controls.HousingLabel:SetHide( m_isShowingPanels );
    Controls.PanelStackShadow:SetHide( not m_isShowingPanels );
    Controls.ProductionNowLabel:SetHide( m_isShowingPanels );

    -- Determine size of progress bars at the bottom, as well as sub-panel offset.
    local OFF_BOTTOM_Y                   :number = 9;
    local OFF_ROOM_FOR_PROGRESS_Y        :number = 36;
    local OFF_GROWTH_BAR_PUSH_RIGHT_X    :number = 2;
    local OFF_GROWTH_BAR_DEFAULT_RIGHT_X :number = 32;
    local widthNumLabel                  :number = 0;

    -- Growth
    Controls.GrowthTurnsSmall:SetHide( not m_isShowingPanels );
    Controls.GrowthTurns:SetHide( m_isShowingPanels );
    Controls.GrowthTurnsBar:SetPercent( data.CurrentFoodPercent );
    Controls.GrowthTurnsBar:SetShadowPercent( data.FoodPercentNextTurn );
    Controls.GrowthTurnsBarSmall:SetPercent( data.CurrentFoodPercent );
    Controls.GrowthTurnsBarSmall:SetShadowPercent( data.FoodPercentNextTurn );
    Controls.GrowthNum:SetText( math.abs(data.TurnsUntilGrowth) );
    Controls.GrowthNumSmall:SetText( math.abs(data.TurnsUntilGrowth).."[Icon_Turn]" );

    if data.Occupied then
        Controls.GrowthLabel:SetColorByName("StatBadCS");
        Controls.GrowthLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_GROWTH_OCCUPIED") ) );
    else
        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
        -- CQUI show the current and required food values
        local pCityGrowth :table = data.City:GetGrowth();
        local CurFood = Round(pCityGrowth:GetFood(), 1);
        local FoodGainNextTurn = Round(data.FoodSurplus * pCityGrowth:GetOverallGrowthModifier(), 1);
        local RequiredFood = Round(data.GrowthThreshold, 1);
        if (data.TurnsUntilGrowth >= 0) then
            Controls.GrowthLabel:SetColorByName("StatGoodCS");
            Controls.GrowthLabel:SetText( "  "..CurFood.." / "..RequiredFood.."  (+"..FoodGainNextTurn.."[ICON_Food])");
        else
            Controls.GrowthLabel:SetColorByName("StatBadCS");
            Controls.GrowthLabel:SetText( "  "..CurFood.." / "..RequiredFood.."  ("..data.FoodSurplus.."[ICON_Food])");
        end
        -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    end

    widthNumLabel = Controls.GrowthNum:GetSizeX();
    TruncateStringWithTooltip(Controls.GrowthLabel, MAX_BEFORE_TRUNC_TURN_LABELS-widthNumLabel, Controls.GrowthLabel:GetText());

    --Production

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- update CQUI custom controls, do not hide the Controls.ProductionTurns
    --Controls.ProductionTurns:SetHide( m_isShowingPanels );
    Controls.CurrentProductionProgress:SetPercent(Clamp(data.CurrentProdPercent, 0.0, 1.0));
    Controls.CurrentProductionProgress:SetShadowPercent(Clamp(data.ProdPercentNextTurn, 0.0, 1.0));
    Controls.CurrentProductionCost:SetText( data.CurrentTurnsLeft );
    Controls.ProductionLabel:SetText(currentProductionInfo.Progress.."/"..currentProductionInfo.Cost.."  (+"..data.ProductionPerTurn.." [ICON_Production])");
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Controls.ProductionNowLabel:SetText( data.CurrentProductionName );

    Controls.ProductionDescriptionString:SetText( data.CurrentProductionDescription );
    --Controls.ProductionDescription:SetText( "There was a young lady from Venus, who's body was shaped like a, THAT'S ENOUGH DATA." );
    if ( data.CurrentProductionStats ~= "") then
        Controls.ProductionStatString:SetText( data.CurrentProductionStats );
    end
    Controls.ProductionDataStack:CalculateSize();
    Controls.ProductionDataScroll:CalculateSize();

    local isIconSet:boolean = false;
    if data.CurrentProductionIcons then
        for _,iconName in ipairs(data.CurrentProductionIcons) do
            if iconName ~= nil and Controls.ProductionIcon:TrySetIcon(iconName) then
                isIconSet = true;
                break;
            end
        end
    end
    Controls.ProductionIcon:SetHide( not isIconSet );

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Controls.CurrentProductionCost:SetHide( data.CurrentTurnsLeft < 0 );
    Controls.ProductionLabel:SetHide( data.CurrentTurnsLeft < 0 );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    if data.CurrentTurnsLeft < 0 then
        Controls.ProductionLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_NOTHING_PRODUCED")) );
        widthNumLabel = 0;
    end

    TruncateStringWithTooltip(Controls.ProductionLabel, MAX_BEFORE_TRUNC_TURN_LABELS-widthNumLabel, Controls.ProductionLabel:GetText());

    -- Tutorial lockdown
    if m_kTutorialDisabledControls ~= nil then
        for _,name in ipairs(m_kTutorialDisabledControls) do
            if Controls[name] ~= nil then
                Controls[name]:SetDisabled(true);
            end
        end
    end

end




-- ===========================================================================
--  Return ColorSet name
-- ===========================================================================
function GetHappinessColor( eHappiness:number )
    local happinessInfo = GameInfo.Happinesses[eHappiness];
    if (happinessInfo ~= nil) then
        if (happinessInfo.GrowthModifier < 0) then return "StatBadCS"; end
        if (happinessInfo.GrowthModifier > 0) then return "StatGoodCS"; end
    end
    return "StatNormalCS";
end

-- ===========================================================================
--  Return ColorSet name
-- ===========================================================================
function GetTurnsUntilGrowthColor( turns:number )
    if  turns < 1 then return "StatBadCS"; end
    return "StatGoodCS";
end

function GetPercentGrowthColor( percent:number )
    if percent == 0 then return "Error"; end
    if percent <= 0.25 then return "WarningMajor"; end
    if percent <= 0.5 then return "WarningMinor"; end
    return "StatNormalCS";
end


-- ===========================================================================
--  Changes the yield focus.
-- ===========================================================================
function SetYieldFocus( yieldType:number )
    if g_pCity == nil then
        g_pCity = UI.GetHeadSelectedCity();
    end

    local pCitizens   :table = g_pCity:GetCitizens();
    local tParameters :table = {};
    tParameters[CityCommandTypes.PARAM_FLAGS]   = 0;  -- Set Favored
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE]= yieldType;  -- Yield type
    if pCitizens:IsFavoredYield(yieldType) then
        tParameters[CityCommandTypes.PARAM_DATA0]= 0;  -- boolean (1=true, 0=false)
    else
        if pCitizens:IsDisfavoredYield(yieldType) then
            SetYieldIgnore(yieldType);
        end

        tParameters[CityCommandTypes.PARAM_DATA0] = 1; -- boolean (1=true, 0=false)
    end

    CityManager.RequestCommand(g_pCity, CityCommandTypes.SET_FOCUS, tParameters);
end

-- ===========================================================================
--  Changes what yield type(s) should be ignored by citizens
-- ===========================================================================
function SetYieldIgnore( yieldType:number )
    if g_pCity == nil then
        g_pCity = UI.GetHeadSelectedCity();
    end

    local pCitizens   :table = g_pCity:GetCitizens();
    local tParameters :table = {};
    tParameters[CityCommandTypes.PARAM_FLAGS]   = 1;      -- Set Ignored
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE]= yieldType;  -- Yield type
    if pCitizens:IsDisfavoredYield(yieldType) then
        tParameters[CityCommandTypes.PARAM_DATA0]= 0;      -- boolean (1=true, 0=false)
    else
        if ( pCitizens:IsFavoredYield(yieldType) ) then
            SetYieldFocus(yieldType);
        end

        tParameters[CityCommandTypes.PARAM_DATA0] = 1;     -- boolean (1=true, 0=false)
    end

    CityManager.RequestCommand(g_pCity, CityCommandTypes.SET_FOCUS, tParameters);
end


-- ===========================================================================
--  Update both the data & view for the selected city.
-- ===========================================================================
function Refresh()
    local eLocalPlayer :number = Game.GetLocalPlayer();
    m_pPlayer = Players[eLocalPlayer];
    g_pCity   = UI.GetHeadSelectedCity();

    if m_pPlayer ~= nil and g_pCity ~= nil then
        m_kData = GetCityData( g_pCity );
        if m_kData == nil then
            return;
        end

        ViewMain( m_kData );

        -- Tell others (e.g., CityPanelOverview) that the selected city data has changed.
        -- Passing this large table across contexts via LuaEvent is *much*
        -- more effecient than recomputing the entire set of yields a second time,
        -- despite the large size.
        LuaEvents.CityPanel_LiveCityDataChanged( m_kData, true );
        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
        LuaEvents.UpdateBanner(Game.GetLocalPlayer(), g_pCity:GetID());
        -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    end
end

-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- Custom function for CQUI to refresh the UI if needed
function RefreshOnTurnRoll()
    --print("Turn Roll City Panel Update");
    local pPlayer = Game.GetLocalPlayer();

    g_pCity  = UI.GetHeadSelectedCity();

    if g_pCity ~= nil then
        local pCitizens   :table = g_pCity:GetCitizens();
        local tParameters :table = {};

        if pCitizens:IsFavoredYield(YieldTypes.CULTURE) then
            tParameters[CityCommandTypes.PARAM_FLAGS] = 0; -- Set favoured
            tParameters[CityCommandTypes.PARAM_DATA0] = 1; -- on
        elseif pCitizens:IsDisfavoredYield(YieldTypes.CULTURE) then
            tParameters[CityCommandTypes.PARAM_FLAGS] = 1; -- Set Ignored
            tParameters[CityCommandTypes.PARAM_DATA0] = 1; -- on
        else
            tParameters[CityCommandTypes.PARAM_FLAGS] = 0; -- Set favoured
            tParameters[CityCommandTypes.PARAM_DATA0] = 0; -- off
        end

        tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = YieldTypes.CULTURE; -- Yield type
        CityManager.RequestCommand(g_pCity, CityCommandTypes.SET_FOCUS, tParameters);

        m_kData = GetCityData( g_pCity );
        if m_kData == nil then
            return;
        end

        --print("=============================================================");
        --print("Updating City Panel Details Due To Turn Roll");
        --print("=============================================================");

        ViewMain( m_kData );

        -- Tell others (e.g., CityPanelOverview) that the selected city data has changed.
        -- Passing this large table across contexts via LuaEvent is *much*
        -- more effecient than recomputing the entire set of yields a second time,
        -- despite the large size.
        LuaEvents.CityPanel_LiveCityDataChanged( m_kData, true );
        LuaEvents.UpdateBanner(Game.GetLocalPlayer(), g_pCity:GetID());
    end
end
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
function RefreshIfMatch( ownerPlayerID:number, cityID:number )
    if g_pCity ~= nil and ownerPlayerID == g_pCity:GetOwner() and cityID == g_pCity:GetID() then
        Refresh();
    end
end

-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- Handle updating values when a tile is improved
function OnTileImproved(x, y)
    -- print("A Tile Was Improved!");
    local plot:table = Map.GetPlot(x,y);
    local PlayerID = Game.GetLocalPlayer();

    g_pCity = Cities.GetPlotPurchaseCity(plot);

    if (g_pCity ~= nil) then
        -- print("Location: " .. x .."," .. y);
        -- print("Player: " .. PlayerID);
        -- print("City Owner: " .. g_pCity:GetOwner());

        if (PlayerID == g_pCity:GetOwner()) then
            -- print("City: " .. g_pCity:GetID());

            local pCitizens   :table = g_pCity:GetCitizens();
            local tParameters :table = {};

            if pCitizens:IsFavoredYield(YieldTypes.CULTURE) then
                tParameters[CityCommandTypes.PARAM_FLAGS] = 0;  -- Set favoured
                tParameters[CityCommandTypes.PARAM_DATA0] = 1;  -- on
            elseif pCitizens:IsDisfavoredYield(YieldTypes.CULTURE) then
                tParameters[CityCommandTypes.PARAM_FLAGS] = 1;  -- Set Ignored
                tParameters[CityCommandTypes.PARAM_DATA0] = 1;  -- on
            else
                tParameters[CityCommandTypes.PARAM_FLAGS] = 0;  -- Set favoured
                tParameters[CityCommandTypes.PARAM_DATA0] = 0;  -- off
            end

            tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = YieldTypes.CULTURE;  -- Yield type
            CityManager.RequestCommand(g_pCity, CityCommandTypes.SET_FOCUS, tParameters);

            m_kData = GetCityData( g_pCity );

            if m_kData == nil then
                return;
            end

            -- print("=============================================================");
            -- print("Updating City Panel Details Due To Yield Change");
            -- print("=============================================================");

            -- ViewMain( m_kData );

            -- Tell others (e.g., CityPanelOverview) that the selected city data has changed.
            -- Passing this large table across contexts via LuaEvent is *much*
            -- more effecient than recomputing the entire set of yields a second time,
            -- despite the large size.
            LuaEvents.CityPanel_LiveCityDataChanged( m_kData, true );
            --LuaEvents.UpdateBanner(Game.GetLocalPlayer(), g_pCity:GetID());

        end
    end
end
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
--  GAME Event
-- ===========================================================================
function OnPlayerResourceChanged( ownerPlayerID:number, resourceTypeID:number)
    if (Game.GetLocalPlayer() ~= nil and ownerPlayerID == Game.GetLocalPlayer()) then
        Refresh();
    end
end

function OnCityAddedToMap( ownerPlayerID:number, cityID:number )
    if Game.GetLocalPlayer() ~= nil then
        if ownerPlayerID == Game.GetLocalPlayer() then
            local pSelectedCity:table = UI.GetHeadSelectedCity();
            if pSelectedCity ~= nil then
                Refresh();
            else
                UI.DeselectAllCities();
            end
        end
    end
end

function OnCityNameChanged( playerID:number, cityID:number )
    local city = UI.GetHeadSelectedCity();
    if (city and city:GetOwner() == playerID and city:GetID() == cityID) then
        local name = city:IsCapital() and "[ICON_Capital]" or "";
        name = name .. Locale.ToUpper(Locale.Lookup(city:GetName()));
        Controls.CityName:SetText(name);
    end
end

-- ===========================================================================
--  GAME Event
--  Yield changes
-- ===========================================================================
function OnCityFocusChange(ownerPlayerID:number, cityID:number)
    RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--  GAME Event
-- ===========================================================================
function OnCityWorkerChanged(ownerPlayerID:number, cityID:number)
    RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--  GAME Event
-- ===========================================================================
function OnCityProductionChanged(ownerPlayerID:number, cityID:number)
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    if Controls.ChangeProductionCheck:IsChecked() then
        Controls.ChangeProductionCheck:SetCheck(false);
    end
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--  GAME Event
-- ===========================================================================
function OnCityProductionCompleted(ownerPlayerID:number, cityID:number)
    RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--  GAME Event
-- ===========================================================================
function OnCityProductionUpdated( ownerPlayerID:number, cityID:number, eProductionType, eProductionObject)
    RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--  GAME Event
-- ===========================================================================
function OnToggleOverviewPanel()
    if Controls.ToggleOverviewPanel:IsChecked() then
        LuaEvents.CityPanel_ShowOverviewPanel(true);
    else
        LuaEvents.CityPanel_ShowOverviewPanel(false);
    end
end

-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- CQUI Replaces this function with CQUI_OnCitySelectionChanged (function header shown here at location it appears in unmodified citypanel.lua)
-- function OnCitySelectionChanged( ownerPlayerID:number, cityID:number, i:number, j:number, k:number, isSelected:boolean, isEditable:boolean)
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
function AnimateFromCloseToOpen()
    Controls.CityPanelAlpha:SetToBeginning();
    Controls.CityPanelAlpha:Play();
    Controls.CityPanelSlide:SetBeginVal(0,0);
    Controls.CityPanelSlide:SetEndVal(ANIM_OFFSET_OPEN,0);
    Controls.CityPanelSlide:SetToBeginning();
    Controls.CityPanelSlide:Play();
end

-- ===========================================================================
function AnimateToWithProductionQueue()                 
    if IsRoomToPushOutPanel() then
        Controls.CityPanelSlide:SetEndVal(ANIM_OFFSET_OPEN_WITH_PRODUCTION_LIST,0);
        Controls.CityPanelSlide:RegisterEndCallback( function() Controls.CityPanelSlide:SetBeginVal(ANIM_OFFSET_OPEN_WITH_PRODUCTION_LIST,0); end );                
        Controls.CityPanelSlide:SetToBeginning();
        Controls.CityPanelSlide:Play();
    end
end

-- ===========================================================================
function AnimateToOpenFromWithProductionQueue() 
    if IsRoomToPushOutPanel() then
        Controls.CityPanelSlide:SetEndVal(ANIM_OFFSET_OPEN,0);
        Controls.CityPanelSlide:RegisterEndCallback( function() Controls.CityPanelSlide:SetBeginVal(ANIM_OFFSET_OPEN,0); end );
        Controls.CityPanelSlide:SetToBeginning();     
        Controls.CityPanelSlide:Play();
    end
end

-- ===========================================================================
--  Is there enough room to push out the CityPanel, rather than just have
--  the production list overlap it?
-- ===========================================================================
function IsRoomToPushOutPanel()
    local width, height   = UIManager:GetScreenSizeVal();
    -- Minimap showing; subtract how much space it takes up
    local uiMinimap:table = ContextPtr:LookUpControl("/InGame/MinimapPanel/MinimapContainer");
    if uiMinimap then
        local minimapWidth, minimapHeight = uiMinimap:GetSizeVal();
        width = width - minimapWidth;     
    end

    return ( width > 850);    -- Does remaining width have enough space for both?
end

-- ===========================================================================
--  GAME Event
-- ===========================================================================
function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, isSelected:boolean, isEditable:boolean )
    if playerID == Game.GetLocalPlayer() then
        if ContextPtr:IsHidden()==false then
            Close();
            Controls.ToggleOverviewPanel:SetAndCall(false);
        end
    end
end

-- ===========================================================================
function LateInitialize()
    -- Override in DLC, Expansion, and MODs for special initialization.
end

-- ===========================================================================
--  UI Event
-- ===========================================================================
function OnInit( isHotload:boolean )
    LateInitialize();
    if isHotload then
        LuaEvents.GameDebug_GetValues( "CityPanel");
    end

    m_isInitializing = false;
    Refresh();
end

-- ===========================================================================
--  UI EVENT
-- ===========================================================================
function OnShutdown()
    -- Cache values for hotloading...
    LuaEvents.GameDebug_AddValue("CityPanel", "isHidden", ContextPtr:IsHidden() );

        -- Game Core Events
    Events.CityAddedToMap.Remove(          OnCityAddedToMap );
    Events.CityNameChanged.Remove(         OnCityNameChanged );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Events.CitySelectionChanged.Remove(    CQUI_OnCitySelectionChanged );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Events.CityFocusChanged.Remove(        OnCityFocusChange );
    Events.CityProductionCompleted.Remove( OnCityProductionCompleted );
    Events.CityProductionUpdated.Remove(   OnCityProductionUpdated );
    Events.CityProductionChanged.Remove(   OnCityProductionChanged );
    Events.CityWorkerChanged.Remove(       OnCityWorkerChanged );
    Events.DistrictDamageChanged.Remove(   OnCityProductionChanged );
    Events.LocalPlayerTurnBegin.Remove(    OnLocalPlayerTurnBegin );
    Events.ImprovementChanged.Remove(      OnCityProductionChanged );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Events.InterfaceModeChanged.Remove(    CQUI_OnInterfaceModeChanged );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Events.LocalPlayerChanged.Remove(      OnLocalPlayerChanged );
    Events.PlayerResourceChanged.Remove(   OnPlayerResourceChanged );
    Events.UnitSelectionChanged.Remove(    OnUnitSelectionChanged );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Events.LoadScreenClose.Remove(         CQUI_OnLoadScreenClose );
    Events.PlotYieldChanged.Remove(        OnTileImproved );
    Events.PlayerTurnActivated.Remove(     RefreshOnTurnRoll );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    -- LUA Events
    LuaEvents.CityPanelOverview_CloseButton.Remove(     OnCloseOverviewPanel );
    LuaEvents.CityPanel_SetOverViewState.Remove(    OnCityPanelSetOverViewState );
    LuaEvents.CityPanel_ToggleManageCitizens.Remove(OnCityPanelToggleManageCitizens );
    LuaEvents.GameDebug_Return.Remove(                  OnGameDebugReturn );
    LuaEvents.ProductionPanel_Close.Remove(             OnProductionPanelClose );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- CQUI does not register this event
    -- LuaEvents.ProductionPanel_ListModeChanged.Remove( OnProductionPanelListModeChanged );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    LuaEvents.ProductionPanel_Open.Remove(              OnProductionPanelOpen );
    LuaEvents.Tutorial_CityPanelOpen.Remove(            OnTutorialOpen );
    LuaEvents.Tutorial_ContextDisableItems.Remove(      OnTutorial_ContextDisableItems );

end

-- ===========================================================================
--  LUA Event
--  Set cached values back after a hotload.
-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
    function RunWithNoError()
        if context ~= "CityPanel" or contextTable == nil then
            return;
        end

        local isHidden:boolean = contextTable["isHidden"];
        ContextPtr:SetHide( isHidden );
    end

    pcall( RunWithNoError );
end

-- ===========================================================================
--  LUA Event
-- ===========================================================================
function OnProductionPanelClose()
    -- If no longer checked, make sure the side Production Panel closes.
    -- Clear the checks, even if hidden, the Production Pane can close after the City Panel has already been closed.
    Controls.ChangeProductionCheck:SetCheck( false );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- Controls.ProduceWithFaithCheck:SetCheck( false );
    -- Controls.ProduceWithGoldCheck:SetCheck( false );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    AnimateToOpenFromWithProductionQueue();
end

-- ===========================================================================
--  LUA Event
-- ===========================================================================
function OnProductionPanelOpen()
    AnimateToWithProductionQueue();
end

-- ===========================================================================
--  LUA Event
-- ===========================================================================
function OnTutorialOpen()
    ContextPtr:SetHide(false);
    Refresh();
end

-- ===========================================================================
function OnBreakdown()
    LuaEvents.CityPanel_ShowBreakdownTab();
end

-- ===========================================================================
function OnReligion()
    LuaEvents.CityPanel_ShowReligionTab();
end

-- ===========================================================================
function OnAmenities()
    LuaEvents.CityPanel_ShowAmenitiesTab();
end

-- ===========================================================================
function OnHousing()
    LuaEvents.CityPanel_ShowHousingTab();
end

-- ===========================================================================
--function OnCheckQueue()
--  if m_isInitializing then return; end
--  if not m_debugAllowMultiPanel then
--    UILens.ToggleLayerOff("Adjacency_Bonus_Districts");
--    UILens.ToggleLayerOff("Districts");
--  end
--  Refresh();
--end

-- ===========================================================================
function OnCitizensGrowth()
    LuaEvents.CityPanel_ShowCitizensTab();
end

-- ===========================================================================
--  Set a yield to one of 3 check states.
--  yieldType Enum from game engine on the yield
--  yieldName Name of the yield used in the UI controls
-- ===========================================================================
function OnCheckYield( yieldType:number, yieldName:string )
    if Controls.YieldsArea:IsDisabled() then return; end  -- Via tutorial event
    if Controls[yieldName.."Check"]:IsChecked() then
        SetYieldFocus( yieldType );
    else
        SetYieldIgnore( yieldType );
        Controls[yieldName.."Ignore"]:SetHide( false );
        Controls[yieldName.."Check"]:SetDisabled( true );
    end
end

-- ===========================================================================
--  Reset a yield to not be favored nor ignored
--  yieldType Enum from game engine on the yield
--  yieldName Name of the yield used in the UI controls
-- ===========================================================================
function OnResetYieldToNormal( yieldType:number, yieldName:string )
    if Controls.YieldsArea:IsDisabled() then return; end  -- Via tutorial event
    Controls[yieldName.."Ignore"]:SetHide( true );
    Controls[yieldName.."Check"]:SetDisabled( false );
    SetYieldIgnore( yieldType );    -- One more ignore to flip it off
end

-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- CQUI implements custom versions of these functions from the unmodified file that appear here
-- function OnNextCity()
-- function OnPreviousCity()
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
--  Recenter camera on city
-- ===========================================================================
function RecenterCameraOnCity()
    local kCity:table = UI.GetHeadSelectedCity();
    UI.LookAtPlot( kCity:GetX(), kCity:GetY() );
end

-- ===========================================================================
--  Turn on/off layers and switch the interface mode based on what is checked.
--  Interface mode is changed first as the Lens system may inquire as to the
--  current state in deciding what is populate in a lens layer.
-- ===========================================================================
function OnTogglePurchaseTile()
    if Controls.PurchaseTileCheck:IsChecked() then
        if not Controls.ManageCitizensCheck:IsChecked() then
            -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
            -- CQUI does not save off the interface mode and restore later
            -- m_PrevInterfaceMode = UI.GetInterfaceMode();
            -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
            UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);  -- Enter mode
        end
        RecenterCameraOnCity();
        UILens.ToggleLayerOn( m_PurchasePlot );
    else
        if not Controls.ManageCitizensCheck:IsChecked() and UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then
            -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
            -- CQUI does not save off the interface mode and restore later
            -- UI.SetInterfaceMode(m_PrevInterfaceMode);         -- Exit mode
            -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

            UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);      -- Exit mode
        end

        UILens.ToggleLayerOff( m_PurchasePlot );
    end
end

-- ===========================================================================
function OnToggleProduction()
    if Controls.ChangeProductionCheck:IsChecked() then
        RecenterCameraOnCity();
        LuaEvents.CityPanel_ProductionOpen();
    else
        LuaEvents.CityPanel_ProductionClose();
    end
end

-- ===========================================================================
function OnTogglePurchaseWithGold()
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- CQUI allows purchasing with gold at all times, so no code is required here
    -- if Controls.ProduceWithGoldCheck:IsChecked() then
    --     RecenterCameraOnCity();
    --     LuaEvents.CityPanel_PurchaseGoldOpen();
    --     Controls.ChangeProductionCheck:SetCheck( false );
    --     Controls.ProduceWithFaithCheck:SetCheck( false );
    --     --AnimateToWithProductionQueue();
    -- else
    --     LuaEvents.CityPanel_ProductionClose();
    -- end
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
end

-- ===========================================================================
function OnTogglePurchaseWithFaith()
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- CQUI allows purchasing with faith at all times, so no code is required here
    -- if Controls.ProduceWithFaithCheck:IsChecked() then
    --     RecenterCameraOnCity();
    --     LuaEvents.CityPanel_PurchaseFaithOpen();
    --     Controls.ChangeProductionCheck:SetCheck( false );
    --     Controls.ProduceWithGoldCheck:SetCheck( false );
    --     --AnimateToWithProductionQueue();
    -- else
    --     LuaEvents.CityPanel_ProductionClose();
    -- end
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
end

function OnCloseOverviewPanel()
    Controls.ToggleOverviewPanel:SetCheck(false);
end
-- ===========================================================================
--  Turn on/off layers and switch the interface mode based on what is checked.
--  Interface mode is changed first as the Lens system may inquire as to the
--  current state in deciding what is populate in a lens layer.
-- ===========================================================================
function OnToggleManageCitizens()
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- CQUI shows the Manage Citizens at all times, so no code is required here
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
end

-- ===========================================================================
function OnLocalPlayerTurnBegin()
    Refresh();

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- SelectedUnit.lua sets the lens to default in OnLocalPlayerTurnBegin
    -- This clears the district/building placement view without exiting it
    -- So, exit out of the district/building placement mode to prevent weird UI
    if (CQUI_wonderMode) then
        LuaEvents.CQUI_CityviewDisableCurrentMode();
    end
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
end

-- ===========================================================================
--  Enable a control unless it's in the tutorial lock down list.
-- ===========================================================================
function EnableIfNotTutorialBlocked( controlName:string )
    local isDisabled :boolean = false;
    if m_kTutorialDisabledControls ~= nil then
        for _,name in ipairs(m_kTutorialDisabledControls) do
            if name == controlName then
                isDisabled = true;
                break;
            end
        end
    end
    Controls[ controlName ]:SetDisabled( isDisabled );
end

function OnCameraUpdate( vFocusX:number, vFocusY:number, fZoomLevel:number )
    if g_growthPlotId ~= -1 then

        if fZoomLevel and fZoomLevel > 0.5 then
            local delta:number = (fZoomLevel - 0.3);
            local alpha:number = delta / 0.7;
            Controls.GrowthHexAlpha:SetProgress(alpha);
        else
            Controls.GrowthHexAlpha:SetProgress(0);
        end

        local plotX:number, plotY:number = Map.GetPlotLocation(g_growthPlotId);
        local worldX:number, worldY:number, worldZ:number = UI.GridToWorld(plotX, plotY);
        Controls.GrowthHexAnchor:SetWorldPositionVal(worldX, worldY + HEX_GROWTH_TEXT_PADDING, worldZ);
    end
end

function DisplayGrowthTile()
    if g_pCity ~= nil and HasCapability("CAPABILITY_CULTURE") then
        local cityCulture:table = g_pCity:GetCulture();
        if cityCulture ~= nil then
            local newGrowthPlot:number = cityCulture:GetNextPlot();
            -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
            -- CQUI also checks if this is the CQUI_growthTile
            if (newGrowthPlot ~= -1 and newGrowthPlot ~= g_growthPlotId and CQUI_growthTile) then
                -- ==== CQUI CUSTOMIZATION END ==================================================================================== --
                g_growthPlotId = newGrowthPlot;

                local cost:number = cityCulture:GetNextPlotCultureCost();
                local currentCulture:number = cityCulture:GetCurrentCulture();
                local currentYield:number = cityCulture:GetCultureYield();
                local currentGrowth:number = math.max(math.min(currentCulture / cost, 1.0), 0);
                local nextTurnGrowth:number = math.max(math.min((currentCulture + currentYield) / cost, 1.0), 0);

                UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), g_growthPlotId, 1, "GrowthHexBG");
                UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), g_growthPlotId, nextTurnGrowth, "GrowthHexNext");
                UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), g_growthPlotId, currentGrowth, "GrowthHexCurrent");

                local turnsRemaining:number = cityCulture:GetTurnsUntilExpansion();
                Controls.TurnsLeftDescription:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_BORDER_GROWTH", turnsRemaining)));
                Controls.TurnsLeftLabel:SetText(turnsRemaining);
                Controls.GrowthHexStack:CalculateSize();
                g_growthHexTextWidth = Controls.GrowthHexStack:GetSizeX();

                Events.Camera_Updated.Add(OnCameraUpdate);
                Events.CityMadePurchase.Add(OnCityMadePurchase);
                Controls.GrowthHexAnchor:SetHide(false);
                OnCameraUpdate();
            end
        end
    end
end

function HideGrowthTile()
    if g_growthPlotId ~= -1 then
        Controls.GrowthHexAnchor:SetHide(true);
        Events.Camera_Updated.Remove(OnCameraUpdate);
        Events.CityMadePurchase.Remove(OnCityMadePurchase);
        UILens.ClearHex(m_PurchasePlot, g_growthPlotId);
        g_growthPlotId = -1;
    end
end

function OnCityMadePurchase(owner:number, cityID:number, plotX:number, plotY:number, purchaseType, objectType)
    if g_growthPlotId ~= -1 then
        local growthPlotX:number, growthPlotY:number = Map.GetPlotLocation(g_growthPlotId);

        if (growthPlotX == plotX and growthPlotY == plotY) then
            HideGrowthTile();
            DisplayGrowthTile();
        end
    end
end


-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- CQUI does not implement this function (unmodified defines this function here)
-- function OnProductionPanelListModeChanged( listMode:number )
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
function OnCityPanelSetOverViewState( isOpened:boolean )
    Controls.ToggleOverviewPanel:SetCheck(isOpened);
end

-- ===========================================================================
function OnCityPanelToggleManageCitizens()
    Controls.ManageCitizensCheck:SetAndCall(not Controls.ManageCitizensCheck:IsChecked());
end

-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- CQUI implements a custom version of this function (unmodified defines this function here)
-- function OnInterfaceModeChanged( eOldMode:number, eNewMode:number )
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
--  Engine EVENT
--  Local player changed; likely a hotseat game
-- ===========================================================================
function OnLocalPlayerChanged( eLocalPlayer:number , ePrevLocalPlayer:number )
    if eLocalPlayer == -1 then
        m_pPlayer = nil;
        return;
    end

    m_pPlayer = Players[eLocalPlayer];
    if ContextPtr:IsHidden()==false then
        Close();
    end
end

-- ===========================================================================
--  Show/hide an area based on the status of a checkbox control
--  checkBoxControl   A checkbox control that when selected is open
--  buttonControl   (optional) button control that toggles the state
--  areaControl     The area to be shown/hidden
--  kParentControls   DEPRECATED, not needed
-- ===========================================================================
function SetupCollapsibleToggle( pCheckBoxControl:table, pButtonControl:table, pAreaControl:table, kParentControls:table )
    pCheckBoxControl:RegisterCheckHandler(
        function()
            pAreaControl:SetHide( pCheckBoxControl:IsChecked() );
        end
    );

    if pButtonControl ~= nil then
        pButtonControl:RegisterCallback( Mouse.eLClick,
            function()
                pCheckBoxControl:SetAndCall( not pCheckBoxControl:IsChecked() );
            end
    );
    end
end

-- ===========================================================================
--  LUA Event
--  Tutorial requests controls that should always be locked down.
--  Send nil to clear.
-- ===========================================================================
function OnTutorial_ContextDisableItems( contextName:string, kIdsToDisable:table )

    if contextName~="CityPanel" then return; end

    -- Enable any existing controls that are disabled
    if m_kTutorialDisabledControls ~= nil then
        for _,name in ipairs(m_kTutorialDisabledControls) do
            if Controls[name] ~= nil then
                Controls[name]:SetDisabled(false);
            end
        end
    end

    m_kTutorialDisabledControls = kIdsToDisable;

    -- Immediate set disabled
    if m_kTutorialDisabledControls ~= nil then
        for _,name in ipairs(m_kTutorialDisabledControls) do
            if Controls[name] ~= nil then
                Controls[name]:SetDisabled(true);
            else
                UI.DataError("Tutorial requested the control '"..name.."' be disabled in the city panel, but no such control exists in that context.");
            end
        end
    end
end

-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- CQUI update all cities data including real housing when tech/civic that adds housing is boosted and research is completed
function CQUI_UpdateAllCitiesData(PlayerID)
    local m_kCity :table = Players[PlayerID]:GetCities();
    for i, kCity in m_kCity:Members() do
        CityManager.RequestCommand(kCity, CityCommandTypes.SET_FOCUS, nil);
    end
end
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
--  CTOR
-- ===========================================================================
function Initialize()
    LuaEvents.CityPanel_OpenOverview();

    m_isInitializing = true;

    -- Context Events
    ContextPtr:SetInitHandler( OnInit );
    ContextPtr:SetShutdown( OnShutdown );

    -- Control Events
    Controls.BreakdownButton:RegisterCallback( Mouse.eLClick,  OnBreakdown );
    Controls.ReligionButton :RegisterCallback( Mouse.eLClick,  OnReligion );
    Controls.AmenitiesButton:RegisterCallback( Mouse.eLClick,  OnAmenities );
    Controls.HousingButton  :RegisterCallback( Mouse.eLClick,  OnHousing );
    Controls.CitizensGrowthButton:RegisterCallback( Mouse.eLClick,  OnCitizensGrowth );

    Controls.CultureCheck     :RegisterCheckHandler( function() OnCheckYield( YieldTypes.CULTURE,    "Culture"); end );
    Controls.FaithCheck       :RegisterCheckHandler( function() OnCheckYield( YieldTypes.FAITH,      "Faith"); end );
    Controls.FoodCheck        :RegisterCheckHandler( function() OnCheckYield( YieldTypes.FOOD,       "Food"); end );
    Controls.GoldCheck        :RegisterCheckHandler( function() OnCheckYield( YieldTypes.GOLD,       "Gold"); end );
    Controls.ProductionCheck  :RegisterCheckHandler( function() OnCheckYield( YieldTypes.PRODUCTION, "Production"); end );
    Controls.ScienceCheck     :RegisterCheckHandler( function() OnCheckYield( YieldTypes.SCIENCE,    "Science"); end );
    Controls.CultureIgnore    :RegisterCallback( Mouse.eLClick, function() OnResetYieldToNormal( YieldTypes.CULTURE,    "Culture"); end);
    Controls.FaithIgnore      :RegisterCallback( Mouse.eLClick, function() OnResetYieldToNormal( YieldTypes.FAITH,      "Faith"); end);
    Controls.FoodIgnore       :RegisterCallback( Mouse.eLClick, function() OnResetYieldToNormal( YieldTypes.FOOD,       "Food"); end);
    Controls.GoldIgnore       :RegisterCallback( Mouse.eLClick, function() OnResetYieldToNormal( YieldTypes.GOLD,       "Gold"); end);
    Controls.ProductionIgnore :RegisterCallback( Mouse.eLClick, function() OnResetYieldToNormal( YieldTypes.PRODUCTION, "Production"); end);
    Controls.ScienceIgnore    :RegisterCallback( Mouse.eLClick, function() OnResetYieldToNormal( YieldTypes.SCIENCE,    "Science"); end);
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Controls.NextCityButton   :RegisterCallback( Mouse.eLClick, CQUI_OnNextCity);
    Controls.PrevCityButton   :RegisterCallback( Mouse.eLClick, CQUI_OnPreviousCity);

    -- CQUI recenter on the city when clicking the round icon in the panel
    Controls.CircleBacking:RegisterCallback( Mouse.eLClick,  RecenterCameraOnCity);
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    if GameCapabilities.HasCapability("CAPABILITY_GOLD") then
        Controls.PurchaseTileCheck:RegisterCheckHandler(OnTogglePurchaseTile );
        Controls.PurchaseTileCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
        -- CQUI does not register these (unmodified does)
        -- Controls.ProduceWithGoldCheck:RegisterCheckHandler( OnTogglePurchaseWithGold );
        -- Controls.ProduceWithGoldCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
        -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    else
        Controls.PurchaseTileCheck:SetHide(true);
        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
        -- CQUI does not hide this control here (unmodified does)
        -- Controls.ProduceWithGoldCheck:SetHide(true);
        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    end

    Controls.ManageCitizensCheck  :RegisterCheckHandler(  OnToggleManageCitizens );
    Controls.ManageCitizensCheck  :RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    Controls.ChangeProductionCheck:RegisterCheckHandler( OnToggleProduction );
    Controls.ChangeProductionCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    --Controls.ProduceWithFaithCheck:RegisterCheckHandler( OnTogglePurchaseWithFaith );
    --Controls.ProduceWithFaithCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    --Controls.ProduceWithGoldCheck:RegisterCheckHandler( OnTogglePurchaseWithGold );
    --Controls.ProduceWithGoldCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    Controls.ToggleOverviewPanel:RegisterCheckHandler( OnToggleOverviewPanel );
    Controls.ToggleOverviewPanel:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

    -- Game Core Events
    Events.CityAddedToMap         .Add( OnCityAddedToMap );
    Events.CityNameChanged        .Add( OnCityNameChanged );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Events.CitySelectionChanged   .Add( CQUI_OnCitySelectionChanged );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Events.CityFocusChanged       .Add( OnCityFocusChange );
    Events.CityProductionCompleted.Add( OnCityProductionCompleted );
    Events.CityProductionUpdated  .Add( OnCityProductionUpdated );
    Events.CityProductionChanged  .Add( OnCityProductionChanged );
    Events.CityWorkerChanged      .Add( OnCityWorkerChanged );
    Events.DistrictDamageChanged  .Add( OnCityProductionChanged );
    Events.LocalPlayerTurnBegin   .Add( OnLocalPlayerTurnBegin );
    Events.ImprovementChanged     .Add( OnCityProductionChanged );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Events.InterfaceModeChanged   .Add( CQUI_OnInterfaceModeChanged );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    Events.LocalPlayerChanged     .Add( OnLocalPlayerChanged );
    Events.UnitSelectionChanged   .Add( OnUnitSelectionChanged );
    Events.PlayerResourceChanged  .Add( OnPlayerResourceChanged );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    Events.LoadScreenClose        .Add( CQUI_OnLoadScreenClose );
    Events.PlotYieldChanged       .Add( OnTileImproved );
    Events.PlayerTurnActivated    .Add( RefreshOnTurnRoll );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    -- LUA Events
    LuaEvents.CityPanelOverview_CloseButton.Add( OnCloseOverviewPanel );
    LuaEvents.CityPanel_SetOverViewState.Add(    OnCityPanelSetOverViewState );
    LuaEvents.CityPanel_ToggleManageCitizens.Add(OnCityPanelToggleManageCitizens );
    LuaEvents.GameDebug_Return             .Add( OnGameDebugReturn );      -- hotloading help
    LuaEvents.ProductionPanel_Close        .Add( OnProductionPanelClose );
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- CQUI does not register this LuaEvent (unmodified does)
    -- LuaEvents.ProductionPanel_ListModeChanged.Add(   OnProductionPanelListModeChanged );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    LuaEvents.ProductionPanel_Open         .Add( OnProductionPanelOpen );
    LuaEvents.Tutorial_CityPanelOpen       .Add( OnTutorialOpen );
    LuaEvents.Tutorial_ContextDisableItems .Add( OnTutorial_ContextDisableItems );

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- CQUI Events
    LuaEvents.CQUI_GoNextCity      .Add( CQUI_OnNextCity );
    LuaEvents.CQUI_GoPrevCity      .Add( CQUI_OnPreviousCity );
    LuaEvents.CQUI_ToggleGrowthTile.Add( CQUI_ToggleGrowthTile );
    LuaEvents.CQUI_SettingsUpdate  .Add( CQUI_SettingsUpdate );
    LuaEvents.RefreshCityPanel     .Add( Refresh );
    LuaEvents.CQUI_AllCitiesInfoUpdatedOnTechCivicBoost .Add( CQUI_UpdateAllCitiesData );    -- CQUI update all cities data including real housing when tech/civic that adds housing is boosted and research is completed
    LuaEvents.CQUI_DisplayGrowthTileIfValid             .Add( CQUI_DisplayGrowthTileIfValid );
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

    -- Truncate possible static text overflows
    TruncateStringWithTooltip(Controls.BreakdownLabel, MAX_BEFORE_TRUNC_STATIC_LABELS, Controls.BreakdownLabel:GetText());
    TruncateStringWithTooltip(Controls.ReligionLabel,  MAX_BEFORE_TRUNC_STATIC_LABELS, Controls.ReligionLabel:GetText());
    TruncateStringWithTooltip(Controls.AmenitiesLabel, MAX_BEFORE_TRUNC_STATIC_LABELS, Controls.AmenitiesLabel:GetText());
    TruncateStringWithTooltip(Controls.HousingLabel,   MAX_BEFORE_TRUNC_STATIC_LABELS, Controls.HousingLabel:GetText());
end

-- Main script start
Initialize();
