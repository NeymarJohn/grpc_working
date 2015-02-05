<?php
// DO NOT EDIT! Generated by Protobuf-PHP protoc plugin 1.0
// Source: test/cpp/interop/test.proto
//   Date: 2015-01-30 21:44:54

namespace grpc\testing {

  class TestServiceClient extends \Grpc\BaseStub {
    /**
     * @param grpc\testing\EmptyMessage $input
     * @return grpc\testing\EmptyMessage
     */
    public function EmptyCall(\grpc\testing\EmptyMessage $argument, $metadata = array()) {
      return $this->_simpleRequest('/grpc.testing.TestService/EmptyCall', $argument, '\grpc\testing\EmptyMessage::deserialize', $metadata);
    }
    /**
     * @param grpc\testing\SimpleRequest $input
     * @return grpc\testing\SimpleResponse
     */
    public function UnaryCall(\grpc\testing\SimpleRequest $argument, $metadata = array()) {
      return $this->_simpleRequest('/grpc.testing.TestService/UnaryCall', $argument, '\grpc\testing\SimpleResponse::deserialize', $metadata);
    }
    /**
     * @param grpc\testing\StreamingOutputCallRequest $input
     * @return grpc\testing\StreamingOutputCallResponse
     */
    public function StreamingOutputCall($argument, $metadata = array()) {
      return $this->_serverStreamRequest('/grpc.testing.TestService/StreamingOutputCall', $argument, '\grpc\testing\StreamingOutputCallResponse::deserialize', $metadata);
    }
    /**
     * @param grpc\testing\StreamingInputCallRequest $input
     * @return grpc\testing\StreamingInputCallResponse
     */
    public function StreamingInputCall($arguments, $metadata = array()) {
      return $this->_clientStreamRequest('/grpc.testing.TestService/StreamingInputCall', $arguments, '\grpc\testing\StreamingInputCallResponse::deserialize', $metadata);
    }
    /**
     * @param grpc\testing\StreamingOutputCallRequest $input
     * @return grpc\testing\StreamingOutputCallResponse
     */
    public function FullDuplexCall($metadata = array()) {
      return $this->_bidiRequest('/grpc.testing.TestService/FullDuplexCall', '\grpc\testing\StreamingOutputCallResponse::deserialize', $metadata);
    }
    /**
     * @param grpc\testing\StreamingOutputCallRequest $input
     * @return grpc\testing\StreamingOutputCallResponse
     */
    public function HalfDuplexCall($metadata = array()) {
      return $this->_bidiRequest('/grpc.testing.TestService/HalfDuplexCall', '\grpc\testing\StreamingOutputCallResponse::deserialize', $metadata);
    }
  }
}
