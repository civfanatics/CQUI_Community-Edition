-- ===========================================================================
-- Base File
-- ===========================================================================
include("WonderBuiltPopup");
include( "ToolTipHelper" );  -- For AddBuildingYieldTooltip()

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnWonderCompleted = OnWonderCompleted;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
-- Base file local variables copied for use here
local m_kPopupMgr :table = ExclusivePopupManager:new("WonderBuiltPopup");
local m_kCurrentPopup :table = nil;
local m_kQueuedPopups :table = {};

-- CQUI added variables
local m_IsSinglePlayerGame      :boolean = not GameConfiguration.IsAnyMultiplayer();
local CQUI_wonderBuiltVisual    :boolean = m_IsSinglePlayerGame;
local CQUI_wonderBuiltAudio     :boolean = m_IsSinglePlayerGame;
local CQUI_MultiplayerPopups    :boolean = false;

-- ===========================================================================
--  FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--  CQUI added CQUI_OnSettingsUpdate function
--  Update the local variables based on the user settings
-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- Get the user settings
    CQUI_wonderBuiltVisual = GameConfiguration.GetValue("CQUI_WonderBuiltPopupVisual");
    CQUI_wonderBuiltAudio = GameConfiguration.GetValue("CQUI_WonderBuiltPopupAudio");
    CQUI_MultiplayerPopups = GameConfiguration.GetValue("CQUI_MultiplayerPopups");

    -- Check to allow in multiplayer
    if (not CQUI_MultiplayerPopups) then
        CQUI_wonderBuiltVisual = CQUI_wonderBuiltVisual and m_IsSinglePlayerGame;
        CQUI_wonderBuiltAudio = CQUI_wonderBuiltAudio and m_IsSinglePlayerGame;
    end
end

-- ===========================================================================
--  CQUI CQUI_GetWonderTooltip function
--  Inspired by ToolTipHelper.GetBuildingToolTip
-- ===========================================================================
function CQUI_GetWonderTooltip(buildingHash, playerId, cityId)
    local building = GameInfo.Buildings[buildingHash];
    local description = building.Description;
    local city = Players[playerId]:GetCities():FindID(cityID);

    local buildingType:string = "";
    if (building ~= nil) then
        buildingType = building.BuildingType;
    end

    local district = nil;
    if city ~= nil then
        district = city:GetDistricts():GetDistrict(building.PrereqDistrict);
    end
    
    local toolTipLines = {};
    local stats = {};

    AddBuildingYieldTooltip(buildingHash, city, stats);

    for row in GameInfo.Building_YieldDistrictCopies() do
        if (row.BuildingType == buildingType) then
            local from = GameInfo.Yields[row.OldYieldType];
            local to   = GameInfo.Yields[row.NewYieldType];

            table.insert(stats, Locale.Lookup("LOC_TOOLTIP_BUILDING_DISTRICT_COPY", to.IconString, to.Name, from.IconString, from.Name));
        end
    end

    local housing = building.Housing or 0;
    if (housing ~= 0) then
        table.insert(stats, Locale.Lookup("LOC_TYPE_TRAIT_HOUSING", housing));
    end

    AddBuildingEntertainmentTooltip(buildingHash, city, district, stats);

    local citizens = building.CitizenSlots or 0;
    if (citizens ~= 0) then
        table.insert(stats, Locale.Lookup("LOC_TYPE_TRAIT_CITIZENS", citizens));
    end

    local defense = building.OuterDefenseHitPoints or 0;
    if (defense ~= 0) then
        table.insert(stats, Locale.Lookup("LOC_TYPE_TRAIT_OUTER_DEFENSE", defense));
    end

    for row in GameInfo.Building_GreatPersonPoints() do
        if (row.BuildingType == buildingType) then
            local gpClass = GameInfo.GreatPersonClasses[row.GreatPersonClassType];
            if (gpClass) then
                local greatPersonClassName = gpClass.Name;
                local greatPersonClassIconString = gpClass.IconString;
                table.insert(stats, Locale.Lookup("LOC_TYPE_TRAIT_GREAT_PERSON_POINTS", row.PointsPerTurn, greatPersonClassIconString, greatPersonClassName));
            end
        end
    end
    
    local slotStrings = {
        ["GREATWORKSLOT_PALACE"] = "LOC_TYPE_TRAIT_GREAT_WORKS_PALACE_SLOTS";
        ["GREATWORKSLOT_ART"] = "LOC_TYPE_TRAIT_GREAT_WORKS_ART_SLOTS";
        ["GREATWORKSLOT_WRITING"] = "LOC_TYPE_TRAIT_GREAT_WORKS_WRITING_SLOTS";
        ["GREATWORKSLOT_MUSIC"] = "LOC_TYPE_TRAIT_GREAT_WORKS_MUSIC_SLOTS";
        ["GREATWORKSLOT_RELIC"] = "LOC_TYPE_TRAIT_GREAT_WORKS_RELIC_SLOTS";
        ["GREATWORKSLOT_ARTIFACT"] = "LOC_TYPE_TRAIT_GREAT_WORKS_ARTIFACT_SLOTS";
        ["GREATWORKSLOT_CATHEDRAL"] = "LOC_TYPE_TRAIT_GREAT_WORKS_CATHEDRAL_SLOTS";
    };

    for row in GameInfo.Building_GreatWorks() do
        if (row.BuildingType == buildingType) then
            local slotType = row.GreatWorkSlotType;
            local key = slotStrings[slotType];
            if (key) then
                table.insert(stats, Locale.Lookup(key, row.NumSlots));
            end
        end
    end
    
    if (not Locale.IsNilOrWhitespace(description)) then
        table.insert(toolTipLines, Locale.Lookup(description));
    end
    
    if playerId ~= nil and playerId ~= -1 then
        local kPlayerCulture:table = Players[playerId]:GetCulture();
        -- Determine the unlocked Policy, if any
        if building.UnlocksGovernmentPolicy == true then
            local slottounlock :number = kPlayerCulture:GetPolicyToUnlock(building.Index);
            if (slottounlock ~= -1) then
                local newpolicy = GameInfo.Policies[slottounlock];
                if newpolicy ~= nil then
                    table.insert(toolTipLines, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_POLICY_CARD", newpolicy.Name))
                end
            end
        end
    end

    for i,v in ipairs(stats) do
        if (i == 1) then
            table.insert(toolTipLines, "[NEWLINE]" .. v);
        else
            table.insert(toolTipLines, v);
        end
    end

    return table.concat(toolTipLines, "[NEWLINE]");
end

-- ===========================================================================
--  CQUI modified OnWonderCompleted function
--  Setting to disable wonder movie and/or audio
-- ===========================================================================
function OnWonderCompleted( locX:number, locY:number, buildingIndex:number, playerIndex:number, cityId:number, iPercentComplete:number, pillaged:number)

    local localPlayer = Game.GetLocalPlayer();
    if (localPlayer == PlayerTypes.NONE) then
        return; -- Nobody there to click on it, just exit.
    end

    -- Ignore if wonder isn't for this player.
    if (localPlayer ~= playerIndex ) then
        return;
    end

    -- TEMP (ZBR): Ignore if pause-menu is up; prevents stuck camera bug.
    local uiInGameOptionsMenu:table = ContextPtr:LookUpControl("/InGame/TopOptionsMenu");
    if (uiInGameOptionsMenu and uiInGameOptionsMenu:IsHidden()==false) then
        return;
    end

    local kData:table = nil;

    if (GameInfo.Buildings[buildingIndex].RequiresPlacement and iPercentComplete == 100) then
        local currentBuildingType :string = GameInfo.Buildings[buildingIndex].BuildingType;
        if currentBuildingType ~= nil then

            -- CQUI: Only play the visual is allowed by user settings
            if (not CQUI_wonderBuiltVisual) then
                -- CQUI: If there is valid quote audio, play it if allowed by user settings
                if (GameInfo.Buildings[buildingIndex].QuoteAudio ~= nil and CQUI_wonderBuiltAudio) then
                    UI.PlaySound(GameInfo.Buildings[buildingIndex].QuoteAudio);
                end

                -- CQUI: Stop to avoid doing the work for the visaul
                return;
            end

            local kData:table =
            {
                locX = locX,
                locY = locY,
                buildingIndex = buildingIndex,
                currentBuildingType = currentBuildingType,
                currentCityId = cityId -- CQUI: Added cityId for our custom tooltip
            };

            if not m_kPopupMgr:IsLocked() then
                m_kPopupMgr:Lock( ContextPtr, PopupPriority.High );
                ShowPopup( kData );
                LuaEvents.WonderBuiltPopup_Shown(); -- Signal other systems (e.g., bulk hide UI)
            else
                table.insert( m_kQueuedPopups, kData );
            end
        end
    end
end

-- ===========================================================================
--  CQUI modified OnWonderCompleted function
--  Replace the tooltip string with our own, and check the quote audio settings
-- ===========================================================================
function ShowPopup( kData:table )

    if (UI.GetInterfaceMode() ~= InterfaceModeTypes.CINEMATIC) then
        UILens.SaveActiveLens();
        UILens.SetActive("Cinematic");
        UI.SetInterfaceMode(InterfaceModeTypes.CINEMATIC);
    end

    m_kCurrentPopup = kData;

    -- In marketing mode, hide all the UI (temporarly via a timer) but still
    -- play the animation and camera curve.
    if UI.IsInMarketingMode() then
        ContextPtr:SetHide( true );
        Controls.ForceAutoCloseMarketingMode:SetToBeginning();
        Controls.ForceAutoCloseMarketingMode:Play();
        Controls.ForceAutoCloseMarketingMode:RegisterEndCallback( OnClose );
    end

    local locX                  :number = m_kCurrentPopup.locX;
    local locY                  :number = m_kCurrentPopup.locY;
    local buildingIndex         :number = m_kCurrentPopup.buildingIndex;
    local currentBuildingType   :string = m_kCurrentPopup.currentBuildingType;

    -- CQUI: Get the City ID from the popup data too
    local cityID                :number = m_kCurrentPopup.currentCityId;

    Controls.WonderName:SetText(Locale.ToUpper(Locale.Lookup(GameInfo.Buildings[buildingIndex].Name)));
    Controls.WonderIcon:SetIcon("ICON_"..currentBuildingType);

    -- CQUI: Replace the tooltip string with our own custom tooltip
    -- Controls.WonderIcon:SetToolTipString(Locale.Lookup(GameInfo.Buildings[buildingIndex].Description));
    Controls.WonderIcon:SetToolTipString(CQUI_GetWonderTooltip(GameInfo.Buildings[buildingIndex].Hash, Game.GetLocalPlayer(), cityId));

    if (Locale.Lookup(GameInfo.Buildings[buildingIndex].Quote) ~= nil) then
        Controls.WonderQuote:SetText(Locale.Lookup(GameInfo.Buildings[buildingIndex].Quote));
    else
        UI.DataError("The field 'Quote' has not been initialized for "..GameInfo.Buildings[buildingIndex].BuildingType);
    end

    -- Only play quote audio if CQUI settings allow
    if (GameInfo.Buildings[buildingIndex].QuoteAudio ~= nil and CQUI_wonderBuiltAudio) then
        UI.PlaySound(GameInfo.Buildings[buildingIndex].QuoteAudio);
    end

    UI.LookAtPlot(locX, locY);

    Controls.ReplayButton:SetHide(UI.GetWorldRenderView() ~= WorldRenderView.VIEW_3D);

    -- The camera animation does not work on multiplayer
    -- As a workaround, use the Rock Band camera animation if on multiplayer
    -- If this animation doesn't exist for some reason, nothing happens
    if (not m_IsSinglePlayerGame) then
        Events.PlayCameraAnimationAtHex("ROCK_BAND_CONCERT_CAMERA", locX, locY, 0.0, true);
    end
end

-- ===========================================================================
--  CQUI modified Close function
--  Now uses our own m_kQueuedPopups and m_kCurrentPopup
--  Also ensures the camera animation is stopped if in multiplayer
-- ===========================================================================
function Close()

    StopSound();

    -- Stop the multiplayer only camera animation
    if (not m_IsSinglePlayerGame) then
        Events.StopAllCameraAnimations();
    end

    local isDone:boolean  = true;

    -- Find first entry in table, display that, then remove it from the internal queue
    for i, entry in ipairs(m_kQueuedPopups) do
        ShowPopup(entry);
        table.remove(m_kQueuedPopups, i);
        isDone = false;
        break;
    end

    -- If done, restore engine processing and let the world know.
    if isDone then
        m_kCurrentPopup = nil;
        LuaEvents.WonderBuiltPopup_Closed(); -- Signal other systems (e.g., bulk show UI)
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
        UILens.RestoreActiveLens();
        m_kPopupMgr:Unlock();
    end
end

-- ===========================================================================
--  CQUI modified OnRestartMovie function
--  Now uses our own m_kQueuedPopups and m_kCurrentPopup, and checks CQUI audio settings
-- ===========================================================================
function OnRestartMovie()    
    StopSound(); -- stop the music before beginning another go-round
    Events.RestartWonderMovie();

    -- CQUI: Only play quote audio if CQUI settings allow
    local buildingIndex :number = m_kCurrentPopup.buildingIndex;
    if (GameInfo.Buildings[buildingIndex].QuoteAudio ~= nil and CQUI_wonderBuiltAudio) then
        UI.PlaySound(GameInfo.Buildings[buildingIndex].QuoteAudio);
    end

    -- The camera animation does not work on multiplayer
    -- As a workaround, use the Rock Band camera animation if on multiplayer
    -- If this animation doesn't exist for some reason, nothing happens
    if (not m_IsSinglePlayerGame) then
        Events.PlayCameraAnimationAtHex("ROCK_BAND_CONCERT_CAMERA", m_kCurrentPopup.locX, m_kCurrentPopup.locY, 0.0, true);
    end
end

-- ===========================================================================
--  CQUI added Initialize_WonderBuiltPopup_CQUI function
--  Initialize the context
-- ===========================================================================
function Initialize_WonderBuiltPopup_CQUI()

    -- Original file does not inititalize the following on AnyMultiplayer
    -- Initialize it here for multiplayer to optionally allow popups in multiplayer
    if (GameConfiguration.IsAnyMultiplayer()) then
        ContextPtr:SetInputHandler( OnInputHandler, true );

        Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
        Controls.ReplayButton:RegisterCallback(Mouse.eLClick, OnRestartMovie);
        Controls.ReplayButton:SetToolTipString(Locale.Lookup("LOC_UI_ENDGAME_REPLAY_MOVIE"));

        Events.WonderCompleted.Add( OnWonderCompleted );
        Events.WorldRenderViewChanged.Add( OnWorldRenderViewChanged );
        Events.SystemUpdateUI.Add( OnUpdateUI );

    else
        -- If already inititalized, replace the event function with our new one
        -- Also update the replay button control callback
        Controls.ReplayButton:RegisterCallback(Mouse.eLClick, OnRestartMovie);
        Events.WonderCompleted.Remove( BASE_CQUI_OnWonderCompleted );
        Events.WonderCompleted.Add( OnWonderCompleted );
    end

    -- Add the CQUI Settings function to the LuaEvents
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end

-- Start Initialize
Initialize_WonderBuiltPopup_CQUI();