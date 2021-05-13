include("LensSupport")

local LENS_NAME = "ML_WONDER"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")
local m_ModLenses_Wonder_Lenses = {
    ["COLOR_WONDER_LENS_NATURAL"] =  { Index = 0x01, ConfiguredColor = GetLensColorFromSettings("COLOR_WONDER_LENS_NATURAL"),  ConfigRules = {}, LocName = "LOC_HUD_WONDER_LENS_NATURAL" },
    ["COLOR_WONDER_LENS_PLAYER"]  =  { Index = 0x02, ConfiguredColor = GetLensColorFromSettings("COLOR_WONDER_LENS_PLAYER"),   ConfigRules = {}, LocName = "LOC_HUD_WONDER_LENS_PLAYER" }
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

    local NaturalWonderColor  :number = GetLensColorFromSettings("COLOR_WONDER_LENS_NATURAL")
    local PlayerWonderColor   :number = GetLensColorFromSettings("COLOR_WONDER_LENS_PLAYER")
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

function CQUI_ModLens_Wonder_OnSettingsInitialized()
    UpdateLensConfiguredColors(m_ModLenses_Wonder_Lenses, g_ModLensModalPanel, LENS_NAME);
end

-- ===========================================================================
function CQUI_ModLens_Wonder_OnSettingsUpdate()
    CQUI_ModLens_Wonder_OnSettingsInitialized();
end

local function CQUI_SettingsPanelClosed()
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        -- Hide and show the builder lens to update the coloring
        ClearBuilderLens();
        ShowBuilderLens();
    end
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
    -- We only get into this code path via the Include call in minimappanel.lua
    -- Add the settings callback hooks for that minimappanel context
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_ModLens_Wonder_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_ModLens_Wonder_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsPanelClosed.Add(CQUI_SettingsPanelClosed);
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[LENS_NAME] = {}
    g_ModLensModalPanel[LENS_NAME].LensTextKey = "LOC_HUD_WONDER_LENS"
    g_ModLensModalPanel[LENS_NAME].Legend = {
        {m_ModLenses_Wonder_Lenses["COLOR_WONDER_LENS_NATURAL"].LocName, m_ModLenses_Wonder_Lenses["COLOR_WONDER_LENS_NATURAL"].ConfiguredColor},
        {m_ModLenses_Wonder_Lenses["COLOR_WONDER_LENS_PLAYER"].LocName, m_ModLenses_Wonder_Lenses["COLOR_WONDER_LENS_PLAYER"].ConfiguredColor}
    }
    -- We only get into this code path via the Include call in modallenspanel.lua
    -- Add the settings callback hooks for that modallenspanel context
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_ModLens_Wonder_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_ModLens_Wonder_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsPanelClosed.Add(CQUI_SettingsPanelClosed);
end
