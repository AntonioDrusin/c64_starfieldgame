;*********************************
;** ACTIVATES OBJECTS 
;*********************************

; variables


; level struct definition
lvl_type  = 0
lvl_height= 1
lvl_width = 2
lvl_y     = 3
lvl_pos   = 4

defm      activateObjects
          
                                   ; Increment stagex by one
          clc
          lda            stagex_w  
          adc            #1        
          sta            stagex_w  
          lda            stagex_w+1
          adc            #0        
          sta            stagex_w+1

                                   ; compare our stagex to the location the next object should appear          
          lda            stagex_w+1; HIGH byte
          cmp            levelptr_w+1
          bpl            @activate 
          lda            stagex_w  
          cmp            levelptr_w
          bpl            @activate 
          jmp            @noop
          
@activate
                                   ; find the first object that is not in use
          


@noop

          endm
          