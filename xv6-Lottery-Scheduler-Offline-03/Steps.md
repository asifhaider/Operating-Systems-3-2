# Steps to reproduce and run
Find the problem statement (here:)[https://github.com/Tahmid04/xv6-scheduling-july-2022]

### Adding System Call

1. ```syscall.h```
- add the ```setticket``` and ```getpinfo``` system call numbers

2. ```syscall.c```
- add the ```setticket``` and ```getpinfo``` call in the syscall list
- provide extern signatures

3. ```user.h```
- add the ```setticket``` and ```getpinfo``` system call prototype
- add ```pstat``` struct

4. ```usys.pl```
- add the ```setticket``` and ```getpinfo``` entry

### Testing System Call

1. ```user``` directory
- add ```testticket.c``` and ```testprocinfo.c```inside

2. ```Makefile```
- add ```testticket``` and ```testprocinfo``` to the UPROGS
- set ```CPUS``` = 1
- add ```random.o``` object to the Makefile (OBJS)

### Handling Kernel Implementation

0. ```kernel``` directory
- add ```pstat.h``` inside with given definition
- add ```random.c``` file inside the kernel

1. ```proc.h```
- add necessary fields to the process structure (initial and current ticket counts, ticks used)
- careful about the locks

2. ```sysproc.c```
- add routine implementations that handle ```setticket``` and ```getpinfo``` system calls
- call methods from ```proc.c``` so that locks can be handled
- sets/passes the input value to kernel

3. ```proc.c```
- set initial ticket, original ticket and ticks used value in the ```scheduler()``` (or inside ```allocproc()```?, and exiting ticket value in ```freeproc()```?)
- start adding new functions that are called from and returned to the callers in ```sysproc.c```
- copy parent fields to child fields in the ```fork()``` method
- replace the round robin algorithm and implement the lottery logic inside ```scheduler``` with ```RUNNABLE``` states
- create ```settickets()``` and ```getpinfo()``` methods to set tickets and get process info while holding the lock properly

4. ```defs.h```
- add ```pstat``` struct to the struct list
- add function prototype here so that the system recognizes the new functions inside ```proc.c```

