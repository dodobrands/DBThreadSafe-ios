# DBThreadSafeContainer

> **_NOTE:_**  Prefer using Apple's [Mutex](https://developer.apple.com/documentation/synchronization/mutex) when possible

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2FDBThreadSafe-ios%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dodobrands/DBThreadSafe-ios)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2FDBThreadSafe-ios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dodobrands/DBThreadSafe-ios)

DBThreadSafeContainer is a generic class that provides thread-safe read and write access to a stored value. It uses a `pthread_rwlock_t` lock to ensure that multiple threads can safely access the value concurrently.

## Usage

### Initialization

To create a new instance of DBThreadSafeContainer, simply initialize it with an initial value:

```swift
let container = DBThreadSafeContainer("Hello, World!")
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

DBThreadSafeContainer ensures that read and write operations are thread-safe by using a `pthread_rwlock_t` lock. This allows multiple threads to read the value concurrently, while ensuring that only one thread can write to the value at a time.

## Cleanup

DBThreadSafeContainer automatically destroys the `pthread_rwlock_t` lock when it is deallocated to prevent any resource leaks.

## License

This code is released under the Apache License. See [LICENSE](LICENSE) for more information.
