include("LensSupport");
local LENS_NAME = "CQUI_CITIZEN_MANAGEMENT"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

local m_cityID :number = -1;

local m_LensSettings = {
    ["COLOR_CITY_PLOT_LENS_WORKING"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITY_PLOT_LENS_WORKING"), KeyLabel = "LOC_HUD_CITY_PLOT_LENS_WORKING" },
    ["COLOR_CITY_PLOT_LENS_LOCKED"]  =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITY_PLOT_LENS_LOCKED"),  KeyLabel = "LOC_HUD_CITY_PLOT_LENS_LOCKED" },
    ["COLOR_CITY_PLOT_LENS_OTHER"]   =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITY_PLOT_LENS_OTHER"),   KeyLabel = "LOC_HUD_CITY_PLOT_LENS_OTHER" },
    ["COLOR_CITY_PLOT_LENS_CULTURE"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITY_PLOT_LENS_CULTURE"), KeyLabel = "LOC_HUD_CITY_PLOT_LENS_CULTURE" }
}
-- ===========================================================================
-- Exported functions
-- ===========================================================================

function OnGetColorPlotTable()
    local playerID:number = Game.GetLocalPlayer();
    local pCity:table = Players[playerID]:GetCities():FindID(m_cityID);
    local colorPlot:table = {};

    if pCity ~= nil then
        --print("Show citizens for " .. Locale.Lookup(pCity:GetName()));

        local tParameters:table = {};
        local cityPlotID = Map.GetPlot(pCity:GetX(), pCity:GetY()):GetIndex();
        tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);

        local workingColor:number = m_LensSettings["COLOR_CITY_PLOT_LENS_WORKING"].ConfiguredColor;
        local lockedColor:number = m_LensSettings["COLOR_CITY_PLOT_LENS_LOCKED"].ConfiguredColor;
        local otherColor:number = m_LensSettings["COLOR_CITY_PLOT_LENS_OTHER"].ConfiguredColor;
        colorPlot[workingColor] = {};
        colorPlot[lockedColor] = {};
        colorPlot[otherColor] = {};

        -- Get city plot and citizens info
        local tResults:table = CityManager.GetCommandTargets(pCity, CityCommandTypes.MANAGE, tParameters);
        if tResults == nil then
            print("ERROR : Could not find plots");
            return;
        end

        local tPlots:table = tResults[CityCommandResults.PLOTS];
        local tUnits:table = tResults[CityCommandResults.CITIZENS];
        local tLockedUnits:table = tResults[CityCommandResults.LOCKED_CITIZENS];
        local markedPlots = {};

        if tPlots ~= nil and table.count(tPlots) > 0 then
            for i, plotID in ipairs(tPlots) do
                if ((tLockedUnits[i] ~= nil and tLockedUnits[i] > 0) or cityPlotID == plotID) then
                    table.insert(colorPlot[lockedColor], plotID);
                    markedPlots[plotID] = 1;
                elseif (tUnits[i] ~= nil and tUnits[i] > 0) then
                    table.insert(colorPlot[workingColor], plotID);
                    markedPlots[plotID] = 1;
                end
            end
        end

        -- Next culture expansion plot, show it only if not in city panel
        if UI.GetHeadSelectedCity() == nil then
            local pCityCulture:table    = pCity:GetCulture();
            local culturePlotColor:number = m_LensSettings["COLOR_CITY_PLOT_LENS_CULTURE"].ConfiguredColor;
            if pCityCulture ~= nil then
                local pNextPlotID:number = pCityCulture:GetNextPlot();
                if pNextPlotID ~= nil and Map.IsPlot(pNextPlotID) then
                    colorPlot[culturePlotColor] = {pNextPlotID};
                end
            end
        end

        -- Show the city borders and mark plots not yet marked with "other" color
        local pOverlay:object = UILens.GetOverlay("CityBorders");
        pOverlay:ClearPlotChannel(); -- Calling ClearPlotChannel without a channel clears all channels
        pOverlay:SetVisible(true);

        local backColor:number, frontColor:number  = UI.GetPlayerColors( pCity:GetOwner() );

        local kCityPlots :table = Map.GetCityPlots():GetPurchasedPlots( pCity );
        for _,plotId in pairs(kCityPlots) do
            -- Add this city only to the border overlay
            pOverlay:SetBorderColors(0, backColor, frontColor);
            pOverlay:SetPlotChannel(kCityPlots, 0);
            if markedPlots[plotId] == nil then
                table.insert(colorPlot[otherColor], plotId);
            end
        end
    end
    
    return colorPlot;
end

-- ===========================================================================
function ShowCitizenManagementLens(cityID:number)
    m_cityID = cityID;
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME);
    UILens.ToggleLayerOn(ML_LENS_LAYER);
end

-- ===========================================================================
function ClearCitizenManagementLens(clearBorder:boolean)
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER);
    end

    LuaEvents.MinimapPanel_SetActiveModLens("NONE");

    if (clearBorder == nil or clearBorder == true) then
        local pOverlay:object = UILens.GetOverlay("CityBorders");
        pOverlay:ClearPlotChannel();
        pOverlay:SetVisible(false);
    end

    m_cityID = -1;
end

-- ===========================================================================
function RefreshCitizenManagementLens(cityID:number)
    -- Do not redraw the border for the city, just refresh the tiles
    ClearCitizenManagementLens(false);
    ShowCitizenManagementLens(cityID);
end

-- ===========================================================================
function HideCitizenManagementLens()
    -- Hide the highlighted tiles, but don't clear the data
    if (m_cityID ~= -1 and UILens.IsLayerOn(ML_LENS_LAYER)) then
        UILens.ToggleLayerOff(ML_LENS_LAYER);
    end
end

-- ===========================================================================
function UnhideCitizenManagementLens()
    -- Unhides the highlighted tiles
    if (m_cityID ~= -1 and not UILens.IsLayerOn(ML_LENS_LAYER)) then
        UILens.ToggleLayerOn(ML_LENS_LAYER);
    end
end

-- ===========================================================================
local function CQUI_OnSettingsInitialized()
    UpdateLensConfiguredColors(m_LensSettings, nil, nil);
end

-- ===========================================================================
local function CQUI_OnSettingsUpdate()
    CQUI_OnSettingsInitialized();
end

-- ===========================================================================
local function OnInitialize()
    -- CQUI Handlers
    LuaEvents.CQUI_ShowCitizenManagement.Add( ShowCitizenManagementLens );
    LuaEvents.CQUI_RefreshCitizenManagement.Add( RefreshCitizenManagementLens );
    LuaEvents.CQUI_ClearCitizenManagement.Add( ClearCitizenManagementLens );
    LuaEvents.CQUI_HideCitizenManagementLens.Add( HideCitizenManagementLens );
    LuaEvents.CQUI_UnhideCitizenManagementLens.Add( UnhideCitizenManagementLens );
end

local CitizenManagementEntry = {
    LensButtonText = "LOC_HUD_CITIZEN_MANAGEMENT_LENS",
    LensButtonTooltip = "LOC_HUD_CITIZEN_MANAGEMENT_LENS_TOOLTIP",
    Initialize = OnInitialize,
    GetColorPlotTable = OnGetColorPlotTable
}

-- minimappanel.lua
if g_ModLenses ~= nil then
    g_ModLenses[LENS_NAME] = CitizenManagementEntry;
end

-- Add CQUI LuaEvent Hooks for minimappanel context
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
