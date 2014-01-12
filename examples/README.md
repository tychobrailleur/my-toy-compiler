To execute an example:

```
cd examples/
ruby -I.. <filename> > example.s
gcc -o example example.s ../runtime.c
```