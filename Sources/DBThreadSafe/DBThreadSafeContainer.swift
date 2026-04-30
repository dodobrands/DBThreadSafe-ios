import Foundation

public final class DBThreadSafeContainer<T>: Sendable {
    private let storage: any LockStorage<T>

    /// The concrete lock backend currently used by the container.
    public var lockType: DBThreadSafeLock {
        storage.lockType
    }

    public init(_ value: T) {
        self.storage = Self.makeDefaultStorage(value)
    }

    public init(_ value: T, lock: DBThreadSafeLock) {
        self.storage = Self.makeStorage(value, lock: lock)
    }

    private static func makeDefaultStorage(_ value: T) -> any LockStorage<T> {
        #if canImport(Synchronization)
        if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
            return MutexStorage(value)
        }
        #endif

        return PThreadRWLockStorage(value)
    }

    private static func makeStorage(_ value: T, lock: DBThreadSafeLock) -> any LockStorage<T> {
        switch lock {
        case .pthreadRWLock:
            return PThreadRWLockStorage(value)
#if canImport(Synchronization)
        case .mutex:
            if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
                return MutexStorage(value)
            } else {
                preconditionFailure("DBThreadSafeLock.mutex requires a supported OS version")
            }
#endif
        }
    }

    /// Reads the value stored
    /// - Returns: The value stored in the container.
    public func read() -> T {
        storage.read()
    }

    public func read(_ closure: (_ value: T) throws -> Void) rethrows {
        try storage.read(closure)
    }

    public func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        try storage.read(closure)
    }

    /// Executes a closure while holding an exclusive lock on the stored value.
    public func withLock<U>(_ closure: (_ value: inout T) throws -> U) rethrows -> U {
        try storage.withLock(closure)
    }

    /// Replaces current value with a new one
    /// - Parameter newValue: The new value to be stored in the container.
    public func write(_ newValue: T) {
        storage.write(newValue)
    }

    /// Returns current value in a closure with possibility to make multiple modifications of any kind inside a single lock.
    public func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        try storage.write(closure)
    }
}
