# MCP3208
This library provides driver code for Microchip's MCP3208 8-Channel 12-Bit A/D Converter with SPI Interface.

# Class Usage
## Constructor: MCP3208(spiPin, vref[,cs])
The constructor takes two required parameters: spi, the spi module that the chip is connected to, and
vref, the voltage reference to the ADC. The spi module MUST be pre-configured before being passed to
the constructor. The optional third argument, cs, is the chip select pin being used. If it is not 
passed to the constructor, it is assumed you are using an imp with a dedicated chip select pin for
the spi module you have passed.

#### Example
```
spiModule <- hardware.spiBCAD;
spiModule.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, 50);

adc <- MCP3208(spiModule, 3.3);
```

# Class Methods
## readADC(channel)
The method readADC(channel) will return the voltage on the ADC channel you pass to the method, calculated
using the vref you supplied to the constructor.

#### Example
```
reading <- adc.readADC(1);
```

## readDifferential(in_minus, in_plus)
The method readDifferential(in_minus, in_plus) will return the voltage difference between the voltage at
channel in_plus and channel in_minus. in_minus and in_plus must be a valid pair: channels 0 and 1, 
channels 2 and 3, channels 4 and 5, or channels 6 and 7.

#### Example
```
difference <- adc.readDifferential(0, 1);
```
## Datasheet
[Datasheet](http://ww1.microchip.com/downloads/en/DeviceDoc/21298c.pdf)

## License
The MCP3208 library is licensed under the [MIT License](https://github.com/electricimp/MCP3208/blob/develop/LICENSE)
