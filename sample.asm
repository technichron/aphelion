# comment
@define out, 0x0FF
@define address, 0x00AB
$main:
    set a, 0x00 #sets A register
    $loop:
        add a, 0d01
        str a, address
        str a, out
        jmp loop