@testable import DBThreadSafe
import Testing

@Suite("LockStorage Protocol Tests")
struct LockStorageTests {
    @Test("LockStorage supports existential storage for pthread backend")
    func existentialPThreadStorage() {
        let storage: any LockStorage<Int> = PThreadRWLockStorage(42)

        #expect(storage.lockType == .pthreadRWLock)
        #expect(storage.read() == 42)
    }

#if canImport(Synchronization)
    @available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("LockStorage supports existential storage for mutex backend")
    func existentialMutexStorage() {
        let storage: any LockStorage<Int> = MutexStorage(42)

        #expect(storage.lockType == .mutex)
        #expect(storage.read() == 42)
    }
#endif
}
