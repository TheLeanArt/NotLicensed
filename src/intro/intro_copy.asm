; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"


SECTION "CopyIntro", ROM0
CopyIntro::
	ldh a, [rLY]               ; Read the LY register to check the current scanline
	cp SCREEN_HEIGHT_PX        ; Compare the current scanline to the first scanline of VBlank
	jr c, CopyIntro            ; Loop until the carry flag is set

IF DEF(COLOR8)
	ld hl, STARTOF(VRAM) | T_INTRO_NOT_2 << 4
	MEM_COPY TopTiles2
ELSE
	ld de, TopTiles
	ld hl, STARTOF(VRAM) | T_INTRO_NOT << 4
ENDC
	COPY_1BPP_PRE_SAFE Top     ; Copy ® + top tiles
IF T_INTRO_N0 == T_INTRO_E + 32
	ld bc, Intro2Tiles.end - Intro1Tiles
ELSE
	ld bc, Intro1Tiles.end - Intro1Tiles
	call CopyPre2Safe
	ld hl, STARTOF(VRAM) | T_INTRO_N0 << 4
	ld bc, Intro2Tiles.end - Intro2Tiles
ENDC
	; Fall through

CopyPre2Safe:
	rst WaitVRAM               ; Wait for VRAM to become accessible
REPT 2
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	xor a                      ; Clear the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
ENDR
	inc de                     ; Increment the source pointer in DE
	dec bc                     ; Decrement the loop counter in BC
	ld a, b                    ; Load the value in B into A
	or c                       ; Logical OR the value in A (from B) with C
	jr nz, CopyPre2Safe        ; If B and C are both zero, OR B will be zero, otherwise keep looping
	ret


SECTION "Intro Tile data", ROM0, ALIGN[8]
TopTiles2:
	INCBIN "intro_not.2bpp"
	INCBIN "intro_top_0.2bpp"
	INCBIN "intro_by.2bpp"
.end

TopTiles:
	INCBIN "intro_not.1bpp"
	INCBIN "intro_top.1bpp"
	INCBIN "intro_reg.1bpp"
	INCBIN "intro_by.1bpp"
.end

Intro1Tiles:
FOR I, 0, 256, 2
	INCBIN "intro_n.1bpp", I, 1
ENDR
FOR I, 0, 256, 2
	INCBIN "intro_e.1bpp", I, 1
ENDR
.end

Intro2Tiles:
FOR I, 0, 128, 2
	INCBIN "intro_n0.1bpp", I, 1
ENDR
FOR I, 0, 128, 2
	INCBIN "intro_d.1bpp", I, 1
ENDR
FOR I, 0, 128, 2
	INCBIN "intro_o.1bpp", I, 1
ENDR
FOR I, 0, 64, 2
	INCBIN "intro_i.1bpp", I, 1
ENDR
FOR I, 0, 64, 2
	INCBIN "intro_t.1bpp", I, 1
ENDR
.end
