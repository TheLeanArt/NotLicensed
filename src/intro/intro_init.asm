; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"


SECTION FRAGMENT "Intro", ROM0
Intro::

IF !DEF(INTRO_FADEIN_GBC)
	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	call nz, SetPalettes       ; If yes, set SGB palettes
ENDC
