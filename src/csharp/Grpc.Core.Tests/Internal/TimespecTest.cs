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
using System.Runtime.InteropServices;
using Grpc.Core.Internal;
using NUnit.Framework;

namespace Grpc.Core.Internal.Tests
{
    public class TimespecTest
    {
        [Test]
        public void Now_IsInUtc() 
        {
            Assert.AreEqual(DateTimeKind.Utc, Timespec.Now.ToDateTime().Kind);
        }

        [Test]
        public void Now_AgreesWithUtcNow()
        {
            var timespec = Timespec.Now;
            var utcNow = DateTime.UtcNow;

            TimeSpan difference = utcNow - timespec.ToDateTime();

            // This test is inherently a race - but the two timestamps
            // should really be way less that a minute apart.
            Assert.IsTrue(difference.TotalSeconds < 60);
        }

        [Test]
        public void InfFuture()
        {
            var timespec = Timespec.InfFuture;
        }

        [Test]
        public void InfPast()
        {
            var timespec = Timespec.InfPast;
        }

        [Test]
        public void TimespecSizeIsNativeSize()
        {
            Assert.AreEqual(Timespec.NativeSize, Marshal.SizeOf(typeof(Timespec)));
        }

        [Test]
        public void ToDateTime()
        {
            Assert.AreEqual(new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                new Timespec(IntPtr.Zero, 0).ToDateTime());

            Assert.AreEqual(new DateTime(1970, 1, 1, 0, 0, 10, DateTimeKind.Utc).AddTicks(50),
                new Timespec(new IntPtr(10), 5000).ToDateTime());

            Assert.AreEqual(new DateTime(2015, 7, 21, 4, 21, 48, DateTimeKind.Utc),
                new Timespec(new IntPtr(1437452508), 0).ToDateTime());

            // before epoch
            Assert.AreEqual(new DateTime(1969, 12, 31, 23, 59, 55, DateTimeKind.Utc).AddTicks(10),
                new Timespec(new IntPtr(-5), 1000).ToDateTime());
        }

        [Test]
        public void ToDateTime_RoundUp()
        {
            Assert.AreEqual(new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddTicks(1),
                new Timespec(IntPtr.Zero, 99).ToDateTime());
        }

        [Test]
        public void ToDateTime_WrongInputs()
        {
            Assert.Throws(typeof(InvalidOperationException),
                () => new Timespec(new IntPtr(0), -2).ToDateTime());
            Assert.Throws(typeof(InvalidOperationException),
                () => new Timespec(new IntPtr(0), 1000 * 1000 * 1000).ToDateTime());
            Assert.Throws(typeof(InvalidOperationException),
                () => new Timespec(new IntPtr(0), 0, GPRClockType.Monotonic).ToDateTime());
        }

        [Test]
        public void ToDateTime_ReturnsUtc()
        {
            Assert.AreEqual(DateTimeKind.Utc, new Timespec(new IntPtr(1437452508), 0).ToDateTime().Kind);
            Assert.AreNotEqual(DateTimeKind.Unspecified, new Timespec(new IntPtr(1437452508), 0).ToDateTime().Kind);
        }

        [Test]
        public void ToDateTime_Infinity()
        {
            Assert.AreEqual(DateTime.MaxValue, Timespec.InfFuture.ToDateTime());
            Assert.AreEqual(DateTime.MinValue, Timespec.InfPast.ToDateTime());
        }

        [Test]
        public void ToDateTime_OverflowGivesMaxOrMinVal()
        {
            // we can only get overflow in ticks arithmetic on 64-bit
            if (IntPtr.Size == 8)
            {
                var timespec = new Timespec(new IntPtr(long.MaxValue - 100), 0);
                Assert.AreNotEqual(Timespec.InfFuture, timespec);
                Assert.AreEqual(DateTime.MaxValue, timespec.ToDateTime());

                Assert.AreEqual(DateTime.MinValue, new Timespec(new IntPtr(long.MinValue + 100), 0).ToDateTime());
            }
            else
            {
                Console.WriteLine("Test cannot be run on this platform, skipping the test.");
            }
        }

        [Test]
        public void ToDateTime_OutOfRangeGivesMaxOrMinVal()
        {
            // we can only get out of range on 64-bit, on 32 bit the max 
            // timestamp is ~ Jan 19 2038, which is far within range of DateTime
            // same case for min value.
            if (IntPtr.Size == 8)
            {
                // DateTime range goes up to year 9999, 20000 years from now should
                // be out of range.
                long seconds = 20000L * 365L * 24L * 3600L; 

                var timespec = new Timespec(new IntPtr(seconds), 0);
                Assert.AreNotEqual(Timespec.InfFuture, timespec);
                Assert.AreEqual(DateTime.MaxValue, timespec.ToDateTime());

                Assert.AreEqual(DateTime.MinValue, new Timespec(new IntPtr(-seconds), 0).ToDateTime());
            }
            else
            {
                Console.WriteLine("Test cannot be run on this platform, skipping the test");
            }
        }
    }
}
