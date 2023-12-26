import Foundation

public class DBThreadSafeContainer<T> {
    private var value: T
    private var lock = pthread_rwlock_t()
    
    public init(_ value: T) {
        self.value = value
        pthread_rwlock_init(&lock, nil)
    }
    
    /// Reads the value stored
    /// - Returns: The value stored in the container.
    public func read() -> T {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return value
    }
    
    public func read(_ closure: (_ value: T) throws -> Void) rethrows {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        try closure(value)
    }
    
    public func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return try closure(value)
    }
    
    /// Replaces current value with a new one
    /// - Parameter newValue: The new value to be stored in the container.
    public func write(_ newValue: T) {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        value = newValue
    }
        
    /// Returns current value in a closure with possibility to make multiple modifications of any kind inside a single lock.
    public func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        try closure(&value)
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
}
