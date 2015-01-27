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

#include "src/core/transport/chttp2/stream_encoder.h"

#include <stdio.h>

#include "src/core/support/string.h"
#include "src/core/transport/chttp2/hpack_parser.h"
#include <grpc/support/alloc.h>
#include <grpc/support/log.h>
#include "test/core/util/parse_hexstring.h"
#include "test/core/util/slice_splitter.h"
#include "test/core/util/test_config.h"

#define TEST(x) run_test(x, #x)

grpc_mdctx *g_mdctx;
grpc_chttp2_hpack_compressor g_compressor;
int g_failure = 0;
grpc_stream_op_buffer g_sopb;

static gpr_slice create_test_slice(size_t length) {
  gpr_slice slice = gpr_slice_malloc(length);
  size_t i;
  for (i = 0; i < length; i++) {
    GPR_SLICE_START_PTR(slice)[i] = i;
  }
  return slice;
}

/* verify that the output generated by encoding the stream matches the
   hexstring passed in */
static void verify_sopb(size_t window_available, int eof,
                        size_t expect_window_used, const char *expected) {
  gpr_slice_buffer output;
  grpc_stream_op_buffer encops;
  gpr_slice merged;
  gpr_slice expect = parse_hexstring(expected);
  gpr_slice_buffer_init(&output);
  grpc_sopb_init(&encops);
  GPR_ASSERT(expect_window_used ==
             grpc_chttp2_preencode(g_sopb.ops, &g_sopb.nops, window_available,
                                   &encops));
  grpc_chttp2_encode(encops.ops, encops.nops, eof, 0xdeadbeef, &g_compressor,
                     &output);
  encops.nops = 0;
  merged = grpc_slice_merge(output.slices, output.count);
  gpr_slice_buffer_destroy(&output);
  grpc_sopb_destroy(&encops);

  if (0 != gpr_slice_cmp(merged, expect)) {
    char *expect_str =
        gpr_hexdump((char *)GPR_SLICE_START_PTR(expect),
                    GPR_SLICE_LENGTH(expect), GPR_HEXDUMP_PLAINTEXT);
    char *got_str =
        gpr_hexdump((char *)GPR_SLICE_START_PTR(merged),
                    GPR_SLICE_LENGTH(merged), GPR_HEXDUMP_PLAINTEXT);
    gpr_log(GPR_ERROR, "mismatched output for %s", expected);
    gpr_log(GPR_ERROR, "EXPECT: %s", expect_str);
    gpr_log(GPR_ERROR, "GOT:    %s", got_str);
    gpr_free(expect_str);
    gpr_free(got_str);
    g_failure = 1;
  }

  gpr_slice_unref(merged);
  gpr_slice_unref(expect);
}

static void assert_result_ok(void *user_data, grpc_op_error error) {
  GPR_ASSERT(error == GRPC_OP_OK);
}

static void test_small_data_framing(void) {
  grpc_sopb_add_no_op(&g_sopb);
  verify_sopb(10, 0, 0, "");

  grpc_sopb_add_flow_ctl_cb(&g_sopb, assert_result_ok, NULL);
  grpc_sopb_add_slice(&g_sopb, create_test_slice(3));
  verify_sopb(10, 0, 3, "000003 0000 deadbeef 000102");

  grpc_sopb_add_slice(&g_sopb, create_test_slice(4));
  verify_sopb(10, 0, 4, "000004 0000 deadbeef 00010203");

  grpc_sopb_add_slice(&g_sopb, create_test_slice(3));
  grpc_sopb_add_slice(&g_sopb, create_test_slice(4));
  verify_sopb(10, 0, 7, "000007 0000 deadbeef 000102 00010203");

  grpc_sopb_add_slice(&g_sopb, create_test_slice(0));
  grpc_sopb_add_slice(&g_sopb, create_test_slice(0));
  grpc_sopb_add_slice(&g_sopb, create_test_slice(0));
  grpc_sopb_add_slice(&g_sopb, create_test_slice(0));
  grpc_sopb_add_slice(&g_sopb, create_test_slice(3));
  verify_sopb(10, 0, 3, "000003 0000 deadbeef 000102");

  verify_sopb(10, 1, 0, "000000 0001 deadbeef");

  grpc_sopb_add_begin_message(&g_sopb, 255, 0);
  verify_sopb(10, 0, 5, "000005 0000 deadbeef 00000000ff");
}

static void add_sopb_header(const char *key, const char *value) {
  grpc_sopb_add_metadata(&g_sopb,
                         grpc_mdelem_from_strings(g_mdctx, key, value));
}

static void test_basic_headers(void) {
  int i;

  add_sopb_header("a", "a");
  verify_sopb(0, 0, 0, "000005 0104 deadbeef 40 0161 0161");

  add_sopb_header("a", "a");
  verify_sopb(0, 0, 0, "000001 0104 deadbeef be");

  add_sopb_header("a", "a");
  verify_sopb(0, 0, 0, "000001 0104 deadbeef be");

  add_sopb_header("a", "a");
  add_sopb_header("b", "c");
  verify_sopb(0, 0, 0, "000006 0104 deadbeef be 40 0162 0163");

  add_sopb_header("a", "a");
  add_sopb_header("b", "c");
  verify_sopb(0, 0, 0, "000002 0104 deadbeef bf be");

  add_sopb_header("a", "d");
  verify_sopb(0, 0, 0, "000004 0104 deadbeef 7f 00 0164");

  /* flush out what's there to make a few values look very popular */
  for (i = 0; i < 350; i++) {
    add_sopb_header("a", "a");
    add_sopb_header("b", "c");
    add_sopb_header("a", "d");
    verify_sopb(0, 0, 0, "000003 0104 deadbeef c0 bf be");
  }

  add_sopb_header("a", "a");
  add_sopb_header("k", "v");
  verify_sopb(0, 0, 0, "000006 0104 deadbeef c0 00 016b 0176");

  add_sopb_header("a", "v");
  /* this could be      000004 0104 deadbeef 0f 30 0176 also */
  verify_sopb(0, 0, 0, "000004 0104 deadbeef 0f 2f 0176");
}

static void encode_int_to_str(int i, char *p) {
  p[0] = 'a' + i % 26;
  i /= 26;
  GPR_ASSERT(i < 26);
  p[1] = 'a' + i;
  p[2] = 0;
}

static void test_decode_table_overflow(void) {
  int i;
  char key[3], value[3];
  char expect[128];

  for (i = 0; i < 114; i++) {
    if (i > 0) {
      add_sopb_header("aa", "ba");
    }

    encode_int_to_str(i, key);
    encode_int_to_str(i + 1, value);

    if (i + 61 >= 127) {
      sprintf(expect, "000009 0104 deadbeef ff%02x 40 02%02x%02x 02%02x%02x",
              i + 61 - 127, key[0], key[1], value[0], value[1]);
    } else if (i > 0) {
      sprintf(expect, "000008 0104 deadbeef %02x 40 02%02x%02x 02%02x%02x",
              0x80 + 61 + i, key[0], key[1], value[0], value[1]);
    } else {
      sprintf(expect, "000007 0104 deadbeef 40 02%02x%02x 02%02x%02x", key[0],
              key[1], value[0], value[1]);
    }

    add_sopb_header(key, value);
    verify_sopb(0, 0, 0, expect);
  }

  /* if the above passes, then we must have just knocked this pair out of the
     decoder stack, and so we'll be forced to re-encode it */
  add_sopb_header("aa", "ba");
  verify_sopb(0, 0, 0, "000007 0104 deadbeef 40 026161 026261");
}

static void randstr(char *p, int bufsz) {
  int i;
  int len = 1 + rand() % bufsz;
  for (i = 0; i < len; i++) {
    p[i] = 'a' + rand() % 26;
  }
  p[len] = 0;
}

typedef struct {
  char key[300];
  char value[300];
  int got_hdr;
} test_decode_random_header_state;

static void chk_hdr(void *p, grpc_mdelem *el) {
  test_decode_random_header_state *st = p;
  GPR_ASSERT(0 == gpr_slice_str_cmp(el->key->slice, st->key));
  GPR_ASSERT(0 == gpr_slice_str_cmp(el->value->slice, st->value));
  st->got_hdr = 1;
  grpc_mdelem_unref(el);
}

static void test_decode_random_headers_inner(int max_len) {
  int i;
  test_decode_random_header_state st;
  gpr_slice_buffer output;
  gpr_slice merged;
  grpc_stream_op_buffer encops;
  grpc_chttp2_hpack_parser parser;

  grpc_chttp2_hpack_parser_init(&parser, g_mdctx);
  grpc_sopb_init(&encops);

  gpr_log(GPR_INFO, "max_len = %d", max_len);

  for (i = 0; i < 10000; i++) {
    randstr(st.key, max_len);
    randstr(st.value, max_len);

    add_sopb_header(st.key, st.value);
    gpr_slice_buffer_init(&output);
    GPR_ASSERT(0 ==
               grpc_chttp2_preencode(g_sopb.ops, &g_sopb.nops, 0, &encops));
    grpc_chttp2_encode(encops.ops, encops.nops, 0, 0xdeadbeef, &g_compressor,
                       &output);
    encops.nops = 0;
    merged = grpc_slice_merge(output.slices, output.count);
    gpr_slice_buffer_destroy(&output);

    st.got_hdr = 0;
    parser.on_header = chk_hdr;
    parser.on_header_user_data = &st;
    grpc_chttp2_hpack_parser_parse(&parser, GPR_SLICE_START_PTR(merged) + 9,
                                   GPR_SLICE_END_PTR(merged));
    GPR_ASSERT(st.got_hdr);

    gpr_slice_unref(merged);
  }

  grpc_chttp2_hpack_parser_destroy(&parser);
  grpc_sopb_destroy(&encops);
}

#define DECL_TEST_DECODE_RANDOM_HEADERS(n)           \
  static void test_decode_random_headers_##n(void) { \
    test_decode_random_headers_inner(n);             \
  }                                                  \
  int keeps_formatting_correct_##n

DECL_TEST_DECODE_RANDOM_HEADERS(1);
DECL_TEST_DECODE_RANDOM_HEADERS(2);
DECL_TEST_DECODE_RANDOM_HEADERS(3);
DECL_TEST_DECODE_RANDOM_HEADERS(5);
DECL_TEST_DECODE_RANDOM_HEADERS(8);
DECL_TEST_DECODE_RANDOM_HEADERS(13);
DECL_TEST_DECODE_RANDOM_HEADERS(21);
DECL_TEST_DECODE_RANDOM_HEADERS(34);
DECL_TEST_DECODE_RANDOM_HEADERS(55);
DECL_TEST_DECODE_RANDOM_HEADERS(89);
DECL_TEST_DECODE_RANDOM_HEADERS(144);

static void run_test(void (*test)(), const char *name) {
  gpr_log(GPR_INFO, "RUN TEST: %s", name);
  g_mdctx = grpc_mdctx_create_with_seed(0);
  grpc_chttp2_hpack_compressor_init(&g_compressor, g_mdctx);
  grpc_sopb_init(&g_sopb);
  test();
  grpc_chttp2_hpack_compressor_destroy(&g_compressor);
  grpc_mdctx_orphan(g_mdctx);
  grpc_sopb_destroy(&g_sopb);
}

int main(int argc, char **argv) {
  grpc_test_init(argc, argv);
  TEST(test_small_data_framing);
  TEST(test_basic_headers);
  TEST(test_decode_table_overflow);
  TEST(test_decode_random_headers_1);
  TEST(test_decode_random_headers_2);
  TEST(test_decode_random_headers_3);
  TEST(test_decode_random_headers_5);
  TEST(test_decode_random_headers_8);
  TEST(test_decode_random_headers_13);
  TEST(test_decode_random_headers_21);
  TEST(test_decode_random_headers_34);
  TEST(test_decode_random_headers_55);
  TEST(test_decode_random_headers_89);
  TEST(test_decode_random_headers_144);
  return g_failure;
}
