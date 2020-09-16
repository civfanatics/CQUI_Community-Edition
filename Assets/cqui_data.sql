-- CQUI
-- Author: Infixo
-- Created: 2020-09-11


-- Add missing descriptions for boost-related goody huts
UPDATE GoodyHutSubTypes SET Description = "LOC_GOODYHUT_CIVIC_BOOST_DESCRIPTION" WHERE SubTypeGoodyHut = "GOODYHUT_ONE_CIVIC_BOOST";
UPDATE GoodyHutSubTypes SET Description = "LOC_GOODYHUT_CIVIC_BOOST_DESCRIPTION" WHERE SubTypeGoodyHut = "GOODYHUT_TWO_CIVIC_BOOSTS";
UPDATE GoodyHutSubTypes SET Description = "LOC_GOODYHUT_TECH_BOOST_DESCRIPTION"  WHERE SubTypeGoodyHut = "GOODYHUT_ONE_TECH_BOOST";
UPDATE GoodyHutSubTypes SET Description = "LOC_GOODYHUT_TECH_BOOST_DESCRIPTION"  WHERE SubTypeGoodyHut = "GOODYHUT_TWO_TECH_BOOSTS";
