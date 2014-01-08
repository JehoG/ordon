#include "functions.S"

data_items:
.section .data
#STRUCTS:
#struct Activity
ACT_TYPE:    .int    0
ACT_EXEC_TIME:   .int    4
ACT_NEXT:    .int    8  #pointer to Activity struct
ACT_SIZE:    .int    16
#struct Process
PRO_ID:      .int    0   #pointer to string
PRO_ARRIVAL: .int    8
PRO_PRIORITY:    .int    12
PRO_ACT_LIST:    .int    16  #pointer to Actvity
PRO_NEXT:    .int    24  #pointer to Process
PRO_SIZE:    .int    32

STR: .ascii "hello\n"
STR_ERR_NB_ARG: .ascii  "Erreur: Utilisation: nom_du_programme nom_du_fichier!\n\0"
STR_ERR_FILE_OPEN: .ascii   "Erreur: impossible d'ouvrir le fichier!\n\0"
STR_ERR_INVALID_FILE: .ascii "Erreur: fichier mal formé!\n\0"
STR_TEST: .ascii "TEST\n"
.equ    STR_TEST_LEN, 5

.equ    SYS_OPEN, 2

.equ    STDIN, 0
.equ    STDOUT, 1

.equ    O_RDONLY, 0

#Position of var:
.equ    STACK_RESERVE, 8
.equ    STACK_FD, 8
.section .text

	.globl main
main:
    pushq   %rbp
    movq    %rsp, %rbp                  #saving stack ptr
    subq    $STACK_RESERVE, %rsp
    movq    %rsp, %rbx

    movq    %rsi, %rcx                  # Saving filename in %rcx
    addq    $8, %rcx                    # Second arg of argv[]
    movq    (%rcx), %rcx                # %rcx = argv[2]

    cmp     $2, %rdi                    #if(argc != 2){
    je      _mainReadFile               #   ErrArgs()

    movq    $STR_ERR_NB_ARG, %rdi
    call    PrintStr
    jmp     _mainEnd                    #} else {
_mainReadFile:
    movq    %rcx, %rdi
    call    ReadFile                    # ReadFile()
                                        #}
_mainEnd:
    leave
    ret

#Var:
#   Line: %r12
#   Pos: %r13
#   Line status: %r14
ReadFile:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $24, %rsp                    # Saving caller-saved regs:
    movq    %r12, (%rsp)                
    movq    %r13, 8(%rsp)                
    movq    %r14, 16(%rsp)               

    call    OpenFile
    movq    %rax, STACK_FD(%rbx)            # Saving the FD in the main stack
    cmp     $0, %rax
    je      _errFileOpen
    call    ReadAlgo

    movq    $0, %r13
_start_while_read_file:                     # do {
    call    ReadLine
    movq    %rax, %r12
    movq    %rdx, %r14

#Test
    movq    %r12, %rdi
    call    PrintStr

    movq    %r12, %rdi
    movq    %r13, %rsi
    call    ReadProcess
    movq    %r12, %rdi
    call    free
    addq    $1, %r13
    cmpq    $0, %r14
    jne     _start_while_read_file          # } while( not_last_line( %r14 != 0 ))

    jmp     _readFileEnd
_errFileOpen:
    movq    $STR_ERR_FILE_OPEN, %rdi
    call    PrintStr
_readFileEnd:
    movq    8(%rsp), %r13
    movq    16(%rsp), %r14
    movq    (%rsp), %r12                # Restoring %r12 value
    addq    $24, %rsp
    leave
    ret

# Vars:
#   %r12: line
#   %r13: process
ReadProcess:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $16, %rsp                    # Saving caller-saved regs:
    movq    %r12, (%rsp)                
    movq    %r13, 8(%rsp)
    movq    %rdi, %r12                  # %r12 = line

    movq    $PRO_SIZE, %rdi             # process = malloc(sizeof(process)) -> %r13
    call    malloc
    movq    %rax, %r13

    movq    %rsi, PRO_PRIORITY(%r13)    # Saving priority

    movq    %r12, %rdi

    movq    $58, %rsi                   # Getting process ID
    call    SubStrUntil
    movq    %rax, PRO_ID(%r13)
    addq    %rdx, %r12

    movq    %r12, %rdi                  # Getting arrival time
    call    StrToInt
    movq    %rax, PRO_ARRIVAL(%r13)
    addq    %rdx, %r12

    movq    %r12, %rdi                  # Getting activity list
    movq    %r13, %rsi
    addq    $PRO_ACT_LIST, %rsi
    movq    $0, (%rsi)
    call    ReadActivities
#    movq    %rax, PRO_ACT_LIST(%r13)
#   FREE    

_stop:
    movq    8(%rsp), %r13
    movq    (%rsp), %r12                # Restoring %r12 value
    addq    $16, %rsp
    leave
    ret

# Params:
#   Str: %rdi
# Ret:
#   Act list: %rax
# Var:
#   Char: %rcx
#   Pointer to the next act: %r12
#   Pointer to the actual act: %r13
#   Str: %r14 -----
#
.CPU:
    .string "CPU"
.IO:
    .string "E/S"
.CPUTEST:
    .string "---CPU\n\0"
.IOTEST:
    .string "---E/S\n\0"

ReadActivities:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $24, %rsp
    movq    %r12, (%rsp)
    movq    %r13, 8(%rsp)
    movq    %r14, 16(%rsp)

    movq    %rdi, %r14
    movq    %rsi, %r12

_start_while_read_activities:
    cmpb    $0, (%r14)
    je      _end_while_read_activities
    cmpb    $10, (%r14)
    je      _end_while_read_activities
    cmpb    $-1, (%r14)
    je      _end_while_read_activities
   

#    movq    %r14, %rdi
#    call    PrintStr
    addq    $1, %r14


    movq    ACT_SIZE, %rdi
    call    malloc
    movq    %rax, (%r12)                    # actual_act = malloc(sizeof(act)) 
    

    movq    %rax, %r13
    movq    %r13, %r12
#    addq    $ACT_NEXT, %r12                  # next_act = &actual_act->next
    addq    $8, %r12
   
    movq    $.CPU, %rdi
    movq    %r14, %rsi
    movq    $3, %rdx
    call    MemCmp
    cmp     $0, %rax
    je      _read_act_check_io

    movq    $.CPUTEST, %rdi
    call    PrintStr

    movq    $1, (%r13)
    jmp     _read_act_exec_time
_read_act_check_io:
    movq    $.IO, %rdi
    movq    %r14, %rsi
    movq    $3, %rdx
    call    MemCmp
    cmp     $0, %rax
    je      _read_act_invalid_file

    movq    $.IOTEST, %rdi
    call    PrintStr

    movq    $0, (%r13)

_read_act_exec_time:
    addq    $4, %r14

    movq    %r14, %rdi
    call    StrToInt

    pushq   %rdx

#    movq    %r14, %rdi
#    call    PrintStr

    cmpb     $10, 1(%r14)
    jne     _end

    movq    $STR_ERR_NB_ARG, %rdi
    call    PrintStr

_end:
    popq    %rdx
    addq    %rdx, %r14

#    cmpb    $58, (%rdi)
#    jne     _start_while_read_activities 
#    addq    $1, %rdi
    jmp     _start_while_read_activities

_read_act_invalid_file:
    movq    $STR_ERR_INVALID_FILE, %rdi
    call    PrintStr

_end_while_read_activities:

    movq    16(%rsp), %r14
    movq    8(%rsp), %r13
    movq    (%rsp), %r12
    addq    $24, %rsp
    leave
    ret

# var:
#   %r12: line
# return:
#   %rax: algo (0:SJFP or 1:RR)
#   %rdx: quantum
.AlgSJFP:
    .string "Alg:SJFP"
.AlgRR:
    .string "Alg:RR"
ReadAlgo:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp                    # Saving caller-saved regs:
    movq    %r12, (%rsp)                # %r12

    call    ReadLine
    movq    %rax, %r12
    movq    %rax, %rdi
    call    StrLen
    cmp     $8, %rax
    jl     _read_algo_err_file
    
    movq    %r12, %rdi
    movq    $.AlgSJFP, %rsi              # "r"
    movq    $8, %rdx
    call    MemCmp
    cmp     $0, %rax
    jne      _sjfp_read_algo
    movq    %r12, %rdi
    movq    $.AlgRR, %rsi
    movq    $6, %rdx
    call    MemCmp
    cmp     $0, %rax
    jne      _rr_read_algo
    jmp     _read_algo_err_file
_rr_read_algo:
    movq    $.AlgRR, %rdi
    call    PrintStr

    movq    %r12, %rdi
    addq    $7, %rdi
    call    StrToInt
    movq    %rax, %rdx
    movq    $1, %rax
    jmp     _end_read_algo

_sjfp_read_algo:
    movq    $.AlgSJFP, %rdi
    call    PrintStr
    movq    $0, %rax
    jmp     _end_read_algo

_read_algo_err_file:
    movq    $STR_ERR_INVALID_FILE, %rdi
    call    PrintStr
_end_read_algo:
    movq    %r12, %rdi                  #free(line)
    call    free
    movq    (%rsp), %r12                # Restoring %r14 value
    addq    $8, %rsp
    leave
    ret

# %esi: max
# %r9:  char
# %r15: count
# %r14: line
# Ret:
#   %rax:   line
#   %rdx:   last char (1: \n, 0: EOF)
ReadLine:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $16, %rsp                   # Saving caller-saved regs:
    movq    %r14, (%rsp)                # %r14
    movq    %r15, 8(%rsp)               # %r15
   
    movl    $128, %esi

    movslq  %esi, %rdi                  # %r14 = malloc(max)
    call    malloc
    movq    %rax, %r14

    movl    $0, %r15d
    movb    $0, %r9b

_startWhileReadLine:
    cmpb    $10, %r9b
    je      _endLineReadLine
    cmpb    $-1, %r9b
    je      _endFileReadLine

    movq    STACK_FD(%rbx), %rdi
#    movq    %rdi, %rax
    call    _IO_getc
    movb    %al, %r9b
    movq    %r14, %rcx
    addq    %r15, %rcx
    movb    %r9b, (%rcx)

    addl    $1, %r15d

    
    jmp     _startWhileReadLine
_endLineReadLine:
    movl    $1, %edx
    jmp     _endWhileReadLine
_endFileReadLine:
    movl    $0, %edx
    jmp     _endWhileReadLine

_endWhileReadLine:
    addq    $1, %rcx
    movb    $0, (%rcx)

    movq    %r14, %rax 
#    call    ErrFileOpen
    movq    (%rsp), %r14                # Restoring %r14 value
    movq    8(%rsp), %r15
    addq    $16, %rsp
    leave
    ret
    
.LCOPEN:
    .string "r"
# Arg: %rdi: filename
OpenFile:
    pushq   %rbp
    movq    %rsp, %rbp
#    movq    $SYS_OPEN, %rax
#    movq    %rcx, %rdi                  # filename
    movl    $.LCOPEN, %esi              # "r"
#    movq    $0666, %rdx
    call    fopen                                
    leave
    ret
