# comment
@define out, 0xFFFF
@define address, 0x9001
main:
    set a, 0d104
    loop:
        sw a, out
        jmp loop