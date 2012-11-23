As I am using `gcc -S` to figure out the code that needs to be
generated, this page describes GNU AS as I understand it — usual
warnings here: this is my own understanding of how it works, it could
be incorrect...



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
* `rsi`, `rdi` are the index registers (`si`, source index; `di`, destination index).
* `rsp` is the stack pointer
* `rbp` is the stackframe base pointer.
* Also have `r8`, `r9`, `r10`, `r11`, `r12`, `r13`, `r14`, `r15` 64 bits general purpose register.  To access lower 32 bits, use `r8d`, etc. `r15d`.  To access lowest 16 bits, use `r8w`, etc. `r15w`. To access last 8 bits, use `r8b`, etc. `r15b`.

According to [AMD’s documentation](http://support.amd.com/us/Processor_TechDocs/24592_APM_v1.pdf), “a stack is a potion of a stack segment in memory that is used to link procedures. Software convenions typically define stacks using a _stack frame_, which consists of two registers—a _stackframe base pointer_ (rBP) and a _stack pointer_ (rSP)”.

## Addressing

* Immediate addressing: set constant (prefixed with `$`) directly into a register:
    movl $4, %eax
    addl $-45, %esi
* Register indirect: When using the register between parenthesis, it holds a memory _address_:
    movl $45, (%ebx) # store 45 at the memory location whose address is stored in ebx
* Register indexed: When using an offset with an index register:
    movl $45, 12(%ebx)

### Function calls

First, save the base pointer:

    pushq %rbp # Save stackframe pointer
    movq %rsp, %rbp # Copy stack pointer to base pointer

Last, restore base pointer:

    popq %rbp
    ret

See also http://www.delorie.com/djgpp/doc/ug/asm/calling.html

Each function has a frame on the runtime stack, which grows downwards.


## Fastcall registers

Fastcall passes the first 4 integers (and pointers) in the registers `rcx`, `rdx`, `r8` and `r9`.  The following arguments are passed on the stack. See also http://www.x86-64.org/documentation/abi.pdf

## Instructions

* `leave`: frees the space saved on the stack by copying ebp into esp, then popping the saved value of esp back to ebp.

* `mov`: Copies data. Example:

    movq %rbx, %rax # Copies value of %rbx into %rax.

* `lea`: Load effective address.
* `add`: Integer addition.
* `imul`: Signed multiply.
* `sall`: arithmetic shift left. 
* `sarl`: arithmetic shift right. 

* `call`, `ret`: Subroutine call, and return. The call instruction pushes the return address on the stack.

* `int`: Call to interrupt.  The interrupt number is passed as a parameter and is a byte.

## C Function call

* Push function’s arguments onto the stack, last arg first.

### Return value

* Integers, pointers stored in `%rax` register.

## Labels

* `.L` are for local labels — avoid conflicts.
* `.LFB` function begin
* `.LFE` function end
* `.LPE` prologue end
* `.LEB` epilogue begin

## Pseudo-Ops

* `.globl`, or `.global`: makes the symbol visible for linking.
* `.section name`: indicates that code must be assembled into a section named `name` (e.g. `rodata`, read-only data)
* `.string "A String"`: copies characters into the binary file and ends it with a 0 byte.
* `.text subsection`: indicates that the code must be assembled onto the end of the text subsection _subsection_; if no subsection specified, subsection _0_.

See also: http://sourceware.org/binutils/docs/as/Pseudo-Ops.html

## CFI Directives 

Call Frame Information used to build a backtrace.



See also http://www.logix.cz/michal/devel/gas-cfi/


Sections: http://sourceware.org/binutils/docs/as/Secs-Background.html#Secs-Background

* `.cfi_def_cfa reg,imm`: Set a rule for computing CFA to: take content of register reg and add imm to it.

## Other Links

* http://scr.csc.noctrl.edu/courses/csc220/asm/GnuFTPl.htm
* http://scr.csc.noctrl.edu/courses/csc220/asm/gasmanual.pdf
* http://cs.nyu.edu/courses/fall11/CSCI-GA.2130-001/x64-intro.pdf
* http://gcc.gnu.org/viewcvs/trunk/gcc/dwarf2out.c?view=markup
* http://www.logix.cz/michal/devel/gas-cfi/
* http://x86-64.org/documentation/abi.pdf
* http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64/

## Other Abbreviations

* ABI: Application Binary Interface
* CFA: Canonical Frame Address, a fixed address on the stack which identifies a call frame.
* CFI: Call Frame Instruction

