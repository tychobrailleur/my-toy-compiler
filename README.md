This is my first attempt at a simple compiler following the Ruby
 compiler series:
 http://www.hokstad.com/tag/compiler%20in%20Ruby%20bottom%20up

The article however uses x86 assembler, when this is an attempt at
generating x64 assembler.  I know nothing of x64 assembler, and the
code generated is deduced from `gcc -S` as indicated by the article
series.  This means that more than likely the code is either
suboptimal, or plain incorrect.

The command used to compile is:

    ruby compiler.rb > hello.s ; gcc -o hello hello.s

# Docker

  docker can be used to compile everything:

```
cd docker
docker build -t my-compiler .
docker run -it -v $(pwd)/..:/develop my-compiler:latest /bin/bash
```

Some useful links:

* http://www.hep.wisc.edu/~pinghc/x86AssmTutorial.htm x86 GNU AS tutorial, but very useful to get started with x64.
