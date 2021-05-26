-- Colors for lenses. (alpha value does not seem to change anything)

-- Builder lens
-- Priority - Outside
-- INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
-- VALUES                  (   'COLOR_BUILDER_PO_LENS',            '0',        '0',        '0',        '0.5');
-- Priority - Dangerous (Red color)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_PD',            '1',        '0',        '0',        '0.5');
-- Priority - 1 (Purple)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P1',            '1',        '0.2',      '1',        '0.5');
-- Priority - 1- (Purple but whitened to show lower priority)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P1N',           '1',        '0.5',      '1',        '0.5');
-- Priority - 2 (Violet)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P2',            '0.6',      '0.2',      '1',        '0.5');
-- Priority - 3 (Blue)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P3',            '0.2',      '0.2',      '1',        '0.5');
-- Priority - 4 (Teal)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P4',            '0',        '0.8',      '0.8',      '0.5');
-- Priority - 5 (Green)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P5',            '0.4',      '1',        '0.4',      '0.5');
-- Priority - 6 (Yellow)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P6',            '1',        '1',        '0',        '0.5');
-- Priority - 7 (White'ish)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_P7',            '0.67',     '0.67',     '0.67',     '0.5');
-- Priority - Nothing (Grey color)
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BUILDER_LENS_PN',            '0.33',     '0.33',     '0.33',     '0.5');

-- Archeologist lens
INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha)
VALUES                  (   'COLOR_ARCHAEOLOGIST_LENS_ARTIFACT',  '1',      '0',        '0',        '0.5');
INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha)
VALUES                  (   'COLOR_ARCHAEOLOGIST_LENS_SHIPWRECK', '0',      '1',        '0',        '0.5');

-- Gradient 8
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_1',         '0.9',      '0.0',      '0.05',     '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_2',         '0.8',      '0.48',     '0.0',      '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_3',         '0.75',     '0.75',     '0.75',     '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_4',         '0.5',      '1',        '0.5',      '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_5',         '0',        '1',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_6',         '0.0',      '0.98',     '0.93',     '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_7',         '0.56',     '0.0',      '0.98',     '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITYOVERLAP_LENS_8',         '0.98',     '0.0',      '0.81',     '0.5');

-- Barbarian Lens
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_BARBARIAN_LENS_ENCAMPMENT',  '1',        '0',        '0',        '0.5');

-- Resources Lens
INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha)
VALUES                  (   'COLOR_RESOURCE_LENS_LUXCONNECTED',   '0.82',   '0.65',     '0.96',     '0.5');
INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha) 
VALUES                  (   'COLOR_RESOURCE_LENS_LUXNCONNECTED',  '1',      '0',        '1',        '0.5');

INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha)
VALUES                  (   'COLOR_RESOURCE_LENS_STRATCONNECTED', '0.96',   '0.54',     '0.54',     '0.5');
INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha)
VALUES                  (   'COLOR_RESOURCE_LENS_STRATNCONNECTED','1',      '0',        '0',        '0.5');

INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha)
VALUES                  (   'COLOR_RESOURCE_LENS_BONUSCONNECTED', '0.5',    '1',        '0.5',      '0.5');
INSERT INTO Colors      (   Type,                                 Red,      Green,      Blue,       Alpha)
VALUES                  (   'COLOR_RESOURCE_LENS_BONUSNCONNECTED','0',      '1',        '0',        '0.5');

-- Wonder Lens
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_WONDER_LENS_NATURAL',        '0',        '1',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_WONDER_LENS_PLAYER',         '1',        '0',        '1',        '0.5');

INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_SCOUT_LENS_GHUT',            '1',        '0',        '1',        '0.5');

-- Naturalist Lens
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_NATURALIST_LENS_PARK',       '0',        '1',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_NATURALIST_LENS_OK',         '0',        '1',        '1',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_NATURALIST_LENS_FIXABLE',    '0.56',     '0.0',      '0.98',     '0.5');


-- City Manager Colors
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITY_PLOT_LENS_WORKING',     '1',        '0.5',      '0',        '0.2');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITY_PLOT_LENS_LOCKED',      '0',        '1',        '0',        '0.2');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_CITY_PLOT_LENS_CULTURE',     '0.89',     '0.431',   '0.862',    '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_AREA_LENS_NEUTRAL',          '0',        '0',        '0',        '0.0');

-- Alternate Settler Colors
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_ALT_SETTLER_RESOURCE',       '1',        '0',        '1',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_ALT_SETTLER_UNUSABLE',       '1',        '0',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_ALT_SETTLER_OVERLAP',        '0.5',      '0',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_ALT_SETTLER_HILL',           '0',        '1',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_ALT_SETTLER_REGULAR',        '0.75',     '0.75',     '0.75',     '0.5');

-- Test Colors
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_BLACK',           '0',        '0',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_MAROON',          '0.5',      '0',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_GREEN',           '0',        '0.5',      '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_OLIVE',           '0.5',      '0.5',      '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_NAVY',            '0',        '0',        '0.5',      '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_PURPLE',          '0.5',      '0',        '0.5',      '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_TEAL',            '0',        '0.5',      '0.5',      '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_SILVER',          '0.75',     '0.75',     '0.75',     '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_GREY',            '0.5',      '0.5',      '0.5',      '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_RED',             '1',        '0',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_LIME',            '0',        '1',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_YELLOW',          '1',        '1',        '0',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_BLUE',            '0',        '0',        '1',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_MAGENTA',         '1',        '0',        '1',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_AQUA',            '0',        '1',        '1',        '0.5');
INSERT INTO Colors      (   Type,                               Red,        Green,      Blue,       Alpha)
VALUES                  (   'COLOR_MORELENSES_WHITE',           '1',        '1',        '1',        '0.5');
