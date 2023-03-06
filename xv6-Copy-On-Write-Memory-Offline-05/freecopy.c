#include "kernel/types.h"
#include "kernel/memlayout.h"
#include "user/user.h"

// three processes all write COW memory.
// this causes more than half of physical memory
// to be allocated, so it also checks whether
// copied pages are freed.
void test()
{
    uint64 phys_size = PHYSTOP - KERNBASE;
    int sz = phys_size / 4;
    int pid1, pid2;

    printf("three: ");

    char *p = sbrk(sz);
    if (p == (char *)0xffffffffffffffffL)
    {
        printf("sbrk(%d) failed\n", sz);
        exit(-1);
    }

    pid1 = fork();
    if (pid1 < 0)
    {
        printf("fork failed\n");
        exit(-1);
    }
    if (pid1 == 0)
    {
        pid2 = fork();
        if (pid2 < 0)
        {
            printf("fork failed");
            exit(-1);
        }
        if (pid2 == 0)
        {
            for (char *q = p; q < p + (sz / 5) * 4; q += 4096)
            {
                *(int *)q = getpid();
            }
            for (char *q = p; q < p + (sz / 5) * 4; q += 4096)
            {
                if (*(int *)q != getpid())
                {
                    printf("wrong content\n");
                    exit(-1);
                }
            }
            exit(-1);
        }
        for (char *q = p; q < p + (sz / 2); q += 4096)
        {
            *(int *)q = 9999;
        }
        exit(0);
    }

    for (char *q = p; q < p + sz; q += 4096)
    {
        *(int *)q = getpid();
    }

    wait(0);

    sleep(1);

    for (char *q = p; q < p + sz; q += 4096)
    {
        if (*(int *)q != getpid())
        {
            printf("wrong content\n");
            exit(-1);
        }
    }

    if (sbrk(-sz) == (char *)0xffffffffffffffffL)
    {
        printf("sbrk(-%d) failed\n", sz);
        exit(-1);
    }

    printf("ok\n");
}

int main(int argc, char *argv[])
{
    test();
    test();
    test();
    printf("TESTS PASSED\n");

    exit(0);
}