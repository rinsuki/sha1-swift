import XCTest
@testable import SHA1

private extension Data {
    var hex: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

final class SHA1Tests: XCTestCase {
    func testEmpty() {
        var empty = Data()
        let hash = SHA1(from: &empty)
        XCTAssertEqual(hash.hex, "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        XCTAssertEqual(hash.data.hex, hash.hex)
    }

    func testString() {
        var helloWorld = "Hello, world!".data(using: .utf8)!
        let helloWorldHash = SHA1(from: &helloWorld)
        XCTAssertEqual(helloWorldHash.hex, helloWorldHash.data.hex)
        XCTAssertEqual(helloWorldHash.hex, "943a702d06f34599aee1f8da8ef9f7296031d699")
        
        var helloWorld39 = String(repeating: "Hello, world!", count: 39).data(using: .utf8)!
        let helloWorld39Hash = SHA1(from: &helloWorld39)
        XCTAssertEqual(helloWorld39Hash.hex, "832d1072304bb8662ca5c44e9c568172983d61bb")
        XCTAssertEqual(helloWorld39Hash.hex, helloWorld39Hash.data.hex)
    }

    static var allTests = [
        ("testEmpty", testEmpty),
        ("testString", testString),
    ]
}
