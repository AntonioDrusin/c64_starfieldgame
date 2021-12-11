; 10 SYS (2096)
GenerateTo      starfield.prg
DebugStartAddress start
Incasm    "vicii.asm""
Incasm    "macros.asm"
*=$0801
          BYTE           $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $39, $36, $29, $00, $00, $00
*=$830
screen    = $8400
chars     = $b000
charsetend = $bfff
; starscroller
starchar  = 36
star_chars0 = chars+288
star_chars1 = chars+296
; *********************
; ZERO PAGE VARIABLES
; *********************
; VARIABLES
scrptr_w  = $10                    ; For character filling
atemp     = $12                    ; Store A sometimes
framect   = $13
curcolor_w= $14                    ; word
curptr    = $16                    ; generic pointer
curscrnptr = $18                    ; generic screen pointer
unused0   = $20
delta     = $21                    ; delta characters for screen scroll
stagex_w  = $22                    ; current position of the stage
levelptr_w= $24                    ; pointer to the currently evaluated object in the level          
                    
; temp variables for programs:
; $ff descending
ob_type   = 0
ob_h      = 1
ob_l      = 2
ob_y      = 3
ob_x1     = 4
ob_x2     = 5
ob_size   = 6
          
start
          jsr            initlevel
                                   ; disable CIA interrupt (Is this on by default for BASIC?)
                                   ; This is important or the copy char routine will crash for some reason
          lda            $dc0e
          and            #$fe
          sta            $dc0e
                                   ; disable all CPU interrupt
          sei
          jsr            initmultable
                                   ; DEBUG HERE
                                   ; END DEBUG
          lda            $1
          and            #$fb
          sta            $1        ; CHAR ROM VISIBLE AT $D000
; **********
; Copy chars
; **********
                                   ; https://www.pagetable.com/c64ref/c64disasm/
          lda            #$0
          ldy            #$d0
          sta            95
          sty            96
          lda            #$ff
          ldy            #$df
          sta            90
          sty            91
          lda            #<charsetend; must keep these values in a and y
          ldy            #>charsetend
          sta            88
          sty            89
          jsr            $a3bf     ; block copy
          lda            $1
          and            #$f8
          ora            #$05      ; All RAM, except for i/o
          sta            $1
                                   ; VIC II ON BANK 2 ($8000-$BFFF)
          lda            CIAB_PRA
          and            #$fc
          ora            #$1
          sta            CIAB_PRA
                                   ; select VIC character bank to $3000
          lda            VIC_MEM   ; default $15
          and            #$f0
          ora            #$0c
          sta            VIC_MEM   ; $1c
; ******************************************
; Fill screen with alternating BC characters
; ******************************************
          movew          screen,scrptr_w
          ldx            #25       ; 25 lines
          lda            #starchar ; first of two alternating chars
@rowloop
          ldy            #39
@loop
          sta            (scrptr_w),y
          eor            #$1       ; Other character
          dey
          bpl            @loop
          eor            #$1
          sta            atemp
          addaw          40,scrptr_w; scrptr += 40
          lda            atemp
          dex
          bne            @rowloop
; ************
; Setup Colors
; ************
          lda            #$0
          sta            $d020     ; border
          sta            $d021     ; background
          lda            #<VIC_COLOR
          sta            curcolor_w
          lda            #>VIC_COLOR
          sta            curcolor_w+1
          lda            #VIC_BLUE
          jsr            triband
          lda            #VIC_LIGHTBLUE
          jsr            triband
          lda            #VIC_YELLOW
          jsr            triband
          lda            #VIC_WHITE
          jsr            triband
          lda            #VIC_WHITE
          jsr            triband
          lda            #VIC_YELLOW
          jsr            triband
          lda            #VIC_LIGHTRED
          jsr            triband
          lda            #VIC_RED
          jsr            triband
; ********************
; Prep star characters
; ********************
                                   ; Stars are on line 3
                                   ; and on line 7
          lda            #$0
          ldx            #15
@nulchar
          sta            star_chars0,x
          dex
          bpl            @nulchar
          lda            #$10
          sta            star_chars0+3
          lda            #$02
          sta            star_chars1+7
; *********
; MAIN LOOP
; *********
          lda            #$00
          sta            framect
forever
          lda            #$ff
WAIT
          cmp            VIC_RASTER
          bne            WAIT
          lda            #VIC_RED
          sta            VIC_BORDERC
;**********************
; BACKGROUND SCROLLING
;**********************
                                   ; Scroll fast star
          clc
          lda            star_chars1+3
          rol
          sta            star_chars1+3
          lda            star_chars0+3
          rol
          sta            star_chars0+3
          bcc            @nol
          lda            star_chars1+3
          ora            #$01
          sta            star_chars1+3
@nol
                                   ; Check if scroll slow star
          ldx            framect
          inx
          stx            framect
          txa
          and            #$01
          bne            @nos
                                   ; Scroll low star
          clc
          lda            star_chars1+7
          rol
          sta            star_chars1+7
          lda            star_chars0+7
          rol
          sta            star_chars0+7
          bcc            @nor
          lda            star_chars1+7
          ora            #$01
          sta            star_chars1+7
@nor
@nos


;*********************************
;** ACTIVATES OBJECTS 
;*********************************
; VARIABLES
cursrcptr = $fe          


          perfMark       VIC_LIGHTRED
activateobjects
                                   ; Increment stagex by one
          clc
          lda            stagex_w  
          adc            #1        
          sta            stagex_w  
          lda            stagex_w+1
          adc            #0        
          sta            stagex_w+1


; ******************
; SCROLL FRONT
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
                                             
paintobjects
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
          perfMark       VIC_BLACK
          jmp            forever
Incasm    "utility.asm"
initlevel
          lda            #1
          sta            delta     ; scroll by 1 for now
          
; reset stage x position
          lda            #0        
          sta            stagex_w   ; reset stage x position
          sta            stagex_w+1
          
; initialize level pointer
          lda            #<level
          sta            levelptr_w
          lda            #>level   
          sta            levelptr_w+1
          

          rts
multable
          DCW            25,0
;*****************************
; Obstacles on screen
; Objects are ob_size bytes
;*****************************
objtable
                                   ; Type, height, width, y,, x1, x2
          DCB            200,0; space for enough objects
level
          BYTE           1,4,30, 3 ; Type, height, width, y
          WORD           10        ; position within block
          BYTE           1,4,30, 15
          WORD           30
          BYTE           1,4,30, 20
          WORD           60
          BYTE           1,4,30, 20
          WORD           120