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

'use strict';

var fs = require('fs');
var path = require('path');
var async = require('async');
var _ = require('lodash');
var grpc = require('..');
var testProto = grpc.load({
  root: __dirname + '/../../..',
  file: 'test/proto/test.proto'}).grpc.testing;

var ECHO_INITIAL_KEY = 'x-grpc-test-echo-initial';
var ECHO_TRAILING_KEY = 'x-grpc-test-echo-trailing-bin';

var incompressible_data = fs.readFileSync(
    __dirname + '/../../../test/cpp/interop/rnd.dat');

/**
 * Create a buffer filled with size zeroes
 * @param {number} size The length of the buffer
 * @return {Buffer} The new buffer
 */
function zeroBuffer(size) {
  var zeros = new Buffer(size);
  zeros.fill(0);
  return zeros;
}

/**
 * Echos a header metadata item as specified in the interop spec.
 * @param {Call} call The call to echo metadata on
 */
function echoHeader(call) {
  var echo_initial = call.metadata.get(ECHO_INITIAL_KEY);
  if (echo_initial.length > 0) {
    var response_metadata = new grpc.Metadata();
    response_metadata.set(ECHO_INITIAL_KEY, echo_initial[0]);
    call.sendMetadata(response_metadata);
  }
}

/**
 * Gets the trailer metadata that should be echoed when the call is done,
 * as specified in the interop spec.
 * @param {Call} call The call to get metadata from
 * @return {grpc.Metadata} The metadata to send as a trailer
 */
function getEchoTrailer(call) {
  var echo_trailer = call.metadata.get(ECHO_TRAILING_KEY);
  var response_trailer = new grpc.Metadata();
  if (echo_trailer.length > 0) {
    response_trailer.set(ECHO_TRAILING_KEY, echo_trailer[0]);
  }
  return response_trailer;
}

/**
 * @typedef Payload
 * @type {object}
 * @property {string} payload_type The payload type
 * @property {Buffer} body The payload body
 */

/**
 * Get a payload of the specified type and size. If the requested payload is
 * COMPRESSABLE, it returns a zero buffer. If the type is UNCOMRESSABLE, it
 * returns a slice of pre-loaded uncompressable data. If the type is RANDOM,
 * it returns one of the other choices, chosen at random.
 * @param {string} payload_type The type of payload to return
 * @param {Number} size The size of the payload body
 * @return {Payload} The requested payload
 */
function getPayload(payload_type, size) {
  if (payload_type === 'RANDOM') {
    payload_type = ['COMPRESSABLE',
                    'UNCOMPRESSABLE'][Math.random() < 0.5 ? 0 : 1];
  }
  var body;
  switch (payload_type) {
    case 'COMPRESSABLE': body = zeroBuffer(size); break;
    case 'UNCOMPRESSABLE': incompressible_data.slice(size); break;
  }
  return {type: payload_type, body: body};
}

function respondWithStream(call, request, callback) {
  async.eachSeries(request.response_parameters, function(resp_param, callback) {
    setTimeout(function() {
      call.write({payload: getPayload(request.response_type, resp_param.size)});
      callback();
    }, resp_param.interval_us/1000);
  }, callback);
}

/**
 * Respond to an empty parameter with an empty response.
 * NOTE: this currently does not work due to issue #137
 * @param {Call} call Call to handle
 * @param {function(Error, Object)} callback Callback to call with result
 *     or error
 */
function handleEmpty(call, callback) {
  echoHeader(call);
  callback(null, {}, getEchoTrailer(call));
}

/**
 * Handle a unary request by sending the requested payload
 * @param {Call} call Call to handle
 * @param {function(Error, Object)} callback Callback to call with result or
 *     error
 */
function handleUnary(call, callback) {
  echoHeader(call);
  var req = call.request;
  if (req.response_status) {
    var status = req.response_status;
    status.metadata = getEchoTrailer(call);
    callback(status);
    return;
  }
  var payload = getPayload(req.response_type, req.response_size);
  callback(null, {payload: payload},
           getEchoTrailer(call));
}

/**
 * Respond to a streaming call with the total size of all payloads
 * @param {Call} call Call to handle
 * @param {function(Error, Object)} callback Callback to call with result or
 *     error
 */
function handleStreamingInput(call, callback) {
  echoHeader(call);
  var aggregate_size = 0;
  call.on('data', function(value) {
    aggregate_size += value.payload.body.length;
  });
  call.on('end', function() {
    callback(null, {aggregated_payload_size: aggregate_size},
             getEchoTrailer(call));
  });
}

/**
 * Respond to a payload request with a stream of the requested payloads
 * @param {Call} call Call to handle
 */
function handleStreamingOutput(call) {
  echoHeader(call);
  var req = call.request;
  if (req.response_status) {
    var status = req.response_status;
    status.metadata = getEchoTrailer(call);
    call.emit('error', status);
    return;
  }
  respondWithStream(call, req, function(err) {
    if (err) {
      call.emit(err);
    } else {
      call.end(getEchoTrailer(call));
    }
  });
}

/**
 * Respond to a stream of payload requests with a stream of payload responses as
 * they arrive.
 * @param {Call} call Call to handle
 */
function handleFullDuplex(call) {
  echoHeader(call);
  var call_ended;
  call.on('data', function(value) {
    if (value.response_status) {
      var status = value.response_status;
      status.metadata = getEchoTrailer(call);
      call.emit('error', status);
      return;
    }
    call.pause();
    respondWithStream(call, value, function(err) {
      call.resume();
      if (call_ended) {
        call.end(getEchoTrailer(call));
      }
    });
  });
  call.on('end', function() {
    call_ended = true;

  });
}

/**
 * Respond to a stream of payload requests with a stream of payload responses
 * after all requests have arrived
 * @param {Call} call Call to handle
 */
function handleHalfDuplex(call) {
  call.emit('error', Error('HalfDuplexCall not yet implemented'));
}

/**
 * Get a server object bound to the given port
 * @param {string} port Port to which to bind
 * @param {boolean} tls Indicates that the bound port should use TLS
 * @return {{server: Server, port: number}} Server object bound to the support,
 *     and port number that the server is bound to
 */
function getServer(port, tls) {
  // TODO(mlumish): enable TLS functionality
  var options = {};
  var server_creds;
  if (tls) {
    var key_path = path.join(__dirname, '../test/data/server1.key');
    var pem_path = path.join(__dirname, '../test/data/server1.pem');

    var key_data = fs.readFileSync(key_path);
    var pem_data = fs.readFileSync(pem_path);
    server_creds = grpc.ServerCredentials.createSsl(null,
                                                    [{private_key: key_data,
                                                      cert_chain: pem_data}]);
  } else {
    server_creds = grpc.ServerCredentials.createInsecure();
  }
  var server = new grpc.Server(options);
  server.addProtoService(testProto.TestService.service, {
    emptyCall: handleEmpty,
    unaryCall: handleUnary,
    streamingOutputCall: handleStreamingOutput,
    streamingInputCall: handleStreamingInput,
    fullDuplexCall: handleFullDuplex,
    halfDuplexCall: handleHalfDuplex
  });
  var port_num = server.bind('0.0.0.0:' + port, server_creds);
  return {server: server, port: port_num};
}

if (require.main === module) {
  var parseArgs = require('minimist');
  var argv = parseArgs(process.argv, {
    string: ['port', 'use_tls']
  });
  var server_obj = getServer(argv.port, argv.use_tls === 'true');
  console.log('Server attaching to port ' + argv.port);
  server_obj.server.start();
}

/**
 * See docs for getServer
 */
exports.getServer = getServer;
