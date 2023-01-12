; system defines
INCLUDE "hardware.inc"
INCLUDE "tiles.inc"
INCLUDE "functions.inc"

; constants
DEF NE    EQU $00
DEF SE    EQU $01
DEF SW    EQU $02
DEF NW    EQU $03

; object count (max: 40)
DEF OBJCOUNT EQU 40

; bounce area limits
DEF WESTLIMIT EQU 8
DEF EASTLIMIT EQU 160
DEF NORTHLIMIT EQU 16
DEF SOUTHLIMIT EQU 144+8 

; variable and structures stored in RAM
DEF SHADOW_OAM EQU _RAM              ; 160 bytes
DEF DIRARRAY EQU  SHADOW_OAM+160     ; 40 bytes

; VBlank interrupt handler
SECTION "Vblank", ROM0[$40]         
    jp Shadow_OAM_Copy

SECTION "Header", ROM0[$100]
    jp EntryPoint

    ds $150 - @, 0 ; make room for the header

EntryPoint:
    ; avoid to turn the LCD off outside of VBlank

    call VBlank

    ; turn the LCD off
    ld a, 0
    ld [rLCDC], a

    ; copy the tile data
    ld de, Title    ; strat location
    ld hl, $9000    ; destination
    ld bc, TitleEnd - Title
    call COPY

    ; copy the tilemap
    ld de, Titlemap
    ld hl, $9800
    ld bc, TitlemapEnd - Titlemap
    call COPY

    ; copy the tile data
    ld de, object
    ld hl, $8000
    ld bc, objectEnd - object
    call COPY

    ; clear the OAM
    xor a, a            
    ld b, 160
    ld hl, _OAMRAM      
ClearOam0:
    ld [hli], a
    dec b
    jp nz, ClearOam0

    ld hl, _OAMRAM
    ld a, 120 + 16  ; Y direction           
    ld [hli], a         
    ld a, 0 + 8     ; X direction    
    ld [hli], a
    xor a           
    ld [hli], a
    ld [hl], a

    ; turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    ; during the first (blank) frame, initialize display registers
    ld a, %11100100
    ld [rBGP], a    ; background palette manipulation

    ; turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; during the first (blank) frame, initialize display registers
    ld a, %11100100
    ld [rBGP], a    ; background palette manipulation
    ld a, %11100100 
    ld [rOBP0], a   ; object palette manipulation
    
    ld hl, 3000     ; path length

.loop:
    ld a, [rLY]     ; wait for vblank to properly disable lcd
    cp 144
    jp nz, .loop

    ld a, [_OAMRAM + 1]
    inc a
    ld [_OAMRAM + 1], a     ; move object in x axis

    dec hl
    ld a, h
    or l

    jp nz, .loop  

;===============================================================
  Scene2:  
;----------------------01----------------------------------------
    call VBlank

    ; turn off LCD
    ld a, 0
    ld [rLCDC], a

    ; copy the tile data
    ld de, MaskBG   ; start location
    ld hl, $9000    ; destinaton
    ld bc, MaskBGEnd - MaskBG
    call COPY

    ; copy the tilemap
    ld de, MaskBGmap
    ld hl, $9800
    ld bc, MaskBGmapEnd - MaskBGmap
    call COPY

    ; turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a
    ld b, 3

; bling the mask background
.loop:
    call FADE_IN
    ld hl, 100
    call WAIT
    call FADE_OUT
    ld hl, 100
    call WAIT

    dec b
    jp nz, .loop

;-----------------------02----------------------------------
    call VBlank

    ; turn off LCD
    ld a, 0
    ld [rLCDC], a

    ; copy the tile data
    ld de, Last
    ld hl, $9000
    ld bc, LastEnd - Last
    call COPY

    ; copy the tilemap
    ld de, Lastmap
    ld hl, $9800
    ld bc, LastmapEnd - Lastmap
    call COPY

    ; turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a
    
    call FADE_IN

    ld hl, 1000
    call WAIT

;============================================================= 
Scene3:
    ld hl, 110   
    ld c, 50 

; scroll the background layer
Scroll_y:
    call VBlank

    dec c
    jp nz, Scroll_y
    ld c, 50

    ld a, [rSCY]    
    inc a   ; move down
    ld [rSCY], a

    dec hl
    ld a, h
    or l

    jp nz, Scroll_y

    ; copy the tile data
    ld de, Virus    ; start from
    ld hl, $8000    ; destination
    ld bc, VirusEnd - Virus
    call COPY

    ;clear the OAM
    ld a, 0			
    ld b, 160
    ld hl, _OAMRAM		
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; clear SHADOW OAM
    ld hl,SHADOW_OAM
    ld b, 40*4
    ld a, 0

SHADOW_OAM_clear_loop:
    ld [hl], a
    inc hl
    dec b
    jp nz,SHADOW_OAM_clear_loop

;===================CODES FROM LAB=====================================
; 1. INITIALIZE SHADOW_OAM AND DIRARRAY
; FOR EACH OBJ (FROM 0 TO OBJCOUNT-1)
;   OBJ.X   = RANDOM(WESTLIMIT, EASTLIMIT)
;   OBJ.Y   = RANDOM(NORTHLIMIT, SOUTHLIMIT)
;   OBJ.DIR = RANDOM(NE,SE,SW,NW)
    ld hl,DIRARRAY
    ld de,SHADOW_OAM
    ld b,0
init_obj_loop:
    call dir_random  
    ld [hl],a
    inc hl
    call y_random
    ld [de],a
    inc de
    call x_random
    ld [de],a
    inc de
    ld a, 0
    ld [de],a ; use first tile
    inc de
    ld [de],a ; set object flags to zero
    inc de

    inc b
    ld a,b
    cp OBJCOUNT
    jp nz, init_obj_loop

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; during the first (blank) frame, initialize display registers
    ld a, %11100100
    ld [rBGP], a    ; background palette manipulation
    ld a, %11100100
    ld [rOBP0], a   ; object palette manipulation

    ld a, IEF_VBLANK 
    ld [rIE], a
    ei  
    
; 2. MAIN LOOP
main_loop:
; UPDATE OBJECTS IN SHADOW_OAM
    ld hl,DIRARRAY
    ld de,SHADOW_OAM
    ld b,0
update_loop:
    ld a,[hl] ; get OBJ direction
    cp NE
    jp z, update_NE
    cp SE
    jp z, update_SE
    cp SW
    jp z, update_SW
    cp NW
    jp z, update_NW
end_update:
    inc hl ; next DIRARRAY location
    inc de
    inc de
    inc de
    inc de ; next SHADOW_OAM location

    inc b
    ld a,b
    cp OBJCOUNT
    jp nz, update_loop
    ; END OF UPDATE OBJECTS IN SHADOW_OAM

    halt
    nop
    jp main_loop
; use of VBlank interrup
Shadow_OAM_Copy:
    ld de, SHADOW_OAM
    ld hl, _OAMRAM
    ld b, OBJCOUNT
.loop:
    ld a, [de]
    inc e
    ld [hli], a
    ld a, [de]
    inc e
    ld [hli], a
    ld a, [de]
    inc e
    ld [hli], a
    ld a, [de]
    inc e
    ld [hli], a
    dec b
    jr nz, .loop
    reti 

;****************
;   ROUTINES
;****************

; input:
;   hl: OBJ entry in DIRARRAY
;   de: OBJ entry in OAM
update_NE:
    ld a,[de] ; Y
    cp NORTHLIMIT
    jp nz, update_NE_1
    ld a, SE
    ld [hl], a
    jp end_update
update_NE_1:
    inc de
    ld a,[de] ; X
    cp EASTLIMIT
    jp nz, update_NE_2
    ld a, NW
    ld [hl],a 
    dec de ; restore de value
    jp end_update
update_NE_2:
    inc a      ; INCREMENT X
    ld [de], a ; STORE X 
    dec de
    ld a,[de]
    dec a
    ld [de],a  ; DECREMENT Y 
    jp end_update

; input:
;   hl: OBJ entry in DIRARRAY
;   de: OBJ entry in OAM
update_SE:
    ld a,[de] ; Y
    cp SOUTHLIMIT
    jp nz, update_SE_1
    ld a, NE
    ld [hl], a
    jp end_update
update_SE_1:
    inc de
    ld a,[de] ; X
    cp EASTLIMIT
    jp nz, update_SE_2
    ld a, SW
    ld [hl],a 
    dec de ; restore de value
    jp end_update
update_SE_2:
    inc a      ; INCREMENT X
    ld [de], a ; STORE X 
    dec de
    ld a,[de]
    inc a
    ld [de],a  ; INCREMENT Y 
    jp end_update

; input:
;   hl: OBJ entry in DIRARRAY
;   de: OBJ entry in OAM
update_SW:
    ld a,[de] ; Y
    cp SOUTHLIMIT
    jp nz, update_SW_1
    ld a, NW
    ld [hl], a
    jp end_update
update_SW_1:
    inc de
    ld a,[de] ; X
    cp WESTLIMIT
    jp nz, update_SW_2
    ld a, SE
    ld [hl],a 
    dec de ; restore de value
    jp end_update
update_SW_2:
    dec a
    ld [de], a ; DECREMENT X 
    dec de
    ld a,[de]
    inc a
    ld [de],a  ; INCREMENT Y 
    jp end_update

; input:
;   hl: OBJ entry in DIRARRAY
;   de: OBJ entry in OAM
update_NW:
    ld a,[de] ; Y
    cp NORTHLIMIT
    jp nz, update_NW_1
    ld a, SW
    ld [hl], a
    jp end_update
update_NW_1:
    inc de
    ld a,[de] ; X
    cp WESTLIMIT
    jp nz, update_NW_2
    ld a, NE
    ld [hl],a 
    dec de ; restore de value
    jp end_update
update_NW_2:
    dec a
    ld [de], a ; DECREMENT X 
    dec de
    ld a,[de]
    dec a
    ld [de],a  ; DECREMENT Y 
    jp end_update

; non-trivially moving object
; return in a a random value within [WESTLIMIT, EASTLIMIT]
x_random:
    call random_byte
    ; make A fit into [0, EASTLIMIT-WESTLIMIT] interval
    cp EASTLIMIT-WESTLIMIT
    jp c, x_random_1
    sub EASTLIMIT-WESTLIMIT
x_random_1:
    add WESTLIMIT
    ret

; return in a a random value within [NORTHLIMIT, SOUTHLIMIT]
y_random:
    call random_byte
    cp SOUTHLIMIT-NORTHLIMIT
    jp c, x_random_1
    sub SOUTHLIMIT-NORTHLIMIT
y_random_1:
    add NORTHLIMIT
    ret

; return in a a random value within [0,3]
dir_random:
    call random_byte
    rra
    and %00000011
    ret

random_byte:
    ld a,[rDIV]
    xor b
    xor e
    ret


