//
//  XPCMachPort.swift
//  SwiftXPC
//
//  Created by Linus Henze.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//

import Foundation
import SwiftXPCCBindings

// Ugly definitions below...
public let XPC_TYPE_MACH_SEND: xpc_type_t = unsafeBitCast(OpaquePointer(dlsym(dlopen(nil, 0), "NSClassFromString")), to: (@convention(c) (NSString) -> xpc_type_t?).self)("OS_xpc_mach_send")!
public let XPC_TYPE_MACH_RECV: xpc_type_t = unsafeBitCast(OpaquePointer(dlsym(dlopen(nil, 0), "NSClassFromString")), to: (@convention(c) (NSString) -> xpc_type_t?).self)("OS_xpc_mach_recv")!

// Potentially unavailable?
public let XPC_TYPE_MACH_SEND_ONCE: xpc_type_t? = unsafeBitCast(OpaquePointer(dlsym(dlopen(nil, 0), "NSClassFromString")), to: (@convention(c) (NSString) -> xpc_type_t?)?.self)?("OS_xpc_mach_send_once")!

public class XPCMachPortSendRight: XPCObject {
    let underlying: xpc_object_t
    
    init(_ underlying: xpc_object_t) {
        assert(xpc_get_type(underlying) == XPC_TYPE_MACH_SEND)
        
        self.underlying = underlying
    }
    
    public convenience init(consuming sr: mach_port_t) {
        self.init(xpc_mach_send_create_with_disposition(sr, MACH_MSG_TYPE_MOVE_SEND))
    }
    
    public convenience init(copying sr: mach_port_t) {
        self.init(xpc_mach_send_create_with_disposition(sr, MACH_MSG_TYPE_COPY_SEND))
    }
    
    public convenience init(fromReceiveRight rr: mach_port_t) {
        self.init(xpc_mach_send_create_with_disposition(rr, MACH_MSG_TYPE_MAKE_SEND))
    }
    
    public func copySendRight() -> mach_port_t {
        xpc_mach_send_copy_right(underlying)
    }
    
    public func toXPCObject() -> xpc_object_t {
        underlying
    }
}

public class XPCMachPortReceiveRight: XPCObject {
    let underlying: xpc_object_t
    
    init(_ underlying: xpc_object_t) {
        assert(xpc_get_type(underlying) == XPC_TYPE_MACH_RECV)
        
        self.underlying = underlying
    }
    
    public convenience init(consuming rr: mach_port_t) {
        self.init(xpc_mach_recv_create(rr))
    }
    
    public func extractReceiveRight() -> mach_port_t {
        xpc_mach_recv_extract_right(underlying)
    }
    
    public func toXPCObject() -> xpc_object_t {
        underlying
    }
}

public class XPCMachPortSendOnceRight: XPCObject {
    let underlying: xpc_object_t
    
    init(_ underlying: xpc_object_t) {
        guard XPC_TYPE_MACH_SEND_ONCE != nil else {
            fatalError("XPC send once rights are not available!")
        }
        
        assert(xpc_get_type(underlying) == XPC_TYPE_MACH_SEND_ONCE.unsafelyUnwrapped)
        
        self.underlying = underlying
    }
    
    public convenience init(consuming sor: mach_port_t) {
        guard XPC_TYPE_MACH_SEND_ONCE != nil else {
            fatalError("XPC send once rights are not available!")
        }
        
        typealias soCreateType = @convention(c) (mach_port_t) -> xpc_object_t
        guard let fPtr = OpaquePointer(dlsym(dlopen(nil, 0), "xpc_mach_send_once_create")) else {
            fatalError("xpc_mach_send_once_create is unavailable!")
        }
        
        let xpc_mach_send_once_create = unsafeBitCast(fPtr, to: soCreateType.self)
        
        self.init(xpc_mach_send_once_create(sor))
    }
    
    public func extractSendOnceRight() -> mach_port_t {
        guard XPC_TYPE_MACH_SEND_ONCE != nil else {
            fatalError("XPC send once rights are not available!")
        }
        
        typealias soExtractType = @convention(c) (xpc_object_t) -> mach_port_t
        guard let fPtr = OpaquePointer(dlsym(dlopen(nil, 0), "xpc_mach_send_once_extract_right")) else {
            fatalError("xpc_mach_send_once_extract_right is unavailable!")
        }
        
        let xpc_mach_send_once_extract_right = unsafeBitCast(fPtr, to: soExtractType.self)
        
        return xpc_mach_send_once_extract_right(underlying)
    }
    
    public func toXPCObject() -> xpc_object_t {
        underlying
    }
}
