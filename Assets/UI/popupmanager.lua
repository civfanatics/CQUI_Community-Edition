-- CQUI Modification Summary:
-- Allow for popups to show in multiplayer without locking the engine.
-- Firaxis' design of this file makes it difficult/impossible to just extend functions.
-- CQUI Modifications are marked in the file with BEGIN/END comments

-- Copyright 2019, Firaxis Games
-- Manager for (exclusive) popups that may request the engine to hold processing
-- until the player proceeds.

include("InputSupport");

-- === BEGIN CQUI CHANGES ====================================================
-- ===========================================================================
--  CQUI added ShouldUseDummyLock function
--  Check if Dummy Lock should be used instead of proper Engine Lock
--  Prevents locking the entire engine for multiplayer popups
-- ===========================================================================
function ShouldUseDummyLock(name:string)
    -- Check if multiplayer
    if (not GameConfiguration.IsAnyMultiplayer()) then
        -- Not multiplayer, use default behavior
        return false;
    end

    -- Check if one of the locking popups we allow
    if (name == "EraCompletePopupBase" or name == "NaturalWonderPopup" or name == "ProjectBuiltPopup" or name == "WonderBuiltPopup"
        or name == "EraCompletePopupXP1"
        or name == "EraCompletePopupXP2" or name == "NaturalDisasterPopup") then

        -- One of our locking popups, use dummy lock
        return true;
    end
    
    -- Not one of our locking popups, use default behavior
    return false;
end
-- === END CQUI CHANGES ======================================================

ExclusivePopupManager =
{
    -- ===========================================================================
    --  MEMBERS
    -- ===========================================================================
    m_name      = "";
    m_pContext  = nil;
    m_eventID   = 0;
    m_priority  = 0;

    -- ===========================================================================
    --  CTOR
    -- ===========================================================================
    new = function(self, name)
        local o = {};
        setmetatable(o, self);
        self.__index = self;
        if name==nil or name=="" then
            name = "UnsetName";
            local stack = where();
            UI.DataError("Attempt to create a PopupManager but no name passed in! stack:"..stack);
        end
        o.m_name = name; -- A name could be derived via the context's GetID() at lock time, but requiring an explicit name helps track down bugs.
        return o;
    end,

    -- ===========================================================================
    --  Performs engine lock for a series of popups to be shown.
    --  pContext        The context to popup.
    --  priority        What popup priority to put the popup on the queue.
    --  kParameters     (optional) Popup paramters.
    --  RETURNS true if lock was obtained
    -- ===========================================================================
    Lock = function( self, pContext:table, priority:number, kParameters:table )
        if self.m_eventID ~= 0 then
            UI.DataError("Attempt to re-lock '"..self.m_name.."' but it's already locked.  This should only happen once per batch.");
            return false;
        end
        if pContext == nil then 
            UI.DataError("Attempt to lock '"..self.m_name.."' but a nil context table was passed in.");
            return false;
        end

        self.m_pContext = pContext;
        self.m_priority = priority;

        -- === BEGIN CQUI CHANGES ====================================================
        if (ShouldUseDummyLock(self.m_name)) then
            self.m_eventID = -1; -- Dummy value for multiplayer
        else
            self.m_eventID = UI.ReferenceCurrentEvent();
        end
        -- === END CQUI CHANGES ======================================================

        print("PopupManager.LOCK   '"..self.m_name.."', id: "..tostring(self.m_eventID)..", priority:"..tostring(self.m_priority));
        if self.m_eventID == 0 then
            UI.DataError("Attempt to lock '"..self.m_name.."' but no locking event was returned from engine.");
            return false;
        end

        Input.PushActiveContext( InputContext.Reveal );
        if self.m_priority == nil then self.m_priority = PopupPriority.Current; end
        UIManager:QueuePopup( self.m_pContext, self.m_priority, kParameters);

        return true;
    end,

    -- ===========================================================================
    --  Releases only the sequence lock.  This is used by popups that want to 
    --  ransfer to using another event in the event queue
    -- ===========================================================================
    ReleaseSequenceLock = function( self )
        if self.m_eventID ~= 0 then
            UI.ReleaseEventID( self.m_eventID ); -- Release engine hold.
        end
    end,

    -- ===========================================================================
    --  Get a the sequence lock from the current event.
    -- ===========================================================================
    AcquireSequenceLock = function( self )
        if self.m_eventID ~= 0 then
            UI.ReleaseEventID( self.m_eventID ); -- Release engine hold.
        end

        -- === BEGIN CQUI CHANGES ====================================================
        if (ShouldUseDummyLock(self.m_name)) then
            self.m_eventID = -1; -- Dummy value for multiplayer
        else
            self.m_eventID = UI.ReferenceCurrentEvent();
        end
        -- === END CQUI CHANGES ======================================================
    end,

    -- ===========================================================================
    Unlock = function( self )
        if self.m_eventID == 0 then
            UI.DataError("Attempt to Unlock '"..self.m_name.."' but it's already unlocked!");
            if self.m_pContext:IsHidden() then -- Only leave early if this is already hidden.
                return;
            end
        end
        print("PopupManager.Unlock '"..self.m_name.."', id: "..tostring(self.m_eventID)..", priority:"..tostring(self.m_priority));
        UIManager:DequeuePopup( self.m_pContext );
        Input.PopContext();
        UI.ReleaseEventID( self.m_eventID ); -- Release engine hold.
        self.m_eventID = 0;        
        self.m_pContext = nil;
    end,

    -- ===========================================================================
    IsLocked = function(self)
        return (self.m_eventID ~= 0);
    end,

    -- ===========================================================================
    --  Serialize out (save)
    --  RETURNS: A table representing this object's internal state (minus Context)
    -- ===========================================================================
    ToTable = function(self)
        return {
            m_name = m_name,
            m_eventID = m_eventID,
            m_priority = m_priority
        }
    end,

    -- ===========================================================================
    --  Serialize in (restore)
    --  Context cannot be saved across the save, for if this is a hot reload then 
    --  the old context is gone, and so it needs to be passed in.
    -- ===========================================================================
    FromTable = function( self, kSerial:table, pContext:table )
        self.m_pContext = pContext;
        self.m_name        = kSerial.m_name;        
        self.m_eventID    = kSerial.m_eventID;
        self.m_priority    = kSerial.m_priority;
    end

}