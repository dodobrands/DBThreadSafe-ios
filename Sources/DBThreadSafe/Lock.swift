import Foundation
#if canImport(Synchronization)
import Synchronization
#endif

class LockStorage<T>: @unchecked Sendable {
    var lockType: DBThreadSafeLock {
        fatalError("Subclasses must override lockType")
    }

    func readValue() -> T {
        fatalError("Subclasses must override readValue()")
    }

    func withReadValue(_ closure: (_ value: T) throws -> Void) rethrows {
        fatalError("Subclasses must override withReadValue(_:)")
    }

    func withReadValue<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        fatalError("Subclasses must override withReadValue(_:)")
    }

    func overwrite(with newValue: T) {
        fatalError("Subclasses must override overwrite(with:)")
    }

    func withWriteValue(_ closure: (_ value: inout T) throws -> Void) rethrows {
        fatalError("Subclasses must override withWriteValue(_:)")
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

    override func readValue() -> T {
        lock.readLock()
        defer { lock.unlock() }
        return value
    }

    override func withReadValue(_ closure: (_ value: T) throws -> Void) rethrows {
        lock.readLock()
        defer { lock.unlock() }
        try closure(value)
    }

    override func withReadValue<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        lock.readLock()
        defer { lock.unlock() }
        return try closure(value)
    }

    override func overwrite(with newValue: T) {
        lock.writeLock()
        defer { lock.unlock() }
        value = newValue
    }

    override func withWriteValue(_ closure: (_ value: inout T) throws -> Void) rethrows {
        lock.writeLock()
        defer { lock.unlock() }
        try closure(&value)
    }
}

#if canImport(Synchronization)
@available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
final class MutexStorage<T>: LockStorage<T>, @unchecked Sendable {
    nonisolated(unsafe) private var value: T
    private let mutex: Mutex<Void>
    private let readDepthToken = NSObject()

    override var lockType: DBThreadSafeLock {
        .mutex
    }

    init(_ value: T) {
        self.value = value
        self.mutex = Mutex(())
    }

    override func readValue() -> T {
        withNestedReadSupport { value in
            value
        }
    }

    override func withReadValue(_ closure: (_ value: T) throws -> Void) rethrows {
        try withNestedReadSupport(closure)
    }

    override func withReadValue<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        try withNestedReadSupport(closure)
    }

    override func overwrite(with newValue: T) {
        mutex.withLock { _ in
            value = newValue
        }
    }

    override func withWriteValue(_ closure: (_ value: inout T) throws -> Void) rethrows {
        try mutex.withLock { _ in
            try closure(&value)
        }
    }

    private var readDepthKey: String {
        "dbthreadsafe.mutex.readDepth.\(UInt(bitPattern: Unmanaged.passUnretained(readDepthToken).toOpaque()))"
    }

    private var currentReadDepth: Int {
        Thread.current.threadDictionary[readDepthKey] as? Int ?? 0
    }

    private func incrementReadDepth() {
        Thread.current.threadDictionary[readDepthKey] = currentReadDepth + 1
    }

    private func decrementReadDepth() {
        let newValue = currentReadDepth - 1

        if newValue > 0 {
            Thread.current.threadDictionary[readDepthKey] = newValue
        } else {
            Thread.current.threadDictionary.removeObject(forKey: readDepthKey)
        }
    }

    private func withNestedReadSupport<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        if currentReadDepth > 0 {
            return try closure(value)
        }

        return try mutex.withLock { _ in
            incrementReadDepth()
            defer { decrementReadDepth() }

            return try closure(value)
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
