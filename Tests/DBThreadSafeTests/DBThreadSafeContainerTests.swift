import DBThreadSafe
import Foundation
import Testing

@Suite("DBThreadSafeContainer Tests")
struct DBThreadSafeContainerTests {
    let iterations = 100000

    @Test("Explicit pthread rwlock selection reports pthread backend")
    func explicitPThreadRWLockSelection() {
        let container = DBThreadSafeContainer(0, lock: .pthreadRWLock)

        #expect(container.lockType == .pthreadRWLock)
        #expect(container.read() == 0)
    }

#if canImport(Synchronization)
    @available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("Explicit mutex selection reports mutex backend")
    func explicitMutexSelection() {
        let container = DBThreadSafeContainer(0, lock: .mutex)

        #expect(container.lockType == .mutex)
        #expect(container.read() == 0)
    }

    @available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("Default initializer prefers mutex when available")
    func defaultInitializerPrefersMutexWhenAvailable() {
        let container = DBThreadSafeContainer(0)

        #expect(container.lockType == .mutex)
        #expect(container.read() == 0)
    }

    @available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("Default backend preserves nested read access")
    func defaultBackendPreservesNestedReadAccess() {
        let container = DBThreadSafeContainer(0)
        let finished = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            container.read { _ in
                #expect(container.read() == 0)
            }

            finished.signal()
        }

        #expect(finished.wait(timeout: .now() + 3) == .success)
    }
#endif

    @Test("Concurrent reads return correct value")
    func concurrentGet() {
        let container = DBThreadSafeContainer(0)

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = container.read()
        }

        #expect(container.read() == 0)
    }

    @Test("Read with closure")
    func read() {
        let container = DBThreadSafeContainer("Hello, World!")

        enum TestError: Error {
            case someError
        }

        // Test case 1: Read value successfully
        let expectedValue1 = "Hello, World!"
        container.read { value in
            #expect(value == expectedValue1)
        }

        // Test case 2: Read value with throwing closure
        #expect(throws: TestError.self) {
            try container.read { _ in
                throw TestError.someError
            }
        }
    }

    @Test("Read closure with return value")
    func readClosureReturnValue() {
        let container = DBThreadSafeContainer("Hello, World!")

        let result = container.read { $0.count }

        #expect(result == 13)
    }


    @Test("Concurrent writes increment correctly")
    func concurrentSet() {
        let container = DBThreadSafeContainer(0)

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            container.write { value in
                let newValue = value + 1
                value = newValue
            }
        }

        #expect(container.read() == iterations)
    }

    @Test("Concurrent array reads return correct value")
    func concurrentGetArray() {
        let container = DBThreadSafeContainer([1, 2, 3])

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = container.read()
        }

        #expect(container.read() == [1, 2, 3])
    }

    @Test("Concurrent array appends")
    func concurrentSetArray() throws {
        let container = DBThreadSafeContainer([0])

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            container.write { value in
                let lastValue = value.last!
                value.append(lastValue + 1)
            }
        }

        #expect(container.read().last == iterations)
    }

    @Test("Concurrent dictionary reads return correct value")
    func concurrentGetDictionary() {
        let container = DBThreadSafeContainer(["key1": "value1", "key2": "value2"])

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = container.read()
        }

        #expect(container.read() == ["key1": "value1", "key2": "value2"])
    }

    @Test("Concurrent dictionary operations")
    func concurrentSetDictionary() {
        let container = DBThreadSafeContainer(["key": 0])

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            container.write { dict in
                let value = dict["key"]
                dict["key"] = value! + 1
            }
        }

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            container.write { dict in
                let key = "key\(i)"
                dict[key] = i
            }
        }

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            container.write { dict in
                let key = "key\(i)"
                dict.removeValue(forKey: key)
            }
        }

        #expect(container.read() == ["key": iterations])
    }
}
