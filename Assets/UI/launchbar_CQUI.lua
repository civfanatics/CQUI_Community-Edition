include( "GameCapabilities" );
include( "GovernorSupport" );

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnOpen = OnOpen;
BASE_CQUI_RefreshGovernors = RefreshGovernors;
BASE_CQUI_LateInitialize = LateInitialize;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
-- Launchbar Extras. Contains the callback and the button text
local m_LaunchbarExtras:table = {};

-- ===========================================================================
-- CQUI Extension Functions
-- These functions replace the unmodifed versions
-- ===========================================================================
function OnOpen()
    local screenX, screenY:number = UIManager:GetScreenSizeVal();
    if screenY <= 850 then
        Controls.ScienceHookWithMeter:SetOffsetY(-5);
        Controls.CultureHookWithMeter:SetOffsetY(-5);
    end

    BASE_CQUI_OnOpen();
end

-- ===========================================================================
-- CQUI: Unique Functions
-- These functions are unique to CQUI, do not exist in the Base WorldInput.lua
-- ===========================================================================
function BuildExtraEntries()
    -- Clear previous entries
    Controls.LaunchExtraStack:DestroyAllChildren();
  
    for key, entryInfo in pairs(m_LaunchbarExtras) do
        local tButtonEntry:table = {};
    
        -- Get Button Info
        local fCallback = function() entryInfo.Callback(); OnCloseExtras(); end;
        local sButtonText = Locale.Lookup(entryInfo.Text)
        ContextPtr:BuildInstanceForControl("LaunchExtraEntry", tButtonEntry, Controls.LaunchExtraStack);
    
        tButtonEntry.Button:SetText(sButtonText);
        tButtonEntry.Button:RegisterCallback(Mouse.eLClick, fCallback);
    
        if entryInfo.Tooltip ~= nil then
            local sTooltip = Locale.Lookup(entryInfo.Tooltip)
            tButtonEntry.Button:SetToolTipString(sTooltip);
        else
            tButtonEntry.Button:SetToolTipString("");
        end
    end
  
    -- Cleanup
    Controls.LaunchExtraStack:CalculateSize();
    Controls.LaunchExtraStack:ReprocessAnchoring();
    Controls.LaunchExtraWrapper:DoAutoSize();
    Controls.LaunchExtraWrapper:ReprocessAnchoring();
end

-- ===========================================================================
function OnCloseExtras()
    Controls.LaunchExtraControls:SetHide(true);
    Controls.LaunchExtraShow:SetCheck(false);
end

-- ===========================================================================
function OnToggleExtras()
    if Controls.LaunchExtraShow:IsChecked() then
        Controls.LaunchExtraControls:SetHide(true);

        Controls.LaunchExtraAlpha:SetToBeginning();
        Controls.LaunchExtraSlide:SetToBeginning();

        Controls.LaunchExtraAlpha:Play();
        Controls.LaunchExtraSlide:Play();

        Controls.LaunchExtraControls:SetHide(false);

        BuildExtraEntries();
    else
        OnCloseExtras();
    end
end

-- ===========================================================================
function OnAddExtraEntry(entryKey:string, entryInfo:table)
    -- Add info at key. Overwrite if they key already exists.
    m_LaunchbarExtras[entryKey] = entryInfo;
    -- show the button
    Controls.LaunchExtraShow:SetHide(false);
end

-- ===========================================================================
function OnAddLaunchbarIcon(buttonInfo:table)
    local tButtonEntry:table = {};
    ContextPtr:BuildInstanceForControl("LaunchbarButtonInstance", tButtonEntry, Controls.ButtonStack);

    local textureOffsetX = buttonInfo.IconTexture.OffsetX;
    local textureOffsetY = buttonInfo.IconTexture.OffsetY;
    local textureSheet = buttonInfo.IconTexture.Sheet;

    -- Update Icon Info
    if (textureOffsetX ~= nil and textureOffsetY ~= nil and textureSheet ~= nil) then
        tButtonEntry.Image:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
    end
    if (buttonInfo.IconTexture.Color ~= nil) then
        tButtonEntry.Image:SetColor(buttonInfo.IconTexture.Color);
    end

    if (buttonInfo.Tooltip ~= nil) then
        tButtonEntry.Button:SetToolTipString(buttonInfo.Tooltip);
    end

    textureOffsetX = buttonInfo.BaseTexture.OffsetX;
    textureOffsetY = buttonInfo.BaseTexture.OffsetY;
    textureSheet = buttonInfo.BaseTexture.Sheet;

    local stateOffsetX = buttonInfo.BaseTexture.HoverOffsetX;
    local stateOffsetY = buttonInfo.BaseTexture.HoverOffsetY;

    if (textureOffsetX ~= nil and textureOffsetY ~= nil and textureSheet ~= nil) then
        tButtonEntry.Base:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
        if (buttonInfo.BaseTexture.Color ~= nil) then
            tButtonEntry.Base:SetColor(buttonInfo.BaseTexture.Color);
        end

        -- Setup behaviour on hover
        if (stateOffsetX ~= nil and stateOffsetY ~= nil) then
            local OnMouseOver = function()
                tButtonEntry.Base:SetTextureOffsetVal(stateOffsetX, stateOffsetY);
                UI.PlaySound("Main_Menu_Mouse_Over");
                end

            local OnMouseExit = function()
                tButtonEntry.Base:SetTextureOffsetVal(textureOffsetX, textureOffsetY);
                end

            tButtonEntry.Button:RegisterMouseEnterCallback( OnMouseOver );
            tButtonEntry.Button:RegisterMouseExitCallback( OnMouseExit );
        end
    end

    if (buttonInfo.Callback ~= nil) then
        tButtonEntry.Button:RegisterCallback( Mouse.eLClick, buttonInfo.Callback );
    end

    RefreshView();
end

-- ===========================================================================
function TestLaunchBarExtension()
    -- NOTE: This function is not called, exists to be called if wanting to test should we ever decide to add things here
    -- Running this method shows how to add items to the "extra" menu that is made visible by clicking on the small circle next to the Science/Culture/Government/etc (in the LaunchBar)
    LuaEvents.LaunchBar_AddExtra("Test1", {Text="Test1", Callback=function() print("Test1") end, Tooltip="Test1"})
    LuaEvents.LaunchBar_AddExtra("Test2", {Text="Test2", Callback=function() print("Test2") end})

    local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas("ICON_BUILDING_MONUMENT", 38);
    local buttonInfo = {
        -- ICON TEXTURE
        IconTexture = {
        OffsetX = textureOffsetX;
        OffsetY = textureOffsetY+3;
        Sheet = textureSheet;
        };

        -- BUTTON TEXTURE
        BaseTexture = {
        OffsetX = 0;
        OffsetY = 0;
        Sheet = "LaunchBar_Hook_ReligionButton";

        -- Offset to have when hovering
        HoverOffsetX = 0;
        HoverOffsetY = 49;
        };

        -- BUTTON INFO
        Callback = function() print("Agora!") end;
        Tooltip = "Agora";
    }

    LuaEvents.LaunchBar_AddIcon(buttonInfo);

    textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas("ICON_UNIT_JAPANESE_SAMURAI", 38);
    local button2Info = {
        -- ICON TEXTURE
        IconTexture = {
        OffsetX = textureOffsetX;
        OffsetY = textureOffsetY+3;
        Sheet = textureSheet;
        Color = UI.GetColorValue("COLOR_PLAYER_BARBARIAN_PRIMARY");
        };

        -- BASE TEXTURE (Treat it as Button Texture)
        BaseTexture = {
        OffsetX = 0;
        OffsetY = 147;
        Sheet = "LaunchBar_Hook_GreatPeopleButton";
        -- Color = UI.GetColorValue("COLOR_BLUE");
        HoverOffsetX = 0;
        HoverOffsetY = 0;
        };

        -- BUTTON INFO
        Callback = function() print("ATTACK!") end;
        -- Tooltip = "barbs...";
    }

    LuaEvents.LaunchBar_AddIcon(button2Info);
end

-- ===========================================================================
-- CQUI extended RefreshGovernors
-- Also show the alert indicator if a governor is assignable
-- ===========================================================================
function RefreshGovernors()
    -- Autoplay
    if (Game.GetLocalPlayer() == -1) then
        return;
    end

    -- Base function
    BASE_CQUI_RefreshGovernors();

    local pPlayer            :table   = Players[Game.GetLocalPlayer()];
    local pPlayerGovernors   :table   = pPlayer:GetGovernors();
    local bCanAppoint        :boolean = pPlayerGovernors:CanAppoint();
    local bCanPromote        :boolean = pPlayerGovernors:CanPromote();

    -- Stop if a governor can be appointed or promoted
    -- The indicator will already be showing, so no point in checking if a governor can be assigned
    if (bCanAppoint or bCanPromote) then
        return;
    end

    local bCanAssign :boolean = false;
    local bHasGovernors, tGovernorList = pPlayerGovernors:GetGovernorList();

    for _, pAppointedGovernor in ipairs(tGovernorList) do
        -- Check if a governor is not assigned to a city and is not currently neutralized
        if (not pAppointedGovernor:GetAssignedCity() and pAppointedGovernor:GetNeutralizedTurns() == 0) then
            local eGovernorType:number = pAppointedGovernor:GetType();
            local kGovernorDef:table = GameInfo.Governors[eGovernorType];
            
            -- Check if the governor is actually assignable
            -- This prevents showing the indicator for secret society governors
            if (not IsCannotAssign(kGovernorDef)) then
                bCanAssign = true;
            end
        end
    end

    -- Stop if a governor doesn't need to be assigned
    -- No need to find the indicator if this is the case
    if (not bCanAssign) then
        return;
    end

    -- Get the governor button instance
    local governorAlertIndicator = nil;
    for _,ctrl in pairs(Controls.ButtonStack:GetChildren()) do
        if (ctrl:GetID() == "LaunchItemButton") then
            local foundButton = false;
            local foundIndicator = false;
            local indicator = nil;
            for _,ctrlChild in pairs(ctrl:GetChildren()) do
                if (ctrlChild:GetID() == "LaunchItemIcon" and ctrlChild:GetTexture() == "LaunchBar_Hook_Governors") then
                    foundButton = true;
                end
                if (ctrlChild:GetID() == "AlertIndicator") then
                    foundIndicator = true;
                    indicator = ctrlChild;
                end
            end

            -- If a button and indicator were both found, then this is the correct item
            if (foundButton and foundIndicator) then
                governorAlertIndicator = indicator;
                break;
            end
        end
    end
    
    -- We should have the alert indicator now
    if (governorAlertIndicator) then
        governorAlertIndicator:SetShow(bCanAssign);
        governorAlertIndicator:SetToolTipString(bCanAssign and Locale.Lookup("LOC_GOVERNOR_ACTION_AVAILABLE") or nil );
    end
end

-- ===========================================================================
-- CQUI: Initialize Function
-- ===========================================================================
function LateInitialize()
    BASE_CQUI_LateInitialize();
    Controls.LaunchExtraShow:RegisterCallback( Mouse.eLClick, OnToggleExtras );
    Controls.LaunchExtraShow:SetHide(true); -- will be enabled only if any entries will be registered

    -- Modular Screens
    LuaEvents.LaunchBar_AddExtra.Add( OnAddExtraEntry );
    LuaEvents.LaunchBar_AddIcon.Add( OnAddLaunchbarIcon );
    --TestLaunchBarExtension();
end
