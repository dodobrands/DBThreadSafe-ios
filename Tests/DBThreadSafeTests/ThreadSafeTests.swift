import DBThreadSafe
import Foundation
import Testing

@Suite("ThreadSafe Property Wrapper Tests")
struct ThreadSafeTests {
    let iterations = 100000

    @Test("Reading wrappedValue returns correct value")
    func readWrappedValue() {
        @ThreadSafe var counter = 42

        #expect(counter == 42)
    }

    @Test("Writing with write closure updates value")
    func writeWithClosure() {
        @ThreadSafe var counter = 0

        $counter.write { value in
            value = 100
        }

        #expect(counter == 100)
    }

    @Test("Concurrent reads via wrappedValue")
    func concurrentReads() {
        @ThreadSafe var value = 42

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = value
        }

        #expect(value == 42)
    }

    @Test("Concurrent writes with write closure")
    func concurrentWrites() {
        @ThreadSafe var counter = 0

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            $counter.write { value in
                value += 1
            }
        }

        #expect(counter == iterations)
    }

    @Test("Projected value provides access to container")
    func projectedValue() {
        @ThreadSafe var counter = 0

        $counter.write { value in
            value = 100
        }

        #expect(counter == 100)
    }

    @Test("Concurrent writes using projected value write closure")
    func concurrentWritesWithClosure() {
        @ThreadSafe var counter = 0

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            $counter.write { value in
                value += 1
            }
        }

        #expect(counter == iterations)
    }

    @Test("Reading with projected value read method")
    func readWithProjectedValue() {
        @ThreadSafe var text = "Hello, World!"

        let length = $text.read { $0.count }

        #expect(length == 13)
    }

    @Test("Concurrent array operations via projected value")
    func concurrentArrayOperations() {
        @ThreadSafe var numbers = [0]

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            $numbers.write { value in
                let lastValue = value.last!
                value.append(lastValue + 1)
            }
        }

        #expect(numbers.last == iterations)
    }

    @Test("Concurrent dictionary operations via projected value")
    func concurrentDictionaryOperations() {
        @ThreadSafe var dict = ["key": 0]

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            $dict.write { dict in
                let value = dict["key"]
                dict["key"] = value! + 1
            }
        }

        #expect(dict["key"] == iterations)
    }

    @Test("Struct property with ThreadSafe wrapper")
    func structProperty() {
        struct Counter {
            @ThreadSafe var value = 0
        }

        let counter = Counter()
        counter.$value.write { value in
            value = 50
        }

        #expect(counter.value == 50)
    }

    @Test("Class property with ThreadSafe wrapper")
    func classProperty() {
        class Counter {
            @ThreadSafe var value = 0
        }

        let counter = Counter()
        counter.$value.write { value in
            value = 75
        }

        #expect(counter.value == 75)

        counter.$value.write { value in
            value = 100
        }

        #expect(counter.value == 100)
    }

    @Test("write method with throwing closure")
    func writeThrowing() {
        @ThreadSafe var counter = 0

        enum TestError: Error {
            case someError
        }

        #expect(throws: TestError.self) {
            try $counter.write { _ in
                throw TestError.someError
            }
        }
    }

    @Test("Concurrent array operations via write closure")
    func concurrentArrayWithWrite() {
        @ThreadSafe var numbers = [0]

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            $numbers.write { value in
                let lastValue = value.last!
                value.append(lastValue + 1)
            }
        }

        #expect(numbers.last == iterations)
    }

    @Test("Concurrent dictionary operations via write closure")
    func concurrentDictionaryWithWrite() {
        @ThreadSafe var dict = ["key": 0]

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            $dict.write { dict in
                let value = dict["key"]
                dict["key"] = value! + 1
            }
        }

        #expect(dict["key"] == iterations)
    }
}
