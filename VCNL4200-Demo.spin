{
----------------------------------------------------------------------------------------------------
    Filename:       VCNL4200-Demo.spin
    Description:    Demo of the VCNL4200 driver
    Author:         Jesse Burt
    Started:        Feb 7, 2021
    Updated:        May 9, 2025
    Copyright (c) 2025 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment the two lines below to use the bytecode-based I2C engine
'#define VCNL4200_I2C_BC
'#pragma exportdef(VCNL4200_I2C_BC)

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.light.vcnl4200" | SCL=28, SDA=29, I2C_FREQ=400_000


PUB main() | lux

    setup()

    sensor.preset_als_prox()                    ' set to combined ALS and proximity mode

    repeat
        lux := sensor.lux()
        ser.pos_xy(0, 3)
        ser.printf(@"Lux: %d.%03.3d\n\r", (lux / 1000), (lux // 1000))
        ser.printf(@"White ADC: %04.4x\n\r", sensor.white_data())
        ser.printf(@"Proximity ADC: %04.4x\n\r", sensor.prox_data())


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"VCNL4200 driver started")
    else
        ser.strln(@"VCNL4200 driver failed to start - halting")
        repeat


DAT
{
Copyright 2025 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

