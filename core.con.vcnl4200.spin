{
    --------------------------------------------
    Filename: core.con.vcnl4200.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2021
    Started Feb 07, 2021
    Updated Feb 07, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' I2C Configuration
    I2C_MAX_FREQ    = 400_000                   ' device max I2C bus freq
    SLAVE_ADDR      = $51 << 1                  ' 7-bit format slave address
    T_POR           = 100_000                      ' startup time (usecs)

    DEVID_RESP      = $1058                     ' device ID expected response

' Register definitions
    DEVID           = $0E

PUB Null{}
' This is not a top-level object

