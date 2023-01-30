//
//  XPCPipe.swift
//  SwiftXPC
//
//  Created by Linus Henze.
//  Copyright © 2023 Pinauten GmbH. All rights reserved.
//

import Foundation
import SwiftXPCCBindings

public class XPCPipe {
    public let pipe: xpc_pipe_t
    
    public init(port: mach_port_t) {
        pipe = xpc_pipe_create_from_port(port, 0)
    }
    
    public init(name: String) {
        pipe = xpc_pipe_create(name, 0)
    }
    
    public func send(message: XPCDict) -> XPCDictOrError? {
        var obj: xpc_object_t?
        let kr = xpc_pipe_routine(pipe, message._toXPCObject(), &obj)
        guard kr == KERN_SUCCESS,
              let obj = obj else {
            // XXX: Throw error
            return nil
        }
        
        // XXX: Can this even return errors?
        return xpc_object_t_to_XPCObject(obj) as? XPCDictOrError
    }
    
    public func sendOneway(message: XPCDict) -> Bool {
        xpc_pipe_simpleroutine(pipe, message._toXPCObject()) == KERN_SUCCESS
    }
    
    public func forward(message: XPCDict) -> Bool {
        xpc_pipe_routine_forward(pipe, message._toXPCObject()) == KERN_SUCCESS
    }
    
    public static func receive(port: mach_port_t) -> XPCDictOrError? {
        var obj: xpc_object_t?
        let kr = xpc_pipe_receive(port, &obj)
        guard kr == KERN_SUCCESS,
              let obj = obj else {
            return nil
        }
        
        // XXX: Can this even return errors?
        return xpc_object_t_to_XPCObject(obj) as? XPCDictOrError
    }
    
    public static func reply(dict: XPCDict) {
        xpc_pipe_routine_reply(dict._toXPCObject())
    }
}
