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


/*
This part is frequency limited. For example, through testing, it was accurate
within 10% up to ~200kHz clock frequency given 120k impedance with 3.3V ref. For specific max
clock frequency as a function of impedance, see figure 4-2 in the datasheet

http://ww1.microchip.com/downloads/en/DeviceDoc/21298c.pdf
*/

const MCP3208_CHANNEL_0     = 0x00;
const MCP3208_CHANNEL_1     = 0x01;
const MCP3208_CHANNEL_2     = 0x02;
const MCP3208_CHANNEL_3     = 0x03;
const MCP3208_CHANNEL_4     = 0x04;
const MCP3208_CHANNEL_5     = 0x05;
const MCP3208_CHANNEL_6     = 0x06;
const MCP3208_CHANNEL_7     = 0x07;
const MCP3208_ADC_MAX 	    = 4095.0;

class MCP3208 {

	static VERSION = "1.0.0";
	
	_spiPin = null;
	_csPin = null;
	_vref = null;
	
	function constructor(spiPin, vref, cs=null) { 
		this._spiPin = spiPin; // assume it's already been configured 
		
		this._csPin = cs;

		if (_csPin) {
			_csPin.configure(DIGITAL_OUT, 1);
		}
		
		this._vref = vref;
	}
	
	function readADC(channel) {
		_csLow();
		
    		// 3 byte command
    		local sent = blob();
		// for single, bit after start bit is a 1
    		sent.writen(0x06 | (channel >> 2), 'b'); 
    		sent.writen((channel << 6) & 0xFF, 'b');
    		sent.writen(0, 'b');
        
    		local read = _spiPin.writeread(sent);

    		_csHigh();

    		// Extract reading as volts
    		return ((((read[1] & 0x0f) << 8) | read[2]) / MCP3208_ADC_MAX) * _vref;
	}
	
	function readDifferential(in_minus, in_plus) {
		_csLow();
	    
		local select = in_plus; // datasheet
		
		// 3 byte command 
		local sent = blob();
		// for differential, bit after start bit is a 0
		sent.writen(0x04 | (select >> 2), 'b'); 
    		sent.writen((select << 6) & 0xFF, 'b');
    		sent.writen(0, 'b');
	    
		local read = _spiPin.writeread(sent);
		
		_csHigh();
		
		// Extract reading as volts 
		return ((((read[1] & 0x0f) << 8) | read[2]) / MCP3208_ADC_MAX) * _vref;
	}
	
	function _csLow() {
		if(_csPin == null) { 
			// if no cs was passed, assume there is a hardware cs pin
			_spiPin.chipselect(1);
		} else {
			_csPin.write(0);
		}
	}
	
	function _csHigh() {
		if(_csPin == null) {
			_spiPin.chipselect(0);
		} else {
			_csPin.write(1);
		}
	}
}
