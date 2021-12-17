; 10 SYS (2096)
GenerateTo      starfield.prg
DebugStartAddress start
          
; Include macros and definitions
Incasm    "vicii.asm""
Incasm    "macros.asm"

       

; BASIC header   
*=$0801
          BYTE           $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $39, $36, $29, $00, $00, $00
*=$830


; *********************
; SCREEN LOCATION
; *********************

screen    = $8400
chars     = $b000
charsetend = $bfff
; starscroller
starchar  = 36
star_chars0 = chars+288
star_chars1 = chars+296

; $0-$ff zero page
; $100-$1ff stack
; $200-$7fff RAM
; $8000-$bfff VIC
; $c000-$ffff RAM          

; *********************
; Constants
; *********************

                    

; ***************************
; Zero Page Global Variables
; ***************************
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
                    
start
          jsr            initlevel 
          
@again
          ;jsr            activateObjects
          jmp            @again    
          
          
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
; Fill background with alternating BC characters
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
; ***********************
; Setup Character Colors
; ***********************
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

          perfMark       VIC_LIGHTRED
          
          jsr activateObjects          
          jsr paintObjects


          perfMark       VIC_BLACK
          jmp            forever   
          

          
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
          
; clear object memory
          ldy            #max_objects-1
          ldx            #0        
          lda            #0        
@clearnext          
          sta            objtable,x
          inx
          sta            objtable,x
          inx
          sta            objtable,x
          inx
          sta            objtable,x
          inx
          sta            objtable,x
          inx
          sta            objtable,x
          inx
          dey
          bpl            @clearnext
          
          rts
          
; *******************************
; * include assembly routines
; *******************************

Incasm    "utility.asm"
Incasm    "paintObjects.asm"
Incasm    "level.asm"

multable
          DCW            25,0
;*****************************
; Obstacles on screen
; Objects are ob_size bytes
;*****************************
 
lvl_xpos  = 4
lvl_size  = 6
                             
level
          BYTE           1,4,30, 3 ; Type, height, width, y
          WORD           10        ; position within block
          BYTE           1,4,30, 15
          WORD           30
          BYTE           1,4,30, 20
          WORD           60
          BYTE           1,4,30, 20
          WORD           120


; **********************************
; * Object table
; **********************************
objtable = $c000          

max_objects = 10
          
ob_type   = 0
ob_h      = 1
ob_l      = 2
ob_y      = 3
ob_x1     = 4
ob_x2     = 5
ob_size   = 6          
       
          
