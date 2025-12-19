BITS 64

section .rodata
    err_uso: db "Uso: ./asm <entrada.s> <saida>",10
    err_uso_len: equ $-err_uso
    err_arq: db "Erro ao abrir arquivo",10
    err_arq_len: equ $-err_arq
    ok_msg: db "OK",10
    ok_len: equ $-ok_msg

    ; Tab inst: 4/5 chars + opcode
    align 16
    inst_tab:
        db "nop ",0x90, "mov ",0xB8, "add ",0x05, "sub ",0x2D
        db "ret ",0xC3, "push",0x50, "pop ",0x58, "cmp ",0x3D
        db "jmp ",0xE9, "call",0xE8, "xor ",0x35, "and ",0x25
        db "or  ",0x0D, "test",0x85, "lea ",0x8D, "je  ",0x74
        db "jz  ",0x74, "jne ",0x75, "jnz ",0x75, "jg  ",0x7F
        db "jge ",0x7D, "jl  ",0x7C, "jle ",0x7E, "ja  ",0x77
        db "jae ",0x73, "jb  ",0x72, "jbe ",0x76, "jc  ",0x72
        db "jnc ",0x73, "jo  ",0x70, "jno ",0x71, "js  ",0x78
        db "jns ",0x79, "inc ",0xFE, "dec ",0xFE, "neg ",0xF7
        db "mul ",0xF7, "imul",0xF7, "div ",0xF7, "idiv",0xF7
        db "adc ",0x15, "sbb ",0x1D, "not ",0xF7, "shl ",0xD3
        db "shr ",0xD3, "sal ",0xD3, "sar ",0xD3, "rol ",0xD3
        db "ror ",0xD3, "rcl ",0xD3, "rcr ",0xD3, "int ",0xCD
        db "hlt ",0xF4, "clc ",0xF8, "stc ",0xF9, "cli ",0xFA
        db "sti ",0xFB, "cld ",0xFC, "std ",0xFD, "loop",0xE2
        db "loope",0xE1, "loopz",0xE1, "loopne",0xE0, "loopnz",0xE0
        db "int3",0xCC, "into",0xCE, "iret",0xCF, "cbw ",0x98
        db "cwde",0x98, "cwd ",0x99, "cdq ",0x99, "xchg",0x87
        db "xlat",0xD7, "lahf",0x9F, "sahf",0x9E, "wait",0x9B
        db "retf",0xCB, "jp  ",0x7A, "jpe ",0x7A, "jnp ",0x7B
        db "jpo ",0x7B, "movb",0xB0, "movw",0xB8, "movd",0xB8
        db "movq",0xB8, "pusha",0x60, "popa",0x61
        db "pushf",0x9C, "popf",0x9D
        db "movsb",0xA4, "movsw",0xA5, "movsd",0xA5
        db "cmpsb",0xA6, "cmpsw",0xA7, "cmpsd",0xA7
        db "scasb",0xAE, "scasw",0xAF, "scasd",0xAF
        db "lodsb",0xAC, "lodsw",0xAD, "lodsd",0xAD
        db "stosb",0xAA, "stosw",0xAB, "stosd",0xAB

    inst_count: equ 105

section .bss
    alignb 4096
    buffer: resb 65536
    output: resb 65536
    labels: resb 8192
    label_count: resq 1

section .text
global _start

_start:
    ; Ck args
    pop rax
    cmp rax,3
    jne uso_erro

    pop rax      ; argv[0]
    pop rdi      ; entrada
    pop r14      ; saida

    ; Abrir/ler
    mov rax,2
    xor rsi,rsi
    syscall
    js arq_erro

    mov rdi,rax
    xor rax,rax
    lea rsi,[rel buffer]
    mov rdx,65536
    syscall
    mov r15,rax  ; tam

    mov rax,3
    syscall

    ; === PROC ===
    xor rbx,rbx      ; pos ent
    xor r12,r12      ; pos sai

main_loop:
    cmp rbx,r15
    jae escrever

    ; Skip ws
    movzx rax,byte[buffer+rbx]
    cmp al,32
    je pular
    cmp al,10
    je pular
    cmp al,9
    je pular
    cmp al,13
    je pular
    cmp al,0
    je pular

    ; Ck num (0-9)
    cmp al,'0'
    jb tentar_inst
    cmp al,'9'
    ja tentar_inst

    ; Parse num
    call parse_numero
    mov byte[output+r12],al
    inc r12
    jmp main_loop

tentar_inst:
    ; Match inst
    xor r13,r13

inst_loop:
    cmp r13,inst_count
    jae pular

    ; Calc offs
    mov rax,r13
    mov rcx,5
    mul rcx
    lea r10,[rel inst_tab]
    add r10,rax

    ; Cmp 4ch
    mov eax,dword[buffer+rbx]
    cmp eax,dword[r10]
    jne prox_inst

    ; OK! Get opc
    movzx rax,byte[r10+4]
    mov byte[output+r12],al
    inc r12
    add rbx,4

    ; Ck 5ch inst
    cmp r13,60
    jb main_loop
    inc rbx
    jmp main_loop

prox_inst:
    inc r13
    jmp inst_loop

pular:
    inc rbx
    jmp main_loop

; === PARSE NUM ===
parse_numero:
    push rcx
    push rdx
    xor rax,rax
    xor rcx,rcx
.loop:
    cmp rbx,r15
    jae .fim
    movzx rdx,byte[buffer+rbx]
    cmp dl,'0'
    jb .fim
    cmp dl,'9'
    ja .fim
    imul rax,10
    sub dl,'0'
    add rax,rdx
    inc rbx
    jmp .loop
.fim:
    pop rdx
    pop rcx
    ret

; === ESC ARQ ===
escrever:
    mov rdi,r14
    mov rax,2
    mov rsi,0x241
    mov rdx,0644o
    syscall
    js arq_erro

    mov rdi,rax
    mov rax,1
    lea rsi,[rel output]
    mov rdx,r12
    syscall

    mov rax,3
    syscall

    ; OK
    mov rax,1
    mov rdi,1
    lea rsi,[rel ok_msg]
    mov rdx,ok_len
    syscall

    xor rdi,rdi
    jmp sair

uso_erro:
    mov rax,1
    mov rdi,2
    lea rsi,[rel err_uso]
    mov rdx,err_uso_len
    syscall
    mov rdi,1
    jmp sair

arq_erro:
    mov rax,1
    mov rdi,2
    lea rsi,[rel err_arq]
    mov rdx,err_arq_len
    syscall
    mov rdi,1

sair:
    mov rax,60
    syscall
