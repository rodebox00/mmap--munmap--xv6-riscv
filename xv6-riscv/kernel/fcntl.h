#define O_RDONLY  0x000
#define O_WRONLY  0x001
#define O_RDWR    0x002
#define O_CREATE  0x200
#define O_TRUNC   0x400

//field prot for mmap
#define PROT_READ (1L << 1)
#define PROT_WRITE (1L << 2)
#define PROT_READ_WRITE ((1L << 1)|(1L << 2))

//flags for mmap
#define MAP_PRIVATE 1
#define MAP_SHARED 2

