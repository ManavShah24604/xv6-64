#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

#define NULL 0

#ifdef MLFQ
struct Queue mlfq[NMLFQ];
#endif

int my_max(int a, int b)
{
  if (a > b)
    return a;
  return b;
}
int mine_min(int a, int b)
{
  if (a < b)
    return a;
  return b;
}

// static int all_tickets = 0;

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.

// void Ticket_set_for_process(struct proc *p, int n)
// {
//   cprintf("Print from function Ticket_set_for_process and process ID: %d\n", p->pid);
//   all_tickets -= p->nice_pro1;
//   p->nice_pro1 = n;
//   all_tickets += p->nice_pro1;
// }

void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }

#ifdef MLFQ
  for (int i = 0; i < NMLFQ; i++)
  {
    mlfq[i].size = 0;
    mlfq[i].head = 0;
    mlfq[i].tail = 0;
  }
#endif
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

int proc_priority(const struct proc *process)
{
  int nice = 5;

  if (process->ticks_last_scheduled != 0) // if the process hasnt been scheduled yet before
  {
    if (process->num_run != 0)
    {
      int time_diff = process->last_run + process->last_sleep;
      int sleeping = process->last_sleep;
      if (time_diff != 0)
        nice = ((sleeping) / (time_diff)) * 10;
    }
  }
  if (mine_min(process->priority - nice + 5, 1001) > 0)
    return mine_min(process->priority - nice + 5, 100);
  else
    return 0;
}

static struct proc *
allocproc(void)
{
  struct proc *p;
  int ok = 0;
  p = proc;
  while (p < &proc[NPROC])
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      ok = 1;
      break;
    }
    else
    {
      release(&p->lock);
    }
    p++;
  }
  if (!ok)
    return 0;

  p->pid = allocpid();
  p->state = USED;
  // p->tickets=10;
  // for PBS
  p->priority = 60;

  p->tick = 0;
  p->ticket = InitialTickets; // initially

  ok = 1;

  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    ok = 0;
  }

  if (ok)
  {
    p->pagetable = proc_pagetable(p);
    if (p->pagetable == 0)
    {
      freeproc(p);
      release(&p->lock);
      return 0;
    }

    if ((p->trapframe_copy = (struct trapframe *)kalloc()) == 0)
    {
      release(&p->lock);
      return 0;
    }
    p->handler = 0;
    p->is_sigalarm = 0;
    p->now_ticks = 0;
    p->ticks = 0;

    memset(&p->context, 0, sizeof(p->context));
    p->context.ra = (uint64)forkret;

    p->etime = 0;
    p->ctime = ticks;
    p->context.sp = p->kstack + PGSIZE;
    p->rtime = 0;

#ifdef MLFQ
    p->priority = 0;
    p->in_queue = 0;
    p->quanta = 1;
    p->nrun = 0;
    p->qitime = ticks;
    for (int i = 0; i < NMLFQ; i++)
      p->qrtime[i] = 0;

#endif

    return p;
  }
  return 0;
}

int set_priority(int new_static_priority, int proc_pid)
{
  struct proc *p;
  int old_static_priority = -1;

  if (new_static_priority < 0)
  {
    printf("<new_static_priority> should be in range [0 - 100]\n");
    return -1;
  }
  if (new_static_priority > 100)
  {
    printf("<new_static_priority> should be in range [0 - 100]\n");
    return -1;
  }
  int found = 1;
  p = proc;
  while (p < &proc[NPROC])
  {
    acquire(&p->lock);
    if (p->pid == proc_pid)
    {
      old_static_priority = p->priority;
      p->priority = new_static_priority;
      found = 0;
      break;
    }
    release(&p->lock);
    p++;
  }
  if (!found)
  {
    printf("priority of proc wit pid : %d changed from %d to %d \n", p->pid, old_static_priority, new_static_priority);
    release(&p->lock);
    if (old_static_priority < new_static_priority)
    {
      p->last_run = 0;
      p->last_sleep = 0;
#ifdef PBS
      yield();
#else
      ;
#endif
    }
  }
  else
    printf("no process with pid : %d exists\n", proc_pid);
  return old_static_priority;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);

  if (p->trapframe_copy)
    kfree((void *)p->trapframe_copy);

  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);

  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
static inline void
sti(void)
{
  asm volatile("sti");
}
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
  np->ticket = p->ticket;
  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  p->etime = ticks;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.

int getpinfo(struct pstat *ps)
{
  // acquire(&ptable.lock);
  struct proc *p;
  int i = 0;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    ps->pid[i] = p->pid;
    ps->inuse[i] = p->state != UNUSED;
    ps->ticket[i] = p->ticket;
    ps->tick[i] = p->tick;
    i++;
    release(&p->lock);
  }
  // release(&ptable.lock);
  return 0;
}

int getRunnableProcTickets(void)
{
  struct proc *p;
  int total = 0;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == RUNNABLE)
    {
      total += p->ticket;
    }
  }
  return total;
}

int settickets(int number)
{
  struct proc *pr = myproc();
  int pid = pr->pid;
  // acquire(&ptable.lock); // Find and assign the tickets to the process
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->ticket = number; // assigining alloted ticket for a process
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return 0;
}
#define SEG_TSS 5
#define STS_T32A 0x9
#define SEG_KDATA 2
#define KSTACKSIZE 4096
#define V2P(a) (((uint)(a)) - KERNBASE)
#define SEG16(type, base, lim, dpl) \
  (struct segdesc) { (lim) & 0xffff, (uint)(base)&0xffff, ((uint)(base) >> 16) & 0xff, type, 1, dpl, 1, (uint)(lim) >> 16, 0, 0, 1, 0, (uint)(base) >> 24 }
pde_t *kpgdir;
#ifdef LBS
void switchkvm(void)
{
  lcr3(V2P(kpgdir)); // switch to the kernel page table
}

// Switch TSS and h/w page table to correspond to process p.
void switchuvm(struct proc *p)
{
  if (p == 0)
    panic("switchuvm: no process");
  if (p->kstack == 0)
    panic("switchuvm: no kstack");
  if (p->pgdir == 0)
    panic("switchuvm: no pgdir");

  pushcli();
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
                                sizeof(mycpu()->ts) - 1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
  mycpu()->ts.ss0 = SEG_KDATA << 3;
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort)0xFFFF;
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir)); // switch to process's address space
  popcli();
}
#endif

void scheduler(void)
{
  // struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    // for fcfs begin

#ifdef FCFS
    struct proc *p;
    struct proc *first_come_proc = NULL;
    p = proc;
    while (p < &proc[NPROC])
    {
      int ok = 1;
      acquire(&p->lock);
      if (p->state == RUNNABLE) // check if the process is RUNNABLE
      {
        if (first_come_proc == NULL)
        {
          first_come_proc = p;
          ok = 0;
        }
        if (first_come_proc->creation_time > p->creation_time)
        {
          release(&first_come_proc->lock);
          first_come_proc = p;
          ok = 0;
        }
      }
      if (ok)
        release(&p->lock);
      p++;
    }
    if (first_come_proc != NULL)
    {
      c->proc = first_come_proc;
      first_come_proc->state = 4;
      swtch(&c->context, &first_come_proc->context);
      c->proc = 0;
      release(&first_come_proc->lock);
    }
#endif
#ifdef PBS
    struct proc *p;
    struct proc *pbs_proc = NULL;
    uint pbs_priority = 101;
    p = proc;
    while (p < &proc[NPROC])
    {
      int ok = 0;
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        int temp_priority = proc_priority(p);
        if (pbs_proc == NULL)
        {
          pbs_proc = p;
          pbs_priority = temp_priority;
          ok = 1;
        }
        else if (pbs_priority > temp_priority)
        {
          release(&pbs_proc->lock);
          pbs_proc = p;
          pbs_priority = temp_priority;
          ok = 1;
        }
        else if (pbs_proc->num_run > p->num_run)
        {
          if (pbs_priority == temp_priority)
          {
            release(&pbs_proc->lock);
            pbs_proc = p;
            pbs_priority = temp_priority;
            ok = 1;
          }
        }
        else if (pbs_proc->creation_time > p->creation_time)
        {
          if (pbs_proc->num_run == p->num_run)
          {
            if (pbs_priority == temp_priority)
            {
              release(&pbs_proc->lock);
              pbs_proc = p;
              pbs_priority = temp_priority;
              ok = 1;
            }
          }
        }
      }
      if (!ok)
        release(&p->lock);
      p++;
    }
    if (pbs_proc == NULL)
      continue; // nothing to release

    pbs_proc->last_sleep = 0;
    pbs_proc->state = RUNNING;
    pbs_proc->num_run += 1;
    pbs_proc->last_run = 0;
    pbs_proc->ticks_last_scheduled = ticks;
    c->proc = pbs_proc;
    swtch(&c->context, &pbs_proc->context);
    c->proc = 0;
    release(&pbs_proc->lock);

#endif
#ifdef RR
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
#endif
#ifdef LBS
    struct proc *p;
    struct cpu *c = mycpu();
    c->proc = 0;
    for (;;)
    {
      sti(); // Enable interrupts on this processor.
      long cur_total = 0;
      long total = getRunnableProcTickets() * 1LL;
      long win_ticket = random_at_most(total);
      for (p = proc; p < &proc[NPROC]; p++)
      {
        acquire(&p->lock); // Loop over process table looking for process to run.
        if (p->state == RUNNABLE)
          cur_total += p->ticket;
        else
          continue;
        if (cur_total > win_ticket) // winner process
        {
          // Switch to chosen process.  It is the process's job to release ptable.lock and then reacquire it before jumping back to us.
          c->proc = p;
          switchuvm(p);
          p->state = RUNNING;
          // p->tick++;
          int tick_start = ticks;
          swtch(&(c->scheduler), &p->context);
          int tick_end = ticks;
          p->tick += (tick_end - tick_start);
          switchkvm();
          // Process is done running for now. It should have changed its p->state before coming back.
          c->proc = 0;
          break;
        }
        else
          continue;
        release(&p->lock);
      }
    }
#endif
    #ifdef MLFQ
    struct proc *chosen = 0;
    struct proc *p;
    // Reset priority for old processes /Aging/
    p = proc;
    while (p < &proc[NPROC])
    {
      if (p->state == RUNNABLE)
      {
        if (ticks >= OLDAGE + p->qitime)
        {
          p->qitime = ticks;
          if (p->in_queue)
          {
            p->in_queue = 0;
            qrm(&mlfq[p->priority], p->pid);
          }
          if (p->priority != 0)
            p->priority--;
        }
      }
      p++;
    }
    p = proc;
    while (p < &proc[NPROC])
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        if (p->in_queue == 0)
        {
          // printf("%d %d %d\n",ticks, p->pid, p->priority);
          qpush(&mlfq[p->priority], p);
          p->in_queue = 1;
        }
      }
      release(&p->lock);
      p++;
    }
    int lvl = 0;
    while (lvl < NMLFQ)
    {
      int ok = 0;
      for (int i = 0; mlfq[lvl].size; i++)
      {
        p = top(&mlfq[lvl]);
        acquire(&p->lock);
        qpop(&mlfq[lvl]);
        p->in_queue = 0;
        if (p->state == RUNNABLE)
        {
          p->qitime = ticks;
          chosen = p;
          ok = 1;
        }
        if (ok)
          break;
        release(&p->lock);
      }
      if (chosen)
        break;
      lvl++;
    }
    if (!chosen)
      continue;
    chosen->state = RUNNING;
    chosen->quanta = 1 << chosen->priority;
    chosen->nrun++;
    c->proc = chosen;
    swtch(&c->context, &chosen->context);
    c->proc = 0;
    chosen->qitime = ticks;
    release(&chosen->lock);
#endif
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  struct proc *p;
  static char *states[] = {
      [UNUSED] "unused",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
#ifdef FCS
    printf("%d %d %s %d %d", p->pid, p->current_queue, state, p->run_time, p->creation_time);
#endif
#ifdef PBS
    printf("%d %d %s %d %d %d\n", p->pid, p->priority, state, p->run_time, p->total_wait_time, p->num_run);
#endif
#ifdef MLFQ
    printf("PID Priority State rtime wtime nrun q0 q1 q2 q3 q4\n");
#endif
#ifdef MLFQ
    int wtime = ticks - p->qitime;
    printf("%d %d %s %d %d %d %d %d %d %d %d", p->pid, p->priority, state, p->rtime, wtime, p->nrun, p->qrtime[0], p->qrtime[1], p->qrtime[2], p->qrtime[3], p->qrtime[4]);
#endif
    printf("\n");
  }
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->rtime;
          *wtime = np->etime - np->ctime - np->rtime;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

uint64 sys_sigalarm(void)
{
  int ticks;
  uint64 handler;
  argint(0, &ticks);
  argaddr(1, &handler);
  if (ticks < 0 || handler < 0)
    return -1;
  myproc()->handler = handler;
  myproc()->ticks = ticks;
  myproc()->is_sigalarm = 0;
  myproc()->now_ticks = 0;
  return 0;
}

void update_time()
{
#ifdef MLFQ
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
#ifdef MLFQ
      p->qrtime[p->priority]++;
      p->quanta--;
#endif
    }
    release(&p->lock);
  }
#endif
#ifndef MLFQ
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
    }
    release(&p->lock);
  }
#endif
}

#ifdef MLFQ
struct proc *top(struct Queue *q)
{
  if (q->head == q->tail)
    return 0;
  return q->procs[q->head];
}

void qpush(struct Queue *q, struct proc *element)
{
  if (q->size == NPROC)
    panic("Proccess limit exceeded");
  // printf("%d %d %d\n", ticks, element->pid,q->tail );

      // printf("%d %d s%d\n",element->)

      q->procs[q->tail] = element;
  q->tail++;
  if (q->tail == NPROC + 1)
    q->tail = 0;
  q->size++;
}

void qpop(struct Queue *q)
{
  if (q->size == 0)
    panic("Empty queue");
  q->head++;
  if (q->head == NPROC + 1)
    q->head = 0;
  q->size--;
}

void qrm(struct Queue *q, int pid)
{
  for (int curr = q->head; curr != q->tail; curr = (curr + 1) % (NPROC + 1))
  {
    if (q->procs[curr]->pid == pid)
    {
      struct proc *temp = q->procs[curr];
      q->procs[curr] = q->procs[(curr + 1) % (NPROC + 1)];
      q->procs[(curr + 1) % (NPROC + 1)] = temp;
    }
  }

  q->tail--;
  q->size--;
  if (q->tail < 0)
    q->tail = NPROC;
}
#endif