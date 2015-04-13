# GRPC Bazel BUILD file.
# This currently builds C and C++ code.

# Copyright 2015, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

licenses(["notice"])  # 3-clause BSD

package(default_visibility = ["//visibility:public"])




cc_library(
  name = "gpr",
  srcs = [
    "src/core/support/env.h",
    "src/core/support/file.h",
    "src/core/support/murmur_hash.h",
    "src/core/support/string.h",
    "src/core/support/string_win32.h",
    "src/core/support/thd_internal.h",
    "src/core/support/alloc.c",
    "src/core/support/cancellable.c",
    "src/core/support/cmdline.c",
    "src/core/support/cpu_iphone.c",
    "src/core/support/cpu_linux.c",
    "src/core/support/cpu_posix.c",
    "src/core/support/cpu_windows.c",
    "src/core/support/env_linux.c",
    "src/core/support/env_posix.c",
    "src/core/support/env_win32.c",
    "src/core/support/file.c",
    "src/core/support/file_posix.c",
    "src/core/support/file_win32.c",
    "src/core/support/histogram.c",
    "src/core/support/host_port.c",
    "src/core/support/log.c",
    "src/core/support/log_android.c",
    "src/core/support/log_linux.c",
    "src/core/support/log_posix.c",
    "src/core/support/log_win32.c",
    "src/core/support/murmur_hash.c",
    "src/core/support/slice.c",
    "src/core/support/slice_buffer.c",
    "src/core/support/string.c",
    "src/core/support/string_posix.c",
    "src/core/support/string_win32.c",
    "src/core/support/sync.c",
    "src/core/support/sync_posix.c",
    "src/core/support/sync_win32.c",
    "src/core/support/thd.c",
    "src/core/support/thd_posix.c",
    "src/core/support/thd_win32.c",
    "src/core/support/time.c",
    "src/core/support/time_posix.c",
    "src/core/support/time_win32.c",
  ],
  hdrs = [
    "include/grpc/support/alloc.h",
    "include/grpc/support/atm.h",
    "include/grpc/support/atm_gcc_atomic.h",
    "include/grpc/support/atm_gcc_sync.h",
    "include/grpc/support/atm_win32.h",
    "include/grpc/support/cancellable_platform.h",
    "include/grpc/support/cmdline.h",
    "include/grpc/support/cpu.h",
    "include/grpc/support/histogram.h",
    "include/grpc/support/host_port.h",
    "include/grpc/support/log.h",
    "include/grpc/support/log_win32.h",
    "include/grpc/support/port_platform.h",
    "include/grpc/support/slice.h",
    "include/grpc/support/slice_buffer.h",
    "include/grpc/support/sync.h",
    "include/grpc/support/sync_generic.h",
    "include/grpc/support/sync_posix.h",
    "include/grpc/support/sync_win32.h",
    "include/grpc/support/thd.h",
    "include/grpc/support/time.h",
    "include/grpc/support/tls.h",
    "include/grpc/support/tls_gcc.h",
    "include/grpc/support/tls_msvc.h",
    "include/grpc/support/tls_pthread.h",
    "include/grpc/support/useful.h",
  ],
  includes = [
    "include",
    ".",
  ],
  deps = [
  ],
)


cc_library(
  name = "grpc",
  srcs = [
    "src/core/httpcli/format_request.h",
    "src/core/httpcli/httpcli.h",
    "src/core/httpcli/httpcli_security_context.h",
    "src/core/httpcli/parser.h",
    "src/core/security/auth.h",
    "src/core/security/base64.h",
    "src/core/security/credentials.h",
    "src/core/security/json_token.h",
    "src/core/security/secure_endpoint.h",
    "src/core/security/secure_transport_setup.h",
    "src/core/security/security_context.h",
    "src/core/tsi/fake_transport_security.h",
    "src/core/tsi/ssl_transport_security.h",
    "src/core/tsi/transport_security.h",
    "src/core/tsi/transport_security_interface.h",
    "src/core/channel/census_filter.h",
    "src/core/channel/channel_args.h",
    "src/core/channel/channel_stack.h",
    "src/core/channel/child_channel.h",
    "src/core/channel/client_channel.h",
    "src/core/channel/client_setup.h",
    "src/core/channel/connected_channel.h",
    "src/core/channel/http_client_filter.h",
    "src/core/channel/http_filter.h",
    "src/core/channel/http_server_filter.h",
    "src/core/channel/metadata_buffer.h",
    "src/core/channel/noop_filter.h",
    "src/core/compression/algorithm.h",
    "src/core/compression/message_compress.h",
    "src/core/debug/trace.h",
    "src/core/iomgr/alarm.h",
    "src/core/iomgr/alarm_heap.h",
    "src/core/iomgr/alarm_internal.h",
    "src/core/iomgr/endpoint.h",
    "src/core/iomgr/endpoint_pair.h",
    "src/core/iomgr/fd_posix.h",
    "src/core/iomgr/iocp_windows.h",
    "src/core/iomgr/iomgr.h",
    "src/core/iomgr/iomgr_internal.h",
    "src/core/iomgr/iomgr_posix.h",
    "src/core/iomgr/pollset.h",
    "src/core/iomgr/pollset_kick.h",
    "src/core/iomgr/pollset_kick_posix.h",
    "src/core/iomgr/pollset_kick_windows.h",
    "src/core/iomgr/pollset_posix.h",
    "src/core/iomgr/pollset_windows.h",
    "src/core/iomgr/resolve_address.h",
    "src/core/iomgr/sockaddr.h",
    "src/core/iomgr/sockaddr_posix.h",
    "src/core/iomgr/sockaddr_utils.h",
    "src/core/iomgr/sockaddr_win32.h",
    "src/core/iomgr/socket_utils_posix.h",
    "src/core/iomgr/socket_windows.h",
    "src/core/iomgr/tcp_client.h",
    "src/core/iomgr/tcp_posix.h",
    "src/core/iomgr/tcp_server.h",
    "src/core/iomgr/tcp_windows.h",
    "src/core/iomgr/time_averaged_stats.h",
    "src/core/iomgr/wakeup_fd_pipe.h",
    "src/core/iomgr/wakeup_fd_posix.h",
    "src/core/json/json.h",
    "src/core/json/json_common.h",
    "src/core/json/json_reader.h",
    "src/core/json/json_writer.h",
    "src/core/statistics/census_interface.h",
    "src/core/statistics/census_log.h",
    "src/core/statistics/census_rpc_stats.h",
    "src/core/statistics/census_tracing.h",
    "src/core/statistics/hash_table.h",
    "src/core/statistics/window_stats.h",
    "src/core/surface/byte_buffer_queue.h",
    "src/core/surface/call.h",
    "src/core/surface/channel.h",
    "src/core/surface/client.h",
    "src/core/surface/completion_queue.h",
    "src/core/surface/event_string.h",
    "src/core/surface/init.h",
    "src/core/surface/server.h",
    "src/core/surface/surface_trace.h",
    "src/core/transport/chttp2/alpn.h",
    "src/core/transport/chttp2/bin_encoder.h",
    "src/core/transport/chttp2/frame.h",
    "src/core/transport/chttp2/frame_data.h",
    "src/core/transport/chttp2/frame_goaway.h",
    "src/core/transport/chttp2/frame_ping.h",
    "src/core/transport/chttp2/frame_rst_stream.h",
    "src/core/transport/chttp2/frame_settings.h",
    "src/core/transport/chttp2/frame_window_update.h",
    "src/core/transport/chttp2/hpack_parser.h",
    "src/core/transport/chttp2/hpack_table.h",
    "src/core/transport/chttp2/http2_errors.h",
    "src/core/transport/chttp2/huffsyms.h",
    "src/core/transport/chttp2/status_conversion.h",
    "src/core/transport/chttp2/stream_encoder.h",
    "src/core/transport/chttp2/stream_map.h",
    "src/core/transport/chttp2/timeout_encoding.h",
    "src/core/transport/chttp2/varint.h",
    "src/core/transport/chttp2_transport.h",
    "src/core/transport/metadata.h",
    "src/core/transport/stream_op.h",
    "src/core/transport/transport.h",
    "src/core/transport/transport_impl.h",
    "src/core/httpcli/format_request.c",
    "src/core/httpcli/httpcli.c",
    "src/core/httpcli/httpcli_security_context.c",
    "src/core/httpcli/parser.c",
    "src/core/security/auth.c",
    "src/core/security/base64.c",
    "src/core/security/credentials.c",
    "src/core/security/credentials_posix.c",
    "src/core/security/credentials_win32.c",
    "src/core/security/factories.c",
    "src/core/security/google_default_credentials.c",
    "src/core/security/json_token.c",
    "src/core/security/secure_endpoint.c",
    "src/core/security/secure_transport_setup.c",
    "src/core/security/security_context.c",
    "src/core/security/server_secure_chttp2.c",
    "src/core/surface/init_secure.c",
    "src/core/surface/secure_channel_create.c",
    "src/core/tsi/fake_transport_security.c",
    "src/core/tsi/ssl_transport_security.c",
    "src/core/tsi/transport_security.c",
    "src/core/channel/call_op_string.c",
    "src/core/channel/census_filter.c",
    "src/core/channel/channel_args.c",
    "src/core/channel/channel_stack.c",
    "src/core/channel/child_channel.c",
    "src/core/channel/client_channel.c",
    "src/core/channel/client_setup.c",
    "src/core/channel/connected_channel.c",
    "src/core/channel/http_client_filter.c",
    "src/core/channel/http_filter.c",
    "src/core/channel/http_server_filter.c",
    "src/core/channel/metadata_buffer.c",
    "src/core/channel/noop_filter.c",
    "src/core/compression/algorithm.c",
    "src/core/compression/message_compress.c",
    "src/core/debug/trace.c",
    "src/core/iomgr/alarm.c",
    "src/core/iomgr/alarm_heap.c",
    "src/core/iomgr/endpoint.c",
    "src/core/iomgr/endpoint_pair_posix.c",
    "src/core/iomgr/endpoint_pair_windows.c",
    "src/core/iomgr/fd_posix.c",
    "src/core/iomgr/iocp_windows.c",
    "src/core/iomgr/iomgr.c",
    "src/core/iomgr/iomgr_posix.c",
    "src/core/iomgr/iomgr_windows.c",
    "src/core/iomgr/pollset_kick.c",
    "src/core/iomgr/pollset_multipoller_with_epoll.c",
    "src/core/iomgr/pollset_multipoller_with_poll_posix.c",
    "src/core/iomgr/pollset_posix.c",
    "src/core/iomgr/pollset_windows.c",
    "src/core/iomgr/resolve_address_posix.c",
    "src/core/iomgr/resolve_address_windows.c",
    "src/core/iomgr/sockaddr_utils.c",
    "src/core/iomgr/socket_utils_common_posix.c",
    "src/core/iomgr/socket_utils_linux.c",
    "src/core/iomgr/socket_utils_posix.c",
    "src/core/iomgr/socket_windows.c",
    "src/core/iomgr/tcp_client_posix.c",
    "src/core/iomgr/tcp_client_windows.c",
    "src/core/iomgr/tcp_posix.c",
    "src/core/iomgr/tcp_server_posix.c",
    "src/core/iomgr/tcp_server_windows.c",
    "src/core/iomgr/tcp_windows.c",
    "src/core/iomgr/time_averaged_stats.c",
    "src/core/iomgr/wakeup_fd_eventfd.c",
    "src/core/iomgr/wakeup_fd_nospecial.c",
    "src/core/iomgr/wakeup_fd_pipe.c",
    "src/core/iomgr/wakeup_fd_posix.c",
    "src/core/json/json.c",
    "src/core/json/json_reader.c",
    "src/core/json/json_string.c",
    "src/core/json/json_writer.c",
    "src/core/statistics/census_init.c",
    "src/core/statistics/census_log.c",
    "src/core/statistics/census_rpc_stats.c",
    "src/core/statistics/census_tracing.c",
    "src/core/statistics/hash_table.c",
    "src/core/statistics/window_stats.c",
    "src/core/surface/byte_buffer.c",
    "src/core/surface/byte_buffer_queue.c",
    "src/core/surface/byte_buffer_reader.c",
    "src/core/surface/call.c",
    "src/core/surface/call_details.c",
    "src/core/surface/call_log_batch.c",
    "src/core/surface/channel.c",
    "src/core/surface/channel_create.c",
    "src/core/surface/client.c",
    "src/core/surface/completion_queue.c",
    "src/core/surface/event_string.c",
    "src/core/surface/init.c",
    "src/core/surface/lame_client.c",
    "src/core/surface/metadata_array.c",
    "src/core/surface/server.c",
    "src/core/surface/server_chttp2.c",
    "src/core/surface/server_create.c",
    "src/core/surface/surface_trace.c",
    "src/core/transport/chttp2/alpn.c",
    "src/core/transport/chttp2/bin_encoder.c",
    "src/core/transport/chttp2/frame_data.c",
    "src/core/transport/chttp2/frame_goaway.c",
    "src/core/transport/chttp2/frame_ping.c",
    "src/core/transport/chttp2/frame_rst_stream.c",
    "src/core/transport/chttp2/frame_settings.c",
    "src/core/transport/chttp2/frame_window_update.c",
    "src/core/transport/chttp2/hpack_parser.c",
    "src/core/transport/chttp2/hpack_table.c",
    "src/core/transport/chttp2/huffsyms.c",
    "src/core/transport/chttp2/status_conversion.c",
    "src/core/transport/chttp2/stream_encoder.c",
    "src/core/transport/chttp2/stream_map.c",
    "src/core/transport/chttp2/timeout_encoding.c",
    "src/core/transport/chttp2/varint.c",
    "src/core/transport/chttp2_transport.c",
    "src/core/transport/metadata.c",
    "src/core/transport/stream_op.c",
    "src/core/transport/transport.c",
  ],
  hdrs = [
    "include/grpc/grpc_security.h",
    "include/grpc/byte_buffer.h",
    "include/grpc/byte_buffer_reader.h",
    "include/grpc/grpc.h",
    "include/grpc/grpc_http.h",
    "include/grpc/status.h",
  ],
  includes = [
    "include",
    ".",
  ],
  deps = [
    "//external:libssl",
    ":gpr",
  ],
)


cc_library(
  name = "grpc_unsecure",
  srcs = [
    "src/core/channel/census_filter.h",
    "src/core/channel/channel_args.h",
    "src/core/channel/channel_stack.h",
    "src/core/channel/child_channel.h",
    "src/core/channel/client_channel.h",
    "src/core/channel/client_setup.h",
    "src/core/channel/connected_channel.h",
    "src/core/channel/http_client_filter.h",
    "src/core/channel/http_filter.h",
    "src/core/channel/http_server_filter.h",
    "src/core/channel/metadata_buffer.h",
    "src/core/channel/noop_filter.h",
    "src/core/compression/algorithm.h",
    "src/core/compression/message_compress.h",
    "src/core/debug/trace.h",
    "src/core/iomgr/alarm.h",
    "src/core/iomgr/alarm_heap.h",
    "src/core/iomgr/alarm_internal.h",
    "src/core/iomgr/endpoint.h",
    "src/core/iomgr/endpoint_pair.h",
    "src/core/iomgr/fd_posix.h",
    "src/core/iomgr/iocp_windows.h",
    "src/core/iomgr/iomgr.h",
    "src/core/iomgr/iomgr_internal.h",
    "src/core/iomgr/iomgr_posix.h",
    "src/core/iomgr/pollset.h",
    "src/core/iomgr/pollset_kick.h",
    "src/core/iomgr/pollset_kick_posix.h",
    "src/core/iomgr/pollset_kick_windows.h",
    "src/core/iomgr/pollset_posix.h",
    "src/core/iomgr/pollset_windows.h",
    "src/core/iomgr/resolve_address.h",
    "src/core/iomgr/sockaddr.h",
    "src/core/iomgr/sockaddr_posix.h",
    "src/core/iomgr/sockaddr_utils.h",
    "src/core/iomgr/sockaddr_win32.h",
    "src/core/iomgr/socket_utils_posix.h",
    "src/core/iomgr/socket_windows.h",
    "src/core/iomgr/tcp_client.h",
    "src/core/iomgr/tcp_posix.h",
    "src/core/iomgr/tcp_server.h",
    "src/core/iomgr/tcp_windows.h",
    "src/core/iomgr/time_averaged_stats.h",
    "src/core/iomgr/wakeup_fd_pipe.h",
    "src/core/iomgr/wakeup_fd_posix.h",
    "src/core/json/json.h",
    "src/core/json/json_common.h",
    "src/core/json/json_reader.h",
    "src/core/json/json_writer.h",
    "src/core/statistics/census_interface.h",
    "src/core/statistics/census_log.h",
    "src/core/statistics/census_rpc_stats.h",
    "src/core/statistics/census_tracing.h",
    "src/core/statistics/hash_table.h",
    "src/core/statistics/window_stats.h",
    "src/core/surface/byte_buffer_queue.h",
    "src/core/surface/call.h",
    "src/core/surface/channel.h",
    "src/core/surface/client.h",
    "src/core/surface/completion_queue.h",
    "src/core/surface/event_string.h",
    "src/core/surface/init.h",
    "src/core/surface/server.h",
    "src/core/surface/surface_trace.h",
    "src/core/transport/chttp2/alpn.h",
    "src/core/transport/chttp2/bin_encoder.h",
    "src/core/transport/chttp2/frame.h",
    "src/core/transport/chttp2/frame_data.h",
    "src/core/transport/chttp2/frame_goaway.h",
    "src/core/transport/chttp2/frame_ping.h",
    "src/core/transport/chttp2/frame_rst_stream.h",
    "src/core/transport/chttp2/frame_settings.h",
    "src/core/transport/chttp2/frame_window_update.h",
    "src/core/transport/chttp2/hpack_parser.h",
    "src/core/transport/chttp2/hpack_table.h",
    "src/core/transport/chttp2/http2_errors.h",
    "src/core/transport/chttp2/huffsyms.h",
    "src/core/transport/chttp2/status_conversion.h",
    "src/core/transport/chttp2/stream_encoder.h",
    "src/core/transport/chttp2/stream_map.h",
    "src/core/transport/chttp2/timeout_encoding.h",
    "src/core/transport/chttp2/varint.h",
    "src/core/transport/chttp2_transport.h",
    "src/core/transport/metadata.h",
    "src/core/transport/stream_op.h",
    "src/core/transport/transport.h",
    "src/core/transport/transport_impl.h",
    "src/core/surface/init_unsecure.c",
    "src/core/channel/call_op_string.c",
    "src/core/channel/census_filter.c",
    "src/core/channel/channel_args.c",
    "src/core/channel/channel_stack.c",
    "src/core/channel/child_channel.c",
    "src/core/channel/client_channel.c",
    "src/core/channel/client_setup.c",
    "src/core/channel/connected_channel.c",
    "src/core/channel/http_client_filter.c",
    "src/core/channel/http_filter.c",
    "src/core/channel/http_server_filter.c",
    "src/core/channel/metadata_buffer.c",
    "src/core/channel/noop_filter.c",
    "src/core/compression/algorithm.c",
    "src/core/compression/message_compress.c",
    "src/core/debug/trace.c",
    "src/core/iomgr/alarm.c",
    "src/core/iomgr/alarm_heap.c",
    "src/core/iomgr/endpoint.c",
    "src/core/iomgr/endpoint_pair_posix.c",
    "src/core/iomgr/endpoint_pair_windows.c",
    "src/core/iomgr/fd_posix.c",
    "src/core/iomgr/iocp_windows.c",
    "src/core/iomgr/iomgr.c",
    "src/core/iomgr/iomgr_posix.c",
    "src/core/iomgr/iomgr_windows.c",
    "src/core/iomgr/pollset_kick.c",
    "src/core/iomgr/pollset_multipoller_with_epoll.c",
    "src/core/iomgr/pollset_multipoller_with_poll_posix.c",
    "src/core/iomgr/pollset_posix.c",
    "src/core/iomgr/pollset_windows.c",
    "src/core/iomgr/resolve_address_posix.c",
    "src/core/iomgr/resolve_address_windows.c",
    "src/core/iomgr/sockaddr_utils.c",
    "src/core/iomgr/socket_utils_common_posix.c",
    "src/core/iomgr/socket_utils_linux.c",
    "src/core/iomgr/socket_utils_posix.c",
    "src/core/iomgr/socket_windows.c",
    "src/core/iomgr/tcp_client_posix.c",
    "src/core/iomgr/tcp_client_windows.c",
    "src/core/iomgr/tcp_posix.c",
    "src/core/iomgr/tcp_server_posix.c",
    "src/core/iomgr/tcp_server_windows.c",
    "src/core/iomgr/tcp_windows.c",
    "src/core/iomgr/time_averaged_stats.c",
    "src/core/iomgr/wakeup_fd_eventfd.c",
    "src/core/iomgr/wakeup_fd_nospecial.c",
    "src/core/iomgr/wakeup_fd_pipe.c",
    "src/core/iomgr/wakeup_fd_posix.c",
    "src/core/json/json.c",
    "src/core/json/json_reader.c",
    "src/core/json/json_string.c",
    "src/core/json/json_writer.c",
    "src/core/statistics/census_init.c",
    "src/core/statistics/census_log.c",
    "src/core/statistics/census_rpc_stats.c",
    "src/core/statistics/census_tracing.c",
    "src/core/statistics/hash_table.c",
    "src/core/statistics/window_stats.c",
    "src/core/surface/byte_buffer.c",
    "src/core/surface/byte_buffer_queue.c",
    "src/core/surface/byte_buffer_reader.c",
    "src/core/surface/call.c",
    "src/core/surface/call_details.c",
    "src/core/surface/call_log_batch.c",
    "src/core/surface/channel.c",
    "src/core/surface/channel_create.c",
    "src/core/surface/client.c",
    "src/core/surface/completion_queue.c",
    "src/core/surface/event_string.c",
    "src/core/surface/init.c",
    "src/core/surface/lame_client.c",
    "src/core/surface/metadata_array.c",
    "src/core/surface/server.c",
    "src/core/surface/server_chttp2.c",
    "src/core/surface/server_create.c",
    "src/core/surface/surface_trace.c",
    "src/core/transport/chttp2/alpn.c",
    "src/core/transport/chttp2/bin_encoder.c",
    "src/core/transport/chttp2/frame_data.c",
    "src/core/transport/chttp2/frame_goaway.c",
    "src/core/transport/chttp2/frame_ping.c",
    "src/core/transport/chttp2/frame_rst_stream.c",
    "src/core/transport/chttp2/frame_settings.c",
    "src/core/transport/chttp2/frame_window_update.c",
    "src/core/transport/chttp2/hpack_parser.c",
    "src/core/transport/chttp2/hpack_table.c",
    "src/core/transport/chttp2/huffsyms.c",
    "src/core/transport/chttp2/status_conversion.c",
    "src/core/transport/chttp2/stream_encoder.c",
    "src/core/transport/chttp2/stream_map.c",
    "src/core/transport/chttp2/timeout_encoding.c",
    "src/core/transport/chttp2/varint.c",
    "src/core/transport/chttp2_transport.c",
    "src/core/transport/metadata.c",
    "src/core/transport/stream_op.c",
    "src/core/transport/transport.c",
  ],
  hdrs = [
    "include/grpc/byte_buffer.h",
    "include/grpc/byte_buffer_reader.h",
    "include/grpc/grpc.h",
    "include/grpc/grpc_http.h",
    "include/grpc/status.h",
  ],
  includes = [
    "include",
    ".",
  ],
  deps = [
    ":gpr",
  ],
)


cc_library(
  name = "grpc++",
  srcs = [
    "src/cpp/client/secure_credentials.h",
    "src/cpp/server/secure_server_credentials.h",
    "src/cpp/client/channel.h",
    "src/cpp/proto/proto_utils.h",
    "src/cpp/server/thread_pool.h",
    "src/cpp/util/time.h",
    "src/cpp/client/secure_credentials.cc",
    "src/cpp/server/secure_server_credentials.cc",
    "src/cpp/client/channel.cc",
    "src/cpp/client/channel_arguments.cc",
    "src/cpp/client/client_context.cc",
    "src/cpp/client/client_unary_call.cc",
    "src/cpp/client/create_channel.cc",
    "src/cpp/client/credentials.cc",
    "src/cpp/client/generic_stub.cc",
    "src/cpp/client/insecure_credentials.cc",
    "src/cpp/client/internal_stub.cc",
    "src/cpp/common/call.cc",
    "src/cpp/common/completion_queue.cc",
    "src/cpp/common/rpc_method.cc",
    "src/cpp/proto/proto_utils.cc",
    "src/cpp/server/async_generic_service.cc",
    "src/cpp/server/insecure_server_credentials.cc",
    "src/cpp/server/server.cc",
    "src/cpp/server/server_builder.cc",
    "src/cpp/server/server_context.cc",
    "src/cpp/server/server_credentials.cc",
    "src/cpp/server/thread_pool.cc",
    "src/cpp/util/byte_buffer.cc",
    "src/cpp/util/slice.cc",
    "src/cpp/util/status.cc",
    "src/cpp/util/time.cc",
  ],
  hdrs = [
    "include/grpc++/async_generic_service.h",
    "include/grpc++/async_unary_call.h",
    "include/grpc++/byte_buffer.h",
    "include/grpc++/channel_arguments.h",
    "include/grpc++/channel_interface.h",
    "include/grpc++/client_context.h",
    "include/grpc++/completion_queue.h",
    "include/grpc++/config.h",
    "include/grpc++/create_channel.h",
    "include/grpc++/credentials.h",
    "include/grpc++/generic_stub.h",
    "include/grpc++/impl/call.h",
    "include/grpc++/impl/client_unary_call.h",
    "include/grpc++/impl/internal_stub.h",
    "include/grpc++/impl/rpc_method.h",
    "include/grpc++/impl/rpc_service_method.h",
    "include/grpc++/impl/service_type.h",
    "include/grpc++/impl/sync.h",
    "include/grpc++/impl/sync_cxx11.h",
    "include/grpc++/impl/sync_no_cxx11.h",
    "include/grpc++/impl/thd.h",
    "include/grpc++/impl/thd_cxx11.h",
    "include/grpc++/impl/thd_no_cxx11.h",
    "include/grpc++/server.h",
    "include/grpc++/server_builder.h",
    "include/grpc++/server_context.h",
    "include/grpc++/server_credentials.h",
    "include/grpc++/slice.h",
    "include/grpc++/status.h",
    "include/grpc++/status_code_enum.h",
    "include/grpc++/stream.h",
    "include/grpc++/thread_pool_interface.h",
  ],
  includes = [
    "include",
    ".",
  ],
  deps = [
    "//external:protobuf_clib",
    ":gpr",
    ":grpc",
  ],
)


cc_library(
  name = "grpc++_unsecure",
  srcs = [
    "src/cpp/client/channel.h",
    "src/cpp/proto/proto_utils.h",
    "src/cpp/server/thread_pool.h",
    "src/cpp/util/time.h",
    "src/cpp/client/channel.cc",
    "src/cpp/client/channel_arguments.cc",
    "src/cpp/client/client_context.cc",
    "src/cpp/client/client_unary_call.cc",
    "src/cpp/client/create_channel.cc",
    "src/cpp/client/credentials.cc",
    "src/cpp/client/generic_stub.cc",
    "src/cpp/client/insecure_credentials.cc",
    "src/cpp/client/internal_stub.cc",
    "src/cpp/common/call.cc",
    "src/cpp/common/completion_queue.cc",
    "src/cpp/common/rpc_method.cc",
    "src/cpp/proto/proto_utils.cc",
    "src/cpp/server/async_generic_service.cc",
    "src/cpp/server/insecure_server_credentials.cc",
    "src/cpp/server/server.cc",
    "src/cpp/server/server_builder.cc",
    "src/cpp/server/server_context.cc",
    "src/cpp/server/server_credentials.cc",
    "src/cpp/server/thread_pool.cc",
    "src/cpp/util/byte_buffer.cc",
    "src/cpp/util/slice.cc",
    "src/cpp/util/status.cc",
    "src/cpp/util/time.cc",
  ],
  hdrs = [
    "include/grpc++/async_generic_service.h",
    "include/grpc++/async_unary_call.h",
    "include/grpc++/byte_buffer.h",
    "include/grpc++/channel_arguments.h",
    "include/grpc++/channel_interface.h",
    "include/grpc++/client_context.h",
    "include/grpc++/completion_queue.h",
    "include/grpc++/config.h",
    "include/grpc++/create_channel.h",
    "include/grpc++/credentials.h",
    "include/grpc++/generic_stub.h",
    "include/grpc++/impl/call.h",
    "include/grpc++/impl/client_unary_call.h",
    "include/grpc++/impl/internal_stub.h",
    "include/grpc++/impl/rpc_method.h",
    "include/grpc++/impl/rpc_service_method.h",
    "include/grpc++/impl/service_type.h",
    "include/grpc++/impl/sync.h",
    "include/grpc++/impl/sync_cxx11.h",
    "include/grpc++/impl/sync_no_cxx11.h",
    "include/grpc++/impl/thd.h",
    "include/grpc++/impl/thd_cxx11.h",
    "include/grpc++/impl/thd_no_cxx11.h",
    "include/grpc++/server.h",
    "include/grpc++/server_builder.h",
    "include/grpc++/server_context.h",
    "include/grpc++/server_credentials.h",
    "include/grpc++/slice.h",
    "include/grpc++/status.h",
    "include/grpc++/status_code_enum.h",
    "include/grpc++/stream.h",
    "include/grpc++/thread_pool_interface.h",
  ],
  includes = [
    "include",
    ".",
  ],
  deps = [
    "//external:protobuf_clib",
    ":gpr",
    ":grpc_unsecure",
  ],
)


cc_library(
  name = "grpc_plugin_support",
  srcs = [
    "src/compiler/config.h",
    "src/compiler/cpp_generator.h",
    "src/compiler/cpp_generator_helpers.h",
    "src/compiler/generator_helpers.h",
    "src/compiler/objective_c_generator.h",
    "src/compiler/objective_c_generator_helpers.h",
    "src/compiler/python_generator.h",
    "src/compiler/ruby_generator.h",
    "src/compiler/ruby_generator_helpers-inl.h",
    "src/compiler/ruby_generator_map-inl.h",
    "src/compiler/ruby_generator_string-inl.h",
    "src/compiler/cpp_generator.cc",
    "src/compiler/objective_c_generator.cc",
    "src/compiler/python_generator.cc",
    "src/compiler/ruby_generator.cc",
  ],
  hdrs = [
  ],
  includes = [
    "include",
    ".",
  ],
  deps = [
    "//external:protobuf_compiler",
  ],
)


cc_library(
  name = "grpc_csharp_ext",
  srcs = [
    "src/csharp/ext/grpc_csharp_ext.c",
  ],
  hdrs = [
  ],
  includes = [
    "include",
    ".",
  ],
  deps = [
    ":gpr",
    ":grpc",
  ],
)



cc_binary(
  name = "grpc_cpp_plugin",
  srcs = [
    "src/compiler/cpp_plugin.cc",
  ],
  deps = [
    "//external:protobuf_compiler",
    ":grpc_plugin_support",
  ],
)


cc_binary(
  name = "grpc_objective_c_plugin",
  srcs = [
    "src/compiler/objective_c_plugin.cc",
  ],
  deps = [
    "//external:protobuf_compiler",
    ":grpc_plugin_support",
  ],
)


cc_binary(
  name = "grpc_python_plugin",
  srcs = [
    "src/compiler/python_plugin.cc",
  ],
  deps = [
    "//external:protobuf_compiler",
    ":grpc_plugin_support",
  ],
)


cc_binary(
  name = "grpc_ruby_plugin",
  srcs = [
    "src/compiler/ruby_plugin.cc",
  ],
  deps = [
    "//external:protobuf_compiler",
    ":grpc_plugin_support",
  ],
)





