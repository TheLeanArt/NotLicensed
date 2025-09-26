; Common Game Boy definitions
;
; Copyright (c) 2025 Dmitry Shechtman


; https://github.com/gbdev/hardware.inc/pull/75
DEF BOOTUP_B_DMG0        EQU $FF

DEF B_FLAGS_SGB          EQU   0
DEF B_FLAGS_GBC          EQU   1
DEF B_FLAGS_GBA          EQU   2
DEF B_FLAGS_DMG0         EQU   4

DEF FLAGS_DMG            EQU   0
DEF FLAGS_SGB            EQU   1 << B_FLAGS_SGB
DEF FLAGS_GBC            EQU   1 << B_FLAGS_GBC
DEF FLAGS_GBA            EQU   1 << B_FLAGS_GBC | 1 << B_FLAGS_GBA
DEF FLAGS_DMG0           EQU   1 << B_FLAGS_DMG0

DEF FLAGS_MASK           EQU   FLAGS_SGB | FLAGS_GBC


; Adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)

; @param B  Zero
; @param \1 Page count
MACRO CLEAR_LONG
	xor a               ; Clear the A register
	ld bc, \1           ; Clear B and set C to the page count
.loop\@
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	dec b               ; Decrement the inner loop counter
	jr nz, .loop\@      ; Stop if B is zero, otherwise keep looping
	dec c               ; Decrement the outer loop counter
	jr nz, .loop\@      ; Stop if C is zero, otherwise keep looping
ENDM

; @param \1 Tiles prefix
MACRO COPY_0_5BPP_PRE_SAFE
	ld bc, \1Tiles.end - \1Tiles ; Set BC to the byte count
.loop\@
	rst WaitVRAM        ; Wait for VRAM to become accessible
REPT 2
	ld a, [de]          ; Load a byte from the address DE points to into the A register
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	xor a               ; Clear the A register
	ld [hli], a         ; Repeat for the second bitplane
	inc de              ; Increment the source pointer in DE
	dec bc              ; Decrement the loop counter in BC
	ld a, b             ; Load the value in B into A
	or c                ; Logical OR the value in A (from B) with C
	jr nz, .loop\@      ; If B and C are both zero, OR B will be zero, otherwise keep looping
ENDM

; @param \1 Tiles prefix
MACRO COPY_1BPP_PRE_SAFE
ASSERT(!HIGH(\1Tiles.end - \1Tiles))
	ld b, \1Tiles.end - \1Tiles ; Set B to the byte count
.loop\@
	rst WaitVRAM        ; Wait for VRAM to become accessible
	ld a, [de]          ; Load a byte from the address DE points to into the A register
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	xor a               ; Clear the A register
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	inc de              ; Increment the source pointer in DE
	dec b               ; Decrement the inner loop counter
	jr nz, .loop\@      ; Stop if B is zero, otherwise keep looping
ENDM

; @param \1 Page-aligned Tiles prefix
MACRO COPY_2BPP
ASSERT(HIGH(\1Tiles.end - \1Tiles))
	ld bc, HIGH(\1Tiles.end - \1Tiles) ; Clear B and set C to the page count
.loop\@
	ld a, [de]          ; Load a byte from the address DE points to into the A register
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	inc de              ; Increment the source pointer in DE
	dec b               ; Decrement the inner loop counter
	jr nz, .loop\@      ; Stop if B is zero, otherwise keep looping
	dec c               ; Decrement the outer loop counter
	jr nz, .loop\@      ; Stop if C is zero, otherwise keep looping
ENDM

; @param \1 Label
MACRO MEM_COPY
	ld bc, \1.end - \1  ; Set BC to the byte count
	ld de, \1           ; Load the source address into DE
	call MemCopy        ; Call the copy subroutine
ENDM

; @param \1 First color
; @param \2 Second color
; @param \3 Step count
; @param \4 Step
MACRO INTER_COLOR
	DEF _R = ((((\1      ) & $1F) * (\3 - \4) + ((\2      ) & $1F) * (\4 + 1)) / \3)
	DEF _G = ((((\1 >>  5) & $1F) * (\3 - \4) + ((\2 >>  5) & $1F) * (\4 + 1)) / \3)
	DEF _B = ((((\1 >> 10) & $1F) * (\3 - \4) + ((\2 >> 10) & $1F) * (\4 + 1)) / \3)
	dw {d:_B} << 10 | {d:_G} << 5 | {d:_R}
ENDM

; @param \1 Top
; @param \2 Bottom
MACRO GRADIENT_LUT
FOR I, GRADIENT_LENGTH
	INTER_COLOR \1, \2, GRADIENT_LENGTH, I
ENDR
REPT GRADIENT_PADDING
	dw \2
ENDR
ENDM
