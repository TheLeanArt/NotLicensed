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
IF \1 && T_INTRO_TOP_\1 != T_INTRO_TOP_{d:_} + 1
	ld b, T_INTRO_TOP_\1       ; Load tile ID
ENDC
IF \1 && X_INTRO_TOP_\1 == X_INTRO_TOP_{d:_} + INTRO_TOP_NORM_WIDTH
	call SetNextTopObject      ; Set the next object
ELSE
	ld e, X_INTRO_TOP_\1       ; Load X coordinate
	call SetObject             ; Set the object
ENDC
ENDM

MACRO INTRO_BOTTOM_INIT
	ld b, T_INTRO_\1           ; Load tile ID
IF \1 == 0
	ld de, Y_INTRO_BOTTOM << 8 | X_INTRO_0
ELSE
	ld e, X_INTRO_\1           ; Load X coordinate
ENDC
IF \1 == 5
	ASSERT (INTRO_\1_WIDTH == 1)
	jr SetDoubleObject
ELIF INTRO_\1_WIDTH == 1
	call SetDoubleObject       ; Set the double-object
ELSE
	call SetMetaObject         ; Set the meta-object
ENDC
ENDM


SECTION FRAGMENT "Intro", ROM0
Intro::
	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	jr z, .trySGB              ; If not, proceed to try setting SGB palettes
	call SetPalettes           ; Set GBC palettes
	jr .cont                   ; Proceed to initialize objects

.trySGB
	bit B_FLAGS_SGB, a         ; Are we running on SGB?
	jr z, .cont                ; If not, proceed to initialize objects

	ld hl, wPacketBuffer + SGB_PACKET_SIZE - 1
.clearLoop
	xor a                      ; Set A to zero
	ld [hld], a                ; Set and move back
	or l                       ; Buffer start reached?
	jr nz, .clearLoop          ; If not, continue to loop

ASSERT(SGB_PAL01 == 0)

	inc a                      ; Set A to one

IF DEF(INTRO_FADEIN_SGB)

ASSERT(C_INTRO_INIT_SGB == 0)  ; All blacks

	ld [hl], a                 ; Set packet header

ELSE

ASSERT(C_INTRO_BOTTOM_SGB == 0)  ; Mostly blacks

	ld [hli], a                  ; Set packet header and advance
	inc l                        ; Advance to the background's upper byte
	ld a, HIGH(C_INTRO_BACK_SGB) ; Load the background's upper byte into A
	ld [hld], a                  ; Set and move back
	ld a, LOW(C_INTRO_BACK_SGB)  ; Load the background's lower byte into A
	ld [hld], a                  ; Set and move back

ENDC

	call SGB_SendPacket        ; Set SGB palette

.cont
	call InitTop               ; Initialize our objects
	call ClearOAM              ; Clear the remaining shadow OAM
	call CopyIntro             ; Copy our tiles

	call SGB_TryFreeze         ; Freeze SGB display

	INIT_VRAM_HL LOGO          ; Load the background logo address into the HL register
	call ClearLogo             ; Clear the logo from the background
	call InitOAndBy            ; Draw top O and BY on the background
	
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

IF LOW(C_INTRO_GRADIENT_TOP) != $FF
	ld a, LOW(C_INTRO_GRADIENT_TOP)
ENDC
	ldh [hColorLow], a         ; Set background color's lower byte

IF HIGH(C_INTRO_GRADIENT_TOP) != LOW(C_INTRO_GRADIENT_TOP)
	ld a, HIGH(C_INTRO_GRADIENT_TOP)
ENDC
	ldh [hColorHigh], a        ; Set background color's upper byte

IF DEF(INTRO_GRADIENT)

	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	ld a, IE_VBLANK            ; Load the flag to enable the VBlank interrupt into A
	jr z, .setIE               ; If not, proceed to set the interrupt enable register

	ld de, IntroColorLUT       ; Load the address of our color LUT into DE
	call CopyColorLUT          ; Copy the color LUT
	ld a, STAT_LYC             ; Load the flag to enable LYC STAT interrupts into A
	ldh [rSTAT], a             ; Load the prepared flag into rSTAT to enable the LY=LYC interrupt source 
	ld a, IE_VBLANK | IE_STAT  ; Load the flag to enable the VBlank and STAT interrupts into A

ELSE

	ld de, C_INTRO_BACK        ; Load the background color into DE
	call InitColorLUT          ; Initialize the color LUT
	ld a, IE_VBLANK            ; Load the flag to enable the VBlank interrupt into A

ENDC

ELSE

	ld a, IE_VBLANK            ; Load the flag to enable the VBlank interrupt into A

ENDC

.setIE
	ldh [rIE], a               ; Load the prepared flag into the interrupt enable register
	xor a                      ; Set A to zero
	ldh [rIF], a               ; Clear any lingering flags from the interrupt flag register to avoid false interrupts

	call hFixedOAMDMA          ; Perform our OAM DMA
	ei                         ; Enable interrupts!

	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON | LCDC_WIN_ON | LCDC_WIN_9C00
	ldh [rLCDC], a             ; Enable and configure the LCD

	call SGB_TryUnfreeze       ; Unfreeze SGB display

IF DEF(INTRO_SONG)
	ld hl, INTRO_SONG          ; Load the song address into the HL register
	call hUGE_init             ; Initialize song
ENDC

	ldh a, [hFlags]            ; Load our flags into the A register
	ld c, a                    ; Store the flags in the C register
	and FLAGS_SGB              ; Are we running on SGB?
	call nz, IntroInitSGB      ; If yes, initialize SGB

.drop
	ld e, 0                    ; Use E as our step counter
.dropLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld hl, wShadowOAM          ; Start from the top
	ld d, HIGH(IntroDropLUT)   ; Set the upper address byte to the start of our LUT
	ld a, [de]                 ; Load the background's Y value
	ldh [rSCY], a              ; Set the Y coordinate
	cpl                        ; Complement A
	add Y_INTRO_FINAL + 1      ; Adjust the Y coordinate
	ld b, a                    ; Store the Y coordinate in B

.objLoop
	ld [hl], b                 ; Set the Y coordinate
	ld a, l                    ; Advance to the next object
	add OBJ_SIZE               ; ...
	ld l, a                    ; ...
	cp OBJ_INTRO_REG * OBJ_SIZE; ® object reached?
	jr nz, .objLoop            ; If not, continue to loop

	set 7, e                   ; Advance to the second half-page
	ld a, [de]                 ; Load the window's Y value
	ldh [rWY], a               ; Set the Y coordinate
	res 7, e                   ; Go back to the first half-page

	bit B_FLAGS_DMG0, c        ; Are we running on DMG0?
	jr nz, .dropDone           ; If yes, skip the ® object

	inc d                      ; Advance to the next page
	ld a, [de]                 ; Load the Y coordinate value
	ld [hli], a                ; Set the Y coordinate
	set 7, e                   ; Advance to the second half-page
	ld a, [de]                 ; Load the X coordinate value
	ld [hli], a                ; Set the X coordinate
	res 7, e                   ; Go back to the first half-page

	ld a, e                    ; Load the value in E into A
	sub INTRO_REG_START + 1    ; Starting step reached?
	jr c, .regDone             ; If not, skip setting tile ID and attributes
.regTile
	inc a                      ; Compensate for step adjustment
	and INTRO_REG_MASK         ; Isolate rotation step
	add T_INTRO_REG            ; Add base tile ID
	ld [hli], a                ; Set the tile ID
	sub T_INTRO_REG            ; Subtract base tile ID
	jr nz, .regDone            ; If nonzero, skip setting the attributes
.regAttrs
	ld a, OAM_XFLIP | OAM_YFLIP; Rotate 180 degrees
	xor [hl]                   ; Apply to the current attributes
	ld [hl], a                 ; Set the new attributes
.regDone

IF DEF(COLOR8)

	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	jr z, .dropDone            ; If not, proceed to prevent lag
	ld a, e                    ; Load the value in E into A
	cp COLOR8_STEP             ; Coloration step reached?
	call z, Color8             ; If yes, colorate

ENDC

.dropDone
	call hFixedOAMDMA          ; Prevent lag
	inc e                      ; Increment the step counter
	bit 7, e                   ; Step 128 reached?
	jr z, .dropLoop            ; If not, continue to loop

	call Sleep                 ; Wait 128 frames
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

	bit 6, e                   ; Step 64 reached?
	jr nz, .shiftDone          ; If yes, skip to updating E

	INIT_VRAM_HL INTRO_TOP     ; Load the top row's address into the HL register

	ld a, e                    ; Load the step counter into A
	srl a                      ; Divide by 2
	srl a                      ; Divide by 2
	add e                      ; Add t * 2
	add e                      ; ...
	ld b, a                    ; Store t * 9/4 in B
	swap a                     ; Divide by 8
	rlca                       ; ...
	
	                           ; Optimization courtesy of calc84maniac
	cpl                        ; Negate...
	add COL_INTRO_O + 2        ; and add base column + 1
	and TILEMAP_WIDTH - 1      ; Stay within the row
	or l                       ; Adjust row
	ld l, a                    ; Load the lower address byte into L
	ld a, b                    ; Load t * 9/4
	and $07                    ; Isolate tile pair index
	add a                      ; Multiply by 2
	or T_INTRO_TOP_O + 1       ; Adjust tile ID
ASSERT (ROW_INTRO_TOP & 1)
	ld [hld], a                ; Set right tile and decrement the address
	set TZCOUNT(TILEMAP_WIDTH), l ; Stay within the row
	dec a                      ; Decrement tile ID
	ld [hld], a                ; Set left tile and decrement the address

	ld a, e                    ; Load the step counter into A
	or a                       ; Skip the first step
	jr z, .shiftDone           ; If zero, skip to updating E
	and 3                      ; Shift Y every 4th step (and clear CF)
	jr nz, .shiftDone          ; If not on 4th step, skip to updating E
	ld [hl], a                 ; Clear any lingering Os

.bShift
	ld hl, STARTOF(VRAM) | T_INTRO_BY << 4
	bit 2, e                   ; Shift B every 8th step
	jr z, .yShift              ; If not on 8th step, skip to shifting Y

.bLoop
	rr [hl]                    ; Shift the left tile to the right
	set 5, l                   ; Advance to the middle tile
	rr [hl]                    ; Shift the middle tile to the right
	ld a, l                    ; Load the lower address byte into A
	sub TILE_SIZE * 2 - 2      ; Go back to the left tile and advance to the next row
	ld l, a                    ; Update the lower address byte
	bit 4, l                   ; Tile boundary crossed?
	jr z, .bLoop               ; If not, keep looping

.yShift
	ld l, LOW(T_INTRO_BY_1 << 4) | 1

.yLoop
	rr [hl]                    ; Shift the middle tile to the right
	set 4, l                   ; Advance to the right tile
	rr [hl]                    ; Shift the right tile to the right
	ld a, l                    ; Load the lower address byte into A
	sub TILE_SIZE - 2          ; Go back to the middle tile and advance to the next row
	ld l, a                    ; Update the lower address byte
	bit 4, l                   ; Tile boundary crossed?
	jr z, .yLoop               ; If not, keep looping

.shiftDone
	ld d, HIGH(IntroLUT)       ; Set the upper address byte to the start of our LUT

	INTRO_META_SET E           ; Update E's tiles
	set 7, e                   ; Advance to the second half-page

	INTRO_META_SET N2          ; Update N2's tiles
	res 7, e                   ; Go back to the first half-page

	call IntroMain             ; Set objects and background/window coordinates

IF DEF(INTRO_FADEOUT)

	ldh a, [hFlags]            ; Load our flags into the A register
	ld d, a                    ; Store the flags in the D register
	and FLAGS_GBC | FLAGS_SGB  ; Are we running on GBC/SGB?
	jr z, .fadeOutDMG          ; If not, proceed to fade out DMG
	ld a, e                    ; Load the value in E into A
	sub INTRO_FADEOUT_START    ; Adjust to start of fadeout
	jr c, .fadeOutDone         ; If not reached, proceed to play sound
	bit B_FLAGS_GBC, d         ; Are we running on GBC?
	jr z, .fadeOutSGB          ; If not, proceed to fade out SGB

.fadeOutGBC
	ld hl, FadeOutLUT          ; Load LUT address into HL
	call ReadLUT2              ; Read color values
	ldh [hColorLow], a         ; Set the background color's lower byte
	ld a, d                    ; Load the background's upper byte into A
	ldh [hColorHigh], a        ; Set the background color's upper byte
	ld a, e                    ; Load the step counter into A
	add a                      ; Multiply by 2
	and 2                      ; Isolate the 2nd lowest bit
	ld hl, rBGPI               ; Load the index register address into HL
	add l                      ; Add lower register address byte
	ld l, a                    ; Load the result into L
	ld a, BGPI_AUTOINC         ; Start at color 0 and autoincrement
	ld [hli], a                ; Set index register and advance to value register
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ldh a, [hColorLow]         ; Load the background's lower byte into A
	ld [hl], a                 ; Set the background's lower byte
	ld [hl], d                 ; Set the background's upper byte
	ld [hl], c                 ; Set the foreground's lower byte
	ld [hl], b                 ; Set the foreground's upper byte
	dec l                      ; Move back to the index register
	ld a, BGPI_AUTOINC | 8     ; Start at palette 1 color 0 and autoincrement
	ld [hli], a                ; Set index register and advance to value register
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ldh a, [hColorLow]         ; Load the background's lower byte into A
	ld [hl], a                 ; Set the background's lower byte
	ld [hl], d                 ; Set the background's upper byte
	jr .fadeOutDone            ; Proceed to play sound

.fadeOutSGB
	ld hl, FadeOutSGBLUT       ; Load LUT address into HL
	call ReadSGBLUT2           ; Read color values
	ld hl, wPacketBuffer + 8   ; Load the foreground's address into HL
	ld [hld], a                ; Set and move back
	ld a, b                    ; Load the foreground's lower byte into A
	ld [hld], a                ; Set and move back
	ld l, LOW(wPacketBuffer + 2) ; Load the background's lower address byte into L
	ld a, c                    ; Load the background's upper byte into A
	ld [hld], a                ; Set and move back
	ld a, d                    ; Load the background's lower byte into A
	ld [hld], a                ; Set and move back
	call SGB_SendPacket        ; Set SGB palette
	jr .fadeOutDone            ; Proceed to play sound

.fadeOutDMG

IF DEF(INTRO_FADEOUT_DMG)

	ld a, e                    ; Load the value in E into A
	cp INTRO_FADEOUT_START     ; Start fadeout?
	jr z, .fade1               ; If true, proceed to set dark palettes
	cp INTRO_FADEOUT_MIDDLE    ; Continue fadeout?
	jr nz, .fadeOutDone        ; If true, proceed to set light palettes

.fade2
	ld a, INTRO_FADEOUT_DMG_P2 ; Set the second palette
	jr .fadeCont               ; Proceed to set palettes

.fade1
	ld a, INTRO_FADEOUT_DMG_P1 ; Set the first palette

.fadeCont
	ldh [rBGP], a              ; Set the background palette
	ldh [rOBP0], a             ; Set the default object palette

ENDC

.fadeOutDone

ENDC

IF DEF(INTRO_SONG)
	push de                    ; Save the step counter
	call hUGE_dosound          ; Play sound
	pop de                     ; Restore the step counter
ENDC

	inc e                      ; Increment the step counter
	bit 7, e                   ; Step 128 reached?
	jp z, .mainLoop            ; If not, continue to loop

IF DEF(INTRO_FADEOUT_DMG)
	ld a, INTRO_FADEOUT_DMG_P3 ; Set the final palette
	ld [rBGP], a               ; Set the background palette
	ld [rOBP0], a              ; Set the default object palette
ENDC

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


SECTION "Intro Subroutines", ROM0
IntroMain:
	ld hl, rSCX                ; Start from the background's X coordinate
	xor a                      ; Set A to zero
	sub e                      ; Negate t
	ld [hld], a                ; Set the background's X coordinate and move to Y
	ld [hl], e                 ; Set the background's Y coordinate

	ld l, LOW(rWY)             ; Start from the window's Y coordinate
	ld a, e                    ; Load t into A
	cp Y_INTRO_N2              ; Threshold reached?
	jr nc, .cont               ; If yes, skip
	add a                      ; Multiply by 2
	add Y_INTRO_N2             ; Add initial Y coordinate
	ld [hli], a                ; Set the windows's Y coordinate and move to X
	add X_INTRO_N2 - Y_INTRO_N2; Add initial X coordinate
	ld [hl], a                 ; Set the window's X coordinate
.cont

	                           ; Optimization courtesy of calc84maniac
	ld a, e                    ; Load t into A
	srl a                      ; Divide by 2
	ld c, a                    ; Store t/2 in C
	srl c                      ; Divide by 2
	srl c                      ; Divide by 2
	sub c                      ; Subtract t/8
	ld b, a                    ; Store t * 3/8 in B

	ld a, X_INTRO_TOP_0        ; Load x_-1 into A
	sub e                      ; Subtract t
	sub b                      ; Subtract t * 3/8
	ld hl, wShadowOAM + OBJ_INTRO_TOP_0 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_0 - t * 11/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_1        ; Load x_0 into A
	sub e                      ; Subtract t
	sub c                      ; Subtract t / 8
	ld l, OBJ_INTRO_TOP_1 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_0 - t * 9/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_2        ; Load x_1 into A
	sub e                      ; Subtract t
	add c                      ; Add t * 7/8
	ld l, OBJ_INTRO_TOP_2 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_1 - t * 7/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_3        ; Load x_2 into A
	sub e                      ; Subtract e
	add b                      ; Subtract t * 3/8
	ld l, OBJ_INTRO_TOP_3 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_2 - t * 5/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_4        ; Load x_3 into A
	sub b                      ; Subtract t * 3/8
	ld l, OBJ_INTRO_TOP_4 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_3 - t * 3/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_5        ; Load x_4 into A
	sub c                      ; Subtract t/8
	ld l, OBJ_INTRO_TOP_5 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_4 - t * 1/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_6        ; Load x_5 into A
	add c                      ; Add t/8
	ld l, OBJ_INTRO_TOP_6 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_5 + t * 1/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_7        ; Load x_5 into A
	add b                      ; Add t * 3/8
	ld l, OBJ_INTRO_TOP_7 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_5 + t * 3/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_8        ; Load x_7 into A
	add e                      ; Add t
	sub b                      ; Subtract t * 3/8
	ld l, OBJ_INTRO_TOP_8 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_7 + t * 5/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate

	ld a, X_INTRO_TOP_9        ; Load x_8 into A
	add e                      ; Add t
	sub c                      ; Subtract t/8
	ld l, OBJ_INTRO_TOP_9 * OBJ_SIZE + OAMA_X
	ld [hld], a                ; Store x_8 + t * 7/8 and move to the Y coordinate
	dec [hl]                   ; Decrement the Y coordinate
	
	ld l, OBJ_INTRO_0 * OBJ_SIZE

.metaLoop
	inc d                      ; Advance to the Y/X page
	push de                    ; Save the page and the step counter
	push hl                    ; Save the destination address
	ld h, d                    ; Load the page into H
	ld l, e                    ; Load the step into L
	ld d, [hl]                 ; Load the Y value
	set 7, l                   ; Advance to the second half-page
	ld e, [hl]                 ; Load the X value
	inc h                      ; Advance to the tile/attrs page
	ld c, [hl]                 ; Load the attributes value
	res 7, l                   ; Go back to the first half-page
	ld b, [hl]                 ; Load the tile ID value
	pop hl                     ; Restore the destination address
	call SetMetaObject         ; Set the meta-object
	pop de                     ; Restore the page and the step counter
	inc d                      ; Advance to the tile/attrs page
	ld a, l                    ; Load the value in L into A
	cp OBJ_INTRO_META_END * OBJ_SIZE ; End meta-object reached?
	jr nz, .metaLoop           ; If not, continue to loop

.dblLoop
	inc d                      ; Advance to the Y/X page
	push de                    ; Save the page and the step counter
	push hl                    ; Save the destination address
	ld h, d                    ; Load the page into H
	ld l, e                    ; Load the step into L
	ld d, [hl]                 ; Load the Y value
	set 7, l                   ; Advance to the second half-page
	ld e, [hl]                 ; Load the X value
	inc h                      ; Advance to the tile/attrs page
	ld c, [hl]                 ; Load the attributes value
	res 7, l                   ; Go back to the first half-page
	ld b, [hl]                 ; Load the tile ID value
	pop hl                     ; Restore the destination address
	call SetDoubleObject       ; Set the double-object
	pop de                     ; Restore the page and the step counter
	inc d                      ; Advance to the tile/attrs page
	ld a, l                    ; Load the value in L into A
	cp OBJ_INTRO_END * OBJ_SIZE; End double-object reached?
	jr nz, .dblLoop            ; If not, continue to loop
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
	ld hl, wShadowOAM + OBJ_INTRO_TOP_0 * OBJ_SIZE
	ld bc, T_INTRO_TOP_0 << 8  ; Load tile ID and attributes
	ld de, Y_INTRO_INIT << 8 | X_INTRO_TOP_0
	call SetObject             ; Set the N object

FOR I, 1, INTRO_TOP_COUNT
	INTRO_TOP_INIT {d:I}
ENDR
	; Fall through

InitReg:
IF T_INTRO_REG != T_INTRO_TOP_9 + 1
	ld b, T_INTRO_REG          ; Load tile ID
ENDC
	                           ; Compensate for width adjustment
	ld de, Y_INTRO_REG << 8 | (X_INTRO_REG + 2)
ASSERT (B_FLAGS_DMG0 == B_OAM_PAL1)
	ldh a, [hFlags]            ; Load our flags into the A register
	and FLAGS_DMG0             ; Isolate the DMG0 flag
	ld c, a                    ; Load attributes
	; Fall through

SetNextTopObject:
	dec e                      ; Adjust width
	dec e                      ; ...
	; Fall through

SetObject::
	ld a, d                    ; Load the Y coordinate from D
.cont1
	ld [hli], a                ; Set the Y coordinate
	ld a, e                    ; Load the X coordinate from E
	ld [hli], a                ; Set the X coordinate
	add TILE_WIDTH             ; Advance the X coordinate
	ld e, a                    ; Store the updated X coordinate
.cont2
	ld a, b                    ; Load the tile ID from B
	ld [hli], a                ; Set the tile ID
	inc b                      ; Advance the tile ID
	ld a, c                    ; Load the attributes from C
	ld [hli], a                ; Set the attributes
	ret

InitBottom:
	ld hl, wShadowOAM + OBJ_INTRO_0 * OBJ_SIZE

FOR I, 6
	INTRO_BOTTOM_INIT {d:I}
ENDR

SetMetaObject:
	call SetDoubleObject       ; Set the first double-object
	bit B_OAM_XFLIP, c         ; Is it flipped?
	jr z, SetDoubleObject      ; If not, continue
	ld a, b                    ; Load the tile ID into A
	sub 4                      ; Adjust tile ID
	ld b, a                    ; Store the new tile ID in B
	; Fall through

SetDoubleObject:
	ld a, d                    ; Load the Y coordinate from D
	ld [hli], a                ; Set the Y coordinate
	ld a, e                    ; Load the X coordinate from E
	ld [hli], a                ; Set the X coordinate
	call SetObject.cont2       ; Proceed to set the tile ID + attributes

	ld a, d                    ; Load the Y coordinate from D
	add TILE_HEIGHT            ; Advance the Y coordinate
	jr SetObject.cont1         ; Proceed to set object


IF DEF(COLOR8)

Color8:
	ld b, 1                    ; Set the palette to 1
	call SetByAttrs            ; Set attributes

	ld hl, wShadowOAM + OBJ_INTRO_TOP_0 * OBJ_SIZE + OAMA_TILEID
	ld a, T_INTRO_NOT_2
	ld [hl], a
	ld l, OBJ_INTRO_TOP_1 * OBJ_SIZE + OAMA_TILEID
	inc a
	ld [hl], a
	ld l, OBJ_INTRO_TOP_2 * OBJ_SIZE + OAMA_TILEID
	ld a, T_INTRO_TOP_2_2
	ld [hli], a
	ld a, 1
	ld [hl], a
FOR I, 3, INTRO_TOP_COUNT
	ld l, OBJ_INTRO_TOP_{d:I} * OBJ_SIZE + OAMA_FLAGS
	ld [hl], a
	inc a
ENDR

	ret

ENDC

InitOAndBy:
	INIT_VRAM_HL INTRO_O       ; Load the meta-tile address into the HL register
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, T_INTRO_TOP_O        ; Load left tile ID
	call .do                   ; Set O's tiles
	ld l, ROW_INTRO_BY * TILEMAP_WIDTH + COL_INTRO_BY
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, T_INTRO_BY           ; Load left tile ID
	ld [hli], a                ; Set left tile
	ld a, T_INTRO_BY_1         ; Load middle tile ID
.do
	ld [hli], a                ; Set middle tile
	inc a                      ; Increment tile ID
	ld [hl], a                 ; Set right tile
	ret

SetByAttrs::
	INIT_VRAM_HL INTRO_TOP     ; Load the top row's address into the HL register
	ld a, VBK_BANK             ; Set A to one
	ldh [rVBK], a              ; Switch the VRAM bank to attributes
	ld a, b                    ; Load the attributes into A
.loop
	ld [hli], a                ; Set attributes
	bit 5, l                   ; Row boundary crossed?
	jr nz, .loop               ; If not, keep looping
	xor a                      ; Set A to zero
	ldh [rVBK], a              ; Switch the VRAM bank back to tile IDs
	ret

SetPalettes:
	ld hl, rBGPI
	call SetPalette

IF DEF(COLOR8)

FOR I, 2, INTRO_TOP_COUNT
	ld a, OBPI_AUTOINC | (I - 2) << 3 | 2
	ld [hli], a
IF I == 2
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
	ld bc, C_INTRO_TOP_0
	ld [hl], c
	ld [hl], b
	ld bc, C_INTRO_TOP_1
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
IF I == 3
	ld bc, C_INTRO_TOP_2
	ld [hl], c
	ld [hl], b
ENDC
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
	ld [hl], a
ELSE
	ld bc, C_INTRO_BOTTOM
	ld [hl], c
	ld [hl], b
ENDC

REPT 4
	ld [hl], a
ENDR

IF LOW(C_INTRO_BACK) == HIGH(C_INTRO_BACK)
	ld a, LOW(C_INTRO_BACK)
	ld [hl], a
	ld [hl], a
ELSE
	ld bc, C_INTRO_BACK
	ld [hl], c
	ld [hl], b
ENDC

IF LOW(C_INTRO_BY1) == HIGH(C_INTRO_BY1)
	ld a, LOW(C_INTRO_BY1)
	ld [hl], a
	ld [hl], a
ELSE
	ld bc, C_INTRO_BY1
	ld [hl], c
	ld [hl], b
ENDC

IF LOW(C_INTRO_BY2) == HIGH(C_INTRO_BY2)
	IF C_INTRO_BY2 != C_INTRO_BY1
		ld a, LOW(C_INTRO_BY2)
	ENDC
	ld [hl], a
	ld [hl], a
ELSE
	IF C_INTRO_BY2 != C_INTRO_BY1
		ld bc, C_INTRO_BY2
	ENDC
	ld [hl], c
	ld [hl], b
ENDC

IF LOW(C_INTRO_TOP_O) == HIGH(C_INTRO_TOP_O)
	IF C_INTRO_TOP_O != C_INTRO_BY2
		ld a, LOW(C_INTRO_TOP_O)
	ENDC
	ld [hl], a
	ld [hli], a
ELSE
	IF C_INTRO_TOP_O != C_INTRO_BY2
		ld bc, C_INTRO_TOP_O
	ENDC
	ld [hl], c
	ld [hl], b
	inc l
ENDC

	ret


SECTION "IntroInitSGB", ROM0
IntroInitSGB:

	ld e, INTRO_SGB_DELAY      ; ~1 sec delay to make up for the SGB bootup animation

IF DEF(INTRO_FADEIN_SGB)

	call Sleep                 ; Sleep

.fadeInLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld a, e                    ; Load the value in E into A
	ld hl, FadeInSGBLUT        ; Load LUT address into HL
	call ReadLUT               ; Read color
	ld hl, wPacketBuffer + 2   ; Load the background's address into HL
	ld [hld], a                ; Set and move back
	ld a, b                    ; Load the background's lower byte into A
	ld [hld], a                ; Set and move back
	call SGB_SendPacket        ; Set SGB palette
	inc e                      ; Increment the step counter

ASSERT(INTRO_FADEIN_SGB_LENGTH == 1 << TZCOUNT(INTRO_FADEIN_SGB_LENGTH))

	bit TZCOUNT(INTRO_FADEIN_SGB_LENGTH) + 1, e
	jr z, .fadeInLoop          ; If length not reached, continue to loop
	ret

ELSE

	; Fall through

ENDC

Sleep:
	rst WaitVBlank             ; Wait for the next VBlank
	dec e                      ; Decrement the counter
	jr nz, Sleep               ; Continue to loop unless zero
	ret


IF DEF(INTRO_FADEIN_SGB) || DEF(INTRO_FADEOUT)

SECTION "ReadLUT", ROM0
ReadLUT:
	add l                      ; Add lower address byte
	ld l, a                    ; Load the result into L
	res 0, l                   ; Clear the lowest bit
	jr ReadSGBLUT2.cont        ; Proceed to read the values

ReadSGBLUT2:
	add a                      ; Multiply by 2
	add l                      ; Add lower address byte
	ld l, a                    ; Load the result into L
	res 1, l                   ; Clear the 2nd lowest bit
	ld d, [hl]                 ; Load the background's lower byte into D
	inc l                      ; Increment lower LUT address byte
	ld c, [hl]                 ; Load the background's upper byte into C
	inc l                      ; Increment lower LUT address byte
.cont
	ld b, [hl]                 ; Load the foreground's lower byte into B
	inc l                      ; Increment lower LUT address byte
	ld a, [hl]                 ; Load the foreground's upper byte into A
	ret

ENDC


IF DEF(INTRO_FADEOUT)

SECTION "ReadLUT2", ROM0
ReadLUT2:
	add a                      ; Multiply by 2
	add l                      ; Add lower address byte
	ld l, a                    ; Load the result into L
	res 1, l                   ; Clear the 2nd lowest bit
	ld a, [hl]                 ; Load the background's lower byte into A
	inc l                      ; Increment lower LUT address byte
	ld d, [hl]                 ; Load the background's upper byte into D
	inc l                      ; Increment lower LUT address byte
	ld c, [hl]                 ; Load the foreground's lower byte into C
	inc l                      ; Increment lower LUT address byte
	ld b, [hl]                 ; Load the foreground's upper byte into B
	ret

ENDC


IF DEF(INTRO_FADEIN_SGB)

SECTION "FadeInSGBLUT", ROM0, ALIGN[1]
FadeInSGBLUT:
	FADEIN_LUT INTRO_FADEIN_SGB, C_INTRO_INIT_SGB, C_INTRO_BACK_SGB

ENDC


IF DEF(INTRO_FADEOUT)

SECTION "FadeOutLUT", ROM0, ALIGN[2]
IF C_INTRO_BOTTOM_SGB == C_INTRO_BOTTOM && C_INTRO_BACK_SGB == C_INTRO_BACK && C_INTRO_FADEOUT_SGB == C_INTRO_FADEOUT
FadeOutSGBLUT:
ENDC
FadeOutLUT:
	FADE_LUT INTRO_FADEOUT, C_INTRO_BACK, C_INTRO_BOTTOM, C_INTRO_FADEOUT

IF C_INTRO_BOTTOM_SGB != C_INTRO_BOTTOM || C_INTRO_BACK_SGB != C_INTRO_BACK || C_INTRO_FADEOUT_SGB != C_INTRO_FADEOUT

SECTION "FadeOutSGBLUT", ROM0, ALIGN[2]
FadeOutSGBLUT:
	FADE_LUT INTRO_FADEOUT, C_INTRO_BACK_SGB, C_INTRO_BOTTOM_SGB, C_INTRO_FADEOUT_SGB

ENDC

ENDC


SECTION "SGB Packet Buffer", WRAM0, ALIGN[8]
wPacketBuffer:
	ds SGB_PACKET_SIZE


IF DEF(INTRO_GRADIENT)

SECTION "IntroColorLUT", ROMX
IntroColorLUT:
	GRADIENT_LUT C_INTRO_GRADIENT_TOP, C_INTRO_GRADIENT_BOTTOM

ENDC
