{
    --------------------------------------------
    Filename: sensor.range.vcnl4200.spin
    Author: Jesse Burt
    Description: Driver for the Vishay VCNL4200
        Proximity and Ambient Light sensor
    Copyright (c) 2022
    Started Feb 07, 2021
    Updated Dec 3, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Operating modes
    SLEEP           = %00
    ALS             = %01
    PROX            = %10
    BOTH            = %11

' Sunlight immunity modes
    OFF             = 0
    NORM            = 1
    HIGH            = 3

' Interrupt flags
    PROX_SAT        = (1 << 7)                  ' prox. sensor saturated
    SUNLT_PROT      = (1 << 6)                  ' sunlight protect on
    ALS_LOW         = (1 << 5)                  ' ALS low threshold
    ALS_HI          = (1 << 4)                  ' ALS high threshold
    PROX_CLOSE      = (1 << 1)                  ' prox. sensor close distance
    PROX_FAR        = 1                         ' prox. sensor far distance

' Proximity sensor interrupt config
    INT_NEAR        = 1
    INT_FAR         = (1 << 1)

VAR

    long _als_res

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef VCNL4200_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.vcnl4200"                   ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            i2c.start{}                         ' reset a possibly "hung up"
            i2c.write($ff)                      '   bus
            i2c.start{}
            i2c.stop{}
            if (dev_id{} == core#DEVID_RESP)    ' validate device
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}
    _als_res := 0

PUB defaults{}
' Set factory defaults
    als_data_rate(20)

PUB preset_als{}
' ALS operating mode, 20Hz data rate
    opmode(ALS)
    als_data_rate(20)

PUB preset_als_prox{}
' ALS and Proximity sensor operating mode
'   * ALS data rate 20Hz
'   * Proximity sensor integration time 1T
    opmode(BOTH)
    als_data_rate(20)
    prox_integr_time(1)

PUB preset_prox{}
' Proximity sensor operating mode
'   * Proximity sensor integration time 1T
    opmode(PROX)
    prox_integr_time(1)

PUB preset_prox_long_range{}
' Proximity sensor operating mode
'   * Proximity sensor integration time 9T
    opmode(PROX)
    prox_integr_time(9)
    prox_adc_res(16)

PUB als_data{}: als_adc
' Read Ambient Light Sensor data
'   Returns: u16
    readreg(core#ALS_DATA, 2, @als_adc)

PUB als_data_rate(rate): curr_rate
' Set ALS data rate, in Hz
'   Valid values: 2_5 (2.5), 5, 10, 20 (default: 20)
'   Any other value polls the chip and returns the current setting
'   NOTE: This affects both als_data() and white_data() output
    readreg(core#ALS_CONF, 2, @curr_rate)
    case rate
        2_5, 5, 10, 20:
            rate := lookdownz(rate: 20, 10, 5, 2_5)
            _als_res := lookupz(rate: 0_024, 0_012, 0_006, 0_003)
            rate <<= core#ALS_IT
        other:
            curr_rate := ((curr_rate >> core#ALS_IT) & core#ALS_IT_BITS)
            return lookupz(curr_rate: 20, 10, 5, 2_5)

    rate := ((curr_rate & core#ALS_IT_MASK) | rate)
    writereg(core#ALS_CONF, 2, @rate)

PUB als_int_hi_thresh{}: thresh
' Get ALS interrupt high threshold
'   Returns: milli-lux
    thresh := 0
    readreg(core#ALS_THDH, 2, @thresh)
    thresh *= _als_res

PUB als_int_lo_thresh{}: thresh
' Get ALS interrupt low threshold
'   Returns: milli-lux
    thresh := 0
    readreg(core#ALS_THDL, 2, @thresh)
    thresh *= _als_res

PUB als_int_set_hi_thresh(thresh)
' Set ALS interrupt high threshold, in milli-lux
'   Valid values: dependent on als_data_rate() - see table below
    case _als_res
        0_024:                                  ' 20Hz
            thresh := 0 #> thresh <# 1572_840
        0_012:                                  ' 10Hz
            thresh := 0 #> thresh <# 786_420
        0_006:                                  ' 5Hz
            thresh := 0 #> thresh <# 393_210
        0_003:                                  ' 2_5Hz (2.5)
            thresh := 0 #> thresh <# 196_605

    thresh /= _als_res
    writereg(core#ALS_THDH, 2, @thresh)

PUB als_int_set_lo_thresh(thresh)
' Set ALS interrupt low threshold, in milli-lux
'   Valid values: dependent on als_data_rate() - see table below
    case _als_res
        0_024:                                  ' 20Hz
            thresh := 0 #> thresh <# 1572_840
        0_012:                                  ' 10Hz
            thresh := 0 #> thresh <# 786_420
        0_006:                                  ' 5Hz
            thresh := 0 #> thresh <# 393_210
        0_003:                                  ' 2_5Hz (2.5)
            thresh := 0 #> thresh <# 196_605

    thresh /= _als_res
    writereg(core#ALS_THDL, 2, @thresh)

PUB als_int_duration(cycles): curr_cyc
' Set number of cycles beyond threshold needed to generate an ALS interrupt
'   Valid values:
'      1, 2, 4, 8 (default: 1)
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

PUB als_int_ena(state): curr_state
' Enable ALS interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0) (default: FALSE)
'   Any other value polls the chip and returns the current setting
    readreg(core#ALS_CONF, 2, @curr_state)
    case ||(state)
        0, 1:
            state := ((||(state) << core#ALS_INT_EN))
        other:
            return (((curr_state >> core#ALS_INT_EN) & 1) == 1)

    state := ((curr_state & core#ALS_INT_EN_MASK) | state)
    writereg(core#ALS_CONF, 2, @state)

PUB dev_id{}: id
' Read device identification
    id := 0
    readreg(core#DEVID, 2, @id)

PUB int_clear{}
' Clear interrupts
    interrupt{}                                 ' simply reading interrupt flags clears them

PUB interrupt{}: src
' Read interrupt flags
'   Bit 7: proximity sensor saturated
'       6: sunlight protection
'       5: ALS crossing als_int_lo_thresh()
'       4: ALS crossing als_int_hi_thresh()
'       1: close proximity: prox. above prox_int_hi_thresh()
'       0: far proximity: prox. below prox_int_lo_thresh()
    src := 0
    readreg(core#INT_FLAG, 2, @src)
    src >>= 8

PUB ired_current(led_i): curr_i
' Set IRED drive current, in milliamperes
'   Valid values: 50, 75, 100, 120, 140, 160, 180, 200
'   Any other value polls the chip and returns the current setting
    readreg(core#PS_CONF3, 2, @curr_i)
    case led_i
        50, 75, 100, 120, 140, 160, 180, 200:
            led_i := lookdownz(led_i: 50, 75, 100, 120, 140, 160, 180, 200) << core#LED_I
        other:
            curr_i := ((curr_i >> core#LED_I) & core#LED_I_BITS)
            return lookupz(curr_i: 50, 75, 100, 120, 140, 160, 180, 200)
    led_i := ((curr_i & core#LED_I_MASK) | led_i)
    writereg(core#PS_CONF3, 2, @led_i)

PUB ired_duty_cycle(ratio): curr_rat
' Set IRED duty cycle, as a ratio of 1 / ...
'   Valid values: 160, 320, 640, 1280 (default: 160)
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

PUB lux{}: mlx
' Read ALS sensor data, calculated in milli-lux
    return (als_data{} * _als_res)

PUB opmode(mode): curr_mode | alsconf, psconf
' Set operating mode
'   Valid values:
'       SLEEP (0): Power down both ALS+PROX sensors (default)
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
        BOTH:
            alsconf := (alsconf & core#ALS_SD_MASK)
            psconf := (psconf & core#PS_SD_MASK)
        other:
            ' a set bit (1) in either reg shuts the sensor down, but
            ' 1 is more intuitive as "on", so invert the bits before returning:
            return (((psconf & 1) << 1) | (alsconf & 1)) ^ %11

    writereg(core#ALS_CONF, 2, @alsconf)
    writereg(core#PS_CONF1, 2, @psconf)

PUB prox_adc_res(adc_res): curr_res
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

PUB prox_bias{}: p
' Get currently set proximity sensor bias/offset
    p := 0
    readreg(core#PS_CANC, 2, @p)

PUB prox_data{}: prox_adc
' Read proximity data
'   Returns: u16
    readreg(core#PS_DATA, 2, @prox_adc)

PUB prox_int_hi_thresh{}: curr_thr
' Get proximity interrupt high threshold
    curr_thr := 0
    readreg(core#PS_THDH, 2, @curr_thr)

PUB prox_int_lo_thresh{}: curr_thr
' Get proximity interrupt low threshold
    curr_thr := 0
    readreg(core#PS_THDL, 2, @curr_thr)

PUB prox_int_set_hi_thresh(thresh)
' Set proximity interrupt high threshold
'   Valid values: 0..65535
    thresh := 0 #> thresh <# 65535
    writereg(core#PS_THDH, 2, @thresh)

PUB prox_int_set_lo_thresh(thresh)
' Set proximity interrupt low threshold
'   Valid values: 0..65535
    thresh := 0 #> thresh <# 65535
    writereg(core#PS_THDL, 2, @thresh)

PUB prox_int_mask(mask): curr_mask
' Set proximity sensor interrupt mask
'   Valid values:
'       Bit 1: (INT_FAR) assert when far
'           0: (INT_NEAR) assert when near
'   Any other value polls the chip and returns the current setting
    readreg(core#PS_CONF1, 2, @curr_mask)
    case mask
        %00..%11:
            mask <<= core#PS_INT
        other:
            return ((curr_mask >> core#PS_INT) & core#PS_INT_BITS)

    mask := ((curr_mask & core#PS_INT_MASK) | mask)
    writereg(core#PS_CONF1, 2, @mask)

PUB prox_int_duration(cycles): curr_cyc
' Set number of cycles beyond threshold needed to generate a proximity interrupt
'   Valid values: 1, 2, 3, 4 (default: 1)
'   Any other value polls the chip and returns the current setting
    readreg(core#PS_CONF1, 2, @curr_cyc)
    case cycles
        1..4:
            cycles := (cycles-1) << core#PS_PERS
        other:
            return (((curr_cyc >> core#PS_PERS) & core#PS_PERS_BITS) + 1)

    cycles := ((curr_cyc & core#PS_PERS_MASK) | cycles)
    writereg(core#PS_CONF1, 2, @cycles)

PUB prox_integr_time(itime): curr_itime
' Set Proximity sensor integration time, as a cycle multiplier
'   Valid values: 1, 1_5 (1.5), 2, 4, 8, 9
'   Any other value polls the chip and returns the current setting
    curr_itime := 0
    readreg(core#PS_CONF1, 2, @curr_itime)
    case itime
        1, 1_5, 2, 4, 8, 9:
            itime := lookdownz(itime: 1, 1_5, 2, 4, 8, 9) << core#PS_IT
        other:
            curr_itime := ((curr_itime >> core#PS_IT) & core#PS_IT_BITS)
            return lookupz(itime: 1, 1_5, 2, 4, 8, 9)

    itime := ((curr_itime & core#PS_IT_MASK) | itime)
    writereg(core#PS_CONF1, 2, @itime)

PUB prox_set_bias(p)
' Set proximity sensor bias/offset
'   Valid values: 0..65535 (clamped to range; default: 0)
    p := 0 #> p <# 65535
    writereg(core#PS_CANC, 2, @p)

PUB reset{}
' Reset the device

PUB sun_cancel_mode(mode): curr_mode
' Set sunlight cancellation/immunity mode
'   Valid values:
'       OFF (0): disabled
'       NORM (1): typical sunlight immunity
'       HIGH (3): 2x typical sunlight immunity
    readreg(core#PS_CONF3, 2, @curr_mode)
    case mode
        OFF, NORM, HIGH:
        other:
            curr_mode := (curr_mode & core#PS_SC_BITS)
            return lookupz(curr_mode & core#PS_SC_BITS: OFF, NORM, OFF, HIGH)

    mode := ((curr_mode & core#PS_SC_MASK) | mode)
    writereg(core#PS_CONF3, 2, @mode)

PUB white_data{}: white_adc
' Read White light data
    readreg(core#WHITE_DATA, 2, @white_adc)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
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

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
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
Copyright 2022 Jesse Burt

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

