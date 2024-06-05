{
----------------------------------------------------------------------------------------------------
    Filename:       VCNL4200-Demo.spin
    Description:    Demo of the VCNL4200 driver
    Author:         Jesse Burt
    Started:        Feb 7, 2021
    Updated:        Jun 5, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment the two lines below to use the bytecode-based I2C engine
#define VCNL4200_I2C_BC
#pragma exportdef(VCNL4200_I2C_BC)

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg.LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
' --


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi"
    sensor: "sensor.light.vcnl4200"


PUB main() | lux

    setup()

    sensor.preset_als_prox()                      ' set to combined ALS and proximity mode

    repeat
        lux := sensor.lux()
        ser.pos_xy(0, 3)
        ser.printf2(string("Lux: %d.%03.3d     \n\r"), (lux / 1000), (lux // 1000))
        ser.printf1(string("White ADC: %04.4x\n\r"), sensor.white_data())
        ser.printf1(string("Proximity ADC: %04.4x\n\r"), sensor.prox_data())


PUB setup()

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear()
    ser.strln(string("Serial terminal started"))

    if sensor.startx(SCL_PIN, SDA_PIN, I2C_FREQ)
        ser.strln(string("VCNL4200 driver started"))
    else
        ser.strln(string("VCNL4200 driver failed to start - halting"))
        repeat


DAT
{
Copyright 2024 Jesse Burt

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

