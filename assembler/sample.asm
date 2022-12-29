# comment
@define out, 0x0FF
@define address, 0x00AB
main:
    loop:
        add a, 0d03
        str a, address
        str a, out
        add a, 0d03
        str a, address
        str a, out
        jmp loop