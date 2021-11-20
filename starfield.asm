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
@fflag           = $fd   ; paint head follower ?
@hflag           = $fc   ; paint head ?
@vhx             = $fb   ; current object x (where head is)
@hfollowlen      = $fa   ; how long the trail after painting the head
@hfskiplen       = $f9   ; how many chars to skip before painting the head trail

        lda     #VIC_BLUE
        sta     VIC_BORDERC


        lda     #2              ; scroll 0-4
        sta     delta           ; Just fixed scrolling by 2

        ; object ptr
        ldx     #0
        stx     @curobj


        lda     ob_type+objtable,x      ; test if object is LIVE
        bne     @dothisobject
        jmp     @endobj

@dothisobject

        ; ******
        ; Move object left
        ; ******
        lda     ob_l+objtable,x
        sec
        sbc     delta
        sta     ob_l+objtable,x        

        lda     ob_x1+objtable,x
        sec
        sbc     delta
        sta     ob_x1+objtable,x
        sta     @vhx

        ; avoid painting if x1 is >39 
        cmp     #40
        bmi     @visible
        jmp     @endobj

@visible
        ldy     #0
        lda     @vhx                    ; x1 is head of object
        bmi     @nohead                 ; if x1 is negative, no need to paint head
        ldy     #$ff
@nohead
        sty     @hflag

        lda     delta
        sta     @hfollowlen        
        sec
        lda     #39
        sbc     @vhx            
        cmp     delta
        bpl     @fullhfollow
        sta     @hfollowlen     ; this is how long is the head trail to paint.
@fullhfollow

        lda     #$ab
        jsr     printa


        ; calculate how much head trail to skip (in case the trail is too much on the left)
        sec
        lda     #-1
        sbc     @vhx
        bpl     @hfskip
        lda     #0
@hfskip
        sta     @hfskiplen

        ; how many character to _actually_ paint for the head follow length
        sec
        lda     @hfollowlen
        sbc     @hfskiplen
        sta     @hfollowlen

        ;
        ; Check if x1 is >38, in that case, no need to paint the head erase column
        ldy     #0
        cmp     #39
        bpl     @nofollow               ; No need to paint the slice next to head
        ldy     #$ff
@nofollow        
        sty     @fflag                   ; if this is on, paint the no erase column

        ; ***********
        ; Paint head
        ; ***********

        lda     ob_h+objtable,x
        sta     @vh

        lda     ob_y+objtable,x         ; curscrnptr = *(multable+o.y*2)
        asl
        tax                             ; x = o.y*2
        lda     multable,x
        sta     curscrnptr
        lda     multable+1,x
        sta     curscrnptr+1

        ; REQUIREMENT: A is non zero here (last sta is high of screen ptr, which is $8000+)


        ; top row
        bit     @hflag
        beq     @notophead
        ; Set screen character
        ldy     @vhx                    ; x = o.x1, we could optimize this to ZEROPAGE
        lda     #o0_fu                  ; *curscrnptr+x     
        sta     (curscrnptr),y
@notophead
        ; top row follow

        bit     @fflag                   ; test if need to pain the follow column
        beq     @notopfollow        
        iny
        lda     #o0_mu
        sta     (curscrnptr),y                
@notopfollow
        
        ldy     @vh
        dey
        beq     @nohead

@moremiddle
        ; Next row
        clc
        lda     curscrnptr              ; curscrnptr += 40
        adc     #40
        sta     curscrnptr
        lda     curscrnptr+1
        adc     #0
        sta     curscrnptr+1

        ; check if we need to paint the middle
        dey
        sty     @vh
        beq     @nomiddle

        ; middle
        bit     @hflag
        beq     @nomidhead
        ldy     @vhx                    ; Set screen character
        lda     #o0_fm
        sta     (curscrnptr),y
@nomidhead
        ; middle follow
        bit     @fflag
        beq     @nomidfollow
        iny
        lda     #o0_mm
        sta     (curscrnptr),y
@nomidfollow

        ldy     @vh
        jmp     @moremiddle


@nomiddle
        ; bottom
        bit     @hflag
        beq     @nobothead
        ldy     @vhx
        lda     #o0_fb
        sta     (curscrnptr),y
@nobothead
        ; bottom follow
        bit     @fflag
        beq     @nobottomfollow
        iny
        lda     #o0_mb
        sta     (curscrnptr),y
@nobottomfollow        

        
@endobj
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
        rts

multable
        DCW 25,0

; Objects are 10 bytes, there are 20 of them here
objtable
        DCB 200,0
