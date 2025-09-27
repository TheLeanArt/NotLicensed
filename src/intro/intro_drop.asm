; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "intro.inc"


SECTION "Intro Drop LUT", ROM0, ALIGN[8]

IntroDropLUT::

.SCY

FOR T, 0, 64
	db 64 - ((T * T) / 64 - 4)
ENDR
	db 0, 1, 2, 2, 1, 0

	ds 128 - LOW(@ - .SCY), 0

.WY

	ds 64, Y_INTRO_TOP

	db Y_INTRO_TOP + 0
	db Y_INTRO_TOP + 1
	db Y_INTRO_TOP + 3
	db Y_INTRO_TOP + 4
	db Y_INTRO_TOP + 4
	db Y_INTRO_TOP + 3
	db Y_INTRO_TOP + 1
	db Y_INTRO_TOP + 0

	ds 128 - LOW(@ - .WY), Y_INTRO_TOP

ASSERT (LOW(@) == 0)

.regY

FOR T, 0, INTRO_REG_START
	db Y_INTRO_REG
ENDR
	db Y_INTRO_REG + 0
	db Y_INTRO_REG + 1
	db Y_INTRO_REG + 3
	db Y_INTRO_REG + 4
	db Y_INTRO_REG + 4
	db Y_INTRO_REG + 3
	db Y_INTRO_REG + 1
	db Y_INTRO_REG + 0

FOR T, 0, 128 - INTRO_REG_DROP_START
	db Y_INTRO_REG + T / 2 + (T * T) / 27
ENDR

ASSERT (LOW(@) == 128)

.regX

FOR T, 0, INTRO_REG_DROP_START
	db X_INTRO_REG
ENDR

FOR T, 0, 128 - INTRO_REG_DROP_START
	db X_INTRO_REG + T / 2
ENDR

ASSERT (LOW(@) == 0)
