import XCTest
@testable import SwiftXPC

final class SwiftXPCTests: XCTestCase {
    func testListener() {
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
        
        XCTAssertNoThrow(try {
            let reply = try client.sendMessageWithReplySync(request)
            
            print("Client: \(reply)")
            
            XCTAssert(reply["status"] as? Int64 == 0)
        }())
    }

    static var allTests = [
        ("testListener", testListener),
    ]
}
