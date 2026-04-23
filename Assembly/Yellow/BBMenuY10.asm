/*

BBMenu file 10 - Compatible with EN Yellow ONLY


Source is compiled with RGBDS
*/

include "pokeyellow.inc"
include "bbmenuY.inc"

SECTION "BBMenuY10", ROM0

start:
ld hl, dmaflags
set 4, [hl]	; enable dmashiny