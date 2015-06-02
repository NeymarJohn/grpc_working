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

#ifndef NET_GRPC_NODE_CHANNEL_H_
#define NET_GRPC_NODE_CHANNEL_H_

#include <node.h>
#include <nan.h>
#include "grpc/grpc.h"

namespace grpc {
namespace node {

/* Wrapper class for grpc_channel structs */
class Channel : public ::node::ObjectWrap {
 public:
  static void Init(v8::Handle<v8::Object> exports);
  static bool HasInstance(v8::Handle<v8::Value> val);
  /* This is used to typecheck javascript objects before converting them to
     this type */
  static v8::Persistent<v8::Value> prototype;

  /* Returns the grpc_channel struct that this object wraps */
  grpc_channel *GetWrappedChannel();

  /* Return the hostname that this channel connects to */
  char *GetHost();

 private:
  explicit Channel(grpc_channel *channel, NanUtf8String *host);
  ~Channel();

  // Prevent copying
  Channel(const Channel &);
  Channel &operator=(const Channel &);

  static NAN_METHOD(New);
  static NAN_METHOD(Close);
  static NanCallback *constructor;
  static v8::Persistent<v8::FunctionTemplate> fun_tpl;

  grpc_channel *wrapped_channel;
  NanUtf8String *host;
};

}  // namespace node
}  // namespace grpc

#endif  // NET_GRPC_NODE_CHANNEL_H_
