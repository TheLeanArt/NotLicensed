; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"


; Initialization portion adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)

SECTION "Start", ROM0[$0100]
	di                         ; Disable interrupts during setup
	jp EntryPoint              ; Jump past the header space to our actual code
	ds $150 - @, 0             ; Allocate space for RGBFIX to insert our ROM header


SECTION "EntryPoint", ROM0
EntryPoint:
	ld sp, $E000               ; Set the stack pointer to the end of WRAM

	ld d, FLAGS_DMG            ; Set flags to DMG
	cp BOOTUP_A_CGB            ; Are we running on GBC/GBA?
	jr nz, .cont               ; If not, proceed

.GBC:
	set B_FLAGS_GBC, d         ; Set the GBC flag
	ld a, b                    ; Load the initial value of B into A
	cp BOOTUP_B_AGB            ; Are we running on GBA?
	jr nz, .setFlags           ; If not, proceed to setting flags

.GBA:
	set B_FLAGS_GBA, d         ; Set the GBA flag
	jr .setFlags               ; Proceed to setting flags

.cont:
	ld a, c                    ; Load the initial value of C into A
	cp BOOTUP_C_SGB            ; Are we running on SGB/SGB2?
	jr nz, .notSGB             ; If not, proceed to setting flags

.SGB:
	set B_FLAGS_SGB, d         ; Set the SGB flag
	jr .setFlags               ; Proceed to setting flags

.notSGB:
	ld a, b                    ; Load the initial value of B into A
	cp BOOTUP_B_DMG0           ; Are we running on DMG0?
	jr nz, .setFlags           ; If not, proceed to setting flags

.DMG0
	set B_FLAGS_DMG0, d        ; Set the DMG0 flag

.setFlags
	ld a, d                    ; Load the flags into A
	ldh [hFlags], a            ; Set our flags

	call CopyOAMDMA            ; Copy our OAM DMA routine
	call Intro                 ; Call intro

	xor a                      ; Clear the A register
	ldh [rAUDENA], a           ; Shut down audio circuitry

LoopForever:
	halt
	jr LoopForever


SECTION "Flags", HRAM

hFlags::
	ds 1
