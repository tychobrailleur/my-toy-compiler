#include <stdio.h>


char*
foo(char* in)
{
    return in;
}

int
main() 
{
    printf("Hello, %s", foo("World"));
}
