# Contributing

You want to contribute to the mod? New contributors and their pull requests are always welcome!
Some issues are labeled "easy" it should be a great entry point if you want to join the team. 
A comprehensive contribution guide created for the predecessor of this mod is a good starting point.

## Quick coding style
* Please use 4 spaces for indentation. Do NOT use tabs.
* Follow whatever style is currently present in the file you are editing, do not reformat it, as it is difficult to discern those changes from the other changes made to a file.
You can configure your IDE/editor to auto-format **your new files** only. 
* When modifying existing game files, prefix newly added functions, events, and members with "CQUI_"
* There should be NO hardcoded strings in CQUI
* These are guidelines and not laws. A PR should be still accepted if the styling is a bit off. We need to be realistic about the volunteering nature of this project and the limited amount of time we ca expect from contributors. **We value progress over perfection.**

## Quick git guideline
* A pull request summary line should have a meaningful description of the changes.
* When your commit includes a bugfix or implements a feature that's tracked on the issue tracker, 
include the phrase "Fixes #X" or "Resolves #X", where X is the tracker number of the issue or feature. This will notify everyone participating in the issue of your change when you push it to your fork, as well as automatically close the issue when the change is merged into the main repo.

## Steam Workshop Update Process
Steam Workshop limits those that can upload an item to the workshop.  This version of the upload was created by @the_m4a.

To upload the mod, use the Steam Workshop Uploader utility.  If you have not previously uploaded this mod, click on the Upload button and navigate to the .modinfo file.
The Workshop Uploader will then run a series of checks, if you see all green bars, then you can proceed to next page.
**Note:** If the uploader crashes, ensure your .modinfo file is a valid XML (use an XML validation website, for example)!  The game may successfully load your mod, even if the file is invalid XML.

**Additional Details Page**
- The Photo description for the Workshop item is contained in the WorkshopArtifacts folder, as TitleGraphic.png.
- The description text should be kept very simple here, as it does not appear to allow cutting and pasting of lengthy text.
  - The description can be updated once the upload is completed.
- Click the "Gameplay", "UI", "Base Game", "Rise and Fall", and "Gathering Storm" checkboxes.
- Click Upload
  - The Uploader may appear to get stuck at "Committing Changes".  If this is the case, check and see that the mod uploaded, it may have completed.

**Once the Mod is Uploaded**
- Update the description text by pasting in the text found in the file checked into this repo, WorkshopArtifacts\DescriptionFormatted.txt.
  - The text file is formatted in the manner expected by Steam for their description page.
  - Additional information about formatting of this file can be found at the following (the second link shows additional information not found on the Steam formattinghelp page):
    - https://steamcommunity.com/comment/Recommendation/formattinghelp
    - https://steamcommunity.com/sharedfiles/filedetails/?id=1245720477
