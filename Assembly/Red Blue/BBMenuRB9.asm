/*

BBMenu file 9 - Compatible with EN RED/BLUE ONLY


Source is compiled with RGBDS
*/

include "pokered.inc"
include "bbmenuRB.inc"
include "charmap.inc"

def dmashiny        = $dc72
def sdmashiny       = $dc72-boxoffset
DEF SHINY_ATK_MASK EQU %0010
DEF SHINY_DEF_DV EQU 10
DEF SHINY_SPD_DV EQU 10
DEF SHINY_SPC_DV EQU 10

SECTION "BBMenuRB9", ROM0

start:
LOAD "Installer", WRAMX[nicknameaddress]
;;;;;;;;;;;; Installer payload ;;;;;;;;;;;; 
installer:

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
ld a, [wIsInBattle]
and a
call z, .statusCheck ; jump to status check if not in battle

.battle
	; Battle has been confirmed
	; Check wTilemap tile for opponent HUD ('HP' tile)
	ld hl, $C3CA 
	ld a, [hl]
	cp $71				; 'HP'
	ret nz 				; Return if HUD isn't present

	; Check if '!' already exists
	ld hl, $C3B4
	ld a, [hl]
	cp $E7 				; '!'
	ret z 				; Return if true

	ld hl, wEnemyMonDVs
	ld bc, $C3B4 		; Store position for '!'
	call .shinyCheck
	ret

.statusCheck
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
	ld bc, $C3E5 		; Store position for '!'
	call .shinyCheck
	ret

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
    ld l, c
    ld h, b
    ld [hl], $E7 ; !
    ret


scriptsend:
ENDL

