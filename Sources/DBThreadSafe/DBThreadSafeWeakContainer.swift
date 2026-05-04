import Foundation
#if canImport(Synchronization)
import Synchronization
#endif

/// Thread-safe Sendable container for a weak reference.
///
/// Use when `weak var` prevents `Sendable` conformance of the enclosing type.
/// The stored object is held weakly and becomes `nil` when deallocated.
///
/// Generic parameter `T` is intentionally unconstrained (no `T: AnyObject`),
/// because class-bound protocol existentials don't fit that generic constraint
/// well in call sites like `DBThreadSafeWeakContainer<any MyDelegate>()`.
public final class DBThreadSafeWeakContainer<T>: Sendable {
    private let storage: any WeakLockStorage<T>

    /// The concrete lock backend currently used by the container.
    public var lockType: DBThreadSafeLock {
        storage.lockType
    }

    public init(_ value: T? = nil) {
        self.storage = Self.makeDefaultStorage(value)
    }

    public init(_ value: T? = nil, lock: DBThreadSafeLock) {
        self.storage = Self.makeStorage(value, lock: lock)
    }

    private static func makeDefaultStorage(_ value: T?) -> any WeakLockStorage<T> {
        #if canImport(Synchronization)
        if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
            return MutexWeakStorage(value)
        }
        #endif

        return PThreadRWLockWeakStorage(value)
    }

    private static func makeStorage(_ value: T?, lock: DBThreadSafeLock) -> any WeakLockStorage<T> {
        switch lock {
        case .pthreadRWLock:
            return PThreadRWLockWeakStorage(value)
#if canImport(Synchronization)
        case .mutex:
            if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
                return MutexWeakStorage(value)
            } else {
                preconditionFailure("DBThreadSafeLock.mutex requires a supported OS version")
            }
#endif
        }
    }

    /// Reads the value stored.
    /// - Returns: The weakly stored value, or `nil` if it was deallocated.
    public func read() -> T? {
        storage.read()
    }

    public func read(_ closure: (_ value: T?) throws -> Void) rethrows {
        try storage.read(closure)
    }

    public func read<U>(_ closure: (_ value: T?) throws -> U) rethrows -> U {
        try storage.read(closure)
    }

    /// Executes a closure while holding an exclusive lock on the stored weak reference.
    public func withLock<U>(_ closure: (_ value: inout T?) throws -> U) rethrows -> U {
        try storage.withLock(closure)
    }

    /// Replaces current weakly stored value with a new one.
    /// - Parameter newValue: The new value to be stored in the container.
    public func write(_ newValue: T?) {
        storage.write(newValue)
    }

    /// Returns current weakly stored value in a closure with possibility to replace it inside a single lock.
    public func write(_ closure: (_ value: inout T?) throws -> Void) rethrows {
        try storage.write(closure)
    }

    public var value: T? {
        get {
            read()
        }
        set {
            write(newValue)
        }
    }
}

protocol WeakLockStorage<Value>: AnyObject, Sendable {
    associatedtype Value

    var lockType: DBThreadSafeLock { get }

    func read() -> Value?
    func read<U>(_ closure: (_ value: Value?) throws -> U) rethrows -> U
    func write(_ newValue: Value?)
    func write(_ closure: (_ value: inout Value?) throws -> Void) rethrows
    func withLock<U>(_ closure: (_ value: inout Value?) throws -> U) rethrows -> U
}

final class PThreadRWLockWeakStorage<T>: WeakLockStorage, @unchecked Sendable {
    nonisolated(unsafe) private weak var object: AnyObject?
    private let lock = Lock()

    var lockType: DBThreadSafeLock {
        .pthreadRWLock
    }

    init(_ value: T?) {
        self.object = value as AnyObject?
    }

    func read() -> T? {
        lock.readLock()
        defer { lock.unlock() }
        return object as? T
    }

    func read<U>(_ closure: (_ value: T?) throws -> U) rethrows -> U {
        lock.readLock()
        defer { lock.unlock() }
        return try closure(object as? T)
    }

    func write(_ newValue: T?) {
        lock.writeLock()
        defer { lock.unlock() }
        object = newValue as AnyObject?
    }

    func write(_ closure: (_ value: inout T?) throws -> Void) rethrows {
        try withLock(closure)
    }

    func withLock<U>(_ closure: (_ value: inout T?) throws -> U) rethrows -> U {
        lock.writeLock()
        var value = object as? T
        defer {
            object = value as AnyObject?
            lock.unlock()
        }
        return try closure(&value)
    }
}

#if canImport(Synchronization)
@available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
final class MutexWeakStorage<T>: WeakLockStorage, @unchecked Sendable {
    nonisolated(unsafe) private weak var object: AnyObject?
    private let mutex: Mutex<Void>

    var lockType: DBThreadSafeLock {
        .mutex
    }

    init(_ value: T?) {
        self.object = value as AnyObject?
        self.mutex = Mutex(())
    }

    func read() -> T? {
        mutex.withLock { _ in
            object as? T
        }
    }

    func read<U>(_ closure: (_ value: T?) throws -> U) rethrows -> U {
        try mutex.withLock { _ in
            try closure(object as? T)
        }
    }

    func write(_ newValue: T?) {
        mutex.withLock { _ in
            object = newValue as AnyObject?
        }
    }

    func write(_ closure: (_ value: inout T?) throws -> Void) rethrows {
        try withLock(closure)
    }

    func withLock<U>(_ closure: (_ value: inout T?) throws -> U) rethrows -> U {
        try mutex.withLock { _ in
            var value = object as? T
            defer { object = value as AnyObject? }
            return try closure(&value)
        }
    }
}
#endif
