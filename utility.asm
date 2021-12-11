; ****************************************
; PAINTS 3 ROW WITH COLOR IN A
; input: curcolor current color pointer
; ****************************************

triband
        ldy     #0
@nextcolor
        sta     (curcolor_w),y
        iny
        cpy     #120
        bne     @nextcolor
        
        addaw   120, curcolor_w

        rts

; **************************
; POINTERS TO EACH CHAR ROW
; destroys ALL registers
; **************************
initmultable
        lda     #<screen
        sta     curptr
        lda     #>screen
        sta     curptr+1

        ldx     #0
        ldy     #25

@next        
        lda     curptr          ; multable[x] = *curptr
        sta     multable,x
        inx
        lda     curptr+1
        sta     multable,x
        inx
        dey
        beq     @done           ; if (all rows done) exit
        
        clc                    ; *curptr+=40
        lda     curptr
        adc     #40
        sta     curptr
        lda     curptr+1
        adc     #0
        sta     curptr+1
        jmp     @next
        
@done
        rts


;*********************************************
;* Prints hex content of register A on screen
;*********************************************
printa
        sta     atemp
        lsr
        lsr
        lsr
        lsr
        and     #$0f
        ora     #$30
        cmp     #$3a
        bmi     @ok1
        sec
        sbc     #$39
@ok1
        sta     screen
        lda     atemp
        and     #$0f
        ora     #$30
        cmp     #$3a
        bmi     @ok2
        sec
        sbc     #$39
@ok2
        sta     screen+1
        lda     atemp
        rts