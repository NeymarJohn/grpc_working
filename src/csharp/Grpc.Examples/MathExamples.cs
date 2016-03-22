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
using System.Threading.Tasks;
using Grpc.Core.Utils;

namespace Math
{
    public static class MathExamples
    {
        public static void DivExample(Math.MathClientBase client)
        {
            DivReply result = client.Div(new DivArgs { Dividend = 10, Divisor = 3 });
            Console.WriteLine("Div Result: " + result);
        }

        public static async Task DivAsyncExample(Math.MathClientBase client)
        {
            DivReply result = await client.DivAsync(new DivArgs { Dividend = 4, Divisor = 5 });
            Console.WriteLine("DivAsync Result: " + result);
        }

        public static async Task FibExample(Math.MathClientBase client)
        {
            using (var call = client.Fib(new FibArgs { Limit = 5 }))
            {
                List<Num> result = await call.ResponseStream.ToListAsync();
                Console.WriteLine("Fib Result: " + string.Join("|", result));
            }
        }

        public static async Task SumExample(Math.MathClientBase client)
        {
            var numbers = new List<Num>
            {
                new Num { Num_ = 1 },
                new Num { Num_ = 2 },
                new Num { Num_ = 3 }
            };

            using (var call = client.Sum())
            {
                await call.RequestStream.WriteAllAsync(numbers);
                Console.WriteLine("Sum Result: " + await call.ResponseAsync);
            }
        }

        public static async Task DivManyExample(Math.MathClientBase client)
        {
            var divArgsList = new List<DivArgs>
            {
                new DivArgs { Dividend = 10, Divisor = 3 },
                new DivArgs { Dividend = 100, Divisor = 21 },
                new DivArgs { Dividend = 7, Divisor = 2 }
            };
            using (var call = client.DivMany())
            { 
                await call.RequestStream.WriteAllAsync(divArgsList);
                Console.WriteLine("DivMany Result: " + string.Join("|", await call.ResponseStream.ToListAsync()));
            }
        }

        public static async Task DependendRequestsExample(Math.MathClientBase client)
        {
            var numbers = new List<Num>
            {
                new Num { Num_ = 1 }, 
                new Num { Num_ = 2 },
                new Num { Num_ = 3 }
            };

            Num sum;
            using (var sumCall = client.Sum())
            {
                await sumCall.RequestStream.WriteAllAsync(numbers);
                sum = await sumCall.ResponseAsync;
            }

            DivReply result = await client.DivAsync(new DivArgs { Dividend = sum.Num_, Divisor = numbers.Count });
            Console.WriteLine("Avg Result: " + result);
        }
    }
}
