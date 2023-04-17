include("LensSupport")
-- Note: Include for BuilderLens_Config and BuilderLens_Support occurs below, as supporting calls need to be added first
-- ==== BEGIN CQUI: Integration Modification =================================
-- CQUI: Allow Customized Color Scheme for Plots
-- Key: PN = Nothing    PD = Dangerous    P1 = Resources  P1B = Bonus  P1L = Luxury  P1S = Strategic    P2 = Recommended/Pillaged/Unique
--      P3 = Currently Worked / Wonder-Buffed    P4 = Hills    P5 = Feature Extraction    P6 = Nothing(Disabled)    P7 = General
local m_LensSettings = {
    ["COLOR_BUILDER_LENS_PN"]  =  { Index = 0x01, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_PN"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_PN" },
    ["COLOR_BUILDER_LENS_PD"]  =  { Index = 0x02, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_PD"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_PD" },
    -- Holder for all of the "P1" Resource colors, no actual color shown for P1 
    ["COLOR_BUILDER_LENS_P1"]  =  { Index = 0x10, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P1"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P1" },
    ["COLOR_BUILDER_LENS_P1B"] =  { Index = 0x11, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P1N"), ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P1B"},
    ["COLOR_BUILDER_LENS_P1L"] =  { Index = 0x12, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P1N"), ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P1L"},
    ["COLOR_BUILDER_LENS_P1S"] =  { Index = 0x13, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P1N"), ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P1S"},
    ["COLOR_BUILDER_LENS_P2"]  =  { Index = 0x20, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P2"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P2" },
    ["COLOR_BUILDER_LENS_P3"]  =  { Index = 0x30, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P3"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P3" },
    ["COLOR_BUILDER_LENS_P4"]  =  { Index = 0x40, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P4"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P4" },
    ["COLOR_BUILDER_LENS_P5"]  =  { Index = 0x50, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P5"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P5" },
    ["COLOR_BUILDER_LENS_P6"]  =  { Index = 0x60, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P6"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P6" },
    ["COLOR_BUILDER_LENS_P7"]  =  { Index = 0x70, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P7"),  ConfigRules = {}, KeyLabel = "LOC_HUD_BUILDER_LENS_P7" }
}

local m_LensSettings_SortedIndexMap = {}
for k,v in pairs(m_LensSettings) do
    table.insert(m_LensSettings_SortedIndexMap, {Index = m_LensSettings[k].Index, Key = k});
end
table.sort(m_LensSettings_SortedIndexMap, function(a,b) return a.Index < b.Index end)

local DISABLE_NOTHING_PLOT_HIGHLIGHT:boolean = true;
local AUTO_APPLY_BUILDER_LENS:boolean = true;
local DISABLE_DANGEROUS_PLOT_HIGHLIGHT:boolean = false;
local IGNORE_PLOT_COLOR:number = -2

-- ==== Functions called by the "include" Files
-- ===========================================================================
function GetColorForNothingPlot()
    if DISABLE_NOTHING_PLOT_HIGHLIGHT then
        return IGNORE_PLOT_COLOR;
    else
        return m_LensSettings["COLOR_BUILDER_LENS_PN"].ConfiguredColor;
    end
end

-- ===========================================================================
function GetIgnorePlotColor()
    return IGNORE_PLOT_COLOR;
end

-- ===========================================================================
function GetConfigRules(lensName)
    return m_LensSettings[lensName].ConfigRules;
end

-- ===========================================================================
function GetConfiguredColor(lensName)
    return m_LensSettings[lensName].ConfiguredColor;
end

-- ===========================================================================
-- Import config files for builder lens
include("BuilderLens_Config_", true)
-- ===========================================================================

local LENS_NAME = "ML_BUILDER"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

-- ==== BEGIN CQUI: Integration Modification =================================
-- ===========================================================================
local function CQUI_OnSettingsInitialized()
    -- Should the builder lens auto apply, when a builder is selected.
    AUTO_APPLY_BUILDER_LENS = GameConfiguration.GetValue("CQUI_AutoapplyBuilderLens");
    -- Disables the nothing color being highlted by the builder
    DISABLE_NOTHING_PLOT_HIGHLIGHT = GameConfiguration.GetValue("CQUI_BuilderLensDisableNothingPlot");
    -- Disables the dangerous plots highlted by the builder (barbs/military units at war with)
    DISABLE_DANGEROUS_PLOT_HIGHLIGHT = GameConfiguration.GetValue("CQUI_BuilderLensDisableDangerousPlot");
    UpdateLensConfiguredColors(m_LensSettings, g_ModLensModalPanel, LENS_NAME);
end

-- ===========================================================================
local function CQUI_OnSettingsUpdate()
    CQUI_OnSettingsInitialized();
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
    local fallbackColorIndex = GetColorForNothingPlot();
    colorPlot[fallbackColorIndex] = {}

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
            for _, lensEntry in ipairs(m_LensSettings_SortedIndexMap) do
                config = m_LensSettings[lensEntry.Key].ConfigRules
                if config ~= nil and table.count(config) > 0 then
                    for _, rule in ipairs(config) do
                        if rule ~= nil then
                            ruleColor = rule(pPlot)
                            if ruleColor ~= nil and ruleColor ~= -1 then
                                -- Catch special flag that says to completely ignore coloring
                                if ruleColor == IGNORE_PLOT_COLOR then
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
                table.insert(colorPlot[fallbackColorIndex], i)
            end
        end
    end

    if not DISABLE_DANGEROUS_PLOT_HIGHLIGHT then
        -- From hash build our colorPlot entry
        local pdLensIndex = m_LensSettings["COLOR_BUILDER_LENS_PD"].Index;
        colorPlot[pdLensIndex] = {}
        for iPlot, _ in pairs(dangerousPlotsHash) do
            table.insert(colorPlot[pdLensIndex], iPlot)
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
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER);
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE");
end

local function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, bSelected:boolean, bEditable:boolean )
    if not AUTO_APPLY_BUILDER_LENS then
        return
    end
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local unitType = GetUnitTypeFromIDs(playerID, unitID);
    if unitType ~= "UNIT_BUILDER" then
        return
    end

    if bSelected then
        ShowBuilderLens();
    -- Deselection
    else
        ClearBuilderLens();
    end
end

local function OnUnitChargesChanged( playerID: number, unitID : number, newCharges : number, oldCharges : number )
    if not AUTO_APPLY_BUILDER_LENS then
        return
    end
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local unitType = GetUnitTypeFromIDs(playerID, unitID);
    if unitType ~= "UNIT_BUILDER" then
        return
    end

    if newCharges == 0 then
        ClearBuilderLens();
    end
end

-- Multiplayer support for simultaneous turn captured builder
local function OnUnitCaptured( currentUnitOwner, unit, owningPlayer, capturingPlayer )
    if not AUTO_APPLY_BUILDER_LENS then
        return
    end
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local unitType = GetUnitTypeFromIDs(owningPlayer, unitID);
    if unitType ~= "UNIT_BUILDER" then
        return
    end

    ClearBuilderLens();
end

local function OnUnitRemovedFromMap( playerID: number, unitID : number )
    if not AUTO_APPLY_BUILDER_LENS then
        return
    end
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local lens = {}
    LuaEvents.MinimapPanel_GetActiveModLens(lens)
    if lens[1] == LENS_NAME then
        ClearBuilderLens();
    end
end

local function OnInitialize()
    Events.UnitSelectionChanged.Add( OnUnitSelectionChanged );
    Events.UnitCaptured.Add( OnUnitCaptured );
    Events.UnitChargesChanged.Add( OnUnitChargesChanged );
    Events.UnitRemovedFromMap.Add( OnUnitRemovedFromMap );
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
    g_ModLensModalPanel[LENS_NAME].Legend = {
        -- Insert only those with Rules that do coloring
        {m_LensSettings["COLOR_BUILDER_LENS_P1B"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P1B"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_P1L"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P1L"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_P1S"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P1S"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_P2"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P2"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_P3"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P3"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_P4"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P4"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_P5"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P5"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_P7"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_P7"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_PD"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_PD"].ConfiguredColor},
        {m_LensSettings["COLOR_BUILDER_LENS_PN"].KeyLabel, m_LensSettings["COLOR_BUILDER_LENS_PN"].ConfiguredColor},
    }
end

-- Add CQUI LuaEvent Hooks for minimappanel and modallenspanel contexts
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
