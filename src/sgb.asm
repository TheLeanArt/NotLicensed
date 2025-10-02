; SGB subroutines
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "sgb.inc"


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


; Send SGB packet
;
; Optimized subroutine by nitro2k01
; https://github.com/nitro2k01
;
; @param HL Packet
; @param BC Clobbered
SGB_SendPacket::
	ld bc, SGB_PACKET_SIZE + 1 ; B = 0, C = SGB packet size + 1
	xor a                      ; A = 0, CF = 0
	ldh [rJOYP], a             ; Send start bit

.bitLoop
	ld a, JOYP_SGB_FINISH      ; Load idle state
	ldh [rJOYP], a             ; Send idle state

.bitCont
	rr b                       ; Get next bit, plus zero check
	jr z, .nextByte            ; If byte end reached, proceed to the next byte
	sbc a                      ; Transfer carry into all bits of A
	xor JOYP_SGB_ZERO          ; Select the relevant bit, CF = 0
	ldh [rJOYP], a             ; Send bit
	jr .bitLoop                ; Continue looping

.nextByte
	dec c                      ; Check length in bytes
	scf                        ; Set carry to inject sentinel bit
	jr z, .done                ; If packet end reached, proceed to send stop bit
	ld a, [hli]                ; Load next byte
	ld b, a                    ; Load into B
	jr .bitCont                ; Continue looping

.done
	ld a, JOYP_SGB_ZERO        ; Load stop bit
	ldh [rJOYP], a             ; Send stop bit
	sbc a                      ; Reuse the sentinel bit to save 1 byte/cycle loading $FF into A
	ldh [rJOYP], a             ; Send idle state
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
