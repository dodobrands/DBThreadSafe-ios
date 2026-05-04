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

    public var value: T? {
        get {
            storage.read()
        }
        set {
            storage.write(newValue)
        }
    }
}

protocol WeakLockStorage<Value>: AnyObject, Sendable {
    associatedtype Value

    var lockType: DBThreadSafeLock { get }

    func read() -> Value?
    func write(_ newValue: Value?)
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

    func write(_ newValue: T?) {
        lock.writeLock()
        defer { lock.unlock() }
        object = newValue as AnyObject?
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

    func write(_ newValue: T?) {
        mutex.withLock { _ in
            object = newValue as AnyObject?
        }
    }
}
#endif
