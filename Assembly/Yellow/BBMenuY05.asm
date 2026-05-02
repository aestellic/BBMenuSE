/*

BBMenu file 5 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"
include "charmap.inc"


def stackteacher    = $dfe3
def returnteacher   = DisplayListMenuIDLoopnotOldManBattle+6

def stackgiver      = $dfd5
def returngiver     = ShowPokedexMenuexitPokedex-2
def dexbackup       = $d9e0        ; temp values go near the end of trainer battle, nnot saved

def winstall        = $ca2f
def sinstall        = winstall-block1offset


SECTION "BBMenuY5", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

call opensram1

ld   c, menupointersend - menupointers
ld   de, slistable+22              ; destination
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
db low(moves),      high(moves)
db low(dexgiver),   high(dexgiver)
db low(wilds),      high(wilds)
menupointersend:

ENDL

LOAD "mapdata", WRAM0[winstall]
mapstart:


;;;;;;;;;;;; Moves+ payload ;;;;;;;;;;;;
moves:
ld   de, dmateacher                     ; set and start temp dma payload for stack hijack
call bufferdmaspare

movesloop:
xor  a
ld   [wUpdateSpritesEnabled], a         ; enable moving sprites
ld   [wPartyMenuTypeOrMessageID], a     ; text id 0
call DisplayPartyMenu
ld   a, [wWhichPokemon]
ldh  [hbackup], a
jr   nc, createlist

movexit:
; unloads dma hijack and exit
call resetdmaspare
ld   hl, sp+10                ; calfunctionintable pushes some values into the stack, so we change sp to jump back
ld   sp, hl
call ClearScreen              ; Fill screen with 7F bytes = white tiles
call RestoreScreenTilesAndReloadTilePatterns
jp   wOverworldMap

createlist:
ld   de, listaddress          ; list header is stored for later
ld   a, $a3                   ; number of options
call createmenulist

inc  de

call initmenulist
ld   a, $01                   ; we start from move with id 1
ld   [wListMenuID], a         ; we need to set it to 0 with oam dma, when not scrolling      
inc  hl

.loop1
inc  a
ld   [de], a
inc  de
cp   a, $a6                   ; list is stopped before glitch names appear
jr   nz, .loop1

xor  a
ld   c, a
dec  a
ld   [de], a

call DisplayListMenuID
and  a
jr   z, movesloop             ; end if B is pressed

continue:
ldh  a, [hbackup]
ld   [wWhichPokemon], a
ld   hl, LearnMove
call bankswitch1
jr   movesloop                ; reload menu


dmateacher:                   ; we check specific addresses in stack to detect the address
ld   hl, stackteacher         ; static address DelayFrame ret address is stored
ld   bc, returnteacher
ld   de, teacherhijack
jp   stackhijack


teacherhijack:                ; when  HandlePokedexListMenu finishes execution it jumps to this script instead
bit  0, a                     ; if we detect A button pressed. A stays intact to be used in the rom code
jp   z, returnteacher         ; we jumpback to the original return point if A is not pressed

call calcselect               ; uses b internally, outputs selection in a

inc  a
ld   [wMoveNum], a
ld   [wNamedObjectIndex], a
call GetMoveName
jp   DisplayListMenuIDLoopstoreChosenEntry


;;;;;;;;;;;; DexGiver+ payload ;;;;;;;;;;;;
dexgiver:
ldh  a, [boxflag]             ; we check if codebox is off, just in case
and  a
jr   nz, .setflag             ; if a = 0, it is also used in codeboxon
call codeboxon                ; we need to re enable codebox if pokemon is sent to pc - codebox off

.setflag
ld   de, dmagiver
call bufferdmaspare           ; stack inspection is enabled
call dexhack                  ; common routine to preset dex data

dexexit:
jp LoadScreenTilesFromBuffer2 ; restore saved screen


dmagiver:                     ; we check specific addresses in stack to detect the address
ld   de, giverhijack
dmacommon:
ld   hl, stackgiver           ; static address DelayFrame ret address is stored
ld   bc, returngiver
jp   stackhijack


giverhijack:                  ; when  HandlePokedexListMenu finishes execution it jumps to this script instead
call pokelevel
ld   b, [hl]                  ; back ups wCurrentMenuItem for pokedex reload
push hl
push bc
call idfinder                 ; calculates poke id + id = b, lvl = c

call GivePokemon

ldh  a, [boxflag]             ; if boxflag = 0 mon was sent to pc
and  a
jr   nz, dexrestore           ; if a = 0, it is also used in codeboxon

call resetdmaspare
call codeboxon                ; re-enables codebox if pokemon is sent to pc (it disables and re-enable interrupts so there is no need to reset dmaflags bit7)

ld   de, dmagiver
call enabledmaspare           ; re-enables temp dma flag

dexrestore:                   ; restores currently selected pokemon
pop  bc
pop  hl
ld   [hl], b

dexreload:
call ClearScreen
jp   ShowPokedexMenusetUpGraphics


;;;;;;;;;;;; Wilds+ payload ;;;;;;;;;;;;
wilds:
ld   de, dmawilds
call bufferdmaspare

call dexhack

ldh  a, [hbackup]
and  a
jr   z, dexexit

ld   [wCurOpponent], a
ld   hl, sp+10                ; callfunctionintable pushes some values into the stack, so we change sp to jump back
ld   sp, hl
jp   RunDefaultPaletteCommand


dmawilds:                     ; we check specific addresses in stack to detect the address
ld   de, wildshijack
jr   dmacommon


wildshijack:
call pokelevel
call idfinder                 ; calculates and load pk id to b, lvl to c

ld   [wCurEnemyLevel], a      ; a left with pk lvl from earlier
ld   a, b                     ; b = pk id

giverend:
ldh  [hbackup], a             ; sets hram flag (zero if no pokemon, non zero for selected pokemon)
jp   returngiver+2


;;;;;;;;;;;; Common payloads ;;;;;;;;;;;;
pokelevel:
jr   c, .noret
pop  hl                       ; to restore stack balance
xor  a                        ; for hbackup if B was pressed
jr   giverend

.noret
ld   a, $64
ld   [wMaxItemQuantity], a 
call DisplayChooseQuantityMenu
and  a, a	
jp   z, calcselect            ; uses hl internally, outputs selection in a

pop  hl                       ; to restore stack balance
jr   dexreload                ; if B pressed reload menu

idfinder:
ld   [wPokedexNum], a
ld   b, $10
ld   hl, PokedexToIndex       ; changes pokedex id to pokemon id
call Bankswitch
ld   a, [wPokedexNum]
ld   b, a
ld   a, [wItemQuantity]
ld   c, a                     ; b = id, c = level
ret

dexhack:
; pokedex flags dexbackup
ld   hl, wPokedexSeen
ld   de, dexbackup
ld   c, $13
push de                       ; saves backup address for later
push bc                       ; saves data length
push hl                       ; saves seen address

push bc                       ; saves length again
push hl                       ; saves seen address again
call CopyMapConnectionHeaderloop

; pokedex flags setup for script
pop  hl                       ; restores seen address
pop  bc                       ; restores length
dec  bc                       ; we ff 1 byte less
xor  a
dec  a                        ; $ff, all bits set
call FillMemory               ; Set BC bytes of A starting from address HL
ld   [hl], $7f                ; last byte is set manually so 151 pokemon appear instead of 152

xor  a                        ; preset zero to return if nothing is selected
ld   [wCurPartySpecies], a

ld   b, $10                   ; ROM bank $10
ld   hl, ShowPokedexMenu      ; Loads pokedex menu routine
call Bankswitch

; unloads dma hijack after menu is closed
call resetdmaspare

; restores seen flags
pop  de
pop  bc
pop  hl                       ; dexbackup
push af
push bc                       ; bytes
push de                       ; seens start
call CopyMapConnectionHeaderloop

; merges seen with own
pop  hl                       ; hl = own end, de = seen end
pop  bc
.loop
dec  de
dec  hl
ld   a, [de]
or   a, [hl]
ld   [de], a
dec  c
jr   nz, .loop

pop  af
ret

mapend:

ENDL


