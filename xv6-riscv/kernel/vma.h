#define START_ADDRESS 0x2000000000  //First address of the process memory area where a vma is created
#define TOP_ADDRESS 0x3FFFFFDFFF //Maximum address of the process where a vma can fit

struct vma
{
    int use;
    unsigned int long size;     //Truly size of the information inside vma
    struct file *ofile;
    unsigned int long addri;    //Init address of the vma
    unsigned int long addre;    //End address of the vma
    unsigned int long offset;
    struct vma *next;
    int prot;
    int flag;
};
