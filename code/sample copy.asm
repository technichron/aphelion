%define asciistart, 'a'
%define asciiend, 'Z'


main:
    set a, asciistart

    jle a, asciiend, loop

    invalidrange:
        dsave 'i', out
        dsave 'n', out
        dsave 'v', out
        dsave 'a', out
        dsave 'l', out
        dsave 'i', out
        dsave 'd', out
        hcf

    loop:
        save a, out
        add a, 0d01
        jle a, asciiend, loop
        hcf