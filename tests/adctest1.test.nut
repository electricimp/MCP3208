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

class MyTestCase extends ImpTestCase {
    
    _adc = null;
    _vref = 0;

    function testWrongParameterToFunction() {
        local spi = hardware.spi0;
        spi.configure(USE_CS_L | CLOCK_IDLE_LOW | MSB_FIRST, 50);
        _adc = MCP3208(spi, 3.3);
        _vref = 3.3;
        for(local i = 10; i < 20; ++i) {
            local read = _adc.readADC(10);
            this.info(format("incorrect input to readADC yielded value %f", read));
            this.assertBetween(read, 0, _vref);
        }
    }

    function testValue() {
        local spi = hardware.spi0;
        spi.configure(USE_CS_L | CLOCK_IDLE_LOW | MSB_FIRST, 50);
        _adc = MCP3208(spi, 3.3);
        _vref = 3.3;
        local vals = array(8);
        for(local i = 0; i < 8; ++i) {
            vals[i] = _adc.readADC(i);
        }
        for(local i = 0; i < 8; ++i) {
            this.assertBetween(vals[i], 0, _vref);
        }
    }
    
    function read(_adc, chan, ref, startTime, resolve, reject) {
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

    function testAsynchronous() {
        local spi = hardware.spi0;
        spi.configure(USE_CS_L | CLOCK_IDLE_LOW | MSB_FIRST, 50);
        _adc = MCP3208(spi, 3.3);
        _vref = 3.3;
        local th = this;
        local series = [
            @() Promise(@(resolve, reject) th.read(th._adc, MCP3208_CHANNEL_1, th._vref,
            hardware.micros(), resolve, reject)),
            @() Promise(@(resolve, reject) th.read(th._adc, MCP3208_CHANNEL_0, th._vref,
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
        local _adc = MCP3208(spi, 3.3);
        _vref = 3.3;
        local read = _adc.readADC(MCP3208_CHANNEL_0);
        this.info("unitialized read a value of: " + read);
        this.assertBetween(read, 0, _vref);
    }
}