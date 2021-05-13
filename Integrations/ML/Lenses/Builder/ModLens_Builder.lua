include("LensSupport")
print("LOADFILE: ModLens_Builder")
-- ==== BEGIN CQUI: Integration Modification =================================
-- CQUI: Allow Customized Color Scheme for Plots
-- Builder Lens Colors can be configured from the Settings menu
-- TODO: Color for other lenses, some way to save/load these values in Game setup

-- CQUI Change: these values, used as indexes in the g_ModLenses_Builder_Config table, are now static
-- Key: PN = Nothing    PD = Dangerous    P1 = Resources    P1N = Resources Outside Range    P2 = Recommended/Pillaged/Unique
--      P3 = Currently Worked / Wonder-Buffed    P4 = Hills    P5 = Feature Extraction    P6 = Nothing(Disabled)    P7 = General
g_ModLenses_Builder_Lenses = {
    ["COLOR_BUILDER_LENS_PN"]  =  { Index = 0x01, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_PN"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_PN" },
    ["COLOR_BUILDER_LENS_PD"]  =  { Index = 0x02, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_PD"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_PD" },
    ["COLOR_BUILDER_LENS_P1"]  =  { Index = 0x10, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P1"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P1" },
    ["COLOR_BUILDER_LENS_P1N"] =  { Index = 0x11, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P1N"), ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P1N"},
    ["COLOR_BUILDER_LENS_P2"]  =  { Index = 0x20, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P2"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P2" },
    ["COLOR_BUILDER_LENS_P3"]  =  { Index = 0x30, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P3"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P3" },
    ["COLOR_BUILDER_LENS_P4"]  =  { Index = 0x40, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P4"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P4" },
    ["COLOR_BUILDER_LENS_P5"]  =  { Index = 0x50, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P5"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P5" },
    ["COLOR_BUILDER_LENS_P6"]  =  { Index = 0x60, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P6"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P6" },
    ["COLOR_BUILDER_LENS_P7"]  =  { Index = 0x70, ConfiguredColor = GetLensColorFromSettings("COLOR_BUILDER_LENS_P7"),  ConfigRules = {}, LocName = "LOC_HUD_BUILDER_LENS_P7" }
}

g_ModLenses_Builder_Lenses_SortedIndexMap = {}
for k,v in pairs(g_ModLenses_Builder_Lenses) do
    table.insert(g_ModLenses_Builder_Lenses_SortedIndexMap, {Index = g_ModLenses_Builder_Lenses[k].Index, Key = k});
end
table.sort(g_ModLenses_Builder_Lenses_SortedIndexMap, function(a,b) return a.Index < b.Index end)

local DISABLE_NOTHING_PLOT_HIGHLIGHT:boolean = true;
local AUTO_APPLY_BUILDER_LENS:boolean = true;
local DISABLE_DANGEROUS_PLOT_HIGHLIGHT:boolean = false;
local IGNORE_PLOT_COLOR:number = -2

--------------------------------------
function GetColorForNothingPlot()
    if DISABLE_NOTHING_PLOT_HIGHLIGHT then
        return IGNORE_PLOT_COLOR
    else
        return g_ModLenses_Builder_Lenses["COLOR_BUILDER_LENS_PN"].ConfiguredColor
    end
end

function GetIgnorePlotColor()
    return IGNORE_PLOT_COLOR
end

-- Import config files for builder lens
include("BuilderLens_Config_", true)

local LENS_NAME = "ML_BUILDER"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

-- ==== BEGIN CQUI: Integration Modification =================================
function UpdateLensConfiguredColors()
    -- Called whenever we want to force the Lens Colors to be refreshed
    -- GetLensColorFromSettings will get the value if stored by GameConfiguration.SetValue,
    -- otherwise it will load the value from the GameInfo.Colors table that was updated by the MoreLenses SQL file
    for lensKey, lensConfig in pairs(g_ModLenses_Builder_Lenses) do
        lensColor = GetLensColorFromSettings(lensKey);
        g_ModLenses_Builder_Lenses[lensKey].ConfiguredColor = lensColor;
        -- Not sure there's a better way to do this and also keep the structure of g_ModLensModalPanel?
        -- defined only by modellenspanel.lua, so only gets called when in the modellenspanel context
        if g_ModLensModalPanel ~= nil then
            lensLegend = g_ModLensModalPanel[LENS_NAME].Legend;
            for idx, entry in ipairs(g_ModLensModalPanel[LENS_NAME].Legend) do
                locVal, colorVal = unpack(entry);
                if locVal == g_ModLenses_Builder_Lenses[lensKey].LocName then
                    g_ModLensModalPanel[LENS_NAME].Legend[idx] = {g_ModLenses_Builder_Lenses[lensKey].LocName, lensColor};
                    break;
                end
            end
        end
    end
end

-- ===========================================================================
function CQUI_ModLens_Builder_OnSettingsInitialized()
    -- Should the builder lens auto apply, when a builder is selected.
    AUTO_APPLY_BUILDER_LENS = GameConfiguration.GetValue("CQUI_AutoapplyBuilderLens");
    -- Disables the nothing color being highlted by the builder
    DISABLE_NOTHING_PLOT_HIGHLIGHT = GameConfiguration.GetValue("CQUI_BuilderLensDisableNothingPlot");
    -- Disables the dangerous plots highlted by the builder (barbs/military units at war with)
    DISABLE_DANGEROUS_PLOT_HIGHLIGHT = GameConfiguration.GetValue("CQUI_BuilderLensDisableDangerousPlot");
    UpdateLensConfiguredColors();
end

-- ===========================================================================
function CQUI_ModLens_Builder_OnSettingsUpdate()
    CQUI_ModLens_Builder_OnSettingsInitialized();
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
    local fallbackColorIndex = g_ModLenses_Builder_Lenses["COLOR_BUILDER_LENS_PN"].Index;
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
            for _, lensEntry in ipairs(g_ModLenses_Builder_Lenses_SortedIndexMap) do
                config = g_ModLenses_Builder_Lenses[lensEntry.Key].ConfigRules
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
        local pdLensIndex = g_ModLenses_Builder_Lenses["COLOR_BUILDER_LENS_PD"].Index;
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
    -- CQUI Settings Updates occur below, depending on the file that Included this one
end

function CQUI_SettingsPanelClosed()
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        -- Hide and show the builder lens to update the coloring
        ClearBuilderLens();
        ShowBuilderLens();
    end
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
    -- We only get into this code path via the Include call in minimappanel.lua
    -- Add the settings callback hooks for that minimappanel context
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_ModLens_Builder_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_ModLens_Builder_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsPanelClosed.Add(CQUI_SettingsPanelClosed);
end

-- modallenspanel.lua
if g_ModLensModalPanel ~= nil then
    g_ModLensModalPanel[LENS_NAME] = {}
    g_ModLensModalPanel[LENS_NAME].LensTextKey = "LOC_HUD_BUILDER_LENS"
    g_ModLensModalPanel[LENS_NAME].Legend = {}
    -- Insert in priority order and only those with Rules that do coloring
    for _,lensInfo in ipairs(g_ModLenses_Builder_Lenses_SortedIndexMap) do
        local lensData = g_ModLenses_Builder_Lenses[lensInfo.Key];
        if (#lensData.ConfigRules > 0) then
            table.insert(g_ModLensModalPanel[LENS_NAME].Legend, {lensData.LocName, lensData.ConfiguredColor});
        end
    end

    -- We only get into this code path via the Include call in modallenspanel.lua
    -- Add the settings callback hooks for that modallenspanel context
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_ModLens_Builder_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_ModLens_Builder_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsPanelClosed.Add(CQUI_SettingsPanelClosed);
end
