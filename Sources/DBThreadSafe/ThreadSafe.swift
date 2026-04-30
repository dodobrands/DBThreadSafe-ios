import Foundation

@propertyWrapper
public final class ThreadSafe<T> {
    private let container: DBThreadSafeContainer<T>

    /// Creates a thread-safe wrapper that prefers `Synchronization.Mutex` when available and
    /// otherwise falls back to the `pthread_rwlock_t` backend.
    public init(wrappedValue: T) {
        self.container = DBThreadSafeContainer(wrappedValue)
    }

    /// Creates a thread-safe wrapper using the explicitly requested lock backend.
    public init(wrappedValue: T, lock: DBThreadSafeLock) {
        self.container = DBThreadSafeContainer(wrappedValue, lock: lock)
    }

    public var wrappedValue: T {
        get {
            container.read()
        }
        @available(
            *,
             unavailable,
             message: "Use $property.write { } to modify the value"
        )
        set {
            container.write(newValue)
        }
    }

    /// Exposes the underlying container, including `read`, `write`, and `lockType`.
    public var projectedValue: DBThreadSafeContainer<T> {
        container
    }
}
