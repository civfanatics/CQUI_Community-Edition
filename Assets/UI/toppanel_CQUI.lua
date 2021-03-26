-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_LateInitialize = LateInitialize;
BASE_CQUI_RefreshResources = RefreshResources;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_showLuxury = true;

function CQUI_OnSettingsInitialized()
    CQUI_showLuxury = GameConfiguration.GetValue("CQUI_ShowLuxuries"); -- Infixo, issue #44
end

function CQUI_OnSettingsUpdate()
    CQUI_showLuxury = GameConfiguration.GetValue("CQUI_ShowLuxuries");
    RefreshResources();
end

-- ===========================================================================
--  CQUI modified RefreshResources functiton
--  Show luxury resources
-- ===========================================================================
function RefreshResources()
    BASE_CQUI_RefreshResources();

    local localPlayerID = Game.GetLocalPlayer();
    if localPlayerID == PlayerTypes.NONE or localPlayerID == PlayerTypes.OBSERVER then return; end
    
    local pPlayerResources:table = Players[localPlayerID]:GetResources();
    local yieldStackX:number = Controls.YieldStack:GetSizeX();
    local infoStackX:number = Controls.StaticInfoStack:GetSizeX();
    local metaStackX:number = Controls.RightContents:GetSizeX();
    local screenX, _:number = UIManager:GetScreenSizeVal();
    local maxSize:number = math.max(screenX - yieldStackX - infoStackX - metaStackX - META_PADDING, 0);
    local currSize:number = 0;
    local isOverflow:boolean = false;
    local overflowString:string = "";
    local plusInstance:table = nil;

    -- CQUI/jhcd: show RESOURCECLASS_LUXURY too, if it is enabled in CQUI settings
    if CQUI_showLuxury then
        for resource in GameInfo.Resources() do
            if resource.ResourceClassType == "RESOURCECLASS_LUXURY" then -- it cleary says "show luxuries in the top panel"...
                local amount:number = pPlayerResources:GetResourceAmount(resource.ResourceType);
                if amount > 0 then
                    local resourceText = "[ICON_"..resource.ResourceType.."] ".. amount;
                    local numDigits:number = (amount >= 10 and 4 or 3);
                    local guessinstanceWidth:number = math.ceil(numDigits * FONT_MULTIPLIER);
                    if currSize + guessinstanceWidth < maxSize and not isOverflow then
                        local instance:table = m_kResourceIM:GetInstance();
                        instance.ResourceText:SetText(resourceText);
                        instance.ResourceText:SetToolTipString(Locale.Lookup(resource.Name).."[NEWLINE]"..Locale.Lookup("LOC_TOOLTIP_LUXURY_RESOURCE"));
                        currSize = currSize + instance.ResourceText:GetSizeX();
                    else
                        if not isOverflow then
                            overflowString = amount.. "[ICON_"..resource.ResourceType.."]".. Locale.Lookup(resource.Name);
                            local instance:table = m_kResourceIM:GetInstance();
                            instance.ResourceText:SetText("[ICON_Plus]");
                            plusInstance = instance.ResourceText;
                        else
                            overflowString = overflowString .. "[NEWLINE]".. amount.. "[ICON_"..resource.ResourceType.."]".. Locale.Lookup(resource.Name);
                        end
                        isOverflow = true;
                    end
                end -- amount > 0
            end -- if luxury
        end -- for
    end -- CQUI_showLuxury

    if plusInstance ~= nil then
        plusInstance:SetToolTipString(overflowString);
    end
    Controls.ResourceStack:CalculateSize();
    Controls.Resources:SetHide( Controls.ResourceStack:GetSizeX() == 0 );
end

-- ===========================================================================
--  CQUI modified OnToggleReportsScreen functiton
--  Moved this to launchbar.lua since we moved the button there 
-- ===========================================================================
function OnToggleReportsScreen()
end

-- ===========================================================================
function LateInitialize()
    BASE_CQUI_LateInitialize();

    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsInitialized ); -- Infixo, issue #44
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);

    if Controls.ViewReports then
        Controls.ViewReports:SetHide(true); -- CQUI : hide the report button, moved to launchbar
    end
end
