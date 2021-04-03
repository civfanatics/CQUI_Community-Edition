# Community Quick User Interface (CQUI)
> CQUI is an open source Civilization 6 mod that is maintained by its community.

CQUI is a UI mod that replaces parts of the original Civ 6 UI, with the intention of letting you manage your empire with fewer mouse clicks.

This repository is the official repository of the [CQUI steam mod](http://steamcommunity.com/sharedfiles/filedetails/?id=2115302648).

![CQUIReadmeScreen](https://user-images.githubusercontent.com/8787640/89616678-a6b97c80-d83d-11ea-8822-06e005c4ce8e.png)

## Installation

### Steam Workshop
If you want to install the latest official version, you can go to the [steam workshop page](http://steamcommunity.com/sharedfiles/filedetails/?id=2115302648) of CQUI and add it to your game.

### Manually
If you want to have the cutting edge version (that might be not in steam workshop yet), you can download this repository and place the cqui folder into your mod folder : 

```
Windows : Documents\my games\Sid Meier's Civilization VI\Mods
Mac : /Users/[user]/Library/Application Support/Sid Meier's Civilization VI/Mods
Linux : ~/.local/share/aspyr-media/Sid Meier's Civilization VI/Mods
```

### Customizing Settings
See CQUI_Settings_Local section later in this document.

## Key Features

- Civ V Style Cityview _- [image](https://camo.githubusercontent.com/e39306c882c0f9b95494ea391cee0baa838d3072/687474703a2f2f692e696d6775722e636f6d2f583571427a6a612e6a7067)_
  - Produce or buy units with gold and faith from a single production panel
  - Production panel elements compressed and reordered
  - Improved amenities city details screen (clean icons) _- [image](https://i.imgur.com/UA1NrR5.png)_
  - Growth/Production progress is enumerated in the city panel
- "Smart" City Banners that show useful info in the banner and in tooltips _- [image](https://i.imgur.com/Xdt33Nw.gif)_
  - Icons showing districts built and if more are available to be built
  - Housing, turns until population growth, turns until culture growth displayed in banners _- [image](http://i.imgur.com/8CUJSB6.png)_
  - City State banners show Suzerain icon (Configurable: Civ Symbol or Leaderhead)
  - City State banners display an icon when at war with you
- Additional Tooltips to quickly find information:
  - Tooltip on City Banner showing districts built, districts available, housing, turns until growth
  - Tooltip on Unit upgrade includes maintenance costs (current and upgraded unit)
  - Tooltip in City State list shows all envoys sent from all Civs
  - Tooltip on Plot shows additional information, such as Tourism generated
- Improvements for Units
  - Builders, Engineers, and Religious units show the remaining number of charges on the Unit flag
  - Non-religious unit flags are dimmed when Religion lens applied (with option to hide completely)
  - Unit actions are no longer hidden behind an expand button _- [image](http://i.imgur.com/x1xZtyY.png)_
  - Unit XP bars are twice as tall _- [image](http://i.imgur.com/TeWR0VA.png)_
  - Unit flags show a "+" icon when able to be promoted
  - Hero units have a brighter glow    
- Great Person panel revamped _- [image](https://user-images.githubusercontent.com/8012430/31862025-75a4cb88-b737-11e7-9b0f-57129f114f59.jpg)_
  - Reduced or eliminate side scrolling
  - Adapts to the screen height
  - Heroes entries are twice as wide for better readability
- Policy Reminder Popup _- [image](https://user-images.githubusercontent.com/8012430/31861779-17cd1758-b733-11e7-8b16-b4422999c8af.png)_
  - If new policies are available, a popup reminds you to check them out
- City State Panel shows additional information
  - Envoy list also shows 2nd place Suzerain and tooltip lists all Envoys sent to that City State
  - City State quests are shown in-line with a resizable font
- "My Government" tab removed from Government panel _- [image](http://i.imgur.com/168ThOx.jpg)_
- Leaderheads expanded tooltips _- [image](https://user-images.githubusercontent.com/8012430/31861835-17537960-b734-11e7-8ae4-08e7e3f19cc4.png)_
- Map Pinning system enhanced _- [image](http://i.imgur.com/M11tac6.png)_
  - New pins
  - Long pinlists are now scrollable
  - Shift-Right click to quickly delete pins
  - Enter key now bound to finalizing a pin in pin creation menu
- Tech/Civic Tree and Civilopedia now autofocus the search bar
- Civic/Tech popups can be disabled
  - Civic/Tech voice-overs can be set to only play manually
- Recommendation UI can be enabled/disabled
- Citizen management icons are overhauled to make seeing yield info easier _-[ image](http://i.imgur.com/gbA4z3s.png)_
- Growth/Production progress is enumerated in the city panel _- [image](http://i.imgur.com/3kYsEIf.png)_
- Improved resource icons are dimmed to emphasize unutilized resources _- [image](http://i.imgur.com/m32xtQr.png)_
- Available customized key bindings
- Luxury resources are displayed in the top bar alongside strategic resources _-[ image](http://i.imgur.com/ebYO8l4.png)_
- Right clicking the action panel (bottom right button) instantly ends turn even when things like production/research/unit moves have not been decided
- Dedicated mod settings menu _- [image](https://user-images.githubusercontent.com/8787640/89606291-67cafd00-d824-11ea-91b2-25b1fdab39d6.png)_

## Integrations

Below are a list of mods that have been integrated into CQUI.  **You do not have to download these mods separately.**  Downloading and using these mods at the same time as CQUI may cause those mods or CQUI to not function correctly.

### Improved Deal Screen
Mod originally by mironos (on the Steam Workshop), now incorporated into and maintained as part of CQUI.  A totally revamped diplomatic deals screen, with an improved and expanded layout, easier to read and navigate offer area, color-coded icons, and more in-depth information.

![improveddealscreen](https://user-images.githubusercontent.com/8787640/89608067-e6299e00-d828-11ea-8b13-c46943717751.png)

- All resources a civilization has access to are now listed, including those acquired via trade with other civs and those imported from city states, to avoid trading for resources you already have
- Resource icons have been color-coded and custom sorted
  - Resources you have direct access to are sorted by decreasing quantity
  - Resources you only have 1 of are considered scarce, and are given a red font
  - Resources that both you and your trading partner already have are color-coded with a tan button
  - Resources that you own but that can't be traded (typically, those that are imported from elsewhere) are listed for reference, but cannot be selected
- Cities are now sorted alphabetically
- City details are displayed right on the city buttons for easy reference
- Additional city information has been added the city tooltips _- [image](https://user-images.githubusercontent.com/8787640/89608240-74058900-d829-11ea-82d9-36797f04068c.png)_
- When negotiating peace treaties, currently occupied cities are highlighted and sorted to the top
- Great works buttons include a 'type' icon
- All great works with a creator now display that creator
- Artifacts include civ leader names so you can tell at a glance what nation or city state the artifact originated from, as well as the artifact's era.

### Better Trade Screen
Mod by [astog](https://github.com/astog), the stand-alone version can be found [on github](https://github.com/astog/BTS). The goal of this mod is to improve the trade screens in Civilization VI and help manage and monitor running trade routes.

![](http://i.imgur.com/8DXfZx3.png)

- Shows turns to complete a trade route rather than the distance between the cities
- Overhauled Trade Overview screen _- [image](http://i.imgur.com/0IMseO1.png)_
  - Shows all possible routes, even if the trader is not present in the origin city
  - Clicking on a route where a free trade unit is not present in the origin city takes you to a free trade unit and opens the Change City screen
  - Route entry is colored based on destination player
  - Player/City header are also colored
  - Shows origin city and destination city yields in the same screen
  - Added Group and Filter settings
  - My Routes tab tracks active routes, so you know when a trade route completes
- Sort bar in Make Trade Route screen and Trade Overview screen. Sort the routes by left clicking on a button _- [image](http://i.imgur.com/F7ZRUi7.png)_
- Trade Routes can be sorted based on yields, and turns remaining. Queue multiple sorts by holding SHIFT and the left clicking on a sort button. Right click on any sort button to remove it from the sort setting
- When opening Make Trade Route screen, the last destination is automatically picked
- Set a trader to repeat its last route by selecting the Repeat Route checkbox when initiating a trade route
- An additional checkbox is provided that sets the trader to repeat the top route from the sort settings when the trade was initiated. This allows the trade route to always be the best one, hence reducing micromanagement of always checking the trade routes
- Cancel the automated trader from the My Routes tab in Trade Overview screen

### More Lenses
Mod by [astog](https://github.com/astog), the stand-alone version can be found [on github](https://github.com/astog/MoreLenses). The goal of this mod is to add more lenses to the game, that help with empire management and in general quality of life improvements.

![morelenses](https://user-images.githubusercontent.com/8012430/31861684-d04142de-b731-11e7-97c7-6e8359d47f96.jpg)

- Add a Builder Lens to highlight unimproved resources, hills and removable features. This lens auto applies when a builder is selected (can be toggled in the settings)
- Add an Archaeologist Lens to highlight artifacts and shipwrecks.
- Add a City Overlap 6 or 9 to show how many cities a particular hex overlaps with
- Add a Barbarian Lens to highlight barbarian encampments on the map
- Add a Resource Lens to highlight resources on the map based on their category (Bonus vs Strategic vs Luxury) and if they are connected or not
- Add a Wonder Lens to highlights natural and player made wonders
- Add an Adjacency Yield Lens to show the various adjacency bonuses in a gradient, allowing you to relish in your pristine city planning skills
- Add a Scout Lens to highlight goody huts on the map. Automatically applies when a scout/ranger is selected (can be toggled in the settings)

### Better Espionage Screen
Mod by [astog](https://github.com/astog), the stand-alone version can be found [on github](https://github.com/astog/BES). The Espionage Screens are overhauled to reduce the number of clicks and find the right information quickly.

![](https://camo.githubusercontent.com/763167a1fb61481c0e9a60888d30687f51c3e919/687474703a2f2f692e696d6775722e636f6d2f705435617352652e6a7067)

- District Filter Options
  - Allows you to filter the cities based on their districts
  - You can also filter based on civilizations
- Mission list is shown as a side screen, rather than replacing the destination list

### Divine Yuri's Custom City Panel
Mod by [Divine Yuri](https://forums.civfanatics.com/members/divine-yuri.263736/), the stand-alone version can be found [on civfanatics](https://forums.civfanatics.com/resources/divine-yuris-custom-city-panel.25430/). The mod adds additional tooltips to the city panel.

![Amenities tooltip](http://i.imgur.com/qHjdmUG.png)

- Hover over the new "Districts" bar show the built districts in the city, and the buildings in each district. As well as telling you when a building or district is pillaged _- [image](http://i.imgur.com/DqwAySq.png)_
- The tool tip for the religions bar shows how many citizens follow each religion, your pantheon belief, and benefits of the dominant religion in the city _- [image](http://i.imgur.com/Vo8ZVGr.png)_
- The tool tip for the Amenities bar shows the current mood of the city the benefit/hindrance of that mood, and the breakdown of what's causing the lost/gains of Amenities
- Hovering over Housing will give the current food modifier from housing _- [image](http://i.imgur.com/h5R3Dhh.png)_
- Added food lost from population, and modifiers to the food tool tip _- [image](http://i.imgur.com/ZGwznFv.png)_
- The production bar on the city panel has been changed to show total production on the right side of the bar
- The Growth bar has been shortened to make room
- Added a Expansion Bar which will show how long until the city expands it's boarders
- Expansion Bar that show total Food and Culture
- Added tooltips to the Growth Bar
- Added info to current production in the form of a tooltip in the same way a tooltip would be displayed in the production panel
- Right clicking the current production icon will links to the civilopedia of what ever is being produced

### Simplified Gossip
Mod by FinalFreak16, from the [steam workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=1126451168). This mod simplifies the gossip history log in the leader diplomacy view.

![gossip](https://user-images.githubusercontent.com/8012430/31861664-7fe2bf8e-b731-11e7-9eae-2ea138b53007.jpg)

- Each message has its own icon to categorize each entry and make it easier to see what happened at a glance

## Maintaining CQUI Settings in New Games using CQUI_Settings_Local.sql
CQUI will maintain your configured settings for every saved game without issue, however, Firaxis has not made maintaining configured settings easy to do when creating a new game.  The CQUI_Settings_Local.sql file can be used to maintain these settings.

CQUI_Settings_Local.sql is a copy of the CQUI_Settings.sql file found in the mod's root folder.  CQUI_Settings.sql contains all of the _default_ settings for CQUI, the settings that are applied at the start of every new game if CQUI_Settings_Local.sql is not in place.

CQUI_Settings_Local.sql loads after CQUI_Settings.sql, meaning it will replace/update any of those default values to the value you prefer.

The version of CQUI_Settings_Local.sql packaged with this mod has all of the lines "commented" out, meaning that Civ VI will not load that setting.  Remove the double-minus sign ( -- ) from the beginning of a line to "uncomment" it, and save the SQL file.

**NOTE:** When subscribing to the CQUI mod on the Steam Workshop, the copy of CQUI_Settings_Local.sql located in the mod's root directory [SteamFolder]/SteamApps/Workshop/Content/289070/2115302648 is overwritten every time a new update for CQUI is pushed to the Steam Workshop.  **Save a copy of this file elsewhere on your machine so you can restore settings whenever the Workshop version is updated.**

### New (August 2020): CQUI_Settings_Local.sql located in Mod's _Parent_ Folder
It was discovered recently that files in the mod's _parent_ folder can ben referenced, and those files are _not_ updated when new versions are pushed to the Steam Workshop.  With that in mind, CQUI will now also look for CQUI_Settings_Local.sql in the _parent folder of where CQUI.modinfo is located_.

#### Example: CQUI From Steam Workshop Subscription
Place CQUI_Settings_Local.sql in the [SteamFolder]/SteamApps/Workshop/Content/289070 folder

![image](https://user-images.githubusercontent.com/8787640/89610046-6dc5db80-d82e-11ea-87f5-a8f440d81a1f.png)

#### Example: CQUI Downloaded and Placed in Civ VI Mods Folder
Place CQUI_Settings_Local.sql in the "Mods" folder:

![image](https://user-images.githubusercontent.com/8787640/89610526-94384680-d82f-11ea-83a9-4d55540f2055.png)


## Credits
@Vans163 for his original QUI mod, @Chaorace for the Chao's QUI, @alexeyOnGitHub, @alimulhuda, @the-m4a, @Infixo, @Sparrow, @astog, Aristos/@ricanuck, @JHCD, Greg Miller, Ace, Divine Yuri, @ZhouYzzz, @deggesim, @e1ectron, @sejbr, @frytom, @maxap, @lctrs, @wbqd, @jacks0nX, @RatchetJ, @Frozen-In-Ice, @zgavin, @olegbl, @Proustldee, @kblease, @bolbass, @SpaceOgre, @OfekA, @zeyangl, @Remolten, @bestekov, @cpinter, @paavohuhtala, @perseghini, @benjaminjackman, @velit, @MarkusKV, @apskim, @8h42

Firaxis for eventually delivering mod tools and steam workshop. 

The lovely folks over at Civfanatics for their guides, knowledge, tools, and resources. 

The even lovelier folks contributing on GitHub and over at /r/civ for their input and testing. 

The, arguably, lovely folks back at the Steam Workshop :p
