/*

BBMenu file 6 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"
include "charmap.inc"


def sinstall2       = wblock-block2offset

def nicknameaddress = $d8b4
def stacktrainer    = $dfe3
def returntrainer   = DisplayListMenuIDLoop+6



SECTION "BBMenuY6", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

call opensram1

ld   c, menupointersend - menupointers
ld   de, slistable+28              ; destination
ld   hl, menupointers              ; installer origin
call CopyMapConnectionHeaderloop

ld   bc, mapend2 - mapstart2
ld   de, sinstall2                 ; destination
call CopyData


; closes SRAM
jp   CloseSRAM

; ----------- Menu pointers ------------
menupointers:           ; it automatically calculates every script's starting point offsets
db low(trainers),   high(trainers)
db low(instant),    high(instant)
db low(filldex),    high(filldex)
db low(allbadges),  high(allbadges)
db low(makeitrain), high(makeitrain)
db low(allcoins),   high(allcoins)
db low(duplicator), high(duplicator)
menupointersend:

ENDL



LOAD "mapdata2", WRAM0[wblock]
mapstart2:

;;;;;;;;;;;; Trainers+ payload ;;;;;;;;;;;;
trainers:
ld   de, listaddress     ; list of menu id is created by the end of the script
ld   b, 47               ; how many options will be loaded
ld   a, b
call createmenulist
ld   a, $56              ; 1F items id has a small name = quicker code execution without graphical glitches

buildloop:               ; builds item list
inc  de
ld   [de], a
dec  b
jr   nz, buildloop
inc  de
ld   a, $ff              ; adds cancel item at the end of the list
ld   [de], a             ; it is ff anyway, no need to make it

; predefs menu settings
call initmenulist

ld   [wListScrollOffset], a   ; initialize list items position
ld   a, $04
ld   [wListMenuID], a    ; wListMenuID = 4

hijack:
ld   de, dmatrainers
call enabledmaspare

call DisplayListMenuID   ; script's menu is fired

; unloads dma hijack
call resetdmaspare

; setting up stack to return
ld   hl, sp+10           ; calfunctionintable pushes some values into the stack, so we change sp to jump back
ld   sp, hl

and  a, a	               ; reads list menu button
jp   z, wOverworldMap+6  ; exits if B is pressed

presseda:
ld   a, $01
ld   [wEngagedTrainerSet], a  ; wEngagedTrainerSet = 1
call calcselect
add  a, $c8
jp   InitBattleEnemyParameters+3


dmatrainers:             ; we check specific addresses in stack to detect the address
ld   hl, stacktrainer    ; HandleMenuInput is going to return to
ld   bc, returntrainer
ld   de, trainerhijack
jp   stackhijack

trainerhijack:           ; when HandleMenuInput finishes execution it jumps to this script instead
; loop that calculates correct address for display names

ld   de, wNameBuffer     ; origin
ld   hl, $c3f6           ; destination tile - first letter of menu
ld   a, [wListScrollOffset]   ; it shows how many times the list has scrolled downwards
inc  a
ld   c, a                ; wListScrollOffset

; loop that overwrites list names
ld   b, $04              ; 4 lines to be replaced

.loopline  
push de                  ; saves wNameBuffer
push hl                  ; saves initial tile for later
ld   a, c                ; wListScrollOffset
ld   [wTrainerClass], a

cp   a, 48               ; if list ended, skip loading names
jr   nc, .endloop
cp   a, 25               ; replace name 25 with rival's
jr   z, .rival
and  a, %11111110        ; combines 42 and 43 by clearing bit 0
cp   a, 42               ; replace name 42 or 43 with rival's
jr   nz, .aftercheck

.rival
ld   de, wRivalName
jr   .loopletter
.aftercheck
push bc                  ; b: lines remaining, c: wListScrollOffset
call GetTrainerName      ; other registers are the same
pop  bc
pop  hl                  ; initial tile
pop  de                  ; wNameBuffer
push de
push hl                  ; saves initial tile for later

; fetches text replacement
.loopletter
ld   a, [de]
inc  de
cp   a, $50              ; if @
jr   z, .endloop         ; stops execution without writing char
ld   [hli], a            ; else write char and repeat
jr   .loopletter

.endloop
pop  hl                  ; restores first tile
ld   de, $0028           ; tiles to be added
add  hl, de              ; calculates next line
pop  de                  ; restores wNameBuffer address
inc  c                   ; wListScrollOffset + 1
dec  b                   ; subtracts 1 line from the counter
jr   nz, .loopline       ; are remaining lines 0?

endjp:
jp   returntrainer


;;;;;;;;;;;; Instant Text  ;;;;;;;;;;;;
instant:
ld   de, menu17txt
call verify
ret  nz
ld   hl, wOptions
ld   a, [hl]
and  a, $f0
ld   [hl], a
ret


;;;;;;;;;;;; Common verify payload  ;;;;;;;;;;;;
verify:
ld   hl, wNameBuffer
call CopyString
ld   a, SoYouWantPrizeTextPtr_Bank
call BankswitchHome
ld   hl, SoYouWantPrizeTextPtr
call PrintText
call YesNoChoice
call BankswitchBack
ld   a, [wCurrentMenuItem]
and  a
ret  nz
call WaitForSoundToFinish
ld   a, 178
jp   PlaySound                     ; Play the sound


;;;;;;;;;;;; All Pokemon  ;;;;;;;;;;;;
filldex:
ld   de, menu18txt
call verify
ret  nz
ld   hl, wPokedexOwned
ld   e, $02
.loop
ld   bc, $0012
ld   a, $ff
call FillMemory  ;; Set BC bytes of A starting from address HL
ld   a, $7f
ld   [hli], a
dec  e
jr   nz, .loop
ret


;;;;;;;;;;;; All Badges  ;;;;;;;;;;;;
allbadges:
ld   de, menu19txt
call verify
ret  nz
ld   a, $ff
ld   [wObtainedBadges], a
ret


;;;;;;;;;;;; Max Money  ;;;;;;;;;;;;
makeitrain:
ld   de, menu20txt
call verify
ret  nz
ld   hl, wPlayerMoney
ld   a, $99
ld   [hli], a
ld   [hli], a
ld   [hl], a
ret


;;;;;;;;;;;; Max Coins  ;;;;;;;;;;;;
allcoins:
ld   de, menu21txt
call verify
ret  nz
ld   hl, wPlayerCoins
ld   a, $99
ld   [hli], a
ld   [hl], a
ret


;;;;;;;;;;;; Dumplicate Pokemon  ;;;;;;;;;;;;
duplicator:
; check if there are at least 2 pokemon in party
ld   de, menu22txt
call verify
ret  nz
ld   a, [wPartyCount]
cp   a, $02
ret  c

; transfer pokemon id
ld   hl, wPartySpecies	     ; poke 1 id
ld   a, [hli]
ld   [hl], a			     ; hl = $d164

ld   c, $2c		          ; poke data length
ld   de, wPartyMon2	          ; poke 2 data
ld   l, low(wPartyMon1)	     ; $6a - poke 1 data
call CopyMapConnectionHeaderloop   ; transfer pokemon data

ld   de, wPartyMon1Nick		; poke 1 nickname
ld   hl, wPartyMon2Nick		; poke 2 nickname
jp   CopyString               ; transfer pokemon nickname

mapend2:

ENDL

