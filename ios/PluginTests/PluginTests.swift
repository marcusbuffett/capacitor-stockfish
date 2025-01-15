import XCTest
import Capacitor
import CapacitorStockfish

class PluginTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEcho() {
        // This is an example of a functional test case for a plugin.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let value = "Hello, World!"
        let stockfish = Stockfish()
        let plugin = StockfishBridge(plugin: stockfish)
        print("plugin: \(plugin!)")

        let call = CAPPluginCall(callbackId: "test", options: [
            "value": value
        ], success: { (result, _) in
            let resultValue = result!.data!["value"] as? String
            XCTAssertEqual(value, resultValue)
        }, error: { (_) in
            XCTFail("Error shouldn't have been called")
        })
        

        plugin!.start()
        plugin!.cmd("go nodes 1000")
        
        let expectation = XCTestExpectation(description: "Wait for 60 seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
            expectation.fulfill()
        }
        plugin!.exit();
        
        wait(for: [expectation], timeout: 61.0)


    }
}
