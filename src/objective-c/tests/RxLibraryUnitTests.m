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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <gRPC/GRXBufferedPipe.h>
#import <gRPC/GRXWriter.h>
#import <gRPC/GRXWriteable.h>

// A mock of a GRXSingleValueHandler block that can be queried for how many times it was called and
// what were the last values passed to it.
//
// TODO(jcanizales): Move this to a test util library, and add tests for it.
@interface CapturingSingleValueHandler : NSObject
@property (nonatomic, readonly) void (^block)(id value, NSError *errorOrNil);
@property (nonatomic, readonly) NSUInteger timesCalled;
@property (nonatomic, readonly) id value;
@property (nonatomic, readonly) NSError *errorOrNil;
+ (instancetype)handler;
@end

@implementation CapturingSingleValueHandler
+ (instancetype)handler {
  return [[self alloc] init];
}

- (GRXSingleValueHandler)block {
  return ^(id value, NSError *errorOrNil) {
    ++_timesCalled;
    _value = value;
    _errorOrNil = errorOrNil;
  };
}
@end

@interface RxLibraryUnitTests : XCTestCase
@end

@implementation RxLibraryUnitTests

#pragma mark Writeable

- (void)testWriteableSingleValueHandlerIsCalledForValue {
  // Given:
  CapturingSingleValueHandler *handler = [CapturingSingleValueHandler handler];
  id anyValue = @7;

  // If:
  id<GRXWriteable> writeable = [GRXWriteable writeableWithSingleValueHandler:handler.block];
  [writeable writeValue:anyValue];

  // Then:
  XCTAssertEqual(handler.timesCalled, 1);
  XCTAssertEqualObjects(handler.value, anyValue);
  XCTAssertEqualObjects(handler.errorOrNil, nil);
}

- (void)testWriteableSingleValueHandlerIsCalledForError {
  // Given:
  CapturingSingleValueHandler *handler = [CapturingSingleValueHandler handler];
  NSError *anyError = [NSError errorWithDomain:@"domain" code:7 userInfo:nil];

  // If:
  id<GRXWriteable> writeable = [GRXWriteable writeableWithSingleValueHandler:handler.block];
  [writeable writesFinishedWithError:anyError];

  // Then:
  XCTAssertEqual(handler.timesCalled, 1);
  XCTAssertEqualObjects(handler.value, nil);
  XCTAssertEqualObjects(handler.errorOrNil, anyError);
}

#pragma mark BufferedPipe

- (void)testBufferedPipePropagatesValue {
  // Given:
  CapturingSingleValueHandler *handler = [CapturingSingleValueHandler handler];
  id<GRXWriteable> writeable = [GRXWriteable writeableWithSingleValueHandler:handler.block];
  id anyValue = @7;

  // If:
  GRXBufferedPipe *pipe = [GRXBufferedPipe pipe];
  [pipe startWithWriteable:writeable];
  [pipe writeValue:anyValue];

  // Then:
  XCTAssertEqual(handler.timesCalled, 1);
  XCTAssertEqualObjects(handler.value, anyValue);
  XCTAssertEqualObjects(handler.errorOrNil, nil);
}

- (void)testBufferedPipePropagatesError {
  // Given:
  CapturingSingleValueHandler *handler = [CapturingSingleValueHandler handler];
  id<GRXWriteable> writeable = [GRXWriteable writeableWithSingleValueHandler:handler.block];
  NSError *anyError = [NSError errorWithDomain:@"domain" code:7 userInfo:nil];

  // If:
  GRXBufferedPipe *pipe = [GRXBufferedPipe pipe];
  [pipe startWithWriteable:writeable];
  [pipe writesFinishedWithError:anyError];

  // Then:
  XCTAssertEqual(handler.timesCalled, 1);
  XCTAssertEqualObjects(handler.value, nil);
  XCTAssertEqualObjects(handler.errorOrNil, anyError);
}

@end
