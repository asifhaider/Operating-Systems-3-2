#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <wait.h>
#include "zemaphore.h"

// initializing a semaphore with a value and initializing a lock and condition variable
void zem_init(zem_t *s, int value) {
    s->value = value;
    pthread_mutex_init(&s->lock, NULL);
    pthread_cond_init(&s->condition, NULL);
}

// decrementing a semaphore
void zem_down(zem_t *s) {
    pthread_mutex_lock(&s->lock);
    while (s->value <= 0) {
        pthread_cond_wait(&s->condition, &s->lock);
    }
    // s->value is now guaranteed to be > 0, must be placed later than the while loop
    s->value--;
    pthread_mutex_unlock(&s->lock);
}

// incrementing a semaphore
void zem_up(zem_t *s) {
    pthread_mutex_lock(&s->lock);
    s->value++;
    pthread_cond_signal(&s->condition); // signal one thread waiting on the condition variable, not broadcast
    pthread_mutex_unlock(&s->lock);
}
