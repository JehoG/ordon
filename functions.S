data_item:
.section .data

.equ    SYS_WRITE, 1


.equ    STDERR, 2

#Args
#   mem1 ptr: %rdi
#   mem2 ptr: %rsi
#   mem length: %rdx
#Var:
#   counter: %rcx
#   char: %r8
MemCmp:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $1, %rax
    movq    $0, %rcx

_start_while_mem_cmp:               #for (i=0; i < length; i++)
    cmp     %rcx, %rdx
    je      _end_mem_cmp

    movb    (%rdi), %r8b            #   if (str1[i] != str2[i]){
    cmpb     %r8b, (%rsi)           #       break
    jne     _not_equal_mem_cmp      #   }
                        
    addq    $1, %rcx                # i++
    addq    $1, %rdi
    addq    $1, %rsi
    jmp     _start_while_mem_cmp    #} while

_not_equal_mem_cmp:
    movq    $0, %rax
_end_mem_cmp:
    leave
    ret


#   str ptr: %rdi
PrintStr:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movq    %rdi, %rcx          #str ptr
    call    StrLen
    movq    %rax, %rdx
    movq    %rcx, %rsi
    
    movq    $SYS_WRITE, %rax            
    movq    $STDERR, %rdi                
    syscall
    leave
    ret


# %rdi: str ptr
# %rsi: counter
StrLen:
    pushq   %rbp
    movq    %rsp, %rbp

    movl    $0, %esi

_startStrLen:
    cmpb    $0, (%edi)
    je      _endStrLen

    addl    $1, %esi
    addl    $1, %edi
    jmp     _startStrLen

_endStrLen:
    movq    %rsi, %rax
    leave
    ret
