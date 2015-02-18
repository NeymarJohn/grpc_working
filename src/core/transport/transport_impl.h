/*
 *
 * Copyright 2015, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef __GRPC_INTERNAL_TRANSPORT_TRANSPORT_IMPL_H__
#define __GRPC_INTERNAL_TRANSPORT_TRANSPORT_IMPL_H__

#include "src/core/transport/transport.h"

typedef struct grpc_transport_vtable {
  /* Memory required for a single stream element - this is allocated by upper
     layers and initialized by the transport */
  size_t sizeof_stream; /* = sizeof(transport stream) */

  /* implementation of grpc_transport_init_stream */
  int (*init_stream)(grpc_transport *self, grpc_stream *stream,
                     const void *server_data);

  /* implementation of grpc_transport_send_batch */
  void (*send_batch)(grpc_transport *self, grpc_stream *stream,
                     grpc_stream_op *ops, size_t ops_count, int is_last);

  /* implementation of grpc_transport_set_allow_window_updates */
  void (*set_allow_window_updates)(grpc_transport *self, grpc_stream *stream,
                                   int allow);

  /* implementation of grpc_transport_add_to_pollset */
  void (*add_to_pollset)(grpc_transport *self, grpc_pollset *pollset);

  /* implementation of grpc_transport_destroy_stream */
  void (*destroy_stream)(grpc_transport *self, grpc_stream *stream);

  /* implementation of grpc_transport_abort_stream */
  void (*abort_stream)(grpc_transport *self, grpc_stream *stream,
                       grpc_status_code status);

  /* implementation of grpc_transport_goaway */
  void (*goaway)(grpc_transport *self, grpc_status_code status,
                 gpr_slice debug_data);

  /* implementation of grpc_transport_close */
  void (*close)(grpc_transport *self);

  /* implementation of grpc_transport_ping */
  void (*ping)(grpc_transport *self, void (*cb)(void *user_data),
               void *user_data);

  /* implementation of grpc_transport_destroy */
  void (*destroy)(grpc_transport *self);
} grpc_transport_vtable;

/* an instance of a grpc transport */
struct grpc_transport {
  /* pointer to a vtable defining operations on this transport */
  const grpc_transport_vtable *vtable;
};

#endif /* __GRPC_INTERNAL_TRANSPORT_TRANSPORT_IMPL_H__ */