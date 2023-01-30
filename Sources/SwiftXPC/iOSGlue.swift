//
//  iOSGlue.swift
//  SwiftXPC
//
//  Created by Linus Henze.
//  Copyright © 2023 Pinauten GmbH. All rights reserved.
//

#if os(iOS)

import SwiftXPCCBindings

public let XPC_TYPE_CONNECTION = _swift_xpc_type_CONNECTION()
public let XPC_TYPE_ENDPOINT   = _swift_xpc_type_ENDPOINT()
public let XPC_TYPE_NULL       = _swift_xpc_type_NULL()
public let XPC_TYPE_BOOL       = _swift_xpc_type_BOOL()
public let XPC_TYPE_INT64      = _swift_xpc_type_INT64()
public let XPC_TYPE_UINT64     = _swift_xpc_type_UINT64()
public let XPC_TYPE_DOUBLE     = _swift_xpc_type_DOUBLE()
public let XPC_TYPE_DATE       = _swift_xpc_type_DATE()
public let XPC_TYPE_DATA       = _swift_xpc_type_DATA()
public let XPC_TYPE_STRING     = _swift_xpc_type_STRING()
public let XPC_TYPE_UUID       = _swift_xpc_type_UUID()
public let XPC_TYPE_FD         = _swift_xpc_type_FD()
public let XPC_TYPE_SHMEM      = _swift_xpc_type_SHMEM()
public let XPC_TYPE_ARRAY      = _swift_xpc_type_ARRAY()
public let XPC_TYPE_DICTIONARY = _swift_xpc_type_DICTIONARY()
public let XPC_TYPE_ERROR      = _swift_xpc_type_ERROR()
public let XPC_TYPE_ACTIVITY   = _swift_xpc_type_ACTIVITY()

public let XPC_ERROR_KEY_DESCRIPTION = _xpc_error_key_description

#endif
