# comment
@define out, 0xFFFF
@define address, 0x9001
main:
    loop:
        add a, 0d03
        str a, address
        str a, out
        add a, 0d03
        str a, address
        str a, out
        jmp loop