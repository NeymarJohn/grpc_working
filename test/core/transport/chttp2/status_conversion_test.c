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

#include "src/core/lib/transport/chttp2/status_conversion.h"
#include <grpc/support/log.h>
#include "test/core/util/test_config.h"

#define GRPC_STATUS_TO_HTTP2_ERROR(a, b) \
  GPR_ASSERT(grpc_chttp2_grpc_status_to_http2_error(a) == (b))
#define HTTP2_ERROR_TO_GRPC_STATUS(a, b) \
  GPR_ASSERT(grpc_chttp2_http2_error_to_grpc_status(a) == (b))
#define GRPC_STATUS_TO_HTTP2_STATUS(a, b) \
  GPR_ASSERT(grpc_chttp2_grpc_status_to_http2_status(a) == (b))
#define HTTP2_STATUS_TO_GRPC_STATUS(a, b) \
  GPR_ASSERT(grpc_chttp2_http2_status_to_grpc_status(a) == (b))

int main(int argc, char **argv) {
  int i;

  grpc_test_init(argc, argv);

  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_OK, GRPC_CHTTP2_NO_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_CANCELLED, GRPC_CHTTP2_CANCEL);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_UNKNOWN, GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_INVALID_ARGUMENT,
                             GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_DEADLINE_EXCEEDED,
                             GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_NOT_FOUND, GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_ALREADY_EXISTS,
                             GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_PERMISSION_DENIED,
                             GRPC_CHTTP2_INADEQUATE_SECURITY);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_UNAUTHENTICATED,
                             GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_RESOURCE_EXHAUSTED,
                             GRPC_CHTTP2_ENHANCE_YOUR_CALM);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_FAILED_PRECONDITION,
                             GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_ABORTED, GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_OUT_OF_RANGE,
                             GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_UNIMPLEMENTED,
                             GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_INTERNAL, GRPC_CHTTP2_INTERNAL_ERROR);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_UNAVAILABLE,
                             GRPC_CHTTP2_REFUSED_STREAM);
  GRPC_STATUS_TO_HTTP2_ERROR(GRPC_STATUS_DATA_LOSS, GRPC_CHTTP2_INTERNAL_ERROR);

  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_OK, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_CANCELLED, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_UNKNOWN, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_INVALID_ARGUMENT, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_DEADLINE_EXCEEDED, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_NOT_FOUND, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_ALREADY_EXISTS, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_PERMISSION_DENIED, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_UNAUTHENTICATED, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_RESOURCE_EXHAUSTED, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_FAILED_PRECONDITION, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_ABORTED, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_OUT_OF_RANGE, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_UNIMPLEMENTED, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_INTERNAL, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_UNAVAILABLE, 200);
  GRPC_STATUS_TO_HTTP2_STATUS(GRPC_STATUS_DATA_LOSS, 200);

  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_NO_ERROR, GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_PROTOCOL_ERROR, GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_INTERNAL_ERROR, GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_FLOW_CONTROL_ERROR,
                             GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_SETTINGS_TIMEOUT,
                             GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_STREAM_CLOSED, GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_FRAME_SIZE_ERROR,
                             GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_REFUSED_STREAM,
                             GRPC_STATUS_UNAVAILABLE);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_CANCEL, GRPC_STATUS_CANCELLED);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_COMPRESSION_ERROR,
                             GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_CONNECT_ERROR, GRPC_STATUS_INTERNAL);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_ENHANCE_YOUR_CALM,
                             GRPC_STATUS_RESOURCE_EXHAUSTED);
  HTTP2_ERROR_TO_GRPC_STATUS(GRPC_CHTTP2_INADEQUATE_SECURITY,
                             GRPC_STATUS_PERMISSION_DENIED);

  HTTP2_STATUS_TO_GRPC_STATUS(200, GRPC_STATUS_OK);
  HTTP2_STATUS_TO_GRPC_STATUS(400, GRPC_STATUS_INVALID_ARGUMENT);
  HTTP2_STATUS_TO_GRPC_STATUS(401, GRPC_STATUS_UNAUTHENTICATED);
  HTTP2_STATUS_TO_GRPC_STATUS(403, GRPC_STATUS_PERMISSION_DENIED);
  HTTP2_STATUS_TO_GRPC_STATUS(404, GRPC_STATUS_NOT_FOUND);
  HTTP2_STATUS_TO_GRPC_STATUS(409, GRPC_STATUS_ABORTED);
  HTTP2_STATUS_TO_GRPC_STATUS(412, GRPC_STATUS_FAILED_PRECONDITION);
  HTTP2_STATUS_TO_GRPC_STATUS(429, GRPC_STATUS_RESOURCE_EXHAUSTED);
  HTTP2_STATUS_TO_GRPC_STATUS(499, GRPC_STATUS_CANCELLED);
  HTTP2_STATUS_TO_GRPC_STATUS(500, GRPC_STATUS_UNKNOWN);
  HTTP2_STATUS_TO_GRPC_STATUS(503, GRPC_STATUS_UNAVAILABLE);
  HTTP2_STATUS_TO_GRPC_STATUS(504, GRPC_STATUS_DEADLINE_EXCEEDED);

  /* check all status values can be converted */
  for (i = 0; i <= 999; i++) {
    grpc_chttp2_http2_status_to_grpc_status(i);
  }

  return 0;
}
