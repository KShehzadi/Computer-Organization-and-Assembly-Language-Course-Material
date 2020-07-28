.model large 

.data

exit db 0 
player_pos dw 1760d   ;position of player

arrow_pos dw 0d       ;position of arrow
arrow_status db 0d    ;arrow ready to go else not
arrow_limit dw 22d    ;150d

loon_pos dw 3860d     ;3990d 
loon_status db 0d

;direction of player
;up = 8, down = 2
direction db 0d
state_buf db '00:0:0:0:0:0:00:00$'  ;score variable
hit_num db 0d
hits dw 0d
miss dw 0d

game_over_str dw ' ',0ah,0dh
dw '           |        |',0ah,0dh
dw '           |--------|',0ah,0dh
dw '           |^SCORE^ |',0ah,0dh
dw '           |--------|',0ah,0dh
dw '  ',0ah,0dh
dw '  ',0ah,0dh
dw '  ',0ah,0dh
dw '  ',0ah,0dh
dw '  ',0ah,0dh
dw '  ',0ah,0dh
dw '  ',0ah,0dh
dw '          GAME OVER',0ah,0dh
dw '     Please Enter to start again$',0ah,0dh
 
 
 
game_start_str dw ' ',0ah,0dh
dw '',0ah,0dh 
dw '',0ah,0dh
dw '',0ah,0dh
dw '       --------------------',0ah,0dh
dw '       --------------------',0ah,0dh
dw '       BALLON SHOOTER GAME ',0ah,0dh 
dw '                           ',0ah,0dh
dw '    Use up and down keys to move player ',0ah,0dh
dw '     and space button to shoot          ',0ah,0dh
dw '      Press enter to start              ',0ah,0dh
dw '      --------------------',0ah,0dh
dw '$',0ah,0dh


.code
main proc
mov ax,@data
mov ds,ax
   
mov ax,0B800h
mov es,ax

jmp game_menu     ;display main menu

main_loop:
      
        mov ah,1h
        int 16h
        jnz key_pressed  ;go if pressed
        jmp inside_loop  ;or just continue
 
   inside_loop: 
 
         cmp miss,9   ;if baloon miss 9 times
         jge game_over
         
         mov dx,arrow_pos  ;checking collisions
         cmp dx,loon_pos
         je hit
         
         cmp direction,8d  ;update player position
         je player_up
         cmp direction,2d
         je player_down
         
         mov dx,arrow_limit ;hide arrow
         cmp arrow_pos,dx
         jge hide_arrow
         
         cmp loon_pos,0d   ;check missed loon
         jle miss_loon
         jne render_loon
   
   hit:  
   
             mov ah,2
             mov dx,7d  ;play sound of hit
             int 21h
             
             inc hits   ;update scores
             
             lea bx,state_buf ;display scores
             call show_score
             lea dx,state_buf
             mov ah,09h
             int 21h
             
             mov ah,2   ;new line
             mov dl,0dh
             int 21h 
             
             jmp fire_loon   ;new loon pops up
       
   render_loon:
   
             mov cl, ' '  ;hide old loon
             mov ch,1111b
             
             mov bx,loon_pos
             mov es:[bx], cx
             
             sub loon_pos,160d    ;draw new one in new position
             mov cl,15d
             mov ch,1101b
                        
             mov bx,loon_pos
             mov es:[bx], cx
             
             cmp arrow_status,1d  ;check any arrow to render
             je render_arrow
             jne inside_loop2
       
    render_arrow:
             
             mov cl, ' '
             mov ch,1111b 
             
             mov bx,arrow_pos       ;hide old position
             mov es:[bx],cx     
             
             add arrow_pos,4d
             mov cl,26d
             mov ch,1001b         ;draw new position
             
             mov bx,arrow_pos
             mov es:[bx],cx
       
     inside_loop2:
        
             mov cl, 125d  ;draw player
             mov ch,1100b
             
             mov bx,player_pos
             mov es:[bx],cx
       
    cmp exit,'0' ;end main loop 
    je main_loop
    jne exit_game 
    
jmp inside_loop2
 
player_up:

 mov cl,' '     ;hide players old position
 mov ch,1111b
 
 mov bx, player_pos
 mov es:[bx], cx
 
 sub player_pos,160d  ;set new position of player
 mov direction,0 
 
 jmp inside_loop2
 
player_down:

 mov cl,' '  ; hide players old position
 mov ch,1111b
 
 mov bx, player_pos
 mov es:[bx], cx 
 
 add player_pos,160d
 mov direction,0
 
 jmp inside_loop2
 
key_pressed:

       mov ah,0
       int 16h
       
       cmp ah,48h  ;go upkey if up button is presed
       je upkey
       
       cmp  ah,50h 
       je downkey
       
       cmp ah,39h
       je spacekey
       
       cmp ah,4Bh
       je leftkey
 
      jmp inside_loop
 
leftkey: 

       inc miss
       lea bx,state_buf
       call show_score
       lea dx,state_buf
       mov ah,09h
       int 21h
       
       mov ah,2
       mov dl,0dh
       int 21h
jmp inside_loop

upkey:

    mov direction,8d
    jmp inside_loop
   
downkey: 

   mov direction,2d
   jmp inside_loop
   
spacekey:

   cmp arrow_status,0
   je fire_arrow
   jmp inside_loop  

fire_arrow:
      mov dx,player_pos   ;set arrow position in player position
      mov arrow_pos,dx
      
      mov dx,player_pos
      mov arrow_limit,dx
      mov arrow_limit, 22d
      
      mov arrow_status,1d
      jmp inside_loop

miss_loon:

      add miss,1    ;update scores
      
      lea bx,state_buf
      call show_score
      lea dx,state_buf  ;display scores
      mov ah,09h
      int 21h
      
      mov ah,2
      mov dl,0dh
      int 21h
jmp fire_loon

fire_loon: 

      mov loon_status,1d  ; fire a new ballon
      mov loon_pos,3860d
      jmp render_loon

hide_arrow: 

      mov arrow_status,0   
      
      mov cl,' '
      mov ch,1111b
      
      mov bx,arrow_pos
      mov es:[bx],cx
      
      cmp loon_pos,0d
      jle miss_loon
      jne render_loon
      
      jmp inside_loop2

game_over:  

      mov ah,09h
      mov dx,offset game_over_str
      int 21h
      
      mov cl, ' '
      mov ch,1111b
      mov bx,arrow_pos   ; hide last of screen ballon
      
      mov cl,' '
      mov ch,1111b
      mov bx,player_pos 
      
      mov miss,0d
      mov hits,0d
      
      mov player_pos,1760d
      
      mov arrow_pos,0d
      mov arrow_status,0d
      mov arrow_limit,22d
      
      mov loon_pos,3860d 
      mov loon_status,0d
      
      mov direction,0d

      input:
         mov ah,1
         int 21h
         cmp al,13d
         jne input
         call clear_screen
         jmp main_loop

game_menu:

      mov ah,09h
      mov dh,0
      mov dx,offset game_start_str
      int 21h

        input2:
            mov ah,1
            int 21h
            cmp al,13d
            jne input2
            call clear_screen  
            
            
            lea bx,state_buf
            call show_score
            lea dx,state_buf
            mov ah,09h
            int 21h
      
            mov ah,2
            mov dl,0dh  
            int 21h
            jmp main_loop

exit_game:  
mov exit,10d

main endp  


proc show_score
         lea bx,state_buf 
         
         mov dx,hits
         add dx,48d
         
         mov [bx], 9d
         mov [bx+1], 9d
         mov [bx+2], 9d
         mov [bx+3], 9d
         mov [bx+4], 'H' 
         mov [bx+5], 'I'
         mov [bx+6], 'T'
         mov [bx+7], 'S'
         mov [bx+8], ':'
         mov [bx+9], dx
         
         mov dx,miss
         add dx,48d
         mov [bx+10], ' '
         mov [bx+11], 'M'
         mov [bx+12], 'I'
         mov [bx+13], 'S'
         mov [bx+14], 'S'
         mov [bx+15], ':'
         mov [bx+16], dx
         
ret
show_score endp  


clear_screen proc near 
   mov ah,0
   mov al,3
   int 10h
    ret
clear_screen endp


end main



 
                                             
                                             
       
       
       
       
 


