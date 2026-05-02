/*

BBMenu file 7 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"
include "charmap.inc"


def backroundTile   = $7f
def ballTile        = $d0
def padTile         = $d9

;def pongscore      = $d704   ; adderess highscore is stored
def direction       = $ffdf   ; byte used to decide ball's direction
def ballx           = $ffe2   ; holds ball's x tile position
def bally           = $ffe3   ; holds ball's y tile position
def hops            = $ffef   ; counter to decide when to level up
def framesdelay     = $fff0   ; frames to delay base on current level
def score           = $fff1   ; current score to show on screen

def winstall        = $ca39
def sinstall        = winstall-block2offset



SECTION "BBMenuY7", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

call opensram1

ld   c, menupointersend - menupointers
ld   de, slistable+42              ; destination
ld   hl, menupointers              ; installer origin
call CopyMapConnectionHeaderloop

; move scripts into map data
ld   bc, mapend - mapstart
ld   de, sinstall                  ; destination
call CopyData

; closes SRAM
jp   CloseSRAM

; ----------- Menu pointers ------------
menupointers:           ; it automatically calculates every script's starting point offsets
db low(pong),            high(pong)
menupointersend:

ENDL

LOAD "mapdata", WRAM0[winstall]
mapstart:

pong:
call SaveScreenTilesToBuffer2
call ClearScreen
call UpdateSprites

newgame:
ld   bc, $0e10                ; load 16 tiles from bank $0e
ld   de, tileAddress          ; from address
ld   hl, $8d00                ; to vram address
call CopyVideoData

ld   a, $06
ld   hl, hops                 ; hops are subtracted to change level
ld   [hli], a                 ; hops = 6
ld   [hli], a                 ; framesdelay = 6
xor  a
ld   [hli], a                 ; score = 0
ldh  [direction], a           ; resets ball direction        
ld   l, low(ballx)
ld   [hl], b                  ; ballx = 15
inc  hl                       ; hl = bally
ld   [hl], b                  ; bally = 15
ld   d, b
dec  d                        ; d = 14

keycheck:   
ldh  a, [hJoyInput]           ; Read buttons
ld   c, a
bit  1, a                     ; Check button B

; Exit to menu
jp   nz, LoadScreenTilesFromBuffer2

; No exit
ld   a, $10
and  a, c                     ; Check right
jr   z, checkleft             ; If it is, skip this check so the pad does not go outside the screen bounds
dec  a                        ; a = $0f
cp   a, d                     ; Check if the pad is on the screen's rightmost edge
jr   z, checkleft             ; Increment the pad X location if it is set
inc  d                        ; Increments the D register. Used in conditional jumps.

; Part of key input checking
checkleft:             
ld   a, $20                   ; Check left
and  a, c
jr   z, screenupdate          ; Decrement the pad Y location if it is set
ld   a, d
and  a                        ; Check if the pad is on the screen's leftmost edge
jr   z, screenupdate          ; If it is, skip this check so the pad does not go outside the screen bounds

dec  d

; make screen white
screenupdate:
ld   bc, $0154                ; bytes to set
ld   hl, $c3a0                ; on screen tiles
ld   a, backroundTile         ; loads white tile
push de                       ; save ball pos for later
push hl                       ; saves screen tile for later
push de                       ; save ball pos for later
call FillMemory               ; fill screen with white tiles

; draw stats
ld   b, d
ld   de, text                 ; hl $c4f4
call CopyString               ; copies game's stats text

; draw pad tiles
ld   hl, $c4e0
ld   a, l                       
add  a, b
ld   l, a                     ; adds pad offset to hl
ld   a, padTile
ld   [hl+], a                 ; draws pad
ld   [hl+], a
ld   [hl+], a
ld   [hl+], a
ld   [hl], a

; level calc
ld   de, framesdelay
ld   a, [de]
ld   c, a
ld   a, $07
sub  a, c                     ; 7 - framedelay

; print level
ld   l, $f6                   ; hl = $c4f6
add  a, "0"
ld   [hl], a                  ; print level on screen

; print score
inc  de
ld   l, $fc                   ; hl $c4fc
ld   bc, $4103                ; bit 6 of b set to align left, c = 3 digits
call PrintNumber              ; current score

; print highscore
ld   de, pongscore
ld   hl, $c505                ; screen tile position
call PrintNumber              ; print pongscore

; detect wall collision
pop  de                       ; reloads ball pos
ld   hl, direction
ld   c, $0f                   ; preload c - invert byte x
ldh  a, [ballx]
and  a                        ; if x = 0 - left wall
call z, bounce
cp   a, $13                   ; if x = 19 - right wall
call z, bounce 
ld   c, $f0                   ; preload c - invert byte y
ldh  a, [bally]
and  a                        ; if y = 0 - upper wall
call z, bounce
cp   a, $11                   ; if y = 17 - below pad level
jr   nc, gameover             ; if y >= 17, ball is low, game is over
cp	a, $0f                    ; if y = 15 - on pad level
jr 	nz, moveball             ; if no bounce found, just move ball

; if ball bounces on pad
ldh  a, [hops]
inc  a
ldh  [hops], a
cp   a, $0a                   ; Check to speed up game
jr   nz, samehardness

ldh  a, [framesdelay]
dec  a
ldh  [hops], a
cp   a, $01
jr   z, samehardness
ldh  [framesdelay], a

samehardness:
ld   e, d
dec  e
ld   b, $08
ldh  a, [ballx]

checkpad:
cp   a, e                     ; check if the ball touches the pad tile
jr   nz, nobounce

; update counter
push hl
ld   hl, score
inc  [hl]
pop  hl
call bounce

nobounce:
inc  e
dec  b
jr   nz, checkpad             ; check all pad tiles

; Moves the ball on diagonals based on the direction byte
moveball:
ld   a, [hl]                  ; direction byte
ld   b, a                     ; b = direction
ld   l, low(ballx)            ; hl = ballx
and  a, $0f
jr   nz, dontincx             ; if true, inc x
inc  [hl]                     ; hl = bally
xor  a                        ; sets z flag

dontincx:
jr   z, dontdecx              ; If it isn't, decrement X position
dec  [hl]
xor  a       

dontdecx:
inc  l                        ; bally
ld   a, b
and  a, $f0
jr   nz, dontincy             ; if true, inc y
inc  [hl]                      
xor  a 

dontincy:
jr   z, dontdecy              ; If it isn't, decrement Y position
dec  [hl]
xor  a 

; Calculates new balls position
dontdecy:
pop  hl                       ; restore tile address
ldh  a, [ballx]
add  a, l                         
ld   l, a
ldh  a, [bally]
and  a
jr   z, placeball             ; If it is, skip the loop, as the ball drawing position is already calculated

; loop to calculate ball's position
ballcalc:
ld   bc, $0014                ; tile screen width
add  hl, bc                   ; increase ball y position
dec  a
jr   nz, ballcalc

placeball:
ld   a, ballTile              ; draw ball
ld   [hl], a

; Delays frames according to game's level after updating graphics
delaytime:
ldh  a, [framesdelay]
ld   c, a
call DelayFrames

pop  de                       ; restore pad location
jp   keycheck

gameover:
ld 	a, $a6                 	; error sound
call PlaySound
call WaitForSoundToFinish     ; adds a delay for new game

; updates highscore if needed
ldh  a, [score]
ld   hl, pongscore
cp   a, [hl]
jr   c, skip
ld   [hl], a

skip:
pop  hl
pop  hl
jp 	newgame

bounce:
push af
ld   a, c                     ; loads direction
xor  a, [hl]                  ; changes direction
ld   [hl], a                  ; loads back new direction
ld   a, $af                   ; beeps sound
call PlaySound
pop  af
ret  

text:
db "Lv  Hop     Best @"

mapend:

ENDL

