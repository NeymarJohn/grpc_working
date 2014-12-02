# Copyright 2014, Google Inc.
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

require 'grpc'
require 'port_picker'

include GRPC::StatusCodes

describe GRPC::RpcErrors do

  before(:each) do
    @known_types = {
      :OK => 0,
      :ERROR => 1,
      :NOT_ON_SERVER => 2,
      :NOT_ON_CLIENT => 3,
      :ALREADY_INVOKED => 4,
      :NOT_INVOKED => 5,
      :ALREADY_FINISHED => 6,
      :TOO_MANY_OPERATIONS => 7,
      :INVALID_FLAGS => 8,
      :ErrorMessages => {
        0=>'ok',
        1=>'unknown error',
        2=>'not available on a server',
        3=>'not available on a client',
        4=>'call is already invoked',
        5=>'call is not yet invoked',
        6=>'call is already finished',
        7=>'outstanding read or write present',
        8=>'a bad flag was given',
      }
    }
  end

  it 'should have symbols for all the known error codes' do
    m = GRPC::RpcErrors
    syms_and_codes = m.constants.collect { |c| [c, m.const_get(c)] }
    expect(Hash[syms_and_codes]).to eq(@known_types)
  end

end

describe GRPC::Call do

  before(:each) do
    @tag = Object.new
    @client_queue = GRPC::CompletionQueue.new
    @server_queue = GRPC::CompletionQueue.new
    port = find_unused_tcp_port
    host = "localhost:#{port}"
    @server = GRPC::Server.new(@server_queue, nil)
    @server.add_http2_port(host)
    @ch = GRPC::Channel.new(host, nil)
  end

  after(:each) do
    @server.close
  end

  describe '#start_read' do
    it 'should fail if called immediately' do
      expect { make_test_call.start_read(@tag) }.to raise_error GRPC::CallError
    end
  end

  describe '#start_write' do
    it 'should fail if called immediately' do
      bytes = GRPC::ByteBuffer.new('test string')
      expect { make_test_call.start_write(bytes, @tag) }
          .to raise_error GRPC::CallError
    end
  end

  describe '#start_write_status' do
    it 'should fail if called immediately' do
      sts = GRPC::Status.new(153, 'test detail')
      expect { make_test_call.start_write_status(sts, @tag) }
          .to raise_error GRPC::CallError
    end
  end

  describe '#writes_done' do
    it 'should fail if called immediately' do
      expect { make_test_call.writes_done(@tag) }.to raise_error GRPC::CallError
    end
  end

  describe '#add_metadata' do
    it 'adds metadata to a call without fail' do
      call = make_test_call
      n = 37
      metadata = Hash[n.times.collect { |i| ["key%d" % i, "value%d" %i] } ]
      expect { call.add_metadata(metadata) }.to_not raise_error
    end
  end

  describe '#start_invoke' do
    it 'should cause the INVOKE_ACCEPTED event' do
      call = make_test_call
      expect(call.start_invoke(@client_queue, @tag, @tag, @tag)).to be_nil
      ev = @client_queue.next(deadline)
      expect(ev.call).to be_a(GRPC::Call)
      expect(ev.tag).to be(@tag)
      expect(ev.type).to be(GRPC::CompletionType::INVOKE_ACCEPTED)
      expect(ev.call).to_not be(call)
    end
  end

  describe '#start_write' do
    it 'should cause the WRITE_ACCEPTED event' do
      call = make_test_call
      call.start_invoke(@client_queue, @tag, @tag, @tag)
      ev = @client_queue.next(deadline)
      expect(ev.type).to be(GRPC::CompletionType::INVOKE_ACCEPTED)
      expect(call.start_write(GRPC::ByteBuffer.new('test_start_write'),
                              @tag)).to be_nil
      ev = @client_queue.next(deadline)
      expect(ev.call).to be_a(GRPC::Call)
      expect(ev.type).to be(GRPC::CompletionType::WRITE_ACCEPTED)
      expect(ev.tag).to be(@tag)
    end
  end

  describe '#status' do
    it 'can save the status and read it back' do
      call = make_test_call
      sts = GRPC::Status.new(OK, 'OK')
      expect { call.status = sts }.not_to raise_error
      expect(call.status).to be(sts)
    end

    it 'must be set to a status' do
      call = make_test_call
      bad_sts = Object.new
      expect { call.status = bad_sts }.to raise_error(TypeError)
    end

    it 'can be set to nil' do
      call = make_test_call
      expect { call.status = nil }.not_to raise_error
    end
  end

  describe '#metadata' do
    it 'can save the metadata hash and read it back' do
      call = make_test_call
      md = {'k1' => 'v1',  'k2' => 'v2'}
      expect { call.metadata = md }.not_to raise_error
      expect(call.metadata).to be(md)
    end

    it 'must be set with a hash' do
      call = make_test_call
      bad_md = Object.new
      expect { call.metadata = bad_md }.to raise_error(TypeError)
    end

    it 'can be set to nil' do
      call = make_test_call
      expect { call.metadata = nil }.not_to raise_error
    end
  end


  def make_test_call
    @ch.create_call('dummy_method', 'dummy_host', deadline)
  end

  def deadline
    Time.now + 2  # in 2 seconds; arbitrary
  end

end
