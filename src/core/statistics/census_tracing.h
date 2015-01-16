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

#ifndef __GRPC_INTERNAL_STATISTICS_CENSUS_TRACING_H_
#define __GRPC_INTERNAL_STATISTICS_CENSUS_TRACING_H_

/* Opaque structure for trace object */
typedef struct trace_obj trace_obj;

/* Initializes trace store. This function is thread safe. */
void census_tracing_init(void);

/* Shutsdown trace store. This function is thread safe. */
void census_tracing_shutdown(void);

/* Gets trace obj corresponding to the input op_id. Returns NULL if trace store
   is not initialized or trace obj is not found. Requires trace store being
   locked before calling this function. */
trace_obj* census_get_trace_obj_locked(census_op_id op_id);

/* The following two functions acquire and release the trace store global lock.
   They are for census internal use only. */
void census_internal_lock_trace_store(void);
void census_internal_unlock_trace_store(void);

/* Gets method tag name associated with the input trace object. */
const char* census_get_trace_method_name(const trace_obj* trace);

#endif /* __GRPC_INTERNAL_STATISTICS_CENSUS_TRACING_H_ */
