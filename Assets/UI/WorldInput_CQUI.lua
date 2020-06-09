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
local m_isInputBlocked :boolean = false;
local CQUI_cityview    :boolean = false;
local CQUI_hotkeyMode  :number  = 1; -- 0: V-Style with enhancements 1: V-Style 2: No changes
local CQUI_isShiftDown :boolean = false;

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
    CQUI_isShiftDown = true;
  end

  if CQUI_hotkeyMode ~= 0 then
    if CQUI_hotkeyMode == 2 then
      if( uiKey == Keys.W ) then
        keyPanChanged = true;
        m_isUPpressed = true;
      end

      if( uiKey == Keys.D ) then
        keyPanChanged = true;
        m_isRIGHTpressed = true;
      end

      if( uiKey == Keys.S ) then
        keyPanChanged = true;
        m_isDOWNpressed = true;
      end

      if( uiKey == Keys.A ) then
        keyPanChanged = true;
        m_isLEFTpressed = true;
      end
    end
  end

  if( uiKey == Keys.VK_UP ) then
    keyPanChanged = true;
    m_isUPpressed = true;
  end

  if( uiKey == Keys.VK_RIGHT ) then
    keyPanChanged = true;
    m_isRIGHTpressed = true;
  end

  if( uiKey == Keys.VK_DOWN ) then
    keyPanChanged = true;
    m_isDOWNpressed = true;
  end

  if( uiKey == Keys.VK_LEFT ) then
    keyPanChanged = true;
    m_isLEFTpressed = true;
  end

  if( keyPanChanged == true ) then
    -- Base game file uses m_edgePanX and m_edgePanY... but I do not see evidence where these are assigned to, except for the initial 0.
    -- ProcessPan(m_edgePanX,m_edgePanY);
    ProcessPan(0, 0);
  end

  return false;
end

-- ===========================================================================
function DefaultKeyUpHandler( uiKey:number )
  print_debug("** Function Entry: DefaultKeyUpHandler (CQUI Hook).  uiKey: "..tostring(uiKey));
  local keyPanChanged :boolean = false;
  --print("Key Up: " .. uiKey);
  local selectedUnit = UI.GetHeadSelectedUnit();
  local unitType = nil;
  local formationClass = nil;
  if selectedUnit then
    unitType = GameInfo.Units[selectedUnit:GetUnitType()].UnitType;
    formationClass = GameInfo.Units[selectedUnit:GetUnitType()].FormationClass;
    --print("Unit Type: " .. unitType .. " Formation Class: " .. formationClass);
  end

    --CQUI Keybinds
  if CQUI_hotkeyMode ~= 0 then
    if CQUI_hotkeyMode == 2 then -- CQUI Hotkey Enhanced mode
      if( uiKey == Keys.W ) then
        m_isUPpressed = false;
        keyPanChanged = true;
      end

      if( uiKey == Keys.D ) then
        m_isRIGHTpressed = false;
        keyPanChanged = true;
      end

      if( uiKey == Keys.S ) then
        m_isDOWNpressed = false;
        keyPanChanged = true;
      end

      if( uiKey == Keys.A ) then
        m_isLEFTpressed = false;
        keyPanChanged = true;
      end

      if( uiKey == Keys.E ) then
        if(CQUI_cityview) then
          LuaEvents.CQUI_GoNextCity();
        else
          UI.SelectNextReadyUnit();
        end
      end

      if( uiKey == Keys.Q ) then
        if(CQUI_cityview) then
          LuaEvents.CQUI_GoPrevCity();
        else
          UI.SelectPrevReadyUnit();
        end
      end

      if( uiKey == Keys.VK_SHIFT and ContextPtr:LookUpControl("/InGame/TechTree"):IsHidden() and ContextPtr:LookUpControl("/InGame/CivicsTree"):IsHidden()) then
        if(CQUI_cityview) then
          UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
          UI.SelectNextReadyUnit();
        else
          LuaEvents.CQUI_GoNextCity();
        end
      end
    else --Classic binds that would overlap with the enhanced binds
      if( uiKey == Keys.Q ) then
        if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), -80493497); --Quarry
        end
      end

      if( uiKey == Keys.S ) then
        UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitOperationTypes.AIR_ATTACK);
      end
    end

    -- Fortify until healed hotkey
    if( uiKey == Keys.H ) then
      if (unitType ~= nil) then -- OPTIMIZATION -- if unit health 100% alert not heal
        UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), 2126026491); -- OH MY GOD IT WAS SO HARD TO FIND THAT ID. WHAT WAS FIRAXIS THINKING
      end
      return;
    end

    -- Focus Capital hotkey
    if( uiKey == Keys.VK_HOME ) then
      UI.SelectCity(Players[Game.GetLocalPlayer()]:GetCities():GetCapitalCity());
    end

    if( uiKey == Keys.VK_BACK ) then
      if (unitType ~= nil) then
        UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitCommandTypes.CANCEL);
      end
    end

    if( uiKey == Keys.I ) then
      if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 168372657); --Farm
      end
    end

    if( uiKey == Keys.P ) then
      if ( CQUI_isShiftDown) then
        CQUI_isShiftDown = false;
        PlaceMapPin();
      else
        if (unitType == "UNIT_BUILDER") then
          CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 154488225); --Pasture
          CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 1523996587); --Plantation
        end
      end
    end

    if( uiKey == Keys.N ) then
      if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 1001859687); --Mine
      else
        UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.WMD_STRIKE);
      end
    end

    if( uiKey == Keys.H ) then
      if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), -1819558972); --Camp
      end
    end

    if( uiKey == Keys.L ) then
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 2048582848); --Lumber Mill
    end

    if( uiKey == Keys.R ) then
      if (unitType == "UNIT_MILITARY_ENGINEER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 115772143); --Road
      elseif (formationClass == "FORMATION_CLASS_AIR") then
        UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.REBASE);
      else
        return false;
      end
    end

    if( uiKey == Keys.F ) then
      if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 578093457); --Fishing Boats
      elseif (unitType == "UNIT_MILITARY_ENGINEER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), 1694280827); --Fort
      else
        UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), -744032280); --Sleep
      end
    end

    if( uiKey == Keys.Z ) then
      UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), -41338758); --Sleep
    end

    if( uiKey == Keys.O ) then
      if (unitType == "UNIT_BUILDER") then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), -1355513600); --Oil Well
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), -396628467); --Offshore Platform
      end
    end

    if( m_isALTDown ) then --Overridden classic binds get an alt-version as well as the normal alt-shortcuts
      if( uiKey == Keys.C ) then
        if (unitType == "UNIT_BUILDER") or (unitType == "UNIT_MILITARY_ENGINEER") then
          UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.HARVEST_RESOURCE);
          UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.REMOVE_FEATURE);
        end
      end

      if( uiKey == Keys.Q ) then
        CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), -80493497); --Quarry
      end

      if( uiKey == Keys.S ) then
        if (formationClass == "FORMATION_CLASS_AIR") then
          UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitOperationTypes.AIR_ATTACK);
        end
      end
    end
  end -- CQUI_hotkeyMode ~= 0

  if uiKey == Keys.VK_SHIFT then
    CQUI_isShiftDown = false;
  end

  if( uiKey == Keys.VK_UP ) then
    m_isUPpressed = false;
    keyPanChanged = true;
  end

  if( uiKey == Keys.VK_RIGHT ) then
    m_isRIGHTpressed = false;
    keyPanChanged = true;
  end

  if( uiKey == Keys.VK_DOWN ) then
    m_isDOWNpressed = false;
    keyPanChanged = true;
  end

  if( uiKey == Keys.VK_LEFT ) then
    m_isLEFTpressed = false;
    keyPanChanged = true;
  end

  if( keyPanChanged == true ) then
    -- Base game file uses m_edgePanX and m_edgePanY... but I do not see evidence where these are assigned to, except for the initial 0.
    -- ProcessPan(m_edgePanX,m_edgePanY);
    ProcessPan(0, 0);
  end

  return BASE_CQUI_DefaultKeyUpHandler( uiKey );
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