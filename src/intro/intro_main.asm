; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"
include "gradient.inc"
include "sgb.inc"


MACRO INIT_VRAM_HL
	ld hl, MAP_\1 + ROW_\1 * TILEMAP_WIDTH + COL_\1
ENDM

MACRO INTRO_META_INIT
	INIT_VRAM_HL INTRO_\1      ; Load the meta-tile address into the HL register
	ld a, T_INTRO_\1           ; Load top left tile ID
	call SetMetaTile           ; Set the meta-tile
ENDM

MACRO INTRO_META_SET
	INIT_VRAM_HL INTRO_\1      ; Load the meta-tile address into the HL register
	call SetOddballMetaTile    ; Update the meta-tile
ENDM

MACRO INTRO_TOP_INIT
DEF _ = (\1 - 1)
IF \1 && T_INTRO_TOP_\1 != T_INTRO_TOP_{d:_} + 2
	ld b, T_INTRO_TOP_\1       ; Load tile ID
ENDC
	ld e, X_INTRO_TOP_\1       ; Load X coordinate
	call SetObject16           ; Set the object
ENDM

MACRO INTRO_BOTTOM_INIT
	ld b, T_INTRO_\1           ; Load tile ID
	ld e, X_INTRO_\1           ; Load X coordinate
IF I == 5
	jr SetObject16             ; Set the object and return
ELIF INTRO_\1_WIDTH == 1
	call SetObject16           ; Set the object
ELSE
	call SetTwoObjects16       ; Set the meta-object
ENDC
ENDM


SECTION "Intro", ROM0
Intro::
	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	jr z, .trySGB              ; If not, proceed to try setting SGB palettes
	call SetPalettes           ; Set GBC palettes
	jr .cont                   ; Proceed to initialize objects

.trySGB
	ld hl, PaletteSGB          ; Load the palette address into the HL register
	call SGB_TrySendPacket     ; Try setting SGB palettes

.cont
	call InitTop               ; Initialize our objects
	call ClearOAM              ; Clear the remaining shadow OAM
	call CopyIntro             ; Copy our tiles

	call SGB_TryFreeze         ; Freeze SGB display

	INIT_VRAM_HL LOGO          ; Load the background logo address into the HL register
	call ClearLogo             ; Clear the logo from the background
	rst WaitVRAM               ; Wait for VRAM to become accessible
	INTRO_META_INIT BY         ; Draw BY on the background
	
	INIT_VRAM_HL LOGO2         ; Load the window logo address into the HL register
	ld b, T_LOGO               ; Load the first tile index into the B register
	call SetLogo               ; Draw the logo on the window

	ld a, Y_INTRO_TOP          ; Load the initial Y value into A
	ldh [rSCY], a              ; Set the background's Y coordinate
	ldh [rWY], a               ; Set the window's Y coordinate
	ld a, WX_OFS               ; Load the window's X value into A
	ldh [rWX], a               ; Set the window's X coordinate

	xor a                      ; Display everything as white
	ldh [rOBP1], a             ; Set the alternate object palette
	ldh [rLYC], a              ; Set which line to trigger the LY=LYC interrupt on

	dec a                      ; Set A to $FF
	ldh [rOBP0], a             ; Set the default object palette

IF DEF(GRADIENT)

IF LOW(C_GRADIENT_TOP) != $FF
	ld a, LOW(C_GRADIENT_TOP)  ; Load background color's lower byte into the A register
ENDC
	ldh [hColorLow], a         ; Set background color's lower byte

IF HIGH(C_GRADIENT_TOP) != LOW(C_GRADIENT_TOP)
	ld a, HIGH(C_GRADIENT_TOP) ; Load background color's upper byte into the A register
ENDC
	ldh [hColorHigh], a        ; Set background color's upper byte

	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	ld a, IE_VBLANK            ; Load the flag to enable the VBlank interrupt into A
	jr z, .setIE               ; If not, proceed to set the interrupt enable register
	ld a, STAT_LYC             ; Load the flag to enable LYC STAT interrupts into A
	ldh [rSTAT], a             ; Load the prepared flag into rSTAT to enable the LY=LYC interrupt source 
	ld a, IE_VBLANK | IE_STAT  ; Load the flag to enable the VBlank and STAT interrupts into A

ELSE

	ld a, IE_VBLANK            ; Load the flag to enable the VBlank interrupt into A

ENDC

.setIE
	ldh [rIE], a               ; Load the prepared flag into the interrupt enable register
	xor a                      ; Set A to zero
	ldh [rIF], a               ; Clear any lingering flags from the interrupt flag register to avoid false interrupts

	call hFixedOAMDMA          ; Perform our OAM DMA
	ei                         ; Enable interrupts!

	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON | LCDC_OBJ_16 | LCDC_WIN_ON | LCDC_WIN_9C00
	ldh [rLCDC], a             ; Enable and configure the LCD

	call SGB_TryUnfreeze       ; Unfreeze SGB display

IF DEF(INTRO_SONG)
	ld hl, INTRO_SONG          ; Load the song address into the HL register
	call hUGE_init             ; Initialize song
ENDC

	ldh a, [hFlags]            ; Load our flags into the A register
	ld c, a                    ; Store the flags in the C register
	bit B_FLAGS_SGB, a         ; Are we running on SGB?
	jr z, .drop                ; If not, skip SGB init

IF DEF(FADEOUT)
	ld hl, wPacketBuffer       ; Load packet buffer address into HL
	ld a, SGB_PAL01 | $01      ; Load command type and packet count
	ld [hli], a                ; Set header and advance
	xor a                      ; Set A to zero
.clearLoop
	ld [hli], a                ; Set and advance
	bit 4, l                   ; Buffer length reached?
	jr z, .clearLoop           ; If not, continue to loop
ENDC

	ld b, INTRO_SGB_DELAY      ; ~1 sec delay to make up for the SGB bootup animation
.waitLoop
	rst WaitVBlank             ; Wait for the next VBlank
	dec b                      ; Decrement the counter
	jr nz, .waitLoop           ; Continue to loop unless zero

.drop
	ld e, 0                    ; Use E as our step counter
.dropLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld hl, wShadowOAM          ; Start from the top
	ld d, HIGH(IntroDropLUT)   ; Set the upper address byte to the start of our LUT
	ld a, [de]                 ; Load the Y coordinate value
	ld b, a                    ; Store the Y coordinate in B

.objLoop
	ld [hl], b                 ; Set the Y coordinate
	ld a, l                    ; Advance to the next object
	add OBJ_SIZE               ; ...
	ld l, a                    ; ...
	cp OBJ_INTRO_TOP_END * OBJ_SIZE ; Bottom object reached?
	jr nz, .objLoop            ; If not, continue to loop

	inc d                      ; Advance to the background LUT
	ld a, [de]                 ; Load the background's Y value
	ldh [rSCY], a              ; Set the Y coordinate

	inc d                      ; Advance to the window LUT
	ld a, [de]                 ; Load the window's Y value
	ldh [rWY], a               ; Set the Y coordinate

	bit B_FLAGS_DMG0, c        ; Are we running on DMG0?
	jr nz, .regDone            ; If yes, skip the ® object

REPT 4
	inc d                      ; Advance to the next page
	ld a, [de]                 ; Load Y/X/tile ID/attributes value
	ld [hli], a                ; Set the value
ENDR

IF C_INTRO_BY1 != C_INTRO_BOTTOM || C_INTRO_BY2 != C_INTRO_BOTTOM || DEF(COLOR8)

	bit B_FLAGS_GBC, c         ; Are we running on GBC?
	jr z, .regDone             ; If not, proceed to prevent lag
	ld a, e                    ; Load the value in E into A
	cp COLOR8_STEP             ; Coloration step reached?
	call z, Color8             ; If yes, colorate
	jr .regDone

ENDC

.regDone
	call hFixedOAMDMA          ; Prevent lag
	inc e                      ; Increment the step counter
	jr nz, .dropLoop           ; Continue to loop unless 256 reached

	rst WaitVBlank             ; Wait for the next VBlank
	INIT_VRAM_HL LOGO2         ; Load the window logo address into the HL register
	call ClearLogo             ; Remove the logo from the window
	INTRO_META_INIT E          ; Draw E on the background
	INTRO_META_INIT N2         ; Draw N2 on the window
	call InitBottom            ; Draw the rest of the logo with objects
	call hFixedOAMDMA          ; Prevent flicker
	
	ld a, X_INTRO_N2           ; Set the window's X coordinate
	ldh [rWX], a               ; ...

	ld e, 0                    ; Use E as our step counter
.mainLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld d, HIGH(IntroLUT)       ; Set the upper address byte to the start of our LUT

	call SetOddballs           ; Update background and window coordinates

	INTRO_META_SET E           ; Update E's tiles
	set 7, e                   ; Advance to the second half-page

	INTRO_META_SET N2          ; Update N2's tiles
	res 7, e                   ; Go back to the first half-page

	ld hl, wShadowOAM          ; Start from the top

.topLoop
	rst SetTopEven             ; Decrement Y and copy X
	inc l                      ; Skip tile ID
	inc l                      ; Skip attributes
	rst SetTopOdd              ; Decrement Y and copy X
	inc l                      ; Skip tile ID
	inc l                      ; Skip attributes
	cp OBJ_INTRO_TOP_END * OBJ_SIZE - 2 ; Bottom object reached?
	jr nz, .topLoop            ; If not, continue to loop

.bottomLoop
	call CopyEven              ; Copy Y/tile ID
	call CopyOdd               ; Copy X/attributes
	cp OBJ_INTRO_END * OBJ_SIZE; End object reached?
	jr nz, .bottomLoop         ; If not, continue to loop

	call hFixedOAMDMA          ; Prevent lag

IF DEF(FADEOUT)

	ldh a, [hFlags]            ; Load our flags into the A register
	ld d, a                    ; Store the flags in the D register
	and FLAGS_GBC | FLAGS_SGB  ; Are we running on GBC/SGB?
	jr z, .fadeOutDone         ; If not, proceed to play sound
	ld a, e                    ; Load the value in E into A
	sub FADEOUT_START          ; Adjust to start of fadeout
	jr c, .fadeOutDone         ; If not reached, proceed to play sound
	bit B_FLAGS_GBC, d         ; Are we running on GBC?
	jr z, .fadeOutSGB          ; If not, proceed to fade out SGB

.fadeOutGBC
	ld hl, FadeOutLUT          ; Load LUT address into HL
	call ReadLUT               ; Read color value
	and 1                      ; Isolate the lower bit
	add a                      ; Multiply by 2
	add LOW(rBGPI)             ; Add lower register address byte
	ld l, a                    ; Load the result into L
	ld h, HIGH(rBGPI)          ; Load upper register address byte into H
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, BGPI_AUTOINC | 2     ; Start at color 1 and autoincrement
	ld [hli], a                ; Set index register and advance to value register
	ld [hl], c                 ; Set lower byte
	ld [hl], b                 ; Set upper byte
	jr .fadeOutDone            ; Proceed to play sound

.fadeOutSGB
	bit 0, a                   ; Is the lower bit set?
	jr nz, .fadeOutDone        ; If yes, proceed to play sound
	ld hl, FadeOutSGBLUT       ; Load LUT address into HL
	call ReadLUT               ; Read color value
	ld hl, wPacketBuffer + 8   ; Load final buffer address into HL
	call WriteThreeColorsSGB   ; Write colors 3, 2 and 1
	ld bc, C_INTRO_BACK_SGB    ; Load background color into BC
	call WriteColorSGB         ; Write color 0
	push de                    ; Save the step counter
	call SGB_SendPacket        ; Set SGB palette
	pop de                     ; Restore the step counter

.fadeOutDone

ENDC

IF DEF(INTRO_SONG)
	push de                    ; Save the step counter
	call hUGE_dosound          ; Play sound
	pop de                     ; Restore the step counter
ENDC

	inc e                      ; Increment the step counter
	bit 7, e                   ; Step 128 reached?
	jr z, .mainLoop            ; If not, continue to loop

IF DEF(INTRO_SONG) && INTRO_SONG_DELAY
	ld b, INTRO_SONG_DELAY     ; Small delay for the audio to finish playing
.songLoop
	rst WaitVBlank             ; Wait for the next VBlank
	push bc                    ; Save the loop counter
	call hUGE_dosound          ; Play sound
	pop bc                     ; Restore the loop counter
	dec b                      ; Decrement the loop counter
	jr nz, .songLoop           ; Continue to loop unless zero
ENDC

	ret


SECTION "SetTopEven", ROM0[$20]
SetTopEven:
	dec [hl]                   ; Decrement the Y coordinate
	inc l                      ; Advance to the X coordinate
	; Fall through

CopyEven:
	inc d                      ; Advance to the next page
	ld a, [de]                 ; Load the Y/tile ID value
	ld [hli], a                ; Set Y/tile ID
	set 7, e                   ; Advance to the second half-page
	ret


SECTION "SetTopOdd", ROM0[$28]
SetTopOdd:
	dec [hl]                   ; Decrement the Y coordinate
	inc l                      ; Advance to the X coordinate
	; Fall through

CopyOdd:
	ld a, [de]                 ; Load the X/attributes value
	ld [hli], a                ; Set X/attributes
	res 7, e                   ; Go back to the first half-page
	ld a, l                    ; Load the value in L into A
	ret


SECTION "Intro Subroutines", ROM0
SetOddballs:
	ld c, LOW(rSCY)            ; Start from the background's Y coordinate
	call SetOddball            ; Update the background's coordinates
	ld c, LOW(rWY)             ; Proceed to the window's Y coordinate
	; Fall through

SetOddball:
	ld a, [de]                 ; Load the Y value
	ldh [c], a                 ; Set the Y coordinate
	set 7, e                   ; Advance to the second half-page
	inc c                      ; Advance to the X coordinate
	ld a, [de]                 ; Load the X value
	ldh [c], a                 ; Set the X coordinate
	res 7, e                   ; Go back to the first half-page
	inc d                      ; Advance to the next page
	ret

SetOddballMetaTile:
	ld a, [de]
	; Fall through

SetMetaTile:
	ld [hli], a                ; Set top left tile
	set 1, a                   ; Base + 2
	ld [hld], a                ; Set top right tile
	set 5, l                   ; Move to second row
	dec a                      ; Base + 1
	ld [hli], a                ; Set bottom left tile
	set 1, a                   ; Base + 3
	ld [hl], a                 ; Set bottom right tile
	ret

ClearLogo:
	call .logo
	ld l, LOW(((ROW_LOGO + 1) * TILEMAP_WIDTH) + COL_LOGO)
	; Fall through

.logo:
	ld c, LOGO_WIDTH + 1       ; Clear ®
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	xor a
	ld [hli], a
	dec c
	jr nz, .loop
	ret

SetLogo:
	call .logo
	ld l, (ROW_LOGO2 + 1) * TILEMAP_WIDTH + COL_LOGO
	; Fall through

.logo:
	ld c, LOGO_WIDTH
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld [hl], b
	inc l
	inc b
	dec c
	jr nz, .loop
	ret

InitTop:
	ld hl, wShadowOAM + OBJ_INTRO_NOT * OBJ_SIZE
	ld bc, T_INTRO_NOT << 8    ; Load tile ID and attributes
	ld de, Y_INTRO_INIT << 8 | X_INTRO_TOP
	call SetTwoObjects16       ; Set the meta-object

FOR I, 8
	INTRO_TOP_INIT {d:I}
ENDR
	; Fall through

InitReg:
	ld b, T_INTRO_REG          ; Load tile ID
	ld de, Y_INTRO_REG << 8 | X_INTRO_REG
ASSERT (B_FLAGS_DMG0 == B_OAM_PAL1)
	ldh a, [hFlags]            ; Load our flags into the A register
	and FLAGS_DMG0             ; Isolate the DMG0 flag
	ld c, a                    ; Load attributes
	jr SetObject16             ; Set the object and return

InitBottom:
	ld hl, wShadowOAM + OBJ_INTRO_0 * OBJ_SIZE
	ld bc, T_INTRO_0 << 8      ; Load tile ID and attributes
	ld de, Y_INTRO_BOTTOM << 8 | X_INTRO_0
	call SetTwoObjects16       ; Set the meta-object

FOR I, 1, 6
	INTRO_BOTTOM_INIT {d:I}
ENDR

SetTwoObjects16:
	call SetObject16           ; Set the first object
	; Fall through

SetObject16::
	ld a, d                    ; Load the X coordinate from D
	ld [hli], a                ; Set the Y coordinate
	ld a, e                    ; Load the X coordinate from E
	ld [hli], a                ; Set the X coordinate
	add TILE_WIDTH             ; Advance the X coordinate
	ld e, a                    ; Store the updated X coordinate
	ld a, b                    ; Load the tile ID from B
	ld [hli], a                ; Set the tile ID
	inc b                      ; Advance the tile ID
	inc b                      ; ...
	ld a, c                    ; Load the attributes from C
	ld [hli], a                ; Set the attributes
	ret

Color8:

IF C_INTRO_BY1 != C_INTRO_BOTTOM || C_INTRO_BY2 != C_INTRO_BOTTOM
	push de
	ld hl, STARTOF(VRAM) | (T_INTRO_BY - 2) << 4
	ld de, ByTiles
	call CopyTopDouble
	pop de
ENDC

IF DEF(COLOR8)
FOR I, 0, 3
IF I == 0
	ld hl, wShadowOAM + OAMA_TILEID
ELSE
	ld l, I * OBJ_SIZE + OAMA_TILEID
ENDC
	ld a, T_INTRO_NOT_2 + I * 2
	ld [hli], a
ENDR
	xor a
FOR I, 0, 8
IF I > 0
	ld l, (I + 2) * OBJ_SIZE + OAMA_FLAGS
ENDC
	ld [hl], a
	inc a
ENDR
ENDC

	ret

SetPalettes:
	ld hl, rBGPI
	call SetPalette

IF DEF(COLOR8)

FOR I, 0, 8
	ld a, OBPI_AUTOINC | I << 3 | 2
	ld [hli], a
IF I == 0
IF LOW(C_INTRO_BOTTOM) == HIGH(C_INTRO_BOTTOM)
	IF C_INTRO_BOTTOM
		ld a, LOW(C_INTRO_BOTTOM)
	ELSE
		xor a
	ENDC
	ld [hl], a
	ld [hl], a
ELSE
	ld bc, C_INTRO_BOTTOM
	ld [hl], c
	ld [hl], b
ENDC
	ld bc, C_INTRO_NOT
	ld [hl], c
	ld [hl], b
	ld bc, C_INTRO_TOP_0
ELSE
DEF _ = (I - 1)
IF HIGH(C_INTRO_TOP_{d:I}) == HIGH(C_INTRO_TOP_{d:_})
	ld c, LOW(C_INTRO_TOP_{d:I})
ELIF LOW(C_INTRO_TOP_{d:I}) == LOW(C_INTRO_TOP_{d:_})
	ld b, HIGH(C_INTRO_TOP_{d:I})
ELSE
	ld bc, C_INTRO_TOP_{d:I}
ENDC
ENDC
	ld [hl], c
	ld [hl], b
	dec l
ENDR
	ret

ELSE

	; Fall through

ENDC

SetPalette:
	ld a, BGPI_AUTOINC
	ld [hli], a

IF LOW(C_INTRO_BACK) == HIGH(C_INTRO_BACK)
	ld a, LOW(C_INTRO_BACK)
	ld [hl], a
	ld [hl], a
ELSE
	ld bc, C_INTRO_BACK
	ld [hl], c
	ld [hl], b
ENDC

IF LOW(C_INTRO_BOTTOM) == HIGH(C_INTRO_BOTTOM)
	IF C_INTRO_BOTTOM
		ld a, LOW(C_INTRO_BOTTOM)
	ELSE
		xor a
	ENDC
	ld [hl], a
IF C_INTRO_BY1 != C_INTRO_BOTTOM || C_INTRO_BY2 != C_INTRO_BOTTOM
	ld [hl], a
ELSE
	ld [hli], a
ENDC
ELSE
	ld bc, C_INTRO_BOTTOM
	ld [hl], c
	ld [hl], b
ENDC

IF C_INTRO_BY1 != C_INTRO_BOTTOM || C_INTRO_BY2 != C_INTRO_BOTTOM
	ld bc, C_INTRO_BY1
	ld [hl], c
	ld [hl], b
IF C_INTRO_BY2 != C_INTRO_BY1
	ld bc, C_INTRO_BY2
ENDC
	ld [hl], c
	ld [hl], b
	inc l
ENDC

	ret

PaletteSGB:
	db SGB_PAL01 | $01
	dw C_INTRO_BACK_SGB
REPT 6
	dw C_INTRO_BOTTOM_SGB
ENDR
	db 0


IF DEF(FADEOUT)

SECTION "ReadLUT", ROM0
ReadLUT:
	add l                      ; Add lower address byte
	ld l, a                    ; Load the result into L
	res 0, l                   ; Clear the lowest bit
	ld c, [hl]                 ; Load lower byte into C
	inc l                      ; Increment lower LUT address byte
	ld b, [hl]                 ; Load upper byte into B
	bit B_FLAGS_GBC, d         ; Are we running on GBC?
	ret

WriteThreeColorsSGB:
	call WriteColorSGB         ; Write the first color
	; Fall through

WriteTwoColorsSGB:
	call WriteColorSGB         ; Write the color before last
	; Fall through

WriteColorSGB:
	ld a, b                    ; Load upper byte into A
	ld [hld], a                ; Set and move back
	ld a, c                    ; Load lower byte into A
	ld [hld], a                ; Set and move back
	ret


SECTION "FadeOutLUT", ROMX, ALIGN[1]
IF C_INTRO_BOTTOM_SGB == C_INTRO_BOTTOM && C_INTRO_BACK_SGB == C_INTRO_BACK
FadeOutSGBLUT:
ENDC
FadeOutLUT:
FOR I, FADEOUT_LENGTH
	INTER_COLOR C_INTRO_BOTTOM, C_INTRO_BACK, FADEOUT_LENGTH, I
ENDR


IF C_INTRO_BOTTOM_SGB != C_INTRO_BOTTOM || C_INTRO_BACK_SGB != C_INTRO_BACK

SECTION "FadeOutSGBLUT", ROMX, ALIGN[1]
FadeOutSGBLUT:
DEF FADEOUT_MAX = (FADEOUT_LENGTH - 1)
FOR I, FADEOUT_LENGTH
	INTER_COLOR C_INTRO_BOTTOM_SGB, C_INTRO_BACK_SGB, FADEOUT_LENGTH, I
ENDR

ENDC


SECTION "SGB Packet Buffer", WRAM0, ALIGN[8]
wPacketBuffer:
	ds SGB_PACKET_SIZE

ENDC
