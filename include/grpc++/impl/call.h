/*
 *
 * Copyright 2015, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef __GRPCPP_CALL_H__
#define __GRPCPP_CALL_H__

#include <grpc/grpc.h>
#include <grpc++/status.h>
#include <grpc++/completion_queue.h>

#include <memory>
#include <map>

namespace google {
namespace protobuf {
class Message;
}  // namespace protobuf
}  // namespace google

struct grpc_call;
struct grpc_op;

namespace grpc {

class Call;

class CallOpBuffer : public CompletionQueueTag {
 public:
  CallOpBuffer() : return_tag_(this) {}
  ~CallOpBuffer();

  void Reset(void *next_return_tag);

  // Does not take ownership.
  void AddSendInitialMetadata(
      std::multimap<grpc::string, grpc::string> *metadata);
  void AddSendInitialMetadata(ClientContext *ctx);
  void AddRecvInitialMetadata(ClientContext* ctx);
  void AddSendMessage(const google::protobuf::Message &message);
  void AddRecvMessage(google::protobuf::Message *message);
  void AddClientSendClose();
  void AddClientRecvStatus(ClientContext *ctx, Status *status);
  void AddServerSendStatus(std::multimap<grpc::string, grpc::string> *metadata,
                           const Status &status);
  void AddServerRecvClose(bool *cancelled);

  // INTERNAL API:

  // Convert to an array of grpc_op elements
  void FillOps(grpc_op *ops, size_t *nops);

  // Called by completion queue just prior to returning from Next() or Pluck()
  void FinalizeResult(void **tag, bool *status) override;

  bool got_message = false;

 private:
  void *return_tag_ = nullptr;
  // Send initial metadata
  bool send_initial_metadata_ = false;
  size_t initial_metadata_count_ = 0;
  grpc_metadata *initial_metadata_ = nullptr;
  // Recv initial metadta
  std::multimap<grpc::string, grpc::string> *recv_initial_metadata_ = nullptr;
  grpc_metadata_array recv_initial_metadata_arr_ = {0, 0, nullptr};
  // Send message
  const google::protobuf::Message *send_message_ = nullptr;
  grpc_byte_buffer *send_message_buf_ = nullptr;
  // Recv message
  google::protobuf::Message *recv_message_ = nullptr;
  grpc_byte_buffer *recv_message_buf_ = nullptr;
  // Client send close
  bool client_send_close_ = false;
  // Client recv status
  std::multimap<grpc::string, grpc::string> *recv_trailing_metadata_ = nullptr;
  Status *recv_status_ = nullptr;
  grpc_metadata_array recv_trailing_metadata_arr_ = {0, 0, nullptr};
  grpc_status_code status_code_ = GRPC_STATUS_OK;
  char *status_details_ = nullptr;
  size_t status_details_capacity_ = 0;
  // Server send status
  const Status *send_status_ = nullptr;
  size_t trailing_metadata_count_ = 0;
  grpc_metadata *trailing_metadata_ = nullptr;
  int cancelled_buf_;
  bool *recv_closed_ = nullptr;
};

// Channel and Server implement this to allow them to hook performing ops
class CallHook {
 public:
  virtual ~CallHook() {}
  virtual void PerformOpsOnCall(CallOpBuffer *ops, Call *call) = 0;
};

// Straightforward wrapping of the C call object
class Call final {
 public:
  /* call is owned by the caller */
  Call(grpc_call *call, CallHook *call_hook_, CompletionQueue *cq);

  void PerformOps(CallOpBuffer *buffer);

  grpc_call *call() { return call_; }
  CompletionQueue *cq() { return cq_; }

 private:
  CallHook *call_hook_;
  CompletionQueue *cq_;
  grpc_call *call_;
};

}  // namespace grpc

#endif  // __GRPCPP_CALL_INTERFACE_H__
