; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"


SECTION "CopyIntro", ROM0
CopyIntro::
IF DEF(COLOR8)
	ld de, TopTiles2
	ld hl, STARTOF(VRAM) | T_INTRO_NOT_2 << 4
	call CopyTopTriple
	ld l, LOW(T_INTRO_REG << 4) - 8
ELSE
	ld de, RegTiles
	ld hl, (STARTOF(VRAM) | T_INTRO_REG << 4 | $100) - 8
ENDC
	COPY_1BPP_TOP_PRE_SAFE Reg ; Copy the ® tiles
	ld l, LOW(T_INTRO_NOT << 4); Advance to the beginning of the next tile
	COPY_1BPP_TOP_PRE_SAFE Top ; Copy the top tiles
	COPY_0_5BPP_PRE_SAFE Intro2; Copy 0.5bpp tiles
	ret


SECTION "CopyTop", ROM0
CopyTopTriple::
	call CopyTopSingle         ; Copy the first tile
	; Fall through

CopyTopDouble::
	call CopyTopSingle         ; Copy the tile before last
	; Fall through

CopyTopSingle::
	ld b, TILE_SIZE            ; Set the loop counter
	ld a, l                    ; Load the value in L into A
	add b                      ; Add tile size
	ld l, a                    ; Load the result into L
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	dec b                      ; Decrement the inner loop counter
	jr nz, .loop               ; Stop if B is zero, otherwise keep looping
	ret

CopyTopPreSafe:
.loop1
	ld b, TILE_SIZE / 2        ; Set the loop counter
	ld a, l                    ; Load the value in L into A
	add b                      ; Add tile size
	add b                      ; ...
	ld l, a                    ; Load the result into L
.loop2
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	xor a                      ; Clear the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc de                     ; Increment the source pointer in DE
	dec b                      ; Decrement the inner loop counter
	jr nz, .loop2              ; Stop if B is zero, otherwise keep looping
	dec c                      ; Decrement the outer loop counter
	jr nz, .loop1              ; Stop if C is zero, otherwise keep looping
	ret


SECTION "Intro Tile data", ROM0, ALIGN[8]
TopTiles2:
	INCBIN "intro_not.2bpp"
	INCBIN "intro_top_0.2bpp"
.end

RegTiles:
	INCBIN "intro_reg.1bpp"
.end

TopTiles:
	INCBIN "intro_not.1bpp"
	INCBIN "intro_top.1bpp"
	INCBIN "intro_by.1bpp"
.end

Intro2Tiles:
FOR I, 0, 128, 2
	INCBIN "intro_n0.1bpp", I, 1
ENDR
FOR I, 0, 64, 2
	INCBIN "intro_i.1bpp", I, 1
ENDR
FOR I, 0, 64, 2
	INCBIN "intro_t.1bpp", I, 1
ENDR
FOR I, 0, 128, 2
	INCBIN "intro_d.1bpp", I, 1
ENDR
FOR I, 0, 128, 2
	INCBIN "intro_o.1bpp", I, 1
ENDR
FOR I, 0, 256, 2
	INCBIN "intro_n.1bpp", I, 1
ENDR
FOR I, 0, 256, 2
	INCBIN "intro_e.1bpp", I, 1
ENDR
.end

ByTiles::
	INCBIN "intro_by.2bpp"
