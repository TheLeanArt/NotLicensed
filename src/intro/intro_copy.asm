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

	ld hl, STARTOF(VRAM) | T_INTRO_NOT_2 << 4
	ld de, TopTiles.n
	ld bc, $FF00               ; Bitplane 1 only
	call Copy1bppEven          ; Copy top N
	ld c, b                    ; Set bitplane 0
	call Copy1bppOdd           ; Copy top T
	ld e, LOW(ByTiles.b)
	ld b, a                    ; Clear bitplane 1
	call Copy1bppEven          ; Copy B
	ld e, LOW(TopTiles.l)
	ld b, c                    ; Set bitplane 1
	ld c, a                    ; Clear bitplane 0
	call Copy1bppOdd           ; Copy L
	ld e, LOW(ByTiles.y)
	call Copy2bppEven          ; Copy Y
	call FillSafe              ; Clear the last tile in the 1st row
	COPY_1BPP_PRE_SAFE Top     ; Copy ® + top tiles
	ld hl, STARTOF(VRAM) | T_INTRO_TOP_O << 4
	COPY_1BPP_SAFE TopO        ; Copy top O tiles

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


SECTION "Copy1bpp", ROM0[$28]
Copy1bpp:
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	and c                      ; Filter bitplane 0
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	and b                      ; Filter bitplane 1
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	ret


SECTION "Copy2bppEven", ROM0
Copy2bppEven:
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	bit 4, l                   ; Odd tile address reached?
	jr z, Copy2bppEven         ; If not, continue looping
	ret


SECTION "Copy1bppEven", ROM0
Copy1bppEven:
	rst Copy1bpp               ; Copy row
	bit 4, l                   ; Odd tile address reached?
	jr z, Copy1bppEven         ; If not, continue looping
	ret


SECTION "Copy1bppOdd", ROM0
Copy1bppOdd:
	rst Copy1bpp               ; Copy row
	bit 4, l                   ; Even tile address reached?
	jr nz, Copy1bppOdd         ; If not, continue looping
	ret


SECTION "FillSafe", ROM0
FillSafe:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	bit 4, l                   ; Even tile address reached?
	jr nz, FillSafe            ; If not, keep looping
	ret


SECTION "Intro Tile data", ROM0, ALIGN[8]
ByTiles:
.b
FOR I, 0, 16, 2
	INCBIN "intro_by.2bpp", I, 1
ENDR
.y
	INCBIN "intro_by.2bpp", 16, 16

TopTiles:
.n
	INCBIN "intro_top_n.1bpp"
.t
	INCBIN "intro_top_t.1bpp"
.l
	INCBIN "intro_top.1bpp"
	INCBIN "intro_reg.1bpp"
.end

TopOTiles:
	INCBIN "intro_top_o.1bpp"
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
