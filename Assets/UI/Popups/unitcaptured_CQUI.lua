-- ===========================================================================
-- Base File
-- ===========================================================================
include("UnitCaptured");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnUnitCaptured = OnUnitCaptured;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
-- Base file local variables copied for use here
local m_HexColoringWaterAvail : number = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity");

-- CQUI added variables
local m_IsSinglePlayerGame          :boolean = not GameConfiguration.IsAnyMultiplayer();
local CQUI_UnitCapturedPopupVisual  :boolean = m_IsSinglePlayerGame;
local CQUI_MultiplayerPopups        :boolean = false;

-- ===========================================================================
--  FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--  CQUI added CQUI_OnSettingsUpdate function
--  Update the local variables based on the user settings
-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- Get the user settings
    CQUI_UnitCapturedPopupVisual = GameConfiguration.GetValue("CQUI_UnitCapturedPopupVisual");
    CQUI_MultiplayerPopups = GameConfiguration.GetValue("CQUI_MultiplayerPopups");

    -- Check to allow in multiplayer
    if (not CQUI_MultiplayerPopups) then
        CQUI_UnitCapturedPopupVisual = CQUI_UnitCapturedPopupVisual and m_IsSinglePlayerGame;
    end
end

-- ===========================================================================
--  CQUI modified OnUnitCaptured function
--  Setting to not show popup
-- ===========================================================================
function OnUnitCaptured( currentUnitOwner, unit, owningPlayer, capturingPlayer )
    -- Check if the popup setting is disabled
    if (not CQUI_UnitCapturedPopupVisual) then

        -- Make sure this part of the base function executes
        local localPlayer = Game.GetLocalPlayer();
        if (localPlayer == currentUnitOwner and localPlayer ~= capturingPlayer and UILens.IsLayerOn(m_HexColoringWaterAvail) and UI.GetInterfaceMode() ~= InterfaceModeTypes.VIEW_MODAL_LENS) then
            UILens.ToggleLayerOff(m_HexColoringWaterAvail);    
        end

        -- The popup is disabled, so stop here
        return;
    end

    -- Base function
    BASE_CQUI_OnUnitCaptured(currentUnitOwner, unit, owningPlayer, capturingPlayer);
end

-- ===========================================================================
--  CQUI added Initialize_UnitCaptured_CQUI function
--  Initialize the context
-- ===========================================================================
function Initialize_UnitCaptured_CQUI()
    -- Original file does not inititalize the following on AnyMultiplayer
    -- Initialize it here for multiplayer to optionally allow popups in multiplayer
    if (GameConfiguration.IsAnyMultiplayer()) then
        Events.UnitCaptured.Add(OnUnitCaptured);

    else
        -- If already inititalized, replace the event function with our new one
        Events.UnitCaptured.Remove(BASE_CQUI_OnUnitCaptured);
        Events.UnitCaptured.Add(OnUnitCaptured);
    end

    -- Add the CQUI Settings function to the LuaEvent
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end

-- Start Initialize
Initialize_UnitCaptured_CQUI();