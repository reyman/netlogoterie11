extensions [ gis ]

;-----------------------------------------------------------------------

; element = turtle representant un batiment, une enceinte ou un ilot
breed [ elements element ]

breed [ sommets sommet ]
undirected-link-breed [ aretes arete ]

elements-own
[ nom-type             ; batiment, enceinte ou ilot
  vector-data
  ensemble-sommets 
  ensemble-aretes ]

sommets-own
[ proprietaire ]

;-----------------------------------------------------------------------

globals
[ liste-noms-fichiers-donnees
  liste-donnees-brutes
  hauteur-donnees
  largeur-donnees ]

;-----------------------------------------------------------------------

to chargement-donnees
  ca
  no-display
  
  ;---------------------------------------------------------------------
  ; chargement des donnees en memoire +
  ; transformation "referentiel GIS vers referentiel NetLogo"
  
  ifelse taille-data = "grande"
  [ set liste-noms-fichiers-donnees [ "./data/batiments.shp" "./data/enceintes.shp" "./data/ilots.shp" ] ]
  [ set liste-noms-fichiers-donnees [ "./data/batiments_petit.shp" "./data/enceintes_petit.shp" "./data/ilots_petit.shp" ] ]
  
  set liste-donnees-brutes [ ]
  let enveloppe-monde [ ]
  
  foreach liste-noms-fichiers-donnees
  [ let donnees-brutes-courantes gis:load-dataset ?
    set liste-donnees-brutes lput donnees-brutes-courantes liste-donnees-brutes
    
    ifelse empty? enveloppe-monde
    [ set enveloppe-monde gis:envelope-of donnees-brutes-courantes ]
    [ set enveloppe-monde gis:envelope-union-of enveloppe-monde gis:envelope-of donnees-brutes-courantes ] ]
  
  let epsilon 0.01     ; petite erreur introduite pour eliminer les effets de bords
  
  set enveloppe-monde (list (item 0 enveloppe-monde - epsilon) (item 1 enveloppe-monde + epsilon) (item 2 enveloppe-monde - epsilon) (item 3 enveloppe-monde + epsilon))

  set largeur-donnees item 1 enveloppe-monde - item 0 enveloppe-monde
  set hauteur-donnees item 3 enveloppe-monde - item 2 enveloppe-monde
  
  resize-world 0 (largeur-donnees / metres-par-patch) 0 (hauteur-donnees / metres-par-patch)
  
  gis:set-world-envelope enveloppe-monde
  
  output-print (word "Largeur (en m) : " largeur-donnees)
  output-print (word "Hauteur (en m) : " hauteur-donnees)
  
  ;---------------------------------------------------------------------
  ; creation des shapes
  
  creation-polygones
      
  ask patches
  [ set pcolor 9 ]
  
  rafraichissement
  display
end

;-----------------------------------------------------------------------

; methode issue de l'exemple GIS dans la librairie
to creation-polygones
  (foreach liste-donnees-brutes liste-noms-fichiers-donnees
  [ let donnees-brutes-courantes ?1
    let nom-fichier-courant ?2
   
    ;-------------------------------------------------------------------
    ; recherche du type courant des elements
    
    let nom-type-courant ""
  
    ifelse member? "batiments" nom-fichier-courant
    [ set nom-type-courant "batiment" ]
    [ ifelse member? "enceintes" nom-fichier-courant
      [ set nom-type-courant "enceinte" ]
      [ set nom-type-courant "ilot" ] ]
  
    foreach gis:feature-list-of donnees-brutes-courantes
    [ let liste-sommets-crees [ ]
      let liste-aretes-creees [ ]
    
      ;-------------------------------------------------------------------
      ; creation des sommets et des aretes du polygone
    
      foreach gis:vertex-lists-of ?
      [ let sommet-precedent nobody
        let premier-sommet nobody
      
      ; le premier et le dernier sommets d'un polygone dans un shapefile sont aux memes coordonnees
      ; on ne les cree pas deux fois ici
      foreach but-last ?
      [ let coords-sommet-courant gis:location-of ?
        
        if empty? coords-sommet-courant [ print "ok" ]
          ; si les coordonnees du sommet courant sont en-dehors du monde de NetLogo, gis:location-of donne une liste vide
          if not empty? coords-sommet-courant
          [ create-sommets 1
            [ set xcor first coords-sommet-courant
              set ycor last coords-sommet-courant
              set shape "dot"
            
              ifelse not is-turtle? sommet-precedent
              [ set premier-sommet self ]
              [ create-arete-with sommet-precedent
                [ set color black
                  set liste-aretes-creees lput self liste-aretes-creees ] ]
            
              set hidden? true
              set sommet-precedent self
              set liste-sommets-crees lput self liste-sommets-crees ] ] ]
        
        ; on relie le premier sommet au dernier cree pour fermer le polygone courant
        if is-turtle? premier-sommet and premier-sommet != sommet-precedent
        [ ask premier-sommet
          [ create-arete-with sommet-precedent
            [ set color black
              set liste-aretes-creees lput self liste-aretes-creees ] ] ] ]
    
      ;-------------------------------------------------------------------
      ; creation de l' "objet" au centre du polygone
      
      let coords-centroide gis:location-of gis:centroid-of ?

      create-elements 1
      [ set xcor first coords-centroide
        set ycor last coords-centroide
        set shape "x"
        set size 0.5
        set color black
        
        set nom-type nom-type-courant
        set vector-data ?
        set ensemble-sommets turtle-set liste-sommets-crees
        set ensemble-aretes link-set liste-aretes-creees
      
        ask ensemble-sommets
        [ set proprietaire myself ] ] ] ])
end

;-----------------------------------------------------------------------

to rafraichissement
  ; rafraichissement de la fenetre de visualisation en fonction des options d'affichage choisies par l'utilisateur
  ; note : l'ordre de dessin des elements est important. Sinon, les enceintes cacheraient les batiments, etc.
  
  cd
  
  ask aretes [ hide-link ]
  ask elements [ hide-turtle ]
  
  let elements-concernes-affichage no-turtles
  
  if affichage-ilots?
  [ gis:set-drawing-color couleur-ilots
    
    ask elements with [ nom-type = "ilot" ]
    [ ask ensemble-aretes [ show-link ]
      gis:fill vector-data 0 ]
    
    set elements-concernes-affichage (turtle-set elements-concernes-affichage elements with [ nom-type = "ilot" ]) ]
  
  if affichage-enceintes?
  [ gis:set-drawing-color couleur-enceintes
    
    ask elements with [ nom-type = "enceinte" ]
    [ ask ensemble-aretes [ show-link ]
      gis:fill vector-data 0 ]
    
    set elements-concernes-affichage (turtle-set elements-concernes-affichage elements with [ nom-type = "enceinte" ]) ]
  
  if affichage-batiments?
  [ gis:set-drawing-color couleur-batiments
    
    ask elements with [ nom-type = "batiment" ]
    [ ask ensemble-aretes [ show-link ]
      gis:fill vector-data 0 ]
    
    set elements-concernes-affichage (turtle-set elements-concernes-affichage elements with [ nom-type = "batiment" ]) ]
  
  if affichage-centroides?
  [ ask elements-concernes-affichage [ show-turtle ] ]
end

;-----------------------------------------------------------------------
@#$#@#$#@
GRAPHICS-WINDOW
205
105
561
450
-1
-1
15.73
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
21
0
19
0
0
1
ticks
30.0

BUTTON
5
187
200
220
Afficher les donnees
chargement-donnees
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
5
10
840
100
12

SLIDER
5
152
200
185
metres-par-patch
metres-par-patch
10
100
50
10
1
m.p-1
HORIZONTAL

MONITOR
845
10
920
55
Nb sommets
count sommets
17
1
11

MONITOR
845
55
920
100
Nb elements
count elements
17
1
11

SWITCH
5
240
200
273
affichage-batiments?
affichage-batiments?
0
1
-1000

SWITCH
5
275
200
308
affichage-enceintes?
affichage-enceintes?
0
1
-1000

SWITCH
5
310
200
343
affichage-ilots?
affichage-ilots?
0
1
-1000

SWITCH
5
345
200
378
affichage-centroides?
affichage-centroides?
1
1
-1000

BUTTON
5
575
200
608
Rafraichir
rafraichissement
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
5
385
200
445
couleur-batiments
15
1
0
Color

INPUTBOX
5
445
200
505
couleur-enceintes
65
1
0
Color

INPUTBOX
5
505
200
565
couleur-ilots
45
1
0
Color

MONITOR
950
55
1025
100
Nb batiments
count elements with [ nom-type = \"batiment\" ]
17
1
11

MONITOR
1045
55
1120
100
Nb enceintes
count elements with [ nom-type = \"enceinte\" ]
17
1
11

MONITOR
1140
55
1215
100
Nb ilots
count elements with [ nom-type = \"ilot\" ]
17
1
11

TEXTBOX
930
70
945
91
=
16
0.0
1

TEXTBOX
1030
70
1045
91
+
16
0.0
1

TEXTBOX
1125
70
1140
91
+
16
0.0
1

CHOOSER
5
105
200
150
taille-data
taille-data
"petite" "grande"
0

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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
