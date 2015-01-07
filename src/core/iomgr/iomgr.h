/*
 *
 * Copyright 2014, Google Inc.
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

#ifndef __GRPC_INTERNAL_IOMGR_IOMGR_H__
#define __GRPC_INTERNAL_IOMGR_IOMGR_H__

/* Status passed to callbacks for grpc_em_fd_notify_on_read and
   grpc_em_fd_notify_on_write.  */
typedef enum grpc_em_cb_status {
  GRPC_CALLBACK_SUCCESS = 0,
  GRPC_CALLBACK_TIMED_OUT,
  GRPC_CALLBACK_CANCELLED,
  GRPC_CALLBACK_DO_NOT_USE
} grpc_iomgr_cb_status;

/* gRPC Callback definition */
typedef void (*grpc_iomgr_cb_func)(void *arg, grpc_iomgr_cb_status status);

void grpc_iomgr_init();
void grpc_iomgr_shutdown();

/* This function is called from within a callback or from anywhere else
   and causes the invocation of a callback at some point in the future */
void grpc_iomgr_add_callback(grpc_iomgr_cb_func cb, void *cb_arg);

#endif /* __GRPC_INTERNAL_IOMGR_IOMGR_H__ */
