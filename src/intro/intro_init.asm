; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"


MACRO INTRO_TOP_INIT
DEF _ = (\1 - 1)
IF \1 && T_INTRO_TOP_\1 != T_INTRO_TOP_{d:_} + 1
	ld b, T_INTRO_TOP_\1       ; Load tile ID
ENDC
IF \1 && X_INTRO_TOP_\1 == X_INTRO_TOP_{d:_} + INTRO_TOP_NORM_WIDTH
	call SetNextTopObject      ; Set the next object
ELSE
	ld e, X_INTRO_TOP_\1       ; Load X coordinate
	call SetObject             ; Set the object
ENDC
ENDM


SECTION FRAGMENT "Intro", ROM0
Intro::

IF !DEF(INTRO_FADEIN_GBC)
	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	call nz, SetPalettes       ; If yes, set SGB palettes
ENDC

.initTop
	ld hl, wShadowOAM + OBJ_INTRO_TOP_0 * OBJ_SIZE
	ld bc, T_INTRO_TOP_0 << 8  ; Load tile ID and attributes
	ld de, Y_INTRO_INIT << 8 | X_INTRO_TOP_0
	call SetObject             ; Set the N object

FOR I, 1, INTRO_TOP_COUNT
	INTRO_TOP_INIT {d:I}
ENDR

	call ClearOAM              ; Clear the remaining shadow OAM
