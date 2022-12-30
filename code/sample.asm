@define out, 0xFFFF
@define address, 0x9001

@define asciistart, 0x41
@define asciiend, 0x5B

main:
    set a, asciistart
    set b, asciiend
    subtract b, asciistart
    loop:

        str a, out
        add a, 0d01 
        sub b, 0d01 
        jnz b, loop