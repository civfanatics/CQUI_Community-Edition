include( "InGameTopOptionsMenu" );

-- ===========================================================================
--	OVERRIDES
-- ===========================================================================
BASE_CQUI_LateInitialize = LateInitialize;

function LateInitialize()	
    BASE_CQUI_LateInitialize();

    -- This is added in order to allow CQUI to close the Top Options menu from a different Lua context
    LuaEvents.InGame_CloseInGameOptionsMenu.Add( OnReturn );
end

