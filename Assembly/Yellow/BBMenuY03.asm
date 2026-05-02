/*

BBMenu file 3 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"
include "charmap.inc"


def listitems       = 23
def scriptsblock1   = 14
def scriptsblock2   = 22


SECTION "BBMenuY3", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:
call opensram1

; move scripts into map sram data
ld   bc, menuend - menustart
ld   de, smenu		          ; destination
ld   hl, installer.end
call CopyData

ld   a, listitems
ld   [smenulist], a

; closes SRAM
jp   CloseSRAM
.end
ENDL
	


LOAD "mapdata", WRAM0[wOverworldMap]
menustart:

ld   hl, DisplayTextIDInitdrawTextBoxBorder
call bankswitch1         ; Bankswitch hardcoded to bank 1

ld   hl, wListPointer	; list header is stored
ld   de, wmenulist
ld   [hl], e
inc  hl
ld   [hl], d

ld   a, $56              ; items id is the least noticable one
ld   b, listitems

buildloop:               ; builds item list
inc  de
ld   [de], a
dec  b
jr   nz, buildloop
inc  de
ld   a, $ff              ; adds cancel item
ld   [de], a             ; it is ff anyway, no need to make it

openmenu:
; gets extra menu graphics
ld   bc, $0e10           ; load 10 tiles from bank $0e
ld   de, tileAddress     ; from address
ld   hl, $8d00           ; to vram address
call CopyVideoData

; predefs menu settings
xor  a
ld   hl, wPrintItemPrices	
ld   [hl+], a			; wPrintItemPrices = 0
ld   [hl], $04           ; wListMenuID = 0

; recovers bbm pointer
ld   hl, bbmselect       ; restores bbmenu's selector position
push hl
call loadsel

jr   nz, noset           ; loadsel sets z if add is 0
inc  a                   ; a = 1
ld   [de], a             ; wCurrentMenuItem = 1

noset:
ld   hl, dmaflags
set  0, [hl]             ; it enables dma renaming
push hl
call DisplayListMenuID
and  a, a	
pop  hl
res  0, [hl]             ; it disables dma renaming

pop  hl                  ; bbmselect
push af                  ; stores menu output for later

call savesel             ; saves menu pointer

pop  af
ret  z	               ; end if B is pressed

; calculate and fetch correct map bank data
push de
ld   a, d
ld   bc, blocklength  
ld   hl, sblock1 

cp   a, scriptsblock1
jr   c, part1

cp   a, scriptsblock2
jr   c, part2

part3:
add  hl, bc

part2:
add  hl, bc

part1:
call opensram1
ld   de, wblock
call CopyData
call CloseSRAM
pop  af             ; item selection
ld   hl, listable
call CallFunctionInTable

jr   openmenu		; reload menu


;;;;;;;;;;;; DMA Routine ;;;;;;;;;;;;

; loop that calculates correct address for display names
menucode:           ; it overwrites list menu names
ld   de, menu1		; origin
ld   hl, $c3f6		; destination tile - first letter of menu
ld   a, [wListScrollOffset]   ; it shows how many times the list has scrolled downwards
inc  a              ; +1
ld   b, a           ; stored in b counter
ld   c, a           ; stored in c counter

.loop               ; breaks when correct label is found for line 1
dec  b
jr   z, next

.findstop           ; next label is after @ char
ld   a, [de]
inc  de
cp   a, $50
jr   nz, .findstop
jr   .loop

; loop that overwrites list names
next:
ld   b, $04         ; 4 lines to be replaced
push hl             ; saves initial tile for later

.loop               ; fetches text replacement
ld   a, [de]
inc  de
cp   a, $50         ; if @
jr   z, .endloop    ; stops execution without writing char
ld   [hli], a       ; else write char and repeat
jr   .loop

.endloop
pop  hl             ; restores first tile
push de             ; saves current text origin

ld   a, $02
sub  a, b           ; current line counter
add  a, c           ; wListScrollOffset

push hl
ld   de, $000a      ; tiles to be added to draw selector icon
add  hl, de         ; calculates next line
cp   a, $06         ; number of script using selector (max 8)
jr   nc, .nextline
ld   e, a 
ld   a, [bbmflags]

.rotateloop
rrc  a              ; rotate to check current selected bit
dec  e
jr   nz, .rotateloop

bit  0, a
jr   nz, .on
ld   [hl], $d3
jr   .nextline
.on
ld   [hl], $d0

.nextline
pop  hl
ld   e, $28         ; tiles to be added to draw next line
add  hl, de         ; calculates next line
pop  de             ; restores dear address
push hl             ; saves new line's first digit
dec  b              ; subtracts 1 line from the counter
jr   nz, .loop      ; are remaining lines 0?

pop  hl             ; restores saved line to keep balance of stack

endjp:
jp DisplayListMenuIDLoop+6


bufferspare:        ; bufferdmaspare is called by other scripts
push de
call SaveScreenTilesToBuffer2
pop  de

dmaspare:           ; enabledmaspare is called by other scripts
ld   hl, dmatable+14
ld   [hl], e
inc  hl
ld   [hl], d
ld   hl, dmaflags
set  7, [hl]        ; enables temp dma flag
ret

; Custom Text
menu1:
db "BBMenu@"
menu2:
db "A-Run@"
menu3:
db "B-Slip@"
menu4:
db "Repel@"
menu5:
db "Beast@"
menu6:
db "StealRun@"
menu7:
db "Stealth@"
menu8:
db "Fly@"
menu9:
db "Heal@"
menu10:
db "PC@"
menu11:
db "Items@"
menu12:
db "Moves@"
menu13:
db "Pokémon@"
menu14:
db "Wilds@"
menu15:
db "Trainers@"
menu16:
db "InstaText@"
menu17:
db "FillDex@"
menu18:
db "Badges@"
menu19:
db "Cash@"
menu20:
db "Coins@"
menu21:
db "Clone@"
menu22:
db "Pong@"
menu23:
db "Snake@"
menu24:
db "Cancel@"
menu25:
db "@"

menuend:

ENDL


