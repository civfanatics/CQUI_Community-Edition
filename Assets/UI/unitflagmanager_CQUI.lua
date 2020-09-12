-- ===========================================================================
-- Base File
-- ===========================================================================
include("UnitFlagManager");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_SetColor = UnitFlag.SetColor;
BASE_CQUI_UpdateStats = UnitFlag.UpdateStats;
BASE_CQUI_OnUnitSelectionChanged = OnUnitSelectionChanged;
BASE_CQUI_OnPlayerTurnActivated = OnPlayerTurnActivated;
BASE_CQUI_OnUnitPromotionChanged = OnUnitPromotionChanged;
BASE_CQUI_UpdateFlagType = UnitFlag.UpdateFlagType;
BASE_CQUI_OnLensLayerOn = OnLensLayerOn;
BASE_CQUI_OnLensLayerOff = OnLensLayerOff;
BASE_CQUI_ShouldHideFlag = ShouldHideFlag;
BASE_CQUI_UpdateIconStack = UpdateIconStack;
BASE_CQUI_Refresh = Refresh;

local m_HexColoringReligion:number = UILens.CreateLensLayerHash("Hex_Coloring_Religion");
local m_IsReligionLensOn:boolean = false;
local m_CQUIInitiatedRefresh = false;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_ShowingPath = nil; --unitID for the unit whose path is currently being shown. nil for no unit
local CQUI_SelectionMade = false;
local CQUI_ShowPaths = true; --Toggle for showing the paths
local CQUI_IsFlagHover = false; -- if the path is the flag us currently hover or not

local CQUI_RELIGIONLENS_UNITFLAGSTYLE_SOLID       = 0;
local CQUI_RELIGIONLENS_UNITFLAGSTYLE_TRANSPARENT = 1;
local CQUI_RELIGIONLENS_UNITFLAGSTYLE_HIDDEN      = 2;
local CQUI_ReligionLensUnitFlagStyle = CQUI_RELIGIONLENS_UNITFLAGSTYLE_TRANSPARENT; -- Update flag of non-religious units when the Religion Lens is enabled

-- ===========================================================================
--Hides any currently drawn paths.
function CQUI_HidePath()
    if CQUI_ShowPaths and CQUI_IsFlagHover then
        LuaEvents.CQUI_clearUnitPath();
        CQUI_IsFlagHover = false;
    end
end

-- ===========================================================================
function CQUI_OnSettingsUpdate()
    CQUI_HidePath();
    CQUI_ShowPaths = GameConfiguration.GetValue("CQUI_ShowUnitPaths");

    -- If the lens is showing, we'll need to do an update to re-show the units
    local curHideUnitsValue = CQUI_ReligionLensUnitFlagStyle;
    CQUI_ReligionLensUnitFlagStyle = GameConfiguration.GetValue("CQUI_ReligionLensUnitFlagStyle");
    --print("********* m_IsReligionLensOn: "..tostring(m_IsReligionLensOn).." curHideUnitsValue:"..tostring(curHideUnitsValue).." CQUI_ReligionLensUnitFlagStyle:"..tostring(CQUI_ReligionLensUnitFlagStyle))
    if (m_IsReligionLensOn and curHideUnitsValue ~= CQUI_ReligionLensUnitFlagStyle) then
        -- Call the Refresh, which will update the unit flags based on the setting that changed
        CQUI_RefreshForReligionLensUpdate();
    end
end

-- ===========================================================================
function CQUI_Refresh()
    -- AZURENCY : update the stats of the flags on refresh
    local unitList = Players[Game.GetLocalPlayer()]:GetUnits();
    if unitList ~= nil then
        for _,pUnit in unitList:Members() do
            local eUnitID = pUnit:GetID();
            local eOwner  = pUnit:GetOwner();

            local pFlag = GetUnitFlag( eOwner, eUnitID );
            if pFlag ~= nil then
                pFlag:UpdateStats();
            end
        end
    end
end

-- ===========================================================================
function CQUI_IsReligiousUnit(playerID:number, unitID:number)
    local retVal = false;
    local pPlayer = Players[playerID];
    if pPlayer ~= nil then
        local pUnit = pPlayer:GetUnits():FindID(unitID);
        if pUnit ~= nil and pUnit:GetReligiousStrength() > 0 then
            retVal = true;
        end
    end

    return retVal;
end

-- ===========================================================================
function CQUI_OnUnitFlagPointerEntered(playerID:number, unitID:number)
    if m_IsReligionLensOn and not CQUI_IsReligiousUnit(playerID, unitID) then
        -- If the lens was enabled from the Lenses Menu, it is possible to show the queued path on mouseover
        -- If we are here, then the religion lens is on, but player is hovering on a non-religious unit
        return;
    end

    if CQUI_ShowPaths and not CQUI_IsFlagHover then
        if not CQUI_SelectionMade then
            LuaEvents.CQUI_showUnitPath(true, unitID);
        end

        CQUI_IsFlagHover = true;
    end
end

-- ===========================================================================
function CQUI_OnUnitFlagPointerExited(playerID:number, unitID:number)
    if m_IsReligionLensOn and not CQUI_IsReligiousUnit(playerID, unitID) then
        return;
    end

    if CQUI_ShowPaths and CQUI_IsFlagHover and not m_IsReligionLensOn then
        if not CQUI_SelectionMade then
            LuaEvents.CQUI_clearUnitPath();
        end

        CQUI_IsFlagHover = false;
    end
end

-- ===========================================================================
--  CQUI modified UnitFlag.SetColor functiton
--  Enemy unit flags are red-tinted when at war with you
-- ===========================================================================
function UnitFlag.SetColor( self )
    BASE_CQUI_SetColor(self)

    local instance:table = self.m_Instance;
    instance.FlagBaseDarken:SetHide(true);

    -- War Check
    if Game.GetLocalPlayer() > -1 then
        local pUnit : table = self:GetUnit();
        local localPlayer =  Players[Game.GetLocalPlayer()];
        local ownerPlayer = pUnit:GetOwner();
        --instance.FlagBaseDarken:SetHide(false);

        local isAtWar = localPlayer:GetDiplomacy():IsAtWarWith( ownerPlayer );
        local CQUI_isBarb = Players[ownerPlayer]:IsBarbarian(); --pUnit:GetBarbarianTribeIndex() ~= -1

        if (isAtWar and (not CQUI_isBarb)) then
            instance.FlagBaseDarken:SetColor( UI.GetColorValue(255,0,0,255) );
            instance.FlagBaseDarken:SetHide(false);
        end
    end
end

-- ===========================================================================
--  CQUI modified UnitFlag.UpdateFlagType functiton
--  Set the right texture for the FlagBaseDarken used on enemy unit during war
-- ===========================================================================
function UnitFlag.UpdateFlagType( self )
    BASE_CQUI_UpdateFlagType(self)

    local pUnit = self:GetUnit();
    if pUnit == nil then
        return;
    end

    local textureName = self.m_Instance.FlagBase:GetTexture():gsub('_Combo', '');
    self.m_Instance.FlagBaseDarken:SetTexture( textureName );
end

-- ===========================================================================
--  CQUI modified UnitFlag.UpdateStats functiton
--  Also set the color
-- ===========================================================================
function UnitFlag.UpdateStats( self )
    BASE_CQUI_UpdateStats(self);
    if (pUnit ~= nil) then
        self:SetColor();
    end
end

-- ===========================================================================
--  CQUI modified UnitFlag.UpdatePromotions functiton
--  Builder show charges in promotion flag
--  Unit pending a promotion show a "+"
-- ===========================================================================

-- Infixo converts promotions into a few font icons
-- an Apostle can have up to 3 promos

local tReligionPromosMap:table = {
    --PROMOTION_ORATOR -- adds charges
    PROMOTION_PROSELYTIZER       = { Icon = "[ICON_Damaged]" },-- 75% reduce
    PROMOTION_TRANSLATOR         = { Icon = "[ICON_Bombard]" }, -- 3x pressure
    --PROMOTION_PILGRIM -- adds charges
    PROMOTION_INDULGENCE_VENDOR  = { Icon = "[ICON_Gold]" }, -- gold
    PROMOTION_HEATHEN_CONVERSION = { Icon = "[ICON_Barbarian]" }, -- barbs
    PROMOTION_DEBATER            = { Icon = "[ICON_Ability]" }, -- +20 combat
    PROMOTION_MARTYR             = { Icon = "[ICON_GreatWork_Relic]" }, -- relic
    PROMOTION_CHAPLAIN           = { Icon = "[ICON_Religion]" },-- medic
    -- add more promos here to support other mods, etc.
};

-- add names to speed up TT creation
for promoType,promoData in pairs(tReligionPromosMap) do
    promoData.Name = Locale.Lookup( GameInfo.UnitPromotions[ promoType ].Name );
end

-- ===========================================================================
function GetReligionPromotions(pUnit:table)
    local sPromos:string, sTT:string = "", "";
    for _,promoID in ipairs(pUnit:GetExperience():GetPromotions()) do
        local promoData:table = tReligionPromosMap[ GameInfo.UnitPromotions[promoID].UnitPromotionType ];
        if promoData ~= nil then
            sPromos = sPromos..promoData.Icon;
            if sTT ~= "" then sTT = sTT.."[NEWLINE]";end
            sTT = sTT..promoData.Icon.." "..promoData.Name;
        end
    end
    return sPromos, sTT;
end

-- ===========================================================================
function UnitFlag.UpdatePromotions( self )
    self.m_Instance.Promotion_Flag:SetHide(true);
    local pUnit : table = self:GetUnit();
    local isLocalPlayerUnit: boolean = pUnit:GetOwner() == Game:GetLocalPlayer(); --ARISTOS: hide promotion/charge info if not local player's unit!
    if pUnit ~= nil then
        -- If this unit is levied (ie. from a city-state), showing that takes precedence
        local iLevyTurnsRemaining = GetLevyTurnsRemaining(pUnit);
        if (iLevyTurnsRemaining >= 0) then
            self.m_Instance.UnitNumPromotions:SetText("[ICON_Turn]");
            self.m_Instance.Promotion_Flag:SetHide(false);
        -- Otherwise, show the experience level
        elseif ((GameInfo.Units[pUnit:GetUnitType()].UnitType == "UNIT_BUILDER") or (GameInfo.Units[pUnit:GetUnitType()].UnitType == "UNIT_MILITARY_ENGINEER")) and isLocalPlayerUnit then
            local uCharges = pUnit:GetBuildCharges();
            self.m_Instance.New_Promotion_Flag:SetHide(true);
            self.m_Instance.UnitNumPromotions:SetText(uCharges);
            self.m_Instance.Promotion_Flag:SetHide(false);
            self.m_Instance.Promotion_Flag:SetOffsetX(-4);
            self.m_Instance.Promotion_Flag:SetOffsetY(12);

        -- Infixo extension to show charges for religious units and promotions for Apostles
        elseif isLocalPlayerUnit and self.m_Style == FLAGSTYLE_RELIGION then
            --print("religious unit", pUnit:GetID(), pUnit:GetType(), pUnit:GetUnitType(), pUnit:GetName());
            -- charges
            self.m_Instance.New_Promotion_Flag:SetHide(true);
            self.m_Instance.UnitNumPromotions:SetText( pUnit:GetSpreadCharges() + pUnit:GetReligiousHealCharges() );
            self.m_Instance.Promotion_Flag:SetHide(false);
            -- promotions
            local sPromos:string, sTT:string = GetReligionPromotions(pUnit);
            self.m_Instance.ReligionPromotions:SetText(sPromos);
            self.m_Instance.ReligionPromotions:SetToolTipString(sTT);
            self.m_Instance.ReligionPromotions:SetHide(false);

        else
            local unitExperience = pUnit:GetExperience();
            if (unitExperience ~= nil) then
                local promotionList :table = unitExperience:GetPromotions();
                self.m_Instance.New_Promotion_Flag:SetHide(true);
                --ARISTOS: to test for available promotions! Previous test using XPs was faulty (Firaxis... :rolleyes:)
                local bCanStart, tResults = UnitManager.CanStartCommand( pUnit, UnitCommandTypes.PROMOTE, true, true);
                -- AZURENCY : CanStartCommand will return false if the unit have no movements left but still can have 
                -- a promotion (maybe not this turn, but it have enough experience, so we'll show it on the flag anyway)
                if not bCanStart then
                    bCanStart = unitExperience:GetExperiencePoints() >= unitExperience:GetExperienceForNextLevel()
                end

                -- Nilt: Added check to prevent the promotion flag staying a red + permanently on max XP units.
                if bCanStart and isLocalPlayerUnit and (#promotionList < 7) then
                    self.m_Instance.New_Promotion_Flag:SetHide(false);
                    self.m_Instance.UnitNumPromotions:SetText("[COLOR:StatBadCS]+[ENDCOLOR]");
                    self.m_Instance.Promotion_Flag:SetHide(false);
                --end
                --ARISTOS: if already promoted, or no promotion available, show # of proms
                elseif (#promotionList > 0) then
                    --[[
                    local tooltipString :string = "";
                    for i, promotion in ipairs(promotionList) do
                        tooltipString = tooltipString .. Locale.Lookup(GameInfo.UnitPromotions[promotion].Name);
                        if (i < #promotionList) then
                            tooltipString = tooltipString .. "[NEWLINE]";
                        end
                    end
                    self.m_Instance.Promotion_Flag:SetToolTipString(tooltipString);
                    --]]
                    self.m_Instance.UnitNumPromotions:SetText(#promotionList);
                    self.m_Instance.Promotion_Flag:SetHide(false);
                end
            end
        end
    end
end

-- ===========================================================================
--  CQUI modified OnUnitSelectionChanged functiton
--  Hide unit paths on deselect
-- ===========================================================================
function OnUnitSelectionChanged( playerID : number, unitID : number, hexI : number, hexJ : number, hexK : number, bSelected : boolean, bEditable : boolean )
    BASE_CQUI_OnUnitSelectionChanged(playerID, unitID, hexI, hexJ, hexK, bSelected, bEditable);

    if (bSelected) then
        -- CQUI modifications for tracking unit selection and displaying unit paths
        -- unitID could be nil, if unit is consumed (f.e. settler, worker)
        if (unitID ~= nil) then
            CQUI_SelectionMade = true;
            if (CQUI_ShowingPath ~= unitID) then
                if (CQUI_ShowingPath ~= nil) then
                    CQUI_HidePath();
                end

                CQUI_ShowingPath = unitID;
            end
        else
            CQUI_SelectionMade = false;
            CQUI_ShowingPath = nil;
        end
    else
        CQUI_SelectionMade = false;
        CQUI_HidePath();
        CQUI_ShowingPath = nil;
    end
end

-- ===========================================================================
function OnDiplomacyWarStateChange(player1ID:number, player2ID:number)
    local localPlayer =  Players[Game.GetLocalPlayer()];

    local playerToUpdate = player1ID;
    if (player1ID ==Game.GetLocalPlayer()) then
        playerToUpdate = player2ID;
    else
        playerToUpdate = player1ID;
    end

    if (playerToUpdate ~= nil) then
        for index,pUnit in Players[playerToUpdate]:GetUnits():Members() do
            if (pUnit ~= nil) then
                local flag = GetUnitFlag(playerToUpdate, pUnit:GetID());
                if (flag ~= nil) then
                    flag:UpdateStats();
                end
            end
        end
    end
end

-- ===========================================================================
-- Update charges on units
function OnUnitChargesChanged(player, unitID)
    local localPlayerID = Game.GetLocalPlayer();
    local pPlayer = Players[ player ];

    if (player == localPlayerID) then
        local pUnit = pPlayer:GetUnits():FindID(unitID);
        if (pUnit ~= nil) then
            local flagInstance = GetUnitFlag( player, unitID );
            if (flagInstance ~= nil) then
                flagInstance:UpdatePromotions();
            end
        end
    end
end

-- ===========================================================================
--  CQUI modified OnPlayerTurnActivated functiton
--  AutoPlay mod compatibility
-- ===========================================================================
function OnPlayerTurnActivated( ePlayer:number, bFirstTimeThisTurn:boolean )

    local idLocalPlayer = Game.GetLocalPlayer();
    if idLocalPlayer < 0 then
        return;
    end

    BASE_CQUI_OnPlayerTurnActivated(ePlayer, bFirstTimeThisTurn);
end

-- ===========================================================================
--  CQUI modified OnUnitPromotionChanged functiton
--  Refresh the flag promotion sign
-- ===========================================================================
function OnUnitPromotionChanged( playerID : number, unitID : number )
    local pPlayer = Players[ playerID ];
    if (pPlayer ~= nil) then
        local pUnit = pPlayer:GetUnits():FindID(unitID);
        if (pUnit ~= nil) then
            local flag = GetUnitFlag(playerID, pUnit:GetID());
            if (flag ~= nil) then
                --flag:UpdateStats();
                -- AZURENCY : request a refresh on the next frame (to update the promotion flag and remove + sign)
                ContextPtr:RequestRefresh()
            end
        end
    end
end

-- ===========================================================================
--  CQUI modified OnLensLayerOn function
--  If Religion Lens is enabled, call Refresh so non-religious units can be dimmed
-- ===========================================================================
function OnLensLayerOn( layerNum:number )
    BASE_CQUI_OnLensLayerOn(layerNum);

    if (layerNum == m_HexColoringReligion) then
        m_IsReligionLensOn = true;
        -- Call Refresh, which will cycle through all of the units visible to the current player
        -- OnUnitVisibilityChanged will be called for every unit the player can see, where the
        -- icon can be dimmed due to the religion lens being selected.
        CQUI_RefreshForReligionLensUpdate();
    end
end

-- ===========================================================================
--  CQUI modified OnLensLayerOff function
--  If Religion Lens is disabled, call Refresh so non-religious units can be restored
-- ===========================================================================
function OnLensLayerOff( layerNum:number )
    BASE_CQUI_OnLensLayerOff(layerNum);

    if (layerNum == m_HexColoringReligion) then
        m_IsReligionLensOn = false;
        -- See note in OnLensLayerOn as for why we call refresh here
        CQUI_RefreshForReligionLensUpdate();
    end
end

-- ===========================================================================
--  CQUI modified ShouldHideFlag function
--  If Religion Lens is enabled and the unit is NOT a Religous unit and Style is hidden, then hide the other unit flags
-- ===========================================================================
function ShouldHideFlag(pUnit:table)
    local retVal = BASE_CQUI_ShouldHideFlag(pUnit);

    if (m_IsReligionLensOn
       and pUnit:GetReligiousStrength() <= 0
       and CQUI_ReligionLensUnitFlagStyle == CQUI_RELIGIONLENS_UNITFLAGSTYLE_HIDDEN) then
        retVal = true;
    end

    return retVal;
end

-- ===========================================================================
function CQUI_RefreshForReligionLensUpdate()
    -- Track that this refresh was initiated by CQUI, so the work of dimming or hiding the icons can be done
    m_CQUIInitiatedRefresh = true;
    Refresh();
end

-- ===========================================================================
-- CQUI modified Refresh function
-- Whenever Refresh is completed, mark m_CQUIInitiatedRefresh as false 
-- ===========================================================================
function Refresh()
    BASE_CQUI_Refresh();
    m_CQUIInitiatedRefresh = false;
end

-- ===========================================================================
-- CQUI modified UpdateIconStack
-- When a Refresh() has been initiated by CQUI, cycle through the visible units and update their transparency based on CQUI_ReligionLensUnitFlagStyle setting
-- ===========================================================================
function UpdateIconStack( plotX:number, plotY:number )
    BASE_CQUI_UpdateIconStack(plotX, plotY);

    if m_CQUIInitiatedRefresh == false then
        -- Don't do the extra work if CQUI didn't initiate the refresh
        return;
    end

    local applyDimming = false;
    if (m_IsReligionLensOn and (CQUI_ReligionLensUnitFlagStyle == CQUI_RELIGIONLENS_UNITFLAGSTYLE_TRANSPARENT)) then
        applyDimming = true;
    end

    local unitList:table = Units.GetUnitsInPlotLayerID( plotX, plotY, MapLayers.ANY );
    if (unitList ~= nil) then
        for _, pUnit in ipairs(unitList) do
            -- Cache commonly used values (optimization)
            local unitID:number = pUnit:GetID();
            local unitOwner:number = pUnit:GetOwner();
            local flag = GetUnitFlag( unitOwner, unitID );
            if (flag ~= nil and flag.m_eVisibility == RevealedState.VISIBLE and flag.m_Style ~= FLAGSTYLE_RELIGION) then
                -- print("**** unitID: "..tostring(unitID).."  CQUI_ReligionLensUnitFlagStyle:"..tostring(CQUI_ReligionLensUnitFlagStyle).."  applyDimming:"..tostring(applyDimming).." m_IsDimmed:"..tostring(flag.m_IsDimmed).." m_OverrideDimmed:"..tostring(flag.m_OverrideDimmed));
                if (applyDimming) then
                    flag.m_Instance.FlagRoot:SetToEnd();
                    flag.m_Instance.FlagRoot:SetAlpha(ALPHA_DIM / 2); -- 1/2 of the "normal" dim
                    flag.m_Instance.HealthBar:SetAlpha(ALPHA_DIM / 2);
                elseif (flag.m_IsDimmed and not flag._OverrideDimmed) then
                    -- When Religion lens is off, we need to reapply the usual dimming level to units that should have it
                    flag.m_Instance.FlagRoot:SetToEnd();
                    flag.m_Instance.FlagRoot:SetAlpha(ALPHA_DIM);
                    flag.m_Instance.HealthBar:SetAlpha(ALPHA_DIM);
                else
                    flag.m_Instance.FlagRoot:SetAlpha(1.0);
                    flag.m_Instance.HealthBar:SetAlpha(1.0);
                end
            end
        end
    end
end

-- ===========================================================================
function Initialize()
    ContextPtr:SetRefreshHandler(CQUI_Refresh);

    Events.DiplomacyMakePeace.Add(OnDiplomacyWarStateChange);
    Events.DiplomacyDeclareWar.Add(OnDiplomacyWarStateChange);
    Events.UnitChargesChanged.Add(OnUnitChargesChanged);
    Events.UnitSelectionChanged.Remove(BASE_CQUI_OnUnitSelectionChanged);
    Events.UnitSelectionChanged.Add(OnUnitSelectionChanged);
    Events.PlayerTurnActivated.Remove(BASE_CQUI_OnPlayerTurnActivated);
    Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);
    Events.UnitPromoted.Remove(BASE_CQUI_OnUnitPromotionChanged);
    Events.UnitPromoted.Add(OnUnitPromotionChanged);

    LuaEvents.UnitFlagManager_PointerEntered.Add(CQUI_OnUnitFlagPointerEntered);
    LuaEvents.UnitFlagManager_PointerExited.Add(CQUI_OnUnitFlagPointerExited);

    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize();