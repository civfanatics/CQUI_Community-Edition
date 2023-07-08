-- ===========================================================================
-- Base File
-- ===========================================================================
include("ProjectBuiltPopup");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnProjectComplete = OnProjectComplete;
BASE_CQUI_ShowPopup = ShowPopup;
BASE_CQUI_Close = Close;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local m_IsSinglePlayerGame      :boolean = not GameConfiguration.IsAnyMultiplayer();
local CQUI_ProjectBuiltVisual   :boolean = m_IsSinglePlayerGame;
local CQUI_MultiplayerPopups    :boolean = false;

-- ===========================================================================
--  FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--  CQUI added CQUI_OnSettingsUpdate function
--  Update the local variables based on the user settings
-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- Get the user settings
    CQUI_ProjectBuiltVisual = GameConfiguration.GetValue("CQUI_ProjectBuiltPopupVisual");
    CQUI_MultiplayerPopups = GameConfiguration.GetValue("CQUI_MultiplayerPopups");

    -- Check to allow in multiplayer
    if (not CQUI_MultiplayerPopups) then
        CQUI_ProjectBuiltVisual = CQUI_ProjectBuiltVisual and m_IsSinglePlayerGame;
    end
end

-- ===========================================================================
--  CQUI modified OnProjectComplete function
--  Only show visual based on user settings
-- ===========================================================================
function OnProjectComplete(playerID:number, cityID:number, projectIndex, buildingIndex:number, locX:number, locY:number, bCanceled:boolean)
    if (CQUI_ProjectBuiltVisual) then
        BASE_CQUI_OnProjectComplete(playerID, cityID, projectIndex, buildingIndex, locX, locY, bCanceled);
    end
end

-- ===========================================================================
--  CQUI modified ShowPopup function
--  Show a camera animation when in multiplayer
-- ===========================================================================
function ShowPopup( kData:table )
    -- Base function
    BASE_CQUI_ShowPopup(kData);

    -- The camera animation does not work on multiplayer
    -- As a workaround, use the Rock Band camera animation if on multiplayer
    -- If this animation doesn't exist for some reason, nothing happens
    if (not m_IsSinglePlayerGame) then
        Events.PlayCameraAnimationAtHex("ROCK_BAND_CONCERT_CAMERA", kData.locX, kData.locY, 0.0, true);
    end
end

-- ===========================================================================
--  CQUI modified Close function
--  Stop the camera animation when in multiplayer
-- ===========================================================================
function Close()
	-- Stop the multiplayer camera animation
	if (not m_IsSinglePlayerGame) then
		Events.StopAllCameraAnimations();
	end

    -- Base function
    BASE_CQUI_Close();
end

-- ===========================================================================
--  CQUI added Initialize_ProjectBuiltPopup_CQUI function
--  Initialize the context
-- ===========================================================================
function Initialize_ProjectBuiltPopup_CQUI()

    -- Original file does not inititalize the following on AnyMultiplayer
    -- Initialize it here for multiplayer to optionally allow popups in multiplayer
    if (GameConfiguration.IsAnyMultiplayer()) then
        ContextPtr:SetInputHandler( OnInputHandler, true );
        Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
        Controls.ScreenConsumer:RegisterCallback(Mouse.eRClick, OnClose);

        Events.CityProjectCompletedNarrative.Add( OnProjectComplete );
        Events.SystemUpdateUI.Add( OnUpdateUI );

        -- Hot-Reload Events
        ContextPtr:SetInitHandler( OnInit );
        ContextPtr:SetShutdown( OnShutdown );
        LuaEvents.GameDebug_Return.Add( OnGameDebugReturn );

    else
        -- Replace the event functions with our new ones
        Events.CityProjectCompletedNarrative.Remove( BASE_CQUI_OnProjectComplete );
        Events.CityProjectCompletedNarrative.Add( OnProjectComplete );
    end

    -- Initialize CQUI Settings function
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end

-- Start Initialize
Initialize_ProjectBuiltPopup_CQUI();