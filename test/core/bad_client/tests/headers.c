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

#include "test/core/bad_client/bad_client.h"
#include "src/core/surface/server.h"

#define PFX_STR                      \
  "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n" \
  "\x00\x00\x00\x04\x00\x00\x00\x00\x00"

static void verifier(grpc_server *server, grpc_completion_queue *cq) {
  while (grpc_server_has_open_connections(server)) {
    GPR_ASSERT(grpc_completion_queue_next(
                   cq, GRPC_TIMEOUT_MILLIS_TO_DEADLINE(20), NULL)
                   .type == GRPC_QUEUE_TIMEOUT);
  }
}

int main(int argc, char **argv) {
  grpc_test_init(argc, argv);

  /* partial http2 header prefixes */
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00\x01",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00\x01\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00\x01\x04",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00\x01\x05",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00\x01\x04\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00\x01\x04\x00\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR "\x00\x00\x00\x01\x04\x00\x00\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR "\x00\x00\x00\x01\x04\x00\x00\x00\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR "\x00\x00\x00\x01\x04\x00\x00\x00\x01",
                           GRPC_BAD_CLIENT_DISCONNECT);

  /* test adding prioritization data */
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x01\x01\x24\x00\x00\x00\x01"
                           "\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x02\x01\x24\x00\x00\x00\x01"
                           "\x00\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x03\x01\x24\x00\x00\x00\x01"
                           "\x00\x00\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x04\x01\x24\x00\x00\x00\x01"
                           "\x00\x00\x00\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x05\x01\x24\x00\x00\x00\x01"
                           "\x00\x00\x00\x00\x00",
                           GRPC_BAD_CLIENT_DISCONNECT);

  /* test looking up an invalid index */
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x01\x01\x04\x00\x00\x00\x01"
                           "\xfe",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x04\x01\x04\x00\x00\x00\x01"
                           "\x7f\x7f\x01a",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x04\x01\x04\x00\x00\x00\x01"
                           "\x0f\x7f\x01a",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x04\x01\x04\x00\x00\x00\x01"
                           "\x1f\x7f\x01a",
                           0);
  /* test nvr, not indexed in static table */
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x03\x01\x04\x00\x00\x00\x01"
                           "\x01\x01a",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x03\x01\x04\x00\x00\x00\x01"
                           "\x11\x01a",
                           GRPC_BAD_CLIENT_DISCONNECT);
  /* illegal op code */
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x01\x01\x04\x00\x00\x00\x01"
                           "\x80",
                           0);
  /* parse some long indices */
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x02\x01\x04\x00\x00\x00\x01"
                           "\xff\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x03\x01\x04\x00\x00\x00\x01"
                           "\xff\x80\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x04\x01\x04\x00\x00\x00\x01"
                           "\xff\x80\x80\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x05\x01\x04\x00\x00\x00\x01"
                           "\xff\x80\x80\x80\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x06\x01\x04\x00\x00\x00\x01"
                           "\xff\x80\x80\x80\x80\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x07\x01\x04\x00\x00\x00\x01"
                           "\xff\x80\x80\x80\x80\x80\x00",
                           0);
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x08\x01\x04\x00\x00\x00\x01"
                           "\xff\x80\x80\x80\x80\x80\x80\x00",
                           0);
  /* end of headers mid-opcode */
  GRPC_RUN_BAD_CLIENT_TEST(verifier, PFX_STR
                           "\x00\x00\x01\x01\x04\x00\x00\x00\x01"
                           "\x01",
                           GRPC_BAD_CLIENT_DISCONNECT);

  /* dynamic table size update: set to default */
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR 
                           "\x00\x00\x03\x01\x04\x00\x00\x00\x01"
                           "\x3f\xe1\x1f",
                           GRPC_BAD_CLIENT_DISCONNECT);
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR 
                           "\x00\x00\x03\x01\x04\x00\x00\x00\x01"
                           "\x3f\xf1\x1f",
                           0);

  /* non-ending header followed by continuation frame */
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR 
                           "\x00\x00\x00\x01\x00\x00\x00\x00\x01"
                           "\x00\x00\x00\x09\x04\x00\x00\x00\x01",
                           GRPC_BAD_CLIENT_DISCONNECT);
  /* non-ending header followed by non-continuation frame */
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR 
                           "\x00\x00\x00\x01\x00\x00\x00\x00\x01"
                           "\x00\x00\x00\x00\x04\x00\x00\x00\x01",
                           0);
  /* opening with a continuation frame */
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR 
                           "\x00\x00\x00\x09\x04\x00\x00\x00\x01",
                           0);

  /* an invalid header found with fuzzing */
  GRPC_RUN_BAD_CLIENT_TEST(verifier,
                           PFX_STR 
                           "\x00\x00\x00\x01\x39\x67\xed\x1d\x64",
                           GRPC_BAD_CLIENT_DISCONNECT);

  return 0;
}
