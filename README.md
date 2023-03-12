# Multi-Agent System Project : shape-filling robot swarm
The code and utilities for my MAS project

## What you need to know before using the code

The code has been written and tested with version 6.1.1 of the Netlogo software. For
compatibility reasons, you should run in on the same version.  
Furthermore, the code uses the extension eXtraWidgets available here
https://github.com/CRESS-Surrey/eXtraWidgets. This extension does NOT work with recent
versions of the Netlogo software but does work with the 6.1.1 version.

## The files

### Maplist.txt

It contains a list of all the names of the saved map.

### Files with the .BOTMAP extension

Files containing each one a map represented by 0s and 1s. A 0 indicates that this cell is not in
the shape, a 1 indicates that it is. If you wish to delete one of the BOTMAP files, please also
delete its entry in the “maplist.txt” file.

### Swarm.nlogo

Contains all the code to run the simulation. This file must be open with the Netlogo software
version 6.1.1.

## How to use the code

First open the file Swarm.nlogo with version 6.1.1 of Netlogo.  
You will be met with the interface.  

On the left, there is a grid of 33x33 cells. A blue cell means that this cell is in the shape and a red one that it is not. The bots are the arrows on the bottom of the right-hand side of the grid. They are white when they are stuck, black the rest of the time.  
On the right, there are buttons separated into two parts: the Simulation actions and the Map
actions.  

Among the Simulation actions, there are five of them:

+ Reset: this button allows the user to reload the map and redraw the bots at their
original places
+ Go: this button can be toggled to pause or un-pause the simulation. This button is also
bound with the Space bar of the keyboard.
Among the Map actions, there are:
+ Draw a new map: allows the user to draw on the map when holding down the left
button of the mouse and moving the cursor on the interface. Click again on the button
when the drawing is over. Please note that the cursor will invert the color of the cell it is
entering. Please also note that to draw on an empty map, the user must first load the
empty map.
+ Save the new map: allows the user to save the map they just created by asking them for
a filename (without any extension)
+ Load Map: pressing on this button will lead the user to the “Load Maps” menu. There,
the user will be able to choose a map from a scrolling list and pressing the “Load this
map” button to effectively load the requested map. Please note that the user will find
the name of the map they created themselves in that list.
• Populate: this button must be pressed when the user has finished drawing a map and
wants to create the bots.
