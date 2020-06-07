include("GameCapabilities");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_VIEW = View;
BASE_CQUI_Refresh = Refresh;
BASE_CQUI_GetUnitActionsTable = GetUnitActionsTable;

-- temp global
actionsTable = nil;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_ShowImprovementsRecommendations :boolean = false;
function CQUI_OnSettingsUpdate()
  CQUI_ShowImprovementsRecommendations = GameConfiguration.GetValue("CQUI_ShowImprovementsRecommendations") == 1
end
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);

-- ===========================================================================
--  CQUI modified View functiton : check if we should show the recommanded action
-- ===========================================================================
function View(data)
  BASE_CQUI_VIEW(data);

  if ( data.Actions["BUILD"] ~= nil and #data.Actions["BUILD"] > 0 ) then
    local BUILD_PANEL_ART_PADDING_Y = 20;
    local buildStackHeight :number = Controls.BuildActionsStack:GetSizeY();

    if not CQUI_ShowImprovementsRecommendations then
      Controls.RecommendedActionButton:SetHide(true);
      Controls.BuildActionsPanel:SetSizeY( buildStackHeight + BUILD_PANEL_ART_PADDING_Y);
      Controls.BuildActionsStack:SetOffsetY(0);
    end
  end

  -- CQUI (Azurency) : instead of changing the xml, it's easier to do it in code here (bigger XP bar)
  Controls.XPArea:SetSizeY(15);
  Controls.XPBar:SetSizeY(10);
  Controls.XPLabel:SetFontSize(12);
end

-- ===========================================================================
--  CQUI modified Refresh functiton : AutoExpand
-- ===========================================================================
function Refresh(player, unitId)
  BASE_CQUI_Refresh(player, unitId);

  if(player ~= nil and player ~= -1 and unitId ~= nil and unitId ~= -1) then
    local units = Players[player]:GetUnits();
    local unit = units:FindID(unitId);
    if(unit ~= nil) then
      --CQUI auto-expando
      if(GameConfiguration.GetValue("CQUI_AutoExpandUnitActions")) then
        local isHidden:boolean = Controls.SecondaryActionsStack:IsHidden();
        if isHidden then
          Controls.SecondaryActionsStack:SetHide(false);
          Controls.ExpandSecondaryActionsButton:SetTextureOffsetVal(0,29);
          OnSecondaryActionStackMouseEnter();
          Controls.ExpandSecondaryActionStack:CalculateSize();
          Controls.ExpandSecondaryActionStack:ReprocessAnchoring();
        end

        -- AZURENCY : fix for the size not updating correcly (fall 2017), we calculate the size manually, 4 is the StackPadding
        Controls.ExpandSecondaryActionStack:SetSizeX(Controls.ExpandSecondaryActionsButton:GetSizeX() + Controls.SecondaryActionsStack:GetSizeX() + 4);
        ResizeUnitPanelToFitActionButtons();
      end
    end
  end
end

-- ===========================================================================
--  CQUI modified Refresh functiton : GetUnitActionsTable
--  Update the Housing tool tip to show Farm Provides 1 Housing when Plaeyr is Maya
--  This is fixing a bug in the unmodified game, as it still shows 0.5 Housing on the tool tip
-- ===========================================================================
function GetUnitActionsTable( pUnit )
  print_debug("CQUI: GetUnitActionsTable Hook Called")
  actionsTable = BASE_CQUI_GetUnitActionsTable(pUnit);

  --[[
    Powershell Script to Pull the two lines from the text file:
  
    $xmlfiles = Get-ChildItem -Filter *.xml
    $pat = 'LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING'
    foreach ($xml in $xmlfiles)
    {
        $fn = $xml.Name
        Get-Content $fn | Select-String -Pattern 'LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING' -Context 0,1
    }
  --]]

  -- Update the Farm Tool Tip to show 1 Housing if the player is Maya
  if HasTrait("TRAIT_CIVILIZATION_MAYAB", Game.GetLocalPlayer()) then
    local iconCount = #actionsTable["BUILD"];
    for i = 1, iconCount do
      if (actionsTable["BUILD"][i]["IconId"] == "ICON_IMPROVEMENT_FARM") then
        -- For some reason, Locale.Lookup("LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING") returns an empty string, so we need to do this manually
        -- Each of the strings below is the LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING value
        -- Note: The Lua string matching requires that we use the escape character (the % sign) for the brackets and plus and other , otherwise the strings will not match
        local curLang = Locale.GetCurrentLanguage();
        local housingStr = "";
        if curLang.Type == "en_US" then
          housingStr = "Provides {1_Amount:number #.#} %[ICON_Housing%] Housing";
        elseif curLang.Type == "de_DE" then
          housingStr = "Gewährt {1_Amount:number #.#} %[ICON_Housing%] Wohnraum";
        elseif curLang.Type == "es_ES" then
          housingStr = "Proporciona {1_Amount:number #.#} a Alojamiento %[ICON_Housing%]";
        elseif curLang.Type == "fr_FR" then
          housingStr = "%[ICON_Housing%] Habitations %+{1_Amount:number #.#}.";
        elseif curLang.Type == "it_IT" then
          housingStr = "Fornisce {1_Amount:number #.#} %[ICON_Housing%] Abitazioni";
        elseif curLang.Type == "ja_JP" then
          housingStr = "%[ICON_Housing%] 住宅%+{1_Amount:number #.#}";
        elseif curLang.Type == "ko_KR" then
          housingStr = "%[ICON_Housing%] 주거공간 {1_Amount:number #.#} 제공";
        elseif curLang.Type == "pl_PL" then
          housingStr = "Daje następującą liczbę %[ICON_Housing%] obszarów mieszkalnych: {1_Amount:number #.#}";
        elseif curLang.Type == "pt_BR" then
          housingStr = "Concede {1_Amount:number #.#} de %[ICON_Housing%] habitação";
        elseif curLang.Type == "ru_RU" then
          housingStr = "Предоставляет {1_Amount:number #.#} %[ICON_Housing%] жилья";
        elseif curLang.Type == "zh_Hans_CN" then
          housingStr = "提供{1_Amount:number #.#} %[ICON_Housing%] 住房";
        elseif curLang.Type == "zh_Hant_HK" then
          housingStr = "提供 {1_Amount:number #.#} %[ICON_Housing%] 住房";
        else
          print("Unknown language type: "..tostring(curLang.Type));
        end

        if housingStr ~= "" then
          local chunkToUpdate = "{1_Amount:number #.#}";
          local housingStrBefore = housingStr:gsub(chunkToUpdate, tostring(Locale.ToNumber("0.5")));
          local housingStrAfter = housingStr:gsub(chunkToUpdate, "1");

          print_debug("housingStr is: "..housingStr);
          print_debug("housingStrBefore is: "..housingStrBefore);
          print_debug("housingStrAfter is: "..housingStrAfter);

          local updatedHelpString, replacedCount = actionsTable["BUILD"][i]["helpString"]:gsub(housingStrBefore, housingStrAfter);
          print_debug("updatedHelpString is: "..updatedHelpString);
          print_debug("replacedCount is: "..tostring(replacedCount));

          if replacedCount == 1 then
            actionsTable["BUILD"][i]["helpString"] = updatedHelpString;
          end
        end

        break -- Only the farm icon needs updating, break from the for loop
      end
    end
  end

  return actionsTable;
end