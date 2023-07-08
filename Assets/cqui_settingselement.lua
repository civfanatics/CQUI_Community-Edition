-- TODO (2020-05): Custom localizations are temporarily disabled due to reloads breaking them at the moment. Localizations are complete, so remember to enable them once Firaxis fixes this!
include("Civ6Common");
include("CQUICommon.lua");
include("InstanceManager");
-- note: cqui_settingselement_lenscolors.lua is included at the end of this file, so it can make use of some of the functions defined here

-- ============================================================================
-- VARIABLE DECLARATIONS
-- ============================================================================
--Add new options tabs to this in Initialize function
local m_tabs;
local m_keyBindingActionsIM = InstanceManager:new("KeyBindingAction", "Root", Controls.KeyBindingsStack);
-- ===========================================================================

local suzerain_icon_options = {
    {"LOC_CQUI_SHOW_SUZERAIN_DISABLED",    0},
    {"LOC_CQUI_SHOW_SUZERAIN_CIV_ICON",    1},
    {"LOC_CQUI_SHOW_SUZERAIN_LEADER_ICON", 2}
};

local icon_style_options = {
    {"LOC_CQUI_GENERAL_SOLID"      , 0},
    {"LOC_CQUI_GENERAL_TRANSPARENT", 1},
    {"LOC_CQUI_GENERAL_HIDDEN"     , 2}
};

local boolean_options = {
    {"LOC_OPTIONS_ENABLED" , 1},
    {"LOC_OPTIONS_DISABLED", 0},
};

-- Object containing functions that convert either a value to a set slider notch, or convert a notch to a value
local SliderControlConverter = {
    ToSteps = function(value, min, max, numsteps)
            -- Determine the position of the slider based on the number of steps in total
            -- If the value is the same as the minimum, then the step value is 0.
            local stepIncrement = math.floor((max - min + 1) / numsteps);
            local out = math.floor((value - min) / stepIncrement);
            if (out < 0) then
                out = 0;
            end

            return out;
        end,

    ToValue = function(curstep, min, max, numsteps)
            local stepIncrement = math.floor((max - min + 1) / numsteps);
            local out = (curstep * stepIncrement) + min;

            if (out > max) then
                out = max;
            end
            return out;
        end
};

-- This exists so it can be made available to the lenscolors lua file
function GetSliderControlConverter()
    return SliderControlConverter;
end

-- ============================================================================
-- FUNCTIONS
-- ============================================================================


-- ===========================================================================
-- Used to register a control to be updated whenever settings update (only necessary for controls that can be updated from multiple places)
function RegisterControl(control, setting_name, update_function, extra_data)
    -- print_debug("ENTRY: CQUICommon - RegisterControl");
    LuaEvents.CQUI_SettingsUpdate.Add(function() update_function(control, setting_name, extra_data); end);
end

-- ===========================================================================
-- Companion functions to RegisterControl
-- ===========================================================================
function UpdateCheckbox(control, setting_name)
    -- print_debug("ENTRY: CQUICommon - UpdateCheckbox");
    local value = GameConfiguration.GetValue(setting_name);
    if (value == nil) then
        return;
    end

    control:SetSelected(value);
end

-- ===========================================================================
function UpdateSlider( control, setting_name, data_converter)
    -- print_debug("ENTRY: CQUICommon - UpdateSlider");
    local value = GameConfiguration.GetValue(setting_name);
    if (value == nil) then
        return;
    end

    control:SetStep(data_converter.ToSteps(value));
end

-- ===========================================================================
--Used to populate combobox options
function PopulateComboBox(control, values, setting_name, tooltip)
    -- print_debug("ENTRY: CQUICommon - PopulateComboBox");
    control:ClearEntries();
    local current_value = GameConfiguration.GetValue(setting_name);

    -- Validate the Value retrieved is legal
    local isLegalValue = false;
    if (current_value ~= nil) then
        for _, v in ipairs(values) do
            if (v[2] == current_value) then
                isLegalValue = true;
                break;
            end
        end
    end

    if (current_value == nil or isLegalValue == false) then
        --LY Checks if this setting has a default state defined in the database
        if (GameInfo.CQUI_Settings[setting_name]) then
            --reads the default value from the database. Set them in Settings.sql
            current_value = GameInfo.CQUI_Settings[setting_name].Value;
        else
            current_value = 0;
        end

        GameConfiguration.SetValue(setting_name, current_value); --/LY
    end

    for i, v in ipairs(values) do
        local instance = {};
        control:BuildEntry( "InstanceOne", instance );
        instance.Button:SetVoid1(i);
        instance.Button:LocalizeAndSetText(v[1]);
        if (v[2] == current_value) then
            local button = control:GetButton();
            button:LocalizeAndSetText(v[1]);
        end
    end

    control:CalculateInternals();
    if (setting_name) then
        control:RegisterSelectionCallback(
            function(voidValue1, voidValue2, control)
                local option = values[voidValue1];
                local button = control:GetButton();
                button:LocalizeAndSetText(option[1]);
                GameConfiguration.SetValue(setting_name, option[2]);
                LuaEvents.CQUI_SettingsUpdate();
            end
        );
    end

    if (tooltip ~= nil)then
        control:SetToolTipString(tooltip);
    end
end

--Used to populate checkboxes
function PopulateCheckBox(control, setting_name, tooltip)
    -- print_debug("ENTRY: CQUICommon - PopulateCheckBox");
    local current_value = GameConfiguration.GetValue(setting_name);
    if (current_value == nil) then
        --LY Checks if this setting has a default state defined in the database
        if (GameInfo.CQUI_Settings[setting_name]) then
            --because 0 is true in Lua
            if (GameInfo.CQUI_Settings[setting_name].Value == 0) then
                current_value = false;
            else
                current_value = true;
            end
        else
            current_value = false;
        end

        GameConfiguration.SetValue(setting_name, current_value);
    end

    if (current_value == false) then
        control:SetSelected(false);
    else
        control:SetSelected(true);
    end

    control:RegisterCallback(Mouse.eLClick,
        function()
            local selected = not control:IsSelected();
            control:SetSelected(selected);
            GameConfiguration.SetValue(setting_name, selected);
            LuaEvents.CQUI_SettingsUpdate();
        end
    );

    if (tooltip ~= nil)then
        control:SetToolTipString(tooltip);
    end
end

-- ===========================================================================
--Used to populate Generic Edit Boxes
function PopulateEditBox(control, setting_name, commit_callback, string_changed_callback, tooltip)
    -- print_debug("ENTRY: CQUICommon - PopulateCheckBox");
    local current_value = GameConfiguration.GetValue(setting_name);

    if (current_value == nil) then
        --LY Checks if this setting has a default state defined in the database
        if (GameInfo.CQUI_Settings[setting_name]) then
            current_value = GameInfo.CQUI_Settings[setting_name].Value;
        else
            current_value = "";
        end

        GameConfiguration.SetValue(setting_name, current_value);
    end

    if (commit_callback ~= nil) then
        control:RegisterCommitCallback(commit_callback);
    end

    if (string_changed_callback ~= nil) then
        control:RegisterStringChangedCallback(string_changed_callback);
    end

    control:SetText(current_value);

    if (tooltip ~= nil)then
        control:SetToolTipString(tooltip);
    end
end

-- ===========================================================================
--Used to populate sliders. data_converter is a table containing two functions: ToStep and ToValue, which describe how to handle converting from the incremental slider steps to a setting value, think of it as a less elegant inner class
--Optional third function: ToString. When included, this function will handle how the value is converted to a display value, otherwise this defaults to using the value from ToValue
function PopulateSlider(control, label, setting_name, data_converter, tooltip, minvalue, maxvalue)
    -- print_debug("ENTRY: CQUICommon - PopulateSlider");
    -- This is necessary because RegisterSliderCallback fires twice when releasing the mouse cursor for some reason
    local hasScrolled = false;
    local current_value = GameConfiguration.GetValue(setting_name);
    if (current_value == nil) then
        --LY Checks if this setting has a default state defined in the database
        if (GameInfo.CQUI_Settings[setting_name]) then
            current_value = GameInfo.CQUI_Settings[setting_name].Value;
        else
            current_value = 0;
        end

        GameConfiguration.SetValue(setting_name, current_value); --/LY
    end

    control:SetStep(data_converter.ToSteps(current_value, minvalue, maxvalue, control:GetNumSteps()));
    if (data_converter.ToString) then
        label:SetText(data_converter.ToString(current_value));
    else
        label:SetText(current_value);
    end

    control:RegisterSliderCallback(
        function()
            local value = data_converter.ToValue(control:GetStep(), minvalue, maxvalue, control:GetNumSteps());
            if (data_converter.ToString) then
                label:SetText(data_converter.ToString(value));
            else
                label:SetText(value);
            end

            GameConfiguration.SetValue(setting_name, value);
            LuaEvents.CQUI_SettingsUpdate();
        end
    );

    if (tooltip ~= nil) then
        control:SetToolTipString(tooltip);
    end
end

-- ===========================================================================
--Used to switch active panels/tabs in the settings panel
function ShowTab(button, panel)
    -- print_debug("CQUI_SettingsElement: ShowTab Function Entry");
    -- Unfocus all tabs and hide panels
    for i, v in ipairs(m_tabs) do
        v[2]:SetHide(true);
        v[1]:SetSelected(false);
    end

    button:SetSelected(true);
    panel:SetHide(false);
    -- TODO: Investigate Locale problem
    -- Controls.WindowTitle:SetText(Locale.Lookup("LOC_CQUI_NAME") .. ": " .. Locale.ToUpper(button:GetText()));
    Controls.WindowTitle:SetText("CQUI: " .. Locale.ToUpper(button:GetText()));
end

-- ===========================================================================
--Populates the status message panel checkboxes with appropriate strings
function InitializeGossipCheckboxes()
    -- Base Gossip
    Controls.LOC_GOSSIP_AGENDA_KUDOSCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_AGENDA_KUDOS", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_AGENDA_WARNINGCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_AGENDA_WARNING", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_ALLIEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_ALLIED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_ANARCHY_BEGINSCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_ANARCHY_BEGINS", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_ARTIFACT_EXTRACTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_ARTIFACT_EXTRACTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_BARBARIAN_INVASION_STARTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_BARBARIAN_INVASION_STARTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_BARBARIAN_RAID_STARTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_BARBARIAN_RAID_STARTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_BEACH_RESORT_CREATEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_BEACH_RESORT_CREATED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CHANGE_GOVERNMENTCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CHANGE_GOVERNMENT", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CITY_BESIEGEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CITY_BESIEGED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CITY_LIBERATEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CITY_LIBERATED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CITY_RAZEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CITY_RAZED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CLEAR_CAMPCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CLEAR_CAMP", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_IMPROVEMENT_BARBARIAN_CAMP_NAME") .. ")");
    Controls.LOC_GOSSIP_CITY_STATE_INFLUENCECheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CITY_STATE_INFLUENCE", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CONQUER_CITYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CONQUER_CITY", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CONQUER_CAPITAL_CITYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CONQUER_CAPITAL_CITY", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CONSTRUCT_BUILDINGCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CONSTRUCT_BUILDING", "X", "Y", "Z", "1", "2", "3") .. "  (" .. Locale.Lookup("LOC_BUILDING_NAME") .. ")");
    Controls.LOC_GOSSIP_CONSTRUCT_DISTRICTCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CONSTRUCT_DISTRICT", "X", "Y", "Z", "1", "2", "3") .. "  (" .. Locale.Lookup("LOC_DISTRICT_NAME") .. ")");
    Controls.LOC_GOSSIP_CREATE_PANTHEONCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CREATE_PANTHEON", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_CULTURVATE_CIVICCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_CULTURVATE_CIVIC", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_DECLARED_FRIENDSHIPCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_DECLARED_FRIENDSHIP", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_DELEGATIONCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_DELEGATION", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_DENOUNCEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_DENOUNCED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_EMBASSYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_EMBASSY", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_ERA_CHANGEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_ERA_CHANGED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_FIND_NATURAL_WONDERCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_FIND_NATURAL_WONDER", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_FOUND_CITYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_FOUND_CITY", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_FOUND_RELIGIONCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_FOUND_RELIGION", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_GREATPERSON_CREATEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_GREATPERSON_CREATED", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_GREAT_PEOPLE_TAB_GREAT_PEOPLE") .. ")");
    Controls.LOC_GOSSIP_LAUNCHING_ATTACKCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_LAUNCHING_ATTACK", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_WAR_PREPARATIONCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_WAR_PREPARATION", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_INQUISITION_LAUNCHEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_INQUISITION_LAUNCHED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_LAND_UNIT_LEVELCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_LAND_UNIT_LEVEL", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_FORMATION_CLASS_LAND_COMBAT_NAME", "") .. ")");
    Controls.LOC_GOSSIP_MAKE_DOWCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_MAKE_DOW", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_NATIONAL_PARK_CREATEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_NATIONAL_PARK_CREATED", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_NATIONAL_PARK_NAME", "") .. ")");
    Controls.LOC_GOSSIP_NAVAL_UNIT_LEVELCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_NAVAL_UNIT_LEVEL", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_FORMATION_CLASS_NAVAL_NAME", "") .. ")");
    Controls.LOC_GOSSIP_NEW_RELIGIOUS_MAJORITYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_NEW_RELIGIOUS_MAJORITY", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_PILLAGECheckbox:SetText(Locale.Lookup("LOC_GOSSIP_PILLAGE", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_POLICY_ENACTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_POLICY_ENACTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_RECEIVE_DOWCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_RECEIVE_DOW", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_RELIC_RECEIVEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_RELIC_RECEIVED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_RESEARCH_AGREEMENTCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_RESEARCH_AGREEMENT", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_RESEARCH_TECHCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_RESEARCH_TECH", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_CAPTUREDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_CAPTURED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_DETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_GREAT_WORK_HEIST_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_GREAT_WORK_HEIST_DETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_GREAT_WORK_HEIST_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_GREAT_WORK_HEIST_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_RECRUIT_PARTISANS_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_RECRUIT_PARTISANS_DETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_RECRUIT_PARTISANS_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_RECRUIT_PARTISANS_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_DETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_SIPHON_FUNDS_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_SIPHON_FUNDS_DETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_SIPHON_FUNDS_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_SIPHON_FUNDS_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_STEAL_TECH_BOOST_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_STEAL_TECH_BOOST_DETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_SPY_STEAL_TECH_BOOST_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_STEAL_TECH_BOOST_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_TRADE_DEALCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_TRADE_DEAL", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_TRADE_RENEGECheckbox:SetText(Locale.Lookup("LOC_GOSSIP_TRADE_RENEGE", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_TRAIN_SETTLERCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_TRAIN_SETTLER", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_TRAIN_UNITCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_TRAIN_UNIT", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_TRAIN_UNIQUE_UNITCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_TRAIN_UNIQUE_UNIT", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_PROJECT_STARTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_PROJECT_STARTED", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_PROJECT_NAME") .. ")");
    Controls.LOC_GOSSIP_SPACE_RACE_PROJECT_COMPLETEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPACE_RACE_PROJECT_COMPLETED", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_PROJECT_NAME") .. ")");
    Controls.LOC_GOSSIP_START_VICTORY_STRATEGYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_START_VICTORY_STRATEGY", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_VICTORY_DEFAULT_NAME") .. ")");
    Controls.LOC_GOSSIP_STOP_VICTORY_STRATEGYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_STOP_VICTORY_STRATEGY", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_VICTORY_DEFAULT_NAME") .. ")");
    Controls.LOC_GOSSIP_WMD_BUILTCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_WMD_BUILT", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_WMD_STRIKECheckbox:SetText(Locale.Lookup("LOC_GOSSIP_WMD_STRIKE", "X", "Y", "Z", "1", "2", "3"));
    Controls.LOC_GOSSIP_WONDER_STARTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_WONDER_STARTED", "X", "Y", "Z", "1", "2", "3") .. " (" .. Locale.Lookup("LOC_WONDER_NAME") .. ")");

    PopulateCheckBox(Controls.LOC_GOSSIP_AGENDA_KUDOSCheckbox, "CQUI_LOC_GOSSIP_AGENDA_KUDOS");
    PopulateCheckBox(Controls.LOC_GOSSIP_AGENDA_WARNINGCheckbox, "CQUI_LOC_GOSSIP_AGENDA_WARNING");
    PopulateCheckBox(Controls.LOC_GOSSIP_ALLIEDCheckbox, "CQUI_LOC_GOSSIP_ALLIED");
    PopulateCheckBox(Controls.LOC_GOSSIP_ANARCHY_BEGINSCheckbox, "CQUI_LOC_GOSSIP_ANARCHY_BEGINS");
    PopulateCheckBox(Controls.LOC_GOSSIP_ARTIFACT_EXTRACTEDCheckbox, "CQUI_LOC_GOSSIP_ARTIFACT_EXTRACTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_BARBARIAN_INVASION_STARTEDCheckbox, "CQUI_LOC_GOSSIP_BARBARIAN_INVASION_STARTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_BARBARIAN_RAID_STARTEDCheckbox, "CQUI_LOC_GOSSIP_BARBARIAN_RAID_STARTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_BEACH_RESORT_CREATEDCheckbox, "CQUI_LOC_GOSSIP_BEACH_RESORT_CREATED");
    PopulateCheckBox(Controls.LOC_GOSSIP_CHANGE_GOVERNMENTCheckbox, "CQUI_LOC_GOSSIP_CHANGE_GOVERNMENT");
    PopulateCheckBox(Controls.LOC_GOSSIP_CITY_BESIEGEDCheckbox, "CQUI_LOC_GOSSIP_CITY_BESIEGED");
    PopulateCheckBox(Controls.LOC_GOSSIP_CITY_LIBERATEDCheckbox, "CQUI_LOC_GOSSIP_CITY_LIBERATED");
    PopulateCheckBox(Controls.LOC_GOSSIP_CITY_RAZEDCheckbox, "CQUI_LOC_GOSSIP_CITY_RAZED");
    PopulateCheckBox(Controls.LOC_GOSSIP_CLEAR_CAMPCheckbox, "CQUI_LOC_GOSSIP_CLEAR_CAMP");
    PopulateCheckBox(Controls.LOC_GOSSIP_CITY_STATE_INFLUENCECheckbox, "CQUI_LOC_GOSSIP_CITY_STATE_INFLUENCE");
    PopulateCheckBox(Controls.LOC_GOSSIP_CONQUER_CITYCheckbox, "CQUI_LOC_GOSSIP_CONQUER_CITY");
    PopulateCheckBox(Controls.LOC_GOSSIP_CONQUER_CAPITAL_CITYCheckbox, "CQUI_LOC_GOSSIP_CONQUER_CAPITAL_CITY");
    PopulateCheckBox(Controls.LOC_GOSSIP_CONSTRUCT_BUILDINGCheckbox, "CQUI_LOC_GOSSIP_CONSTRUCT_BUILDING");
    PopulateCheckBox(Controls.LOC_GOSSIP_CONSTRUCT_DISTRICTCheckbox, "CQUI_LOC_GOSSIP_CONSTRUCT_DISTRICT");
    PopulateCheckBox(Controls.LOC_GOSSIP_CREATE_PANTHEONCheckbox, "CQUI_LOC_GOSSIP_CREATE_PANTHEON");
    PopulateCheckBox(Controls.LOC_GOSSIP_CULTURVATE_CIVICCheckbox, "CQUI_LOC_GOSSIP_CULTURVATE_CIVIC");
    PopulateCheckBox(Controls.LOC_GOSSIP_DECLARED_FRIENDSHIPCheckbox, "CQUI_LOC_GOSSIP_DECLARED_FRIENDSHIP");
    PopulateCheckBox(Controls.LOC_GOSSIP_DELEGATIONCheckbox, "CQUI_LOC_GOSSIP_DELEGATION");
    PopulateCheckBox(Controls.LOC_GOSSIP_DENOUNCEDCheckbox, "CQUI_LOC_GOSSIP_DENOUNCED");
    PopulateCheckBox(Controls.LOC_GOSSIP_EMBASSYCheckbox, "CQUI_LOC_GOSSIP_EMBASSY");
    PopulateCheckBox(Controls.LOC_GOSSIP_ERA_CHANGEDCheckbox, "CQUI_LOC_GOSSIP_ERA_CHANGED");
    PopulateCheckBox(Controls.LOC_GOSSIP_FIND_NATURAL_WONDERCheckbox, "CQUI_LOC_GOSSIP_FIND_NATURAL_WONDER");
    PopulateCheckBox(Controls.LOC_GOSSIP_FOUND_CITYCheckbox, "CQUI_LOC_GOSSIP_FOUND_CITY");
    PopulateCheckBox(Controls.LOC_GOSSIP_FOUND_RELIGIONCheckbox, "CQUI_LOC_GOSSIP_FOUND_RELIGION");
    PopulateCheckBox(Controls.LOC_GOSSIP_GREATPERSON_CREATEDCheckbox, "CQUI_LOC_GOSSIP_GREATPERSON_CREATED");
    PopulateCheckBox(Controls.LOC_GOSSIP_LAUNCHING_ATTACKCheckbox, "CQUI_LOC_GOSSIP_LAUNCHING_ATTACK");
    PopulateCheckBox(Controls.LOC_GOSSIP_WAR_PREPARATIONCheckbox, "CQUI_LOC_GOSSIP_WAR_PREPARATION");
    PopulateCheckBox(Controls.LOC_GOSSIP_INQUISITION_LAUNCHEDCheckbox, "CQUI_LOC_GOSSIP_INQUISITION_LAUNCHED");
    PopulateCheckBox(Controls.LOC_GOSSIP_LAND_UNIT_LEVELCheckbox, "CQUI_LOC_GOSSIP_LAND_UNIT_LEVEL");
    PopulateCheckBox(Controls.LOC_GOSSIP_MAKE_DOWCheckbox, "CQUI_LOC_GOSSIP_MAKE_DOW");
    PopulateCheckBox(Controls.LOC_GOSSIP_NATIONAL_PARK_CREATEDCheckbox, "CQUI_LOC_GOSSIP_NATIONAL_PARK_CREATED");
    PopulateCheckBox(Controls.LOC_GOSSIP_NAVAL_UNIT_LEVELCheckbox, "CQUI_LOC_GOSSIP_NAVAL_UNIT_LEVEL");
    PopulateCheckBox(Controls.LOC_GOSSIP_NEW_RELIGIOUS_MAJORITYCheckbox, "CQUI_LOC_GOSSIP_NEW_RELIGIOUS_MAJORITY");
    PopulateCheckBox(Controls.LOC_GOSSIP_PILLAGECheckbox, "CQUI_LOC_GOSSIP_PILLAGE");
    PopulateCheckBox(Controls.LOC_GOSSIP_POLICY_ENACTEDCheckbox, "CQUI_LOC_GOSSIP_POLICY_ENACTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_RECEIVE_DOWCheckbox, "CQUI_LOC_GOSSIP_RECEIVE_DOW");
    PopulateCheckBox(Controls.LOC_GOSSIP_RELIC_RECEIVEDCheckbox, "CQUI_LOC_GOSSIP_RELIC_RECEIVED");
    PopulateCheckBox(Controls.LOC_GOSSIP_RESEARCH_AGREEMENTCheckbox, "CQUI_LOC_GOSSIP_RESEARCH_AGREEMENT");
    PopulateCheckBox(Controls.LOC_GOSSIP_RESEARCH_TECHCheckbox, "CQUI_LOC_GOSSIP_RESEARCH_TECH");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_CAPTUREDCheckbox, "CQUI_LOC_GOSSIP_SPY_CAPTURED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_DETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_UNDETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_GREAT_WORK_HEIST_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_GREAT_WORK_HEIST_DETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_GREAT_WORK_HEIST_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_GREAT_WORK_HEIST_UNDETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_RECRUIT_PARTISANS_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_RECRUIT_PARTISANS_DETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_RECRUIT_PARTISANS_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_RECRUIT_PARTISANS_UNDETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_DETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_UNDETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_SIPHON_FUNDS_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_SIPHON_FUNDS_DETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_SIPHON_FUNDS_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_SIPHON_FUNDS_UNDETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_STEAL_TECH_BOOST_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_STEAL_TECH_BOOST_DETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPY_STEAL_TECH_BOOST_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_STEAL_TECH_BOOST_UNDETECTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_TRADE_DEALCheckbox, "CQUI_LOC_GOSSIP_TRADE_DEAL");
    PopulateCheckBox(Controls.LOC_GOSSIP_TRADE_RENEGECheckbox, "CQUI_LOC_GOSSIP_TRADE_RENEGE");
    PopulateCheckBox(Controls.LOC_GOSSIP_TRAIN_SETTLERCheckbox, "CQUI_LOC_GOSSIP_TRAIN_SETTLER");
    PopulateCheckBox(Controls.LOC_GOSSIP_TRAIN_UNITCheckbox, "CQUI_LOC_GOSSIP_TRAIN_UNIT");
    PopulateCheckBox(Controls.LOC_GOSSIP_TRAIN_UNIQUE_UNITCheckbox, "CQUI_LOC_GOSSIP_TRAIN_UNIQUE_UNIT");
    PopulateCheckBox(Controls.LOC_GOSSIP_PROJECT_STARTEDCheckbox, "CQUI_LOC_GOSSIP_PROJECT_STARTED");
    PopulateCheckBox(Controls.LOC_GOSSIP_SPACE_RACE_PROJECT_COMPLETEDCheckbox, "CQUI_LOC_GOSSIP_SPACE_RACE_PROJECT_COMPLETED");
    PopulateCheckBox(Controls.LOC_GOSSIP_START_VICTORY_STRATEGYCheckbox, "CQUI_LOC_GOSSIP_START_VICTORY_STRATEGY");
    PopulateCheckBox(Controls.LOC_GOSSIP_STOP_VICTORY_STRATEGYCheckbox, "CQUI_LOC_GOSSIP_STOP_VICTORY_STRATEGY");
    PopulateCheckBox(Controls.LOC_GOSSIP_WMD_BUILTCheckbox, "CQUI_LOC_GOSSIP_WMD_BUILT");
    PopulateCheckBox(Controls.LOC_GOSSIP_WMD_STRIKECheckbox, "CQUI_LOC_GOSSIP_WMD_STRIKE");
    PopulateCheckBox(Controls.LOC_GOSSIP_WONDER_STARTEDCheckbox, "CQUI_LOC_GOSSIP_WONDER_STARTED");

    -- Expansion 1 Gossip
    if g_bIsRiseAndFall or g_bIsGatheringStorm then
        Controls.LOC_GOSSIP_SPY_FOMENT_UNREST_DETECTEDCheckbox:SetHide(false);
        Controls.LOC_GOSSIP_SPY_FOMENT_UNREST_UNDETECTEDCheckbox:SetHide(false);
        Controls.LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_DETECTEDCheckbox:SetHide(false);
        Controls.LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_UNDETECTEDCheckbox:SetHide(false);
        
        Controls.LOC_GOSSIP_SPY_FOMENT_UNREST_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_FOMENT_UNREST_DETECTED", "X", "Y", "Z", "1", "2", "3"));
        Controls.LOC_GOSSIP_SPY_FOMENT_UNREST_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_FOMENT_UNREST_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
        Controls.LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_DETECTED", "X", "Y", "Z", "1", "2", "3"));
        Controls.LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));

        PopulateCheckBox(Controls.LOC_GOSSIP_SPY_FOMENT_UNREST_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_FOMENT_UNREST_DETECTED");
        PopulateCheckBox(Controls.LOC_GOSSIP_SPY_FOMENT_UNREST_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_FOMENT_UNREST_UNDETECTED");
        PopulateCheckBox(Controls.LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_DETECTED");
        PopulateCheckBox(Controls.LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_UNDETECTED");
    end

    -- Expansion 2 Gossip
    if g_bIsGatheringStorm then
        Controls.LOC_GOSSIP_SPY_DAM_BREACHED_DETECTEDCheckbox:SetHide(false);
        Controls.LOC_GOSSIP_SPY_DAM_BREACHED_UNDETECTEDCheckbox:SetHide(false);
        Controls.LOC_GOSSIP_ROCK_CONCERTCheckbox:SetHide(false);
        Controls.LOC_GOSSIP_POWERED_CITYCheckbox:SetHide(false);
        Controls.LOC_GOSSIP_RANDOM_EVENTCheckbox:SetHide(false);
        
        Controls.LOC_GOSSIP_SPY_DAM_BREACHED_DETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_DAM_BREACHED_DETECTED", "X", "Y", "Z", "1", "2", "3"));
        Controls.LOC_GOSSIP_SPY_DAM_BREACHED_UNDETECTEDCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_SPY_DAM_BREACHED_UNDETECTED", "X", "Y", "Z", "1", "2", "3"));
        Controls.LOC_GOSSIP_ROCK_CONCERTCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_ROCK_CONCERT", "X", "Y", "Z", "1", "2", "3"));
        Controls.LOC_GOSSIP_POWERED_CITYCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_POWERED_CITY", "X", "Y", "Z", "1", "2", "3"));
        Controls.LOC_GOSSIP_RANDOM_EVENTCheckbox:SetText(Locale.Lookup("LOC_GOSSIP_RANDOM_EVENT", "X", "Y", "Z", "1", "2", "3"));

        PopulateCheckBox(Controls.LOC_GOSSIP_SPY_DAM_BREACHED_DETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_DAM_BREACHED_DETECTED");
        PopulateCheckBox(Controls.LOC_GOSSIP_SPY_DAM_BREACHED_UNDETECTEDCheckbox, "CQUI_LOC_GOSSIP_SPY_DAM_BREACHED_UNDETECTED");
        PopulateCheckBox(Controls.LOC_GOSSIP_ROCK_CONCERTCheckbox, "CQUI_LOC_GOSSIP_ROCK_CONCERT");
        PopulateCheckBox(Controls.LOC_GOSSIP_POWERED_CITYCheckbox, "CQUI_LOC_GOSSIP_POWERED_CITY");
        PopulateCheckBox(Controls.LOC_GOSSIP_RANDOM_EVENTCheckbox, "CQUI_LOC_GOSSIP_RANDOM_EVENT");
    end
end

-- ===========================================================================
function InitializeTraderScreenCheckboxes()
    PopulateCheckBox(Controls.TraderAddDividerCheckbox, "CQUI_TraderAddDivider", Locale.Lookup("LOC_CQUI_TRADER_ADD_DIVIDER_TOOLTIP"));
    PopulateCheckBox(Controls.TraderShowSortOrderCheckbox, "CQUI_TraderShowSortOrder", Locale.Lookup("LOC_CQUI_TRADER_SHOW_SORT_ORDER_TOOLTIP"));
end

-- ===========================================================================
--  Input
--  UI Event Handler
-- ===========================================================================
function KeyDownHandler( key:number )
    if key == Keys.VK_SHIFT then
        m_shiftDown = true;
        -- let it fall through
    end

    return false;
end

-- ===========================================================================
function KeyUpHandler( key:number )
    if key == Keys.VK_SHIFT then
        m_shiftDown = false;
        -- let it fall through
    end

    if key == Keys.VK_ESCAPE then
        Close();
        return true;
    end

    if key == Keys.VK_RETURN then
        return true; -- Don't let enter propigate or it will hit action panel which will raise a screen (potentially this one again) tied to the action.
    end

    return false;
end

-- ===========================================================================
function OnInputHandler( pInputStruct:table )
    local uiMsg = pInputStruct:GetMessageType();
    if uiMsg == KeyEvents.KeyDown then
        return KeyDownHandler( pInputStruct:GetKey() );
    end
    
    if uiMsg == KeyEvents.KeyUp then
        return KeyUpHandler( pInputStruct:GetKey() );
    end

    return false;
end

-- ===========================================================================
function Close()
    UI.PlaySound("UI_Pause_Menu_On");
    ContextPtr:SetHide(true);
    LuaEvents.CQUI_SettingsUpdate();
    LuaEvents.CQUI_SettingsPanelClosed();
end

-- ===========================================================================
function OnShow()
    UI.PlaySound("UI_Pause_Menu_On");
    -- From Civ6_styles: FullScreenVignetteConsumer
    Controls.ScreenAnimIn:SetToBeginning();
    Controls.ScreenAnimIn:Play();
end

-- ===========================================================================
function OnSettingsButtonClicked( showUseMenuOption:boolean )
    -- Clicking the icon above the minimap will cause this message to show (showUseMenuOption will be true)
    Controls.CQUISettingsMoved:SetShow(showUseMenuOption);
    -- Display the settings dialog
    ContextPtr:SetHide(not ContextPtr:IsHidden());
end

-- ===========================================================================
function Initialize()
    print_debug("ENTRY: CQUI_SettingsElement Initialize")
    ContextPtr:SetHide(true);
    --Adding/binding tabs...
    m_tabs = {
        {Controls.GeneralTab, Controls.GeneralOptions},
        {Controls.BindingsTab, Controls.BindingsOptions},
        {Controls.PopupsTab, Controls.PopupsOptions},
        {Controls.GossipTab, Controls.GossipOptions},
        {Controls.CityviewTab, Controls.CityviewOptions},
        {Controls.LensesTab, Controls.LensesOptions},
        {Controls.UnitsTab, Controls.UnitsOptions},
        {Controls.TraderScreenTab, Controls.TraderScreenOption},
        {Controls.RecommendationsTab, Controls.RecommendationsOptions},
        {Controls.NotificationsTab, Controls.NotificationsOptions},
        {Controls.HiddenTab, Controls.HiddenOptions}
    };

    for i, tab in ipairs(m_tabs) do
        local button = tab[1];
        local panel = tab[2];
        button:RegisterCallback(Mouse.eLClick,
            function()
                ShowTab(button, panel);
            end);
    end

    -- Close callback
    Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, Close);

    --Populating/binding comboboxes...
    PopulateComboBox(Controls.BindingsPullDown, boolean_options, "CQUI_BindingsMode");
    m_keyBindingActionsIM:ResetInstances();
    for currentBinding in GameInfo.CQUI_Bindings() do
        local entry = m_keyBindingActionsIM:GetInstance();
        entry.ActionName:SetText(Locale.Lookup(currentBinding["ActionDesc"]));
        entry.Binding:SetText(currentBinding["Keys"]);
    end
    Controls.KeyBindingsStack:CalculateSize();
    Controls.KeyBindingsScrollPanel:CalculateSize();
    UpdateKeyBindingsDisplay();

    PopulateComboBox(Controls.ResourceIconStyle, icon_style_options, "CQUI_ResourceDimmingStyle", Locale.Lookup("LOC_CQUI_GENERAL_RESOURCEDIMMINGSTYLE_TOOLTIP"));
    PopulateComboBox(Controls.ProductionRecommendationsPullDown, boolean_options, "CQUI_ShowProductionRecommendations");
    PopulateComboBox(Controls.TechRecommendationsPullDown, boolean_options, "CQUI_ShowTechCivicRecommendations");
    PopulateComboBox(Controls.ImprovementsRecommendationsPullDown, boolean_options, "CQUI_ShowImprovementsRecommendations");
    PopulateComboBox(Controls.CityDetailAdvisorPullDown, boolean_options, "CQUI_ShowCityDetailAdvisor");
    PopulateComboBox(Controls.ShowSuzerainInCityStateBanner, suzerain_icon_options, "CQUI_ShowSuzerainInCityStateBanner",  Locale.Lookup("LOC_CQUI_SHOW_SUZERAIN_IN_CITYSTATE_BANNER_TOOLTIP"));

    --Populating/binding checkboxes...
    PopulateCheckBox(Controls.ProductionQueueCheckbox, "CQUI_ProductionQueue");
    PopulateCheckBox(Controls.InlineCityStateQuest, "CQUI_InlineCityStateQuest");
    RegisterControl (Controls.ProductionQueueCheckbox, "CQUI_ProductionQueue", UpdateCheckbox);
    PopulateCheckBox(Controls.ShowLuxuryCheckbox, "CQUI_ShowLuxuries");
    PopulateCheckBox(Controls.AutoRepeatTechCivicCheckbox, "CQUI_AutoRepeatTechCivic", Locale.Lookup("LOC_CQUI_GENERAL_AUTOREPEATTECHCIVIC_TOOLTIP"));
    PopulateCheckBox(Controls.ShowCultureGrowthCheckbox, "CQUI_ShowCultureGrowth", Locale.Lookup("LOC_CQUI_CITYVIEW_SHOWCULTUREGROWTH_TOOLTIP"));
    RegisterControl (Controls.ShowCultureGrowthCheckbox, "CQUI_ShowCultureGrowth", UpdateCheckbox);
    PopulateCheckBox(Controls.SmartbannerCheckbox, "CQUI_Smartbanner", Locale.Lookup("LOC_CQUI_CITYVIEW_SMARTBANNER_TOOLTIP"));
    PopulateCheckBox(Controls.SmartbannerUnlockedCitizenCheckbox, "CQUI_Smartbanner_UnlockedCitizen", Locale.Lookup("LOC_CQUI_CITYVIEW_SMARTBANNER_UNLOCKEDCITIZEN_TOOLTIP"));
    PopulateCheckBox(Controls.SmartbannerDistrictsCheckbox, "CQUI_Smartbanner_Districts", Locale.Lookup("LOC_CQUI_CITYVIEW_SMARTBANNER_DISTRICTS_TOOLTIP"));
    PopulateCheckBox(Controls.SmartbannerPopulationCheckbox, "CQUI_Smartbanner_Population", Locale.Lookup("LOC_CQUI_CITYVIEW_SMARTBANNER_POPULATION_TOOLTIP"));
    PopulateCheckBox(Controls.SmartbannerCulturalCheckbox, "CQUI_Smartbanner_Cultural", Locale.Lookup("LOC_CQUI_CITYVIEW_SMARTBANNER_CULTURAL_TOOLTIP"));
    PopulateCheckBox(Controls.SmartbannerDistrictsAvailableCheckbox, "CQUI_Smartbanner_DistrictsAvailable", Locale.Lookup("LOC_CQUI_CITYVIEW_SMARTBANNER_DISTRICTS_AVAILABLE_TOOLTIP"));
    PopulateCheckBox(Controls.ToggleYieldsOnLoadCheckbox, "CQUI_ToggleYieldsOnLoad");
    PopulateCheckBox(Controls.ShowSuzerainLabelInCityStateBanner, "CQUI_ShowSuzerainLabelInCityStateBanner", Locale.Lookup("LOC_CQUI_LABELS_ON_SUZERAIN_ICON_TOOLTIP"));
    PopulateCheckBox(Controls.ShowWarIconInCityStateBanner, "CQUI_ShowWarIconInCityStateBanner", Locale.Lookup("LOC_CQUI_SHOW_WAR_ICON_IN_CITYSTATE_BANNER_TOOLTIP"));
    PopulateCheckBox(Controls.RelocateCityStrikeCheckbox, "CQUI_RelocateCityStrike", Locale.Lookup("LOC_CQUI_CITYVIEW_RELOCATECITYSTRIKEBUTTON_TOOLTIP"));
    PopulateCheckBox(Controls.RelocateEncampmentStrikeCheckbox, "CQUI_RelocateEncampmentStrike", Locale.Lookup("LOC_CQUI_CITYVIEW_RELOCATEENCAMPMENTSTRIKEBUTTON_TOOLTIP"));
    PopulateCheckBox(Controls.ShowCityManageOverLensesCheckbox, "CQUI_ShowCityManageOverLenses", Locale.Lookup("LOC_CQUI_CITYVIEW_SHOWCITYMANAGEOVERLENSES_TOOLTIP"));

    -- Popups
    -- Base game popups
    PopulateCheckBox(Controls.TechCivicCompletedVisualCheckbox, "CQUI_TechCivicCompletedPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_TECHCIVICCOMPLETEDVISUAL_TOOLTIP"));
    PopulateCheckBox(Controls.TechCivicCompletedAudioCheckbox, "CQUI_TechCivicCompletedPopupAudio", Locale.Lookup("LOC_CQUI_POPUPS_TECHCIVICCOMPLETEDAUDIO_TOOLTIP"));
    PopulateCheckBox(Controls.BoostUnlockedVisualCheckbox, "CQUI_BoostUnlockedPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_BOOSTUNLOCKEDVISUAL_TOOLTIP"));
    PopulateCheckBox(Controls.EraCompleteVisualCheckbox, "CQUI_EraCompletePopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_ERACOMPLETEVISUAL_TOOLTIP"));
    PopulateCheckBox(Controls.ProjectBuiltVisualCheckbox, "CQUI_ProjectBuiltPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_PROJECTBUILTVISUAL_TOOLTIP"));
    PopulateCheckBox(Controls.UnitCapturedVisualCheckbox, "CQUI_UnitCapturedPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_UNITCAPTUREDVISUAL_TOOLTIP"));
    PopulateCheckBox(Controls.NaturalWonderVisualCheckbox, "CQUI_NaturalWonderPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_NATURALWONDERVISUAL_TOOLTIP"));
    PopulateCheckBox(Controls.NaturalWonderAudioCheckbox, "CQUI_NaturalWonderPopupAudio", Locale.Lookup("LOC_CQUI_POPUPS_NATURALWONDERAUDIO_TOOLTIP"));
    PopulateCheckBox(Controls.WonderBuiltVisualCheckbox, "CQUI_WonderBuiltPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_WONDERBUILTVISUAL_TOOLTIP"));
    PopulateCheckBox(Controls.WonderBuiltAudioCheckbox, "CQUI_WonderBuiltPopupAudio", Locale.Lookup("LOC_CQUI_POPUPS_WONDERBUILTAUDIO_TOOLTIP"));
    
    -- Expansion 1 Popups
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        Controls.HistoricMomentsVisualCheckbox:SetHide(false);
        PopulateCheckBox(Controls.HistoricMomentsVisualCheckbox, "CQUI_HistoricMomentsPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_HISTORICMOMENTSVISUAL_TOOLTIP"));
    end

    -- Expansion 2 Popups
    if (g_bIsGatheringStorm) then
        Controls.NaturalDisasterVisualCheckbox:SetHide(false);
        Controls.RockBandMovieVisualCheckbox:SetHide(false);
        PopulateCheckBox(Controls.NaturalDisasterVisualCheckbox, "CQUI_NaturalDisasterPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_NATURALDISASTERVISUAL_TOOLTIP"));
        PopulateCheckBox(Controls.RockBandMovieVisualCheckbox, "CQUI_RockBandMoviePopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_ROCKBANDMOVIEVISUAL_TOOLTIP"));
    end

    -- Secret Societies Popups
    if (GameCapabilities.HasCapability("CAPABILITY_SECRETSOCIETIES")) then
        Controls.SecretSocietyDiscoveredVisualCheckbox:SetHide(false);
        Controls.SecretSocietyJoinedVisualCheckbox:SetHide(false);
        PopulateCheckBox(Controls.SecretSocietyDiscoveredVisualCheckbox, "CQUI_SecretSocietyDiscoveredPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_SECRETSOCIETYDISCOVEREDVISUAL_TOOLTIP"));
        PopulateCheckBox(Controls.SecretSocietyJoinedVisualCheckbox, "CQUI_SecretSocietyJoinedPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_SECRETSOCIETYJOINEDVISUAL_TOOLTIP"));
    end

    -- Heroes and Legends Popups
    if (GameInfo.Kinds.KIND_HEROCLASS ~= nil) then
        Controls.HeroDiscoveredVisualCheckbox:SetHide(false);
        Controls.HeroExpiredVisualCheckbox:SetHide(false);
        PopulateCheckBox(Controls.HeroDiscoveredVisualCheckbox, "CQUI_HeroDiscoveredPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_HERODISCOVEREDVISUAL_TOOLTIP"));
        PopulateCheckBox(Controls.HeroExpiredVisualCheckbox, "CQUI_HeroExpiredPopupVisual", Locale.Lookup("LOC_CQUI_POPUPS_HEROEXPIREDVISUAL_TOOLTIP"));
    end

    -- Multiplayer Popups
    if (GameConfiguration.IsAnyMultiplayer()) then
        Controls.MultiplayerPopupsLabel:SetHide(false);
        Controls.MultiplayerPopupsCheckbox:SetHide(false);
        PopulateCheckBox(Controls.MultiplayerPopupsCheckbox, "CQUI_MultiplayerPopups", Locale.Lookup("LOC_CQUI_POPUPS_MULTIPLAYER_TOOLTIP"));
    end

    -- Lenses
    PopulateCheckBox(Controls.AutoapplyArchaeologistLensCheckbox, "CQUI_AutoapplyArchaeologistLens", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYARCHAEOLOGISTLENS_TOOLTIP"));
    PopulateCheckBox(Controls.AutoapplyBuilderLensCheckbox, "CQUI_AutoapplyBuilderLens", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYBUILDERLENS_TOOLTIP"));
    PopulateCheckBox(Controls.BuilderLensDisableNothingPlotCheckbox, "CQUI_BuilderLensDisableNothingPlot", Locale.Lookup("LOC_CQUI_LENSES_BUILDERDISABLENOTHING_TOOLTIP"));
    PopulateCheckBox(Controls.BuilderLensDisableDangerousPlotCheckbox, "CQUI_BuilderLensDisableDangerousPlot", Locale.Lookup("LOC_CQUI_LENSES_BUILDERDISABLEDANGEROUS_TOOLTIP"));
    PopulateCheckBox(Controls.AutoapplyScoutLensCheckbox, "CQUI_AutoapplyScoutLens", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYSCOUTLENS_TOOLTIP"));
    PopulateCheckBox(Controls.AutoapplyScoutLensExtraCheckbox, "CQUI_AutoapplyScoutLensExtra", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYSCOUTLENS_EXTRA_TOOLTIP"));
    PopulateCheckBox(Controls.AutoapplyEngineerLensCheckbox, "CQUI_AutoapplyEngineerLens", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYENGINEERLENS_TOOLTIP"));
    PopulateComboBox(Controls.ReligionLensHideUnits, icon_style_options, "CQUI_ReligionLensUnitFlagStyle", Locale.Lookup("LOC_CQUI_LENSES_RELIGIONLENSUNITFLAGSTYLE_TOOLTIP"));
    PopulateCheckBox(Controls.AutoapplyReligionLensInCityCheckbox, "CQUI_AutoapplyReligionLensInCity", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYRELIGIONLENSINCITY_TOOLTIP"));
    
    -- Expansion 1 Lens Options
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        Controls.AutoapplyLoyaltyLensInCityCheckbox:SetHide(false);
        PopulateCheckBox(Controls.AutoapplyLoyaltyLensInCityCheckbox, "CQUI_AutoapplyLoyaltyLensInCity", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYLOYALTYLENSINCITY_TOOLTIP"));
    end
    
    -- Expansion 2 Lens Options
    if (g_bIsGatheringStorm) then
        Controls.AutoapplyPowerLensInCityCheckbox:SetHide(false);
        PopulateCheckBox(Controls.AutoapplyPowerLensInCityCheckbox, "CQUI_AutoapplyPowerLensInCity", Locale.Lookup("LOC_CQUI_LENSES_AUTOAPPLYPOWERLENSINCITY_TOOLTIP"));
    end
    
    -- Add Individual Builder Lenses
    PopulateLensRGBPickerSettings();

    PopulateCheckBox(Controls.ShowYieldsOnCityHoverCheckbox, "CQUI_ShowYieldsOnCityHover", Locale.Lookup("LOC_CQUI_CITYVIEW_SHOWYIELDSONCITYHOVER_TOOLTIP"));
    PopulateCheckBox(Controls.ShowCitizenIconsOnHoverCheckbox, "CQUI_ShowCitizenIconsOnCityHover", Locale.Lookup("LOC_CQUI_CITYVIEW_SHOWCITIZENICONSONHOVER_TOOLTIP"));
    PopulateCheckBox(Controls.ShowCityManageAreaOnHoverCheckbox, "CQUI_ShowCityManageAreaOnCityHover", Locale.Lookup("LOC_CQUI_CITYVIEW_SHOWCITYMANAGEONHOVER_TOOLTIP"));
    PopulateCheckBox(Controls.ShowUnitPathsCheckbox, "CQUI_ShowUnitPaths");
    PopulateCheckBox(Controls.AutoExpandUnitActionsCheckbox, "CQUI_AutoExpandUnitActions");
    PopulateCheckBox(Controls.AlwaysOpenTechTreesCheckbox, "CQUI_AlwaysOpenTechTrees");
    PopulateCheckBox(Controls.SmartWorkIconCheckbox, "CQUI_SmartWorkIcon", Locale.Lookup("LOC_CQUI_CITYVIEW_SMARTWORKICON_TOOLTIP"));
    PopulateCheckBox(Controls.ShowPolicyReminderCheckbox, "CQUI_ShowPolicyReminder", Locale.Lookup("LOC_CQUI_GENERAL_SHOWPRD_TOOLTIP"));
    -- Number of steps for each setting in each slider is set in the XML
    PopulateSlider(Controls.WorkIconSizeSlider, Controls.WorkIconSizeText, "CQUI_WorkIconSize", SliderControlConverter, "", 48, 128);
    PopulateSlider(Controls.SmartWorkIconSizeSlider, Controls.SmartWorkIconSizeText, "CQUI_SmartWorkIconSize", SliderControlConverter, "", 48, 128);
    PopulateSlider(Controls.WorkIconAlphaSlider, Controls.WorkIconAlphaText, "CQUI_WorkIconAlpha", SliderControlConverter, "", 0, 100);
    PopulateSlider(Controls.SmartWorkIconAlphaSlider, Controls.SmartWorkIconAlphaText, "CQUI_SmartWorkIconAlpha", SliderControlConverter, "", 0, 100);
    PopulateSlider(Controls.InlineCityStateQuestFontSize, Controls.InlineCityStateQuestFontSizeText, "CQUI_InlineCityStateQuestFontSize", SliderControlConverter, "", 8, 14);
    
    -- Notifications
    PopulateCheckBox(Controls.NotificationGoodyHutCheckbox,   "CQUI_NotificationGoodyHut");
    PopulateCheckBox(Controls.NOTIFICATION_CITY_LOW_AMENITIESCheckbox,   "CQUI_NOTIFICATION_CITY_LOW_AMENITIES");
    PopulateCheckBox(Controls.NOTIFICATION_HOUSING_PREVENTING_GROWTHCheckbox,   "CQUI_NOTIFICATION_HOUSING_PREVENTING_GROWTH");
    PopulateCheckBox(Controls.NOTIFICATION_CITY_FOOD_FOCUSCheckbox,   "CQUI_NOTIFICATION_CITY_FOOD_FOCUS");
    --PopulateCheckBox(Controls.NotificationTradeDealCheckbox,  "CQUI_NotificationTradeDeal");
    --PopulateCheckBox(Controls.NotificationPopulationCheckbox, "CQUI_NotificationPopulation");
    --PopulateCheckBox(Controls.NotificationCityBorderCheckbox, "CQUI_NotificationCityBorder");

    -- Expansion 1 Notifications
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        -- Nothing (for now)
    end

    -- Expansion 2 Notifications
    if (g_bIsGatheringStorm) then
        Controls.NOTIFICATION_CITY_UNPOWEREDCheckbox:SetHide(false);
        PopulateCheckBox(Controls.NOTIFICATION_CITY_UNPOWEREDCheckbox, "CQUI_NOTIFICATION_CITY_UNPOWERED");
    end

    -- Gossip
    PopulateCheckBox(Controls.TrimGossipCheckbox, "CQUI_TrimGossip", Locale.Lookup("LOC_CQUI_GOSSIP_TRIMMESSAGE_TOOLTIP"));
    InitializeGossipCheckboxes();

    InitializeTraderScreenCheckboxes();

    ContextPtr:SetShowHandler( OnShow );

    --Setting up panel controls
    ShowTab(m_tabs[1][1], m_tabs[1][2]); --Show General Settings on start
    ContextPtr:SetInputHandler( OnInputHandler, true );

    --Bind CQUI events
    LuaEvents.CQUI_ToggleSettings.Add(OnSettingsButtonClicked);
    LuaEvents.CQUI_SettingsUpdate.Add(ToggleSmartbannerCheckboxes);
    LuaEvents.CQUI_SettingsUpdate.Add(ToggleSmartWorkIconSettings);
    LuaEvents.CQUI_SettingsUpdate.Add(ToggleSuzerainOptionsCheckboxes);
    LuaEvents.CQUI_SettingsUpdate.Add(UpdateKeyBindingsDisplay);
    LuaEvents.CQUI_SettingsUpdate.Add(ToggleInlineCityStateQuestFontSizeSlider);
    LuaEvents.CQUI_SettingsUpdate.Add(ToggleCityBannerHoverOptions);
    LuaEvents.CQUI_SettingsUpdate.Add(ToggleMultiplayerPopupOptions);

    LuaEvents.CQUI_SettingsInitialized.Add(ToggleSmartbannerCheckboxes);
    LuaEvents.CQUI_SettingsInitialized.Add(ToggleSmartWorkIconSettings);
    LuaEvents.CQUI_SettingsInitialized.Add(ToggleSuzerainOptionsCheckboxes);
    LuaEvents.CQUI_SettingsInitialized.Add(UpdateKeyBindingsDisplay);
    LuaEvents.CQUI_SettingsInitialized.Add(ToggleInlineCityStateQuestFontSizeSlider);
    LuaEvents.CQUI_SettingsInitialized.Add(ToggleCityBannerHoverOptions);
    LuaEvents.CQUI_SettingsInitialized.Add(ToggleMultiplayerPopupOptions);

    LuaEvents.CQUI_SettingsInitialized(); --Tell other elements that the settings have been initialized and it's safe to try accessing settings now
end

-- ===========================================================================
function ToggleSmartbannerCheckboxes()
    local selected = Controls.SmartbannerCheckbox:IsSelected();
    Controls.SmartbannerCheckboxes:SetHide(not selected);
    Controls.CityViewStack:ReprocessAnchoring();
end

-- ===========================================================================
function ToggleSuzerainOptionsCheckboxes()
    local selected = (GameConfiguration.GetValue("CQUI_ShowSuzerainInCityStateBanner") ~= 0);  -- 0 is Do Not Show
    Controls.CityStateSuzerainOptions:SetHide(not selected);
    Controls.CityViewStack:ReprocessAnchoring();
end

-- ===========================================================================
function ToggleSmartWorkIconSettings()
    local selected = Controls.SmartWorkIconCheckbox:IsSelected();
    Controls.SmartWorkIconSettings:SetHide(not selected);
    Controls.CityViewStack:ReprocessAnchoring();
end

-- ===========================================================================
function ToggleInlineCityStateQuestFontSizeSlider()
    local selected = Controls.InlineCityStateQuest:IsSelected();
    Controls.InlineCityStateQuestFontSizeStack:SetHide(not selected);
    Controls.GeneralOptionsStack:ReprocessAnchoring();
end

-- ===========================================================================
function ToggleCityBannerHoverOptions()
    local selected = Controls.ShowYieldsOnCityHoverCheckbox:IsSelected();
    Controls.ShowCitizenIconsOnHoverCheckbox:SetHide(not selected);
    Controls.ShowCityManageAreaOnHoverCheckbox:SetHide(not selected);
    Controls.CityViewStack:ReprocessAnchoring();
end

-- ===========================================================================
function UpdateKeyBindingsDisplay()
    local selected = (GameConfiguration.GetValue("CQUI_BindingsMode") ~= 0);
    Controls.KeyBindingsScrollPanel:SetHide(not selected);
end

-- ===========================================================================
function ToggleMultiplayerPopupOptions()
    -- Check if multiplayer
    if (not GameConfiguration.IsAnyMultiplayer()) then
        return;
    end

    -- Check if the multiplayer popups checkbox is checked
    local selected = Controls.MultiplayerPopupsCheckbox:IsSelected();

    -- Show/hide all of the popup options based on the state of the main checkbox
    -- Base game options
    Controls.TechCivicCompletedVisualCheckbox:SetShow(selected);
    Controls.TechCivicCompletedAudioCheckbox:SetShow(selected);
    Controls.BoostUnlockedVisualCheckbox:SetShow(selected);
    Controls.EraCompleteVisualCheckbox:SetShow(selected);
    Controls.ProjectBuiltVisualCheckbox:SetShow(selected);
    Controls.UnitCapturedVisualCheckbox:SetShow(selected);
    Controls.NaturalWonderVisualCheckbox:SetShow(selected);
    Controls.NaturalWonderAudioCheckbox:SetShow(selected);
    Controls.WonderBuiltVisualCheckbox:SetShow(selected);
    Controls.WonderBuiltAudioCheckbox:SetShow(selected);

    -- Expansion 1 options
    if (g_bIsRiseAndFall or g_bIsGatheringStorm) then
        Controls.HistoricMomentsVisualCheckbox:SetShow(selected);
    end

    -- Expansion 2 options
    if (g_bIsGatheringStorm) then
        Controls.NaturalDisasterVisualCheckbox:SetShow(selected);
        Controls.RockBandMovieVisualCheckbox:SetShow(selected);
    end

    -- Secret Societies options
    if (GameCapabilities.HasCapability("CAPABILITY_SECRETSOCIETIES")) then
        Controls.SecretSocietyDiscoveredVisualCheckbox:SetShow(selected);
        Controls.SecretSocietyJoinedVisualCheckbox:SetShow(selected);
    end

    -- Heroes and Legends options
    if (GameInfo.Kinds.KIND_HEROCLASS ~= nil) then
        Controls.HeroDiscoveredVisualCheckbox:SetShow(selected);
        Controls.HeroExpiredVisualCheckbox:SetShow(selected);
    end

    -- Option group labels
    Controls.WonderPopupsLabel:SetShow(selected);
    Controls.OtherPopupsLabel:SetShow(selected);

    -- Reprocess anchoring
    Controls.PopupsOptionsStack:ReprocessAnchoring();
end

-- Include the logic specific to the Lenses color settings
include("cqui_settingselement_lenscolors.lua");

Initialize();
