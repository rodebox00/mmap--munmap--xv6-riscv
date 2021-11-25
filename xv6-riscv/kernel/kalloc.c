// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

#define MAXPAGES (PHYSTOP / PGSIZE)

void _freerange(void *pa_vstart, void *pa_vend);
void freerange(void *pa_start, void *pa_end);
void _kfree(void *pa);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
  uint ref; // reference count
};

struct {
  struct spinlock lock;
  struct run *freelist;
  // DEP: For COW fork, we can't store the run in the 
  //      physical page, because we need space for the ref
  //      count.  Move to the kmem struct.
  struct run runs[MAXPAGES];
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  _freerange(end, (void*)PHYSTOP);
}

void
_freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    _kfree(p);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Called by _freerange, which is only called by kinit.
void
_kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("_kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = &kmem.runs[(uint64)pa / PGSIZE];

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}


// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = &kmem.runs[(uint64)pa / PGSIZE];
  if (r->ref != 1) {
    // assert ref == 1
    printf("kfree: assert ref == 1 failed\n");
    printf("0x%x %d\n", r, r->ref);
    exit(-1);
  }
  
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r){
    r->ref = 1;
    kmem.freelist = r->next;
  }
  release(&kmem.lock);

  if(r)
    memset((char*)((r - kmem.runs) * PGSIZE), 5, PGSIZE); // fill with junk
  return (void*)((r - kmem.runs) * PGSIZE);
}


/**
 * Increment the reference count of a page descriptor.
 */
void
incref(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("incref");

  acquire(&kmem.lock);
  r = &kmem.runs[(uint64)pa / PGSIZE];
  r->ref++;
  release(&kmem.lock);
}

/**
 * Decrement the reference count of a page descriptor.
 */
void
decref(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("decref");

  acquire(&kmem.lock);
  r = &kmem.runs[(uint64)pa / PGSIZE];
  r->ref--;
  release(&kmem.lock);
}

/**
 * Get reference count of a page descriptor.
 */
uint
getref(void *pa)
{
  struct run *r = &kmem.runs[(uint64)pa / PGSIZE];
  return r->ref;
}

/**
 * Print reference count of a page descriptor.
 */
void
printref(char *pa)
{
  struct run *r = &kmem.runs[(uint64)pa / PGSIZE];
  printf("printref: address: 0x%p, ref: %d\n", r, r->ref);
}
