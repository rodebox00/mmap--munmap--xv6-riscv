# mmap--munmap--xv6-riscv

En esta modificación del sistema operativo xv6 se incluyen las implementaciones de las llamadas al sistema `nmap()` y `munmap()` que permiten la creación, eliminación o modificación de VMAs (Virtual Me-
mory Areas) respectivamente.

Esta versión modificada trae consigo un programa llamado `mmaptest` que comprueba el correcto funcionamiento de ambas llamadas al sistema.

Para poder ejecutar este xv6 modificado y simular la arquitectura se debe ejecutar el comando `make qemu` desde el directorio en el que se encuentra el fichero **Makefile**.

-------------------------------------------------

# mmap--munmap--xv6-riscv

This modification of the xv6 operating system includes implementations of the `nmap()` and `munmap()` system calls that allow the creation, deletion or modification of VMAs (Virtual Me-
mory Areas) respectively.

This modified version comes with a program called `mmaptest` that checks the correct operation of both system calls.

In order to run this modified xv6 and simulate the architecture you must run the `make qemu` command from the directory where the **Makefile** file is located.
