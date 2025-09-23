; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "intro.inc"


MACRO INTRO_DBL_INIT
	ld hl, MAP_INTRO_\1 + ROW_INTRO_\1 * TILEMAP_WIDTH + COL_INTRO_\1
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, T_INTRO_\1           ; Load left tile ID
	ld [hli], a                ; Set left tile and advance to the right
	inc a                      ; Base + 1
	ld [hl], a                 ; Set right tile
ENDM

MACRO INTRO_TOP_INIT
DEF _ = (\1 - 1)
IF \1 && T_INTRO_TOP_\1 != T_INTRO_TOP_{d:_} + 1
	ld b, T_INTRO_TOP_\1       ; Load tile ID
ENDC
	ld e, X_INTRO_TOP_\1       ; Load X coordinate
	call SetObject             ; Set the object
ENDM


SECTION "Intro", ROM0
Intro::
	ldh a, [hFlags]            ; Load our flags into the A register
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	call nz, SetPalettes       ; If yes, set palettes

	call InitTop               ; Initialize our objects

.clearOAMLoop
	xor a                      ; Set A to zero
	ld [hli], a                ; Set and advance
	ld a, l                    ; Load the lower address byte into A
	cp OAM_SIZE                ; End of OAM reached?
	jr nz, .clearOAMLoop       ; If not, continue looping

	ld de, IntroTiles
	ld hl, STARTOF(VRAM) | T_INTRO_START << 4
	COPY_1BPP_SAFE Intro       ; Copy 1bpp tiles

	call ClearBackground       ; Clear the logo from the background
	INTRO_DBL_INIT BY          ; Draw BY on the background
	call SetWindow             ; Draw the logo on the window

	ld a, Y_INTRO_TOP          ; Load the initial Y value into A
	ldh [rSCY], a              ; Set the background's Y coordinate
	ld a, Y_INTRO_WINDOW       ; Load the initial WY value into A
	ldh [rWY], a               ; Set the window's Y coordinate
	ld a, WX_OFS               ; Load the window's X value into A
	ldh [rWX], a               ; Set the window's X coordinate

	ld a, %11_11_11_00         ; Display everything as black
	ldh [rOBP0], a             ; Set the default object palette
	xor a                      ; Display everything as white
	ldh [rOBP1], a             ; Set the alternate object palette
	
	ld a, IE_VBLANK            ; Load the flag to enable the VBlank and STAT interrupts into A
	ldh [rIE], a               ; Load the prepared flag into the interrupt enable register
	xor a                      ; Set A to zero
	ldh [rIF], a               ; Clear any lingering flags from the interrupt flag register to avoid false interrupts

	call VBlank                ; Perform our OAM DMA and enable interrupts!

	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON | LCDC_WIN_ON | LCDC_WIN_9C00
	ldh [rLCDC], a             ; Enable and configure the LCD

	ldh a, [hFlags]            ; Load our flags into the A register
	ld c, a                    ; Store the flags in the C register
	bit B_FLAGS_SGB, a         ; Are we running on SGB?
	jr z, .drop                ; If not, skip the SGB delay

	ld b, INTRO_SGB_DELAY      ; ~1 sec delay to make up for the SGB bootup animation
.waitLoop
	rst WaitVBlank             ; Wait for the next VBlank
	dec b                      ; Decrement the counter
	jr nz, .waitLoop           ; Continue to loop unless zero

.drop
	ld e, 0                    ; Use E as our step counter
.loop
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

.regDone
	call hFixedOAMDMA          ; Prevent lag
	inc e                      ; Increment the step counter
	jr nz, .loop               ; Continue to loop unless 256 reached

LoopForever:
	halt
	jr LoopForever


SECTION "Intro Subroutines", ROM0

ClearBackground:
	ld hl, MAP_LOGO + ROW_LOGO * TILEMAP_WIDTH + COL_LOGO
	call ClearLogo
	ld l, LOW(((ROW_LOGO + 1) * TILEMAP_WIDTH) + COL_LOGO)
	; Fall through

ClearLogo:
	ld c, LOGO_WIDTH + 1       ; Clear ®
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	xor a
	ld [hli], a
	dec c
	jr nz, .loop
	ret

SetWindow:
	ld hl, TILEMAP1 + COL_LOGO
	ld b, T_LOGO
	call .logo
	ld l, TILEMAP_WIDTH + COL_LOGO
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
	call SetTwoObjects         ; Set the meta-object

FOR I, 8
	INTRO_TOP_INIT {d:I}
ENDR
	; Fall through

InitReg:
	ld b, T_INTRO_REG          ; Load tile ID
	ld de, Y_INTRO_REG << 8 | X_INTRO_REG
ASSERT (B_FLAGS_DMG0 == B_OAM_PAL1)
	ldh a, [hFlags]            ; Load our flags into the A register
	and 1 << B_FLAGS_DMG0      ; Isolate the DMG0 flag
	ld c, a                    ; Load attributes
	jr SetObject               ; Set the object and return

SetTwoObjects:
	call SetObject             ; Set the first object
	; Fall through

SetObject:
	ld a, d                    ; Load the X coordinate from D
	ld [hli], a                ; Set the Y coordinate
	ld a, e                    ; Load the X coordinate from E
	ld [hli], a                ; Set the X coordinate
	add TILE_WIDTH             ; Advance the X coordinate
	ld e, a                    ; Store the updated X coordinate
	ld a, b                    ; Load the tile ID from B
	ld [hli], a                ; Set the tile ID
	inc b                      ; Advance the tile ID
	ld a, c                    ; Load the attributes from C
	ld [hli], a                ; Set the attributes
	ret

SetPalettes:
	ld hl, rBGPI
	call SetPalette
	; Fall through

SetPalette:
	ld a, BGPI_AUTOINC
	ld [hli], a
	ld a, $FF
	ld [hl], a
	ld [hl], a
	cpl
REPT 5
	ld [hl], a
ENDR
	ld [hli], a
	ret


SECTION "Intro Tile data", ROM0

IntroTiles:
	INCBIN "intro_reg.1bpp"
	INCBIN "intro_not.1bpp"
	INCBIN "intro_top.1bpp"
	INCBIN "intro_by.1bpp"
.end
