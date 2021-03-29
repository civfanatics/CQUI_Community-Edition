-- ===========================================================================
--	Map Pin Manager
--	Manages all the map pins on the world map.
-- ===========================================================================

include( "MapPinManager" );


-- ===========================================================================
-- CQUI Members
-- ===========================================================================

local CQUI_isShiftDown:boolean = false;


-- ===========================================================================
-- CQUI Replacements
-- ===========================================================================

function OnMapPinFlagRightClick( playerID : number, pinID : number )
    -- TODO it might be nice to enable this if shift is down
    -- If we are the owner of this pin, delete the pin.
    if CQUI_isShiftDown and playerID == Game.GetLocalPlayer() then
        local playerCfg = PlayerConfigurations[playerID];
        playerCfg:DeleteMapPin(pinID);
        Network.BroadcastPlayerInfo();
        UI.PlaySound("Map_Pin_Remove");
    end
end


-- ===========================================================================
--  Input
--  UI Event Handler
-- ===========================================================================

function OnInputHandler( pInputStruct:table )
    local uiMsg = pInputStruct:GetMessageType();
    if uiMsg == KeyEvents.KeyDown then
        if pInputStruct:GetKey() == Keys.VK_SHIFT then
            CQUI_isShiftDown = true;
            -- let it fall through
        end
    end
    if uiMsg == KeyEvents.KeyUp then
        if pInputStruct:GetKey() == Keys.VK_SHIFT then
            CQUI_isShiftDown = false;
            -- let it fall through
        end
    end
    return false;
end


-- ===========================================================================
function Initialize_MapPinManager_CQUI()
    ContextPtr:SetInputHandler( OnInputHandler, true );
end
Initialize_MapPinManager_CQUI();
