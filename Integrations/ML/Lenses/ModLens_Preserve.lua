include("LensSupport")

local PRESERVELENS_NAME = "ML_PRESERVE"
local PRESERVEML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

-- ===========================================================================
--  Exported functions
-- ===========================================================================

local function PreserveOnGetColorPlotTable()
    local mapWidth, mapHeight = Map.GetGridSize()

    --Initiate Color Plot with 6 colors
    local colorPlot:table = {}
    local colors = {}
    for i = 1, 7, 1 do
        local colorLookup:string = "COLOR_GRADIENT8_" .. tostring(i)
        print("color lookup", colorLookup)
        local color:number = UI.GetColorValue(colorLookup)
        table.insert(colors, color)
        print("initializing color", color)
        colorPlot[color] = {}
    end

    for i = 0, (mapWidth * mapHeight) - 1, 1 do -- for every plot on the map
        local pPlot:table = Map.GetPlotByIndex(i)
        local localPlayer   :number = Game.GetLocalPlayer()
        local localPlayerVis:table = PlayersVisibility[localPlayer]
        local plotX = pPlot:GetX()
        local plotY = pPlot:GetY()

        if localPlayerVis:IsRevealed(plotX, plotY) and not pPlot:IsMountain() and not pPlot:IsWater() then
            local totalScore = 1;

            -- check surrounding locations
            for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
                local checkPlot = Map.GetAdjacentPlot(pPlot:GetX(), pPlot:GetY(), direction)
                if checkPlot and localPlayerVis:IsRevealed(plotX, plotY) and not checkPlot:IsMountain() then 
                    -- Charming = 2+, Breathtaking = 4+
                    -- Preserve improves appeal by 1, so we are looking for tiles with appeal >= 1, or >=3
                    -- Using some arbitrary scoring logic here to map to <= 8 levels of colors. Total possible score here would be 6*1 = 6
                    
                    if(checkPlot:GetAppeal() > 2) then
                        totalScore = totalScore + 1
                    elseif(checkPlot:GetAppeal() > 0) then
                        totalScore = totalScore + 0.5
                    end
                end
            end

            local color = colors[math.floor(totalScore)]
            table.insert(colorPlot[color], i);
        end
    end

    return colorPlot
end

-- ===========================================================================
--  Init
-- ===========================================================================
local PreserveLensEntry = {
    LensButtonText = "LOC_HUD_PRESERVE_LENS",
    LensButtonTooltip = "LOC_HUD_PRESERVE_LENS_TOOLTIP",
    Initialize = nil,
    GetColorPlotTable = PreserveOnGetColorPlotTable
}

print("LOAD ModLens_Preserve.lua in ModLens_Wonder.lua")
-- minimappanel.lua
if g_ModLenses ~= nil then
    g_ModLenses[PRESERVELENS_NAME] = PreserveLensEntry
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[PRESERVELENS_NAME] = {}
    g_ModLensModalPanel[PRESERVELENS_NAME].LensTextKey = "LOC_HUD_PRESERVE_LENS"
    g_ModLensModalPanel[PRESERVELENS_NAME].Legend = {
        {"LOC_TOOLTIP_WONDER_LENS_NWONDER", UI.GetColorValue("COLOR_NATURAL_WONDER_LENS")},
        {"LOC_TOOLTIP_RESOURCE_LENS_PWONDER", UI.GetColorValue("COLOR_PLAYER_WONDER_LENS")}
    }
end


