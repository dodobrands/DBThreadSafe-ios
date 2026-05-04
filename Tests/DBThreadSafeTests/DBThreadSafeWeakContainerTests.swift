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

        #expect(container.value == nil)
    }

    @Test("Init with value stores reference")
    func initWithValueStoresReference() {
        let object = NSObject()
        let container = DBThreadSafeWeakContainer(object)

        #expect(container.value === object)
    }

    @Test("Set and get value")
    func setAndGetValue() {
        let container = DBThreadSafeWeakContainer<NSObject>()
        let object = NSObject()

        container.value = object

        #expect(container.value === object)
    }

    @Test("Set nil clears value")
    func setNilClearsValue() {
        let object = NSObject()
        let container = DBThreadSafeWeakContainer(object)

        container.value = nil

        #expect(container.value == nil)
    }

    @Test("Value becomes nil when referenced object deallocates")
    func valueBecomesNilWhenReferencedObjectDeallocates() {
        let container = DBThreadSafeWeakContainer<NSObject>()

        autoreleasepool {
            let object = NSObject()
            container.value = object
            #expect(container.value != nil)
        }

        #expect(container.value == nil)
    }

    @Test("Replace value with another object")
    func replaceValueWithAnotherObject() {
        let first = NSObject()
        let second = NSObject()
        let container = DBThreadSafeWeakContainer(first)

        container.value = second

        #expect(container.value === second)
    }

    @Test("Class-bound protocol existentials are supported")
    func classBoundProtocolExistentialsAreSupported() {
        final class Delegate: TestDelegate {}

        let delegate = Delegate()
        let container = DBThreadSafeWeakContainer<any TestDelegate>()

        container.value = delegate

        #expect((container.value as AnyObject?) === delegate)
    }
}

private protocol TestDelegate: AnyObject {}
