// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: src/main/proto/helloworld.proto

package ex.grpc;

public final class Helloworld {
  private Helloworld() {}
  public static void registerAllExtensions(
      com.google.protobuf.ExtensionRegistry registry) {
  }
  public interface HelloRequestOrBuilder extends
      // @@protoc_insertion_point(interface_extends:helloworld.HelloRequest)
      com.google.protobuf.MessageOrBuilder {

    /**
     * <code>optional string name = 1;</code>
     */
    java.lang.String getName();
    /**
     * <code>optional string name = 1;</code>
     */
    com.google.protobuf.ByteString
        getNameBytes();
  }
  /**
   * Protobuf type {@code helloworld.HelloRequest}
   *
   * <pre>
   * The request message containing the user's name.
   * </pre>
   */
  public  static final class HelloRequest extends
      com.google.protobuf.GeneratedMessage implements
      // @@protoc_insertion_point(message_implements:helloworld.HelloRequest)
      HelloRequestOrBuilder {
    // Use HelloRequest.newBuilder() to construct.
    private HelloRequest(com.google.protobuf.GeneratedMessage.Builder builder) {
      super(builder);
    }
    private HelloRequest() {
      name_ = "";
    }

    @java.lang.Override
    public final com.google.protobuf.UnknownFieldSet
    getUnknownFields() {
      return com.google.protobuf.UnknownFieldSet.getDefaultInstance();
    }
    private HelloRequest(
        com.google.protobuf.CodedInputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws com.google.protobuf.InvalidProtocolBufferException {
      this();
      int mutable_bitField0_ = 0;
      try {
        boolean done = false;
        while (!done) {
          int tag = input.readTag();
          switch (tag) {
            case 0:
              done = true;
              break;
            default: {
              if (!input.skipField(tag)) {
                done = true;
              }
              break;
            }
            case 10: {
              com.google.protobuf.ByteString bs = input.readBytes();

              name_ = bs;
              break;
            }
          }
        }
      } catch (com.google.protobuf.InvalidProtocolBufferException e) {
        throw e.setUnfinishedMessage(this);
      } catch (java.io.IOException e) {
        throw new com.google.protobuf.InvalidProtocolBufferException(
            e.getMessage()).setUnfinishedMessage(this);
      } finally {
        makeExtensionsImmutable();
      }
    }
    public static final com.google.protobuf.Descriptors.Descriptor
        getDescriptor() {
      return ex.grpc.Helloworld.internal_static_helloworld_HelloRequest_descriptor;
    }

    protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
        internalGetFieldAccessorTable() {
      return ex.grpc.Helloworld.internal_static_helloworld_HelloRequest_fieldAccessorTable
          .ensureFieldAccessorsInitialized(
              ex.grpc.Helloworld.HelloRequest.class, ex.grpc.Helloworld.HelloRequest.Builder.class);
    }

    public static final com.google.protobuf.Parser<HelloRequest> PARSER =
        new com.google.protobuf.AbstractParser<HelloRequest>() {
      public HelloRequest parsePartialFrom(
          com.google.protobuf.CodedInputStream input,
          com.google.protobuf.ExtensionRegistryLite extensionRegistry)
          throws com.google.protobuf.InvalidProtocolBufferException {
        return new HelloRequest(input, extensionRegistry);
      }
    };

    @java.lang.Override
    public com.google.protobuf.Parser<HelloRequest> getParserForType() {
      return PARSER;
    }

    public static final int NAME_FIELD_NUMBER = 1;
    private java.lang.Object name_;
    /**
     * <code>optional string name = 1;</code>
     */
    public java.lang.String getName() {
      java.lang.Object ref = name_;
      if (ref instanceof java.lang.String) {
        return (java.lang.String) ref;
      } else {
        com.google.protobuf.ByteString bs = 
            (com.google.protobuf.ByteString) ref;
        java.lang.String s = bs.toStringUtf8();
        if (bs.isValidUtf8()) {
          name_ = s;
        }
        return s;
      }
    }
    /**
     * <code>optional string name = 1;</code>
     */
    public com.google.protobuf.ByteString
        getNameBytes() {
      java.lang.Object ref = name_;
      if (ref instanceof java.lang.String) {
        com.google.protobuf.ByteString b = 
            com.google.protobuf.ByteString.copyFromUtf8(
                (java.lang.String) ref);
        name_ = b;
        return b;
      } else {
        return (com.google.protobuf.ByteString) ref;
      }
    }

    private byte memoizedIsInitialized = -1;
    public final boolean isInitialized() {
      byte isInitialized = memoizedIsInitialized;
      if (isInitialized == 1) return true;
      if (isInitialized == 0) return false;

      memoizedIsInitialized = 1;
      return true;
    }

    public void writeTo(com.google.protobuf.CodedOutputStream output)
                        throws java.io.IOException {
      getSerializedSize();
      if (!getNameBytes().isEmpty()) {
        output.writeBytes(1, getNameBytes());
      }
    }

    private int memoizedSerializedSize = -1;
    public int getSerializedSize() {
      int size = memoizedSerializedSize;
      if (size != -1) return size;

      size = 0;
      if (!getNameBytes().isEmpty()) {
        size += com.google.protobuf.CodedOutputStream
          .computeBytesSize(1, getNameBytes());
      }
      memoizedSerializedSize = size;
      return size;
    }

    private static final long serialVersionUID = 0L;
    public static ex.grpc.Helloworld.HelloRequest parseFrom(
        com.google.protobuf.ByteString data)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data);
    }
    public static ex.grpc.Helloworld.HelloRequest parseFrom(
        com.google.protobuf.ByteString data,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloRequest parseFrom(byte[] data)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data);
    }
    public static ex.grpc.Helloworld.HelloRequest parseFrom(
        byte[] data,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloRequest parseFrom(java.io.InputStream input)
        throws java.io.IOException {
      return PARSER.parseFrom(input);
    }
    public static ex.grpc.Helloworld.HelloRequest parseFrom(
        java.io.InputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      return PARSER.parseFrom(input, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloRequest parseDelimitedFrom(java.io.InputStream input)
        throws java.io.IOException {
      return PARSER.parseDelimitedFrom(input);
    }
    public static ex.grpc.Helloworld.HelloRequest parseDelimitedFrom(
        java.io.InputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      return PARSER.parseDelimitedFrom(input, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloRequest parseFrom(
        com.google.protobuf.CodedInputStream input)
        throws java.io.IOException {
      return PARSER.parseFrom(input);
    }
    public static ex.grpc.Helloworld.HelloRequest parseFrom(
        com.google.protobuf.CodedInputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      return PARSER.parseFrom(input, extensionRegistry);
    }

    public static Builder newBuilder() { return new Builder(); }
    public Builder newBuilderForType() { return newBuilder(); }
    public static Builder newBuilder(ex.grpc.Helloworld.HelloRequest prototype) {
      return newBuilder().mergeFrom(prototype);
    }
    public Builder toBuilder() { return newBuilder(this); }

    @java.lang.Override
    protected Builder newBuilderForType(
        com.google.protobuf.GeneratedMessage.BuilderParent parent) {
      Builder builder = new Builder(parent);
      return builder;
    }
    /**
     * Protobuf type {@code helloworld.HelloRequest}
     *
     * <pre>
     * The request message containing the user's name.
     * </pre>
     */
    public static final class Builder extends
        com.google.protobuf.GeneratedMessage.Builder<Builder> implements
        // @@protoc_insertion_point(builder_implements:helloworld.HelloRequest)
        ex.grpc.Helloworld.HelloRequestOrBuilder {
      public static final com.google.protobuf.Descriptors.Descriptor
          getDescriptor() {
        return ex.grpc.Helloworld.internal_static_helloworld_HelloRequest_descriptor;
      }

      protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
          internalGetFieldAccessorTable() {
        return ex.grpc.Helloworld.internal_static_helloworld_HelloRequest_fieldAccessorTable
            .ensureFieldAccessorsInitialized(
                ex.grpc.Helloworld.HelloRequest.class, ex.grpc.Helloworld.HelloRequest.Builder.class);
      }

      // Construct using ex.grpc.Helloworld.HelloRequest.newBuilder()
      private Builder() {
        maybeForceBuilderInitialization();
      }

      private Builder(
          com.google.protobuf.GeneratedMessage.BuilderParent parent) {
        super(parent);
        maybeForceBuilderInitialization();
      }
      private void maybeForceBuilderInitialization() {
        if (com.google.protobuf.GeneratedMessage.alwaysUseFieldBuilders) {
        }
      }
      public Builder clear() {
        super.clear();
        name_ = "";

        return this;
      }

      public com.google.protobuf.Descriptors.Descriptor
          getDescriptorForType() {
        return ex.grpc.Helloworld.internal_static_helloworld_HelloRequest_descriptor;
      }

      public ex.grpc.Helloworld.HelloRequest getDefaultInstanceForType() {
        return ex.grpc.Helloworld.HelloRequest.getDefaultInstance();
      }

      public ex.grpc.Helloworld.HelloRequest build() {
        ex.grpc.Helloworld.HelloRequest result = buildPartial();
        if (!result.isInitialized()) {
          throw newUninitializedMessageException(result);
        }
        return result;
      }

      public ex.grpc.Helloworld.HelloRequest buildPartial() {
        ex.grpc.Helloworld.HelloRequest result = new ex.grpc.Helloworld.HelloRequest(this);
        result.name_ = name_;
        onBuilt();
        return result;
      }

      public Builder mergeFrom(com.google.protobuf.Message other) {
        if (other instanceof ex.grpc.Helloworld.HelloRequest) {
          return mergeFrom((ex.grpc.Helloworld.HelloRequest)other);
        } else {
          super.mergeFrom(other);
          return this;
        }
      }

      public Builder mergeFrom(ex.grpc.Helloworld.HelloRequest other) {
        if (other == ex.grpc.Helloworld.HelloRequest.getDefaultInstance()) return this;
        if (!other.getName().isEmpty()) {
          name_ = other.name_;
          onChanged();
        }
        onChanged();
        return this;
      }

      public final boolean isInitialized() {
        return true;
      }

      public Builder mergeFrom(
          com.google.protobuf.CodedInputStream input,
          com.google.protobuf.ExtensionRegistryLite extensionRegistry)
          throws java.io.IOException {
        ex.grpc.Helloworld.HelloRequest parsedMessage = null;
        try {
          parsedMessage = PARSER.parsePartialFrom(input, extensionRegistry);
        } catch (com.google.protobuf.InvalidProtocolBufferException e) {
          parsedMessage = (ex.grpc.Helloworld.HelloRequest) e.getUnfinishedMessage();
          throw e;
        } finally {
          if (parsedMessage != null) {
            mergeFrom(parsedMessage);
          }
        }
        return this;
      }

      private java.lang.Object name_ = "";
      /**
       * <code>optional string name = 1;</code>
       */
      public java.lang.String getName() {
        java.lang.Object ref = name_;
        if (!(ref instanceof java.lang.String)) {
          com.google.protobuf.ByteString bs =
              (com.google.protobuf.ByteString) ref;
          java.lang.String s = bs.toStringUtf8();
          if (bs.isValidUtf8()) {
            name_ = s;
          }
          return s;
        } else {
          return (java.lang.String) ref;
        }
      }
      /**
       * <code>optional string name = 1;</code>
       */
      public com.google.protobuf.ByteString
          getNameBytes() {
        java.lang.Object ref = name_;
        if (ref instanceof String) {
          com.google.protobuf.ByteString b = 
              com.google.protobuf.ByteString.copyFromUtf8(
                  (java.lang.String) ref);
          name_ = b;
          return b;
        } else {
          return (com.google.protobuf.ByteString) ref;
        }
      }
      /**
       * <code>optional string name = 1;</code>
       */
      public Builder setName(
          java.lang.String value) {
        if (value == null) {
    throw new NullPointerException();
  }
  
        name_ = value;
        onChanged();
        return this;
      }
      /**
       * <code>optional string name = 1;</code>
       */
      public Builder clearName() {
        
        name_ = getDefaultInstance().getName();
        onChanged();
        return this;
      }
      /**
       * <code>optional string name = 1;</code>
       */
      public Builder setNameBytes(
          com.google.protobuf.ByteString value) {
        if (value == null) {
    throw new NullPointerException();
  }
  
        name_ = value;
        onChanged();
        return this;
      }
      public final Builder setUnknownFields(
          final com.google.protobuf.UnknownFieldSet unknownFields) {
        return this;
      }

      public final Builder mergeUnknownFields(
          final com.google.protobuf.UnknownFieldSet unknownFields) {
        return this;
      }


      // @@protoc_insertion_point(builder_scope:helloworld.HelloRequest)
    }

    // @@protoc_insertion_point(class_scope:helloworld.HelloRequest)
    private static final ex.grpc.Helloworld.HelloRequest defaultInstance;static {
      defaultInstance = new ex.grpc.Helloworld.HelloRequest();
    }

    public static ex.grpc.Helloworld.HelloRequest getDefaultInstance() {
      return defaultInstance;
    }

    public ex.grpc.Helloworld.HelloRequest getDefaultInstanceForType() {
      return defaultInstance;
    }

  }

  public interface HelloReplyOrBuilder extends
      // @@protoc_insertion_point(interface_extends:helloworld.HelloReply)
      com.google.protobuf.MessageOrBuilder {

    /**
     * <code>optional string message = 1;</code>
     */
    java.lang.String getMessage();
    /**
     * <code>optional string message = 1;</code>
     */
    com.google.protobuf.ByteString
        getMessageBytes();
  }
  /**
   * Protobuf type {@code helloworld.HelloReply}
   *
   * <pre>
   * The response message containing the greetings
   * </pre>
   */
  public  static final class HelloReply extends
      com.google.protobuf.GeneratedMessage implements
      // @@protoc_insertion_point(message_implements:helloworld.HelloReply)
      HelloReplyOrBuilder {
    // Use HelloReply.newBuilder() to construct.
    private HelloReply(com.google.protobuf.GeneratedMessage.Builder builder) {
      super(builder);
    }
    private HelloReply() {
      message_ = "";
    }

    @java.lang.Override
    public final com.google.protobuf.UnknownFieldSet
    getUnknownFields() {
      return com.google.protobuf.UnknownFieldSet.getDefaultInstance();
    }
    private HelloReply(
        com.google.protobuf.CodedInputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws com.google.protobuf.InvalidProtocolBufferException {
      this();
      int mutable_bitField0_ = 0;
      try {
        boolean done = false;
        while (!done) {
          int tag = input.readTag();
          switch (tag) {
            case 0:
              done = true;
              break;
            default: {
              if (!input.skipField(tag)) {
                done = true;
              }
              break;
            }
            case 10: {
              com.google.protobuf.ByteString bs = input.readBytes();

              message_ = bs;
              break;
            }
          }
        }
      } catch (com.google.protobuf.InvalidProtocolBufferException e) {
        throw e.setUnfinishedMessage(this);
      } catch (java.io.IOException e) {
        throw new com.google.protobuf.InvalidProtocolBufferException(
            e.getMessage()).setUnfinishedMessage(this);
      } finally {
        makeExtensionsImmutable();
      }
    }
    public static final com.google.protobuf.Descriptors.Descriptor
        getDescriptor() {
      return ex.grpc.Helloworld.internal_static_helloworld_HelloReply_descriptor;
    }

    protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
        internalGetFieldAccessorTable() {
      return ex.grpc.Helloworld.internal_static_helloworld_HelloReply_fieldAccessorTable
          .ensureFieldAccessorsInitialized(
              ex.grpc.Helloworld.HelloReply.class, ex.grpc.Helloworld.HelloReply.Builder.class);
    }

    public static final com.google.protobuf.Parser<HelloReply> PARSER =
        new com.google.protobuf.AbstractParser<HelloReply>() {
      public HelloReply parsePartialFrom(
          com.google.protobuf.CodedInputStream input,
          com.google.protobuf.ExtensionRegistryLite extensionRegistry)
          throws com.google.protobuf.InvalidProtocolBufferException {
        return new HelloReply(input, extensionRegistry);
      }
    };

    @java.lang.Override
    public com.google.protobuf.Parser<HelloReply> getParserForType() {
      return PARSER;
    }

    public static final int MESSAGE_FIELD_NUMBER = 1;
    private java.lang.Object message_;
    /**
     * <code>optional string message = 1;</code>
     */
    public java.lang.String getMessage() {
      java.lang.Object ref = message_;
      if (ref instanceof java.lang.String) {
        return (java.lang.String) ref;
      } else {
        com.google.protobuf.ByteString bs = 
            (com.google.protobuf.ByteString) ref;
        java.lang.String s = bs.toStringUtf8();
        if (bs.isValidUtf8()) {
          message_ = s;
        }
        return s;
      }
    }
    /**
     * <code>optional string message = 1;</code>
     */
    public com.google.protobuf.ByteString
        getMessageBytes() {
      java.lang.Object ref = message_;
      if (ref instanceof java.lang.String) {
        com.google.protobuf.ByteString b = 
            com.google.protobuf.ByteString.copyFromUtf8(
                (java.lang.String) ref);
        message_ = b;
        return b;
      } else {
        return (com.google.protobuf.ByteString) ref;
      }
    }

    private byte memoizedIsInitialized = -1;
    public final boolean isInitialized() {
      byte isInitialized = memoizedIsInitialized;
      if (isInitialized == 1) return true;
      if (isInitialized == 0) return false;

      memoizedIsInitialized = 1;
      return true;
    }

    public void writeTo(com.google.protobuf.CodedOutputStream output)
                        throws java.io.IOException {
      getSerializedSize();
      if (!getMessageBytes().isEmpty()) {
        output.writeBytes(1, getMessageBytes());
      }
    }

    private int memoizedSerializedSize = -1;
    public int getSerializedSize() {
      int size = memoizedSerializedSize;
      if (size != -1) return size;

      size = 0;
      if (!getMessageBytes().isEmpty()) {
        size += com.google.protobuf.CodedOutputStream
          .computeBytesSize(1, getMessageBytes());
      }
      memoizedSerializedSize = size;
      return size;
    }

    private static final long serialVersionUID = 0L;
    public static ex.grpc.Helloworld.HelloReply parseFrom(
        com.google.protobuf.ByteString data)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data);
    }
    public static ex.grpc.Helloworld.HelloReply parseFrom(
        com.google.protobuf.ByteString data,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloReply parseFrom(byte[] data)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data);
    }
    public static ex.grpc.Helloworld.HelloReply parseFrom(
        byte[] data,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return PARSER.parseFrom(data, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloReply parseFrom(java.io.InputStream input)
        throws java.io.IOException {
      return PARSER.parseFrom(input);
    }
    public static ex.grpc.Helloworld.HelloReply parseFrom(
        java.io.InputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      return PARSER.parseFrom(input, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloReply parseDelimitedFrom(java.io.InputStream input)
        throws java.io.IOException {
      return PARSER.parseDelimitedFrom(input);
    }
    public static ex.grpc.Helloworld.HelloReply parseDelimitedFrom(
        java.io.InputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      return PARSER.parseDelimitedFrom(input, extensionRegistry);
    }
    public static ex.grpc.Helloworld.HelloReply parseFrom(
        com.google.protobuf.CodedInputStream input)
        throws java.io.IOException {
      return PARSER.parseFrom(input);
    }
    public static ex.grpc.Helloworld.HelloReply parseFrom(
        com.google.protobuf.CodedInputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      return PARSER.parseFrom(input, extensionRegistry);
    }

    public static Builder newBuilder() { return new Builder(); }
    public Builder newBuilderForType() { return newBuilder(); }
    public static Builder newBuilder(ex.grpc.Helloworld.HelloReply prototype) {
      return newBuilder().mergeFrom(prototype);
    }
    public Builder toBuilder() { return newBuilder(this); }

    @java.lang.Override
    protected Builder newBuilderForType(
        com.google.protobuf.GeneratedMessage.BuilderParent parent) {
      Builder builder = new Builder(parent);
      return builder;
    }
    /**
     * Protobuf type {@code helloworld.HelloReply}
     *
     * <pre>
     * The response message containing the greetings
     * </pre>
     */
    public static final class Builder extends
        com.google.protobuf.GeneratedMessage.Builder<Builder> implements
        // @@protoc_insertion_point(builder_implements:helloworld.HelloReply)
        ex.grpc.Helloworld.HelloReplyOrBuilder {
      public static final com.google.protobuf.Descriptors.Descriptor
          getDescriptor() {
        return ex.grpc.Helloworld.internal_static_helloworld_HelloReply_descriptor;
      }

      protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
          internalGetFieldAccessorTable() {
        return ex.grpc.Helloworld.internal_static_helloworld_HelloReply_fieldAccessorTable
            .ensureFieldAccessorsInitialized(
                ex.grpc.Helloworld.HelloReply.class, ex.grpc.Helloworld.HelloReply.Builder.class);
      }

      // Construct using ex.grpc.Helloworld.HelloReply.newBuilder()
      private Builder() {
        maybeForceBuilderInitialization();
      }

      private Builder(
          com.google.protobuf.GeneratedMessage.BuilderParent parent) {
        super(parent);
        maybeForceBuilderInitialization();
      }
      private void maybeForceBuilderInitialization() {
        if (com.google.protobuf.GeneratedMessage.alwaysUseFieldBuilders) {
        }
      }
      public Builder clear() {
        super.clear();
        message_ = "";

        return this;
      }

      public com.google.protobuf.Descriptors.Descriptor
          getDescriptorForType() {
        return ex.grpc.Helloworld.internal_static_helloworld_HelloReply_descriptor;
      }

      public ex.grpc.Helloworld.HelloReply getDefaultInstanceForType() {
        return ex.grpc.Helloworld.HelloReply.getDefaultInstance();
      }

      public ex.grpc.Helloworld.HelloReply build() {
        ex.grpc.Helloworld.HelloReply result = buildPartial();
        if (!result.isInitialized()) {
          throw newUninitializedMessageException(result);
        }
        return result;
      }

      public ex.grpc.Helloworld.HelloReply buildPartial() {
        ex.grpc.Helloworld.HelloReply result = new ex.grpc.Helloworld.HelloReply(this);
        result.message_ = message_;
        onBuilt();
        return result;
      }

      public Builder mergeFrom(com.google.protobuf.Message other) {
        if (other instanceof ex.grpc.Helloworld.HelloReply) {
          return mergeFrom((ex.grpc.Helloworld.HelloReply)other);
        } else {
          super.mergeFrom(other);
          return this;
        }
      }

      public Builder mergeFrom(ex.grpc.Helloworld.HelloReply other) {
        if (other == ex.grpc.Helloworld.HelloReply.getDefaultInstance()) return this;
        if (!other.getMessage().isEmpty()) {
          message_ = other.message_;
          onChanged();
        }
        onChanged();
        return this;
      }

      public final boolean isInitialized() {
        return true;
      }

      public Builder mergeFrom(
          com.google.protobuf.CodedInputStream input,
          com.google.protobuf.ExtensionRegistryLite extensionRegistry)
          throws java.io.IOException {
        ex.grpc.Helloworld.HelloReply parsedMessage = null;
        try {
          parsedMessage = PARSER.parsePartialFrom(input, extensionRegistry);
        } catch (com.google.protobuf.InvalidProtocolBufferException e) {
          parsedMessage = (ex.grpc.Helloworld.HelloReply) e.getUnfinishedMessage();
          throw e;
        } finally {
          if (parsedMessage != null) {
            mergeFrom(parsedMessage);
          }
        }
        return this;
      }

      private java.lang.Object message_ = "";
      /**
       * <code>optional string message = 1;</code>
       */
      public java.lang.String getMessage() {
        java.lang.Object ref = message_;
        if (!(ref instanceof java.lang.String)) {
          com.google.protobuf.ByteString bs =
              (com.google.protobuf.ByteString) ref;
          java.lang.String s = bs.toStringUtf8();
          if (bs.isValidUtf8()) {
            message_ = s;
          }
          return s;
        } else {
          return (java.lang.String) ref;
        }
      }
      /**
       * <code>optional string message = 1;</code>
       */
      public com.google.protobuf.ByteString
          getMessageBytes() {
        java.lang.Object ref = message_;
        if (ref instanceof String) {
          com.google.protobuf.ByteString b = 
              com.google.protobuf.ByteString.copyFromUtf8(
                  (java.lang.String) ref);
          message_ = b;
          return b;
        } else {
          return (com.google.protobuf.ByteString) ref;
        }
      }
      /**
       * <code>optional string message = 1;</code>
       */
      public Builder setMessage(
          java.lang.String value) {
        if (value == null) {
    throw new NullPointerException();
  }
  
        message_ = value;
        onChanged();
        return this;
      }
      /**
       * <code>optional string message = 1;</code>
       */
      public Builder clearMessage() {
        
        message_ = getDefaultInstance().getMessage();
        onChanged();
        return this;
      }
      /**
       * <code>optional string message = 1;</code>
       */
      public Builder setMessageBytes(
          com.google.protobuf.ByteString value) {
        if (value == null) {
    throw new NullPointerException();
  }
  
        message_ = value;
        onChanged();
        return this;
      }
      public final Builder setUnknownFields(
          final com.google.protobuf.UnknownFieldSet unknownFields) {
        return this;
      }

      public final Builder mergeUnknownFields(
          final com.google.protobuf.UnknownFieldSet unknownFields) {
        return this;
      }


      // @@protoc_insertion_point(builder_scope:helloworld.HelloReply)
    }

    // @@protoc_insertion_point(class_scope:helloworld.HelloReply)
    private static final ex.grpc.Helloworld.HelloReply defaultInstance;static {
      defaultInstance = new ex.grpc.Helloworld.HelloReply();
    }

    public static ex.grpc.Helloworld.HelloReply getDefaultInstance() {
      return defaultInstance;
    }

    public ex.grpc.Helloworld.HelloReply getDefaultInstanceForType() {
      return defaultInstance;
    }

  }

  private static final com.google.protobuf.Descriptors.Descriptor
    internal_static_helloworld_HelloRequest_descriptor;
  private static
    com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internal_static_helloworld_HelloRequest_fieldAccessorTable;
  private static final com.google.protobuf.Descriptors.Descriptor
    internal_static_helloworld_HelloReply_descriptor;
  private static
    com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internal_static_helloworld_HelloReply_fieldAccessorTable;

  public static com.google.protobuf.Descriptors.FileDescriptor
      getDescriptor() {
    return descriptor;
  }
  private static com.google.protobuf.Descriptors.FileDescriptor
      descriptor;
  static {
    java.lang.String[] descriptorData = {
      "\n\037src/main/proto/helloworld.proto\022\nhello" +
      "world\"\034\n\014HelloRequest\022\014\n\004name\030\001 \001(\t\"\035\n\nH" +
      "elloReply\022\017\n\007message\030\001 \001(\t2H\n\tGreetings\022" +
      ";\n\005hello\022\030.helloworld.HelloRequest\032\026.hel" +
      "loworld.HelloReply\"\000B\t\n\007ex.grpcb\006proto3"
    };
    com.google.protobuf.Descriptors.FileDescriptor.InternalDescriptorAssigner assigner =
        new com.google.protobuf.Descriptors.FileDescriptor.    InternalDescriptorAssigner() {
          public com.google.protobuf.ExtensionRegistry assignDescriptors(
              com.google.protobuf.Descriptors.FileDescriptor root) {
            descriptor = root;
            return null;
          }
        };
    com.google.protobuf.Descriptors.FileDescriptor
      .internalBuildGeneratedFileFrom(descriptorData,
        new com.google.protobuf.Descriptors.FileDescriptor[] {
        }, assigner);
    internal_static_helloworld_HelloRequest_descriptor =
      getDescriptor().getMessageTypes().get(0);
    internal_static_helloworld_HelloRequest_fieldAccessorTable = new
      com.google.protobuf.GeneratedMessage.FieldAccessorTable(
        internal_static_helloworld_HelloRequest_descriptor,
        new java.lang.String[] { "Name", });
    internal_static_helloworld_HelloReply_descriptor =
      getDescriptor().getMessageTypes().get(1);
    internal_static_helloworld_HelloReply_fieldAccessorTable = new
      com.google.protobuf.GeneratedMessage.FieldAccessorTable(
        internal_static_helloworld_HelloReply_descriptor,
        new java.lang.String[] { "Message", });
  }

  // @@protoc_insertion_point(outer_class_scope)
}
