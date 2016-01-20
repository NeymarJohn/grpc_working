# -*- ruby -*-
# encoding: utf-8
$LOAD_PATH.push File.expand_path('../src/ruby/lib', __FILE__)
require 'grpc/version'

Gem::Specification.new do |s|
  s.name          = 'grpc'
  s.version       = GRPC::VERSION
  s.authors       = ['gRPC Authors']
  s.email         = 'temiola@google.com'
  s.homepage      = 'https://github.com/google/grpc/tree/master/src/ruby'
  s.summary       = 'GRPC system in Ruby'
  s.description   = 'Send RPCs from Ruby using GRPC'
  s.license       = 'BSD-3-Clause'

  s.required_ruby_version = '>= 2.0.0'
  s.requirements << 'libgrpc ~> 0.11.0 needs to be installed'

  s.files = %w( Rakefile Makefile )
  s.files += %w( etc/roots.pem )
  s.files += Dir.glob('src/ruby/bin/**/*')
  s.files += Dir.glob('src/ruby/ext/**/*')
  s.files += Dir.glob('src/ruby/lib/**/*')
  s.files += Dir.glob('src/ruby/pb/**/*')
  s.files += Dir.glob('include/grpc/**/*')
  s.test_files = Dir.glob('src/ruby/spec/**/*')
  s.bindir = 'src/ruby/bin'
  %w(math noproto).each do |b|
    s.executables += ["#{b}_client.rb", "#{b}_server.rb"]
  end
  s.executables += %w(grpc_ruby_interop_client grpc_ruby_interop_server)
  s.require_paths = %w( src/ruby/bin src/ruby/lib src/ruby/pb )
  s.platform      = Gem::Platform::RUBY

  s.add_dependency 'google-protobuf', '~> 3.0.0alpha.1.1'
  s.add_dependency 'googleauth', '~> 0.5.1'

  s.add_development_dependency 'bundler', '~> 1.9'
  s.add_development_dependency 'logging', '~> 2.0'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'rake-compiler', '~> 0.9'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rubocop', '~> 0.30.0'
  s.add_development_dependency 'signet', '~>0.7.0'

  s.extensions = %w(src/ruby/ext/grpc/extconf.rb)

  s.files += %w( include/grpc/support/alloc.h )
  s.files += %w( include/grpc/support/atm.h )
  s.files += %w( include/grpc/support/atm_gcc_atomic.h )
  s.files += %w( include/grpc/support/atm_gcc_sync.h )
  s.files += %w( include/grpc/support/atm_win32.h )
  s.files += %w( include/grpc/support/avl.h )
  s.files += %w( include/grpc/support/cmdline.h )
  s.files += %w( include/grpc/support/cpu.h )
  s.files += %w( include/grpc/support/histogram.h )
  s.files += %w( include/grpc/support/host_port.h )
  s.files += %w( include/grpc/support/log.h )
  s.files += %w( include/grpc/support/log_win32.h )
  s.files += %w( include/grpc/support/port_platform.h )
  s.files += %w( include/grpc/support/slice.h )
  s.files += %w( include/grpc/support/slice_buffer.h )
  s.files += %w( include/grpc/support/string_util.h )
  s.files += %w( include/grpc/support/subprocess.h )
  s.files += %w( include/grpc/support/sync.h )
  s.files += %w( include/grpc/support/sync_generic.h )
  s.files += %w( include/grpc/support/sync_posix.h )
  s.files += %w( include/grpc/support/sync_win32.h )
  s.files += %w( include/grpc/support/thd.h )
  s.files += %w( include/grpc/support/time.h )
  s.files += %w( include/grpc/support/tls.h )
  s.files += %w( include/grpc/support/tls_gcc.h )
  s.files += %w( include/grpc/support/tls_msvc.h )
  s.files += %w( include/grpc/support/tls_pthread.h )
  s.files += %w( include/grpc/support/useful.h )
  s.files += %w( src/core/profiling/timers.h )
  s.files += %w( src/core/support/block_annotate.h )
  s.files += %w( src/core/support/env.h )
  s.files += %w( src/core/support/file.h )
  s.files += %w( src/core/support/murmur_hash.h )
  s.files += %w( src/core/support/stack_lockfree.h )
  s.files += %w( src/core/support/string.h )
  s.files += %w( src/core/support/string_win32.h )
  s.files += %w( src/core/support/thd_internal.h )
  s.files += %w( src/core/support/time_precise.h )
  s.files += %w( src/core/profiling/basic_timers.c )
  s.files += %w( src/core/profiling/stap_timers.c )
  s.files += %w( src/core/support/alloc.c )
  s.files += %w( src/core/support/avl.c )
  s.files += %w( src/core/support/cmdline.c )
  s.files += %w( src/core/support/cpu_iphone.c )
  s.files += %w( src/core/support/cpu_linux.c )
  s.files += %w( src/core/support/cpu_posix.c )
  s.files += %w( src/core/support/cpu_windows.c )
  s.files += %w( src/core/support/env_linux.c )
  s.files += %w( src/core/support/env_posix.c )
  s.files += %w( src/core/support/env_win32.c )
  s.files += %w( src/core/support/file.c )
  s.files += %w( src/core/support/file_posix.c )
  s.files += %w( src/core/support/file_win32.c )
  s.files += %w( src/core/support/histogram.c )
  s.files += %w( src/core/support/host_port.c )
  s.files += %w( src/core/support/log.c )
  s.files += %w( src/core/support/log_android.c )
  s.files += %w( src/core/support/log_linux.c )
  s.files += %w( src/core/support/log_posix.c )
  s.files += %w( src/core/support/log_win32.c )
  s.files += %w( src/core/support/murmur_hash.c )
  s.files += %w( src/core/support/slice.c )
  s.files += %w( src/core/support/slice_buffer.c )
  s.files += %w( src/core/support/stack_lockfree.c )
  s.files += %w( src/core/support/string.c )
  s.files += %w( src/core/support/string_posix.c )
  s.files += %w( src/core/support/string_win32.c )
  s.files += %w( src/core/support/subprocess_posix.c )
  s.files += %w( src/core/support/sync.c )
  s.files += %w( src/core/support/sync_posix.c )
  s.files += %w( src/core/support/sync_win32.c )
  s.files += %w( src/core/support/thd.c )
  s.files += %w( src/core/support/thd_posix.c )
  s.files += %w( src/core/support/thd_win32.c )
  s.files += %w( src/core/support/time.c )
  s.files += %w( src/core/support/time_posix.c )
  s.files += %w( src/core/support/time_precise.c )
  s.files += %w( src/core/support/time_win32.c )
  s.files += %w( src/core/support/tls_pthread.c )
  s.files += %w( include/grpc/grpc_security.h )
  s.files += %w( include/grpc/byte_buffer.h )
  s.files += %w( include/grpc/byte_buffer_reader.h )
  s.files += %w( include/grpc/compression.h )
  s.files += %w( include/grpc/grpc.h )
  s.files += %w( include/grpc/status.h )
  s.files += %w( include/grpc/census.h )
  s.files += %w( src/core/security/auth_filters.h )
  s.files += %w( src/core/security/base64.h )
  s.files += %w( src/core/security/credentials.h )
  s.files += %w( src/core/security/handshake.h )
  s.files += %w( src/core/security/json_token.h )
  s.files += %w( src/core/security/jwt_verifier.h )
  s.files += %w( src/core/security/secure_endpoint.h )
  s.files += %w( src/core/security/security_connector.h )
  s.files += %w( src/core/security/security_context.h )
  s.files += %w( src/core/tsi/fake_transport_security.h )
  s.files += %w( src/core/tsi/ssl_transport_security.h )
  s.files += %w( src/core/tsi/ssl_types.h )
  s.files += %w( src/core/tsi/transport_security.h )
  s.files += %w( src/core/tsi/transport_security_interface.h )
  s.files += %w( src/core/census/grpc_filter.h )
  s.files += %w( src/core/channel/channel_args.h )
  s.files += %w( src/core/channel/channel_stack.h )
  s.files += %w( src/core/channel/client_channel.h )
  s.files += %w( src/core/channel/client_uchannel.h )
  s.files += %w( src/core/channel/compress_filter.h )
  s.files += %w( src/core/channel/connected_channel.h )
  s.files += %w( src/core/channel/context.h )
  s.files += %w( src/core/channel/http_client_filter.h )
  s.files += %w( src/core/channel/http_server_filter.h )
  s.files += %w( src/core/channel/subchannel_call_holder.h )
  s.files += %w( src/core/client_config/client_config.h )
  s.files += %w( src/core/client_config/connector.h )
  s.files += %w( src/core/client_config/initial_connect_string.h )
  s.files += %w( src/core/client_config/lb_policies/load_balancer_api.h )
  s.files += %w( src/core/client_config/lb_policies/pick_first.h )
  s.files += %w( src/core/client_config/lb_policies/round_robin.h )
  s.files += %w( src/core/client_config/lb_policy.h )
  s.files += %w( src/core/client_config/lb_policy_factory.h )
  s.files += %w( src/core/client_config/lb_policy_registry.h )
  s.files += %w( src/core/client_config/resolver.h )
  s.files += %w( src/core/client_config/resolver_factory.h )
  s.files += %w( src/core/client_config/resolver_registry.h )
  s.files += %w( src/core/client_config/resolvers/dns_resolver.h )
  s.files += %w( src/core/client_config/resolvers/sockaddr_resolver.h )
  s.files += %w( src/core/client_config/subchannel.h )
  s.files += %w( src/core/client_config/subchannel_factory.h )
  s.files += %w( src/core/client_config/uri_parser.h )
  s.files += %w( src/core/compression/algorithm_metadata.h )
  s.files += %w( src/core/compression/message_compress.h )
  s.files += %w( src/core/debug/trace.h )
  s.files += %w( src/core/httpcli/format_request.h )
  s.files += %w( src/core/httpcli/httpcli.h )
  s.files += %w( src/core/httpcli/parser.h )
  s.files += %w( src/core/iomgr/closure.h )
  s.files += %w( src/core/iomgr/endpoint.h )
  s.files += %w( src/core/iomgr/endpoint_pair.h )
  s.files += %w( src/core/iomgr/exec_ctx.h )
  s.files += %w( src/core/iomgr/executor.h )
  s.files += %w( src/core/iomgr/fd_posix.h )
  s.files += %w( src/core/iomgr/iocp_windows.h )
  s.files += %w( src/core/iomgr/iomgr.h )
  s.files += %w( src/core/iomgr/iomgr_internal.h )
  s.files += %w( src/core/iomgr/iomgr_posix.h )
  s.files += %w( src/core/iomgr/pollset.h )
  s.files += %w( src/core/iomgr/pollset_posix.h )
  s.files += %w( src/core/iomgr/pollset_set.h )
  s.files += %w( src/core/iomgr/pollset_set_posix.h )
  s.files += %w( src/core/iomgr/pollset_set_windows.h )
  s.files += %w( src/core/iomgr/pollset_windows.h )
  s.files += %w( src/core/iomgr/resolve_address.h )
  s.files += %w( src/core/iomgr/sockaddr.h )
  s.files += %w( src/core/iomgr/sockaddr_posix.h )
  s.files += %w( src/core/iomgr/sockaddr_utils.h )
  s.files += %w( src/core/iomgr/sockaddr_win32.h )
  s.files += %w( src/core/iomgr/socket_utils_posix.h )
  s.files += %w( src/core/iomgr/socket_windows.h )
  s.files += %w( src/core/iomgr/tcp_client.h )
  s.files += %w( src/core/iomgr/tcp_posix.h )
  s.files += %w( src/core/iomgr/tcp_server.h )
  s.files += %w( src/core/iomgr/tcp_windows.h )
  s.files += %w( src/core/iomgr/time_averaged_stats.h )
  s.files += %w( src/core/iomgr/timer.h )
  s.files += %w( src/core/iomgr/timer_heap.h )
  s.files += %w( src/core/iomgr/timer_internal.h )
  s.files += %w( src/core/iomgr/udp_server.h )
  s.files += %w( src/core/iomgr/wakeup_fd_pipe.h )
  s.files += %w( src/core/iomgr/wakeup_fd_posix.h )
  s.files += %w( src/core/iomgr/workqueue.h )
  s.files += %w( src/core/iomgr/workqueue_posix.h )
  s.files += %w( src/core/iomgr/workqueue_windows.h )
  s.files += %w( src/core/json/json.h )
  s.files += %w( src/core/json/json_common.h )
  s.files += %w( src/core/json/json_reader.h )
  s.files += %w( src/core/json/json_writer.h )
  s.files += %w( src/core/proto/grpc/lb/v0/load_balancer.pb.h )
  s.files += %w( src/core/statistics/census_interface.h )
  s.files += %w( src/core/statistics/census_rpc_stats.h )
  s.files += %w( src/core/surface/api_trace.h )
  s.files += %w( src/core/surface/call.h )
  s.files += %w( src/core/surface/call_test_only.h )
  s.files += %w( src/core/surface/channel.h )
  s.files += %w( src/core/surface/completion_queue.h )
  s.files += %w( src/core/surface/event_string.h )
  s.files += %w( src/core/surface/init.h )
  s.files += %w( src/core/surface/server.h )
  s.files += %w( src/core/surface/surface_trace.h )
  s.files += %w( src/core/transport/byte_stream.h )
  s.files += %w( src/core/transport/chttp2/alpn.h )
  s.files += %w( src/core/transport/chttp2/bin_encoder.h )
  s.files += %w( src/core/transport/chttp2/frame.h )
  s.files += %w( src/core/transport/chttp2/frame_data.h )
  s.files += %w( src/core/transport/chttp2/frame_goaway.h )
  s.files += %w( src/core/transport/chttp2/frame_ping.h )
  s.files += %w( src/core/transport/chttp2/frame_rst_stream.h )
  s.files += %w( src/core/transport/chttp2/frame_settings.h )
  s.files += %w( src/core/transport/chttp2/frame_window_update.h )
  s.files += %w( src/core/transport/chttp2/hpack_encoder.h )
  s.files += %w( src/core/transport/chttp2/hpack_parser.h )
  s.files += %w( src/core/transport/chttp2/hpack_table.h )
  s.files += %w( src/core/transport/chttp2/http2_errors.h )
  s.files += %w( src/core/transport/chttp2/huffsyms.h )
  s.files += %w( src/core/transport/chttp2/incoming_metadata.h )
  s.files += %w( src/core/transport/chttp2/internal.h )
  s.files += %w( src/core/transport/chttp2/status_conversion.h )
  s.files += %w( src/core/transport/chttp2/stream_map.h )
  s.files += %w( src/core/transport/chttp2/timeout_encoding.h )
  s.files += %w( src/core/transport/chttp2/varint.h )
  s.files += %w( src/core/transport/chttp2_transport.h )
  s.files += %w( src/core/transport/connectivity_state.h )
  s.files += %w( src/core/transport/metadata.h )
  s.files += %w( src/core/transport/metadata_batch.h )
  s.files += %w( src/core/transport/static_metadata.h )
  s.files += %w( src/core/transport/transport.h )
  s.files += %w( src/core/transport/transport_impl.h )
  s.files += %w( src/core/census/aggregation.h )
  s.files += %w( src/core/census/context.h )
  s.files += %w( src/core/census/rpc_metric_id.h )
  s.files += %w( third_party/nanopb/pb.h )
  s.files += %w( third_party/nanopb/pb_common.h )
  s.files += %w( third_party/nanopb/pb_decode.h )
  s.files += %w( third_party/nanopb/pb_encode.h )
  s.files += %w( src/core/httpcli/httpcli_security_connector.c )
  s.files += %w( src/core/security/base64.c )
  s.files += %w( src/core/security/client_auth_filter.c )
  s.files += %w( src/core/security/credentials.c )
  s.files += %w( src/core/security/credentials_metadata.c )
  s.files += %w( src/core/security/credentials_posix.c )
  s.files += %w( src/core/security/credentials_win32.c )
  s.files += %w( src/core/security/google_default_credentials.c )
  s.files += %w( src/core/security/handshake.c )
  s.files += %w( src/core/security/json_token.c )
  s.files += %w( src/core/security/jwt_verifier.c )
  s.files += %w( src/core/security/secure_endpoint.c )
  s.files += %w( src/core/security/security_connector.c )
  s.files += %w( src/core/security/security_context.c )
  s.files += %w( src/core/security/server_auth_filter.c )
  s.files += %w( src/core/security/server_secure_chttp2.c )
  s.files += %w( src/core/surface/init_secure.c )
  s.files += %w( src/core/surface/secure_channel_create.c )
  s.files += %w( src/core/tsi/fake_transport_security.c )
  s.files += %w( src/core/tsi/ssl_transport_security.c )
  s.files += %w( src/core/tsi/transport_security.c )
  s.files += %w( src/core/census/grpc_context.c )
  s.files += %w( src/core/census/grpc_filter.c )
  s.files += %w( src/core/channel/channel_args.c )
  s.files += %w( src/core/channel/channel_stack.c )
  s.files += %w( src/core/channel/client_channel.c )
  s.files += %w( src/core/channel/client_uchannel.c )
  s.files += %w( src/core/channel/compress_filter.c )
  s.files += %w( src/core/channel/connected_channel.c )
  s.files += %w( src/core/channel/http_client_filter.c )
  s.files += %w( src/core/channel/http_server_filter.c )
  s.files += %w( src/core/channel/subchannel_call_holder.c )
  s.files += %w( src/core/client_config/client_config.c )
  s.files += %w( src/core/client_config/connector.c )
  s.files += %w( src/core/client_config/default_initial_connect_string.c )
  s.files += %w( src/core/client_config/initial_connect_string.c )
  s.files += %w( src/core/client_config/lb_policies/load_balancer_api.c )
  s.files += %w( src/core/client_config/lb_policies/pick_first.c )
  s.files += %w( src/core/client_config/lb_policies/round_robin.c )
  s.files += %w( src/core/client_config/lb_policy.c )
  s.files += %w( src/core/client_config/lb_policy_factory.c )
  s.files += %w( src/core/client_config/lb_policy_registry.c )
  s.files += %w( src/core/client_config/resolver.c )
  s.files += %w( src/core/client_config/resolver_factory.c )
  s.files += %w( src/core/client_config/resolver_registry.c )
  s.files += %w( src/core/client_config/resolvers/dns_resolver.c )
  s.files += %w( src/core/client_config/resolvers/sockaddr_resolver.c )
  s.files += %w( src/core/client_config/subchannel.c )
  s.files += %w( src/core/client_config/subchannel_factory.c )
  s.files += %w( src/core/client_config/uri_parser.c )
  s.files += %w( src/core/compression/algorithm.c )
  s.files += %w( src/core/compression/message_compress.c )
  s.files += %w( src/core/debug/trace.c )
  s.files += %w( src/core/httpcli/format_request.c )
  s.files += %w( src/core/httpcli/httpcli.c )
  s.files += %w( src/core/httpcli/parser.c )
  s.files += %w( src/core/iomgr/closure.c )
  s.files += %w( src/core/iomgr/endpoint.c )
  s.files += %w( src/core/iomgr/endpoint_pair_posix.c )
  s.files += %w( src/core/iomgr/endpoint_pair_windows.c )
  s.files += %w( src/core/iomgr/exec_ctx.c )
  s.files += %w( src/core/iomgr/executor.c )
  s.files += %w( src/core/iomgr/fd_posix.c )
  s.files += %w( src/core/iomgr/iocp_windows.c )
  s.files += %w( src/core/iomgr/iomgr.c )
  s.files += %w( src/core/iomgr/iomgr_posix.c )
  s.files += %w( src/core/iomgr/iomgr_windows.c )
  s.files += %w( src/core/iomgr/pollset_multipoller_with_epoll.c )
  s.files += %w( src/core/iomgr/pollset_multipoller_with_poll_posix.c )
  s.files += %w( src/core/iomgr/pollset_posix.c )
  s.files += %w( src/core/iomgr/pollset_set_posix.c )
  s.files += %w( src/core/iomgr/pollset_set_windows.c )
  s.files += %w( src/core/iomgr/pollset_windows.c )
  s.files += %w( src/core/iomgr/resolve_address_posix.c )
  s.files += %w( src/core/iomgr/resolve_address_windows.c )
  s.files += %w( src/core/iomgr/sockaddr_utils.c )
  s.files += %w( src/core/iomgr/socket_utils_common_posix.c )
  s.files += %w( src/core/iomgr/socket_utils_linux.c )
  s.files += %w( src/core/iomgr/socket_utils_posix.c )
  s.files += %w( src/core/iomgr/socket_windows.c )
  s.files += %w( src/core/iomgr/tcp_client_posix.c )
  s.files += %w( src/core/iomgr/tcp_client_windows.c )
  s.files += %w( src/core/iomgr/tcp_posix.c )
  s.files += %w( src/core/iomgr/tcp_server_posix.c )
  s.files += %w( src/core/iomgr/tcp_server_windows.c )
  s.files += %w( src/core/iomgr/tcp_windows.c )
  s.files += %w( src/core/iomgr/time_averaged_stats.c )
  s.files += %w( src/core/iomgr/timer.c )
  s.files += %w( src/core/iomgr/timer_heap.c )
  s.files += %w( src/core/iomgr/udp_server.c )
  s.files += %w( src/core/iomgr/wakeup_fd_eventfd.c )
  s.files += %w( src/core/iomgr/wakeup_fd_nospecial.c )
  s.files += %w( src/core/iomgr/wakeup_fd_pipe.c )
  s.files += %w( src/core/iomgr/wakeup_fd_posix.c )
  s.files += %w( src/core/iomgr/workqueue_posix.c )
  s.files += %w( src/core/iomgr/workqueue_windows.c )
  s.files += %w( src/core/json/json.c )
  s.files += %w( src/core/json/json_reader.c )
  s.files += %w( src/core/json/json_string.c )
  s.files += %w( src/core/json/json_writer.c )
  s.files += %w( src/core/proto/grpc/lb/v0/load_balancer.pb.c )
  s.files += %w( src/core/surface/api_trace.c )
  s.files += %w( src/core/surface/byte_buffer.c )
  s.files += %w( src/core/surface/byte_buffer_reader.c )
  s.files += %w( src/core/surface/call.c )
  s.files += %w( src/core/surface/call_details.c )
  s.files += %w( src/core/surface/call_log_batch.c )
  s.files += %w( src/core/surface/channel.c )
  s.files += %w( src/core/surface/channel_connectivity.c )
  s.files += %w( src/core/surface/channel_create.c )
  s.files += %w( src/core/surface/channel_ping.c )
  s.files += %w( src/core/surface/completion_queue.c )
  s.files += %w( src/core/surface/event_string.c )
  s.files += %w( src/core/surface/init.c )
  s.files += %w( src/core/surface/lame_client.c )
  s.files += %w( src/core/surface/metadata_array.c )
  s.files += %w( src/core/surface/server.c )
  s.files += %w( src/core/surface/server_chttp2.c )
  s.files += %w( src/core/surface/server_create.c )
  s.files += %w( src/core/surface/validate_metadata.c )
  s.files += %w( src/core/surface/version.c )
  s.files += %w( src/core/transport/byte_stream.c )
  s.files += %w( src/core/transport/chttp2/alpn.c )
  s.files += %w( src/core/transport/chttp2/bin_encoder.c )
  s.files += %w( src/core/transport/chttp2/frame_data.c )
  s.files += %w( src/core/transport/chttp2/frame_goaway.c )
  s.files += %w( src/core/transport/chttp2/frame_ping.c )
  s.files += %w( src/core/transport/chttp2/frame_rst_stream.c )
  s.files += %w( src/core/transport/chttp2/frame_settings.c )
  s.files += %w( src/core/transport/chttp2/frame_window_update.c )
  s.files += %w( src/core/transport/chttp2/hpack_encoder.c )
  s.files += %w( src/core/transport/chttp2/hpack_parser.c )
  s.files += %w( src/core/transport/chttp2/hpack_table.c )
  s.files += %w( src/core/transport/chttp2/huffsyms.c )
  s.files += %w( src/core/transport/chttp2/incoming_metadata.c )
  s.files += %w( src/core/transport/chttp2/parsing.c )
  s.files += %w( src/core/transport/chttp2/status_conversion.c )
  s.files += %w( src/core/transport/chttp2/stream_lists.c )
  s.files += %w( src/core/transport/chttp2/stream_map.c )
  s.files += %w( src/core/transport/chttp2/timeout_encoding.c )
  s.files += %w( src/core/transport/chttp2/varint.c )
  s.files += %w( src/core/transport/chttp2/writing.c )
  s.files += %w( src/core/transport/chttp2_transport.c )
  s.files += %w( src/core/transport/connectivity_state.c )
  s.files += %w( src/core/transport/metadata.c )
  s.files += %w( src/core/transport/metadata_batch.c )
  s.files += %w( src/core/transport/static_metadata.c )
  s.files += %w( src/core/transport/transport.c )
  s.files += %w( src/core/transport/transport_op_string.c )
  s.files += %w( src/core/census/context.c )
  s.files += %w( src/core/census/initialize.c )
  s.files += %w( src/core/census/operation.c )
  s.files += %w( src/core/census/tracing.c )
  s.files += %w( third_party/nanopb/pb_common.c )
  s.files += %w( third_party/nanopb/pb_decode.c )
  s.files += %w( third_party/nanopb/pb_encode.c )
end
