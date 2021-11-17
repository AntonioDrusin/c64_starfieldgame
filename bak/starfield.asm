; 10 SYS (2096)

GenerateTo      starfield.prg
DebugStartAddress       start

Incasm "macros.asm"

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $39, $36, $29, $00, $00, $00

*=$830

VIC_COLOR = $d800

screen = $0400
chars  = $3000
charsetend = $3fff

block0 = screen
block1 = screen+(40*6)
block2 = screen+(40*12)
block3 = screen+(40*18)

scrptr = $10    ; For character filling
atemp  = $12    ; Store A sometimes
framect = $13 
curcolor = $14   ; word 

; Copy ROM characters over, mainly for debugging purposes
; CPU views the chracters at $D000-$DFFF
        
start

copychars
        ; disable CIA interrupt (Is this on by default for BASIC?)
        ; This is important or the copy char routine will crash for some reason
        lda $dc0e
        and #$fe
        sta $dc0e


        ; Setup Colors
        lda     #$0
        sta     $d020   ; border
        sta     $D021   ; background


        lda     #<VIC_COLOR
        sta     curcolor
        lda     #>VIC_COLOR
        sta     curcolor+1

        lda     #$06 ; BLUE
        jsr     triband
        lda     #$0e ; lb
        jsr     triband
        lda     #$07 ; yellow
        jsr     triband
        lda     #$01 ; white
        jsr     triband
        lda     #$01 ; white
        jsr     triband
        lda     #$07 ; yellow
        jsr     triband
        lda     #$0e ; lb
        jsr     triband
        lda     #$06 ; BLUE
        jsr     triband
        
        lda $1 
        and #$fb
        sta $1   ; CHAR ROM VISIBLE AT $D000


        ; https://www.pagetable.com/c64ref/c64disasm/
        ; use $a3b7 routine
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
        lda $d018     ; default $15
        and #$f0
        ora #$0c
        sta $d018       ; $1c

        
        ; Stars are on line 3
        ; and on line 7
        lda #$0
        ldx #15
@nulchar
        sta chars+16,x
        dex
        bpl @nulchar

        lda #$10
        sta chars+19
        lda #$02
        sta chars+31


        ; Fill screen with alternating BC characters
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
                       


        lda     #$00
        sta     framect
forever

        lda     #$f0
WAIT
        cmp     $d012
        bne     WAIT

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

        JMP     forever


triband
        ldy     #0
@nextcolor
        sta     (curcolor),y
        iny
        cpy     #120
        bne     @nextcolor
        
        addaw   120, curcolor

        rts
