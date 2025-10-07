import DBThreadSafe
import Foundation
import Testing

@Suite("DBThreadSafeContainer Tests")
struct DBThreadSafeContainerTests {
    let iterations = 100000

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
