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

#include "src/core/transport/connectivity_state.h"

#include <string.h>

#include <grpc/support/alloc.h>
#include <grpc/support/log.h>
#include <grpc/support/string_util.h>

int grpc_connectivity_state_trace = 0;

const char *grpc_connectivity_state_name(grpc_connectivity_state state) {
  switch (state) {
    case GRPC_CHANNEL_IDLE:
      return "IDLE";
    case GRPC_CHANNEL_CONNECTING:
      return "CONNECTING";
    case GRPC_CHANNEL_READY:
      return "READY";
    case GRPC_CHANNEL_TRANSIENT_FAILURE:
      return "TRANSIENT_FAILURE";
    case GRPC_CHANNEL_FATAL_FAILURE:
      return "FATAL_FAILURE";
  }
  abort();
  return "UNKNOWN";
}

void grpc_connectivity_state_init(grpc_connectivity_state_tracker *tracker,
                                  grpc_connectivity_state init_state,
                                  const char *name) {
  tracker->current_state = init_state;
  tracker->watchers = NULL;
  tracker->name = gpr_strdup(name);
  tracker->changed = 0;
}

void grpc_connectivity_state_destroy(grpc_connectivity_state_tracker *tracker) {
  int success;
  grpc_connectivity_state_watcher *w;
  while ((w = tracker->watchers)) {
    tracker->watchers = w->next;

    if (GRPC_CHANNEL_FATAL_FAILURE != *w->current) {
      *w->current = GRPC_CHANNEL_FATAL_FAILURE;
      success = 1;
    } else {
      success = 0;
    }
    w->notify->cb(w->notify->cb_arg, success);
    gpr_free(w);
  }
  gpr_free(tracker->name);
}

grpc_connectivity_state grpc_connectivity_state_check(
    grpc_connectivity_state_tracker *tracker) {
  return tracker->current_state;
}

grpc_connectivity_state_notify_on_state_change_result
grpc_connectivity_state_notify_on_state_change(
    grpc_connectivity_state_tracker *tracker, grpc_connectivity_state *current,
    grpc_iomgr_closure *notify) {
  grpc_connectivity_state_notify_on_state_change_result result;
  memset(&result, 0, sizeof(result));
  if (grpc_connectivity_state_trace) {
    gpr_log(GPR_DEBUG, "CONWATCH: %s: from %s [cur=%s]", tracker->name,
            grpc_connectivity_state_name(*current),
            grpc_connectivity_state_name(tracker->current_state));
  }
  if (tracker->current_state != *current) {
    *current = tracker->current_state;
    result.state_already_changed = 1;
  } else {
    grpc_connectivity_state_watcher *w = gpr_malloc(sizeof(*w));
    w->current = current;
    w->notify = notify;
    w->next = tracker->watchers;
    tracker->watchers = w;
  }
  result.current_state_is_idle = tracker->current_state == GRPC_CHANNEL_IDLE;
  return result;
}

void grpc_connectivity_state_set(grpc_connectivity_state_tracker *tracker,
                                 grpc_connectivity_state state,
                                 const char *reason) {
  if (grpc_connectivity_state_trace) {
    gpr_log(GPR_DEBUG, "SET: %s: %s --> %s [%s]", tracker->name,
            grpc_connectivity_state_name(tracker->current_state),
            grpc_connectivity_state_name(state), reason);
  }
  if (tracker->current_state == state) {
    return;
  }
  GPR_ASSERT(tracker->current_state != GRPC_CHANNEL_FATAL_FAILURE);
  tracker->current_state = state;
  tracker->changed = 1;
}

void grpc_connectivity_state_begin_flush(
    grpc_connectivity_state_tracker *tracker,
    grpc_connectivity_state_flusher *flusher) {
  grpc_connectivity_state_watcher *w;
  flusher->cbs = NULL;
  if (!tracker->changed) return;
  w = tracker->watchers;
  tracker->watchers = NULL;
  while (w != NULL) {
    grpc_connectivity_state_watcher *next = w->next;
    if (tracker->current_state != *w->current) {
      *w->current = tracker->current_state;
      w->notify->next = flusher->cbs;
      flusher->cbs = w->notify;
      gpr_free(w);
    } else {
      w->next = tracker->watchers;
      tracker->watchers = w;
    }
    w = next;
  }
  tracker->changed = 0;
}

void grpc_connectivity_state_end_flush(
    grpc_connectivity_state_flusher *flusher) {
  grpc_iomgr_closure *c = flusher->cbs;
  while (c != NULL) {
    grpc_iomgr_closure *next = c;
    c->cb(c->cb_arg, 1);
    c = next;
  }
}

