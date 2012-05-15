This is my first attempt at a simple compiler following the Ruby
 compiler series:
 http://www.hokstad.com/writing-a-compiler-in-ruby-bottom-up-step-2.html

The article however uses x86 assembler, when this is an attempt at
generating x64 assembler.  I know nothing of x64 assembler, and the
code generated is deduced from `gcc -S` as indicated by the article
series.  This means that more than likely the code is either
suboptimal, or plain incorrect.  In particular, the convoluted way in
which the label sequence is computed is due to the fact that I wanted
to keep the registers used for the function call args in the order
returned by gcc.  I actually have no idea what the registers may be,
or if they could be possibly ordered in another way.

The command used to compile is:

    ruby stuff.rb > hello.s ; gcc -o hello hello.s

Some useful links:

* http://www.hep.wisc.edu/~pinghc/x86AssmTutorial.htm x86 GNU AS tutorial, but very useful to get started with x64.