#region Copyright notice and license
// Copyright 2015, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#endregion

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;

using Grpc.Core.Internal;
using Grpc.Core.Logging;
using Grpc.Core.Utils;

namespace Grpc.Core
{
    /// <summary>
    /// Represents a gRPC channel. Channels are an abstraction of long-lived connections to remote servers.
    /// More client objects can reuse the same channel. Creating a channel is an expensive operation compared to invoking
    /// a remote call so in general you should reuse a single channel for as many calls as possible.
    /// </summary>
    public class Channel
    {
        static readonly ILogger Logger = GrpcEnvironment.Logger.ForType<Channel>();

        readonly object myLock = new object();
        readonly AtomicCounter activeCallCounter = new AtomicCounter();

        readonly string target;
        readonly GrpcEnvironment environment;
        readonly ChannelSafeHandle handle;
        readonly List<ChannelOption> options;

        bool shutdownRequested;

        /// <summary>
        /// Creates a channel that connects to a specific host.
        /// Port will default to 80 for an unsecure channel and to 443 for a secure channel.
        /// </summary>
        /// <param name="target">Target of the channel.</param>
        /// <param name="credentials">Credentials to secure the channel.</param>
        /// <param name="options">Channel options.</param>
        public Channel(string target, ChannelCredentials credentials, IEnumerable<ChannelOption> options = null)
        {
            this.target = Preconditions.CheckNotNull(target, "target");
            this.environment = GrpcEnvironment.AddRef();
            this.options = options != null ? new List<ChannelOption>(options) : new List<ChannelOption>();

            EnsureUserAgentChannelOption(this.options);
            using (var nativeCredentials = credentials.ToNativeCredentials())
            using (var nativeChannelArgs = ChannelOptions.CreateChannelArgs(this.options))
            {
                if (nativeCredentials != null)
                {
                    this.handle = ChannelSafeHandle.CreateSecure(nativeCredentials, target, nativeChannelArgs);
                }
                else
                {
                    this.handle = ChannelSafeHandle.CreateInsecure(target, nativeChannelArgs);
                }
            }
        }

        /// <summary>
        /// Creates a channel that connects to a specific host and port.
        /// </summary>
        /// <param name="host">The name or IP address of the host.</param>
        /// <param name="port">The port.</param>
        /// <param name="credentials">Credentials to secure the channel.</param>
        /// <param name="options">Channel options.</param>
        public Channel(string host, int port, ChannelCredentials credentials, IEnumerable<ChannelOption> options = null) :
            this(string.Format("{0}:{1}", host, port), credentials, options)
        {
        }

        /// <summary>
        /// Gets current connectivity state of this channel.
        /// </summary>
        public ChannelState State
        {
            get
            {
                return handle.CheckConnectivityState(false);        
            }
        }

        /// <summary>
        /// Returned tasks completes once channel state has become different from 
        /// given lastObservedState. 
        /// If deadline is reached or and error occurs, returned task is cancelled.
        /// </summary>
        public Task WaitForStateChangedAsync(ChannelState lastObservedState, DateTime? deadline = null)
        {
            Preconditions.CheckArgument(lastObservedState != ChannelState.FatalFailure,
                "FatalFailure is a terminal state. No further state changes can occur.");
            var tcs = new TaskCompletionSource<object>();
            var deadlineTimespec = deadline.HasValue ? Timespec.FromDateTime(deadline.Value) : Timespec.InfFuture;
            var handler = new BatchCompletionDelegate((success, ctx) =>
            {
                if (success)
                {
                    tcs.SetResult(null);
                }
                else
                {
                    tcs.SetCanceled();
                }
            });
            handle.WatchConnectivityState(lastObservedState, deadlineTimespec, environment.CompletionQueue, environment.CompletionRegistry, handler);
            return tcs.Task;
        }

        /// <summary>Resolved address of the remote endpoint in URI format.</summary>
        public string ResolvedTarget
        {
            get
            {
                return handle.GetTarget();
            }
        }

        /// <summary>The original target used to create the channel.</summary>
        public string Target
        {
            get
            {
                return this.target;
            }
        }

        /// <summary>
        /// Allows explicitly requesting channel to connect without starting an RPC.
        /// Returned task completes once state Ready was seen. If the deadline is reached,
        /// or channel enters the FatalFailure state, the task is cancelled.
        /// There is no need to call this explicitly unless your use case requires that.
        /// Starting an RPC on a new channel will request connection implicitly.
        /// </summary>
        /// <param name="deadline">The deadline. <c>null</c> indicates no deadline.</param>
        public async Task ConnectAsync(DateTime? deadline = null)
        {
            var currentState = handle.CheckConnectivityState(true);
            while (currentState != ChannelState.Ready)
            {
                if (currentState == ChannelState.FatalFailure)
                {
                    throw new OperationCanceledException("Channel has reached FatalFailure state.");
                }
                await WaitForStateChangedAsync(currentState, deadline);
                currentState = handle.CheckConnectivityState(false);
            }
        }

        /// <summary>
        /// Waits until there are no more active calls for this channel and then cleans up
        /// resources used by this channel.
        /// </summary>
        public async Task ShutdownAsync()
        {
            lock (myLock)
            {
                Preconditions.CheckState(!shutdownRequested);
                shutdownRequested = true;
            }

            var activeCallCount = activeCallCounter.Count;
            if (activeCallCount > 0)
            {
                Logger.Warning("Channel shutdown was called but there are still {0} active calls for that channel.", activeCallCount);
            }

            handle.Dispose();

            await Task.Run(() => GrpcEnvironment.Release());
        }

        internal ChannelSafeHandle Handle
        {
            get
            {
                return this.handle;
            }
        }

        internal GrpcEnvironment Environment
        {
            get
            {
                return this.environment;
            }
        }

        internal void AddCallReference(object call)
        {
            activeCallCounter.Increment();

            bool success = false;
            handle.DangerousAddRef(ref success);
            Preconditions.CheckState(success);
        }

        internal void RemoveCallReference(object call)
        {
            handle.DangerousRelease();

            activeCallCounter.Decrement();
        }

        private static void EnsureUserAgentChannelOption(List<ChannelOption> options)
        {
            if (!options.Any((option) => option.Name == ChannelOptions.PrimaryUserAgentString))
            {
                options.Add(new ChannelOption(ChannelOptions.PrimaryUserAgentString, GetUserAgentString()));
            }
        }

        private static string GetUserAgentString()
        {
            // TODO(jtattermusch): it would be useful to also provide .NET/mono version.
            return string.Format("grpc-csharp/{0}", VersionInfo.CurrentVersion);
        }
    }
}
