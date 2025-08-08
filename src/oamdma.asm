; Adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)


include "hardware.inc"


SECTION "WaitVBlank", ROM0[$38]
WaitVBlank::
	halt                       ; Wait for interrupt
    ldh a, [rLY]               ; Read the LY register to check the current scanline
    cp SCREEN_HEIGHT_PX        ; Compare the current scanline to the first scanline of VBlank
	ret nc                     ; Return as soon as the carry flag is clear
	jr WaitVBlank              ; Proceed to loop otherwise


SECTION "VBlank Vector", ROM0[$40]
VBlank::
	push af
	call hFixedOAMDMA
	pop af
	reti


SECTION "Fixed OAM DMA Subroutine", ROM0

FixedOAMDMA::
	ld a, HIGH(wShadowOAM)
    ldh [rDMA], a
    ld a, OAM_COUNT
.loop
    dec a
    jr nz, .loop
    ret
.end::


SECTION "OAM DMA", HRAM

hFixedOAMDMA::
	ds FixedOAMDMA.end - FixedOAMDMA


SECTION "Shadow OAM", WRAM0, ALIGN[8]

wShadowOAM::
	ds OAM_SIZE
