# vcnl4200-spin
---------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Vishay VCNL4200 Proximity and Ambient Light sensor.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Read Ambient Light Sensor data (raw ADC, milli-lux), Proximity sensor data (raw ADC), White light data (raw ADC)
* Set ALS data rate/integration time
* Set IRED current and duty cycle
* Interrupts: ALS and Prox. interrupt thresholds, interrupt persistence, interrupt mask (Prox.)
* Set Prox. ADC resolution (12, 16 bits)
* Set Prox. 'zero', or bias offset
* Sunlight cancellation/immunity

## Requirements

P1/SPIN1:

* spin-standard-library
* 1 extra core/cog for the PASM I2C engine (none if bytecode engine is used)

P2/SPIN2:

* p2-spin-standard-library

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | NuCode      | FTBFS                 |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* Ensure you power the VCNL4200's IR LED from a high current 5V source (>800mA); powering it
via some boards' 5V outputs (e.g., from a Parallax FLiP's USB5V when connected to a PC USB port)
isn't recommended. The high current draw can cause strange serial behavior and failure to load
code to the Propeller.

