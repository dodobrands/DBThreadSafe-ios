import Foundation

final class Lock: Sendable {
    nonisolated(unsafe) private let lock = UnsafeMutablePointer<pthread_rwlock_t>.allocate(capacity: 1)
    
    init() {
        precondition(pthread_rwlock_init(lock, nil) == 0, "Failed to initialize the lock")
    }
    
    func readLock() {
        pthread_rwlock_rdlock(lock)
    }
    
    func writeLock() {
        pthread_rwlock_wrlock(lock)
    }
    
    func unlock() {
        pthread_rwlock_unlock(lock)
    }
    
    deinit {
        precondition(pthread_rwlock_destroy(lock) == 0, "Failed to destroy the lock")
        
        lock.deallocate()
    }
}
