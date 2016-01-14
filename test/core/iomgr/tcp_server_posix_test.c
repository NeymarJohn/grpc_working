/*
 *
 * Copyright 2015-2016, Google Inc.
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

#include "src/core/iomgr/tcp_server.h"
#include "src/core/iomgr/iomgr.h"
#include "src/core/iomgr/sockaddr_utils.h"
#include <grpc/support/log.h>
#include <grpc/support/sync.h>
#include <grpc/support/time.h>
#include "test/core/util/test_config.h"

#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <unistd.h>

#define LOG_TEST(x) gpr_log(GPR_INFO, "%s", #x)

static grpc_pollset g_pollset;
static int g_nconnects = 0;

typedef struct on_connect_result {
  unsigned port_index;
  unsigned fd_index;
  int server_fd;
} on_connect_result;

static on_connect_result g_result = {0, 0, -1};

static void on_connect(grpc_exec_ctx *exec_ctx, void *arg, grpc_endpoint *tcp,
                       grpc_tcp_server_acceptor *acceptor) {
  grpc_endpoint_shutdown(exec_ctx, tcp);
  grpc_endpoint_destroy(exec_ctx, tcp);

  gpr_mu_lock(GRPC_POLLSET_MU(&g_pollset));
  g_result.port_index = acceptor->port_index;
  g_result.fd_index = acceptor->fd_index;
  g_result.server_fd = grpc_tcp_server_port_fd(
      acceptor->from_server, acceptor->port_index, acceptor->fd_index);
  g_nconnects++;
  grpc_pollset_kick(&g_pollset, NULL);
  gpr_mu_unlock(GRPC_POLLSET_MU(&g_pollset));
}

static void test_no_op(void) {
  grpc_exec_ctx exec_ctx = GRPC_EXEC_CTX_INIT;
  grpc_tcp_server *s = grpc_tcp_server_create(NULL);
  grpc_tcp_server_unref(&exec_ctx, s);
  grpc_exec_ctx_finish(&exec_ctx);
}

static void test_no_op_with_start(void) {
  grpc_exec_ctx exec_ctx = GRPC_EXEC_CTX_INIT;
  grpc_tcp_server *s = grpc_tcp_server_create(NULL);
  LOG_TEST("test_no_op_with_start");
  grpc_tcp_server_start(&exec_ctx, s, NULL, 0, on_connect, NULL);
  grpc_tcp_server_unref(&exec_ctx, s);
  grpc_exec_ctx_finish(&exec_ctx);
}

static void test_no_op_with_port(void) {
  grpc_exec_ctx exec_ctx = GRPC_EXEC_CTX_INIT;
  struct sockaddr_in addr;
  grpc_tcp_server *s = grpc_tcp_server_create(NULL);
  LOG_TEST("test_no_op_with_port");

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  GPR_ASSERT(
      grpc_tcp_server_add_port(s, (struct sockaddr *)&addr, sizeof(addr)) > 0);

  grpc_tcp_server_unref(&exec_ctx, s);
  grpc_exec_ctx_finish(&exec_ctx);
}

static void test_no_op_with_port_and_start(void) {
  grpc_exec_ctx exec_ctx = GRPC_EXEC_CTX_INIT;
  struct sockaddr_in addr;
  grpc_tcp_server *s = grpc_tcp_server_create(NULL);
  LOG_TEST("test_no_op_with_port_and_start");

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  GPR_ASSERT(
      grpc_tcp_server_add_port(s, (struct sockaddr *)&addr, sizeof(addr)) > 0);

  grpc_tcp_server_start(&exec_ctx, s, NULL, 0, on_connect, NULL);

  grpc_tcp_server_unref(&exec_ctx, s);
  grpc_exec_ctx_finish(&exec_ctx);
}

static void tcp_connect(grpc_exec_ctx *exec_ctx, const struct sockaddr *remote,
                        socklen_t remote_len, on_connect_result *result) {
  gpr_timespec deadline = GRPC_TIMEOUT_SECONDS_TO_DEADLINE(10);
  int clifd = socket(remote->sa_family, SOCK_STREAM, 0);
  int nconnects_before;

  gpr_mu_lock(GRPC_POLLSET_MU(&g_pollset));
  nconnects_before = g_nconnects;
  g_result.server_fd = -1;
  GPR_ASSERT(clifd >= 0);
  gpr_log(GPR_DEBUG, "start connect");
  GPR_ASSERT(connect(clifd, remote, remote_len) == 0);
  gpr_log(GPR_DEBUG, "wait");
  while (g_nconnects == nconnects_before &&
         gpr_time_cmp(deadline, gpr_now(deadline.clock_type)) > 0) {
    grpc_pollset_worker worker;
    grpc_pollset_work(exec_ctx, &g_pollset, &worker,
                      gpr_now(GPR_CLOCK_MONOTONIC), deadline);
    gpr_mu_unlock(GRPC_POLLSET_MU(&g_pollset));
    grpc_exec_ctx_finish(exec_ctx);
    gpr_mu_lock(GRPC_POLLSET_MU(&g_pollset));
  }
  gpr_log(GPR_DEBUG, "wait done");
  GPR_ASSERT(g_nconnects == nconnects_before + 1);
  close(clifd);
  *result = g_result;

  gpr_mu_unlock(GRPC_POLLSET_MU(&g_pollset));
}

/* grpc_tcp_server_add_port() will not pick a second port randomly. We must find
   one by binding one randomly, closing the socket, and returning the port
   number. This might fail because of races. */
static int unused_port() {
  int s = socket(AF_INET, SOCK_STREAM, 0);
  struct sockaddr_storage addr;
  socklen_t addr_len = sizeof(addr);
  GPR_ASSERT(s >= 0);
  memset(&addr, 0, sizeof(addr));
  addr.ss_family = AF_INET;
  if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
    gpr_log(GPR_ERROR, "bind: %s", strerror(errno));
    abort();
  }
  GPR_ASSERT(getsockname(s, (struct sockaddr *)&addr, &addr_len) == 0);
  GPR_ASSERT(addr_len <= sizeof(addr));
  close(s);
  return ntohs(((struct sockaddr_in *)&addr)->sin_port);
}

/* Tests a tcp server with multiple ports. TODO(daniel-j-born): Multiple fds for
   the same port should be tested. */
static void test_connect(unsigned n) {
  grpc_exec_ctx exec_ctx = GRPC_EXEC_CTX_INIT;
  struct sockaddr_storage addr;
  struct sockaddr_storage addr1;
  socklen_t addr_len = sizeof(addr);
  unsigned svr_fd_count;
  int svr_port;
  unsigned svr1_fd_count;
  int svr1_port;
  grpc_tcp_server *s = grpc_tcp_server_create(NULL);
  grpc_pollset *pollsets[1];
  unsigned i;
  LOG_TEST("test_connect");
  gpr_log(GPR_INFO, "clients=%d", n);
  memset(&addr, 0, sizeof(addr));
  memset(&addr1, 0, sizeof(addr1));
  addr.ss_family = addr1.ss_family = AF_INET;
  svr_port = grpc_tcp_server_add_port(s, (struct sockaddr *)&addr, addr_len);
  GPR_ASSERT(svr_port > 0);
  svr1_port = unused_port();
  grpc_sockaddr_set_port((struct sockaddr *)&addr1, svr1_port);
  GPR_ASSERT(grpc_tcp_server_add_port(s, (struct sockaddr *)&addr1, addr_len) ==
             svr1_port);

  /* Bad port_index. */
  GPR_ASSERT(grpc_tcp_server_port_fd_count(s, 2) == 0);
  GPR_ASSERT(grpc_tcp_server_port_fd(s, 2, 0) < 0);

  /* Bad fd_index. */
  GPR_ASSERT(grpc_tcp_server_port_fd(s, 0, 100) < 0);
  GPR_ASSERT(grpc_tcp_server_port_fd(s, 1, 100) < 0);

  /* Got at least one fd per port. */
  svr_fd_count = grpc_tcp_server_port_fd_count(s, 0);
  GPR_ASSERT(svr_fd_count >= 1);
  svr1_fd_count = grpc_tcp_server_port_fd_count(s, 1);
  GPR_ASSERT(svr1_fd_count >= 1);

  for (i = 0; i < svr_fd_count; ++i) {
    int fd = grpc_tcp_server_port_fd(s, 0, i);
    GPR_ASSERT(fd >= 0);
    if (i == 0) {
      GPR_ASSERT(getsockname(fd, (struct sockaddr *)&addr, &addr_len) == 0);
      GPR_ASSERT(addr_len <= sizeof(addr));
    }
  }
  for (i = 0; i < svr1_fd_count; ++i) {
    int fd = grpc_tcp_server_port_fd(s, 1, i);
    GPR_ASSERT(fd >= 0);
    if (i == 0) {
      GPR_ASSERT(getsockname(fd, (struct sockaddr *)&addr1, &addr_len) == 0);
      GPR_ASSERT(addr_len <= sizeof(addr1));
    }
  }

  pollsets[0] = &g_pollset;
  grpc_tcp_server_start(&exec_ctx, s, pollsets, 1, on_connect, NULL);

  for (i = 0; i < n; i++) {
    on_connect_result result = {0, 0, -1};
    int svr_fd;
    tcp_connect(&exec_ctx, (struct sockaddr *)&addr, addr_len, &result);
    GPR_ASSERT(result.server_fd >= 0);
    svr_fd = result.server_fd;
    GPR_ASSERT(grpc_tcp_server_port_fd(s, result.port_index, result.fd_index) ==
               result.server_fd);
    GPR_ASSERT(result.port_index == 0);
    GPR_ASSERT(result.fd_index < svr_fd_count);

    result.port_index = 0;
    result.fd_index = 0;
    result.server_fd = -1;
    tcp_connect(&exec_ctx, (struct sockaddr *)&addr1, addr_len, &result);
    GPR_ASSERT(result.server_fd >= 0);
    GPR_ASSERT(result.server_fd != svr_fd);
    GPR_ASSERT(grpc_tcp_server_port_fd(s, result.port_index, result.fd_index) ==
               result.server_fd);
    GPR_ASSERT(result.port_index == 1);
    GPR_ASSERT(result.fd_index < svr_fd_count);
  }

  grpc_tcp_server_unref(&exec_ctx, s);
  grpc_exec_ctx_finish(&exec_ctx);
}

static void destroy_pollset(grpc_exec_ctx *exec_ctx, void *p, int success) {
  grpc_pollset_destroy(p);
}

int main(int argc, char **argv) {
  grpc_closure destroyed;
  grpc_exec_ctx exec_ctx = GRPC_EXEC_CTX_INIT;
  grpc_test_init(argc, argv);
  grpc_iomgr_init();
  grpc_pollset_init(&g_pollset);

  test_no_op();
  test_no_op_with_start();
  test_no_op_with_port();
  test_no_op_with_port_and_start();
  test_connect(1);
  test_connect(10);

  grpc_closure_init(&destroyed, destroy_pollset, &g_pollset);
  grpc_pollset_shutdown(&exec_ctx, &g_pollset, &destroyed);
  grpc_exec_ctx_finish(&exec_ctx);
  grpc_iomgr_shutdown();
  return 0;
}
