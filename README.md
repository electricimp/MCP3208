# MCP3208

This library provides driver code for Microchip’s [MCP3208](http://ww1.microchip.com/downloads/en/DeviceDoc/21298c.pdf) 8-channel 12-bit analog-digital converter (ADC) with SPI Interface.

**To add this library to your project, add** `#require "MCP3208.device.lib.nut:1.0.0"` **to the top of your device code**

## Class Usage

### Constructor: MCP3208(*spiPin, vref[, cs]*)

The constructor takes two required parameters: *spiPin*, the imp SPI bus that the chip is connected to, and
*vref*, the voltage reference to the ADC. This voltage reference can be set by putting the desired voltage at the
VREF pin of the device. The SPI module **must** be pre-configured before being passed to the constructor. The optional third argument, *cs*, is the chip select pin being used. If it is not passed to the constructor, it is assumed you are using an imp (eg. imp005) with a dedicated chip select pin for the SPI module you have passed.

#### Example

```
// Code for imp005
spiBus <- hardware.spi0;
spiBus.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, 50);

adc <- MCP3208(spiBus, 3.3);
```

## Class Methods

### readADC(*channel*)

This method will return the voltage on the ADC channel you pass to the method, calculated using the VREF you supplied to the constructor. The channel should be an integer in the range 0-7 corresponding to the channel on the device you are taking measurements from. There are constants that you may use provided with this library, eg. *MCP3208_CHANNEL_1*.

#### Example

```
reading <- adc.readADC(MCP3208_CHANNEL_1);
```

### readDifferential(*inMinus, inPlus*)

This method will return the voltage difference between the voltage at channel *inPlus* and channel *inMinus*. *inMinus* and *inPlus* must be a valid pair: channels 0 and 1, channels 2 and 3, channels 4 and 5, or channels 6 and 7.

#### Example

```
difference <- adc.readDifferential(MCP3208_CHANNEL_0, MCP3208_CHANNEL_1);
```

## License

The MCP3208 library is licensed under the [MIT License](./LICENSE)
