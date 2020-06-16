include("PopupDialog.lua");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_UpdateDragMap            = UpdateDragMap;
BASE_CQUI_OnUnitSelectionChanged   = OnUnitSelectionChanged;
BASE_CQUI_DefaultKeyDownHandler    = DefaultKeyDownHandler;
BASE_CQUI_DefaultKeyUpHandler      = DefaultKeyUpHandler;
BASE_CQUI_ClearAllCachedInputState = ClearAllCachedInputState;
BASE_CQUI_OnUserRequestClose       = OnUserRequestClose;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_HOTKEYMODE_ENHANCED    = 2;
local CQUI_HOTKEYMODE_CLASSIC     = 1;
local CQUI_HOTKEYMODE_STANDARD    = 0;

local CQUI_cityview     :boolean = false;
local CQUI_hotkeyMode   :number  = CQUI_HOTKEYMODE_ENHANCED;
local CQUI_isShiftDown  :boolean = false;
local CQUI_isAltDown    :boolean = false;

function CQUI_OnSettingsUpdate()
  CQUI_hotkeyMode = GameConfiguration.GetValue("CQUI_BindingsMode");
end

LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );

-- ===========================================================================
--  VARIABLES
-- ===========================================================================
local CQUI_ShowDebugPrint = false;

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
function OnUserRequestClose()
  CQUI_isAltDown = false;
  CQUI_isShiftDown = false;

  BASE_CQUI_OnUserRequestClose();
end

-- ===========================================================================
function UpdateDragMap()
  if g_isMouseDragging then
    -- Event sets a global in PlotInfo so tiles are not purchased while dragging
    LuaEvents.CQUI_StartDragMap();
  end

  return BASE_CQUI_UpdateDragMap();
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
  BASE_CQUI_DefaultKeyDownHandler( uiKey );

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

  if (keyPanChanged == true) then
    -- Base game file uses m_edgePanX and m_edgePanY... but those values do not ever appear change from 0, so just send 0.
    ProcessPan(0, 0);
    return true;
  end

  -- Allow other handlers of KeyDown events to capture input, if any exist after World Input
  return false;
end

-- ===========================================================================
function DefaultKeyUpHandler( uiKey:number )
  print_debug("** Function Entry: DefaultKeyUpHandler (CQUI Hook) uiKey: "..tostring(uiKey));

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
        cquiHandledKey = true;
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
        -- Do nothing, this case is handled later on in this function
      elseif (CQUI_cityview) then
        LuaEvents.CQUI_GoPrevCity();
        cquiHandledKey = true;
      else
        UI.SelectPrevReadyUnit();
        cquiHandledKey = true;
      end
    end

    -- TODO: Not a huge fan of the Shift key being used to do things when the Shift key should just be a modifier.
    --       Taking it out for now and will address with Issue #40
    -- if (uiKey == Keys.VK_SHIFT and ContextPtr:LookUpControl("/InGame/TechTree"):IsHidden() and ContextPtr:LookUpControl("/InGame/CivicsTree"):IsHidden()) then
    --   cquiHandledKey = true;
    --   if (CQUI_cityview) then
    --     UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
    --     UI.SelectNextReadyUnit();
    --   else
    --     LuaEvents.CQUI_GoNextCity();
    --   end
    -- end

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

    -- TODO: AIR_ATTACK requires a separate set of parameters be passed to it, pointing at the object to attack
    --       Similar to how the CQUI_BuildImprovement generates an object based on where the Builder/Engineer unit happens to be.
    -- Logged on GitHub as Issue #40
    -- if (uiKey == Keys.S) then
      -- if (formationClass == "FORMATION_CLASS_AIR") then
      -- UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitOperationTypes.AIR_ATTACK);
      --  cquiHandledKey = true;
      -- end
    -- end
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
      cquiHandledKey = true;
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
    -- See TODO note Below
    -- cquiHandledKey = true;
    if (unitType == "UNIT_BUILDER") then
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_MINE"].Hash);
      cquiHandledKey = true;
    else
      -- TODO: WMD_STRIKE requires a separate set of parameters be passed to it, pointing at the object to attack
      --       Similar to how the CQUI_BuildImprovement generates an object based on where the Builder/Engineer unit happens to be.
      -- Logged on GitHub as Issue #40
      -- UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.WMD_STRIKE);
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

  if (uiKey == Keys.Q) then
    if (CQUI_isAltDown == true and unitType == "UNIT_BUILDER" ) then
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.Improvements["IMPROVEMENT_QUARRY"].Hash);
      cquiHandledKey = true;
    end
  end

  if (uiKey == Keys.R) then
    if (unitType == "UNIT_MILITARY_ENGINEER") then
      -- Build Road/Rail is a UnitOperation
      CQUI_BuildImprovement(UI.GetHeadSelectedUnit(), GameInfo.UnitOperations["UNITOPERATION_BUILD_ROUTE"].Hash);
      cquiHandledKey = true;
      -- TODO: Rebase requires a separate set of parameters be passed to it, pointing at the location to move to
      --       Similar to how the CQUI_BuildImprovement generates an object based on where the Builder/Engineer unit happens to be.
      -- Logged on GitHub as Issue #40
    -- elseif (formationClass == "FORMATION_CLASS_AIR") then
      -- UnitManager.RequestOperation(UI.GetHeadSelectedUnit(), UnitOperationTypes.REBASE);
      -- cquiHandledKey = true;
    end
  end

  -- TODO: AIR_ATTACK requires a separate set of parameters be passed to it, pointing at the object to attack
  --       Similar to how the CQUI_BuildImprovement generates an object based on where the Builder/Engineer unit happens to be.
  -- Logged on GitHub as Issue #40
  -- if (uiKey == Keys.S and CQUI_isAltDown == true) then
    -- if (formationClass == "FORMATION_CLASS_AIR") then
    --   UnitManager.RequestCommand(UI.GetHeadSelectedUnit(), UnitOperationTypes.AIR_ATTACK);
    --   cquiHandledKey = true;
    -- end
  -- end

  if uiKey == Keys.VK_SHIFT then
    -- We need to let the base function also handle the Shift Up action
    CQUI_isShiftDown = false;
  end

  if uiKey == Keys.VK_ALT then
    -- We need to let the base function also handle the Alt Up action
    CQUI_isAltDown = false;
  end

  if (cquiHandledKey == false) then
    print_debug("** CQUI DefaultKeyUpHandler did not handle key: "..tostring(uiKey));
    cquiHandledKey = BASE_CQUI_DefaultKeyUpHandler(uiKey);
  end

  return cquiHandledKey;
end

-- ===========================================================================
function ClearAllCachedInputState()
  print_debug("** Function Entry: ClearAllCachedInputState (CQUI Hook)");
  BASE_CQUI_ClearAllCachedInputState();

  CQUI_isShiftDown = false;
  CQUI_isAltDown = false;
end

-- ===========================================================================
-- CQUI Base Replacement Functions
-- These functions do not call the function of the same name found in base WorldInput.lua
-- ===========================================================================
function RealizeMovementPath(showQueuedPath:boolean, unitID:number)
  print_debug("** Function Entry: RealizeMovementPath (CQUI Hook) -- showQueuedPath: "..tostring(showQueuedPath).." unitID"..tostring(unitID));
  -- Largely the same as the base RealizeMovementPath, save for the additional unitID parameter
  -- The unitID allows CQUI to show the movement path when a unit is hovered over (base game returns because no unit is actually selected)
  
  if not UI.IsMovementPathOn() or UI.IsGameCoreBusy() then
    return;
  end

  -- CQUI (Azurency) : Check if in CITY_MANAGEMENT or STRIKE modes
  CQUI_im = UI.GetInterfaceMode();
  if (CQUI_im == InterfaceModeTypes.CITY_MANAGEMENT or CQUI_im == InterfaceModeTypes.CITY_RANGE_ATTACK or CQUI_im == InterfaceModeTypes.DISTRICT_RANGE_ATTACK) then
    return;
  end

  -- Bail if no selected unit
  -- CQUI: If unitID is not null (as happens when hovering option is enabled), then that will be used instead
  local kUnit :table = nil;
  if unitID then
    kUnit = Players[Game.GetLocalPlayer()]:GetUnits():FindID(unitID);
  else
    kUnit = UI.GetHeadSelectedUnit();
  end

  if kUnit == nil then
    UILens.SetActive("Default");
    m_cachedPathUnit = nil;
    m_cachedPathPlotId = -1;
    return;
  end

  -- Bail if unit is not a type that allows movement.
  if GameInfo.Units[kUnit:GetUnitType()].IgnoreMoves then
    return;
  end

  -- Bail if end plot is not determined.
  local endPlotId :number = UI.GetCursorPlotID();

  -- Use the queued destination to show the queued path
  if (showQueuedPath) then
    local queuedEndPlotId:number = UnitManager.GetQueuedDestination( kUnit );
    if queuedEndPlotId then
      endPlotId = queuedEndPlotId;
    elseif unitID then -- AZURENCY : bail if the unit have no endplot and we wanted to draw its path
      return;
    end
  end

  -- Ensure this is a proper plot ID
  if (not Map.IsPlot(endPlotId)) then
    return;
  end

  -- Only update if a new unit or new plot from the previous update.
  if m_cachedPathUnit ~= kUnit or m_cachedPathPlotId  ~= endPlotId then
    UILens.ClearLayerHexes( g_MovementPath );
    UILens.ClearLayerHexes( g_Numbers );
    UILens.ClearLayerHexes( g_AttackRange );

    if m_cachedPathPlotId ~= -1 then
      UILens.UnFocusHex( g_AttackRange, m_cachedPathPlotId );
    end

    m_cachedPathUnit  = kUnit;
    m_cachedPathPlotId  = endPlotId;

    -- Obtain ordered list of plots.
    local variations  : table = {};  -- 2 to 3 values
    local eLocalPlayer  : number = Game.GetLocalPlayer();

    --check for unit position swap first
    local startPlotId :number = Map.GetPlot(kUnit:GetX(),kUnit:GetY()):GetIndex();
    if startPlotId ~= endPlotId then
      local pathPlots    :table = {};
      local plot      :table        = Map.GetPlotByIndex(endPlotId);
      local tParameters :table        = {};
      tParameters[UnitOperationTypes.PARAM_X] = plot:GetX();
      tParameters[UnitOperationTypes.PARAM_Y] = plot:GetY();
      if ( UnitManager.CanStartOperation( kUnit, UnitOperationTypes.SWAP_UNITS, nil, tParameters) ) then
        lensNameBase = "MovementGood";
        if not UILens.IsLensActive(lensNameBase) then
          UILens.SetActive(lensNameBase);
        end

        table.insert(pathPlots, startPlotId);
        table.insert(pathPlots, endPlotId);
        table.insert(variations, {lensNameBase.."_Destination",startPlotId} );
        table.insert(variations, {lensNameBase.."_Counter", startPlotId} ); -- show counter pip
        UI.AddNumberToPath( 1, startPlotId);
        table.insert(variations, {lensNameBase.."_Destination",endPlotId} );
        table.insert(variations, {lensNameBase.."_Counter", endPlotId} ); -- show counter pip
        UI.AddNumberToPath( 1, endPlotId);
        UILens.SetLayerHexesPath(g_MovementPath, eLocalPlayer, pathPlots, variations);
        return;
      end
    end

    local pathInfo : table = UnitManager.GetMoveToPathEx( kUnit, endPlotId );

    if table.count(pathInfo.plots) > 1 then
      -- Start and end art "variations" when drawing path
      local startHexId:number = kUnit:GetPlotId();
      local endHexId  :number = pathInfo.plots[table.count(pathInfo.plots)];

      -- Don't show the implicit arrow if the unit has no remaining moves
      -- NOTE: UnitManager.CanStartOperation and kUnit:GetAttacksRemaining both indicate a ranged
      -- unit with 0 remaining moves can still attack, so we check using kUnit:GetMovesRemaining
      if kUnit:GetMovesRemaining() > 0 then
        -- Check if our desired "movement" is actually a ranged attack. Early out if so.
        local isImplicitRangedAttack :boolean = false;

        local pResults = UnitManager.GetOperationTargets(kUnit, UnitOperationTypes.RANGE_ATTACK );
        local pAllPlots = pResults[UnitOperationResults.PLOTS];
        if pAllPlots ~= nil then
          for i, modifier in ipairs( pResults[UnitOperationResults.MODIFIERS] ) do
            if modifier == UnitOperationResults.MODIFIER_IS_TARGET then
              if pAllPlots[i] == endPlotId then
                isImplicitRangedAttack = true;
                break;
              end
            end
          end
        end

        if isImplicitRangedAttack then
          -- Unit can apparently perform a ranged attack on that hex. Show the arrow!
          local kVariations:table = {};
          local kEmpty:table = {};
          table.insert(kVariations, {"EmptyVariant", startHexId, endHexId} );
          UILens.SetLayerHexesArea(g_AttackRange, eLocalPlayer, kEmpty, kVariations);

          -- Focus must be called AFTER the attack range variants are set.
          UILens.FocusHex( g_AttackRange, endHexId );
          return; -- We're done here. Do not show a movement path.
        end
      end

      -- Any plots of path in Fog Of War or midfog?
      local isPathInFog:boolean = false;
      local pPlayerVis :table = PlayersVisibility[eLocalPlayer];
      if pPlayerVis ~= nil then
        for _,plotIds in pairs(pathInfo.plots) do
          isPathInFog = not pPlayerVis:IsVisible(plotIds);
          if isPathInFog then
            break;
          end
        end
      end

      -- If any plots are in Fog Of War (FOW) then switch to the FOW movement lens.
      local lensNameBase      :string = "MovementGood";
      local movePostfix      :string = "";
      local isPathHaveRestriction,restrictedPlotId = IsPlotPathRestrictedForUnit( pathInfo.plots, pathInfo.turns, kUnit );

      if showQueuedPath then
        lensNameBase = "MovementQueue";
      elseif isPathHaveRestriction then
        lensNameBase = "MovementBad";
        m_isPlotFlaggedRestricted = true;
        if restrictedPlotId ~= nil and restrictedPlotId ~= -1 then
          table.insert(variations, {"MovementBad_Destination", restrictedPlotId} );
        end
      elseif isPathInFog then
        lensNameBase = "MovementFOW";
        movePostfix = "_FOW";
      end

      -- Turn on lens.
      if not UILens.IsLensActive(lensNameBase) then
        UILens.SetActive(lensNameBase);
      end

      -- is there an enemy unit at the end?
      local bIsEnemyAtEnd:boolean = false;
      local endPlot :table  = Map.GetPlotByIndex(endPlotId);
      if( endPlot ~= nil ) then
        local unitList  = Units.GetUnitsInPlotLayerID( endPlot:GetX(), endPlot:GetY(), MapLayers.ANY );
        for i, pUnit in ipairs(unitList) do
          if( eLocalPlayer ~= pUnit:GetOwner() and pPlayerVis ~= nil and pPlayerVis:IsVisible(endPlot:GetX(), endPlot:GetY()) and pPlayerVis:IsUnitVisible(pUnit) ) then
            bIsEnemyAtEnd = true;
          end
        end
      end

      -- Hide the destination indicator only if the attack is guaranteed this turn.
      -- Regular movements and attacks planned for later turns still get the indicator.
      if not showQueuedPath then
        table.insert(variations, {lensNameBase.."_Origin",startHexId} );
      end

      local nTurnCount :number = pathInfo.turns[table.count( pathInfo.turns )];
      if not bIsEnemyAtEnd or nTurnCount > 1 then
        table.insert(variations, {lensNameBase.."_Destination",endHexId} );
      end

      -- Since pathInfo.turns are matched against plots, this should be the same # as above.
      if table.count(pathInfo.turns) > 1 then
        -- Track any "holes" in the path.
        local pathHole:table = {};
        for i=1,table.count(pathInfo.plots),1 do
          pathHole[i] = true;
        end

        local lastTurn:number = 1;
        for i,value in pairs(pathInfo.turns) do
          -- If a new turn entry exists, or it's the very last entry of the path... show turn INFO.
          if value > lastTurn then
            if i > 1 then
              table.insert(variations, {lensNameBase.."_Counter", pathInfo.plots[i-1]} );                -- show counter pip
              UI.AddNumberToPath( lastTurn, pathInfo.plots[i-1] );
              pathHole[i-1]=false;
            end
            lastTurn = value;
          end

          if i == table.count(pathInfo.turns) and i > 1 then
            table.insert(variations, {lensNameBase.."_Counter", pathInfo.plots[i]} );                -- show counter pip
            UI.AddNumberToPath( lastTurn, pathInfo.plots[i] );
            if lastTurn == 2 then
              if m_previousTurnsCount == 1 then
                UI.PlaySound("UI_Multi_Turn_Movement_Alert");
              end
            end

            m_previousTurnsCount = lastTurn;
            pathHole[i]=false;
          end
        end

        -- Any obstacles? (e.g., rivers)
        if not showQueuedPath then
          local plotIndex:number = 1;
          for i,value in pairs(pathInfo.obstacles) do
            while( pathInfo.plots[plotIndex] ~= value ) do plotIndex = plotIndex + 1; end  -- Get ID to use for river's next plot
            table.insert(variations, {lensNameBase.."_Minus", value, pathInfo.plots[plotIndex+1]} );
          end
        end

        -- Any variations not filled in earlier (holes), are filled in with Pips
        for i,isHole in pairs(pathHole) do
          if isHole then
            table.insert(variations, {lensNameBase.."_Pip", pathInfo.plots[i]} );    -- non-counter pip
          end
        end
      end
    else
      -- No path; is it a bad path or is the player have the cursor on the same hex as the unit?
      local startPlotId :number = Map.GetPlot(kUnit:GetX(),kUnit:GetY()):GetIndex();
      if startPlotId ~= endPlotId then
        if not UILens.IsLensActive("MovementBad") then
          UILens.SetActive("MovementBad");
          lensNameBase = "MovementBad";
        end
        table.insert(pathInfo.plots, endPlotId);
        table.insert(variations, {"MovementBad_Destination", endPlotId} );
      else
        table.insert(pathInfo.plots, endPlotId);
        table.insert(variations, {"MovementGood_Destination", endPlotId} );
      end
    end

    -- Handle mountain tunnels
    -- TODO consider adding variations for entering/exiting portals
    local pPathSegment = { };
    for i,plot in pairs(pathInfo.plots) do

      -- Prepend an exit portal if one exists
      local pExit = pathInfo.exitPortals[i];
      if (pExit and pExit >= 0) then
        table.insert(pPathSegment, pExit);
      end

      -- Add the next plot to the segment
      table.insert(pPathSegment, plot);

      -- Append an entrance portal if one exists
      local pEntrance = pathInfo.entrancePortals[i];
      if (pEntrance and pEntrance >= 0) then
        table.insert(pPathSegment, pEntrance);

        -- Submit the segment so far and start a new segment
        UILens.SetLayerHexesPath(g_MovementPath, eLocalPlayer, pPathSegment, { });
        pPathSegment = { };
      end
    end

    -- Submit the final segment
    UILens.SetLayerHexesPath(g_MovementPath, eLocalPlayer, pPathSegment, variations);
  end
end


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
end
Initialize();
