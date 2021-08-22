import Foundation
import XPC

public protocol XPCObject {
    func _toXPCObject() -> xpc_object_t
}

public typealias XPCSwiftDict = [String: XPCObject?]
public typealias XPCArray     = [XPCObject?]

public class XPCDict: ExpressibleByDictionaryLiteral, Sequence, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, XPCObject {
    public typealias Key = String
    public typealias Value = XPCObject?
    
    public typealias Iterator = Dictionary<String, XPCObject?>.Iterator
    
    let xpcDict: xpc_object_t
    
    public var description: String { toSwiftDict().description }
    public var debugDescription: String { toSwiftDict().debugDescription }
    public var customMirror: Mirror { toSwiftDict().customMirror }
    
    public init(_ dict: xpc_object_t) {
        xpcDict = dict
    }
    
    public init(fromSwiftDict sDict: XPCSwiftDict) {
        xpcDict = xpc_dictionary_create(nil, nil, 0)
        for elem in sDict {
            xpc_dictionary_set_value(xpcDict, elem.key.cString(using: .utf8)!, elem.value._toXPCObject())
        }
    }
    
    public required init(dictionaryLiteral elements: (Key, Value)...) {
        xpcDict = xpc_dictionary_create(nil, nil, 0)
        for elem in elements {
            xpc_dictionary_set_value(xpcDict, elem.0.cString(using: .utf8)!, elem.1._toXPCObject())
        }
    }
    
    public subscript(_ key: Key) -> Value? {
        get {
            guard let val = xpc_dictionary_get_value(xpcDict, key.cString(using: .utf8)!) else {
                return nil
            }
            
            return xpc_object_t_to_XPCObject(val)
        }
        
        set {
            xpc_dictionary_set_value(xpcDict, key.cString(using: .utf8)!, newValue?._toXPCObject())
        }
    }
    
    public func createReply() -> XPCDict? {
        guard let repl = xpc_dictionary_create_reply(xpcDict) else {
            return nil
        }
        
        return XPCDict(repl)
    }
    
    public func toSwiftDict() -> XPCSwiftDict {
        var res = XPCSwiftDict()
        
        xpc_dictionary_apply(xpcDict) { (key, value) -> Bool in
            res[String(cString: key)] = xpc_object_t_to_XPCObject(value)
            
            return true
        }
        
        return res
    }
    
    public func makeIterator() -> Iterator {
        return toSwiftDict().makeIterator()
    }
    
    public func _toXPCObject() -> xpc_object_t {
        xpcDict
    }
}

extension XPCArray: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        let xpcAr = xpc_array_create(nil, 0)
        for elem in self {
            xpc_array_append_value(xpcAr, elem._toXPCObject())
        }
        
        return xpcAr
    }
}

extension Data: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        withUnsafeBytes {
            xpc_data_create($0.baseAddress, $0.count)
        }
    }
}

extension String: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        xpc_string_create(self.cString(using: .utf8)!)
    }
}

extension Bool: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        xpc_bool_create(self)
    }
}

extension UInt64: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        xpc_uint64_create(self)
    }
}

extension Int64: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        xpc_int64_create(self)
    }
}

extension UInt: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        xpc_uint64_create(UInt64(self))
    }
}

extension Int: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        xpc_int64_create(Int64(self))
    }
}

extension Double: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        xpc_double_create(self)
    }
}

extension UUID: XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        withUnsafePointer(to: uuid.0) {
            xpc_uuid_create($0)
        }
    }
}

extension Optional: XPCObject where Wrapped == XPCObject {
    public func _toXPCObject() -> xpc_object_t {
        if self != nil {
            return self.unsafelyUnwrapped._toXPCObject()
        }
        
        return xpc_null_create()
    }
}

public class XPCError: XPCObject {
    let underlying: xpc_object_t
    
    public var description: String { String(cString: xpc_dictionary_get_string(underlying, XPC_ERROR_KEY_DESCRIPTION)!) }
    
    fileprivate init(_ underlying: xpc_object_t) {
        assert(xpc_get_type(underlying) == XPC_TYPE_ERROR)
        
        self.underlying = underlying
    }
    
    public func _toXPCObject() -> xpc_object_t {
        underlying
    }
}

public func xpc_object_t_to_XPCObject(_ obj: xpc_object_t) -> XPCObject? {
    let type = xpc_get_type(obj)
    switch type {
    case XPC_TYPE_DICTIONARY:
        return XPCDict(obj)
        
    case XPC_TYPE_ARRAY:
        var res = XPCArray(repeating: nil, count: xpc_array_get_count(obj))
        
        xpc_array_apply(obj) { (index, value) -> Bool in
            res[index] = xpc_object_t_to_XPCObject(value)
            
            return true
        }
        
        return res
        
    case XPC_TYPE_DATA:
        if let ptr = xpc_data_get_bytes_ptr(obj) {
            return Data(bytes: ptr, count: xpc_data_get_length(obj))
        }
        
        return Data()
        
    case XPC_TYPE_STRING:
        if let ptr = xpc_string_get_string_ptr(obj) {
            return String(cString: ptr)
        }
        
        return ""
        
    case XPC_TYPE_BOOL:
        return xpc_bool_get_value(obj)
        
    case XPC_TYPE_UINT64:
        return xpc_uint64_get_value(obj)
        
    case XPC_TYPE_INT64:
        return xpc_int64_get_value(obj)
        
    case XPC_TYPE_DOUBLE:
        return xpc_double_get_value(obj)
    
    case XPC_TYPE_UUID:
        let uuid = UnsafeRawPointer(xpc_uuid_get_bytes(obj))!.assumingMemoryBound(to: uuid_t.self).pointee
        return UUID(uuid: uuid)
        
    case XPC_TYPE_NULL:
        return nil
        
    case XPC_TYPE_ERROR:
        return XPCError(obj)
        
    case XPC_TYPE_CONNECTION:
        return XPCConnection(connection: obj)
        
    default:
        if #available(OSX 10.15, *) {
            let str = String(cString: xpc_type_get_name(type))
            fatalError("Don't know how to handle XPC type \(str)")
        } else {
            let str = String(cString: xpc_copy_description(obj))
            fatalError("Don't know how to handle XPC object \(str)")
        }
    }
}
