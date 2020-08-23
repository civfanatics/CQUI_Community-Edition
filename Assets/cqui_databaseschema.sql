/*
    Created by LordYanaek for CQUI mod by chaorace.
    This file contains queries used to create the mod's tables in the database.
    Don't touch this unless you know what you do.
*/

CREATE TABLE 'CQUI_Bindings' (
    'Action' TEXT NOT NULL,
    'Keys' TEXT NOT NULL,
    'ActionDesc' TEXT NOT NULL,
    PRIMARY KEY('Action')
);

CREATE TABLE 'CQUI_Settings' (
    'Setting' TEXT NOT NULL,
    'Value' INTEGER NOT NULL,
    PRIMARY KEY('Setting')
);
