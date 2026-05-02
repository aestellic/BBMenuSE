/*

BBMenu file 4 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"
include "charmap.inc"


def wcommon     = $c86a
def scommon    = smenulist-112


SECTION "BBMenuY4", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

call opensram1

ld   c, menupointersend - menupointers
ld   de, slistable                 ; destination
ld   hl, menupointers              ; installer origin
call CopyMapConnectionHeaderloop

; move scripts into map data
ld   c, commonend - commonstart
ld   de, scommon                   ; destination
call CopyMapConnectionHeaderloop

; move scripts into map data
ld   bc, mapend - mapstart
ld   de, sblock1                   ; destination
call CopyData

; closes SRAM
jp   CloseSRAM


; ----------- Menu pointers ------------
menupointers:       ; it automatically calculates every script's starting point offsets
db low(credits),    high(credits)
db low(run),        high(run)
db low(slip),       high(slip)
db low(rep),        high(rep)
db low(god),        high(god)
db low(escape),     high(escape)
db low(stealth),    high(stealth)
db low(flier),      high(flier)
db low(healer),     high(healer)
db low(anypc),      high(anypc)
db low(items),      high(items)
menupointersend:

ENDL

LOAD "commondata", WRAM0[wcommon]
commonstart:

;;;;;;;;;;;; Script common payloads  ;;;;;;;;;;;;
createlistcommon:                  ; call it as createmenulist
ld   hl, wListPointer              ; list header is stored
ld   [hl], e
inc  hl
ld   [hl], d
ld   [de], a
ret

resetsparecommon:                  ; call it as resetdmaspare
ld   hl, dmaflags
res  7, [hl]                       ; disables temp dma flag
ret

initlist:                          ; call initmenulist
xor  a
ld   [wPrintItemPrices], a
ld   [wCurrentMenuItem], a
ret

calcselection:                     ; call it as calcselect
ld   hl, wListScrollOffset
ld   a, [hl]
ld   l, low(wCurrentMenuItem)
add  a, [hl]                       ; calculates selected item
inc  a
ret
commonend:

ENDL


LOAD "mapdata", WRAM0[wblock]
mapstart:

;;;;;;;;;;;; BBMenu Credits ;;;;;;;;;;;;
credits:
ld   c, $1f       	          ; Bank with sound
ld   a, $98       	          ; BlipBlop sound
call PlayMusic

ld   hl, text                 ; address to print text from
jp   PrintText
text:
db   $00                      ; TX_START
db   "Made with love"
db   $4f                      ; new line
db   "by aestellic"
db   $57                      ; ends text

;;;;;;;;;;;; Enablers ;;;;;;;;;;;; 
; b: msp or dma flags, c: bbm flags
slip:
ld   bc, $0102

mspcommon:
ld   hl, mspflags
jr   common

rep:
ld   bc, $0204
jr   mspcommon

run:
ld   bc, $0201

; common function - 7 bytes
dmacommon:
ld   hl, dmaflags

common:
ld   a, [hl]
xor  a, b
ld   [hl], a
ld   l, low(bbmflags)
ld   a, [hl]
xor  a, c
ld   [hl], a
and  a, c
ld   a, $a2       	          ; Enable sound
jr   nz, .enable
ld   a, $9e       	          ; Disable sound
.enable
ld   c, $1f       	          ; Bank with sound
jp   PlayMusic


god:
ld   bc, $0408
jr   dmacommon


escape:
ld   bc, $0810
jr   dmacommon


stealth:
ld   hl, mspinstruction
ld   a, $c9
cp   a, [hl]
jr   nz, .set
.reset
ld   a, $c3
.set
ld   [hl], a
ld   bc, $0420
jr   mspcommon


;;;;;;;;;;;; Fly payload ;;;;;;;;;;;; 
flier:
call SaveScreenTilesToBuffer2

ld   hl, wTownVisitedFlag+1        ; set all fly locations
push hl
ld   a, [hld]
ld   b, a
ld   a, [hl]
ld   c, a
push bc
ld   a, $ff
ld   [hli], a
ld   [hl], a
call ChooseFlyDestination
pop  bc
pop  hl
ld   a, b
ld   [hld], a
ld   a, c
ld   [hl], a

ld   hl, sp+10                     ; callfunctionintable pushes some values into the stack, so we change sp to jump back
ld   sp, hl
call RunDefaultPaletteCommand
ld   a, [wStatusFlags7]
bit  7, a
ret  nz                            ; return to overworld and fly

goback:
call LoadScreenTilesFromBuffer2    ; restore saved screen
jp   wOverworldMap


;;;;;;;;;;;; Heal payload ;;;;;;;;;;;; 
healer:
ld   a, [wPartyCount]              ; aborts if no pokemon to avoid crash
and  a
ret  z
ld   c, $02                        ; sound bank 2
ld   a, $e8                        ; heal sound
call PlayMusic
call WaitForSoundToFinish          ; sound plays until the end, then the sound bank can change
ld   hl, HealParty
jp   bankswitch3


;;;;;;;;;;;; PC payload ;;;;;;;;;;;; 
anypc:
ld   hl, ActivatePC+3
call bankswitch5
ld   hl, sp+10                     ; calfunctionintable pushes some values into the stack, so we change sp to jump back
ld   sp, hl
xor  a                             ; a should be 0 to make codebox load properly
jp   codeboxon                     ; we need to re enable codebox if pokemon is sent to pc


;;;;;;;;;;;; ItemGiver+ payload ;;;;;;;;;;;; 
items:
ld   hl, giverselect               ; restores bbmenu's selector position
call loadsel

ld   de, listaddress
ld   a, $ae
call createmenulist

xor  a
.loop1
inc  a
inc  de
ld   [de], a
cp   a, $73                        ; list is stopped before glitch names appear
jr   nz, .loop1

ld   a, $c4                        ; list continues from HMs 

.loop2
inc  de
ld   [de], a
inc  a
and  a                             ; up to cancel item
jr   nz, .loop2

ld   hl, wPrintItemPrices	
ld   [hl+], a					; wListMenuID
ld   [hl], $04
dec  a                             ; $ff
ld   l, low(wMaxItemQuantity)
ld   [hl], a

reload:
call DisplayListMenuID
and  a, a	
jr   nz, cont                      ; end if B is pressed

ldh  a, [hJoyInput]
xor  a, $02                        ; so when B is pressed, a == 00
jr   z, exit

ld   hl, wNumBagItems			; checks for non zero items
ld   a, [hl]
and  a
jr   z, reload

dec  a                             ; removes last item in full quantity
ld   [hli], a
add  a, a
add  a, l
ld   l, a
ld   a, $ff
ld   [hl], a
call WaitForSoundToFinish
ld   a, $ab
jr   playsound

exit:
ld   hl, giverselect               ; restores bbmenu's selector position
call savesel
ld   hl, sp+10                     ; calfunctionintable pushes some values into the stack, so we change sp to jump back
ld   sp, hl
jp   wOverworldMap+6

cont:
call DisplayChooseQuantityMenu
and  a, a	
jr   nz, reload                    ; if B pressed reload menu
ld   hl, wItemQuantity
ld   c, [hl]                       ; b, c = id, quantity
ld   l, low(wCurItem)
ld   b, [hl]
call GiveItem
ld   a, $86                        ; Load the sound identifier [86 == levelup sound]
playsound:
call PlaySound      			; Play the sound

jr   reload                        ; reload menu



mapend:

ENDL


