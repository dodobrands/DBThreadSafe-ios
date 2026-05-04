import DBThreadSafe
import Foundation
import Testing

@Suite("DBThreadSafeWeakContainer Tests")
struct DBThreadSafeWeakContainerTests {
    @Test("Explicit pthread rwlock selection reports pthread backend")
    func explicitPThreadRWLockSelection() {
        let container = DBThreadSafeWeakContainer<NSObject>(lock: .pthreadRWLock)

        #expect(container.lockType == .pthreadRWLock)
    }

#if canImport(Synchronization)
    @available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("Explicit mutex selection reports mutex backend")
    func explicitMutexSelection() {
        let container = DBThreadSafeWeakContainer<NSObject>(lock: .mutex)

        #expect(container.lockType == .mutex)
    }
#endif

    @Test("Default initializer prefers mutex backend when available")
    func defaultInitializerPrefersMutexBackendWhenAvailable() {
        let container = DBThreadSafeWeakContainer<NSObject>()

        #if canImport(Synchronization)
        if #available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
            #expect(container.lockType == .mutex)
        } else {
            #expect(container.lockType == .pthreadRWLock)
        }
        #else
        #expect(container.lockType == .pthreadRWLock)
        #endif
    }

    @Test("Init without value stores nil")
    func initWithoutValueStoresNil() {
        let container = DBThreadSafeWeakContainer<NSObject>()

        #expect(container.withLock { $0 } == nil)
    }

    @Test("Init with value stores reference")
    func initWithValueStoresReference() {
        let object = NSObject()
        let container = DBThreadSafeWeakContainer(object)

        #expect(container.withLock { $0 } === object)
    }

    @Test("withLock can write and read value")
    func withLockCanWriteAndReadValue() {
        let container = DBThreadSafeWeakContainer<NSObject>()
        let object = NSObject()

        container.withLock { value in
            value = object
        }

        #expect(container.withLock { $0 } === object)
    }

    @Test("withLock can clear value")
    func withLockCanClearValue() {
        let object = NSObject()
        let container = DBThreadSafeWeakContainer(object)

        container.withLock { value in
            value = nil
        }

        #expect(container.withLock { $0 } == nil)
    }

    @Test("Value becomes nil when referenced object deallocates")
    func valueBecomesNilWhenReferencedObjectDeallocates() {
        let container = DBThreadSafeWeakContainer<NSObject>()

        autoreleasepool {
            let object = NSObject()
            container.withLock { value in
                value = object
            }
            #expect(container.withLock { $0 } != nil)
        }

        #expect(container.withLock { $0 } == nil)
    }

    @Test("withLock replaces value with another object")
    func withLockReplacesValueWithAnotherObject() {
        let first = NSObject()
        let second = NSObject()
        let container = DBThreadSafeWeakContainer(first)

        container.withLock { value in
            value = second
        }

        #expect(container.withLock { $0 } === second)
    }

    @Test("withLock updates stored value")
    func withLockUpdatesStoredValue() {
        let first = NSObject()
        let second = NSObject()
        let container = DBThreadSafeWeakContainer(first)

        container.withLock { value in
            value = second
        }

        #expect(container.withLock { $0 } === second)
    }

    @Test("withLock returns transformed value")
    func withLockReturnsTransformedValue() {
        let object = NSObject()
        let container = DBThreadSafeWeakContainer(object)

        let identity = container.withLock { value in
            ObjectIdentifier(value!)
        }

        #expect(identity == ObjectIdentifier(object))
    }

    @Test("Class-bound protocol existentials are supported")
    func classBoundProtocolExistentialsAreSupported() {
        final class Delegate: TestDelegate {}

        let delegate = Delegate()
        let container = DBThreadSafeWeakContainer<any TestDelegate>()

        container.withLock { value in
            value = delegate
        }

        #expect((container.withLock { $0 } as AnyObject?) === delegate)
    }
}

private protocol TestDelegate: AnyObject {}
