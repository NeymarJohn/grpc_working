# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: test/cpp/interop/test.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
from google.protobuf import descriptor_pb2
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()


from test.cpp.interop import empty_pb2 as test_dot_cpp_dot_interop_dot_empty__pb2
from test.cpp.interop import messages_pb2 as test_dot_cpp_dot_interop_dot_messages__pb2


DESCRIPTOR = _descriptor.FileDescriptor(
  name='test/cpp/interop/test.proto',
  package='grpc.testing',
  serialized_pb=_b('\n\x1btest/cpp/interop/test.proto\x12\x0cgrpc.testing\x1a\x1ctest/cpp/interop/empty.proto\x1a\x1ftest/cpp/interop/messages.proto2\xbb\x04\n\x0bTestService\x12\x35\n\tEmptyCall\x12\x13.grpc.testing.Empty\x1a\x13.grpc.testing.Empty\x12\x46\n\tUnaryCall\x12\x1b.grpc.testing.SimpleRequest\x1a\x1c.grpc.testing.SimpleResponse\x12l\n\x13StreamingOutputCall\x12(.grpc.testing.StreamingOutputCallRequest\x1a).grpc.testing.StreamingOutputCallResponse0\x01\x12i\n\x12StreamingInputCall\x12\'.grpc.testing.StreamingInputCallRequest\x1a(.grpc.testing.StreamingInputCallResponse(\x01\x12i\n\x0e\x46ullDuplexCall\x12(.grpc.testing.StreamingOutputCallRequest\x1a).grpc.testing.StreamingOutputCallResponse(\x01\x30\x01\x12i\n\x0eHalfDuplexCall\x12(.grpc.testing.StreamingOutputCallRequest\x1a).grpc.testing.StreamingOutputCallResponse(\x01\x30\x01')
  ,
  dependencies=[test_dot_cpp_dot_interop_dot_empty__pb2.DESCRIPTOR,test_dot_cpp_dot_interop_dot_messages__pb2.DESCRIPTOR,])
_sym_db.RegisterFileDescriptor(DESCRIPTOR)





from grpc.framework.face import demonstration as _face_testing
from grpc.framework.face import interfaces as _face_interfaces
class TestServiceService(object):
  """<fill me in later!>"""
  def __init__(self):
    pass
class TestServiceServicer(object):
  """<fill me in later!>"""
  def EmptyCall(self, arg):
    raise NotImplementedError()
  def UnaryCall(self, arg):
    raise NotImplementedError()
  def StreamingOutputCall(self, arg):
    raise NotImplementedError()
  def StreamingInputCall(self, arg):
    raise NotImplementedError()
  def FullDuplexCall(self, arg):
    raise NotImplementedError()
  def HalfDuplexCall(self, arg):
    raise NotImplementedError()
class TestServiceStub(object):
  """<fill me in later!>"""
  def EmptyCall(self, arg):
    raise NotImplementedError()
  EmptyCall.async = None
  def UnaryCall(self, arg):
    raise NotImplementedError()
  UnaryCall.async = None
  def StreamingOutputCall(self, arg):
    raise NotImplementedError()
  StreamingOutputCall.async = None
  def StreamingInputCall(self, arg):
    raise NotImplementedError()
  StreamingInputCall.async = None
  def FullDuplexCall(self, arg):
    raise NotImplementedError()
  FullDuplexCall.async = None
  def HalfDuplexCall(self, arg):
    raise NotImplementedError()
  HalfDuplexCall.async = None
class _TestServiceStub(TestServiceStub):
  def __init__(self, face_stub, default_timeout):
    self._face_stub = face_stub
    self._default_timeout = default_timeout
    stub_self = self
    class EmptyCall(object):
      def __call__(self, arg):
        return stub_self._face_stub.blocking_value_in_value_out("EmptyCall", arg, stub_self._default_timeout)
      def async(self, arg):
        return stub_self._face_stub.future_value_in_value_out("EmptyCall", arg, stub_self._default_timeout)
    self.EmptyCall = EmptyCall()
    class UnaryCall(object):
      def __call__(self, arg):
        return stub_self._face_stub.blocking_value_in_value_out("UnaryCall", arg, stub_self._default_timeout)
      def async(self, arg):
        return stub_self._face_stub.future_value_in_value_out("UnaryCall", arg, stub_self._default_timeout)
    self.UnaryCall = UnaryCall()
    class StreamingOutputCall(object):
      def __call__(self, arg):
        return stub_self._face_stub.inline_value_in_stream_out("StreamingOutputCall", arg, stub_self._default_timeout)
      def async(self, arg):
        return stub_self._face_stub.inline_value_in_stream_out("StreamingOutputCall", arg, stub_self._default_timeout)
    self.StreamingOutputCall = StreamingOutputCall()
    class StreamingInputCall(object):
      def __call__(self, arg):
        return stub_self._face_stub.blocking_stream_in_value_out("StreamingInputCall", arg, stub_self._default_timeout)
      def async(self, arg):
        return stub_self._face_stub.future_stream_in_value_out("StreamingInputCall", arg, stub_self._default_timeout)
    self.StreamingInputCall = StreamingInputCall()
    class FullDuplexCall(object):
      def __call__(self, arg):
        return stub_self._face_stub.inline_stream_in_stream_out("FullDuplexCall", arg, stub_self._default_timeout)
      def async(self, arg):
        return stub_self._face_stub.inline_stream_in_stream_out("FullDuplexCall", arg, stub_self._default_timeout)
    self.FullDuplexCall = FullDuplexCall()
    class HalfDuplexCall(object):
      def __call__(self, arg):
        return stub_self._face_stub.inline_stream_in_stream_out("HalfDuplexCall", arg, stub_self._default_timeout)
      def async(self, arg):
        return stub_self._face_stub.inline_stream_in_stream_out("HalfDuplexCall", arg, stub_self._default_timeout)
    self.HalfDuplexCall = HalfDuplexCall()
def mock_TestService(servicer, default_timeout):
  value_in_value_out = {}
  value_in_stream_out = {}
  stream_in_value_out = {}
  stream_in_stream_out = {}
  class EmptyCall(_face_interfaces.InlineValueInValueOutMethod):
    def service(self, request, context):
      return servicer.EmptyCall(request)
  value_in_value_out['EmptyCall'] = EmptyCall()
  class UnaryCall(_face_interfaces.InlineValueInValueOutMethod):
    def service(self, request, context):
      return servicer.UnaryCall(request)
  value_in_value_out['UnaryCall'] = UnaryCall()
  class StreamingOutputCall(_face_interfaces.InlineValueInStreamOutMethod):
    def service(self, request, context):
      return servicer.StreamingOutputCall(request)
  value_in_stream_out['StreamingOutputCall'] = StreamingOutputCall()
  class StreamingInputCall(_face_interfaces.InlineStreamInValueOutMethod):
    def service(self, request, context):
      return servicer.StreamingInputCall(request)
  stream_in_value_out['StreamingInputCall'] = StreamingInputCall()
  class FullDuplexCall(_face_interfaces.InlineStreamInStreamOutMethod):
    def service(self, request, context):
      return servicer.FullDuplexCall(request)
  stream_in_stream_out['FullDuplexCall'] = FullDuplexCall()
  class HalfDuplexCall(_face_interfaces.InlineStreamInStreamOutMethod):
    def service(self, request, context):
      return servicer.HalfDuplexCall(request)
  stream_in_stream_out['HalfDuplexCall'] = HalfDuplexCall()
  face_linked_pair = _face_testing.server_and_stub(default_timeout,inline_value_in_value_out_methods=value_in_value_out,inline_value_in_stream_out_methods=value_in_stream_out,inline_stream_in_value_out_methods=stream_in_value_out,inline_stream_in_stream_out_methods=stream_in_stream_out)
  class LinkedPair(object):
    def __init__(self, server, stub):
      self.server = server
      self.stub = stub
  stub = _TestServiceStub(face_linked_pair.stub, default_timeout)
  return LinkedPair(None, stub)
# @@protoc_insertion_point(module_scope)
