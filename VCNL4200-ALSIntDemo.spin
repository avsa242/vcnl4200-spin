{
----------------------------------------------------------------------------------------------------
    Filename:       VCNL4200-ALSIntDemo.spin
    Description:    Demo of the VCNL4200 driver
        * ALS sensor interrupt functionality
    Author:         Jesse Burt
    Started:        Feb 10, 2021
    Updated:        Jun 6, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment the two lines below to use the bytecode-based I2C engine
'#define VCNL4200_I2C_BC
'#pragma exportdef(VCNL4200_I2C_BC)

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq

' -- User-defined constants
    LED         = cfg.LED1
    INT_PIN     = 24
' --


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.light.vcnl4200" | SCL=28, SDA=29, I2C_FREQ=400_000


VAR

    long _isr_stack[50], _interrupt


PUB main()

    setup()

    sensor.preset_als()                           ' set to ambient light sensing mode

    { enable interrupts and set low and high thresholds }
    sensor.als_int_ena(TRUE)
    sensor.int_clear()
    sensor.als_int_set_lo_thresh(55_000)          ' units: milli-lux (1_000 = 0.001 lx)
    sensor.als_int_set_hi_thresh(75_000)          '

    ser.pos_xy(0, 3)
    ser.printf2(@"Thresh  low: %d high: %d",    sensor.als_int_lo_thresh(), ...
                                                sensor.als_int_hi_thresh() )

    repeat
        ser.pos_xy(0, 5)
        ser.printf1(@"Lux: %6.6d", sensor.lux())
        if ( _interrupt )
            ser.str(@"   INTERRUPT (press c to clear)")

        ser.clear_line()
        if ( ser.rx_check() == "c" )
            sensor.int_clear()


PUB cog_isr()
' Interrupt service routine
    dira[INT_PIN] := 0
    dira[LED] := 1

    repeat
        waitpne(|< INT_PIN, |< INT_PIN, 0)      ' wait for interrupt (active low)
        outa[LED] := 1
        _interrupt := TRUE
        waitpeq(|< INT_PIN, |< INT_PIN, 0)      ' wait for interrupt to clear
        outa[LED] := 0
        _interrupt := FALSE


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

    cognew(cog_isr(), @_isr_stack)              ' start the ISR in another cog


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

