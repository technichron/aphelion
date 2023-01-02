@define out, 0xFFFF
@define address, 0x9001

@define asciistart, 0x41
@define asciiend, 0x5A

main:
    set a, asciistart

    loop:
        save a, out
        add a, 0d01
        jle a, asciiend, loop
hcf