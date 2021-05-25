include("LensSupport")

local LENS_NAME = "ML_WONDER"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")
local m_LensSettings = {
    ["COLOR_WONDER_LENS_NATURAL"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_WONDER_LENS_NATURAL"), KeyLabel = "LOC_HUD_WONDER_LENS_NATURAL" },
    ["COLOR_WONDER_LENS_PLAYER"]  =  { ConfiguredColor = GetLensColorFromSettings("COLOR_WONDER_LENS_PLAYER"),  KeyLabel = "LOC_HUD_WONDER_LENS_PLAYER" }
}

-- ===========================================================================
-- Wonder Lens Support
-- ===========================================================================

-- ===========================================================================
-- Exported functions
-- ===========================================================================

local function OnGetColorPlotTable()
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer   :number = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local NaturalWonderColor  :number = m_LensSettings["COLOR_WONDER_LENS_NATURAL"].ConfiguredColor
    local PlayerWonderColor   :number = m_LensSettings["COLOR_WONDER_LENS_PLAYER"].ConfiguredColor
    local IgnoreColor = UI.GetColorValue("COLOR_MORELENSES_GREY")
    local colorPlot:table = {}
    colorPlot[NaturalWonderColor] = {}
    colorPlot[PlayerWonderColor] = {}
    colorPlot[IgnoreColor] = {}

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            -- check for player wonder.
            if plotHasWonder(pPlot) then
                table.insert(colorPlot[PlayerWonderColor], i)
            else
                -- Check for natural wonder
                local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
                if featureInfo ~= nil and featureInfo.NaturalWonder then
                    table.insert(colorPlot[NaturalWonderColor], i)
                else
                    table.insert(colorPlot[IgnoreColor], i)
                end
            end
        end
    end

    return colorPlot
end

--[[
local function ShowWonderLens()
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearWonderLens()
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER)
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE")
end

local function OnInitialize()
    -- Nothing to do
end
]]

-- ===========================================================================
local function CQUI_OnSettingsInitialized()
    UpdateLensConfiguredColors(m_LensSettings, g_ModLensModalPanel, LENS_NAME);
end

-- ===========================================================================
local function CQUI_OnSettingsUpdate()
    CQUI_OnSettingsInitialized();
end

local WonderLensEntry = {
    LensButtonText = "LOC_HUD_WONDER_LENS",
    LensButtonTooltip = "LOC_HUD_WONDER_LENS_TOOLTIP",
    Initialize = nil,
    GetColorPlotTable = OnGetColorPlotTable
}

-- minimappanel.lua
if g_ModLenses ~= nil then
    g_ModLenses[LENS_NAME] = WonderLensEntry
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[LENS_NAME] = {}
    g_ModLensModalPanel[LENS_NAME].LensTextKey = "LOC_HUD_WONDER_LENS"
    g_ModLensModalPanel[LENS_NAME].Legend = {
        {m_LensSettings["COLOR_WONDER_LENS_NATURAL"].KeyLabel, m_LensSettings["COLOR_WONDER_LENS_NATURAL"].ConfiguredColor},
        {m_LensSettings["COLOR_WONDER_LENS_PLAYER"].KeyLabel, m_LensSettings["COLOR_WONDER_LENS_PLAYER"].ConfiguredColor}
    }
end

-- Add CQUI LuaEvent Hooks for minimappanel and modallenspanel contexts
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
