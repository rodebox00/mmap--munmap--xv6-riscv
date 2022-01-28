//
// Support functions for system calls that involve file descriptors.
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "file.h"
#include "stat.h"
#include "proc.h"
#include "vma.h"
#include "fcntl.h"



struct vma vmas[VMAS_STORED];
struct spinlock vmaslock; //Lock to modify global vma array

extern pte_t *walk(pagetable_t, uint64, int);

struct devsw devsw[NDEV];
struct {
  struct spinlock lock;
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
  initlock(&ftable.lock, "ftable");
}

// Allocate a file structure.
struct file*
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filedup");
  f->ref++;
  release(&ftable.lock);
  return f;
}

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  struct file ff;

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  if(--f->ref > 0){
    release(&ftable.lock);
    return;
  }
  ff = *f;
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);

  if(ff.type == FD_PIPE){
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
  struct proc *p = myproc();
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    ilock(f->ip);
    stati(f->ip, &st);
    iunlock(f->ip);
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
      return -1;
    return 0;
  }
  return -1;
}

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
  int r = 0;

  if(f->readable == 0)
    return -1;

  if(f->type == FD_PIPE){
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    ilock(f->ip);
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
  } else {
    panic("fileread");
  }

  return r;
}

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    return -1;

  if(f->type == FD_PIPE){
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    // write a few blocks at a time to avoid exceeding
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
      ilock(f->ip);
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r != n1){
        // error from writei
        break;
      }
      i += r;
    }
    ret = (i == n ? n : -1);
  } else {
    panic("filewrite");
  }

  return ret;
}

#pragma GCC push_options
#pragma GCC optimize ("O0")

uint64
mmap(void *addr, uint64 length, int prot, int flag, int fd){

  struct proc *p = myproc();

  //Check if it is a private map or not and it has the correct permissions
  if(flag == MAP_SHARED){
    
  }else if(flag != MAP_SHARED && flag != MAP_PRIVATE) return 0xffffffffffffffff;

  int i;
  struct vma *n, *act, *prev;
  uint64 psize;  //Real size of the vma based on page size

  acquire(&p->lock);

  if(p->nvma == MAX_VMAS){
    release(&p->lock);
    return 0xffffffffffffffff;
  }

  acquire(&vmaslock);

  //Search for a free vma in the global vma array
  for(i = 0; i < VMAS_STORED; i++){
    if(vmas[i].use == 0) break;
    else if(i == VMAS_STORED-1){
      release(&p->lock);
      release(&vmaslock);
      return 0xffffffffffffffff;  //No free vma was found
    }
  }

  psize = PGROUNDUP(length-1);
  act = p->vmas;
  prev = 0;
  n = 0;

  printf("ENTRA\n");

  for(i= 0; i<=MAX_VMAS; i++){
    if(act == 0){
      printf("1\n");
      if(((prev != 0) && (prev->addre + psize) >= TOP_ADDRESS) || ((prev == 0) && START_ADDRESS + psize >= TOP_ADDRESS)){
        printf("1\n");
        return 0xffffffffffffffff; //The vma can not be allocated
      }
      n = &vmas[i];
      printf("1\n");
      if(prev == 0){
        n->addri = START_ADDRESS;
        n->addre = START_ADDRESS + psize + 1;
      }else{
        prev->next = n;
        n->addri = prev->addre;
        n->addre = prev->addre + psize + 1; 
      }
      n->next = 0;
      goto allocated; 

    }else if((prev != 0) && prev->addre + psize < act->addri){ //A new vma can fit between two
      printf("1\n");
      n = &vmas[i];
      prev->next = n;
      n->next = act;
      n->addri = prev->addre;
      n->addre = prev->addre + psize + 1;
      goto allocated; 
    }

    printf("1\n"); 
    prev = act;
    act = act->next;
  }
  printf("1\n");
  return 0xffffffffffffffff; //The vma can not be allocated

  allocated:
    n->size = length;
    n->use = 1;
    n->prot = prot;
    n->ofile = p->ofile[fd];
    n->offset = 0;
    n->flag = flag;
    n->addrinit = n->addri;

    release(&vmaslock);

    p->ofile[fd]->ref++;  //Add a reference to the file
    if(p->nvma == 0)  p->vmas = n;
    p->nvma++;
 
    release(&p->lock);

    printf("Devuekvo %p\n", n->addri);
    return n->addri; 
}
#pragma GCC pop_options

#pragma GCC push_options
#pragma GCC optimize ("O0")

int
munmap(uint64 addr, uint64 length){

  struct proc *p = myproc(); 

  acquire(&p->lock);
  struct vma *act = p->vmas;
  struct vma *prev = 0;
  int i;
  
  printf("1\n");

  //Function to release a vma
  void freeVma(){
    acquire(&vmaslock);

    //Organize the linked list of vmas
    if(prev == 0){
      if(act->next == 0) p->vmas = 0;
      else p->vmas = act->next;
    }else if(act->next != 0) prev->next = act->next;

    act->use = 0;
    act->size = 0;  
    act->ofile = 0;
    act->addrinit = 0;
    act->addri = 0;
    act->addre = 0;   
    act->offset = 0;
    act->next = 0;
    act->prot = 0;
    act->flag = 0;
    p->nvma--;
    release(&vmaslock);
  }

  printf("2\n");

  //Check if the address is contained in a vma
  for(i = 0; i<p->nvma; i++){
    printf("%p %p %p\n", addr+length, act->addri, act->addre);
    if(addr+length-1 >= act->addri && addr+length-1 < act->addre) break;
    prev = act;
    act = act->next;
  }

  //printf("%p %d\n", addr, length);

  if(i == p->nvma){
    release(&p->lock);
    return -1; 
  }

  pte_t *pte;
  
  printf("3\n");

  //Whether flag MAP_SHARED was established, check if the page has the dirty bit and if it has write in disk
  if(act->flag == MAP_SHARED){
    printf("4\n");
    for(i = 0; i < PGROUNDUP(length-1)/PGSIZE; i++){
      printf("5\n");
      pte =  walk(p->pagetable, PGROUNDDOWN(addr+i*PGSIZE), 0);
      if(CHECK_BIT(*pte, 7)){
        printf("6\n");
        ilock(act->ofile->ip);
        if(writei(act->ofile->ip, 1, PGROUNDDOWN(addr), PGROUNDDOWN(addr)-act->addrinit, PGSIZE) == -1){
          iunlock(act->ofile->ip);  
          release(&p->lock);
          return -1;
        }
        iunlock(act->ofile->ip);
      }
    }
}
  printf("8\n");
  uvmunmap(p->pagetable, PGROUNDDOWN(addr), PGROUNDUP(length-1)/PGSIZE, 1);

  printf("%d\n", PGROUNDUP(length));

  if(act->addri+PGROUNDUP(length-1) + 1 == act->addre){
    act->ofile->ref--;  //Reduce references to file 
    freeVma();
  }else act->addri = act->addri+PGROUNDUP(length-1);  //Set the new init address of the vma

  release(&p->lock);
  return 0;
}

#pragma GCC pop_options