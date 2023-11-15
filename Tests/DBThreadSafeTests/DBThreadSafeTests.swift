import DBThreadSafe
import XCTest

class DBThreadSafeTests: XCTestCase {
    let iterations = 100000
    
    func testConcurrentGet() {
        let container = ThreadSafeContainer(0)
        
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = container.read()
        }
        
        XCTAssertEqual(container.read(), 0)
    }
    
    func testRead() {
        let container = ThreadSafeContainer("Hello, World!")
        
        enum TestError: Error {
            case someError
        }
        
        // Test case 1: Read value successfully
        let expectedValue1 = "Hello, World!"
        container.read { value in
            XCTAssertEqual(value, expectedValue1)
        }
        
        // Test case 2: Read value with throwing closure
        XCTAssertThrowsError(try container.read { _ in
            throw TestError.someError
        }) { error in
            XCTAssertEqual(error as? TestError, TestError.someError)
        }
    }
    
    func testReadClosureReturnValue() {
        let container = ThreadSafeContainer("Hello, World!")
        
        let result = container.read { $0.count }
        
        XCTAssertEqual(result, 13)
    }

    
    func testConcurrentSet() {
        let container = ThreadSafeContainer(0)
        
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            container.write { value in
                let newValue = value + 1
                value = newValue
            }
        }
        
        XCTAssertEqual(container.read(), iterations)
    }
    
    func testConcurrentGetArray() {
        let container = ThreadSafeContainer([1, 2, 3])
        
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = container.read()
        }
        
        XCTAssertEqual(container.read(), [1, 2, 3])
    }
    
    func testConcurrentSetArray() throws {
        let container = ThreadSafeContainer([0])
        
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            container.write { value in
                let lastValue = value.last!
                value.append(lastValue + 1)
            }
        }
        
        XCTAssertEqual(container.read().last, iterations)
    }
    
    func testConcurrentGetDictionary() {
        let container = ThreadSafeContainer(["key1": "value1", "key2": "value2"])
        
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = container.read()
        }
        
        XCTAssertEqual(container.read(), ["key1": "value1", "key2": "value2"])
    }
    
    func testConcurrentSetDictionary() {
        let container = ThreadSafeContainer(["key": 0])
        
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
        
        XCTAssertEqual(container.read(), ["key": iterations])
    }
}
