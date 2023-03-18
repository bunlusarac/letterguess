global _start

%define SYSCALL_GETRANDOM   355
%define SYSCALL_BRK         45  
%define SYSCALL_WRITE       4
%define SYSCALL_READ        3
%define SYSCALL_EXIT        1

%define FD_STDOUT   1
%define FD_STDIN    0

%define BUFSIZE     2
%define RANDSIZE    1

section .data
	failmsg db "An error occured",0x0a,0
	faillen equ $ - failmsg
	truemsg db "You guessed the letter right!",0x0a,0
	truelen equ $ - truemsg
	ltmsg db "That's the wrong letter! Try going higher...",0x0a,0
	ltlen equ $ - ltmsg
	gtmsg db "That's the wrong letter! Try going lower...",0x0a,0
	gtlen equ $ - gtmsg

section .text
_start:
	;heap alloc
	mov eax, SYSCALL_BRK
	mov ebx, 0
	int 0x80
	cmp eax, 0
	jl .fail

	mov ebx, eax
	add ebx, BUFSIZE
	mov eax, SYSCALL_BRK
	int 0x80
	cmp eax, 0
	jl .fail

	;random
	sub eax, BUFSIZE
	mov ebx, eax
	jmp .getrand

	jmp .fail

.fail:
	mov eax, SYSCALL_WRITE
	mov ebx, FD_STDOUT
	mov ecx, failmsg
	mov edx, faillen
	int 0x80

	;free heap
	mov eax, SYSCALL_BRK
	sub ecx, BUFSIZE
	mov ebx, ecx
	int 0x80

	cmp eax, 0
	jl .fail

	mov eax, SYSCALL_EXIT
	mov ebx, 0
	int 0x80

.found:
	sub esp, 4
	mov ebp, ecx
	;!!!!!!

	mov eax, SYSCALL_WRITE
	mov ebx, FD_STDOUT
	mov ecx, truemsg
	mov edx, truelen
	int 0x80

	mov ecx, ebp
	add esp, 4

	;free heap
	mov eax, SYSCALL_BRK
	sub ecx, BUFSIZE
	mov ebx, ecx
	int 0x80

	cmp eax, 0
	jl .fail

	mov eax, SYSCALL_EXIT
	mov ebx, 0
	int 0x80

.lt:
	sub esp, 4
	mov ebp, ecx
	;!!!!!!!

	mov eax, SYSCALL_WRITE
	mov ebx, FD_STDOUT
	mov ecx, ltmsg
	mov edx, ltlen
	int 0x80

	mov ecx, ebp
	add esp, 4

	jmp .guess

.gt:
	sub esp, 4
	mov ebp, ecx
	;!!!!!!

	mov eax, SYSCALL_WRITE
	mov ebx, FD_STDOUT
	mov ecx, gtmsg
	mov edx, gtlen
	int 0x80

	mov ecx, ebp
	add esp, 4

	jmp .guess

.guess:
	;ecx -> input memloc
	mov eax, SYSCALL_READ
	mov ebx, FD_STDIN
	mov edx, 1
	int 0x80

	cmp eax, 0
	jl .fail

	mov al, [ecx]
	cmp al, [ecx-1] 
	je .found
	jl .lt
	jg .gt

.getrand:
	;get rand byte from udev
	;ebx -> rnd byte write memloc
	mov eax, SYSCALL_GETRANDOM
	mov ecx, RANDSIZE
	mov edx, 1
	int 0x80

	cmp eax, 0
	jl .fail

	mov al, [ebx]
	cmp al, 97
	jl .getrand
	cmp al, 122
	jg .getrand

	add ebx, 1
	mov ecx, ebx
	jmp .guess	