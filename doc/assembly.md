As I am using `gcc -S` to figure out the code that needs to be
generated, this page describes GNU AS as I understand it — usual
warnings here: this is my own understanding of it works, it could be
incorrect...



Syntax of an instruction:

    opcode source, destination
    
Instruction names finish with `q`, `l`, `w` or `b`, depending on the
size of the operands: `q` for quadriword, `l` for long, `w` for word
and `b` for byte.

To use 64 bits, registers must be named with `r`, to use only the
lowest 32 bits, they must be named with `e`: `%rax` uses the whole
register, `%eax` uses only the lowest 32.

* `rax`, `rbx`, `rcx`, `rdx` are the general purpose registers.
  Remember, if using the lower 32 bits, they become `eax`, `ebx`,
  `ecx`, `edx`.
* `rsi`, `rdi` are the index registers.
* `rsp` is the stack pointer


Sections: http://sourceware.org/binutils/docs/as/Secs-Background.html#Secs-Background
