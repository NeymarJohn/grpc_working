#region Copyright notice and license

// Copyright 2015-2016, Google Inc.
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
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Google.Protobuf;
using Grpc.Core;
using Grpc.Core.Logging;
using Grpc.Core.Utils;
using NUnit.Framework;
using Grpc.Testing;

namespace Grpc.IntegrationTesting
{
    /// <summary>
    /// Helper methods to start client runners for performance testing.
    /// </summary>
    public class ClientRunners
    {
        static readonly ILogger Logger = GrpcEnvironment.Logger.ForType<ClientRunners>();

        /// <summary>
        /// Creates a started client runner.
        /// </summary>
        public static IClientRunner CreateStarted(ClientConfig config)
        {
            Logger.Debug("ClientConfig: {0}", config);
            string target = config.ServerTargets.Single();
            GrpcPreconditions.CheckArgument(config.LoadParams.LoadCase == LoadParams.LoadOneofCase.ClosedLoop,
                "Only closed loop scenario supported for C#");
            GrpcPreconditions.CheckArgument(config.ClientType == ClientType.SYNC_CLIENT,
                "Only sync client support for C#");
            GrpcPreconditions.CheckArgument(config.ClientChannels == 1, "ClientConfig.ClientChannels needs to be 1");

            if (config.OutstandingRpcsPerChannel != 0)
            {
                Logger.Warning("ClientConfig.OutstandingRpcsPerChannel is not supported for C#. Ignoring the value");
            }
            if (config.AsyncClientThreads != 0)
            {
                Logger.Warning("ClientConfig.AsyncClientThreads is not supported for C#. Ignoring the value");
            }
            if (config.CoreLimit != 0)
            {
                Logger.Warning("ClientConfig.CoreLimit is not supported for C#. Ignoring the value");
            }
            if (config.CoreList.Count > 0)
            {
                Logger.Warning("ClientConfig.CoreList is not supported for C#. Ignoring the value");
            }

            var credentials = config.SecurityParams != null ? TestCredentials.CreateSslCredentials() : ChannelCredentials.Insecure;
            List<ChannelOption> channelOptions = null;
            if (config.SecurityParams != null && config.SecurityParams.ServerHostOverride != "")
            {
                channelOptions = new List<ChannelOption>
                {
                    new ChannelOption(ChannelOptions.SslTargetNameOverride, config.SecurityParams.ServerHostOverride)
                };
            }
            var channel = new Channel(target, credentials, channelOptions);

            switch (config.RpcType)
            {
                case RpcType.UNARY:
                    return new SyncUnaryClientRunner(channel,
                        config.PayloadConfig.SimpleParams,
                        config.HistogramParams);

                case RpcType.STREAMING:
                default:
                    throw new ArgumentException("Unsupported RpcType.");
            }
        }
    }

    /// <summary>
    /// Client that starts synchronous unary calls in a closed loop.
    /// </summary>
    public class SyncUnaryClientRunner : IClientRunner
    {
        const double SecondsToNanos = 1e9;

        readonly Channel channel;
        readonly SimpleProtoParams payloadParams;
        readonly Histogram histogram;

        readonly BenchmarkService.IBenchmarkServiceClient client;
        readonly Task runnerTask;
        readonly CancellationTokenSource stoppedCts;
        readonly WallClockStopwatch wallClockStopwatch = new WallClockStopwatch();
        
        public SyncUnaryClientRunner(Channel channel, SimpleProtoParams payloadParams, HistogramParams histogramParams)
        {
            this.channel = GrpcPreconditions.CheckNotNull(channel);
            this.histogram = new Histogram(histogramParams.Resolution, histogramParams.MaxPossible);

            this.stoppedCts = new CancellationTokenSource();
            this.client = BenchmarkService.NewClient(channel);
            this.runnerTask = Task.Factory.StartNew(Run, TaskCreationOptions.LongRunning);
        }

        public ClientStats GetStats(bool reset)
        {
            var histogramData = histogram.GetSnapshot(reset);
            var secondsElapsed = wallClockStopwatch.GetElapsedSnapshot(reset).TotalSeconds;

            // TODO: populate user time and system time
            return new ClientStats
            {
                Latencies = histogramData,
                TimeElapsed = secondsElapsed,
                TimeUser = 0,
                TimeSystem = 0
            };
        }

        public async Task StopAsync()
        {
            stoppedCts.Cancel();
            await runnerTask;
            await channel.ShutdownAsync();
        }

        private void Run()
        {
            var request = new SimpleRequest
            {
                Payload = CreateZerosPayload(payloadParams.ReqSize),
                ResponseSize = payloadParams.RespSize
            };
            var stopwatch = new Stopwatch();

            while (!stoppedCts.Token.IsCancellationRequested)
            {
                stopwatch.Restart();
                client.UnaryCall(request);
                stopwatch.Stop();

                // spec requires data point in nanoseconds.
                histogram.AddObservation(stopwatch.Elapsed.TotalSeconds * SecondsToNanos);
            }
        }

        private static Payload CreateZerosPayload(int size)
        {
            return new Payload { Body = ByteString.CopyFrom(new byte[size]) };
        }
    }
}
