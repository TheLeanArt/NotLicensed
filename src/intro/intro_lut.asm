; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "intro.inc"


SECTION "Intro LUT", ROM0, ALIGN[8]

IntroLUT::

E_LUT:
FOR T, 0, 128
	db T_INTRO_E + ((T >> 3) & 7) << 2
ENDR

N2_LUT:
FOR T, 0, 128
	db T_INTRO_N2 + ((T >> 2) & 7) << 2
ENDR

N0_LUT:

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
IF (T & 4) == 0
	db T_INTRO_0 + ((T & 3) << 2) + I * 2
ELSE
	db T_INTRO_0 + ((T & 3) << 2) + 3 - I * 2
ENDC
ENDR
	ds 32, 0

.attrs\@
FOR T, 0, 128
IF (T & 4) == 0
	db 0
ELSE
	db OAM_XFLIP
ENDC
ENDR

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
IF (T >> 1) & 4 == 0
	db T_INTRO_2 + (((T >> 1) & 3) << 2) + I * 2
ELSE
	db T_INTRO_2 + (((T >> 1) & 3) << 2) + 3 - I * 2
ENDC
ENDR
	ds 64, 0

.attrs\@
FOR I, 0, 64
IF (T >> 1) & 4 == 0
	db 0
ELSE
	db OAMF_XFLIP
ENDC
ENDR
	ds 64, 0

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
IF (T >> 1) & 4 == 0
	db T_INTRO_4 + (((T >> 1) & 3) << 2) + I * 2
ELSE
	db T_INTRO_4 + (((T >> 1) & 3) << 2) + 3 - I * 2
ENDC
ENDR

.attrs\@
FOR T, 0, 128
IF (T >> 1) & 4 == 0
	db 0
ELSE
	db OAM_XFLIP
ENDC
ENDR

ENDR

O_LUT:

FOR I, 0, 2

.y\@
FOR T, 0, 96
	db LOW(Y_INTRO_BOTTOM + T * 4)
ENDR
	ds 32, 0

.x\@
FOR T, 0, 128
	db LOW(X_INTRO_5 + T * 4 + I * 8)
ENDR

.tile\@
FOR T, 0, 128
IF (T & 4) == 0
	db T_INTRO_5 + ((T & 3) << 2) + I * 2
ELSE
	db T_INTRO_5 + ((T & 3) << 2) + 3 - I * 2
ENDC
ENDR

.attrs\@
FOR T, 0, 128
IF (T & 4) == 0
	db 0
ELSE
	db OAM_XFLIP
ENDC
ENDR

ASSERT (LOW(@) == 0)

ENDR

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
