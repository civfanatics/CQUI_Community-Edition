-- ===========================================================================
-- Base File
-- ===========================================================================
include("UnitFlagManager");
include("CQUICommon.lua");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_SetColor = UnitFlag.SetColor;
BASE_CQUI_UpdateStats = UnitFlag.UpdateStats;
BASE_CQUI_OnUnitSelectionChanged = OnUnitSelectionChanged;
BASE_CQUI_OnUnitPromotionChanged = OnUnitPromotionChanged;
BASE_CQUI_UpdateFlagType = UnitFlag.UpdateFlagType;
BASE_CQUI_OnLensLayerOn = OnLensLayerOn;
BASE_CQUI_OnLensLayerOff = OnLensLayerOff;
BASE_CQUI_ShouldHideFlag = ShouldHideFlag;
BASE_CQUI_Subscribe = Subscribe;
BASE_CQUI_Unsubscribe = Unsubscribe;
BASE_CQUI_UpdateName = UnitFlag.UpdateName;
BASE_CQUI_UpdateVisibility = UnitFlag.UpdateVisibility;
BASE_CQUI_UpdateDimmedState = UnitFlag.UpdateDimmedState;

local m_HexColoringReligion:number = UILens.CreateLensLayerHash("Hex_Coloring_Religion");
local m_IsReligionLensOn:boolean = false;
local m_CQUIInitiatedRefresh = false;

-- Constants (from Barbarian Clans mode)
local BRIBE_STATUS_ICON_NAME				: string = "Bribe22";
local INCITE_AGAINST_PLAYER_STATUS_ICON_NAME: string = "Incite22";
local INCITE_BY_PLAYER_STATUS_ICON_NAME		: string = "InciteByMe22";	--TODO: Asset requested

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
        -- Call the CQUI_Refresh, which will update the unit flags based on the setting that changed
        CQUI_Refresh();
    end
end

-- ===========================================================================
-- Update the stats of the flags (Azurency) and update the flag transparency if Religion Lens is displayed (the_m4a)
function CQUI_Refresh()
    local unitList = Players[Game.GetLocalPlayer()]:GetUnits();
    if unitList ~= nil then
        local applyDimming = false;
        if (m_IsReligionLensOn and (CQUI_ReligionLensUnitFlagStyle == CQUI_RELIGIONLENS_UNITFLAGSTYLE_TRANSPARENT)) then
            applyDimming = true;
        end

        for _,pUnit in unitList:Members() do
            local eUnitID = pUnit:GetID();
            local eOwner  = pUnit:GetOwner();

            local flag = GetUnitFlag( eOwner, eUnitID );
            if flag ~= nil then
                flag:UpdateStats();

                if (flag.m_eVisibility == RevealedState.VISIBLE and flag.m_Style ~= FLAGSTYLE_RELIGION) then
                    if (m_IsReligionLensOn and (CQUI_ReligionLensUnitFlagStyle == CQUI_RELIGIONLENS_UNITFLAGSTYLE_TRANSPARENT)) then
                        flag.m_Instance.FlagRoot:SetToEnd();
                        flag.m_Instance.FlagRoot:SetAlpha(ALPHA_DIM / 2); -- 1/2 of the "normal" dim
                        flag.m_Instance.HealthBar:SetAlpha(ALPHA_DIM / 2);
                        if (flag.m_Instance.Promotion_Flag ~= nil and flag.m_Instance.Promotion_Flag:IsVisible()) then
                            flag.m_Instance.Promotion_Flag:SetAlpha(ALPHA_DIM / 2);
                        end
                    elseif (m_IsReligionLensOn and (CQUI_ReligionLensUnitFlagStyle == CQUI_RELIGIONLENS_UNITFLAGSTYLE_HIDDEN)) then
                        flag.m_Instance.FlagRoot:SetToEnd();
                        flag.m_Instance.FlagRoot:SetAlpha(0.0); -- 1/2 of the "normal" dim
                        flag.m_Instance.HealthBar:SetAlpha(0.0);
                        if (flag.m_Instance.Promotion_Flag ~= nil and flag.m_Instance.Promotion_Flag:IsVisible()) then
                            flag.m_Instance.Promotion_Flag:SetAlpha(0.0);
                        end
                    else
                        -- Handle the "normal" dimmed or undimmed state
                        flag:UpdateDimmedState();
                    end
                end
            end
        end
    end
end

-- ===========================================================================
function CQUI_UpdateDimmedStateOnFlags(self)
    if (self.m_IsDimmed and not self.m_OverrideDimmed) then
        if (self.m_Instance.Promotion_Flag:IsVisible()) then
             self.m_Instance.Promotion_Flag:SetAlpha(ALPHA_DIM);
        end

        if (self.m_Instance.TribeStatusFlag:IsVisible()) then
            self.m_Instance.TribeStatusFlag:SetAlpha(ALPHA_DIM);
        end

        if (self.m_Instance.TribeInidcatorFlag:IsVisible()) then
           self.m_Instance.TribeInidcatorFlag:SetAlpha(ALPHA_DIM);
        end
    else
        if (self.m_Instance.Promotion_Flag:IsVisible()) then
            self.m_Instance.Promotion_Flag:SetAlpha(1.0);
       end

       if (self.m_Instance.TribeStatusFlag:IsVisible()) then
           self.m_Instance.TribeStatusFlag:SetAlpha(1.0);
       end

       if (self.m_Instance.TribeInidcatorFlag:IsVisible()) then
          self.m_Instance.TribeInidcatorFlag:SetAlpha(1.0);
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
        LuaEvents.CQUI_showUnitPath(true, unitID);

        CQUI_IsFlagHover = true;
    end
end

-- ===========================================================================
function CQUI_OnUnitFlagPointerExited(playerID:number, unitID:number)
    if m_IsReligionLensOn and not CQUI_IsReligiousUnit(playerID, unitID) then
        return;
    end

    if CQUI_ShowPaths and CQUI_IsFlagHover and not m_IsReligionLensOn then
        LuaEvents.CQUI_clearUnitPath();

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

    local pUnit : table = self:GetUnit();
    if (pUnit ~= nil) then
        self:SetColor();
    end
end

-- ===========================================================================
--  CQUI modified UnitFlag.UpdateDimmedState functiton
--  Ensure the additional Flags (Unit promotions, barbarian flags) are dimmed accordingly
-- ===========================================================================
function UnitFlag.UpdateDimmedState( self )
    BASE_CQUI_UpdateDimmedState(self);
    CQUI_UpdateDimmedStateOnFlags(self);
end

-- ===========================================================================
--  CQUI modified UnitFlag.UpdateVisibility functiton
--  Ensure the additional Flags (Unit promotions, barbarian flags) are dimmed accordingly
-- ===========================================================================
function UnitFlag.UpdateVisibility( self )
    BASE_CQUI_UpdateVisibility(self);
    if (not self.m_IsForceHide and self.m_IsCurrentlyVisible) then
        CQUI_UpdateDimmedStateOnFlags(self);
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
                    self.m_Instance.UnitNumPromotions:SetText(#promotionList);
                    self.m_Instance.Promotion_Flag:SetHide(false);
                end
            end
        end

        -- WORKAROUND: The Barbarian Clans Mode also uses ReplaceUIScript for UnitFlagManager, so to use both that code was integrated with CQUI.
        --             This code is copied from the UnitFlagManager_BarbarianClansMode.lua
        if (g_bIsBarbarianClansMode) then
            UnitFlag.UpdatePromotionsBarbarianClansMode(self, pUnit);
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
                ContextPtr:RequestRefresh();
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
        CQUI_Refresh();
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
        CQUI_Refresh();
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
-- IMPORTS FROM THE BARBARIAN CLANS MODE
-- Firaxis implemented the Barbarian Clans Mode using a ReplaceUIScript with UnitFlagManager
-- ReplaceUIScript can only happen once, so in order to get their additions to work with CQUI, we have to copy that code
-- The functions below pull those changes from Barbarian Clans mode in to CQUI so they can work together
-- ===========================================================================
function UnitFlag.UpdatePromotionsBarbarianClansMode(self, pUnit)
    -- This is the code specific to the Barbarian Clans Mode from that DLC that is added to the UnitFlag.UpdatePromotions function.
    self.m_Instance.TribeStatusFlag:SetHide(true);
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    self.m_Instance.TribeInidcatorFlag:SetHide(true);
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
    local tribeIndex : number = pUnit:GetBarbarianTribeIndex();
    if (tribeIndex >= 0) then

        local pBarbarianTribeManager : table = Game.GetBarbarianManager();
        local bribedTurnsRemaining : number = pBarbarianTribeManager:GetTribeBribeTurnsRemaining(tribeIndex, localPlayerID);
        self.m_Instance.Promotion_Flag:SetHide(true);

        -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
        -- CQUI Specific Change: Show the barbarian clan (so we know who we're dealing with without having to mouse-over)
        local barbType : number = pBarbarianTribeManager:GetTribeNameType(tribeIndex);
        local pBarbTribe : table = GameInfo.BarbarianTribeNames[barbType];
        self.m_Instance.TribeInidcatorFlag:SetHide(false);
        self.m_Instance.TribeIndicatorIcon:SetIcon("ICON_" .. pBarbTribe.TribeNameType);
        -- ==== CQUI CUSTOMIZATION END ======================================================================================== --

        --Show any Barbarian Tribe specific status icons (bribed, incited)
        if (bribedTurnsRemaining > 0) then
            --Show bribe icon w/ turns remaining tooltip
            self.m_Instance.TribeStatusFlag:SetHide(false);
            self.m_Instance.TribeStatusIcon:SetTexture(BRIBE_STATUS_ICON_NAME);
            return;
        else
            local inciteTargetID : number = pBarbarianTribeManager:GetTribeInciteTargetPlayer(tribeIndex);
            if (inciteTargetID >= 0) then
                if(inciteTargetID == localPlayerID)then
                    --Show incited against us icon
                    self.m_Instance.TribeStatusFlag:SetHide(false);
                    self.m_Instance.TribeStatusIcon:SetTexture(INCITE_AGAINST_PLAYER_STATUS_ICON_NAME);
                    return;
                else
                    local inciteSourceID : number = pBarbarianTribeManager:GetTribeInciteSourcePlayer(tribeIndex);
                    if(inciteSourceID == localPlayerID)then
                        --Show we incited them icon
                        self.m_Instance.TribeStatusFlag:SetHide(false);
                        self.m_Instance.TribeStatusIcon:SetTexture(INCITE_BY_PLAYER_STATUS_ICON_NAME);
                        return;
                    end
                end
            end
        end
    end
end -- BarbarianClansMode Loaded

-- ===========================================================================
function UnitFlag.UpdateName( self )
    BASE_CQUI_UpdateName(self);

    -- WORKAROUND: This implements the extension to UnitFlag.UpdateName that Firaxis put into
    -- their UnitFlagManager_BarbarianClansMode.lua.  Copying that code here allows CQUI to load its UnitFlagManager
    -- changes with the Barbarian Clans mode.
    if (g_bIsBarbarianClansMode) then
        local localPlayerID : number = Game.GetLocalPlayer();
        if (localPlayerID == -1) then
            return;
        end
    
        local pUnit : table = self:GetUnit();
        if(pUnit ~= nil)then
            local tribeIndex : number = pUnit:GetBarbarianTribeIndex();
            if(tribeIndex >= 0)then
                local pBarbarianTribeManager : table = Game.GetBarbarianManager();
                local bribedTurnsRemaining : number = pBarbarianTribeManager:GetTribeBribeTurnsRemaining(tribeIndex, localPlayerID);
                local nameString = self.m_Instance.UnitIcon:GetToolTipString();
    
                local barbType : number = pBarbarianTribeManager:GetTribeNameType(tribeIndex);
                if(barbType >= 0)then
                    local pBarbTribe : table = GameInfo.BarbarianTribeNames[barbType];
                    nameString = nameString .. "[NEWLINE]" .. Locale.Lookup(pBarbTribe.TribeDisplayName);

                    --Add any Barbarian Tribe specific statuses (bribed, incited) to the unit tooltip
                    if(bribedTurnsRemaining > 0)then
                        --Add bribe turns remaining to the unit tooltip
                        nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_BARBARIAN_STATUS_BRIBED", bribedTurnsRemaining);
                    else
                        local inciteTargetID : number = pBarbarianTribeManager:GetTribeInciteTargetPlayer(tribeIndex);
                        if (inciteTargetID >= 0) then
                            if(inciteTargetID == localPlayerID)then
                                --Add incited against us to the unit tooltip
                                local inciteSourcePlayer : table = PlayerConfigurations[pBarbarianTribeManager:GetTribeInciteSourcePlayer(tribeIndex)];
                                local inciteSourcePlayerName : string = inciteSourcePlayer:GetPlayerName();
                                nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_BARBARIAN_STATUS_INCITED_AGAINST_YOU", inciteSourcePlayerName);
                            else
                                local inciteSourceID : number = pBarbarianTribeManager:GetTribeInciteSourcePlayer(tribeIndex);
                                if(inciteSourceID == localPlayerID)then
                                    --Add incited by us to the unit tooltip
                                    local inciteTargetPlayer : table = PlayerConfigurations[pBarbarianTribeManager:GetTribeInciteTargetPlayer(tribeIndex)];
                                    local inciteTargetPlayerName : string = inciteTargetPlayer:GetPlayerName();
                                    nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_BARBARIAN_STATUS_INCITED_BY_YOU", inciteTargetPlayerName);
                                end
                            end
                        end
                    end
    
                    self.m_Instance.UnitIcon:SetToolTipString( nameString );
                end
            end
        end
    end -- if Barbarian Clans Mode loaded
end

-- ===========================================================================
function OnPlayerOperationComplete(playerID : number, operation : number)
    -- Update Barbarian UnitFlag tooltip and status icons in case we have Bribed or Incited them
    if (operation == PlayerOperations.BRIBE_CLAN or operation == PlayerOperations.INCITE_CLAN) then
        local pBarbarianPlayer = Players[PlayerTypes.BARBARIAN]
        local pBarbarianUnits:table = pBarbarianPlayer:GetUnits();
        for i, pUnit in pBarbarianUnits:Members() do
            local flag:table = GetUnitFlag(PlayerTypes.BARBARIAN, pUnit:GetID());
            flag:UpdateName();
            flag:UpdatePromotions();
        end
    end
end

-- ===========================================================================
function Subscribe()
    BASE_CQUI_Subscribe();
    Events.PlayerOperationComplete.Add(OnPlayerOperationComplete);
end

-- ===========================================================================
function Unsubscribe()
    if BASE_CQUI_Unsubscribe ~= nil then
        BASE_CQUI_Unsubscribe();
    end

    Events.PlayerOperationComplete.Remove(OnPlayerOperationComplete);
end

-- ===========================================================================
-- END Imports from Barbarian Clans Mode
-- ===========================================================================

-- ===========================================================================
function Initialize_UnitFlagManager_CQUI()
    ContextPtr:SetRefreshHandler(CQUI_Refresh);

    Events.DiplomacyMakePeace.Add(OnDiplomacyWarStateChange);
    Events.DiplomacyDeclareWar.Add(OnDiplomacyWarStateChange);
    Events.UnitChargesChanged.Add(OnUnitChargesChanged);
    Events.UnitSelectionChanged.Remove(BASE_CQUI_OnUnitSelectionChanged);
    Events.UnitSelectionChanged.Add(OnUnitSelectionChanged);
    Events.UnitPromoted.Remove(BASE_CQUI_OnUnitPromotionChanged);
    Events.UnitPromoted.Add(OnUnitPromotionChanged);

    LuaEvents.UnitFlagManager_PointerEntered.Add(CQUI_OnUnitFlagPointerEntered);
    LuaEvents.UnitFlagManager_PointerExited.Add(CQUI_OnUnitFlagPointerExited);

    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize_UnitFlagManager_CQUI();
