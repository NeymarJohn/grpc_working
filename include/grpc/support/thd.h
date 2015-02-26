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

#ifndef __GRPC_SUPPORT_THD_H__
#define __GRPC_SUPPORT_THD_H__
/* Thread interface for GPR.

   Types
        gpr_thd_id        a thread identifier.
                          (Currently no calls take a thread identifier.
                          It exists for future extensibility.)
        gpr_thd_options   options used when creating a thread
 */

#include <grpc/support/port_platform.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef gpr_uint64 gpr_thd_id;

/* Thread creation options. */
typedef struct {
  int flags; /* Flags below can be set here.  Default value 0.  */
} gpr_thd_options;
/* No flags are currently defined. */

/* Create a new thread running (*thd_body)(arg) and place its thread identifier
   in *t, and return true.  If there are insufficient resources, return false.
   If options==NULL, default options are used.
   The thread is immediately runnable, and exits when (*thd_body)() returns.  */
int gpr_thd_new(gpr_thd_id *t, void (*thd_body)(void *arg), void *arg,
                const gpr_thd_options *options);

/* Return a gpr_thd_options struct with all fields set to defaults. */
gpr_thd_options gpr_thd_options_default(void);

/* Returns the identifier of the current thread. */
gpr_thd_id gpr_thd_currentid(void);

#ifdef __cplusplus
}
#endif

#endif /* __GRPC_SUPPORT_THD_H__ */
