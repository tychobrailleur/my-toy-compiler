As I am using `gcc -S` to figure out the code that needs to be
generated, this page describes GNU AS as I understand it — usual
warnings here: this is my own understanding of how it works, it could be
incorrect...



Syntax of an instruction:

    opcode source, destination
    
Instruction names finish with `q`, `l`, `w` or `b`, depending on the
size of the operands: `q` for quadriword, `l` for long, `w` for word
and `b` for byte.

## Registers

To use 64 bits, registers must be named with `r`, to use only the
lowest 32 bits, they must be named with `e`: `%rax` uses the whole
register, `%eax` uses only the lowest 32.

* `rax`, `rbx`, `rcx`, `rdx` are the general purpose registers.
  Remember, if using the lower 32 bits, they become `eax`, `ebx`,
  `ecx`, `edx`.
* `rsi`, `rdi` are the index registers.
* `rsp` is the stack pointer

## Addressing

* Immediate addressing: set constant (prefixed with `$`) directly into a register:
    movl $4, %eax
    addl $-45, %esi
* Register indirect: When using the register between parenthesis, it holds a memory _address_:
    movl $45, (%ebx) # store 45 at the memory location whose address is stored in ebx
* Register indexed: When using an offset with an index register:
    movl $45, 12(%ebx)


## Labels

* `.L` are for local labels — avoid conflicts.
* `.LFB` function begin
* `.LFE` function end
* `.LPE` prologue end
* `.LEB` epilogue begin

## Pseudo-Ops

* `.globl`, or `.global`: makes the symbol visible for linking.

## CFI Directives 

Call Frame Information used to build a backtrace.



See also http://www.logix.cz/michal/devel/gas-cfi/


Sections: http://sourceware.org/binutils/docs/as/Secs-Background.html#Secs-Background

## Other Links

* http://scr.csc.noctrl.edu/courses/csc220/asm/GnuFTPl.htm
* http://scr.csc.noctrl.edu/courses/csc220/asm/gasmanual.pdf
* http://gcc.gnu.org/viewcvs/trunk/gcc/dwarf2out.c?view=markup
* http://www.logix.cz/michal/devel/gas-cfi/

## Other Abbreviations

* CFA: Canonical Frame Address, a fixed address on the stack which identifies a call frame.
* CFI: Call Frame Instruction
