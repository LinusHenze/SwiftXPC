//
//  SwiftXPCCBindings.h
//  SwiftXPC/SwiftXPCCBindings
//
//  Created by Linus Henze.
//  Copyright © 2021-2023 Pinauten GmbH. All rights reserved.
//

#ifndef SwiftXPCCBindings_h
#define SwiftXPCCBindings_h

#include <xpc/xpc.h>
#include <mach/mach.h>

#include "XPCOverlayShims.h"

typedef xpc_object_t xpc_pipe_t;

// Mach send rights
xpc_object_t xpc_mach_send_create_with_disposition(mach_port_t port, int disposition);
mach_port_t xpc_mach_send_copy_right(xpc_object_t xpcMachSend);

// Mach receive rights
xpc_object_t xpc_mach_recv_create(mach_port_t port);
mach_port_t xpc_mach_recv_extract_right(xpc_object_t xpcMachRecv);

// Create pipes
xpc_pipe_t xpc_pipe_create(const char *name, uint64_t flags);
xpc_pipe_t xpc_pipe_create_from_port(mach_port_t port, uint64_t flags);

// Receive (takes a port not pipe)
int xpc_pipe_receive(mach_port_t port, __strong xpc_object_t* message);

// Send
int xpc_pipe_routine(xpc_pipe_t pipe, xpc_object_t request, __strong xpc_object_t* reply);
int xpc_pipe_routine_reply(xpc_object_t reply);
int xpc_pipe_simpleroutine(xpc_pipe_t pipe, xpc_object_t message);

// Forward
int xpc_pipe_routine_forward(xpc_pipe_t forward_to, xpc_object_t request);

#endif /* SwiftXPCCBindings_h */
