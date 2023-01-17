#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if(argc != 2){
        printf("Usage: testticket <number of tickets>\n");
        exit(1);
    }
    printf("Setting ticket\n");
    int number = atoi(argv[1]);
    if(settickets(number)==-1){
        printf("Error setting ticket\n");
        exit(1);
    }
    int rc = fork();
    if(rc<0){
        printf("Error forking\n");
        exit(1);
    }
    else if(rc==0){
        // child process
        while(1){
            // running
        }
    }
    // while loop to make sure the process is not terminated
    exit(0);
}