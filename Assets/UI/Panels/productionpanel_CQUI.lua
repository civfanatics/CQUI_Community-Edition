-- ===========================================================================
-- Base File
-- ===========================================================================
include("ProductionPanel");
include("StrategicView_MapPlacement");    -- RealizePlotArtForDistrictPlacement, RealizePlotArtForWonderPlacement

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_OnInterfaceModeChanged = OnInterfaceModeChanged;
BASE_OnClose = OnClose;
BASE_PopulateGenericItemData = PopulateGenericItemData;
BASE_View = View;
BASE_GetData = GetData;
BASE_Refresh = Refresh;
BASE_OnNotificationPanelChooseProduction = OnNotificationPanelChooseProduction;
BASE_OnCityBannerManagerProductionToggle = OnCityBannerManagerProductionToggle;
BASE_CQUI_ZoneDistrict = ZoneDistrict;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
-- Do not show a number of turns or the timer icon if it's a purchase-only item
local CQUI_TURNS_LEFT_PURCHASE_ONLY = -2;
local CQUI_PurchaseTable = {}; -- key = item Hash
local CQUI_ProductionQueue :boolean = true;
local CQUI_ShowProductionRecommendations :boolean = false;
local CQUI_ManagerShowing = false;
local m_AdjacencyBonusDistricts : number = UILens.CreateLensLayerHash("Adjacency_Bonus_Districts");
local m_Districts : number = UILens.CreateLensLayerHash("Districts");

function CQUI_OnSettingsUpdate()
    CQUI_ProductionQueue = GameConfiguration.GetValue("CQUI_ProductionQueue");
    CQUI_ShowProductionRecommendations = GameConfiguration.GetValue("CQUI_ShowProductionRecommendations") == 1
    CQUI_SelectRightTab()
    Controls.CQUI_ShowManagerButton:SetHide(not CQUI_ProductionQueue);
end

function CQUI_SelectRightTab()
    if (not CQUI_ProductionQueue) then
        OnTabChangeProduction();
    else
        OnTabChangeQueue();
    end
end

function CQUI_ToggleManager()
    if CQUI_ManagerShowing then
        CQUI_ManagerShowing = false;
        OnTabChangeQueue();
    else
        CQUI_ManagerShowing = true;
        OnTabChangeManager();
    end
    Controls.CQUI_ShowManagerButton:SetSelected(CQUI_ManagerShowing);
end

function CQUI_PurchaseUnit(item, city)
    return function()
        if not item.CantAfford and not item.Disabled then
            PurchaseUnit(city, item);
        end
    end
end

function CQUI_PurchaseUnitCorps(item, city)
    return function()
        if not item.CantAfford and not item.Disabled then
            PurchaseUnitCorps(city, item);
        end
    end
end

function CQUI_PurchaseUnitArmy(item, city)
    return function()
        if not item.CantAfford and not item.Disabled then
            PurchaseUnitArmy(city, item);
        end
    end
end

function CQUI_PurchaseDistrict(item, city)
    return function()
        if not item.CantAfford and not item.Disabled then
            PurchaseDistrict(city, item);
        end
    end
end

function CQUI_PurchaseBuilding(item, city)
    return function()
        if not item.CantAfford and not item.Disabled then
            PurchaseBuilding(city, item);
        end
    end
end

function CQUI_ClearDistrictBuildingLayers()
    -- Make it's the right mode.
    if (UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT) then
        -- Clear existing art then re-realize
        UILens.ClearLayerHexes( m_AdjacencyBonusDistricts );
        UILens.ClearLayerHexes( m_Districts );
        RealizePlotArtForDistrictPlacement();
    elseif (UI.GetInterfaceMode() == InterfaceModeTypes.BUILDING_PLACEMENT) then
        -- Clear existing art then re-realize
        UILens.ClearLayerHexes( m_AdjacencyBonusDistricts );
        UILens.ClearLayerHexes( m_Districts );
        RealizePlotArtForWonderPlacement();
    end
    LuaEvents.CQUI_RefreshPurchasePlots();
    LuaEvents.CQUI_DistrictPlotIconManager_ClearEverything();
    LuaEvents.CQUI_Realize2dArtForDistrictPlacement();
end

-- ===========================================================================
--    CQUI modified View function
--    create the list of purchasable items
-- ===========================================================================
function View(data)
    for i, item in ipairs(data.UnitPurchases) do
        if item.Yield then
            if (CQUI_PurchaseTable[item.Hash] == nil) then
                CQUI_PurchaseTable[item.Hash] = {};
            end
            if (item.Yield == "YIELD_GOLD") then
                CQUI_PurchaseTable[item.Hash]["gold"] = item.Cost;
                CQUI_PurchaseTable[item.Hash]["goldCantAfford"] = item.CantAfford;
                CQUI_PurchaseTable[item.Hash]["goldDisabled"] = item.Disabled;
                CQUI_PurchaseTable[item.Hash]["goldCallback"] = CQUI_PurchaseUnit(item, data.City);
                if (item.Corps) then
                    CQUI_PurchaseTable[item.Hash]["corpsGold"] = item.CorpsCost;
                    CQUI_PurchaseTable[item.Hash]["corpsGoldDisabled"] = item.CorpsDisabled;
                    CQUI_PurchaseTable[item.Hash]["corpsGoldCallback"] = CQUI_PurchaseUnitCorps(item, data.City);
                end
                if (item.Army) then
                    CQUI_PurchaseTable[item.Hash]["armyGold"] = item.ArmyCost;
                    CQUI_PurchaseTable[item.Hash]["armyGoldDisabled"] = item.ArmyDisabled;
                    CQUI_PurchaseTable[item.Hash]["armyGoldCallback"] = CQUI_PurchaseUnitArmy(item, data.City);
                end
            else
                CQUI_PurchaseTable[item.Hash]["faith"] = item.Cost;
                CQUI_PurchaseTable[item.Hash]["faithCantAfford"] = item.CantAfford;
                CQUI_PurchaseTable[item.Hash]["faithDisabled"] = item.Disabled;
                CQUI_PurchaseTable[item.Hash]["faithCallback"] = CQUI_PurchaseUnit(item, data.City);
                if (item.Corps) then
                    CQUI_PurchaseTable[item.Hash]["corpsFaith"] = item.CorpsCost;
                    CQUI_PurchaseTable[item.Hash]["corpsFaithDisabled"] = item.ArmyDisabled;
                    CQUI_PurchaseTable[item.Hash]["corpsFaithCallback"] = CQUI_PurchaseUnitCorps(item, data.City);
                end
                if (item.Army) then
                    CQUI_PurchaseTable[item.Hash]["armyFaith"] = item.ArmyCost;
                    CQUI_PurchaseTable[item.Hash]["armyFaithDisabled"] = item.ArmyDisabled;
                    CQUI_PurchaseTable[item.Hash]["armyFaithCallback"] = CQUI_PurchaseUnitArmy(item, data.City);
                end
            end
        end
    end

    for i, item in ipairs(data.DistrictPurchases) do
        if item.Yield then
            if (CQUI_PurchaseTable[item.Hash] == nil) then
                CQUI_PurchaseTable[item.Hash] = {};
            end
            if (item.Yield == "YIELD_GOLD") then
                CQUI_PurchaseTable[item.Hash]["goldCantAfford"] = item.CantAfford;
                CQUI_PurchaseTable[item.Hash]["goldDisabled"] = item.Disabled;
                CQUI_PurchaseTable[item.Hash]["gold"] = item.Cost;
                CQUI_PurchaseTable[item.Hash]["goldCallback"] = CQUI_PurchaseDistrict(item, data.City);
            else
                CQUI_PurchaseTable[item.Hash]["faithCantAfford"] = item.CantAfford;
                CQUI_PurchaseTable[item.Hash]["faithDisabled"] = item.Disabled;
                CQUI_PurchaseTable[item.Hash]["faith"] = item.Cost;
                CQUI_PurchaseTable[item.Hash]["faithCallback"] = CQUI_PurchaseDistrict(item, data.City);
            end
        end
    end

    for i, item in ipairs(data.BuildingPurchases) do
        if item.Yield then
            if (CQUI_PurchaseTable[item.Hash] == nil) then
                CQUI_PurchaseTable[item.Hash] = {};
            end
            if (item.Yield == "YIELD_GOLD") then
                CQUI_PurchaseTable[item.Hash]["goldCantAfford"] = item.CantAfford;
                CQUI_PurchaseTable[item.Hash]["goldDisabled"] = item.Disabled;
                CQUI_PurchaseTable[item.Hash]["gold"] = item.Cost;
                CQUI_PurchaseTable[item.Hash]["goldCallback"] = CQUI_PurchaseBuilding(item, data.City);
            else
                CQUI_PurchaseTable[item.Hash]["faithCantAfford"] = item.CantAfford;
                CQUI_PurchaseTable[item.Hash]["faithDisabled"] = item.Disabled;
                CQUI_PurchaseTable[item.Hash]["faith"] = item.Cost;
                CQUI_PurchaseTable[item.Hash]["faithCallback"] = CQUI_PurchaseBuilding(item, data.City);
            end
        end
    end

    BASE_View(data)
end

-- ===========================================================================
--    CQUI modified GetData function
--    add religious units to the unit list
-- ===========================================================================
function GetData()
    local new_data = BASE_GetData()

    local pSelectedCity:table = UI.GetHeadSelectedCity();
    if pSelectedCity == nil then
        Close();
        return nil;
    end

    local buildQueue = pSelectedCity:GetBuildQueue();

    for row in GameInfo.Units() do
        if row.MustPurchase and buildQueue:CanProduce( row.Hash, true ) and (row.PurchaseYield == "YIELD_FAITH" or row.PurchaseYield == "YIELD_GOLD") then
            local isCanProduceExclusion, results     = buildQueue:CanProduce( row.Hash, false, true );
            -- If a unit is purchase only, then "isDisabled" needs to be True, as that disables the button control that
            -- allows the religious units to be enqueued
            local isDisabled  :boolean = row.MustPurchase -- not isCanProduceExclusion;
            local sAllReasons :string = ComposeFailureReasonStrings( isDisabled, results );
            local sToolTip    :string = ToolTipHelper.GetUnitToolTip( row.Hash, MilitaryFormationTypes.STANDARD_MILITARY_FORMATION, buildQueue ) .. sAllReasons;
            -- Remove the part about the production cost from the tooltip (this format comes from ToolTipHelper.lua)
            local prodPartPattern = "%[NEWLINE%]%[NEWLINE%]"..Locale.Lookup("LOC_HUD_PRODUCTION_COST")..": .+%[ICON_Production%] "..Locale.Lookup("LOC_HUD_PRODUCTION");
            sToolTip = sToolTip:gsub(prodPartPattern, "");

            local kUnit :table = {
                Type                = row.UnitType,
                Name                = row.Name,
                ToolTip             = sToolTip,
                Hash                = row.Hash,
                Kind                = row.Kind,
                TurnsLeft           = CQUI_TURNS_LEFT_PURCHASE_ONLY,
                Disabled            = isDisabled,
                Civilian            = row.FormationClass == "FORMATION_CLASS_CIVILIAN",
                Cost                = 0,
                Progress            = 0,
                Corps               = false,
                CorpsCost           = 0,
                CorpsTurnsLeft      = 1,
                CorpsTooltip        = "",
                CorpsName           = "",
                Army                = false,
                ArmyCost            = 0,
                ArmyTurnsLeft       = 1,
                ArmyTooltip         = "",
                ArmyName            = "",
                ReligiousStrength   = row.ReligiousStrength,
                IsCurrentProduction = row.Hash == m_CurrentProductionHash
            };

            table.insert(new_data.UnitItems, kUnit );
        end
    end

    return new_data
end

-- ===========================================================================
--    CQUI modified GetTurnsToCompleteStrings function
--    add gold and faith purchase in the same list
-- ===========================================================================
function GetTurnsToCompleteStrings( turnsToComplete:number )
    local turnsStr:string = "";
    local turnsStrTT:string = "";

    if turnsToComplete == -1 then
        turnsStr = "999+[ICON_Turn]";
        turnsStrTT = TXT_HUD_CITY_WILL_NOT_COMPLETE;
    elseif turnsToComplete == CQUI_TURNS_LEFT_PURCHASE_ONLY then
        turnsStr = "";
        turnsStrTT = ""; --Locale.Lookup("LOC_PRODPANEL_PURCHASE_FAITH");
    else
        turnsStr = turnsToComplete .. "[ICON_Turn]";
        turnsStrTT = turnsToComplete .. Locale.Lookup("LOC_HUD_CITY_TURNS_TO_COMPLETE", turnsToComplete);
    end

    return turnsStr, turnsStrTT;
end

-- ===========================================================================
--    CQUI modified PopulateGenericItemData function
--    add gold and faith purchase in the same list
-- ===========================================================================
function PopulateGenericItemData( kInstance:table, kItem:table )
    BASE_PopulateGenericItemData(kInstance, kItem);

    local purchaseGoldFaithColor = UI.GetColorValueFromHexLiteral(0xFFFFFFFF);
    local notEnoughGoldFaithColor = UI.GetColorValueFromHexLiteral(0xCF0000FF);
    local enabledButtonColor = UI.GetColorValueFromHexLiteral(0xFFF38FFF);
    local disabledButtonColor = UI.GetColorValueFromHexLiteral(0xDD3366FF);
    local purchaseButtonPadding = 15;

  -- CQUI show recommandations check
    if not CQUI_ShowProductionRecommendations then
        kInstance.RecommendedIcon:SetHide(true);
    end

  -- CQUI Reset the color
    if kInstance.PurchaseButton then
        kInstance.PurchaseButton:GetTextControl():SetColor(purchaseGoldFaithColor);
    end
    if kInstance.CorpsPurchaseButton then
        kInstance.CorpsPurchaseButton:GetTextControl():SetColor(purchaseGoldFaithColor);
    end
    if kInstance.ArmyPurchaseButton then
        kInstance.ArmyPurchaseButton:GetTextControl():SetColor(purchaseGoldFaithColor);
    end
    if kInstance.FaithPurchaseButton then
        kInstance.FaithPurchaseButton:GetTextControl():SetColor(purchaseGoldFaithColor);
    end
    if kInstance.CorpsFaithPurchaseButton then
        kInstance.CorpsFaithPurchaseButton:GetTextControl():SetColor(purchaseGoldFaithColor);
    end
    if kInstance.ArmyFaithPurchaseButton then
        kInstance.ArmyFaithPurchaseButton:GetTextControl():SetColor(purchaseGoldFaithColor);
    end

    -- Gold purchase button for building, district and units
    if kInstance.PurchaseButton then
        if CQUI_PurchaseTable[kItem.Hash] and CQUI_PurchaseTable[kItem.Hash]["gold"] then
            kInstance.PurchaseButton:SetText(CQUI_PurchaseTable[kItem.Hash]["gold"] .. "[ICON_GOLD]");
            kInstance.PurchaseButton:SetSizeX(kInstance.PurchaseButton:GetTextControl():GetSizeX() + purchaseButtonPadding);
            kInstance.PurchaseButton:SetColor(enabledButtonColor);
            kInstance.PurchaseButton:SetHide(false);
            kInstance.PurchaseButton:SetDisabled(false);
            kInstance.PurchaseButton:RegisterCallback(Mouse.eLClick, CQUI_PurchaseTable[kItem.Hash]["goldCallback"]);

            if CQUI_PurchaseTable[kItem.Hash]["goldCantAfford"] or CQUI_PurchaseTable[kItem.Hash]["goldDisabled"] then
                kInstance.PurchaseButton:SetDisabled(true);
                kInstance.PurchaseButton:SetColor(disabledButtonColor);
                kInstance.PurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end

            if CQUI_PurchaseTable[kItem.Hash]["goldCantAfford"] then
                kInstance.PurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end
        else
            kInstance.PurchaseButton:SetHide(true);
        end
    end

    -- Special case for Corps gold purchase button
    if kInstance.CorpsPurchaseButton then
        if CQUI_PurchaseTable[kItem.Hash] and CQUI_PurchaseTable[kItem.Hash]["corpsGold"] then
            kInstance.CorpsPurchaseButton:SetHide(false);
            kInstance.CorpsPurchaseButton:SetDisabled(false);
            kInstance.CorpsPurchaseButton:SetText(CQUI_PurchaseTable[kItem.Hash]["corpsGold"] .. "[ICON_GOLD]");
            kInstance.CorpsPurchaseButton:SetSizeX(kInstance.CorpsPurchaseButton:GetTextControl():GetSizeX() + purchaseButtonPadding);
            kInstance.CorpsPurchaseButton:RegisterCallback(Mouse.eLClick, CQUI_PurchaseTable[kItem.Hash]["corpsGoldCallback"]);

            if CQUI_PurchaseTable[kItem.Hash]["corpsGoldDisabled"] then
                kInstance.CorpsPurchaseButton:SetDisabled(true);
                kInstance.CorpsPurchaseButton:SetColor(disabledButtonColor);
                kInstance.CorpsPurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end
        else
            kInstance.CorpsPurchaseButton:SetHide(true);
        end
    end

    -- Special case for Army gold purchase button
    if kInstance.ArmyPurchaseButton then
        if CQUI_PurchaseTable[kItem.Hash] and CQUI_PurchaseTable[kItem.Hash]["armyGold"] then
            kInstance.ArmyPurchaseButton:SetHide(false);
            kInstance.ArmyPurchaseButton:SetDisabled(false);
            kInstance.ArmyPurchaseButton:SetText(CQUI_PurchaseTable[kItem.Hash]["armyGold"] .. "[ICON_GOLD]");
            kInstance.ArmyPurchaseButton:SetSizeX(kInstance.ArmyPurchaseButton:GetTextControl():GetSizeX() + purchaseButtonPadding);
            kInstance.ArmyPurchaseButton:RegisterCallback(Mouse.eLClick, CQUI_PurchaseTable[kItem.Hash]["armyGoldCallback"]);

            if CQUI_PurchaseTable[kItem.Hash]["armyGoldDisabled"] then
                kInstance.ArmyPurchaseButton:SetDisabled(true);
                kInstance.ArmyPurchaseButton:SetColor(disabledButtonColor);
                kInstance.ArmyPurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end
        else
            kInstance.ArmyPurchaseButton:SetHide(true);
        end
    end

  -- Faith purchase button for building, district and units
    if kInstance.FaithPurchaseButton then
        if CQUI_PurchaseTable[kItem.Hash] and CQUI_PurchaseTable[kItem.Hash]["faith"] then
            kInstance.FaithPurchaseButton:SetText(CQUI_PurchaseTable[kItem.Hash]["faith"] .. "[ICON_FAITH]");
            kInstance.FaithPurchaseButton:SetSizeX(kInstance.FaithPurchaseButton:GetTextControl():GetSizeX() + purchaseButtonPadding);
            kInstance.FaithPurchaseButton:SetColor(enabledButtonColor);
            kInstance.FaithPurchaseButton:SetHide(false);
            kInstance.FaithPurchaseButton:SetDisabled(false);
            kInstance.FaithPurchaseButton:RegisterCallback(Mouse.eLClick, CQUI_PurchaseTable[kItem.Hash]["faithCallback"]);

            if CQUI_PurchaseTable[kItem.Hash]["faithCantAfford"] or CQUI_PurchaseTable[kItem.Hash]["faithDisabled"] then
                kInstance.FaithPurchaseButton:SetDisabled(true);
                kInstance.FaithPurchaseButton:SetColor(disabledButtonColor);
                kInstance.FaithPurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end

            if CQUI_PurchaseTable[kItem.Hash]["faithCantAfford"] then
                kInstance.FaithPurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end
        else
            kInstance.FaithPurchaseButton:SetHide(true);
        end
    end

    -- Special case for Corps faith purchase button
    if kInstance.CorpsFaithPurchaseButton then
        if CQUI_PurchaseTable[kItem.Hash] and CQUI_PurchaseTable[kItem.Hash]["corpsFaith"] then
            kInstance.CorpsFaithPurchaseButton:SetHide(false);
            kInstance.CorpsFaithPurchaseButton:SetDisabled(false);
            kInstance.CorpsFaithPurchaseButton:SetText(CQUI_PurchaseTable[kItem.Hash]["corpsFaith"] .. "[ICON_FAITH]");
            kInstance.CorpsFaithPurchaseButton:SetSizeX(kInstance.CorpsFaithPurchaseButton:GetTextControl():GetSizeX() + purchaseButtonPadding);
            kInstance.CorpsFaithPurchaseButton:RegisterCallback(Mouse.eLClick, CQUI_PurchaseTable[kItem.Hash]["corpsFaithCallback"]);

            if CQUI_PurchaseTable[kItem.Hash]["corpsFaithDisabled"] then
                kInstance.CorpsFaithPurchaseButton:SetDisabled(true);
                kInstance.CorpsFaithPurchaseButton:SetColor(disabledButtonColor);
                kInstance.CorpsFaithPurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end
        else
            kInstance.CorpsFaithPurchaseButton:SetHide(true);
        end
    end

    -- Special case for Army faith purchase button
    if kInstance.ArmyFaithPurchaseButton then
        if CQUI_PurchaseTable[kItem.Hash] and CQUI_PurchaseTable[kItem.Hash]["armyFaith"] then
            kInstance.ArmyFaithPurchaseButton:SetHide(false);
            kInstance.ArmyFaithPurchaseButton:SetDisabled(false);
            kInstance.ArmyFaithPurchaseButton:SetText(CQUI_PurchaseTable[kItem.Hash]["armyFaith"] .. "[ICON_FAITH]");
            kInstance.ArmyFaithPurchaseButton:SetSizeX(kInstance.ArmyFaithPurchaseButton:GetTextControl():GetSizeX() + purchaseButtonPadding);
            kInstance.ArmyFaithPurchaseButton:RegisterCallback(Mouse.eLClick, CQUI_PurchaseTable[kItem.Hash]["armyFaithCallback"]);

            if CQUI_PurchaseTable[kItem.Hash]["armyFaithDisabled"] then
                kInstance.ArmyFaithPurchaseButton:SetDisabled(true);
                kInstance.ArmyFaithPurchaseButton:SetColor(disabledButtonColor);
                kInstance.ArmyFaithPurchaseButton:GetTextControl():SetColor(notEnoughGoldFaithColor);
            end
        else
            kInstance.ArmyFaithPurchaseButton:SetHide(true);
        end
    end
end

-- ===========================================================================
--    CQUI modified BuildBuilding function : removed the InterfaceMode change
-- ===========================================================================
function BuildBuilding(city, buildingEntry)
    if CheckQueueItemSelected() then
        return;
    end

    local building        :table   = GameInfo.Buildings[buildingEntry.Type];
    local bNeedsPlacement :boolean = building.RequiresPlacement;

    -- UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);

    local pBuildQueue = city:GetBuildQueue();
    if (pBuildQueue:HasBeenPlaced(buildingEntry.Hash)) then
        bNeedsPlacement = false;
    end

    -- If it's a Wonder and the city already has the building then it doesn't need to be replaced.
    if (bNeedsPlacement) then
        local cityBuildings = city:GetBuildings();
        if (cityBuildings:HasBuilding(buildingEntry.Hash)) then
            bNeedsPlacement = false;
        end
    end

    -- Does the building need to be placed?
    if ( bNeedsPlacement ) then
        -- If so, set the placement mode
        local tParameters = {};
        tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash;
        GetBuildInsertMode(tParameters);
        UI.SetInterfaceMode(InterfaceModeTypes.BUILDING_PLACEMENT, tParameters);
        Close();
    else
        -- If not, add it to the queue.
        local tParameters = {};
        tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash;
        GetBuildInsertMode(tParameters);
        CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
        UI.PlaySound("Confirm_Production");
        CloseAfterNewProduction();
    end

    CQUI_ClearDistrictBuildingLayers();
end

-- ===========================================================================
--    CQUI modified ZoneDistrict function :
--    If already in placing district/building mode, reset the lenses for
--    the new district/building
-- ===========================================================================
function ZoneDistrict(city, districtEntry)
    BASE_CQUI_ZoneDistrict(city, districtEntry);

    CQUI_ClearDistrictBuildingLayers();
end

-- ===========================================================================
--    CQUI modified Close function
--    Add a check to see if we're placing something down (no need to close)
--    Changed the condition of closing (not IsReversing)
-- ===========================================================================
function Close()
    if UI.GetInterfaceMode() == InterfaceModeTypes.BUILDING_PLACEMENT or UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then
        return;
    end

    if (not Controls.SlideIn:IsReversing()) then -- Need to check to make sure that we have not already begun the transition before attempting to close the panel.
        UI.PlaySound("Production_Panel_Closed");
        Controls.SlideIn:Reverse();
        Controls.AlphaIn:Reverse();
        Controls.PauseDismissWindow:Play();
        LuaEvents.ProductionPanel_CloseManager();
        LuaEvents.ProductionPanel_Close();
    end
end

-- ===========================================================================
--    CQUI modified OnExpand function : fixed slide speed and list size
-- ===========================================================================
function OnExpand(instance:table)
    instance.ListSlide:SetSpeed(100); -- CQUI : fix the sliding time

    m_kClickedInstance = instance;
    instance.HeaderOn:SetHide(false);
    instance.Header:SetHide(true);
    instance.List:SetHide(false);
    -- CQUI : fix the list flickering when it's refreshed
    --instance.ListSlide:SetSizeY(instance.List:GetSizeY());
    --instance.ListAlpha:SetSizeY(instance.List:GetSizeY());
    instance.ListSlide:SetToBeginning();
    instance.ListAlpha:SetToBeginning();
    instance.ListSlide:Play();
    instance.ListAlpha:Play();
    -- CQUI : Don't touch the interface Mode
    --UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);
end

-- ===========================================================================
--    CQUI modified Refresh function : reset the CQUI_PurchaseTable
-- ===========================================================================
function Refresh()
    CQUI_PurchaseTable = {};

    BASE_Refresh()
end

-- ===========================================================================
--    CQUI modified Open function
-- ===========================================================================
function Open()
    if ContextPtr:IsHidden() or Controls.SlideIn:IsReversing() then                 -- The ContextPtr is only hidden as a callback to the finished SlideIn animation, so this check should be sufficient to ensure that we are not animating.
        -- Sets up proper selection AND the associated lens so it's not stuck "on".
        UI.PlaySound("Production_Panel_Open");
        Controls.PauseDismissWindow:SetToBeginning(); -- AZURENCY : fix the callback that hide the pannel to be called during the Openning animation
        LuaEvents.ProductionPanel_Open();
        Refresh();
        CQUI_SelectRightTab();
        ContextPtr:SetHide(false);
        Controls.ProductionListScroll:SetScrollValue(0);

        -- Size the panel to the maximum Y value of the expanded content
        Controls.AlphaIn:SetToBeginning();
        Controls.SlideIn:SetToBeginning();
        Controls.AlphaIn:Play();
        Controls.SlideIn:Play();
    end
end

-- ===========================================================================
--    CQUI modified OnClose via click
-- ===========================================================================
function OnClose()
    if UI.GetInterfaceMode() == InterfaceModeTypes.BUILDING_PLACEMENT or UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then
        UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);
        LuaEvents.CQUI_CityviewEnable();
        return;
    end

    LuaEvents.CQUI_CityPanel_CityviewDisable();
end

-- ===========================================================================
--    CQUI modified CloseAfterNewProduction
-- ===========================================================================
function CloseAfterNewProduction()
    return;
end

-- ===========================================================================
--    CQUI modified OnNotificationPanelChooseProduction : Removed tab selection
-- ===========================================================================
function OnNotificationPanelChooseProduction()
    if ContextPtr:IsHidden() then
        Open();
        --m_tabs.SelectTab(m_productionTab);
    end
end

-- ===========================================================================
--    CQUI modified OnCityBannerManagerProductionToggle : Removed tab selection
-- ===========================================================================
function OnCityBannerManagerProductionToggle()
    if (ContextPtr:IsHidden()) then
        Open();
        --m_tabs.SelectTab(m_productionTab);
    else
        Close();
    end
end

-- ===========================================================================
--    CQUI Cityview
-- ===========================================================================
function CQUI_OnCityviewEnabled()
    Open();
end

function CQUI_OnCityviewDisabled()
    Close();
end

-- ===========================================================================
--    CQUI modified OnInterfaceModeChanged
-- ===========================================================================
function OnInterfaceModeChanged( eOldMode:number, eNewMode:number )
    return;
end

-- ===========================================================================
--    CQUI modified CreateCorrectTabs : no need for tabs, one unified list
-- ===========================================================================
function CreateCorrectTabs()
end

-- ===========================================================================
function Initialize_ProductionPanel_CQUI()
    Events.InterfaceModeChanged.Remove( BASE_OnInterfaceModeChanged );
    Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );
    Events.CityMadePurchase.Add( function() Refresh(); end);

    LuaEvents.NotificationPanel_ChooseProduction.Remove( BASE_OnNotificationPanelChooseProduction );
    LuaEvents.NotificationPanel_ChooseProduction.Add( OnNotificationPanelChooseProduction );

    LuaEvents.CityBannerManager_ProductionToggle.Remove( BASE_OnCityBannerManagerProductionToggle );
    LuaEvents.CityBannerManager_ProductionToggle.Add( OnCityBannerManagerProductionToggle );

    Controls.CloseButton:ClearCallback(Mouse.eLClick);
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose);
    Controls.CQUI_ShowManagerButton:RegisterCallback(Mouse.eLClick, CQUI_ToggleManager);

    LuaEvents.CQUI_ProductionPanel_CityviewEnable.Add( CQUI_OnCityviewEnabled);
    LuaEvents.CQUI_ProductionPanel_CityviewDisable.Add( CQUI_OnCityviewDisabled);
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize_ProductionPanel_CQUI();

-- ===========================================================================
-- 2020-11-22 Support for the Hero Mode
-- Copy & paste from ProductionPanel_Babylon_Heroes.lua
-- ===========================================================================

local bIsHeroMODE:boolean = ( GameInfo.Kinds.KIND_HEROCLASS ~= nil);
print("Hero MODE is:", bIsHeroMODE and "ON" or "off");

if bIsHeroMODE then

    include("ToolTipHelper")
    include("ToolTipHelper_Babylon_Heroes");

    local RightClickProductionItem_BASE = RightClickProductionItem;

    -- ===========================================================================
    -- Override: when clicking a Hero Devotion project, view the Hero info rather than
    -- the project info
    function RightClickProductionItem(sItemType:string)

        local pProjectInfo = GameInfo.Projects[sItemType];
        if (pProjectInfo ~= nil) then
            for row in GameInfo.HeroClasses() do
                if (row.CreationProjectType == sItemType) then
                    -- View the Hero UnitType instead
                    if (row.UnitType ~= "") then
                        return RightClickProductionItem_BASE(row.UnitType);
                    end
                end
            end
        end

        -- Default
        return RightClickProductionItem_BASE(sItemType);
    end

end -- bIsHeroMODE
