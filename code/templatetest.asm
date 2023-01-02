@define out, 0xFFFF

main:
    jge a, 0x50, display
    add a, 0x01
    jmp main


display:
    save a, out
    dsave 0x5F, out