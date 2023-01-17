#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/pstat.h"
#include "user/user.h"

int main (int argc, char *argv[])
{
    printf("Printing process info (gorib er ps)\n");
    printf("PID | In Use | Original Tickets | Current Tickets | Time Slices\n");
    struct pstat pst;
    getpinfo(&pst);    
    for (int i = 0; i < NPROC; i++) {
        if (pst.inuse[i]) {
            printf("%d\t%d\t\t%d\t\t%d\t\t%d\n", pst.pid[i], pst.inuse[i], pst.tickets_original[i], pst.tickets_current[i], pst.time_slices[i]);
        }
    }    
    exit(0);
}