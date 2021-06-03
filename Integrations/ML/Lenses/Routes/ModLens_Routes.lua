include("LensSupport")
-- CQUI-made Lens to show Road and Rail network
local LENS_NAME = "ML_ROUTES"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")
local m_LensSettings = {
    ["COLOR_ROUTES_LENS_ROAD"] = { ConfiguredColor = GetLensColorFromSettings("COLOR_ROUTES_LENS_ROAD"), KeyLabel = "LOC_HUD_ROUTES_LENS_ROAD" },
    ["COLOR_ROUTES_LENS_RAIL"] = { ConfiguredColor = GetLensColorFromSettings("COLOR_ROUTES_LENS_RAIL"),  KeyLabel = "LOC_HUD_ROUTES_LENS_RAIL" }
}

-- Should the archaeologist lens auto apply, when a archaeologist is selected.
local AUTO_APPLY_ENGINEER_LENS:boolean = false

-- ===========================================================================
-- Routes (Road and Rail) Lens Support
-- ===========================================================================

local function OnGetColorPlotTable()
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer   :number = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local RoadColor    :number = m_LensSettings["COLOR_ROUTES_LENS_ROAD"].ConfiguredColor
    local RailColor    :number = m_LensSettings["COLOR_ROUTES_LENS_RAIL"].ConfiguredColor

    local colorPlot:table = {}
    colorPlot[RoadColor] = {}
    colorPlot[RailColor] = {}
-- so what happens when plot has both rail and harbor?  this should just be road and rail shouldn't it

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            routeType = pPlot:GetRouteType();
            if routeType ~= -1 then
                if GameInfo.Routes[routeType].RouteType == "ROUTE_RAILROAD" then
                    table.insert(colorPlot[RailColor], i);
                else -- it must be one of the road types
                    table.insert(colorPlot[RoadColor], i);
                end
            end
        end
    end

    return colorPlot
end

-- ===========================================================================
local function ShowRoutesLens()
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

-- ===========================================================================
local function ClearRoutesLens()
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER)
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE")
end

-- ===========================================================================
local function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, bSelected:boolean, bEditable:boolean )
    if playerID == Game.GetLocalPlayer() then
        local unitType = GetUnitTypeFromIDs(playerID, unitID)
        if unitType then
            if bSelected then
                if unitType == "UNIT_MILITARY_ENGINEER" and AUTO_APPLY_ENGINEER_LENS then
                    ShowRoutesLens()
                end
            -- Deselection
            else
                if unitType == "UNIT_MILITARY_ENGINEER" and AUTO_APPLY_ENGINEER_LENS then
                    ClearRoutesLens()
                end
            end
        end
    end
end

-- ===========================================================================
local function OnUnitRemovedFromMap( playerID: number, unitID : number )
    local localPlayer = Game.GetLocalPlayer()
    local lens = {}
    LuaEvents.MinimapPanel_GetActiveModLens(lens)
    if playerID == localPlayer then
        if lens[1] == LENS_NAME and AUTO_APPLY_ENGINEER_LENS then
            ClearRoutesLens()
        end
    end
end

-- ===========================================================================
-- For modded lens during multiplayer. Might need to test this further
function OnUnitCaptured( currentUnitOwner, unit, owningPlayer, capturingPlayer )
    local localPlayer = Game.GetLocalPlayer()
    if owningPlayer == localPlayer then
        local unitType = GetUnitTypeFromIDs(owningPlayer, unitID)
        if unitType and unitType == "UNIT_MILITARY_ENGINEER" and AUTO_APPLY_ENGINEER_LENS then
            ClearRoutesLens()
        end
    end
end

-- ===========================================================================
local function OnInitialize()
    Events.UnitSelectionChanged.Add( OnUnitSelectionChanged )
    Events.UnitRemovedFromMap.Add( OnUnitRemovedFromMap )
    Events.UnitCaptured.Add( OnUnitCaptured )
end

-- ===========================================================================
local function CQUI_OnSettingsInitialized()
    AUTO_APPLY_ENGINEER_LENS = GameConfiguration.GetValue("CQUI_AutoapplyEngineerLens");
    UpdateLensConfiguredColors(m_LensSettings, g_ModLensModalPanel, LENS_NAME);
end

-- ===========================================================================
local function CQUI_OnSettingsUpdate()
    CQUI_OnSettingsInitialized();
end

local RoutesLensEntry = {
    LensButtonText = "LOC_HUD_ROUTES_LENS",
    LensButtonTooltip = "LOC_HUD_ROUTES_LENS_TOOLTIP",
    Initialize = OnInitialize,
    GetColorPlotTable = OnGetColorPlotTable
}

-- minimappanel.lua
if g_ModLenses ~= nil then
    g_ModLenses[LENS_NAME] = RoutesLensEntry
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[LENS_NAME] = {}
    g_ModLensModalPanel[LENS_NAME].LensTextKey = "LOC_HUD_ROUTES_LENS"
    g_ModLensModalPanel[LENS_NAME].Legend = {
        {m_LensSettings["COLOR_ROUTES_LENS_ROAD"].KeyLabel, m_LensSettings["COLOR_ROUTES_LENS_ROAD"].ConfiguredColor},
        {m_LensSettings["COLOR_ROUTES_LENS_RAIL"].KeyLabel, m_LensSettings["COLOR_ROUTES_LENS_RAIL"].ConfiguredColor}
    }
end

-- Add CQUI LuaEvent Hooks for minimappanel and modallenspanel contexts
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
