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

activateObjects
                                   ; Increment stagex by one
          clc
          lda            stagex_w  
          adc            #1        
          sta            stagex_w  
          lda            stagex_w+1
          adc            #0        
          sta            stagex_w+1


          ldy            #lvl_xpos+1
                                   ; compare our stagex to the location the next object should appear          
          
          
          lda            (levelptr_w),y
          cmp            stagex_w+1; HIGH byte          
                    
          bmi            @activate
          dey
          lda            (levelptr_w),y
          cmp            stagex_w  
          bmi            @activate 
          jmp            @noop
        
;*********************************
;* Activate object at levelptr_w  
;*********************************
@activate
        
                                   ; find the first object that is not in use
          ldy            #max_objects
          ldx            #0        
@findNext
          lda            objtable,x
          beq            @found    
          
          txa                      ; x+=obj_size
          clc
          adc            #ob_size 
          tax
          
                                   ; test if end of list          
          cmp            #ob_size*max_objects          
          bmi            @findNext
          jmp            @noop
                              
@found          ; objtable, x is an available object          

                                   ; activate object at levelptr_w into objtable
          ldy            #0    
          lda            (levelptr_w),y
          sta            objtable+ob_type,x
          
          iny
          lda            (levelptr_w),y
          sta            objtable+ob_h,x
          
          iny
          lda            (levelptr_w),y
          sta            objtable+ob_l,x
          
          iny
          lda            (levelptr_w),y
          sta            objtable+ob_y,x
                                   ; x1 = lvl_xpos - stagex_w + 50 (40 width + 10 margin)
          
    
          iny
          iny
          lda            (levelptr_w),y; lvl_xpos
          sec
          sbc            stagex_w+1
          clc
          adc            #50       
          sta            objtable+ob_x1,x
                                                  
@noop
          rts
          
          