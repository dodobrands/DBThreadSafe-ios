import Foundation
#if canImport(Synchronization)
import Synchronization
#endif

protocol LockStorage<Value>: AnyObject, Sendable {
    associatedtype Value

    var lockType: DBThreadSafeLock {
        get
    }

    func read() -> Value
    func read<U>(_ closure: (_ value: Value) throws -> U) rethrows -> U
    func write(_ newValue: Value)
    func write(_ closure: (_ value: inout Value) throws -> Void) rethrows
    func withLock<U>(_ closure: (_ value: inout Value) throws -> U) rethrows -> U
}

final class PThreadRWLockStorage<T>: LockStorage, @unchecked Sendable {
    nonisolated(unsafe) private var value: T
    private let lock = Lock()

    var lockType: DBThreadSafeLock {
        .pthreadRWLock
    }

    init(_ value: T) {
        self.value = value
    }

    func read() -> T {
        lock.readLock()
        defer { lock.unlock() }
        return value
    }

    func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        lock.readLock()
        defer { lock.unlock() }
        return try closure(value)
    }

    func write(_ newValue: T) {
        lock.writeLock()
        defer { lock.unlock() }
        value = newValue
    }

    func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        lock.writeLock()
        defer { lock.unlock() }
        try closure(&value)
    }

    func withLock<U>(_ closure: (_ value: inout T) throws -> U) rethrows -> U {
        lock.writeLock()
        defer { lock.unlock() }
        return try closure(&value)
    }
}

#if canImport(Synchronization)
@available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
final class MutexStorage<T>: LockStorage, @unchecked Sendable {
    nonisolated(unsafe) private var value: T
    private let mutex: Mutex<Void>

    var lockType: DBThreadSafeLock {
        .mutex
    }

    init(_ value: T) {
        self.value = value
        self.mutex = Mutex(())
    }

    func read() -> T {
        withLock { value in
            value
        }
    }

    func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        try withLock { value in
            try closure(value)
        }
    }

    func write(_ newValue: T) {
        withLock { value in
            value = newValue
        }
    }

    func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        try withLock(closure)
    }

    func withLock<U>(_ closure: (_ value: inout T) throws -> U) rethrows -> U {
        try mutex.withLock { _ in
            try closure(&value)
        }
    }
}
#endif

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
