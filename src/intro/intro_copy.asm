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
	ld hl, STARTOF(VRAM) | T_INTRO_REG << 4
ENDC
	COPY_1BPP_PRE_SAFE Top     ; Copy ® + top tiles
	ret


SECTION "Intro Tile data", ROM0, ALIGN[8]
TopTiles2:
	INCBIN "intro_not.2bpp"
	INCBIN "intro_top_0.2bpp"
	INCBIN "intro_by.2bpp"
.end

TopTiles:
	INCBIN "intro_reg.1bpp"
	INCBIN "intro_not.1bpp"
	INCBIN "intro_top.1bpp"
	INCBIN "intro_by.1bpp"
.end
