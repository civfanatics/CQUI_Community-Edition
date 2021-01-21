-- ===========================================================================
-- CQUI GreatPeopleHeroPanel replacement for GreatPeopleHeroPanel.lua, found in Babylon DLC (DLC/Babylon/UI/Additions)
-- Full file replacement is necessary because of Firaxis' use of local variables that CQUI requires access to in order to implement the scaling based on screen resolution
-- CQUI changes are marked with Customization Begin/End Tags
-- ===========================================================================

-- Copyright 2020, Firaxis Games

include("InstanceManager");
include("HeroesSupport");
include("CivilizationIcon");
-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
-- Include CQUICommon.lua for GreatPeople vertical size calculation
include("CQUICommon.lua");
-- ==== CQUI CUSTOMIZATION END ======================================================================================== --

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================

local m_sPortraitPrefix:string = "ICON_";
local m_sPortraitSuffix:string = "_PORTRAIT";

-- ===========================================================================
--  MEMBERS
-- ===========================================================================

local m_pHeroPanelIM:table      = InstanceManager:new("HeroPanelInstance",  "Content",  Controls.HeroStack);
local m_pAbilityIM:table        = InstanceManager:new("AbilityInstance",    "Top");
local m_pCommandIM:table        = InstanceManager:new("CommandInstance",    "Top");
local m_pStatIM:table           = InstanceManager:new("StatInstance",       "Top");

local m_newestHeroType:string   = "";

-- ===========================================================================
function RefreshHeroes()
    ClearHeroes();

    local pGameHeroes:object = Game.GetHeroesManager();
    for row in GameInfo.HeroClasses() do
        if pGameHeroes:IsHeroDiscovered(Game.GetLocalPlayer(), row.Index) then
            AddHero(row);
        end
    end
end

-- ===========================================================================
function AddHero( kHeroDef:table )
    local kHeroInstance:object = m_pHeroPanelIM:GetInstance();

    local sHeroName:string = "";
    if kHeroDef.HeroClassType == m_newestHeroType then
        sHeroName = "[ICON_New] ";
    end
    sHeroName = sHeroName .. Locale.ToUpper(kHeroDef.Name);
    kHeroInstance.IndividualName:SetText(sHeroName);

    local sIconName:string = m_sPortraitPrefix .. kHeroDef.HeroClassType .. m_sPortraitSuffix;
    kHeroInstance.Portrait:SetIcon(sIconName);

    -- Stats
    local kStats:table = GetHeroUnitStats(kHeroDef.Index);

    if kStats.Lifespan ~= nil then
        local pLifespanInst:table = m_pStatIM:GetInstance(kHeroInstance.EffectStack);
        pLifespanInst.StatIcon:SetIcon("ICON_LIFESPAN");
        pLifespanInst.ValueText:SetText(kStats.Lifespan);
        pLifespanInst.NameText:SetText(Locale.Lookup("LOC_HUD_UNIT_PANEL_LIFESPAN"));
    end

    if kStats.BaseMoves ~= nil and kStats.BaseMoves > 0 then
        local pCombatInst:table = m_pStatIM:GetInstance(kHeroInstance.EffectStack);
        pCombatInst.StatIcon:SetIcon("ICON_MOVES");
        pCombatInst.ValueText:SetText(kStats.BaseMoves);
        pCombatInst.NameText:SetText(Locale.Lookup("LOC_HUD_UNIT_PANEL_MOVEMENT"));
    end

    if kStats.Combat ~= nil and kStats.Combat > 0 then
        local pCombatInst:table = m_pStatIM:GetInstance(kHeroInstance.EffectStack);
        pCombatInst.StatIcon:SetIcon("ICON_STRENGTH");
        pCombatInst.ValueText:SetText(kStats.Combat);
        pCombatInst.NameText:SetText(Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH"));
    end
        
    if kStats.RangedCombat ~= nil and kStats.RangedCombat > 0 then
        local pRangedCombatInst:table = m_pStatIM:GetInstance(kHeroInstance.EffectStack);
        pRangedCombatInst.StatIcon:SetIcon("ICON_RANGED_STRENGTH");
        pRangedCombatInst.ValueText:SetText(kStats.RangedCombat);
        pRangedCombatInst.NameText:SetText(Locale.Lookup("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH"));
    end

    if kStats.Range ~= nil and kStats.Range > 0 then
        local pRangedCombatInst:table = m_pStatIM:GetInstance(kHeroInstance.EffectStack);
        pRangedCombatInst.StatIcon:SetIcon("ICON_RANGE");
        pRangedCombatInst.ValueText:SetText(kStats.Range);
        pRangedCombatInst.NameText:SetText(Locale.Lookup("LOC_HUD_UNIT_PANEL_ATTACK_RANGE"));
    end

    if kStats.Charges ~= nil and kStats.Charges > 0 then
        local pChargesInst:table = m_pStatIM:GetInstance(kHeroInstance.EffectStack);
        pChargesInst.StatIcon:SetIcon("ICON_STATS_SPREADCHARGES");
        pChargesInst.ValueText:SetText(kStats.Charges);
        pChargesInst.NameText:SetText(Locale.Lookup("LOC_HUD_UNIT_PANEL_CHARGES"));
    end

    -- Abilities
    local kAbilities:table = GetHeroClassUnitAbilities(kHeroDef.Index);
    for _, kAbility in pairs(kAbilities) do
        local pAbilityInst:table = m_pAbilityIM:GetInstance(kHeroInstance.EffectStack);
        pAbilityInst.AbilityName:SetText(Locale.ToUpper(kAbility.Name));
        pAbilityInst.AbilityText:SetText(Locale.Lookup(kAbility.Description));
    end

    -- Commands
    local kCommands:table = GetHeroClassUnitCommands(kHeroDef.Index);
    for _, kCommand in pairs(kCommands) do
        local pCommandInst:table = m_pCommandIM:GetInstance(kHeroInstance.EffectStack);
        pCommandInst.CommandName:SetText( Locale.ToUpper(kCommand.Name) );
        pCommandInst.CommandText:SetText( Locale.Lookup(kCommand.Description) );
        pCommandInst.CommandIcon:SetIcon( kCommand.Icon );
    end

    -- Setup Civilopedia button
    if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_CIVPEDIA") then
        kHeroInstance.CivilopediaButton:RegisterCallback( Mouse.eLClick, function() OpenCivilopediaForHero(kHeroDef.UnitType); end );
        kHeroInstance.CivilopediaButton:SetHide(false);
    else
        kHeroInstance.CivilopediaButton:SetHide(true);
    end

    -- Hero Status
    local pGameHeroes:object = Game.GetHeroesManager();
    local claimedByPlayer:number = pGameHeroes:GetHeroClaimPlayer(kHeroDef.Index);

    if claimedByPlayer ~= -1 then
        kHeroInstance.HeroStatus:SetText(Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_RECRUITED_STATE"));

        local kCivIconController:table = CivilizationIcon:AttachInstance( kHeroInstance.ClaimedByCivIcon );
        kCivIconController:UpdateIconFromPlayerID( claimedByPlayer );
        kCivIconController:SetLeaderTooltip( claimedByPlayer );
        kHeroInstance.ClaimedByCivIcon.CivIconBacking:SetHide(false);

        -- Determine if the hero is still alive
        local bIsAlive:boolean = false;
        local pHeroUnit:object = nil;
        local pPlayer:object = Players[claimedByPlayer];
        if pPlayer ~= nil then
            local pPlayerUnits:table = pPlayer:GetUnits();
            for i, pUnit in pPlayerUnits:Members() do
                if GameInfo.Units[pUnit:GetType()].UnitType == kHeroDef.UnitType then
                    bIsAlive = true;
                    pHeroUnit = pUnit;
                end
            end
        end

        kHeroInstance.DeceasedText:SetHide(bIsAlive);

        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
        -- CQUI change, show the origin city if the hero is claimed
        kHeroInstance.CQUI_HeroOriginCity:SetHide(true);
        -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

        local bHideLookAtButton:boolean = true;
        local bHideRecallButton:boolean = true;
        if claimedByPlayer == Game.GetLocalPlayer() then
            -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
            -- CQUI: Show the City value (code relocated from else case below)
            local cityID:table = pGameHeroes:GetHeroOriginCityID(kHeroDef.Index);
            local pPlayerCities:object = Players[claimedByPlayer]:GetCities();
            local pHeroCity:object = pPlayerCities:FindID(cityID.id);
            -- ==== CQUI CUSTOMIZATION END ====================================================================================== --

            -- Show Look at Hero/City button if claimed by the active player
            if pHeroUnit ~= nil then
                kHeroInstance.LookAtButton:SetToolTipString(Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_LOOK_AT_HERO_TT"));
                kHeroInstance.LookAtButton:RegisterCallback( Mouse.eLClick, function() LookAtUnit(pHeroUnit); end);
                bHideLookAtButton = false;
                -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
                -- CQUI: Show the Home City value (this shows "Home City: City Name")
                kHeroInstance.CQUI_HeroOriginCity:SetHide(false);
                kHeroInstance.CQUI_HeroOriginCity:SetText(Locale.Lookup("LOC_UNITFLAG_ARCHAEOLOGY_HOME_CITY", pHeroCity:GetName()))
                -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
            else
                if pHeroCity then
                    kHeroInstance.LookAtButton:SetToolTipString(Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_LOOK_AT_CITY_TT"))
                    kHeroInstance.LookAtButton:RegisterCallback( Mouse.eLClick, function() LookAtCity(pHeroCity); end);
                    bHideLookAtButton = false;

                    -- Show the Recall button if the hero isn't alive and can be recalled by the claimed player
                    if not bIsAlive then
                        bHideRecallButton = not UpdateRecallButton( kHeroInstance, kHeroDef.Index, kHeroDef.UnitType, pHeroCity );
                    end
                end
            end
        end
        kHeroInstance.LookAtButton:SetHide(bHideLookAtButton);
        kHeroInstance.FaithRecallButton:SetHide(bHideRecallButton);
    else
        kHeroInstance.HeroStatus:SetText(Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_DISCOVERED_STATE"));
        kHeroInstance.ClaimedByCivIcon.CivIconBacking:SetHide(true);
        kHeroInstance.DeceasedText:SetHide(true);
        kHeroInstance.LookAtButton:SetHide(true);
        kHeroInstance.FaithRecallButton:SetHide(true);
    end

    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- Set the heights of the various elements in the Great People Panel instance as has been computed
    -- These functions are defined in CQUICommon.lua
    kHeroInstance.Content:SetSizeY(CQUI_GreatPeoplePanel_GetControlSizeY("Content"));
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
end

-- ===========================================================================
function OpenCivilopediaForHero( sHeroUnitType:string )
    LuaEvents.GreatPeopleHeroPanel_Close();
    LuaEvents.OpenCivilopedia(sHeroUnitType);
end

-- ===========================================================================
function LookAtUnit( pUnit:object )
    LuaEvents.GreatPeopleHeroPanel_Close();
    UI.LookAtPlotScreenPosition( pUnit:GetX(), pUnit:GetY(), 0.5, 0.5 );
    UI.SelectUnit( pUnit );
end

-- ===========================================================================
function LookAtCity( pCity:object )
    LuaEvents.GreatPeopleHeroPanel_Close();
    UI.LookAtPlotScreenPosition( pCity:GetX(), pCity:GetY(), 0.5, 0.5 );
    UI.SelectCity( pCity );
end

-- ===========================================================================
function UpdateRecallButton( kHeroInstance:table, eHeroClass:number, sUnitType:string, pCity:object )
    local kHeroUnitDef:table = GameInfo.Units[sUnitType];
    local kYieldDef:table = GameInfo.Yields["YIELD_FAITH"];

    local tParameters = {};
    tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = kHeroUnitDef.Hash;
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = kYieldDef.Index;
    if CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, true, tParameters, false ) then
        local isCanStart, results = CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, false, tParameters, true );

        local pCityGold:table = pCity:GetGold();
        local faithCost:number = pCityGold:GetPurchaseCost( kYieldDef.Index, kHeroUnitDef.Hash, MilitaryFormationTypes.STANDARD_MILITARY_FORMATION );
        kHeroInstance.FaithRecallButton:SetText(faithCost .. "[ICON_Faith]");

        local sToolTip:string = Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_FAITH_RECALL_TT", faithCost);

        if isCanStart then
            kHeroInstance.FaithRecallButton:RegisterCallback( Mouse.eLClick, function() RecallHero(eHeroClass); end );
            kHeroInstance.FaithRecallButton:SetDisabled(false);
        else
            -- Add failure reasons to the tooltip
            if results ~= nil and results[CityCommandResults.FAILURE_REASONS] ~= nil then
                local kFailureReasons:table = results[CityCommandResults.FAILURE_REASONS];
                if kFailureReasons ~= nil and table.count( kFailureReasons ) > 0 then
                    for i,v in ipairs(kFailureReasons) do
                        sToolTip = sToolTip .. "[NEWLINE][NEWLINE][COLOR:Red]" .. Locale.Lookup(v) .. "[ENDCOLOR]";
                    end
                end
            end

            -- Affordability check
            local pPlayerReligion = Players[pCity:GetOwner()]:GetReligion();
            if pPlayerReligion ~= nil and not pPlayerReligion:CanAfford( pCity:GetID(), kHeroUnitDef.Hash ) then
                sToolTip = sToolTip .. "[NEWLINE][NEWLINE]" .. Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_INSUFFICIENT_FAITH_TT");
            end

            kHeroInstance.FaithRecallButton:SetDisabled(true);
        end

        kHeroInstance.FaithRecallButton:SetToolTipString(sToolTip);

        return true;
    end

    return false;
end

-- ===========================================================================
function RecallHero( eHeroClass:number )
    local kHeroDef:table = GameInfo.HeroClasses[eHeroClass];
    local kHeroUnitDef:table = GameInfo.Units[kHeroDef.UnitType];

    local pGameHeroes:object = Game.GetHeroesManager();
    local claimedByPlayer:number = pGameHeroes:GetHeroClaimPlayer(kHeroDef.Index);
    local pPlayerCities:object = Players[claimedByPlayer]:GetCities();
    local kCityID:table = pGameHeroes:GetHeroOriginCityID(kHeroDef.Index);
    local pHeroCity:object = pPlayerCities:FindID(kCityID.id);

    -- Close the panel and look at the city the hero will be spawned in
    LuaEvents.GreatPeopleHeroPanel_Close();
    UI.LookAtPlotScreenPosition( pHeroCity:GetX(), pHeroCity:GetY(), 0.5, 0.5 );

    -- Purchase the hero
    local tParameters = {};
    tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = kHeroUnitDef.Hash;
    tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION;
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index;  
    UI.PlaySound("Purchase_With_Faith");
    CityManager.RequestCommand(pHeroCity, CityCommandTypes.PURCHASE, tParameters);
end

-- ===========================================================================
function ClearHeroes()
    if m_pStatIM ~= nil then
        m_pStatIM:ResetInstances();
    end

    if m_pAbilityIM ~= nil then
        m_pAbilityIM:ResetInstances();
    end

    if m_pCommandIM ~= nil then
        m_pCommandIM:ResetInstances();
    end

    if m_pHeroPanelIM ~= nil then
        m_pHeroPanelIM:ResetInstances();
    end
end

-- ===========================================================================
function OnHeroStackSizeChanged()
    LuaEvents.GreatPeopleHeroPanel_SizeChanged(Controls.HeroStack:GetSizeX());
end

-- ===========================================================================
function OnHeroesPopup_ShowNewHero( kHeroDef:table )
    m_newestHeroType = kHeroDef.HeroClassType;
    LuaEvents.GreatPeopleHeroPanel_Show();
end

-- ===========================================================================
function Initialize()
    -- Set this context to autosize
    ContextPtr:SetAutoSize(true);

    LuaEvents.GreatPeoplePopup_RefreshHeroes.Add(RefreshHeroes);
    LuaEvents.GreatPeoplePopup_ClearHeroes.Add(ClearHeroes);
    LuaEvents.HeroesPopup_ShowNewHero.Add(OnHeroesPopup_ShowNewHero);

    Controls.HeroStack:RegisterSizeChanged( OnHeroStackSizeChanged );
end
Initialize();
