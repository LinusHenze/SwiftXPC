# SwiftXPC

This library provides an easy-to-use Swift interface for XPC.  

# Examples
## Creating a listener

```Swift
// Create an XPCConnection object in listener mode
// Note: This requires the server name to be registered with launchd
//       (by including it in your service's launchd plist under the "MachServices" key)
//       Alternatively, this requirement can be bypassed by launching your Application inside a debugger
let listener = XPCConnection(machService: "SomeServiceName", flags: .listener)
listener.setEventHandler { (obj) in
    if let conn = obj as? XPCConnection {
        // Got a new client connection
        print("Listener: Got new connection!")
        
        // Set an event handler which will handle messages sent by the client
        conn.setEventHandler { (obj) in
            if let msg = obj as? XPCDict {
                print("Listener: Received message: \(msg)")
                
                // To reply, first create a reply dict
                let reply = msg.createReply()!
                reply["status"] = 0
                
                // Then send it
                conn.sendMessage(reply)
            }
        }
        
        conn.activate()
    } else {
        print("Listener: \(obj)")
    }
}
listener.activate()
```

## Creating a client
```Swift
// Create a connection to a service
let client = XPCConnection(machService: "SomeServiceName")
client.setEventHandler { (obj) in
    // Handle errors etc. here
}
client.activate()

// Send a message
let reply = try client.sendMessageWithReplySync(["Hello": "World!"])

// Print reply
print("Reply: \(reply)")
```
