/*

BBMenu file 1 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"


def newpokemonstackret = $6724


SECTION "BBMenuY1", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
Installer:
ld   a, $01
call OpenSRAM

; move NicknameWriter into TimOS
ld   c, $41                   ; 65 bytes
ld   de, nickwriterdest       ; destination
push de
ld   hl, MSPhijack            ; origin
push hl
call CopyMapConnectionHeaderloop

; move main payload in unused memory $d669
ld   c, flagsend - MSPhijack
pop  de
ld   hl, .end
call CopyMapConnectionHeaderloop

; move OAM hijack + BBMenu Loader + scripts into SRAM Bank 1
ld   c, sramlength
ld   de, sramcopy             ; destination
call CopyMapConnectionHeaderloop

ld   hl, nickwriterpointer    ; change nickname writer pointer inside timos
pop  de                       ; restore new nickwriter address
ld   [hl], e
inc  hl
ld   [hl], d

.end
ENDL
 

LOAD "MSP_hijack", WRAMX[wunused]
;;;;;;;;;;;; Executed by MSP hijack ;;;;;;;;;;;;
MSPhijack:
; $d669 - executed by MapScript after loading the game
; it checks if TimOS Loader payload is present
ld   a, [stackend-1]          ; last byte of stack payload
cp   a, $d9                   ; reti instruction
jr   z, .mspcodebox

; if stack payload is corrupted, it is rebuilded along with OAM DMA hijack
di                            ; interrupts are disabled since we mess with dma stuff
call opensram1

; copy 4 bytes to hijack dma
ld   c, $04                   ; 4 bytes to be copied to ff80 earlier set to de
ld   de, hDMARoutine          ; destination
ld   hl, sramcopy             ; from SRAM 1
call CopyMapConnectionHeaderloop 

; copy codebox kernel to df15
ld   c, stackend-stackstart
ld   de, topstack             ; to the top of the stack
call CopyMapConnectionHeaderloop

; closes SRAM
call CloseSRAM

; checks and initialises map if unused room is detected in place of HoF
ld   hl, wCurMap              ; 00=Pallet town, 76=HoF room, 0b=unused
ld   a, [hl]
cp   a, $0b                   ; if unused room is detected
jr   nz, .endcp 	
ld   [hl], $76                ; set room back to HoF
ld   sp, $e003                ; underflow sp
ld   hl, MainMenupressedA
jp   bankswitch1

.endcp
ei

.mspcodebox
ldh  a, [boxflag]             ; custom HRAM flag
and  a
call z, codeboxon             ; if flag is 0, code box is loaded and a is used

call mspayloads               ; payloads always run before menuloader, since they can trigger codebox change

call menuloader               ; BBMenu loader checks are in code box, always loaded before this runs


.curmsp	
jp   safejump                 ; a safe jump address to be replaced automatically by msp manipulator

.end

;;;;;;;;;;;; Executed by OAM DMA hijack ;;;;;;;;;;;; 
DMAhijack:
; $d6a3
; MSP Manipulator - It checks and sets Map Script Pointer after backing up the original one

; Preload addresses
ld   hl, wCurMapScriptPtr+1
ld   de, MSPhijack.curmsp+2   ; Original MSP backup address+1 - $d6a3

; checks if MSP is hijacked
ld   a, d                     ; Custom wCurMapScriptPtr high byte check
cp   a, [hl]                  ; Compares current to custom pointer
jr   z, .dmacodebox

; room checking to bypass HoF reset
ld   bc, wCurMap              ; 00=Pallet town, 76=HoF room, 0b=unused
ld   a, [bc]
cp   a, $76                   ; if wCurMap = HoF
jr   nz, .backup
ld   a, [wLetterPrintingDelayFlags]
and  a                        ; check if text is active
jr   nz, .dmacodebox          ; if 0 do following
ld   a, $0b                   ; set wCurMap to unused id
ld   [bc], a

; hijacks MSP
.backup
ld   a, [hl-]
ld   [de], a
dec  de
ld   a, [hl]
ld   [de], a
ld   a, low(wunused)
ld   [hl+], a
ld   [hl], d                  ; d669

; payloads = 35 bytes can be moved in box data
.dmacodebox
ldh  a, [boxflag]             ; check if codebox is active
and  a
jr   z, .endoam               ; if not skip payload execution

call dmapayloads

call boxmanager               ; initiate checks to diable codebox
dec  b
call nz, codeboxoff           ; disable codebox if trigger point detected

; setting return values for OAM DMA routine
.endoam
ld   c, $46
ld   a, $c3
ret	

;;;;;;;;;;;; Bank Change function ;;;;;;;;;;;; 
; opensram1:
xor  a

; opensramplus1:
inc  a
jp   OpenSRAM

flagsend:
ENDL
	  

;;;;;;;;;;;; OAM hijack payload ;;;;;;;;;;;;
dmajack:
call DMAhijack                ; if initial payload changes, change address acordingly
ld   [c], a                   ; setup to trigger stock OAM payload


LOAD "boxselector", WRAMX[topstack]
stackstart:

;;;;;;;;;;;; Box selector scripts ;;;;;;;;;;;;
; check of pokebox is active
codeboxoff:                   ; 23 bytes
xor  a
ldh  [boxflag], a             ; reset custom flag
; open poke box
inc  a                        ; a = 1
call opensramplus1            ; opens sram for a = 1+1=2
ld   bc, $0460                ; 1120 bytes
ld   de, wBoxSpecies          ; destination
ld   hl, srampokebuffer       ; origin
call CopyData                 ; restores poke box
jp   opensram1                ; while saving bank 1 needs to be open

; codeboxon:                    ; 39 bytes
di
ld   [wSaveFileStatus], a     ; always reset save flag, a=0 from call point
inc  a                        ; a is always 0 when function called
ldh  [boxflag], a
call opensramplus1            ; sram bank 2
ld   bc, $0460                ; 1120 bytes
ld   de, srampokebuffer       ; destination
ld   hl, wBoxSpecies          ; origin
push bc
push hl
call CopyData                 ; back ups active poke box
call opensram1 
pop  de
pop  bc
ld   hl, scodebox             ; origin
call CopyData                 ; restores code box
call CloseSRAM
reti

stackend:
ENDL

LOAD "payloads", WRAMX[wBoxSpecies]
; box area is reserved for constant msp and dma payloads

codeboxstart:
;;;;;;;;;;;; Box Manipulation payload ;;;;;;;;;;;;
; Loaded from SRAM1 $bb80 to $da80 automatically with map script pointer
boxmanager:                   ; checks if mon box should be loaded
ld   b, $02                   ; to set boxflag

; if saving check
ld   a, [wSaveFileStatus]     ; saving flag 
cp   a, b                     ; can be set safely. MSP will reset it anyways while in OW
ret  z

; if new pokemon check
ld   hl, sp+$1c               ; inspect stack - if givepokemon is active
ld   a, [hl+]
cp   a, low(newpokemonstackret)
jr   nz, .flagcheck
ld   a, [hl]
cp   a, high(newpokemonstackret)
ret  z

; if PC active check
.flagcheck
ld   a, [wMiscFlags]          ; active pc
bit  3, a
ret  nz

; if pokemon catching check
ld   a, [wEnemyBattleStatus3]	; catching flag
and  a, $08
ret  nz

dec b                         ; to unset boxflag
ret


;;;;;;;;;;;; BBMenu Loader payload ;;;;;;;;;;;;
; This part checks and loads BBMenu when select is pressed in Overworld, run by MSP
menuloader:
; Read select button state - It automatically skips false positives like in start menu
ldh  a, [hJoyPressed]         ; Read buttons
bit  2, a                     ; Compare to select button [bit2]
ret  z                        ; If select not pressed, stop executing

ldh  a, [hLoadedROMBank]      ; Saves hLoadedROMBank
push af

call SaveScreenTilesToBuffer1 ; to not break graphics in backround

xor  a
call StopMusic
ld   c, $1f                   ; Bank with sound
ld   a, $9d                   ; BlipBlop sound
call PlayMusic

call opensram1

ld   bc, $01f3                ; 499 bytes
ld   de, wOverworldMap        ; destination
ld   hl, smenu                ; origin
call CopyData

call CloseSRAM

ld   hl, gamesel
push hl
call savesel

call wOverworldMap            ; Activated only when BBMenu is triggered

pop  hl
call loadsel

call ReloadMapAfterPrinter    ; reload map after closing BBMenu

ld   hl, hljump               ; We set hl to static address to continue execution after CloseTextDisplay
push hl
call CloseTextDisplay

hljump:
pop  af                       ; Restores saved rom bank
ldh  [hLoadedROMBank], a 

jp   PlayDefaultMusic

;;;;;;;;;;;; Box MSP payloads ;;;;;;;;;;;;
mspayloads:
ld   hl, msptable
ld   a, [mspflags]
jr   tablecommon
	
;;;;;;;;;;;; Box DMA payloads ;;;;;;;;;;;;
dmapayloads:
ld   hl, dmatable
ld   a, [dmaflags]

tablecommon:
ld   b, a                     ; load flags to b temp register
ld   c, $08                   ; 8 bits to rotate
tableloop:
ld   a, c                     ; load current bit checking number to a
dec  a
rlc  b                        ; rotate to check current selected bit
call c, CallFunctionInTable
dec  c                        ; dec counter every time loopruns
jr   nz, tableloop
ret

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

	
codeboxend:
ENDL

def  sramlength = 4+stackend-stackstart+codeboxend-codeboxstart
def  msptable   = dmatable+16
