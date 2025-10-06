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

MACRO INIT_COLOR_BACK
IF LOW(C_INTRO_BACK) == HIGH(C_INTRO_BACK)
	IF LOW(C_INTRO_BACK) == HIGH(rBGPI)
		ld d, h
	ELSE
		ld d, LOW(C_INTRO_BACK)
	ENDC
ELSE
	ld de, C_INTRO_BACK
ENDC
ENDM

MACRO INIT_COLOR
IF LOW(\1) != LOW(\2) && HIGH(\1) != HIGH(\2) && HIGH(\1) != LOW(\1)
	ld bc, \1
ELIF LOW(\1) != LOW(\2) && HIGH(\1) != LOW(\1)
	ld c, LOW(\1)
ELIF HIGH(\1) != HIGH(\2) && HIGH(\1) != LOW(\1)
	ld b, HIGH(\1)
ENDC
ENDM

MACRO SET_COLOR_BACK
IF LOW(C_INTRO_BACK) == HIGH(C_INTRO_BACK)
	ld [hl], d
ELSE
	ld [hl], e
ENDC
	ld [hl], d
ENDM

MACRO SET_COLOR
IF LOW(\1) == HIGH(\1)
	ld [hl], b
ELSE
	ld [hl], c
ENDC
	ld [hl], b
ENDM

MACRO SET_PALETTE
	SET_COLOR_BACK
	INIT_COLOR \2, \1
	SET_COLOR \2, \1
	INIT_COLOR \3, \2
	SET_COLOR \3, \2
	INIT_COLOR \4, \3
	SET_COLOR \4, \3
ENDM


SECTION FRAGMENT "Intro", ROM0
Intro:
	call InitTop               ; Initialize top objects
	call ClearOAM              ; Clear the remaining shadow OAM

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

IF DEF(INTRO_SONG)
	ld hl, INTRO_SONG          ; Load the song address into the HL register
	call hUGE_init             ; Initialize song
ENDC

	ldh a, [hFlags]            ; Load our flags into the A register

IF DEF(INTRO_FADEIN_GBC)

	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	jr z, .initCont            ; If not, proceed to try initializing SGB

	ld e, 0                    ; Use E as our step counter
.fadeInLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld a, e                    ; Load the step counter into A
	ld hl, FadeInGBCLUT        ; Load LUT address into HL
	call ReadLUT2              ; Read color values
	ldh [hColorLow], a         ; Set the background color's lower byte
	ld a, d                    ; Load the background's upper byte into A
	ldh [hColorHigh], a        ; Set the background color's upper byte
	ld hl, rBGPI               ; Load the index register address into HL
	ld a, BGPI_AUTOINC         ; Start at color 0 and autoincrement
	ld [hli], a                ; Set index register and advance to value register
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ldh a, [hColorLow]         ; Load the background's lower byte into A
	ld [hl], a                 ; Set the background's lower byte
	ld [hl], d                 ; Set the background's upper byte
	ld [hl], c                 ; Set the foreground's lower byte
	ld [hl], b                 ; Set the foreground's upper byte
	inc e                      ; Increment the step counter
ASSERT(INTRO_FADEIN_GBC_LENGTH == 1 << TZCOUNT(INTRO_FADEIN_GBC_LENGTH))
	bit TZCOUNT(INTRO_FADEIN_GBC_LENGTH) + 1, e
	jr z, .fadeInLoop          ; If length not reached, continue to loop
	
	call SetPalettes           ; Set the remaining palettes
	jr .drop                   ; Proceed to drop

.initCont

ENDC

	and FLAGS_SGB              ; Are we running on SGB?
	call nz, IntroInitSGB      ; If yes, initialize SGB

.drop
	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_DMG0, a        ; Are we running on DMG0?
	jr nz, .dropCont           ; If yes, skip the ® object

.initReg
	ld bc, T_INTRO_REG << 8    ; Load tile ID and attributes
	ld de, Y_INTRO_REG << 8 | X_INTRO_REG
	ld hl, wShadowOAM + OBJ_INTRO_REG * OBJ_SIZE
	call SetObject             ; Set the ® object
	call hFixedOAMDMA          ; Prevent flicker

.dropCont
	ld e, 0                    ; Use E as our step counter
	INIT_VRAM_HL REG2          ; Load the window ® address into the HL register
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld [hl], e                 ; Clear ®

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

	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_DMG0, a        ; Are we running on DMG0?
	jr nz, .regDone            ; If yes, skip the ® object

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

IF DEF(INTRO_COLOR8)

	ld a, e                    ; Load the value in E into A
	cp INTRO_COLOR8_STEP       ; Coloration step reached?
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
	ld hl, STARTOF(VRAM) | T_INTRO_BY << 4 | 1
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
	ld l, LOW(T_INTRO_BY_1 << 4)

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
	call FadeOutGBC            ; Set color values
	jr .fadeOutDone            ; Proceed to play sound

.fadeOutSGB
	ld hl, FadeOutSGBLUT       ; Load LUT address into HL
	call ReadLUT2              ; Read color values
	call SGB_SetColors01       ; Set SGB colors
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
	call .logo                 ; Set the first row
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, T_REG                ; Load ®'s tile ID into A
	ld [hl], a                 ; Set ®
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


SECTION "SetObject", ROM0
InitTop:
	ld hl, wShadowOAM + OBJ_INTRO_TOP_0 * OBJ_SIZE
	ld bc, T_INTRO_TOP_0 << 8  ; Load tile ID and attributes
	ld de, Y_INTRO_INIT << 8 | X_INTRO_TOP_0
	call SetObject             ; Set the N object
	ld e, X_INTRO_TOP_1        ; Load X coordinate
	call SetObject             ; Set the T object
	ld e, X_INTRO_TOP_2        ; Load X coordinate
	call SetObject             ; Set the L object
	ld e, X_INTRO_TOP_3        ; Load X coordinate
	call SetObject             ; Set the I object
	ld e, X_INTRO_TOP_4 + 2    ; Load X coordinate + adjust for SetNextTopObject
	call SetNextTopObjectDouble; Set the C and E1 objects
	call SetNextTopObjectDouble; Set the N and S objects
IF !DEF(EN_GB)
	dec e                      ; Adjust the X coordinate
ENDC
	; Fall through

SetNextTopObjectDouble:
	call SetNextTopObject
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


IF DEF(INTRO_COLOR8)

Color8:
IF DEF(INTRO_COLOR8_DMG)
	ld hl, rBGP
	ld a, %11_10_11_00
	ld [hli], a
	ld a, %11_10_01_00
	ld [hli], a
	ld a, %01_11_10_00
	ld [hl], a
ENDC

	ldh a, [hFlags]            ; Load our flags into the A register
	ld b, 1                    ; Set the palette to 1
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	jr z, .nonGBC              ; If not, proceed to set top N0's tile ID
	call SetByAttrs            ; If yes, set attributes
	jr .cont

.nonGBC
	ld hl, wShadowOAM + OBJ_INTRO_TOP_0 * OBJ_SIZE + OAMA_TILEID
ASSERT (T_INTRO_TOP_0_2 == T_INTRO_TOP_0 - 1)
	dec [hl]                   ; Set top N0 to dark

.cont

FOR I, INTRO_TOP_COUNT
IF I == 0
	ld hl, wShadowOAM + OBJ_INTRO_TOP_0 * OBJ_SIZE + OAMA_FLAGS
ELSE
	ld l, OBJ_INTRO_TOP_{d:I} * OBJ_SIZE + OAMA_FLAGS
ENDC
IF I % 3 == 1
	IF DEF(INTRO_COLOR8_DMG) && I == 1
		ld b, OAM_PAL1 | 2
	ELIF DEF(INTRO_COLOR8_DMG) && I == 4
		ld b, 3
	ELSE
		inc b
	ENDC
ENDC
	ld [hl], b
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
ASSERT (T_INTRO_BY == T_INTRO_TOP_9 + 1)
	ld a, b                    ; Load left tile ID
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


SECTION "SetPalette", ROM0
SetPalettes::
	ld hl, rBGPI
	call SetPalette
	inc l

IF DEF(INTRO_COLOR8)
	ld a, OBPI_AUTOINC
	ld [hli], a
	SET_PALETTE C_INTRO_TOP_O, C_INTRO_BOTTOM, C_INTRO_BOTTOM, C_INTRO_BOTTOM
	dec l

	ld a, OBPI_AUTOINC | 12
	ld [hli], a
	INIT_COLOR C_INTRO_BOTTOM, C_INTRO_TOP_0
	SET_COLOR C_INTRO_BOTTOM, C_INTRO_TOP_0
	INIT_COLOR C_INTRO_TOP_0, C_INTRO_BOTTOM
	SET_COLOR C_INTRO_TOP_0, C_INTRO_BOTTOM

	SET_PALETTE C_INTRO_BOTTOM, C_INTRO_TOP_2, C_INTRO_TOP_3, C_INTRO_TOP_1
	SET_PALETTE C_INTRO_TOP_1, C_INTRO_TOP_4, C_INTRO_TOP_5, C_INTRO_TOP_6
	SET_PALETTE C_INTRO_TOP_6, C_INTRO_TOP_7, C_INTRO_TOP_8, C_INTRO_TOP_9
	ret
ELSE
	; Fall through
ENDC

SetPalette:
	ld a, BGPI_AUTOINC
	ld [hli], a
	INIT_COLOR_BACK
	SET_PALETTE C_INTRO_BACK, C_INTRO_BOTTOM, C_INTRO_BOTTOM, C_INTRO_BOTTOM
	SET_PALETTE C_INTRO_BOTTOM, C_INTRO_BY2, C_INTRO_BY1, C_INTRO_TOP_O
	ret


SECTION "IntroInitSGB", ROM0
IntroInitSGB:

	ld hl, wPacketBuffer + SGB_PACKET_SIZE - 1
.clearLoop
	xor a                      ; Set A to zero
	ld [hld], a                ; Set and move back
	or l                       ; Buffer start reached?
	jr nz, .clearLoop          ; If not, continue to loop

IF !DEF(INTRO_FADEIN_SGB)

	ld a, HIGH(C_INTRO_BACK_SGB) ; Load the background's upper byte into A
IF LOW(C_INTRO_BACK_SGB) == HIGH(C_INTRO_BACK_SGB)
	ld d, a                      ; Load the background's lower byte into D
ELSE
	ld d, LOW(C_INTRO_BACK_SGB)  ; Load the background's lower byte into D
ENDC
	call SGB_SetBackground01     ; Set SGB background

ENDC

	ld e, INTRO_SGB_DELAY      ; ~1 sec delay to make up for the SGB bootup animation
.sleepLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld l, LOW(wPacketBuffer)   ; Clear lower address byte
	call SGB_SetPalettes01     ; Set SGB palette
	dec e                      ; Decrement the counter
	jr nz, .sleepLoop          ; Continue to loop unless zero

IF DEF(INTRO_FADEIN_SGB)

.fadeInLoop
	call FadeSGB               ; Update SGB palette
	inc e                      ; Increment the step counter

ASSERT(INTRO_FADEIN_SGB_LENGTH == 1 << TZCOUNT(INTRO_FADEIN_SGB_LENGTH))
	bit TZCOUNT(INTRO_FADEIN_SGB_LENGTH) + 1, e
	jr z, .fadeInLoop          ; If length not reached, continue to loop

ENDC

	ret


SECTION "Sleep", ROM0
Sleep:
	rst WaitVBlank             ; Wait for the next VBlank
	dec e                      ; Decrement the counter
	jr nz, Sleep               ; Continue to loop unless zero
	ret


IF DEF(INTRO_FADEIN_SGB)

SECTION "FadeSGB", ROM0
FadeSGB::
	rst WaitVBlank             ; Wait for the next VBlank
	ld hl, FadeInSGBLUT        ; Load LUT address into HL
	ld a, e                    ; Load the step counter into A
	add l                      ; Add lower address byte
	ld l, a                    ; Load the result into L
	res 0, l                   ; Clear the lowest bit
	ld c, [hl]                 ; Load the background's lower byte into C
	inc l                      ; Increment lower LUT address byte
	ld b, [hl]                 ; Load the background's upper byte into B
	jp SGB_SetBackground01     ; Set SGB background and return

ENDC

IF DEF(INTRO_FADEIN_GBC) || DEF(INTRO_FADEOUT)

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


IF DEF(INTRO_FADEIN_GBC)

SECTION "FadeInGBCLUT", ROM0, ALIGN[1]
FadeInGBCLUT:
	FADEIN_LUT2 INTRO_FADEIN_GBC, C_INTRO_INIT_GBC, C_INTRO_BACK, C_INTRO_BOTTOM

ENDC


IF DEF(INTRO_FADEIN_SGB)

SECTION "FadeInSGBLUT", ROM0, ALIGN[1]
FadeInSGBLUT:
	FADEIN_LUT INTRO_FADEIN_SGB, C_INTRO_INIT_SGB, C_INTRO_BACK_SGB

ENDC


IF DEF(INTRO_FADEOUT)

SECTION "FadeOutGBC", ROM0
FadeOutGBC:
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
	call SetBackgroundGBC      ; Set background color
	dec l                      ; Go back to the index register
	ld a, BGPI_AUTOINC | 6     ; Start at color 3 and autoincrement
	ld [hli], a                ; Set index register and advance to value register
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld [hl], c                 ; Set the foreground's lower byte
	ld [hl], b                 ; Set the foreground's upper byte
	; Fall through

SetBackgroundGBC:
	ldh a, [hColorLow]         ; Load the background's lower byte into A
	ld [hl], a                 ; Set the background's lower byte
	ld [hl], d                 ; Set the background's upper byte
	ret


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


IF DEF(INTRO_GRADIENT)

SECTION "IntroColorLUT", ROMX
IntroColorLUT:
	GRADIENT_LUT C_INTRO_GRADIENT_TOP, C_INTRO_GRADIENT_BOTTOM

ENDC
