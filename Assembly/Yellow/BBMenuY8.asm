/*

BBMenu file 8 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"
include "charmap.inc"


def borderTile                = $c0
def snakeTile 		          = $c1
def foodTile 		          = $c7
def bgTile  		          = $7f
def tileAddress 	          = $5188
def buffer  		          = $d8b4
def atefood 		          = $ffef
def length 	    	          = $fff0
def score   		          = $fff1
def level   		          = $fff2
def lastkey 		          = $fff6
def lastmove 		          = $fff7

def sinstall                  = wblock-block3offset



SECTION "BBMenuY8", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

call opensram1

ld   c, menupointersend - menupointers
ld   de, slistable+44              ; destination
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
db low(snake),           high(snake)
menupointersend:

ENDL

LOAD "mapdata", WRAM0[wblock]
mapstart:

snake:
call SaveScreenTilesToBuffer2
ld   bc, $0409			; load 9 tiles from bank $04
ld   de, tileAddress		; from address
ld   hl, $8c00			; to vram address
call CopyVideoData
jr   EnterPoint

collided:				     ; Snake collided
ld 	a, $a6         		; Load the sound identifier [A6 == error sound]
pop  hl
call PlaySound      	     ; Play the sound [external subroutine]
call WaitForSoundToFinish     ; Wait for sound to be done playing [external subroutine]

EnterPoint:				; Clear BG
call GBFadeOutToWhite	; fade out effect
call ClearScreen		; Fill screen with 7F bytes = white tiles
call UpdateSprites		; removes sprites from screen

ld   a, $10				; default direction value set to right
ldh  [lastkey], a 		; starting movement lastkey
ldh  [lastmove], a 

; Draw top border
ld   hl, wTileMap 		; 1st screen tile		
ld   bc, $0014 			; screen width (20)
ld   a, borderTile		; black tile (border)
call FillMemory

; Draw vertical borders
ld   c, $12				; b is already 0, a is black
ld   d, $0f 				; screen height 
;ld a, borderTile		; used only for rb
.loop
ld   [hli], a 			; right border tile
add  hl, bc
ld   [hli], a 			; left border tile
dec  d
jr   nz, .loop 
	
; Draw bottom border
ld   c, $14
call FillMemory 		; bottom row

; Draw stats
ld   de, text
call CopyString			; copies game's stats text
ld   bc, $4103			; bit 6 of b set to align left, c = 3 digits
dec  hl					; screen tile position
ld   de, snakescore
call PrintNumber		; print snakescore
	
call GBFadeInFromWhite

; Place the three-tile snake in the screen and save its position and length	
ld   a, $02
ldh  [length], a	
ld   b, a
ld   de, buffer			; save the snake position in the buffer
ld   hl, $c445 			; center of screen
call bufferloop
push hl					; saves next tile position
jr   placeobject

; MAIN LOOP
tilecheck:				; Check if the snake moved on empty tile
push hl					; saves new tile position
ld   a, [hl]
cp   a, bgTile
jr   z, movesnake

; Check if the snake ate the object
cp   a, foodTile
jr   nz, collided

didEat:
ld 	a, $a7           	; Load the sound identifier [A7 == eating sound]
call PlaySound        	; Play the sound

; Draw the object that can be eaten in a random position in the screen
placeobject:
call Random				; Since A can handle values up to 255, we divide by 2 and multiply by 2 afterwards.
cp   a, $95 				; 298 empty tiles / 2  
jr   nc, placeobject 		; don't place the object outside the screen
ld   b, $00
ld   c, a
ld   hl, $c3b5			; 1st screen tile c3b5-c4de=398 tiles
add  hl, bc
add  hl, bc
call Random
and  a, $01
jr   z, noinc
inc  hl
noinc:
ld   a, bgTile 			; white tile
cp   [hl]					; check random tile
jr   nz, placeobject 		; don't place the object in a border or over a snake or obstacle tile
ld   [hl], foodTile 		; place object

buffsnake:				; +1 length
ldh  a, [length]
inc  a
cp   a, $c7
jr   nc, movesnake
ldh  [length], a 		; increase snake length
jr   loadhead


movesnake:				; Move snake in the buffer
; Remove the snake's tail
ld   de, buffer			; load last tile from buffer
push de
ld   a, [de]				; into hl
ld   h, a
inc  de
ld   a, [de]
ld   l, a
inc  de
ld   [hl], bgTile 		; replace with white tile

ldh  a, [length]
dec  a					; subtracts head
add  a					; doubles size to fit buffer addresses
ld   c, a
	
; move every snake tile one space
movebody:
ld   h, d
ld   l, e
pop  de
call CopyMapConnectionHeader+2


; add head tile
loadhead:
pop  hl					; loads new head address to hl
ld   b, $01
call bufferloop			; updates tile + buffer
dec  hl					; it selects head tile again
push de					; buffer head +1
push hl					; tile head 
; fallthrough	


DrawScore:				; update stats
ld   bc, $4103			; bit 6 of b set to align left, c = 3 digits
ld   de, length
ld   a, [de]
inc  de					; lenght to score
sub  a, c				; c = 3 snake tiles too
ld   [de], a				; into score
ld   hl, snakescore
cp   a, [hl]
jr   c, nobest
ld   [hl], a
nobest:
ld   hl, $c4fb
call PrintNumber		; current score

ld   bc, $141c			; calculate speed level
ld   a, [de]				; load current length (PrintNumber actually decreses de)
cp   a, b					; if current score more than 17
jr   nc, samelevel		; use preset speed
ld   b, a					; else use current score

samelevel:				; calculate delay frames
ld   a, c					; example if skipping level (max speed)
sub  a, b				; min 8
ld   b, a					; delay frames

pop  hl					; tile head
pop  de					; buffer +1

loopdelay:
call DelayFrame

ldh  a, [hJoyInput]
bit  1, a
jp   nz, LoadScreenTilesFromBuffer2     ; end game if B is pressed
and  $F0 				; %11110000, R/L/U/D bits
jr   z, nobutton
ld   c, a

ldh  a, [lastmove]
and  a, $30				; check last active bits 4,5
jr   nz, next				; if not, we know last active bits are 6,7

ld   a, c
and  a, $C0				; if true we check new input
jr   nz, nobutton 		; if new input ands with non zero, we have same or forbidden direction, end of loop

ld   a, c					; if new input ands with zero, legal button is pressed, we update input
ldh  [lastkey], a
jr   nobutton


; lastmove and C0 is true for sure
next:
ld   a, c
and  a, $30				; if true we check new input
jr   nz, nobutton 		; if new input ands with non zero, we have same or forbidden direction, end of loop

ld   a, c					; if new input ands with zero, legal button is pressed, we update input
ldh  [lastkey], a

nobutton:
dec  b
jr   nz, loopdelay


; Read user input
ReadUserInput:
ldh  a, [lastkey] 		; load last key pressed out of R/L/U/D
ldh  [lastmove], a
bit  6, a
ld   bc, $ffec			; - $14 up
jr   nz, MovePosition
bit  5, a
ld   c, b                ; - $01 left
jr   nz, MovePosition
bit  4, a
inc  bc
inc  bc                  ; + $01 right
jr   nz, MovePosition
MovePositionDown: 		; + $14 down
ld   c, $14
; fallthrough

; Calculate the new snake head and save it in the buffer
MovePosition:
add  hl, bc				; adds new offset to head'stile address
jp   tilecheck

bufferloop:				; places b snake's tiles on screen and save their address int buffer
ld   [hl], snakeTile
ld   a, h
ld   [de], a
inc  de
ld   a, l
ld   [de], a
inc  de
inc  hl
dec  b
ret  z
jr   bufferloop

text:					; " Score XXX Best XXX "
db $7F, $92, $A2, $AE, $B1, $A4, $7F, $F6, $7F, $7F, $7F, $81, $A4, $B2, $B3, $7F, $50

mapend:

ENDL

