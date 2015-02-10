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

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200112L
#endif

#define _GNU_SOURCE
#include <grpc/support/port_platform.h>

#if defined(GPR_POSIX_LOG)

#include <grpc/support/alloc.h>
#include <grpc/support/log.h>
#include <grpc/support/time.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <pthread.h>

static gpr_intptr gettid(void) { return (gpr_intptr)pthread_self(); }

void gpr_log(const char *file, int line, gpr_log_severity severity,
             const char *format, ...) {
  char buf[64];
  char *allocated = NULL;
  char *message = NULL;
  int ret;
  va_list args;
  va_start(args, format);
  ret = vsnprintf(buf, sizeof(buf), format, args);
  va_end(args);
  if (ret < 0) {
    message = NULL;
  } else if ((size_t)ret <= sizeof(buf) - 1) {
    message = buf;
  } else {
    message = allocated = gpr_malloc(ret + 1);
    va_start(args, format);
    vsnprintf(message, ret, format, args);
    va_end(args);
  }
  gpr_log_message(file, line, severity, message);
  gpr_free(allocated);
}

void gpr_default_log(gpr_log_func_args *args) {
  char *final_slash;
  const char *display_file;
  char time_buffer[64];
  gpr_timespec now = gpr_now();
  struct tm tm;

  final_slash = strrchr(args->file, '/');
  if (final_slash == NULL)
    display_file = args->file;
  else
    display_file = final_slash + 1;

  if (!localtime_r(&now.tv_sec, &tm)) {
    strcpy(time_buffer, "error:localtime");
  } else if (0 ==
             strftime(time_buffer, sizeof(time_buffer), "%m%d %H:%M:%S", &tm)) {
    strcpy(time_buffer, "error:strftime");
  }

  fprintf(stderr, "%s%s.%09d %7tu %s:%d] %s\n",
          gpr_log_severity_string(args->severity), time_buffer,
          (int)(now.tv_nsec), gettid(), display_file, args->line,
          args->message);
}

#endif /* defined(GPR_POSIX_LOG) */
