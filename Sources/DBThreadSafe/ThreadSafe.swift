import Foundation

@propertyWrapper
public final class ThreadSafe<T> {
    private let container: DBThreadSafeContainer<T>

    public init(wrappedValue: T) {
        self.container = DBThreadSafeContainer(wrappedValue)
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

    public var projectedValue: DBThreadSafeContainer<T> {
        container
    }
}
