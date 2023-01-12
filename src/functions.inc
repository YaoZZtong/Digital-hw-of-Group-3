SECTION "functions", ROM0

;function to slow down
WAIT:
    ld a, [rLY]     ; wait for vblank to properly disable lcd
    cp 144
    jp nz, WAIT

    dec hl
    ld a, h
    or l
    jp nz, WAIT
    ret   

VBlank:
    ld a, [rLY]     ; wait for vblank to properly disable lcd
    cp 144
    jp c, VBlank
    ret

COPY:
    ld a, [de]      ; start location
    ld [hli], a     ; destination
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, COPY
    ret

;function to change color
FADE_IN:
    ld a, %11111111
    ld [rBGP], a

    ld hl, 233
    call WAIT

    ld a, %11111001
    ld [rBGP], a

    ld hl, 233
    call WAIT

    ld a, %11100100
    ld [rBGP], a
    ret

FADE_OUT:
    ld a, %11100100
    ld [rBGP], a

    ld hl, 233
    call WAIT

    ld a, %11111001
    ld [rBGP], a

    ld hl, 233
    call WAIT

    ld a, %11111111
    ld [rBGP], a
    ret