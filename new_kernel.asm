 org 0x7C00   ; add 0x7C00 to label addresses
 bits 16      ; tell the assembler we want 16 bit code

   mov ax, 0  ; set up segments
   mov ds, ax
   mov es, ax
   mov ss, ax     ; setup stack
   mov sp, 0x7C00 ; stack grows downwards from 0x7C00
 
   mov ah, 0x00
   mov al, 0x03
   int 0x10

   mov si, welcome
   call print_string
 
 mainloop:
   mov si, prompt
   call print_string
 
   mov di, buffer
   call get_string
 
   mov si, buffer
   cmp byte [si], 0  ; blank line?
   je mainloop       ; yes, ignore it
 
   mov si, buffer
   mov di, cmd_help  ; "help" command
   call strcmp
   jc .help
   
   mov si, buffer
   mov di, cmd_clear ; "clear" command
   call strcmp
   jc .clear 

   mov si, buffer
   mov di, system_info ; "system" command
   call strcmp
   jc .system


   mov si,badcommand
   call print_string 
   jmp mainloop  

 .help:
   mov si, msg_help
   call print_string
   jmp mainloop
   
  .clear:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    jmp mainloop

  .system:
   mov si, msg_info1
   call print_string
   mov si, msg_info2
   call print_string
   jmp mainloop

;  .shortcuts:
;    mov si, msg_shortcuts
;    call print_string
;    jmp mainloop
 
 welcome db 'KassOS Genesis', 0x0D, 0x0A, 0
 badcommand db 'Unknown Command', 0x0D, 0x0A, 0
 prompt db '$', 0
 cmd_restart db 'restart', 0
 cmd_system db 'system', 0
 cmd_clear db 'clear', 0
 cmd_help db 'help', 0
 cmd_shortcut db 'shortcuts', 0
 msg_info1 db 'KassOS Genesis v0.1.0', 0x0D, 0x0A, 0
 msg_info2 db 'KassOS is hosted by Kassian Horizons', 0x0D, 0x0A, 0
 msg_help db 'Help: help, clear, info', 0x0D, 0x0A, 0
 buffer times 16 db 0
 
 ; ================
 ; calls start here
 ; ================
 
 print_string:
 

   lodsb        ; grab a byte from SI
 
   or al, al  ; logical or AL by itself
   jz .done   ; if the result is zero, get out
 
   mov ah, 0x0E
   int 0x10      ; otherwise, print out the character!
 
   jmp print_string
 
 .done:
   ret
 
 get_string:
   xor cl, cl
 
 .loop:
   mov ah, 0
   int 0x16   ; wait for keypress

   cmp al, 0x0E    ; Ctrl-Alt-Backspace pressed?
   je .restart     ; yes, handle it
 
   cmp al, 0x08    ; backspace pressed?
   je .backspace   ; yes, handle it
 
   cmp al, 0x0D  ; enter pressed?
   je .done      ; yes, we're done
 
   cmp cl, 0x3F  ; 63 chars inputted?
   je .loop      ; yes, only let in backspace and enter
 
   mov ah, 0x0E
   int 0x10      ; print out character
 
   stosb  ; put character in buffer
   inc cl
   jmp .loop
 
  .restart:
    mov ah, 0x00
    mov al, 0x12
    int 0x19
    jmp $

 .backspace:
   cmp cl, 0	; beginning of string?
   je .loop	; yes, ignore the key
 
   dec di
   mov byte [di], 0	; delete character
   dec cl		; decrement counter as well
 
   mov ah, 0x0E
   mov al, 0x08
   int 10h		; backspace on the screen
 
   mov al, ' '
   int 10h		; blank character out
 
   mov al, 0x08
   int 10h		; backspace again
 
   jmp .loop	; go to the main loop
 


 .done:
   mov al, 0	; null terminator
   stosb
 
   mov ah, 0x0E
   mov al, 0x0D
   int 0x10
   mov al, 0x0A
   int 0x10		; newline
 
   ret
 
 strcmp:
 .loop:
   mov al, [si]   ; grab a byte from SI
   mov bl, [di]   ; grab a byte from DI
   cmp al, bl     ; are they equal?
   jne .notequal  ; nope, we're done.
 
   cmp al, 0  ; are both bytes (they were equal before) null?
   je .done   ; yes, we're done.
 
   inc di     ; increment DI
   inc si     ; increment SI
   jmp .loop  ; loop!
 
 .notequal:
   clc  ; not equal, clear the carry flag
   ret
 
 .done: 	
   stc  ; equal, set the carry flag
   ret
 
   times 510-($-$$) db 0
   dw 0AA55h ; some BIOSes require this signature
