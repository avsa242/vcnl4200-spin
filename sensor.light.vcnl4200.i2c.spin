{
    --------------------------------------------
    Filename: sensor.range.vcnl4200.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Vishay VCNL4200
        Proximity and Ambient Light sensor
    Copyright (c) 2021
    Started Feb 07, 2021
    Updated Feb 09, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

' Operating modes
    SLEEP           = %00
    ALS             = %01
    PROX            = %10
    BOTH            = %11
    ALS_PROX        = %11

VAR


OBJ

' choose an I2C engine below
    i2c : "com.i2c"                             ' PASM I2C engine
    core: "core.con.vcnl4200"                   ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if i2c.present(SLAVE_WR)            ' test device bus presence
                i2c.stop{}                      ' *** req'd: device quirk
                if deviceid{} == core#DEVID_RESP' validate device 
                    return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB Defaults{}
' Set factory defaults

PUB ALSData{}: als_adc
' Read Ambient Light Sensor data
'   Returns: u16
    readreg(core#ALS_DATA, 2, @als_adc)

PUB ALSDataRate(rate): curr_rate
' Set ALS data rate, in Hz
'   Valid values: 2_5 (2.5), 5, 10, *20
'   Any other value polls the chip and returns the current setting
'   NOTE: This affects both ALSData() and WhiteData() output
    readreg(core#ALS_CONF, 2, @curr_rate)
    case rate
        2_5, 5, 10, 20:
            rate := lookdownz(rate: 20, 10, 5, 2_5) << core#ALS_IT
        other:
            curr_rate := ((curr_rate >> core#ALS_IT) & core#ALS_IT_BITS)
            return lookupz(curr_rate: 20, 10, 5, 2_5)

    rate := ((curr_rate & core#ALS_IT_MASK) | rate)
    writereg(core#ALS_CONF, 2, @rate)

PUB ALSIntHighThresh(thresh): curr_thr
' Set ALS interrupt high threshold
'   Valid values: 0..65535
    case thresh
        0..65535:
            writereg(core#ALS_THDH, 2, @thresh)
        other:
            readreg(core#ALS_THDH, 2, @curr_thr)
            return

PUB ALSIntLowThresh(thresh): curr_thr
' Set ALS interrupt low threshold
'   Valid values: 0..65535
    case thresh
        0..65535:
            writereg(core#ALS_THDL, 2, @thresh)
        other:
            readreg(core#ALS_THDL, 2, @curr_thr)
            return

PUB ALSIntPersistence(cycles): curr_cyc
' Set ALS interrupt persistence, in number of cycles
'   Valid values:
'      *1, 2, 4, 8
'   Any other value polls the chip and returns the current setting
    readreg(core#ALS_CONF, 2, @curr_cyc)
    case cycles
        1, 2, 4, 8:
            cycles := lookdownz(cycles: 1, 2, 4, 8) << core#ALS_PERS
        other:
            curr_cyc := ((curr_cyc >> core#ALS_PERS) & core#ALS_PERS_BITS)
            return lookupz(curr_cyc: 1, 2, 4, 8)

    cycles := ((curr_cyc & core#ALS_PERS_MASK) | cycles)
    writereg(core#ALS_CONF, 2, @cycles)

PUB ALSIntsEnabled(state): curr_state
' Enable ALS interrupts
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the chip and returns the current setting
    readreg(core#ALS_CONF, 2, @curr_state)
    case ||(state)
        0, 1:
            state := ((||(state) << core#ALS_INT_EN))
        other:
            return (((curr_state >> core#ALS_INT_EN) & 1) == 1)

    state := ((curr_state & core#ALS_INT_EN_MASK) | state)
    writereg(core#ALS_CONF, 2, @state)

PUB DeviceID{}: id
' Read device identification
    id := 0
    readreg(core#DEVID, 2, @id)

PUB IREDDutyCycle(ratio): curr_rat
' Set IRED duty cycle, as a ratio of 1 / ...
'   Valid values: *160, 320, 640, 1280
'   Any other value polls the chip and returns the current setting
    readreg(core#PS_CONF1, 2, @curr_rat)
    case ratio
        160, 320, 640, 1280:
            ratio := lookdownz(ratio: 160, 320, 640, 1280) << core#PS_DUTY
        other:
            curr_rat := ((curr_rat >> core#PS_DUTY) & core#PS_DUTY_BITS)
            return lookupz(curr_rat: 160, 320, 640, 1280)

    ratio := ((curr_rat & core#PS_DUTY_MASK) | ratio)
    writereg(core#PS_CONF1, 2, @ratio)

PUB OpMode(mode): curr_mode | alsconf, psconf
' Set operating mode
'   Valid values:
'      *SLEEP (0): Power down both ALS+PROX sensors
'       ALS (1): Ambient Light Sensor active
'       PROX (2): Proximity sensor active
'       BOTH (3): Both sensors active
'   Any other value polls the chip and returns the current setting
    readreg(core#ALS_CONF, 2, @alsconf)
    readreg(core#PS_CONF1, 2, @psconf)
    case mode
        SLEEP:
            alsconf := (alsconf & core#ALS_SD_MASK) | core#ALS_OFF
            psconf := (psconf & core#PS_SD_MASK) | core#PS_OFF
        ALS:
            alsconf := (alsconf & core#ALS_SD_MASK)
            psconf := (psconf & core#PS_SD_MASK) | core#PS_OFF
        PROX:
            alsconf := ((alsconf & core#ALS_SD_MASK) | core#ALS_OFF)
            psconf := (psconf & core#PS_SD_MASK)
        BOTH, ALS_PROX:
            alsconf := (alsconf & core#ALS_SD_MASK)
            psconf := (psconf & core#PS_SD_MASK)
        other:
            ' a set bit (1) in either reg shuts the sensor down, but
            ' 1 is more intuitive as "on", so invert the bits before returning:
            return (((psconf & 1) << 1) | (alsconf & 1)) ^ %11

    writereg(core#ALS_CONF, 2, @alsconf)
    writereg(core#PS_CONF1, 2, @psconf)

PUB ProxADCRes(adc_res): curr_res
' Set proximity sensor ADC resolution, in bits
'   Valid values: 12, 16
'   Any other value polls the chip and returns the current setting
    readreg(core#PS_CONF1, 2, @curr_res)
    case adc_res
        12, 16:
            adc_res := lookdownz(adc_res: 12, 16) << core#PS_HD
        other:
            curr_res := ((curr_res >> core#PS_HD) & 1)
            return lookupz(curr_res: 12, 16)

    adc_res := ((curr_res & core#PS_HD_MASK) | adc_res)
    writereg(core#PS_CONF1, 2, @adc_res)

PUB ProxBias(level): curr_lev
' Set proximity sensor bias offset
'   Valid values: *0..65535
'   Any other value polls the chip and returns the current setting
    case level
        0..65535:
            writereg(core#PS_CANC, 2, @level)
        other:
            readreg(core#PS_CANC, 2, @curr_lev)
            return

PUB ProxData{}: prox_adc
' Read proximity data
'   Returns: u16
    readreg(core#PS_DATA, 2, @prox_adc)

PUB ProxIntMask(mask): curr_mask
' Set proximity sensor interrupt mask
'   Valid values:
'       Bit 1: assert when far
'           0: assert when near
'   Any other value polls the chip and returns the current setting
    readreg(core#PS_CONF1, 2, @curr_mask)
    case mask
        %00..%11:
            mask <<= core#PS_INT
        other:
            return ((curr_mask >> core#PS_INT) & core#PS_INT_BITS)

    mask := ((curr_mask & core#PS_INT_MASK) | mask)
    writereg(core#PS_CONF1, 2, @mask)

PUB ProxIntPersistence(cycles): curr_cyc
' Set Proximity Sensor interrupt persistence, in cycles
'   Valid values: *1, 2, 3, 4
'   Any other value polls the chip and returns the current setting
    readreg(core#PS_CONF1, 2, @curr_cyc)
    case cycles
        1..4:
            cycles := (cycles-1) << core#PS_PERS
        other:
            return (((curr_cyc >> core#PS_PERS) & core#PS_PERS_BITS) + 1)

    cycles := ((curr_cyc & core#PS_PERS_MASK) | cycles)
    writereg(core#PS_CONF1, 2, @cycles)

PUB Reset{}
' Reset the device

PUB WhiteData{}: white_adc
' Read White light data
    readreg(core#WHITE_DATA, 2, @white_adc)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#ALS_CONF..core#WHITE_DATA, core#INT_FLAG, core#ID:
        other:                                  ' invalid reg_nr
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.wr_byte(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#ALS_CONF:
            byte[ptr_buff][1] |= core#IDD_RSVD  ' preserve reserved bit
        core#ALS_THDH..core#PS_THDH:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop{}

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
