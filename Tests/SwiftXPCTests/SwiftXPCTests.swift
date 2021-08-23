import XCTest
@testable import SwiftXPC

final class SwiftXPCTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let request = [
            "Bool": false,
            "String": "Test",
            "Null": nil,
            "Dict": [
                "Array": ["Element 0", 1] as XPCArray
            ] as XPCDict
        ] as XPCDict
        
        let listener = XPCConnection(machService: "de.linushenze.test", flags: .listener)
        listener.setEventHandler { (obj) in
            if let conn = obj as? XPCConnection {
                print("Listener: Got new connection!")
                conn.setEventHandler { (obj) in
                    if let msg = obj as? XPCDict {
                        print("Listener: Received message: \(msg)")
                        
                        let reply = msg.createReply()!
                        reply["status"] = 0
                        
                        conn.sendMessage(reply)
                    }
                }
                
                conn.activate()
            } else {
                print("Listener: \(obj)")
            }
        }
        listener.activate()
        
        let client = XPCConnection(machService: "de.linushenze.test")
        client.setEventHandler { (obj) in
            print("Client: \(obj)")
        }
        client.activate()
        
        print("Client: \(client.sendMessageWithReplySync(request))")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
