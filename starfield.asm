; 10 SYS (2096)

GenerateTo      starfield.prg
DebugStartAddress       start

Incasm "vicii.asm""
Incasm "macros.asm"

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $39, $36, $29, $00, $00, $00

*=$830

screen = $8400
chars  = $b000
charsetend = $bfff

; starscroller
starchar = 36
star_chars0 = chars+288
star_chars1 = chars+296

; *********************
; ZERO PAGE VARIABLES
; *********************

; VARIABLES
scrptr          = $10    ; For character filling
atemp           = $12    ; Store A sometimes
framect         = $13 
curcolor        = $14   ; word 
curptr          = $16   ; generic pointer 
curscrnptr      = $18   ; generic screen pointer
delay           = $20
delta           = $21   ; delta characters for screen scroll

; temp variables for programs:
; $ff descending



ob_type = 0
ob_h    = 1        
ob_l    = 2
ob_y    = 3
ob_x1   = 4
        
start
        
        jsr     initlevel

        ; disable CIA interrupt (Is this on by default for BASIC?)
        ; This is important or the copy char routine will crash for some reason
        lda $dc0e
        and #$fe
        sta $dc0e
        ; disable all CPU interrupt
        sei
        
        jsr initmultable

        ; DEBUG HERE
        ; END DEBUG

        lda $1 
        and #$fb
        sta $1   ; CHAR ROM VISIBLE AT $D000


        ; **********
        ; Copy chars
        ; **********

        ; https://www.pagetable.com/c64ref/c64disasm/
        lda #$0
        ldy #$d0
        sta 95
        sty 96
        lda #$ff 
        ldy #$df
        sta 90
        sty 91
        lda #<charsetend         ; must keep these values in a and y
        ldy #>charsetend
        sta 88
        sty 89
        jsr $a3bf       ; block copy

        lda $1
        and #$f8
        ora #$05        ; All RAM, except for i/o
        sta $1         


                
        ; VIC II ON BANK 2 ($8000-$BFFF)
        lda CIAB_PRA
        and #$fc
        ora #$1          
        sta CIAB_PRA
        

        ; select VIC character bank to $3000
        lda VIC_MEM     ; default $15
        and #$f0
        ora #$0c
        sta VIC_MEM       ; $1c


        ; ******************************************
        ; Fill screen with alternating BC characters
        ; ******************************************

        movew screen, scrptr        
        ldx #25                ; 25 lines
        lda #starchar          ; first of two alternating chars
@rowloop
        ldy #39
@loop        
        sta (scrptr),y
        eor #$1                 ; Other character
        dey
        bpl @loop
        
        eor #$1
        
        sta atemp                
        addaw 40,scrptr         ; scrptr += 40
        lda atemp
        
        dex
        bne @rowloop

        ; ************
        ; Setup Colors
        ; ************
        lda     #$0
        sta     $d020   ; border
        sta     $d021   ; background


        lda     #<VIC_COLOR
        sta     curcolor
        lda     #>VIC_COLOR
        sta     curcolor+1

        lda     #VIC_BLUE 
        jsr     triband
        lda     #VIC_LIGHTBLUE
        jsr     triband
        lda     #VIC_YELLOW
        jsr     triband
        lda     #VIC_WHITE
        jsr     triband
        lda     #VIC_WHITE
        jsr     triband
        lda     #VIC_YELLOW
        jsr     triband
        lda     #VIC_LIGHTRED
        jsr     triband
        lda     #VIC_RED
        jsr     triband


        ; ********************
        ; Prep star characters
        ; ********************

        ; Stars are on line 3
        ; and on line 7
        lda #$0
        ldx #15
@nulchar
        sta star_chars0,x
        dex
        bpl @nulchar

        lda #$10
        sta star_chars0+3
        lda #$02
        sta star_chars1+7



        ; *********
        ; MAIN LOOP
        ; *********

        lda     #$00
        sta     framect
forever

        lda     #$ff
WAIT
        cmp     VIC_RASTER
        bne     WAIT

        lda     #VIC_RED
        sta     VIC_BORDERC

;**********************
; BACKGROUND SCROLLING
;**********************

        ; Scroll fast star
        clc
        lda     star_chars1+3 
        rol
        sta     star_chars1+3
        lda     star_chars0+3
        rol
        sta     star_chars0+3
        bcc     @nol
        lda     star_chars1+3
        ora     #$01
        sta     star_chars1+3
@nol        

        ; Check if scroll slow star
        ldx     framect
        inx     
        stx     framect
        txa     
        and     #$01
        bne     @nos

        ; Scroll low star
        clc
        lda     star_chars1+7
        rol
        sta     star_chars1+7
        lda     star_chars0+7
        rol
        sta     star_chars0+7
        bcc     @nor
        lda     star_chars1+7
        ora     #$01
        sta     star_chars1+7
@nor
        
    
@nos


; 1 scroll screen 1 char at a time
; 2 restore background
; create lines by "level design"
; add sprite   -> FUN
; scroll screen at fine resolution
; fix background at fine resolution

        
; ******************
; SCROLL FRONT 
; ******************
        
        ; for each objects

        ; if x1 is negative, skip this.
        ; at x1-delta
        ; DRAW FRONT
        ; if DELTA >1
        ; for each remaining delta, draw middle

        ; subtract delta from l
        ; subtract delta from x1

        ; IF l <=0
        ; Draw end at l+39
        ; if l+39 <0 , reset object
        ; draw backgrounds for each DELTA

        ; done
o0_fu=85
o0_fm=66
o0_fb=74
o0_mu=67
o0_mm=102
o0_mb=67
o0_bu=73
o0_bm=72
o0_bb=75


        ; (We may not need x2)
objectgen

; VARIABLES
@curobj          = $ff   ; current object offset, byte
@vh              = $fe   ; just a variable
@unused           = $fd   ; 
@hflag           = $fc   ; paint head ?
@vhx             = $fb   ; current object x (where head is)
@hfollowlen      = $fa   ; how long the trail after painting the head
@hfskiplen       = $f9   ; how many chars to skip before painting the head trail
@vtx             = $f8   ; current object x (where head is)
@vtc             = $f7   ; current object x (where head is)

        lda     #VIC_BLUE
        sta     VIC_BORDERC


        lda     #1              ; scroll 0-4
        sta     delta           ; Just fixed scrolling by 2

        ; object ptr
        ldx     #0
        stx     @curobj


        lda     ob_type+objtable,x      ; test if object is LIVE
        bne     @dothisobject
        jmp     endobj

@dothisobject

        ; ******
        ; Set vh counter
        ; ******
        ldy     ob_h+objtable,x
        dey
        sty     @vh

        ; ******
        ; Move object left
        ; ******
        lda     ob_x1+objtable,x
        sec
        sbc     delta
        sta     ob_x1+objtable,x

        ; @vhx x where the head goes, negative if no head
        ; @vtx x where the tail goes, negative if no tail
        ; @vtc count of how many tails to paint
        cmp     #0
        bmi     @nohead         ; less than 0, no head painted
        cmp     #40
        bpl     @nohead         ; 40 or more, no head (no tail either)
        sta     @vhx            ; head is at x1
        jmp     @checktail
@nohead
        lda     #-1
        sta     @vhx

@checktail
        lda     ob_x1+objtable,x       ; this+1 to this+delta is tail
        cmp     #-1
        bmi     @tailleft
; x0 >= -1
        cmp     #39
        bpl     @notail
        
        clc
        adc     #1      
        sta     @vtx                    ; tail is at X1+1

        lda     #40
        sec
        sbc     @vtx
        cmp     delta
        bpl     @biggerdelta
        
        sta     @vtc
        jmp     @taildone

@biggerdelta
        lda     delta
        sta     @vtc
        jmp     @taildone
               
; x0 < -1
@tailleft
        clc
        adc     delta                   ; x0+delta
        ; 0 or above, means we paint 
        bmi     @notail
        adc     #1
        sta     @vtc    ; how many trailing chars to pain
        lda     #0
        sta     @vtx    ; all get painted at zero
        jmp     @taildone
@notail
        lda     #-1
        sta     @vtx    ; no tail paints at all
@taildone        
        ; prepare scrnptr
        lda     ob_y+objtable,x         ; curscrnptr = *(multable+o.y*2)
        asl
        tax                             ; x = o.y*2
        lda     multable,x
        sta     curscrnptr
        lda     multable+1,x
        sta     curscrnptr+1

painttop        
        ldy     @vhx
        bmi     @nohead
        lda     #o0_fu
        sta     (curscrnptr),y
        
@nohead
        ldy     @vtx
        bmi     @notail
        ldx     @vtc
        lda     #o0_mu
@moretail
        sta     (curscrnptr),y
        iny
        dex
        bne     @moretail
@notail

nextrow
        ; Next row
        clc                             ; 2
        lda     curscrnptr              ; 3 curscrnptr += 40
        adc     #40                     ; 2
        sta     curscrnptr              ; 3
        lda     curscrnptr+1            ; 3
        adc     #0                      ; 2
        sta     curscrnptr+1            ; 3
                                        
        ; check if we need to paint the middle
        dec     @vh
        bmi     paintend
        beq     paintbottom
paintmiddle
        ldy     @vhx
        bmi     @nohead
        lda     #o0_fm
        sta     (curscrnptr),y
        
@nohead
        ldy     @vtx
        bmi     @notail
        ldx     @vtc
        lda     #o0_mm
@moretail
        sta     (curscrnptr),y
        iny
        dex
        bne     @moretail
@notail
        jmp     nextrow 

paintbottom
        ldy     @vhx
        bmi     @nohead
        lda     #o0_fb
        sta     (curscrnptr),y
        
@nohead
        ldy     @vtx
        bmi     @notail
        ldx     @vtc
        lda     #o0_mb
@moretail
        sta     (curscrnptr),y
        iny
        dex
        bne     @moretail
@notail        
        
        ; paints the end of the object
paintend


endobj
        ldx     @curobj                  ; restore cur obj pointer in X
                ; go the next object, put the current object in x again
        
        

        lda     #VIC_BLACK
        sta     VIC_BORDERC

        jmp     forever


; ****************************************
; PAINTS 3 ROW WITH COLOR IN A
; input: curcolor current color pointer
; ****************************************

triband
        ldy     #0
@nextcolor
        sta     (curcolor),y
        iny
        cpy     #120
        bne     @nextcolor
        
        addaw   120, curcolor

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

initlevel
        lda     #1
        sta     delta   ; scroll by 1 for now
        

;       Init objtable with "DEMO" object
        lda     #1
        sta     objtable+ob_type
        lda     #20
        sta     objtable+ob_h
        lda     #20
        sta     objtable+ob_l
        lda     #3
        sta     objtable+ob_y
        lda     #40
        sta     objtable+ob_x1


        lda     #0
        sta     delay

        rts


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

multable
        DCW 25,0

; Objects are 10 bytes, there are 20 of them here
objtable
        DCB 200,0
