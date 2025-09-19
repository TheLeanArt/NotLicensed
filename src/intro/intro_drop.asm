; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "intro.inc"


SECTION "Intro Drop LUT", ROM0, ALIGN[8]

IntroDropLUT::

.objY
FOR T, 0, 64
	db (T * T) / 64 + 4
ENDR
	db 72, 71, 70, 70, 71, 72

	ds 256 - LOW(@ - IntroDropLUT), 72

.SCY

FOR T, 0, 64
	db 64 - ((T * T) / 64 - 4)
ENDR
	db 0, 1, 2, 2, 1, 0

	ds 256 - LOW(@ - .SCY), 0

.WY

FOR T, 0, 64
	db 64
ENDR
	db 64, 65, 67, 68, 68, 67, 65, 64

	ds 256 - LOW(@ - .WY), 64

.regY

FOR T, 0, 64
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

FOR T, 0, 63
	db Y_INTRO_REG + T / 2 + (T * T) / 27
ENDR

	ds 256 - LOW(@ - .regY), Y_INTRO_INIT

.regX

FOR T, 0, 72
	db X_INTRO_REG
ENDR

FOR T, 0, 64
	db X_INTRO_REG + T / 2
ENDR

	ds 256 - LOW(@ - .regX), 0

.regTile:

	ds 64, T_INTRO_REG

FOR T, 64, 256
	db T_INTRO_REG + (T & 3)
ENDR

.regAttrs:

	ds 64, 0

FOR T, 64, 256
	db ((T & 4) >> 2) * (OAM_XFLIP | OAM_YFLIP)
ENDR

ASSERT (LOW(@) == 0)
