//
//  XPCConnection.swift
//  SwiftXPC
//
//  Created by Linus Henze.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//

import Foundation
import XPC

public class XPCConnection: XPCObject, XPCDictConnectionOrError {
    public enum MachServiceFlags {
        case none
        case listener
        case privileged
    }
    
    let conn: xpc_connection_t
    
    private var didActivate = false
    
    public var pid: pid_t { xpc_connection_get_pid(conn) }
    public var auditSessionID: au_asid_t { xpc_connection_get_asid(conn) }
    public var euid: uid_t { xpc_connection_get_euid(conn) }
    public var egid: gid_t { xpc_connection_get_egid(conn) }
    
    public init(connection: xpc_connection_t) {
        conn = connection
    }
    
    public convenience init(name: String? = nil, queue: DispatchQueue? = nil) {
        self.init(connection: xpc_connection_create(name, queue))
    }
    
    public convenience init(machService: String, flags: MachServiceFlags = .none, queue: DispatchQueue? = nil) {
        var iFlags: UInt64 = 0
        switch flags {
        case .none:
            iFlags = 0
            
        case .listener:
            iFlags = UInt64(bitPattern: Int64(XPC_CONNECTION_MACH_SERVICE_LISTENER))
        
        case .privileged:
            iFlags = UInt64(bitPattern: Int64(XPC_CONNECTION_MACH_SERVICE_PRIVILEGED))
        }
        
        self.init(connection: xpc_connection_create_mach_service(machService, queue, iFlags))
    }
    
    public func activate() {
        if #available(OSX 10.12, *) {
            xpc_connection_activate(conn)
        } else {
            if !didActivate {
                xpc_connection_resume(conn)
                didActivate = true
            }
        }
    }
    
    public func resume() {
        xpc_connection_resume(conn)
    }
    
    public func suspend() {
        xpc_connection_suspend(conn)
    }
    
    public func cancel() {
        xpc_connection_cancel(conn)
    }
    
    public func setEventHandler(_ handler: @escaping (XPCDictConnectionOrError) -> Void) {
        xpc_connection_set_event_handler(conn) {
            let xpcObj = xpc_object_t_to_XPCObject($0)
            
            assert((xpcObj as? XPCDictConnectionOrError) != nil)
            handler(xpcObj as! XPCDictConnectionOrError)
        }
    }
    
    public func sendMessage(_ message: XPCDict) {
        xpc_connection_send_message(conn, message._toXPCObject())
    }
    
    public func sendMessageWithReply(_ message: XPCDict, _ handler: @escaping (XPCDictOrError) -> Void, replyQueue: DispatchQueue? = nil) {
        xpc_connection_send_message_with_reply(conn, message._toXPCObject(), replyQueue) {
            let xpcObj = xpc_object_t_to_XPCObject($0)
            
            assert((xpcObj as? XPCDictOrError) != nil)
            handler(xpcObj as! XPCDictOrError)
        }
    }
    
    public func sendMessageWithReplySync(_ message: XPCDict) throws -> XPCDict {
        let res = xpc_connection_send_message_with_reply_sync(conn, message._toXPCObject())
        let xpcObj = xpc_object_t_to_XPCObject(res)
        
        if let error = xpcObj as? XPCError {
            throw error
        }
        
        guard let dict = xpcObj as? XPCDict else {
            fatalError()
        }
        
        return dict
    }
    
    public func _toXPCObject() -> xpc_object_t {
        return conn
    }
}
