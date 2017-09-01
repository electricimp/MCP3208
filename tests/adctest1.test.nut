/***
MIT License

Copyright 2017 Electric Imp

SPDX-License-Identifier: MIT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

***/

// Tests written for Imp 005 with ADC connected to spiBCAD

class MyTestCase extends ImpTestCase {
    
    _adc = null;
    _vref = null;

    function setUp() {
        local spi = hardware.spiBCAD;
        local cs = hardware.pinD;
        spi.configure(CLOCK_IDLE_LOW | MSB_FIRST, 50);
        _vref = 3.3;
        _adc = MCP3208(spi, _vref, cs);
    }

    // Helper read function
    function takeADCReading(_adc, chan, ref, startTime, resolve, reject) {
        this.info("I'm starting at " + startTime);
        local read = _adc.readADC(chan);
        if(read >= 0 && read <= ref) {
            this.info("reading: " + read);
            this.info(format("it took %d uS to execute", hardware.micros() - startTime));
            resolve();
        } else {
            reject();
        }
    }

    function testWrongParameterToFunction() {
        for(local i = 10; i < 20; ++i) {
            local read = _adc.readADC(10);
            this.info(format("incorrect input to readADC yielded value %f", read));
            this.assertBetween(read, 0, _vref);
        }
    }

    function testValue() {
        local vals = array(8);
        for(local i = 0; i < 8; ++i) {
            vals[i] = _adc.readADC(i);
        }
        for(local i = 0; i < 8; ++i) {
            this.assertBetween(vals[i], 0, _vref);
        }
    }

    function testAsynchronous() {
        local th = this;
        local series = [
            @() Promise(@(resolve, reject) th.takeADCReading(th._adc, MCP3208_CHANNEL_1, th._vref,
            hardware.micros(), resolve, reject)),
            @() Promise(@(resolve, reject) th.takeADCReading(th._adc, MCP3208_CHANNEL_0, th._vref,
            hardware.micros(), resolve, reject))
        ];

        local p = Promise.all(series);
        p.then(function(value) {
            this.info("successfully executed async");
            this.info(value.len());
            }, function(reason) {
            this.info("failure w/ reason: " + reason);
        });
    }
    
    function testUnInitialized() {
        local spi = hardware.spi0;
        local UITest_adc = MCP3208(spi, _vref);
        local read;
        try {
            read = UITest_adc.readADC(MCP3208_CHANNEL_0);
        } catch (e) {
            return "Unitialized read threw error: " + e;
        }
    }
}