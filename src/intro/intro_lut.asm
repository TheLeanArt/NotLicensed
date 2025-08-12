; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "intro.inc"


MACRO TOP_LUT

.y\@
FOR T, 0, 64
	db Y_INTRO_TOP - T
ENDR
	ds 64, 0

.x\@
FOR T, 0, 64
	db X_INTRO_TOP_\1 + (\2 * T) / 8
ENDR
	ds 64, 0

.tile\@
	ds 128, T_INTRO_TOP_0 + \1 * 2

.attrs\@
	ds 128, 0

ASSERT (LOW(@) == 0)

ENDM

SECTION "Intro LUT", ROMX, ALIGN[8]

IntroLUT::

FOR I, 0, 2

.y\@
FOR T, 0, 64
	db Y_INTRO_TOP - T
ENDR
	ds 64, 0

.x\@
FOR T, 0, 64
	db X_INTRO_TOP - T + I * 8
ENDR
	ds 64, 0

.tile\@
	ds 128, T_INTRO_NOT + I * 2

.attrs\@
	ds 128, 0

ASSERT (LOW(@) == 0)

ENDR

TOP_LUT 0, -7
TOP_LUT 1, -5
TOP_LUT 2, -3
TOP_LUT 3, -1
TOP_LUT 4,  1
TOP_LUT 5,  3
TOP_LUT 6,  5
TOP_LUT 7,  7

FOR I, 0, 2

.y\@
FOR T, 0, 96
	db LOW(Y_INTRO_BOTTOM - T * 4)
ENDR
	ds 32, 0

.x\@
FOR T, 0, 96
	db LOW(X_INTRO_0 - T * 4 + I * 8)
ENDR
	ds 32, 0

.tile\@
FOR T, 0, 96
	db T_INTRO_0 + ((T & 7) << 2) + I * 2
ENDR
	ds 32, 0

.attrs\@
	ds 128, 0

ASSERT (LOW(@) == 0)

ENDR

I_LUT:
.y
FOR T, 0, 128
	db LOW(Y_INTRO_BOTTOM + T * 3)
ENDR

.x
FOR T, 0, 128
	db LOW(X_INTRO_1 - T * 3)
ENDR

.tile
FOR T, 0, 128
	db T_INTRO_1 + ((T & 3) << 1)
ENDR

.attrs
	ds 128, 0

ASSERT (LOW(@) == 0)

N1_LUT:

FOR I, 0, 2

.y\@
FOR T, 0, 64
	db Y_INTRO_BOTTOM - T * 2
ENDR
	ds 64, 0

.x\@
FOR T, 0, 64
	db LOW(X_INTRO_2 - T * 2 + I * 8)
ENDR
	ds 64, 0

.tile\@
FOR T, 0, 64
	db T_INTRO_2 + (((T >> 1) & 7) << 2) + I * 2
ENDR
	ds 64, 0

.attrs\@
	ds 128, 0

ENDR

ASSERT (LOW(@) == 0)

T_LUT:

.y
FOR T, 0, 128
	db Y_INTRO_BOTTOM + T
ENDR

.x
FOR T, 0, 128
	db X_INTRO_3 - T
ENDR

.tile
FOR T, 0, 128
	db T_INTRO_3 + (((T >> 2) & 3) << 1)
ENDR

.attrs
	ds 128, 0

D_LUT:

FOR I, 0, 2

.y\@
FOR T, 0, 128
	db LOW(Y_INTRO_BOTTOM - T * 3)
ENDR

.x\@
FOR T, 0, 128
	db LOW(X_INTRO_4 + T * 3 + I * 8)
ENDR

.tile\@
FOR T, 0, 128
	db T_INTRO_4 + (((T >> 1) & 7) << 2) + I * 2
ENDR

.filags\@
	ds 128, 0

ENDR

O_LUT:

FOR I, 0, 2

.y\@
FOR T, 0, 72
	db LOW(Y_INTRO_BOTTOM + T * 4)
ENDR
	ds 56, 0

.x\@
FOR T, 0, 128
	db LOW(X_INTRO_5 + T * 4 + I * 8)
ENDR

.tile\@
FOR T, 0, 128
	db T_INTRO_5 + ((T & 7) << 2) + I * 2
ENDR

.attrs\@
	ds 128, 0
ENDR

ASSERT (LOW(@) == 0)

SCY_LUT:
FOR T, 0, 128
	db T
ENDR

SCX_LUT:
FOR T, 0, 128
	db -T
ENDR

ASSERT (LOW(@) == 0)

WY_LUT:
FOR T, 0, 64
	db LOW(64 + T * 2)
ENDR
	ds 64, -1

WX_LUT:
FOR T, 0, 128
	db LOW(X_INTRO_N2 + T * 2)
ENDR

E_LUT:
FOR T, 0, 128
	db T_INTRO_E + ((T >> 3) & 7) << 2
ENDR

N2_LUT:
FOR T, 0, 128
	db T_INTRO_N2 + ((T >> 2) & 7) << 2
ENDR

ASSERT (LOW(@) == 0)
