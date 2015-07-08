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

#include "src/cpp/common/secure_auth_context.h"

#include "src/core/security/security_context.h"

namespace grpc {

SecureAuthContext::SecureAuthContext(grpc_auth_context* ctx)
    : ctx_(GRPC_AUTH_CONTEXT_REF(ctx, "SecureAuthContext")) {}

SecureAuthContext::~SecureAuthContext() {
  GRPC_AUTH_CONTEXT_UNREF(ctx_, "SecureAuthContext");
}

std::vector<grpc::string> SecureAuthContext::GetPeerIdentity() const {
  if (!ctx_) {
    return std::vector<grpc::string>();
  }
  grpc_auth_property_iterator iter = grpc_auth_context_peer_identity(ctx_);
  std::vector<grpc::string> identity;
  const grpc_auth_property* property = nullptr;
  while ((property = grpc_auth_property_iterator_next(&iter))) {
    identity.push_back(grpc::string(property->value, property->value_length));
  }
  return identity;
}

grpc::string SecureAuthContext::GetPeerIdentityPropertyName() const {
  if (!ctx_) {
    return "";
  }
  const char* name = grpc_auth_context_peer_identity_property_name(ctx_);
  return name == nullptr ? "" : name;
}

std::vector<grpc::string> SecureAuthContext::FindPropertyValues(
    const grpc::string& name) const {
  if (!ctx_) {
    return std::vector<grpc::string>();
  }
  grpc_auth_property_iterator iter =
      grpc_auth_context_find_properties_by_name(ctx_, name.c_str());
  const grpc_auth_property* property = nullptr;
  std::vector<grpc::string> values;
  while ((property = grpc_auth_property_iterator_next(&iter))) {
    values.push_back(grpc::string(property->value, property->value_length));
  }
  return values;
}

}  // namespace grpc
