spiModule <- hardware.spi0;
spiModule.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, 50);

adc <- MCP3208(spiModule, 3.3);

function read() {
	server.log(adc.readADC(const MCP3208_CHANNEL_1));
	imp.wakeup(1, read);
}

read();