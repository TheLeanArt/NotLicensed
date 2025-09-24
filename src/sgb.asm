; Adapted from https://github.com/gb-archive/snek-gbc/blob/main/code/sub.sm83
;
; Copyright (c) 2023 zlago

include "hardware.inc"
include "common.inc"
include "sgb.inc"


MACRO SEND_BIT
	ldh [c], a          ; 5 cycles
	ld a, $FF           ; end pulse
	nop
	ldh [c], a          ; 15 cycles
ENDM

SECTION "SGB_SendPacket", ROM0
SGB_Freeze::
	ld hl, FreezeSGB
	jr SGB_SendPacket

SGB_TryFreeze::
	ld hl, FreezeSGB
	jr SGB_TrySendPacket

SGB_Unfreeze::
	ld hl, UnfreezeSGB
	jr SGB_SendPacket

SGB_TryUnfreeze::
	ld hl, UnfreezeSGB
	; Fall through

SGB_TrySendPacket::
	ldh a, [hFlags]
	cp FLAGS_SGB
	ret nz
	; Fall through

SGB_SendPacket::
	ld bc, SGB_PACKET_SIZE << 8 | LOW(rP1)
	xor a               ; start bit
	SEND_BIT

.byteLoop
	ld d, [hl]
	inc hl
	ld e, 8

.bitLoop
	xor a               ; load A with SGB bit
	rr d                ; fetch next bit
	ccf                 ; set accumulator in the dumbest way i could come up with
	adc a
	inc a
	swap a
	nop
	nop
	SEND_BIT

	dec e
	jr nz, .bitLoop
	dec b
	jr nz, .byteLoop

	REPT 6
		nop
	ENDR

	ld a, $20           ; stop bit
	SEND_BIT

	REPT 11
		nop
	ENDR

	ld a, JOYP_GET_CTRL_PAD
	ldh [c], a
	ret


SECTION "FreezeSGB", ROM0
FreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_FREEZE
	ds 14


SECTION "UnfreezeSGB", ROM0
UnfreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_CANCEL
	ds 14
