%include "asm_io.inc"

SECTION .data
MAX_ARGS: equ 2
MIN_ARGS: equ 2
MIN_LENGTH: equ 1
MAX_LENGTH: equ 20
MSG_TOO_MANY_ARGS: db "Too many arguments passed",10,0
MSG_TOO_FEW_ARGS: db "Too few arguments passed",10,0
MSG_TOO_SHORT: db "Your argument was too short",10,0
MSG_TOO_LONG: db "Your argument was too long",10,0
MSG_LETTER_ERROR: db "Your argument must contain only lowercase letters",10,0

SECTION .bss
X: resb 20
Y: resd 40
N: resd 1
k: resd 1
p: resd 1
i: resd 1
flag: resd 1
lyndon_address: resd 1


SECTION .text
	global asm_main

asm_main:
	enter 0,0 
	pusha
	 
	
	cmp dword [ebp + 8], MAX_ARGS
	jg TOO_MANY_ARGS
	cmp dword [ebp + 8], MIN_ARGS
	jl TOO_FEW_ARGS
	mov ebx, dword [ebp + 12]
	mov eax, dword [ebx + 4]
	mov ecx, eax
	mov edx, 0
	GET_LENGTH:
		mov al, byte [ecx]
		cmp al, 0
		je CHECK_LENGTH
		cmp al, 'a'
		jl LETTER_ERROR
		cmp al, 'z'
		jg LETTER_ERROR
		inc ecx
		inc edx	
		jmp GET_LENGTH
	CHECK_LENGTH:
		cmp edx, MIN_LENGTH
		jl TOO_SHORT
		cmp edx, MAX_LENGTH
		jg TOO_LONG
		mov [N], edx
		mov eax, edx
	mov ebx, dword [ebp + 12]
	mov eax, dword [ebx + 4] 
	mov ecx, eax
	mov edx, 0
	mov ebx, X
	COPY_TO_ARRAY:
		mov al, byte [ecx]
		mov [ebx], al
		inc ebx
		inc ecx
		inc edx
		cmp edx, dword [N]
		jb COPY_TO_ARRAY
	mov [flag], dword 0
	;call (display(X, N, flag)
	mov eax, dword [flag]
	mov ebx, dword [N]
	mov ecx, X
	push eax
	push ebx
	push ecx
	call display
	add esp, 12
	mov [k], dword 0
	mov edx, Y
	mov [lyndon_address], dword 0
	LYNDON_LOOP:
		mov eax, dword [k]	; k
		mov ebx, dword [N] 	; N
		cmp ebx, dword [k] 	; if k < N
		jle DISPLAY_2		
		mov ecx, X		; Address of X
		push eax		; push k to stack @ ebp + 16
		push ebx		; push N to stack @ ebp + 12
		push ecx		; push Z to stack @ ebp + 8
		call maxLyn		; call maxLyn(Z, N, k)
		add esp, 12		; reset stack pointer
		inc dword [k]		; k = k + 1
		mov edx, Y
		add edx, dword [lyndon_address]
		mov eax, dword [p]
		mov [edx], eax
		add [lyndon_address], dword 4
		jmp LYNDON_LOOP		; iterate
	DISPLAY_2:
	mov [flag], dword 1
	;call display(Y, N, flag)
	mov eax, dword [flag]
	mov ebx, dword [N]
	mov ecx, Y
	push eax
	push ebx
	push ecx
	call display
	add esp, 12	
	jmp exit		
	TOO_MANY_ARGS:
		mov eax, MSG_TOO_MANY_ARGS
		call print_string
		jmp exit
	TOO_FEW_ARGS:
		mov eax, MSG_TOO_FEW_ARGS
		call print_string
		jmp exit
	TOO_SHORT:
		mov eax, MSG_TOO_SHORT
		call print_string
		jmp exit
	TOO_LONG:
		mov eax, MSG_TOO_LONG
		call print_string
		jmp exit
	LETTER_ERROR:
		mov eax, MSG_LETTER_ERROR
		call print_string
		jmp exit
	exit:
		popa	
		leave
		ret
maxLyn:
	enter 0,0
	mov ebx, dword [ebp + 8]	; Z
	mov ecx, dword [ebp + 12]	; n 
	mov edx, dword [ebp + 16]	; k
	sub ecx, 1			; n = n - 1 for comparison
	cmp edx, ecx 			; if k = n - 1
	je BASE_CASE
	mov [p], dword 1		; p = 1
	mov [i], edx			; i = k
	add [i], dword 1		; i = k + 1
	inc ecx				; n = n + 1 reset from comparison
	mov eax, dword 0
	loop: 
		mov ecx, dword [ebp + 12] ; reset n
		cmp ecx, dword [i]	; for i < n
		jle RETURN
		add ebx, dword[i]	; Z[i]
		mov al, byte[ebx]	; store Z[i] in al
		sub ebx, dword[p]	; Z[i - p]
		cmp al, byte[ebx] 	; if Z[i] != Z[i - p]
		je ELSE_1
		IF_1:
			cmp al, byte[ebx]	; if Z[i] <= Z[i - p]	
			jge ELSE_2
			IF_2:
				jmp RETURN	; Exit
			ELSE_2:
				sub ebx, dword[i] ; Sub to reset ebx
				add ebx, dword[p] ; Add p to reset ebx
				mov ecx, 0	  ; p
				add ecx, dword[i] ; p = p + i
				add ecx, dword 1  ; p = p + i + 1
				sub ecx, edx	  ; p = p + i + 1 - k
				mov [p], ecx	  ; store p
				add [i], dword 1  ; i = i + 1
				jmp loop
		ELSE_1:
			sub ebx, dword[i]	; Sub to reset ebx
			add ebx, dword[p]	; Sub to reset ebx
			add [i], dword 1
			jmp loop
	BASE_CASE:
		mov [p], dword 1
		leave
		ret	
;
	RETURN:
		leave
		ret
		
display:
	enter 0, 0
	
	mov ebx, dword [ebp + 8]	; Z
	mov ecx, dword [ebp + 16]	; flag
	mov edx, 0			; counter
	cmp ecx, 0			; dword or byte array
	jne INT_ARRAY	
	STRING_ARRAY:
		mov al, byte [ebx]
		call print_char
		inc edx
		cmp edx, dword [ebp + 12]
		jae EXIT_DISPLAY
		inc ebx
		jmp STRING_ARRAY
	INT_ARRAY:
		mov eax, dword [ebx]
		call print_int
		mov eax, dword ' '
		call print_char
		inc edx
		cmp edx, dword [ebp + 12]
		jae EXIT_DISPLAY
		add ebx, dword 4
		jmp INT_ARRAY
	EXIT_DISPLAY:
		call print_nl
		leave 
		ret
	
