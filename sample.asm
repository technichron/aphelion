# comment
@define out, 0x0FF
main:
    set a, 0x00
    loop:
        add a, 0d01
        str a, 0x00AB
        str a, out
        jmp loop