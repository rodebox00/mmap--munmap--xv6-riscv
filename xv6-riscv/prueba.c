#include <stdlib.h>
#include <stdio.h>

int main(int argc, char const *argv[])
{   
    int i = 2;
    int *p, *c;

    p = &i;

    c = &*p;
    
    printf("%d", *c);
    /*int *p = 1;
    printf("%d", *p);


    pe[0] = "a";

    int n = sizeof(pe);
    if(pe[0] == 0) printf("PRIMERO/n");
    if(pe[1] == NULL) printf("SEGUNDO");
    if(pe[2] == NULL) printf("SEGUNDO");
    printf("%d",n);*/
    
    return 0;
}

