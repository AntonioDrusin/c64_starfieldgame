; -----------------
; paint head macro
; -----------------
defm      paintobj
          ldy            @vhx
          bmi            @nohead
          lda            #/1
          sta            (curscrnptr),y
@nohead
          ldy            @vtx
          bmi            @notail
          ldx            @vtc
          lda            #/2
@moretail
          sta            (curscrnptr),y
          iny
          dex
          bne            @moretail
@notail
          endm


          

; ******************
; SCROLL FRONT macro
; ******************
                                   ; Characters used for scrolling
o0_fu     = 85                     ; front up
o0_fm     = 66                     ; front middle
o0_fb     = 74                     ; front bottom
o0_mu     = 67                     ; middle up
o0_mm     = 102                    ; middle middle
o0_mb     = 67                     ; middle bottom
o0_bu     = 73                     ; back up
o0_bm     = 72                     ; back middle
o0_bb     = 75                     ; back bottom
objectgen
; VARIABLES
@curobj   = $ff                    ; current object offset, byte
@vh       = $fe                    ; just a variable
@unused   = $fd                    ;
@hflag    = $fc                    ; paint head ?
@vhx      = $fb                    ; current object x (where left/right is)
@vtx      = $fa                    ; current object x (where left/right is)
@vtc      = $f9                    ; current object x (where left/right is)

paintObjects                                             
          perfMark       VIC_BLUE
          
          
          lda            #4        ; scroll 0-4
          sta            delta     ; Just fixed scrolling by 2
                                   ; object ptr
          ldx            #0
          stx            @curobj
          lda            ob_type+objtable,x; test if object is LIVE
          bne            @dothisobject
          jmp            endobj
@dothisobject
                                   ; Set vh counter
          ldy            ob_h+objtable,x
          dey
          sty            @vh
                                   ; Move object left
          lda            ob_x1+objtable,x
          sec
          sbc            delta
          sta            ob_x1+objtable,x
; *******************************
; ** LEFT SIDE
; *******************************
                                   ; if x1 is more than 4 outside, there is nothing to paint here
          cmp            #-4
          bpl            paintthis
          jmp            paintend
paintthis
                                   ; @vhx x where the head goes, negative if no head
                                   ; @vtx x where the tail goes, negative if no tail
                                   ; @vtc count of how many tails to paint
          cmp            #0
          bmi            @nohead   ; less than 0, no head painted
          cmp            #40
          bpl            @nohead   ; 40 or more, no head (no tail either)
          sta            @vhx      ; head is at x1
          jmp            @checktail
@nohead
          lda            #-1
          sta            @vhx
@checktail
          lda            ob_x1+objtable,x; this+1 to this+delta is tail
          cmp            #-1
          bmi            @tailleft
; x0 >= -1
          cmp            #39
          bpl            @notail
          clc
          adc            #1
          sta            @vtx      ; tail is at X1+1
          lda            #40
          sec
          sbc            @vtx
          cmp            delta
          bpl            @biggerdelta
          sta            @vtc
          jmp            @taildone
@biggerdelta
          lda            delta
          sta            @vtc
          jmp            @taildone
; x0 < -1
@tailleft
          clc
          adc            delta     ; x0+delta
                                   ; 0 or above, means we paint
          bmi            @notail
          adc            #1
          sta            @vtc      ; how many trailing chars to paint
          lda            #0
          sta            @vtx      ; all get painted at zero
          jmp            @taildone
@notail
          lda            #-1
          sta            @vtx      ; no tail paints at all
@taildone
; *******************************
; ** PAINT LEFT SIDE
; *******************************
          lda            #VIC_GREEN
          sta            VIC_BORDERC
                                   ; prepare scrnptr
          lda            ob_y+objtable,x; curscrnptr = *(multable+o.y*2)
          asl
          tax                      ; x = o.y*2
          lda            multable,x
          sta            curscrnptr
          lda            multable+1,x
          sta            curscrnptr+1
; -----------------
painttop
          paintobj       o0_fu,o0_mu
nextrow
                                   ; Next row just add 40 to curscrnptr
          clc                      ; 2 NEED THIS AS using INC later might leave carry on
          lda            curscrnptr; 3 curscrnptr += 40
          adc            #40       ; 2
          sta            curscrnptr; 3
          bcc            @nocarry  ; 2 not taken (1 out of 4), 3 taken (3 out of 4)
          inc            curscrnptr+1; 5 1/4 we know we have carry
@nocarry
          clc
                                   ; check if we need to paint the middle
          dec            @vh
          bmi            paintend  ; SUPPORT FOR 1 ROW OBSTACLES
          beq            paintbottom
@paintmiddle
          paintobj       o0_fm,o0_mm
          jmp            nextrow
paintbottom
          paintobj       o0_fb,o0_mb
paintend
          lda            #VIC_BLUE
          sta            VIC_BORDERC
; *******************************
; ** CALC RIGHT SIDE
; *******************************
          ldx            @curobj
                                   ; Set vh counter
          ldy            ob_h+objtable,x
          dey
          sty            @vh
          lda            ob_x1+objtable,x; left end of object
          clc
          adc            ob_l+objtable; add length of the object
          sta            ob_x2+objtable,x; store right end of object
          cmp            #-4
          bpl            paintThisRight
          jmp            paintendright
paintThisRight
                                   ; Repeat head and tail paint location calculation we did
                                   ; for the left end of object
                                   ; @vhx x where the head goes, negative if no head
                                   ; @vtx x where the tail goes, negative if no tail
                                   ; @vtc count of how many tails to paint
          cmp            #0
          bmi            @nohead   ; less than 0, no head painted
          cmp            #40
          bpl            @nohead   ; 40 or more, no head (no tail either)
          sta            @vhx      ; head is at x1
          jmp            @checktail
@nohead
          lda            #-1
          sta            @vhx
@checktail
          lda            ob_x2+objtable,x; this+1 to this+delta is tail
          cmp            #-1
          bmi            @tailleft
; x0 >= -1
          cmp            #39
          bpl            @notail
          clc
          adc            #1
          sta            @vtx      ; tail is at X1+1
          lda            #40
          sec
          sbc            @vtx
          cmp            delta
          bpl            @biggerdelta
          sta            @vtc
          jmp            @taildone
@biggerdelta
          lda            delta
          sta            @vtc
          jmp            @taildone
; x0 < -1
@tailleft
          clc
          adc            delta     ; x0+delta
                                   ; 0 or above, means we paint
          bmi            @notail
          adc            #1
          sta            @vtc      ; how many trailing chars to paint
          lda            #0
          sta            @vtx      ; all get painted at zero
          jmp            @taildone
@notail
          lda            #-1
          sta            @vtx      ; no tail paints at all
@taildone
; *******************************
; ** PAINT RIGHT SIDE
; *******************************
          perfMark       VIC_LIGHTGREEN
                                   ; prepare scrnptr
          lda            ob_y+objtable,x; curscrnptr = *(multable+o.y*2)
          asl
          tax                      ; x = o.y*2
          lda            multable,x
          sta            curscrnptr
          lda            multable+1,x
          sta            curscrnptr+1
painttopright
          paintobj       o0_bu,starchar
nextrowright
                                   ; Next row just add 40 to curscrnptr
          clc
          lda            curscrnptr; curscrnptr += 40
          adc            #40
          sta            curscrnptr
          bcc            @nocarry
          inc            curscrnptr+1
@nocarry
          clc
                                   ; check if we need to paint the middle
          dec            @vh
          bmi            paintendright; SUPPORT FOR 1 ROW OBSTACLES
          beq            paintbottomright
@paintmiddle
          paintobj       o0_bm,starchar
          jmp            nextrowright
paintbottomright
          paintobj       o0_bb,starchar
paintendright
endobj
          ldx            @curobj   ; restore cur obj pointer in X
                                   ; go the next object, put the current object in x again
          
          rts
          