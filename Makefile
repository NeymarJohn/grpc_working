# GRPC global makefile
# This currently builds C and C++ code.


# Configurations

VALID_CONFIG_opt = 1
CC_opt = gcc
CXX_opt = g++
LD_opt = gcc
LDXX_opt = g++
CPPFLAGS_opt = -O2
LDFLAGS_opt =
DEFINES_opt = NDEBUG

VALID_CONFIG_dbg = 1
CC_dbg = gcc
CXX_dbg = g++
LD_dbg = gcc
LDXX_dbg = g++
CPPFLAGS_dbg = -O0
LDFLAGS_dbg =
DEFINES_dbg = _DEBUG DEBUG

VALID_CONFIG_tsan = 1
CC_tsan = clang
CXX_tsan = clang++
LD_tsan = clang
LDXX_tsan = clang++
CPPFLAGS_tsan = -O1 -fsanitize=thread -fno-omit-frame-pointer
LDFLAGS_tsan = -fsanitize=thread
DEFINES_tsan = NDEBUG

VALID_CONFIG_asan = 1
CC_asan = clang
CXX_asan = clang++
LD_asan = clang
LDXX_asan = clang++
CPPFLAGS_asan = -O1 -fsanitize=address -fno-omit-frame-pointer
LDFLAGS_asan = -fsanitize=address
DEFINES_asan = NDEBUG

VALID_CONFIG_msan = 1
CC_msan = clang
CXX_msan = clang++
LD_msan = clang
LDXX_msan = clang++
CPPFLAGS_msan = -O1 -fsanitize=memory -fno-omit-frame-pointer
LDFLAGS_msan = -fsanitize=memory
DEFINES_msan = NDEBUG

VALID_CONFIG_gcov = 1
CC_gcov = gcc
CXX_gcov = g++
LD_gcov = gcc
LDXX_gcov = g++
CPPFLAGS_gcov = -O0 -fprofile-arcs -ftest-coverage
LDFLAGS_gcov = -fprofile-arcs -ftest-coverage
DEFINES_gcov = NDEBUG

# General settings.
# You may want to change these depending on your system.

prefix ?= /usr/local

PROTOC = protoc
CONFIG ?= opt
CC = $(CC_$(CONFIG))
CXX = $(CXX_$(CONFIG))
LD = $(LD_$(CONFIG))
LDXX = $(LDXX_$(CONFIG))
AR = ar
STRIP = strip --strip-unneeded
INSTALL = install -D
RM = rm -f

ifndef VALID_CONFIG_$(CONFIG)
$(error Invalid CONFIG value '$(CONFIG)')
endif

HOST_CC = $(CC)
HOST_CXX = $(CXX)
HOST_LD = $(LD)
HOST_LDXX = $(LDXX)

CPPFLAGS += $(CPPFLAGS_$(CONFIG))
DEFINES += $(DEFINES_$(CONFIG))
LDFLAGS += $(LDFLAGS_$(CONFIG))

CFLAGS += -std=c89 -pedantic
CXXFLAGS += -std=c++11
CPPFLAGS += -g -fPIC -Wall -Werror -Wno-long-long
LDFLAGS += -g -pthread -fPIC

INCLUDES = . include gens
LIBS = rt m z pthread
LIBSXX = protobuf
LIBS_PROTOC = protoc protobuf

ifneq ($(wildcard /usr/src/gtest/src/gtest-all.cc),)
GTEST_LIB = /usr/src/gtest/src/gtest-all.cc -I/usr/src/gtest
else
GTEST_LIB = -lgtest
endif
GTEST_LIB += -lgflags
ifeq ($(V),1)
E = @:
Q =
else
E = @echo
Q = @
endif

VERSION = 0.8.0.0

CPPFLAGS_NO_ARCH += $(addprefix -I, $(INCLUDES)) $(addprefix -D, $(DEFINES))
CPPFLAGS += $(CPPFLAGS_NO_ARCH) $(ARCH_FLAGS)

LDFLAGS += $(ARCH_FLAGS)
LDLIBS += $(addprefix -l, $(LIBS))
LDLIBSXX += $(addprefix -l, $(LIBSXX))
HOST_LDLIBS_PROTOC += $(addprefix -l, $(LIBS_PROTOC))

HOST_CPPFLAGS = $(CPPFLAGS)
HOST_CFLAGS = $(CFLAGS)
HOST_CXXFLAGS = $(CXXFLAGS)
HOST_LDFLAGS = $(LDFLAGS)
HOST_LDLIBS = $(LDLIBS)


# These are automatically computed variables.
# There shouldn't be any need to change anything from now on.

HOST_SYSTEM = $(shell uname | cut -f 1 -d_)
ifeq ($(SYSTEM),)
SYSTEM = $(HOST_SYSTEM)
endif

ifeq ($(SYSTEM),MINGW32)
SHARED_EXT = dll
endif
ifeq ($(SYSTEM),Darwin)
SHARED_EXT = dylib
endif
ifeq ($(SHARED_EXT),)
SHARED_EXT = so.$(VERSION)
endif

ifeq ($(wildcard .git),)
IS_GIT_FOLDER = false
else
IS_GIT_FOLDER = true
endif

OPENSSL_ALPN_CHECK_CMD = $(CC) $(CFLAGS) $(CPPFLAGS) -o /dev/null test/build/openssl-alpn.c -lssl -lcrypto -ldl $(LDFLAGS)
ZLIB_CHECK_CMD = $(CC) $(CFLAGS) $(CPPFLAGS) -o /dev/null test/build/zlib.c -lz $(LDFLAGS)

HAS_SYSTEM_OPENSSL_ALPN = $(shell $(OPENSSL_ALPN_CHECK_CMD) 2> /dev/null && echo true || echo false)
HAS_SYSTEM_ZLIB = $(shell $(ZLIB_CHECK_CMD) 2> /dev/null && echo true || echo false)

ifeq ($(wildcard third_party/openssl/ssl/ssl.h),)
HAS_EMBEDDED_OPENSSL_ALPN = false
else
HAS_EMBEDDED_OPENSSL_ALPN = true
endif

ifeq ($(wildcard third_party/zlib/zlib.h),)
HAS_EMBEDDED_ZLIB = false
else
HAS_EMBEDDED_ZLIB = true
endif

ifeq ($(HAS_SYSTEM_ZLIB),false)
ifeq ($(HAS_EMBEDDED_ZLIB),true)
ZLIB_DEP = third_party/zlib/libz.a
CPPFLAGS += -Ithird_party/zlib
LDFLAGS += -Lthird_party/zlib
else
DEP_MISSING += zlib
endif
endif

ifeq ($(HAS_SYSTEM_OPENSSL_ALPN),false)
ifeq ($(HAS_EMBEDDED_OPENSSL_ALPN),true)
OPENSSL_DEP = third_party/openssl/libssl.a
OPENSSL_MERGE_LIBS += third_party/openssl/libssl.a third_party/openssl/libcrypto.a
CPPFLAGS += -Ithird_party/openssl/include
LDFLAGS += -Lthird_party/openssl
LIBS_SECURE = dl
else
NO_SECURE = true
endif
else
LIBS_SECURE = ssl crypto dl
endif

LDLIBS_SECURE += $(addprefix -l, $(LIBS_SECURE))

ifeq ($(MAKECMDGOALS),clean)
NO_DEPS = true
endif

.SECONDARY = %.pb.h %.pb.cc

PROTOC_PLUGINS= bins/$(CONFIG)/cpp_plugin bins/$(CONFIG)/ruby_plugin
ifeq ($(DEP_MISSING),)
all: static shared
dep_error:
	@echo "You shouldn't see this message - all of your dependencies are correct."
else
all: dep_error git_update stop

dep_error:
	@echo
	@echo "DEPENDENCY ERROR"
	@echo
	@echo "You are missing system dependencies that are essential to build grpc,"
	@echo "and the third_party directory doesn't have them:"
	@echo
	@echo "  $(DEP_MISSING)"
	@echo
	@echo "Installing the development packages for your system will solve"
	@echo "this issue. Please consult INSTALL to get more information."
	@echo
	@echo "If you need information about why these tests failed, run:"
	@echo
	@echo "  make run_dep_checks"
	@echo
endif

git_update:
ifeq ($(IS_GIT_FOLDER),true)
	@echo "Additionally, since you are in a git clone, you can download the"
	@echo "missing dependencies in third_party by running the following command:"
	@echo
	@echo "  git submodule update --init"
	@echo
endif

openssl_dep_error: openssl_dep_message git_update stop

openssl_dep_message:
	@echo
	@echo "DEPENDENCY ERROR"
	@echo
	@echo "The target you are trying to run requires OpenSSL with ALPN support."
	@echo "Your system doesn't have it, and neither does the third_party directory."
	@echo
	@echo "Please consult INSTALL to get more information."
	@echo
	@echo "If you need information about why these tests failed, run:"
	@echo
	@echo "  make run_dep_checks"
	@echo

stop:
	@false

gen_hpack_tables: bins/$(CONFIG)/gen_hpack_tables
cpp_plugin: bins/$(CONFIG)/cpp_plugin
ruby_plugin: bins/$(CONFIG)/ruby_plugin
grpc_byte_buffer_reader_test: bins/$(CONFIG)/grpc_byte_buffer_reader_test
gpr_cancellable_test: bins/$(CONFIG)/gpr_cancellable_test
gpr_log_test: bins/$(CONFIG)/gpr_log_test
gpr_useful_test: bins/$(CONFIG)/gpr_useful_test
gpr_cmdline_test: bins/$(CONFIG)/gpr_cmdline_test
gpr_histogram_test: bins/$(CONFIG)/gpr_histogram_test
gpr_host_port_test: bins/$(CONFIG)/gpr_host_port_test
gpr_slice_buffer_test: bins/$(CONFIG)/gpr_slice_buffer_test
gpr_slice_test: bins/$(CONFIG)/gpr_slice_test
gpr_string_test: bins/$(CONFIG)/gpr_string_test
gpr_sync_test: bins/$(CONFIG)/gpr_sync_test
gpr_thd_test: bins/$(CONFIG)/gpr_thd_test
gpr_time_test: bins/$(CONFIG)/gpr_time_test
murmur_hash_test: bins/$(CONFIG)/murmur_hash_test
grpc_stream_op_test: bins/$(CONFIG)/grpc_stream_op_test
alpn_test: bins/$(CONFIG)/alpn_test
time_averaged_stats_test: bins/$(CONFIG)/time_averaged_stats_test
chttp2_stream_encoder_test: bins/$(CONFIG)/chttp2_stream_encoder_test
hpack_table_test: bins/$(CONFIG)/hpack_table_test
chttp2_stream_map_test: bins/$(CONFIG)/chttp2_stream_map_test
hpack_parser_test: bins/$(CONFIG)/hpack_parser_test
transport_metadata_test: bins/$(CONFIG)/transport_metadata_test
chttp2_status_conversion_test: bins/$(CONFIG)/chttp2_status_conversion_test
chttp2_transport_end2end_test: bins/$(CONFIG)/chttp2_transport_end2end_test
tcp_posix_test: bins/$(CONFIG)/tcp_posix_test
dualstack_socket_test: bins/$(CONFIG)/dualstack_socket_test
no_server_test: bins/$(CONFIG)/no_server_test
resolve_address_test: bins/$(CONFIG)/resolve_address_test
sockaddr_utils_test: bins/$(CONFIG)/sockaddr_utils_test
tcp_server_posix_test: bins/$(CONFIG)/tcp_server_posix_test
tcp_client_posix_test: bins/$(CONFIG)/tcp_client_posix_test
grpc_channel_stack_test: bins/$(CONFIG)/grpc_channel_stack_test
metadata_buffer_test: bins/$(CONFIG)/metadata_buffer_test
grpc_completion_queue_test: bins/$(CONFIG)/grpc_completion_queue_test
grpc_completion_queue_benchmark: bins/$(CONFIG)/grpc_completion_queue_benchmark
census_trace_store_test: bins/$(CONFIG)/census_trace_store_test
census_stats_store_test: bins/$(CONFIG)/census_stats_store_test
census_window_stats_test: bins/$(CONFIG)/census_window_stats_test
census_statistics_quick_test: bins/$(CONFIG)/census_statistics_quick_test
census_statistics_small_log_test: bins/$(CONFIG)/census_statistics_small_log_test
census_statistics_performance_test: bins/$(CONFIG)/census_statistics_performance_test
census_statistics_multiple_writers_test: bins/$(CONFIG)/census_statistics_multiple_writers_test
census_statistics_multiple_writers_circular_buffer_test: bins/$(CONFIG)/census_statistics_multiple_writers_circular_buffer_test
census_stub_test: bins/$(CONFIG)/census_stub_test
census_hash_table_test: bins/$(CONFIG)/census_hash_table_test
fling_server: bins/$(CONFIG)/fling_server
fling_client: bins/$(CONFIG)/fling_client
fling_test: bins/$(CONFIG)/fling_test
echo_server: bins/$(CONFIG)/echo_server
echo_client: bins/$(CONFIG)/echo_client
echo_test: bins/$(CONFIG)/echo_test
low_level_ping_pong_benchmark: bins/$(CONFIG)/low_level_ping_pong_benchmark
message_compress_test: bins/$(CONFIG)/message_compress_test
bin_encoder_test: bins/$(CONFIG)/bin_encoder_test
secure_endpoint_test: bins/$(CONFIG)/secure_endpoint_test
httpcli_format_request_test: bins/$(CONFIG)/httpcli_format_request_test
httpcli_parser_test: bins/$(CONFIG)/httpcli_parser_test
httpcli_test: bins/$(CONFIG)/httpcli_test
grpc_credentials_test: bins/$(CONFIG)/grpc_credentials_test
grpc_fetch_oauth2: bins/$(CONFIG)/grpc_fetch_oauth2
grpc_base64_test: bins/$(CONFIG)/grpc_base64_test
grpc_json_token_test: bins/$(CONFIG)/grpc_json_token_test
timeout_encoding_test: bins/$(CONFIG)/timeout_encoding_test
fd_posix_test: bins/$(CONFIG)/fd_posix_test
fling_stream_test: bins/$(CONFIG)/fling_stream_test
lame_client_test: bins/$(CONFIG)/lame_client_test
thread_pool_test: bins/$(CONFIG)/thread_pool_test
status_test: bins/$(CONFIG)/status_test
sync_client_async_server_test: bins/$(CONFIG)/sync_client_async_server_test
qps_client: bins/$(CONFIG)/qps_client
qps_server: bins/$(CONFIG)/qps_server
interop_server: bins/$(CONFIG)/interop_server
interop_client: bins/$(CONFIG)/interop_client
end2end_test: bins/$(CONFIG)/end2end_test
channel_arguments_test: bins/$(CONFIG)/channel_arguments_test
credentials_test: bins/$(CONFIG)/credentials_test
alarm_test: bins/$(CONFIG)/alarm_test
alarm_list_test: bins/$(CONFIG)/alarm_list_test
alarm_heap_test: bins/$(CONFIG)/alarm_heap_test
time_test: bins/$(CONFIG)/time_test
chttp2_fake_security_cancel_after_accept_test: bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_test
chttp2_fake_security_cancel_after_accept_and_writes_closed_test: bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_and_writes_closed_test
chttp2_fake_security_cancel_after_invoke_test: bins/$(CONFIG)/chttp2_fake_security_cancel_after_invoke_test
chttp2_fake_security_cancel_before_invoke_test: bins/$(CONFIG)/chttp2_fake_security_cancel_before_invoke_test
chttp2_fake_security_cancel_in_a_vacuum_test: bins/$(CONFIG)/chttp2_fake_security_cancel_in_a_vacuum_test
chttp2_fake_security_census_simple_request_test: bins/$(CONFIG)/chttp2_fake_security_census_simple_request_test
chttp2_fake_security_disappearing_server_test: bins/$(CONFIG)/chttp2_fake_security_disappearing_server_test
chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test: bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test
chttp2_fake_security_early_server_shutdown_finishes_tags_test: bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_tags_test
chttp2_fake_security_invoke_large_request_test: bins/$(CONFIG)/chttp2_fake_security_invoke_large_request_test
chttp2_fake_security_max_concurrent_streams_test: bins/$(CONFIG)/chttp2_fake_security_max_concurrent_streams_test
chttp2_fake_security_no_op_test: bins/$(CONFIG)/chttp2_fake_security_no_op_test
chttp2_fake_security_ping_pong_streaming_test: bins/$(CONFIG)/chttp2_fake_security_ping_pong_streaming_test
chttp2_fake_security_request_response_with_binary_metadata_and_payload_test: bins/$(CONFIG)/chttp2_fake_security_request_response_with_binary_metadata_and_payload_test
chttp2_fake_security_request_response_with_metadata_and_payload_test: bins/$(CONFIG)/chttp2_fake_security_request_response_with_metadata_and_payload_test
chttp2_fake_security_request_response_with_payload_test: bins/$(CONFIG)/chttp2_fake_security_request_response_with_payload_test
chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test: bins/$(CONFIG)/chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test
chttp2_fake_security_simple_delayed_request_test: bins/$(CONFIG)/chttp2_fake_security_simple_delayed_request_test
chttp2_fake_security_simple_request_test: bins/$(CONFIG)/chttp2_fake_security_simple_request_test
chttp2_fake_security_thread_stress_test: bins/$(CONFIG)/chttp2_fake_security_thread_stress_test
chttp2_fake_security_writes_done_hangs_with_pending_read_test: bins/$(CONFIG)/chttp2_fake_security_writes_done_hangs_with_pending_read_test
chttp2_fullstack_cancel_after_accept_test: bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_test
chttp2_fullstack_cancel_after_accept_and_writes_closed_test: bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_and_writes_closed_test
chttp2_fullstack_cancel_after_invoke_test: bins/$(CONFIG)/chttp2_fullstack_cancel_after_invoke_test
chttp2_fullstack_cancel_before_invoke_test: bins/$(CONFIG)/chttp2_fullstack_cancel_before_invoke_test
chttp2_fullstack_cancel_in_a_vacuum_test: bins/$(CONFIG)/chttp2_fullstack_cancel_in_a_vacuum_test
chttp2_fullstack_census_simple_request_test: bins/$(CONFIG)/chttp2_fullstack_census_simple_request_test
chttp2_fullstack_disappearing_server_test: bins/$(CONFIG)/chttp2_fullstack_disappearing_server_test
chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test: bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test
chttp2_fullstack_early_server_shutdown_finishes_tags_test: bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_tags_test
chttp2_fullstack_invoke_large_request_test: bins/$(CONFIG)/chttp2_fullstack_invoke_large_request_test
chttp2_fullstack_max_concurrent_streams_test: bins/$(CONFIG)/chttp2_fullstack_max_concurrent_streams_test
chttp2_fullstack_no_op_test: bins/$(CONFIG)/chttp2_fullstack_no_op_test
chttp2_fullstack_ping_pong_streaming_test: bins/$(CONFIG)/chttp2_fullstack_ping_pong_streaming_test
chttp2_fullstack_request_response_with_binary_metadata_and_payload_test: bins/$(CONFIG)/chttp2_fullstack_request_response_with_binary_metadata_and_payload_test
chttp2_fullstack_request_response_with_metadata_and_payload_test: bins/$(CONFIG)/chttp2_fullstack_request_response_with_metadata_and_payload_test
chttp2_fullstack_request_response_with_payload_test: bins/$(CONFIG)/chttp2_fullstack_request_response_with_payload_test
chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test: bins/$(CONFIG)/chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test
chttp2_fullstack_simple_delayed_request_test: bins/$(CONFIG)/chttp2_fullstack_simple_delayed_request_test
chttp2_fullstack_simple_request_test: bins/$(CONFIG)/chttp2_fullstack_simple_request_test
chttp2_fullstack_thread_stress_test: bins/$(CONFIG)/chttp2_fullstack_thread_stress_test
chttp2_fullstack_writes_done_hangs_with_pending_read_test: bins/$(CONFIG)/chttp2_fullstack_writes_done_hangs_with_pending_read_test
chttp2_simple_ssl_fullstack_cancel_after_accept_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_test
chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test
chttp2_simple_ssl_fullstack_cancel_after_invoke_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_invoke_test
chttp2_simple_ssl_fullstack_cancel_before_invoke_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_before_invoke_test
chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test
chttp2_simple_ssl_fullstack_census_simple_request_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_census_simple_request_test
chttp2_simple_ssl_fullstack_disappearing_server_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_disappearing_server_test
chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test
chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test
chttp2_simple_ssl_fullstack_invoke_large_request_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_invoke_large_request_test
chttp2_simple_ssl_fullstack_max_concurrent_streams_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_max_concurrent_streams_test
chttp2_simple_ssl_fullstack_no_op_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_no_op_test
chttp2_simple_ssl_fullstack_ping_pong_streaming_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_ping_pong_streaming_test
chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test
chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test
chttp2_simple_ssl_fullstack_request_response_with_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_payload_test
chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test
chttp2_simple_ssl_fullstack_simple_delayed_request_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_delayed_request_test
chttp2_simple_ssl_fullstack_simple_request_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_request_test
chttp2_simple_ssl_fullstack_thread_stress_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_thread_stress_test
chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test: bins/$(CONFIG)/chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test
chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test
chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test
chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test
chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test
chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test
chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test
chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test
chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test
chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test
chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test
chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test
chttp2_simple_ssl_with_oauth2_fullstack_no_op_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_no_op_test
chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test
chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test
chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test
chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test
chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test
chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test
chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test
chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test
chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test: bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test
chttp2_socket_pair_cancel_after_accept_test: bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_test
chttp2_socket_pair_cancel_after_accept_and_writes_closed_test: bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_and_writes_closed_test
chttp2_socket_pair_cancel_after_invoke_test: bins/$(CONFIG)/chttp2_socket_pair_cancel_after_invoke_test
chttp2_socket_pair_cancel_before_invoke_test: bins/$(CONFIG)/chttp2_socket_pair_cancel_before_invoke_test
chttp2_socket_pair_cancel_in_a_vacuum_test: bins/$(CONFIG)/chttp2_socket_pair_cancel_in_a_vacuum_test
chttp2_socket_pair_census_simple_request_test: bins/$(CONFIG)/chttp2_socket_pair_census_simple_request_test
chttp2_socket_pair_disappearing_server_test: bins/$(CONFIG)/chttp2_socket_pair_disappearing_server_test
chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test: bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test
chttp2_socket_pair_early_server_shutdown_finishes_tags_test: bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_tags_test
chttp2_socket_pair_invoke_large_request_test: bins/$(CONFIG)/chttp2_socket_pair_invoke_large_request_test
chttp2_socket_pair_max_concurrent_streams_test: bins/$(CONFIG)/chttp2_socket_pair_max_concurrent_streams_test
chttp2_socket_pair_no_op_test: bins/$(CONFIG)/chttp2_socket_pair_no_op_test
chttp2_socket_pair_ping_pong_streaming_test: bins/$(CONFIG)/chttp2_socket_pair_ping_pong_streaming_test
chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test: bins/$(CONFIG)/chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test
chttp2_socket_pair_request_response_with_metadata_and_payload_test: bins/$(CONFIG)/chttp2_socket_pair_request_response_with_metadata_and_payload_test
chttp2_socket_pair_request_response_with_payload_test: bins/$(CONFIG)/chttp2_socket_pair_request_response_with_payload_test
chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test: bins/$(CONFIG)/chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test
chttp2_socket_pair_simple_delayed_request_test: bins/$(CONFIG)/chttp2_socket_pair_simple_delayed_request_test
chttp2_socket_pair_simple_request_test: bins/$(CONFIG)/chttp2_socket_pair_simple_request_test
chttp2_socket_pair_thread_stress_test: bins/$(CONFIG)/chttp2_socket_pair_thread_stress_test
chttp2_socket_pair_writes_done_hangs_with_pending_read_test: bins/$(CONFIG)/chttp2_socket_pair_writes_done_hangs_with_pending_read_test
chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test
chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test
chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test
chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test
chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test
chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test
chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test
chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test
chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test
chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test
chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test
chttp2_socket_pair_one_byte_at_a_time_no_op_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_no_op_test
chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test
chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test
chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test
chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test
chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test
chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test
chttp2_socket_pair_one_byte_at_a_time_simple_request_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_request_test
chttp2_socket_pair_one_byte_at_a_time_thread_stress_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_thread_stress_test
chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test: bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test

run_dep_checks:
	$(OPENSSL_ALPN_CHECK_CMD) || true
	$(ZLIB_CHECK_CMD) || true

third_party/zlib/libz.a:
	(cd third_party/zlib ; CFLAGS="-fPIC -fvisibility=hidden" ./configure --static)
	$(MAKE) -C third_party/zlib

third_party/openssl/libssl.a:
	(cd third_party/openssl ; CC="$(CC) -fPIC -fvisibility=hidden" ./config)
	$(MAKE) -C third_party/openssl build_crypto build_ssl

static: static_c static_cxx

static_c:  libs/$(CONFIG)/libgpr.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgrpc_unsecure.a

static_cxx:  libs/$(CONFIG)/libgrpc++.a

shared: shared_c shared_cxx

shared_c:  libs/$(CONFIG)/libgpr.$(SHARED_EXT) libs/$(CONFIG)/libgrpc.$(SHARED_EXT) libs/$(CONFIG)/libgrpc_unsecure.$(SHARED_EXT)

shared_cxx:  libs/$(CONFIG)/libgrpc++.$(SHARED_EXT)

privatelibs: privatelibs_c privatelibs_cxx

privatelibs_c:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a

privatelibs_cxx:  libs/$(CONFIG)/libgrpc++_test_util.a

buildtests: buildtests_c buildtests_cxx

buildtests_c: privatelibs_c bins/$(CONFIG)/grpc_byte_buffer_reader_test bins/$(CONFIG)/gpr_cancellable_test bins/$(CONFIG)/gpr_log_test bins/$(CONFIG)/gpr_useful_test bins/$(CONFIG)/gpr_cmdline_test bins/$(CONFIG)/gpr_histogram_test bins/$(CONFIG)/gpr_host_port_test bins/$(CONFIG)/gpr_slice_buffer_test bins/$(CONFIG)/gpr_slice_test bins/$(CONFIG)/gpr_string_test bins/$(CONFIG)/gpr_sync_test bins/$(CONFIG)/gpr_thd_test bins/$(CONFIG)/gpr_time_test bins/$(CONFIG)/murmur_hash_test bins/$(CONFIG)/grpc_stream_op_test bins/$(CONFIG)/alpn_test bins/$(CONFIG)/time_averaged_stats_test bins/$(CONFIG)/chttp2_stream_encoder_test bins/$(CONFIG)/hpack_table_test bins/$(CONFIG)/chttp2_stream_map_test bins/$(CONFIG)/hpack_parser_test bins/$(CONFIG)/transport_metadata_test bins/$(CONFIG)/chttp2_status_conversion_test bins/$(CONFIG)/chttp2_transport_end2end_test bins/$(CONFIG)/tcp_posix_test bins/$(CONFIG)/dualstack_socket_test bins/$(CONFIG)/no_server_test bins/$(CONFIG)/resolve_address_test bins/$(CONFIG)/sockaddr_utils_test bins/$(CONFIG)/tcp_server_posix_test bins/$(CONFIG)/tcp_client_posix_test bins/$(CONFIG)/grpc_channel_stack_test bins/$(CONFIG)/metadata_buffer_test bins/$(CONFIG)/grpc_completion_queue_test bins/$(CONFIG)/census_window_stats_test bins/$(CONFIG)/census_statistics_quick_test bins/$(CONFIG)/census_statistics_small_log_test bins/$(CONFIG)/census_statistics_performance_test bins/$(CONFIG)/census_statistics_multiple_writers_test bins/$(CONFIG)/census_statistics_multiple_writers_circular_buffer_test bins/$(CONFIG)/census_stub_test bins/$(CONFIG)/census_hash_table_test bins/$(CONFIG)/fling_server bins/$(CONFIG)/fling_client bins/$(CONFIG)/fling_test bins/$(CONFIG)/echo_server bins/$(CONFIG)/echo_client bins/$(CONFIG)/echo_test bins/$(CONFIG)/message_compress_test bins/$(CONFIG)/bin_encoder_test bins/$(CONFIG)/secure_endpoint_test bins/$(CONFIG)/httpcli_format_request_test bins/$(CONFIG)/httpcli_parser_test bins/$(CONFIG)/httpcli_test bins/$(CONFIG)/grpc_credentials_test bins/$(CONFIG)/grpc_base64_test bins/$(CONFIG)/grpc_json_token_test bins/$(CONFIG)/timeout_encoding_test bins/$(CONFIG)/fd_posix_test bins/$(CONFIG)/fling_stream_test bins/$(CONFIG)/lame_client_test bins/$(CONFIG)/alarm_test bins/$(CONFIG)/alarm_list_test bins/$(CONFIG)/alarm_heap_test bins/$(CONFIG)/time_test bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_test bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_and_writes_closed_test bins/$(CONFIG)/chttp2_fake_security_cancel_after_invoke_test bins/$(CONFIG)/chttp2_fake_security_cancel_before_invoke_test bins/$(CONFIG)/chttp2_fake_security_cancel_in_a_vacuum_test bins/$(CONFIG)/chttp2_fake_security_census_simple_request_test bins/$(CONFIG)/chttp2_fake_security_disappearing_server_test bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_tags_test bins/$(CONFIG)/chttp2_fake_security_invoke_large_request_test bins/$(CONFIG)/chttp2_fake_security_max_concurrent_streams_test bins/$(CONFIG)/chttp2_fake_security_no_op_test bins/$(CONFIG)/chttp2_fake_security_ping_pong_streaming_test bins/$(CONFIG)/chttp2_fake_security_request_response_with_binary_metadata_and_payload_test bins/$(CONFIG)/chttp2_fake_security_request_response_with_metadata_and_payload_test bins/$(CONFIG)/chttp2_fake_security_request_response_with_payload_test bins/$(CONFIG)/chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test bins/$(CONFIG)/chttp2_fake_security_simple_delayed_request_test bins/$(CONFIG)/chttp2_fake_security_simple_request_test bins/$(CONFIG)/chttp2_fake_security_thread_stress_test bins/$(CONFIG)/chttp2_fake_security_writes_done_hangs_with_pending_read_test bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_test bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_and_writes_closed_test bins/$(CONFIG)/chttp2_fullstack_cancel_after_invoke_test bins/$(CONFIG)/chttp2_fullstack_cancel_before_invoke_test bins/$(CONFIG)/chttp2_fullstack_cancel_in_a_vacuum_test bins/$(CONFIG)/chttp2_fullstack_census_simple_request_test bins/$(CONFIG)/chttp2_fullstack_disappearing_server_test bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_tags_test bins/$(CONFIG)/chttp2_fullstack_invoke_large_request_test bins/$(CONFIG)/chttp2_fullstack_max_concurrent_streams_test bins/$(CONFIG)/chttp2_fullstack_no_op_test bins/$(CONFIG)/chttp2_fullstack_ping_pong_streaming_test bins/$(CONFIG)/chttp2_fullstack_request_response_with_binary_metadata_and_payload_test bins/$(CONFIG)/chttp2_fullstack_request_response_with_metadata_and_payload_test bins/$(CONFIG)/chttp2_fullstack_request_response_with_payload_test bins/$(CONFIG)/chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test bins/$(CONFIG)/chttp2_fullstack_simple_delayed_request_test bins/$(CONFIG)/chttp2_fullstack_simple_request_test bins/$(CONFIG)/chttp2_fullstack_thread_stress_test bins/$(CONFIG)/chttp2_fullstack_writes_done_hangs_with_pending_read_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_invoke_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_before_invoke_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_census_simple_request_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_disappearing_server_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_invoke_large_request_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_max_concurrent_streams_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_no_op_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_ping_pong_streaming_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_payload_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_delayed_request_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_request_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_thread_stress_test bins/$(CONFIG)/chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_no_op_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_test bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_and_writes_closed_test bins/$(CONFIG)/chttp2_socket_pair_cancel_after_invoke_test bins/$(CONFIG)/chttp2_socket_pair_cancel_before_invoke_test bins/$(CONFIG)/chttp2_socket_pair_cancel_in_a_vacuum_test bins/$(CONFIG)/chttp2_socket_pair_census_simple_request_test bins/$(CONFIG)/chttp2_socket_pair_disappearing_server_test bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_tags_test bins/$(CONFIG)/chttp2_socket_pair_invoke_large_request_test bins/$(CONFIG)/chttp2_socket_pair_max_concurrent_streams_test bins/$(CONFIG)/chttp2_socket_pair_no_op_test bins/$(CONFIG)/chttp2_socket_pair_ping_pong_streaming_test bins/$(CONFIG)/chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test bins/$(CONFIG)/chttp2_socket_pair_request_response_with_metadata_and_payload_test bins/$(CONFIG)/chttp2_socket_pair_request_response_with_payload_test bins/$(CONFIG)/chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test bins/$(CONFIG)/chttp2_socket_pair_simple_delayed_request_test bins/$(CONFIG)/chttp2_socket_pair_simple_request_test bins/$(CONFIG)/chttp2_socket_pair_thread_stress_test bins/$(CONFIG)/chttp2_socket_pair_writes_done_hangs_with_pending_read_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_no_op_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_request_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_thread_stress_test bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test

buildtests_cxx: privatelibs_cxx bins/$(CONFIG)/thread_pool_test bins/$(CONFIG)/status_test bins/$(CONFIG)/sync_client_async_server_test bins/$(CONFIG)/qps_client bins/$(CONFIG)/qps_server bins/$(CONFIG)/interop_server bins/$(CONFIG)/interop_client bins/$(CONFIG)/end2end_test bins/$(CONFIG)/channel_arguments_test bins/$(CONFIG)/credentials_test

test: test_c test_cxx

test_c: buildtests_c
	$(E) "[RUN]     Testing grpc_byte_buffer_reader_test"
	$(Q) ./bins/$(CONFIG)/grpc_byte_buffer_reader_test || ( echo test grpc_byte_buffer_reader_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_cancellable_test"
	$(Q) ./bins/$(CONFIG)/gpr_cancellable_test || ( echo test gpr_cancellable_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_log_test"
	$(Q) ./bins/$(CONFIG)/gpr_log_test || ( echo test gpr_log_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_useful_test"
	$(Q) ./bins/$(CONFIG)/gpr_useful_test || ( echo test gpr_useful_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_cmdline_test"
	$(Q) ./bins/$(CONFIG)/gpr_cmdline_test || ( echo test gpr_cmdline_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_histogram_test"
	$(Q) ./bins/$(CONFIG)/gpr_histogram_test || ( echo test gpr_histogram_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_host_port_test"
	$(Q) ./bins/$(CONFIG)/gpr_host_port_test || ( echo test gpr_host_port_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_slice_buffer_test"
	$(Q) ./bins/$(CONFIG)/gpr_slice_buffer_test || ( echo test gpr_slice_buffer_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_slice_test"
	$(Q) ./bins/$(CONFIG)/gpr_slice_test || ( echo test gpr_slice_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_string_test"
	$(Q) ./bins/$(CONFIG)/gpr_string_test || ( echo test gpr_string_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_sync_test"
	$(Q) ./bins/$(CONFIG)/gpr_sync_test || ( echo test gpr_sync_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_thd_test"
	$(Q) ./bins/$(CONFIG)/gpr_thd_test || ( echo test gpr_thd_test failed ; exit 1 )
	$(E) "[RUN]     Testing gpr_time_test"
	$(Q) ./bins/$(CONFIG)/gpr_time_test || ( echo test gpr_time_test failed ; exit 1 )
	$(E) "[RUN]     Testing murmur_hash_test"
	$(Q) ./bins/$(CONFIG)/murmur_hash_test || ( echo test murmur_hash_test failed ; exit 1 )
	$(E) "[RUN]     Testing grpc_stream_op_test"
	$(Q) ./bins/$(CONFIG)/grpc_stream_op_test || ( echo test grpc_stream_op_test failed ; exit 1 )
	$(E) "[RUN]     Testing alpn_test"
	$(Q) ./bins/$(CONFIG)/alpn_test || ( echo test alpn_test failed ; exit 1 )
	$(E) "[RUN]     Testing time_averaged_stats_test"
	$(Q) ./bins/$(CONFIG)/time_averaged_stats_test || ( echo test time_averaged_stats_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_stream_encoder_test"
	$(Q) ./bins/$(CONFIG)/chttp2_stream_encoder_test || ( echo test chttp2_stream_encoder_test failed ; exit 1 )
	$(E) "[RUN]     Testing hpack_table_test"
	$(Q) ./bins/$(CONFIG)/hpack_table_test || ( echo test hpack_table_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_stream_map_test"
	$(Q) ./bins/$(CONFIG)/chttp2_stream_map_test || ( echo test chttp2_stream_map_test failed ; exit 1 )
	$(E) "[RUN]     Testing hpack_parser_test"
	$(Q) ./bins/$(CONFIG)/hpack_parser_test || ( echo test hpack_parser_test failed ; exit 1 )
	$(E) "[RUN]     Testing transport_metadata_test"
	$(Q) ./bins/$(CONFIG)/transport_metadata_test || ( echo test transport_metadata_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_status_conversion_test"
	$(Q) ./bins/$(CONFIG)/chttp2_status_conversion_test || ( echo test chttp2_status_conversion_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_transport_end2end_test"
	$(Q) ./bins/$(CONFIG)/chttp2_transport_end2end_test || ( echo test chttp2_transport_end2end_test failed ; exit 1 )
	$(E) "[RUN]     Testing tcp_posix_test"
	$(Q) ./bins/$(CONFIG)/tcp_posix_test || ( echo test tcp_posix_test failed ; exit 1 )
	$(E) "[RUN]     Testing dualstack_socket_test"
	$(Q) ./bins/$(CONFIG)/dualstack_socket_test || ( echo test dualstack_socket_test failed ; exit 1 )
	$(E) "[RUN]     Testing no_server_test"
	$(Q) ./bins/$(CONFIG)/no_server_test || ( echo test no_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing resolve_address_test"
	$(Q) ./bins/$(CONFIG)/resolve_address_test || ( echo test resolve_address_test failed ; exit 1 )
	$(E) "[RUN]     Testing sockaddr_utils_test"
	$(Q) ./bins/$(CONFIG)/sockaddr_utils_test || ( echo test sockaddr_utils_test failed ; exit 1 )
	$(E) "[RUN]     Testing tcp_server_posix_test"
	$(Q) ./bins/$(CONFIG)/tcp_server_posix_test || ( echo test tcp_server_posix_test failed ; exit 1 )
	$(E) "[RUN]     Testing tcp_client_posix_test"
	$(Q) ./bins/$(CONFIG)/tcp_client_posix_test || ( echo test tcp_client_posix_test failed ; exit 1 )
	$(E) "[RUN]     Testing grpc_channel_stack_test"
	$(Q) ./bins/$(CONFIG)/grpc_channel_stack_test || ( echo test grpc_channel_stack_test failed ; exit 1 )
	$(E) "[RUN]     Testing metadata_buffer_test"
	$(Q) ./bins/$(CONFIG)/metadata_buffer_test || ( echo test metadata_buffer_test failed ; exit 1 )
	$(E) "[RUN]     Testing grpc_completion_queue_test"
	$(Q) ./bins/$(CONFIG)/grpc_completion_queue_test || ( echo test grpc_completion_queue_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_window_stats_test"
	$(Q) ./bins/$(CONFIG)/census_window_stats_test || ( echo test census_window_stats_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_statistics_quick_test"
	$(Q) ./bins/$(CONFIG)/census_statistics_quick_test || ( echo test census_statistics_quick_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_statistics_small_log_test"
	$(Q) ./bins/$(CONFIG)/census_statistics_small_log_test || ( echo test census_statistics_small_log_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_statistics_performance_test"
	$(Q) ./bins/$(CONFIG)/census_statistics_performance_test || ( echo test census_statistics_performance_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_statistics_multiple_writers_test"
	$(Q) ./bins/$(CONFIG)/census_statistics_multiple_writers_test || ( echo test census_statistics_multiple_writers_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_statistics_multiple_writers_circular_buffer_test"
	$(Q) ./bins/$(CONFIG)/census_statistics_multiple_writers_circular_buffer_test || ( echo test census_statistics_multiple_writers_circular_buffer_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_stub_test"
	$(Q) ./bins/$(CONFIG)/census_stub_test || ( echo test census_stub_test failed ; exit 1 )
	$(E) "[RUN]     Testing census_hash_table_test"
	$(Q) ./bins/$(CONFIG)/census_hash_table_test || ( echo test census_hash_table_test failed ; exit 1 )
	$(E) "[RUN]     Testing fling_test"
	$(Q) ./bins/$(CONFIG)/fling_test || ( echo test fling_test failed ; exit 1 )
	$(E) "[RUN]     Testing echo_test"
	$(Q) ./bins/$(CONFIG)/echo_test || ( echo test echo_test failed ; exit 1 )
	$(E) "[RUN]     Testing message_compress_test"
	$(Q) ./bins/$(CONFIG)/message_compress_test || ( echo test message_compress_test failed ; exit 1 )
	$(E) "[RUN]     Testing bin_encoder_test"
	$(Q) ./bins/$(CONFIG)/bin_encoder_test || ( echo test bin_encoder_test failed ; exit 1 )
	$(E) "[RUN]     Testing secure_endpoint_test"
	$(Q) ./bins/$(CONFIG)/secure_endpoint_test || ( echo test secure_endpoint_test failed ; exit 1 )
	$(E) "[RUN]     Testing httpcli_format_request_test"
	$(Q) ./bins/$(CONFIG)/httpcli_format_request_test || ( echo test httpcli_format_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing httpcli_parser_test"
	$(Q) ./bins/$(CONFIG)/httpcli_parser_test || ( echo test httpcli_parser_test failed ; exit 1 )
	$(E) "[RUN]     Testing httpcli_test"
	$(Q) ./bins/$(CONFIG)/httpcli_test || ( echo test httpcli_test failed ; exit 1 )
	$(E) "[RUN]     Testing grpc_credentials_test"
	$(Q) ./bins/$(CONFIG)/grpc_credentials_test || ( echo test grpc_credentials_test failed ; exit 1 )
	$(E) "[RUN]     Testing grpc_base64_test"
	$(Q) ./bins/$(CONFIG)/grpc_base64_test || ( echo test grpc_base64_test failed ; exit 1 )
	$(E) "[RUN]     Testing grpc_json_token_test"
	$(Q) ./bins/$(CONFIG)/grpc_json_token_test || ( echo test grpc_json_token_test failed ; exit 1 )
	$(E) "[RUN]     Testing timeout_encoding_test"
	$(Q) ./bins/$(CONFIG)/timeout_encoding_test || ( echo test timeout_encoding_test failed ; exit 1 )
	$(E) "[RUN]     Testing fd_posix_test"
	$(Q) ./bins/$(CONFIG)/fd_posix_test || ( echo test fd_posix_test failed ; exit 1 )
	$(E) "[RUN]     Testing fling_stream_test"
	$(Q) ./bins/$(CONFIG)/fling_stream_test || ( echo test fling_stream_test failed ; exit 1 )
	$(E) "[RUN]     Testing lame_client_test"
	$(Q) ./bins/$(CONFIG)/lame_client_test || ( echo test lame_client_test failed ; exit 1 )
	$(E) "[RUN]     Testing alarm_test"
	$(Q) ./bins/$(CONFIG)/alarm_test || ( echo test alarm_test failed ; exit 1 )
	$(E) "[RUN]     Testing alarm_list_test"
	$(Q) ./bins/$(CONFIG)/alarm_list_test || ( echo test alarm_list_test failed ; exit 1 )
	$(E) "[RUN]     Testing alarm_heap_test"
	$(Q) ./bins/$(CONFIG)/alarm_heap_test || ( echo test alarm_heap_test failed ; exit 1 )
	$(E) "[RUN]     Testing time_test"
	$(Q) ./bins/$(CONFIG)/time_test || ( echo test time_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_cancel_after_accept_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_test || ( echo test chttp2_fake_security_cancel_after_accept_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_cancel_after_accept_and_writes_closed_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_and_writes_closed_test || ( echo test chttp2_fake_security_cancel_after_accept_and_writes_closed_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_cancel_after_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_cancel_after_invoke_test || ( echo test chttp2_fake_security_cancel_after_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_cancel_before_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_cancel_before_invoke_test || ( echo test chttp2_fake_security_cancel_before_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_cancel_in_a_vacuum_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_cancel_in_a_vacuum_test || ( echo test chttp2_fake_security_cancel_in_a_vacuum_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_census_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_census_simple_request_test || ( echo test chttp2_fake_security_census_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_disappearing_server_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_disappearing_server_test || ( echo test chttp2_fake_security_disappearing_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test || ( echo test chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_early_server_shutdown_finishes_tags_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_tags_test || ( echo test chttp2_fake_security_early_server_shutdown_finishes_tags_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_invoke_large_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_invoke_large_request_test || ( echo test chttp2_fake_security_invoke_large_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_max_concurrent_streams_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_max_concurrent_streams_test || ( echo test chttp2_fake_security_max_concurrent_streams_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_no_op_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_no_op_test || ( echo test chttp2_fake_security_no_op_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_ping_pong_streaming_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_ping_pong_streaming_test || ( echo test chttp2_fake_security_ping_pong_streaming_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_request_response_with_binary_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_request_response_with_binary_metadata_and_payload_test || ( echo test chttp2_fake_security_request_response_with_binary_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_request_response_with_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_request_response_with_metadata_and_payload_test || ( echo test chttp2_fake_security_request_response_with_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_request_response_with_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_request_response_with_payload_test || ( echo test chttp2_fake_security_request_response_with_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test || ( echo test chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_simple_delayed_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_simple_delayed_request_test || ( echo test chttp2_fake_security_simple_delayed_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_simple_request_test || ( echo test chttp2_fake_security_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_thread_stress_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_thread_stress_test || ( echo test chttp2_fake_security_thread_stress_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fake_security_writes_done_hangs_with_pending_read_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fake_security_writes_done_hangs_with_pending_read_test || ( echo test chttp2_fake_security_writes_done_hangs_with_pending_read_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_cancel_after_accept_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_test || ( echo test chttp2_fullstack_cancel_after_accept_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_cancel_after_accept_and_writes_closed_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_and_writes_closed_test || ( echo test chttp2_fullstack_cancel_after_accept_and_writes_closed_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_cancel_after_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_cancel_after_invoke_test || ( echo test chttp2_fullstack_cancel_after_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_cancel_before_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_cancel_before_invoke_test || ( echo test chttp2_fullstack_cancel_before_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_cancel_in_a_vacuum_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_cancel_in_a_vacuum_test || ( echo test chttp2_fullstack_cancel_in_a_vacuum_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_census_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_census_simple_request_test || ( echo test chttp2_fullstack_census_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_disappearing_server_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_disappearing_server_test || ( echo test chttp2_fullstack_disappearing_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test || ( echo test chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_early_server_shutdown_finishes_tags_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_tags_test || ( echo test chttp2_fullstack_early_server_shutdown_finishes_tags_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_invoke_large_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_invoke_large_request_test || ( echo test chttp2_fullstack_invoke_large_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_max_concurrent_streams_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_max_concurrent_streams_test || ( echo test chttp2_fullstack_max_concurrent_streams_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_no_op_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_no_op_test || ( echo test chttp2_fullstack_no_op_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_ping_pong_streaming_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_ping_pong_streaming_test || ( echo test chttp2_fullstack_ping_pong_streaming_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_request_response_with_binary_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_request_response_with_binary_metadata_and_payload_test || ( echo test chttp2_fullstack_request_response_with_binary_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_request_response_with_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_request_response_with_metadata_and_payload_test || ( echo test chttp2_fullstack_request_response_with_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_request_response_with_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_request_response_with_payload_test || ( echo test chttp2_fullstack_request_response_with_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test || ( echo test chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_simple_delayed_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_simple_delayed_request_test || ( echo test chttp2_fullstack_simple_delayed_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_simple_request_test || ( echo test chttp2_fullstack_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_thread_stress_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_thread_stress_test || ( echo test chttp2_fullstack_thread_stress_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_fullstack_writes_done_hangs_with_pending_read_test"
	$(Q) ./bins/$(CONFIG)/chttp2_fullstack_writes_done_hangs_with_pending_read_test || ( echo test chttp2_fullstack_writes_done_hangs_with_pending_read_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_cancel_after_accept_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_test || ( echo test chttp2_simple_ssl_fullstack_cancel_after_accept_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test || ( echo test chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_cancel_after_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_invoke_test || ( echo test chttp2_simple_ssl_fullstack_cancel_after_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_cancel_before_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_before_invoke_test || ( echo test chttp2_simple_ssl_fullstack_cancel_before_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test || ( echo test chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_census_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_census_simple_request_test || ( echo test chttp2_simple_ssl_fullstack_census_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_disappearing_server_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_disappearing_server_test || ( echo test chttp2_simple_ssl_fullstack_disappearing_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test || ( echo test chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test || ( echo test chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_invoke_large_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_invoke_large_request_test || ( echo test chttp2_simple_ssl_fullstack_invoke_large_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_max_concurrent_streams_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_max_concurrent_streams_test || ( echo test chttp2_simple_ssl_fullstack_max_concurrent_streams_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_no_op_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_no_op_test || ( echo test chttp2_simple_ssl_fullstack_no_op_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_ping_pong_streaming_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_ping_pong_streaming_test || ( echo test chttp2_simple_ssl_fullstack_ping_pong_streaming_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test || ( echo test chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test || ( echo test chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_request_response_with_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_payload_test || ( echo test chttp2_simple_ssl_fullstack_request_response_with_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test || ( echo test chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_simple_delayed_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_delayed_request_test || ( echo test chttp2_simple_ssl_fullstack_simple_delayed_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_request_test || ( echo test chttp2_simple_ssl_fullstack_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_thread_stress_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_thread_stress_test || ( echo test chttp2_simple_ssl_fullstack_thread_stress_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test || ( echo test chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_no_op_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_no_op_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_no_op_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test"
	$(Q) ./bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test || ( echo test chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_cancel_after_accept_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_test || ( echo test chttp2_socket_pair_cancel_after_accept_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_cancel_after_accept_and_writes_closed_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_and_writes_closed_test || ( echo test chttp2_socket_pair_cancel_after_accept_and_writes_closed_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_cancel_after_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_cancel_after_invoke_test || ( echo test chttp2_socket_pair_cancel_after_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_cancel_before_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_cancel_before_invoke_test || ( echo test chttp2_socket_pair_cancel_before_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_cancel_in_a_vacuum_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_cancel_in_a_vacuum_test || ( echo test chttp2_socket_pair_cancel_in_a_vacuum_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_census_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_census_simple_request_test || ( echo test chttp2_socket_pair_census_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_disappearing_server_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_disappearing_server_test || ( echo test chttp2_socket_pair_disappearing_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test || ( echo test chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_early_server_shutdown_finishes_tags_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_tags_test || ( echo test chttp2_socket_pair_early_server_shutdown_finishes_tags_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_invoke_large_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_invoke_large_request_test || ( echo test chttp2_socket_pair_invoke_large_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_max_concurrent_streams_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_max_concurrent_streams_test || ( echo test chttp2_socket_pair_max_concurrent_streams_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_no_op_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_no_op_test || ( echo test chttp2_socket_pair_no_op_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_ping_pong_streaming_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_ping_pong_streaming_test || ( echo test chttp2_socket_pair_ping_pong_streaming_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test || ( echo test chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_request_response_with_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_request_response_with_metadata_and_payload_test || ( echo test chttp2_socket_pair_request_response_with_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_request_response_with_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_request_response_with_payload_test || ( echo test chttp2_socket_pair_request_response_with_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test || ( echo test chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_simple_delayed_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_simple_delayed_request_test || ( echo test chttp2_socket_pair_simple_delayed_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_simple_request_test || ( echo test chttp2_socket_pair_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_thread_stress_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_thread_stress_test || ( echo test chttp2_socket_pair_thread_stress_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_writes_done_hangs_with_pending_read_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_writes_done_hangs_with_pending_read_test || ( echo test chttp2_socket_pair_writes_done_hangs_with_pending_read_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_no_op_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_no_op_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_no_op_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_simple_request_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_request_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_simple_request_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_thread_stress_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_thread_stress_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_thread_stress_test failed ; exit 1 )
	$(E) "[RUN]     Testing chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test"
	$(Q) ./bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test || ( echo test chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test failed ; exit 1 )


test_cxx: buildtests_cxx
	$(E) "[RUN]     Testing thread_pool_test"
	$(Q) ./bins/$(CONFIG)/thread_pool_test || ( echo test thread_pool_test failed ; exit 1 )
	$(E) "[RUN]     Testing status_test"
	$(Q) ./bins/$(CONFIG)/status_test || ( echo test status_test failed ; exit 1 )
	$(E) "[RUN]     Testing sync_client_async_server_test"
	$(Q) ./bins/$(CONFIG)/sync_client_async_server_test || ( echo test sync_client_async_server_test failed ; exit 1 )
	$(E) "[RUN]     Testing qps_client"
	$(Q) ./bins/$(CONFIG)/qps_client || ( echo test qps_client failed ; exit 1 )
	$(E) "[RUN]     Testing qps_server"
	$(Q) ./bins/$(CONFIG)/qps_server || ( echo test qps_server failed ; exit 1 )
	$(E) "[RUN]     Testing end2end_test"
	$(Q) ./bins/$(CONFIG)/end2end_test || ( echo test end2end_test failed ; exit 1 )
	$(E) "[RUN]     Testing channel_arguments_test"
	$(Q) ./bins/$(CONFIG)/channel_arguments_test || ( echo test channel_arguments_test failed ; exit 1 )
	$(E) "[RUN]     Testing credentials_test"
	$(Q) ./bins/$(CONFIG)/credentials_test || ( echo test credentials_test failed ; exit 1 )


tools: privatelibs bins/$(CONFIG)/gen_hpack_tables bins/$(CONFIG)/grpc_fetch_oauth2

buildbenchmarks: privatelibs bins/$(CONFIG)/grpc_completion_queue_benchmark bins/$(CONFIG)/low_level_ping_pong_benchmark

benchmarks: buildbenchmarks

strip: strip-static strip-shared

strip-static: strip-static_c strip-static_cxx

strip-shared: strip-shared_c strip-shared_cxx

strip-static_c: static_c
	$(E) "[STRIP]   Stripping libgpr.a"
	$(Q) $(STRIP) libs/$(CONFIG)/libgpr.a
	$(E) "[STRIP]   Stripping libgrpc.a"
	$(Q) $(STRIP) libs/$(CONFIG)/libgrpc.a
	$(E) "[STRIP]   Stripping libgrpc_unsecure.a"
	$(Q) $(STRIP) libs/$(CONFIG)/libgrpc_unsecure.a

strip-static_cxx: static_cxx
	$(E) "[STRIP]   Stripping libgrpc++.a"
	$(Q) $(STRIP) libs/$(CONFIG)/libgrpc++.a

strip-shared_c: shared_c
	$(E) "[STRIP]   Stripping libgpr.so"
	$(Q) $(STRIP) libs/$(CONFIG)/libgpr.$(SHARED_EXT)
	$(E) "[STRIP]   Stripping libgrpc.so"
	$(Q) $(STRIP) libs/$(CONFIG)/libgrpc.$(SHARED_EXT)
	$(E) "[STRIP]   Stripping libgrpc_unsecure.so"
	$(Q) $(STRIP) libs/$(CONFIG)/libgrpc_unsecure.$(SHARED_EXT)

strip-shared_cxx: shared_cxx
	$(E) "[STRIP]   Stripping libgrpc++.so"
	$(Q) $(STRIP) libs/$(CONFIG)/libgrpc++.$(SHARED_EXT)

gens/test/cpp/interop/empty.pb.cc: test/cpp/interop/empty.proto $(PROTOC_PLUGINS)
	$(E) "[PROTOC]  Generating protobuf CC file from $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(PROTOC) --cpp_out=gens --grpc_out=gens --plugin=protoc-gen-grpc=bins/$(CONFIG)/cpp_plugin $<

gens/test/cpp/interop/messages.pb.cc: test/cpp/interop/messages.proto $(PROTOC_PLUGINS)
	$(E) "[PROTOC]  Generating protobuf CC file from $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(PROTOC) --cpp_out=gens --grpc_out=gens --plugin=protoc-gen-grpc=bins/$(CONFIG)/cpp_plugin $<

gens/test/cpp/interop/test.pb.cc: test/cpp/interop/test.proto $(PROTOC_PLUGINS)
	$(E) "[PROTOC]  Generating protobuf CC file from $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(PROTOC) --cpp_out=gens --grpc_out=gens --plugin=protoc-gen-grpc=bins/$(CONFIG)/cpp_plugin $<

gens/test/cpp/qps/qpstest.pb.cc: test/cpp/qps/qpstest.proto $(PROTOC_PLUGINS)
	$(E) "[PROTOC]  Generating protobuf CC file from $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(PROTOC) --cpp_out=gens --grpc_out=gens --plugin=protoc-gen-grpc=bins/$(CONFIG)/cpp_plugin $<

gens/test/cpp/util/echo.pb.cc: test/cpp/util/echo.proto $(PROTOC_PLUGINS)
	$(E) "[PROTOC]  Generating protobuf CC file from $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(PROTOC) --cpp_out=gens --grpc_out=gens --plugin=protoc-gen-grpc=bins/$(CONFIG)/cpp_plugin $<

gens/test/cpp/util/echo_duplicate.pb.cc: test/cpp/util/echo_duplicate.proto $(PROTOC_PLUGINS)
	$(E) "[PROTOC]  Generating protobuf CC file from $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(PROTOC) --cpp_out=gens --grpc_out=gens --plugin=protoc-gen-grpc=bins/$(CONFIG)/cpp_plugin $<

gens/test/cpp/util/messages.pb.cc: test/cpp/util/messages.proto $(PROTOC_PLUGINS)
	$(E) "[PROTOC]  Generating protobuf CC file from $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(PROTOC) --cpp_out=gens --grpc_out=gens --plugin=protoc-gen-grpc=bins/$(CONFIG)/cpp_plugin $<


objs/$(CONFIG)/%.o : %.c
	$(E) "[C]       Compiling $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MF $(addsuffix .dep, $(basename $@)) -c -o $@ $<

objs/$(CONFIG)/%.o : gens/%.pb.cc
	$(E) "[CXX]     Compiling $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -MF $(addsuffix .dep, $(basename $@)) -c -o $@ $<

objs/$(CONFIG)/src/compiler/%.o : src/compiler/%.cc
	$(E) "[HOSTCXX] Compiling $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(HOST_CXX) $(HOST_CXXFLAGS) $(HOST_CPPFLAGS) -MMD -MF $(addsuffix .dep, $(basename $@)) -c -o $@ $<

objs/$(CONFIG)/%.o : %.cc
	$(E) "[CXX]     Compiling $<"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -MF $(addsuffix .dep, $(basename $@)) -c -o $@ $<


install: install_c install_cxx

install_c: install-headers_c install-static_c install-shared_c

install_cxx: install-headers_cxx install-static_cxx install-shared_cxx

install-headers: install-headers_c install-headers_cxx

install-headers_c:
	$(E) "[INSTALL] Installing public C headers"
	$(Q) $(foreach h, $(PUBLIC_HEADERS_C), $(INSTALL) $(h) $(prefix)/$(h) && ) exit 0 || exit 1

install-headers_cxx:
	$(E) "[INSTALL] Installing public C++ headers"
	$(Q) $(foreach h, $(PUBLIC_HEADERS_CXX), $(INSTALL) $(h) $(prefix)/$(h) && ) exit 0 || exit 1

install-static: install-static_c install-static_cxx

install-static_c: static_c strip-static_c
	$(E) "[INSTALL] Installing libgpr.a"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgpr.a $(prefix)/lib/libgpr.a
	$(E) "[INSTALL] Installing libgrpc.a"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc.a $(prefix)/lib/libgrpc.a
	$(E) "[INSTALL] Installing libgrpc_unsecure.a"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc_unsecure.a $(prefix)/lib/libgrpc_unsecure.a

install-static_cxx: static_cxx strip-static_cxx
	$(E) "[INSTALL] Installing libgrpc++.a"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc++.a $(prefix)/lib/libgrpc++.a

install-shared_c: shared_c strip-shared_c
ifeq ($(SYSTEM),MINGW32)
	$(E) "[INSTALL] Installing gpr.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/gpr.$(SHARED_EXT) $(prefix)/lib/gpr.$(SHARED_EXT)
	$(Q) $(INSTALL) libs/$(CONFIG)/libgpr-imp.a $(prefix)/lib/libgpr-imp.a
else
	$(E) "[INSTALL] Installing libgpr.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgpr.$(SHARED_EXT) $(prefix)/lib/libgpr.$(SHARED_EXT)
ifneq ($(SYSTEM),Darwin)
	$(Q) ln -sf libgpr.$(SHARED_EXT) $(prefix)/lib/libgpr.so
endif
endif
ifeq ($(SYSTEM),MINGW32)
	$(E) "[INSTALL] Installing grpc.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/grpc.$(SHARED_EXT) $(prefix)/lib/grpc.$(SHARED_EXT)
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc-imp.a $(prefix)/lib/libgrpc-imp.a
else
	$(E) "[INSTALL] Installing libgrpc.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc.$(SHARED_EXT) $(prefix)/lib/libgrpc.$(SHARED_EXT)
ifneq ($(SYSTEM),Darwin)
	$(Q) ln -sf libgrpc.$(SHARED_EXT) $(prefix)/lib/libgrpc.so
endif
endif
ifeq ($(SYSTEM),MINGW32)
	$(E) "[INSTALL] Installing grpc_unsecure.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/grpc_unsecure.$(SHARED_EXT) $(prefix)/lib/grpc_unsecure.$(SHARED_EXT)
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc_unsecure-imp.a $(prefix)/lib/libgrpc_unsecure-imp.a
else
	$(E) "[INSTALL] Installing libgrpc_unsecure.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc_unsecure.$(SHARED_EXT) $(prefix)/lib/libgrpc_unsecure.$(SHARED_EXT)
ifneq ($(SYSTEM),Darwin)
	$(Q) ln -sf libgrpc_unsecure.$(SHARED_EXT) $(prefix)/lib/libgrpc_unsecure.so
endif
endif
ifneq ($(SYSTEM),MINGW32)
ifneq ($(SYSTEM),Darwin)
	$(Q) ldconfig
endif
endif

install-shared_cxx: shared_cxx strip-shared_cxx
ifeq ($(SYSTEM),MINGW32)
	$(E) "[INSTALL] Installing grpc++.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/grpc++.$(SHARED_EXT) $(prefix)/lib/grpc++.$(SHARED_EXT)
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc++-imp.a $(prefix)/lib/libgrpc++-imp.a
else
	$(E) "[INSTALL] Installing libgrpc++.$(SHARED_EXT)"
	$(Q) $(INSTALL) libs/$(CONFIG)/libgrpc++.$(SHARED_EXT) $(prefix)/lib/libgrpc++.$(SHARED_EXT)
ifneq ($(SYSTEM),Darwin)
	$(Q) ln -sf libgrpc++.$(SHARED_EXT) $(prefix)/lib/libgrpc++.so
endif
endif
ifneq ($(SYSTEM),MINGW32)
ifneq ($(SYSTEM),Darwin)
	$(Q) ldconfig
endif
endif

clean:
	$(Q) $(RM) -rf objs libs bins gens


# The various libraries


LIBGPR_SRC = \
    src/core/support/alloc.c \
    src/core/support/cancellable.c \
    src/core/support/cmdline.c \
    src/core/support/cpu_linux.c \
    src/core/support/cpu_posix.c \
    src/core/support/histogram.c \
    src/core/support/host_port.c \
    src/core/support/log_android.c \
    src/core/support/log.c \
    src/core/support/log_linux.c \
    src/core/support/log_posix.c \
    src/core/support/log_win32.c \
    src/core/support/murmur_hash.c \
    src/core/support/slice_buffer.c \
    src/core/support/slice.c \
    src/core/support/string.c \
    src/core/support/string_posix.c \
    src/core/support/string_win32.c \
    src/core/support/sync.c \
    src/core/support/sync_posix.c \
    src/core/support/sync_win32.c \
    src/core/support/thd_posix.c \
    src/core/support/thd_win32.c \
    src/core/support/time.c \
    src/core/support/time_posix.c \
    src/core/support/time_win32.c \

PUBLIC_HEADERS_C += \
    include/grpc/support/alloc.h \
    include/grpc/support/atm_gcc_atomic.h \
    include/grpc/support/atm_gcc_sync.h \
    include/grpc/support/atm.h \
    include/grpc/support/atm_win32.h \
    include/grpc/support/cancellable_platform.h \
    include/grpc/support/cmdline.h \
    include/grpc/support/histogram.h \
    include/grpc/support/host_port.h \
    include/grpc/support/log.h \
    include/grpc/support/port_platform.h \
    include/grpc/support/slice_buffer.h \
    include/grpc/support/slice.h \
    include/grpc/support/string.h \
    include/grpc/support/sync_generic.h \
    include/grpc/support/sync.h \
    include/grpc/support/sync_posix.h \
    include/grpc/support/sync_win32.h \
    include/grpc/support/thd.h \
    include/grpc/support/thd_posix.h \
    include/grpc/support/thd_win32.h \
    include/grpc/support/time.h \
    include/grpc/support/time_posix.h \
    include/grpc/support/time_win32.h \
    include/grpc/support/useful.h \

LIBGPR_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBGPR_SRC))))

libs/$(CONFIG)/libgpr.a: $(LIBGPR_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libgpr.a $(LIBGPR_OBJS)



ifeq ($(SYSTEM),MINGW32)
libs/$(CONFIG)/gpr.$(SHARED_EXT): $(LIBGPR_OBJS) 
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,--output-def=libs/$(CONFIG)/gpr.def -Wl,--out-implib=libs/$(CONFIG)/libgpr-imp.a -o libs/$(CONFIG)/gpr.$(SHARED_EXT) $(LIBGPR_OBJS) $(LDLIBS)
else
libs/$(CONFIG)/libgpr.$(SHARED_EXT): $(LIBGPR_OBJS) 
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
ifeq ($(SYSTEM),Darwin)
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -dynamiclib -o libs/$(CONFIG)/libgpr.$(SHARED_EXT) $(LIBGPR_OBJS) $(LDLIBS)
else
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,-soname,libgpr.so.0 -o libs/$(CONFIG)/libgpr.$(SHARED_EXT) $(LIBGPR_OBJS) $(LDLIBS)
	$(Q) ln -sf libgpr.$(SHARED_EXT) libs/$(CONFIG)/libgpr.so
endif
endif


ifneq ($(NO_DEPS),true)
-include $(LIBGPR_OBJS:.o=.dep)
endif

objs/$(CONFIG)/src/core/support/alloc.o: 
objs/$(CONFIG)/src/core/support/cancellable.o: 
objs/$(CONFIG)/src/core/support/cmdline.o: 
objs/$(CONFIG)/src/core/support/cpu_linux.o: 
objs/$(CONFIG)/src/core/support/cpu_posix.o: 
objs/$(CONFIG)/src/core/support/histogram.o: 
objs/$(CONFIG)/src/core/support/host_port.o: 
objs/$(CONFIG)/src/core/support/log_android.o: 
objs/$(CONFIG)/src/core/support/log.o: 
objs/$(CONFIG)/src/core/support/log_linux.o: 
objs/$(CONFIG)/src/core/support/log_posix.o: 
objs/$(CONFIG)/src/core/support/log_win32.o: 
objs/$(CONFIG)/src/core/support/murmur_hash.o: 
objs/$(CONFIG)/src/core/support/slice_buffer.o: 
objs/$(CONFIG)/src/core/support/slice.o: 
objs/$(CONFIG)/src/core/support/string.o: 
objs/$(CONFIG)/src/core/support/string_posix.o: 
objs/$(CONFIG)/src/core/support/string_win32.o: 
objs/$(CONFIG)/src/core/support/sync.o: 
objs/$(CONFIG)/src/core/support/sync_posix.o: 
objs/$(CONFIG)/src/core/support/sync_win32.o: 
objs/$(CONFIG)/src/core/support/thd_posix.o: 
objs/$(CONFIG)/src/core/support/thd_win32.o: 
objs/$(CONFIG)/src/core/support/time.o: 
objs/$(CONFIG)/src/core/support/time_posix.o: 
objs/$(CONFIG)/src/core/support/time_win32.o: 


LIBGRPC_SRC = \
    src/core/security/auth.c \
    src/core/security/base64.c \
    src/core/security/credentials.c \
    src/core/security/factories.c \
    src/core/security/google_root_certs.c \
    src/core/security/json_token.c \
    src/core/security/secure_endpoint.c \
    src/core/security/secure_transport_setup.c \
    src/core/security/security_context.c \
    src/core/security/server_secure_chttp2.c \
    src/core/tsi/fake_transport_security.c \
    src/core/tsi/ssl_transport_security.c \
    src/core/tsi/transport_security.c \
    src/core/channel/call_op_string.c \
    src/core/channel/census_filter.c \
    src/core/channel/channel_args.c \
    src/core/channel/channel_stack.c \
    src/core/channel/child_channel.c \
    src/core/channel/client_channel.c \
    src/core/channel/client_setup.c \
    src/core/channel/connected_channel.c \
    src/core/channel/http_client_filter.c \
    src/core/channel/http_filter.c \
    src/core/channel/http_server_filter.c \
    src/core/channel/metadata_buffer.c \
    src/core/channel/noop_filter.c \
    src/core/compression/algorithm.c \
    src/core/compression/message_compress.c \
    src/core/httpcli/format_request.c \
    src/core/httpcli/httpcli.c \
    src/core/httpcli/httpcli_security_context.c \
    src/core/httpcli/parser.c \
    src/core/iomgr/alarm.c \
    src/core/iomgr/alarm_heap.c \
    src/core/iomgr/endpoint.c \
    src/core/iomgr/endpoint_pair_posix.c \
    src/core/iomgr/fd_posix.c \
    src/core/iomgr/iomgr.c \
    src/core/iomgr/iomgr_posix.c \
    src/core/iomgr/pollset_multipoller_with_poll_posix.c \
    src/core/iomgr/pollset_posix.c \
    src/core/iomgr/resolve_address_posix.c \
    src/core/iomgr/sockaddr_utils.c \
    src/core/iomgr/socket_utils_common_posix.c \
    src/core/iomgr/socket_utils_linux.c \
    src/core/iomgr/socket_utils_posix.c \
    src/core/iomgr/tcp_client_posix.c \
    src/core/iomgr/tcp_posix.c \
    src/core/iomgr/tcp_server_posix.c \
    src/core/iomgr/time_averaged_stats.c \
    src/core/statistics/census_init.c \
    src/core/statistics/census_log.c \
    src/core/statistics/census_rpc_stats.c \
    src/core/statistics/census_tracing.c \
    src/core/statistics/hash_table.c \
    src/core/statistics/window_stats.c \
    src/core/surface/byte_buffer.c \
    src/core/surface/byte_buffer_reader.c \
    src/core/surface/call.c \
    src/core/surface/channel.c \
    src/core/surface/channel_create.c \
    src/core/surface/client.c \
    src/core/surface/completion_queue.c \
    src/core/surface/event_string.c \
    src/core/surface/init.c \
    src/core/surface/lame_client.c \
    src/core/surface/secure_channel_create.c \
    src/core/surface/secure_server_create.c \
    src/core/surface/server.c \
    src/core/surface/server_chttp2.c \
    src/core/surface/server_create.c \
    src/core/transport/chttp2/alpn.c \
    src/core/transport/chttp2/bin_encoder.c \
    src/core/transport/chttp2/frame_data.c \
    src/core/transport/chttp2/frame_goaway.c \
    src/core/transport/chttp2/frame_ping.c \
    src/core/transport/chttp2/frame_rst_stream.c \
    src/core/transport/chttp2/frame_settings.c \
    src/core/transport/chttp2/frame_window_update.c \
    src/core/transport/chttp2/hpack_parser.c \
    src/core/transport/chttp2/hpack_table.c \
    src/core/transport/chttp2/huffsyms.c \
    src/core/transport/chttp2/status_conversion.c \
    src/core/transport/chttp2/stream_encoder.c \
    src/core/transport/chttp2/stream_map.c \
    src/core/transport/chttp2/timeout_encoding.c \
    src/core/transport/chttp2/varint.c \
    src/core/transport/chttp2_transport.c \
    src/core/transport/metadata.c \
    src/core/transport/stream_op.c \
    src/core/transport/transport.c \
    third_party/cJSON/cJSON.c \

PUBLIC_HEADERS_C += \
    include/grpc/grpc_security.h \
    include/grpc/byte_buffer.h \
    include/grpc/byte_buffer_reader.h \
    include/grpc/grpc.h \
    include/grpc/status.h \

LIBGRPC_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBGRPC_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libgrpc.a: openssl_dep_error

ifeq ($(SYSTEM),MINGW32)
libs/$(CONFIG)/grpc.$(SHARED_EXT): openssl_dep_error
else
libs/$(CONFIG)/libgrpc.$(SHARED_EXT): openssl_dep_error
endif

else

libs/$(CONFIG)/libgrpc.a: $(OPENSSL_DEP) $(LIBGRPC_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libgrpc.a $(LIBGRPC_OBJS)
	$(Q) rm -rf tmp-merge
	$(Q) mkdir tmp-merge
	$(Q) ( cd tmp-merge ; $(AR) x ../libs/$(CONFIG)/libgrpc.a )
	$(Q) for l in $(OPENSSL_MERGE_LIBS) ; do ( cd tmp-merge ; ar x ../$${l} ) ; done
	$(Q) rm -f libs/$(CONFIG)/libgrpc.a tmp-merge/__.SYMDEF*
	$(Q) ar rcs libs/$(CONFIG)/libgrpc.a tmp-merge/*
	$(Q) rm -rf tmp-merge



ifeq ($(SYSTEM),MINGW32)
libs/$(CONFIG)/grpc.$(SHARED_EXT): $(LIBGRPC_OBJS) libs/$(CONFIG)/gpr.$(SHARED_EXT) $(OPENSSL_DEP)
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,--output-def=libs/$(CONFIG)/grpc.def -Wl,--out-implib=libs/$(CONFIG)/libgrpc-imp.a -o libs/$(CONFIG)/grpc.$(SHARED_EXT) $(LIBGRPC_OBJS) $(LDLIBS) $(LDLIBS_SECURE) $(OPENSSL_MERGE_LIBS) -lgpr-imp
else
libs/$(CONFIG)/libgrpc.$(SHARED_EXT): $(LIBGRPC_OBJS) libs/$(CONFIG)/libgpr.$(SHARED_EXT) $(OPENSSL_DEP)
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
ifeq ($(SYSTEM),Darwin)
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -dynamiclib -o libs/$(CONFIG)/libgrpc.$(SHARED_EXT) $(LIBGRPC_OBJS) $(LDLIBS) $(LDLIBS_SECURE) $(OPENSSL_MERGE_LIBS) -lgpr
else
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,-soname,libgrpc.so.0 -o libs/$(CONFIG)/libgrpc.$(SHARED_EXT) $(LIBGRPC_OBJS) $(LDLIBS) $(LDLIBS_SECURE) $(OPENSSL_MERGE_LIBS) -lgpr
	$(Q) ln -sf libgrpc.$(SHARED_EXT) libs/$(CONFIG)/libgrpc.so
endif
endif


endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBGRPC_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/src/core/security/auth.o: 
objs/$(CONFIG)/src/core/security/base64.o: 
objs/$(CONFIG)/src/core/security/credentials.o: 
objs/$(CONFIG)/src/core/security/factories.o: 
objs/$(CONFIG)/src/core/security/google_root_certs.o: 
objs/$(CONFIG)/src/core/security/json_token.o: 
objs/$(CONFIG)/src/core/security/secure_endpoint.o: 
objs/$(CONFIG)/src/core/security/secure_transport_setup.o: 
objs/$(CONFIG)/src/core/security/security_context.o: 
objs/$(CONFIG)/src/core/security/server_secure_chttp2.o: 
objs/$(CONFIG)/src/core/tsi/fake_transport_security.o: 
objs/$(CONFIG)/src/core/tsi/ssl_transport_security.o: 
objs/$(CONFIG)/src/core/tsi/transport_security.o: 
objs/$(CONFIG)/src/core/channel/call_op_string.o: 
objs/$(CONFIG)/src/core/channel/census_filter.o: 
objs/$(CONFIG)/src/core/channel/channel_args.o: 
objs/$(CONFIG)/src/core/channel/channel_stack.o: 
objs/$(CONFIG)/src/core/channel/child_channel.o: 
objs/$(CONFIG)/src/core/channel/client_channel.o: 
objs/$(CONFIG)/src/core/channel/client_setup.o: 
objs/$(CONFIG)/src/core/channel/connected_channel.o: 
objs/$(CONFIG)/src/core/channel/http_client_filter.o: 
objs/$(CONFIG)/src/core/channel/http_filter.o: 
objs/$(CONFIG)/src/core/channel/http_server_filter.o: 
objs/$(CONFIG)/src/core/channel/metadata_buffer.o: 
objs/$(CONFIG)/src/core/channel/noop_filter.o: 
objs/$(CONFIG)/src/core/compression/algorithm.o: 
objs/$(CONFIG)/src/core/compression/message_compress.o: 
objs/$(CONFIG)/src/core/httpcli/format_request.o: 
objs/$(CONFIG)/src/core/httpcli/httpcli.o: 
objs/$(CONFIG)/src/core/httpcli/httpcli_security_context.o: 
objs/$(CONFIG)/src/core/httpcli/parser.o: 
objs/$(CONFIG)/src/core/iomgr/alarm.o: 
objs/$(CONFIG)/src/core/iomgr/alarm_heap.o: 
objs/$(CONFIG)/src/core/iomgr/endpoint.o: 
objs/$(CONFIG)/src/core/iomgr/endpoint_pair_posix.o: 
objs/$(CONFIG)/src/core/iomgr/fd_posix.o: 
objs/$(CONFIG)/src/core/iomgr/iomgr.o: 
objs/$(CONFIG)/src/core/iomgr/iomgr_posix.o: 
objs/$(CONFIG)/src/core/iomgr/pollset_multipoller_with_poll_posix.o: 
objs/$(CONFIG)/src/core/iomgr/pollset_posix.o: 
objs/$(CONFIG)/src/core/iomgr/resolve_address_posix.o: 
objs/$(CONFIG)/src/core/iomgr/sockaddr_utils.o: 
objs/$(CONFIG)/src/core/iomgr/socket_utils_common_posix.o: 
objs/$(CONFIG)/src/core/iomgr/socket_utils_linux.o: 
objs/$(CONFIG)/src/core/iomgr/socket_utils_posix.o: 
objs/$(CONFIG)/src/core/iomgr/tcp_client_posix.o: 
objs/$(CONFIG)/src/core/iomgr/tcp_posix.o: 
objs/$(CONFIG)/src/core/iomgr/tcp_server_posix.o: 
objs/$(CONFIG)/src/core/iomgr/time_averaged_stats.o: 
objs/$(CONFIG)/src/core/statistics/census_init.o: 
objs/$(CONFIG)/src/core/statistics/census_log.o: 
objs/$(CONFIG)/src/core/statistics/census_rpc_stats.o: 
objs/$(CONFIG)/src/core/statistics/census_tracing.o: 
objs/$(CONFIG)/src/core/statistics/hash_table.o: 
objs/$(CONFIG)/src/core/statistics/window_stats.o: 
objs/$(CONFIG)/src/core/surface/byte_buffer.o: 
objs/$(CONFIG)/src/core/surface/byte_buffer_reader.o: 
objs/$(CONFIG)/src/core/surface/call.o: 
objs/$(CONFIG)/src/core/surface/channel.o: 
objs/$(CONFIG)/src/core/surface/channel_create.o: 
objs/$(CONFIG)/src/core/surface/client.o: 
objs/$(CONFIG)/src/core/surface/completion_queue.o: 
objs/$(CONFIG)/src/core/surface/event_string.o: 
objs/$(CONFIG)/src/core/surface/init.o: 
objs/$(CONFIG)/src/core/surface/lame_client.o: 
objs/$(CONFIG)/src/core/surface/secure_channel_create.o: 
objs/$(CONFIG)/src/core/surface/secure_server_create.o: 
objs/$(CONFIG)/src/core/surface/server.o: 
objs/$(CONFIG)/src/core/surface/server_chttp2.o: 
objs/$(CONFIG)/src/core/surface/server_create.o: 
objs/$(CONFIG)/src/core/transport/chttp2/alpn.o: 
objs/$(CONFIG)/src/core/transport/chttp2/bin_encoder.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_data.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_goaway.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_ping.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_rst_stream.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_settings.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_window_update.o: 
objs/$(CONFIG)/src/core/transport/chttp2/hpack_parser.o: 
objs/$(CONFIG)/src/core/transport/chttp2/hpack_table.o: 
objs/$(CONFIG)/src/core/transport/chttp2/huffsyms.o: 
objs/$(CONFIG)/src/core/transport/chttp2/status_conversion.o: 
objs/$(CONFIG)/src/core/transport/chttp2/stream_encoder.o: 
objs/$(CONFIG)/src/core/transport/chttp2/stream_map.o: 
objs/$(CONFIG)/src/core/transport/chttp2/timeout_encoding.o: 
objs/$(CONFIG)/src/core/transport/chttp2/varint.o: 
objs/$(CONFIG)/src/core/transport/chttp2_transport.o: 
objs/$(CONFIG)/src/core/transport/metadata.o: 
objs/$(CONFIG)/src/core/transport/stream_op.o: 
objs/$(CONFIG)/src/core/transport/transport.o: 
objs/$(CONFIG)/third_party/cJSON/cJSON.o: 


LIBGRPC_UNSECURE_SRC = \
    src/core/channel/call_op_string.c \
    src/core/channel/census_filter.c \
    src/core/channel/channel_args.c \
    src/core/channel/channel_stack.c \
    src/core/channel/child_channel.c \
    src/core/channel/client_channel.c \
    src/core/channel/client_setup.c \
    src/core/channel/connected_channel.c \
    src/core/channel/http_client_filter.c \
    src/core/channel/http_filter.c \
    src/core/channel/http_server_filter.c \
    src/core/channel/metadata_buffer.c \
    src/core/channel/noop_filter.c \
    src/core/compression/algorithm.c \
    src/core/compression/message_compress.c \
    src/core/httpcli/format_request.c \
    src/core/httpcli/httpcli.c \
    src/core/httpcli/httpcli_security_context.c \
    src/core/httpcli/parser.c \
    src/core/iomgr/alarm.c \
    src/core/iomgr/alarm_heap.c \
    src/core/iomgr/endpoint.c \
    src/core/iomgr/endpoint_pair_posix.c \
    src/core/iomgr/fd_posix.c \
    src/core/iomgr/iomgr.c \
    src/core/iomgr/iomgr_posix.c \
    src/core/iomgr/pollset_multipoller_with_poll_posix.c \
    src/core/iomgr/pollset_posix.c \
    src/core/iomgr/resolve_address_posix.c \
    src/core/iomgr/sockaddr_utils.c \
    src/core/iomgr/socket_utils_common_posix.c \
    src/core/iomgr/socket_utils_linux.c \
    src/core/iomgr/socket_utils_posix.c \
    src/core/iomgr/tcp_client_posix.c \
    src/core/iomgr/tcp_posix.c \
    src/core/iomgr/tcp_server_posix.c \
    src/core/iomgr/time_averaged_stats.c \
    src/core/statistics/census_init.c \
    src/core/statistics/census_log.c \
    src/core/statistics/census_rpc_stats.c \
    src/core/statistics/census_tracing.c \
    src/core/statistics/hash_table.c \
    src/core/statistics/window_stats.c \
    src/core/surface/byte_buffer.c \
    src/core/surface/byte_buffer_reader.c \
    src/core/surface/call.c \
    src/core/surface/channel.c \
    src/core/surface/channel_create.c \
    src/core/surface/client.c \
    src/core/surface/completion_queue.c \
    src/core/surface/event_string.c \
    src/core/surface/init.c \
    src/core/surface/lame_client.c \
    src/core/surface/secure_channel_create.c \
    src/core/surface/secure_server_create.c \
    src/core/surface/server.c \
    src/core/surface/server_chttp2.c \
    src/core/surface/server_create.c \
    src/core/transport/chttp2/alpn.c \
    src/core/transport/chttp2/bin_encoder.c \
    src/core/transport/chttp2/frame_data.c \
    src/core/transport/chttp2/frame_goaway.c \
    src/core/transport/chttp2/frame_ping.c \
    src/core/transport/chttp2/frame_rst_stream.c \
    src/core/transport/chttp2/frame_settings.c \
    src/core/transport/chttp2/frame_window_update.c \
    src/core/transport/chttp2/hpack_parser.c \
    src/core/transport/chttp2/hpack_table.c \
    src/core/transport/chttp2/huffsyms.c \
    src/core/transport/chttp2/status_conversion.c \
    src/core/transport/chttp2/stream_encoder.c \
    src/core/transport/chttp2/stream_map.c \
    src/core/transport/chttp2/timeout_encoding.c \
    src/core/transport/chttp2/varint.c \
    src/core/transport/chttp2_transport.c \
    src/core/transport/metadata.c \
    src/core/transport/stream_op.c \
    src/core/transport/transport.c \
    third_party/cJSON/cJSON.c \

PUBLIC_HEADERS_C += \
    include/grpc/byte_buffer.h \
    include/grpc/byte_buffer_reader.h \
    include/grpc/grpc.h \
    include/grpc/status.h \

LIBGRPC_UNSECURE_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBGRPC_UNSECURE_SRC))))

libs/$(CONFIG)/libgrpc_unsecure.a: $(LIBGRPC_UNSECURE_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libgrpc_unsecure.a $(LIBGRPC_UNSECURE_OBJS)



ifeq ($(SYSTEM),MINGW32)
libs/$(CONFIG)/grpc_unsecure.$(SHARED_EXT): $(LIBGRPC_UNSECURE_OBJS) libs/$(CONFIG)/gpr.$(SHARED_EXT)
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,--output-def=libs/$(CONFIG)/grpc_unsecure.def -Wl,--out-implib=libs/$(CONFIG)/libgrpc_unsecure-imp.a -o libs/$(CONFIG)/grpc_unsecure.$(SHARED_EXT) $(LIBGRPC_UNSECURE_OBJS) $(LDLIBS) -lgpr-imp
else
libs/$(CONFIG)/libgrpc_unsecure.$(SHARED_EXT): $(LIBGRPC_UNSECURE_OBJS) libs/$(CONFIG)/libgpr.$(SHARED_EXT)
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
ifeq ($(SYSTEM),Darwin)
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -dynamiclib -o libs/$(CONFIG)/libgrpc_unsecure.$(SHARED_EXT) $(LIBGRPC_UNSECURE_OBJS) $(LDLIBS) -lgpr
else
	$(Q) $(LD) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,-soname,libgrpc_unsecure.so.0 -o libs/$(CONFIG)/libgrpc_unsecure.$(SHARED_EXT) $(LIBGRPC_UNSECURE_OBJS) $(LDLIBS) -lgpr
	$(Q) ln -sf libgrpc_unsecure.$(SHARED_EXT) libs/$(CONFIG)/libgrpc_unsecure.so
endif
endif


ifneq ($(NO_DEPS),true)
-include $(LIBGRPC_UNSECURE_OBJS:.o=.dep)
endif

objs/$(CONFIG)/src/core/channel/call_op_string.o: 
objs/$(CONFIG)/src/core/channel/census_filter.o: 
objs/$(CONFIG)/src/core/channel/channel_args.o: 
objs/$(CONFIG)/src/core/channel/channel_stack.o: 
objs/$(CONFIG)/src/core/channel/child_channel.o: 
objs/$(CONFIG)/src/core/channel/client_channel.o: 
objs/$(CONFIG)/src/core/channel/client_setup.o: 
objs/$(CONFIG)/src/core/channel/connected_channel.o: 
objs/$(CONFIG)/src/core/channel/http_client_filter.o: 
objs/$(CONFIG)/src/core/channel/http_filter.o: 
objs/$(CONFIG)/src/core/channel/http_server_filter.o: 
objs/$(CONFIG)/src/core/channel/metadata_buffer.o: 
objs/$(CONFIG)/src/core/channel/noop_filter.o: 
objs/$(CONFIG)/src/core/compression/algorithm.o: 
objs/$(CONFIG)/src/core/compression/message_compress.o: 
objs/$(CONFIG)/src/core/httpcli/format_request.o: 
objs/$(CONFIG)/src/core/httpcli/httpcli.o: 
objs/$(CONFIG)/src/core/httpcli/httpcli_security_context.o: 
objs/$(CONFIG)/src/core/httpcli/parser.o: 
objs/$(CONFIG)/src/core/iomgr/alarm.o: 
objs/$(CONFIG)/src/core/iomgr/alarm_heap.o: 
objs/$(CONFIG)/src/core/iomgr/endpoint.o: 
objs/$(CONFIG)/src/core/iomgr/endpoint_pair_posix.o: 
objs/$(CONFIG)/src/core/iomgr/fd_posix.o: 
objs/$(CONFIG)/src/core/iomgr/iomgr.o: 
objs/$(CONFIG)/src/core/iomgr/iomgr_posix.o: 
objs/$(CONFIG)/src/core/iomgr/pollset_multipoller_with_poll_posix.o: 
objs/$(CONFIG)/src/core/iomgr/pollset_posix.o: 
objs/$(CONFIG)/src/core/iomgr/resolve_address_posix.o: 
objs/$(CONFIG)/src/core/iomgr/sockaddr_utils.o: 
objs/$(CONFIG)/src/core/iomgr/socket_utils_common_posix.o: 
objs/$(CONFIG)/src/core/iomgr/socket_utils_linux.o: 
objs/$(CONFIG)/src/core/iomgr/socket_utils_posix.o: 
objs/$(CONFIG)/src/core/iomgr/tcp_client_posix.o: 
objs/$(CONFIG)/src/core/iomgr/tcp_posix.o: 
objs/$(CONFIG)/src/core/iomgr/tcp_server_posix.o: 
objs/$(CONFIG)/src/core/iomgr/time_averaged_stats.o: 
objs/$(CONFIG)/src/core/statistics/census_init.o: 
objs/$(CONFIG)/src/core/statistics/census_log.o: 
objs/$(CONFIG)/src/core/statistics/census_rpc_stats.o: 
objs/$(CONFIG)/src/core/statistics/census_tracing.o: 
objs/$(CONFIG)/src/core/statistics/hash_table.o: 
objs/$(CONFIG)/src/core/statistics/window_stats.o: 
objs/$(CONFIG)/src/core/surface/byte_buffer.o: 
objs/$(CONFIG)/src/core/surface/byte_buffer_reader.o: 
objs/$(CONFIG)/src/core/surface/call.o: 
objs/$(CONFIG)/src/core/surface/channel.o: 
objs/$(CONFIG)/src/core/surface/channel_create.o: 
objs/$(CONFIG)/src/core/surface/client.o: 
objs/$(CONFIG)/src/core/surface/completion_queue.o: 
objs/$(CONFIG)/src/core/surface/event_string.o: 
objs/$(CONFIG)/src/core/surface/init.o: 
objs/$(CONFIG)/src/core/surface/lame_client.o: 
objs/$(CONFIG)/src/core/surface/secure_channel_create.o: 
objs/$(CONFIG)/src/core/surface/secure_server_create.o: 
objs/$(CONFIG)/src/core/surface/server.o: 
objs/$(CONFIG)/src/core/surface/server_chttp2.o: 
objs/$(CONFIG)/src/core/surface/server_create.o: 
objs/$(CONFIG)/src/core/transport/chttp2/alpn.o: 
objs/$(CONFIG)/src/core/transport/chttp2/bin_encoder.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_data.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_goaway.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_ping.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_rst_stream.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_settings.o: 
objs/$(CONFIG)/src/core/transport/chttp2/frame_window_update.o: 
objs/$(CONFIG)/src/core/transport/chttp2/hpack_parser.o: 
objs/$(CONFIG)/src/core/transport/chttp2/hpack_table.o: 
objs/$(CONFIG)/src/core/transport/chttp2/huffsyms.o: 
objs/$(CONFIG)/src/core/transport/chttp2/status_conversion.o: 
objs/$(CONFIG)/src/core/transport/chttp2/stream_encoder.o: 
objs/$(CONFIG)/src/core/transport/chttp2/stream_map.o: 
objs/$(CONFIG)/src/core/transport/chttp2/timeout_encoding.o: 
objs/$(CONFIG)/src/core/transport/chttp2/varint.o: 
objs/$(CONFIG)/src/core/transport/chttp2_transport.o: 
objs/$(CONFIG)/src/core/transport/metadata.o: 
objs/$(CONFIG)/src/core/transport/stream_op.o: 
objs/$(CONFIG)/src/core/transport/transport.o: 
objs/$(CONFIG)/third_party/cJSON/cJSON.o: 


LIBGPR_TEST_UTIL_SRC = \
    test/core/util/test_config.c \


LIBGPR_TEST_UTIL_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBGPR_TEST_UTIL_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libgpr_test_util.a: openssl_dep_error


else

libs/$(CONFIG)/libgpr_test_util.a: $(OPENSSL_DEP) $(LIBGPR_TEST_UTIL_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libgpr_test_util.a $(LIBGPR_TEST_UTIL_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBGPR_TEST_UTIL_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/util/test_config.o: 


LIBGRPC_TEST_UTIL_SRC = \
    test/core/end2end/cq_verifier.c \
    test/core/end2end/data/test_root_cert.c \
    test/core/end2end/data/prod_roots_certs.c \
    test/core/end2end/data/server1_cert.c \
    test/core/end2end/data/server1_key.c \
    test/core/iomgr/endpoint_tests.c \
    test/core/statistics/census_log_tests.c \
    test/core/transport/transport_end2end_tests.c \
    test/core/util/grpc_profiler.c \
    test/core/util/port_posix.c \
    test/core/util/parse_hexstring.c \
    test/core/util/slice_splitter.c \


LIBGRPC_TEST_UTIL_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBGRPC_TEST_UTIL_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libgrpc_test_util.a: openssl_dep_error


else

libs/$(CONFIG)/libgrpc_test_util.a: $(OPENSSL_DEP) $(LIBGRPC_TEST_UTIL_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libgrpc_test_util.a $(LIBGRPC_TEST_UTIL_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBGRPC_TEST_UTIL_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/cq_verifier.o: 
objs/$(CONFIG)/test/core/end2end/data/test_root_cert.o: 
objs/$(CONFIG)/test/core/end2end/data/prod_roots_certs.o: 
objs/$(CONFIG)/test/core/end2end/data/server1_cert.o: 
objs/$(CONFIG)/test/core/end2end/data/server1_key.o: 
objs/$(CONFIG)/test/core/iomgr/endpoint_tests.o: 
objs/$(CONFIG)/test/core/statistics/census_log_tests.o: 
objs/$(CONFIG)/test/core/transport/transport_end2end_tests.o: 
objs/$(CONFIG)/test/core/util/grpc_profiler.o: 
objs/$(CONFIG)/test/core/util/port_posix.o: 
objs/$(CONFIG)/test/core/util/parse_hexstring.o: 
objs/$(CONFIG)/test/core/util/slice_splitter.o: 


LIBGRPC++_SRC = \
    src/cpp/client/channel.cc \
    src/cpp/client/channel_arguments.cc \
    src/cpp/client/client_context.cc \
    src/cpp/client/create_channel.cc \
    src/cpp/client/credentials.cc \
    src/cpp/client/internal_stub.cc \
    src/cpp/proto/proto_utils.cc \
    src/cpp/common/rpc_method.cc \
    src/cpp/server/async_server.cc \
    src/cpp/server/async_server_context.cc \
    src/cpp/server/completion_queue.cc \
    src/cpp/server/server_builder.cc \
    src/cpp/server/server_context_impl.cc \
    src/cpp/server/server.cc \
    src/cpp/server/server_rpc_handler.cc \
    src/cpp/server/server_credentials.cc \
    src/cpp/server/thread_pool.cc \
    src/cpp/stream/stream_context.cc \
    src/cpp/util/status.cc \
    src/cpp/util/time.cc \

PUBLIC_HEADERS_CXX += \
    include/grpc++/async_server_context.h \
    include/grpc++/async_server.h \
    include/grpc++/channel_arguments.h \
    include/grpc++/channel_interface.h \
    include/grpc++/client_context.h \
    include/grpc++/completion_queue.h \
    include/grpc++/config.h \
    include/grpc++/create_channel.h \
    include/grpc++/credentials.h \
    include/grpc++/impl/internal_stub.h \
    include/grpc++/impl/rpc_method.h \
    include/grpc++/impl/rpc_service_method.h \
    include/grpc++/server_builder.h \
    include/grpc++/server_context.h \
    include/grpc++/server_credentials.h \
    include/grpc++/server.h \
    include/grpc++/status.h \
    include/grpc++/stream_context_interface.h \
    include/grpc++/stream.h \

LIBGRPC++_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBGRPC++_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libgrpc++.a: openssl_dep_error

ifeq ($(SYSTEM),MINGW32)
libs/$(CONFIG)/grpc++.$(SHARED_EXT): openssl_dep_error
else
libs/$(CONFIG)/libgrpc++.$(SHARED_EXT): openssl_dep_error
endif

else

libs/$(CONFIG)/libgrpc++.a: $(OPENSSL_DEP) $(LIBGRPC++_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libgrpc++.a $(LIBGRPC++_OBJS)



ifeq ($(SYSTEM),MINGW32)
libs/$(CONFIG)/grpc++.$(SHARED_EXT): $(LIBGRPC++_OBJS) libs/$(CONFIG)/grpc.$(SHARED_EXT) $(OPENSSL_DEP)
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,--output-def=libs/$(CONFIG)/grpc++.def -Wl,--out-implib=libs/$(CONFIG)/libgrpc++-imp.a -o libs/$(CONFIG)/grpc++.$(SHARED_EXT) $(LIBGRPC++_OBJS) $(LDLIBS) $(LDLIBS_SECURE) $(OPENSSL_MERGE_LIBS) -lgrpc-imp
else
libs/$(CONFIG)/libgrpc++.$(SHARED_EXT): $(LIBGRPC++_OBJS) libs/$(CONFIG)/libgrpc.$(SHARED_EXT) $(OPENSSL_DEP)
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
ifeq ($(SYSTEM),Darwin)
	$(Q) $(LDXX) $(LDFLAGS) -Llibs/$(CONFIG) -dynamiclib -o libs/$(CONFIG)/libgrpc++.$(SHARED_EXT) $(LIBGRPC++_OBJS) $(LDLIBS) $(LDLIBS_SECURE) $(OPENSSL_MERGE_LIBS) -lgrpc
else
	$(Q) $(LDXX) $(LDFLAGS) -Llibs/$(CONFIG) -shared -Wl,-soname,libgrpc++.so.0 -o libs/$(CONFIG)/libgrpc++.$(SHARED_EXT) $(LIBGRPC++_OBJS) $(LDLIBS) $(LDLIBS_SECURE) $(OPENSSL_MERGE_LIBS) -lgrpc
	$(Q) ln -sf libgrpc++.$(SHARED_EXT) libs/$(CONFIG)/libgrpc++.so
endif
endif


endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBGRPC++_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/src/cpp/client/channel.o: 
objs/$(CONFIG)/src/cpp/client/channel_arguments.o: 
objs/$(CONFIG)/src/cpp/client/client_context.o: 
objs/$(CONFIG)/src/cpp/client/create_channel.o: 
objs/$(CONFIG)/src/cpp/client/credentials.o: 
objs/$(CONFIG)/src/cpp/client/internal_stub.o: 
objs/$(CONFIG)/src/cpp/proto/proto_utils.o: 
objs/$(CONFIG)/src/cpp/common/rpc_method.o: 
objs/$(CONFIG)/src/cpp/server/async_server.o: 
objs/$(CONFIG)/src/cpp/server/async_server_context.o: 
objs/$(CONFIG)/src/cpp/server/completion_queue.o: 
objs/$(CONFIG)/src/cpp/server/server_builder.o: 
objs/$(CONFIG)/src/cpp/server/server_context_impl.o: 
objs/$(CONFIG)/src/cpp/server/server.o: 
objs/$(CONFIG)/src/cpp/server/server_rpc_handler.o: 
objs/$(CONFIG)/src/cpp/server/server_credentials.o: 
objs/$(CONFIG)/src/cpp/server/thread_pool.o: 
objs/$(CONFIG)/src/cpp/stream/stream_context.o: 
objs/$(CONFIG)/src/cpp/util/status.o: 
objs/$(CONFIG)/src/cpp/util/time.o: 


LIBGRPC++_TEST_UTIL_SRC = \
    gens/test/cpp/util/messages.pb.cc \
    gens/test/cpp/util/echo.pb.cc \
    gens/test/cpp/util/echo_duplicate.pb.cc \
    test/cpp/util/create_test_channel.cc \
    test/cpp/end2end/async_test_server.cc \


LIBGRPC++_TEST_UTIL_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBGRPC++_TEST_UTIL_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libgrpc++_test_util.a: openssl_dep_error


else

libs/$(CONFIG)/libgrpc++_test_util.a: $(OPENSSL_DEP) $(LIBGRPC++_TEST_UTIL_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libgrpc++_test_util.a $(LIBGRPC++_TEST_UTIL_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBGRPC++_TEST_UTIL_OBJS:.o=.dep)
endif
endif




objs/$(CONFIG)/test/cpp/util/create_test_channel.o:     gens/test/cpp/util/messages.pb.cc    gens/test/cpp/util/echo.pb.cc    gens/test/cpp/util/echo_duplicate.pb.cc
objs/$(CONFIG)/test/cpp/end2end/async_test_server.o:     gens/test/cpp/util/messages.pb.cc    gens/test/cpp/util/echo.pb.cc    gens/test/cpp/util/echo_duplicate.pb.cc


LIBEND2END_FIXTURE_CHTTP2_FAKE_SECURITY_SRC = \
    test/core/end2end/fixtures/chttp2_fake_security.c \


LIBEND2END_FIXTURE_CHTTP2_FAKE_SECURITY_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_FIXTURE_CHTTP2_FAKE_SECURITY_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a: openssl_dep_error


else

libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a: $(OPENSSL_DEP) $(LIBEND2END_FIXTURE_CHTTP2_FAKE_SECURITY_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a $(LIBEND2END_FIXTURE_CHTTP2_FAKE_SECURITY_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_FIXTURE_CHTTP2_FAKE_SECURITY_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/fixtures/chttp2_fake_security.o: 


LIBEND2END_FIXTURE_CHTTP2_FULLSTACK_SRC = \
    test/core/end2end/fixtures/chttp2_fullstack.c \


LIBEND2END_FIXTURE_CHTTP2_FULLSTACK_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_FIXTURE_CHTTP2_FULLSTACK_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a: openssl_dep_error


else

libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a: $(OPENSSL_DEP) $(LIBEND2END_FIXTURE_CHTTP2_FULLSTACK_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a $(LIBEND2END_FIXTURE_CHTTP2_FULLSTACK_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_FIXTURE_CHTTP2_FULLSTACK_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/fixtures/chttp2_fullstack.o: 


LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_FULLSTACK_SRC = \
    test/core/end2end/fixtures/chttp2_simple_ssl_fullstack.c \


LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_FULLSTACK_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_FULLSTACK_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a: openssl_dep_error


else

libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a: $(OPENSSL_DEP) $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_FULLSTACK_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_FULLSTACK_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_FULLSTACK_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/fixtures/chttp2_simple_ssl_fullstack.o: 


LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SRC = \
    test/core/end2end/fixtures/chttp2_simple_ssl_with_oauth2_fullstack.c \


LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a: openssl_dep_error


else

libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a: $(OPENSSL_DEP) $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_FIXTURE_CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/fixtures/chttp2_simple_ssl_with_oauth2_fullstack.o: 


LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_SRC = \
    test/core/end2end/fixtures/chttp2_socket_pair.c \


LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a: openssl_dep_error


else

libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a: $(OPENSSL_DEP) $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/fixtures/chttp2_socket_pair.o: 


LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SRC = \
    test/core/end2end/fixtures/chttp2_socket_pair_one_byte_at_a_time.c \


LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a: openssl_dep_error


else

libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a: $(OPENSSL_DEP) $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_FIXTURE_CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/fixtures/chttp2_socket_pair_one_byte_at_a_time.o: 


LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_SRC = \
    test/core/end2end/tests/cancel_after_accept.c \


LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_SRC))))

libs/$(CONFIG)/libend2end_test_cancel_after_accept.a: $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_cancel_after_accept.a $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/cancel_after_accept.o: 


LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_SRC = \
    test/core/end2end/tests/cancel_after_accept_and_writes_closed.c \


LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_SRC))))

libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a: $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/cancel_after_accept_and_writes_closed.o: 


LIBEND2END_TEST_CANCEL_AFTER_INVOKE_SRC = \
    test/core/end2end/tests/cancel_after_invoke.c \


LIBEND2END_TEST_CANCEL_AFTER_INVOKE_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_CANCEL_AFTER_INVOKE_SRC))))

libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a: $(LIBEND2END_TEST_CANCEL_AFTER_INVOKE_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a $(LIBEND2END_TEST_CANCEL_AFTER_INVOKE_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_CANCEL_AFTER_INVOKE_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/cancel_after_invoke.o: 


LIBEND2END_TEST_CANCEL_BEFORE_INVOKE_SRC = \
    test/core/end2end/tests/cancel_before_invoke.c \


LIBEND2END_TEST_CANCEL_BEFORE_INVOKE_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_CANCEL_BEFORE_INVOKE_SRC))))

libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a: $(LIBEND2END_TEST_CANCEL_BEFORE_INVOKE_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a $(LIBEND2END_TEST_CANCEL_BEFORE_INVOKE_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_CANCEL_BEFORE_INVOKE_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/cancel_before_invoke.o: 


LIBEND2END_TEST_CANCEL_IN_A_VACUUM_SRC = \
    test/core/end2end/tests/cancel_in_a_vacuum.c \


LIBEND2END_TEST_CANCEL_IN_A_VACUUM_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_CANCEL_IN_A_VACUUM_SRC))))

libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a: $(LIBEND2END_TEST_CANCEL_IN_A_VACUUM_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a $(LIBEND2END_TEST_CANCEL_IN_A_VACUUM_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_CANCEL_IN_A_VACUUM_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/cancel_in_a_vacuum.o: 


LIBEND2END_TEST_CENSUS_SIMPLE_REQUEST_SRC = \
    test/core/end2end/tests/census_simple_request.c \


LIBEND2END_TEST_CENSUS_SIMPLE_REQUEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_CENSUS_SIMPLE_REQUEST_SRC))))

libs/$(CONFIG)/libend2end_test_census_simple_request.a: $(LIBEND2END_TEST_CENSUS_SIMPLE_REQUEST_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_census_simple_request.a $(LIBEND2END_TEST_CENSUS_SIMPLE_REQUEST_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_CENSUS_SIMPLE_REQUEST_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/census_simple_request.o: 


LIBEND2END_TEST_DISAPPEARING_SERVER_SRC = \
    test/core/end2end/tests/disappearing_server.c \


LIBEND2END_TEST_DISAPPEARING_SERVER_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_DISAPPEARING_SERVER_SRC))))

libs/$(CONFIG)/libend2end_test_disappearing_server.a: $(LIBEND2END_TEST_DISAPPEARING_SERVER_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_disappearing_server.a $(LIBEND2END_TEST_DISAPPEARING_SERVER_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_DISAPPEARING_SERVER_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/disappearing_server.o: 


LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_SRC = \
    test/core/end2end/tests/early_server_shutdown_finishes_inflight_calls.c \


LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_SRC))))

libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a: $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/early_server_shutdown_finishes_inflight_calls.o: 


LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_SRC = \
    test/core/end2end/tests/early_server_shutdown_finishes_tags.c \


LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_SRC))))

libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a: $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/early_server_shutdown_finishes_tags.o: 


LIBEND2END_TEST_INVOKE_LARGE_REQUEST_SRC = \
    test/core/end2end/tests/invoke_large_request.c \


LIBEND2END_TEST_INVOKE_LARGE_REQUEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_INVOKE_LARGE_REQUEST_SRC))))

libs/$(CONFIG)/libend2end_test_invoke_large_request.a: $(LIBEND2END_TEST_INVOKE_LARGE_REQUEST_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_invoke_large_request.a $(LIBEND2END_TEST_INVOKE_LARGE_REQUEST_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_INVOKE_LARGE_REQUEST_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/invoke_large_request.o: 


LIBEND2END_TEST_MAX_CONCURRENT_STREAMS_SRC = \
    test/core/end2end/tests/max_concurrent_streams.c \


LIBEND2END_TEST_MAX_CONCURRENT_STREAMS_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_MAX_CONCURRENT_STREAMS_SRC))))

libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a: $(LIBEND2END_TEST_MAX_CONCURRENT_STREAMS_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a $(LIBEND2END_TEST_MAX_CONCURRENT_STREAMS_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_MAX_CONCURRENT_STREAMS_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/max_concurrent_streams.o: 


LIBEND2END_TEST_NO_OP_SRC = \
    test/core/end2end/tests/no_op.c \


LIBEND2END_TEST_NO_OP_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_NO_OP_SRC))))

libs/$(CONFIG)/libend2end_test_no_op.a: $(LIBEND2END_TEST_NO_OP_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_no_op.a $(LIBEND2END_TEST_NO_OP_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_NO_OP_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/no_op.o: 


LIBEND2END_TEST_PING_PONG_STREAMING_SRC = \
    test/core/end2end/tests/ping_pong_streaming.c \


LIBEND2END_TEST_PING_PONG_STREAMING_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_PING_PONG_STREAMING_SRC))))

libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a: $(LIBEND2END_TEST_PING_PONG_STREAMING_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a $(LIBEND2END_TEST_PING_PONG_STREAMING_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_PING_PONG_STREAMING_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/ping_pong_streaming.o: 


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_SRC = \
    test/core/end2end/tests/request_response_with_binary_metadata_and_payload.c \


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_SRC))))

libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a: $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/request_response_with_binary_metadata_and_payload.o: 


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_SRC = \
    test/core/end2end/tests/request_response_with_metadata_and_payload.c \


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_SRC))))

libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a: $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/request_response_with_metadata_and_payload.o: 


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_PAYLOAD_SRC = \
    test/core/end2end/tests/request_response_with_payload.c \


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_PAYLOAD_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_PAYLOAD_SRC))))

libs/$(CONFIG)/libend2end_test_request_response_with_payload.a: $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_PAYLOAD_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_request_response_with_payload.a $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_PAYLOAD_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_PAYLOAD_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/request_response_with_payload.o: 


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_SRC = \
    test/core/end2end/tests/request_response_with_trailing_metadata_and_payload.c \


LIBEND2END_TEST_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_SRC))))

libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a: $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/request_response_with_trailing_metadata_and_payload.o: 


LIBEND2END_TEST_SIMPLE_DELAYED_REQUEST_SRC = \
    test/core/end2end/tests/simple_delayed_request.c \


LIBEND2END_TEST_SIMPLE_DELAYED_REQUEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_SIMPLE_DELAYED_REQUEST_SRC))))

libs/$(CONFIG)/libend2end_test_simple_delayed_request.a: $(LIBEND2END_TEST_SIMPLE_DELAYED_REQUEST_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_simple_delayed_request.a $(LIBEND2END_TEST_SIMPLE_DELAYED_REQUEST_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_SIMPLE_DELAYED_REQUEST_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/simple_delayed_request.o: 


LIBEND2END_TEST_SIMPLE_REQUEST_SRC = \
    test/core/end2end/tests/simple_request.c \


LIBEND2END_TEST_SIMPLE_REQUEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_SIMPLE_REQUEST_SRC))))

libs/$(CONFIG)/libend2end_test_simple_request.a: $(LIBEND2END_TEST_SIMPLE_REQUEST_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_simple_request.a $(LIBEND2END_TEST_SIMPLE_REQUEST_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_SIMPLE_REQUEST_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/simple_request.o: 


LIBEND2END_TEST_THREAD_STRESS_SRC = \
    test/core/end2end/tests/thread_stress.c \


LIBEND2END_TEST_THREAD_STRESS_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_THREAD_STRESS_SRC))))

libs/$(CONFIG)/libend2end_test_thread_stress.a: $(LIBEND2END_TEST_THREAD_STRESS_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_thread_stress.a $(LIBEND2END_TEST_THREAD_STRESS_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_THREAD_STRESS_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/thread_stress.o: 


LIBEND2END_TEST_WRITES_DONE_HANGS_WITH_PENDING_READ_SRC = \
    test/core/end2end/tests/writes_done_hangs_with_pending_read.c \


LIBEND2END_TEST_WRITES_DONE_HANGS_WITH_PENDING_READ_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_TEST_WRITES_DONE_HANGS_WITH_PENDING_READ_SRC))))

libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a: $(LIBEND2END_TEST_WRITES_DONE_HANGS_WITH_PENDING_READ_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a $(LIBEND2END_TEST_WRITES_DONE_HANGS_WITH_PENDING_READ_OBJS)





ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_TEST_WRITES_DONE_HANGS_WITH_PENDING_READ_OBJS:.o=.dep)
endif

objs/$(CONFIG)/test/core/end2end/tests/writes_done_hangs_with_pending_read.o: 


LIBEND2END_CERTS_SRC = \
    test/core/end2end/data/test_root_cert.c \
    test/core/end2end/data/prod_roots_certs.c \
    test/core/end2end/data/server1_cert.c \
    test/core/end2end/data/server1_key.c \


LIBEND2END_CERTS_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LIBEND2END_CERTS_SRC))))

ifeq ($(NO_SECURE),true)

libs/$(CONFIG)/libend2end_certs.a: openssl_dep_error


else

libs/$(CONFIG)/libend2end_certs.a: $(OPENSSL_DEP) $(LIBEND2END_CERTS_OBJS)
	$(E) "[AR]      Creating $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(AR) rcs libs/$(CONFIG)/libend2end_certs.a $(LIBEND2END_CERTS_OBJS)





endif

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LIBEND2END_CERTS_OBJS:.o=.dep)
endif
endif

objs/$(CONFIG)/test/core/end2end/data/test_root_cert.o: 
objs/$(CONFIG)/test/core/end2end/data/prod_roots_certs.o: 
objs/$(CONFIG)/test/core/end2end/data/server1_cert.o: 
objs/$(CONFIG)/test/core/end2end/data/server1_key.o: 



# All of the test targets, and protoc plugins


GEN_HPACK_TABLES_SRC = \
    src/core/transport/chttp2/gen_hpack_tables.c \

GEN_HPACK_TABLES_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GEN_HPACK_TABLES_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gen_hpack_tables: openssl_dep_error

else

bins/$(CONFIG)/gen_hpack_tables: $(GEN_HPACK_TABLES_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgpr.a libs/$(CONFIG)/libgrpc.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GEN_HPACK_TABLES_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgpr.a libs/$(CONFIG)/libgrpc.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gen_hpack_tables

endif

objs/$(CONFIG)/src/core/transport/chttp2/gen_hpack_tables.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgpr.a libs/$(CONFIG)/libgrpc.a

deps_gen_hpack_tables: $(GEN_HPACK_TABLES_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GEN_HPACK_TABLES_OBJS:.o=.dep)
endif
endif


CPP_PLUGIN_SRC = \
    src/compiler/cpp_plugin.cpp \
    src/compiler/cpp_generator.cpp \

CPP_PLUGIN_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CPP_PLUGIN_SRC))))

bins/$(CONFIG)/cpp_plugin: $(CPP_PLUGIN_OBJS)
	$(E) "[HOSTLD]  Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(HOST_LDXX) $(HOST_LDFLAGS) $(CPP_PLUGIN_OBJS) $(HOST_LDLIBSXX) $(HOST_LDLIBS) $(HOST_LDLIBS_PROTOC) -o bins/$(CONFIG)/cpp_plugin

objs/$(CONFIG)/src/compiler/cpp_plugin.o: 
objs/$(CONFIG)/src/compiler/cpp_generator.o: 

deps_cpp_plugin: $(CPP_PLUGIN_OBJS:.o=.dep)

ifneq ($(NO_DEPS),true)
-include $(CPP_PLUGIN_OBJS:.o=.dep)
endif


RUBY_PLUGIN_SRC = \
    src/compiler/ruby_plugin.cpp \
    src/compiler/ruby_generator.cpp \

RUBY_PLUGIN_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(RUBY_PLUGIN_SRC))))

bins/$(CONFIG)/ruby_plugin: $(RUBY_PLUGIN_OBJS)
	$(E) "[HOSTLD]  Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(HOST_LDXX) $(HOST_LDFLAGS) $(RUBY_PLUGIN_OBJS) $(HOST_LDLIBSXX) $(HOST_LDLIBS) $(HOST_LDLIBS_PROTOC) -o bins/$(CONFIG)/ruby_plugin

objs/$(CONFIG)/src/compiler/ruby_plugin.o: 
objs/$(CONFIG)/src/compiler/ruby_generator.o: 

deps_ruby_plugin: $(RUBY_PLUGIN_OBJS:.o=.dep)

ifneq ($(NO_DEPS),true)
-include $(RUBY_PLUGIN_OBJS:.o=.dep)
endif


GRPC_BYTE_BUFFER_READER_TEST_SRC = \
    test/core/surface/byte_buffer_reader_test.c \

GRPC_BYTE_BUFFER_READER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_BYTE_BUFFER_READER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_byte_buffer_reader_test: openssl_dep_error

else

bins/$(CONFIG)/grpc_byte_buffer_reader_test: $(GRPC_BYTE_BUFFER_READER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_BYTE_BUFFER_READER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_byte_buffer_reader_test

endif

objs/$(CONFIG)/test/core/surface/byte_buffer_reader_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_byte_buffer_reader_test: $(GRPC_BYTE_BUFFER_READER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_BYTE_BUFFER_READER_TEST_OBJS:.o=.dep)
endif
endif


GPR_CANCELLABLE_TEST_SRC = \
    test/core/support/cancellable_test.c \

GPR_CANCELLABLE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_CANCELLABLE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_cancellable_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_cancellable_test: $(GPR_CANCELLABLE_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_CANCELLABLE_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_cancellable_test

endif

objs/$(CONFIG)/test/core/support/cancellable_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_cancellable_test: $(GPR_CANCELLABLE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_CANCELLABLE_TEST_OBJS:.o=.dep)
endif
endif


GPR_LOG_TEST_SRC = \
    test/core/support/log_test.c \

GPR_LOG_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_LOG_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_log_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_log_test: $(GPR_LOG_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_LOG_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_log_test

endif

objs/$(CONFIG)/test/core/support/log_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_log_test: $(GPR_LOG_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_LOG_TEST_OBJS:.o=.dep)
endif
endif


GPR_USEFUL_TEST_SRC = \
    test/core/support/useful_test.c \

GPR_USEFUL_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_USEFUL_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_useful_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_useful_test: $(GPR_USEFUL_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_USEFUL_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_useful_test

endif

objs/$(CONFIG)/test/core/support/useful_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_useful_test: $(GPR_USEFUL_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_USEFUL_TEST_OBJS:.o=.dep)
endif
endif


GPR_CMDLINE_TEST_SRC = \
    test/core/support/cmdline_test.c \

GPR_CMDLINE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_CMDLINE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_cmdline_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_cmdline_test: $(GPR_CMDLINE_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_CMDLINE_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_cmdline_test

endif

objs/$(CONFIG)/test/core/support/cmdline_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_cmdline_test: $(GPR_CMDLINE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_CMDLINE_TEST_OBJS:.o=.dep)
endif
endif


GPR_HISTOGRAM_TEST_SRC = \
    test/core/support/histogram_test.c \

GPR_HISTOGRAM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_HISTOGRAM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_histogram_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_histogram_test: $(GPR_HISTOGRAM_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_HISTOGRAM_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_histogram_test

endif

objs/$(CONFIG)/test/core/support/histogram_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_histogram_test: $(GPR_HISTOGRAM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_HISTOGRAM_TEST_OBJS:.o=.dep)
endif
endif


GPR_HOST_PORT_TEST_SRC = \
    test/core/support/host_port_test.c \

GPR_HOST_PORT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_HOST_PORT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_host_port_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_host_port_test: $(GPR_HOST_PORT_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_HOST_PORT_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_host_port_test

endif

objs/$(CONFIG)/test/core/support/host_port_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_host_port_test: $(GPR_HOST_PORT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_HOST_PORT_TEST_OBJS:.o=.dep)
endif
endif


GPR_SLICE_BUFFER_TEST_SRC = \
    test/core/support/slice_buffer_test.c \

GPR_SLICE_BUFFER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_SLICE_BUFFER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_slice_buffer_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_slice_buffer_test: $(GPR_SLICE_BUFFER_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_SLICE_BUFFER_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_slice_buffer_test

endif

objs/$(CONFIG)/test/core/support/slice_buffer_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_slice_buffer_test: $(GPR_SLICE_BUFFER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_SLICE_BUFFER_TEST_OBJS:.o=.dep)
endif
endif


GPR_SLICE_TEST_SRC = \
    test/core/support/slice_test.c \

GPR_SLICE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_SLICE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_slice_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_slice_test: $(GPR_SLICE_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_SLICE_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_slice_test

endif

objs/$(CONFIG)/test/core/support/slice_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_slice_test: $(GPR_SLICE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_SLICE_TEST_OBJS:.o=.dep)
endif
endif


GPR_STRING_TEST_SRC = \
    test/core/support/string_test.c \

GPR_STRING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_STRING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_string_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_string_test: $(GPR_STRING_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_STRING_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_string_test

endif

objs/$(CONFIG)/test/core/support/string_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_string_test: $(GPR_STRING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_STRING_TEST_OBJS:.o=.dep)
endif
endif


GPR_SYNC_TEST_SRC = \
    test/core/support/sync_test.c \

GPR_SYNC_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_SYNC_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_sync_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_sync_test: $(GPR_SYNC_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_SYNC_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_sync_test

endif

objs/$(CONFIG)/test/core/support/sync_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_sync_test: $(GPR_SYNC_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_SYNC_TEST_OBJS:.o=.dep)
endif
endif


GPR_THD_TEST_SRC = \
    test/core/support/thd_test.c \

GPR_THD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_THD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_thd_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_thd_test: $(GPR_THD_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_THD_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_thd_test

endif

objs/$(CONFIG)/test/core/support/thd_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_thd_test: $(GPR_THD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_THD_TEST_OBJS:.o=.dep)
endif
endif


GPR_TIME_TEST_SRC = \
    test/core/support/time_test.c \

GPR_TIME_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GPR_TIME_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/gpr_time_test: openssl_dep_error

else

bins/$(CONFIG)/gpr_time_test: $(GPR_TIME_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GPR_TIME_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/gpr_time_test

endif

objs/$(CONFIG)/test/core/support/time_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_gpr_time_test: $(GPR_TIME_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GPR_TIME_TEST_OBJS:.o=.dep)
endif
endif


MURMUR_HASH_TEST_SRC = \
    test/core/support/murmur_hash_test.c \

MURMUR_HASH_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(MURMUR_HASH_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/murmur_hash_test: openssl_dep_error

else

bins/$(CONFIG)/murmur_hash_test: $(MURMUR_HASH_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(MURMUR_HASH_TEST_OBJS) libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/murmur_hash_test

endif

objs/$(CONFIG)/test/core/support/murmur_hash_test.o:  libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_murmur_hash_test: $(MURMUR_HASH_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(MURMUR_HASH_TEST_OBJS:.o=.dep)
endif
endif


GRPC_STREAM_OP_TEST_SRC = \
    test/core/transport/stream_op_test.c \

GRPC_STREAM_OP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_STREAM_OP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_stream_op_test: openssl_dep_error

else

bins/$(CONFIG)/grpc_stream_op_test: $(GRPC_STREAM_OP_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_STREAM_OP_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_stream_op_test

endif

objs/$(CONFIG)/test/core/transport/stream_op_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_stream_op_test: $(GRPC_STREAM_OP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_STREAM_OP_TEST_OBJS:.o=.dep)
endif
endif


ALPN_TEST_SRC = \
    test/core/transport/chttp2/alpn_test.c \

ALPN_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(ALPN_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/alpn_test: openssl_dep_error

else

bins/$(CONFIG)/alpn_test: $(ALPN_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(ALPN_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/alpn_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/alpn_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_alpn_test: $(ALPN_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(ALPN_TEST_OBJS:.o=.dep)
endif
endif


TIME_AVERAGED_STATS_TEST_SRC = \
    test/core/iomgr/time_averaged_stats_test.c \

TIME_AVERAGED_STATS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(TIME_AVERAGED_STATS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/time_averaged_stats_test: openssl_dep_error

else

bins/$(CONFIG)/time_averaged_stats_test: $(TIME_AVERAGED_STATS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(TIME_AVERAGED_STATS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/time_averaged_stats_test

endif

objs/$(CONFIG)/test/core/iomgr/time_averaged_stats_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_time_averaged_stats_test: $(TIME_AVERAGED_STATS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(TIME_AVERAGED_STATS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_STREAM_ENCODER_TEST_SRC = \
    test/core/transport/chttp2/stream_encoder_test.c \

CHTTP2_STREAM_ENCODER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_STREAM_ENCODER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_stream_encoder_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_stream_encoder_test: $(CHTTP2_STREAM_ENCODER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_STREAM_ENCODER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_stream_encoder_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/stream_encoder_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_chttp2_stream_encoder_test: $(CHTTP2_STREAM_ENCODER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_STREAM_ENCODER_TEST_OBJS:.o=.dep)
endif
endif


HPACK_TABLE_TEST_SRC = \
    test/core/transport/chttp2/hpack_table_test.c \

HPACK_TABLE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(HPACK_TABLE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/hpack_table_test: openssl_dep_error

else

bins/$(CONFIG)/hpack_table_test: $(HPACK_TABLE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(HPACK_TABLE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/hpack_table_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/hpack_table_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_hpack_table_test: $(HPACK_TABLE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(HPACK_TABLE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_STREAM_MAP_TEST_SRC = \
    test/core/transport/chttp2/stream_map_test.c \

CHTTP2_STREAM_MAP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_STREAM_MAP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_stream_map_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_stream_map_test: $(CHTTP2_STREAM_MAP_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_STREAM_MAP_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_stream_map_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/stream_map_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_chttp2_stream_map_test: $(CHTTP2_STREAM_MAP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_STREAM_MAP_TEST_OBJS:.o=.dep)
endif
endif


HPACK_PARSER_TEST_SRC = \
    test/core/transport/chttp2/hpack_parser_test.c \

HPACK_PARSER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(HPACK_PARSER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/hpack_parser_test: openssl_dep_error

else

bins/$(CONFIG)/hpack_parser_test: $(HPACK_PARSER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(HPACK_PARSER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/hpack_parser_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/hpack_parser_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_hpack_parser_test: $(HPACK_PARSER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(HPACK_PARSER_TEST_OBJS:.o=.dep)
endif
endif


TRANSPORT_METADATA_TEST_SRC = \
    test/core/transport/metadata_test.c \

TRANSPORT_METADATA_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(TRANSPORT_METADATA_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/transport_metadata_test: openssl_dep_error

else

bins/$(CONFIG)/transport_metadata_test: $(TRANSPORT_METADATA_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(TRANSPORT_METADATA_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/transport_metadata_test

endif

objs/$(CONFIG)/test/core/transport/metadata_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_transport_metadata_test: $(TRANSPORT_METADATA_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(TRANSPORT_METADATA_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_STATUS_CONVERSION_TEST_SRC = \
    test/core/transport/chttp2/status_conversion_test.c \

CHTTP2_STATUS_CONVERSION_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_STATUS_CONVERSION_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_status_conversion_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_status_conversion_test: $(CHTTP2_STATUS_CONVERSION_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_STATUS_CONVERSION_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_status_conversion_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/status_conversion_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_chttp2_status_conversion_test: $(CHTTP2_STATUS_CONVERSION_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_STATUS_CONVERSION_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_TRANSPORT_END2END_TEST_SRC = \
    test/core/transport/chttp2_transport_end2end_test.c \

CHTTP2_TRANSPORT_END2END_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_TRANSPORT_END2END_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_transport_end2end_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_transport_end2end_test: $(CHTTP2_TRANSPORT_END2END_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_TRANSPORT_END2END_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_transport_end2end_test

endif

objs/$(CONFIG)/test/core/transport/chttp2_transport_end2end_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_chttp2_transport_end2end_test: $(CHTTP2_TRANSPORT_END2END_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_TRANSPORT_END2END_TEST_OBJS:.o=.dep)
endif
endif


TCP_POSIX_TEST_SRC = \
    test/core/iomgr/tcp_posix_test.c \

TCP_POSIX_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(TCP_POSIX_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/tcp_posix_test: openssl_dep_error

else

bins/$(CONFIG)/tcp_posix_test: $(TCP_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(TCP_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/tcp_posix_test

endif

objs/$(CONFIG)/test/core/iomgr/tcp_posix_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_tcp_posix_test: $(TCP_POSIX_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(TCP_POSIX_TEST_OBJS:.o=.dep)
endif
endif


DUALSTACK_SOCKET_TEST_SRC = \
    test/core/end2end/dualstack_socket_test.c \

DUALSTACK_SOCKET_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(DUALSTACK_SOCKET_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/dualstack_socket_test: openssl_dep_error

else

bins/$(CONFIG)/dualstack_socket_test: $(DUALSTACK_SOCKET_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(DUALSTACK_SOCKET_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/dualstack_socket_test

endif

objs/$(CONFIG)/test/core/end2end/dualstack_socket_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_dualstack_socket_test: $(DUALSTACK_SOCKET_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(DUALSTACK_SOCKET_TEST_OBJS:.o=.dep)
endif
endif


NO_SERVER_TEST_SRC = \
    test/core/end2end/no_server_test.c \

NO_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(NO_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/no_server_test: openssl_dep_error

else

bins/$(CONFIG)/no_server_test: $(NO_SERVER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(NO_SERVER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/no_server_test

endif

objs/$(CONFIG)/test/core/end2end/no_server_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_no_server_test: $(NO_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(NO_SERVER_TEST_OBJS:.o=.dep)
endif
endif


RESOLVE_ADDRESS_TEST_SRC = \
    test/core/iomgr/resolve_address_test.c \

RESOLVE_ADDRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(RESOLVE_ADDRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/resolve_address_test: openssl_dep_error

else

bins/$(CONFIG)/resolve_address_test: $(RESOLVE_ADDRESS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(RESOLVE_ADDRESS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/resolve_address_test

endif

objs/$(CONFIG)/test/core/iomgr/resolve_address_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_resolve_address_test: $(RESOLVE_ADDRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(RESOLVE_ADDRESS_TEST_OBJS:.o=.dep)
endif
endif


SOCKADDR_UTILS_TEST_SRC = \
    test/core/iomgr/sockaddr_utils_test.c \

SOCKADDR_UTILS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(SOCKADDR_UTILS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/sockaddr_utils_test: openssl_dep_error

else

bins/$(CONFIG)/sockaddr_utils_test: $(SOCKADDR_UTILS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(SOCKADDR_UTILS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/sockaddr_utils_test

endif

objs/$(CONFIG)/test/core/iomgr/sockaddr_utils_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_sockaddr_utils_test: $(SOCKADDR_UTILS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(SOCKADDR_UTILS_TEST_OBJS:.o=.dep)
endif
endif


TCP_SERVER_POSIX_TEST_SRC = \
    test/core/iomgr/tcp_server_posix_test.c \

TCP_SERVER_POSIX_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(TCP_SERVER_POSIX_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/tcp_server_posix_test: openssl_dep_error

else

bins/$(CONFIG)/tcp_server_posix_test: $(TCP_SERVER_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(TCP_SERVER_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/tcp_server_posix_test

endif

objs/$(CONFIG)/test/core/iomgr/tcp_server_posix_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_tcp_server_posix_test: $(TCP_SERVER_POSIX_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(TCP_SERVER_POSIX_TEST_OBJS:.o=.dep)
endif
endif


TCP_CLIENT_POSIX_TEST_SRC = \
    test/core/iomgr/tcp_client_posix_test.c \

TCP_CLIENT_POSIX_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(TCP_CLIENT_POSIX_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/tcp_client_posix_test: openssl_dep_error

else

bins/$(CONFIG)/tcp_client_posix_test: $(TCP_CLIENT_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(TCP_CLIENT_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/tcp_client_posix_test

endif

objs/$(CONFIG)/test/core/iomgr/tcp_client_posix_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_tcp_client_posix_test: $(TCP_CLIENT_POSIX_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(TCP_CLIENT_POSIX_TEST_OBJS:.o=.dep)
endif
endif


GRPC_CHANNEL_STACK_TEST_SRC = \
    test/core/channel/channel_stack_test.c \

GRPC_CHANNEL_STACK_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_CHANNEL_STACK_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_channel_stack_test: openssl_dep_error

else

bins/$(CONFIG)/grpc_channel_stack_test: $(GRPC_CHANNEL_STACK_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_CHANNEL_STACK_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_channel_stack_test

endif

objs/$(CONFIG)/test/core/channel/channel_stack_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_channel_stack_test: $(GRPC_CHANNEL_STACK_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_CHANNEL_STACK_TEST_OBJS:.o=.dep)
endif
endif


METADATA_BUFFER_TEST_SRC = \
    test/core/channel/metadata_buffer_test.c \

METADATA_BUFFER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(METADATA_BUFFER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/metadata_buffer_test: openssl_dep_error

else

bins/$(CONFIG)/metadata_buffer_test: $(METADATA_BUFFER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(METADATA_BUFFER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/metadata_buffer_test

endif

objs/$(CONFIG)/test/core/channel/metadata_buffer_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_metadata_buffer_test: $(METADATA_BUFFER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(METADATA_BUFFER_TEST_OBJS:.o=.dep)
endif
endif


GRPC_COMPLETION_QUEUE_TEST_SRC = \
    test/core/surface/completion_queue_test.c \

GRPC_COMPLETION_QUEUE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_COMPLETION_QUEUE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_completion_queue_test: openssl_dep_error

else

bins/$(CONFIG)/grpc_completion_queue_test: $(GRPC_COMPLETION_QUEUE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_COMPLETION_QUEUE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_completion_queue_test

endif

objs/$(CONFIG)/test/core/surface/completion_queue_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_completion_queue_test: $(GRPC_COMPLETION_QUEUE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_COMPLETION_QUEUE_TEST_OBJS:.o=.dep)
endif
endif


GRPC_COMPLETION_QUEUE_BENCHMARK_SRC = \
    test/core/surface/completion_queue_benchmark.c \

GRPC_COMPLETION_QUEUE_BENCHMARK_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_COMPLETION_QUEUE_BENCHMARK_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_completion_queue_benchmark: openssl_dep_error

else

bins/$(CONFIG)/grpc_completion_queue_benchmark: $(GRPC_COMPLETION_QUEUE_BENCHMARK_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_COMPLETION_QUEUE_BENCHMARK_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_completion_queue_benchmark

endif

objs/$(CONFIG)/test/core/surface/completion_queue_benchmark.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_completion_queue_benchmark: $(GRPC_COMPLETION_QUEUE_BENCHMARK_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_COMPLETION_QUEUE_BENCHMARK_OBJS:.o=.dep)
endif
endif


CENSUS_TRACE_STORE_TEST_SRC = \
    test/core/statistics/trace_test.c \

CENSUS_TRACE_STORE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_TRACE_STORE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_trace_store_test: openssl_dep_error

else

bins/$(CONFIG)/census_trace_store_test: $(CENSUS_TRACE_STORE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_TRACE_STORE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_trace_store_test

endif

objs/$(CONFIG)/test/core/statistics/trace_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_trace_store_test: $(CENSUS_TRACE_STORE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_TRACE_STORE_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_STATS_STORE_TEST_SRC = \
    test/core/statistics/rpc_stats_test.c \

CENSUS_STATS_STORE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_STATS_STORE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_stats_store_test: openssl_dep_error

else

bins/$(CONFIG)/census_stats_store_test: $(CENSUS_STATS_STORE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_STATS_STORE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_stats_store_test

endif

objs/$(CONFIG)/test/core/statistics/rpc_stats_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_stats_store_test: $(CENSUS_STATS_STORE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_STATS_STORE_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_WINDOW_STATS_TEST_SRC = \
    test/core/statistics/window_stats_test.c \

CENSUS_WINDOW_STATS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_WINDOW_STATS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_window_stats_test: openssl_dep_error

else

bins/$(CONFIG)/census_window_stats_test: $(CENSUS_WINDOW_STATS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_WINDOW_STATS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_window_stats_test

endif

objs/$(CONFIG)/test/core/statistics/window_stats_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_window_stats_test: $(CENSUS_WINDOW_STATS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_WINDOW_STATS_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_STATISTICS_QUICK_TEST_SRC = \
    test/core/statistics/quick_test.c \

CENSUS_STATISTICS_QUICK_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_STATISTICS_QUICK_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_statistics_quick_test: openssl_dep_error

else

bins/$(CONFIG)/census_statistics_quick_test: $(CENSUS_STATISTICS_QUICK_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_STATISTICS_QUICK_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_statistics_quick_test

endif

objs/$(CONFIG)/test/core/statistics/quick_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_statistics_quick_test: $(CENSUS_STATISTICS_QUICK_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_STATISTICS_QUICK_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_STATISTICS_SMALL_LOG_TEST_SRC = \
    test/core/statistics/small_log_test.c \

CENSUS_STATISTICS_SMALL_LOG_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_STATISTICS_SMALL_LOG_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_statistics_small_log_test: openssl_dep_error

else

bins/$(CONFIG)/census_statistics_small_log_test: $(CENSUS_STATISTICS_SMALL_LOG_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_STATISTICS_SMALL_LOG_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_statistics_small_log_test

endif

objs/$(CONFIG)/test/core/statistics/small_log_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_statistics_small_log_test: $(CENSUS_STATISTICS_SMALL_LOG_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_STATISTICS_SMALL_LOG_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_STATISTICS_PERFORMANCE_TEST_SRC = \
    test/core/statistics/performance_test.c \

CENSUS_STATISTICS_PERFORMANCE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_STATISTICS_PERFORMANCE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_statistics_performance_test: openssl_dep_error

else

bins/$(CONFIG)/census_statistics_performance_test: $(CENSUS_STATISTICS_PERFORMANCE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_STATISTICS_PERFORMANCE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_statistics_performance_test

endif

objs/$(CONFIG)/test/core/statistics/performance_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_statistics_performance_test: $(CENSUS_STATISTICS_PERFORMANCE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_STATISTICS_PERFORMANCE_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_STATISTICS_MULTIPLE_WRITERS_TEST_SRC = \
    test/core/statistics/multiple_writers_test.c \

CENSUS_STATISTICS_MULTIPLE_WRITERS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_STATISTICS_MULTIPLE_WRITERS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_statistics_multiple_writers_test: openssl_dep_error

else

bins/$(CONFIG)/census_statistics_multiple_writers_test: $(CENSUS_STATISTICS_MULTIPLE_WRITERS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_STATISTICS_MULTIPLE_WRITERS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_statistics_multiple_writers_test

endif

objs/$(CONFIG)/test/core/statistics/multiple_writers_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_statistics_multiple_writers_test: $(CENSUS_STATISTICS_MULTIPLE_WRITERS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_STATISTICS_MULTIPLE_WRITERS_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_STATISTICS_MULTIPLE_WRITERS_CIRCULAR_BUFFER_TEST_SRC = \
    test/core/statistics/multiple_writers_circular_buffer_test.c \

CENSUS_STATISTICS_MULTIPLE_WRITERS_CIRCULAR_BUFFER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_STATISTICS_MULTIPLE_WRITERS_CIRCULAR_BUFFER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_statistics_multiple_writers_circular_buffer_test: openssl_dep_error

else

bins/$(CONFIG)/census_statistics_multiple_writers_circular_buffer_test: $(CENSUS_STATISTICS_MULTIPLE_WRITERS_CIRCULAR_BUFFER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_STATISTICS_MULTIPLE_WRITERS_CIRCULAR_BUFFER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_statistics_multiple_writers_circular_buffer_test

endif

objs/$(CONFIG)/test/core/statistics/multiple_writers_circular_buffer_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_statistics_multiple_writers_circular_buffer_test: $(CENSUS_STATISTICS_MULTIPLE_WRITERS_CIRCULAR_BUFFER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_STATISTICS_MULTIPLE_WRITERS_CIRCULAR_BUFFER_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_STUB_TEST_SRC = \
    test/core/statistics/census_stub_test.c \

CENSUS_STUB_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_STUB_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_stub_test: openssl_dep_error

else

bins/$(CONFIG)/census_stub_test: $(CENSUS_STUB_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_STUB_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_stub_test

endif

objs/$(CONFIG)/test/core/statistics/census_stub_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_stub_test: $(CENSUS_STUB_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_STUB_TEST_OBJS:.o=.dep)
endif
endif


CENSUS_HASH_TABLE_TEST_SRC = \
    test/core/statistics/hash_table_test.c \

CENSUS_HASH_TABLE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CENSUS_HASH_TABLE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/census_hash_table_test: openssl_dep_error

else

bins/$(CONFIG)/census_hash_table_test: $(CENSUS_HASH_TABLE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CENSUS_HASH_TABLE_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/census_hash_table_test

endif

objs/$(CONFIG)/test/core/statistics/hash_table_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_census_hash_table_test: $(CENSUS_HASH_TABLE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CENSUS_HASH_TABLE_TEST_OBJS:.o=.dep)
endif
endif


FLING_SERVER_SRC = \
    test/core/fling/server.c \

FLING_SERVER_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(FLING_SERVER_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/fling_server: openssl_dep_error

else

bins/$(CONFIG)/fling_server: $(FLING_SERVER_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(FLING_SERVER_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/fling_server

endif

objs/$(CONFIG)/test/core/fling/server.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_fling_server: $(FLING_SERVER_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(FLING_SERVER_OBJS:.o=.dep)
endif
endif


FLING_CLIENT_SRC = \
    test/core/fling/client.c \

FLING_CLIENT_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(FLING_CLIENT_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/fling_client: openssl_dep_error

else

bins/$(CONFIG)/fling_client: $(FLING_CLIENT_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(FLING_CLIENT_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/fling_client

endif

objs/$(CONFIG)/test/core/fling/client.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_fling_client: $(FLING_CLIENT_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(FLING_CLIENT_OBJS:.o=.dep)
endif
endif


FLING_TEST_SRC = \
    test/core/fling/fling_test.c \

FLING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(FLING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/fling_test: openssl_dep_error

else

bins/$(CONFIG)/fling_test: $(FLING_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(FLING_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/fling_test

endif

objs/$(CONFIG)/test/core/fling/fling_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_fling_test: $(FLING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(FLING_TEST_OBJS:.o=.dep)
endif
endif


ECHO_SERVER_SRC = \
    test/core/echo/server.c \

ECHO_SERVER_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(ECHO_SERVER_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/echo_server: openssl_dep_error

else

bins/$(CONFIG)/echo_server: $(ECHO_SERVER_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(ECHO_SERVER_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/echo_server

endif

objs/$(CONFIG)/test/core/echo/server.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_echo_server: $(ECHO_SERVER_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(ECHO_SERVER_OBJS:.o=.dep)
endif
endif


ECHO_CLIENT_SRC = \
    test/core/echo/client.c \

ECHO_CLIENT_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(ECHO_CLIENT_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/echo_client: openssl_dep_error

else

bins/$(CONFIG)/echo_client: $(ECHO_CLIENT_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(ECHO_CLIENT_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/echo_client

endif

objs/$(CONFIG)/test/core/echo/client.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_echo_client: $(ECHO_CLIENT_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(ECHO_CLIENT_OBJS:.o=.dep)
endif
endif


ECHO_TEST_SRC = \
    test/core/echo/echo_test.c \

ECHO_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(ECHO_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/echo_test: openssl_dep_error

else

bins/$(CONFIG)/echo_test: $(ECHO_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(ECHO_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/echo_test

endif

objs/$(CONFIG)/test/core/echo/echo_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_echo_test: $(ECHO_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(ECHO_TEST_OBJS:.o=.dep)
endif
endif


LOW_LEVEL_PING_PONG_BENCHMARK_SRC = \
    test/core/network_benchmarks/low_level_ping_pong.c \

LOW_LEVEL_PING_PONG_BENCHMARK_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LOW_LEVEL_PING_PONG_BENCHMARK_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/low_level_ping_pong_benchmark: openssl_dep_error

else

bins/$(CONFIG)/low_level_ping_pong_benchmark: $(LOW_LEVEL_PING_PONG_BENCHMARK_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(LOW_LEVEL_PING_PONG_BENCHMARK_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/low_level_ping_pong_benchmark

endif

objs/$(CONFIG)/test/core/network_benchmarks/low_level_ping_pong.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_low_level_ping_pong_benchmark: $(LOW_LEVEL_PING_PONG_BENCHMARK_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LOW_LEVEL_PING_PONG_BENCHMARK_OBJS:.o=.dep)
endif
endif


MESSAGE_COMPRESS_TEST_SRC = \
    test/core/compression/message_compress_test.c \

MESSAGE_COMPRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(MESSAGE_COMPRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/message_compress_test: openssl_dep_error

else

bins/$(CONFIG)/message_compress_test: $(MESSAGE_COMPRESS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(MESSAGE_COMPRESS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/message_compress_test

endif

objs/$(CONFIG)/test/core/compression/message_compress_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_message_compress_test: $(MESSAGE_COMPRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(MESSAGE_COMPRESS_TEST_OBJS:.o=.dep)
endif
endif


BIN_ENCODER_TEST_SRC = \
    test/core/transport/chttp2/bin_encoder_test.c \

BIN_ENCODER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(BIN_ENCODER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/bin_encoder_test: openssl_dep_error

else

bins/$(CONFIG)/bin_encoder_test: $(BIN_ENCODER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(BIN_ENCODER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/bin_encoder_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/bin_encoder_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_bin_encoder_test: $(BIN_ENCODER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(BIN_ENCODER_TEST_OBJS:.o=.dep)
endif
endif


SECURE_ENDPOINT_TEST_SRC = \
    test/core/security/secure_endpoint_test.c \

SECURE_ENDPOINT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(SECURE_ENDPOINT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/secure_endpoint_test: openssl_dep_error

else

bins/$(CONFIG)/secure_endpoint_test: $(SECURE_ENDPOINT_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(SECURE_ENDPOINT_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/secure_endpoint_test

endif

objs/$(CONFIG)/test/core/security/secure_endpoint_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_secure_endpoint_test: $(SECURE_ENDPOINT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(SECURE_ENDPOINT_TEST_OBJS:.o=.dep)
endif
endif


HTTPCLI_FORMAT_REQUEST_TEST_SRC = \
    test/core/httpcli/format_request_test.c \

HTTPCLI_FORMAT_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(HTTPCLI_FORMAT_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/httpcli_format_request_test: openssl_dep_error

else

bins/$(CONFIG)/httpcli_format_request_test: $(HTTPCLI_FORMAT_REQUEST_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(HTTPCLI_FORMAT_REQUEST_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/httpcli_format_request_test

endif

objs/$(CONFIG)/test/core/httpcli/format_request_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_httpcli_format_request_test: $(HTTPCLI_FORMAT_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(HTTPCLI_FORMAT_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


HTTPCLI_PARSER_TEST_SRC = \
    test/core/httpcli/parser_test.c \

HTTPCLI_PARSER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(HTTPCLI_PARSER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/httpcli_parser_test: openssl_dep_error

else

bins/$(CONFIG)/httpcli_parser_test: $(HTTPCLI_PARSER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(HTTPCLI_PARSER_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/httpcli_parser_test

endif

objs/$(CONFIG)/test/core/httpcli/parser_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_httpcli_parser_test: $(HTTPCLI_PARSER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(HTTPCLI_PARSER_TEST_OBJS:.o=.dep)
endif
endif


HTTPCLI_TEST_SRC = \
    test/core/httpcli/httpcli_test.c \

HTTPCLI_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(HTTPCLI_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/httpcli_test: openssl_dep_error

else

bins/$(CONFIG)/httpcli_test: $(HTTPCLI_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(HTTPCLI_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/httpcli_test

endif

objs/$(CONFIG)/test/core/httpcli/httpcli_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_httpcli_test: $(HTTPCLI_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(HTTPCLI_TEST_OBJS:.o=.dep)
endif
endif


GRPC_CREDENTIALS_TEST_SRC = \
    test/core/security/credentials_test.c \

GRPC_CREDENTIALS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_CREDENTIALS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_credentials_test: openssl_dep_error

else

bins/$(CONFIG)/grpc_credentials_test: $(GRPC_CREDENTIALS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_CREDENTIALS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_credentials_test

endif

objs/$(CONFIG)/test/core/security/credentials_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_credentials_test: $(GRPC_CREDENTIALS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_CREDENTIALS_TEST_OBJS:.o=.dep)
endif
endif


GRPC_FETCH_OAUTH2_SRC = \
    test/core/security/fetch_oauth2.c \

GRPC_FETCH_OAUTH2_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_FETCH_OAUTH2_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_fetch_oauth2: openssl_dep_error

else

bins/$(CONFIG)/grpc_fetch_oauth2: $(GRPC_FETCH_OAUTH2_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_FETCH_OAUTH2_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_fetch_oauth2

endif

objs/$(CONFIG)/test/core/security/fetch_oauth2.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_fetch_oauth2: $(GRPC_FETCH_OAUTH2_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_FETCH_OAUTH2_OBJS:.o=.dep)
endif
endif


GRPC_BASE64_TEST_SRC = \
    test/core/security/base64_test.c \

GRPC_BASE64_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_BASE64_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_base64_test: openssl_dep_error

else

bins/$(CONFIG)/grpc_base64_test: $(GRPC_BASE64_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_BASE64_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_base64_test

endif

objs/$(CONFIG)/test/core/security/base64_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_base64_test: $(GRPC_BASE64_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_BASE64_TEST_OBJS:.o=.dep)
endif
endif


GRPC_JSON_TOKEN_TEST_SRC = \
    test/core/security/json_token_test.c \

GRPC_JSON_TOKEN_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(GRPC_JSON_TOKEN_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/grpc_json_token_test: openssl_dep_error

else

bins/$(CONFIG)/grpc_json_token_test: $(GRPC_JSON_TOKEN_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(GRPC_JSON_TOKEN_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/grpc_json_token_test

endif

objs/$(CONFIG)/test/core/security/json_token_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_grpc_json_token_test: $(GRPC_JSON_TOKEN_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(GRPC_JSON_TOKEN_TEST_OBJS:.o=.dep)
endif
endif


TIMEOUT_ENCODING_TEST_SRC = \
    test/core/transport/chttp2/timeout_encoding_test.c \

TIMEOUT_ENCODING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(TIMEOUT_ENCODING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/timeout_encoding_test: openssl_dep_error

else

bins/$(CONFIG)/timeout_encoding_test: $(TIMEOUT_ENCODING_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(TIMEOUT_ENCODING_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/timeout_encoding_test

endif

objs/$(CONFIG)/test/core/transport/chttp2/timeout_encoding_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_timeout_encoding_test: $(TIMEOUT_ENCODING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(TIMEOUT_ENCODING_TEST_OBJS:.o=.dep)
endif
endif


FD_POSIX_TEST_SRC = \
    test/core/iomgr/fd_posix_test.c \

FD_POSIX_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(FD_POSIX_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/fd_posix_test: openssl_dep_error

else

bins/$(CONFIG)/fd_posix_test: $(FD_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(FD_POSIX_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/fd_posix_test

endif

objs/$(CONFIG)/test/core/iomgr/fd_posix_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_fd_posix_test: $(FD_POSIX_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(FD_POSIX_TEST_OBJS:.o=.dep)
endif
endif


FLING_STREAM_TEST_SRC = \
    test/core/fling/fling_stream_test.c \

FLING_STREAM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(FLING_STREAM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/fling_stream_test: openssl_dep_error

else

bins/$(CONFIG)/fling_stream_test: $(FLING_STREAM_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(FLING_STREAM_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/fling_stream_test

endif

objs/$(CONFIG)/test/core/fling/fling_stream_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_fling_stream_test: $(FLING_STREAM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(FLING_STREAM_TEST_OBJS:.o=.dep)
endif
endif


LAME_CLIENT_TEST_SRC = \
    test/core/surface/lame_client_test.c \

LAME_CLIENT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(LAME_CLIENT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/lame_client_test: openssl_dep_error

else

bins/$(CONFIG)/lame_client_test: $(LAME_CLIENT_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(LAME_CLIENT_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/lame_client_test

endif

objs/$(CONFIG)/test/core/surface/lame_client_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_lame_client_test: $(LAME_CLIENT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(LAME_CLIENT_TEST_OBJS:.o=.dep)
endif
endif


THREAD_POOL_TEST_SRC = \
    test/cpp/server/thread_pool_test.cc \

THREAD_POOL_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(THREAD_POOL_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/thread_pool_test: openssl_dep_error

else

bins/$(CONFIG)/thread_pool_test: $(THREAD_POOL_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(THREAD_POOL_TEST_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/thread_pool_test

endif

objs/$(CONFIG)/test/cpp/server/thread_pool_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_thread_pool_test: $(THREAD_POOL_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(THREAD_POOL_TEST_OBJS:.o=.dep)
endif
endif


STATUS_TEST_SRC = \
    test/cpp/util/status_test.cc \

STATUS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(STATUS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/status_test: openssl_dep_error

else

bins/$(CONFIG)/status_test: $(STATUS_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(STATUS_TEST_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/status_test

endif

objs/$(CONFIG)/test/cpp/util/status_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_status_test: $(STATUS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(STATUS_TEST_OBJS:.o=.dep)
endif
endif


SYNC_CLIENT_ASYNC_SERVER_TEST_SRC = \
    test/cpp/end2end/sync_client_async_server_test.cc \

SYNC_CLIENT_ASYNC_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(SYNC_CLIENT_ASYNC_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/sync_client_async_server_test: openssl_dep_error

else

bins/$(CONFIG)/sync_client_async_server_test: $(SYNC_CLIENT_ASYNC_SERVER_TEST_OBJS) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(SYNC_CLIENT_ASYNC_SERVER_TEST_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/sync_client_async_server_test

endif

objs/$(CONFIG)/test/cpp/end2end/sync_client_async_server_test.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_sync_client_async_server_test: $(SYNC_CLIENT_ASYNC_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(SYNC_CLIENT_ASYNC_SERVER_TEST_OBJS:.o=.dep)
endif
endif


QPS_CLIENT_SRC = \
    gens/test/cpp/qps/qpstest.pb.cc \
    test/cpp/qps/client.cc \

QPS_CLIENT_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(QPS_CLIENT_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/qps_client: openssl_dep_error

else

bins/$(CONFIG)/qps_client: $(QPS_CLIENT_OBJS) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(QPS_CLIENT_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/qps_client

endif

objs/$(CONFIG)/test/cpp/qps/qpstest.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/qps/client.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_qps_client: $(QPS_CLIENT_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(QPS_CLIENT_OBJS:.o=.dep)
endif
endif


QPS_SERVER_SRC = \
    gens/test/cpp/qps/qpstest.pb.cc \
    test/cpp/qps/server.cc \

QPS_SERVER_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(QPS_SERVER_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/qps_server: openssl_dep_error

else

bins/$(CONFIG)/qps_server: $(QPS_SERVER_OBJS) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(QPS_SERVER_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/qps_server

endif

objs/$(CONFIG)/test/cpp/qps/qpstest.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/qps/server.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_qps_server: $(QPS_SERVER_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(QPS_SERVER_OBJS:.o=.dep)
endif
endif


INTEROP_SERVER_SRC = \
    gens/test/cpp/interop/empty.pb.cc \
    gens/test/cpp/interop/messages.pb.cc \
    gens/test/cpp/interop/test.pb.cc \
    test/cpp/interop/server.cc \

INTEROP_SERVER_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(INTEROP_SERVER_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/interop_server: openssl_dep_error

else

bins/$(CONFIG)/interop_server: $(INTEROP_SERVER_OBJS) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(INTEROP_SERVER_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/interop_server

endif

objs/$(CONFIG)/test/cpp/interop/empty.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/interop/messages.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/interop/test.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/interop/server.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_interop_server: $(INTEROP_SERVER_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(INTEROP_SERVER_OBJS:.o=.dep)
endif
endif


INTEROP_CLIENT_SRC = \
    gens/test/cpp/interop/empty.pb.cc \
    gens/test/cpp/interop/messages.pb.cc \
    gens/test/cpp/interop/test.pb.cc \
    test/cpp/interop/client.cc \

INTEROP_CLIENT_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(INTEROP_CLIENT_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/interop_client: openssl_dep_error

else

bins/$(CONFIG)/interop_client: $(INTEROP_CLIENT_OBJS) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(INTEROP_CLIENT_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/interop_client

endif

objs/$(CONFIG)/test/cpp/interop/empty.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/interop/messages.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/interop/test.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
objs/$(CONFIG)/test/cpp/interop/client.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_interop_client: $(INTEROP_CLIENT_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(INTEROP_CLIENT_OBJS:.o=.dep)
endif
endif


END2END_TEST_SRC = \
    test/cpp/end2end/end2end_test.cc \

END2END_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(END2END_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/end2end_test: openssl_dep_error

else

bins/$(CONFIG)/end2end_test: $(END2END_TEST_OBJS) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(END2END_TEST_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/end2end_test

endif

objs/$(CONFIG)/test/cpp/end2end/end2end_test.o:  libs/$(CONFIG)/libgrpc++_test_util.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_end2end_test: $(END2END_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(END2END_TEST_OBJS:.o=.dep)
endif
endif


CHANNEL_ARGUMENTS_TEST_SRC = \
    test/cpp/client/channel_arguments_test.cc \

CHANNEL_ARGUMENTS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHANNEL_ARGUMENTS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/channel_arguments_test: openssl_dep_error

else

bins/$(CONFIG)/channel_arguments_test: $(CHANNEL_ARGUMENTS_TEST_OBJS) libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(CHANNEL_ARGUMENTS_TEST_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/channel_arguments_test

endif

objs/$(CONFIG)/test/cpp/client/channel_arguments_test.o:  libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr.a

deps_channel_arguments_test: $(CHANNEL_ARGUMENTS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHANNEL_ARGUMENTS_TEST_OBJS:.o=.dep)
endif
endif


CREDENTIALS_TEST_SRC = \
    test/cpp/client/credentials_test.cc \

CREDENTIALS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CREDENTIALS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/credentials_test: openssl_dep_error

else

bins/$(CONFIG)/credentials_test: $(CREDENTIALS_TEST_OBJS) libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LDXX) $(LDFLAGS) $(CREDENTIALS_TEST_OBJS) $(GTEST_LIB) libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr.a $(LDLIBSXX) $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/credentials_test

endif

objs/$(CONFIG)/test/cpp/client/credentials_test.o:  libs/$(CONFIG)/libgrpc++.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr.a

deps_credentials_test: $(CREDENTIALS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CREDENTIALS_TEST_OBJS:.o=.dep)
endif
endif


ALARM_TEST_SRC = \
    test/core/iomgr/alarm_test.c \

ALARM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(ALARM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/alarm_test: openssl_dep_error

else

bins/$(CONFIG)/alarm_test: $(ALARM_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(ALARM_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/alarm_test

endif

objs/$(CONFIG)/test/core/iomgr/alarm_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_alarm_test: $(ALARM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(ALARM_TEST_OBJS:.o=.dep)
endif
endif


ALARM_LIST_TEST_SRC = \
    test/core/iomgr/alarm_list_test.c \

ALARM_LIST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(ALARM_LIST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/alarm_list_test: openssl_dep_error

else

bins/$(CONFIG)/alarm_list_test: $(ALARM_LIST_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(ALARM_LIST_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/alarm_list_test

endif

objs/$(CONFIG)/test/core/iomgr/alarm_list_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_alarm_list_test: $(ALARM_LIST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(ALARM_LIST_TEST_OBJS:.o=.dep)
endif
endif


ALARM_HEAP_TEST_SRC = \
    test/core/iomgr/alarm_heap_test.c \

ALARM_HEAP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(ALARM_HEAP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/alarm_heap_test: openssl_dep_error

else

bins/$(CONFIG)/alarm_heap_test: $(ALARM_HEAP_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(ALARM_HEAP_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/alarm_heap_test

endif

objs/$(CONFIG)/test/core/iomgr/alarm_heap_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_alarm_heap_test: $(ALARM_HEAP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(ALARM_HEAP_TEST_OBJS:.o=.dep)
endif
endif


TIME_TEST_SRC = \
    test/core/support/time_test.c \

TIME_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(TIME_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/time_test: openssl_dep_error

else

bins/$(CONFIG)/time_test: $(TIME_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(TIME_TEST_OBJS) libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/time_test

endif

objs/$(CONFIG)/test/core/support/time_test.o:  libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a

deps_time_test: $(TIME_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(TIME_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_TEST_SRC = \

CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_test: $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_test

endif


deps_chttp2_fake_security_cancel_after_accept_test: $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC = \

CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_and_writes_closed_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_and_writes_closed_test: $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_cancel_after_accept_and_writes_closed_test

endif


deps_chttp2_fake_security_cancel_after_accept_and_writes_closed_test: $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_CANCEL_AFTER_INVOKE_TEST_SRC = \

CHTTP2_FAKE_SECURITY_CANCEL_AFTER_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_cancel_after_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_cancel_after_invoke_test: $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_cancel_after_invoke_test

endif


deps_chttp2_fake_security_cancel_after_invoke_test: $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_CANCEL_BEFORE_INVOKE_TEST_SRC = \

CHTTP2_FAKE_SECURITY_CANCEL_BEFORE_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_CANCEL_BEFORE_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_cancel_before_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_cancel_before_invoke_test: $(CHTTP2_FAKE_SECURITY_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_cancel_before_invoke_test

endif


deps_chttp2_fake_security_cancel_before_invoke_test: $(CHTTP2_FAKE_SECURITY_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_CANCEL_IN_A_VACUUM_TEST_SRC = \

CHTTP2_FAKE_SECURITY_CANCEL_IN_A_VACUUM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_CANCEL_IN_A_VACUUM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_cancel_in_a_vacuum_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_cancel_in_a_vacuum_test: $(CHTTP2_FAKE_SECURITY_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_cancel_in_a_vacuum_test

endif


deps_chttp2_fake_security_cancel_in_a_vacuum_test: $(CHTTP2_FAKE_SECURITY_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_CENSUS_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_FAKE_SECURITY_CENSUS_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_CENSUS_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_census_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_census_simple_request_test: $(CHTTP2_FAKE_SECURITY_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_census_simple_request_test

endif


deps_chttp2_fake_security_census_simple_request_test: $(CHTTP2_FAKE_SECURITY_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_DISAPPEARING_SERVER_TEST_SRC = \

CHTTP2_FAKE_SECURITY_DISAPPEARING_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_DISAPPEARING_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_disappearing_server_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_disappearing_server_test: $(CHTTP2_FAKE_SECURITY_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_disappearing_server_test

endif


deps_chttp2_fake_security_disappearing_server_test: $(CHTTP2_FAKE_SECURITY_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC = \

CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test

endif


deps_chttp2_fake_security_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC = \

CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_tags_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_tags_test: $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_early_server_shutdown_finishes_tags_test

endif


deps_chttp2_fake_security_early_server_shutdown_finishes_tags_test: $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_INVOKE_LARGE_REQUEST_TEST_SRC = \

CHTTP2_FAKE_SECURITY_INVOKE_LARGE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_INVOKE_LARGE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_invoke_large_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_invoke_large_request_test: $(CHTTP2_FAKE_SECURITY_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_invoke_large_request_test

endif


deps_chttp2_fake_security_invoke_large_request_test: $(CHTTP2_FAKE_SECURITY_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_MAX_CONCURRENT_STREAMS_TEST_SRC = \

CHTTP2_FAKE_SECURITY_MAX_CONCURRENT_STREAMS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_MAX_CONCURRENT_STREAMS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_max_concurrent_streams_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_max_concurrent_streams_test: $(CHTTP2_FAKE_SECURITY_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_max_concurrent_streams_test

endif


deps_chttp2_fake_security_max_concurrent_streams_test: $(CHTTP2_FAKE_SECURITY_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_NO_OP_TEST_SRC = \

CHTTP2_FAKE_SECURITY_NO_OP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_NO_OP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_no_op_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_no_op_test: $(CHTTP2_FAKE_SECURITY_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_no_op_test

endif


deps_chttp2_fake_security_no_op_test: $(CHTTP2_FAKE_SECURITY_NO_OP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_NO_OP_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_PING_PONG_STREAMING_TEST_SRC = \

CHTTP2_FAKE_SECURITY_PING_PONG_STREAMING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_PING_PONG_STREAMING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_ping_pong_streaming_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_ping_pong_streaming_test: $(CHTTP2_FAKE_SECURITY_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_ping_pong_streaming_test

endif


deps_chttp2_fake_security_ping_pong_streaming_test: $(CHTTP2_FAKE_SECURITY_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_request_response_with_binary_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_request_response_with_binary_metadata_and_payload_test

endif


deps_chttp2_fake_security_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_request_response_with_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_request_response_with_metadata_and_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_request_response_with_metadata_and_payload_test

endif


deps_chttp2_fake_security_request_response_with_metadata_and_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC = \

CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_request_response_with_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_request_response_with_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_request_response_with_payload_test

endif


deps_chttp2_fake_security_request_response_with_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test

endif


deps_chttp2_fake_security_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_SIMPLE_DELAYED_REQUEST_TEST_SRC = \

CHTTP2_FAKE_SECURITY_SIMPLE_DELAYED_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_SIMPLE_DELAYED_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_simple_delayed_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_simple_delayed_request_test: $(CHTTP2_FAKE_SECURITY_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_simple_delayed_request_test

endif


deps_chttp2_fake_security_simple_delayed_request_test: $(CHTTP2_FAKE_SECURITY_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_FAKE_SECURITY_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_simple_request_test: $(CHTTP2_FAKE_SECURITY_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_simple_request_test

endif


deps_chttp2_fake_security_simple_request_test: $(CHTTP2_FAKE_SECURITY_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_THREAD_STRESS_TEST_SRC = \

CHTTP2_FAKE_SECURITY_THREAD_STRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_THREAD_STRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_thread_stress_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_thread_stress_test: $(CHTTP2_FAKE_SECURITY_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_thread_stress_test

endif


deps_chttp2_fake_security_thread_stress_test: $(CHTTP2_FAKE_SECURITY_THREAD_STRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_THREAD_STRESS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FAKE_SECURITY_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC = \

CHTTP2_FAKE_SECURITY_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FAKE_SECURITY_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fake_security_writes_done_hangs_with_pending_read_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fake_security_writes_done_hangs_with_pending_read_test: $(CHTTP2_FAKE_SECURITY_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FAKE_SECURITY_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fake_security.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fake_security_writes_done_hangs_with_pending_read_test

endif


deps_chttp2_fake_security_writes_done_hangs_with_pending_read_test: $(CHTTP2_FAKE_SECURITY_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FAKE_SECURITY_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_SRC = \

CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_test: $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_test

endif


deps_chttp2_fullstack_cancel_after_accept_test: $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC = \

CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_and_writes_closed_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_and_writes_closed_test: $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_cancel_after_accept_and_writes_closed_test

endif


deps_chttp2_fullstack_cancel_after_accept_and_writes_closed_test: $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_SRC = \

CHTTP2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_cancel_after_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_cancel_after_invoke_test: $(CHTTP2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_cancel_after_invoke_test

endif


deps_chttp2_fullstack_cancel_after_invoke_test: $(CHTTP2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_SRC = \

CHTTP2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_cancel_before_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_cancel_before_invoke_test: $(CHTTP2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_cancel_before_invoke_test

endif


deps_chttp2_fullstack_cancel_before_invoke_test: $(CHTTP2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_SRC = \

CHTTP2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_cancel_in_a_vacuum_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_cancel_in_a_vacuum_test: $(CHTTP2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_cancel_in_a_vacuum_test

endif


deps_chttp2_fullstack_cancel_in_a_vacuum_test: $(CHTTP2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_census_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_census_simple_request_test: $(CHTTP2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_census_simple_request_test

endif


deps_chttp2_fullstack_census_simple_request_test: $(CHTTP2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_DISAPPEARING_SERVER_TEST_SRC = \

CHTTP2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_DISAPPEARING_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_disappearing_server_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_disappearing_server_test: $(CHTTP2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_disappearing_server_test

endif


deps_chttp2_fullstack_disappearing_server_test: $(CHTTP2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC = \

CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test

endif


deps_chttp2_fullstack_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC = \

CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_tags_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_tags_test: $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_early_server_shutdown_finishes_tags_test

endif


deps_chttp2_fullstack_early_server_shutdown_finishes_tags_test: $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_SRC = \

CHTTP2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_invoke_large_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_invoke_large_request_test: $(CHTTP2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_invoke_large_request_test

endif


deps_chttp2_fullstack_invoke_large_request_test: $(CHTTP2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_SRC = \

CHTTP2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_max_concurrent_streams_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_max_concurrent_streams_test: $(CHTTP2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_max_concurrent_streams_test

endif


deps_chttp2_fullstack_max_concurrent_streams_test: $(CHTTP2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_NO_OP_TEST_SRC = \

CHTTP2_FULLSTACK_NO_OP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_NO_OP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_no_op_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_no_op_test: $(CHTTP2_FULLSTACK_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_no_op_test

endif


deps_chttp2_fullstack_no_op_test: $(CHTTP2_FULLSTACK_NO_OP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_NO_OP_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_PING_PONG_STREAMING_TEST_SRC = \

CHTTP2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_PING_PONG_STREAMING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_ping_pong_streaming_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_ping_pong_streaming_test: $(CHTTP2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_ping_pong_streaming_test

endif


deps_chttp2_fullstack_ping_pong_streaming_test: $(CHTTP2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_request_response_with_binary_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_request_response_with_binary_metadata_and_payload_test

endif


deps_chttp2_fullstack_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_request_response_with_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_request_response_with_metadata_and_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_request_response_with_metadata_and_payload_test

endif


deps_chttp2_fullstack_request_response_with_metadata_and_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC = \

CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_request_response_with_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_request_response_with_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_request_response_with_payload_test

endif


deps_chttp2_fullstack_request_response_with_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test

endif


deps_chttp2_fullstack_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_SRC = \

CHTTP2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_simple_delayed_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_simple_delayed_request_test: $(CHTTP2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_simple_delayed_request_test

endif


deps_chttp2_fullstack_simple_delayed_request_test: $(CHTTP2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_simple_request_test: $(CHTTP2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_simple_request_test

endif


deps_chttp2_fullstack_simple_request_test: $(CHTTP2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_THREAD_STRESS_TEST_SRC = \

CHTTP2_FULLSTACK_THREAD_STRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_THREAD_STRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_thread_stress_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_thread_stress_test: $(CHTTP2_FULLSTACK_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_thread_stress_test

endif


deps_chttp2_fullstack_thread_stress_test: $(CHTTP2_FULLSTACK_THREAD_STRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_THREAD_STRESS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC = \

CHTTP2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_fullstack_writes_done_hangs_with_pending_read_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_fullstack_writes_done_hangs_with_pending_read_test: $(CHTTP2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_fullstack.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_fullstack_writes_done_hangs_with_pending_read_test

endif


deps_chttp2_fullstack_writes_done_hangs_with_pending_read_test: $(CHTTP2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_test

endif


deps_chttp2_simple_ssl_fullstack_cancel_after_accept_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test

endif


deps_chttp2_simple_ssl_fullstack_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_invoke_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_after_invoke_test

endif


deps_chttp2_simple_ssl_fullstack_cancel_after_invoke_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_before_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_before_invoke_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_before_invoke_test

endif


deps_chttp2_simple_ssl_fullstack_cancel_before_invoke_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test

endif


deps_chttp2_simple_ssl_fullstack_cancel_in_a_vacuum_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_census_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_census_simple_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_census_simple_request_test

endif


deps_chttp2_simple_ssl_fullstack_census_simple_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_DISAPPEARING_SERVER_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_DISAPPEARING_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_disappearing_server_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_disappearing_server_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_disappearing_server_test

endif


deps_chttp2_simple_ssl_fullstack_disappearing_server_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test

endif


deps_chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test

endif


deps_chttp2_simple_ssl_fullstack_early_server_shutdown_finishes_tags_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_invoke_large_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_invoke_large_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_invoke_large_request_test

endif


deps_chttp2_simple_ssl_fullstack_invoke_large_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_max_concurrent_streams_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_max_concurrent_streams_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_max_concurrent_streams_test

endif


deps_chttp2_simple_ssl_fullstack_max_concurrent_streams_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_NO_OP_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_NO_OP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_NO_OP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_no_op_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_no_op_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_no_op_test

endif


deps_chttp2_simple_ssl_fullstack_no_op_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_NO_OP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_NO_OP_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_PING_PONG_STREAMING_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_PING_PONG_STREAMING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_ping_pong_streaming_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_ping_pong_streaming_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_ping_pong_streaming_test

endif


deps_chttp2_simple_ssl_fullstack_ping_pong_streaming_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test

endif


deps_chttp2_simple_ssl_fullstack_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test

endif


deps_chttp2_simple_ssl_fullstack_request_response_with_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_payload_test

endif


deps_chttp2_simple_ssl_fullstack_request_response_with_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test

endif


deps_chttp2_simple_ssl_fullstack_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_delayed_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_delayed_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_delayed_request_test

endif


deps_chttp2_simple_ssl_fullstack_simple_delayed_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_simple_request_test

endif


deps_chttp2_simple_ssl_fullstack_simple_request_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_THREAD_STRESS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_THREAD_STRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_THREAD_STRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_thread_stress_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_thread_stress_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_thread_stress_test

endif


deps_chttp2_simple_ssl_fullstack_thread_stress_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_THREAD_STRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_THREAD_STRESS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC = \

CHTTP2_SIMPLE_SSL_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_fullstack.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test

endif


deps_chttp2_simple_ssl_fullstack_writes_done_hangs_with_pending_read_test: $(CHTTP2_SIMPLE_SSL_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_cancel_after_invoke_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_cancel_before_invoke_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_cancel_in_a_vacuum_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_census_simple_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_DISAPPEARING_SERVER_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_DISAPPEARING_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_disappearing_server_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_early_server_shutdown_finishes_tags_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_invoke_large_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_max_concurrent_streams_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_NO_OP_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_NO_OP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_NO_OP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_no_op_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_no_op_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_no_op_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_no_op_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_NO_OP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_NO_OP_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_PING_PONG_STREAMING_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_PING_PONG_STREAMING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_ping_pong_streaming_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_simple_delayed_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_simple_request_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_THREAD_STRESS_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_THREAD_STRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_THREAD_STRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_thread_stress_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_THREAD_STRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_THREAD_STRESS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC = \

CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_simple_ssl_with_oauth2_fullstack.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test

endif


deps_chttp2_simple_ssl_with_oauth2_fullstack_writes_done_hangs_with_pending_read_test: $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SIMPLE_SSL_WITH_OAUTH2_FULLSTACK_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_TEST_SRC = \

CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_test: $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_test

endif


deps_chttp2_socket_pair_cancel_after_accept_test: $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC = \

CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_and_writes_closed_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_cancel_after_accept_and_writes_closed_test

endif


deps_chttp2_socket_pair_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_CANCEL_AFTER_INVOKE_TEST_SRC = \

CHTTP2_SOCKET_PAIR_CANCEL_AFTER_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_cancel_after_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_cancel_after_invoke_test: $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_cancel_after_invoke_test

endif


deps_chttp2_socket_pair_cancel_after_invoke_test: $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_CANCEL_BEFORE_INVOKE_TEST_SRC = \

CHTTP2_SOCKET_PAIR_CANCEL_BEFORE_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_CANCEL_BEFORE_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_cancel_before_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_cancel_before_invoke_test: $(CHTTP2_SOCKET_PAIR_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_cancel_before_invoke_test

endif


deps_chttp2_socket_pair_cancel_before_invoke_test: $(CHTTP2_SOCKET_PAIR_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_CANCEL_IN_A_VACUUM_TEST_SRC = \

CHTTP2_SOCKET_PAIR_CANCEL_IN_A_VACUUM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_CANCEL_IN_A_VACUUM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_cancel_in_a_vacuum_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_cancel_in_a_vacuum_test: $(CHTTP2_SOCKET_PAIR_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_cancel_in_a_vacuum_test

endif


deps_chttp2_socket_pair_cancel_in_a_vacuum_test: $(CHTTP2_SOCKET_PAIR_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_CENSUS_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_CENSUS_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_CENSUS_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_census_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_census_simple_request_test: $(CHTTP2_SOCKET_PAIR_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_census_simple_request_test

endif


deps_chttp2_socket_pair_census_simple_request_test: $(CHTTP2_SOCKET_PAIR_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_DISAPPEARING_SERVER_TEST_SRC = \

CHTTP2_SOCKET_PAIR_DISAPPEARING_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_DISAPPEARING_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_disappearing_server_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_disappearing_server_test: $(CHTTP2_SOCKET_PAIR_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_disappearing_server_test

endif


deps_chttp2_socket_pair_disappearing_server_test: $(CHTTP2_SOCKET_PAIR_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test

endif


deps_chttp2_socket_pair_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_tags_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_tags_test: $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_early_server_shutdown_finishes_tags_test

endif


deps_chttp2_socket_pair_early_server_shutdown_finishes_tags_test: $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_INVOKE_LARGE_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_INVOKE_LARGE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_INVOKE_LARGE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_invoke_large_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_invoke_large_request_test: $(CHTTP2_SOCKET_PAIR_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_invoke_large_request_test

endif


deps_chttp2_socket_pair_invoke_large_request_test: $(CHTTP2_SOCKET_PAIR_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_MAX_CONCURRENT_STREAMS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_MAX_CONCURRENT_STREAMS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_MAX_CONCURRENT_STREAMS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_max_concurrent_streams_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_max_concurrent_streams_test: $(CHTTP2_SOCKET_PAIR_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_max_concurrent_streams_test

endif


deps_chttp2_socket_pair_max_concurrent_streams_test: $(CHTTP2_SOCKET_PAIR_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_NO_OP_TEST_SRC = \

CHTTP2_SOCKET_PAIR_NO_OP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_NO_OP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_no_op_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_no_op_test: $(CHTTP2_SOCKET_PAIR_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_no_op_test

endif


deps_chttp2_socket_pair_no_op_test: $(CHTTP2_SOCKET_PAIR_NO_OP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_NO_OP_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_PING_PONG_STREAMING_TEST_SRC = \

CHTTP2_SOCKET_PAIR_PING_PONG_STREAMING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_PING_PONG_STREAMING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_ping_pong_streaming_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_ping_pong_streaming_test: $(CHTTP2_SOCKET_PAIR_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_ping_pong_streaming_test

endif


deps_chttp2_socket_pair_ping_pong_streaming_test: $(CHTTP2_SOCKET_PAIR_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test

endif


deps_chttp2_socket_pair_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_request_response_with_metadata_and_payload_test

endif


deps_chttp2_socket_pair_request_response_with_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_request_response_with_payload_test

endif


deps_chttp2_socket_pair_request_response_with_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test

endif


deps_chttp2_socket_pair_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_SIMPLE_DELAYED_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_SIMPLE_DELAYED_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_SIMPLE_DELAYED_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_simple_delayed_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_simple_delayed_request_test: $(CHTTP2_SOCKET_PAIR_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_simple_delayed_request_test

endif


deps_chttp2_socket_pair_simple_delayed_request_test: $(CHTTP2_SOCKET_PAIR_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_simple_request_test: $(CHTTP2_SOCKET_PAIR_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_simple_request_test

endif


deps_chttp2_socket_pair_simple_request_test: $(CHTTP2_SOCKET_PAIR_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_THREAD_STRESS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_THREAD_STRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_THREAD_STRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_thread_stress_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_thread_stress_test: $(CHTTP2_SOCKET_PAIR_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_thread_stress_test

endif


deps_chttp2_socket_pair_thread_stress_test: $(CHTTP2_SOCKET_PAIR_THREAD_STRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_THREAD_STRESS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC = \

CHTTP2_SOCKET_PAIR_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_writes_done_hangs_with_pending_read_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_writes_done_hangs_with_pending_read_test: $(CHTTP2_SOCKET_PAIR_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_writes_done_hangs_with_pending_read_test

endif


deps_chttp2_socket_pair_writes_done_hangs_with_pending_read_test: $(CHTTP2_SOCKET_PAIR_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_after_accept.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_after_accept_and_writes_closed.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_cancel_after_accept_and_writes_closed_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_ACCEPT_AND_WRITES_CLOSED_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_INVOKE_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_after_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_cancel_after_invoke_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_AFTER_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_BEFORE_INVOKE_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_BEFORE_INVOKE_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_BEFORE_INVOKE_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_BEFORE_INVOKE_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_before_invoke.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_cancel_before_invoke_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_BEFORE_INVOKE_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_IN_A_VACUUM_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_IN_A_VACUUM_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_IN_A_VACUUM_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_IN_A_VACUUM_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_cancel_in_a_vacuum.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_cancel_in_a_vacuum_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CANCEL_IN_A_VACUUM_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CENSUS_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CENSUS_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CENSUS_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CENSUS_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_census_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_census_simple_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_CENSUS_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_DISAPPEARING_SERVER_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_DISAPPEARING_SERVER_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_DISAPPEARING_SERVER_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_DISAPPEARING_SERVER_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_disappearing_server.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_disappearing_server_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_DISAPPEARING_SERVER_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_inflight_calls.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_inflight_calls_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_INFLIGHT_CALLS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_early_server_shutdown_finishes_tags.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_early_server_shutdown_finishes_tags_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_EARLY_SERVER_SHUTDOWN_FINISHES_TAGS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_INVOKE_LARGE_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_INVOKE_LARGE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_INVOKE_LARGE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_INVOKE_LARGE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_invoke_large_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_invoke_large_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_INVOKE_LARGE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_MAX_CONCURRENT_STREAMS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_MAX_CONCURRENT_STREAMS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_MAX_CONCURRENT_STREAMS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_MAX_CONCURRENT_STREAMS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_max_concurrent_streams.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_max_concurrent_streams_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_MAX_CONCURRENT_STREAMS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_NO_OP_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_NO_OP_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_NO_OP_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_no_op_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_no_op_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_NO_OP_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_no_op.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_no_op_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_no_op_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_NO_OP_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_NO_OP_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_PING_PONG_STREAMING_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_PING_PONG_STREAMING_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_PING_PONG_STREAMING_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_PING_PONG_STREAMING_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_ping_pong_streaming.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_ping_pong_streaming_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_PING_PONG_STREAMING_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_binary_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_request_response_with_binary_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_BINARY_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_request_response_with_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_request_response_with_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_request_response_with_trailing_metadata_and_payload.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_request_response_with_trailing_metadata_and_payload_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_REQUEST_RESPONSE_WITH_TRAILING_METADATA_AND_PAYLOAD_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_DELAYED_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_DELAYED_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_DELAYED_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_DELAYED_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_simple_delayed_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_simple_delayed_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_DELAYED_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_REQUEST_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_REQUEST_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_REQUEST_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_request_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_REQUEST_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_simple_request.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_simple_request_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_simple_request_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_SIMPLE_REQUEST_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_THREAD_STRESS_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_THREAD_STRESS_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_THREAD_STRESS_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_thread_stress_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_thread_stress_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_THREAD_STRESS_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_thread_stress.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_thread_stress_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_thread_stress_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_THREAD_STRESS_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_THREAD_STRESS_TEST_OBJS:.o=.dep)
endif
endif


CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC = \

CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS = $(addprefix objs/$(CONFIG)/, $(addsuffix .o, $(basename $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_SRC))))

ifeq ($(NO_SECURE),true)

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test: openssl_dep_error

else

bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a
	$(E) "[LD]      Linking $@"
	$(Q) mkdir -p `dirname $@`
	$(Q) $(LD) $(LDFLAGS) $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS) libs/$(CONFIG)/libend2end_fixture_chttp2_socket_pair_one_byte_at_a_time.a libs/$(CONFIG)/libend2end_test_writes_done_hangs_with_pending_read.a libs/$(CONFIG)/libend2end_certs.a libs/$(CONFIG)/libgrpc_test_util.a libs/$(CONFIG)/libgrpc.a libs/$(CONFIG)/libgpr_test_util.a libs/$(CONFIG)/libgpr.a $(LDLIBS) $(LDLIBS_SECURE) -o bins/$(CONFIG)/chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test

endif


deps_chttp2_socket_pair_one_byte_at_a_time_writes_done_hangs_with_pending_read_test: $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)

ifneq ($(NO_SECURE),true)
ifneq ($(NO_DEPS),true)
-include $(CHTTP2_SOCKET_PAIR_ONE_BYTE_AT_A_TIME_WRITES_DONE_HANGS_WITH_PENDING_READ_TEST_OBJS:.o=.dep)
endif
endif






.PHONY: all strip tools dep_error openssl_dep_error openssl_dep_message git_update stop buildtests buildtests_c buildtests_cxx test test_c test_cxx install install_c install_cxx install-headers install-headers_c install-headers_cxx install-shared install-shared_c install-shared_cxx install-static install-static_c install-static_cxx strip strip-shared strip-static strip_c strip-shared_c strip-static_c strip_cxx strip-shared_cxx strip-static_cxx dep_c dep_cxx bins_dep_c bins_dep_cxx clean

