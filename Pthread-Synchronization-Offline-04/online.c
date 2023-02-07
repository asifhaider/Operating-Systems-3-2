#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <wait.h>
#include <pthread.h>
#include "zemaphore.c"

#define NUM_THREADS 26
#define NUM_ITER 10

// N semaphores for N threads
zem_t zemaphores[NUM_THREADS];

void *justprint(void *data)
{
  int thread_id = *((int *)data);

  // putting the zemaphore up-downs outside the loop prints all 0s all 1s all 2s
  while(1)
  {
    // waiting for the previous thread to print
    zem_down(&zemaphores[thread_id]);
    printf("%c\n", 25 - thread_id + 'a');
    // allowing the next thread to print
    zem_up(&zemaphores[(thread_id + 1) % NUM_THREADS]);
  }

  return 0;
}

int main(int argc, char *argv[])
{

  pthread_t mythreads[NUM_THREADS];
  int mythread_id[NUM_THREADS];

  // initializing the semaphores and creating the threads
  for (int i = 0; i < NUM_THREADS; i++)
  {
    if (i == 0)
      // allowing the first thread to print first (locking first and ordering)
      zem_init(&zemaphores[i], 1);
    else
      // waiting for the previous thread to print (ordering)
      zem_init(&zemaphores[i], 0);

    mythread_id[i] = i;
    pthread_create(&mythreads[i], NULL, justprint, (void *)&mythread_id[i]);
  }

  // joining the threads
  for (int i = 0; i < NUM_THREADS; i++)
  {
    pthread_join(mythreads[i], NULL);
  }

  return 0;
}
