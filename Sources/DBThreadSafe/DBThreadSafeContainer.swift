import Foundation

public final class DBThreadSafeContainer<T>: Sendable {
    nonisolated(unsafe) private var value: T
    private let lock = Lock()
    
    public init(_ value: T) {
        self.value = value
    }
    
    /// Reads the value stored
    /// - Returns: The value stored in the container.
    public func read() -> T {
        lock.readLock()
        defer { lock.unlock() }
        return value
    }
    
    public func read(_ closure: (_ value: T) throws -> Void) rethrows {
        lock.readLock()
        defer { lock.unlock() }
        try closure(value)
    }
    
    public func read<U>(_ closure: (_ value: T) throws -> U) rethrows -> U {
        lock.readLock()
        defer { lock.unlock() }
        return try closure(value)
    }
    
    /// Replaces current value with a new one
    /// - Parameter newValue: The new value to be stored in the container.
    public func write(_ newValue: T) {
        lock.writeLock()
        defer { lock.unlock() }
        value = newValue
    }
        
    /// Returns current value in a closure with possibility to make multiple modifications of any kind inside a single lock.
    public func write(_ closure: (_ value: inout T) throws -> Void) rethrows {
        lock.writeLock()
        defer { lock.unlock() }
        try closure(&value)
    }
}
