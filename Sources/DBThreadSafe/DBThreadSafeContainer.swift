import Foundation

public final class DBThreadSafeContainer<T>: Sendable {
    private let storage: LockStorage<T>

    /// The concrete lock backend currently used by the container.
    public var lockType: DBThreadSafeLock {
        storage.lockType
    }

    /// Creates a container that prefers `Synchronization.Mutex` when the current OS supports it
    /// and otherwise falls back to the `pthread_rwlock_t` backend.
    public init(_ value: T) {
#if canImport(Synchronization)
        if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
            self.storage = MutexStorage(value)
        } else {
            self.storage = PThreadRWLockStorage(value)
        }
#else
        self.storage = PThreadRWLockStorage(value)
#endif
    }

    /// Creates a container using the explicitly requested lock backend.
    public init(_ value: T, lock: DBThreadSafeLock) {
        switch lock {
        case .pthreadRWLock:
            self.storage = PThreadRWLockStorage(value)
#if canImport(Synchronization)
        case .mutex:
            if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
                self.storage = MutexStorage(value)
            } else {
                preconditionFailure("DBThreadSafeLock.mutex requires a supported OS version")
            }
#endif
        }
    }

    /// Reads the value stored
    /// - Returns: The value stored in the container.
    public func read() -> T {
        storage.readValue()
    }

    public func read(_ closure: (_ value: T) throws -> Void) rethrows {
        try storage.withReadValue(closure)
    }

    public func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        try storage.withReadValue(closure)
    }

    /// Replaces current value with a new one
    /// - Parameter newValue: The new value to be stored in the container.
    public func write(_ newValue: T) {
        storage.overwrite(with: newValue)
    }

    /// Returns current value in a closure with possibility to make multiple modifications of any kind inside a single lock.
    public func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        try storage.withWriteValue(closure)
    }
}
