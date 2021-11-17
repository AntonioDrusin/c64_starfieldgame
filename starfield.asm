; 10 SYS (2096)

GenerateTo      starfield.prg
DebugStartAddress       start

Incasm "vicii.asm""
Incasm "macros.asm"

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $39, $36, $29, $00, $00, $00

*=$830

screen = $0400
chars  = $3000
charsetend = $3fff

; *********************
; ZERO PAGE VARIABLES
; *********************

scrptr = $10    ; For character filling
atemp  = $12    ; Store A sometimes
framect = $13 
curcolor = $14   ; word 

        
start

        ; disable CIA interrupt (Is this on by default for BASIC?)
        ; This is important or the copy char routine will crash for some reason
        lda $dc0e
        and #$fe
        sta $dc0e

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
        ora #$04        
        sta $1         ; CHAR ROM VISIBILE OFF

        
        ; Ideally we move the VIC completely out of there so no ROM chars
        ; with the CIA outputs at $dd00

        ; select VIC character bank to $3000
        lda VIC_MEM     ; default $15
        and #$f0
        ora #$0c
        sta VIC_MEM       ; $1c


        ; ********************
        ; Prep star characters
        ; ********************

        ; Stars are on line 3
        ; and on line 7
        lda #$0
        ldx #15
@nulchar
        sta chars+16,x
        dex
        bpl @nulchar

        lda #$10
        sta chars+19    ; 16 + 3
        lda #$02
        sta chars+31    ; 16 + 7


        ; ******************************************
        ; Fill screen with alternating BC characters
        ; ******************************************

        movew screen, scrptr        
        ldx #24                 ; 25 lines
        lda #2                 ; B/C 
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
              
        ; *********
        ; MAIN LOOP
        ; *********

        lda     #$00
        sta     framect
forever

        lda     #$40
WAIT
        cmp     VIC_RASTER
        bne     WAIT

        lda     #VIC_BLUE
        sta     VIC_BORDERC


        ; Scroll fast star
        clc
        lda     chars+19 ;(16,3)
        ror
        sta     chars+19 ; (16,3)
        lda     chars+27 ; (24,3)
        ror
        sta     chars+27 ;
        bcc     @nol
        lda     chars+19
        ora     #$80
        sta     chars+19
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
        lda     chars+23
        ror
        sta     chars+23
        lda     chars+31
        ror
        sta     chars+31
        bcc     @nor
        lda     chars+23
        ora     #$80
        sta     chars+23
@nor
        
    
@nos
        lda     #VIC_BLACK
        sta     VIC_BORDERC

        jmp     forever


triband
        ldy     #0
@nextcolor
        sta     (curcolor),y
        iny
        cpy     #120
        bne     @nextcolor
        
        addaw   120, curcolor

        rts
