; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"


SECTION FRAGMENT "Intro", ROM0
CopyIntro:
	ld hl, STARTOF(VRAM) | T_INTRO_TOP_0_2 << 4
	ld de, TopTiles
	call Copy1bppPost          ; Copy dark top N0

	ld e, LOW(TopTiles)        ; Move back to start
	call Copy1bppSingle        ; Copy top N0
	call Copy1bppTriplet       ; Copy top T, L and I
	call Copy1bppPair          ; Copy top C and E1
	call Copy1bppTriplet       ; Copy top N, S and E2
	call Copy1bppSingle        ; Copy top D

	call Copy1bppPost          ; Copy B
	call FillSafe              ; Clear the odd tile after B
	call Copy2bppEven          ; Copy Y
	call FillSafe              ; Clear the odd tile after Y

	COPY_1BPP_SAFE Reg         ; Copy ® tiles

	call CopyTopOTiles         ; Copy top O tiles

	ld bc, IntroTiles.end - IntroTiles
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
REPT 4
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
ENDR
	inc de                     ; Increment the source pointer in DE
	dec bc                     ; Decrement the loop counter in BC
	ld a, b                    ; Load the value in B into A
	or c                       ; Logical OR the value in A (from B) with C
	jr nz, .loop               ; If B and C are both zero, OR B will be zero, otherwise keep looping


SECTION "Copy1bppSafe", ROM0
Copy1bppSingle:
	ld b, TILE_SIZE >> 1       ; Copy a single tile
	; Fall through

Copy1bppSafe:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc de                     ; Increment the source pointer in DE
	dec b                      ; Decrement the loop counter
	jr nz, Copy1bppSafe        ; Stop if B is zero, otherwise keep looping
	ret


SECTION "Copy1bppTriplet", ROM0
Copy1bppTriplet:
	call Copy1bppSingle
	; Fall through

Copy1bppPair:
	ld b, TILE_SIZE >> 1       ; Copy a single tile
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	xor a                      ; Clear the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	dec b                      ; Decrement the loop counter
	jr nz, .loop               ; Stop if B is zero, otherwise keep looping
	; Fall through

Copy1bppPost:
	ld b, TILE_SIZE >> 1       ; Copy a single tile
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	xor a                      ; Clear the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	dec b                      ; Decrement the loop counter
	jr nz, .loop               ; Stop if B is zero, otherwise keep looping
	ret


SECTION "Copy2bppEven", ROM0
Copy2bppEven:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	bit 4, l                   ; Odd tile address reached?
	jr z, Copy2bppEven         ; If not, continue looping
	ret


SECTION "FillSafe", ROM0
CopyTopOTiles:
	ld b, TopO2Tiles.end - TopO2Tiles
	call Copy1bppSafe          ; Copy the first nine tile, then clear one
	call Copy1bppDoubleAndFill ; Copy the next two tile, then clear one
	; Fall through

Copy1bppDoubleAndFill:
	call Copy1bppSingleAndFill ; Copy the next tile, then clear one
	; Fall through

Copy1bppSingleAndFill:
	ld b, TILE_SIZE >> 1       ; Copy a single tile
	; Fall through

Copy1bppAndFill:
	call Copy1bppSafe          ; Copy as black
	; Fall through

FillSafe:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	bit 4, l                   ; Even tile address reached?
	jr nz, FillSafe            ; If not, keep looping
	ret


SECTION "Intro Tile data", ROM0, ALIGN[8]
TopTiles:
	INCBIN "intro_top_n.1bpp"
	INCBIN "intro_top_t.1bpp"
IF DEF(EN_GB)
	INCBIN "intro_top.1bpp",  0, 40
	INCBIN "intro_top.1bpp", 16,  8
	INCBIN "intro_top.1bpp", 48
ELSE
	INCBIN "intro_top.1bpp"
ENDC

ByTiles:
FOR I, 0, 16, 2
	INCBIN "intro_by.2bpp", I + 1, 1
ENDR
	INCBIN "intro_by.2bpp", 16, 16

RegTiles:
	INCBIN "intro_reg.1bpp"
.end

TopO2Tiles:
	INCBIN "intro_top_o_2.1bpp"
.end

TopO1Tiles:
	INCBIN "intro_top_o_1.1bpp"
.end

IntroTiles:
	_0_5_BPP "intro_n.1bpp"
	_0_5_BPP "intro_e.1bpp"
	_0_5_BPP "intro_n0.1bpp"
	_0_5_BPP "intro_d.1bpp"
	_0_5_BPP "intro_o.1bpp"
	_0_5_BPP "intro_i.1bpp"
	_0_5_BPP "intro_t.1bpp"
.end
