// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: math.proto
#region Designer generated code

using System;
using System.Threading;
using System.Threading.Tasks;
using Grpc.Core;

namespace math {
  public static class Math
  {
    static readonly string __ServiceName = "math.Math";

    static readonly Marshaller<global::math.DivArgs> __Marshaller_DivArgs = Marshallers.Create((arg) => arg.ToByteArray(), global::math.DivArgs.ParseFrom);
    static readonly Marshaller<global::math.DivReply> __Marshaller_DivReply = Marshallers.Create((arg) => arg.ToByteArray(), global::math.DivReply.ParseFrom);
    static readonly Marshaller<global::math.FibArgs> __Marshaller_FibArgs = Marshallers.Create((arg) => arg.ToByteArray(), global::math.FibArgs.ParseFrom);
    static readonly Marshaller<global::math.Num> __Marshaller_Num = Marshallers.Create((arg) => arg.ToByteArray(), global::math.Num.ParseFrom);

    static readonly Method<global::math.DivArgs, global::math.DivReply> __Method_Div = new Method<global::math.DivArgs, global::math.DivReply>(
        MethodType.Unary,
        "Div",
        __Marshaller_DivArgs,
        __Marshaller_DivReply);

    static readonly Method<global::math.DivArgs, global::math.DivReply> __Method_DivMany = new Method<global::math.DivArgs, global::math.DivReply>(
        MethodType.DuplexStreaming,
        "DivMany",
        __Marshaller_DivArgs,
        __Marshaller_DivReply);

    static readonly Method<global::math.FibArgs, global::math.Num> __Method_Fib = new Method<global::math.FibArgs, global::math.Num>(
        MethodType.ServerStreaming,
        "Fib",
        __Marshaller_FibArgs,
        __Marshaller_Num);

    static readonly Method<global::math.Num, global::math.Num> __Method_Sum = new Method<global::math.Num, global::math.Num>(
        MethodType.ClientStreaming,
        "Sum",
        __Marshaller_Num,
        __Marshaller_Num);

    // client interface
    public interface IMathClient
    {
      global::math.DivReply Div(global::math.DivArgs request, CancellationToken token = default(CancellationToken));
      Task<global::math.DivReply> DivAsync(global::math.DivArgs request, CancellationToken token = default(CancellationToken));
      AsyncDuplexStreamingCall<global::math.DivArgs, global::math.DivReply> DivMany(CancellationToken token = default(CancellationToken));
      AsyncServerStreamingCall<global::math.Num> Fib(global::math.FibArgs request, CancellationToken token = default(CancellationToken));
      AsyncClientStreamingCall<global::math.Num, global::math.Num> Sum(CancellationToken token = default(CancellationToken));
    }

    // server-side interface
    public interface IMath
    {
      Task<global::math.DivReply> Div(ServerCallContext context, global::math.DivArgs request);
      Task DivMany(ServerCallContext context, IAsyncStreamReader<global::math.DivArgs> requestStream, IServerStreamWriter<global::math.DivReply> responseStream);
      Task Fib(ServerCallContext context, global::math.FibArgs request, IServerStreamWriter<global::math.Num> responseStream);
      Task<global::math.Num> Sum(ServerCallContext context, IAsyncStreamReader<global::math.Num> requestStream);
    }

    // client stub
    public class MathClient : ClientBase, IMathClient
    {
      public MathClient(Channel channel) : base(channel)
      {
      }
      public global::math.DivReply Div(global::math.DivArgs request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_Div);
        return Calls.BlockingUnaryCall(call, request, token);
      }
      public Task<global::math.DivReply> DivAsync(global::math.DivArgs request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_Div);
        return Calls.AsyncUnaryCall(call, request, token);
      }
      public AsyncDuplexStreamingCall<global::math.DivArgs, global::math.DivReply> DivMany(CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_DivMany);
        return Calls.AsyncDuplexStreamingCall(call, token);
      }
      public AsyncServerStreamingCall<global::math.Num> Fib(global::math.FibArgs request, CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_Fib);
        return Calls.AsyncServerStreamingCall(call, request, token);
      }
      public AsyncClientStreamingCall<global::math.Num, global::math.Num> Sum(CancellationToken token = default(CancellationToken))
      {
        var call = CreateCall(__ServiceName, __Method_Sum);
        return Calls.AsyncClientStreamingCall(call, token);
      }
    }

    // creates service definition that can be registered with a server
    public static ServerServiceDefinition BindService(IMath serviceImpl)
    {
      return ServerServiceDefinition.CreateBuilder(__ServiceName)
          .AddMethod(__Method_Div, serviceImpl.Div)
          .AddMethod(__Method_DivMany, serviceImpl.DivMany)
          .AddMethod(__Method_Fib, serviceImpl.Fib)
          .AddMethod(__Method_Sum, serviceImpl.Sum).Build();
    }

    // creates a new client
    public static MathClient NewClient(Channel channel)
    {
      return new MathClient(channel);
    }

  }
}
#endregion
