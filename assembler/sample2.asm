set b, 0x0F
loop:
    add b, 0x01
    str b, 0x07FF
    jmp loop