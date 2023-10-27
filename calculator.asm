    SYS_READ   equ     0          ; read text from stdin
    SYS_WRITE  equ     1          ; write text to stdout
    SYS_EXIT   equ     60         ; terminate the program
    STDIN      equ     0          ; standard input
    STDOUT     equ     1          ; standard output
; --------------------------------
section .bss
    BYTE_BUFFER_LEN equ     10
    BYTE_BUFFER     resb    BYTE_BUFFER_LEN 
    uinputfirst_len equ     32         
    uinputfirst     resb    uinputfirst_len 
    uinputoperation_len equ 2         
    uinputoperation resb    uinputoperation_len
    uinputsecond_len equ    32
    uinputsecond    resb    uinputsecond_len
; --------------------------------
section .data
    first            db     "First Number: "
    first_len        equ    $ - first
    operation        db     "Operation: "
    operation_len    equ    $ - operation
    second           db     "Second Number: "
    second_len       equ    $ - second
    answertext       db     10, "Answer: "
    answertext_len   equ    $ - answertext
    addchar          db     "+"
    subchar          db     "-"
    multchar         db     "*"
    divchar          db     "/"

    badop            db     "Bad operation! (int) (+,-,*,/) (int)"
    badop_len        equ    $ - badop
; --------------------------------
section .text
    global _start

_start:
    mov     rdx, first_len    
    mov     rsi, first
    call    print    

    mov     rdx, uinputfirst_len     
    mov     rsi, uinputfirst
    call    read

    mov     rdx, operation_len
    mov     rsi, operation
    call    print

    mov     rdx, uinputoperation_len
    mov     rsi, uinputoperation
    call    read

    mov     rdx, second_len
    mov     rsi, second
    call    print

    mov     rdx, uinputsecond_len
    mov     rsi, uinputsecond
    call    read

    jmp compute

exit:
    xor     edi, edi             ; successful exit (set to 0)
    mov     rax, SYS_EXIT
    syscall

print:
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    ret

read:
    mov     rdi, STDIN
    mov	    rax, SYS_READ
    syscall
    ret

compute:
    xor     rsi, rsi               ; zero the rsi register
    mov     rsi, uinputfirst       ; store the pointer to uinputfirst in rsi to pass into char_to_int
    call char_to_int               ; convert ascii string to number
    push    rax                    ; store the first number on the stack
    
    xor     rsi, rsi               ; zero the rsi register
    mov     rsi, uinputsecond      ; store the pointer to uinputsecond in rsi to pass into char_to_int
    call char_to_int               ; convert ascii string to number
    mov     rcx, rax               ; store the second number in rcx

    pop     rbx                    ; pop the first number off into rbx

    mov     rsi, [uinputoperation]  ; dereference the operation input and store in rsi

    mov     rdi, [addchar]          ; dereference the add character
    cmp     dil, sil                ; compare only the first byte (each operation is only 1 byte)
    je addop                        ; chosen addition

    mov     rdi, [subchar]  
    cmp     dil, sil
    je subop                        ; chosen subtraction

    mov     rdi, [multchar]
    cmp     dil, sil
    je multop                       ; chosen multiplication

    mov     rdi, [divchar]
    cmp     dil, sil
    je divop                        ; chosen division

    jmp none                        ; bad op
addop:
    add rbx, rcx
    mov rax, rbx
    jmp printanswer
subop:
    sub rbx, rcx
    mov rax, rbx
    jmp printanswer
multop:
    mov rax, rcx
    mul rbx                         ; multiply rbx by rax
    jmp printanswer
divop:
    mov rax, rbx
    div rcx                         ; divide rax by rcx
    jmp printanswer

printanswer:
    call    int_to_char
    mov     rdx, r11
    mov     rsi, r9
    call    print
    jmp exit

none:
    mov     rdx, badop_len
    mov     rsi, badop
    call print
    jmp exit

;
;  +--------------------------------------------------------------------------------+
;  | The below code was slightly modified from https://github.com/flouthoc/calc.asm |
;  +--------------------------------------------------------------------------------+
;
;  input in rsi
;  output in rax
char_to_int:
        xor ax, ax ;store zero in ax
        xor cx, cx ;same
        mov bx, 10 ; store 10 in bx - the input string is in base 10, so each place value increases by a factor of 10

.loop_block:

        ;REMEMBER rsi is base address to the string which we want to convert to integer equivalent

        mov cl, [rsi] ;Store value at address (rsi + 0) or (rsi + index) in cl, rsi is incremented below so dont worry about where is index.
        cmp cl, byte 0xA ;If value at address (rsi + index ) is byte 0xA (Newline) , means our string is terminated here
        je .return_block

        ;Each digit must be between 0 (ASCII code 48) and 9 (ASCII code 57)
        cmp cl, 0x30 ;If value is lesser than 0 goto invalid operand
        jl invalid_operand
        cmp cl, 0x39 ;If value is greater than 9 goto invalid operand
        jg invalid_operand

        sub cl, 48 ;Convert ASCII to integer by subtracting 48 - '0' is ASCII code 48, so subtracting 48 gives us the integer value

        ;Multiply the value in 'ax' (implied by 'mul') by bx (always 10). This can be thought of as shifting the current value
        ;to the left by one place (e.g. '123' -> '1230'), which 'makes room' for the current digit to be added onto the end.
        ;The result is stored in dx:ax.
        mul bx

        ;Add the current digit, stored in cl, to the current intermediate number.
        ;The resulting sum will be mulitiplied by 10 during the next iteration of the loop, with a new digit being added onto it
        add ax, cx

        inc rsi ;Increment the rsi's index i.e (rdi + index ) we are incrementing the index

        jmp .loop_block ;Keep looping until loop breaks on its own

.return_block:
    ret
invalid_operand:
    jmp badop

;This is the function which will convert our integers back to characters
;Argument - Integer Value in rax
;Returns pointer to equivalent string (in r9)
;r11 contains the length of the string
int_to_char:
	mov rbx, 10
	;We have declared a memory which we will use as buffer to store our result
	mov r9, BYTE_BUFFER+10 ;We are are storing the number in backward order like LSB in 10 index and decrementing index as we move to MSB
	mov [r9], byte 0 ;Store NULL terminating byte in last slot
	dec r9 ;Decrement memory index
	mov [r9], byte 0XA ;Store break line
	dec r9 ;Decrement memory index
	mov r11, 2;r11 will store the size of our string stored in buffer we will use it while printing as argument to sys_write

.loop_block:
	mov rdx, 0
	div rbx    ;Get the LSB by dividing number by 10 , LSB will be remainder (stored in 'dl') like 23 divider 10 will give us 3 as remainder which is LSB here
	cmp rax, 0 ;If rax (quotient) becomes 0 our procedure reached to the MSB of the number we should leave now
	je .return_block
	add dl, 48 ;Convert each digit to its ASCII value
	mov [r9], dl ;Store the ASCII value in memory by using r9 as index
	dec r9 ;Dont forget to decrement r9 remember we are using memory backwards
	inc r11 ;Increment size as soon as you add a digit in memory
	jmp .loop_block ;Loop until it breaks on its own

.return_block:
	add dl, 48 ;Don't forget to repeat the routine for out last MSB as loop ended early
	mov [r9], dl
	dec r9
	inc r11
	ret
