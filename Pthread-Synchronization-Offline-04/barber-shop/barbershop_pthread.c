#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <wait.h>
#include <pthread.h>
#include <unistd.h>

int chair_count, customer_count;    // waiting room chair and customer count in the shop
int waiting = 0;    // number of customers waiting in the waiting room
int customer_coming;   // number of customers to come in the shop

pthread_mutex_t customer_lock;  // lock for the customer
pthread_cond_t customer_ready;  // condition variable for the customer to wait for the barber
pthread_cond_t barber_ready;    // condition variable for the barber to wait for the customer

void *barber_thread(void *arg)
{
    while (1)
    {
        // critical section
        pthread_mutex_lock(&customer_lock);
        // logic for checking if there is any customer waiting
        while (waiting == 0 && customer_coming > 0)
        {
            // waits for the customers to come
            pthread_cond_wait(&customer_ready, &customer_lock);
        }

        waiting--;
        // signal the customer that the barber is ready
        pthread_cond_signal(&barber_ready);
        // do the hair cut
        printf("Barber serving a customer now!\n");
        // release the lock
        pthread_mutex_unlock(&customer_lock);

        sleep(1);

        // logic for being done with cutting
        if (customer_coming <= 0 && waiting == 0)
        {
            printf("No more customer to come\n");
            return 0;
        }
    }
    return 0;
}

void *customer_thread(void *arg)
{
    int customer_id = *((int *)arg);
    // critical section
    pthread_mutex_lock(&customer_lock);
    printf("Customer %d here at the shop\n", customer_id);

    // logic for checking if there is any chair available
    if (waiting == chair_count) // all chair occupied
    {
        printf("Customer %d is leaving\n", customer_id);
        customer_coming--;  // not coming back to the shop
        pthread_mutex_unlock(&customer_lock);
        // release the lock
    }
    else    // there is a chair available
    {
        waiting++;  
        customer_coming--;

        printf("Customer %d is waiting for barber\n", customer_id);
        // signal the barber that the customer is ready
        pthread_cond_signal(&customer_ready);
        // wait for the barber to be ready
        pthread_cond_wait(&barber_ready, &customer_lock);

        // got the haircut
        printf("Customer %d got haircut\n", customer_id);
        pthread_mutex_unlock(&customer_lock);
        // release the lock
    }
    return 0;
}

int main(int argc, char *argv[])
{
    // check for the command line arguments
    if (argc != 3)
    {
        printf("./barbershop_pthread #chairs #customers\n");
        exit(1);
    }
    else
    {
        chair_count = atoi(argv[1]);
        customer_count = atoi(argv[2]);
    }

    pthread_t barber;
    pthread_t customers[customer_count];
    customer_coming = customer_count;

    pthread_mutex_init(&customer_lock, NULL);
    pthread_cond_init(&barber_ready, NULL);
    pthread_cond_init(&customer_ready, NULL);

    int customer_serial[customer_count];
    for (int i = 0; i < customer_count; i++)
    {
        customer_serial[i] = i;
    }

    pthread_create(&barber, NULL, barber_thread, NULL);

    for (int i = 0; i < customer_count; i++)
    {
        pthread_create(&customers[i], NULL, customer_thread, (void *)&customer_serial[i]);
    }

    // joining all customer threads
    for (int i = 0; i < customer_count; i++)
    {
        pthread_join(customers[i], NULL);
        printf("Customer %d joined\n", customer_serial[i]);
    }

    // barber joins
    pthread_join(barber, NULL);
    printf("Barber done and sleeping\n");

    return 0;
}