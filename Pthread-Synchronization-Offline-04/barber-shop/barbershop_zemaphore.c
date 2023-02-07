#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <wait.h>
#include <pthread.h>
#include <unistd.h>
#include "zemaphore.c"

int chair_count, customer_count;
int waiting = 0;
int customer_present;

zem_t mutex;    // lock for the customer
zem_t barber_z;    // condition variable for the customer to wait for the barber
zem_t customer_z;   // condition variable for the barber to wait for the customer

void *barber_thread(void *arg)
{
    while (1)
    {
        zem_down(&mutex);
        // logic for checking if there is any customer waiting
        while (waiting == 0 && customer_present > 0)
        {
            // barber waits for the customer to come
            zem_up(&mutex);
            zem_down(&customer_z);
            zem_down(&mutex);
        }

        waiting--;
        zem_up(&barber_z);
        printf("Barber serving a customer now!\n");
        sleep(1);
        zem_up(&mutex);

        // logic for being done with cutting
        if (customer_present <= 0 && waiting == 0)
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
    zem_down(&mutex);

    printf("Customer %d here at the shop\n", customer_id);

    // logic for checking if there is any chair available
    if (waiting == chair_count)
    {
        printf("Customer %d is leaving\n", customer_id);
        customer_present--;
        zem_up(&mutex);
    }
    else
    {
        waiting++;
        customer_present--;

        printf("Customer %d is waiting for barber\n", customer_id);

        zem_up(&customer_z);
        zem_up(&mutex);
        zem_down(&barber_z);

        printf("Customer %d got haircut\n", customer_id);
    }
    return 0;
}

int main(int argc, char *argv[])
{
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
    customer_present = customer_count;

    zem_init(&mutex, 1);
    zem_init(&barber_z, 0);
    zem_init(&customer_z, 0);

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