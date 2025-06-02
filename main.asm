.model small
.stack 100h
.data
    msg_start db 'Press Enter to start the reaction test', 0Dh, 0Ah, '$'
    msg_prompt db 'Press any key NOW!', 0Dh, 0Ah, '$'
    msg_start_time db 'Start time (HH:MM:SS:CC): 00:00:00:00', 0Dh, 0Ah, '$'
    msg_end_time db 'End time   (HH:MM:SS:CC): 00:00:00:00', 0Dh, 0Ah, '$'
    msg_result db 'Your reaction time       : 00:00:00:00', 0Dh, 0Ah, '$'
    start_time dw 0, 0 ; Hours:Minutes, Seconds:Centiseconds
    end_time dw 0, 0
    diff_hours db 0
    diff_minutes db 0
    diff_seconds db 0
    diff_centiseconds db 0

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Display start message
    mov ah, 09h
    lea dx, msg_start
    int 21h

    ; Wait for Enter key
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    jne exit

    ; Clear screen
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov cx, 0
    mov dx, 184Fh
    int 10h

    ; Fixed delay of 1.4 seconds (1400 milliseconds)
    mov ah, 86h
    mov cx, 0
    mov dx, 1400
    int 15h

    ; Display prompt
    mov ah, 09h
    lea dx, msg_prompt
    int 21h

    ; Get start timestamp
    mov ah, 2Ch
    int 21h
    mov word ptr start_time, cx    ; CX = CH:CL (Hours:Minutes)
    mov word ptr start_time+2, dx  ; DX = DH:DL (Seconds:Centiseconds)

    ; Display start timestamp
    mov al, ch
    call display_two_digits
    mov byte ptr msg_start_time+26, al
    mov byte ptr msg_start_time+27, ah
    mov al, cl
    call display_two_digits
    mov byte ptr msg_start_time+29, al
    mov byte ptr msg_start_time+30, ah
    mov al, dh
    call display_two_digits
    mov byte ptr msg_start_time+32, al
    mov byte ptr msg_start_time+33, ah
    mov al, dl
    call display_two_digits
    mov byte ptr msg_start_time+35, al
    mov byte ptr msg_start_time+36, ah

    mov ah, 09h
    lea dx, msg_start_time
    int 21h

    ; Wait for any key
    mov ah, 00h
    int 16h

    ; Get end timestamp
    mov ah, 2Ch
    int 21h
    mov word ptr end_time, cx      ; CX = CH:CL (Hours:Minutes)
    mov word ptr end_time+2, dx    ; DX = DH:DL (Seconds:Centiseconds)

    ; Display end timestamp
    mov al, ch
    call display_two_digits
    mov byte ptr msg_end_time+26, al
    mov byte ptr msg_end_time+27, ah
    mov al, cl
    call display_two_digits
    mov byte ptr msg_end_time+29, al
    mov byte ptr msg_end_time+30, ah
    mov al, dh
    call display_two_digits
    mov byte ptr msg_end_time+32, al
    mov byte ptr msg_end_time+33, ah
    mov al, dl
    call display_two_digits
    mov byte ptr msg_end_time+35, al
    mov byte ptr msg_end_time+36, ah

    mov ah, 09h
    lea dx, msg_end_time
    int 21h

    ; Calculate time difference with proper borrowing
    ; Calculate centiseconds
    mov al, byte ptr end_time+3     ; end centiseconds
    sub al, byte ptr start_time+3   ; start centiseconds
    js borrow_seconds
    mov diff_centiseconds, al
    jmp done_centiseconds
borrow_seconds:
    add al, 100
    mov diff_centiseconds, al
    dec byte ptr end_time+2         ; borrow 1 second
done_centiseconds:

    ; Calculate seconds
    mov al, byte ptr end_time+2     ; end seconds
    sub al, byte ptr start_time+2   ; start seconds
    js borrow_minutes
    mov diff_seconds, al
    jmp done_seconds
borrow_minutes:
    add al, 60
    mov diff_seconds, al
    dec byte ptr end_time+1         ; borrow 1 minute
done_seconds:

    ; Calculate minutes
    mov al, byte ptr end_time+1     ; end minutes
    sub al, byte ptr start_time+1   ; start minutes
    js borrow_hours
    mov diff_minutes, al
    jmp done_minutes
borrow_hours:
    add al, 60
    mov diff_minutes, al
    dec byte ptr end_time           ; borrow 1 hour
done_minutes:

    ; Calculate hours
    mov al, byte ptr end_time       ; end hours
    sub al, byte ptr start_time     ; start hours
    jc underflow_hour
    mov diff_hours, al
    jmp done_hours
underflow_hour:
    add al, 24                      ; handle next-day wraparound
    mov diff_hours, al
done_hours:

    ; Prepare display in msg_result
    mov al, diff_hours
    call display_two_digits
    mov byte ptr msg_result+29, al
    mov byte ptr msg_result+30, ah

    mov al, diff_minutes
    call display_two_digits
    mov byte ptr msg_result+26, al
    mov byte ptr msg_result+27, ah

    mov al, diff_seconds
    call display_two_digits
    mov byte ptr msg_result+35, al
    mov byte ptr msg_result+36, ah

    mov al, diff_centiseconds
    call display_two_digits
    mov byte ptr msg_result+32, al
    mov byte ptr msg_result+33, ah

    ; Show the result
    mov ah, 09h
    lea dx, msg_result
    int 21h


exit:
    mov ax, 4C00h
    int 21h
main endp

; Subroutine to convert a number in AL to two ASCII digits in AX
display_two_digits proc
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    add ah, '0'
    ret
display_two_digits endp

end main