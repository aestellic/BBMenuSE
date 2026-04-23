/*

BBMenu file 10 - Compatible with EN RED/BLUE ONLY


Source is compiled with RGBDS
*/

include "pokered.inc"
include "bbmenuRB.inc"

SECTION "BBMenuRB10", ROM0

start:
ld hl, dmaflags
set 4, [hl]	; enable dmashiny