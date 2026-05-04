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

    /// Executes a closure while holding an exclusive lock on the stored weak reference.
    public func withLock<U>(_ closure: (_ value: inout T?) throws -> U) rethrows -> U {
        try storage.withLock(closure)
    }
}

protocol WeakLockStorage<Value>: AnyObject, Sendable {
    associatedtype Value

    var lockType: DBThreadSafeLock { get }
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

    func withLock<U>(_ closure: (_ value: inout T?) throws -> U) rethrows -> U {
        try mutex.withLock { _ in
            var value = object as? T
            defer { object = value as AnyObject? }
            return try closure(&value)
        }
    }
}
#endif
