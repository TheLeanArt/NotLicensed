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
MACRO COPY_1BPP_SAFE
	ld b, \1Tiles.end - \1Tiles ; Set B to the byte count
.loop\@
	rst WaitVRAM        ; Wait for VRAM to become accessible
	ld a, [de]          ; Load a byte from the address DE points to into the A register
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	ld [hli], a         ; Repeat for the second bitplane
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
	ld [hli], a         ; Load the byte in the A register to the address HL points to
	inc de              ; Increment the source pointer in DE
	dec b               ; Decrement the inner loop counter
	jr nz, .loop\@      ; Stop if B is zero, otherwise keep looping
	dec c               ; Decrement the outer loop counter
	jr nz, .loop\@      ; Stop if C is zero, otherwise keep looping
ENDM
