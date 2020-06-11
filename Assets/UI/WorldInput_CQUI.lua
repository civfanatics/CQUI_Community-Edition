-- ===========================================================================
-- Base File
-- ===========================================================================
include("WorldInput");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_UpdateDragMap            = UpdateDragMap;
BASE_CQUI_RealizeMovementPath      = RealizeMovementPath;
BASE_CQUI_OnUnitSelectionChanged   = OnUnitSelectionChanged;
BASE_CQUI_OnInputActionTriggered   = OnInputActionTriggered;
BASE_CQUI_DefaultKeyDownHandler    = DefaultKeyDownHandler;
BASE_CQUI_DefaultKeyUpHandler      = DefaultKeyUpHandler;
BASE_CQUI_OnDefaultKeyDown         = OnDefaultKeyDown;
BASE_CQUI_OnDefaultKeyUp           = OnDefaultKeyUp;
BASE_CQUI_OnPlacementKeyUp         = OnPlacementKeyUp;
BASE_CQUI_ClearAllCachedInputState = ClearAllCachedInputState;
BASE_CQUI_LateInitialize           = LateInitialize;
BASE_CQUI_Initialize               = Initialize;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_HOTKEYMODE_ENHANCED    = 2;
local CQUI_HOTKEYMODE_CLASSIC     = 1;
local CQUI_HOTKEYMODE_STANDARD    = 0;

local m_isInputBlocked  :boolean = false;
local CQUI_cityview     :boolean = false;
local CQUI_hotkeyMode   :number  = CQUI_HOTKEYMODE_ENHANCED;
local CQUI_isShiftDown  :boolean = false;
local CQUI_isAltDown    :boolean = false;
local CQUI_isCtrlDown   :boolean = false;

function CQUI_OnSettingsUpdate()
  CQUI_hotkeyMode = GameConfiguration.GetValue("CQUI_BindingsMode");
end

LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );

-- ===========================================================================
--  VARIABLES
-- ===========================================================================
local CQUI_ShowDebugPrint = true;

-- ===========================================================================
--CQUI setting control support functions
-- ===========================================================================
function print_debug(str)
  if CQUI_ShowDebugPrint then
    print(str);
  end
end

-- ===========================================================================
-- CQUI Base Extension Functions
-- Each of these functions call the Base Function found in WorldInput.lua
-- ===========================================================================

-- ===========================================================================
function UpdateDragMap()
  if g_isMouseDragging then
    -- Event sets a global in PlotInfo so tiles are not purchased while dragging
    LuaEvents.CQUI_StartDragMap();
  end

  return BASE_CQUI_UpdateDragMap();
end

-- ===========================================================================
function RealizeMovementPath(showQueuedPath:boolean)
  print_debug("** Function Entry: RealizeMovementPath (CQUI Hook) showQueuedPath is: "..tostring(showQueuedPath));
  if not UI.IsMovementPathOn() or UI.IsGameCoreBusy() then
    return;
  end
    
  -- CQUI (Azurency) : Check if in CITY_MANAGEMENT or STRIKE modes
  local CQUI_im = UI.GetInterfaceMode();
  if (CQUI_im == InterfaceModeTypes.CITY_MANAGEMENT or CQUI_im == InterfaceModeTypes.CITY_RANGE_ATTACK or CQUI_im == InterfaceModeTypes.DISTRICT_RANGE_ATTACK) then
    return;
  end

  return BASE_CQUI_RealizeMovementPath( showQueuedPath );
end

-- ===========================================================================
function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, isSelected:boolean, isEditable:boolean )
  local msg = "** Function Entry: OnUnitSelectionChanged (CQUI Hook).  playerId:"..tostring(playerID).." unitId:"..tostring(unitID).." hexI:"..tostring(hexI).." hexJ:"..tostring(hexJ).." hexK:"..tostring(hexK).." isSelected:"..tostring(isSelected).." isEditable:"..tostring(isEditable);
  print_debug(msg);
  if playerID ~= Game.GetLocalPlayer() then
    return;
  end

  -- CQUI (Azurency) : Fixes a Vanilla bug from SelectUnit.lua (not taking in account the district range attack)
  -- CQUI (Azurency) : If a selection is occuring and the district attack interface mode is up, take it down.
  if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_RANGE_ATTACK then
    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
  end

  return BASE_CQUI_OnUnitSelectionChanged( playerID, unitID, hexI, hexJ, hexK, isSelected, isEditable );
end

-- ===========================================================================
function DefaultKeyDownHandler( uiKey:number )
  print_debug("** Function Entry: DefaultKeyDownHandler (CQUI Hook).  uiKey: "..tostring(uiKey));
  -- Note: This function always returns false, by design in Base game
  BASE_CQUI_DefaultKeyDownHandler( uiKey ) ;

  --CQUI Keybinds
  local keyPanChanged :boolean = false;

  if uiKey == Keys.VK_SHIFT then
    print_debug("CQUI_isShiftDown = true");
    CQUI_isShiftDown = true;
  end

  if uiKey == Keys.VK_ALT then
    print_debug("CQUI_isAltDown = true");
    CQUI_isAltDown = true;
  end

  if CQUI_hotkeyMode ~= CQUI_HOTKEYMODE_STANDARD then
    if CQUI_hotkeyMode == CQUI_HOTKEYMODE_ENHANCED then
      if (uiKey == Keys.W) then
        keyPanChanged = true;
        m_isUPpressed = true;
      end

      if (uiKey == Keys.D) then
        keyPanChanged = true;
        m_isRIGHTpressed = true;
      end

      if (uiKey == Keys.S) then
        keyPanChanged = true;
        m_isDOWNpressed = true;
      end

      if (uiKey == Keys.A) then
        keyPanChanged = true;
        m_isLEFTpressed = true;
      end
    end
  end

  if (keyPanChanged == true) then
    -- Base game file uses m_edgePanX and m_edgePanY... but those values do not appear to ever change from 0, so just send 0.
    ProcessPan(0, 0);
    return true;
  end

  -- Allow other handlers of KeyDown events to capture input, if any exist after World Input
  return false;
end

-- ===========================================================================
function DefaultKeyUpHandler( uiKey:number )
  print_debug("** Function Entry: DefaultKeyUpHandler (CQUI Hook).  uiKey: "..tostring(uiKey));

  -- If set to Standard, just let the game do its thing
  if CQUI_hotkeyMode == CQUI_HOTKEYMODE_STANDARD then
    if uiKey == Keys.VK_SHIFT then
      CQUI_isShiftDown = false;
    end
  
    if uiKey == Keys.VK_ALT then
      CQUI_isAltDown = false;
    end

    return BASE_CQUI_DefaultKeyUpHandler(uiKey);
  end

  local keyPanChanged  :boolean = false;
  local cquiHandledKey :boolean = false;

  local selectedUnit = UI.GetHeadSelectedUnit();
  local unitType = nil;
  local formationClass = nil;
  if (selectedUnit) then
    unitType = GameInfo.Units[selectedUnit:GetUnitType()].UnitType;
    formationClass = GameInfo.Units[selectedUnit:GetUnitType()].FormationClass;
  end

  --CQUI Keybinds
  if CQUI_hotkeyMode == CQUI_HOTKEYMODE_ENHANCED then
    if (uiKey == Keys.W) then
      m_isUPpressed = false;
      keyPanChanged = true;
    end

    if (uiKey == Keys.D) then
      m_isRIGHTpressed = false;
      keyPanChanged = true;
    end

    if (uiKey == Keys.S) then
      m_isDOWNpressed = false;
      keyPanChanged = true;
    end

    if (uiKey == Keys.A) then
      m_isLEFTpressed = false;
      keyPanChanged = true;
    end

    if (uiKey == Keys.E) then
      if (CQUI_isAltDown == true) then
        -- Behave as if just "E" was pressed, send the unit exploring
        -- Calling this using UnitOperationTypes doesn't work as Automate_Explore hash does not appear among the GameInfo.OperationTypes
        UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), GameInfo.UnitOperations["UNITOPERATION_AUTOMATE_EXPLORE"].Hash);
        -- Use false as we need to let the unmodifed script deal with the Alt Key
        cquiHandledKey = false;
      elseif (CQUI_cityview) then
        LuaEvents.CQUI_GoNextCity();
        cquiHandledKey = true;
      else
        UI.SelectNextReadyUnit();
        cquiHandledKey = true;
      end
    end

    if (uiKey == Keys.Q) then
      if (CQUI_isAltDown == true and unitType == "UNIT_BUILDER" ) then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_QUARRY"].Hash);
        -- Use false as we need to let the unmodifed script deal with the Alt Key
        cquiHandledKey = false;
      elseif (CQUI_cityview) then
        LuaEvents.CQUI_GoPrevCity();
        cquiHandledKey = true;
      else
        UI.SelectPrevReadyUnit();
        cquiHandledKey = true;
      end
    end

    if (uiKey == Keys.VK_SHIFT and ContextPtr:LookUpControl("/InGame/TechTree"):IsHidden() and ContextPtr:LookUpControl("/InGame/CivicsTree"):IsHidden()) then
      cquiHandledKey = true;
      if (CQUI_cityview) then
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
        UI.SelectNextReadyUnit();
      else
        LuaEvents.CQUI_GoNextCity();
      end
    end

    if (keyPanChanged == true) then
      -- Base game file uses m_edgePanX and m_edgePanY... but I do not see evidence where these are assigned to, except for the initial 0.
      ProcessPan(0, 0);
      cquiHandledKey = true;
    end
  else -- CQUI_hotkeyMode == CQUI_HOTKEYMODE_CLASSIC  (Classic binds that overlap with enhanced binds)
    if (uiKey == Keys.Q) then
      if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_QUARRY"].Hash);
        cquiHandledKey = true;
      end
    end

    if (uiKey == Keys.S) then
      if (formationClass == "FORMATION_CLASS_AIR") then
        -- M4A: Not certain that this command actually is functional
        UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitOperationTypes.AIR_ATTACK);
        cquiHandledKey = true;
      end
    end
  end -- Classic binds that overlap with enhanced binds

    -- Focus Capital hotkey
  if (uiKey == Keys.VK_HOME) then
    UI.SelectCity(Players[Game.GetLocalPlayer()]:GetCities():GetCapitalCity());
    cquiHandledKey = true;
  end

  if (uiKey == Keys.VK_BACK) then
    if (unitType ~= nil) then
      UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitCommandTypes.CANCEL);
      cquiHandledKey = true;
    end
  end

  if (uiKey == Keys.C and CQUI_isAltDown == true) then
    if (unitType == "UNIT_BUILDER") or (unitType == "UNIT_MILITARY_ENGINEER") then
      UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.HARVEST_RESOURCE);
      UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.REMOVE_FEATURE);
      -- Use false as we need to let the unmodifed script deal with the Alt Key
      cquiHandledKey = false;
    end
  end

  if (uiKey == Keys.F) then
    if (unitType == "UNIT_BUILDER") then
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_FISHING_BOATS"].Hash);
      cquiHandledKey = true;
    elseif (unitType == "UNIT_MILITARY_ENGINEER") then
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_FORT"].Hash);
      cquiHandledKey = true;
    end
  end

  if (uiKey == Keys.H and unitType == "UNIT_BUILDER") then
    CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_CAMP"].Hash);
    cquiHandledKey = true;
  end

  if (uiKey == Keys.I and unitType == "UNIT_BUILDER") then
    CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_FARM"].Hash);
    cquiHandledKey = true;
  end

  if (uiKey == Keys.L and unitType == "UNIT_BUILDER") then
    CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_LUMBER_MILL"].Hash);
    cquiHandledKey = true;
  end

  if (uiKey == Keys.N) then
    cquiHandledKey = true;
    if (unitType == "UNIT_BUILDER") then
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_MINE"].Hash);
    else
      UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.WMD_STRIKE);
    end
  end

  if (uiKey == Keys.O) then
    if (unitType == "UNIT_BUILDER") then
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_OIL_WELL"].Hash);
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_OFFSHORE_OIL_RIG"].Hash);
      cquiHandledKey = true;
    end
  end

  if (uiKey == Keys.P) then
    if (CQUI_isShiftDown) then
      CQUI_isShiftDown = false;
      PlaceMapPin();
      cquiHandledKey = true;
    else
      if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_PASTURE"].Hash);
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_PLANTATION"].Hash);
        cquiHandledKey = true;
      end
    end
  end

  if (uiKey == Keys.R) then
    if (unitType == "UNIT_MILITARY_ENGINEER") then
      -- Build Road/Rail is a UnitOperation
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.UnitOperations["UNITOPERATION_BUILD_ROUTE"].Hash);
      cquiHandledKey = true;
    elseif (formationClass == "FORMATION_CLASS_AIR") then
      UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.REBASE);
      cquiHandledKey = true;
    end
  end

  if (uiKey == Keys.S and CQUI_isAltDown == true) then
    if (formationClass == "FORMATION_CLASS_AIR") then
      UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitOperationTypes.AIR_ATTACK);
      -- Use false as we need to let the unmodifed script deal with the Alt Key
      cquiHandledKey =false;
    end
  end

  if uiKey == Keys.VK_SHIFT then
    CQUI_isShiftDown = false;
  end

  if uiKey == Keys.VK_ALT then
    CQUI_isAltDown = false;
  end

  if (cquiHandledKey == false) then
    print_debug("CQUI Did not handle key: "..tostring(uiKey));
    cquiHandledKey = BASE_CQUI_DefaultKeyUpHandler( uiKey );
  end

  return cquiHandledKey;
end

-- ===========================================================================
function OnDefaultKeyDown( pInputStruct:table )
  print_debug("** Function Entry: OnDefaultKeyDown (CQUI Hook)");
  if m_isInputBlocked then
    print_debug("** m_isInputBlocked is true");
    return;
  end

  return BASE_CQUI_OnDefaultKeyDown( pInputStruct );
end

-- ===========================================================================
function OnDefaultKeyUp( pInputStruct:table )
  print_debug("** Function Entry: OnDefaultKeyUp (CQUI Hook)");
  if m_isInputBlocked then
    print_debug("** m_isInputBlocked is true");
    return;
  end

  return BASE_CQUI_OnDefaultKeyUp( pInputStruct );
end

-- ===========================================================================
function OnPlacementKeyUp( pInputStruct:table )
  print_debug("** Function Entry: OnPlacementKeyUp (CQUI Hook)");
  if m_isInputBlocked then 
    print_debug("** m_isInputBlocked is true");
    return;
  end

  return BASE_CQUI_OnPlacementKeyUp( pInputStruct );
end

-- ===========================================================================
function ClearAllCachedInputState()
  print_debug("** Function Entry: ClearAllCachedInputState (CQUI Hook)");
  BASE_CQUI_ClearAllCachedInputState();

  CQUI_isShiftDown = false;
end

-- ===========================================================================
function OnInputActionTriggered( actionId:number )
 -- CQUI Enhanced Keyboard over-rides some of the ingame hot keys

end

-- ===========================================================================
function LateInitialize()
  print_debug("** Function Entry: LateInitialize (CQUI Hook)");
  BASE_CQUI_LateInitialize();

  LuaEvents.InGameTopOptionsMenu_Show.Add(OnBlockInput);
  LuaEvents.InGameTopOptionsMenu_Close.Add(OnUnblockInput);
  LuaEvents.DiploScene_SceneClosed.Add(OnUnblockInput);
  LuaEvents.DiploScene_SceneOpened.Add(OnBlockInput);
end

-- ===========================================================================
-- CQUI Base Replacement Functions
-- These functions do not call the function of the same name found in base WorldInput.lua
-- ===========================================================================

-- ===========================================================================
function ClearMovementPath()
  print_debug("** Function Entry: ClearMovementPath (CQUI Hook)");
  -- Replace base function because of the if statement around the UILens.ClearLayerHexes
  UILens.ClearLayerHexes( g_MovementPath );
  UILens.ClearLayerHexes( g_Numbers );
  -- CQUI : As we show path on over
  if (UI.GetInterfaceMode() ~= InterfaceModeTypes.CITY_RANGE_ATTACK and UI.GetInterfaceMode() ~= InterfaceModeTypes.DISTRICT_RANGE_ATTACK) then
    UILens.ClearLayerHexes( g_AttackRange );
  end
  m_cachedPathUnit = nil;
  m_cachedPathPlotId = -1;
end

-- ===========================================================================
function OnInterfaceModeEnter_CityManagement( eNewMode:number )
  print_debug("** Function Entry: OnInterfaceModeEnter_CityManagement (CQUI Hook)");
  UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
  -- AZURENCY : fix the Appeal lens not being applied in city view
  -- UILens.SetActive("CityManagement");
end

-- ===========================================================================
function OnMouseBuildingPlacementCancel( pInputStruct:table )
  print_debug("** Function Entry: OnMouseBuildingPlacementCancel (CQUI Hook)");
  if IsCancelAllowed() then
    LuaEvents.CQUI_CityviewEnable();
    -- CQUI: Do not call ExitPlacementMode here
    -- ExitPlacementMode( true );
  end
end

-- ===========================================================================
function OnMouseDistrictPlacementCancel( pInputStruct:table )
  print_debug("** Function Entry: OnMouseDistrictPlacementCancel (CQUI Hook)");
  if IsCancelAllowed() then
    LuaEvents.StoreHash(0);
    LuaEvents.CQUI_CityviewEnable();
    -- CQUI: Do not call ExitPlacementMode here
    -- ExitPlacementMode( true );
  end
end

-- ===========================================================================
function OnCycleUnitSelectionRequest()
  print_debug("** Function Entry: OnCycleUnitSelectionRequest (CQUI Hook)");
  if(UI.GetInterfaceMode() ~= InterfaceModeTypes.CINEMATIC or m_isMouseButtonRDown) then
    -- AZURENCY : OnCycleUnitSelectionRequest is called by UI.SetCycleAdvanceTimer()
    -- in SelectedUnit.lua causing a conflict with the auto-cyling of unit
    -- (not the same given by UI.SelectNextReadyUnit() and player:GetUnits():GetFirstReadyUnit())
    local pPlayer :table = Players[Game.GetLocalPlayer()];
    if pPlayer ~= nil then
      if pPlayer:IsTurnActive() then
        local unit:table = pPlayer:GetUnits():GetFirstReadyUnit();
        -- AZURENCY : we also check if there is not already a unit selected,
        -- bacause UI.SetCycleAdvanceTimer() is always called after deselecting a unit
        if unit ~= nil and not UI.GetHeadSelectedUnit() then
          UI.DeselectAllUnits();
          UI.DeselectAllCities();
          UI.SelectUnit(unit);
          UI.LookAtPlot(unit:GetX(), unit:GetY());
        end
      end
    end
  end
end

-- ===========================================================================
-- CQUI: Unique Functions
-- These functions are unique to CQUI, do not exist in the Base WorldInput.lua
-- ===========================================================================

-- ===========================================================================
function CQUI_BuildImprovement (unit, improvementHash: number)
  print_debug("** Function Entry: CQUI_BuildImprovement (CQUI Hook)");
  if unit == nil then return end

  local tParameters = {};
  tParameters[UnitOperationTypes.PARAM_X] = unit:GetX();
  tParameters[UnitOperationTypes.PARAM_Y] = unit:GetY();
  tParameters[UnitOperationTypes.PARAM_IMPROVEMENT_TYPE] = improvementHash;

  UnitManager.RequestOperation( unit, UnitOperationTypes.BUILD_IMPROVEMENT, tParameters );
end

-- ===========================================================================
function OnBlockInput()
  print_debug("** Function Entry: OnBlockInput (CQUI Hook)");
  m_isInputBlocked = true;
end
  
-- ===========================================================================
function OnUnblockInput()
  print_debug("** Function Entry: OnUnblockInput (CQUI Hook)");
  m_isInputBlocked = false;
  ClearAllCachedInputState();
end

-- ===========================================================================
-- CQUI: Initialize Function
-- ===========================================================================

-- ===========================================================================
function Initialize()
  print_debug("** Function Entry: Initialize (CQUI Hook)");
  -- CQUI Events from end of Initialize
  LuaEvents.CQUI_WorldInput_CityviewEnable.Add( function() CQUI_cityview = true; end );
  LuaEvents.CQUI_WorldInput_CityviewDisable.Add( function() CQUI_cityview = false; end );
  LuaEvents.CQUI_showUnitPath.Add(RealizeMovementPath);
  LuaEvents.CQUI_clearUnitPath.Add(ClearMovementPath);

  BASE_CQUI_Initialize();
end
Initialize();