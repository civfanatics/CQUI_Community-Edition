-- ===========================================================================
--  Base File
-- ===========================================================================
include("RockBandPopup");

-- ===========================================================================
--  Cached Base Functions
-- ===========================================================================
BASE_CQUI_LateInitialize = LateInitialize;

-- ===========================================================================
--  CQUI Members
-- ===========================================================================
local m_IsSinglePlayerGame              :boolean = not GameConfiguration.IsAnyMultiplayer();
local CQUI_RockBandMoviePopupVisual     :boolean = m_IsSinglePlayerGame;
local CQUI_MultiplayerPopups            :boolean = false;

-- ===========================================================================
--  FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--  CQUI added CQUI_OnSettingsUpdate function
--  Update the local variables based on the user settings
-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- Get the user settings
    CQUI_RockBandMoviePopupVisual = GameConfiguration.GetValue("CQUI_RockBandMoviePopupVisual");
    CQUI_MultiplayerPopups = GameConfiguration.GetValue("CQUI_MultiplayerPopups");

    -- Check to allow in multiplayer
    if (not CQUI_MultiplayerPopups) then
        CQUI_RockBandMoviePopupVisual = CQUI_RockBandMoviePopupVisual and m_IsSinglePlayerGame;
    end
end

-- ===========================================================================
--  CQUI modified OnConcert function
--  Only call Open() if the popup movie is disabled
--  The popup movie will call Open() itself directly
-- ===========================================================================
function OnConcert( ownerID:number, unitID:number, unitX:number, unitY:number, result:number, totalTourism:number )
    local localPlayer:number = Game.GetLocalPlayer();
    if (localPlayer < 0 or ownerID ~= localPlayer) then
        return;
    end

    if (not CQUI_RockBandMoviePopupVisual) then
        Open(ownerID, unitID, result, totalTourism);
    end
end

-- ===========================================================================
--  CQUI modified LateInitialize function
--  Optionally allow popups in multiplayer
-- ===========================================================================
function LateInitialize()
    -- Base function
    BASE_CQUI_LateInitialize();

    -- Add this function to the event if not in multiplayer
    -- The base function will not have done this if this is not multiplayer
    if (not GameConfiguration.IsAnyMultiplayer()) then
        Events.PostTourismBomb.Add(OnConcert);
    end
end

-- ===========================================================================
--  CQUI added Initialize_RockBandPopup_CQUI function
--  Initialize the context
-- ===========================================================================
function Initialize_RockBandPopup_CQUI()
    -- Add the CQUI settings function to the LuaEvents
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end

-- Start Initialize
Initialize_RockBandPopup_CQUI();