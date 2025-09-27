; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "intro.inc"


SECTION "Intro LUT", ROMX, ALIGN[8]

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

.y
FOR T, 1, 97
	db LOW(Y_INTRO_BOTTOM - T * 4)
ENDR
	ds 32, 0

.x
FOR T, 1, 97
	db LOW(X_INTRO_N0 - T * 4)
ENDR
	ds 32, 0

ASSERT (LOW(@) == 0)

.tile
FOR T, 0, 96
IF (T & 4) == 0
	db T_INTRO_N0 + ((T & 3) << 2)
ELSE
	db T_INTRO_N0 + ((T & 3) << 2) + 2
ENDC
ENDR
	ds 32, 0

.attrs
FOR T, 0, 128
IF (T & 4) == 0
	db 0
ELSE
	db OAM_XFLIP
ENDC
ENDR

N1_LUT:

.y
FOR T, 1, 65
	db Y_INTRO_BOTTOM - T * 2
ENDR
	ds 64, 0

.x
FOR T, 1, 65
	db LOW(X_INTRO_N1 - T * 2)
ENDR
	ds 64, 0

.tile
FOR T, 0, 64
	db T_INTRO_N1 + (((T >> 2) & 7) << 2)
ENDR
	ds 64, 0

.attrs
	ds 128, 0

ASSERT (LOW(@) == 0)

D_LUT:

.y
FOR T, 1, 129
	db LOW(Y_INTRO_BOTTOM - T * 3)
ENDR

.x
FOR T, 1, 129
	db LOW(X_INTRO_D + T * 3)
ENDR

.tile
FOR T, 0, 128
IF (T >> 1) & 4 == 0
	db T_INTRO_D + (((T >> 1) & 3) << 2)
ELSE
	db T_INTRO_D + (((T >> 1) & 3) << 2) + 2
ENDC
ENDR

.attrs
FOR T, 0, 128
IF (T >> 1) & 4 == 0
	db 0
ELSE
	db OAM_XFLIP
ENDC
ENDR

ASSERT (LOW(@) == 0)

O_LUT:

.y
FOR T, 1, 97
	db LOW(Y_INTRO_BOTTOM + T * 4)
ENDR
	ds 32, 0

.x
FOR T, 1, 129
	db LOW(X_INTRO_O + T * 4)
ENDR

.tile
FOR T, 0, 128
IF (T & 4) == 0
	db T_INTRO_O + ((T & 3) << 2)
ELSE
	db T_INTRO_O + ((T & 3) << 2) + 2
ENDC
ENDR

.attrs
FOR T, 0, 128
IF (T & 4) == 0
	db 0
ELSE
	db OAM_XFLIP
ENDC
ENDR

ASSERT (LOW(@) == 0)

I_LUT:

.y
FOR T, 1, 129
	db LOW(Y_INTRO_BOTTOM + T * 3)
ENDR

.x
FOR T, 1, 129
	db LOW(X_INTRO_I - T * 3)
ENDR

.tile
FOR T, 0, 128
	db T_INTRO_I + ((T & 3) << 1)
ENDR

.attrs
	ds 128, 0

ASSERT (LOW(@) == 0)

T_LUT:

.y
FOR T, 1, 129
	db Y_INTRO_BOTTOM + T
ENDR

.x
FOR T, 1, 129
	db X_INTRO_T - T
ENDR

.tile
FOR T, 0, 128
	db T_INTRO_T + (((T >> 2) & 3) << 1)
ENDR

.attrs
	ds 128, 0

ASSERT (LOW(@) == 0)
