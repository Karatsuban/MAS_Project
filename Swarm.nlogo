extensions [xw]  ;; uses : https://github.com/CRESS-Surrey/eXtraWidgets
; WARNING : this extension does not work with the most recent update of NetLogo. Please use the version 6.1.1 to run this code.

breed [bots bot]
globals [is_file_open nb_bots old_x_cor old_y_cor PATCH_WIDTH PATCH_HEIGHT do_map_draw]
bots-own [state xGoal yGoal dist neighbor_stuck has_goal in_shape stuck_has_moved]
; State : stopped, moving, lost, stuck
; has_goal : true if the bot has one
; xGoal : x coordinate of the goal
; yGoal : y coordinate of the goal
; dist : distance to the closest empty spot
; neighbor_stuck : true when a neighbor4 is trying to make the bot move, else false
; in_shape : true if the bot is on an in_shape patch
; stuck_has_moved : if it was stuck and now it has moved on a free spot

patches-own [pin_shape pis_empty]
; pin_shape : boolean stating if the patch is part of the shape
; pis_empty : boolean stating if the patch is empty (true) or not (false)


; UTILITY FUNCTIONS

to open_close [ filename ]
  ; open or close the file in parameter
  ifelse is_file_open != true
  [file-open filename set is_file_open true]
  [file-close set is_file_open false]
end


to-report get_maps_name
  ; returns a list of all the available maps found in the file "maplist.txt"
  let list_of_maps []
  open_close("maplist.txt")
  while [not file-at-end?]
  [
    set list_of_maps lput file-read-line list_of_maps  ; read a new line and save the map name
  ]
  open_close("maplist.txt")
  report list_of_maps
end

to startup
  ; setup the simulation : creates the buttons, sets the size of the world
  set PATCH_WIDTH 33
  set PATCH_HEIGHT 33
  resize-world 0 (PATCH_WIDTH - 1) (1 - PATCH_HEIGHT) 0

  if do_map_draw = 0 [set do_map_draw true]


  set is_file_open false  ; no file has been opened yet

  let list_of_maps get_maps_name  ; get all the names of the maps

  xw:clear-all  ; delete all existing tabs and widgets
  ; new tab
  xw:create-tab "t1" [
    xw:set-title "Load Maps"
  ]

  ; new note
  xw:create-note "note_load_map" [
    xw:set-text "Load a Map"
    xw:set-font-size 15
  ]

  ; new (dynamic) chooser
  xw:create-chooser "chooser_filename_list" [
    xw:set-label "Select a file"
    xw:set-items list_of_maps  ; populate it with the map names
    xw:set-y [ xw:y + xw:height + 10 ] xw:of "note_load_map"
  ]

  ; new button
  xw:create-button "button_load" [
    xw:set-label "Load this map"
    xw:set-commands "setup"  ; will launch the setup function
    xw:set-y [ xw:y + xw:height + 10 ] xw:of "chooser_filename_list"
  ]

  setup
end


to load_save_map
  xw:select-tab 2 ; will take the user to the seconde tab
end


to draw_map
  ; draw the selected map

  let filename xw:get "chooser_filename_list"  ; get the name of the map selected

  let x 0
  let y 0
  let cmpt -1
  set nb_bots 0

  open_close( filename )  ; open the file to read from there

  while [not file-at-end?]  ; read the entire file
  [
    set cmpt cmpt + 1
    set x (cmpt mod PATCH_WIDTH )
    set y (0 - floor (cmpt / PATCH_HEIGHT))

    ifelse file-read = 0
    ; colors the patches and update the number of bots to create
    [ask patch x y [set pcolor red set pin_shape false (set pis_empty true) ]]
    [ask patch x y [set pcolor blue set pin_shape true (set pis_empty true) ] (set nb_bots nb_bots + 1)]
  ]
  open_close( filename )  ; close the file after the read
  xw:select-tab 1  ; go back to the interface
end


to save_new_map
  ; saves the map created/modified by the user under the name choosen
  let name (user-input "File name (no extension) ?")
  set name insert-item (length name) name ".botmap"  ; add the extension ".botmap"
  open_close(name) ; create the file by opening it
  let x 0
  let y 0
  let cmpt -1
  print name
  while [cmpt < PATCH_WIDTH * PATCH_HEIGHT - 1 ]
  [
    set cmpt cmpt + 1
    set x (cmpt mod PATCH_WIDTH )
    set y 0 - (floor (cmpt / PATCH_HEIGHT))
    ask patch x y
    [
      ifelse pcolor = red
      [
        file-write 0
      ]
      [
        file-write 1
      ]
    ]
    if x = PATCH_WIDTH - 1
    [
      file-print ""
    ]
  ]
  open_close(name) ; close the map file

  ; save the name of the new map in maplist.exe
  open_close("maplist.txt")
  file-print(name)
  open_close("maplist.txt")
  set do_map_draw false
  startup  ; update the chooser to display the new option
end


to mouse_draw_map
  ; change the color of the patch the mouse cursor is clicking on
  ifelse mouse-down?
  [
     if round( mouse-xcor ) != old_x_cor or round( mouse-ycor ) != old_y_cor
     [
       ask patch round( mouse-xcor ) round( mouse-ycor ) [
        ifelse pcolor = red
          [ set pcolor blue set pin_shape true set nb_bots (nb_bots + 1) ]
          [ set pcolor red  set pin_shape false set nb_bots (nb_bots - 1)]
      ]
       set old_x_cor round( mouse-xcor )
       set old_y_cor round( mouse-ycor )
     ]
  ]
  [
    set old_x_cor false
    set old_y_cor false
  ]
end


; BOTS FUNCTIONS


to setup
  ; create the bots

  if is_file_open [
    user-message ("The map is not finished loading !")
    stop
  ]

  clear-ticks
  clear-turtles
  clear-drawing
  clear-all-plots
  clear-output
  reset-ticks

  if do_map_draw [ draw_map ]
  populate
  place
  set do_map_draw true
end


to populate
  ; creates and places the bots on the map
  clear-turtles ; clear the bots
  create-bots nb_bots ; create the bots
  ask bots [
    set state "moving"
    set color black
    set heading 0
    set dist -1
    set has_goal false
    set neighbor_stuck false
    set in_shape [pin_shape] of patch-here
    set stuck_has_moved true
  ]
  place

end


to place  ; puts the bots in place for the beginning of the simulation
  if nb_bots = 0 [stop]
  let width ceiling sqrt nb_bots
  let height ceiling ( nb_bots / width )

  ask turtles [
    let x (PATCH_WIDTH - 1 - ( ( who mod width ) ))
    let y ( 0 - PATCH_HEIGHT + 1 + ( int ( who  / width ) ))

    setxy x y
    ask patch-here [ set pis_empty false] ; the patch is occupied
  ]

end



; debug function to create as much bots as we want
to put_bots
  clear-turtles
  set nb_bots read-from-string (user-input "Nb robots ?")
  type nb_bots print " bots created"
  create-bots nb_bots ; create as much bots as there are patches counted when loading the map
  ask bots [
    set color black
    fd 5
    set has_goal false
    set stuck_has_moved true
  ]
end




to go

  ask turtles
  [


    let is_stopped false ; false until on an empty_in_shape patch
    let nb_empty 0  ; nb spots ONLY empty
    let nb_empty_in_shape 0  ; nb spots EMPTY and IN SHAPE
    let nb_bots_around 0 ; nb of bots in the neighbors
    let nb_in_shape 0 ;



    ; MOVING ACTIONS ######################################"

    ; MOVING ACTIONS (if possible)
    let can_move false
    let xAmount 0
    let yAmount 0
    let has_moved false

    if has_goal [
      if abs int (xcor - xGoal) != 0 [ set xAmount int (( xGoal - xcor) / abs ( xGoal - xcor )) ]
      if abs int (ycor - yGoal) != 0 [ set yAmount int (( yGoal - ycor) / abs ( yGoal - ycor )) ]

      ; no diagonal allowed ! Priority to the left-right movement
      if xAmount != 0 [
        let asked_patch patch (xcor + xAmount) ycor
        if asked_patch != nobody[
          ask asked_patch [if pis_empty [ set can_move true ]]
        ]

        if can_move [
          ask patch-here [set pis_empty true]  ; free the patch we are leaving
          set xcor xcor + xAmount
          set has_moved true
          ask patch-here [set pis_empty false] ; occupy the patch we are moving on
        ]
      ]

      ; then the up-down movement
      if yAmount != 0 and has_moved = false [

        let asked_patch patch xcor (ycor + yAmount)
        if asked_patch != nobody[
          ask asked_patch [if pis_empty [ set can_move true ]]
        ]

        if can_move [
          ask patch-here [set pis_empty true]  ; free the patch we are leaving
          set ycor ycor + yAmount
          set has_moved true
          ask patch-here [set pis_empty false] ; occupy the patch we are moving on
        ]
      ]

      set in_shape [pin_shape] of patch-here ; update in_shape attribute
      if in_shape [ set state "stopped"]

      if has_moved[
        if state = "stuck" [set stuck_has_moved true] ; the "stuck" bot has moved
      ]

      if (xcor = xgoal and ycor = ygoal) [
        set has_goal false ; the bot has reached its goal
      ]
    ]


    ; CHANGE ITS STATE #################################################

    ; check if STOPPED
    if neighbor_stuck = True ; don't go back to stopped unless we have moved
    [
      ask patch-here [ if pin_shape [set is_stopped true]]  ; if bot in the shape
      if is_stopped [
        set state "stopped"
        set in_shape true
        set has_goal false ; the stopped bot has no goal
      ]  ; it is stopped
    ]

    ; check if LOST
    if state != "stopped" [
      set nb_bots_around count (turtles-on neighbors)
      set nb_in_shape count neighbors with [pin_shape = true]
      ifelse nb_bots_around = 0 and nb_empty_in_shape = 0 [  ; if no neighbors and no in_shape patch around, enter the stuck state
        set state "lost"
      ][
        set state "moving"
      ]
    ]

    ; check if STUCK
    ; count the empty spot around
    if state != "stopped"[
      set nb_empty count neighbors4 with [pis_empty = true]
      if nb_empty = 0 [
        set state "stuck"
        set has_goal false ; the bot is stuck and has no goal for now
      ]  ; if no empty spot around, enter the stuck state
    ]




    ; ACTION OF THE STATES ##############################

    ; the bot is MOVING
    if state = "moving" [

      let is_in_shape false
      let is_turtle_around false

      let x 0 let y 0
      let min_x 0 let min_y 0  ; coordinates of the min and max of gradient around
      let max_x 0 let max_y 0


      ; HAVING AN EMPTY IN-SHAPE SPOT IN THE NEIGHBORHOOD has priority over any goal
      ; 1st STEP : DETECT IF THERE IS AN EMPTY PATCH AROUND WHO IS IN THE SHAPE (count them)
      let selection neighbors with [pis_empty = true and pin_shape = true]
      set nb_empty_in_shape count selection


      ; 2nd STEP : IF THERE IS AN EMPTY-IN-SHAPE SPOT AROUND, set the goal on it
      if nb_empty_in_shape > 0 [
        ask one-of selection [set x pxcor set y pycor]
        set xgoal x set ygoal y  ; get the coordinates ;
        set has_goal true ; THE BOT HAS NOW A GOAL
        ;type who print " wants to move because there is an EMPTY_IN_SHAPE spot around !"
      ]


      if not has_goal
      [
        ; if we have not goal, we will try to follow the gradient of "dist" values
        ; 3rd STEP : IF THERE IS NONE, FOLLOW THE GRADIENT
        ; HOW DO WE FOLLOW THE GRADIENT :
        ; ASK all NEIGHBORS(8) AROUND FOR THEIR DISTANCE
        ; MOVE IN THE DIRECTION OF THE DESCENDING GRADIENT

        ; set the coords of the max and the min dist of turtles around
        if any? (turtles-on neighbors) with [dist != -1 and (state = "stopped" or state = "moving")] [


          ask min-one-of (turtles-on neighbors) with [dist != -1] [dist] [
            ;type who print " has min_gradient"
            set min_x xcor
            set min_y ycor
          ]


          set xgoal min_x ; get the direction to follow
          set ygoal min_y


          set has_goal true ; THE BOT NOW HAS A GOAL
          ;type who type " wants to move to " type xgoal type " " type ygoal type " because it is following the GRADIENT !"
        ]
      ]
    ]


    ; the bot is STOPPED
    if state = "stopped" [

      set has_goal false ; once stopped, a bot has no more goal (except when contacted by another bot)
      ;type who print " is stopped"

      if neighbor_stuck [ ; a neighbour is stuck and ask it to move
        set state "stuck" ; enter the stuck state itself
      ]
    ]


    ; STUCK procedure
    if state = "stuck" [
      set nb_empty 0
      ; type who type " is stuck !"

      if stuck_has_moved [ set neighbor_stuck false set color black] ; it has moved, it can forget being stuck

      ifelse dist = 1[
        let asked one-of neighbors4 with [pis_empty = true and pin_shape = true]
        if asked != nobody [
          set xgoal [pxcor] of asked
          set ygoal [pycor] of asked
          set has_goal true
        ]
      ]
      [

        ; if the turtles around know the way to an empty in-shape spot
        if count (turtles-on neighbors4) with [ dist != -1] > 0 [
          let min_around min [dist] of (turtles-on neighbors4) with [ dist != -1]  ; find the min dist
          let this_neighbor one-of (turtles-on neighbors4) with [dist = min_around]  ; ask one of the neighbor with this dist
          ask this_neighbor [ set neighbor_stuck true set color white]
          set xGoal [xcor] of this_neighbor ; put the goal on his spot
          set yGoal [ycor] of this_neighbor
          ;type "xgoal = " type xgoal type " ygoal = " print ygoal
        ]
      ]


    ]



    ; LOST state
    if state = "lost" [
      ; move right or left until it encounters the limit of the simulation of another robot
      set xgoal xcor + ((random 2 * 2) - 1)
      set ygoal ycor + ((random 2 * 2) - 1)
    ]





    ; SET THE DIST ###############################

    ; WHEN IT HAS done all the actions of the state it was in, the bot sets its own "dist"
    set dist -1 ; by default, all turtles have -1 dist

    let min_bots -1
    let min_patches -1
    let list_min []

    if count (turtles-on neighbors) with [dist != -1] != 0[ ; bots with -1 dist unaccounted
      let list_dist []
      ask (turtles-on neighbors) with [dist != -1] [ set list_dist lput (ceiling (distance myself) + dist) list_dist ]

      ; get the list of dist from all neighbors8 with dist != -1
      ; get the list of ceiling(distances) from my turtle to the neighbors8
      ; add the two lists element by element
      ; find the min of the list, this is the min dist provided by the neighbors
      set min_bots min list_dist
    ]

    if count neighbors with [pis_empty = true and pin_shape = true] != 0[
      let list_dist []
      ask neighbors with [pis_empty = true and pin_shape = true] [set list_dist lput (ceiling distance myself) list_dist]
      set min_patches min list_dist
    ]

    ; calculate a new value in function of the patch, the same way and compares it with the previous min

    set list_min (list min_bots min_patches)
    set list_min remove -1 list_min
    if length list_min != 0[
      set dist min list_min
    ]

  ]

  if count turtles with [state = "stopped"] = nb_bots [stop]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
20
25
457
463
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
32
-32
0
0
0
1
ticks
30.0

BUTTON
535
90
597
123
Reset
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
515
265
645
298
Draw a new map
mouse_draw_map
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
515
310
647
343
Save the new map
save_new_map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
515
355
645
388
Load Map
load_save_map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
535
140
597
173
GO !
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
515
400
645
433
Populate
populate
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
520
221
670
246
Map actions :
20
0.0
1

TEXTBOX
485
45
675
91
Simulation actions :
20
0.0
1

TEXTBOX
735
250
885
316
After drawin a new map without saving it, click on \"Populate\" to create and place the bots.\n
11
0.0
1

TEXTBOX
655
150
805
168
Launch the simulation
11
0.0
1

TEXTBOX
735
355
885
381
Load a map from all the map saved
11
0.0
1

TEXTBOX
665
90
815
116
Redraw the interface and the bots
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
