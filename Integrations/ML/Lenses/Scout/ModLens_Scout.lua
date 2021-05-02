local LENS_NAME = "ML_SCOUT"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

-- Should the scout lens auto apply, when a scout/ranger is selected.
local AUTO_APPLY_SCOUT_LENS:boolean = GameConfiguration.GetValue("ML_AutoApplyScoutLens")
local AUTO_APPLY_SCOUT_LENS_EXTRA:boolean = GameConfiguration.GetValue("ML_AutoApplyScoutLensExtra")

-- ===========================================================================
-- Scout Lens Support
-- ===========================================================================

local function plotHasGoodyHut(plot)
    local improvementInfo = GameInfo.Improvements[plot:GetImprovementType()]
    if improvementInfo ~= nil and improvementInfo.ImprovementType == "IMPROVEMENT_GOODY_HUT" then
        return true
    end
    return false
end

-- ===========================================================================
-- Exported functions
-- ===========================================================================

local function OnGetColorPlotTable()
    -- print("Show scout lens")
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer   :number = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local GoodyHutColor   :number = UI.GetColorValue("COLOR_GHUT_SCOUT_LENS")
    local colorPlot = {}
    colorPlot[GoodyHutColor] = {}

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            if plotHasGoodyHut(pPlot) then
                table.insert(colorPlot[GoodyHutColor], i)
            end
        end
    end

    return colorPlot
end

-- Called when a scout is selected
local function ShowScoutLens()
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearScoutLens()
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER)
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE")
end

local function RefreshScoutLens()
    ClearScoutLens()
    ShowScoutLens()
end

local function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, bSelected:boolean, bEditable:boolean )
    if playerID == Game.GetLocalPlayer() and (AUTO_APPLY_SCOUT_LENS or AUTO_APPLY_SCOUT_LENS_EXTRA) then
        local pPlayer = Players[playerID]
        local pUnit = pPlayer:GetUnits():FindID(unitID)
        local unitType = pUnit:GetUnitType()
        if unitType ~= -1 and GameInfo.Units[unitType] ~= nil then
            local promotionClass = GameInfo.Units[unitType].PromotionClass
            local unitDomain = GameInfo.Units[unitType].Domain
            local militaryUnit = (pUnit:GetCombat() > 0 or pUnit:GetRangedCombat() > 0) and (unitDomain == "DOMAIN_LAND")
            if bSelected then
                if militaryUnit and AUTO_APPLY_SCOUT_LENS_EXTRA then
                    ShowScoutLens()
                elseif promotionClass == "PROMOTION_CLASS_RECON" then
                    ShowScoutLens()
                end
            -- Deselection
            else
                if militaryUnit and AUTO_APPLY_SCOUT_LENS_EXTRA then
                    ClearScoutLens()
                elseif promotionClass == "PROMOTION_CLASS_RECON" then
                    ClearScoutLens()
                end
            end
        end
    end
end

local function OnUnitRemovedFromMap( playerID: number, unitID : number )
    if playerID == Game.GetLocalPlayer() and (AUTO_APPLY_SCOUT_LENS or AUTO_APPLY_SCOUT_LENS_EXTRA) then
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            ClearScoutLens()
        end
    end
end

local function OnUnitMoveComplete( playerID:number, unitID:number )
    if playerID == Game.GetLocalPlayer() and (AUTO_APPLY_SCOUT_LENS or AUTO_APPLY_SCOUT_LENS_EXTRA) then
        local pPlayer = Players[playerID]
        local pUnit = pPlayer:GetUnits():FindID(unitID)
        -- Ensure the unit is selected. Scout could be exploring automated
        if UI.IsUnitSelected(pUnit) then
            local unitType = pUnit:GetUnitType()
            if unitType ~= -1 and GameInfo.Units[unitType] ~= nil then
                local promotionClass = GameInfo.Units[unitType].PromotionClass
                local unitDomain = GameInfo.Units[unitType].Domain
                local militaryUnit = (pUnit:GetCombat() > 0 or pUnit:GetRangedCombat() > 0) and (unitDomain == "DOMAIN_LAND")
                if militaryUnit and AUTO_APPLY_SCOUT_LENS_EXTRA then
                    RefreshScoutLens()
                elseif promotionClass == "PROMOTION_CLASS_RECON" then
                    RefreshScoutLens()
                end
            end
        end
    end
end

local function OnGoodyHutReward( playerID:number )
    if playerID == Game.GetLocalPlayer() and (AUTO_APPLY_SCOUT_LENS or AUTO_APPLY_SCOUT_LENS_EXTRA) then
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            RefreshScoutLens()
        end
    end
end

local function OnLensSettingsUpdate()
    -- Refresh our local settings from updated GameConfig
    AUTO_APPLY_SCOUT_LENS = GameConfiguration.GetValue("ML_AutoApplyScoutLens")
    AUTO_APPLY_SCOUT_LENS_EXTRA = GameConfiguration.GetValue("ML_AutoApplyScoutLensExtra")
end

local function OnInitialize()
    Events.UnitSelectionChanged.Add( OnUnitSelectionChanged )
    Events.UnitRemovedFromMap.Add( OnUnitRemovedFromMap )
    Events.UnitMoveComplete.Add( OnUnitMoveComplete )
    Events.GoodyHutReward.Add( OnGoodyHutReward )
    LuaEvents.ML_SettingsUpdate.Add( OnLensSettingsUpdate )
end

local ScoutLensEntry = {
    LensButtonText = "LOC_HUD_SCOUT_LENS",
    LensButtonTooltip = "LOC_HUD_SCOUT_LENS_TOOLTIP",
    Initialize = OnInitialize,
    GetColorPlotTable = OnGetColorPlotTable
}

-- minimappanel.lua
if g_ModLenses ~= nil then
    g_ModLenses[LENS_NAME] = ScoutLensEntry
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[LENS_NAME] = {}
    g_ModLensModalPanel[LENS_NAME].LensTextKey = "LOC_HUD_SCOUT_LENS"
    g_ModLensModalPanel[LENS_NAME].Legend = {
        {"LOC_TOOLTIP_SCOUT_LENS_GHUT", UI.GetColorValue("COLOR_GHUT_SCOUT_LENS")}
    }
end
