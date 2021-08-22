import Foundation
import XPC

public class XPCConnection: XPCObject {
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
    
    public func setEventHandler(_ handler: @escaping (XPCObject?) -> Void) {
        xpc_connection_set_event_handler(conn) { (obj) in
            handler(xpc_object_t_to_XPCObject(obj))
        }
    }
    
    public func sendMessage(_ message: XPCObject) {
        xpc_connection_send_message(conn, message._toXPCObject())
    }
    
    public func sendMessageWithReply(_ message: XPCObject, _ handler: @escaping (XPCObject?) -> Void, replyQueue: DispatchQueue? = nil) {
        xpc_connection_send_message_with_reply(conn, message._toXPCObject(), replyQueue) {
            handler(xpc_object_t_to_XPCObject($0))
        }
    }
    
    public func sendMessageWithReplySync(_ message: XPCObject) -> XPCObject? {
        let res = xpc_connection_send_message_with_reply_sync(conn, message._toXPCObject())
        return xpc_object_t_to_XPCObject(res)
    }
    
    public func _toXPCObject() -> xpc_object_t {
        return conn
    }
}
