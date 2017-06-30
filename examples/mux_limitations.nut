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