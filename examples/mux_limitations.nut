// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#require "MCP3208.device.lib.nut:1.0.0"

/***
* This is an example of the hardware limitations of the device. A function which reads
* two channels consecutively is called recursively with the time between reads reduced
* with each call in order to show how quickly the ADC mux can switch between channels
* while keeping reads accurate
***/

function testFastChannelSwitch() {
    // ch. 0 should be 3.3v, ch. 1 should be 0 v
    local spi = hardware.spi0;
    spi.configure(USE_CS_L | CLOCK_IDLE_LOW | MSB_FIRST, 50);
    local _adc = MCP3208(spi, 3.3);
    _vref = 3.3;
    fastSwitch(1, _vref, _adc);
}

function fastSwitch(delayTime, vref, adc) {
    local ch0 = adc.readADC(MCP3208_CHANNEL_0);
    imp.sleep(delayTime);
    local ch1 = adc.readADC(MCP3208_CHANNEL_1);
    if(ch1 >= 0 && ch1 <= 0.05 && ch0 >= 3.25 && ch0 <= 3.3) {
        // call recursively until there is too much error
        fastSwitch(delayTime/10.0, vref, adc);
    } else {
        server.log("error at delay time " + delayTime);
        server.log(format("received %f on ch0 and %f on ch1", ch0, ch1));
    }
}

testFastChannelSwitch();
