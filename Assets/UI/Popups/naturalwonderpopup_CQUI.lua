-- ===========================================================================
-- Base File
-- ===========================================================================
include("NaturalWonderPopup");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_ShowPopup = ShowPopup;
BASE_CQUI_OnNaturalWonderRevealed = OnNaturalWonderRevealed;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local m_IsSinglePlayerGame      :boolean = not (GameConfiguration.IsAnyMultiplayer() or GameConfiguration.IsHotseat());
local CQUI_NaturalWonderVisual  :boolean = m_IsSinglePlayerGame;
local CQUI_NaturalWonderAudio   :boolean = m_IsSinglePlayerGame;
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
    CQUI_NaturalWonderVisual = GameConfiguration.GetValue("CQUI_NaturalWonderPopupVisual");
    CQUI_NaturalWonderAudio = GameConfiguration.GetValue("CQUI_NaturalWonderPopupAudio");
    CQUI_MultiplayerPopups = GameConfiguration.GetValue("CQUI_MultiplayerPopups");

    -- Check to allow in multiplayer
    if (not CQUI_MultiplayerPopups) then
        CQUI_NaturalWonderVisual = CQUI_NaturalWonderVisual and m_IsSinglePlayerGame;
        CQUI_NaturalWonderAudio = CQUI_NaturalWonderAudio and m_IsSinglePlayerGame;
    end
end

-- ===========================================================================
--  CQUI modified ShowPopup function
--  Setting to disable wonder quote audio
-- ===========================================================================
function ShowPopup( kData:table )
    -- Remove quote audio if not allowed by user settings
    if (not CQUI_NaturalWonderAudio) then
        kData.QuoteAudio = nil;
    end

    -- Base function
    BASE_CQUI_ShowPopup(kData)
    
    -- The camera animation does not work on multiplayer
    -- As a workaround, use the Rock Band camera animation if on multiplayer
    -- If this animation doesn't exist for some reason, nothing happens
    if (not m_IsSinglePlayerGame) then
        Events.PlayCameraAnimationAtHex("ROCK_BAND_CONCERT_CAMERA", kData.plotx, kData.ploty, 0.0, true);
    end
end

-- ===========================================================================
--  CQUI modified OnNaturalWonderRevealed function
--  Setting to disable wonder movie and audio
-- ===========================================================================
function OnNaturalWonderRevealed( plotx:number, ploty:number, eFeature:number, isFirstToFind:boolean )
    -- Check for autoplay
    local localPlayer = Game.GetLocalPlayer();    
    if (localPlayer < 0) then
        return;
    end

    -- Check if human player
    if (not Players[localPlayer]:IsHuman()) then 
        return;
    end

    -- Check if valid info table
    local info:table = GameInfo.Features[eFeature];
    if (info == nil) then
        return;
    end

    -- Only play the visual if allowed by user settings
    if (not CQUI_NaturalWonderVisual) then
        -- If there is valid quote audio, play it if allowed by user settings
        if (info.QuoteAudio ~= nil and CQUI_NaturalWonderAudio) then
            UI.PlaySound(info.QuoteAudio);
        end

        -- Stop to avoid doing the work for the visaul
        return;
    end

    -- Base function
    BASE_CQUI_OnNaturalWonderRevealed(plotx, ploty, eFeature, isFirstToFind);
end

-- ===========================================================================
--  CQUI added Initialize_NaturalWonderPopup_CQUI function
--  Initialize the context
-- ===========================================================================
function Initialize_NaturalWonderPopup_CQUI()

    -- Original file does not inititalize the following on AnyMultiplayer or Hotseat
    -- Initialize it here for multiplayer to optionally allow popups in multiplayer
    if GameConfiguration.IsAnyMultiplayer() or GameConfiguration.IsHotseat() then
        ContextPtr:SetInputHandler( OnInputHander, true );
        Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
        Controls.ScreenConsumer:RegisterCallback(Mouse.eRClick, OnClose);

        Events.NaturalWonderRevealed.Add( OnNaturalWonderRevealed );
        Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );    
        Events.CameraAnimationStopped.Add( OnCameraAnimationStopped );
        Events.CameraAnimationNotFound.Add( OnCameraAnimationNotFound );

        -- Hot-Reload Events
        ContextPtr:SetInitHandler( OnInit );
        ContextPtr:SetShutdown( OnShutdown );
        LuaEvents.GameDebug_Return.Add( OnGameDebugReturn );

    else
        -- If already inititalized, replace the event function with our new one
        Events.NaturalWonderRevealed.Remove( BASE_CQUI_OnNaturalWonderRevealed );
        Events.NaturalWonderRevealed.Add( OnNaturalWonderRevealed );
    end

    -- Add the CQUI Settings function to the LuaEvent
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end

-- Start Initialize
Initialize_NaturalWonderPopup_CQUI();
