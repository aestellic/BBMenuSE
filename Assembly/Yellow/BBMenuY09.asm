/*

BBMenu file 9 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"
include "charmap.inc"

def dmashiny        = $dc71
def sdmashiny       = $dc71-boxoffset
DEF SHINY_ATK_MASK EQU %0010
DEF SHINY_DEF_DV EQU 10
DEF SHINY_SPD_DV EQU 10
DEF SHINY_SPC_DV EQU 10

SECTION "BBMenuY9", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

ld hl, RandomAdd
ld a, [hRandomAdd]
ld [hli], a
ld a, [hRandomSub]
ld [hl], a ; RandomSub

call opensram1

; move scripts into box data
ld   hl, end
ld   bc, scriptsend - scriptstart
ld   de, sdmashiny              ; destination
call CopyData

; closes SRAM
jp   CloseSRAM

end:

ENDL


LOAD "codebox", WRAMX[dmashiny]

scriptstart:
;;;;;;;;;;;; DMA payloads ;;;;;;;;;;;;

shiny:
call RandomDVs_

ld   a, [wIsInBattle]
dec  a
jr   z, .battle          ; wIsInBattle == 1, wild battle is active

inc  a
ret  nz                  ; end script if trainer battle - animation crashes the game

.statusCheck
    ; check for status screen if no battle at all
	; Perform two checks to confirm status screen is visible
	; First check for 'ID' then check for 'No.' to the right
	ld hl, $C4AE 		; VRAM Tile for ID
	ld a, [hli]
	cp $73 				; 'ID'
	ret nz 
	ld a, [hl]
	cp $74 				; 'No.'
	ret nz 				; Return if both checks fail, not in the status screen
	
	; Check wTilemap for '!'
	ld hl, $C3E5
	ld a, [hl]
	cp $E7 				; '!'
	ret z 				; Return if '!' already exists

	ld hl, wLoadedMonDVs
	jr .shinyCheck

.battle
	; Battle has been confirmed
	ld hl, $DFED
	ld b, HIGH(doBattleTransitionOffset)
	ld c, LOW(doBattleTransitionOffset)
	ld d, HIGH(.fixDVs)
	ld e, LOW(.fixDVs)
	call stackhijack

	ld hl, wEnemyMonDVs

.shinyCheck ; Ported from GSC
	; Attack
	ld a, [hl]
	and SHINY_ATK_MASK << 4
	ret z               ; Not shiny

	; Defense
	ld a, [hli]
	and %1111
	cp SHINY_DEF_DV
	ret nz              ; Not shiny

	; Speed
	ld a, [hl]
	and %1111 << 4
	cp SHINY_SPD_DV << 4
	ret nz              ; Not shiny

	; Special
	ld a, [hl]
	and %1111
	cp SHINY_SPC_DV
	ret nz              ; Not shiny

; Shiny (!)
.checkForAnimation
	; this checks if it should replace the animation pointer in the stack
	ld hl, $DFED
	ld b, HIGH(hideSprites)
	ld c, LOW(hideSprites)
	ld d, HIGH(.shinySoundEffect)
	ld e, LOW(.shinySoundEffect)
	call stackhijack

	; we need to run code depending on if stackhijack returned early
	ld hl, $DFED
	ld a, LOW(.shinySoundEffect)
	cp a, [hl]
	jr nz, .checkForAnimation_exit
	inc hl
	ld a, HIGH(.shinySoundEffect)
	cp a, [hl]
	jr nz, .checkForAnimation_exit

	; stackhijack did not return early
	ld a, $00
	ld [$FFF3], a ; set current turn to player's
	
.checkForAnimation_exit
	; Check wTilemap tile for opponent HUD ('HP' tile)
	ld hl, $C3CA 
	ld a, [hl]
	cp $71						; 'HP'
	jr nz, .statusCheck2		; Return if HUD isn't present

	; Check if '!' already exists
	ld hl, $C3B4
	ld a, [hl]
	cp $E7 						; '!'
	jr z, .statusCheck2		; Return if true

.battleAddIndicator
	ld bc, $C3B4
	ld l, c
	ld h, b
	ld [hl], $E7 ; !
	ret

.statusCheck2
	; Perform two checks to confirm status screen is visible
	; First check for 'ID' then check for 'No.' to the right
	ld hl, $C4AE 		; VRAM Tile for ID
	ld a, [hli]
	cp $73 				; 'ID'
	ret nz 
	ld a, [hl]
	cp $74 				; 'No.'
	ret nz 				; Return if both checks fail, not in the status screen

.statusAddIndicator
	ld bc, $C3E5
	ld l, c
	ld h, b
	ld [hl], $E7 ; !
	ret

.shinySoundEffect
    ld c, $1f ; bank
    ld a, ((SFX_Shooting_Star - SFX_Headers_1) / 3)
    call PlaySound

.shinyAnimation
	ld a, $1E
	call BankswitchHome
	ld a, $02
	ld hl, .animationData
	call animationLoop
	
	ld a, $0F
	call BankswitchHome
	jp hideSprites + 1

.animationData
    db $FD	; SE_DARK_SCREEN_PALETTE
    db $01
    db $41	; SUBANIM_1_STARS_SMALL_TOSS
    db $01
    db $3F
    db $E1	; SE_DELAY_ANIMATION_10
    db $01
    db $FC	; SE_RESET_SCREEN_PALETTE
    db $01
    db $FF	; terminator

.fixDVs
	; DVs have already been set by the time our DMA payload is called, so we need to regenerate and set them ourselves
	call RandomDVs_
	ld a, [RandomAdd]

	ld hl, wEnemyMonDVs
	ld [hli], a
	ld a, [RandomSub]
	ld [hl], a
	ld de, wEnemyMonLevel
	ld a, [wCurEnemyLevel]
	ld [de], a
	inc de
	ld b, $0
	ld hl, wEnemyMonHP
	push hl
	call CalcStats
	pop hl

	ld a, [wEnemyMonMaxHP]
	ld [hli], a
	ld a, [wEnemyMonMaxHP+1]
	ld [hli], a
	xor a
	inc hl
	ld [hl], a

	jp doBattleTransitionOffset

; for a full deep dive into gen 1 rng, see https://www.youtube.com/watch?v=BcIxMyf8yHY and/or https://www.dragonflycave.com/mechanics/gen-i-rng/

; the game uses 3 random calls to check if an encounter should start and to generate the DVs. 
; using more than 2 random calls successively without a naturally random amount of time passing (i.e. user input) causes the output of random to be limited by the results of the first 2 calls
; this limitation normally results in (65336 * encounterRate / 256) possible DV combinations (out of the 65536 total) being possible

; by recreating the random function, we can ensure that only 2 calls are used successively (1 every frame, 1 to generate the DVs)

RandomDVs_:
; Generate a random 16-bit value.
	ld a, [rDIV]
	ld b, a
	ld a, [RandomAdd]
	adc b
	ld [RandomAdd], a
	ld a, [rDIV]
	ld b, a
	ld a, [RandomSub]
	sbc b
	ld [RandomSub], a
	ret
RandomAdd:
	db
RandomSub:
	db

scriptsend:
ENDL

