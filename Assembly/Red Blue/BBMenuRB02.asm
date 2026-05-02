/*

BBMenu file 2 - Compatible with EN RED/BLUE ONLY


Source is compiled with RGBDS
*/

include "pokered.inc"
include "bbmenuRB.inc"
include "charmap.inc"


def menucode        = $c75d   ; modify if menu code length changes
def stackmenu       = $dfe9
def returnmenu      = DisplayListMenuIDLoop+6     ; $2c59
def stackrun        = $dffd
def returnrun       = $0402


SECTION "BBMenuRB02", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

call opensram1

ld   c, dmapointersend - dmapointers
ld   de, sdmatable                 ; destination
ld   hl, dmapointers               ; installer origin
call CopyMapConnectionHeaderloop

ld   c, mspointersend - mspointers
ld   de, smsptable                 ; destination
call CopyMapConnectionHeaderloop

; move scripts into box data
ld   bc, scriptsend - scriptstart
ld   de, sboxpayloads              ; destination
call CopyData

; closes SRAM
jp   CloseSRAM


; ----------- DMA pointers ------------
dmapointers:           ; it automatically calculates every script's starting point offsets
db low(dmamenu),         high(dmamenu)
db low(dmarun),          high(dmarun)
db low(dmabeast),        high(dmabeast)
db low(dmaescape),       high(dmaescape)
dw $DC72 ; dmashiny
dmapointersend:

; ----------- MSP pointers ------------
mspointers:
db low(mspslip),         high(mspslip)
db low(msprepel),        high(msprepel)
db low(mspstealth),      high(mspstealth)
mspointersend:

ENDL


LOAD "codebox", WRAMX[boxpayloads]

scriptstart:
;;;;;;;;;;;; Common payloads ;;;;;;;;;;;;
; savesel:                    ; saves selector value in a buffer specified by de
ld   de, wListScrollOffset
ld   a, [de]
ld   b, a                     ; save it for later
ld   [hli], a
ld   e, low(wCurrentMenuItem)
ld   a, [de]
ld   [hl], a
add  a, b                     ; to check if first script is selected
ld   d, a
ret

; loadsel:
ld   de, wListScrollOffset
ld   a, [hli]
ld   b, a                     ; save it for later
ld   [de], a                  ; into wListScrollOffset address
ld   e, low(wCurrentMenuItem)
ld   a, [hl]
ld   [de], a
add  a, b                     ; to check if first script is selected
ret


;;;;;;;;;;;; DMA payloads ;;;;;;;;;;;;

dmamenu:                      ; this dma common function is placed here to be accessed anytime
; stack check and replace
ld   hl, stackmenu            ; stack return pointer for PrintListMenuEntries
ld   bc, returnmenu           ; static menu return address for PrintListMenuEntries
ld   de, menucode

; stackhijack:
ld   a, [hli]
cp   a, c
ret  nz
ld   a, [hl]
cp   a, b
ret  nz
ld   a, d
ld   [hld], a
ld   [hl], e
ret

dmarun:
; stack check and replace
ld   hl, stackrun		          ; static address DelayFrame ret address is stored
ld   bc, returnrun
ld   de, speedon
jp   stackhijack

; script activates when delayFrame ends in overworld loop
speedon:
; checks button A pressed
ldh  a, [hJoyHeld]
bit  0, a
jp   z, OverworldLoopLessDelay+3	; we skip second DelayFrame, so we speed up game x2	

.loop
ld   b, $02
ld   a, [wWalkBikeSurfState]
inc  a
cp   a, b
jr   nz, .nobike
inc  b
.nobike
ld   a, [wWalkCounter]
cp   a, b
jp   c, OverworldLoopLessDelay+3
call AdvancePlayerSprite
jr   .loop


mspslip:
ld   a, [wStatusFlags5]		; spin check
and  a
ret  nz

ld   hl, hJoyInput
ld   c, [hl]
bit  1, [hl] 			; B Button
jr   z, .skip            ; reset collision if not pressed

call check               ; if pressed call checks
xor  a                   ; a = 0 is needed for later
dec  b                   ; check flag b
jr   nz, .skip           ; if b was 0, forbid movement
inc  a                   ; else walk through walls
.skip
ld   [wSimulatedJoypadStatesIndex], a ; Loads Walk Type
ret

check:
ld   b, a                ; a = 0, b flag = 0 for later
ld   de, wCurMapConnections

checktop:
ld   hl, wYCoord         ; current Y position
ld   a, [wCurMap]
cp   a, $02              ; checks for Brock town
ld   a, [hl]
jr   nz, .nodec

dec  a                   ; it narrows borders 1 tile
dec  a                   ; it narrows borders 1 tile
.nodec
and  a
jr   nz, checkbot        ; next check if not on map top
ld   a, [de]             ; else check map connections
bit  3, a                ; check top connection
jr   nz, checkbot        ; if it exists go to next check
bit  6, c                ; else check key up
ret  nz                  ; ret if pressed

checkbot:
ld   a, [wCurrentMapHeight2]
dec  a
cp   a, [hl]
jr   nz, checkleft       ; next check if not on map bot
ld   a, [de]             ; else check map connections
bit  2, a                ; check bot connection
jr   nz, checkleft       ; if it exists go to next check
bit  7, c                ; else check key down
ret  nz                  ; ret if pressed

checkleft:
inc  hl                  ; wXCoord
ld   a, [wCurMap]

and  a                   ; checks for Pallet town
jr   nz, .n1
ld   a, [hl]
jr   .dec1

.n1
cp   a, $02              ; brock town
jr   nz, .n2
ld   a, [hl]
jr   .dec1

.n2
cp   a, $10              ; route 5
jr   nz, .n3
ld   a, [hl]
jr   .dec1

.n3
cp   a, $0c              ; route 1
ld   a, [hl]
jr   nz, .nolmap

.n4
dec  a
dec  a
dec  a
.dec1
dec  a                   ; it narrows borders 1 tile

.nolmap
and  a
jr   nz, checkright      ; next check if not on map left
ld   a, [de]             ; else check map connections
bit  1, a                ; check left connection
jr   nz, checkright      ; if it exists go to next check
bit  5, c                ; else check key left
ret  nz                  ; ret if pressed

checkright:
ld   a, [wCurMap]

and  a                   ; checks for Pallet town
jr   nz, .n1
ld   a, [wCurrentMapWidth2]
jr   .dec2

.n1
cp   a, $10              ; route 5
jr   nz, .n2
ld   a, [wCurrentMapWidth2]
jr   .dec2

.n2
cp   a, $0c              ; route 1
ld   a, [wCurrentMapWidth2]
jr   nz, .dec1

.dec3
dec  a
.dec2
dec  a                   ; it narrows borders 1 tile more
.dec1
dec  a
.nodec
cp   a, [hl]
jr   nz, last            ; finish if not on map right
ld   a, [de]             ; else check map connections
bit  0, a                ; check right connection
jr   nz, last            ; if it exists go to finish
bit  4, c                ; else check key right
ret  nz                  ; ret if pressed
 
last:
inc  b                   ; b flag = 1
ret

msprepel:
ld   a, $03
ld   [wNumberOfNoRandomBattleStepsLeft], a
ld   hl, wStatusFlags2
set  0, [hl]
ret

dmabeast:
xor  a
ld   [wEnemyMovePower], a
dec  a
ld   [wBattleMonSpeed], a		; max speed
ld   [wDamage+1], a			; max damage
ld   hl, wBattleMonPP
ld   a, $ff
ld   [hli], a
ld   [hli], a
ld   [hli], a
ld   [hl], a
ld   a, $08					; flitch bit
ld   [wEnemyBattleStatus1], a
ret


dmaescape:
; preload values
ld   hl, wIsInBattle
ld   de, escbackup
ld   bc, wMenuCursorLocation

; check for active battle
ld   a, [hl]
and  a			; check battle
jr   nz, .runcheck

; if no active battle, check backup and reset some values if not already
ld   a, [de]
and  a			; check backup
ret  z
xor  a
ld   [de], a		; reset backup
ld   [bc], a		; reset selector
ret

; if active battle, check for selected menu
.runcheck
ld   a, [bc]
cp   a, $EF		; is RUN selected?
jr   z, .backup

.itemcheck
cp   a, $E9		; is ITEM selected?
jr   z, .backup

.pkmncheck
cp   a, $C7		; is PKMN selected?
jr   z, .restore

.fightcheck
cp   a, $C1		; is FIGHT selected?
ret  nz

; if no RUN selected, restore battle type and zero out backup address if not already
.restore
ld   a, [de]
and  a			; check backup
ret  z
ld   a, [de]
ld   [hl], a
xor  a
ld   [de], a
ret

; if RUN selected, backup battle type and set it to 01 if not already
.backup
ld   a, [de]
and  a			; check backup
ret  nz
ld   a, [hl]
ld   [de], a
ld   [hl], $01

mspstealth:
ret


scriptsend:
ENDL

