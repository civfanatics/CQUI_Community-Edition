-- ===========================================================================
-- Includes
-- ===========================================================================
include("CQUICommon.lua");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnEraComplete = OnEraComplete;
BASE_CQUI_OnCheckGameEraChanged = OnCheckGameEraChanged;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local m_IsSinglePlayerGame          :boolean = not GameConfiguration.IsNetworkMultiplayer();
local CQUI_EraCompletePopupVisual   :boolean = m_IsSinglePlayerGame;
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
    CQUI_EraCompletePopupVisual = GameConfiguration.GetValue("CQUI_EraCompletePopupVisual");
    CQUI_MultiplayerPopups = GameConfiguration.GetValue("CQUI_MultiplayerPopups");

    -- Check to allow in multiplayer
    if (not CQUI_MultiplayerPopups) then
        CQUI_EraCompletePopupVisual = CQUI_EraCompletePopupVisual and m_IsSinglePlayerGame;
    end
end

-- ===========================================================================
--  CQUI modified OnEraComplete function (Base game function)
--  Show visual based on CQUI settings
-- ===========================================================================
function OnEraComplete( playerIndex:number, currentEra:number )
    if (CQUI_EraCompletePopupVisual) then
        BASE_CQUI_OnEraComplete(playerIndex, currentEra);
    end
end

-- ===========================================================================
--  CQUI modified OnCheckGameEraChanged function (Expansion 1 and 2 function)
--  Show visual based on CQUI settings
-- ===========================================================================
function OnCheckGameEraChanged()
    if (CQUI_EraCompletePopupVisual) then
        BASE_CQUI_OnCheckGameEraChanged();
    end
end

-- ===========================================================================
--  CQUI added Initialize_EraCompletePopup_CQUI function
--  Initialize the context
-- ===========================================================================
function Initialize_EraCompletePopup_CQUI()

    -- Base game specific initialization
    if (g_bIsBaseGame) then
        -- Stop if the game doesn't have eras
        if (not GameCapabilities.HasCapability("CAPABILITY_ERAS")) then
            return;
        end

        -- Original file does not inititalize the following on NetworkMultiplayer
        -- Initialize it here for multiplayer to optionally allow popups in multiplayer
        if (GameConfiguration.IsNetworkMultiplayer()) then
            ContextPtr:SetInputHandler( OnInputHandler, true );
            ContextPtr:SetShowHandler( OnShow );
            ContextPtr:SetInitHandler( OnInit );
            ContextPtr:SetShutdown( OnShutdown );

            LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);

            Controls.EraPopupAnimation:RegisterEndCallback( OnEraPopupAnimationEnd );

            Events.SystemUpdateUI.Add( OnUpdateUI );    
            Events.PlayerEraChanged.Add( OnEraComplete );

        else
            -- Replace the event function with our new one
            Events.PlayerEraChanged.Remove( BASE_CQUI_OnEraComplete );
            Events.PlayerEraChanged.Add( OnEraComplete );
        end

    else
        -- Expansion 1 and 2 specific initialization (same for both expansions)
        if (GameConfiguration.IsHotseat()) then
            -- Replace the Hotseat specific event functions with our new ones
            LuaEvents.PlayerChange_Close.Remove( BASE_CQUI_OnCheckGameEraChanged );
            LuaEvents.PlayerChange_Close.Add( OnCheckGameEraChanged );

        elseif (GameConfiguration.IsNetworkMultiplayer()) then
            -- Original file does not inititalize the following on NetworkMultiplayer
            -- Initialize it here for multiplayer to optionally allow popups in multiplayer
            Events.LocalPlayerTurnBegin.Add( OnCheckGameEraChanged );

        else
            -- Replace the event function with our new one
            Events.LocalPlayerTurnBegin.Remove( BASE_CQUI_OnCheckGameEraChanged );
            Events.LocalPlayerTurnBegin.Add( OnCheckGameEraChanged );
        end
    end

    -- Add the CQUI Settings function to the LuaEvent
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end

-- Start Initialize
Initialize_EraCompletePopup_CQUI();