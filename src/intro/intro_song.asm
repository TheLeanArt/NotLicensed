include "hUGE.inc"

SECTION "Intro Song Data", ROMX

intro_song::
db 7
dw order_cnt
dw order1, order2, order3, order4
dw duty_instruments, wave_instruments, noise_instruments
dw routines
dw waves

order_cnt: db 2
order1: dw P0
order2: dw P1
order3: dw P2
order4: dw P3

P0:
 dn C_6,2,$000
 dn B_5,2,$000
 dn A#5,2,$000
 dn A_5,2,$000
 dn G#5,2,$000
 dn G_5,2,$000
 dn F#5,2,$000
 dn F_5,2,$000
 dn E_5,2,$000
 dn D#5,2,$000
 dn D_5,2,$000
 dn C#5,2,$000
 dn C_5,2,$000
 dn B_4,2,$000
 dn A#4,2,$000
 dn A_4,2,$000
 dn G#4,2,$000
 dn G_4,2,$000
 dn F#4,2,$000
 dn F_4,2,$000
 dn E_4,2,$000
 dn D#4,2,$000
 dn D_4,2,$000
 dn C#4,2,$000
 dn C_4,2,$000
 dn B_3,2,$000
 dn A#3,2,$000
 dn A_3,2,$000
 dn G#3,2,$000
 dn G_3,2,$000
 dn F#3,2,$000
 dn F_3,2,$E04
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P1:
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$000
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$000
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$000
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$000
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$000
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$000
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$000
 dn G_6,2,$000
 dn F#6,2,$000
 dn F_6,2,$000
 dn G_7,2,$E04
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P2:
 dn C#5,3,$000
 dn ___,0,$C00
 dn C#5,3,$000
 dn C_5,3,$000
 dn D_5,3,$000
 dn ___,0,$C00
 dn D_5,3,$000
 dn C_5,3,$000
 dn D#5,3,$000
 dn ___,0,$C00
 dn D#5,3,$000
 dn C_5,3,$000
 dn E_5,3,$000
 dn ___,0,$C00
 dn E_5,3,$000
 dn C_5,3,$000
 dn F_5,3,$000
 dn ___,0,$C00
 dn F_5,3,$000
 dn C_5,3,$000
 dn F#5,3,$000
 dn ___,0,$C00
 dn F#5,3,$000
 dn C_5,3,$000
 dn G_5,3,$000
 dn ___,0,$C00
 dn G_5,3,$000
 dn C_5,3,$000
 dn A#4,3,$000
 dn ___,0,$000
 dn B_4,3,$000
 dn ___,0,$E04
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P3:
 dn ___,0,$F05
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

duty_instruments:
itSquareinst1:
db 8
db 128
db 240
dw 0
db 128

itSquareinst2:
db 8
db 192
db 240
dw 0
db 128



wave_instruments:
itWaveinst1:
db 0
db 32
db 0
dw 0
db 128

itWaveinst2:
db 0
db 32
db 1
dw 0
db 128

itWaveinst3:
db 0
db 32
db 0
dw 0
db 128



noise_instruments:


routines:
__hUGE_Routine_0:

__end_hUGE_Routine_0:
ret

__hUGE_Routine_1:

__end_hUGE_Routine_1:
ret

__hUGE_Routine_2:

__end_hUGE_Routine_2:
ret

__hUGE_Routine_3:

__end_hUGE_Routine_3:
ret

__hUGE_Routine_4:

__end_hUGE_Routine_4:
ret

__hUGE_Routine_5:

__end_hUGE_Routine_5:
ret

__hUGE_Routine_6:

__end_hUGE_Routine_6:
ret

__hUGE_Routine_7:

__end_hUGE_Routine_7:
ret

__hUGE_Routine_8:

__end_hUGE_Routine_8:
ret

__hUGE_Routine_9:

__end_hUGE_Routine_9:
ret

__hUGE_Routine_10:

__end_hUGE_Routine_10:
ret

__hUGE_Routine_11:

__end_hUGE_Routine_11:
ret

__hUGE_Routine_12:

__end_hUGE_Routine_12:
ret

__hUGE_Routine_13:

__end_hUGE_Routine_13:
ret

__hUGE_Routine_14:

__end_hUGE_Routine_14:
ret

__hUGE_Routine_15:

__end_hUGE_Routine_15:
ret

waves:
wave0: db 232,100,50,34,18,34,52,86,120,153,170,170,169,151,83,16

