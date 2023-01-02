@define out, 0xFFFF

@define arg1, 0x10
@define arg2, 0x11

set a, arg1

cmp a, arg2
set e, f
and e, 0b00000110
jnz e, true

dsave 0d70, out
hcf

true:
    dsave 0d84, out
    hcf