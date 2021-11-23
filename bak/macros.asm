

defm    addaw
        clc
        lda /2
        adc #</1
        sta /2
        lda /2+1
        adc #>/1
        sta /2+1        
        
        endm


defm    movew
        lda #</1
        sta /2
        lda #>/1
        sta /2+1
        endm

        