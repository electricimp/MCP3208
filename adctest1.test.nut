const MCP3208_CHANNEL_0     = 0x00;
const MCP3208_CHANNEL_1     = 0x01;
const MCP3208_CHANNEL_2     = 0x02;
const MCP3208_CHANNEL_3     = 0x03;
const MCP3208_CHANNEL_4     = 0x04;
const MCP3208_CHANNEL_5     = 0x05;
const MCP3208_CHANNEL_6     = 0x06;
const MCP3208_CHANNEL_7     = 0x07;
const MCP3208_ADC_MAX       = 4095.0;

class MCP3208 {

    static VERSION = "1.0.0";
	
    _spiPin = null;
    _csPin = null;
    _vref = null;
	
    function constructor(spiPin, vref, cs=null) { 
	    this._spiPin = spiPin; // assume it's already been configured 
        this._vref = vref;
        this._csPin = cs;

        if (_csPin) {
            _csPin.configure(DIGITAL_OUT, 1);
        }
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
            server.log(format("incorrect input to readADC yieled value %f", read));
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
        server.log("I'm starting at " + startTime);
        local read = _adc.readADC(chan);
        if(read >= 0 && read <= ref) {
            server.log("reading: " + read);
            server.log(format("it took %d uS to execute", hardware.micros() - startTime));
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
            server.log("successfully executed async");
            server.log(value.len());
            }, function(reason) {
            server.log("failure w/ reason: " + reason);
        });
    }
    
    function testUnInitialized() {
        local spi = hardware.spi0;
        local _adc = MCP3208(spi, 3.3);
        _vref = 3.3;
        local read = _adc.readADC(MCP3208_CHANNEL_0);
        server.log("unitialized read a value of: " + read);
        this.assertBetween(read, 0, _vref);
    }
    
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
        if(ch1 >= 0 && ch1 <= 0.02 && ch0 >= 3.299 && ch0 <= 3.3) {
            // call recursively until there is too much error
            fastSwitch(delayTime/10.0, vref, adc);
        } else {
            server.log("error at delay time " + delayTime);
            server.log(format("received %f on ch0 and %f on ch1", ch0, ch1));
        }
    }
}