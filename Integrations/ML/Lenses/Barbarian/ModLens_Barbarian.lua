include("LensSupport")
local LENS_NAME = "ML_BARBARIAN"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

local m_LensSettings = {
    ["COLOR_BARBARIAN_LENS_ENCAMPMENT"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_BARBARIAN_LENS_ENCAMPMENT"), KeyLabel = "LOC_HUD_BARBARIAN_LENS_ENCAMPMENT" }
}

-- ===========================================================================
-- Barbarian Lens Support
-- ===========================================================================

local function plotHasBarbCamp(pPlot:table)
    local improvementInfo = GameInfo.Improvements[pPlot:GetImprovementType()]
    if improvementInfo ~= nil and improvementInfo.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP" then
        return true
    end
    return false
end

-- ===========================================================================
-- Exported functions
-- ===========================================================================

local function OnGetColorPlotTable()
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer   :number = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local BarbarianColor = m_LensSettings["COLOR_BARBARIAN_LENS_ENCAMPMENT"].ConfiguredColor
    local IgnoreColor = UI.GetColorValue("COLOR_MORELENSES_GREY")
    local colorPlot:table = {}
    colorPlot[BarbarianColor] = {}
    colorPlot[IgnoreColor] = {}

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            if plotHasBarbCamp(pPlot) then
                table.insert(colorPlot[BarbarianColor], i)
            else
                table.insert(colorPlot[IgnoreColor], i)
            end
        end
    end

    return colorPlot
end

--[[
local function ShowBarbarianLens()
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearBarbarianLens()
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER)
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE")
end

local function OnInitialize()
    -- Nothing to do
end

]]

local BarbarianLensEntry = {
    LensButtonText = "LOC_HUD_BARBARIAN_LENS",
    LensButtonTooltip = "LOC_HUD_BARBARIAN_LENS_TOOLTIP",
    Initialize = nil,
    GetColorPlotTable = OnGetColorPlotTable
}

-- ===========================================================================
local function CQUI_OnSettingsInitialized()
    UpdateLensConfiguredColors(m_LensSettings, g_ModLensModalPanel, LENS_NAME);
end

-- ===========================================================================
local function CQUI_OnSettingsUpdate()
    CQUI_OnSettingsInitialized();
end

-- minimappanel.lua
if g_ModLenses ~= nil then
    g_ModLenses[LENS_NAME] = BarbarianLensEntry
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[LENS_NAME] = {}
    g_ModLensModalPanel[LENS_NAME].LensTextKey = "LOC_HUD_BARBARIAN_LENS"
    g_ModLensModalPanel[LENS_NAME].Legend = {
        {m_LensSettings["COLOR_BARBARIAN_LENS_ENCAMPMENT"].KeyLabel, m_LensSettings["COLOR_BARBARIAN_LENS_ENCAMPMENT"].ConfiguredColor}
    }
end

-- Add CQUI LuaEvent Hooks for minimappanel and modallenspanel contexts
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);