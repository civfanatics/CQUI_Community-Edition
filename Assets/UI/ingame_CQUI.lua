include( "LocalPlayerActionSupport" );
include( "InputSupport" );
include( "Civ6Common" );

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_Initialize = Initialize;

-- ===========================================================================
-- CQUI Replacement Functions
-- These functions replace the unmodifed versions
-- ===========================================================================
DefaultMessageHandler[KeyEvents.KeyUp] =
  function( pInputStruct:table )
  -- This is the global default message handler for the KeyUp event, which is assigned to a function.
  -- Since the function is assigned directly like this, we cannot extend it, it has to be replaced.

    local uiKey = pInputStruct:GetKey();

    if( uiKey == Keys.VK_ESCAPE ) then
-- ==== CQUI CUSTOMIZATION BEGIN  ==================================================================================== --
      -- AZURENCY : if a unit or a city is selected, deselect and reset interface mode
      -- instead of showing the option menu immediatly
      if (UI.GetHeadSelectedCity() or UI.GetHeadSelectedUnit()) then
        UI.DeselectAll();
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
        return true;
      end
-- ==== CQUI CUSTOMIZATION END  ====================================================================================== --

      if( Controls.TopOptionsMenu:IsHidden() ) then
        OpenInGameOptionsMenu();
        return true;
      end

      return false;  -- Already open, let it handle it.
    elseif( uiKey == Keys.B and pInputStruct:IsShiftDown() and pInputStruct:IsAltDown() and (not UI.IsFinalRelease()) ) then
      -- DEBUG: Force unhiding
      local msg:string =  "***PLAYER Force Bulk unhiding SHIFT+ALT+B ***";
      UI.DataError(msg);
      m_bulkHideTracker = 1;
      BulkHide(false, msg);

    elseif( uiKey == Keys.J and pInputStruct:IsShiftDown() and pInputStruct:IsAltDown() and (not UI.IsFinalRelease()) ) then
      if m_bulkHideTracker < 1 then
        BulkHide(true,  "Forced" );
      else
        BulkHide(false, "Forced" );
      end
    end

    return false;
  end

-- ===========================================================================
-- CQUI Custom Functions
-- ===========================================================================
function CQUI_RequestUIAddin( request: string ) --Returns the first context to match the request string. Returns nil if a matching context can't be found
  for _,v in ipairs(g_uiAddins) do
    if(v:GetID() == request) then
      return v;
    end
  end
end

-- ===========================================================================
-- CQUI Initialize Extension
-- ===========================================================================
function Initialize()
  BASE_CQUI_Initialize();
  --CQUI event handling
  LuaEvents.CQUI_RequestUIAddin.Add(function(request: string, requester: string) LuaEvents.CQUI_PushUIAddIn(CQUI_RequestUIAddin(request), recipient); end); --Responds to an addin request with a PushUIAddIn event containing the requested context. Can return nil
end
Initialize();