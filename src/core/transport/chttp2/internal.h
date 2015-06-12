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

#ifndef GRPC_INTERNAL_CORE_CHTTP2_INTERNAL_H
#define GRPC_INTERNAL_CORE_CHTTP2_INTERNAL_H

#include "src/core/transport/transport_impl.h"
#include "src/core/iomgr/endpoint.h"
#include "src/core/transport/chttp2/frame.h"
#include "src/core/transport/chttp2/frame_data.h"
#include "src/core/transport/chttp2/frame_goaway.h"
#include "src/core/transport/chttp2/frame_ping.h"
#include "src/core/transport/chttp2/frame_rst_stream.h"
#include "src/core/transport/chttp2/frame_settings.h"
#include "src/core/transport/chttp2/frame_window_update.h"
#include "src/core/transport/chttp2/stream_map.h"
#include "src/core/transport/chttp2/hpack_parser.h"
#include "src/core/transport/chttp2/stream_encoder.h"

typedef struct grpc_chttp2_transport grpc_chttp2_transport;
typedef struct grpc_chttp2_stream grpc_chttp2_stream;

/* streams are kept in various linked lists depending on what things need to
   happen to them... this enum labels each list */
typedef enum {
  /* streams that have pending writes */
  WRITABLE = 0,
  /* streams that have been selected to be written */
  WRITING,
  /* streams that have just been written, and included a close */
  WRITTEN_CLOSED,
  /* streams that have been cancelled and have some pending state updates
     to perform */
  CANCELLED,
  /* streams that want to send window updates */
  WINDOW_UPDATE,
  /* streams that are waiting to start because there are too many concurrent
     streams on the connection */
  WAITING_FOR_CONCURRENCY,
  /* streams that have finished reading: we wait until unlock to coalesce
     all changes into one callback */
  FINISHED_READ_OP,
  MAYBE_FINISH_READ_AFTER_PARSE,
  PARSER_CHECK_WINDOW_UPDATES_AFTER_PARSE,
  OTHER_CHECK_WINDOW_UPDATES_AFTER_PARSE,
  NEW_OUTGOING_WINDOW,
  STREAM_LIST_COUNT /* must be last */
} grpc_chttp2_stream_list_id;

/* deframer state for the overall http2 stream of bytes */
typedef enum {
  /* prefix: one entry per http2 connection prefix byte */
  DTS_CLIENT_PREFIX_0 = 0,
  DTS_CLIENT_PREFIX_1,
  DTS_CLIENT_PREFIX_2,
  DTS_CLIENT_PREFIX_3,
  DTS_CLIENT_PREFIX_4,
  DTS_CLIENT_PREFIX_5,
  DTS_CLIENT_PREFIX_6,
  DTS_CLIENT_PREFIX_7,
  DTS_CLIENT_PREFIX_8,
  DTS_CLIENT_PREFIX_9,
  DTS_CLIENT_PREFIX_10,
  DTS_CLIENT_PREFIX_11,
  DTS_CLIENT_PREFIX_12,
  DTS_CLIENT_PREFIX_13,
  DTS_CLIENT_PREFIX_14,
  DTS_CLIENT_PREFIX_15,
  DTS_CLIENT_PREFIX_16,
  DTS_CLIENT_PREFIX_17,
  DTS_CLIENT_PREFIX_18,
  DTS_CLIENT_PREFIX_19,
  DTS_CLIENT_PREFIX_20,
  DTS_CLIENT_PREFIX_21,
  DTS_CLIENT_PREFIX_22,
  DTS_CLIENT_PREFIX_23,
  /* frame header byte 0... */
  /* must follow from the prefix states */
  DTS_FH_0,
  DTS_FH_1,
  DTS_FH_2,
  DTS_FH_3,
  DTS_FH_4,
  DTS_FH_5,
  DTS_FH_6,
  DTS_FH_7,
  /* ... frame header byte 8 */
  DTS_FH_8,
  /* inside a http2 frame */
  DTS_FRAME
} grpc_chttp2_deframe_transport_state;

typedef enum {
  WRITE_STATE_OPEN,
  WRITE_STATE_QUEUED_CLOSE,
  WRITE_STATE_SENT_CLOSE
} grpc_chttp2_write_state;

typedef enum {
  DONT_SEND_CLOSED = 0,
  SEND_CLOSED,
  SEND_CLOSED_WITH_RST_STREAM
} grpc_chttp2_send_closed;

typedef struct {
  grpc_chttp2_stream *head;
  grpc_chttp2_stream *tail;
} grpc_chttp2_stream_list;

typedef struct {
  grpc_chttp2_stream *next;
  grpc_chttp2_stream *prev;
} grpc_chttp2_stream_link;

typedef enum {
  ERROR_STATE_NONE,
  ERROR_STATE_SEEN,
  ERROR_STATE_NOTIFIED
} grpc_chttp2_error_state;

/* We keep several sets of connection wide parameters */
typedef enum {
  /* The settings our peer has asked for (and we have acked) */
  PEER_SETTINGS = 0,
  /* The settings we'd like to have */
  LOCAL_SETTINGS,
  /* The settings we've published to our peer */
  SENT_SETTINGS,
  /* The settings the peer has acked */
  ACKED_SETTINGS,
  NUM_SETTING_SETS
} grpc_chttp2_setting_set;

/* Outstanding ping request data */
typedef struct {
  gpr_uint8 id[8];
  void (*cb)(void *user_data);
  void *user_data;
} grpc_chttp2_outstanding_ping;

typedef struct {
  grpc_status_code status;
  gpr_slice debug;
} grpc_chttp2_pending_goaway;

typedef struct {
  /** data to write next write */
  gpr_slice_buffer qbuf;
  /** queued callbacks */
  grpc_iomgr_closure *pending_closures;

  /** window available for us to send to peer */
  gpr_uint32 outgoing_window;
  /** how much window would we like to have for incoming_window */
  gpr_uint32 connection_window_target;


  /** are the local settings dirty and need to be sent? */
  gpr_uint8 dirtied_local_settings;
  /** have local settings been sent? */
  gpr_uint8 sent_local_settings;
  /** bitmask of setting indexes to send out */
  gpr_uint32 force_send_settings;   
  /** settings values */
  gpr_uint32 settings[NUM_SETTING_SETS][GRPC_CHTTP2_NUM_SETTINGS];

  /** last received stream id */
  gpr_uint32 last_incoming_stream_id;
} grpc_chttp2_transport_global;

typedef struct {
  /** data to write now */
  gpr_slice_buffer outbuf;
  /** hpack encoding */
  grpc_chttp2_hpack_compressor hpack_compressor;
} grpc_chttp2_transport_writing;

struct grpc_chttp2_transport_parsing {
  /** is this transport a client? (boolean) */
  gpr_uint8 is_client;

  /** were settings updated? */
  gpr_uint8 settings_updated;
  /** was a settings ack received? */
  gpr_uint8 settings_ack_received;
  /** was a goaway frame received? */
  gpr_uint8 goaway_received;

  /** data to write later - after parsing */
  gpr_slice_buffer qbuf;
  /* metadata object cache */
  grpc_mdstr *str_grpc_timeout;
  /** parser for headers */
  grpc_chttp2_hpack_parser hpack_parser;
  /** simple one shot parsers */
  union {
    grpc_chttp2_window_update_parser window_update;
    grpc_chttp2_settings_parser settings;
    grpc_chttp2_ping_parser ping;
    grpc_chttp2_rst_stream_parser rst_stream;
  } simple;
  /** parser for goaway frames */
  grpc_chttp2_goaway_parser goaway_parser;

  /** window available for peer to send to us */
  gpr_uint32 incoming_window;

  /** next stream id available at the time of beginning parsing */
  gpr_uint32 next_stream_id;
  gpr_uint32 last_incoming_stream_id;

  /* deframing */
  grpc_chttp2_deframe_transport_state deframe_state;
  gpr_uint8 incoming_frame_type;
  gpr_uint8 incoming_frame_flags;
  gpr_uint8 header_eof;
  gpr_uint32 expect_continuation_stream_id;
  gpr_uint32 incoming_frame_size;
  gpr_uint32 incoming_stream_id;

  /* active parser */
  void *parser_data;
  grpc_chttp2_stream_parsing *incoming_stream;
  grpc_chttp2_parse_error (*parser)(void *parser_user_data,
                                    grpc_chttp2_transport_parsing *transport_parsing, grpc_chttp2_stream_parsing *stream_parsing,
                                    gpr_slice slice, int is_last);

  /* received settings */
  gpr_uint32 settings[GRPC_CHTTP2_NUM_SETTINGS];

  /* goaway data */
  grpc_status_code goaway_error;
  gpr_uint32 goaway_last_stream_index;
  gpr_slice goaway_text;
};


struct grpc_chttp2_transport {
  grpc_transport base; /* must be first */
  grpc_endpoint *ep;
  grpc_mdctx *metadata_context;
  gpr_refcount refs;

  gpr_mu mu;
  gpr_cv cv;

  /** is a thread currently writing */
  gpr_uint8 writing_active;

  /* basic state management - what are we doing at the moment? */
  gpr_uint8 reading;
  /** are we calling back any grpc_transport_op completion events */
  gpr_uint8 calling_back_ops;
  gpr_uint8 destroying;
  gpr_uint8 closed;
  grpc_chttp2_error_state error_state;

  /* stream indexing */
  gpr_uint32 next_stream_id;

  /* window management */
  gpr_uint32 outgoing_window_update;

  /* goaway */
  grpc_chttp2_pending_goaway *pending_goaways;
  size_t num_pending_goaways;
  size_t cap_pending_goaways;

  /* state for a stream that's not yet been created */
  grpc_stream_op_buffer new_stream_sopb;

  /* stream ops that need to be destroyed, but outside of the lock */
  grpc_stream_op_buffer nuke_later_sopb;

  grpc_chttp2_stream_list lists[STREAM_LIST_COUNT];
  grpc_chttp2_stream_map stream_map;

  /* pings */
  grpc_chttp2_outstanding_ping *pings;
  size_t ping_count;
  size_t ping_capacity;
  gpr_int64 ping_counter;

  grpc_chttp2_transport_global global;
  grpc_chttp2_transport_writing writing;
  grpc_chttp2_transport_parsing parsing;

  /** closure to execute writing */
  grpc_iomgr_closure writing_action;

  struct {
    /** is a thread currently performing channel callbacks */
    gpr_uint8 executing;
    /** transport channel-level callback */
    const grpc_transport_callbacks *cb;
    /** user data for cb calls */
    void *cb_user_data;
    /** closure for notifying transport closure */
    grpc_iomgr_closure notify_closed;
  } channel_callback;
};

typedef struct {
  /** HTTP2 stream id for this stream, or zero if one has not been assigned */
  gpr_uint32 id;

  grpc_iomgr_closure *send_done_closure;
  grpc_iomgr_closure *recv_done_closure;

  /** window available for us to send to peer */
  gpr_int64 outgoing_window;
  /** stream ops the transport user would like to send */
  grpc_stream_op_buffer *outgoing_sopb;
  /** when the application requests writes be closed, the write_closed is
      'queued'; when the close is flow controlled into the send path, we are
      'sending' it; when the write has been performed it is 'sent' */
  grpc_chttp2_write_state write_state;
  /** is this stream closed (boolean) */
  gpr_uint8 read_closed;
} grpc_chttp2_stream_global;

typedef struct {
  /** HTTP2 stream id for this stream, or zero if one has not been assigned */
  gpr_uint32 id;
  /** sops that have passed flow control to be written */
  grpc_stream_op_buffer sopb;
  /** how strongly should we indicate closure with the next write */
  grpc_chttp2_send_closed send_closed;
} grpc_chttp2_stream_writing;

struct grpc_chttp2_stream_parsing {
  /** HTTP2 stream id for this stream, or zero if one has not been assigned */
  gpr_uint32 id;
  /** has this stream received a close */
  gpr_uint8 received_close;
  /** incoming_window has been reduced during parsing */
  gpr_uint8 incoming_window_changed;
  /** saw an error on this stream during parsing (it should be cancelled) */
  gpr_uint8 saw_error;
  /** window available for peer to send to us */
  gpr_uint32 incoming_window;
  /** parsing state for data frames */
  grpc_chttp2_data_parser data_parser;

  /* incoming metadata */
  grpc_linked_mdelem *incoming_metadata;
  size_t incoming_metadata_count;
  size_t incoming_metadata_capacity;
  grpc_linked_mdelem *old_incoming_metadata;
  gpr_timespec incoming_deadline;
};

struct grpc_chttp2_stream {
  grpc_chttp2_stream_global global;
  grpc_chttp2_stream_writing writing;

  gpr_uint32 outgoing_window_update;
  gpr_uint8 cancelled;

  grpc_chttp2_stream_link links[STREAM_LIST_COUNT];
  gpr_uint8 included[STREAM_LIST_COUNT];

  /* sops from application */
  grpc_stream_op_buffer *incoming_sopb;
  grpc_stream_state *publish_state;
  grpc_stream_state published_state;

  grpc_stream_state callback_state;
  grpc_stream_op_buffer callback_sopb;
};

/** Transport writing call flow:
    chttp2_transport.c calls grpc_chttp2_unlocking_check_writes to see if writes are required;
    if they are, chttp2_transport.c calls grpc_chttp2_perform_writes to do the writes.
    Once writes have been completed (meaning another write could potentially be started),
    grpc_chttp2_terminate_writing is called. This will call grpc_chttp2_cleanup_writing, at which
    point the write phase is complete. */

/** Someone is unlocking the transport mutex: check to see if writes
    are required, and schedule them if so */
int grpc_chttp2_unlocking_check_writes(grpc_chttp2_transport_global *global, grpc_chttp2_transport_writing *writing);
void grpc_chttp2_perform_writes(grpc_chttp2_transport_writing *transport_writing, grpc_endpoint *endpoint);
void grpc_chttp2_terminate_writing(grpc_chttp2_transport_writing *transport_writing, int success);
void grpc_chttp2_cleanup_writing(grpc_chttp2_transport_global *global, grpc_chttp2_transport_writing *writing);

/** Process one slice of incoming data */
int grpc_chttp2_perform_read(grpc_chttp2_transport_parsing *transport_parsing, gpr_slice slice);
void grpc_chttp2_publish_reads(grpc_chttp2_transport_global *global, grpc_chttp2_transport_parsing *parsing);

/** Get a writable stream
    \return non-zero if there was a stream available */
void grpc_chttp2_list_add_writable_stream(grpc_chttp2_transport_global *transport_global, grpc_chttp2_stream_global *stream_global);
int grpc_chttp2_list_pop_writable_stream(grpc_chttp2_transport_global *transport_global, grpc_chttp2_transport_writing *transport_writing,
    grpc_chttp2_stream_global **stream_global, grpc_chttp2_stream_writing **stream_writing);

void grpc_chttp2_list_add_writing_stream(grpc_chttp2_transport_writing *transport_writing, grpc_chttp2_stream_writing *stream_writing);
int grpc_chttp2_list_have_writing_streams(grpc_chttp2_transport_writing *transport_writing);
int grpc_chttp2_list_pop_writing_stream(grpc_chttp2_transport_writing *transport_writing, grpc_chttp2_stream_writing **stream_writing);

void grpc_chttp2_list_add_written_stream(grpc_chttp2_transport_writing *transport_writing, grpc_chttp2_stream_writing *stream_writing);
int grpc_chttp2_list_pop_written_stream(grpc_chttp2_transport_global *transport_global, grpc_chttp2_transport_writing *transport_writing, grpc_chttp2_stream_global **stream_global, grpc_chttp2_stream_writing **stream_writing);

int grpc_chttp2_list_pop_writable_window_update_stream(grpc_chttp2_transport_global *transport_global, grpc_chttp2_stream_global **stream_global);

void grpc_chttp2_list_add_parsing_seen_stream(grpc_chttp2_transport_parsing *transport_parsing, grpc_chttp2_stream_parsing *stream_parsing);

void grpc_chttp2_schedule_closure(grpc_chttp2_transport_global *transport_global, grpc_iomgr_closure *closure, int success);
void grpc_chttp2_read_write_state_changed(grpc_chttp2_transport_global *transport_global, grpc_chttp2_stream_global *stream_global);

grpc_chttp2_stream_parsing *grpc_chttp2_parsing_lookup_stream(grpc_chttp2_transport_parsing *transport_parsing, gpr_uint32 id);
grpc_chttp2_stream_parsing *grpc_chttp2_parsing_accept_stream(grpc_chttp2_transport_parsing *transport_parsing, gpr_uint32 id);

#define GRPC_CHTTP2_FLOW_CTL_TRACE(a,b,c,d,e) do {} while (0)

#define GRPC_CHTTP2_CLIENT_CONNECT_STRING "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
#define GRPC_CHTTP2_CLIENT_CONNECT_STRLEN (sizeof(GRPC_CHTTP2_CLIENT_CONNECT_STRING)-1)

extern int grpc_http_trace;

#define IF_TRACING(stmt)  \
  if (!(grpc_http_trace)) \
    ;                     \
  else                    \
  stmt

#endif
