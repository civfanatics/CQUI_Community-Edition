-- Include the original Options.lua file, which will execute its own initialize
include("Options");

-- Fallback in case the Options.xml is not loaded somehow
local CQUI_DyamicSettingsButton = nil;

function CQUI_Settings_Clicked()
    -- Close the current options screen
    OnCancel();
    -- Close the Top options menu
    LuaEvents.InGame_CloseInGameOptionsMenu();
    -- Open the CQUI Settings (false indicates the "CQUI Settings can be found from the Civ Settings" message will not be displayed)
    LuaEvents.CQUI_ToggleSettings(false);
end

function Initialize_Options_CQUI()
    if (Controls.CQUISettings ~= nil) then
        Controls.CQUISettings:SetHide(false);
        Controls.CQUISettings:RegisterCallback( Mouse.eLClick, CQUI_Settings_Clicked);
        Controls.CQUISettings:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    else
        -- Dynamically create a button so something is there
        if (CQUI_DyamicSettingsButton == nil) then
            CQUI_DyamicSettingsButton = {};
            -- Popup Button Instance comes from the PopupDialog.xml which is included by Options.xml
            -- So this will add a standard "Blue" button, since that's all we have available as far as instances go
            ContextPtr:BuildInstanceForControl("PopupButtonInstance", CQUI_DyamicSettingsButton, Controls.TabStack);
            CQUI_DyamicSettingsButton.Button:SetSizeX(200);
            CQUI_DyamicSettingsButton.Button:SetSizeY(32);
            CQUI_DyamicSettingsButton.Button:SetColor(12,51,82,20);
            CQUI_DyamicSettingsButton.Button:SetTextureOffsetVal(0,0);
            CQUI_DyamicSettingsButtonLabel = CQUI_DyamicSettingsButton.Button:GetTextControl();
            CQUI_DyamicSettingsButtonLabel:SetText(Locale.Lookup("LOC_CQUI_SETTINGS"));
            CQUI_DyamicSettingsButtonLabel:SetColorByName("ShellOptionText");
            CQUI_DyamicSettingsButton.Button:RegisterCallback( Mouse.eLClick, CQUI_Settings_Clicked);
        end
    end

end
Initialize_Options_CQUI();
