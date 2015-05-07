// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: test.proto
#region Designer generated code

using System;
using System.Threading;
using System.Threading.Tasks;
using Grpc.Core;

namespace grpc.testing {
  public static class TestService
  {
    static readonly string __ServiceName = "grpc.testing.TestService";

    static readonly Marshaller<Empty> __Marshaller_Empty = Marshallers.Create((arg) => arg.ToByteArray(), Empty.ParseFrom);
    static readonly Marshaller<SimpleRequest> __Marshaller_SimpleRequest = Marshallers.Create((arg) => arg.ToByteArray(), SimpleRequest.ParseFrom);
    static readonly Marshaller<SimpleResponse> __Marshaller_SimpleResponse = Marshallers.Create((arg) => arg.ToByteArray(), SimpleResponse.ParseFrom);
    static readonly Marshaller<StreamingOutputCallRequest> __Marshaller_StreamingOutputCallRequest = Marshallers.Create((arg) => arg.ToByteArray(), StreamingOutputCallRequest.ParseFrom);
    static readonly Marshaller<StreamingOutputCallResponse> __Marshaller_StreamingOutputCallResponse = Marshallers.Create((arg) => arg.ToByteArray(), StreamingOutputCallResponse.ParseFrom);
    static readonly Marshaller<StreamingInputCallRequest> __Marshaller_StreamingInputCallRequest = Marshallers.Create((arg) => arg.ToByteArray(), StreamingInputCallRequest.ParseFrom);
    static readonly Marshaller<StreamingInputCallResponse> __Marshaller_StreamingInputCallResponse = Marshallers.Create((arg) => arg.ToByteArray(), StreamingInputCallResponse.ParseFrom);

    static readonly Method<Empty, Empty> __Method_EmptyCall = new Method<Empty, Empty>(
        MethodType.Unary,
        "EmptyCall",
        __Marshaller_Empty,
        __Marshaller_Empty);

    static readonly Method<SimpleRequest, SimpleResponse> __Method_UnaryCall = new Method<SimpleRequest, SimpleResponse>(
        MethodType.Unary,
        "UnaryCall",
        __Marshaller_SimpleRequest,
        __Marshaller_SimpleResponse);

    static readonly Method<StreamingOutputCallRequest, StreamingOutputCallResponse> __Method_StreamingOutputCall = new Method<StreamingOutputCallRequest, StreamingOutputCallResponse>(
        MethodType.ServerStreaming,
        "StreamingOutputCall",
        __Marshaller_StreamingOutputCallRequest,
        __Marshaller_StreamingOutputCallResponse);

    static readonly Method<StreamingInputCallRequest, StreamingInputCallResponse> __Method_StreamingInputCall = new Method<StreamingInputCallRequest, StreamingInputCallResponse>(
        MethodType.ClientStreaming,
        "StreamingInputCall",
        __Marshaller_StreamingInputCallRequest,
        __Marshaller_StreamingInputCallResponse);

    static readonly Method<StreamingOutputCallRequest, StreamingOutputCallResponse> __Method_FullDuplexCall = new Method<StreamingOutputCallRequest, StreamingOutputCallResponse>(
        MethodType.DuplexStreaming,
        "FullDuplexCall",
        __Marshaller_StreamingOutputCallRequest,
        __Marshaller_StreamingOutputCallResponse);

    static readonly Method<StreamingOutputCallRequest, StreamingOutputCallResponse> __Method_HalfDuplexCall = new Method<StreamingOutputCallRequest, StreamingOutputCallResponse>(
        MethodType.DuplexStreaming,
        "HalfDuplexCall",
        __Marshaller_StreamingOutputCallRequest,
        __Marshaller_StreamingOutputCallResponse);

    // client-side stub interface
    public interface ITestServiceClient
    {
      Empty EmptyCall(Empty request, CancellationToken token = default(CancellationToken));
      Task<Empty> EmptyCallAsync(Empty request, CancellationToken token = default(CancellationToken));
      SimpleResponse UnaryCall(SimpleRequest request, CancellationToken token = default(CancellationToken));
      Task<SimpleResponse> UnaryCallAsync(SimpleRequest request, CancellationToken token = default(CancellationToken));
      AsyncServerStreamingCall<StreamingOutputCallResponse> StreamingOutputCall(StreamingOutputCallRequest request, CancellationToken token = default(CancellationToken));
      AsyncClientStreamingCall<StreamingInputCallRequest, StreamingInputCallResponse> StreamingInputCall(CancellationToken token = default(CancellationToken));
      AsyncDuplexStreamingCall<StreamingOutputCallRequest, StreamingOutputCallResponse> FullDuplexCall(CancellationToken token = default(CancellationToken));
      AsyncDuplexStreamingCall<StreamingOutputCallRequest, StreamingOutputCallResponse> HalfDuplexCall(CancellationToken token = default(CancellationToken));
    }

    // server-side interface
    public interface ITestService
    {
      Task<Empty> EmptyCall(ServerCallContext context, Empty request);
      Task<SimpleResponse> UnaryCall(ServerCallContext context, SimpleRequest request);
      Task StreamingOutputCall(ServerCallContext context, StreamingOutputCallRequest request, IServerStreamWriter<StreamingOutputCallResponse> responseStream);
      Task<StreamingInputCallResponse> StreamingInputCall(ServerCallContext context, IAsyncStreamReader<StreamingInputCallRequest> requestStream);
      Task FullDuplexCall(ServerCallContext context, IAsyncStreamReader<StreamingOutputCallRequest> requestStream, IServerStreamWriter<StreamingOutputCallResponse> responseStream);
      Task HalfDuplexCall(ServerCallContext context, IAsyncStreamReader<StreamingOutputCallRequest> requestStream, IServerStreamWriter<StreamingOutputCallResponse> responseStream);
    }

    // client stub
    public class TestServiceClient : AbstractStub<TestServiceClient, StubConfiguration>, ITestServiceClient
    {
      public TestServiceClient(Channel channel) : this(channel, StubConfiguration.Default)
      {
      }
      public TestServiceClient(Channel channel, StubConfiguration config) : base(channel, config)
      {
      }
      public Empty EmptyCall(Empty request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_EmptyCall);
        return Calls.BlockingUnaryCall(call, request, token);
      }
      public Task<Empty> EmptyCallAsync(Empty request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_EmptyCall);
        return Calls.AsyncUnaryCall(call, request, token);
      }
      public SimpleResponse UnaryCall(SimpleRequest request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_UnaryCall);
        return Calls.BlockingUnaryCall(call, request, token);
      }
      public Task<SimpleResponse> UnaryCallAsync(SimpleRequest request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_UnaryCall);
        return Calls.AsyncUnaryCall(call, request, token);
      }
      public AsyncServerStreamingCall<StreamingOutputCallResponse> StreamingOutputCall(StreamingOutputCallRequest request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_StreamingOutputCall);
        return Calls.AsyncServerStreamingCall(call, request, token);
      }
      public AsyncClientStreamingCall<StreamingInputCallRequest, StreamingInputCallResponse> StreamingInputCall(CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_StreamingInputCall);
        return Calls.AsyncClientStreamingCall(call, token);
      }
      public AsyncDuplexStreamingCall<StreamingOutputCallRequest, StreamingOutputCallResponse> FullDuplexCall(CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_FullDuplexCall);
        return Calls.AsyncDuplexStreamingCall(call, token);
      }
      public AsyncDuplexStreamingCall<StreamingOutputCallRequest, StreamingOutputCallResponse> HalfDuplexCall(CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_HalfDuplexCall);
        return Calls.AsyncDuplexStreamingCall(call, token);
      }
    }

    // creates service definition that can be registered with a server
    public static ServerServiceDefinition BindService(ITestService serviceImpl)
    {
      return ServerServiceDefinition.CreateBuilder(__ServiceName)
          .AddMethod(__Method_EmptyCall, serviceImpl.EmptyCall)
          .AddMethod(__Method_UnaryCall, serviceImpl.UnaryCall)
          .AddMethod(__Method_StreamingOutputCall, serviceImpl.StreamingOutputCall)
          .AddMethod(__Method_StreamingInputCall, serviceImpl.StreamingInputCall)
          .AddMethod(__Method_FullDuplexCall, serviceImpl.FullDuplexCall)
          .AddMethod(__Method_HalfDuplexCall, serviceImpl.HalfDuplexCall).Build();
    }

    // creates a new client stub
    public static ITestServiceClient NewStub(Channel channel)
    {
      return new TestServiceClient(channel);
    }

    // creates a new client stub
    public static ITestServiceClient NewStub(Channel channel, StubConfiguration config)
    {
      return new TestServiceClient(channel, config);
    }
  }
}
#endregion