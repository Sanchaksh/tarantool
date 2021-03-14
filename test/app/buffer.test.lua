test_run = require('test_run').new()
buffer = require('buffer')
ffi = require('ffi')

-- Registers.
reg1 = buffer.reg1
reg1.u16 = 100
u16 = ffi.new('uint16_t[1]')
ffi.copy(u16, reg1, 2)
u16[0]

u16[0] = 200
ffi.copy(reg1, u16, 2)
reg1.u16
