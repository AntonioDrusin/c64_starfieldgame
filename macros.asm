; ******************************************************
; Colors background to measure performance
;
; Ex:
; perfMark VIC_YELLOW
; ******************************************************

defm      perfMark
          pha
          lda            #/1        
          sta            VIC_BORDERC 
          pla          
          endm

; ******************************************************
; Adds constant to contents of immediate memory address
;
; Ex:
; addaw 33, screenptr
; ******************************************************

defm      addaw          
          clc
          lda            /2                  
          adc            #</1                
          sta            /2                  
          lda            /2+1                
          adc            #>/1                
          sta            /2+1                
          endm

; ******************************************************
; Moves constant to contents of immediate memory address
;
; Ex:
; movew 0, screenptr
; ******************************************************

defm      movew
          lda            #</1
          sta            /2
          lda            #>/1
          sta            /2+1
          endm

        