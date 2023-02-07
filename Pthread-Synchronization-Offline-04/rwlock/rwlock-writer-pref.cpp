#include "rwlock.h"

void InitalizeReadWriteLock(struct read_write_lock *rw)
{
  //	Write the code for initializing your read-write lock.
  pthread_mutex_init(&rw->lock, NULL);
  pthread_cond_init(&rw->read, NULL);
  pthread_cond_init(&rw->write, NULL);
}

void ReaderLock(struct read_write_lock *rw)
{
  //	Write the code for aquiring read-write lock by the reader.
  pthread_mutex_lock(&rw->lock);
  while (rw->writers > 0 || rw->waiting_writers > 0)
  {
    rw->waiting_readers++;
    pthread_cond_wait(&rw->read, &rw->lock);
    rw->waiting_readers--;
  }
  rw->readers++;
  pthread_mutex_unlock(&rw->lock);
}

void ReaderUnlock(struct read_write_lock *rw)
{
  //	Write the code for releasing read-write lock by the reader.
  pthread_mutex_lock(&rw->lock);
  rw->readers--;
  if (rw->readers == 0 && rw->waiting_writers > 0)
    pthread_cond_signal(&rw->write);
  else if (rw->waiting_readers > 0)
    pthread_cond_broadcast(&rw->read);
  pthread_mutex_unlock(&rw->lock);
}

void WriterLock(struct read_write_lock *rw)
{
  //	Write the code for aquiring read-write lock by the writer.
  pthread_mutex_lock(&rw->lock);
  while (rw->readers > 0 || rw->writers > 0)
  {
    rw->waiting_writers++;
    pthread_cond_wait(&rw->write, &rw->lock);
    rw->waiting_writers--;
  }
  rw->writers++;
  pthread_mutex_unlock(&rw->lock);
}

void WriterUnlock(struct read_write_lock *rw)
{
  //	Write the code for releasing read-write lock by the writer.
  pthread_mutex_lock(&rw->lock);
  rw->writers--;
  // prioritize writers
  if (rw->waiting_writers > 0)
  {
    pthread_cond_signal(&rw->write);
  }
  else if (rw->waiting_readers > 0)
  {
    pthread_cond_broadcast(&rw->read);
  }
  pthread_mutex_unlock(&rw->lock);
}
