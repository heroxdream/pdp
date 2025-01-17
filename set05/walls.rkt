;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname walls) (read-case-sensitive #t) (teachpacks ((lib "arrow-gui.rkt" "teachpack" "htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "arrow-gui.rkt" "teachpack" "htdp")))))
(require "extras.rkt")

(require rackunit)

(require 2htdp/image)

(require 2htdp/universe)

(define TIME-ON-TASK 25) ; hours


; provides ______________

(provide INITIAL-WORLD)

(provide next-world)

(provide key-handler)

(provide mouse-handler)

(provide replace-balls)

(provide end?)

(provide score)

(provide level)

(provide get-balls)

(provide mk-ball)

(provide get-ball-x)

(provide get-ball-y)












; constants _______________

(define WIDTH 400)

(define HEIGHT 400)

(define TOTAL-AREA (* WIDTH HEIGHT))

(define MT (empty-scene WIDTH HEIGHT))

(define RADIUS 20)

(define BALL-IMG (circle RADIUS "solid" "blue"))

(define WALL-WIDTH 4)

(define WALL-INITIAL-LEN 2)

(define WALL-MAX-GROWTH 16)

(define WALL-MIN-GROWTH 8)

(define ALPHA 100)

(define BASE-GOAL 50)

(define MAX-GOAL 90)

(define MAX-VELOCITY 10)

(define MIN-VELOCITY 1)

(define FONT-SIZE 20)

(define GAME-OVER (text "GAME OVER" 45 "black"))










;data definition ___________________



; A Speed is in either one of:
; - [-10, -1]
; - [1, 10]
; INTERP: positive means Speed toward positive direction,
;         vice versa.
(define sp1 -100000) ; speed is 10 in negative X/Y direction, tick/pixels
(define sp2 50000)   ; speed is 5 in positive X/Y direction, tick/pixels





(define-struct velocity [vx vy])
; A Velocity is a (make-velocity Speed Speed)
; INTERP: vx, vy represents the current phycial velocity of the ball along 
;         X or Y Axis; Positive means the ball is now moving in X/Y Coordinate's
;         positive direction; Negtive means toward oppsite direction.
(define ve1 (make-velocity sp2 sp1)) ; x direction speed is 5 tick/pixels
                                     ; y direction speed is -10 tick/pixels
; TEMPLATE:
; velocity-fn : Velocity -> ???
(define (velocity-fn v)
  (... (velocity-vx v) ... (velocity-vy v) ...))




(define-struct property [c s])
; A Property is a (make-property Coordinate Speed)
; INTERP: c represents coordinate and s represents speed, the two elements
;         forms one property of object in X or Y axis direction
(define pro1 (make-property 10 -9)) ; position is 10, speed is -9

; TEMPLATE:
; property-fn : Property -> ???
(define (property-fn p)
  (... (property-c p) ... (property-v p) ...))




(define-struct ball [po v])
; A Ball is a (make-struct Posn Velocity)
; INTERP: posn po represents the ball's x and y Coordinates while velocity v  
;         represents the ball's Speed along x and y Coordinate.
(define b1 (make-ball (make-posn 10 10)       ; ball's position is (10, 10)
                        ve1))                 ; ball's veclocity is (5, -10)
; TEMPLATE:
; ball-fn : Ball -> ???
(define (ball-fn b)
  (... (ball-po b) ... (ball-v b) ...))





; A ListOfBall is a ListOf<Ball>
; INTERP: Represents all the balls in the current world
(define lob1 (list b1))


; A ListOfCoordinate is a ListOf<Coordinate>
; INTERP: a bounch of coordinates
(define loc1 (list 1 2 3 4))





; A ListOfPosn is a ListOf<Posn>
; INTERP: Represents a series of posns
(define lop1 (list (make-posn 10 10)))





(define-struct area [l r u d reachable])
; A Area is a (make-area Coordinate Coordinate Coordinate Coordinate Boolean)
; INTERP: l represents the area's left bound, while r represents right,
;         u for up, d for down
(define INITIAL-CANVAS (make-area 0 400 0 400 #true)) ; initial canvas
(define area1 (make-area 0 400 0 400 #false))

; TEMPLATE:
; area-fn : Area -> ???
(define (area-fn a)
  (... (area-l a) ... (area-r a) ...
       (area-u a) ... (area-d a) ...
       (area-reachable a)))




; A ListOfArea is a ListOf<Area>
; INTERP: Areas in this list reprensts the current structure of the canvas.
;         That is, how the canvas is partioned by the walls. Every element
;         in this list represents a seperate area in the canvas.
(define INITIAL-AREAS (list INITIAL-CANVAS)) ; a list that only contains  
                                             ; the initial canvas
(define loa1 (list area1))




; A Direction is one of:
;  - "horizontal"
;  - "vertical"
; INTERP: horizontal means the wall is now extending in horizontal direction,
;         the same is for vertical
(define H "horizontal") ; horizontal
(define V "vertical")   ; vertical

; TEMPLATE:
; direction-fn : Direction -> ???
;(define (direction-fn d)
;  (cond
;    [(horizontal? d) ...]
;    [(vertical? d) ...]))




(define-struct wall [h1 h2 dir ac1 ac2])
; A Wall is a (make-wall Posn Posn Direction Boolean)
; INTERP: h1, h2 represents position of the two ends of the wall,
;         direction represents whether the wall is vertical or horizontal,
;         active means whether the wall is now active, or growing.
(define w0 (make-wall (make-posn 0 0)        
                      (make-posn 390 0)
                      H
                      #false #true))
(define w2 (make-wall (make-posn 0 300)        
                      (make-posn 400 300)
                      H
                      #true #true))
(define w3 (make-wall (make-posn 0 301)        
                      (make-posn 400 301)
                      H
                      #true #true))

(define WU (make-wall (make-posn 0 0)        ; upper bound of the whole canvans
                      (make-posn WIDTH 0)
                      H
                      #false #false))

(define WD (make-wall (make-posn 0 HEIGHT)   ; down bound of the whole canvans
                      (make-posn WIDTH HEIGHT)
                      H
                      #false #false))

(define WL (make-wall (make-posn 0 0)        ; left bound of the whole canvans
                      (make-posn 0 HEIGHT)
                      V
                      #false #false))

(define WR (make-wall (make-posn WIDTH 0)    ; right bound of the whole canvans
                      (make-posn WIDTH HEIGHT)
                      V
                      #false #false))
; TEMPLATE:
; wall-fn : Wall -> ???
(define (wall-fn w)
  (... (wall-h1 w) ... (wall-h2 w) ...
       (wall-dir w) ... (wall-ac1 w) ...(wall-ac2 w) ...))
                                       




; A ListOfWall is a ListOf<Wall>
; INTERP: the walls in the list represents a group of wall
(define INITIAL-WALLS (list WU WD WL WR))
(define walls1 (list w0 w2 w3 WU WD WL WR))





(define-struct world [areas balls walls level dir])
; A World is a (make-world ListOfBall ListOfArea ListOfWall NonNegInt Direction)
; INTERP: world represents the current world state. areas means how many 
;         sub-areas in this world, balls means how many balls, the same for 
;         walls.level represents the current world's level, dir represents the
;         current inserting wall direction.

(define world1 (make-world loa1 lob1 walls1 10 H)) ; a world

; TEMPLATE:
; world-fn : World -> ???
(define (world-fn w)
  (... (world-areas w) ... (world-balls w) ...
       (world-walls w) ... (world-level w) ...
       (world-dir w)))













; #World Funcitons _______________________



; run : World -> World
; Simulates a game similar to the classic JezzBall game. One should 
; clean certain areas to get score, if the current score above thresold
; then world goes to next level. if a active wall touchs a ball, game over.
; STRATEGY: function composition
(define (run w)
  (big-bang w
            (on-tick next-world)
            (on-key key-handler)
            (on-mouse mouse-handler)
            (on-draw render)
            (stop-when end? render-last)))



; next-world : World -> World
; Computes world's state after one tick by the given world w
(begin-for-test
  (check-equal? (next-world INITIAL-WORLD)
                (make-world (next-areas INITIAL-WORLD)
                            (next-balls INITIAL-WORLD)
                            (next-wall (world-walls INITIAL-WORLD))
                            (world-level INITIAL-WORLD)
                            (world-dir INITIAL-WORLD))
                "world after one tick")
  (check-true (world?  (next-world world1))
              "new level world begins"))
; STRATEGY: function composition
(define (next-world w)
  (if (achieve-goal? w)
      (next-level w)
      (make-world (next-areas w)
                  (next-balls w)
                  (next-wall (world-walls w))
                  (world-level w)
                  (world-dir w))))



; key-handler : World KeyEvent -> World
; Returns the next world after one key is pressed with the given world w
(begin-for-test
  (check-equal? (key-handler INITIAL-WORLD "a")
                INITIAL-WORLD
                "other key pressed do nothing")
  (check-equal? (key-handler INITIAL-WORLD " ")
                (after-key-pressed INITIAL-WORLD)
                "key space pressed do nothing"))
; STRATEGY: data decomposition on KeyEvent : ke
(define (key-handler w ke)
  (cond
    [(string=? " " ke) (after-key-pressed w)]
    [else w]))



; mouse-handler : World MouseEvent -> World
; Returns the next world state after one mouse event happended.
(begin-for-test
  (check-equal? (mouse-handler INITIAL-WORLD 10 10 "button-down")
                (after-mouse-click INITIAL-WORLD 10 10)
                "bottom-down")
  (check-equal? (mouse-handler INITIAL-WORLD 10 10 "button-up")
                INITIAL-WORLD 
                "bottom-down"))
; STRATEGY: data decomposition on MouseEvent : m
(define (mouse-handler w x y m)
  (cond 
    [(string=? m "button-down") (after-mouse-click w x y)]
    [else w]))



; render : World -> Image
; Renders the current world's state into image
(begin-for-test
  (check-true (image? (render INITIAL-WORLD))
              "renders the initial world as a image"))
; STRATEGY: data decomposition on World : w
(define (render w)
  (local (;draw-balls : ListOfBall Image -> Image
          ;Draws the balls of the world
          ;STRATEGY: function composition
          (define (draw-balls bs bkg)
            (foldr (place-item item-image ball-x ball-y) bkg bs))
          
          ;draw-walls : ListOfWall Image -> Image
          ;Draws the alls of the world
          ;STRATEGY: function composition
          (define (draw-walls ws bkg)
            (foldr (place-item item-image wall-x wall-y) bkg ws))
          
          ; unreachable areas, ListOfAreas
          (define unreachable-areas (unreachables (world-areas w)))
          
          ;draw-areas : ListOfArea Image -> Image
          ;Draws the balls of the world
          ;STRATEGY: function composition
          (define (draw-areas as bkg)
            (foldr (place-item item-image area-x area-y) 
                   bkg 
                   unreachable-areas))
          
          ;draw-dir-text : Direction Image -> Image
          ;Draws the hint of direction of wall now inserting in the world
          ;STRATEGY: function composition
          (define (draw-dir-text dir bkg)
            (draw-text (string-append "Click to create " dir " wall") 
                       (/ WIDTH 2) (- HEIGHT 20) bkg))
          
          ;draw-score-text : NonNegInt Image -> Image
          ;Draws how many scores the player got
          ;STRATEGY: function composition
          (define (draw-score-text score bkg)
            (draw-text (string-append "Score " (number->string score) "%") 
                       (- WIDTH 50) 15 bkg))
          
          ;draw-goal-text : NonNegInt Image -> Image
          ;Draws how many scores are needed to pass current level
          ;STRATEGY: function composition
          (define (draw-goal-text goal bkg)
            (draw-text (string-append "Goal " (number->string goal) "%") 
                       (- WIDTH 50) 40 bkg))
          
          ;draw-level-text : PosInt Image -> Image
          ;Draws what level it is now
          ;STRATEGY: function composition
          (define (draw-level-text level bkg)
            (draw-text (string-append "Level " (number->string level)) 
                       50 20 bkg))
          
          ;draw-text : String Image -> Image
          ;Draws one kind of string of the world
          ;STRATEGY: function composition
          (define (draw-text txt x y bkg)
            (place-image (text txt FONT-SIZE "black") x y bkg))
          
          ;draw-all-text : World Image -> Image
          ;Draws all the text info of the world w
          ;STRATEGY: data decomposition on World : w
          (define (draw-all-text w bkg)
            (draw-dir-text (world-dir w) 
                           (draw-score-text (score w) 
                                            (draw-goal-text (goal w) 
                                                            (draw-level-text 
                                                             (world-level w) 
                                                             bkg))))))
    (draw-all-text w
                   (draw-walls (world-walls w)
                               (draw-balls (world-balls w) 
                                           (draw-areas (world-areas w) 
                                                       MT))))))




; end? : World -> Boolean
; Returns true if any ball hit a active wall, which terminates the game
(begin-for-test
  (check-false (end? INITIAL-WORLD)
              "no hit active wall")
  (check-true (end? world1)
              "hit active wall"))
; STRATEGY: data decomposition on World : w
(define (end? w)
  (if (world-wall-active? w)
      (ball-hit-active-wall? (first (world-walls w)) (world-balls w))
      #false))




; render-last : World -> Image
; Renders the last scene of the world
(begin-for-test
  (check-true (image? (render-last world1))
              "renders the last world as a image"))
; STRATEGY: function composition
(define (render-last w)
  (place-image GAME-OVER
               (/ WIDTH 2)
               (/ HEIGHT 2)
               (render w)))



; achieve-goal? : World -> Boolean
; Returns true if the current score >= goal
(begin-for-test
  (check-false (achieve-goal? INITIAL-WORLD)
               "not achieve goal"))
; STRATEGY: function composition
(define (achieve-goal? w)
  (>= (score w) (goal w)))



; next-level : World -> World
; Returns a new initial world after one finished current level's score goal
; i.e. if the current world is level 1, then returns a level 2 world, which
; contains two randomd balls.
(begin-for-test
  (check-true (world? (next-level INITIAL-WORLD))
              "next world"))
; STRATEGY: data decomposition on World : w
(define (next-level w)
  (make-world INITIAL-AREAS
              (random-balls (add1 (world-level w)))
              INITIAL-WALLS
              (add1 (world-level w))
              V))



; next-areas : World -> Areas
; Compute areas of the world after on tick.
(begin-for-test
  (check-equal? (next-areas INITIAL-WORLD)
                (world-areas INITIAL-WORLD)
                "no active wall")
  (check-equal? (next-areas world1)
                (rearrange-areas world1)
                "has one active wall"))
; STRATEGY: function composition
(define (next-areas w)
  (if (world-wall-active? w)
      (rearrange-areas w)
      (world-areas w)))



; next-balls : World -> ListOfBall
; Compute balls of the world after on tick.
(begin-for-test
  (check-true (list? (next-balls world1))
              "next balls of the world1"))
; STRATEGY: function composition
(define (next-balls w)
  (local (
          (define as (world-areas w)) ; ListOfArea
          
          ;area-contain-ball: Ball -> Areas
          ;Returns the area that contains the given ball b
          ;STRATEGY: function composition
          (define (area-contain-ball b)
            (area-contain-posn (ball-po b) as))
          
          ;next-coor-speed: Coordinate Speed Coordinate Coordinate -> 
          ;                                                        ListOf<Real>
          ;Computes speed and position after one tick
          ; - if the speed is not to cross boundary line1 or line2 go ahead
          ; - else the speed will turn opposite, and the position will flush
          ;   against the boundary
          ;STRATEGY: function composition
          (define (next-coor-speed coor speed line1 line2)
            (if (or (cross? coor speed line1)
                    (cross? coor speed line2))
                (make-property (first (crossed coor (list line1 line2) speed))
                               (- 0 speed))
                (make-property (+ coor speed) speed)))
          
          ;next-ball-x: Ball Area -> Property
          ;Computes speed and position in X axis
          ;STRATEGY: data decomposition on Ball : b
          (define (next-ball-x b a)
            (next-coor-speed (ball-x b) (ball-vx b) 
                             (+ (area-l a) (/ WALL-WIDTH 2) RADIUS)
                             (- (area-r a) (/ WALL-WIDTH 2) RADIUS)))
          
          ;next-ball-y: Ball Area -> Property
          ;Computes speed and position in Y axis
          ;STRATEGY: data decomposition on Ball : b
          (define (next-ball-y b a)
            (next-coor-speed (ball-y b) (ball-vy b) 
                             (+ (area-u a) (/ WALL-WIDTH 2) RADIUS)
                             (- (area-d a) (/ WALL-WIDTH 2) RADIUS)))
          
          ;next-ball: Ball -> Ball
          ;Computes one ball's state after one tick
          ;STRATEGY: function composition
          (define (next-ball b)
            (assemble-ball (next-ball-x b (area-contain-ball b)) 
                           (next-ball-y b (area-contain-ball b))))
 
          ;balls-after-one-tick: World -> ListOfBall
          ;Computes all the balls' state after one tick
          ;STRATEGY: function composition
          (define (balls-after-one-tick w)
            (map (lambda (b) (next-ball b))
                 (world-balls w))))
    
    (balls-after-one-tick w)))




; rearrange-areas : World -> Areas
; Returns the world areas after one tick
(begin-for-test
  (check-false (world? (rearrange-areas world1))
              ""))
; STRATEGY: function composition
(define (rearrange-areas w)
  (local(
         (define wall-head (first (next-wall (world-walls w)))) ; Wall
         
         ;split-world-area : World -> Areas
         ;Returns the orignal areas if there is no active wall
         ;else returns the old and new areas
         ;STRATEGY: function composition
         (define (split-world-area w)
           (if (wall-active wall-head)
               (world-areas w)
               (combine-area w wall-head))))
    
    (split-world-area w)))



; after-key-pressed : World -> World
; Changes the world's inserting direction after space key is pressed
(begin-for-test
  (check-true (world? (after-key-pressed world1))
              ""))
; STRATEGY: data decomposition on World : w
(define (after-key-pressed w)
  (cond 
    [(horizontal? (world-dir w)) (replace-dir w V)]
    [(vertical? (world-dir w)) (replace-dir w H)]))



; after-mouse-click: World Coordinate Coordinate -> World
; Computes the new state of world after mouse button is pressed
(begin-for-test
  (check-equal? (after-mouse-click world1 1000 1000)
                world1
                ""))
; STRATEGY: data decomposition on World : w 
(define (after-mouse-click w x y)
  (cond
    [(or (xy-in-unreachable? x y (world-areas w))
         (world-wall-active? w))
     w]
    [else (replace-walls w  
                         (add-wall x y (world-walls w) (world-dir w)))]))



; world-wall-active?: World -> Boolean
; Returns true if the world has a active wall
(begin-for-test
  (check-true (world-wall-active? world1))
  "active")
; STRATEGY: data decomposition on World : w 
(define (world-wall-active? w)
  (wall-active (first (world-walls w))))



; world-balls : World -> ListOf<Ball>
; Returns all the balls in the given world. 
(begin-for-test
  (check-equal? (get-balls INITIAL-WORLD)
                (world-balls INITIAL-WORLD)
                "balls"))
; STRATEGY: function composition
(define (get-balls w)
  (world-balls w))



; replace-balls : World ListOf<Ball> -> World
; Replaces the Balls in the given World with the given Balls.
(begin-for-test
  (check-equal? (replace-balls INITIAL-WORLD (list b1))
                (make-world (world-areas INITIAL-WORLD)
                            (list b1)
                            (world-walls INITIAL-WORLD)
                            (world-level INITIAL-WORLD)
                            (world-dir INITIAL-WORLD))
                "balls"))
; STRATEGY: data decomposition on World : w 
(define (replace-balls w lob)
  (make-world (world-areas w)
              lob
              (world-walls w)
              (world-level w)
              (world-dir w)))


; replace-walls : World ListOf<Wall> -> World
; Replaces the Walls in the given World with the given Walls.
(begin-for-test
  (check-equal? (replace-walls INITIAL-WORLD (list w0))
                (make-world (world-areas INITIAL-WORLD)
                            (world-balls INITIAL-WORLD)
                            (list w0)
                            (world-level INITIAL-WORLD)
                            (world-dir INITIAL-WORLD))
                "walls"))
; STRATEGY: data decomposition on World : w 
(define (replace-walls w low)
  (make-world (world-areas w)
              (world-balls w)
              low
              (world-level w)
              (world-dir w)))


; replace-dir : World Direction -> World
; Replaces the direction in the given World with the given direction d.
(begin-for-test
  (check-equal? (replace-dir INITIAL-WORLD H)
                (make-world (world-areas INITIAL-WORLD)
                            (world-balls INITIAL-WORLD)
                            (world-walls INITIAL-WORLD)
                            (world-level INITIAL-WORLD)
                            H)
                "walls"))
; STRATEGY: data decomposition on World : w 
(define (replace-dir w dir)
  (make-world (world-areas w)
              (world-balls w)
              (world-walls w)
              (world-level w)
              dir))



; score : World -> Natural
; Returns the current score.
(begin-for-test
  (check-equal? (score INITIAL-WORLD)
                0
                "zero"))
; STRATEGY: function composition 
 (define (score w)
  (round (* ALPHA
            (/ (foldr + 0
                   (map (lambda (a) (* (- (area-r a) (area-l a))
                                       (- (area-d a) (area-u a))))
                        (unreachables (world-areas w))))
            TOTAL-AREA))))

 
 
; goal: World -> PosInt
; Returns the goal of the current level
 (begin-for-test
  (check-equal? (goal INITIAL-WORLD)
                55
                "zero"))
; STRATEGY: data decomposition on World : w 
(define (goal w)
  (min 90
       (+ 50 (* 5 (world-level w))))) 



; level : World -> Natural
; Returns the current level.
(begin-for-test
  (check-equal? (level INITIAL-WORLD)
                1
                "1"))
; STRATEGY: function composition 
 (define (level w)
   (world-level w))



 
 

 
 
 

 
; #Ball Functions __________________________________________________


; ball-x : Ball -> Coordinate
; Returns the x position of the Ball's center.
(begin-for-test
  (check-equal? (get-ball-x b1)
                10
                "10"))
; STRATEGY: data decomposition on Ball : b
(define (ball-x b)
  (posn-x (ball-po b)))
; get-ball-x : Ball -> Coordinate
; Returns the x position of the Ball's center.
; STRATEGY: function composition
(define (get-ball-x b)
  (ball-x b))




; ball-y : Ball -> Coordiate
; Returns the y position of the Ball's center.
(begin-for-test
  (check-equal? (get-ball-y b1)
                10
                "10"))
; STRATEGY: data decomposition on Ball : b
(define (ball-y b)
  (posn-y (ball-po b)))
; ball-y : Ball -> Coordiate
; Returns the y position of the Ball's center.
; STRATEGY: function composition
(define (get-ball-y b)
  (ball-y b))



; ball-vx : Ball -> Real
; Returns the vx of the Ball's Velocity.
(begin-for-test
  (check-equal? (ball-vx b1)
                (velocity-vx (ball-v b1))
                "10"))
; STRATEGY: data decomposition on Ball : b
(define (ball-vx b)
  (velocity-vx (ball-v b)))



; ball-vy : Ball -> Real
; Returns the vy of the Ball's Velocity.
(begin-for-test
  (check-equal? (ball-vy b1)
                (velocity-vy (ball-v b1))
                "10"))
; STRATEGY: data decomposition on Ball : b
(define (ball-vy b)
  (velocity-vy (ball-v b)))



; assemble-ball: Property Property -> Ball
; Returns a Ball by give x-lst and y-lst which contains properties in
; X and Y axis
(begin-for-test
  (check-equal? (assemble-ball (make-property 10 10) (make-property 10 10))
                (mk-ball 10 10 10 10)
                "assemble-ball"))
; STRATEGY: function composition
(define (assemble-ball x y)
  (mk-ball (property-c x)
             (property-c y)
             (property-s x)
             (property-s y)))









; #Wall Functions __________________________________________________

; wall-x : Wall -> Coordinate
; Computes wall w's X coordinate inorder to draw it
(begin-for-test
  (check-equal? (wall-x w0)
                (/ (+ (posn-x (wall-h1 w0))
                      (posn-x (wall-h2 w0)))
                   2)
                "10"))
; STRATEGY: data decomposition on Wall : w
(define (wall-x w)
  (/ (+ (posn-x (wall-h1 w))
        (posn-x (wall-h2 w)))
     2))



; wall-y : Wall -> Coordinate
; Computes wall w's Y coordinate inorder to draw it
(begin-for-test
  (check-equal? (wall-y w0)
                (/ (+ (posn-y (wall-h1 w0))
                      (posn-y (wall-h2 w0)))
                   2)
                "10"))
; STRATEGY: data decomposition on Wall : w
(define (wall-y w)
  (/ (+ (posn-y (wall-h1 w))
        (posn-y (wall-h2 w)))
     2))



; wall-image: Wall -> Image
; Presents wall as a image
(begin-for-test
  (check-true (image? (wall-image w0))
              "image"))
; STRATEGY: data decomposition on Wall : w
(define (wall-image w)
  (if (horizontal? (wall-dir w))
      (rectangle (abs (- (posn-x (wall-h1 w)) (posn-x (wall-h2 w))))
                 WALL-WIDTH "solid" "brown")
      (rectangle WALL-WIDTH (abs (- (posn-y (wall-h1 w)) (posn-y (wall-h2 w))))
                 "solid" "brown")))


; wall-active: Wall -> Boolean
; Returns true if the given wall w is active
(begin-for-test
  (check-true (boolean? (wall-active w0))
              "boolean"))
; STRATEGY: data decomposition on Wall : w
(define (wall-active w)
  (or (wall-ac1 w) (wall-ac2 w)))



; next-wall : ListOfWall -> ListOfWall
; Computes all the walls' next state after one tick
(begin-for-test
  (check-true (list? (next-wall (list w0)))
              "list"))
; STRATEGY: function composition
(define (next-wall ws) 
  (if (not (wall-active (first ws))) 
      ws
      (cons (next-active-wall (first ws) (rest ws)) (rest ws))))



; next-active-wall : Wall ListOfWall -> ListOfWall
; Computes the next state of the active wall
(begin-for-test
  (check-equal? (next-active-wall WL (list w0))
                (next-v-wall WL (list w0))
                "vertical"))
; STRATEGY: data decompostion on Wall : w
(define (next-active-wall w ws)
  (cond 
    [(horizontal? (wall-dir w)) (next-h-wall w ws)]
    [(vertical? (wall-dir w)) (next-v-wall w ws)]))



; next-h-wall: Wall ListOfWall -> Wall
; Computes the next state of the active horizontal wall
; STRATEGY: function composition
(define (next-h-wall w ws)
  (compute-next-wall w ws H posn-x posn-y wall-y))



; next-v-wall: Wall ListOfWall -> Wall
; Computes the next state of the active vertical wall
; STRATEGY: function composition
(define (next-v-wall w ws)
  (compute-next-wall w ws V posn-y posn-x wall-x))



; compute-next-wall: Wall ListOfWall [M->N] [M->N] [X->Y] -> Wall
; Computes next wall's state with given wall w, list of walls ws, and three
; functions to extract walls property such as x or y coordinate
; STRATEGY: function composition
(define (compute-next-wall w ws dir active-coor inactive-coor constant-coor)
  (local(
         (define ppd-ws (perpendicular dir ws)) ; ListOfWall
         
         (define ppd-within-ws (ppd-within (inactive-coor (wall-h1 w))
                                            ppd-ws ; ListOfWall
                                            inactive-coor))
         
         (define h1s (next-speed (wall-ac1 w) (wall-ac2 w))) ; Speed
         
         (define h2s (next-speed (wall-ac2 w) (wall-ac1 w))) ; Speed
         
         (define cs (map (lambda (p) (active-coor (wall-h1 p))) ; Coordinates
                         ppd-within-ws))
          ; Coordinates
         (define h1c (next-tick-wall (active-coor (wall-h1 w)) cs (- 0 h1s)))
          ; Coordinates
         (define h2c (next-tick-wall (active-coor (wall-h2 w)) cs h2s))
          ; Coordinates
         (define constantc (constant-coor w))
         
         ; make-pos-lam : Direction -> [Coordinate Coordinate -> Posn]
         ; Returns a lambda function by given direction dir to assembel
         ; a position
         ; STRATEGY: function composition
         (define (make-pos-lam dir)
           (cond 
             [(horizontal? dir) (lambda (x y) (make-posn x y))]
             [(vertical? dir) (lambda (x y) (make-posn y x))]))
         
         ; create-wall: Wall -> Wall
         ; Returns a new wall state after one tick of grow
         ; STRATEGY: function composition
         (define (create-wall w)
           (make-wall ((make-pos-lam dir) h1c constantc)
                      ((make-pos-lam dir) h2c constantc)
                      (wall-dir w)
                      (not (member? h1c cs))
                      (not (member? h2c cs)))))
    
    (create-wall w)))




; ball-hit-active-wall? : Wall Balls -> Boolean
; Returns true if any ball hits the active wall
; STRATEGY: function composition
(define (ball-hit-active-wall? wall balls)
  (local (
          (define posns (decompose-wall wall)) ; ListOfPosn
          
          ;hit? ListOfBall -> Boolean
          ;Returns true if the one of the posns are within or on the ball
          ;STRATEGY: function composition
          (define (hit? balls)
            (ormap (lambda (ball) (posns-in-ball? ball posns))
                   balls))
          
          ;posns-in-ball?: Ball ListOf<Posn> -> Boolean
          ;Returns true if the one of the posns are within or on the ball
          ;STRATEGY: function composition
          (define (posns-in-ball? ball posns)
            (ormap (lambda (posn) (posn-in-ball? posn ball))
                   posns))
          
          ;posn-in-ball?: Ball ListOf<Posn> -> Boolean
          ;Returns true if the given posn is within or on the ball
          ;STRATEGY: data decomposition on Ball : ball
          (define (posn-in-ball? posn ball)
            (<= (distance posn (ball-po ball))
                RADIUS))
          
          ;distance: Coordinate Coordinate -> Real
          ;Computes the phycial of two given position
          ;STRATAGY: data decomposition on Posn : p
          (define (distance p1 p2)
            (sqrt (+ (sqr (- (posn-x p1) (posn-x p2)))
                     (sqr (- (posn-y p1) (posn-y p2)))))))
    
    (hit? balls)))



; decompose-wall : Wall -> ListOfPosn
(define (decompose-wall wall)
  (local (
          (define h1 (wall-h1 wall))   ;Posn
          (define h2 (wall-h2 wall))   ;Posn
          (define dir (wall-dir wall)) ; Direction
         
          ;decompose: Wall -> ListOfPosn
          ;Returns the Posns of the outline of the wall
          ;STRATAGY: function composition
          (define (decompose wall)
            (cond 
              [(horizontal? dir) (points-to-lines H V posn-y posn-x)]
              [(vertical? dir) (points-to-lines V H posn-x posn-y)]))
          ;points-to-lines: Direction Direction 
          ;                [Posn -> Coordinate] [Posn -> Coordinate]
          ;                 -> ListOfPosn
          ;decompose the given posn h1 h2 to list of posns
          ;STRATAGY: function composition
          (define (points-to-lines dir1 dir2 posn-c posn-c2)
            (append (coordinate->posns dir1 
                                       (- (posn-c h1) 2) 
                                       (posn-c2 h1) 
                                       (posn-c2 h2))
                    (coordinate->posns dir1 
                                       (+ (posn-c h1) 2) 
                                       (posn-c2 h1) 
                                       (posn-c2 h2))
                    (coordinate->posns dir2 
                                       (posn-c2 h1) 
                                       (- (posn-c h1) 2) 
                                       (+ (posn-c h1) 2))
                    (coordinate->posns dir2 (posn-c2 h2) 
                                       (- (posn-c h1) 2) 
                                       (+ (posn-c h1) 2))))
          
          ;coordinate->posns: Direction Coordinate Coordinate Coordinate 
          ;                   -> ListOfPosn
          ;Transfer the given coordinate small and big and constant to 
          ;a bounch of posns
          ;STRATAGY: function recursion
          (define (coordinate->posns dir constant small big)
            (if (= small big)
                (list (mk-posn dir constant small))
                (cons (mk-posn dir constant small)
                      (coordinate->posns dir constant (add1 small) big))))
          
          ;mk-posn: Direction Coordinate Coordinate -> Posns
          ;Creates a posn by the given coordinate, with direction dir to decide
          ;which coordinate is the constant.
          ;STRATAGY: data decomposition on Direction dir
          (define (mk-posn dir constant changing)
            (cond
              [(horizontal? dir) (make-posn changing constant)]
              [(vertical? dir) (make-posn constant changing)])))
    

    (decompose wall)))

; add-wall : Coordinate Coordinate ListOfWall Direction -> ListOfWall
; Adds a new wall to the give walls ws
; STRATAGY: function composition
(define (add-wall x y ws dir)
  (cons (new-wall x y dir) ws))



; ppd-within : X ListOfWall [Y -> X] -> ListOfWall
; Returns list of wall by filter on the given walls ws and given property c
; STRATAGY: function composition 
(begin-for-test
  (check-equal? (ppd-within 20 (list w2) posn-x)
                (list w2)
                ""))
(define (ppd-within c ws preperty)
  (filter (lambda (w) (and (<= (preperty (wall-h1 w)) c)
                           (>= (preperty (wall-h2 w)) c)))
          ws))



; perpendicular: Direction ListOfWall -> ListOfWall
; Computes a list of walls that is perpendicular to the given directin dir
; STRATAGY: function composition 
(define (perpendicular dir ws)
  (cond
    [(horizontal? dir) (filter (wall-filter wall-dir vertical?)
                               ws)]
    [(vertical? dir) (filter (wall-filter wall-dir horizontal?)
                               ws)]))




; wall-filter: [X -> Y] [Z -> Boolean] -> [Z -> Boolean]
; Returns filter function by the given propertys and functions
; STRATAGY: function composition
(define (wall-filter property condition)
  (lambda (w) (condition (property w))))




; split-area-by-wall : Wall Area -> ListOfArea
; Splits the given area area-contain-wall to two areas by the given wall w
(begin-for-test
  (check-true (list? (split-area-by-wall w0 area1))
               "")
  (check-true (list? (split-area-by-wall WL area1))
               ""))
; STRATAGY: data decomposition on Wall: w
(define (split-area-by-wall w area-contain-wall)
  (local (
         (define l (area-l area-contain-wall))
         (define r (area-r area-contain-wall))
         (define u (area-u area-contain-wall))
         (define d (area-d area-contain-wall))
          )
  (cond
    [(horizontal? (wall-dir w)) (list (make-area l r u (wall-y w) #true)
                                      (make-area l r (wall-y w) d #true))]
    [(vertical? (wall-dir w)) (list (make-area l (wall-x w) u d #true)
                                    (make-area (wall-x w) r u d #true))])))





; new-wall : Coordinate Coordinate Direction -> Wall
; Creates the initial active wall by given coordinates and direciton
(begin-for-test
  (check-true (wall? (new-wall 1 2 H))
               ""))
; STRATEGY: function composition
(define (new-wall x y dir)
  (cond
    [(horizontal? dir) (make-wall (make-posn (- x (/ WALL-INITIAL-LEN 2)) y)
                                  (make-posn (+ x (/ WALL-INITIAL-LEN 2)) y)
                                  dir
                                  #true #true)]
    [(vertical? dir) (make-wall (make-posn x (- y (/ WALL-INITIAL-LEN 2)))
                                (make-posn  x (+ y (/ WALL-INITIAL-LEN 2)))
                                dir
                                #true #true)]))















; #Area Functions __________________________________________________

; area-image : Area -> Image
; Projects a area as a Image
; STRATAGY: data decomposition on Area: a
(define (area-image a)
  (rectangle (- (area-r a) (area-l a))
             (- (area-d a) (area-u a))
             "solid" "yellow"))



; area-x : Area -> Coordinate
; Returns the x coordinate of the area's center
; STRATAGY: data decomposition on Area: a
(define (area-x a)
  (/ (+ (area-r a) (area-l a))
     2))



; area-y : Area -> Coordinate
; Returns the y coordinate of the area's center
; STRATAGY: data decomposition on Area: a
(define (area-y a)
  (/ (+ (area-d a) (area-u a))
     2))



; unreachables : ListOfArea -> ListOfArea
; Filters those unreachables areas of a list of areas
; STRATAGY: function composition
(define (unreachables as)
  (filter (lambda (a) (not (area-reachable a))) 
          as))



; combine-area: Wall Area -> ListOfArea
; Combines the two areas divied by one new wall with the rest of the areas
; in the world
; STRATAGY: function composition
(define (combine-area world wall)
  (local (
         (define bs (world-balls world)) ; ListOfBall

         (define as (world-areas world)) ; ListOfArea
         
         (define area-contain-wall       ; Area
           (area-contain-posn (make-posn (wall-x wall)
                                         (wall-y wall)) 
                              as))
         
         (define other-areas (remove area-contain-wall as)) ; ListOfArea
         ;combine -> ListOfArea
         ;Combines the new walls with rest walls
         ;STRATAGY: function composition
         (define (combine wall)
           (append (decide-reachable 
                    (split-area-by-wall wall area-contain-wall)
                    bs) 
                   other-areas)))
    
    (combine wall)))         


; dot-in-area?: Posn Area -> Boolean
; Returns true if the given posn p is in the given area a
; STRATAGY: data decomposition on Area: a
(define (dot-in-area? p a)
           (and (< (area-l a) (posn-x p) (area-r a))
                (< (area-u a) (posn-y p) (area-d a))))



; area-contain-posn : Posn ListOfArea -> Area
; Returns the area that contains the given posn from given list of areas
; STRATAGY: function composition
(define (area-contain-posn posn as)
           (first (filter (lambda (a) (dot-in-area? posn
                                                    a))
                   as)))




; decide-reachable : ListOfArea ListOfBall -> ListOfArea
; Decides whether the given list of areas is reachable by the given balls
; STRATAGY: function composition
(define (decide-reachable as bs)
  (map (lambda (a) (make-area (area-l a)
                              (area-r a)
                              (area-u a)
                              (area-d a)
                              (reachable-by-balls? a bs)))
       as))
       




; reachable-by-balls? : Area ListOfBall -> Boolean
; Returns true if the given area a is reachable by the given list of balls
; STRATAGY: function composition
(define (reachable-by-balls? a bs)
  (ormap (lambda (b) (dot-in-area? (ball-po b) a))
         bs))
         














; Direction Functions __________________________________________________


; horizontal? : Direction -> Boolean
; vertical? : Direction -> Boolean
; Returns true if the direction d is horizontal or vertical
; STRATAGY: data decomposition on Direction dir
(begin-for-test
  (check-true (horizontal? H)
              "horizontal")
  (check-false (vertical? H)
              "vertical"))
(define (horizontal? d)
  (string=? d H))
(define (vertical? d)
  (string=? d V))














; Helper Functions __________________________________________________

; place-item: [X -> Image] [X -> Coordinate] [X -> Coordinate] -> [X -> Image]
; Creates a function that can place one kind of image to the background
; STRATAGY: function composition
(define (place-item item-image item-x item-y)
  (lambda (one-item scene)
    (place-image (item-image one-item)
                 (item-x one-item) 
                 (item-y one-item) 
                 scene)))



; item-image : X -> Image
; Returns the image that represent the given item X
; STRATAGY: function composition
(define (item-image item)
  (if (ball? item)
      BALL-IMG
      (if (wall? item)
          (wall-image item)
          (area-image item))))



; mk-ball : Coordinate Coordinate Real Real -> Ball
; Returns a Ball with center at (x,y), with the given velocities.
; A positive x velocity is in the x-increasing direction and vice versa.
; The y velocity is similar.
; STRATAGY: function composition
(define (mk-ball x y vx vy)
  (make-ball (make-posn x y)
              (make-velocity vx vy)))


; random-balls : NonNegInt -> ListOfBall
; Returns a group of balls with randomed position and velocity, the number of 
; balls is assigned by level
; STRATAGY: funciton resursion
(define (random-balls level)
  (local (;Coordinate
          (define horizontal-wall (- WIDTH (+ (* 2 RADIUS) WALL-WIDTH)))
          ;Coordinate
          (define vertical-wall (- HEIGHT (+ (* 2 RADIUS) WALL-WIDTH)))
          ;Coordinate
          (define offset (+ RADIUS (/ WALL-WIDTH 2)))
          ;random-ball PosInt -> Ball
          ;Creates a randomed ball
          ;STRATAGY: funciton composition
          (define (random-ball level)
            (make-ball (random-posn horizontal-wall vertical-wall offset)
                        (random-velocity MAX-VELOCITY MIN-VELOCITY))))
  
    (if (= 1 level)
        (list (random-ball level))
        (cons (random-ball level)
              (random-balls (sub1 level))))))



; random-posn : Coordinate Coordinate NonNegInt NonNegInt
; Returns a random posn within a width x height canvas.
; WHERE: the returned posn satisfies not going off the give
;        canvas
(begin-for-test
  (check-true (posn? (random-posn 300 300 5))
              "check for random posn"))
; STRATEGY: function composition
(define (random-posn width height offset)
  (make-posn 
   (+ offset (random width))
   (+ offset (random height))))



; random-velocity : PosInt PosInt -> Speed
; Returns a randomed speed with the given max and min value
; STRATEGY: function composition
(define (random-velocity max min)
  (make-velocity
   (* (random-sign max) (+ (random max) min))
   (* (random-sign max) (+ (random max) min))))



; xy-in-unreachable? : Coordinate Coordinate ListOfArea -> Boolean
; Returns true if the given coordinates is within the given areas
; STRATEGY: function composition
(define (xy-in-unreachable? x y areas)
  (ormap (lambda (area) (dot-in-area? (make-posn x y) area))
         (unreachables areas)))



; random-sign : Real -> Real
; Returns a randomed sign
; STRATEGY: function composition
(define (random-sign max)
  (if (> (random max) (/ max 2))
      -1
      1))


; crossed: Coordinate ListOfCoordinate Speed -> ListOfCoordinate
; Returns the filtered coordinates that being crossed by the coordinate
; x and speed 
; STRATEGY: function composition
(define (crossed x xs speed)
  (filter (lambda (n) (cross? x speed n))
          xs))



; cross?: Coordinate Speed Coordinate
; Returns true if the given coordinate with the given speed will cross the line
; STRATEGY: function composition
(define (cross? start speed line)
  (or (and (< start line)
           (<= line (+ start speed)))
      (and (> start line) 
           (>= line (+ start speed)))))



; find-closest : Coordinate ListOfCoordinate -> Coordinate
; Finds the closest coordinate to the given coordinate x from a list
; of coordinate given as xs
; STRATEGY: function composition
(define (find-closest x xs)
  (local (;
          ;
          (define (to-pair x xs)
            (map (lambda (n) (make-posn n (abs (- x n))))
                 xs))
          ;
          (define sorted (sort (to-pair x xs)
                               (lambda (p1 p2) (< (posn-y p1) (posn-y p2)))))
          )
    (posn-x (first sorted))))



; next-speed: Boolean Boolean -> NonNegInt
; Returns WALL-MAX-GROWTH if the two given boolean are both true
; WALL-MIN-GROWTH if one of them if true, 0 if both are false.
; STRATEGY: function composition
(define (next-speed ac1 ac2)
  (if (and ac1 ac2)
      WALL-MAX-GROWTH
      (if ac1 WALL-MIN-GROWTH 0)))




; next-tick-wall: Coordinate ListOfCoordinate -> Coordinate
; Computes next coordinate with the given speed, if it is to be block by any of 
; the given groups of lines xs, the final coordinate will flush at the blocking
; line
; STRATEGY: function composition
(begin-for-test
  (check-equal? (next-tick-wall 100 (list 0 110 200) 16)
                110
                "")
  (check-equal? (next-tick-wall 100 '() 16)
                116
                ""))
(define (next-tick-wall x xs speed)
  (local(
         (define crossed-wall (crossed x xs speed)) ; ListOfCoordinate
         ;find-next: Coordinate ListOfCoordinate Speed -> Coordinate
         ;Computes next coordinate
         ;STRATEGY: function composition
         (define (find-next x xs speed)
           (if (empty? crossed-wall)
               (+ x speed)
               (find-closest x crossed-wall)))
         )
    (find-next x xs speed)))






(define INITIAL-BALLS (random-balls 1))


(define INITIAL-WORLD 
  (make-world INITIAL-AREAS INITIAL-BALLS INITIAL-WALLS 1 V))

; Main Function ____________________________________________

(run INITIAL-WORLD)





; ================= Alternate Data Definition =================



; 1. alternative data definition 1




; (define-struct wall [dir constant head1 head2 active])
; A Wall is a (make-wall Direction Coordinate Coordinate Coordinate Boolean)
; INTERP: dir represents the current wall's direction, constant represents the
;         wall's costant coordinate, head1 head2 represents two growing end's
;         coordinates, active represents whether the wall is active.


; other data definition remains unchanged

; Pros:
;  - with this definition, it is easier to operate on wall. there will be no
;    need to decompse posn to get wall's coordinate anymore
;    the following helper functions is not needed .

;(define (wall-x w)
;  (/ (+ (posn-x (wall-h1 w))
;        (posn-x (wall-h2 w)))
;     2))
;
;(define (wall-active w)
; (or (wall-ac1 w) (wall-ac2 w)))

;  - less elements, eaiser to understand and read

; Cons:
;  - but it will be harder to decide whether the wall is active





; 2. alternative data definition 2

; (define-struct area [p1 p2 p3 p4 reachable])
; A Wall is a (make-area Posn Posn Posn Posn Posn Boolean)
; INTERP: p1 p2 p3 p4 represents 4 cooner of the area
;         active represents whether the area is reachable.

; other data definition remains unchanged

; Pros:
;  - with this definition, it is easier to understand


;  

; Cons:
;  - so many redundent informantion included because for each pair the four
;    points, there will be one pair of equal coordinate.
;  - by using posn, more nested strutures will be used to decompose area.


