include("LensSupport")
print("LOADFILE: ModLens_Builder")
local m_BuilderLens_PN =  UI.GetColorValue("COLOR_BUILDER_LENS_PN")
local m_BuilderLens_PD =  UI.GetColorValue("COLOR_BUILDER_LENS_PD")
local m_BuilderLens_P1 =  UI.GetColorValue("COLOR_BUILDER_LENS_P1")
local m_BuilderLens_P1N = UI.GetColorValue("COLOR_BUILDER_LENS_P1N")
local m_BuilderLens_P2 =  UI.GetColorValue("COLOR_BUILDER_LENS_P2")
local m_BuilderLens_P3 =  UI.GetColorValue("COLOR_BUILDER_LENS_P3")
local m_BuilderLens_P4 =  UI.GetColorValue("COLOR_BUILDER_LENS_P4")
local m_BuilderLens_P5 =  UI.GetColorValue("COLOR_BUILDER_LENS_P5")
local m_BuilderLens_P6 =  UI.GetColorValue("COLOR_BUILDER_LENS_P6")
local m_BuilderLens_P7 =  UI.GetColorValue("COLOR_BUILDER_LENS_P7")

local m_FallbackColor = m_BuilderLens_PN

local m_ModLenses_Builder_Priority = {
    m_BuilderLens_PN,
    m_BuilderLens_PD,
    m_BuilderLens_P1,
    m_BuilderLens_P2,
    m_BuilderLens_P3,
    m_BuilderLens_P4,
    m_BuilderLens_P5,
    m_BuilderLens_P6,
    m_BuilderLens_P7,
}

g_ModLenses_Builder_Config = {
    [m_BuilderLens_PN] = {},
    [m_BuilderLens_PD] = {},
    [m_BuilderLens_P1] = {},
    [m_BuilderLens_P2] = {},
    [m_BuilderLens_P3] = {},
    [m_BuilderLens_P4] = {},
    [m_BuilderLens_P5] = {},
    [m_BuilderLens_P6] = {},
    [m_BuilderLens_P7] = {},
}

-- Import config files for builder lens
include("BuilderLens_Config_", true)

local LENS_NAME = "ML_BUILDER"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

local AUTO_APPLY_BUILDER_LENS:boolean = true;
local DISABLE_NOTHING_PLOT_HIGHLIGHT:boolean = true;
local DISABLE_DANGEROUS_PLOT_HIGHLIGHT:boolean = false;

-- ==== BEGIN CQUI: Integration Modification =================================
function CQUI_OnSettingsUpdate()
    -- Should the builder lens auto apply, when a builder is selected.
    AUTO_APPLY_BUILDER_LENS = GameConfiguration.GetValue("CQUI_AutoapplyBuilderLens");
    -- Disables the nothing color being highlted by the builder
    DISABLE_NOTHING_PLOT_HIGHLIGHT = GameConfiguration.GetValue("CQUI_BuilderLensDisableNothingPlot");
    -- Disables the dangerous plots highlted by the builder (barbs/military units at war with)
    DISABLE_DANGEROUS_PLOT_HIGHLIGHT = GameConfiguration.GetValue("CQUI_BuilderLensDisableDangerousPlot");
end
-- ==== END CQUI: Integration Modification ===================================

-- ===========================================================================
-- Exported functions
-- ===========================================================================

local function OnGetColorPlotTable()
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer:number = Game.GetLocalPlayer()
    local pPlayer:table = Players[localPlayer]
    local localPlayerVis:table = PlayersVisibility[localPlayer]
    local pDiplomacy:table = pPlayer:GetDiplomacy()

    local colorPlot:table = {}
    local dangerousPlotsHash:table = {}
    colorPlot[m_FallbackColor] = {}

    if not DISABLE_DANGEROUS_PLOT_HIGHLIGHT then
        -- Make hash of all dangerous plots
        for i = 0, (mapWidth * mapHeight) - 1, 1 do
            local pPlot:table = Map.GetPlotByIndex(i)
            if localPlayerVis:IsVisible(pPlot:GetX(), pPlot:GetY()) then
                local pUnitList = Map.GetUnitsAt(pPlot:GetIndex());
                if pUnitList ~= nil then
                    for pUnit in pUnitList:Units() do
                        local unitInfo:table = GameInfo.Units[pUnit:GetUnitType()]
                        -- Only consider military units
                        if (unitInfo.MakeTradeRoute == nil or unitInfo.MakeTradeRoute == false) and (pUnit:GetCombat() > 0 or pUnit:GetRangedCombat() > 0) then
                            -- Check if we are at with the owner of this unit, or it is a barbarian
                            local iUnitOwner = pUnit:GetOwner()
                            local pUnitOwner = Players[iUnitOwner]
                            if pDiplomacy:IsAtWarWith(iUnitOwner) or pUnitOwner:IsBarbarian() then
                                -- Since units movements points refresh at start of turn, you can have units with 0 movements left
                                -- when the below function is called. Making the dangerous plots incorrect, since the next turn the dangerous
                                -- unit can capture our builder
                                --[[
                                local kMovePlots = UnitManager.GetReachableMovement(pUnit)
                                for _, iPlot in ipairs(kMovePlots) do
                                    dangerousPlotsHash[iPlot] = true
                                end
                                ]]
                                -- So next best is to highlight the unit's plot and all adjacent plots
                                for pAdjPlot in PlotAreaSpiralIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, CENTRE_INCLUDE) do
                                    if pAdjPlot:GetOwner() == localPlayer then
                                        dangerousPlotsHash[pAdjPlot:GetIndex()] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if dangerousPlotsHash[i] == nil and localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            local bPlotColored:boolean = false
            for _, color in ipairs(m_ModLenses_Builder_Priority) do
                config = g_ModLenses_Builder_Config[color]
                if config ~= nil and table.count(config) > 0 then
                    for _, rule in ipairs(config) do
                        if rule ~= nil then
                            ruleColor = rule(pPlot)
                            if ruleColor ~= nil and ruleColor ~= -1 then
                                -- Catch special flag that says to completely ignore coloring
                                if ruleColor == -2 then
                                    bPlotColored = true
                                    break
                                end

                                if colorPlot[ruleColor] == nil then
                                    colorPlot[ruleColor] = {}
                                end

                                table.insert(colorPlot[ruleColor], i)
                                bPlotColored = true
                                break
                            end
                        end
                    end
                end

                if bPlotColored then
                    break
                end
            end

            if not bPlotColored and pPlot:GetOwner() == localPlayer then
                table.insert(colorPlot[m_FallbackColor], i)
            end
        end
    end

    if DISABLE_NOTHING_PLOT_HIGHLIGHT then
        colorPlot[m_BuilderLens_PN] = nil
    end

    if not DISABLE_DANGEROUS_PLOT_HIGHLIGHT then
        -- From hash build our colorPlot entry
        colorPlot[m_BuilderLens_PD] = {}
        for iPlot, _ in pairs(dangerousPlotsHash) do
            table.insert(colorPlot[m_BuilderLens_PD], iPlot)
        end
    end

    return colorPlot
end

-- Called when a builder is selected
local function ShowBuilderLens()
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearBuilderLens()
    -- print("Clearing builder lens")
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER);
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE");
end

local function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, bSelected:boolean, bEditable:boolean )
    if AUTO_APPLY_BUILDER_LENS and playerID == Game.GetLocalPlayer() then
        local unitType = GetUnitTypeFromIDs(playerID, unitID);
        if bSelected then
            if unitType == "UNIT_BUILDER" then
                ShowBuilderLens();
            end
        -- Deselection
        else
            if unitType == "UNIT_BUILDER" then
                ClearBuilderLens();
            end
        end
    end
end

local function OnUnitChargesChanged( playerID: number, unitID : number, newCharges : number, oldCharges : number )
    if AUTO_APPLY_BUILDER_LENS and playerID == Game.GetLocalPlayer() then
        local unitType = GetUnitTypeFromIDs(playerID, unitID)
        if unitType == "UNIT_BUILDER" then
            if newCharges == 0 then
                ClearBuilderLens();
            end
        end
    end
end

-- Multiplayer support for simultaneous turn captured builder
local function OnUnitCaptured( currentUnitOwner, unit, owningPlayer, capturingPlayer )
    if AUTO_APPLY_BUILDER_LENS and owningPlayer == Game.GetLocalPlayer() then
        local unitType = GetUnitTypeFromIDs(owningPlayer, unitID)
        if unitType == "UNIT_BUILDER" then
            ClearBuilderLens();
        end
    end
end

local function OnUnitRemovedFromMap( playerID: number, unitID : number )
    if AUTO_APPLY_BUILDER_LENS and playerID == Game.GetLocalPlayer() then
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            ClearBuilderLens();
        end
    end
end

local function OnInitialize()
    Events.UnitSelectionChanged.Add( OnUnitSelectionChanged );
    Events.UnitCaptured.Add( OnUnitCaptured );
    Events.UnitChargesChanged.Add( OnUnitChargesChanged );
    Events.UnitRemovedFromMap.Add( OnUnitRemovedFromMap );
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end

local BuilderLensEntry = {
    LensButtonText = "LOC_HUD_BUILDER_LENS",
    LensButtonTooltip = "LOC_HUD_BUILDER_LENS_TOOLTIP",
    Initialize = OnInitialize,
    GetColorPlotTable = OnGetColorPlotTable
}

-- minimappanel.lua
if g_ModLenses ~= nil then
    g_ModLenses[LENS_NAME] = BuilderLensEntry
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[LENS_NAME] = {}
    g_ModLensModalPanel[LENS_NAME].LensTextKey = "LOC_HUD_BUILDER_LENS"

    -- TODO: Make this automatic based on added rules
    g_ModLensModalPanel[LENS_NAME].Legend = {
        {"LOC_HUD_BUILDER_LENS_PN", m_BuilderLens_PN},
        {"LOC_HUD_BUILDER_LENS_PD", m_BuilderLens_PD},
        {"LOC_HUD_BUILDER_LENS_P1", m_BuilderLens_P1},
        {"LOC_HUD_BUILDER_LENS_P1N", m_BuilderLens_P1N},
        {"LOC_HUD_BUILDER_LENS_P2", m_BuilderLens_P2},
        {"LOC_HUD_BUILDER_LENS_P3", m_BuilderLens_P3},
        {"LOC_HUD_BUILDER_LENS_P4", m_BuilderLens_P4},
        {"LOC_HUD_BUILDER_LENS_P5", m_BuilderLens_P5},
        -- {"LOC_HUD_BUILDER_LENS_P6", m_BuilderLens_P6},
        {"LOC_HUD_BUILDER_LENS_P7", m_BuilderLens_P7},
    }
end
