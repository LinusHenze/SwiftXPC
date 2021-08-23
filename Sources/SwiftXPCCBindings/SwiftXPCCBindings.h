#ifndef SwiftXPCCBindings_h
#define SwiftXPCCBindings_h

#include <xpc/xpc.h>
#include <mach/mach.h>

xpc_object_t xpc_mach_send_create_with_disposition(mach_port_t port, int disposition);
mach_port_t xpc_mach_send_copy_right(xpc_object_t xpcMachSend);

xpc_object_t xpc_mach_recv_create(mach_port_t port);
mach_port_t xpc_mach_recv_extract_right(xpc_object_t xpcMachRecv);

#endif /* SwiftXPCCBindings_h */
