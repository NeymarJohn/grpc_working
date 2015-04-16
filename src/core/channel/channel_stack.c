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

#include "src/core/channel/channel_stack.h"
#include <grpc/support/log.h>

#include <stdlib.h>

int grpc_trace_channel = 0;

/* Memory layouts.

   Channel stack is laid out as: {
     grpc_channel_stack stk;
     padding to GPR_MAX_ALIGNMENT
     grpc_channel_element[stk.count];
     per-filter memory, aligned to GPR_MAX_ALIGNMENT
   }

   Call stack is laid out as: {
     grpc_call_stack stk;
     padding to GPR_MAX_ALIGNMENT
     grpc_call_element[stk.count];
     per-filter memory, aligned to GPR_MAX_ALIGNMENT
   } */

/* Given a size, round up to the next multiple of sizeof(void*) */
#define ROUND_UP_TO_ALIGNMENT_SIZE(x) \
  (((x) + GPR_MAX_ALIGNMENT - 1) & ~(GPR_MAX_ALIGNMENT - 1))

size_t grpc_channel_stack_size(const grpc_channel_filter **filters,
                               size_t filter_count) {
  /* always need the header, and size for the channel elements */
  size_t size =
      ROUND_UP_TO_ALIGNMENT_SIZE(sizeof(grpc_channel_stack)) +
      ROUND_UP_TO_ALIGNMENT_SIZE(filter_count * sizeof(grpc_channel_element));
  size_t i;

  GPR_ASSERT((GPR_MAX_ALIGNMENT & (GPR_MAX_ALIGNMENT - 1)) == 0 &&
             "GPR_MAX_ALIGNMENT must be a power of two");

  /* add the size for each filter */
  for (i = 0; i < filter_count; i++) {
    size += ROUND_UP_TO_ALIGNMENT_SIZE(filters[i]->sizeof_channel_data);
  }

  return size;
}

#define CHANNEL_ELEMS_FROM_STACK(stk) \
  ((grpc_channel_element *)(          \
      (char *)(stk) + ROUND_UP_TO_ALIGNMENT_SIZE(sizeof(grpc_channel_stack))))

#define CALL_ELEMS_FROM_STACK(stk)       \
  ((grpc_call_element *)((char *)(stk) + \
                         ROUND_UP_TO_ALIGNMENT_SIZE(sizeof(grpc_call_stack))))

grpc_channel_element *grpc_channel_stack_element(
    grpc_channel_stack *channel_stack, size_t index) {
  return CHANNEL_ELEMS_FROM_STACK(channel_stack) + index;
}

grpc_channel_element *grpc_channel_stack_last_element(
    grpc_channel_stack *channel_stack) {
  return grpc_channel_stack_element(channel_stack, channel_stack->count - 1);
}

grpc_call_element *grpc_call_stack_element(grpc_call_stack *call_stack,
                                           size_t index) {
  return CALL_ELEMS_FROM_STACK(call_stack) + index;
}

void grpc_channel_stack_init(const grpc_channel_filter **filters,
                             size_t filter_count, const grpc_channel_args *args,
                             grpc_mdctx *metadata_context,
                             grpc_channel_stack *stack) {
  size_t call_size =
      ROUND_UP_TO_ALIGNMENT_SIZE(sizeof(grpc_call_stack)) +
      ROUND_UP_TO_ALIGNMENT_SIZE(filter_count * sizeof(grpc_call_element));
  grpc_channel_element *elems;
  char *user_data;
  size_t i;

  stack->count = filter_count;
  elems = CHANNEL_ELEMS_FROM_STACK(stack);
  user_data =
      ((char *)elems) +
      ROUND_UP_TO_ALIGNMENT_SIZE(filter_count * sizeof(grpc_channel_element));

  /* init per-filter data */
  for (i = 0; i < filter_count; i++) {
    elems[i].filter = filters[i];
    elems[i].channel_data = user_data;
    elems[i].filter->init_channel_elem(&elems[i], args, metadata_context,
                                       i == 0, i == (filter_count - 1));
    user_data += ROUND_UP_TO_ALIGNMENT_SIZE(filters[i]->sizeof_channel_data);
    call_size += ROUND_UP_TO_ALIGNMENT_SIZE(filters[i]->sizeof_call_data);
  }

  GPR_ASSERT(user_data > (char *)stack);
  GPR_ASSERT((gpr_uintptr)(user_data - (char *)stack) ==
             grpc_channel_stack_size(filters, filter_count));

  stack->call_stack_size = call_size;
}

void grpc_channel_stack_destroy(grpc_channel_stack *stack) {
  grpc_channel_element *channel_elems = CHANNEL_ELEMS_FROM_STACK(stack);
  size_t count = stack->count;
  size_t i;

  /* destroy per-filter data */
  for (i = 0; i < count; i++) {
    channel_elems[i].filter->destroy_channel_elem(&channel_elems[i]);
  }
}

void grpc_call_stack_init(grpc_channel_stack *channel_stack,
                          const void *transport_server_data,
                          grpc_call_stack *call_stack) {
  grpc_channel_element *channel_elems = CHANNEL_ELEMS_FROM_STACK(channel_stack);
  size_t count = channel_stack->count;
  grpc_call_element *call_elems;
  char *user_data;
  size_t i;

  call_stack->count = count;
  call_elems = CALL_ELEMS_FROM_STACK(call_stack);
  user_data = ((char *)call_elems) +
              ROUND_UP_TO_ALIGNMENT_SIZE(count * sizeof(grpc_call_element));

  /* init per-filter data */
  for (i = 0; i < count; i++) {
    call_elems[i].filter = channel_elems[i].filter;
    call_elems[i].channel_data = channel_elems[i].channel_data;
    call_elems[i].call_data = user_data;
    call_elems[i].filter->init_call_elem(&call_elems[i], transport_server_data);
    user_data +=
        ROUND_UP_TO_ALIGNMENT_SIZE(call_elems[i].filter->sizeof_call_data);
  }
}

void grpc_call_stack_destroy(grpc_call_stack *stack) {
  grpc_call_element *elems = CALL_ELEMS_FROM_STACK(stack);
  size_t count = stack->count;
  size_t i;

  /* destroy per-filter data */
  for (i = 0; i < count; i++) {
    elems[i].filter->destroy_call_elem(&elems[i]);
  }
}

void grpc_call_next_op(grpc_call_element *elem, grpc_call_op *op) {
  grpc_call_element *next_elem = elem + op->dir;
  next_elem->filter->call_op(next_elem, elem, op);
}

void grpc_channel_next_op(grpc_channel_element *elem, grpc_channel_op *op) {
  grpc_channel_element *next_elem = elem + op->dir;
  next_elem->filter->channel_op(next_elem, elem, op);
}

grpc_channel_stack *grpc_channel_stack_from_top_element(
    grpc_channel_element *elem) {
  return (grpc_channel_stack *)((char *)(elem) -
                                ROUND_UP_TO_ALIGNMENT_SIZE(
                                    sizeof(grpc_channel_stack)));
}

grpc_call_stack *grpc_call_stack_from_top_element(grpc_call_element *elem) {
  return (grpc_call_stack *)((char *)(elem) - ROUND_UP_TO_ALIGNMENT_SIZE(
                                                  sizeof(grpc_call_stack)));
}

static void do_nothing(void *user_data, grpc_op_error error) {}

void grpc_call_element_send_cancel(grpc_call_element *cur_elem) {
  grpc_call_op cancel_op;
  cancel_op.type = GRPC_CANCEL_OP;
  cancel_op.dir = GRPC_CALL_DOWN;
  cancel_op.done_cb = do_nothing;
  cancel_op.user_data = NULL;
  cancel_op.flags = 0;
  grpc_call_next_op(cur_elem, &cancel_op);
}

void grpc_call_element_send_finish(grpc_call_element *cur_elem) {
  grpc_call_op finish_op;
  finish_op.type = GRPC_SEND_FINISH;
  finish_op.dir = GRPC_CALL_DOWN;
  finish_op.done_cb = do_nothing;
  finish_op.user_data = NULL;
  finish_op.flags = 0;
  grpc_call_next_op(cur_elem, &finish_op);
}

void grpc_call_element_recv_status(grpc_call_element *cur_elem, grpc_status_code status, const char *message) {
  abort();
}

static void assert_valid_list(grpc_mdelem_list *list) {
  grpc_linked_mdelem *l;

  GPR_ASSERT((list->head == NULL) == (list->tail == NULL));
  if (!list->head) return;
  GPR_ASSERT(list->head->prev == NULL);
  GPR_ASSERT(list->tail->next == NULL);
  GPR_ASSERT((list->head == list->tail) == (list->head->next == NULL));

  for (l = list->head; l; l = l->next) {
    GPR_ASSERT((l->prev == NULL) == (l == list->head));
    GPR_ASSERT((l->next == NULL) == (l == list->tail));
    if (l->next) GPR_ASSERT(l->next->prev == l);
    if (l->prev) GPR_ASSERT(l->prev->next == l);
  }
}

void grpc_call_op_metadata_init(grpc_call_op_metadata *comd) {
  abort();
}

void grpc_call_op_metadata_destroy(grpc_call_op_metadata *comd) {
  abort();
}

void grpc_call_op_metadata_merge(grpc_call_op_metadata *target, grpc_call_op_metadata *add) {
  abort();
}

void grpc_call_op_metadata_add_head(grpc_call_op_metadata *comd, grpc_linked_mdelem *storage, grpc_mdelem *elem_to_add) {
  storage->md = elem_to_add;
  grpc_call_op_metadata_link_head(comd, storage);
}

static void link_head(grpc_mdelem_list *list, grpc_linked_mdelem *storage) {
  assert_valid_list(list);
  storage->prev = NULL;
  storage->next = list->head;
  if (list->head != NULL) {
    list->head->prev = storage;
  } else {
    list->tail = storage;
  }
  list->head = storage;
  assert_valid_list(list);
}

void grpc_call_op_metadata_link_head(grpc_call_op_metadata *comd, grpc_linked_mdelem *storage) {
  link_head(&comd->list, storage);
}

void grpc_call_op_metadata_add_tail(grpc_call_op_metadata *comd, grpc_linked_mdelem *storage, grpc_mdelem *elem_to_add) {
  storage->md = elem_to_add;
  grpc_call_op_metadata_link_tail(comd, storage);
}

static void link_tail(grpc_mdelem_list *list, grpc_linked_mdelem *storage) {
  assert_valid_list(list);
  storage->prev = list->tail;
  storage->next = NULL;
  if (list->tail != NULL) {
    list->tail->next = storage;
  } else {
    list->head = storage;
  }
  list->tail = storage;
  assert_valid_list(list);
}

void grpc_call_op_metadata_link_tail(grpc_call_op_metadata *comd, grpc_linked_mdelem *storage) {
  link_tail(&comd->list, storage);
}

void grpc_call_op_metadata_filter(grpc_call_op_metadata *comd, grpc_mdelem *(*filter)(void *user_data, grpc_mdelem *elem), void *user_data) {
  grpc_linked_mdelem *l;
  grpc_linked_mdelem *next;

  assert_valid_list(&comd->list);
  assert_valid_list(&comd->garbage);
  for (l = comd->list.head; l; l = next) {
    grpc_mdelem *orig = l->md;
    grpc_mdelem *filt = filter(user_data, orig);
    next = l->next;
    if (filt == NULL) {
      if (l->prev) {
        l->prev->next = l->next;
      }
      if (l->next) {
        l->next->prev = l->prev;
      }
      if (comd->list.head == l) {
        comd->list.head = l->next;
      }
      if (comd->list.tail == l) {
        comd->list.tail = l->prev;
      }
      assert_valid_list(&comd->list);
      link_head(&comd->garbage, l);
    } else if (filt != orig) {
      grpc_mdelem_unref(orig);
      l->md = filt;
    }
  }
  assert_valid_list(&comd->list);
  assert_valid_list(&comd->garbage);
}
