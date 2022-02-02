//First address of the process memory area where a vma is created
#define START_ADDRESS 0x2000000000  

//Maximum address of the process where a vma can fit
#define TOP_ADDRESS 0x3FFFFFDFFF 


struct vma
{
    int use;
    unsigned int long size;     //True size of the information inside vma
    struct file *ofile;
    unsigned int long addrinit;    //Initial init address (included)
    unsigned int long addri;    //Actual init address (included)
    unsigned int long addre;    //Actual final address (not included in the vma)
    unsigned int long offset;
    struct vma *next;
    int prot;
    int flag;
};
