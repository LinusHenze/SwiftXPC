//
//  SwiftXPCTests.swift
//  SwiftXPC
//
//  Created by Linus Henze.
//  Copyright © 2021-2023 Pinauten GmbH. All rights reserved.
//

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
    
    func testPipe() {
        var port: mach_port_t = 0
        guard mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &port) == KERN_SUCCESS else {
            XCTFail("mach_port_allocate failed!")
            return
        }
        
        guard mach_port_insert_right(mach_task_self_, port, port, mach_msg_type_name_t(MACH_MSG_TYPE_MAKE_SEND)) == KERN_SUCCESS else {
            XCTFail("mach_port_insert_right failed!")
            return
        }
        
        DispatchQueue(label: "rcv").async {
            guard let msg = XPCPipe.receive(port: port) else {
                XCTFail("XPCPipe.receive failed!")
                return
            }
            
            guard let dict = msg as? XPCDict else {
                XCTFail("Didn't receive XPCDict!")
                return
            }
            
            guard let reply = dict.createReply() else {
                XCTFail("Couldn't create reply!")
                return
            }
            
            guard let hello = dict["Hello"] as? String else {
                XCTFail("Dict doesn't contain hello String!")
                reply["status"] = Int64(KERN_INVALID_ARGUMENT)
                XPCPipe.reply(dict: reply)
                return
            }
            
            XCTAssert(hello == "world!")
            
            reply["status"] = 0
            
            XPCPipe.reply(dict: reply)
        }
        
        let msg = [
            "Hello": "world!"
        ] as XPCDict
        
        let pipe = XPCPipe(port: port)
        let reply = pipe.send(message: msg)
        guard let dict = reply as? XPCDict else {
            XCTFail("Didn't receive XPCDict!")
            return
        }
        
        XCTAssert(dict["status"] as? Int64 == 0, "Reply status is not 0!")
    }

    static var allTests = [
        ("testListener", testListener),
        ("testPipe", testPipe),
    ]
}
