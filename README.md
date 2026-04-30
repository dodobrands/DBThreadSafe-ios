# DBThreadSafeContainer

> **_NOTE:_**  Prefer using Apple's [Mutex](https://developer.apple.com/documentation/synchronization/mutex) when possible

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2FDBThreadSafe-ios%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dodobrands/DBThreadSafe-ios)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2FDBThreadSafe-ios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dodobrands/DBThreadSafe-ios)

DBThreadSafeContainer is a generic class that provides thread-safe read and write access to a stored value. By default it prefers Apple's `Synchronization.Mutex` on supported OS versions and falls back to `pthread_rwlock_t` elsewhere.

## Usage

### Initialization

To create a new instance of DBThreadSafeContainer, simply initialize it with an initial value:

```swift
let container = DBThreadSafeContainer("Hello, World!")
```

The default initializer automatically selects the concrete lock backend:

- `Synchronization.Mutex` on iOS 18+, macOS 15+, macCatalyst 18+, tvOS 18+, watchOS 11+, visionOS 2+
- `pthread_rwlock_t` everywhere else

You can inspect the chosen backend through `lockType`:

```swift
let container = DBThreadSafeContainer("Hello, World!")
let lockType = container.lockType
```

### Selecting a lock backend explicitly

Use `DBThreadSafeLock` to force a specific backend:

```swift
let pthreadContainer = DBThreadSafeContainer("Hello, World!", lock: .pthreadRWLock)
```

`Synchronization.Mutex` can only be selected on supported platforms:

```swift
if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
    let mutexContainer = DBThreadSafeContainer("Hello, World!", lock: .mutex)
}
```

The same selection API is available on the property wrapper:

```swift
@ThreadSafe(lock: .pthreadRWLock) var counter = 0
```

### Reading the value

To read the value stored in the container, use the `read()` method:

```swift
let value = container.read()
```

Alternatively, you can pass a closure to the `read()` method to perform operations on the value within the lock:

```swift
container.read { value in
    // Perform read-only operations on the value
}
```

You can also use the `read()` method with a closure that returns a value:

```swift
let result = container.read { value -> Int in
    // Perform read-only operations on the value and return a result
    return value.count
}
```

Simplier way:
```swift
let result = container.read { $.count }
```

If you need to handle errors within the closure, you can use the `read()` method that throws:

```swift
try container.read { value in
    // Perform read-only operations on the value that can throw errors
}
```

### Writing the value

To replace the current value with a new one, use the `write()` method:

```swift
container.write("New value")
```

You can also pass a closure to the `write()` method to make multiple modifications to the value within the lock:

```swift
container.write { value in
    // Make multiple modifications to the value
}
```

If you need to handle errors within the closure, you can use the `write()` method that throws:

```swift
try container.write { value in
    // Make multiple modifications to the value that can throw errors
}
```

## Thread Safety

DBThreadSafeContainer ensures that read and write operations are thread-safe, but the exact semantics depend on the selected backend:

- `pthread_rwlock_t`: multiple readers can proceed concurrently, while writes remain exclusive
- `Synchronization.Mutex`: both reads and writes are exclusive critical sections

Because the default initializer now prefers `Mutex` on supported OS versions, the same source code may use concurrent reads on older systems and exclusive reads on newer ones.

## Cleanup

DBThreadSafeContainer automatically cleans up the selected lock backend when it is deallocated.

## License

This code is released under the Apache License. See [LICENSE](LICENSE) for more information.
