-- ===========================================================================
--  Includes
-- ===========================================================================
-- Nothing to include

-- ===========================================================================
--  Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnProcessNotification = OnProcessNotification;

-- ===========================================================================
--  CQUI Members
-- ===========================================================================
local CQUI_HistoricMomentsPopupVisual :boolean = true;

-- ===========================================================================
--  FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--  CQUI added CQUI_OnSettingsUpdate function
--  Update the local variables based on the user settings
-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- Get the user settings
    CQUI_HistoricMomentsPopupVisual = GameConfiguration.GetValue("CQUI_HistoricMomentsPopupVisual");
end

-- ===========================================================================
--  CQUI modified OnProcessNotification function
--  Only show visual automatically based on user settings or actions
-- ===========================================================================
function OnProcessNotification(playerID :number, notificationID :number, activatedByUser :boolean)
    -- Check if allowed by settings or if the user activated the notification
    if (CQUI_HistoricMomentsPopupVisual or activatedByUser) then
        BASE_CQUI_OnProcessNotification(playerID, notificationID, activatedByUser);
    end
end

-- ===========================================================================
--  CQUI added Initialize_HistoricMoments_CQUI function
--  Initialize the context
-- ===========================================================================
function Initialize_HistoricMoments_CQUI()
    -- Stop if the game doesn't support historic moments
    if (not GameCapabilities.HasCapability("CAPABILITY_HISTORIC_MOMENTS")) then
        return;
    end

    -- Replace the event function with our new one
    Events.NotificationActivated.Remove( BASE_CQUI_OnProcessNotification );
    Events.NotificationActivated.Add( OnProcessNotification );

    -- LuaEvent to optionally allow popup in multiplayer
    LuaEvents.CQUI_ProcessHistoricMoment.Add( OnProcessNotification );

    -- Add the CQUI settings function to the LuaEvents
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end

-- Start Initialize
Initialize_HistoricMoments_CQUI();