-- TODO: The "non-advanced" game mode setup should have a "Use Reccomended CQUI settings"
--       though I suppose that disabling this should mean they're all set to zero?

-- GameModeItems appears on the Advanced Settings Screen
INSERT OR REPLACE INTO Parameters
    (ParameterId, Name, Description, Domain, DefaultValue, ConfigurationGroup, ConfigurationId, NameArrayConfigurationId, GroupId, SortIndex, ReadOnly)
VALUES
    ('ID_CQUI_OPTION_DUMMYLINE',
     '--------------------',
     NULL,
     'text',
     '[COLOR_LIGHTBLUE]CQUI OPTIONS ------------------[ENDCOLOR]',
     'Game',
     'ID_CQUI_OPTION_DUMMYLINE',
     NULL, -- Config Id
     'AdvancedOptions',
     5000, -- SortIndex
     1); -- Readonly

INSERT OR REPLACE INTO Parameters
        (ParameterId, Name, Description, Domain, DefaultValue, ConfigurationGroup, ConfigurationId, NameArrayConfigurationId, GroupId, SortIndex)
VALUES
    ('CQUI_Smartbanner_GameSetup', -- Parameter Id
     'Enable SmartBanners', -- Name
     'LOC_CQUI_CITYVIEW_SMARTBANNER_TOOLTIP',-- Description
     'bool', -- Domain (type: uint, bool, text, int)
     1, -- Default Value
     'Game', -- Config Group
     'CQUI_Smartbanner_GameSetup', -- Config Id
     'CQUI_ConfigurationArray', -- Name Array Config Id
     'AdvancedOptions',
     5001);

INSERT OR REPLACE INTO Parameters
        (ParameterId, Name, Description, Domain, DefaultValue, ConfigurationGroup, ConfigurationId, NameArrayConfigurationId, GroupId, SortIndex)
VALUES
    ('CQUI_RelocateCityStrike_GameSetup', -- Parameter Id
     'LOC_CQUI_CITYVIEW_RELOCATECITYSTRIKEBUTTON', -- Name
     'LOC_CQUI_CITYVIEW_RELOCATECITYSTRIKEBUTTON_TOOLTIP',-- Description
     'bool', -- Domain (type: uint, bool, text, int)
     1, -- Default Value
     'Game', -- Config Group
     'CQUI_RelocateCityStrike_GameSetup', -- Config Id
     'CQUI_ConfigurationArray', -- Name Array Config Id
     'AdvancedOptions',
     5002);

INSERT OR REPLACE INTO Parameters
        (ParameterId, Name, Description, Domain, DefaultValue, ConfigurationGroup, ConfigurationId, NameArrayConfigurationId, GroupId, SortIndex)
VALUES
    ('CQUI_RelocateEncampmentStrike_GameSetup', -- Parameter Id
     'LOC_CQUI_CITYVIEW_RELOCATEENCAMPMENTSTRIKEBUTTON', -- Name
     'LOC_CQUI_CITYVIEW_RELOCATEENCAMPMENTSTRIKEBUTTON_TOOLTIP',-- Description
     'bool', -- Domain (type: uint, bool, text, int)
     0, -- Default Value
     'Game', -- Config Group
     'CQUI_RelocateEncampmentStrike_GameSetup', -- Config Id
     'CQUI_ConfigurationArray', -- Name Array Config Id
     'AdvancedOptions',
     5003);

-- For putting on the Front Menu?

-- INSERT OR REPLACE INTO GameModeItems
--         (GameModeType,
--         Name,
--         Description,
--         Portrait,
--         Background,
--         Icon,
--         UnitIcon,
--         UnitDescription,
--         UnitName,
--         SortIndex)
-- VALUES  (
--         'CQUI_OPTION_SMARTBANNER', -- The value that is matched against in the Modinfo file, in the Criteria section
--         'LOC_CQUI_CITYVIEW_SMARTBANNER', -- Name of the thing
--         'LOC_CQUI_CITYVIEW_SMARTBANNER_TOOLTIP', -- Tooltip for the thing
--         'LEADER_HOJO_BACKGROUND',
--         'LEADER_HOJO_BACKGROUND',
--         'ICON_CITYSTATE_MILITARISTIC',
--         NULL,
--         NULL,
--         NULL,
--         40
--         );

