include("LensSupport")

local PANEL_OFFSET_Y:number = 32
local PANEL_OFFSET_X:number = -5

local LENS_NAME = "ML_CITYOVERLAP"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

local DEFAULT_OVERLAP_RANGE:number = 6

-- ===========================================================================
--  Member Variables
-- ===========================================================================

local m_isOpen:boolean = false
local m_cityOverlapRange:number = DEFAULT_OVERLAP_RANGE
local m_currentCursorPlotID:number = -1

local m_LensSettings = {
    -- Note the special case handling with the KeyLabel
    ["COLOR_CITYOVERLAP_LENS_1"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_1"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +1" },
    ["COLOR_CITYOVERLAP_LENS_2"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_2"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +2" },
    ["COLOR_CITYOVERLAP_LENS_3"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_3"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +3" },
    ["COLOR_CITYOVERLAP_LENS_4"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_4"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +4" },
    ["COLOR_CITYOVERLAP_LENS_5"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_5"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +5" },
    ["COLOR_CITYOVERLAP_LENS_6"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_6"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +6" },
    ["COLOR_CITYOVERLAP_LENS_7"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_7"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +7" },
    ["COLOR_CITYOVERLAP_LENS_8"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_8"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +8" }
}

-- ===========================================================================
--  City Overlap Support functions
-- ===========================================================================

--[[
local function ShowCityOverlapLens()
    print("Showing " .. LENS_NAME)
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearCityOverlapLens()
    print("Clearing " .. LENS_NAME)
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER)
    else
        print("Nothing to clear")
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE")
end
]]

local function clamp(val, min, max)
    if val < min then
        return min
    elseif val > max then
        return max
    end
    return val
end

-- ===========================================================================
--  Exported functions
-- ===========================================================================

local function SetModalKey(maxCityOverlap)
    local CityOverlapLensModalPanelEntry = {}
    CityOverlapLensModalPanelEntry.Legend = {}
    CityOverlapLensModalPanelEntry.LensTextKey = "LOC_HUD_CITYOVERLAP_LENS"
    -- NOTE: Not using the KeyLabel here, in order to place the bonus value on the next line
    for i = 1, 8 do
        local params:table = {
            "LOC_WORLDBUILDER_TAB_CITIES",
            m_LensSettings["COLOR_CITYOVERLAP_LENS_" .. tostring(i)].ConfiguredColor,
            nil,  -- bonus icon
            "+ " .. tostring(i + (maxCityOverlap - 8))  -- bonus value
        }
        table.insert(CityOverlapLensModalPanelEntry.Legend, params)
    end

    -- modallenspanel.lua
    -- overwrite the old entry and refresh key panel
    -- NOTE: Doing a call here because modal panel opens before the lens gets applied
    -- hence a forced refresh after calculating max city overlap
    LuaEvents.ModalLensPanel_AddLensEntry(LENS_NAME, CityOverlapLensModalPanelEntry, true)
end

local function SetCityOverlapLens()
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer   :number = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local plotEntries       :table = {}
    local numCityEntries    :table = {}
    local localPlayerCities = Players[localPlayer]:GetCities()

    local maxCityOverlap:number = 0

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)

        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            if pPlot:GetOwner() == localPlayer or Controls.ShowLensOutsideBorder:IsChecked() then
                local numCities = 0
                for _, pCity in localPlayerCities:Members() do
                    if Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY()) <= m_cityOverlapRange then
                        numCities = numCities + 1
                    end
                end

                if numCities > 0 then
                    if numCities > maxCityOverlap then
                        maxCityOverlap = numCities
                    end

                    table.insert(plotEntries, i)
                    table.insert(numCityEntries, numCities)
                end
            end
        end
    end

    -- number of cities has to be atleast 8
    if maxCityOverlap < 8 then
        maxCityOverlap = 8
    end

    for i = 1, #plotEntries, 1 do
        -- If the max cities overlapping exceed 8, reoffset them so that 8 is now the maximum
        -- Ex if we find 10 cities overlapped in a hex with a given range,
        -- colorgradient8_8 will map to 10
        -- colorgradient8_1 will map to 3
        -- city overlap of 1 and 2 will be ignored
        local cityOffset = maxCityOverlap - 8
        local relativeNumCities:number = numCityEntries[i] - cityOffset

        if relativeNumCities > 0 then
            local colorLookup:string = "COLOR_CITYOVERLAP_LENS_" .. tostring(relativeNumCities)
            local color:number = m_LensSettings[colorLookup].ConfiguredColor
            UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, {plotEntries[i]}, color )
        end
    end
    SetModalKey(maxCityOverlap)
end

local function SetRangeMouseLens(range)
    local plotId = UI.GetCursorPlotID()
    if (not Map.IsPlot(plotId)) then
        return
    end

    local pPlot = Map.GetPlotByIndex(plotId)
    local localPlayer = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]
    local cityPlots:table = {}
    local normalPlot:table = {}

    for pAdjacencyPlot in PlotAreaSpiralIterator(pPlot, m_cityOverlapRange, SECTOR_NONE, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, CENTRE_INCLUDE) do
        if localPlayerVis:IsRevealed(pAdjacencyPlot:GetX(), pAdjacencyPlot:GetY()) then
            if (pAdjacencyPlot:GetOwner() == localPlayer and pAdjacencyPlot:IsCity()) then
                table.insert(cityPlots, pAdjacencyPlot:GetIndex())
            else
                table.insert(normalPlot, pAdjacencyPlot:GetIndex())
            end
        end
    end

    if (table.count(cityPlots) > 0) then
        local plotColor:number = m_LensSettings["COLOR_CITYOVERLAP_LENS_1"].ConfiguredColor
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, cityPlots, plotColor )
    end

    if (table.count(normalPlot) > 0) then
        local plotColor:number = m_LensSettings["COLOR_CITYOVERLAP_LENS_3"].ConfiguredColor
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, normalPlot, plotColor )
    end
end

-- ===========================================================================
--  UI Controls
-- ===========================================================================

local function RefreshCityOverlapLens()
    -- Assuming city overlap lens is already applied
    UILens.ClearLayerHexes(ML_LENS_LAYER)
    if Controls.OverlapLensMouseRange:IsChecked() then
        SetRangeMouseLens()
    else
        SetCityOverlapLens()
    end
end

local function IncreseOverlapRange()
    m_cityOverlapRange = m_cityOverlapRange + 1
    Controls.OverlapRangeLabel:SetText(m_cityOverlapRange)
    RefreshCityOverlapLens()
end

local function DecreaseOverlapRange()
    if (m_cityOverlapRange > 0) then
        m_cityOverlapRange = m_cityOverlapRange - 1
    end
    Controls.OverlapRangeLabel:SetText(m_cityOverlapRange)
    RefreshCityOverlapLens()
end

local function Open()
    Controls.OverlapLensOptionsPanel:SetHide(false)
    m_isOpen = true

    -- Reset settings
    m_cityOverlapRange = DEFAULT_OVERLAP_RANGE
    Controls.OverlapRangeLabel:SetText(m_cityOverlapRange)
    Controls.OverlapLensMouseRange:SetCheck(false)
    Controls.OverlapLensMouseNone:SetCheck(true)
    Controls.ShowLensOutsideBorder:SetCheck(true)
end

local function Close()
    Controls.OverlapLensOptionsPanel:SetHide(true)
    m_isOpen = false
end

local function TogglePanel()
    if m_isOpen then
        Close()
    else
        Open()
    end
end

local function OnReoffsetPanel()
    -- Get size and offsets for minimap panel
    local offsets = {}
    LuaEvents.MinimapPanel_GetLensPanelOffsets(offsets)
    Controls.OverlapLensOptionsPanel:SetOffsetY(offsets.Y + PANEL_OFFSET_Y)
    Controls.OverlapLensOptionsPanel:SetOffsetX(offsets.X + PANEL_OFFSET_X)
end

-- ===========================================================================
--  Game Engine Events
-- ===========================================================================

local function OnLensLayerOn(layerNum:number)
    if layerNum == ML_LENS_LAYER then
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            RefreshCityOverlapLens()
        end
    end
end

local function HandleMouse()
    -- Skip all if panel is hidden
    if m_isOpen then
        -- Get plot under cursor
        local plotId = UI.GetCursorPlotID()
        if (not Map.IsPlot(plotId)) then
            return
        end

        -- If the cursor plot has not changed don't refresh
        if (m_CurrentCursorPlotID == plotId) then
            return
        end
        m_CurrentCursorPlotID = plotId

        -- Handler for City Overlap lens
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            if Controls.OverlapLensMouseRange:IsChecked() then
                RefreshCityOverlapLens()
            end
        end
    end
end

local function ChangeContainer()
    -- Change the parent to /InGame/HUD container so that it hides correcty during diplomacy, etc
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    Controls.OverlapLensOptionsPanel:ChangeParent(hudContainer)
end

local function OnInit(isReload:boolean)
    if isReload then
        ChangeContainer()
    end
end

local function OnShutdown()
    -- Destroy the container manually
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    if hudContainer ~= nil then
        hudContainer:DestroyChild(Controls.OverlapLensOptionsPanel)
    end
end

local function CQUI_OnSettingsInitialized()
    -- NOTE: Do not update the g_ModLensModalPanel directly, use the local function to handle that
    --       as it has special-case handling for the Modal Panel key text
    UpdateLensConfiguredColors(m_LensSettings, nil, LENS_NAME);
    SetModalKey(maxCityOverlap);
end

local function CQUI_OnSettingsUpdate()
    CQUI_OnSettingsInitialized();
end

-- ===========================================================================
--  Init
-- ===========================================================================

-- minimappanel.lua
local CityOverlapLensEntry = {
    LensButtonText = "LOC_HUD_CITYOVERLAP_LENS",
    LensButtonTooltip = "LOC_HUD_CITYOVERLAP_LENS_TOOLTIP",
    Initialize = nil,
    OnToggle = TogglePanel,
    GetColorPlotTable = nil  -- Pass nil since we have our own trigger
}

-- Add CQUI LuaEvent Hooks for minimappanel and modallenspanel contexts
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);

-- Don't import this into g_ModLenses, since this for the UI (ie not lens)
local function Initialize()
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("          City Overlap Panel")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    Close()
    OnReoffsetPanel()

    ContextPtr:SetInitHandler( OnInit )
    ContextPtr:SetShutdown( OnShutdown )
    ContextPtr:SetInputHandler( OnInputHandler, true )

    Events.LoadScreenClose.Add(
        function()
            ChangeContainer()
            LuaEvents.MinimapPanel_AddLensEntry(LENS_NAME, CityOverlapLensEntry)
        end
    )
    Events.LensLayerOn.Add( OnLensLayerOn )

    -- City Overlap Lens Setting
    Controls.OverlapRangeUp:RegisterCallback( Mouse.eLClick, IncreseOverlapRange )
    Controls.OverlapRangeDown:RegisterCallback( Mouse.eLClick, DecreaseOverlapRange )
    Controls.OverlapLensMouseNone:RegisterCallback( Mouse.eLClick, RefreshCityOverlapLens )
    Controls.OverlapLensMouseRange:RegisterCallback( Mouse.eLClick, RefreshCityOverlapLens )
    Controls.ShowLensOutsideBorder:RegisterCallback( Mouse.eLClick, RefreshCityOverlapLens )

    LuaEvents.ML_ReoffsetPanels.Add( OnReoffsetPanel )
    LuaEvents.ML_CloseLensPanels.Add( Close )
    LuaEvents.ML_HandleMouse.Add( HandleMouse )
end

Initialize()
