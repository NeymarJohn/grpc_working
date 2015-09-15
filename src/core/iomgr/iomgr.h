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

#ifndef GRPC_INTERNAL_CORE_IOMGR_IOMGR_H
#define GRPC_INTERNAL_CORE_IOMGR_IOMGR_H

/** gRPC Callback definition.
 *
 * \param arg Arbitrary input.
 * \param success An indication on the state of the iomgr. On false, cleanup
 * actions should be taken (eg, shutdown). */
typedef void (*grpc_iomgr_cb_func)(void *arg, int success);

/** A closure over a grpc_iomgr_cb_func. */
typedef struct grpc_iomgr_closure {
  /** Bound callback. */
  grpc_iomgr_cb_func cb;

  /** Arguments to be passed to "cb". */
  void *cb_arg;

  /** Internal. A boolean indication to "cb" on the state of the iomgr.
   * For instance, closures created during a shutdown would have this field set
   * to false. */
  int success;

  /**< Internal. Do not touch */
  struct grpc_iomgr_closure *next;
} grpc_iomgr_closure;

/** Initializes \a closure with \a cb and \a cb_arg. */
void grpc_iomgr_closure_init(grpc_iomgr_closure *closure, grpc_iomgr_cb_func cb,
                             void *cb_arg);

/** Initializes the iomgr. */
void grpc_iomgr_init(void);

/** Signals the intention to shutdown the iomgr. */
void grpc_iomgr_shutdown(void);

#endif /* GRPC_INTERNAL_CORE_IOMGR_IOMGR_H */
