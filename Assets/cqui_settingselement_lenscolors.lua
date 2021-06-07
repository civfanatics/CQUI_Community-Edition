-- Make the modular lens colors configurable (the_m4a)
-- print("**** File Loaded: CQUI_SettingsElement_LensColors.lua");

-- This file contains the logic tied to the control instances created to allow updating
-- of the lens colors in the CQUI Settings panel
local m_lensRGBSettingsIM = InstanceManager:new("LensRGBPickerLensGroupInstance", "LensRGBPickerLensGroupInstanceRoot", Controls.LensRGBPickerLensGroupStack);
local m_sliderUpdating = false;
local m_editBoxUpdating = false;

-- ===========================================================================
-- Create all of the control instances for each of the various colors available for each of the lenses
-- Each "Lens" as found in the Modal Lens Panel is considered a Lens Category
-- Each individual item in that Lens Category is a lens, where a slider control or an edit 
-- box can be used to set the RGB values for that lens
function PopulateLensRGBPickerSettings()
    m_lensRGBSettingsIM:ResetInstances();

    -- These are the modded lenses that have been updated so their colors can be set via the settings panel
    -- The Lens names and locale text strings have been updated to follow a specific pattern,
    -- Where a Lens "Base Name" has COLOR_LENSNAME_LENS, and all items for that lens are COLOR_LENSNAME_LENS_ITEM
    -- For example, COLOR_ARCHAEOLOGIST_LENS_SHIPWRECK is for all of the ShipWreck tiles shown by the Archaeologist lens
    local lensGroups = {
        { LensGroupName = "LOC_HUD_ARCHAEOLOGIST_LENS", LensBaseName = "COLOR_ARCHAEOLOGIST_LENS"},
        { LensGroupName = "LOC_HUD_BARBARIAN_LENS",     LensBaseName = "COLOR_BARBARIAN_LENS"},
        { LensGroupName = "LOC_HUD_BUILDER_LENS",       LensBaseName = "COLOR_BUILDER_LENS" },
        { LensGroupName = "LOC_HUD_CITYOVERLAP_LENS",   LensBaseName = "COLOR_CITYOVERLAP_LENS", RowLabelFunc = GenerateCityOverlapRowLabel},
        { LensGroupName = "LOC_HUD_CITY_PLOT_LENS",     LensBaseName = "COLOR_CITY_PLOT_LENS" },
        { LensGroupName = "LOC_HUD_NATURALIST_LENS",    LensBaseName = "COLOR_NATURALIST_LENS"},
        { LensGroupName = "LOC_HUD_ROUTES_LENS",        LensBaseName = "COLOR_ROUTES_LENS"},
        { LensGroupName = "LOC_HUD_RESOURCE_LENS",      LensBaseName = "COLOR_RESOURCE_LENS"},
        { LensGroupName = "LOC_HUD_SCOUT_LENS",         LensBaseName = "COLOR_SCOUT_LENS"},
        { LensGroupName = "LOC_HUD_WONDER_LENS",        LensBaseName = "COLOR_WONDER_LENS"}
    };

    for _,lensGroup in ipairs(lensGroups) do
        -- catEntry is an entry for the category, containing 1-to-n rows of RGB Sliders
        local lensGroupInstance = m_lensRGBSettingsIM:GetInstance();
        lensGroupInstance.LensGroupLabel:SetText(Locale.Lookup(lensGroup.LensGroupName));
        local lensRGBPickerRowIM = InstanceManager:new("LensRGBPickerRowInstance", "LensRGBPickerRowInstanceRoot", lensGroupInstance.LensRGBPickerRowInstanceStack);
        -- MoreLenses adds its colors into the GameInfo.Colors table, so cycling through that list will get us the lens items in each lens category
        for lensColorEntry in GameInfo.Colors() do
            -- If LensBaseName is COLOR_FOO_LENS, then this matches COLOR_FOO_LENS_BAR, COLOR_FOO_LENS_STUFF, etc for the Type field of the item in GameInfo.Colors
            if (string.find(lensColorEntry["Type"], lensGroup.LensBaseName)) then
                local rowLabel = "";
                if (lensGroup.RowLabelFunc ~= nil) then
                    -- This lens group has a custom function for assigning the Row Label
                    rowLabel = lensGroup.RowLabelFunc(lensColorEntry["Type"]);
                else
                    -- This turns COLOR_FOO_LENS_BAR into LOC_HUD_FOO_LENS_BAR
                    rowLabel = Locale.Lookup(string.gsub(lensColorEntry["Type"], lensGroup.LensBaseName, lensGroup.LensGroupName));
                end

                -- Skip any entries that have a blank row label
                if (string.len(rowLabel) > 0) then
                    local lensRGBPickerRowInstance = lensRGBPickerRowIM:GetInstance();
                    PopulateLensRGBPickerRowInstance(lensRGBPickerRowInstance, lensColorEntry["Type"], rowLabel);
                end
            end
        end
    end

    -- Both of these controls are found in cqui_settingselement.xml
    Controls.LensRGBPickerLensGroupStack:CalculateSize();
    Controls.LensesOptionsScrollPanel:CalculateSize();
end

-- ===========================================================================
-- Used to populate the Lens RGB Color Pickers asdf(each row item added to the settings control)
-- pickerRowInstance: The instance returned by the lensColorSetting:GetInstance() call
-- settingName: The name of the lens color item to be retrieved (e.g. COLOR_WONDER_LENS_NATURAL)
-- rowLabel: The label for that row
function PopulateLensRGBPickerRowInstance(pickerRowInstance, settingName, rowLabel)
    local lensItemColorData = GameConfiguration.GetValue(settingName);
    if (lensItemColorData == nil or lensItemColorData["Red"] == nil) then
        -- if lensItemColor data is nil, then it has not yet been added to this GameConfiguration...
        -- or if it has, but one of the fields (like Red) is nil, then the entire data structure may be corrupt.
        -- So, get the default values from GameInfo.Colors that was placed by the MoreLenses_Colors.sql
        if (GameInfo.Colors[settingName]) then
            lensItemColorData = GameInfo.Colors[settingName];
        else
            -- Somehow this value does not exist.  Manually create it.  Note, there are missing fields, but we don't touch them, so...
            lensItemColorData = { Type = settingName, Red = 0, Green = 0, Blue = 0, Alpha = 0.5 }
        end

        GameConfiguration.SetValue(settingName, lensItemColorData);
    end

    pickerRowInstance.RowLabel:SetText(rowLabel);

    -- Add 3 instances of the Label/EditBox/Slider control, one each for Red, Green, and Blue
    local lesIM = InstanceManager:new("LensRGBPickerLabelEditBoxSliderInstance", "LensRGBPickerLabelEditBoxSliderInstanceRoot", pickerRowInstance.LensRGBPickerLabelEditBoxSliderInstanceStack);
    local lesArray = { Red = lesIM:GetInstance(), Green = lesIM:GetInstance(), Blue  = lesIM:GetInstance()};
    for color, lesInstance in pairs(lesArray) do
        lesInstance.LabelCtrl:SetText(Locale.Lookup("LOC_CQUI_LENSES_RGB_COLOR_SETTINGS_" .. string.upper(color)));

        -- lensItemColorData[color] is a float (from the RGB Color setting) that requires conversion; this accomplishes rounding the value correctly, as well
        local currentValue = math.floor((lensItemColorData[color] * 255) + 0.5);
        lesInstance.SliderCtrl:SetStep(GetSliderControlConverter().ToSteps(currentValue, 0, 255, lesInstance.SliderCtrl:GetNumSteps()));
        lesInstance.EditBoxCtrl:SetText(currentValue);

        -- Callback function called whenever the slider changes
        lesInstance.SliderCtrl:RegisterSliderCallback(LensRGBPickerSliderCallback(lesInstance, pickerRowInstance.ColorPreviewBox, settingName, color));
        -- Callback function called whenever the edit box is updated
        lesInstance.EditBoxCtrl:RegisterStringChangedCallback(LensRGBPickerEditBoxCallback(lesInstance, pickerRowInstance.ColorPreviewBox, settingName, color));

        if (tooltip ~= nil and string.len(tooltip) > 0) then
            editBoxControl:SetToolTipString(tooltip);
        end

        lesInstance.LabelStack:CalculateSize();
    end

    pickerRowInstance.LensRGBPickerLabelEditBoxSliderInstanceStack:CalculateSize();
 
    -- Give the color preview box its initial coloring
    pickerRowInstance.ColorPreviewBox:SetColor(UI.GetColorValue(lensItemColorData["Red"], lensItemColorData["Green"], lensItemColorData["Blue"]));

    -- Configure the click action for the Default button, which will reset the color preview box as well as the slider control and edit boxes
    pickerRowInstance.RestoreDefaultButton:RegisterCallback(Mouse.eLClick, LensRGBPickerRestoreDefaultButtonCallback(pickerRowInstance, lesArray, settingName));
end

-- ===============================================================================================
-- Callback function for when the Restore Default button is clicked
function LensRGBPickerRestoreDefaultButtonCallback(pickerRowInstance, lesArray, settingName)
    return function()
        -- Get the default value from the GameInfo.Colors DB (as set by morelenses_colors.sql),
        -- then set the setting by the same name in GameConfiguration to that value.
        lensColorData = GameInfo.Colors[settingName];
        GameConfiguration.SetValue(settingName, lensColorData);
        -- Update all of the controls
        pickerRowInstance.ColorPreviewBox:SetColor(UI.GetColorValue(lensColorData["Red"], lensColorData["Green"], lensColorData["Blue"]));
        for color, lesInstance in pairs(lesArray) do
            -- This is effectively how to round a value in lua
            local current_value = math.floor((lensColorData[color] * 255) + 0.5);
            lesInstance.SliderCtrl:SetStep(GetSliderControlConverter().ToSteps(current_value, 0, 255, lesInstance.SliderCtrl:GetNumSteps()));
            lesInstance.EditBoxCtrl:SetText(current_value);
        end
    end
end

-- ===========================================================================
-- Callback function for when a Slider control is being manipulated
function LensRGBPickerSliderCallback(lesInstance, previewBoxCtrl, settingName, controlColor)
    return function()
        m_sliderUpdating = true;

        -- Get value, update the color changed, set value
        local value = GetSliderControlConverter().ToValue(lesInstance.SliderCtrl:GetStep(), 0, 255, lesInstance.SliderCtrl:GetNumSteps());
        local lensData = GameConfiguration.GetValue(settingName);
        lensData[controlColor] = value / 255.0;
        GameConfiguration.SetValue(settingName, lensData);

        if (false == m_editBoxUpdating) then
            -- if m_editBoxUpdating is true, then this callback was called as a result of the editbox callback updating the slider control
            -- therefore it is not necessary to set the preview box or editbox control values, as they will already be updated in that callback
            lesInstance.EditBoxCtrl:SetText(value);
            previewBoxCtrl:SetColor(UI.GetColorValue(lensData["Red"], lensData["Green"], lensData["Blue"]));
        end

        -- Note: Calling the CQUI_SettingsUpdate LuaEvent here is very slow and not necessary as this Callback is called with every movement
        --       of the slider tab.  Instead, the CQUI_SettingsUpdate LuaEvent is called when the CQUI Settings panel is closed. 
        m_sliderUpdating = false;
    end
end

-- ===========================================================================
-- Callback function for when a text box is being edited
function LensRGBPickerEditBoxCallback(lesInstance, previewBoxCtrl, settingName, controlColor)
    return function()
        m_editBoxUpdating = true;

        local numVal:number = 0;
        local userInput:string = lesInstance.EditBoxCtrl:GetText();
        if (string.len(userInput) > 0 and tonumber(userInput) == nil) then
            -- Box isn't blank, but also not a number
            lesInstance.EditBoxCtrl:SetText("0");
        else
            numVal = tonumber(userInput);
            if (numVal < 0) then
                lesInstance.EditBoxCtrl:SetText("0");
                numVal = 0;
            elseif (numVal > 255) then
                lesInstance.EditBoxCtrl:SetText("255");
                numVal = 255;
            end
        end

        local lensData = GameConfiguration.GetValue(settingName);
        lensData[controlColor] = numVal / 255.0;
        GameConfiguration.SetValue(settingName, lensData);

        if (false == m_sliderUpdating) then
            -- if m_sliderUpdating is true, then this callback was called as a result of the slider callback updating the edit box value
            -- therefore it is not necessary to set the preview box or slider control values, as they will already be updated in that callback
            previewBoxCtrl:SetColor(UI.GetColorValue(lensData["Red"], lensData["Green"], lensData["Blue"]));
            lesInstance.SliderCtrl:SetStep(GetSliderControlConverter().ToSteps(numVal, 0, 255, lesInstance.SliderCtrl:GetNumSteps()));
        end

        -- Note: Calling the CQUI_SettingsUpdate LuaEvent here is not necessary.
        --       Instead, the CQUI_SettingsUpdate LuaEvent is called when the CQUI Settings panel is closed. 
        m_editBoxUpdating = false;
    end
end

-- ===========================================================================
-- Generate the Row Label for the City Overlap entry
function GenerateCityOverlapRowLabel(lensTypeName)
    -- CityOverlap has a special case handling for the KeyLabel
    --     ["COLOR_CITYOVERLAP_LENS_1"] =  { ConfiguredColor = GetLensColorFromSettings("COLOR_CITYOVERLAP_LENS_1"), KeyLabel = "LOC_WORLDBUILDER_TAB_CITIES".." +1" },
    -- So, if lensTypeName is COLOR_CITYOVERLAP_LENS_1, the row Label should be "Cities +1", which uses the LOC_WORLDBUILDER_TAB_CITIES string
    -- This gets the last two characters in the string, so it would get 1 from COLOR_CITYOVERLAP_LENS_1
    local cityOverlapLensRow = string.sub(lensTypeName, -1);
    local rowLabel = Locale.Lookup("LOC_WORLDBUILDER_TAB_CITIES").." +"..cityOverlapLensRow;
    return rowLabel;
end
