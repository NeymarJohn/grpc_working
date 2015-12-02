// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: test/proto/benchmarks/payloads.proto
#pragma warning disable 1591, 0612, 3021
#region Designer generated code

using pb = global::Google.Protobuf;
using pbc = global::Google.Protobuf.Collections;
using pbr = global::Google.Protobuf.Reflection;
using scg = global::System.Collections.Generic;
namespace Grpc.Testing {

  [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
  public static partial class Payloads {

    #region Descriptor
    public static pbr::FileDescriptor Descriptor {
      get { return descriptor; }
    }
    private static pbr::FileDescriptor descriptor;

    static Payloads() {
      byte[] descriptorData = global::System.Convert.FromBase64String(
          string.Concat(
            "CiR0ZXN0L3Byb3RvL2JlbmNobWFya3MvcGF5bG9hZHMucHJvdG8SDGdycGMu", 
            "dGVzdGluZyI3ChBCeXRlQnVmZmVyUGFyYW1zEhAKCHJlcV9zaXplGAEgASgF", 
            "EhEKCXJlc3Bfc2l6ZRgCIAEoBSI4ChFTaW1wbGVQcm90b1BhcmFtcxIQCghy", 
            "ZXFfc2l6ZRgBIAEoBRIRCglyZXNwX3NpemUYAiABKAUiFAoSQ29tcGxleFBy", 
            "b3RvUGFyYW1zIsoBCg1QYXlsb2FkQ29uZmlnEjgKDmJ5dGVidWZfcGFyYW1z", 
            "GAEgASgLMh4uZ3JwYy50ZXN0aW5nLkJ5dGVCdWZmZXJQYXJhbXNIABI4Cg1z", 
            "aW1wbGVfcGFyYW1zGAIgASgLMh8uZ3JwYy50ZXN0aW5nLlNpbXBsZVByb3Rv", 
            "UGFyYW1zSAASOgoOY29tcGxleF9wYXJhbXMYAyABKAsyIC5ncnBjLnRlc3Rp", 
            "bmcuQ29tcGxleFByb3RvUGFyYW1zSABCCQoHcGF5bG9hZGIGcHJvdG8z"));
      descriptor = pbr::FileDescriptor.InternalBuildGeneratedFileFrom(descriptorData,
          new pbr::FileDescriptor[] { },
          new pbr::GeneratedCodeInfo(null, new pbr::GeneratedCodeInfo[] {
            new pbr::GeneratedCodeInfo(typeof(global::Grpc.Testing.ByteBufferParams), new[]{ "ReqSize", "RespSize" }, null, null, null),
            new pbr::GeneratedCodeInfo(typeof(global::Grpc.Testing.SimpleProtoParams), new[]{ "ReqSize", "RespSize" }, null, null, null),
            new pbr::GeneratedCodeInfo(typeof(global::Grpc.Testing.ComplexProtoParams), null, null, null, null),
            new pbr::GeneratedCodeInfo(typeof(global::Grpc.Testing.PayloadConfig), new[]{ "BytebufParams", "SimpleParams", "ComplexParams" }, new[]{ "Payload" }, null, null)
          }));
    }
    #endregion

  }
  #region Messages
  [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
  public sealed partial class ByteBufferParams : pb::IMessage<ByteBufferParams> {
    private static readonly pb::MessageParser<ByteBufferParams> _parser = new pb::MessageParser<ByteBufferParams>(() => new ByteBufferParams());
    public static pb::MessageParser<ByteBufferParams> Parser { get { return _parser; } }

    public static pbr::MessageDescriptor Descriptor {
      get { return global::Grpc.Testing.Payloads.Descriptor.MessageTypes[0]; }
    }

    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    public ByteBufferParams() {
      OnConstruction();
    }

    partial void OnConstruction();

    public ByteBufferParams(ByteBufferParams other) : this() {
      reqSize_ = other.reqSize_;
      respSize_ = other.respSize_;
    }

    public ByteBufferParams Clone() {
      return new ByteBufferParams(this);
    }

    public const int ReqSizeFieldNumber = 1;
    private int reqSize_;
    public int ReqSize {
      get { return reqSize_; }
      set {
        reqSize_ = value;
      }
    }

    public const int RespSizeFieldNumber = 2;
    private int respSize_;
    public int RespSize {
      get { return respSize_; }
      set {
        respSize_ = value;
      }
    }

    public override bool Equals(object other) {
      return Equals(other as ByteBufferParams);
    }

    public bool Equals(ByteBufferParams other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      if (ReqSize != other.ReqSize) return false;
      if (RespSize != other.RespSize) return false;
      return true;
    }

    public override int GetHashCode() {
      int hash = 1;
      if (ReqSize != 0) hash ^= ReqSize.GetHashCode();
      if (RespSize != 0) hash ^= RespSize.GetHashCode();
      return hash;
    }

    public override string ToString() {
      return pb::JsonFormatter.Default.Format(this);
    }

    public void WriteTo(pb::CodedOutputStream output) {
      if (ReqSize != 0) {
        output.WriteRawTag(8);
        output.WriteInt32(ReqSize);
      }
      if (RespSize != 0) {
        output.WriteRawTag(16);
        output.WriteInt32(RespSize);
      }
    }

    public int CalculateSize() {
      int size = 0;
      if (ReqSize != 0) {
        size += 1 + pb::CodedOutputStream.ComputeInt32Size(ReqSize);
      }
      if (RespSize != 0) {
        size += 1 + pb::CodedOutputStream.ComputeInt32Size(RespSize);
      }
      return size;
    }

    public void MergeFrom(ByteBufferParams other) {
      if (other == null) {
        return;
      }
      if (other.ReqSize != 0) {
        ReqSize = other.ReqSize;
      }
      if (other.RespSize != 0) {
        RespSize = other.RespSize;
      }
    }

    public void MergeFrom(pb::CodedInputStream input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            input.SkipLastField();
            break;
          case 8: {
            ReqSize = input.ReadInt32();
            break;
          }
          case 16: {
            RespSize = input.ReadInt32();
            break;
          }
        }
      }
    }

  }

  [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
  public sealed partial class SimpleProtoParams : pb::IMessage<SimpleProtoParams> {
    private static readonly pb::MessageParser<SimpleProtoParams> _parser = new pb::MessageParser<SimpleProtoParams>(() => new SimpleProtoParams());
    public static pb::MessageParser<SimpleProtoParams> Parser { get { return _parser; } }

    public static pbr::MessageDescriptor Descriptor {
      get { return global::Grpc.Testing.Payloads.Descriptor.MessageTypes[1]; }
    }

    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    public SimpleProtoParams() {
      OnConstruction();
    }

    partial void OnConstruction();

    public SimpleProtoParams(SimpleProtoParams other) : this() {
      reqSize_ = other.reqSize_;
      respSize_ = other.respSize_;
    }

    public SimpleProtoParams Clone() {
      return new SimpleProtoParams(this);
    }

    public const int ReqSizeFieldNumber = 1;
    private int reqSize_;
    public int ReqSize {
      get { return reqSize_; }
      set {
        reqSize_ = value;
      }
    }

    public const int RespSizeFieldNumber = 2;
    private int respSize_;
    public int RespSize {
      get { return respSize_; }
      set {
        respSize_ = value;
      }
    }

    public override bool Equals(object other) {
      return Equals(other as SimpleProtoParams);
    }

    public bool Equals(SimpleProtoParams other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      if (ReqSize != other.ReqSize) return false;
      if (RespSize != other.RespSize) return false;
      return true;
    }

    public override int GetHashCode() {
      int hash = 1;
      if (ReqSize != 0) hash ^= ReqSize.GetHashCode();
      if (RespSize != 0) hash ^= RespSize.GetHashCode();
      return hash;
    }

    public override string ToString() {
      return pb::JsonFormatter.Default.Format(this);
    }

    public void WriteTo(pb::CodedOutputStream output) {
      if (ReqSize != 0) {
        output.WriteRawTag(8);
        output.WriteInt32(ReqSize);
      }
      if (RespSize != 0) {
        output.WriteRawTag(16);
        output.WriteInt32(RespSize);
      }
    }

    public int CalculateSize() {
      int size = 0;
      if (ReqSize != 0) {
        size += 1 + pb::CodedOutputStream.ComputeInt32Size(ReqSize);
      }
      if (RespSize != 0) {
        size += 1 + pb::CodedOutputStream.ComputeInt32Size(RespSize);
      }
      return size;
    }

    public void MergeFrom(SimpleProtoParams other) {
      if (other == null) {
        return;
      }
      if (other.ReqSize != 0) {
        ReqSize = other.ReqSize;
      }
      if (other.RespSize != 0) {
        RespSize = other.RespSize;
      }
    }

    public void MergeFrom(pb::CodedInputStream input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            input.SkipLastField();
            break;
          case 8: {
            ReqSize = input.ReadInt32();
            break;
          }
          case 16: {
            RespSize = input.ReadInt32();
            break;
          }
        }
      }
    }

  }

  [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
  public sealed partial class ComplexProtoParams : pb::IMessage<ComplexProtoParams> {
    private static readonly pb::MessageParser<ComplexProtoParams> _parser = new pb::MessageParser<ComplexProtoParams>(() => new ComplexProtoParams());
    public static pb::MessageParser<ComplexProtoParams> Parser { get { return _parser; } }

    public static pbr::MessageDescriptor Descriptor {
      get { return global::Grpc.Testing.Payloads.Descriptor.MessageTypes[2]; }
    }

    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    public ComplexProtoParams() {
      OnConstruction();
    }

    partial void OnConstruction();

    public ComplexProtoParams(ComplexProtoParams other) : this() {
    }

    public ComplexProtoParams Clone() {
      return new ComplexProtoParams(this);
    }

    public override bool Equals(object other) {
      return Equals(other as ComplexProtoParams);
    }

    public bool Equals(ComplexProtoParams other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      return true;
    }

    public override int GetHashCode() {
      int hash = 1;
      return hash;
    }

    public override string ToString() {
      return pb::JsonFormatter.Default.Format(this);
    }

    public void WriteTo(pb::CodedOutputStream output) {
    }

    public int CalculateSize() {
      int size = 0;
      return size;
    }

    public void MergeFrom(ComplexProtoParams other) {
      if (other == null) {
        return;
      }
    }

    public void MergeFrom(pb::CodedInputStream input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            input.SkipLastField();
            break;
        }
      }
    }

  }

  [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
  public sealed partial class PayloadConfig : pb::IMessage<PayloadConfig> {
    private static readonly pb::MessageParser<PayloadConfig> _parser = new pb::MessageParser<PayloadConfig>(() => new PayloadConfig());
    public static pb::MessageParser<PayloadConfig> Parser { get { return _parser; } }

    public static pbr::MessageDescriptor Descriptor {
      get { return global::Grpc.Testing.Payloads.Descriptor.MessageTypes[3]; }
    }

    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    public PayloadConfig() {
      OnConstruction();
    }

    partial void OnConstruction();

    public PayloadConfig(PayloadConfig other) : this() {
      switch (other.PayloadCase) {
        case PayloadOneofCase.BytebufParams:
          BytebufParams = other.BytebufParams.Clone();
          break;
        case PayloadOneofCase.SimpleParams:
          SimpleParams = other.SimpleParams.Clone();
          break;
        case PayloadOneofCase.ComplexParams:
          ComplexParams = other.ComplexParams.Clone();
          break;
      }

    }

    public PayloadConfig Clone() {
      return new PayloadConfig(this);
    }

    public const int BytebufParamsFieldNumber = 1;
    public global::Grpc.Testing.ByteBufferParams BytebufParams {
      get { return payloadCase_ == PayloadOneofCase.BytebufParams ? (global::Grpc.Testing.ByteBufferParams) payload_ : null; }
      set {
        payload_ = value;
        payloadCase_ = value == null ? PayloadOneofCase.None : PayloadOneofCase.BytebufParams;
      }
    }

    public const int SimpleParamsFieldNumber = 2;
    public global::Grpc.Testing.SimpleProtoParams SimpleParams {
      get { return payloadCase_ == PayloadOneofCase.SimpleParams ? (global::Grpc.Testing.SimpleProtoParams) payload_ : null; }
      set {
        payload_ = value;
        payloadCase_ = value == null ? PayloadOneofCase.None : PayloadOneofCase.SimpleParams;
      }
    }

    public const int ComplexParamsFieldNumber = 3;
    public global::Grpc.Testing.ComplexProtoParams ComplexParams {
      get { return payloadCase_ == PayloadOneofCase.ComplexParams ? (global::Grpc.Testing.ComplexProtoParams) payload_ : null; }
      set {
        payload_ = value;
        payloadCase_ = value == null ? PayloadOneofCase.None : PayloadOneofCase.ComplexParams;
      }
    }

    private object payload_;
    public enum PayloadOneofCase {
      None = 0,
      BytebufParams = 1,
      SimpleParams = 2,
      ComplexParams = 3,
    }
    private PayloadOneofCase payloadCase_ = PayloadOneofCase.None;
    public PayloadOneofCase PayloadCase {
      get { return payloadCase_; }
    }

    public void ClearPayload() {
      payloadCase_ = PayloadOneofCase.None;
      payload_ = null;
    }

    public override bool Equals(object other) {
      return Equals(other as PayloadConfig);
    }

    public bool Equals(PayloadConfig other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      if (!object.Equals(BytebufParams, other.BytebufParams)) return false;
      if (!object.Equals(SimpleParams, other.SimpleParams)) return false;
      if (!object.Equals(ComplexParams, other.ComplexParams)) return false;
      return true;
    }

    public override int GetHashCode() {
      int hash = 1;
      if (payloadCase_ == PayloadOneofCase.BytebufParams) hash ^= BytebufParams.GetHashCode();
      if (payloadCase_ == PayloadOneofCase.SimpleParams) hash ^= SimpleParams.GetHashCode();
      if (payloadCase_ == PayloadOneofCase.ComplexParams) hash ^= ComplexParams.GetHashCode();
      return hash;
    }

    public override string ToString() {
      return pb::JsonFormatter.Default.Format(this);
    }

    public void WriteTo(pb::CodedOutputStream output) {
      if (payloadCase_ == PayloadOneofCase.BytebufParams) {
        output.WriteRawTag(10);
        output.WriteMessage(BytebufParams);
      }
      if (payloadCase_ == PayloadOneofCase.SimpleParams) {
        output.WriteRawTag(18);
        output.WriteMessage(SimpleParams);
      }
      if (payloadCase_ == PayloadOneofCase.ComplexParams) {
        output.WriteRawTag(26);
        output.WriteMessage(ComplexParams);
      }
    }

    public int CalculateSize() {
      int size = 0;
      if (payloadCase_ == PayloadOneofCase.BytebufParams) {
        size += 1 + pb::CodedOutputStream.ComputeMessageSize(BytebufParams);
      }
      if (payloadCase_ == PayloadOneofCase.SimpleParams) {
        size += 1 + pb::CodedOutputStream.ComputeMessageSize(SimpleParams);
      }
      if (payloadCase_ == PayloadOneofCase.ComplexParams) {
        size += 1 + pb::CodedOutputStream.ComputeMessageSize(ComplexParams);
      }
      return size;
    }

    public void MergeFrom(PayloadConfig other) {
      if (other == null) {
        return;
      }
      switch (other.PayloadCase) {
        case PayloadOneofCase.BytebufParams:
          BytebufParams = other.BytebufParams;
          break;
        case PayloadOneofCase.SimpleParams:
          SimpleParams = other.SimpleParams;
          break;
        case PayloadOneofCase.ComplexParams:
          ComplexParams = other.ComplexParams;
          break;
      }

    }

    public void MergeFrom(pb::CodedInputStream input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            input.SkipLastField();
            break;
          case 10: {
            global::Grpc.Testing.ByteBufferParams subBuilder = new global::Grpc.Testing.ByteBufferParams();
            if (payloadCase_ == PayloadOneofCase.BytebufParams) {
              subBuilder.MergeFrom(BytebufParams);
            }
            input.ReadMessage(subBuilder);
            BytebufParams = subBuilder;
            break;
          }
          case 18: {
            global::Grpc.Testing.SimpleProtoParams subBuilder = new global::Grpc.Testing.SimpleProtoParams();
            if (payloadCase_ == PayloadOneofCase.SimpleParams) {
              subBuilder.MergeFrom(SimpleParams);
            }
            input.ReadMessage(subBuilder);
            SimpleParams = subBuilder;
            break;
          }
          case 26: {
            global::Grpc.Testing.ComplexProtoParams subBuilder = new global::Grpc.Testing.ComplexProtoParams();
            if (payloadCase_ == PayloadOneofCase.ComplexParams) {
              subBuilder.MergeFrom(ComplexParams);
            }
            input.ReadMessage(subBuilder);
            ComplexParams = subBuilder;
            break;
          }
        }
      }
    }

  }

  #endregion

}

#endregion Designer generated code
