; Adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)


include "hardware.inc"
include "common.inc"
include "defs.inc"
include "color.inc"
include "gradient.inc"


SECTION "WaitVRAM", ROM0[$30]
WaitVRAM::
	ldh a, [rSTAT]             ; Check the STAT register to figure out which mode the LCD is in
	and STAT_BUSY              ; AND the value to see if VRAM access is safe
	jr nz, WaitVRAM            ; If not, proceed to loop
	nop                        ; Wait for 1 M-cycle
	ret                        ; Return when VRAM access is safe


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
	push bc
	call hFixedOAMDMA
	jr STAT.cont


SECTION "STAT Vector", ROM0[$48]
STAT:
	push af
	push bc
	ldh a, [rLYC]
.cont
	ld b, a
	add GRADIENT_STEP
	ldh [rLYC], a
	rst WaitVRAM
	ld c, LOW(rBGPI)
	ld a, BGPI_AUTOINC
	ldh [c], a
	inc c
	ldh a, [hColorLow]
	ldh [c], a
	ld a, [hColorHigh]
	ldh [c], a
	ld a, b
	and $FE
	ld c, a
	ld b, HIGH(ColorLUT)
	ld a, [bc]
	ldh [hColorLow], a
	inc c
	ld a, [bc]
	ldh [hColorHigh], a
	pop bc
	pop af
	reti


SECTION "ColorLUT", ROM0, ALIGN[8]
ColorLUT:
FOR I, GRADIENT_LENGTH
	INTER_COLOR C_GRADIENT_TOP, C_GRADIENT_BOTTOM, GRADIENT_LENGTH, I
ENDR
REPT GRADIENT_PADDING
	dw C_GRADIENT_BOTTOM
ENDR


SECTION "CopyOAMDMA", ROM0
CopyOAMDMA::
	ld bc, (FixedOAMDMA.end - FixedOAMDMA) << 8 | LOW(hFixedOAMDMA)
	ld hl, FixedOAMDMA         ; Load the source address of our routine into HL
.loop
	ld a, [hli]                ; Load a byte from the address HL points to into the register A, increment HL
	ldh [c], a                 ; Load the byte in the A register to the address in HRAM with the low byte stored in C
	inc c                      ; Increment the low byte of the HRAM pointer in C
	dec b                      ; Decrement the loop counter in B
	jr nz, .loop               ; If B isn't zero, continue looping
	ret


SECTION "ClearOAM", ROM0
ClearOAM::
	xor a                      ; Set A to zero
	ld [hli], a                ; Set and advance
	ld a, l                    ; Load the lower address byte into A
	cp OAM_SIZE                ; End of OAM reached?
	jr nz, ClearOAM            ; If not, continue looping
	ret


SECTION "Fixed OAM DMA Subroutine", ROM0
FixedOAMDMA:
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


SECTION "Current Color", HRAM
hColorLow::
	db
hColorHigh::
	db


SECTION "Shadow OAM", WRAM0, ALIGN[8]
wShadowOAM::
	ds OAM_SIZE
