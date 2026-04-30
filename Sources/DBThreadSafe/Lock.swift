import Foundation
#if canImport(Synchronization)
import Synchronization
#endif

class LockStorage<T>: @unchecked Sendable {
    var lockType: DBThreadSafeLock {
        fatalError("Subclasses must override lockType")
    }

    func read() -> T {
        fatalError("Subclasses must override read()")
    }

    func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        fatalError("Subclasses must override read(_:)")
    }

    func write(_ newValue: T) {
        fatalError("Subclasses must override write(_:)")
    }

    func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        fatalError("Subclasses must override write(_:)")
    }

    func withLock<U>(_ closure: (_ value: inout T) throws -> U) rethrows -> U {
        fatalError("Subclasses must override withLock(_:)")
    }
}

final class PThreadRWLockStorage<T>: LockStorage<T>, @unchecked Sendable {
    nonisolated(unsafe) private var value: T
    private let lock = Lock()

    override var lockType: DBThreadSafeLock {
        .pthreadRWLock
    }

    init(_ value: T) {
        self.value = value
    }

    override func read() -> T {
        lock.readLock()
        defer { lock.unlock() }
        return value
    }

    override func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        lock.readLock()
        defer { lock.unlock() }
        return try closure(value)
    }

    override func write(_ newValue: T) {
        lock.writeLock()
        defer { lock.unlock() }
        value = newValue
    }

    override func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        lock.writeLock()
        defer { lock.unlock() }
        try closure(&value)
    }

    override func withLock<U>(_ closure: (_ value: inout T) throws -> U) rethrows -> U {
        lock.writeLock()
        defer { lock.unlock() }
        return try closure(&value)
    }
}

#if canImport(Synchronization)
@available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
final class MutexStorage<T>: LockStorage<T>, @unchecked Sendable {
    nonisolated(unsafe) private var value: T
    private let mutex: Mutex<Void>

    override var lockType: DBThreadSafeLock {
        .mutex
    }

    init(_ value: T) {
        self.value = value
        self.mutex = Mutex(())
    }

    override func read() -> T {
        withLock { value in
            value
        }
    }

    override func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        try withLock { value in
            try closure(value)
        }
    }

    override func write(_ newValue: T) {
        withLock { value in
            value = newValue
        }
    }

    override func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        try withLock(closure)
    }

    override func withLock<U>(_ closure: (_ value: inout T) throws -> U) rethrows -> U {
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
