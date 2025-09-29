; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"


SECTION FRAGMENT "Intro", ROM0

	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	ret z                      ; If not, return

	rst WaitVBlank             ; Wait for VRAM to become accessible
	ld b, 0                    ; Set B to zero
	call SetByAttrs            ; Clear attributes

IF DEF(INTRO_SONG)
	jp hUGE_dosound          ; Play sound
ELSE
	ret
ENDC
